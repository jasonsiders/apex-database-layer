import { LightningElement, api } from "lwc";
import describeObjectApex from "@salesforce/apex/FlowResourcePickerController.describeObject";
import { filterSections, getChildSections, getRootSections, parseInput, resolveItem } from "c/flowResourceMenu";

const BOOLEAN_CONSTANTS = { false: "$GlobalConstant.False", true: "$GlobalConstant.True" };
const GLOBAL_CONSTANT_PREFIX = "$GlobalConstant.";
const REFERENCE = "reference";
const ROOT_LABEL = "All Resources";

// Shared by every picker on the page, so each object is described once
const DESCRIBES = new Map();

/**
 * @description Describes an object, reusing earlier requests for the same object.
 * @param {String} objectApiName The object to describe
 * @returns {Promise<Object>} The object's describe
 */
function describeObject(objectApiName) {
	if (!DESCRIBES.has(objectApiName)) {
		const request = describeObjectApex({ objectApiName });
		DESCRIBES.set(objectApiName, request);
	}
	return DESCRIBES.get(objectApiName);
}

/**
 * @description The data type Flow Builder expects for a resource. Global constants keep their own type.
 * @param {Object} item The chosen resource
 * @returns {String} The constant's data type, or `reference`
 */
function toValueDataType(item) {
	const isConstant = item.value.startsWith(GLOBAL_CONSTANT_PREFIX);
	return isConstant ? item.dataType : REFERENCE;
}

/**
 * Flow Builder's resource picker, for Custom Property Editors: a combobox that searches the flow's resources, drills
 * into records, action outputs, and global variables, and accepts literal values. Fires `change` with
 * `{ name, value, valueDataType }`, where `valueDataType` is `reference` for resources.
 */
export default class FlowResourcePicker extends LightningElement {
	/**
	 * @description The CPE's `automaticOutputVariables`, for drilling into action outputs
	 * @type {Object}
	 */
	@api automaticOutputVariables;
	/**
	 * @description The CPE's `elementInfo.apiName`, so only resources available at this point in the flow are offered
	 * @type {String}
	 */
	@api elementName;
	/**
	 * @description Shown below the input, from the CPE's `validate()`
	 * @type {String}
	 */
	@api errorMessage;
	/**
	 * @description Shown in an info tooltip beside the label
	 * @type {String}
	 */
	@api helpText;
	/**
	 * @description Whether the input takes a collection; only applies to records
	 * @type {Boolean}
	 */
	@api isCollection = false;
	/**
	 * @description The input's label
	 * @type {String}
	 */
	@api label;
	/**
	 * @description An icon before the label, like Flow Builder shows for action inputs, ex: `utility:text`
	 * @type {String}
	 */
	@api labelIcon;
	/**
	 * @description The input's name, echoed in `change` events
	 * @type {String}
	 */
	@api name;
	/**
	 * @description Restricts record inputs to one object; any object if blank
	 * @type {String}
	 */
	@api objectType;
	/**
	 * @description Literal choices, listed first as "Picklist Values": `[{ label, value }]`
	 * @type {Array}
	 */
	@api picklistValues;
	/**
	 * @description Flow Builder's own placeholder, by default
	 * @type {String}
	 */
	@api placeholder = "Enter value or search resources...";
	/**
	 * @description Marks the label with an asterisk
	 * @type {Boolean}
	 */
	@api required = false;
	/**
	 * @description The Flow data type the input accepts: `String`, `Boolean`, or `SObject`
	 * @type {String}
	 */
	@api type = "String";

	_activeIndex = -1;
	_builderContext;
	_isDirty = false;
	_isEditing = false;
	_isOpen = false;
	_objectLabels = {};
	_requestId = 0;
	_sections = [];
	_selection = null;
	_shouldFocus = false;
	_text = "";
	_trail = [];
	_value;
	_valueDataType;

	// **** LIFECYCLE **** //
	renderedCallback() {
		if (this._shouldFocus) {
			this._shouldFocus = false;
			this.template.querySelector('input[role="combobox"]')?.focus();
		}
	}

	// **** GETTERS **** //
	get activeDescendant() {
		return this._activeIndex >= 0 ? `option-${this._activeIndex}` : null;
	}

	get comboboxClass() {
		const openClass = this._isOpen ? " slds-is-open" : "";
		return "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click" + openClass;
	}

	get context() {
		return {
			automaticOutputVariables: this.automaticOutputVariables,
			builderContext: this._builderContext,
			elementName: this.elementName,
			objectLabels: this._objectLabels
		};
	}

	get crumbs() {
		const root = { index: -1, label: ROOT_LABEL };
		const steps = this._trail.map((step, index) => ({ index, label: step.label }));
		return [root, ...steps];
	}

	get expanded() {
		return String(this._isOpen);
	}

	get formElementClass() {
		const errorClass = this.errorMessage ? " slds-has-error" : "";
		return "slds-form-element" + errorClass;
	}

	get hasCrumbs() {
		return this._trail.length > 0;
	}

	get hasOptions() {
		return this._sections.length > 0;
	}

	get isOpen() {
		return this._isOpen;
	}

	/**
	 * @description The menu's sections, with each option's DOM id, highlight, and checkmark for the current value
	 * @returns {Array} Sections of options, ready for the template
	 */
	get menu() {
		let index = 0;
		return this._sections.map((section) => ({
			...section,
			items: section.items.map((item) => {
				const isActive = index === this._activeIndex;
				const activeClass = isActive ? " slds-has-focus" : "";
				const option = {
					...item,
					domId: `option-${index}`,
					isActive: String(isActive),
					isCurrent: item.value === this._value,
					className:
						"slds-media slds-media_center slds-listbox__option slds-listbox__option_plain" + activeClass
				};
				index++;
				return option;
			})
		}));
	}

	get options() {
		return this._sections.flatMap((section) => section.items);
	}

	get removeLabel() {
		return `Remove ${this._selection?.pathLabel}`;
	}

	get selection() {
		return this._selection;
	}

	get showPill() {
		return Boolean(this._selection) && !this._isEditing;
	}

	get target() {
		return {
			dataType: this.type,
			isCollection: this.isCollection,
			objectType: this.objectType,
			picklistValues: this.picklistValues
		};
	}

	get text() {
		return this._text;
	}

	// **** API SETTERS **** //
	/**
	 * @description The CPE's `builderContext`: the flow's resources
	 * @type {Object}
	 */
	@api
	get builderContext() {
		return this._builderContext;
	}
	set builderContext(value) {
		this._builderContext = value;
		this._loadObjectLabels();
		this._refreshSelection();
	}

	/**
	 * @description The input's current value: a reference path, or a literal
	 * @type {String}
	 */
	@api
	get value() {
		return this._value;
	}
	set value(value) {
		this._value = value;
		this._refreshSelection();
	}

	/**
	 * @description `reference` for resources, else the literal's data type
	 * @type {String}
	 */
	@api
	get valueDataType() {
		return this._valueDataType;
	}
	set valueDataType(value) {
		this._valueDataType = value;
		this._refreshSelection();
	}

	// **** HANDLERS **** //
	/**
	 * @description Climbs back up the drill-down to the clicked step
	 * @param {Event} event Click on a breadcrumb, whose `data-index` is -1 for All Resources
	 */
	handleCrumbClick(event) {
		const index = Number(event.currentTarget.dataset.index);
		const step = this._trail[index];
		this._text = step ? `{!${step.value}.` : "";
		this._shouldFocus = true;
		this._loadMenu();
	}

	/**
	 * @description Opens the menu, like Flow Builder's picker does on focus
	 */
	handleFocus() {
		this._open();
	}

	/**
	 * @description Saves the typed text once focus leaves the whole combobox, not just moves within it
	 * @param {FocusEvent} event The focusout event
	 */
	handleFocusOut(event) {
		const combobox = this.template.querySelector(".slds-combobox");
		if (!combobox?.contains(event.relatedTarget)) {
			this._commitText();
		}
	}

	/**
	 * @description Searches, or drills via typed merge fields, as the user types
	 * @param {Event} event Input on the text field
	 */
	handleInput(event) {
		this._isDirty = true;
		this._text = event.target.value;
		this._isOpen = true;
		this._loadMenu();
	}

	/**
	 * @description Arrow keys move the highlight, Enter chooses it, and Escape closes the menu
	 * @param {KeyboardEvent} event Keydown on the text field
	 */
	handleKeyDown(event) {
		const actions = {
			ArrowDown: () => this._moveActive(1),
			ArrowUp: () => this._moveActive(-1),
			Enter: () => this._chooseActive(),
			Escape: () => this._close()
		};
		const action = actions[event.key];
		if (action) {
			event.preventDefault();
			action();
		}
	}

	/**
	 * @description Keeps focus in the input, so choosing an option doesn't commit the typed text first
	 * @param {MouseEvent} event Mousedown inside the menu
	 */
	handleListMouseDown(event) {
		event.preventDefault();
	}

	/**
	 * @description Selects the clicked option, or drills into it
	 * @param {Event} event Click on an option, whose `data-key` identifies it
	 */
	handleOptionClick(event) {
		const key = event.currentTarget.dataset.key;
		const item = this.options.find((option) => option.key === key);
		this._choose(item);
	}

	/**
	 * @description Edits the pill's reference as a merge field, like Flow Builder
	 * @param {Event} event Click on the pill's label
	 */
	handlePillClick(event) {
		event.preventDefault();
		this._isEditing = true;
		this._text = `{!${this._selection.value}}`;
		this._shouldFocus = true;
		this._open();
	}

	/**
	 * @description Clears the value
	 * @param {Event} event Click on the pill's remove button
	 */
	handlePillRemove(event) {
		event.stopPropagation();
		this._selection = null;
		this._text = "";
		this._shouldFocus = true;
		this._emitChange(null, null);
	}

	// **** PRIVATE **** //
	/**
	 * @description Selects a selectable item, or drills into a container.
	 * @param {Object} item The chosen menu item
	 */
	_choose(item) {
		if (item?.isSelectable) {
			this._select(item);
		} else if (item?.isDrillable) {
			this._text = `{!${item.value}.`;
			this._loadMenu();
		}
	}

	/**
	 * @description Chooses the highlighted option, or commits the typed text if none is highlighted.
	 */
	_chooseActive() {
		const item = this.options[this._activeIndex];
		if (item) {
			this._choose(item);
		} else {
			this._commitText();
		}
	}

	/**
	 * @description Closes the menu without changing the value.
	 */
	_close() {
		this._isOpen = false;
		this._activeIndex = -1;
	}

	/**
	 * @description Saves anything the user typed, then closes the menu.
	 */
	_commitText() {
		if (this._isDirty || this._isEditing) {
			this._saveText();
		}
		this._isDirty = false;
		this._isEditing = false;
		this._close();
	}

	/**
	 * @description Fires `change`, unless the value is unchanged.
	 * @param {String} value The new value, or null to clear it
	 * @param {String} valueDataType `reference`, the literal's data type, or null
	 * @param {String} objectType For record references, the record's object
	 */
	_emitChange(value, valueDataType, objectType) {
		const isUnchanged = value === this._value && valueDataType === this._valueDataType;
		if (!isUnchanged) {
			this._value = value;
			this._valueDataType = valueDataType;
			const detail = objectType
				? { name: this.name, value, valueDataType, objectType }
				: { name: this.name, value, valueDataType };
			this.dispatchEvent(new CustomEvent("change", { detail }));
		}
	}

	/**
	 * @description The data type to save literals as.
	 * @returns {String} `Boolean` for boolean inputs, else `String`
	 */
	_literalDataType() {
		return this.type === "Boolean" ? "Boolean" : "String";
	}

	/**
	 * @description Rebuilds the menu for the current text: the resources in the drilled-into item, or at the root.
	 */
	async _loadMenu() {
		const requestId = ++this._requestId;
		const parsed = parseInput(this._text);
		const path = parsed.isComplete ? parsed.path : `${parsed.parentPath}.${parsed.searchTerm}`;
		const lastDot = path.lastIndexOf(".");
		const parentPath = parsed.isReference ? path.slice(0, Math.max(lastDot, 0)) : "";
		const searchTerm = parsed.isReference ? path.slice(lastDot + 1) : parsed.searchTerm;
		const parent = parentPath ? await resolveItem(parentPath, this.context, describeObject) : null;
		const sections = parent
			? await getChildSections(parent, this.context, this.target, describeObject)
			: getRootSections(this.context, this.target);
		// An unresolved parent (ex: "$GlobalConstant") searches the root for the whole path instead
		const term = parent || !parentPath ? searchTerm : path;
		if (requestId === this._requestId) {
			this._sections = filterSections(sections, term);
			this._trail = this._initTrail(parent);
			this._activeIndex = -1;
		}
	}

	/**
	 * @description Fetches the labels of the triggering object and of objects queried by Get Records elements, to label
	 * their resources like Flow Builder.
	 */
	async _loadObjectLabels() {
		const lookupObjects = (this._builderContext?.recordLookups ?? []).map((lookup) => lookup.object);
		const triggerObject = this._builderContext?.start?.object;
		const objects = new Set([...lookupObjects, triggerObject].filter(Boolean));
		const requests = [...objects].map((objectApiName) =>
			describeObject(objectApiName)
				.then((describe) => [objectApiName, { label: describe.label, labelPlural: describe.labelPlural }])
				// Without labels, outputs fall back to the object's API name, as the menu still works
				.catch(() => null)
		);
		const entries = await Promise.all(requests);
		this._objectLabels = Object.fromEntries(entries.filter(Boolean));
		if (this._isOpen) {
			this._loadMenu();
		}
	}

	/**
	 * @description Builds the breadcrumb trail for a drilled-into item.
	 * @param {Object} parent The drilled-into item, or null at the root
	 * @returns {Array} `{ label, value }` for each step
	 */
	_initTrail(parent) {
		const labels = parent?.pathLabel?.split(" > ") ?? [];
		const segments = parent?.value?.split(".") ?? [];
		return labels.map((label, index) => ({ label, value: segments.slice(0, index + 1).join(".") }));
	}

	/**
	 * @description Moves the highlight through the options, opening the menu first if it's closed.
	 * @param {Number} offset 1 to move down, -1 to move up
	 */
	_moveActive(offset) {
		const count = this.options.length;
		const wasOpen = this._isOpen;
		this._open();
		const next = wasOpen ? (this._activeIndex + offset + count) % count : 0;
		this._activeIndex = count ? next : -1;
	}

	/**
	 * @description Opens the menu for the current text.
	 */
	_open() {
		const wasOpen = this._isOpen;
		this._isOpen = true;
		if (!wasOpen) {
			this._loadMenu();
		}
	}

	/**
	 * @description Shows the current value: a pill for references, or text for literals.
	 */
	async _refreshSelection() {
		const value = this._value;
		const isBooleanLiteral = typeof value === "boolean" || /^(true|false)$/i.test(String(value));
		const booleanPath =
			this._valueDataType === "Boolean" && isBooleanLiteral
				? BOOLEAN_CONSTANTS[String(value).toLowerCase()]
				: null;
		const isConstant = String(value).startsWith(GLOBAL_CONSTANT_PREFIX);
		const path = this._valueDataType === REFERENCE || isConstant ? value : booleanPath;
		this._text = path || value == null ? "" : String(value);
		this._selection = path ? await this._resolveSelection(path) : null;
	}

	/**
	 * @description Saves the typed text as a reference (`{!path}`), a boolean constant, or a literal. An unfinished
	 * merge field (ex: `{!accountVar.`) is discarded, restoring the previous value.
	 */
	_saveText() {
		const parsed = parseInput(this._text);
		const booleanConstant = this.type === "Boolean" ? BOOLEAN_CONSTANTS[this._text.trim().toLowerCase()] : null;
		const referencePath = parsed.isComplete ? parsed.path : booleanConstant;
		const isUnfinished = parsed.isReference && !parsed.isComplete;
		const hasText = this._text.trim() !== "";
		if (referencePath) {
			this._selectReference(referencePath);
		} else if (isUnfinished) {
			this._refreshSelection();
		} else {
			this._emitChange(hasText ? this._text : null, hasText ? this._literalDataType() : null);
		}
	}

	/**
	 * @description Finds the item for a reference, falling back to the raw path if it no longer exists.
	 * @param {String} path The reference path
	 * @returns {Promise<Object>} The item to show as a pill
	 */
	async _resolveSelection(path) {
		// A deleted resource or inaccessible object still shows, as its raw path, so the user can replace it
		const item = await resolveItem(path, this.context, describeObject).catch(() => null);
		return item ?? { value: path, pathLabel: path, icon: "utility:text" };
	}

	/**
	 * @description Saves a menu item: literals as text, everything else as a reference.
	 * @param {Object} item The chosen item
	 */
	_select(item) {
		if (item.isLiteral) {
			this._selection = null;
			this._text = item.value;
			this._emitChange(item.value, "String");
		} else {
			this._selection = item;
			this._text = "";
			const valueDataType = toValueDataType(item);
			this._emitChange(item.value, valueDataType, item.objectType);
		}
		this._isDirty = false;
		this._isEditing = false;
		this._close();
	}

	/**
	 * @description Saves a typed reference, showing it as a pill.
	 * @param {String} path The reference path
	 */
	async _selectReference(path) {
		this._text = "";
		this._selection = await this._resolveSelection(path);
		const valueDataType = toValueDataType(this._selection);
		this._emitChange(path, valueDataType, this._selection.objectType);
	}
}
