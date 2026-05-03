import { LightningElement, api } from "lwc";
import validateQuery from "@salesforce/apex/InvocableSoql.validateQuery";
import {
	DATA_TYPE_STRING,
	readCollection,
	buildResourceOption,
	readFieldOptions,
	readActionOutputOptions,
	dedupeResourceOptions
} from "./utils";

const EVT_VALUE_CHANGED = "configuration_editor_input_value_changed";
const EVT_VALUE_DELETED = "configuration_editor_input_value_deleted";
const EVT_GENERIC_TYPE_MAPPING_CHANGED = "configuration_editor_generic_type_mapping_changed";
const INPUT_VAR_QUERY = "query";
const INPUT_VAR_BINDS = "binds";
const INPUT_VAR_BINDS_JSON = "bindsJson";
const BIND_KEY_PATTERN = /^[A-Za-z_][A-Za-z0-9_]*$/;
const INVALID_BIND_KEY_MESSAGE =
	"Bind variable names can contain only letters, numbers, and underscores, and must start with a letter or underscore.";
const DUPLICATE_BIND_ERROR_SUFFIX = "is already defined.";
const ORPHANED_BIND_ERROR_SUFFIX = "is not referenced by the query.";
const OUTPUT_TYPE_MAPPINGS = ["U__allResults", "U__firstResult"];
const RESOURCE_COLLECTIONS = [
	{ key: "variables", labelPrefix: "Variable" },
	{ key: "recordVariables", category: "recordVariables", labelPrefix: "Variable", dataType: "SObject" },
	{
		key: "recordCollections",
		category: "recordCollections",
		labelPrefix: "Variable",
		dataType: "SObject",
		isCollection: true
	},
	{ key: "constants", category: "constants", labelPrefix: "Constant" },
	{ key: "formulas", category: "formulas", labelPrefix: "Formula" },
	{ key: "recordLookups", labelPrefix: "Record" },
	{ key: "recordCreates", labelPrefix: "Record" },
	{ key: "recordUpdates", labelPrefix: "Record" }
];

export default class InvocableSoqlPropertyEditor extends LightningElement {
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

	/** Output variables supplied by Flow Builder for the selected action. */
	@api outputVariables = [];

	_builderContext = {};
	_genericTypeMappings = [];
	_inputVariables = [];
	_queryDraft = "";
	_queryError = null;
	_querySuccess = null;
	_queryInitialized = false;
	_outputTypeValue = null;
	_resourceOptions = [];
	_availableResourceOptionsCache = null;
	_bindsDraft = [];
	_bindsInitialized = false;
	_bindValidationErrors = {};
	_hasValidatedBinds = false;

	/** Flow Builder context exposed by the custom property editor contract. */
	@api get builderContext() {
		return this._builderContext;
	}

	set builderContext(value) {
		this._builderContext = value ?? {};
		this._availableResourceOptionsCache = null;
	}

	/** Flow generic type mappings exposed by the custom property editor contract. */
	@api get genericTypeMappings() {
		return this._genericTypeMappings;
	}

	set genericTypeMappings(value) {
		this._genericTypeMappings = Array.isArray(value) ? value : [];
		this._outputTypeValue = this._readOutputTypeValue(this._genericTypeMappings);
	}

	/** Flow action input variables exposed by the custom property editor contract. */
	@api get inputVariables() {
		return this._inputVariables;
	}

	set inputVariables(value) {
		this._inputVariables = Array.isArray(value) ? value : [];
		this._initQuery();
		this._initBinds();
	}

	/** Additional Flow resource options that callers can inject. */
	@api get resourceOptions() {
		return this._resourceOptions;
	}

	set resourceOptions(value) {
		this._resourceOptions = Array.isArray(value) ? value : [];
		this._availableResourceOptionsCache = null;
	}

	get decoratedBinds() {
		return this._bindsDraft.map((variable, index) => ({
			variable,
			indexKey: String(index),
			errorMessage: this._bindValidationErrors[index] ?? null
		}));
	}

	get queryPlaceholder() {
		return "ex., SELECT Id, Name FROM Account WHERE Id = :recordId...";
	}

	get formElementClass() {
		return this._queryError ? "slds-form-element slds-has-error" : "slds-form-element";
	}

	get queryError() {
		return this._queryError;
	}

	get querySuccess() {
		return this._querySuccess;
	}

	get queryValue() {
		return this._queryDraft;
	}

	get hasBinds() {
		return this._bindsDraft.length > 0;
	}

	get availableResourceOptions() {
		this._availableResourceOptionsCache ??= dedupeResourceOptions([
			...this._resourceOptions,
			...this._deriveResourceOptions()
		]);
		return this._availableResourceOptionsCache;
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

	renderedCallback() {
		this._syncEditorContent();
		if (this._hasValidatedBinds) {
			this._applyBindValidationErrors(false);
		}
	}

	handleBindAdd() {
		this._applyBindsUpdate([
			...this._bindsDraft,
			{ key: "", textValue: "", typeName: "String", isCollection: false }
		]);
	}

	handleBindChange(event) {
		if (!event?.detail?.patch) return;
		const index = Number(event.detail.index);
		const updated = this._bindsDraft.map((b, i) => (i === index ? { ...b, ...event.detail.patch } : b));
		this._applyBindsUpdate(updated);
	}

	handleBindRemove(event) {
		const removeIndex = Number(event.detail.index);
		if (Number.isNaN(removeIndex)) return;
		this._applyBindsUpdate(this._bindsDraft.filter((_, i) => i !== removeIndex));
	}

	handleEditorScroll(event) {
		const pre = this.template.querySelector(".code-highlight");
		if (pre) {
			pre.scrollTop = event.target.scrollTop;
			pre.scrollLeft = event.target.scrollLeft;
		}
	}

	handleQueryInput(event) {
		this._updateQuery(event.target.value);
		this._syncOutputTypeMappings();
		this._syncHighlight(this._queryDraft);
		this._syncBindValidationStateAfterInput();
	}

	async handleValidate() {
		const errors = await this.validate();
		this._querySuccess = errors.length ? null : "✓ Valid";
	}

	_applyBindsUpdate(updated) {
		this._bindsDraft = updated;
		this._dispatchBindsChange(updated);
		this._syncBindValidationStateAfterInput();
	}

	_initQuery() {
		if (!this._queryInitialized) {
			this._queryDraft = this._readInputValue(this._inputVariables, INPUT_VAR_QUERY) ?? "";
			this._queryInitialized = true;
		}
	}

	_initBinds() {
		if (!this._bindsInitialized) {
			const rawBinds =
				this._readInputValue(this._inputVariables, INPUT_VAR_BINDS_JSON) ??
				this._readInputValue(this._inputVariables, INPUT_VAR_BINDS);
			this._bindsDraft = this._cloneBinds(rawBinds);
			this._bindsInitialized = true;
		}
	}

	_syncEditorContent() {
		const textarea = this.template.querySelector(".code-editor");
		if (textarea && document.activeElement !== textarea) {
			textarea.value = this.queryValue;
			this._syncHighlight(this.queryValue);
		}
	}

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

	_syncBindValidationStateAfterInput() {
		if (this._hasValidatedBinds) {
			this._validateBindReferences({ report: false });
		}
	}

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

	_applyBindValidationErrors(report) {
		this.template.querySelectorAll("c-soql-bind-input").forEach((bindInput, index) => {
			bindInput.validate?.(this._bindValidationErrors[index] ?? null, { report });
		});
	}

	_dispatchBindsChange(binds) {
		const value = binds.length ? JSON.stringify(binds) : null;
		this._dispatchChange(INPUT_VAR_BINDS_JSON, value, DATA_TYPE_STRING);
		if (this._hasInputVariable(INPUT_VAR_BINDS)) {
			this._dispatchChange(INPUT_VAR_BINDS, null, DATA_TYPE_STRING);
		}
	}

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

	_hasInputVariable(name) {
		return this._inputVariables.some((inputVariable) => inputVariable.name === name);
	}

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

	_readInputValue(inputVariables, name) {
		return (inputVariables ?? []).find((v) => v.name === name)?.value ?? null;
	}

	_readOutputTypeValue(genericTypeMappings) {
		const mapping = (genericTypeMappings ?? []).find((m) => OUTPUT_TYPE_MAPPINGS.includes(m.typeName));
		return mapping?.typeValue;
	}

	_deriveResourceOptions() {
		const options = [];

		for (const collection of RESOURCE_COLLECTIONS) {
			for (const resource of readCollection(this._builderContext, collection.key)) {
				const option = buildResourceOption(resource, collection);
				if (!option) {
					continue;
				}

				options.push(option, ...readFieldOptions(resource, option));
			}
		}

		for (const action of readCollection(this._builderContext, "actionCalls")) {
			options.push(...readActionOutputOptions(action));
		}

		return options;
	}

	_syncHighlight(text) {
		const pre = this.template.querySelector(".code-highlight");
		if (pre) {
			pre.innerHTML = this._highlight(text) + "\n";
		}
	}

	_updateQuery(value) {
		this._queryDraft = value || "";
		this._dispatchChange(INPUT_VAR_QUERY, this._queryDraft || null, DATA_TYPE_STRING);
	}

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

	_matchesWord(text, index, word) {
		return (
			text.slice(index, index + word.length).toUpperCase() === word &&
			!this._isWordChar(text[index - 1]) &&
			!this._isWordChar(text[index + word.length])
		);
	}

	_isWordChar(char) {
		return /[A-Za-z0-9_]/.test(char || "");
	}

	_skipWhitespace(text, index) {
		let nextIndex = index;
		while (/\s/.test(text[nextIndex] || "")) {
			nextIndex++;
		}
		return nextIndex;
	}

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
