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
