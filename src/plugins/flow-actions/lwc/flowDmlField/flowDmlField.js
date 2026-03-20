import { LightningElement, api } from "lwc";

function normalizeTextValue(value) {
	if (value === undefined || value === null) {
		return "";
	}

	if (Array.isArray(value)) {
		return value.join(", ");
	}

	return String(value);
}

function normalizeComparableValue(value) {
	if (value === undefined || value === null) {
		return "";
	}

	return String(value).trim().toLowerCase();
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

function matchesResourceOption(resourceOption, query) {
	const normalizedQuery = normalizeComparableValue(query);

	if (!normalizedQuery) {
		return true;
	}

	return [resourceOption.label, resourceOption.pillLabel, resourceOption.referenceName, resourceOption.displayLabel]
		.filter(Boolean)
		.some((candidate) => candidate.toLowerCase().includes(normalizedQuery));
}

function deriveCategoryKey(resourceOption) {
	if (resourceOption.category) {
		return resourceOption.category;
	}

	if (resourceOption.referenceName?.startsWith("$GlobalConstant.")) {
		return "globalConstants";
	}

	if (resourceOption.objectType && resourceOption.isCollection) {
		return "recordCollections";
	}

	if (resourceOption.objectType) {
		return "recordVariables";
	}

	if (resourceOption.label?.startsWith("Formula:")) {
		return "formulas";
	}

	if (resourceOption.label?.startsWith("Constant:")) {
		return "constants";
	}

	return "variables";
}

function deriveGroupLabel(categoryKey) {
	const labelByCategory = {
		recordVariables: "Record Variables",
		recordCollections: "Record Collections",
		globalVariables: "Global Variables",
		globalConstants: "Global Constants",
		variables: "Variables",
		formulas: "Formulas",
		constants: "Constants"
	};

	if (labelByCategory[categoryKey]) {
		return labelByCategory[categoryKey];
	}

	if (typeof categoryKey === "string" && categoryKey) {
		return categoryKey
			.replace(/([a-z0-9])([A-Z])/g, "$1 $2")
			.replace(/[_-]+/g, " ")
			.replace(/\b\w/g, (character) => character.toUpperCase());
	}

	return "Resources";
}

function deriveDisplayLabel(resourceOption) {
	if (resourceOption.displayLabel) {
		return resourceOption.displayLabel;
	}

	if (resourceOption.referenceName?.startsWith("$GlobalConstant.")) {
		return resourceOption.label?.split(": ").slice(1).join(": ") || resourceOption.referenceName.split(".").pop();
	}

	return resourceOption.pillLabel ?? resourceOption.referenceName ?? resourceOption.label ?? "";
}

function deriveIconName(resourceOption, categoryKey) {
	if (resourceOption.dataType === "Boolean" || resourceOption.valueDataType === "Boolean") {
		return "utility:toggle";
	}

	if (categoryKey === "recordVariables") {
		return "utility:sobject";
	}

	if (categoryKey === "recordCollections") {
		return "utility:table";
	}

	if (categoryKey === "formulas") {
		return "utility:formula";
	}

	return "utility:merge_field";
}

function normalizeLiteralOptionValue(inputType, optionValue) {
	if (inputType === "boolean") {
		return optionValue === true || optionValue === "true";
	}

	return optionValue;
}

function matchesLiteralOptionByValue(option, value) {
	return option.value === value || option.rawValue === value;
}

function matchesLiteralOptionByText(option, text) {
	const normalizedText = normalizeComparableValue(text);

	if (!normalizedText) {
		return false;
	}

	return [option.displayLabel, option.rawValue, option.value]
		.map((candidate) => normalizeComparableValue(candidate))
		.filter(Boolean)
		.includes(normalizedText);
}

export default class FlowDmlField extends LightningElement {
	@api name;
	@api label;
	@api helpText;
	@api errorMessage;
	_value;
	@api valueDataType = "String";
	@api fieldDataType = "String";
	@api required = false;
	@api included;
	@api defaultValue;
	@api options = [];
	@api inputType = "text";
	@api placeholder;
	@api resourceOptions = [];

	_draftTextValue = null;
	_isResourcePickerOpen = false;

	@api
	get value() {
		return this._value;
	}

	set value(nextValue) {
		this._value = nextValue;

		this._draftTextValue = null;
		this._setResourcePickerOpen(false);
	}

	get isIncluded() {
		return this.required || this.included === true || this.included === "true";
	}

	get allowsLiteralChoices() {
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
		return (
			this.selectedResource?.displayLabel ?? this.selectedResource?.pillLabel ?? this.selectedResourceName ?? ""
		);
	}

	get typeMarker() {
		return "Aa";
	}

	get literalOptions() {
		if (!this.allowsLiteralChoices) {
			return [];
		}

		return (this.options || []).map((option, index) => {
			const value = normalizeLiteralOptionValue(this.inputType, option.value);

			return {
				key: `literal-${index}-${String(option.value)}`,
				optionType: "literal",
				categoryKey: "values",
				groupLabel: "Values",
				displayLabel: option.label ?? String(option.value ?? ""),
				label: option.label ?? String(option.value ?? ""),
				rawValue: option.value,
				value,
				valueDataType: this.fieldDataType,
				iconName: "utility:choice"
			};
		});
	}

	get showLiteralOptionsInDropdown() {
		return this.inputType === "picklist";
	}

	get showResourceDropdown() {
		return this.isIncluded && this._isResourcePickerOpen;
	}

	get visibleResourceOptions() {
		const query = this.displayTextValue;

		return (this.resourceOptions || [])
			.filter((resourceOption) => matchesResourceOption(resourceOption, query))
			.map((resourceOption, index) => {
				const categoryKey = deriveCategoryKey(resourceOption);

				return {
					...resourceOption,
					key:
						resourceOption.key ??
						`resource-${resourceOption.referenceName ?? resourceOption.value ?? index}`,
					optionType: "resource",
					categoryKey,
					groupLabel: deriveGroupLabel(categoryKey),
					displayLabel: deriveDisplayLabel(resourceOption),
					iconName: deriveIconName(resourceOption, categoryKey),
					valueDataType: "reference"
				};
			});
	}

	get visibleLiteralOptions() {
		if (!this.showLiteralOptionsInDropdown) {
			return [];
		}

		const query = this.displayTextValue;

		return this.literalOptions.filter((option) => matchesResourceOption(option, query));
	}

	get resourceSections() {
		const sectionOrder = [
			"recordVariables",
			"recordCollections",
			"variables",
			"formulas",
			"constants",
			"globalVariables",
			"globalConstants"
		];
		const sectionsByKey = new Map();

		this.visibleResourceOptions.forEach((resourceOption) => {
			if (!sectionsByKey.has(resourceOption.categoryKey)) {
				sectionsByKey.set(resourceOption.categoryKey, {
					key: resourceOption.categoryKey,
					label: resourceOption.groupLabel,
					options: []
				});
			}

			sectionsByKey.get(resourceOption.categoryKey).options.push(resourceOption);
		});

		const orderedSections = sectionOrder.map((sectionKey) => sectionsByKey.get(sectionKey)).filter(Boolean);
		const remainingSections = [...sectionsByKey.values()].filter((section) => !sectionOrder.includes(section.key));

		return [...orderedSections, ...remainingSections];
	}

	get dropdownSections() {
		const sections = [];

		if (this.visibleLiteralOptions.length) {
			sections.push({
				key: "values",
				label: "Values",
				options: this.visibleLiteralOptions
			});
		}

		return [...sections, ...this.resourceSections];
	}

	get dropdownOptions() {
		return this.dropdownSections.flatMap((section) => section.options);
	}

	get hasVisibleOptions() {
		return this.dropdownOptions.length > 0;
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

	get selectedLiteralOption() {
		if (this.isReferenceValue) {
			return null;
		}

		return this.literalOptions.find((option) => matchesLiteralOptionByValue(option, this.value)) ?? null;
	}

	get displayTextValue() {
		if (this._draftTextValue !== null) {
			return this._draftTextValue;
		}

		if (this.isReferenceValue) {
			return this.selectedResourceLabel;
		}

		if (this.selectedLiteralOption) {
			return this.selectedLiteralOption.displayLabel;
		}

		return this.currentTextValue;
	}

	get defaultDisplayValue() {
		const matchingDefaultLiteral = this.literalOptions.find((option) =>
			matchesLiteralOptionByValue(option, this.defaultValue)
		);

		return matchingDefaultLiteral?.displayLabel ?? normalizeTextValue(this.defaultValue);
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

	get effectivePlaceholder() {
		if (this.placeholder) {
			return this.placeholder;
		}

		return "Enter value or search resources...";
	}

	get controlInputWrapClass() {
		return this.showResourceDropdown
			? "control-input-wrap control-input-wrap_has-menu control-input-wrap_open"
			: "control-input-wrap control-input-wrap_has-menu";
	}

	get resourceTriggerIcon() {
		return "utility:search";
	}

	get dropdownHeaderLabel() {
		if (this.visibleLiteralOptions.length && this.visibleResourceOptions.length) {
			return "All Values and Resources";
		}

		if (this.visibleLiteralOptions.length) {
			return "All Values";
		}

		return "All Resources";
	}

	_setResourcePickerOpen(isOpen) {
		this._isResourcePickerOpen = isOpen;
		this.classList.toggle("resource-picker-open", isOpen);
	}

	_emitFieldChange(value, valueDataType) {
		this.dispatchEvent(
			new CustomEvent("fieldchange", {
				bubbles: true,
				composed: true,
				detail: {
					name: this.name,
					value,
					valueDataType
				}
			})
		);
	}

	_emitSelection(option) {
		this._draftTextValue = option.displayLabel;
		this._setResourcePickerOpen(false);
		this._emitFieldChange(option.value, option.valueDataType);
	}

	_findLiteralOptionByText(text) {
		return this.literalOptions.find((option) => matchesLiteralOptionByText(option, text)) ?? null;
	}

	handleTextFocus() {
		this._setResourcePickerOpen(true);
	}

	handleTextInput(event) {
		this._draftTextValue = event.target.value;
		this._setResourcePickerOpen(true);
	}

	handleTextChange(event) {
		const nextTextValue = event.target.value;
		const matchingLiteralOption = this._findLiteralOptionByText(nextTextValue);

		if (matchingLiteralOption) {
			this._emitSelection(matchingLiteralOption);
			return;
		}

		if (this.inputType === "boolean") {
			this._draftTextValue = null;
			this._setResourcePickerOpen(false);

			if (nextTextValue === "") {
				this._emitFieldChange(null, this.fieldDataType);
			}

			return;
		}

		this._draftTextValue = nextTextValue;
		this._setResourcePickerOpen(false);
		this._emitFieldChange(nextTextValue, this.fieldDataType);
	}

	handleBlur() {
		this._setResourcePickerOpen(false);
		this.dispatchEvent(
			new CustomEvent("fieldblur", {
				bubbles: true,
				composed: true,
				detail: {
					name: this.name
				}
			})
		);
	}

	handleResourceTriggerClick() {
		this._setResourcePickerOpen(!this._isResourcePickerOpen);

		if (this._isResourcePickerOpen) {
			this.template.querySelector('[data-id="resource-input"]')?.focus();
		}
	}

	handleResourceOptionMouseDown(event) {
		event.preventDefault();
	}

	handleResourceOptionClick(event) {
		const selectedOption =
			this.dropdownOptions.find((option) => option.key === event.currentTarget.dataset.key) ?? null;

		if (!selectedOption) {
			return;
		}

		this._emitSelection(selectedOption);
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
