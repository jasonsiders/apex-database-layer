import { LightningElement, api } from 'lwc';

const QUERY = 'query';
const BINDS = 'binds';

export default class InvocableSoqlPropertyEditor extends LightningElement {
    @api inputVariables = [];
    @api outputVariables = [];
    @api genericTypeMappings = [];
    @api resourceOptions = [];

    get bindsValue() {
        return this._inputValue(BINDS);
    }

    get queryValue() {
        return this._inputValue(QUERY);
    }

    @api validate() {
        const errors = [];
        if (!this.queryValue) {
            errors.push({ key: QUERY, errorString: 'Query is required.' });
        }
        return errors;
    }

    handleQueryChange(event) {
        this._dispatchChange(QUERY, event.detail.value, 'String');
    }

    _inputValue(name) {
        return (this.inputVariables ?? []).find((v) => v.name === name)?.value ?? null;
    }

    _dispatchChange(name, value, dataType) {
        const eventName = value == null
            ? 'configuration_editor_input_value_deleted'
            : 'configuration_editor_input_value_changed';
        this.dispatchEvent(
            new CustomEvent(eventName, {
                bubbles: true,
                cancelable: false,
                detail: { name, newValue: value, newValueDataType: dataType }
            })
        );
    }
}
