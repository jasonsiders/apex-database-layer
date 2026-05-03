import { LightningElement, api } from "lwc";
import validateQuery from "@salesforce/apex/InvocableSoql.validateQuery";

/** Custom event name fired when an input value changes. */
const EVT_VALUE_CHANGED = "configuration_editor_input_value_changed";
/** Custom event name fired when an input value is deleted. */
const EVT_VALUE_DELETED = "configuration_editor_input_value_deleted";
/** Custom event name fired when generic type mappings change (e.g., output object types). */
const EVT_GENERIC_TYPE_MAPPING_CHANGED = "configuration_editor_generic_type_mapping_changed";
/** Flow input variable name for the SOQL query text. */
const INPUT_VAR_QUERY = "query";
/** Flow input variable name for bind variables (legacy array format). */
const INPUT_VAR_BINDS = "binds";
/** Flow input variable name for bind variables (current JSON format). */
const INPUT_VAR_BINDS_JSON = "bindsJson";
/** Regular expression for validating bind variable names. */
const BIND_KEY_PATTERN = /^[A-Za-z_][A-Za-z0-9_]*$/;
/** Error message displayed when a bind variable name is invalid. */
const INVALID_BIND_KEY_MESSAGE =
	"Bind variable names can contain only letters, numbers, and underscores, and must start with a letter or underscore.";
/** Error message suffix for duplicate bind variable names. */
const DUPLICATE_BIND_ERROR_SUFFIX = "is already defined.";
/** Error message suffix for bind variables not referenced in the query. */
const ORPHANED_BIND_ERROR_SUFFIX = "is not referenced by the query.";
/** Generic type mapping names for SOQL action output types. */
const OUTPUT_TYPE_MAPPINGS = ["U__allResults", "U__firstResult"];

/**
 * Custom property editor for SOQL queries with bind variable support.
 * Provides syntax highlighting, bind variable management, and Apex-side query validation.
 * Emits configuration_editor_input_value_changed and configuration_editor_generic_type_mapping_changed events.
 */
export default class InvocableSoqlPropertyEditor extends LightningElement {
	/**
	 * Masks quoted string content to avoid matching keywords or bind references within string literals.
	 * Preserves the position of text for accurate pattern matching.
	 * @param {string} query SOQL query string
	 * @returns {string} Query with quoted content replaced by spaces
	 * @private
	 */
	static _maskQuotedText(query) {
		const text = query || "";
		let result = "";
		let quote = null;

		for (let index = 0; index < text.length; index++) {
			const char = text[index];

			if (quote) {
				result += " ";
				if (char === "\\" && index + 1 < text.length) {
					result += " ";
					index++;
				} else if (char === quote) {
					quote = null;
				}
				continue;
			}

			if (char === "'" || char === '"') {
				quote = char;
				result += " ";
				continue;
			}

			result += char;
		}

		return result;
	}

	/**
	 * Extracts all bind variable reference names from a SOQL query.
	 * Bind references are identified by the `:name` pattern outside of quoted strings.
	 * @param {string} query SOQL query string
	 * @returns {Set<string>} Set of bind variable names referenced in the query
	 * @private
	 */
	static _extractBindReferenceNames(query) {
		const names = new Set();
		const text = this._maskQuotedText(query);
		const bindPattern = /:([A-Za-z_][A-Za-z0-9_]*)\b/g;
		let match;

		while ((match = bindPattern.exec(text)) !== null) {
			if (text[match.index - 1] === ":") {
				continue;
			}
			names.add(match[1]);
		}

		return names;
	}

	/**
	 * Validates a bind variable key against naming rules and query usage.
	 * @param {string} key Bind variable name to validate
	 * @param {Map<string, number>} bindKeyCounts Count of each bind key (for duplicate detection)
	 * @param {Set<string>} referencedNames Set of bind names referenced in the query
	 * @returns {string|null} Validation error message, or null if valid
	 * @private
	 */
	static _validateBindKey(key, bindKeyCounts, referencedNames) {
		if (!BIND_KEY_PATTERN.test(key)) {
			return INVALID_BIND_KEY_MESSAGE;
		}
		if (bindKeyCounts.get(key) > 1) {
			return `Bind variable "${key}" ${DUPLICATE_BIND_ERROR_SUFFIX}`;
		}
		if (!referencedNames.has(key)) {
			return `Bind variable "${key}" ${ORPHANED_BIND_ERROR_SUFFIX}`;
		}
		return null;
	}

	/**
	 * Output variables supplied by Flow Builder for the selected action.
	 * Used to populate generic type mappings for output fields.
	 */
	@api outputVariables = [];

	_builderContext = {};
	_genericTypeMappings = [];
	_inputVariables = [];
	_queryDraft = "";
	_queryError = null;
	_querySuccess = null;
	_queryInitialized = false;
	_outputTypeValue = null;
	_bindsDraft = [];
	_bindsInitialized = false;
	_bindValidationErrors = {};
	_hasValidatedBinds = false;

	/**
	 * Flow Builder context exposed by the custom property editor contract.
	 * Contains Flow resources, variables, constants, and other metadata.
	 * @type {Object}
	 */
	@api get builderContext() {
		return this._builderContext;
	}

	set builderContext(value) {
		this._builderContext = value ?? {};
	}

	/**
	 * Generic type mappings exposed by the custom property editor contract.
	 * Maps Flow data type names to runtime values based on selected SOQL objects.
	 * @type {Array<Object>}
	 */
	@api get genericTypeMappings() {
		return this._genericTypeMappings;
	}

	set genericTypeMappings(value) {
		this._genericTypeMappings = Array.isArray(value) ? value : [];
		this._outputTypeValue = this._readOutputTypeValue(this._genericTypeMappings);
	}

	/**
	 * Flow action input variables exposed by the custom property editor contract.
	 * Contains the current query and bind variable definitions.
	 * @type {Array<Object>}
	 */
	@api get inputVariables() {
		return this._inputVariables;
	}

	set inputVariables(value) {
		this._inputVariables = Array.isArray(value) ? value : [];
		this._initQuery();
		this._initBinds();
	}

	/**
	 * Bind variables with their validation errors, formatted for template rendering.
	 * @returns {Array<Object>} Array of bind objects with variable, indexKey, and errorMessage properties
	 */
	get decoratedBinds() {
		return this._bindsDraft.map((variable, index) => ({
			variable,
			indexKey: String(index),
			errorMessage: this._bindValidationErrors[index] ?? null
		}));
	}

	/**
	 * Placeholder text for the SOQL query editor.
	 * @returns {string} Example SOQL query
	 */
	get queryPlaceholder() {
		return "ex., SELECT Id, Name FROM Account WHERE Id = :recordId...";
	}

	/**
	 * CSS class for the query input form element, includes error styling if validation failed.
	 * @returns {string} CSS class names
	 */
	get formElementClass() {
		return this._queryError ? "slds-form-element slds-has-error" : "slds-form-element";
	}

	/**
	 * Current query validation error message from Apex, or null if valid.
	 * @returns {string|null} Error message
	 */
	get queryError() {
		return this._queryError;
	}

	/**
	 * Query validation success message, or null if not validated or validation failed.
	 * @returns {string|null} Success indicator
	 */
	get querySuccess() {
		return this._querySuccess;
	}

	/**
	 * Current SOQL query text being edited.
	 * @returns {string} The query string
	 */
	get queryValue() {
		return this._queryDraft;
	}

	/**
	 * Whether the editor has any bind variables defined.
	 * @returns {boolean} True if bind variables exist
	 */
	get hasBinds() {
		return this._bindsDraft.length > 0;
	}

	/**
	 * Validates bind metadata and the SOQL query through Apex.
	 * @returns {Promise<Array<{ key: string, errorString: string }>>} Flow validation errors.
	 */
	@api async validate() {
		this._hasValidatedBinds = true;
		const bindErrors = this._validateBindReferences({ report: true });
		if (bindErrors.length) {
			this._queryError = null;
			return bindErrors;
		}

		try {
			const bindKeys = this._bindsDraft.map((b) => b.key);
			await validateQuery({ queryToValidate: this._queryDraft, bindKeys });
			this._queryError = null;
			return [];
		} catch (error) {
			// Note: Soql.cls appends the offending query to the error message on a new line
			// This information is redundant, since the query is displayed in the input element
			const fullMessage = error?.body?.message ?? "";
			const errorString = fullMessage.split("\n")[0];
			this._queryError = `Error: ${errorString}`;
			return [{ key: INPUT_VAR_QUERY, errorString }];
		}
	}

	/**
	 * Syncs editor content after render and applies validation errors if needed.
	 */
	renderedCallback() {
		this._syncEditorContent();
		if (this._hasValidatedBinds) {
			this._applyBindValidationErrors(false);
		}
	}

	/**
	 * Adds a new empty bind variable row to the bind list.
	 */
	handleBindAdd() {
		this._applyBindsUpdate([
			...this._bindsDraft,
			{ key: "", textValue: "", typeName: "String", isCollection: false }
		]);
	}

	/**
	 * Applies a partial update to a bind variable row.
	 * @param {CustomEvent} event - Contains index and patch (partial bind object)
	 */
	handleBindChange(event) {
		if (!event?.detail?.patch) return;
		const index = Number(event.detail.index);
		const updated = this._bindsDraft.map((b, i) => (i === index ? { ...b, ...event.detail.patch } : b));
		this._applyBindsUpdate(updated);
	}

	/**
	 * Removes a bind variable row by index.
	 * @param {CustomEvent} event - Contains index of the row to remove
	 */
	handleBindRemove(event) {
		const removeIndex = Number(event.detail.index);
		if (Number.isNaN(removeIndex)) return;
		this._applyBindsUpdate(this._bindsDraft.filter((_, i) => i !== removeIndex));
	}

	/**
	 * Syncs syntax highlighting code element scroll position with the query textarea.
	 * @param {Event} event
	 */
	handleEditorScroll(event) {
		const pre = this.template.querySelector(".code-highlight");
		if (pre) {
			pre.scrollTop = event.target.scrollTop;
			pre.scrollLeft = event.target.scrollLeft;
		}
	}

	/**
	 * Handles query text input: updates query, output types, and syntax highlighting.
	 * @param {Event} event
	 */
	handleQueryInput(event) {
		this._updateQuery(event.target.value);
		this._syncOutputTypeMappings();
		this._syncHighlight(this._queryDraft);
		this._syncBindValidationStateAfterInput();
	}

	/**
	 * Validates the current query and binds, displays success or error message.
	 */
	async handleValidate() {
		const errors = await this.validate();
		this._querySuccess = errors.length ? null : "✓ Valid";
	}

	/**
	 * Updates the bind variables list, notifies parent, and revalidates.
	 * @private
	 * @param {Array} updated - The updated bind variable array
	 */
	_applyBindsUpdate(updated) {
		this._bindsDraft = updated;
		this._dispatchBindsChange(updated);
		this._syncBindValidationStateAfterInput();
	}

	/**
	 * Loads the initial SOQL query from inputVariables, only runs once on first set.
	 * @private
	 */
	_initQuery() {
		if (!this._queryInitialized) {
			this._queryDraft = this._readInputValue(this._inputVariables, INPUT_VAR_QUERY) ?? "";
			this._queryInitialized = true;
		}
	}

	/**
	 * Loads the initial bind variables from inputVariables, only runs once on first set.
	 * Supports both JSON (bindsJson) and array (binds) formats.
	 * @private
	 */
	_initBinds() {
		if (!this._bindsInitialized) {
			const rawBinds =
				this._readInputValue(this._inputVariables, INPUT_VAR_BINDS_JSON) ??
				this._readInputValue(this._inputVariables, INPUT_VAR_BINDS);
			this._bindsDraft = this._cloneBinds(rawBinds);
			this._bindsInitialized = true;
		}
	}

	/**
	 * Syncs the editor textarea value and syntax highlighting after render.
	 * Only updates if the textarea is not currently focused.
	 * @private
	 */
	_syncEditorContent() {
		const textarea = this.template.querySelector(".code-editor");
		if (textarea && document.activeElement !== textarea) {
			textarea.value = this.queryValue;
			this._syncHighlight(this.queryValue);
		}
	}

	/**
	 * Creates a deep copy of bind variables, handling both JSON string and array formats.
	 * @private
	 * @param {Array|string} binds - Bind variables as array or JSON string
	 * @returns {Array} Cloned bind variable array, or empty array if parsing fails
	 */
	_cloneBinds(binds) {
		if (typeof binds === "string") {
			try {
				return this._cloneBinds(JSON.parse(binds));
			} catch {
				return [];
			}
		}
		return Array.isArray(binds) ? binds.map((bind) => ({ ...bind })) : [];
	}

	/**
	 * Re-validates bind variables if validation has already been run by parent.
	 * Used to update validation errors as the user edits without reporting to browser.
	 * @private
	 */
	_syncBindValidationStateAfterInput() {
		if (this._hasValidatedBinds) {
			this._validateBindReferences({ report: false });
		}
	}

	/**
	 * Counts occurrences of each bind key in the bind list.
	 * Used to detect duplicate bind variable names.
	 * @private
	 * @returns {Map<string, number>} Map of bind key to occurrence count
	 */
	_countBindKeys() {
		const counts = new Map();
		for (const bind of this._bindsDraft) {
			const key = String(bind?.key ?? "");
			if (key && BIND_KEY_PATTERN.test(key)) {
				counts.set(key, (counts.get(key) ?? 0) + 1);
			}
		}
		return counts;
	}

	/**
	 * Validates bind names against query references and row-level naming rules.
	 * @param {{ report?: boolean }} [options={}] Whether to report validity immediately.
	 * @returns {Array<{ key: string, errorString: string }>} Flow validation errors.
	 */
	_validateBindReferences({ report = true } = {}) {
		const referencedNames = InvocableSoqlPropertyEditor._extractBindReferenceNames(this._queryDraft);
		const bindKeyCounts = this._countBindKeys();
		const errorsByIndex = {};
		const errors = [];

		this._bindsDraft.forEach((bind, index) => {
			const key = String(bind?.key ?? "");
			if (!key) {
				return;
			}
			const errorString = InvocableSoqlPropertyEditor._validateBindKey(key, bindKeyCounts, referencedNames);
			if (!errorString) {
				return;
			}
			errorsByIndex[index] = errorString;
			errors.push({ key: INPUT_VAR_BINDS_JSON, errorString });
		});

		this._bindValidationErrors = errorsByIndex;
		this._applyBindValidationErrors(report);
		return errors;
	}

	/**
	 * Applies validation error messages to child soql-bind-input components.
	 * @private
	 * @param {boolean} report - If true, bind inputs will report validity to show browser validation UI
	 */
	_applyBindValidationErrors(report) {
		this.template.querySelectorAll("c-soql-bind-input").forEach((bindInput, index) => {
			bindInput.validate?.(this._bindValidationErrors[index] ?? null, { report });
		});
	}

	/**
	 * Notifies parent of bind variable changes.
	 * Dispatches change event for bindsJson and deletion event for legacy binds variable if present.
	 * @private
	 * @param {Array} binds - The updated bind variables
	 */
	_dispatchBindsChange(binds) {
		const value = binds.length ? JSON.stringify(binds) : null;
		this._dispatchChange(INPUT_VAR_BINDS_JSON, value, "String");
		if (this._hasInputVariable(INPUT_VAR_BINDS)) {
			this._dispatchChange(INPUT_VAR_BINDS, null, "String");
		}
	}

	/**
	 * Dispatches a configuration change event to Flow Builder.
	 * Follows the custom property editor contract.
	 * @private
	 * @param {string} name - Input variable name that changed
	 * @param {*} value - New value for the variable, or null to delete
	 * @param {string} dataType - Flow data type of the variable
	 */
	_dispatchChange(name, value, dataType) {
		const eventName = value == null ? EVT_VALUE_DELETED : EVT_VALUE_CHANGED;
		const detail = value == null ? { name } : { name, newValue: value, newValueDataType: dataType };
		this.dispatchEvent(
			new CustomEvent(eventName, {
				bubbles: true,
				cancelable: false,
				composed: true,
				detail
			})
		);
	}

	/**
	 * Checks whether an input variable with the given name exists.
	 * @private
	 * @param {string} name - Input variable name to check
	 * @returns {boolean} True if the variable exists
	 */
	_hasInputVariable(name) {
		return this._inputVariables.some((inputVariable) => inputVariable.name === name);
	}

	/**
	 * Notifies parent of generic type mapping changes (output object types).
	 * Called when the FROM clause object is identified in the query.
	 * @private
	 * @param {string} typeName - The generic type name (e.g., "U__allResults")
	 * @param {string} typeValue - The SObject type (e.g., "Account")
	 */
	_dispatchGenericTypeMapping(typeName, typeValue) {
		const detail = { typeName, typeValue };
		this.dispatchEvent(
			new CustomEvent(EVT_GENERIC_TYPE_MAPPING_CHANGED, {
				bubbles: true,
				cancelable: false,
				composed: true,
				detail
			})
		);
	}

	/**
	 * Applies syntax highlighting to SOQL query text.
	 * Highlights strings, bind references, functions, date functions, and keywords with CSS classes.
	 * @private
	 * @param {string} text - SOQL query text to highlight
	 * @returns {string} HTML with syntax highlighting spans
	 */
	_highlight(text) {
		const escaped = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
		return escaped.replace(
			/("[^"]*")|(\{![^}]+\})|\b(COUNT_DISTINCT|COUNT|SUM|AVG|MIN|MAX|FORMAT|toLabel|convertCurrency|DISTANCE|GEOLOCATION|FIELDS|CALENDAR_YEAR|CALENDAR_MONTH|CALENDAR_QUARTER|DAY_IN_MONTH|DAY_IN_WEEK|DAY_IN_YEAR|DAY_ONLY|FISCAL_MONTH|FISCAL_QUARTER|FISCAL_YEAR|HOUR_IN_DAY|WEEK_IN_MONTH|WEEK_IN_YEAR)\b|\b(LAST_FISCAL_QUARTER|NEXT_FISCAL_QUARTER|THIS_FISCAL_QUARTER|LAST_FISCAL_YEAR|NEXT_FISCAL_YEAR|THIS_FISCAL_YEAR|LAST_N_DAYS|NEXT_N_DAYS|LAST_N_WEEKS|NEXT_N_WEEKS|LAST_N_MONTHS|NEXT_N_MONTHS|LAST_N_QUARTERS|NEXT_N_QUARTERS|LAST_N_YEARS|NEXT_N_YEARS|LAST_90_DAYS|NEXT_90_DAYS|LAST_QUARTER|LAST_MONTH|LAST_WEEK|LAST_YEAR|NEXT_QUARTER|NEXT_MONTH|NEXT_WEEK|NEXT_YEAR|THIS_QUARTER|THIS_MONTH|THIS_WEEK|THIS_YEAR|TODAY|YESTERDAY|TOMORROW)\b|\b(SELECT|FROM|WHERE|AND|OR|NOT|LIKE|IN|INCLUDES|EXCLUDES|AS|WITH|FOR|UPDATE|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|ASC|DESC|NULLS|FIRST|LAST|NULL|TRUE|FALSE|USING|SCOPE|TYPEOF|WHEN|THEN|ELSE|END|VIEW|REFERENCE|TRACKING|VIEWSTAT)\b/gi,
			(match, str, bind, fn, dt) => {
				if (str !== undefined) return `<span class="hl-str">${match}</span>`;
				if (bind !== undefined) return `<span class="hl-bind">${match}</span>`;
				if (fn !== undefined) return `<span class="hl-fn">${match}</span>`;
				if (dt !== undefined) return `<span class="hl-dt">${match}</span>`;
				return `<span class="hl-kw">${match}</span>`;
			}
		);
	}

	/**
	 * Reads a value from an array of input variables by name.
	 * @private
	 * @param {Array} inputVariables - Array of input variable objects
	 * @param {string} name - Name of the variable to find
	 * @returns {*} The variable's value, or null if not found
	 */
	_readInputValue(inputVariables, name) {
		return (inputVariables ?? []).find((v) => v.name === name)?.value ?? null;
	}

	/**
	 * Reads the current output type value from generic type mappings.
	 * @private
	 * @param {Array} genericTypeMappings - Generic type mapping objects
	 * @returns {string|undefined} The output SObject type, or undefined if not found
	 */
	_readOutputTypeValue(genericTypeMappings) {
		const mapping = (genericTypeMappings ?? []).find((m) => OUTPUT_TYPE_MAPPINGS.includes(m.typeName));
		return mapping?.typeValue;
	}

	/**
	 * Updates the syntax highlighting display element with highlighted query text.
	 * @private
	 * @param {string} text - SOQL query text to highlight
	 */
	_syncHighlight(text) {
		const pre = this.template.querySelector(".code-highlight");
		if (pre) {
			pre.innerHTML = this._highlight(text) + "\n";
		}
	}

	/**
	 * Updates the query draft and notifies parent of changes.
	 * @private
	 * @param {string} value - The new query text
	 */
	_updateQuery(value) {
		this._queryDraft = value || "";
		this._dispatchChange(INPUT_VAR_QUERY, this._queryDraft || null, "String");
	}

	/**
	 * Extracts the root SObject name from a SOQL query by parsing the FROM clause.
	 * Properly handles parentheses depth and quoted strings to avoid false matches.
	 * @private
	 * @param {string} query - The SOQL query string
	 * @returns {string|null} The SObject name from the FROM clause, or null if not found
	 */
	_extractRootObjectName(query) {
		const text = query || "";
		let depth = 0;
		let quote = null;
		for (let index = 0; index < text.length; index++) {
			const char = text[index];
			if (quote) {
				if (char === "\\" && index + 1 < text.length) {
					index++;
				} else if (char === quote) {
					quote = null;
				}
				continue;
			}
			if (char === "'" || char === '"') {
				quote = char;
				continue;
			}
			if (char === "(") {
				depth++;
				continue;
			}
			if (char === ")") {
				depth = Math.max(depth - 1, 0);
				continue;
			}
			if (depth === 0 && this._matchesWord(text, index, "FROM")) {
				const objectNameStart = this._skipWhitespace(text, index + "FROM".length);
				const match = text.slice(objectNameStart).match(/^([A-Za-z_][A-Za-z0-9_]*)\b/);
				return match?.[1] ?? null;
			}
		}
		return null;
	}

	/**
	 * Checks if a word boundary matches at a specific position in text.
	 * Ensures the word is surrounded by non-word characters to avoid partial matches.
	 * @private
	 * @param {string} text - The text to search
	 * @param {number} index - The position to check
	 * @param {string} word - The word to match (case-insensitive)
	 * @returns {boolean} True if the word matches with proper boundaries
	 */
	_matchesWord(text, index, word) {
		return (
			text.slice(index, index + word.length).toUpperCase() === word &&
			!this._isWordChar(text[index - 1]) &&
			!this._isWordChar(text[index + word.length])
		);
	}

	/**
	 * Checks if a character is part of a word (letter, digit, or underscore).
	 * @private
	 * @param {string} char - The character to test
	 * @returns {boolean} True if the character is a word character
	 */
	_isWordChar(char) {
		return /[A-Za-z0-9_]/.test(char || "");
	}

	/**
	 * Advances an index past any whitespace characters.
	 * @private
	 * @param {string} text - The text being scanned
	 * @param {number} index - The starting index
	 * @returns {number} The index of the first non-whitespace character
	 */
	_skipWhitespace(text, index) {
		let nextIndex = index;
		while (/\s/.test(text[nextIndex] || "")) {
			nextIndex++;
		}
		return nextIndex;
	}

	/**
	 * Updates generic type mappings based on the root SObject type in the query.
	 * Called when the query changes to reflect the selected FROM object.
	 * @private
	 */
	_syncOutputTypeMappings() {
		const nextOutputTypeValue = this._extractRootObjectName(this._queryDraft);
		if (!nextOutputTypeValue || nextOutputTypeValue === this._outputTypeValue) {
			return;
		}
		this._outputTypeValue = nextOutputTypeValue;
		for (const typeName of OUTPUT_TYPE_MAPPINGS) {
			this._dispatchGenericTypeMapping(typeName, nextOutputTypeValue);
		}
	}
}
