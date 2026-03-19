import { LightningElement, api } from "lwc";

function normalizeTextValue(value) {
	if (value === undefined || value === null) {
		return "";
	}

	if (Array.isArray(value)) {
		return value.join(", ");
	}

	return value;
}

function isReference(valueDataType, value) {
	return (
		valueDataType === "reference" || (typeof value === "string" && value.startsWith("{!") && value.endsWith("}"))
	);
}

function normalizeReferenceName(value) {
	if (typeof value !== "string") {
		return null;
	}

	if (value.startsWith("{!") && value.endsWith("}")) {
		return value.slice(2, -1);
	}

	return value;
}

export default class FlowDmlField extends LightningElement {
	@api name;
	@api label;
	@api helpText;
	@api value;
	@api valueDataType = "String";
	@api fieldDataType = "String";
	@api required = false;
	@api included;
	@api defaultValue;
	@api options = [];
	@api inputType = "text";
	@api placeholder;
	@api resourceOptions = [];

	get isIncluded() {
		return this.required || this.included === true || this.included === "true";
	}

	get isPicklist() {
		return this.inputType === "picklist" || this.inputType === "boolean";
	}

	get hasDefaultValue() {
		return this.defaultValue !== undefined && this.defaultValue !== null && this.defaultValue !== "";
	}

	get showIncludedToggle() {
		return !this.required;
	}

	get isReferenceValue() {
		return isReference(this.valueDataType, this.value);
	}

	get selectedResourceName() {
		return normalizeReferenceName(this.value);
	}

	get selectedResource() {
		return (this.resourceOptions || []).find(
			(option) =>
				option.value === this.value ||
				option.referenceName === this.selectedResourceName ||
				option.pillLabel === this.selectedResourceName
		);
	}

	get selectedResourceLabel() {
		return this.selectedResource?.pillLabel ?? this.selectedResourceName ?? "";
	}

	get showLiteralControl() {
		return this.isIncluded && !this.isReferenceValue;
	}

	get showReferencePill() {
		return this.isIncluded && this.isReferenceValue;
	}

	get showResourcePicker() {
		return this.showLiteralControl && (this.resourceOptions || []).length > 0;
	}

	get showDefaultControl() {
		return !this.isIncluded && this.hasDefaultValue;
	}

	get showEmptyState() {
		return !this.isIncluded && !this.hasDefaultValue;
	}

	get currentTextValue() {
		return normalizeTextValue(this.value);
	}

	get currentPicklistValue() {
		if (this.value === true) {
			return "true";
		}

		if (this.value === false) {
			return "false";
		}

		return this.value ?? null;
	}

	get defaultTextValue() {
		return normalizeTextValue(this.defaultValue);
	}

	get defaultPicklistValue() {
		if (this.defaultValue === true) {
			return "true";
		}

		if (this.defaultValue === false) {
			return "false";
		}

		return this.defaultValue ?? null;
	}

	get includedStateLabel() {
		if (this.isIncluded) {
			return "Included";
		}

		if (this.hasDefaultValue) {
			return "Included with Default Value";
		}

		return "Not Included";
	}

	get resourcePickerPlaceholder() {
		return "Reference a flow resource";
	}

	get effectivePlaceholder() {
		if (this.placeholder) {
			return this.placeholder;
		}

		if (this.isPicklist) {
			return "Select a value";
		}

		return "Enter a value";
	}

	handleTextChange(event) {
		this.dispatchEvent(
			new CustomEvent("fieldchange", {
				bubbles: true,
				composed: true,
				detail: {
					name: this.name,
					value: event.target.value,
					valueDataType: this.fieldDataType
				}
			})
		);
	}

	handlePicklistChange(event) {
		const nextValue = this.fieldDataType === "Boolean" ? event.detail.value === "true" : event.detail.value;

		this.dispatchEvent(
			new CustomEvent("fieldchange", {
				bubbles: true,
				composed: true,
				detail: {
					name: this.name,
					value: nextValue,
					valueDataType: this.fieldDataType
				}
			})
		);
	}

	handleResourceChange(event) {
		this.dispatchEvent(
			new CustomEvent("fieldchange", {
				bubbles: true,
				composed: true,
				detail: {
					name: this.name,
					value: event.detail.value,
					valueDataType: "reference"
				}
			})
		);
	}

	handleResourceRemove() {
		this.dispatchEvent(
			new CustomEvent("fieldchange", {
				bubbles: true,
				composed: true,
				detail: {
					name: this.name,
					value: null,
					valueDataType: this.fieldDataType
				}
			})
		);
	}

	handleIncludedChange(event) {
		this.dispatchEvent(
			new CustomEvent("fieldincludedchange", {
				bubbles: true,
				composed: true,
				detail: {
					name: this.name,
					included: event.target.checked
				}
			})
		);
	}
}
