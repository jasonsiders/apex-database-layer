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

function normalizeTypeName(typeName, objectType) {
	const normalized = String(typeName ?? "")
		.trim()
		.toLowerCase();

	if (objectType || ["sobject", "record", "apex"].includes(normalized)) {
		return "SObject";
	}

	if (
		["string", "text", "textarea", "picklist", "multipicklist", "id", "email", "phone", "url"].includes(normalized)
	) {
		return "String";
	}

	if (["datetime", "date/time"].includes(normalized)) {
		return "DateTime";
	}

	if (normalized === "date") {
		return "Date";
	}

	if (normalized === "time") {
		return "Time";
	}

	if (normalized === "boolean") {
		return "Boolean";
	}

	if (["decimal", "double", "currency", "integer", "int", "long", "number"].includes(normalized)) {
		return "Decimal";
	}

	return typeName ?? null;
}

function isCollection(value) {
	return value === true || value === "true";
}

function getResourceTypeName(resourceOption) {
	return normalizeTypeName(
		resourceOption?.dataType ?? resourceOption?.valueDataType ?? resourceOption?.type,
		resourceOption?.parentObjectType ? null : resourceOption?.objectType
	);
}

function isComplexResource(resourceOption) {
	return getResourceTypeName(resourceOption) === "SObject" && !isCollection(resourceOption?.isCollection);
}

function isResourceCompatible(resourceOption, variableTypeName, variableIsCollection) {
	const resourceTypeName = getResourceTypeName(resourceOption);
	const bindTypeName = normalizeTypeName(variableTypeName);

	if (isCollection(resourceOption?.isCollection) !== isCollection(variableIsCollection)) {
		return false;
	}

	if (!bindTypeName) {
		return false;
	}

	if (!resourceTypeName) {
		return resourceOption?.category === "recordFields" && bindTypeName !== "SObject";
	}

	return resourceTypeName === bindTypeName;
}

function shouldShowDrillableResource(resourceOption, variableTypeName, variableIsCollection) {
	const bindTypeName = normalizeTypeName(variableTypeName);
	return bindTypeName !== "SObject" && !isCollection(variableIsCollection) && isComplexResource(resourceOption);
}

export default class SoqlBindInput extends LightningElement {
	/** Zero-based row index used when emitting bind row changes. */
	@api index;

	/** Current bind variable definition for this row. */
	@api variable = {};

	/** Flow resource options available to the value picker. */
	@api resourceOptions = [];

	/** Validation message to display against the bind name input. */
	@api errorMessage;

	/** Picklist options for bind variable type selection. */
	typeOptions = TYPE_OPTIONS;

	/** Bind variable name. */
	get key() {
		return this.variable?.key ?? "";
	}

	/** Literal or Flow resource value assigned to the bind variable. */
	get textValue() {
		return this.variable?.textValue ?? null;
	}

	/** Selected bind type metadata, defaulting to Text. */
	get selectedType() {
		const { typeName, isCollection: selectedIsCollection } = this.variable ?? {};
		return (
			TYPES.find((t) => t.typeName === typeName && t.isCollection === (selectedIsCollection ?? false)) ?? TYPES[8]
		);
	}

	/** Combobox value representing the selected bind type. */
	get typeValue() {
		return this.selectedType.label;
	}

	/** Normalized data type used by the Flow resource picker. */
	get fieldDataType() {
		return normalizeTypeName(this.selectedType.typeName);
	}

	/** Resource options compatible with the selected bind type. */
	get filteredResourceOptions() {
		return (this.resourceOptions ?? [])
			.filter(
				(resourceOption) =>
					isResourceCompatible(resourceOption, this.selectedType.typeName, this.selectedType.isCollection) ||
					shouldShowDrillableResource(
						resourceOption,
						this.selectedType.typeName,
						this.selectedType.isCollection
					)
			)
			.map((resourceOption) =>
				shouldShowDrillableResource(resourceOption, this.selectedType.typeName, this.selectedType.isCollection)
					? { ...resourceOption, isDrillable: true, isSelectable: false }
					: resourceOption
			);
	}

	/**
	 * Applies the current row-level validation message.
	 * @param {string} [errorMessage=this.errorMessage] Message to display.
	 * @param {{ report?: boolean }} [options={}] Whether to report validity immediately.
	 * @returns {boolean} True when the row has no validation error.
	 */
	@api validate(errorMessage = this.errorMessage, { report = true } = {}) {
		this.errorMessage = errorMessage ?? null;
		this._applyKeyValidity(report);
		return !this.errorMessage;
	}

	/** Reapplies validation after render so the native input stays in sync. */
	renderedCallback() {
		this._applyKeyValidity(false);
	}

	/** Emits a bind row patch when the bind name changes. */
	handleKeyChange(event) {
		this.validate(null, { report: false });
		this._emitChange({ key: event.target.value });
	}

	/** Emits a bind row patch when the bind value changes. */
	handleValueChange(event) {
		this._emitChange({ textValue: event.detail.value });
	}

	/** Emits a bind row patch when the bind type changes. */
	handleTypeChange(event) {
		const match = TYPES.find((t) => t.label === event.detail.value);
		if (match) {
			this._emitChange({ typeName: match.typeName, isCollection: match.isCollection });
		}
	}

	/** Requests removal of this bind row. */
	handleRemove() {
		this.dispatchEvent(new CustomEvent("remove", { detail: { index: this.index } }));
	}

	/** Applies custom validity to the bind name input. */
	_applyKeyValidity(report) {
		const keyInput = this.template.querySelector('[data-id="key"]');
		if (!keyInput) {
			return;
		}

		keyInput.setCustomValidity(this.errorMessage ?? "");
		if (report) {
			keyInput.reportValidity();
		}
	}

	/** Dispatches a partial bind row update to the property editor. */
	_emitChange(patch) {
		this.dispatchEvent(
			new CustomEvent("change", {
				detail: { index: this.index, patch }
			})
		);
	}
}
