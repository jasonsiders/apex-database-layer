import { LightningElement, api } from 'lwc';

const INPUT_VAR_QUERY = 'query';
const INPUT_VAR_BINDS = 'binds';
const EVT_VALUE_CHANGED = 'configuration_editor_input_value_changed';
const EVT_VALUE_DELETED = 'configuration_editor_input_value_deleted';

export default class InvocableSoqlPropertyEditor extends LightningElement {
    @api inputVariables = [];
    @api outputVariables = [];
    @api genericTypeMappings = [];
    @api resourceOptions = [];

    get bindsValue() {
        return this._inputValue(INPUT_VAR_BINDS) ?? [];
    }

    get queryValue() {
        return this._inputValue(INPUT_VAR_QUERY) ?? '';
    }

    get decoratedBinds() {
        return this.bindsValue.map((variable, index) => ({ variable, indexKey: String(index) }));
    }

    @api validate() {
        const errors = [];
        if (!this.queryValue) {
            errors.push({ key: INPUT_VAR_QUERY, errorString: 'Query is required.' });
        }
        return errors;
    }

    renderedCallback() {
        const textarea = this.template.querySelector('.code-editor');
        if (textarea && document.activeElement !== textarea) {
            textarea.value = this.queryValue;
            this._syncHighlight(this.queryValue);
        }
    }

    handleQueryInput(event) {
        this._syncHighlight(event.target.value);
    }

    handleEditorScroll(event) {
        const pre = this.template.querySelector('.code-highlight');
        if (pre) {
            pre.scrollTop = event.target.scrollTop;
            pre.scrollLeft = event.target.scrollLeft;
        }
    }

    handleQueryChange(event) {
        this._dispatchChange(INPUT_VAR_QUERY, event.target.value || null, 'String');
    }

    handleBindChange(event) {
        const updated = this.bindsValue.map((b, i) => (i === event.detail.index ? event.detail.variable : b));
        this._dispatchChange(INPUT_VAR_BINDS, updated, 'sobject');
    }

    handleBindAdd() {
        const updated = [...this.bindsValue, { key: '', textValue: '', typeName: 'String', isCollection: false }];
        this._dispatchChange(INPUT_VAR_BINDS, updated, 'sobject');
    }

    handleBindRemove(event) {
        const updated = this.bindsValue.filter((_, i) => i !== event.detail.index);
        this._dispatchChange(INPUT_VAR_BINDS, updated.length ? updated : null, 'sobject');
    }

    _inputValue(name) {
        return (this.inputVariables ?? []).find((v) => v.name === name)?.value ?? null;
    }

    _syncHighlight(text) {
        const pre = this.template.querySelector('.code-highlight');
        if (pre) {
            pre.innerHTML = this._highlight(text) + '\n';
        }
    }

    _highlight(text) {
        const escaped = text
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;');
        return escaped.replace(
            /('[^']*')|(\{![^}]+\})|\b(COUNT_DISTINCT|COUNT|SUM|AVG|MIN|MAX|FORMAT|toLabel|convertCurrency|DISTANCE|GEOLOCATION|FIELDS|CALENDAR_YEAR|CALENDAR_MONTH|CALENDAR_QUARTER|DAY_IN_MONTH|DAY_IN_WEEK|DAY_IN_YEAR|DAY_ONLY|FISCAL_MONTH|FISCAL_QUARTER|FISCAL_YEAR|HOUR_IN_DAY|WEEK_IN_MONTH|WEEK_IN_YEAR)\b|\b(LAST_FISCAL_QUARTER|NEXT_FISCAL_QUARTER|THIS_FISCAL_QUARTER|LAST_FISCAL_YEAR|NEXT_FISCAL_YEAR|THIS_FISCAL_YEAR|LAST_N_DAYS|NEXT_N_DAYS|LAST_N_WEEKS|NEXT_N_WEEKS|LAST_N_MONTHS|NEXT_N_MONTHS|LAST_N_QUARTERS|NEXT_N_QUARTERS|LAST_N_YEARS|NEXT_N_YEARS|LAST_90_DAYS|NEXT_90_DAYS|LAST_QUARTER|LAST_MONTH|LAST_WEEK|LAST_YEAR|NEXT_QUARTER|NEXT_MONTH|NEXT_WEEK|NEXT_YEAR|THIS_QUARTER|THIS_MONTH|THIS_WEEK|THIS_YEAR|TODAY|YESTERDAY|TOMORROW)\b|\b(SELECT|FROM|WHERE|AND|OR|NOT|LIKE|IN|INCLUDES|EXCLUDES|AS|WITH|FOR|UPDATE|ORDER|BY|GROUP|HAVING|LIMIT|OFFSET|ASC|DESC|NULLS|FIRST|LAST|NULL|TRUE|FALSE|USING|SCOPE|TYPEOF|WHEN|THEN|ELSE|END|VIEW|REFERENCE|TRACKING|VIEWSTAT)\b/gi,
            (match, str, bind, fn, dt) => {
                if (str !== undefined) return `<span class="hl-str">${match}</span>`;
                if (bind !== undefined) return `<span class="hl-bind">${match}</span>`;
                if (fn !== undefined) return `<span class="hl-fn">${match}</span>`;
                if (dt !== undefined) return `<span class="hl-dt">${match}</span>`;
                return `<span class="hl-kw">${match}</span>`;
            }
        );
    }

    _dispatchChange(name, value, dataType) {
        const eventName = value == null ? EVT_VALUE_DELETED : EVT_VALUE_CHANGED;
        this.dispatchEvent(
            new CustomEvent(eventName, {
                bubbles: true,
                cancelable: false,
                detail: { name, newValue: value, newValueDataType: dataType }
            })
        );
    }
}
