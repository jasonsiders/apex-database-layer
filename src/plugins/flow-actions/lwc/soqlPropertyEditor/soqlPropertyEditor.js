import { LightningElement, api } from "lwc";
import validateQuery from "@salesforce/apex/InvocableSoql.validateQuery";

/** Regular expression for validating bind variable names. */
const BIND_KEY_PATTERN = /^[A-Za-z_][A-Za-z0-9_]*$/;
/** Custom property editor event names emitted to Flow Builder. */
const EVENTS = {
	genericTypeMappingChanged: "configuration_editor_generic_type_mapping_changed",
	valueChanged: "configuration_editor_input_value_changed",
	valueDeleted: "configuration_editor_input_value_deleted"
};
/** Flow action input variable names. */
const INPUTS = {
	binds: "binds",
	query: "query"
};
/** Flow data type used when dispatching Apex-defined bind variables. */
const BIND_DATA_TYPE = "Apex";
/** Typed Apex-defined BindVariable value fields by selected bind type. */
const BIND_VALUE_FIELDS = {
	Boolean: { collection: "booleanValues", scalar: "booleanValue" },
	Date: { collection: "dateValues", scalar: "dateValue" },
	Datetime: { collection: "datetimeValues", scalar: "datetimeValue" },
	Decimal: { collection: "decimalValues", scalar: "decimalValue" },
	String: { collection: "textValues", scalar: "textValue" },
	Time: { collection: "timeValues", scalar: "timeValue" }
};
/** Error message displayed when a bind variable name is invalid. */
const INVALID_BIND_KEY_MESSAGE =
	"Bind variable names can contain only letters, numbers, and underscores, and must start with a letter or underscore.";
/** Generic type mapping names for SOQL action output types. */
const OUTPUT_TYPE_MAPPINGS = ["U__allResults", "U__firstResult"];

/**
 * Custom property editor for SOQL queries with bind variable support.
 * Provides syntax highlighting, bind variable management, and Apex-side query validation.
 * Emits configuration_editor_input_value_changed and configuration_editor_generic_type_mapping_changed events.
 */
export default class SoqlPropertyEditor extends LightningElement {
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
	 * Output variables supplied by Flow Builder for the selected action.
	 * Used to populate generic type mappings for output fields.
	 */
	@api outputVariables = [];

	/** Bind variables in draft state while the editor is open. */
	_bindsDraft = [];
	/** Guards against re-initialization if inputVariables is set more than once. */
	_bindsInitialized = false;
	/** Validation error messages keyed by bind row index. */
	_bindValidationErrors = {};
	/** Backing store for the builderContext @api property. */
	_builderContext = {};
	/** Backing store for the genericTypeMappings @api property. */
	_genericTypeMappings = [];
	/** Whether the parent has called validate() at least once, enabling live revalidation on edit. */
	_hasValidatedBinds = false;
	/** Backing store for the inputVariables @api property. */
	_inputVariables = [];
	/** SObject type extracted from the FROM clause and mirrored to the generic type mappings. */
	_outputTypeValue = null;
	/** SOQL query text currently in the editor. */
	_queryDraft = "";
	/** Apex-reported validation error message; null when valid. */
	_queryError = null;
	/** Guards against re-initialization if inputVariables is set more than once. */
	_queryInitialized = false;
	/** Success message shown after Apex validates the query; null until validated or if failed. */
	_querySuccess = null;

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
	 * CSS class for the query input form element, includes error styling if validation failed.
	 * @returns {string} CSS class names
	 */
	get formElementClass() {
		return this._queryError ? "slds-form-element slds-has-error" : "slds-form-element";
	}

	/**
	 * Whether the editor has any bind variables defined.
	 * @returns {boolean} True if bind variables exist
	 */
	get hasBinds() {
		return this._bindsDraft.length > 0;
	}

	/**
	 * Current query validation error message from Apex, or null if valid.
	 * @returns {string|null} Error message
	 */
	get queryError() {
		return this._queryError;
	}

	/**
	 * Placeholder text for the SOQL query editor.
	 * @returns {string} Example SOQL query
	 */
	get queryPlaceholder() {
		return "ex., SELECT Id, Name FROM Account WHERE Id = :recordId...";
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
		if (event?.detail?.patch) {
			const index = Number(event.detail.index);
			const updated = this._bindsDraft.map((b, i) => (i === index ? { ...b, ...event.detail.patch } : b));
			this._applyBindsUpdate(updated);
		}
	}

	/**
	 * Removes a bind variable row by index.
	 * @param {CustomEvent} event - Contains index of the row to remove
	 */
	handleBindRemove(event) {
		const removeIndex = Number(event.detail.index);
		if (!Number.isNaN(removeIndex)) {
			this._applyBindsUpdate(this._bindsDraft.filter((_, i) => i !== removeIndex));
		}
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
		this._hasValidatedBinds = true;
		const localErrors = this._validateLocalInputs({ report: true });
		if (localErrors.length) {
			this._querySuccess = null;
			return localErrors;
		}
		const apexErrors = await this._validateApexQuery();
		this._querySuccess = apexErrors.length ? null : "✓ Valid";
		return apexErrors;
	}

	/**
	 * Validates local input metadata for Flow Builder.
	 * @returns {Array<{ key: string, errorString: string }>} Flow validation errors.
	 */
	@api validate() {
		this._hasValidatedBinds = true;
		const localErrors = this._validateLocalInputs({ report: true });
		if (localErrors.length) {
			this._querySuccess = null;
		}
		return localErrors;
	}

	/**
	 * Updates the bind variables list, notifies parent, and revalidates.
	 * @private
	 * @param {Array} updated - The updated bind variable array
	 */
	_applyBindsUpdate(updated) {
		this._bindsDraft = updated;
		this._querySuccess = null;
		this._queryError = null;
		this._dispatchBindsChange(updated);
		this._syncBindValidationStateAfterInput();
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
	 * Builds validation errors for bind variables.
	 * @private
	 * @param {Set<string>} referencedNames Set of bind names referenced in the query
	 * @param {Map<string, number>} bindKeyCounts Count of each bind key
	 * @returns {{ errorsByIndex: Object, errors: Array }} Error mapping and array
	 */
	_buildBindErrors(referencedNames, bindKeyCounts) {
		const errorsByIndex = {};
		const errors = [];
		this._bindsDraft.forEach((bind, index) => {
			const key = String(bind?.key ?? "");
			const errorString = key && this._validateBindKey(key, bindKeyCounts, referencedNames);
			if (errorString) {
				errorsByIndex[index] = errorString;
				errors.push({ key: INPUTS.binds, errorString });
			}
		});
		return { errorsByIndex, errors };
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
		return Array.isArray(binds) ? binds.map((bind) => this._normalizeBindForEditor(bind)) : [];
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
	 * Notifies parent of bind variable changes.
	 * @private
	 * @param {Array} binds - The updated bind variables
	 */
	_dispatchBindsChange(binds) {
		const value = binds.length ? JSON.stringify(this._toApexBinds(binds)) : null;
		this._dispatchChange(INPUTS.binds, value, BIND_DATA_TYPE);
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
		const eventName = value == null ? EVENTS.valueDeleted : EVENTS.valueChanged;
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
	 * Notifies parent of generic type mapping changes (output object types).
	 * Called when the FROM clause object is identified in the query.
	 * @private
	 * @param {string} typeName - The generic type name (e.g., "U__allResults")
	 * @param {string} typeValue - The SObject type (e.g., "Account")
	 */
	_dispatchGenericTypeMapping(typeName, typeValue) {
		const detail = { typeName, typeValue };
		this.dispatchEvent(
			new CustomEvent(EVENTS.genericTypeMappingChanged, {
				bubbles: true,
				cancelable: false,
				composed: true,
				detail
			})
		);
	}

	/**
	 * Escapes HTML special characters in text.
	 * @private
	 * @param {string} text - Text to escape
	 * @returns {string} Escaped text safe for HTML
	 */
	_escapeHtml(text) {
		return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
	}

	/**
	 * Extracts all bind variable reference names from a SOQL query.
	 * Bind references are identified by the `:name` pattern outside of quoted strings.
	 * @param {string} query SOQL query string
	 * @returns {Set<string>} Set of bind variable names referenced in the query
	 * @private
	 */
	_extractBindReferenceNames(query) {
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
	 * Extracts the object name immediately after a FROM keyword.
	 * @private
	 * @param {string} text - The SOQL query text
	 * @param {number} fromIndex - The index of the FROM keyword
	 * @returns {string|null} The object name, or null if not found
	 */
	_extractObjectNameAfterFROM(text, fromIndex) {
		const objectNameStart = this._skipWhitespace(text, fromIndex + "FROM".length);
		return text.slice(objectNameStart).match(/^([A-Za-z_][A-Za-z0-9_]*)\b/)?.[1] ?? null;
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
			const inQuote = !!quote;
			if (inQuote && char === "\\" && index + 1 < text.length) {
				index++;
			} else if (inQuote && char === quote) {
				quote = null;
			} else if (!inQuote && (char === "'" || char === '"')) {
				quote = char;
			} else if (!inQuote && char === "(") {
				depth++;
			} else if (!inQuote && char === ")") {
				depth = Math.max(depth - 1, 0);
			} else if (!inQuote && depth === 0 && this._matchesWord(text, index, "FROM")) {
				return this._extractObjectNameAfterFROM(text, index);
			}
		}
		return null;
	}

	/**
	 * Applies syntax highlighting to SOQL query text.
	 * Highlights strings, bind references, functions, date functions, and keywords with CSS classes.
	 * @private
	 * @param {string} text - SOQL query text to highlight
	 * @returns {string} HTML with syntax highlighting spans
	 */
	_highlight(text) {
		const escaped = this._escapeHtml(text);
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
	 * Loads the initial bind variables from inputVariables, only runs once on first set.
	 * @private
	 */
	_initBinds() {
		if (!this._bindsInitialized) {
			const rawBinds = this._readInputValue(this._inputVariables, INPUTS.binds);
			this._bindsDraft = this._cloneBinds(rawBinds);
			this._bindsInitialized = true;
		}
	}

	/**
	 * Loads the initial SOQL query from inputVariables, only runs once on first set.
	 * @private
	 */
	_initQuery() {
		if (!this._queryInitialized) {
			this._queryDraft = this._readInputValue(this._inputVariables, INPUTS.query) ?? "";
			this._queryInitialized = true;
		}
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
	 * Masks quoted string content to avoid matching keywords or bind references within string literals.
	 * Preserves the position of text for accurate pattern matching.
	 * @param {string} query SOQL query string
	 * @returns {string} Query with quoted content replaced by spaces
	 * @private
	 */
	_maskQuotedText(query) {
		const text = query || "";
		let result = "";
		let quote = null;

		for (let index = 0; index < text.length; index++) {
			const char = text[index];
			const inQuote = !!quote;
			if (inQuote && char === "\\" && index + 1 < text.length) {
				result += "  ";
				index++;
			} else if (inQuote && char === quote) {
				result += " ";
				quote = null;
			} else if (inQuote) {
				result += " ";
			} else if (char === "'" || char === '"') {
				quote = char;
				result += " ";
			} else {
				result += char;
			}
		}

		return result;
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
	 * Converts a user-entered scalar bind value to the matching Apex-defined property value.
	 * Returns undefined when the value should remain in textValue for Apex fallback parsing.
	 * @private
	 * @param {string} typeName Selected Apex type name
	 * @param {*} value User-entered value or Flow reference
	 * @returns {*|undefined} Coerced value, null, or undefined for fallback
	 */
	_coerceScalarBindValue(typeName, value) {
		if (this._isFlowReference(value)) {
			return value;
		}
		if (typeName === "String") {
			return value ?? "";
		}
		if (value === undefined || value === null || value === "") {
			return null;
		}

		const text = String(value);
		if (typeName === "Boolean") {
			if (/^true$/i.test(text)) return true;
			if (/^false$/i.test(text)) return false;
			return undefined;
		}
		if (typeName === "Decimal") {
			const numeric = Number(text);
			return Number.isFinite(numeric) ? numeric : undefined;
		}
		if (["Date", "Datetime", "Time"].includes(typeName)) {
			return text;
		}
		return undefined;
	}

	/**
	 * Converts a collection bind value to the matching Apex-defined property value.
	 * References are kept as Flow expressions; literal collections must be JSON arrays.
	 * @private
	 * @param {*} value User-entered value or Flow reference
	 * @returns {Array|string|undefined} Array literal, Flow reference, or undefined for fallback
	 */
	_coerceCollectionBindValue(value) {
		if (this._isFlowReference(value)) {
			return value;
		}
		if (value === undefined || value === null || value === "") {
			return [];
		}
		try {
			const parsed = JSON.parse(value);
			return Array.isArray(parsed) ? parsed : undefined;
		} catch {
			return undefined;
		}
	}

	/**
	 * Returns the BindVariable property that stores the current bind value.
	 * @private
	 * @param {string} typeName Selected Apex type name
	 * @param {boolean} isCollection Whether the bind is a collection
	 * @returns {string|undefined} BindVariable property name
	 */
	_getBindValueField(typeName, isCollection) {
		const fields = BIND_VALUE_FIELDS[typeName];
		return fields?.[isCollection ? "collection" : "scalar"];
	}

	/**
	 * Detects complete Flow resource reference syntax.
	 * @private
	 * @param {*} value Value to test
	 * @returns {boolean} True when value is a Flow reference expression
	 */
	_isFlowReference(value) {
		return typeof value === "string" && value.startsWith("{!") && value.endsWith("}");
	}

	/**
	 * Normalizes a BindVariable from Flow into the row shape used by the editor UI.
	 * @private
	 * @param {Object} bind BindVariable-like object from Flow
	 * @returns {Object} Bind row state
	 */
	_normalizeBindForEditor(bind) {
		const typeName = bind?.typeName ?? "String";
		const isCollection = bind?.isCollection === true || bind?.isCollection === "true";
		return {
			...bind,
			key: bind?.key ?? "",
			typeName,
			isCollection,
			textValue: this._readBindDisplayValue(bind, typeName, isCollection)
		};
	}

	/**
	 * Reads the editable display value from either the generic text fallback or the typed Apex field.
	 * @private
	 * @param {Object} bind BindVariable-like object from Flow
	 * @param {string} typeName Selected Apex type name
	 * @param {boolean} isCollection Whether the bind is a collection
	 * @returns {*} Value to pass to c-flow-combobox
	 */
	_readBindDisplayValue(bind, typeName, isCollection) {
		const typedField = this._getBindValueField(typeName, isCollection);
		const typedValue = bind?.[typedField];
		if (typedValue !== undefined && typedValue !== null) {
			return Array.isArray(typedValue) ? JSON.stringify(typedValue) : typedValue;
		}
		return bind?.textValue ?? "";
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
	 * Re-validates bind variables if validation has already been run by parent.
	 * Used to update validation errors as the user edits without reporting to browser.
	 * @private
	 */
	_syncBindValidationStateAfterInput() {
		if (this._hasValidatedBinds) {
			this._validateLocalInputs({ report: false });
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
	 * Updates generic type mappings based on the root SObject type in the query.
	 * Called when the query changes to reflect the selected FROM object.
	 * @private
	 */
	_syncOutputTypeMappings() {
		const nextOutputTypeValue = this._extractRootObjectName(this._queryDraft);
		if (nextOutputTypeValue && nextOutputTypeValue !== this._outputTypeValue) {
			this._outputTypeValue = nextOutputTypeValue;
			for (const typeName of OUTPUT_TYPE_MAPPINGS) {
				this._dispatchGenericTypeMapping(typeName, nextOutputTypeValue);
			}
		}
	}

	/**
	 * Converts editor bind rows to Apex-defined BindVariable payloads for Flow Builder.
	 * @private
	 * @param {Array<Object>} binds Editor bind rows
	 * @returns {Array<Object>} Apex-defined BindVariable payloads
	 */
	_toApexBinds(binds) {
		return (binds ?? []).map((bind) => this._toApexBind(bind));
	}

	/**
	 * Converts one editor bind row to an Apex-defined BindVariable payload.
	 * @private
	 * @param {Object} bind Editor bind row
	 * @returns {Object} Apex-defined BindVariable payload
	 */
	_toApexBind(bind) {
		const typeName = bind?.typeName ?? "String";
		const isCollection = bind?.isCollection === true;
		const value = bind?.textValue ?? "";
		const typedField = this._getBindValueField(typeName, isCollection);
		const typedValue = isCollection
			? this._coerceCollectionBindValue(value)
			: this._coerceScalarBindValue(typeName, value);
		const output = {
			key: bind?.key ?? "",
			typeName,
			isCollection
		};

		if (typedField && typedValue !== undefined) {
			output[typedField] = typedValue;
		} else {
			output.textValue = value;
		}
		return output;
	}

	/**
	 * Converts editor bind rows to the metadata-only payload needed for Apex query validation.
	 * Runtime Flow references are intentionally omitted because LWC Apex calls cannot resolve them.
	 * @private
	 * @param {Array<Object>} binds Editor bind rows
	 * @returns {Array<Object>} BindVariable metadata payloads
	 */
	_toValidationBinds(binds) {
		return (binds ?? []).map((bind) => ({
			key: bind?.key ?? "",
			typeName: bind?.typeName ?? "String",
			isCollection: bind?.isCollection === true
		}));
	}

	/**
	 * Updates the query draft and notifies parent of changes.
	 * @private
	 * @param {string} value - The new query text
	 */
	_updateQuery(value) {
		this._queryDraft = value || "";
		this._queryError = null;
		this._querySuccess = null;
		this._dispatchChange(INPUTS.query, this._queryDraft || null, "String");
	}

	/**
	 * Validates the SOQL query through Apex.
	 * @private
	 * @returns {Promise<Array<{ key: string, errorString: string }>>} Query validation errors
	 */
	async _validateApexQuery() {
		try {
			await validateQuery({
				queryToValidate: this._queryDraft,
				binds: this._toValidationBinds(this._bindsDraft)
			});
			this._queryError = null;
			return [];
		} catch (error) {
			const fullMessage = error?.body?.message ?? "";
			// Soql.cls appends the offending query on a new line
			const errorString = fullMessage.split("\n")[0];
			this._queryError = `Error: ${errorString}`;
			return [{ key: INPUTS.query, errorString }];
		}
	}

	/**
	 * Validates a bind variable key against naming rules and query usage.
	 * @param {string} key Bind variable name to validate
	 * @param {Map<string, number>} bindKeyCounts Count of each bind key (for duplicate detection)
	 * @param {Set<string>} referencedNames Set of bind names referenced in the query
	 * @returns {string|null} Validation error message, or null if valid
	 * @private
	 */
	_validateBindKey(key, bindKeyCounts, referencedNames) {
		if (!BIND_KEY_PATTERN.test(key)) {
			return INVALID_BIND_KEY_MESSAGE;
		}
		if (bindKeyCounts.get(key) > 1) {
			return `Bind variable "${key}" is already defined.`;
		}
		if (!referencedNames.has(key)) {
			return `Bind variable "${key}" is not referenced by the query.`;
		}
		return null;
	}

	/**
	 * Validates bind names against query references and row-level naming rules.
	 * @param {{ report?: boolean }} [options={}] Whether to report validity immediately.
	 * @returns {Array<{ key: string, errorString: string }>} Flow validation errors.
	 */
	_validateBindReferences({ report = true } = {}) {
		const referencedNames = this._extractBindReferenceNames(this._queryDraft);
		const bindKeyCounts = this._countBindKeys();
		const { errorsByIndex, errors } = this._buildBindErrors(referencedNames, bindKeyCounts);
		this._bindValidationErrors = errorsByIndex;
		this._applyBindValidationErrors(report);
		return errors;
	}

	/**
	 * Validates all synchronous metadata rules that Flow Builder can use to block saving.
	 * Apex query validation remains async and is only run from the explicit Validate button.
	 * @param {{ report?: boolean }} [options={}] Whether to report child validity immediately.
	 * @returns {Array<{ key: string, errorString: string }>} Flow validation errors.
	 * @private
	 */
	_validateLocalInputs({ report = true } = {}) {
		const bindErrors = this._validateBindReferences({ report });
		if (bindErrors.length) {
			this._queryError = null;
			return bindErrors;
		}

		const missingBindErrors = this._validateMissingBindReferences();
		if (missingBindErrors.length) {
			this._queryError = `Error: ${missingBindErrors[0].errorString}`;
			return missingBindErrors;
		}

		this._queryError = null;
		return [];
	}

	/**
	 * Validates that every bind reference in the query has a matching bind row.
	 * @returns {Array<{ key: string, errorString: string }>} Query-level validation errors.
	 * @private
	 */
	_validateMissingBindReferences() {
		const referencedNames = this._extractBindReferenceNames(this._queryDraft);
		const definedNames = new Set(this._bindsDraft.map((bind) => String(bind?.key ?? "")).filter(Boolean));

		return [...referencedNames]
			.filter((name) => !definedNames.has(name))
			.map((name) => ({
				key: INPUTS.query,
				errorString: `Bind variable "${name}" is referenced by the query but is not defined.`
			}));
	}
}
