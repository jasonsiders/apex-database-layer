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
		return "utility:record_alt";
	}

	if (categoryKey === "recordCollections") {
		return "utility:multi_picklist";
	}

	if (categoryKey === "formulas") {
		return "utility:formula";
	}

	return "utility:text";
}

function normalizeLiteralOptionValue(inputType, optionValue) {
	if (inputType === "boolean") {
		return optionValue === true || optionValue === "true";
	}

	return optionValue;
}

function deriveLiteralIconName(inputType) {
	if (inputType === "picklist") {
		return "utility:picklist_type";
	}

	if (inputType === "boolean") {
		return "utility:toggle";
	}

	return "utility:choice";
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

export default class FlowCombobox extends LightningElement {
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
	_ignoreNextTextChange = false;
	_ignoreNextResourceClick = false;
	_suppressTextCommitAfterSelection = false;
	_pendingSelection = null;
	_forceLiteralInput = false;
	_focusInputAfterRender = false;
	_focusedOptionKey = null;
	_pendingScrollFocusedOption = false;
	_validationError = null;

	@api
	get value() {
		return this._value;
	}

	set value(nextValue) {
		this._value = nextValue;

		this._draftTextValue = null;
		this._suppressTextCommitAfterSelection = false;
		this._pendingSelection = null;
		this._forceLiteralInput = false;
		this._validationError = null;
		this._setResourcePickerOpen(false);
	}

	@api validate(error) {
		this._validationError = error ?? null;
		return !this._validationError;
	}

	get effectiveErrorMessage() {
		return this._validationError ?? this.errorMessage ?? null;
	}

	get fieldRowClass() {
		return this.effectiveErrorMessage
			? "field-row slds-form-element slds-has-error"
			: "field-row slds-form-element";
	}

	get isIncluded() {
		return this.required || this.included === true || this.included === "true";
	}

	get allowsLiteralChoices() {
		return this.inputType === "picklist";
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

	get decoratedSelectedResource() {
		const selectedResource = this.selectedResource;

		if (!selectedResource) {
			return null;
		}

		const categoryKey = deriveCategoryKey(selectedResource);

		return {
			...selectedResource,
			categoryKey,
			groupLabel: deriveGroupLabel(categoryKey),
			displayLabel: deriveDisplayLabel(selectedResource),
			iconName: deriveIconName(selectedResource, categoryKey)
		};
	}

	get typeMarkerIconName() {
		switch ((this.fieldDataType || '').toLowerCase()) {
			case 'boolean':  return 'utility:toggle';
			case 'date':     return 'utility:event';
			case 'datetime': return 'utility:date_time';
			case 'number':	 return 'utility:number_input';
			case 'integer':	 return 'utility:number_input';
			case 'double':	 return 'utility:number_input';
			case 'currency': return 'utility:number_input';
			case 'sobject':  return 'utility:record_alt';
			default:         return 'utility:text';
		}
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
				iconName: deriveLiteralIconName(this.inputType)
			};
		});
	}

	get showLiteralOptionsInDropdown() {
		return this.inputType === "picklist";
	}

	get activeReferenceSelection() {
		if (this._forceLiteralInput) {
			return null;
		}

		return this._pendingSelection ?? this.decoratedSelectedResource ?? this.selectedLiteralOption ?? null;
	}

	get showSelectedResourcePill() {
		return this.isIncluded && !!this.activeReferenceSelection;
	}

	get showResourceDropdown() {
		return this.isIncluded && !this.showSelectedResourcePill && this._isResourcePickerOpen;
	}

	get hasResourceOptions() {
		return (this.resourceOptions || []).length > 0;
	}

	get visibleResourceOptions() {
		const query = this.displayTextValue;

		return (this.resourceOptions || [])
			.filter((resourceOption) => matchesResourceOption(resourceOption, query))
			.map((resourceOption, index) => {
				const categoryKey = deriveCategoryKey(resourceOption);
				const key =
					resourceOption.key ??
					`resource-${resourceOption.referenceName ?? resourceOption.value ?? index}`;

				return {
					...resourceOption,
					key,
					optionType: "resource",
					categoryKey,
					groupLabel: deriveGroupLabel(categoryKey),
					displayLabel: deriveDisplayLabel(resourceOption),
					iconName: deriveIconName(resourceOption, categoryKey),
					valueDataType: "reference",
					isDrillable: !!resourceOption.objectType,
					isFocused: this._focusedOptionKey === key
				};
			});
	}

	get visibleLiteralOptions() {
		if (!this.showLiteralOptionsInDropdown) {
			return [];
		}

		const query = this.displayTextValue;

		return this.literalOptions
			.filter((option) => matchesResourceOption(option, query))
			.map((option) => ({ ...option, isFocused: this._focusedOptionKey === option.key }));
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
		if (this._forceLiteralInput) {
			return this._draftTextValue ?? "";
		}

		if (this._pendingSelection) {
			return this._pendingSelection.displayLabel;
		}

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

	get resourceComboboxClass() {
		return this.showResourceDropdown
			? "resource-combobox slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open"
			: "resource-combobox slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
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
		if (!isOpen) {
			this._focusedOptionKey = null;
		}
	}

	_syncRenderedInputValue() {
		const input = this.template.querySelector('[data-id="resource-input"]');

		if (input) {
			input.value = this.displayTextValue;
		}
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
		this._value = option.value;
		this._pendingSelection = option;
		this._draftTextValue = null;
		this._forceLiteralInput = false;
		this._suppressTextCommitAfterSelection = true;
		this._setResourcePickerOpen(false);
		this._syncRenderedInputValue();
		this._emitFieldChange(option.value, option.valueDataType);
	}

	_findLiteralOptionByText(text) {
		return this.literalOptions.find((option) => matchesLiteralOptionByText(option, text)) ?? null;
	}

	handleInputKeyDown(event) {
		if (!this.showResourceDropdown) {
			return;
		}

		const options = this.dropdownOptions;

		if (!options.length) {
			return;
		}

		if (event.key === "ArrowDown") {
			event.preventDefault();
			const currentIndex = options.findIndex((o) => o.key === this._focusedOptionKey);
			const nextIndex = currentIndex < options.length - 1 ? currentIndex + 1 : 0;
			this._focusedOptionKey = options[nextIndex].key;
			this._scrollFocusedOptionIntoView();
		} else if (event.key === "ArrowUp") {
			event.preventDefault();
			const currentIndex = options.findIndex((o) => o.key === this._focusedOptionKey);
			if (currentIndex <= 0) {
				this._focusedOptionKey = null;
			} else {
				this._focusedOptionKey = options[currentIndex - 1].key;
				this._scrollFocusedOptionIntoView();
			}
		} else if (event.key === "Enter" && this._focusedOptionKey) {
			event.preventDefault();
			const focusedOption = options.find((o) => o.key === this._focusedOptionKey);
			if (focusedOption) {
				this._emitSelection(focusedOption);
			}
		} else if (event.key === "Escape") {
			this._setResourcePickerOpen(false);
		}
	}

	_scrollFocusedOptionIntoView() {
		// Runs after next render via renderedCallback
		this._pendingScrollFocusedOption = true;
	}

	handleTextFocus() {
		this._setResourcePickerOpen(true);
	}

	handleTextInput(event) {
		if (this._pendingSelection && event.target.value !== this._pendingSelection.displayLabel) {
			this._pendingSelection = null;
		}

		this._focusedOptionKey = null;
		this._forceLiteralInput = false;
		this._suppressTextCommitAfterSelection = false;
		this._draftTextValue = event.target.value;
		this._setResourcePickerOpen(true);
	}

	handleTextChange(event) {
		if (this._pendingSelection && event.target.value === this._pendingSelection.displayLabel) {
			return;
		}

		if (this._suppressTextCommitAfterSelection) {
			return;
		}

		if (this._ignoreNextTextChange) {
			this._ignoreNextTextChange = false;
			return;
		}

		const nextTextValue = event.target.value;
		const matchingLiteralOption = this._findLiteralOptionByText(nextTextValue);

		if (matchingLiteralOption) {
			this._emitSelection(matchingLiteralOption);
			return;
		}

		if (this.allowsLiteralChoices) {
			if (nextTextValue === "") {
				this._draftTextValue = null;
				this._setResourcePickerOpen(false);
				this._emitFieldChange(null, this.fieldDataType);
				return;
			}

			this._draftTextValue = nextTextValue;
			this._setResourcePickerOpen(true);
			return;
		}

		if (this.hasResourceOptions) {
			return;
		}

		this._draftTextValue = nextTextValue;
		this._setResourcePickerOpen(false);
		this._emitFieldChange(nextTextValue, this.fieldDataType);
	}

	handleBlur() {
		if (this.allowsLiteralChoices && this._draftTextValue !== null) {
			const matchingLiteralOption = this._findLiteralOptionByText(this._draftTextValue);

			if (matchingLiteralOption) {
				this._emitSelection(matchingLiteralOption);
			} else if (this._draftTextValue !== "") {
				if (this.inputType === "picklist") {
					this._emitFieldChange(this._draftTextValue, this.fieldDataType);
				} else {
					this._draftTextValue = null;
				}
			}
		}

		if (this.inputType === "text" && this._draftTextValue !== null && !this._suppressTextCommitAfterSelection) {
			this._value = this._draftTextValue;
			this._emitFieldChange(this._draftTextValue, this.fieldDataType);
		}

		this._setResourcePickerOpen(false);
		this._syncRenderedInputValue();
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
		this._ignoreNextTextChange = true;
		this._ignoreNextResourceClick = true;
		this.handleResourceOptionClick(event);
	}

	handleResourceOptionClick(event) {
		if (event.type === "click" && this._ignoreNextResourceClick) {
			this._ignoreNextResourceClick = false;
			return;
		}

		this._ignoreNextTextChange = true;
		const selectedOption =
			this.dropdownOptions.find((option) => option.key === event.currentTarget.dataset.key) ?? null;

		if (!selectedOption) {
			return;
		}

		this._emitSelection(selectedOption);
	}

	renderedCallback() {
		if (this._focusInputAfterRender) {
			this._focusInputAfterRender = false;
			this.template.querySelector('[data-id="resource-input"]')?.focus();
		}

		if (this._pendingScrollFocusedOption) {
			this._pendingScrollFocusedOption = false;
			if (this._focusedOptionKey) {
				this.template
					.querySelector(`[data-key="${this._focusedOptionKey}"]`)
					?.scrollIntoView({ block: "nearest" });
			}
		}
	}

	handleSelectedResourceRemove() {
		this._pendingSelection = null;
		this._forceLiteralInput = true;
		this._draftTextValue = "";
		this._value = null;
		this._suppressTextCommitAfterSelection = false;
		this._focusInputAfterRender = true;
		this._setResourcePickerOpen(false);
		this._emitFieldChange(null, this.fieldDataType);
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

	handleNewResourceClick() {
		this._setResourcePickerOpen(false);
		this.dispatchEvent(new CustomEvent('newresource', { bubbles: true, composed: true }));
	}
}
