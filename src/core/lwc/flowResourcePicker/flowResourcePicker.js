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
	@api automaticOutputVariables;
	@api type = "String";
	@api errorMessage;
	@api helpText;
	@api isCollection = false;
	@api label;
	@api labelIcon;
	@api name;
	@api objectType;
	@api picklistValues;
	@api placeholder = "Enter value or search resources...";
	@api required = false;

	activeIndex = -1;
	isDirty = false;
	isEditing = false;
	isOpen = false;
	objectLabels = {};
	sections = [];
	selection = null;
	text = "";
	trail = [];
	_builderContext;
	_requestId = 0;
	_shouldFocus = false;
	_value;
	_valueDataType;

	/**
	 * @description The flow's resources, from the CPE's `builderContext`.
	 */
	@api
	get builderContext() {
		return this._builderContext;
	}
	set builderContext(value) {
		this._builderContext = value;
		this.loadObjectLabels();
		this.refreshSelection();
	}

	/**
	 * @description The input's current value: a reference path or a literal.
	 */
	@api
	get value() {
		return this._value;
	}
	set value(value) {
		this._value = value;
		this.refreshSelection();
	}

	/**
	 * @description `reference` for resources, else the literal's data type.
	 */
	@api
	get valueDataType() {
		return this._valueDataType;
	}
	set valueDataType(value) {
		this._valueDataType = value;
		this.refreshSelection();
	}

	// **** GETTERS **** //
	get comboboxClass() {
		const openClass = this.isOpen ? " slds-is-open" : "";
		return "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click" + openClass;
	}

	get context() {
		return {
			automaticOutputVariables: this.automaticOutputVariables,
			builderContext: this._builderContext,
			objectLabels: this.objectLabels
		};
	}

	get formElementClass() {
		const errorClass = this.errorMessage ? " slds-has-error" : "";
		return "slds-form-element" + errorClass;
	}

	get hasCrumbs() {
		return this.trail.length > 0;
	}

	get hasOptions() {
		return this.sections.length > 0;
	}

	get crumbs() {
		const root = { index: -1, label: ROOT_LABEL };
		const steps = this.trail.map((step, index) => ({ index, label: step.label }));
		return [root, ...steps];
	}

	get activeDescendant() {
		return this.activeIndex >= 0 ? `option-${this.activeIndex}` : null;
	}

	get expanded() {
		return String(this.isOpen);
	}

	get menu() {
		let index = 0;
		return this.sections.map((section) => ({
			...section,
			items: section.items.map((item) => {
				const isActive = index === this.activeIndex;
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
		return this.sections.flatMap((section) => section.items);
	}

	get removeLabel() {
		return `Remove ${this.selection?.pathLabel}`;
	}

	get showPill() {
		return Boolean(this.selection) && !this.isEditing;
	}

	get target() {
		return {
			dataType: this.type,
			isCollection: this.isCollection,
			objectType: this.objectType,
			picklistValues: this.picklistValues
		};
	}

	// **** LIFECYCLE **** //
	renderedCallback() {
		if (this._shouldFocus) {
			this._shouldFocus = false;
			this.template.querySelector('input[role="combobox"]')?.focus();
		}
	}

	// **** HANDLERS **** //
	handleCrumbClick(event) {
		const index = Number(event.currentTarget.dataset.index);
		const step = this.trail[index];
		this.text = step ? `{!${step.value}.` : "";
		this._shouldFocus = true;
		this.loadMenu();
	}

	handleFocus() {
		this.open();
	}

	handleFocusOut(event) {
		const combobox = this.template.querySelector(".slds-combobox");
		if (!combobox?.contains(event.relatedTarget)) {
			this.commitText();
		}
	}

	handleInput(event) {
		this.isDirty = true;
		this.text = event.target.value;
		this.isOpen = true;
		this.loadMenu();
	}

	handleKeyDown(event) {
		const actions = {
			ArrowDown: () => this.moveActive(1),
			ArrowUp: () => this.moveActive(-1),
			Enter: () => this.chooseActive(),
			Escape: () => this.close()
		};
		const action = actions[event.key];
		if (action) {
			event.preventDefault();
			action();
		}
	}

	handleListMouseDown(event) {
		// Keep focus in the input, so choosing an option doesn't commit the typed text first
		event.preventDefault();
	}

	handleOptionClick(event) {
		const key = event.currentTarget.dataset.key;
		const item = this.options.find((option) => option.key === key);
		this.choose(item);
	}

	handlePillClick(event) {
		event.preventDefault();
		this.isEditing = true;
		this.text = `{!${this.selection.value}}`;
		this._shouldFocus = true;
		this.open();
	}

	handlePillRemove(event) {
		event.stopPropagation();
		this.selection = null;
		this.text = "";
		this._shouldFocus = true;
		this.emitChange(null, null);
	}

	// **** PRIVATE **** //
	/**
	 * @description Selects a selectable item, or drills into a container.
	 * @param {Object} item The chosen menu item
	 */
	choose(item) {
		if (item?.isSelectable) {
			this.select(item);
		} else if (item?.isDrillable) {
			this.text = `{!${item.value}.`;
			this.loadMenu();
		}
	}

	/**
	 * @description Chooses the highlighted option, or commits the typed text if none is highlighted.
	 */
	chooseActive() {
		const item = this.options[this.activeIndex];
		if (item) {
			this.choose(item);
		} else {
			this.commitText();
		}
	}

	/**
	 * @description Closes the menu without changing the value.
	 */
	close() {
		this.isOpen = false;
		this.activeIndex = -1;
	}

	/**
	 * @description Saves anything the user typed, then closes the menu.
	 */
	commitText() {
		if (this.isDirty || this.isEditing) {
			this.saveText();
		}
		this.isDirty = false;
		this.isEditing = false;
		this.close();
	}

	/**
	 * @description Fires `change`, unless the value is unchanged.
	 * @param {String} value The new value, or null to clear it
	 * @param {String} valueDataType `reference`, the literal's data type, or null
	 * @param {String} objectType For record references, the record's object
	 */
	emitChange(value, valueDataType, objectType) {
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
	literalDataType() {
		return this.type === "Boolean" ? "Boolean" : "String";
	}

	/**
	 * @description Rebuilds the menu for the current text: the resources in the drilled-into item, or at the root.
	 */
	async loadMenu() {
		const requestId = ++this._requestId;
		const parsed = parseInput(this.text);
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
			this.sections = filterSections(sections, term);
			this.trail = this.initTrail(parent);
			this.activeIndex = -1;
		}
	}

	/**
	 * @description Fetches the labels of objects queried by Get Records elements, to label their outputs like Flow Builder.
	 */
	async loadObjectLabels() {
		const objects = new Set((this._builderContext?.recordLookups ?? []).map((lookup) => lookup.object));
		const requests = [...objects].map((objectApiName) =>
			describeObject(objectApiName)
				.then((describe) => [objectApiName, { label: describe.label, labelPlural: describe.labelPlural }])
				.catch(() => null)
		);
		const entries = await Promise.all(requests);
		this.objectLabels = Object.fromEntries(entries.filter(Boolean));
		if (this.isOpen) {
			this.loadMenu();
		}
	}

	/**
	 * @description Builds the breadcrumb trail for a drilled-into item.
	 * @param {Object} parent The drilled-into item, or null at the root
	 * @returns {Array} `{ label, value }` for each step
	 */
	initTrail(parent) {
		const labels = parent?.pathLabel?.split(" > ") ?? [];
		const segments = parent?.value?.split(".") ?? [];
		return labels.map((label, index) => ({ label, value: segments.slice(0, index + 1).join(".") }));
	}

	/**
	 * @description Moves the highlight through the options, opening the menu first if it's closed.
	 * @param {Number} offset 1 to move down, -1 to move up
	 */
	moveActive(offset) {
		const count = this.options.length;
		const wasOpen = this.isOpen;
		this.open();
		const next = wasOpen ? (this.activeIndex + offset + count) % count : 0;
		this.activeIndex = count ? next : -1;
	}

	/**
	 * @description Opens the menu for the current text.
	 */
	open() {
		const wasOpen = this.isOpen;
		this.isOpen = true;
		if (!wasOpen) {
			this.loadMenu();
		}
	}

	/**
	 * @description Shows the current value: a pill for references, or text for literals.
	 */
	async refreshSelection() {
		const value = this._value;
		const isBooleanLiteral = typeof value === "boolean" || /^(true|false)$/i.test(String(value));
		const booleanPath =
			this._valueDataType === "Boolean" && isBooleanLiteral
				? BOOLEAN_CONSTANTS[String(value).toLowerCase()]
				: null;
		const isConstant = String(value).startsWith(GLOBAL_CONSTANT_PREFIX);
		const path = this._valueDataType === REFERENCE || isConstant ? value : booleanPath;
		this.text = path || value == null ? "" : String(value);
		this.selection = path ? await this.resolveSelection(path) : null;
	}

	/**
	 * @description Saves the typed text as a reference (`{!path}`), a boolean constant, or a literal. An unfinished
	 * merge field (ex: `{!accountVar.`) is discarded, restoring the previous value.
	 */
	saveText() {
		const parsed = parseInput(this.text);
		const booleanConstant = this.type === "Boolean" ? BOOLEAN_CONSTANTS[this.text.trim().toLowerCase()] : null;
		const referencePath = parsed.isComplete ? parsed.path : booleanConstant;
		const isUnfinished = parsed.isReference && !parsed.isComplete;
		const hasText = this.text.trim() !== "";
		if (referencePath) {
			this.selectReference(referencePath);
		} else if (isUnfinished) {
			this.refreshSelection();
		} else {
			this.emitChange(hasText ? this.text : null, hasText ? this.literalDataType() : null);
		}
	}

	/**
	 * @description Finds the item for a reference, falling back to the raw path if it no longer exists.
	 * @param {String} path The reference path
	 * @returns {Promise<Object>} The item to show as a pill
	 */
	async resolveSelection(path) {
		const item = await resolveItem(path, this.context, describeObject).catch(() => null);
		return item ?? { value: path, pathLabel: path, icon: "utility:text" };
	}

	/**
	 * @description Saves a menu item: literals as text, everything else as a reference.
	 * @param {Object} item The chosen item
	 */
	select(item) {
		if (item.isLiteral) {
			this.selection = null;
			this.text = item.value;
			this.emitChange(item.value, "String");
		} else {
			this.selection = item;
			this.text = "";
			const valueDataType = toValueDataType(item);
			this.emitChange(item.value, valueDataType, item.objectType);
		}
		this.isDirty = false;
		this.isEditing = false;
		this.close();
	}

	/**
	 * @description Saves a typed reference, showing it as a pill.
	 * @param {String} path The reference path
	 */
	async selectReference(path) {
		this.text = "";
		this.selection = await this.resolveSelection(path);
		const valueDataType = toValueDataType(this.selection);
		this.emitChange(path, valueDataType, this.selection.objectType);
	}
}
