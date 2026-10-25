import { LightningElement, api, wire } from "lwc";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import LOCALE_FIELD from "@salesforce/schema/User.LocaleSidKey";
import getMatchFields from "@salesforce/apex/InvocableDmlUpsertRecords.getMatchFields";
import { REFERENCE, REQUIRED_ERROR, compareLabels, toBooleanConstant } from "c/flowResourceMenu";

const FALSE = toBooleanConstant(false);
const TRUE = toBooleanConstant(true);
// Labeled like Flow Builder's boolean global constants
const BOOLEANS = [
	{ label: "True", value: TRUE },
	{ label: "False", value: FALSE }
];
const ACCESS_LEVELS = [
	{ label: "User Mode", value: "USER_MODE" },
	{ label: "System Mode", value: "SYSTEM_MODE" }
];
const EXTERNAL_ID = "externalId";
const EXTERNAL_ID_FIELD = "externalIdField";
const GENERIC_TYPES = ["T__record", "T__recordCollection", "U__record", "U__recordCollection"];
const MASTER_RECORD_TYPE_ID = "012000000000000AAA";
const MAX_LOCALE_LENGTH = 5;
const MULTIPLE = "multiple";
// Flow Builder can't save a blank literal, so choosing None removes the input
const NONE = { label: "--None--", value: "" };
const ONE = "one";
const RECORD_ID = "recordId";
const STANDARD_FIELD = "standardField";
// Wording follows Flow Builder's Create Records upsert
const MATCH_MODES = [
	{ label: "Record ID", value: RECORD_ID },
	{
		label: "External ID",
		value: EXTERNAL_ID,
		fieldLabel: "External ID Field",
		helpText: "Select the field to use as the external ID.",
		placeholder: "Search external ID fields..."
	},
	{
		label: "Standard Field",
		value: STANDARD_FIELD,
		fieldLabel: "Standard Field",
		helpText:
			"Select a field with its idLookup property equal to true. For example, the Case Number field on the Case object. Only supported fields are available.",
		placeholder: "Search standard fields..."
	}
];
const HOW_MANY_OPTIONS = [
	{ label: "One", value: ONE },
	{ label: "Multiple", value: MULTIPLE }
];
const RECORDS_INPUTS = {
	[MULTIPLE]: { label: "Record Collection", name: "recordCollection", isCollection: true },
	[ONE]: { label: "Record", name: "record", isCollection: false }
};

// Mirror InvocableDml.Input. Options are static, since a batch of interviews runs one DML statement with the first
// interview's options; only Assignment Rule ID takes a resource, since rule IDs differ between orgs.
const SETTINGS = [
	{
		name: "accessLevel",
		label: "Access Level",
		type: "String",
		defaultValue: "USER_MODE",
		picklistValues: ACCESS_LEVELS,
		helpText:
			"USER_MODE (default) enforces the running user's object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores object permissions and field-level security, but sharing rules still apply."
	},
	{
		name: "allOrNone",
		label: "All or None",
		type: "Boolean",
		defaultValue: true,
		helpText:
			"When true (default), any failure rolls back every record and fails the action. When false, valid records are processed, and failures are reported in the results."
	}
];
// Flow Builder's Update and Delete Records take either shape in one input
const EITHER_RECORDS_INPUT = { label: "Record or Record Collection", isCollection: undefined };
const LOCALE_OPTIONS = "localeOptions";
// Most used first: Access Level and All or None, then duplicate rules and Lead/Case assignment
const DML_OPTIONS = [
	...SETTINGS,
	{
		name: "allowDuplicates",
		label: "Allow Duplicates",
		type: "Boolean",
		helpText: "Save records that a duplicate rule would otherwise alert on."
	},
	{
		name: "useDefaultAssignmentRule",
		label: "Use Default Assignment Rule",
		type: "Boolean",
		helpText: "Run the default active assignment rule for Leads and Cases."
	},
	{
		name: "assignmentRuleId",
		label: "Assignment Rule ID",
		type: "String",
		allowsResources: true,
		helpText:
			"The ID of a specific Lead or Case assignment rule to run. Rule IDs differ between orgs, so use a resource, ex: an ID from Get Records on Assignment Rule, instead of typing one in."
	},
	{
		name: "allowFieldTruncation",
		label: "Allow Field Truncation",
		type: "Boolean",
		helpText: "Truncate text values that are too long for their field, instead of failing."
	},
	{
		name: "triggerUserEmail",
		label: "Trigger User Email",
		type: "Boolean",
		helpText: "Send email to users in the org, ex: when a Case or Task is assigned."
	},
	{
		name: "triggerAutoResponseEmail",
		label: "Trigger Auto-Response Email",
		type: "Boolean",
		helpText: "Send auto-response emails for new Leads and Cases."
	},
	{
		name: "triggerOtherEmail",
		label: "Trigger Other Email",
		type: "Boolean",
		helpText: "Send email to recipients outside the org."
	},
	{
		name: "runDuplicateRulesAsCurrentUser",
		label: "Run Duplicate Rules as Current User",
		type: "Boolean",
		helpText: "Enforce the running user's sharing rules when duplicate rules look for duplicates."
	},
	{
		name: LOCALE_OPTIONS,
		label: "Locale Options",
		type: "String",
		helpText: 'The language of any labels returned by the operation, ex: "en_US".'
	}
];

// Wording follows Flow Builder's Create, Update, and Delete Records elements
const ACTIONS = {
	InvocableDmlDeleteRecords: {
		heading: "Select Record(s) to Delete",
		hint: "Flow requires record identifiers to successfully delete records. Make sure the records include IDs.",
		options: SETTINGS
	},
	InvocableDmlEmptyRecycleBin: {
		heading: "Select Record(s) to Remove from the Recycle Bin",
		hint: "Make sure the records include IDs, and are in the Recycle Bin. Removed records can't be restored.",
		options: []
	},
	InvocableDmlInsertRecords: {
		headings: { [MULTIPLE]: "Insert Records from These Values", [ONE]: "Insert a Record from These Values" },
		hint: "Make sure that ID is blank. After the records are inserted, find their IDs in the action's Record outputs.",
		howManyLabel: "How Many Records to Insert",
		options: DML_OPTIONS
	},
	InvocableDmlUndeleteRecords: {
		heading: "Select Record(s) to Undelete",
		hint: "Flow requires record identifiers to successfully undelete records. Make sure the records include IDs, and are in the Recycle Bin.",
		options: SETTINGS
	},
	InvocableDmlUpdateRecords: {
		heading: "Select Record(s) to Update",
		hint: "Flow requires record identifiers to successfully update records. Make sure the records include IDs.",
		options: DML_OPTIONS
	},
	InvocableDmlUpsertRecords: {
		heading: "Select Record(s) to Upsert",
		hint: "After the records are upserted, find new records' IDs in the action's Record outputs.",
		options: SETTINGS,
		hasMatchField: true
	}
};

/**
 * @description Custom Property Editor for the record DML actions (`InvocableDml` subclasses), configured by the action
 * being edited. Mirrors Flow Builder's Create, Update, and Delete Records elements: one records input that saves to
 * `record` or `recordCollection`, and types the action's generic inputs and outputs to the chosen object.
 */
export default class DmlRecordsEditor extends LightningElement {
	/**
	 * @description From Flow Builder: outputs of actions that store them automatically, for drilling into
	 * @type {Object}
	 */
	@api automaticOutputVariables;
	/**
	 * @description From Flow Builder: the flow's resources
	 * @type {Object}
	 */
	@api builderContext;
	/**
	 * @description From Flow Builder: the element being edited, so pickers offer only resources available at that point
	 * @type {Object}
	 */
	@api elementInfo;
	/**
	 * @description From Flow Builder: the action's generic object types, which give the records' object
	 * @type {Array}
	 */
	@api genericTypeMappings;

	howManyOptions = HOW_MANY_OPTIONS;
	_errors = {};
	_howMany = ONE;
	_inputVariables = [];
	_locales = [];
	_matchFields = [];
	_matchMode;
	_objectType;
	_values = {};

	// **** GETTERS **** //
	get action() {
		return ACTIONS[this.elementInfo?.actionName] ?? ACTIONS.InvocableDmlInsertRecords;
	}

	get elementName() {
		return this.elementInfo?.apiName;
	}

	get howMany() {
		return this._howMany;
	}

	get localeRecordTypeId() {
		const hasLocaleOptions = this.action.options.some((option) => option.name === LOCALE_OPTIONS);
		// Only actions with Locale Options fetch the org's locales
		return hasLocaleOptions ? MASTER_RECORD_TYPE_ID : undefined;
	}

	get matchMode() {
		const value = this._values[EXTERNAL_ID_FIELD]?.value;
		const field = this._matchFields.find((candidate) => candidate.value === value);
		const fieldMode = field?.isExternalId === false ? STANDARD_FIELD : EXTERNAL_ID;
		// Until the user picks a mode, the saved field implies it
		return this._matchMode ?? (value == null ? RECORD_ID : fieldMode);
	}

	get matchField() {
		const mode = MATCH_MODES.find((candidate) => candidate.value === this.matchMode);
		// Records match on their ID without a field
		return mode.value === RECORD_ID ? null : this._initMatchField(mode);
	}

	get matchModes() {
		const matchMode = this.matchMode;
		return MATCH_MODES.map((mode) => ({ ...mode, isChecked: mode.value === matchMode }));
	}

	get matchObjectType() {
		const mapping = this.genericTypeMappings?.find((candidate) => candidate.typeName === GENERIC_TYPES[0]);
		// Only Upsert Records matches on a field, so the other actions skip the Apex call
		return this.action.hasMatchField ? (this._objectType ?? mapping?.typeValue) : undefined;
	}

	get options() {
		const fields = this._initFields(this.action.options);
		return fields.map((field) => this._initOption(field));
	}

	get records() {
		const { heading, headings, hint, howManyLabel } = this.action;
		const [field] = this._initFields([RECORDS_INPUTS[this._howMany]]);
		return {
			...field,
			...(howManyLabel ? {} : EITHER_RECORDS_INPUT),
			heading: headings?.[this._howMany] ?? heading,
			hint
		};
	}

	// **** API SETTERS **** //
	/**
	 * @description From Flow Builder: the action's saved input values, re-sent after every change
	 * @type {Array}
	 */
	@api
	get inputVariables() {
		return this._inputVariables;
	}
	set inputVariables(value) {
		this._inputVariables = value ?? [];
		this._values = this._initValues();
		this._howMany = this._initHowMany();
	}

	// **** API METHODS **** //
	/**
	 * @description Flow Builder calls this when the panel closes and before saving; any error badges the element and
	 * blocks activation, so only configurations the action can't run are flagged
	 * @returns {Array} `{ key, errorString }` for each problem; empty when the configuration is valid
	 */
	@api
	validate() {
		const errors = [this._validateRecords(), this._validateMatchField()].filter(Boolean);
		const errorEntries = errors.map((error) => [error.key, error.errorString]);
		this._errors = Object.fromEntries(errorEntries);
		return errors;
	}

	// **** WIRED **** //
	/**
	 * @description Lists the org's user locales for Locale Options, by code like the `DmlOptions` docs' `de_DE`, since
	 * that's what the action saves
	 * @param {Object} response The wire's `{ data, error }`
	 */
	@wire(getPicklistValues, { recordTypeId: "$localeRecordTypeId", fieldApiName: LOCALE_FIELD })
	wiredLocales(response) {
		// The DmlOptions docs allow 2-5 characters, which rules out locales like zh_CN_PINYIN; Apex doesn't check
		const values = (response?.data?.values ?? []).filter(({ value }) => value.length <= MAX_LOCALE_LENGTH);
		const locales = values.map(({ value }) => ({ label: value, value }));
		this._locales = [NONE, ...locales.sort(compareLabels)];
	}

	/**
	 * @description Lists the fields Upsert Records can match on, by API name like Flow Builder; an object Apex can't
	 * describe offers none
	 * @param {Object} response The wire's `{ data, error }`
	 */
	@wire(getMatchFields, { objectApiName: "$matchObjectType" })
	wiredMatchFields(response) {
		// shortcut: every field gets the text icon, as most external IDs are text; pass the field type for others
		const options = (response?.data ?? []).map((field) => ({
			label: field.apiName,
			value: field.apiName,
			description: field.label,
			icon: "utility:text",
			isExternalId: field.isExternalId
		}));
		this._matchFields = options.sort(compareLabels);
	}

	// **** HANDLERS **** //
	/**
	 * @description Switches between One and Multiple
	 * @param {CustomEvent} event Change on the radio group
	 */
	handleHowManyChange(event) {
		this._setHowMany(event.detail.value);
	}

	/**
	 * @description Saves the field to match records on, keeping its mode if it's cleared
	 * @param {CustomEvent} event Change on the match field picker
	 */
	handleMatchFieldChange(event) {
		this._matchMode = this.matchMode;
		this._saveInput(event.detail);
	}

	/**
	 * @description Switches how records are matched, dropping a field chosen for another mode
	 * @param {Event} event Change on a match mode radio button
	 */
	handleMatchModeChange(event) {
		this._setMatchMode(event.target.value);
	}

	/**
	 * @description Saves a picker's value to the action, or removes it when cleared
	 * @param {CustomEvent} event Change on a picker: `{ name, value, valueDataType }`
	 */
	handleInputChange(event) {
		this._saveInput(event.detail);
	}

	/**
	 * @description Saves a static option as its data type, or removes it when None is chosen
	 * @param {CustomEvent} event Change on an option's combobox
	 */
	handleOptionChange(event) {
		const { name, type } = event.target.dataset;
		const value = event.detail.value || null;
		this._saveInput({ name, value, valueDataType: type });
	}

	/**
	 * @description Saves the records to the input matching their shape, then types every generic input and output to
	 * their object, which Flow Builder needs before it can save the flow
	 * @param {CustomEvent} event Change on the records picker, with the records' `objectType` and `isCollection`
	 */
	handleRecordsChange(event) {
		const { isCollection, objectType, value } = event.detail;
		this._setObjectType(objectType);
		if (!this.action.howManyLabel && value != null) {
			this._setHowMany(isCollection ? MULTIPLE : ONE);
		}
		this._saveInput({ ...event.detail, name: RECORDS_INPUTS[this._howMany].name });
		this._setGenericTypes(event.detail);
	}

	// **** PRIVATE **** //
	/**
	 * @description Tells Flow Builder to remove an input's value.
	 * @param {String} name The input's name
	 */
	_deleteInput(name) {
		this._dispatch("configuration_editor_input_value_deleted", { name });
	}

	/**
	 * @description Fires a Custom Property Editor event to Flow Builder.
	 * @param {String} type The event type
	 * @param {Object} detail The event's details
	 */
	_dispatch(type, detail) {
		this.dispatchEvent(new CustomEvent(type, { bubbles: true, cancelable: false, composed: true, detail }));
	}

	/**
	 * @description Combines input definitions with their saved values and errors.
	 * @param {Array} definitions The inputs to show
	 * @returns {Array} The inputs, ready for `c-flow-resource-picker`
	 */
	_initFields(definitions) {
		return definitions.map((definition) => {
			const input = this._values[definition.name];
			return {
				...definition,
				errorMessage: this._errors[definition.name],
				value: input?.value,
				valueDataType: input?.valueDataType
			};
		});
	}

	/**
	 * @description Combines a static option with its choices. A resource saved outside the editor, ex: in metadata, is
	 * listed as its own choice, so the option shows it, not a default, until the user picks another value.
	 * @param {Object} field The option, with its saved value
	 * @returns {Object} The option, ready for `lightning-combobox`
	 */
	_initOption(field) {
		const value = field.value ?? field.defaultValue;
		const isResource = field.valueDataType === REFERENCE && toBooleanConstant(value) == null;
		// The picker shows its own resources
		const resource = isResource && !field.allowsResources ? value : null;
		const resourceChoices = resource ? [{ label: `{!${resource}}`, value: resource }] : [];
		const isBoolean = field.type === "Boolean";
		const listChoices = field.name === LOCALE_OPTIONS ? this._locales : (field.picklistValues ?? []);
		// Unset booleans show the action's default, false unless the definition says otherwise
		const booleanValue = resource ?? toBooleanConstant(value) ?? FALSE;
		return {
			...field,
			picklistValues: [...resourceChoices, ...(isBoolean ? BOOLEANS : listChoices)],
			value: isBoolean ? booleanValue : value
		};
	}

	/**
	 * @description Combines a match mode with its field's saved value, error, and the object's fields for that mode.
	 * @param {Object} mode External ID or Standard Field
	 * @returns {Object} The mode's field, ready for `c-flow-resource-picker`
	 */
	_initMatchField(mode) {
		const isExternalId = mode.value === EXTERNAL_ID;
		const definition = { name: EXTERNAL_ID_FIELD, label: mode.fieldLabel, placeholder: mode.placeholder };
		const [field] = this._initFields([definition]);
		const picklistValues = this._matchFields.filter((option) => option.isExternalId === isExternalId);
		return { ...field, picklistValues };
	}

	/**
	 * @description Infers One or Multiple from the saved records input, keeping the current choice if neither is set.
	 * @returns {String} `one` or `multiple`
	 */
	_initHowMany() {
		const hasCollection = this._values.recordCollection?.value != null;
		const hasRecord = this._values.record?.value != null;
		const saved = hasRecord ? ONE : this._howMany;
		return hasCollection ? MULTIPLE : saved;
	}

	/**
	 * @description Indexes the saved inputs by name. A new action's inputs arrive blank, not null; Flow Builder can't
	 * save a blank literal, so blank means unset.
	 * @returns {Object} Each saved input, by name
	 */
	_initValues() {
		const saved = this._inputVariables.filter((input) => input.value !== "");
		const entries = saved.map((input) => [input.name, input]);
		return Object.fromEntries(entries);
	}

	/**
	 * @description Saves a value to the action, or removes it when cleared.
	 * @param {Object} detail `{ name, value, valueDataType }`
	 */
	_saveInput(detail) {
		const { name, value, valueDataType } = detail;
		// Errors only refresh in validate(), which runs when the panel closes, so a fixed input clears its own
		this._errors = { ...this._errors, [name]: undefined };
		if (value == null) {
			this._deleteInput(name);
		} else {
			this._dispatch("configuration_editor_input_value_changed", {
				name,
				newValue: value,
				newValueDataType: valueDataType
			});
		}
	}

	/**
	 * @description Switches between one record and a collection, dropping the other input so the action only gets one.
	 * @param {String} howMany `one` or `multiple`
	 */
	_setHowMany(howMany) {
		const previousName = RECORDS_INPUTS[this._howMany].name;
		const isChanged = howMany !== this._howMany;
		this._howMany = howMany;
		if (isChanged && this._values[previousName]?.value != null) {
			this._deleteInput(previousName);
		}
	}

	/**
	 * @description Switches how records are matched, dropping any field chosen for another mode or object
	 * @param {String} matchMode `recordId`, `externalId`, or `standardField`
	 */
	_setMatchMode(matchMode) {
		this._matchMode = matchMode;
		if (this._values[EXTERNAL_ID_FIELD]?.value != null) {
			this._deleteInput(EXTERNAL_ID_FIELD);
		}
	}

	/**
	 * @description Keeps the records' object, once known; switching to another object drops the match field, which it
	 * wouldn't have, but keeps the mode, so validate() asks for a new field
	 * @param {String} objectType The records' object, if known
	 */
	_setObjectType(objectType) {
		const previousType = this.matchObjectType;
		const isNewObject = Boolean(previousType && objectType) && objectType !== previousType;
		if (isNewObject) {
			this._setMatchMode(this.matchMode);
		}
		this._objectType = objectType ?? this._objectType;
	}

	/**
	 * @description Types the action's generic inputs and outputs to the chosen object, once it's known
	 * @param {Object} detail The records picker's change: `{ value, objectType }`
	 */
	_setGenericTypes(detail) {
		const hasObject = detail.value != null && Boolean(detail.objectType);
		const typeNames = hasObject ? GENERIC_TYPES : [];
		typeNames.forEach((typeName) => {
			this._dispatch("configuration_editor_generic_type_mapping_changed", {
				typeName,
				typeValue: detail.objectType
			});
		});
	}

	/**
	 * @description Checks that a field was chosen, when records match on one.
	 * @returns {Object} An error, or null
	 */
	_validateMatchField() {
		const isMissing =
			this.action.hasMatchField && this.matchMode !== RECORD_ID && this._values[EXTERNAL_ID_FIELD]?.value == null;
		return isMissing ? { key: EXTERNAL_ID_FIELD, errorString: REQUIRED_ERROR } : null;
	}

	/**
	 * @description Checks that records were chosen.
	 * @returns {Object} An error, or null
	 */
	_validateRecords() {
		const { name } = RECORDS_INPUTS[this._howMany];
		return this._values[name]?.value == null ? { key: name, errorString: REQUIRED_ERROR } : null;
	}
}
