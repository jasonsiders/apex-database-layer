import { LightningElement, api } from "lwc";
import { normalizeDataType } from "c/flowUtils";

/** List of types available for selection in the component **/
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

/**
 * Input row component for defining SOQL bind variables.
 * Manages bind name, type selection, and value input through a Flow resource combobox.
 * Emits change and remove events to notify the parent property editor of updates.
 *
 * @extends LightningElement
 */
export default class SoqlBindInput extends LightningElement {
	/** Flow Builder context passed through to the value combobox. */
	@api builderContext = {};

	/** Validation message to display against the bind name input. */
	@api errorMessage;

	/** Zero-based row index used when emitting bind row changes. */
	@api index;

	/** Current bind variable definition for this row. */
	@api variable = {};

	/** Picklist options for bind variable type selection. */
	typeOptions = TYPE_OPTIONS;

	/**
	 * Normalized data type used by the Flow resource picker component.
	 * @returns {string} Normalized type (SObject, String, DateTime, Date, Time, Boolean, Decimal)
	 */
	get fieldDataType() {
		return normalizeDataType(this.selectedType.typeName);
	}

	/**
	 * Whether the bind variable represents a collection type.
	 * @returns {boolean} True if the selected type is a collection
	 */
	get fieldIsCollection() {
		return this.selectedType.isCollection;
	}

	/**
	 * Bind variable name extracted from the variable object.
	 * @returns {string} The bind variable key, or empty string if not set
	 */
	get key() {
		return this.variable?.key ?? "";
	}

	/**
	 * Selected bind type metadata including typeName and isCollection.
	 * Defaults to Text type if current type selection is not found.
	 * @returns {Object} Type object with label, typeName, and isCollection properties
	 */
	get selectedType() {
		const { typeName, isCollection: selectedIsCollection } = this.variable ?? {};
		return (
			TYPES.find((t) => t.typeName === typeName && t.isCollection === (selectedIsCollection ?? false)) ?? TYPES[8]
		);
	}

	/**
	 * Literal or Flow resource value assigned to the bind variable.
	 * @returns {*} The bind variable value, or null if not set
	 */
	get textValue() {
		return this.variable?.textValue ?? null;
	}

	/**
	 * Label text for the combobox representing the selected bind type.
	 * @returns {string} The type label (e.g., "Text", "Number (Collection)")
	 */
	get typeValue() {
		return this.selectedType.label;
	}

	/**
	 * Reapplies validation state after component renders.
	 * Ensures the bind name input displays any current validation errors.
	 */
	renderedCallback() {
		this._applyKeyValidity(false);
	}

	/**
	 * Validates the bind variable name and optionally reports validity to the user.
	 * Called by the parent editor and during user input to check for errors.
	 * @param {string} [errorMessage=this.errorMessage] - Validation error message to display. Pass null to clear errors.
	 * @param {Object} [options={}] - Configuration options
	 * @param {boolean} [options.report=true] - If true, immediately report validity to trigger browser validation UI
	 * @returns {boolean} True if validation passed (no error), false if validation failed
	 */
	@api validate(errorMessage = this.errorMessage, { report = true } = {}) {
		this.errorMessage = errorMessage ?? null;
		this._applyKeyValidity(report);
		return !this.errorMessage;
	}

	/**
	 * Handles bind variable name input changes. Clears validation errors on edit
	 * and notifies parent of the new name value.
	 * @param {Event} event - Standard change event from the input element
	 */
	handleKeyChange(event) {
		this.validate(null, { report: false });
		this._emitChange({ key: event.target.value });
	}

	/**
	 * Requests removal of this bind variable row from the parent editor.
	 * Dispatches a 'remove' event with the row's index.
	 */
	handleRemove() {
		this.dispatchEvent(new CustomEvent("remove", { detail: { index: this.index } }));
	}

	/**
	 * Handles bind variable type changes from the type selector.
	 * Updates both the data type (typeName) and collection flag (isCollection).
	 * @param {CustomEvent} event - Custom change event with detail.value containing the selected type label
	 */
	handleTypeChange(event) {
		const match = TYPES.find((t) => t.label === event.detail.value);
		if (match) {
			this._emitChange({ typeName: match.typeName, isCollection: match.isCollection });
		}
	}

	/**
	 * Handles bind variable value changes from the resource combobox.
	 * Notifies parent of the new value selection.
	 * @param {CustomEvent} event - Custom change event with detail.value containing the selected Flow resource value
	 */
	handleValueChange(event) {
		this._emitChange({ textValue: event.detail.value });
	}

	/**
	 * Applies custom validation message to the bind name input and optionally shows validation UI.
	 * @private
	 * @param {boolean} [report=true] - If true, immediately report validity to trigger browser validation UI
	 */
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

	/**
	 * Dispatches a change event to notify the parent editor of a partial row update.
	 * The parent merges the patch with the current variable definition.
	 * @private
	 * @param {Object} patch - Partial bind variable object with one or more properties to update (e.g., {key: "newName"}, {typeName: "String"})
	 */
	_emitChange(patch) {
		this.dispatchEvent(
			new CustomEvent("change", {
				detail: { index: this.index, patch }
			})
		);
	}
}
