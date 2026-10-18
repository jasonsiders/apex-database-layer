import { LightningElement, api, wire } from "lwc";
import { getObjectInfos } from "lightning/uiObjectInfoApi";
import {
	filterSections,
	getChildSections,
	getRootSections,
	parseInput,
	REQUIRED_ERROR,
	resolveItem,
	toBooleanConstant
} from "c/flowResourceMenu";

const GLOBAL_CONSTANT_PREFIX = "$GlobalConstant.";
// Flow Builder's action inputs use these icons, not its resource menu's
const LABEL_ICONS = { Boolean: "utility:crossfilter", String: "utility:text" };
const REFERENCE = "reference";
const ROOT_LABEL = "All Resources";

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
	 * @description Whether the record input takes a collection; unset accepts either, like Flow Builder's Update Records
	 * @type {Boolean}
	 */
	@api isCollection;
	/**
	 * @description Lists only the picklist values, without flow resources, like Flow Builder's field pickers
	 * @type {Boolean}
	 */
	@api isPicklistOnly = false;
	/**
	 * @description The input's label
	 * @type {String}
	 */
	@api label;
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
	 * @description Literal choices, listed first as "Picklist Values": `[{ label, value, description?, icon? }]`
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
	/**
	 * @description `label-hidden` keeps the label for screen readers only, beside any required asterisk
	 * @type {String}
	 */
	@api variant;

	_activeIndex = -1;
	_builderContext;
	_describeNames;
	_describes = new Map();
	_isDirty = false;
	_isEditing = false;
	_isTouched = false;
	_isOpen = false;
	_objectLabels = {};
	_refreshId = 0;
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

	get dropdownClass() {
		// Flow Builder's resource menu runs its header to the edges; its field pickers keep SLDS's padding
		const paddingClass = this.isPicklistOnly ? "" : " slds-p-vertical_none";
		return "slds-dropdown slds-dropdown_length-10 slds-dropdown_fluid" + paddingClass;
	}

	get error() {
		// Like Flow Builder's own inputs, a required one flags itself once it's left empty
		const isMissing = this.required && this._isTouched && this._value == null;
		return this.errorMessage ?? (isMissing ? REQUIRED_ERROR : null);
	}

	get expanded() {
		return String(this.isOpen);
	}

	get formElementClass() {
		const errorClass = this.error ? " slds-has-error" : "";
		return "slds-form-element slds-col" + errorClass;
	}

	get groupClass() {
		return "slds-listbox slds-listbox_vertical" + (this.isPicklistOnly ? "" : " picker-group");
	}

	get hasCrumbs() {
		return this._trail.length > 0;
	}

	get hasOptions() {
		return this._sections.length > 0;
	}

	get iconSize() {
		return this.isPicklistOnly ? "xx-small" : "x-small";
	}

	get isLabelHidden() {
		return this.variant === "label-hidden";
	}

	get isOpen() {
		// Like Flow Builder's field pickers, a picklist with nothing to offer stays closed
		return this._isOpen && (this.hasOptions || !this.isPicklistOnly);
	}

	get isResourceMenu() {
		return !this.isPicklistOnly;
	}

	get labelIcon() {
		return this.isLabelHidden ? null : LABEL_ICONS[this.type];
	}

	get labelTextClass() {
		return this.isLabelHidden ? "slds-assistive-text" : "";
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
				// Field pickers list fields as SLDS entities, like Flow Builder's own
				const typeClass = this.isPicklistOnly ? " slds-listbox__option_entity" : " picker-option";
				const textClass = this.isPicklistOnly
					? "slds-listbox__option-text slds-listbox__option-text_entity"
					: "slds-truncate";
				const option = {
					...item,
					domId: `option-${index}`,
					isActive: String(isActive),
					isCurrent: item.value === this._value,
					className: "slds-media slds-media_center slds-listbox__option" + typeClass + activeClass,
					textClass
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
			isPicklistOnly: this.isPicklistOnly,
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

	// **** WIRED **** //
	/**
	 * @description Settles each pending describe; results arrive in the order their objects were requested. A failed
	 * describe is forgotten, so the next request for it retries.
	 * @param {Object} response The wire's `{ data, error }`
	 */
	@wire(getObjectInfos, { objectApiNames: "$_describeNames" })
	wiredDescribes({ data, error }) {
		this._describeNames?.forEach((objectApiName, index) => {
			const response = data?.results?.[index];
			const request = this._describes.get(objectApiName);
			const isSuccess = response?.statusCode === 200;
			const isFailure = Boolean(error) || (response != null && !isSuccess);
			if (isSuccess) {
				request?.resolve(response.result);
			} else if (isFailure) {
				this._describes.delete(objectApiName);
				request?.reject(new Error(`Couldn't describe ${objectApiName}`));
			}
		});
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
			this._isTouched = true;
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
	 */
	handlePillRemove() {
		this._selection = null;
		this._text = "";
		this._shouldFocus = true;
		this._emitChange(null, null);
	}

	// **** PRIVATE **** //
	/**
	 * @description Describes an object on demand: adding it to the wire's objects fetches it, and Lightning Data Service
	 * caches it across pickers. Objects are only ever appended, so results line up with them by position.
	 * @param {String} objectApiName The object to describe
	 * @returns {Promise<Object>} The object's UI API object info
	 */
	_describeObject = (objectApiName) => {
		if (!this._describes.has(objectApiName)) {
			const names = this._describeNames ?? [];
			const isNew = !names.includes(objectApiName);
			this._describes.set(objectApiName, Promise.withResolvers());
			// A new array even when retrying, so the wire fetches again
			this._describeNames = isNew ? [...names, objectApiName] : [...names];
		}
		return this._describes.get(objectApiName).promise;
	};

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
	 * @param {Object} selection For references, the chosen item; records add its `objectType` and `isCollection`
	 */
	_emitChange(value, valueDataType, selection) {
		const isUnchanged = value === this._value && valueDataType === this._valueDataType;
		if (!isUnchanged) {
			this._value = value;
			this._valueDataType = valueDataType;
			const { objectType, isCollection } = selection ?? {};
			const detail = objectType
				? { name: this.name, value, valueDataType, objectType, isCollection }
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
		const { parentPath, path, searchTerm } = parseInput(this._text);
		const parent = parentPath ? await resolveItem(parentPath, this.context, this._describeObject) : null;
		const sections = parent
			? await getChildSections(parent, this.context, this.target, this._describeObject)
			: getRootSections(this.context, this.target);
		// An unresolved parent (ex: "$GlobalConstant") searches the root for the whole path instead
		const term = parent || !parentPath ? searchTerm : path;
		if (requestId === this._requestId) {
			this._sections = filterSections(sections, term);
			this._trail = this._initTrail(parent);
			// Flow Builder's field pickers highlight the first field; its resource menu highlights nothing
			this._activeIndex = this.isPicklistOnly && this._sections.length > 0 ? 0 : -1;
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
			this._describeObject(objectApiName)
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
		const refreshId = ++this._refreshId;
		const value = this._value;
		const booleanPath = this._valueDataType === "Boolean" ? toBooleanConstant(value) : null;
		const isConstant = String(value).startsWith(GLOBAL_CONSTANT_PREFIX);
		const path = this._valueDataType === REFERENCE || isConstant ? value : booleanPath;
		this._text = path || value == null ? "" : String(value);
		const selection = path ? await this._resolveSelection(path) : null;
		// A slow describe can resolve after a newer value arrives; only the newest is shown
		if (refreshId === this._refreshId) {
			this._selection = selection;
		}
	}

	/**
	 * @description Saves the typed text as a reference (`{!path}`), a boolean constant, or a literal. An unfinished
	 * merge field (ex: `{!accountVar.`) is discarded, restoring the previous value.
	 */
	_saveText() {
		const parsed = parseInput(this._text);
		const booleanConstant = this.type === "Boolean" ? toBooleanConstant(this._text) : null;
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
		const item = await resolveItem(path, this.context, this._describeObject).catch(() => null);
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
			this._emitChange(item.value, valueDataType, item);
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
		this._emitChange(path, valueDataType, this._selection);
	}
}
