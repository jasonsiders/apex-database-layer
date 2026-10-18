import { LightningElement, api, wire } from "lwc";
import { REQUIRED_ERROR, toBooleanConstant } from "c/flowResourceMenu";
import getMatchFields from "@salesforce/apex/InvocableDmlUpsertRecords.getMatchFields";

const ACCESS_LEVELS = [
	{ label: "User Mode", value: "USER_MODE" },
	{ label: "System Mode", value: "SYSTEM_MODE" }
];
const EXTERNAL_ID = "externalId";
const EXTERNAL_ID_FIELD = "externalIdField";
const GENERIC_TYPES = ["T__record", "T__recordCollection", "U__record", "U__recordCollection"];
const HOW_MANY_OPTIONS = [
	{ label: "One", value: "one" },
	{ label: "Multiple", value: "multiple" }
];
const MULTIPLE = "multiple";
const ONE = "one";
const RECORD_ID = "recordId";
const STANDARD_FIELD = "standardField";
// Wording follows Flow Builder's Create Records upsert
const MATCH_MODES = [
	{ label: "Record ID", value: RECORD_ID },
	{
		label: "External ID",
		value: EXTERNAL_ID,
		helpText: "Select the field to use as the external ID.",
		placeholder: "Search external ID fields..."
	},
	{
		label: "Standard Field",
		value: STANDARD_FIELD,
		helpText:
			"Select a field with its idLookup property equal to true. For example, the Case Number field on the Case object. Only supported fields are available.",
		placeholder: "Search standard fields..."
	}
];
const RECORDS_INPUTS = {
	[MULTIPLE]: { label: "Record Collection", name: "recordCollection", isCollection: true },
	[ONE]: { label: "Record", name: "record", isCollection: false }
};
const REFERENCE = "reference";

// Mirror InvocableDml.Input
const ACCESS_LEVEL = {
	name: "accessLevel",
	label: "Access Level",
	type: "String",
	picklistValues: ACCESS_LEVELS,
	helpText:
		"USER_MODE (default) enforces the running user's object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores them."
};
const ALL_OR_NONE = {
	name: "allOrNone",
	label: "All or None",
	type: "Boolean",
	helpText:
		"When true (default), any failure rolls back every record and fails the action. When false, valid records are processed, and failures are reported in the results."
};
const SETTINGS = [ACCESS_LEVEL, ALL_OR_NONE];
// Flow Builder's Update and Delete Records take either shape in one input
const EITHER_RECORDS_INPUT = { label: "Record or Record Collection", isCollection: undefined };
const DML_OPTIONS = [
	{
		name: "allowDuplicates",
		label: "Allow Duplicates",
		type: "Boolean",
		helpText: "Save records that a duplicate rule would otherwise alert on."
	},
	{
		name: "allowFieldTruncation",
		label: "Allow Field Truncation",
		type: "Boolean",
		helpText: "Truncate text values that are too long for their field, instead of failing."
	},
	{
		name: "assignmentRuleId",
		label: "Assignment Rule ID",
		type: "String",
		helpText: "The Id of a specific Lead or Case assignment rule to run."
	},
	{
		name: "localeOptions",
		label: "Locale Options",
		type: "String",
		helpText: 'The language of any labels returned by the operation, ex: "en_US".'
	},
	{
		name: "runDuplicateRulesAsCurrentUser",
		label: "Run Duplicate Rules as Current User",
		type: "Boolean",
		helpText: "Enforce the running user's sharing rules when duplicate rules look for duplicates."
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
		name: "triggerUserEmail",
		label: "Trigger User Email",
		type: "Boolean",
		helpText: "Send email to users in the org, ex: when a Case or Task is assigned."
	},
	{
		name: "useDefaultAssignmentRule",
		label: "Use Default Assignment Rule",
		type: "Boolean",
		helpText: "Run the default active assignment rule for Leads and Cases."
	}
];

// Wording follows Flow Builder's Create, Update, and Delete Records elements
const ACTIONS = {
	InvocableDmlDeleteRecords: {
		heading: "Select Record(s) to Delete",
		hint: "Flow requires record identifiers to successfully delete records. Make sure the records include IDs.",
		settings: SETTINGS
	},
	InvocableDmlEmptyRecycleBin: {
		heading: "Select Record(s) to Remove from the Recycle Bin",
		hint: "Make sure the records include IDs, and are in the Recycle Bin. Removed records can't be restored.",
		settings: []
	},
	InvocableDmlInsertRecords: {
		headings: { [MULTIPLE]: "Insert Records from These Values", [ONE]: "Insert a Record from These Values" },
		hint: "Make sure that ID is blank. After the records are inserted, find their IDs in the action's Record outputs.",
		howManyLabel: "How Many Records to Insert",
		settings: SETTINGS,
		hasDmlOptions: true
	},
	InvocableDmlUndeleteRecords: {
		heading: "Select Record(s) to Undelete",
		hint: "Flow requires record identifiers to successfully undelete records. Make sure the records include IDs, and are in the Recycle Bin.",
		settings: SETTINGS
	},
	InvocableDmlUpdateRecords: {
		heading: "Select Record(s) to Update",
		hint: "Flow requires record identifiers to successfully update records. Make sure the records include IDs.",
		settings: SETTINGS,
		hasDmlOptions: true
	},
	InvocableDmlUpsertRecords: {
		heading: "Select Record(s) to Upsert",
		hint: "After the records are upserted, find new records' IDs in the action's Record outputs.",
		settings: SETTINGS,
		hasMatchField: true
	}
};

/**
 * Custom Property Editor for the record DML actions (`InvocableDml` subclasses), configured by the action being
 * edited. Mirrors Flow Builder's Create, Update, and Delete Records elements: one records input that saves to `record`
 * or `recordCollection`, and types the action's generic inputs and outputs to the chosen object.
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

	_errors = {};
	_howMany = ONE;
	_inputVariables = [];
	_matchMode;
	_objectType;
	_values = {};

	@wire(getMatchFields, { objectApiName: "$matchObjectType" })
	_matchFields;

	// **** GETTERS **** //
	get action() {
		return ACTIONS[this.elementInfo?.actionName] ?? ACTIONS.InvocableDmlInsertRecords;
	}

	get elementName() {
		return this.elementInfo?.apiName;
	}

	get hasMatchField() {
		return Boolean(this.action.hasMatchField);
	}

	get howMany() {
		return this._howMany;
	}

	get howManyLabel() {
		return this.action.howManyLabel;
	}

	get howManyOptions() {
		return HOW_MANY_OPTIONS;
	}

	get matchModes() {
		const matchMode = this.matchMode;
		return MATCH_MODES.map((mode) => {
			const isChecked = mode.value === matchMode;
			return { ...mode, isChecked, field: isChecked && mode.placeholder ? this._initMatchField(mode) : null };
		});
	}

	get matchMode() {
		const value = this._values[EXTERNAL_ID_FIELD]?.value;
		const field = (this._matchFields?.data ?? []).find((candidate) => candidate.apiName === value);
		const fieldMode = field?.isExternalId === false ? STANDARD_FIELD : EXTERNAL_ID;
		// Until the user picks a mode, the saved field implies it
		return this._matchMode ?? (value == null ? RECORD_ID : fieldMode);
	}

	get matchObjectType() {
		const mapping = this.genericTypeMappings?.find((candidate) => candidate.typeName === GENERIC_TYPES[0]);
		// Only Upsert Records matches on a field, so the other actions skip the Apex call
		return this.hasMatchField ? (this._objectType ?? mapping?.typeValue) : undefined;
	}

	get records() {
		const { heading, headings, hint, howManyLabel } = this.action;
		const recordsInput = RECORDS_INPUTS[this._howMany];
		const input = this._values[recordsInput.name];
		return {
			...recordsInput,
			...(howManyLabel ? {} : EITHER_RECORDS_INPUT),
			heading: headings?.[this._howMany] ?? heading,
			hint,
			value: input?.value,
			valueDataType: input?.valueDataType,
			errorMessage: this._errors[recordsInput.name]
		};
	}

	get sections() {
		const { hasDmlOptions, settings } = this.action;
		return [
			{ heading: "Set Input Values", fields: this._initFields(settings) },
			{ heading: "DML Options", fields: this._initFields(hasDmlOptions ? DML_OPTIONS : []) }
		].filter((section) => section.fields.length);
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
		this._values = Object.fromEntries(this._inputVariables.map((input) => [input.name, input]));
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
		const fields = this.sections.flatMap((section) => section.fields);
		const checks = [
			this._validateRecords(),
			this._validateMatchField(),
			this._validateAccessLevel(fields),
			...this._validateBooleans(fields)
		];
		const errors = checks.filter(Boolean);
		this._errors = Object.fromEntries(errors.map((error) => [error.key, error.errorString]));
		return errors;
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
		this._matchMode = event.target.value;
		if (this._values[EXTERNAL_ID_FIELD]?.value != null) {
			this._deleteInput(EXTERNAL_ID_FIELD);
		}
	}

	/**
	 * @description Saves a picker's value to the action, or removes it when cleared
	 * @param {CustomEvent} event Change on a picker: `{ name, value, valueDataType }`
	 */
	handleInputChange(event) {
		this._saveInput(event.detail);
	}

	/**
	 * @description Saves the records to the input matching their shape, then types every generic input and output to
	 * their object, which Flow Builder needs before it can save the flow
	 * @param {CustomEvent} event Change on the records picker: `{ name, value, valueDataType, objectType, isCollection }`
	 */
	handleRecordsChange(event) {
		const { isCollection, objectType, value } = event.detail;
		this._objectType = objectType ?? this._objectType;
		if (!this.howManyLabel && value != null) {
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
	 * @description Combines a match mode with its field's saved value, error, and the object's fields for that mode.
	 * @param {Object} mode External ID or Standard Field
	 * @returns {Object} The mode's field, ready for `c-flow-resource-picker`
	 */
	_initMatchField(mode) {
		const input = this._values[EXTERNAL_ID_FIELD];
		const isExternalId = mode.value === EXTERNAL_ID;
		// shortcut: every field gets the text icon, as most external IDs are text; pass the field type for others
		const picklistValues = (this._matchFields?.data ?? [])
			.filter((field) => field.isExternalId === isExternalId)
			.map((field) => ({
				label: field.apiName,
				value: field.apiName,
				description: field.label,
				icon: "utility:text"
			}))
			.sort((a, b) => a.label.localeCompare(b.label));
		return {
			errorMessage: this._errors[EXTERNAL_ID_FIELD],
			picklistValues,
			value: input?.value,
			valueDataType: input?.valueDataType
		};
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
	 * @description Whether an input holds a typed-in value, not a resource; only those can be checked before the flow runs
	 * @param {Object} input A saved input value
	 * @returns {Boolean} True for literals
	 */
	_isLiteral(input) {
		return input?.value != null && input.valueDataType !== REFERENCE;
	}

	/**
	 * @description Saves a value to the action, or removes it when cleared.
	 * @param {Object} detail `{ name, value, valueDataType }`
	 */
	_saveInput(detail) {
		const { name, value, valueDataType } = detail;
		// Errors only refresh in validate(), which Flow Builder calls when the panel closes, so a fixed input clears its own
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
	 * @description Types the action's generic inputs and outputs to the chosen object; skipped when the object isn't known
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
	 * @description Checks that a literal access level is one the action accepts, if the action shows it.
	 * @param {Array} fields The inputs the action shows
	 * @returns {Object} An error, or null
	 */
	_validateAccessLevel(fields) {
		const input = this._values.accessLevel;
		const level = String(input?.value).trim().toUpperCase();
		const isChecked = this._isLiteral(input) && fields.some((field) => field.name === ACCESS_LEVEL.name);
		const isValid = !isChecked || ACCESS_LEVELS.some((option) => option.value === level);
		return isValid ? null : { key: "accessLevel", errorString: "Enter USER_MODE or SYSTEM_MODE." };
	}

	/**
	 * @description Checks that literal booleans are true or false.
	 * @param {Array} fields The inputs the action shows
	 * @returns {Array} An error for each invalid boolean input
	 */
	_validateBooleans(fields) {
		return fields
			.filter((field) => field.type === "Boolean" && this._isLiteral(field) && !toBooleanConstant(field.value))
			.map((field) => ({ key: field.name, errorString: "Enter True or False." }));
	}

	/**
	 * @description Checks that a field was chosen, when records match on one.
	 * @returns {Object} An error, or null
	 */
	_validateMatchField() {
		const isMissing =
			this.hasMatchField && this.matchMode !== RECORD_ID && this._values[EXTERNAL_ID_FIELD]?.value == null;
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
