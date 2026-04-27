import { LightningElement, api } from 'lwc';

export default class FlowUntypedVariableInput extends LightningElement {
    @api index;
    @api variable = {};
    @api resourceOptions = [];

    get key() {
        return this.variable?.key ?? '';
    }

    get textValue() {
        return this.variable?.textValue ?? null;
    }

    get typeName() {
        return this.variable?.typeName ?? '';
    }

    get isCollection() {
        return this.variable?.isCollection ?? false;
    }

    handleKeyChange(event) {
        this._emitChange({ key: event.target.value });
    }

    handleValueChange(event) {
        this._emitChange({ textValue: event.detail.value });
    }

    handleTypeNameChange(event) {
        this._emitChange({ typeName: event.target.value });
    }

    handleIsCollectionChange(event) {
        this._emitChange({ isCollection: event.target.checked });
    }

    handleRemove() {
        this.dispatchEvent(new CustomEvent('remove', { detail: { index: this.index } }));
    }

    _emitChange(patch) {
        this.dispatchEvent(
            new CustomEvent('change', {
                detail: { index: this.index, variable: { ...this.variable, ...patch } }
            })
        );
    }
}
