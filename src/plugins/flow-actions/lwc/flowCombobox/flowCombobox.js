import { LightningElement, api } from "lwc";
import describeSObjectFields from "@salesforce/apex/InvocableSoql.describeSObjectFields";

const MAX_RELATIONSHIP_DEPTH = 5;
const INVALID_RESOURCE_REFERENCE_MESSAGE = "Enter a valid Flow resource reference.";

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

function normalizeDataType(dataType) {
	const normalized = String(dataType ?? "")
		.trim()
		.toLowerCase();

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

	if (["decimal", "double", "currency", "integer", "int", "long", "number", "percent"].includes(normalized)) {
		return "Decimal";
	}

	if (["sobject", "record", "apex"].includes(normalized)) {
		return "SObject";
	}

	return dataType ?? null;
}

function isCompatibleDataType(resourceDataType, fieldDataType) {
	const source = normalizeDataType(resourceDataType);
	const target = normalizeDataType(fieldDataType);

	return !source || !target || source === target;
}

function isReference(valueDataType, value) {
	return (
		valueDataType === "reference" || (typeof value === "string" && value.startsWith("{!") && value.endsWith("}"))
	);
}

function isReferenceText(value) {
	const trimmed = typeof value === "string" ? value.trim() : "";
	return /^\{![^}]+\}$/.test(trimmed);
}

function allowsRawInputValue(fieldDataType) {
	return ["String", "Decimal", "Date", "DateTime", "Time"].includes(normalizeDataType(fieldDataType));
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

function unwrapReferenceName(value) {
	const trimmed = typeof value === "string" ? value.trim() : "";
	if (!trimmed.startsWith("{!") || !trimmed.endsWith("}")) {
		return null;
	}
	return normalizeReferenceName(trimmed);
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
		recordFields: "Record Fields",
		actionOutputs: "Action Outputs",
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

function deriveTooltip(resourceOption) {
	return (
		resourceOption.value ??
		resourceOption.pillLabel ??
		resourceOption.referenceName ??
		deriveDisplayLabel(resourceOption)
	);
}

function deriveIconName(resourceOption, categoryKey) {
	if (resourceOption.iconName) {
		return resourceOption.iconName;
	}

	if (resourceOption.dataType === "Boolean" || resourceOption.valueDataType === "Boolean") {
		return "utility:toggle";
	}

	if (categoryKey === "recordVariables") {
		return "utility:record_alt";
	}

	if (categoryKey === "recordCollections") {
		return "utility:multi_picklist";
	}

	if (categoryKey === "recordFields") {
		return "utility:text";
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

function isChildResourceOption(resourceOption, parentOption) {
	return (
		resourceOption.parentReferenceName === parentOption.referenceName ||
		(!!parentOption.referenceName && resourceOption.referenceName?.startsWith(`${parentOption.referenceName}.`))
	);
}

function toReferenceValue(referenceName) {
	return referenceName ? `{!${referenceName}}` : "";
}

function referenceNamesMatch(option, referenceName) {
	return (
		option?.value === toReferenceValue(referenceName) ||
		option?.referenceName === referenceName ||
		option?.pillLabel === referenceName
	);
}

function getRelationshipObjectType(field) {
	return field?.relationshipObjectType ?? field?.relationshipObjectTypes?.[0] ?? null;
}

function toDrilldownResource(option) {
	const relationshipReferenceName = option.relationshipReferenceName ?? option.referenceName;
	const relationshipObjectType = option.relationshipObjectType ?? option.objectType;

	return {
		...option,
		value: toReferenceValue(relationshipReferenceName),
		pillLabel: relationshipReferenceName,
		referenceName: relationshipReferenceName,
		objectType: relationshipObjectType,
		relationshipDepth: option.relationshipDepth ?? 0,
		isSelectable: false
	};
}

function dedupeOptionsByReferenceName(options) {
	const seen = new Set();
	const result = [];

	for (const option of options) {
		const key = option?.referenceName ?? option?.value;
		if (!key || seen.has(key)) {
			continue;
		}

		seen.add(key);
		result.push(option);
	}

	return result;
}

export default class FlowCombobox extends LightningElement {
	@api name;
	@api label;
	@api hideLabel = false;
	@api helpText;
	@api errorMessage;
	@api valueDataType = "String";
	@api fieldDataType = "String";
	@api required = false;
	@api included;
	@api defaultValue;
	@api options = [];
	@api inputType = "text";
	@api placeholder;
	@api resourceOptions = [];
	@api typeName = null;
	@api typeValue = null;

	_draftTextValue = null;
	_focusedOptionKey = null;
	_focusInputAfterRender = false;
	_forceLiteralInput = false;
	_ignoreNextResourceClick = false;
	_ignoreNextTextChange = false;
	_isResourcePickerOpen = false;
	_drilldownResource = null;
	_dynamicChildOptionsByParent = {};
	_loadingFieldsByParent = {};
	_pendingScrollFocusedOption = false;
	_pendingSelection = null;
	_suppressTextCommitAfterSelection = false;
	_validationError = null;
	_value;

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
		this._drilldownResource = null;
		this._setResourcePickerOpen(false);
	}

	@api validate(error) {
		this._validationError = error ?? null;
		return !this._validationError;
	}

	get effectiveErrorMessage() {
		return this._validationError ?? this.errorMessage ?? null;
	}

	get showLabel() {
		return !this.hideLabel;
	}

	get fieldRowClass() {
		const base = this.effectiveErrorMessage
			? "field-row slds-form-element slds-has-error"
			: "field-row slds-form-element";
		const labelHidden = this.hideLabel ? " field-row_label-hidden" : "";
		const noToggle = !this.showIncludedToggle ? " field-row_no-toggle" : "";
		return `${base}${labelHidden}${noToggle}`;
	}

	get isIncluded() {
		return this.required || this.included === true || this.included === "true";
	}

	get allowsLiteralChoices() {
		return this.inputType === "picklist";
	}

	get allowsRawInputValue() {
		return allowsRawInputValue(this.fieldDataType);
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

	get selectableResourceOptions() {
		return [
			...(this.resourceOptions || []),
			...Object.values(this._dynamicChildOptionsByParent).flatMap((options) => options)
		];
	}

	get selectedResource() {
		return this.selectableResourceOptions.find(
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
			tooltip: deriveTooltip(selectedResource),
			iconName: deriveIconName(selectedResource, categoryKey)
		};
	}

	get typeMarkerIconName() {
		switch ((this.fieldDataType || "").toLowerCase()) {
			case "boolean":
				return "utility:toggle";
			case "date":
				return "utility:event";
			case "datetime":
				return "utility:date_time";
			case "number":
				return "utility:number_input";
			case "decimal":
				return "utility:number_input";
			case "integer":
				return "utility:number_input";
			case "double":
				return "utility:number_input";
			case "currency":
				return "utility:number_input";
			case "sobject":
				return "utility:record_alt";
			default:
				return "utility:text";
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
				tooltip: option.label ?? String(option.value ?? ""),
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

	get drilldownResourceLabel() {
		return deriveDisplayLabel(this._drilldownResource ?? {});
	}

	get candidateResourceOptions() {
		if (this._drilldownResource) {
			return this._getChildResourceOptions(this._drilldownResource);
		}

		return (this.resourceOptions || []).filter(
			(resourceOption) => !resourceOption.parentReferenceName && resourceOption.category !== "recordFields"
		);
	}

	get visibleResourceOptions() {
		const query = this.displayTextValue;

		return this.candidateResourceOptions
			.filter((resourceOption) => matchesResourceOption(resourceOption, query))
			.map((resourceOption, index) => {
				const categoryKey = deriveCategoryKey(resourceOption);
				const key =
					resourceOption.key ?? `resource-${resourceOption.referenceName ?? resourceOption.value ?? index}`;

				return {
					...resourceOption,
					key,
					optionType: "resource",
					categoryKey,
					groupLabel: deriveGroupLabel(categoryKey),
					displayLabel: deriveDisplayLabel(resourceOption),
					tooltip: deriveTooltip(resourceOption),
					iconName: deriveIconName(resourceOption, categoryKey),
					valueDataType: "reference",
					isDrillable: resourceOption.isDrillable ?? !!resourceOption.objectType,
					isSelectable: resourceOption.isSelectable !== false,
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
			"recordFields",
			"variables",
			"formulas",
			"constants",
			"actionOutputs",
			"globalConstants",
			"globalVariables"
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

		return "Search a field...";
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
		if (this._drilldownResource) {
			return `All Resources > ${this.drilldownResourceLabel}`;
		}

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
			this._drilldownResource = null;
		}
	}

	_syncRenderedInputValue() {
		const input = this._getResourceInput();
		if (input) {
			input.value = this.displayTextValue;
		}
	}

	_getResourceInput() {
		return this.template.querySelector('[data-id="resource-input"]');
	}

	_setInputCustomValidity(message, report = true) {
		const input = this._getResourceInput();
		input?.setCustomValidity?.(message);
		if (report) {
			input?.reportValidity?.();
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
		this._drilldownResource = null;
		this._suppressTextCommitAfterSelection = true;
		this._setResourcePickerOpen(false);
		this._syncRenderedInputValue();
		this._emitFieldChange(option.value, option.valueDataType);
	}

	_toReferenceSelection(option) {
		const categoryKey = deriveCategoryKey(option);
		return {
			...option,
			categoryKey,
			groupLabel: deriveGroupLabel(categoryKey),
			displayLabel: deriveDisplayLabel(option),
			tooltip: deriveTooltip(option),
			iconName: deriveIconName(option, categoryKey),
			valueDataType: "reference",
			isSelectable: option.isSelectable !== false
		};
	}

	_openDrilldown(option) {
		this._drilldownResource = toDrilldownResource(option);
		this._draftTextValue = "";
		this._focusedOptionKey = null;
		this._suppressTextCommitAfterSelection = true;
		this._setResourcePickerOpen(true);
		this._syncRenderedInputValue();
		this._loadDrilldownFields(this._drilldownResource);
	}

	_getChildResourceOptions(parentOption) {
		const staticOptions = (this.resourceOptions || []).filter((resourceOption) =>
			isChildResourceOption(resourceOption, parentOption)
		);
		const dynamicOptions = this._dynamicChildOptionsByParent[parentOption.referenceName] ?? [];
		return dedupeOptionsByReferenceName([...staticOptions, ...dynamicOptions]);
	}

	async _getFieldOptionsForParent(parentOption) {
		await this._loadDrilldownFields(parentOption);
		return this._getChildResourceOptions(parentOption);
	}

	async _loadDrilldownFields(parentOption) {
		if (!parentOption?.objectType || this._dynamicChildOptionsByParent[parentOption.referenceName]) {
			return;
		}

		if (this._loadingFieldsByParent[parentOption.referenceName]) {
			return;
		}

		this._loadingFieldsByParent = {
			...this._loadingFieldsByParent,
			[parentOption.referenceName]: true
		};

		try {
			const fields = await describeSObjectFields({ objectApiName: parentOption.objectType });
			const dynamicOptions = (fields ?? [])
				.map((field) => {
					const referenceName = `${parentOption.referenceName}.${field.name}`;
					const relationshipObjectType = getRelationshipObjectType(field);
					const relationshipDepth = (parentOption.relationshipDepth ?? 0) + 1;
					const relationshipReferenceName = field.relationshipName
						? `${parentOption.referenceName}.${field.relationshipName}`
						: null;
					const isDrillable =
						!!relationshipReferenceName &&
						!!relationshipObjectType &&
						relationshipDepth <= MAX_RELATIONSHIP_DEPTH;

					return {
						label: `Field: ${field.label}`,
						value: toReferenceValue(referenceName),
						pillLabel: referenceName,
						referenceName,
						displayLabel: field.label,
						dataType: field.dataType,
						valueDataType: field.dataType,
						objectType: relationshipObjectType,
						parentObjectType: parentOption.objectType,
						parentReferenceName: parentOption.referenceName,
						relationshipName: field.relationshipName,
						relationshipReferenceName,
						relationshipObjectType,
						relationshipObjectTypes: field.relationshipObjectTypes,
						relationshipDepth,
						isDrillable,
						isCollection: false,
						category: "recordFields"
					};
				})
				.filter((option) => option.isDrillable || isCompatibleDataType(option.dataType, this.fieldDataType));
			this._dynamicChildOptionsByParent = {
				...this._dynamicChildOptionsByParent,
				[parentOption.referenceName]: dynamicOptions
			};
		} catch {
			this._dynamicChildOptionsByParent = {
				...this._dynamicChildOptionsByParent,
				[parentOption.referenceName]: []
			};
		} finally {
			this._loadingFieldsByParent = {
				...this._loadingFieldsByParent,
				[parentOption.referenceName]: false
			};
		}
	}

	async _resolveTypedResourceOption(inputValue) {
		const referenceName = unwrapReferenceName(inputValue);
		if (!referenceName) {
			return null;
		}

		const exactOption = this.selectableResourceOptions.find((option) => referenceNamesMatch(option, referenceName));
		if (
			exactOption &&
			exactOption.isSelectable !== false &&
			isCompatibleDataType(exactOption.dataType ?? exactOption.valueDataType, this.fieldDataType)
		) {
			return this._toReferenceSelection(exactOption);
		}

		const parts = referenceName.split(".").filter(Boolean);
		if (parts.length < 2 || parts.length > MAX_RELATIONSHIP_DEPTH + 2) {
			return null;
		}

		const root = this.resourceOptions.find((option) => referenceNamesMatch(option, parts[0]));
		if (!root?.objectType) {
			return null;
		}

		let parentOption = toDrilldownResource(root);
		let currentReferenceName = parts[0];

		for (let index = 1; index < parts.length; index++) {
			const segment = parts[index];
			const isLastSegment = index === parts.length - 1;
			const childOptions = await this._getFieldOptionsForParent(parentOption);
			const directReferenceName = `${currentReferenceName}.${segment}`;
			const childOption = childOptions.find(
				(option) =>
					option.referenceName === directReferenceName ||
					option.relationshipReferenceName === directReferenceName
			);

			if (!childOption) {
				return null;
			}

			if (isLastSegment) {
				if (
					childOption.referenceName === referenceName &&
					childOption.isSelectable !== false &&
					isCompatibleDataType(childOption.dataType ?? childOption.valueDataType, this.fieldDataType)
				) {
					return this._toReferenceSelection(childOption);
				}
				return null;
			}

			if (childOption.relationshipReferenceName !== directReferenceName || !childOption.isDrillable) {
				return null;
			}

			parentOption = toDrilldownResource(childOption);
			currentReferenceName = directReferenceName;
		}

		return null;
	}

	async _commitTypedReference(inputValue) {
		if (!isReferenceText(inputValue)) {
			return false;
		}

		const selectedOption = await this._resolveTypedResourceOption(inputValue);
		if (!selectedOption) {
			this._draftTextValue = inputValue;
			this._pendingSelection = null;
			this._forceLiteralInput = true;
			this._setInputCustomValidity(INVALID_RESOURCE_REFERENCE_MESSAGE);
			return true;
		}

		this._setInputCustomValidity("");
		this._emitSelection(selectedOption);
		return true;
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
				if (focusedOption.isDrillable && !focusedOption.isSelectable) {
					this._openDrilldown(focusedOption);
				} else if (focusedOption.isSelectable) {
					this._emitSelection(focusedOption);
				}
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

		this._setInputCustomValidity("", false);
		this._focusedOptionKey = null;
		this._suppressTextCommitAfterSelection = false;
		this._draftTextValue = event.target.value;
		this._setResourcePickerOpen(true);
	}

	async handleTextChange(event) {
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
		if (isReferenceText(nextTextValue) && (await this._commitTypedReference(nextTextValue))) {
			return;
		}

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

		if (this.allowsRawInputValue) {
			this._draftTextValue = nextTextValue;
			this._setResourcePickerOpen(false);
			this._emitFieldChange(nextTextValue, this.fieldDataType);
		}
	}

	async handleBlur(event) {
		const nextTextValue = this._draftTextValue ?? event.target.value;
		if (isReferenceText(nextTextValue) && (await this._commitTypedReference(nextTextValue))) {
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
			return;
		}

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

		if (
			!this.allowsLiteralChoices &&
			this.allowsRawInputValue &&
			this._draftTextValue !== null &&
			!this._suppressTextCommitAfterSelection
		) {
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

	handleDropdownHeaderMouseDown(event) {
		event.preventDefault();
	}

	handleDropdownHeaderClick() {
		if (!this._drilldownResource) {
			return;
		}

		this._drilldownResource = null;
		this._draftTextValue = "";
		this._focusedOptionKey = null;
		this._syncRenderedInputValue();
	}

	handleResourceOptionMouseDown(event) {
		event.preventDefault();
		this._ignoreNextTextChange = true;
		this._ignoreNextResourceClick = true;
		this.handleResourceOptionClick(event);
	}

	handleResourceOptionChevronMouseDown(event) {
		event.preventDefault();
		event.stopPropagation();
		this._ignoreNextTextChange = true;
	}

	handleResourceOptionChevronClick(event) {
		event.preventDefault();
		event.stopPropagation();
		this._ignoreNextTextChange = true;

		const selectedOption =
			this.dropdownOptions.find((option) => option.key === event.currentTarget.dataset.key) ?? null;
		if (selectedOption?.isDrillable) {
			this._openDrilldown(selectedOption);
		}
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

		if (selectedOption.isDrillable && !selectedOption.isSelectable) {
			this._openDrilldown(selectedOption);
			return;
		}

		if (!selectedOption.isSelectable) {
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

	handleSelectedResourceEdit() {
		const rawValue = this.activeReferenceSelection?.value ?? this.value ?? "";
		this._pendingSelection = null;
		this._forceLiteralInput = true;
		this._draftTextValue = normalizeTextValue(rawValue);
		this._drilldownResource = null;
		this._suppressTextCommitAfterSelection = false;
		this._focusInputAfterRender = true;
		this._setResourcePickerOpen(false);
	}

	handleSelectedResourceRemoveMouseDown(event) {
		event.preventDefault();
		event.stopPropagation();
	}

	handleSelectedResourceRemove(event) {
		event?.preventDefault();
		event?.stopPropagation();
		this._pendingSelection = null;
		this._forceLiteralInput = true;
		this._draftTextValue = "";
		this._value = null;
		this._drilldownResource = null;
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
		this.dispatchEvent(new CustomEvent("newresource", { bubbles: true, composed: true }));
	}

	// ── SObject type picker ────────────────────────────────────────────────────

	get showTypePicker() {
		return this.fieldDataType?.toLowerCase() === "sobject" && !!this.typeName;
	}

	get showVariablePicker() {
		return this.isIncluded && (!this.showTypePicker || !!this.typeValue);
	}

	get sobjectTypeOptions() {
		const seen = new Set();
		const result = [];
		for (const opt of this.resourceOptions || []) {
			if (opt.objectType && !seen.has(opt.objectType)) {
				seen.add(opt.objectType);
				result.push({ label: opt.objectType, value: opt.objectType });
			}
		}
		return result;
	}

	handleTypeMappingChange(event) {
		this.dispatchEvent(
			new CustomEvent("configuration_editor_generic_type_mapping_changed", {
				bubbles: true,
				composed: true,
				detail: { typeName: this.typeName, typeValue: event.detail.value }
			})
		);
	}
}
