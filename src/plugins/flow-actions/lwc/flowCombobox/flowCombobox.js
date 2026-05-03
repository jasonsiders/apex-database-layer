import { LightningElement, api, wire } from "lwc";
import { getObjectInfos } from "lightning/uiObjectInfoApi";
import {
	readCollection,
	buildResourceOption,
	readFieldOptions,
	readActionOutputOptions,
	toReferenceValue,
	normalizeDataType as normalizeFlowDataType,
	RESOURCE_COLLECTIONS,
	STANDARD_RESOURCE_OPTIONS
} from "c/flowUtils";

const MAX_RELATIONSHIP_DEPTH = 5;
const INVALID_RESOURCE_REFERENCE_MESSAGE = "Enter a valid Flow resource reference.";

/**
 * Combobox component for selecting Flow resources, field references, action outputs, and literal values.
 * Supports hierarchical browsing of SObject field trees, type-aware filtering, and Flow expression validation.
 * Emits `fieldchange` events when the selection changes and `fieldblur` when the field loses focus.
 */
export default class FlowCombobox extends LightningElement {
	// §1 @api properties

	/** Flow Builder context used to derive available resources. */
	@api builderContext = {};

	/** Default value shown when an optional field is excluded. */
	@api defaultValue;

	/** External validation message to display on the field. */
	@api errorMessage;

	/** Expected field data type used to filter resources. */
	@api fieldDataType = "String";

	/** When defined (true/false), filters resources by collection compatibility. */
	@api fieldIsCollection;

	/** Help text displayed by the field label. */
	@api helpText;

	/** Whether to visually hide the field label. */
	@api hideLabel = false;

	/** Whether this optional field is currently included. */
	@api included;

	/** Input flavor used for literal value handling. */
	@api inputType = "text";

	/** Visible label for the input. */
	@api label;

	/** Field name included in emitted change events. */
	@api name;

	/** Literal options for picklist-style inputs. */
	@api options = [];

	/** Placeholder text for the resource input. */
	@api placeholder;

	/** Whether the field must always be included. */
	@api required = false;

	/** Flow resources available for selection. */
	@api resourceOptions = [];

	/** Generic type mapping name used for SObject pickers. */
	@api typeName = null;

	/** Current generic SObject type mapping value. */
	@api typeValue = null;

	/** Current field value exposed to parent components. */
	@api
	get value() {
		return this._value;
	}

	/** Stores a new field value and resets transient input state. */
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

	/** Data type for the current value emitted to Flow Builder. */
	@api valueDataType = "String";

	// §3 private properties

	/** Draft literal text while the input is being edited. */
	_draftTextValue = null;

	/** Current resource whose fields are being browsed. */
	_drilldownResource = null;

	/** Dynamically described child field options keyed by parent reference name. */
	_dynamicChildOptionsByParent = {};

	/** Key of the option currently focused by keyboard navigation. */
	_focusedOptionKey = null;

	/** Whether the text input should be focused after render. */
	_focusInputAfterRender = false;

	/** Whether to show raw text instead of a selected pill. */
	_forceLiteralInput = false;

	/** Whether the next resource click should be ignored after mousedown selection. */
	_ignoreNextResourceClick = false;

	/** Whether the next text change should be ignored after resource interaction. */
	_ignoreNextTextChange = false;

	/** Whether the resource dropdown is open. */
	_isResourcePickerOpen = false;

	/** Loading flags for dynamic field descriptions keyed by parent reference name. */
	_loadingFieldsByParent = {};

	/** Object API names requested through UI API object metadata. */
	_objectApiNamesToDescribe = [];

	/** UI API object metadata cache keyed by object API name. */
	_objectInfoByApiName = {};

	/** UI API object metadata errors keyed by object API name. */
	_objectInfoErrorsByApiName = {};

	/** Pending object metadata resolvers keyed by object API name. */
	_pendingObjectInfoResolvers = {};

	/** Whether the focused option should be scrolled into view after render. */
	_pendingScrollFocusedOption = false;

	/** Pending selected option used before parent state updates the value. */
	_pendingSelection = null;

	/** Whether to suppress text commit triggered by a just-selected resource. */
	_suppressTextCommitAfterSelection = false;

	/** Internal validation message set by this component. */
	_validationError = null;

	/** Current raw value. */
	_value;

	// §4 get/set

	/** Active option rendered as the selected pill. */
	get activeReferenceSelection() {
		if (this._forceLiteralInput) {
			return null;
		}

		return this._pendingSelection ?? this.decoratedSelectedResource ?? this.selectedLiteralOption ?? null;
	}

	/** Consumer-provided and standard Flow global resource options, deduplicated by referenceName. */
	get _allResourceOptions() {
		return this._dedupeOptionsByReferenceName([
			...(this.resourceOptions || []),
			...this._deriveBuilderContextOptions(),
			...STANDARD_RESOURCE_OPTIONS
		]);
	}

	/** Whether the input supports selecting literal choice options. */
	get allowsLiteralChoices() {
		return this.inputType === "picklist";
	}

	/** Whether the input accepts raw text or number-like values. */
	get allowsRawInputValue() {
		return this._allowsRawInputValue(this.fieldDataType);
	}

	/** Resource options available at the current dropdown level. */
	get candidateResourceOptions() {
		if (this._drilldownResource) {
			return this._getChildResourceOptions(this._drilldownResource);
		}

		return this._allResourceOptions
			.filter(
				(resourceOption) => !resourceOption.parentReferenceName && resourceOption.category !== "recordFields"
			)
			.filter((resourceOption) => this._isCandidateVisible(resourceOption))
			.map((resourceOption) => this._decorateCandidate(resourceOption));
	}

	/** CSS class for the input wrapper. */
	get controlInputWrapClass() {
		return this.showResourceDropdown
			? "control-input-wrap control-input-wrap_has-menu control-input-wrap_open"
			: "control-input-wrap control-input-wrap_has-menu";
	}

	/** Current raw value normalized for text input display. */
	get currentTextValue() {
		return this._normalizeTextValue(this.value);
	}

	/** Selected resource with derived labels, icon, and tooltip for rendering. */
	get decoratedSelectedResource() {
		const selectedResource = this.selectedResource;

		if (!selectedResource) {
			return null;
		}

		const categoryKey = this._deriveCategoryKey(selectedResource);

		return {
			...selectedResource,
			categoryKey,
			groupLabel: this._deriveGroupLabel(categoryKey),
			displayLabel: this._deriveDisplayLabel(selectedResource),
			tooltip: this._deriveTooltip(selectedResource),
			iconName: this._deriveIconName(selectedResource, categoryKey)
		};
	}

	/** Display value for the excluded-field default state. */
	get defaultDisplayValue() {
		const matchingDefaultLiteral = this.literalOptions.find((option) =>
			this._matchesLiteralOptionByValue(option, this.defaultValue)
		);

		return matchingDefaultLiteral?.displayLabel ?? this._normalizeTextValue(this.defaultValue);
	}

	/** Text currently displayed in the editable input. */
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

	/** Display label for the current drilldown parent resource. */
	get drilldownResourceLabel() {
		return this._deriveDisplayLabel(this._drilldownResource ?? {});
	}

	/** Header label for the current dropdown level. */
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

	/** Flat list of dropdown options used by keyboard navigation. */
	get dropdownOptions() {
		return this.dropdownSections.flatMap((section) => section.options);
	}

	/** All dropdown sections, including literal values and resources. */
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

	/** Effective validation message from internal or external sources. */
	get effectiveErrorMessage() {
		return this._validationError ?? this.errorMessage ?? null;
	}

	/** Placeholder text with the standard Flow-style fallback. */
	get effectivePlaceholder() {
		if (this.placeholder) {
			return this.placeholder;
		}

		return "Search a field...";
	}

	/** CSS class for the outer field row. */
	get fieldRowClass() {
		const base = this.effectiveErrorMessage
			? "field-row slds-form-element slds-has-error"
			: "field-row slds-form-element";
		const labelHidden = this.hideLabel ? " field-row_label-hidden" : "";
		const noToggle = !this.showIncludedToggle ? " field-row_no-toggle" : "";
		return `${base}${labelHidden}${noToggle}`;
	}

	/** Whether an excluded optional field has a default value to show. */
	get hasDefaultValue() {
		return this.defaultValue !== undefined && this.defaultValue !== null && this.defaultValue !== "";
	}

	/** Whether any resource options were supplied. */
	get hasResourceOptions() {
		return (this.resourceOptions || []).length > 0;
	}

	/** Whether the dropdown has any visible options. */
	get hasVisibleOptions() {
		return this.dropdownOptions.length > 0;
	}

	/** Accessible label for the include toggle state. */
	get includedStateLabel() {
		if (this.isIncluded) {
			return "Included";
		}

		if (this.hasDefaultValue) {
			return "Included with Default Value";
		}

		return "Not Included";
	}

	/** Whether this field is currently included in the Flow input. */
	get isIncluded() {
		return this.required || this.included === true || this.included === "true";
	}

	/** Whether the current value is a Flow resource reference. */
	get isReferenceValue() {
		return this._isReference(this.valueDataType, this.value);
	}

	/** Literal dropdown options derived from configured choices. */
	get literalOptions() {
		if (!this.allowsLiteralChoices) {
			return [];
		}

		return (this.options || []).map((option, index) => {
			const value = this._normalizeLiteralOptionValue(this.inputType, option.value);

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
				iconName: this._deriveLiteralIconName(this.inputType)
			};
		});
	}

	/** Reactive object API names passed to the UI API object metadata wire. */
	get objectApiNamesToDescribe() {
		return this._objectApiNamesToDescribe.length ? this._objectApiNamesToDescribe : undefined;
	}

	/** CSS class for the combobox container. */
	get resourceComboboxClass() {
		return this.showResourceDropdown
			? "resource-combobox slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-is-open"
			: "resource-combobox slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click";
	}

	/** Grouped resource sections rendered in the dropdown. */
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

	/** Icon shown in the resource input trigger. */
	get resourceTriggerIcon() {
		return "utility:search";
	}

	/** Static and dynamically loaded resource options that can be selected. */
	get selectableResourceOptions() {
		return [
			...this._allResourceOptions,
			...Object.values(this._dynamicChildOptionsByParent).flatMap((options) => options)
		];
	}

	/** Selected literal option, if the raw value matches one. */
	get selectedLiteralOption() {
		if (this.isReferenceValue) {
			return null;
		}

		return this.literalOptions.find((option) => this._matchesLiteralOptionByValue(option, this.value)) ?? null;
	}

	/** Currently selected resource option, if the value resolves to one. */
	get selectedResource() {
		return this.selectableResourceOptions.find((option) =>
			this._referenceNamesMatch(option, this.selectedResourceName)
		);
	}

	/** Display label for the currently selected resource. */
	get selectedResourceLabel() {
		return (
			this.selectedResource?.displayLabel ?? this.selectedResource?.pillLabel ?? this.selectedResourceName ?? ""
		);
	}

	/** Current resource reference name without Flow expression braces. */
	get selectedResourceName() {
		return this._normalizeReferenceName(this.value);
	}

	/** Whether to show the excluded-field default value control. */
	get showDefaultControl() {
		return !this.isIncluded && this.hasDefaultValue;
	}

	/** Whether to show the empty excluded-field state. */
	get showEmptyState() {
		return !this.isIncluded && !this.hasDefaultValue;
	}

	/** Whether the optional include toggle should be shown. */
	get showIncludedToggle() {
		return !this.required;
	}

	/** Whether the label should be rendered. */
	get showLabel() {
		return !this.hideLabel;
	}

	/** Whether literal choices should be shown in the dropdown. */
	get showLiteralOptionsInDropdown() {
		return this.inputType === "picklist";
	}

	/** Whether to render the dropdown menu. */
	get showResourceDropdown() {
		return this.isIncluded && !this.showSelectedResourcePill && this._isResourcePickerOpen;
	}

	/** Whether to render the selected value as a pill. */
	get showSelectedResourcePill() {
		return this.isIncluded && !!this.activeReferenceSelection;
	}

	/** Whether the SObject type picker should be shown. */
	get showTypePicker() {
		return this.fieldDataType?.toLowerCase() === "sobject" && !!this.typeName;
	}

	/** Whether the resource picker should be shown after generic type selection. */
	get showVariablePicker() {
		return this.isIncluded && (!this.showTypePicker || !!this.typeValue);
	}

	/** SObject type choices derived from available resource options. */
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

	/** Icon representing the expected field data type. */
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

	/** Literal options visible after filtering by the current input text. */
	get visibleLiteralOptions() {
		if (!this.showLiteralOptionsInDropdown) {
			return [];
		}

		const query = this.displayTextValue;

		return this.literalOptions
			.filter((option) => this._matchesResourceOption(option, query))
			.map((option) => ({ ...option, isFocused: this._focusedOptionKey === option.key }));
	}

	/** Resource options visible after filtering by the current input text. */
	get visibleResourceOptions() {
		const query = this.displayTextValue;

		return this.candidateResourceOptions
			.filter((resourceOption) => this._matchesResourceOption(resourceOption, query))
			.map((resourceOption, index) => {
				const categoryKey = this._deriveCategoryKey(resourceOption);
				const key =
					resourceOption.key ?? `resource-${resourceOption.referenceName ?? resourceOption.value ?? index}`;

				return {
					...resourceOption,
					key,
					optionType: "resource",
					categoryKey,
					groupLabel: this._deriveGroupLabel(categoryKey),
					displayLabel: this._deriveDisplayLabel(resourceOption),
					tooltip: this._deriveTooltip(resourceOption),
					iconName: this._deriveIconName(resourceOption, categoryKey),
					valueDataType: "reference",
					isDrillable: resourceOption.isDrillable ?? !!resourceOption.objectType,
					isSelectable: resourceOption.isSelectable !== false,
					isFocused: this._focusedOptionKey === key
				};
			});
	}

	// §5 lifecycle

	/** Performs post-render focus and focused-option scrolling work. */
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

	// §6 @wire

	/** Receives UI API object metadata for dynamically requested SObjects. */
	@wire(getObjectInfos, { objectApiNames: "$objectApiNamesToDescribe" })
	wiredObjectInfos({ data, error }) {
		if (data?.results) {
			data.results.forEach((objectInfoResult, index) => {
				this._handleObjectInfoResult(this.objectApiNamesToDescribe[index], objectInfoResult);
			});
		}

		if (error) {
			this._handleObjectInfoError(error);
		}
	}

	// §7 event handlers

	/**
	 * Commits pending text input and closes the dropdown when the field loses focus.
	 * Validates Flow references and emits fieldblur event.
	 * @param {FocusEvent} event
	 */
	async handleBlur(event) {
		const nextTextValue = this._draftTextValue ?? event.target.value;
		if (this._isReferenceText(nextTextValue) && (await this._commitTypedReference(nextTextValue))) {
			this._setResourcePickerOpen(false);
			this._syncRenderedInputValue();
			this._dispatchFieldBlur();
			return;
		}

		this._commitBlurLiteralChoices();

		this._commitBlurRawInput();

		this._setResourcePickerOpen(false);
		this._syncRenderedInputValue();
		this._dispatchFieldBlur();
	}

	/**
	 * Navigates back to the root resource list from a drilldown level.
	 */
	handleDropdownHeaderClick() {
		if (!this._drilldownResource) {
			return;
		}

		this._drilldownResource = null;
		this._draftTextValue = "";
		this._focusedOptionKey = null;
		this._syncRenderedInputValue();
	}

	/**
	 * Prevents mousedown on the dropdown header from blurring the input.
	 * @param {MouseEvent} event
	 */
	handleDropdownHeaderMouseDown(event) {
		event.preventDefault();
	}

	/**
	 * Emits fieldincludedchange event when an optional field's included state changes.
	 * @param {Event} event
	 */
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

	/**
	 * Handles keyboard navigation within the resource dropdown.
	 * Arrow keys move focus, Enter selects or drills down, Escape closes the dropdown.
	 * @param {KeyboardEvent} event
	 */
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
			this._focusNextOption(options);
		} else if (event.key === "ArrowUp") {
			event.preventDefault();
			this._focusPrevOption(options);
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

	/**
	 * Emits newresource event to request creation of a new Flow resource.
	 */
	handleNewResourceClick() {
		this._setResourcePickerOpen(false);
		this.dispatchEvent(new CustomEvent("newresource", { bubbles: true, composed: true }));
	}

	/**
	 * Opens a drilldown level to browse child fields of a complex SObject resource.
	 * @param {MouseEvent} event
	 */
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

	/**
	 * Prevents mousedown on the drilldown chevron from selecting the parent option.
	 * @param {MouseEvent} event
	 */
	handleResourceOptionChevronMouseDown(event) {
		event.preventDefault();
		event.stopPropagation();
		this._ignoreNextTextChange = true;
	}

	/**
	 * Selects a resource option or opens drilldown for complex SObject resources.
	 * Emits fieldchange event with the selected value.
	 * @param {MouseEvent|CustomEvent} event
	 */
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

	/**
	 * Handles mousedown on a resource option to select or drill down before blur can occur.
	 * @param {MouseEvent} event
	 */
	handleResourceOptionMouseDown(event) {
		event.preventDefault();
		this._ignoreNextTextChange = true;
		this._ignoreNextResourceClick = true;
		this.handleResourceOptionClick(event);
	}

	/**
	 * Toggles the resource picker dropdown open/closed from the trigger button.
	 */
	handleResourceTriggerClick() {
		this._setResourcePickerOpen(!this._isResourcePickerOpen);
		if (this._isResourcePickerOpen) {
			this.template.querySelector('[data-id="resource-input"]')?.focus();
		}
	}

	/**
	 * Switches from pill display into raw text editing mode.
	 */
	handleSelectedResourceEdit() {
		const rawValue = this.activeReferenceSelection?.value ?? this.value ?? "";
		this._pendingSelection = null;
		this._forceLiteralInput = true;
		this._draftTextValue = this._normalizeTextValue(rawValue);
		this._drilldownResource = null;
		this._suppressTextCommitAfterSelection = false;
		this._focusInputAfterRender = true;
		this._setResourcePickerOpen(false);
	}

	/**
	 * Clears the selected resource and emits a null field value.
	 * @param {MouseEvent} event
	 */
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

	/**
	 * Prevents mousedown on the pill remove button from triggering edit mode or blur.
	 * @param {MouseEvent} event
	 */
	handleSelectedResourceRemoveMouseDown(event) {
		event.preventDefault();
		event.stopPropagation();
	}

	/**
	 * Commits typed text, literal choices, or Flow references when the input value changes.
	 * Validates Flow reference syntax and applies the selection or error message accordingly.
	 * @param {Event} event
	 */
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
		if (this._isReferenceText(nextTextValue) && (await this._commitTypedReference(nextTextValue))) {
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

	/**
	 * Opens the resource picker when the text input receives focus.
	 */
	handleTextFocus() {
		this._setResourcePickerOpen(true);
	}

	/**
	 * Tracks text input edits and filters the dropdown options by matching against the input text.
	 * @param {InputEvent} event
	 */
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

	/**
	 * Emits configuration_editor_generic_type_mapping_changed event when the SObject type selection changes.
	 * @param {CustomEvent} event
	 */
	handleTypeMappingChange(event) {
		this.dispatchEvent(
			new CustomEvent("configuration_editor_generic_type_mapping_changed", {
				bubbles: true,
				composed: true,
				detail: { typeName: this.typeName, typeValue: event.detail.value }
			})
		);
	}

	// §8 public methods

	/**
	 * Applies an internal validation message.
	 * @param {string} error Validation message to display.
	 * @returns {boolean} True when the field has no validation error.
	 */
	@api validate(error) {
		this._validationError = error ?? null;
		return !this._validationError;
	}

	// §9 private methods

	/**
	 * Checks if a field data type allows raw literal input values.
	 * Only String, Decimal, Date, DateTime, and Time types allow raw input.
	 * @private
	 * @param {string} fieldDataType - The field's data type
	 * @returns {boolean} True if raw literal input is allowed
	 */
	_allowsRawInputValue(fieldDataType) {
		return ["String", "Decimal", "Date", "DateTime", "Time"].includes(normalizeFlowDataType(fieldDataType));
	}

	/** Converts UI API object metadata fields into resource picker options. */
	_buildDynamicChildOptions(parentOption, objectInfo) {
		return this._readObjectInfoFields(objectInfo)
			.map((field) => {
				const fieldName = this._readObjectInfoFieldName(field);
				if (!fieldName) {
					return null;
				}

				const referenceName = `${parentOption.referenceName}.${fieldName}`;
				const relationshipObjectTypes = this._readObjectInfoRelationshipObjectTypes(field);
				const relationshipObjectType = this._chooseRelationshipObjectType(relationshipObjectTypes);
				const relationshipDepth = (parentOption.relationshipDepth ?? 0) + 1;
				const relationshipReferenceName = field.relationshipName
					? `${parentOption.referenceName}.${field.relationshipName}`
					: null;
				const isDrillable =
					!!relationshipReferenceName &&
					!!relationshipObjectType &&
					relationshipDepth <= MAX_RELATIONSHIP_DEPTH;
				const dataType = this._normalizeObjectInfoFieldDataType(field.dataType);

				return {
					label: `Field: ${field.label}`,
					value: toReferenceValue(referenceName),
					pillLabel: referenceName,
					referenceName,
					displayLabel: field.label,
					dataType,
					valueDataType: dataType,
					objectType: relationshipObjectType,
					parentObjectType: parentOption.objectType,
					parentReferenceName: parentOption.referenceName,
					relationshipName: field.relationshipName,
					relationshipReferenceName,
					relationshipObjectType,
					relationshipObjectTypes,
					relationshipDepth,
					isDrillable,
					isCollection: false,
					category: "recordFields"
				};
			})
			.filter(Boolean)
			.filter((option) => option.isDrillable || this._isCompatibleDataType(option.dataType, this.fieldDataType));
	}

	/**
	 * Selects the best object type for a polymorphic relationship field,
	 * preferring User for shared ownership fields and excluding Group.
	 * @private
	 * @param {string[]} objectTypes - Candidate object API names from referenceToInfos
	 * @returns {string|null} The chosen object API name, or null if none
	 */
	_chooseRelationshipObjectType(objectTypes) {
		if (!objectTypes?.length) {
			return null;
		}
		if (objectTypes.includes("User")) {
			return "User";
		}
		return objectTypes.find((objectType) => objectType !== "Group") ?? objectTypes[0];
	}

	/** Commits a literal choice selection when the field blurs. */
	_commitBlurLiteralChoices() {
		if (!this.allowsLiteralChoices || this._draftTextValue === null) return;
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

	/** Commits raw text input when the field blurs. */
	_commitBlurRawInput() {
		if (
			this.allowsLiteralChoices ||
			!this.allowsRawInputValue ||
			this._draftTextValue === null ||
			this._suppressTextCommitAfterSelection
		)
			return;
		this._value = this._draftTextValue;
		this._emitFieldChange(this._draftTextValue, this.fieldDataType);
	}

	/** Commits typed Flow reference text or marks it invalid. */
	async _commitTypedReference(inputValue) {
		if (!this._isReferenceText(inputValue)) {
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

	/**
	 * Marks an option as drillable and non-selectable when the field expects a scalar
	 * type but the resource is a complex SObject that can yield matching child fields.
	 * @private
	 * @param {Object} option - The candidate resource option
	 * @returns {Object} The option, possibly decorated with isDrillable/isSelectable overrides
	 */
	_decorateCandidate(option) {
		return this._isDrillableForField(option) ? { ...option, isDrillable: true, isSelectable: false } : option;
	}

	/**
	 * Deduplicates resource options by reference name, keeping the first occurrence.
	 * Used to suppress redundant entries when static and dynamic sources overlap.
	 * @private
	 * @param {Object[]} options - Options to deduplicate
	 * @returns {Object[]} Deduplicated options preserving insertion order
	 */
	_dedupeOptionsByReferenceName(options) {
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

	/**
	 * Builds all resource options derivable from the current builder context,
	 * combining standard collections, record collections, and action outputs.
	 * @private
	 * @returns {Object[]} All resource options derived from context
	 */
	_deriveBuilderContextOptions() {
		const ctx = this.builderContext;
		if (!ctx || !Object.keys(ctx).length) return [];
		const options = [];
		for (const collection of RESOURCE_COLLECTIONS) {
			for (const resource of readCollection(ctx, collection.key)) {
				const option = buildResourceOption(resource, collection);
				if (!option) continue;
				options.push(option, ...readFieldOptions(resource, option));
			}
		}
		for (const action of readCollection(ctx, "actionCalls")) {
			options.push(...readActionOutputOptions(action));
		}
		return options;
	}

	/**
	 * Derives a category key for a resource option for grouping in the dropdown.
	 * Uses option.category if provided, otherwise infers from option properties.
	 * @private
	 * @param {Object} resourceOption - The option to categorize
	 * @returns {string} A category key for grouping (e.g., "variables", "recordFields", "formulas")
	 */
	_deriveCategoryKey(resourceOption) {
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

	/**
	 * Derives a display label for a resource option, prioritizing more specific labels.
	 * @private
	 * @param {Object} resourceOption - The option
	 * @returns {string} The display label
	 */
	_deriveDisplayLabel(resourceOption) {
		if (resourceOption.displayLabel) {
			return resourceOption.displayLabel;
		}
		if (resourceOption.referenceName?.startsWith("$GlobalConstant.")) {
			return (
				resourceOption.label?.split(": ").slice(1).join(": ") || resourceOption.referenceName.split(".").pop()
			);
		}
		return resourceOption.pillLabel ?? resourceOption.referenceName ?? resourceOption.label ?? "";
	}

	/**
	 * Derives a user-friendly group label from a category key.
	 * Converts camelCase or snake_case to Title Case.
	 * @private
	 * @param {string} categoryKey - The category key
	 * @returns {string} The display label for the category
	 */
	_deriveGroupLabel(categoryKey) {
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

	/**
	 * Derives an icon name for a resource option.
	 * Uses option.iconName if provided, otherwise infers from data type.
	 * @private
	 * @param {Object} resourceOption - The option
	 * @param {string} categoryKey - The category key for additional context
	 * @returns {string} An icon name for display (e.g., "utility:toggle", "utility:world")
	 */
	_deriveIconName(resourceOption, categoryKey) {
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

	/**
	 * Derives an icon name for a literal option based on the input type.
	 * @private
	 * @param {string} inputType - The input type (e.g., "text", "boolean", "picklist")
	 * @returns {string} An icon name suitable for the input type
	 */
	_deriveLiteralIconName(inputType) {
		if (inputType === "picklist") {
			return "utility:picklist_type";
		}
		if (inputType === "boolean") {
			return "utility:toggle";
		}
		return "utility:choice";
	}

	/**
	 * Derives a tooltip string for a resource option, prioritizing value or reference name.
	 * @private
	 * @param {Object} resourceOption - The option
	 * @returns {string} Text suitable for a tooltip hover
	 */
	_deriveTooltip(resourceOption) {
		return (
			resourceOption.value ??
			resourceOption.pillLabel ??
			resourceOption.referenceName ??
			this._deriveDisplayLabel(resourceOption)
		);
	}

	/** Dispatches fieldblur event when the field loses focus. */
	_dispatchFieldBlur() {
		this.dispatchEvent(
			new CustomEvent("fieldblur", {
				bubbles: true,
				composed: true,
				detail: { name: this.name }
			})
		);
	}

	/** Emits a field value change event to the parent property editor. */
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

	/** Commits a selected literal or resource option. */
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

	/** Finds a literal option by user-entered display text or value text. */
	_findLiteralOptionByText(text) {
		return this.literalOptions.find((option) => this._matchesLiteralOptionByText(option, text)) ?? null;
	}

	/** Moves focus to the next dropdown option (or wraps to first). */
	_focusNextOption(options) {
		const currentIndex = options.findIndex((o) => o.key === this._focusedOptionKey);
		const nextIndex = currentIndex < options.length - 1 ? currentIndex + 1 : 0;
		this._focusedOptionKey = options[nextIndex].key;
		this._scrollFocusedOptionIntoView();
	}

	/** Moves focus to the previous dropdown option (or clears focus if at start). */
	_focusPrevOption(options) {
		const currentIndex = options.findIndex((o) => o.key === this._focusedOptionKey);
		if (currentIndex <= 0) {
			this._focusedOptionKey = null;
		} else {
			this._focusedOptionKey = options[currentIndex - 1].key;
			this._scrollFocusedOptionIntoView();
		}
	}

	/** Gets statically provided and dynamically loaded child options for a parent. */
	_getChildResourceOptions(parentOption) {
		const staticOptions = this._allResourceOptions.filter((resourceOption) =>
			this._isChildResourceOption(resourceOption, parentOption)
		);
		const dynamicOptions = this._dynamicChildOptionsByParent[parentOption.referenceName] ?? [];
		return this._dedupeOptionsByReferenceName([...staticOptions, ...dynamicOptions]);
	}

	/** Loads and returns child field options for a parent resource. */
	async _getFieldOptionsForParent(parentOption) {
		await this._loadDrilldownFields(parentOption);
		return this._getChildResourceOptions(parentOption);
	}

	/** Returns the native input element used by the resource picker. */
	_getResourceInput() {
		return this.template.querySelector('[data-id="resource-input"]');
	}

	/** Resolves pending object metadata requests with a shared wire error. */
	_handleObjectInfoError(error) {
		this._objectInfoErrorsByApiName = this._objectApiNamesToDescribe.reduce(
			(errorsByApiName, objectApiName) => ({
				...errorsByApiName,
				[objectApiName]: error
			}),
			this._objectInfoErrorsByApiName
		);

		Object.keys(this._pendingObjectInfoResolvers).forEach((objectApiName) => {
			this._resolvePendingObjectInfo(objectApiName, null);
		});
	}

	/** Stores a UI API object metadata result and resolves pending requests. */
	_handleObjectInfoResult(objectApiName, objectInfoResult) {
		if (!objectApiName) {
			return;
		}

		const objectInfo = this._readObjectInfoResult(objectInfoResult);
		if (!objectInfo) {
			this._objectInfoErrorsByApiName = {
				...this._objectInfoErrorsByApiName,
				[objectApiName]: objectInfoResult?.result ?? objectInfoResult ?? true
			};
			this._resolvePendingObjectInfo(objectApiName, null);
			return;
		}

		const { [objectApiName]: _removedError, ...remainingErrors } = this._objectInfoErrorsByApiName;
		this._objectInfoByApiName = {
			...this._objectInfoByApiName,
			[objectApiName]: objectInfo
		};
		this._objectInfoErrorsByApiName = remainingErrors;
		this._resolvePendingObjectInfo(objectApiName, objectInfo);
	}

	/**
	 * Determines whether a resource option should appear in the dropdown.
	 * Passes options that match field type/collection exactly, or are drillable SObjects
	 * that can yield a matching scalar field.
	 * @private
	 * @param {Object} option - The resource option to evaluate
	 * @returns {boolean} True if the option is a valid candidate for the current field
	 */
	_isCandidateVisible(option) {
		if (this.fieldIsCollection === undefined || this.fieldIsCollection === null) return true;
		return this._isCompatibleWithField(option) || this._isDrillableForField(option);
	}

	/**
	 * Checks if a resource option is a child property of a parent option.
	 * Child options have a parentReferenceName or start with the parent's referenceName.
	 * @private
	 * @param {Object} resourceOption - The potentially child option
	 * @param {Object} parentOption - The potential parent option
	 * @returns {boolean} True if resourceOption is a child of parentOption
	 */
	_isChildResourceOption(resourceOption, parentOption) {
		return (
			resourceOption.parentReferenceName === parentOption.referenceName ||
			(!!parentOption.referenceName && resourceOption.referenceName?.startsWith(`${parentOption.referenceName}.`))
		);
	}

	/**
	 * Checks if a resource data type is compatible with the expected field data type.
	 * Types are compatible if normalized to the same value (case-insensitive).
	 * @private
	 * @param {string} resourceDataType - The resource's data type
	 * @param {string} fieldDataType - The field's expected data type
	 * @returns {boolean} True if types are compatible or either is missing
	 */
	_isCompatibleDataType(resourceDataType, fieldDataType) {
		const source = normalizeFlowDataType(resourceDataType);
		const target = normalizeFlowDataType(fieldDataType);
		return !source || !target || source === target;
	}

	/**
	 * Checks if a resource option matches the expected field data type and collection setting exactly.
	 * @private
	 * @param {Object} option - The resource option to check
	 * @returns {boolean} True if the resource matches type and collection requirements
	 */
	_isCompatibleWithField(option) {
		const resourceType = normalizeFlowDataType(option.dataType ?? option.valueDataType ?? option.type);
		const fieldType = normalizeFlowDataType(this.fieldDataType);
		const targetIsCollection = this.fieldIsCollection === true || this.fieldIsCollection === "true";
		const resourceIsCollection = option.isCollection === true || option.isCollection === "true";
		if (resourceIsCollection !== targetIsCollection) return false;
		if (!fieldType) return false;
		if (!resourceType) return option.category === "recordFields" && fieldType !== "SObject";
		return resourceType === fieldType;
	}

	/**
	 * Checks if a non-collection SObject resource can be drilled into to find a
	 * scalar field matching the expected type. Excludes collections and SObject targets.
	 * @private
	 * @param {Object} option - The resource option to check
	 * @returns {boolean} True if the resource is drillable to reach a compatible field
	 */
	_isDrillableForField(option) {
		const fieldType = normalizeFlowDataType(this.fieldDataType);
		const targetIsCollection = this.fieldIsCollection === true || this.fieldIsCollection === "true";
		const resourceType = normalizeFlowDataType(option.dataType ?? option.valueDataType);
		const resourceIsCollection = option.isCollection === true || option.isCollection === "true";
		return fieldType !== "SObject" && !targetIsCollection && resourceType === "SObject" && !resourceIsCollection;
	}

	/**
	 * Checks if a value represents a Flow resource reference.
	 * A reference either has valueDataType="reference" or is wrapped in {!...}.
	 * @private
	 * @param {string} valueDataType - The declared data type
	 * @param {*} value - The value to check
	 * @returns {boolean} True if value is a Flow reference
	 */
	_isReference(valueDataType, value) {
		return (
			valueDataType === "reference" ||
			(typeof value === "string" && value.startsWith("{!") && value.endsWith("}"))
		);
	}

	/**
	 * Checks if a string is a valid Flow reference text ({!...}).
	 * @private
	 * @param {*} value - The value to check
	 * @returns {boolean} True if value matches Flow reference syntax
	 */
	_isReferenceText(value) {
		const trimmed = typeof value === "string" ? value.trim() : "";
		return /^\{![^}]+\}$/.test(trimmed);
	}

	/** Loads UI API SObject fields for a drilldown parent when they are not cached. */
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
			const objectInfo = await this._requestObjectInfo(parentOption.objectType);
			const dynamicOptions = objectInfo ? this._buildDynamicChildOptions(parentOption, objectInfo) : [];
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

	/**
	 * Checks if a literal option matches a search text across display fields.
	 * @private
	 * @param {Object} option - The literal option
	 * @param {string} text - The search text
	 * @returns {boolean} True if the option matches the text
	 */
	_matchesLiteralOptionByText(option, text) {
		const normalizedText = this._normalizeComparableValue(text);
		if (!normalizedText) {
			return false;
		}
		return [option.displayLabel, option.rawValue, option.value]
			.map((candidate) => this._normalizeComparableValue(candidate))
			.filter(Boolean)
			.includes(normalizedText);
	}

	/**
	 * Checks if a literal option matches a value by comparing value and rawValue.
	 * @private
	 * @param {Object} option - The literal option
	 * @param {*} value - The value to match
	 * @returns {boolean} True if the option matches the value
	 */
	_matchesLiteralOptionByValue(option, value) {
		return option.value === value || option.rawValue === value;
	}

	/**
	 * Checks if a resource option matches a search query across multiple searchable fields.
	 * @private
	 * @param {Object} resourceOption - The option to check
	 * @param {string} query - The search query
	 * @returns {boolean} True if the option matches the query or query is empty
	 */
	_matchesResourceOption(resourceOption, query) {
		const normalizedQuery = this._normalizeComparableValue(query);
		if (!normalizedQuery) {
			return true;
		}
		return [
			resourceOption.label,
			resourceOption.pillLabel,
			resourceOption.referenceName,
			resourceOption.displayLabel
		]
			.filter(Boolean)
			.some((candidate) => candidate.toLowerCase().includes(normalizedQuery));
	}

	/**
	 * Normalizes a value to lowercase string for case-insensitive comparison.
	 * @private
	 * @param {*} value - The value to normalize
	 * @returns {string} Trimmed and lowercased string representation
	 */
	_normalizeComparableValue(value) {
		if (value === undefined || value === null) {
			return "";
		}
		return String(value).trim().toLowerCase();
	}

	/**
	 * Normalizes a literal option value for the given input type.
	 * Converts boolean string values to actual booleans.
	 * @private
	 * @param {string} inputType - The input type (e.g., "text", "boolean", "picklist")
	 * @param {*} optionValue - The option value to normalize
	 * @returns {*} The normalized value
	 */
	_normalizeLiteralOptionValue(inputType, optionValue) {
		if (inputType === "boolean") {
			return optionValue === true || optionValue === "true";
		}
		return optionValue;
	}

	/**
	 * Normalizes a data type from UI API object info.
	 * Reference types are converted to String since Flow doesn't use UI API reference types.
	 * @private
	 * @param {string} dataType - The raw data type from UI API
	 * @returns {string|null} The normalized Flow data type
	 */
	_normalizeObjectInfoFieldDataType(dataType) {
		if (String(dataType ?? "").toLowerCase() === "reference") {
			return "String";
		}
		return normalizeFlowDataType(dataType);
	}

	/**
	 * Extracts a reference name from a Flow reference string or returns the string as-is.
	 * Handles {!referenceName} syntax by removing the delimiters.
	 * @private
	 * @param {*} value - The reference text or string
	 * @returns {string|null} The extracted reference name, or null if not a string
	 */
	_normalizeReferenceName(value) {
		if (typeof value !== "string") {
			return null;
		}
		if (value.startsWith("{!") && value.endsWith("}")) {
			return value.slice(2, -1);
		}
		return value;
	}

	/**
	 * Normalizes a value to a string, handling null, undefined, and arrays.
	 * @private
	 * @param {*} value - The value to normalize
	 * @returns {string} Empty string for null/undefined, comma-joined for arrays, String() otherwise
	 */
	_normalizeTextValue(value) {
		if (value === undefined || value === null) {
			return "";
		}
		if (Array.isArray(value)) {
			return value.join(", ");
		}
		return String(value);
	}

	/** Opens a child-resource drilldown level for a complex resource. */
	_openDrilldown(option) {
		this._drilldownResource = this._toDrilldownResource(option);
		this._draftTextValue = "";
		this._focusedOptionKey = null;
		this._suppressTextCommitAfterSelection = true;
		this._setResourcePickerOpen(true);
		this._syncRenderedInputValue();
		this._loadDrilldownFields(this._drilldownResource);
	}

	/**
	 * Reads the API name of a UI API field descriptor, checking multiple properties
	 * because the shape varies between wire adapter versions.
	 * @private
	 * @param {Object} field - The field metadata object
	 * @returns {string|null} The field's API name, or null if not found
	 */
	_readObjectInfoFieldName(field) {
		return field?.apiName ?? field?.name ?? field?.fieldApiName ?? null;
	}

	/**
	 * Normalizes object info fields into an array regardless of whether the fields
	 * property is an array or a keyed object map (shape differs between wire adapters).
	 * @private
	 * @param {Object} objectInfo - The UI API object info
	 * @returns {Object[]} Array of field metadata objects
	 */
	_readObjectInfoFields(objectInfo) {
		const fields = objectInfo?.fields;
		if (Array.isArray(fields)) {
			return fields;
		}
		if (fields && typeof fields === "object") {
			return Object.entries(fields).map(([apiName, field]) => ({ apiName, ...field }));
		}
		return [];
	}

	/**
	 * Extracts the related object types for a relationship field, used to determine
	 * drillable targets for polymorphic lookups.
	 * @private
	 * @param {Object} field - The field metadata object from UI API
	 * @returns {string[]} Array of related object API names
	 */
	_readObjectInfoRelationshipObjectTypes(field) {
		return (field?.referenceToInfos ?? []).map((referenceToInfo) => referenceToInfo?.apiName).filter(Boolean);
	}

	/**
	 * Extracts a usable object info object from a wire result. The wire adapter can
	 * wrap the actual info in a `result` property depending on the adapter version.
	 * @private
	 * @param {Object} objectInfoResult - The raw wire result
	 * @returns {Object|null} The object info with fields, or null if missing
	 */
	_readObjectInfoResult(objectInfoResult) {
		const result = objectInfoResult?.result ?? objectInfoResult;
		return result?.fields ? result : null;
	}

	/**
	 * Checks if an option's reference name matches a given reference name.
	 * Matches against value, referenceName, or pillLabel.
	 * @private
	 * @param {Object} option - The option to check
	 * @param {string} referenceName - The reference name to match
	 * @returns {boolean} True if the option matches the reference name
	 */
	_referenceNamesMatch(option, referenceName) {
		return (
			option?.value === toReferenceValue(referenceName) ||
			option?.referenceName === referenceName ||
			option?.pillLabel === referenceName
		);
	}

	/** Requests object metadata through the reactive UI API wire and waits for it. */
	_requestObjectInfo(objectApiName) {
		if (this._objectInfoByApiName[objectApiName]) {
			return Promise.resolve(this._objectInfoByApiName[objectApiName]);
		}

		if (this._objectInfoErrorsByApiName[objectApiName]) {
			return Promise.resolve(null);
		}

		return new Promise((resolve) => {
			this._pendingObjectInfoResolvers = {
				...this._pendingObjectInfoResolvers,
				[objectApiName]: [...(this._pendingObjectInfoResolvers[objectApiName] ?? []), resolve]
			};

			if (!this._objectApiNamesToDescribe.includes(objectApiName)) {
				this._objectApiNamesToDescribe = [...this._objectApiNamesToDescribe, objectApiName];
			}
		});
	}

	/** Resolves queued promises for an object metadata request. */
	_resolvePendingObjectInfo(objectApiName, objectInfo) {
		const resolvers = this._pendingObjectInfoResolvers[objectApiName] ?? [];
		if (!resolvers.length) {
			return;
		}

		const { [objectApiName]: _removedResolvers, ...remainingResolvers } = this._pendingObjectInfoResolvers;
		this._pendingObjectInfoResolvers = remainingResolvers;
		resolvers.forEach((resolve) => resolve(objectInfo));
	}

	/** Resolves typed Flow reference text into a selectable resource option. */
	async _resolveTypedResourceOption(inputValue) {
		const referenceName = this._unwrapReferenceName(inputValue);
		if (!referenceName) {
			return null;
		}

		const exactOption = this.selectableResourceOptions.find((option) =>
			this._referenceNamesMatch(option, referenceName)
		);
		if (
			exactOption &&
			exactOption.isSelectable !== false &&
			this._isCompatibleDataType(exactOption.dataType ?? exactOption.valueDataType, this.fieldDataType)
		) {
			return this._toReferenceSelection(exactOption);
		}

		const parts = referenceName.split(".").filter(Boolean);
		if (parts.length < 2 || parts.length > MAX_RELATIONSHIP_DEPTH + 2) {
			return null;
		}

		const root = this._allResourceOptions.find((option) => this._referenceNamesMatch(option, parts[0]));
		if (!root?.objectType) {
			return null;
		}

		let parentOption = this._toDrilldownResource(root);
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
					this._isCompatibleDataType(childOption.dataType ?? childOption.valueDataType, this.fieldDataType)
				) {
					return this._toReferenceSelection(childOption);
				}
				return null;
			}

			if (childOption.relationshipReferenceName !== directReferenceName || !childOption.isDrillable) {
				return null;
			}

			parentOption = this._toDrilldownResource(childOption);
			currentReferenceName = directReferenceName;
		}

		return null;
	}

	/** Schedules the focused dropdown option to be scrolled into view. */
	_scrollFocusedOptionIntoView() {
		// Runs after next render via renderedCallback
		this._pendingScrollFocusedOption = true;
	}

	/** Applies custom validity to the native resource input. */
	_setInputCustomValidity(message, report = true) {
		const input = this._getResourceInput();
		input?.setCustomValidity?.(message);
		if (report) {
			input?.reportValidity?.();
		}
	}

	/** Opens or closes the resource picker and resets dropdown navigation state. */
	_setResourcePickerOpen(isOpen) {
		this._isResourcePickerOpen = isOpen;
		this.classList.toggle("resource-picker-open", isOpen);
		if (!isOpen) {
			this._focusedOptionKey = null;
			this._drilldownResource = null;
		}
	}

	/** Syncs the rendered native input value with component display state. */
	_syncRenderedInputValue() {
		const input = this._getResourceInput();
		if (input) {
			input.value = this.displayTextValue;
		}
	}

	/**
	 * Reshapes a resource option into a drilldown parent by substituting the relationship
	 * reference name and object type for the direct field reference.
	 * @private
	 * @param {Object} option - The source resource option
	 * @returns {Object} The reshaped drilldown resource with isSelectable: false
	 */
	_toDrilldownResource(option) {
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

	/** Converts a raw resource option into the decorated selection shape. */
	_toReferenceSelection(option) {
		const categoryKey = this._deriveCategoryKey(option);
		return {
			...option,
			categoryKey,
			groupLabel: this._deriveGroupLabel(categoryKey),
			displayLabel: this._deriveDisplayLabel(option),
			tooltip: this._deriveTooltip(option),
			iconName: this._deriveIconName(option, categoryKey),
			valueDataType: "reference",
			isSelectable: option.isSelectable !== false
		};
	}

	/**
	 * Unwraps a Flow reference string, returning only the reference name inside {!...}.
	 * Returns null if the value is not a properly formatted reference.
	 * @private
	 * @param {*} value - The value to unwrap
	 * @returns {string|null} The reference name without delimiters, or null if not a reference
	 */
	_unwrapReferenceName(value) {
		const trimmed = typeof value === "string" ? value.trim() : "";
		if (!trimmed.startsWith("{!") || !trimmed.endsWith("}")) {
			return null;
		}
		return this._normalizeReferenceName(trimmed);
	}
}
