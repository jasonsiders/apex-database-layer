import { LightningElement, api } from "lwc";

const TYPES = [
    { label: "Boolean", typeName: "Boolean", isCollection: false },
    { label: "Boolean (Collection)", typeName: "Boolean", isCollection: true },
    { label: "Date", typeName: "Date", isCollection: false },
    { label: "Date (Collection)", typeName: "Date", isCollection: true },
    { label: "Date/Time", typeName: "Datetime", isCollection: false },
    { label: "Date/Time (Collection)", typeName: "Datetime", isCollection: true },
    { label: "Number", typeName: "Decimal", isCollection: false },
    { label: "Number (Collection)", typeName: "Decimal", isCollection: true },
    { label: "Text", typeName: "String", isCollection: false },
    { label: "Text (Collection)", typeName: "String", isCollection: true },
    { label: "Time", typeName: "Time", isCollection: false },
    { label: "Time (Collection)", typeName: "Time", isCollection: true },
    { label: "Record", typeName: "SObject", isCollection: false },
    { label: "Record (Collection)", typeName: "SObject", isCollection: true }
];

const TYPE_OPTIONS = TYPES.map(({ label }) => ({ label, value: label }));

export default class FlowUntypedVariableInput extends LightningElement {
    @api index;
    @api variable = {};
    @api resourceOptions = [];

    typeOptions = TYPE_OPTIONS;

    get key() {
        return this.variable?.key ?? "";
    }

    get textValue() {
        return this.variable?.textValue ?? null;
    }

    get typeValue() {
        const { typeName, isCollection } = this.variable ?? {};
        const match = TYPES.find((t) => t.typeName === typeName && t.isCollection === (isCollection ?? false));
        return match?.label ?? "Text";
    }

    handleKeyChange(event) {
        this._emitChange({ key: event.target.value });
    }

    handleValueChange(event) {
        this._emitChange({ textValue: event.detail.value });
    }

    handleTypeChange(event) {
        const match = TYPES.find((t) => t.label === event.detail.value);
        if (match) {
            this._emitChange({ typeName: match.typeName, isCollection: match.isCollection });
        }
    }

    handleRemove() {
        this.dispatchEvent(new CustomEvent("remove", { detail: { index: this.index } }));
    }

    _emitChange(patch) {
        this.dispatchEvent(
            new CustomEvent("change", {
                detail: { index: this.index, variable: { ...this.variable, ...patch } }
            })
        );
    }
}
