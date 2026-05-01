import { LightningElement, api } from "lwc";
import validateQuery from "@salesforce/apex/InvocableSoql.validateQuery";

const EVT_VALUE_CHANGED = "configuration_editor_input_value_changed";
const EVT_VALUE_DELETED = "configuration_editor_input_value_deleted";
const EVT_GENERIC_TYPE_MAPPING_CHANGED = "configuration_editor_generic_type_mapping_changed";
const INPUT_VAR_QUERY = "query";
const INPUT_VAR_BINDS = "binds";
const DATA_TYPE_APEX = "Apex";
const DATA_TYPE_STRING = "String";
const OUTPUT_TYPE_MAPPINGS = ["U__allResults", "U__firstResult"];

export default class InvocableSoqlPropertyEditor extends LightningElement {
	@api outputVariables = [];
	@api resourceOptions = [];

	_genericTypeMappings = [];
	_inputVariables = [];
	_queryDraft = "";
	_queryError = null;
	_querySuccess = null;
	_queryInitialized = false;
	_outputTypeValue = null;
	_bindsDraft = [];
	_bindsInitialized = false;

	@api get genericTypeMappings() {
		return this._genericTypeMappings;
	}

	set genericTypeMappings(value) {
		this._genericTypeMappings = Array.isArray(value) ? value : [];
		this._outputTypeValue = this._readOutputTypeValue(this._genericTypeMappings);
	}

	@api get inputVariables() {
		return this._inputVariables;
	}

	set inputVariables(value) {
		this._inputVariables = Array.isArray(value) ? value : [];
		if (!this._queryInitialized) {
			this._queryDraft = this._readInputValue(this._inputVariables, INPUT_VAR_QUERY) ?? "";
			this._queryInitialized = true;
		}
		if (!this._bindsInitialized) {
			this._bindsDraft = this._cloneBinds(this._readInputValue(this._inputVariables, INPUT_VAR_BINDS));
			this._bindsInitialized = true;
		}
	}

	get bindsValue() {
		return this._bindsDraft;
	}

	get decoratedBinds() {
		return this.bindsValue.map((variable, index) => ({ variable, indexKey: String(index) }));
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
		return this.bindsValue.length > 0;
	}

	@api async validate() {
		try {
			const bindKeys = this._bindsDraft.map((b) => b.key);
			await validateQuery({ queryToValidate: this._queryDraft, bindKeys });
			this._queryError = null;
			return [];
		} catch (error) {
			// Note: Soql.cls appends the offending query to the error message on a new line
			// This information is redundant, since the query is displayed in the input element
			const errorString = error?.body?.message?.split("\n")?.[0];
			this._queryError = `Error: ${errorString}`;
			return [{ key: INPUT_VAR_QUERY, errorString }];
		}
	}

	renderedCallback() {
		const textarea = this.template.querySelector(".code-editor");
		if (textarea && document.activeElement !== textarea) {
			textarea.value = this.queryValue;
			this._syncHighlight(this.queryValue);
		}
	}

	handleBindAdd() {
		const updated = [...this.bindsValue, { key: "", textValue: "", typeName: "String", isCollection: false }];
		this._bindsDraft = updated;
		this._dispatchChange(INPUT_VAR_BINDS, updated, DATA_TYPE_APEX);
	}

	handleBindChange(event) {
		if (!event?.detail?.patch) return;
		const updated = this.bindsValue.map((b, i) =>
			i === Number(event.detail.index) ? { ...b, ...event.detail.patch } : b
		);
		this._bindsDraft = updated;
		this._dispatchChange(INPUT_VAR_BINDS, updated, DATA_TYPE_APEX);
	}

	handleBindRemove(event) {
		const updated = this.bindsValue.filter((_, i) => i !== event.detail.index);
		this._bindsDraft = updated;
		this._dispatchChange(INPUT_VAR_BINDS, updated.length ? updated : null, DATA_TYPE_APEX);
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
	}

	async handleValidate() {
		const errors = await this.validate();
		this._querySuccess = errors.length ? null : "✓ Valid";
	}

	_cloneBinds(binds) {
		return Array.isArray(binds) ? binds.map((bind) => ({ ...bind })) : [];
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
		return (genericTypeMappings ?? []).find((mapping) => OUTPUT_TYPE_MAPPINGS.includes(mapping.typeName))
			?.typeValue;
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
				return text.slice(objectNameStart).match(/^([A-Za-z_][A-Za-z0-9_]*)\b/)?.[1] ?? null;
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
