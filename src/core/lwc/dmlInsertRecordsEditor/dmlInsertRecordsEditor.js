import { LightningElement, api } from "lwc";

const ACCESS_LEVELS = [
	{ label: "User Mode", value: "USER_MODE" },
	{ label: "System Mode", value: "SYSTEM_MODE" }
];
const BOOLEAN_LITERALS = [true, false, "true", "false", "$GlobalConstant.True", "$GlobalConstant.False"];
const GENERIC_TYPES = ["T__record", "T__recordCollection", "U__record", "U__recordCollection"];
const LABEL_ICONS = { Boolean: "utility:toggle", String: "utility:text" };
const HOW_MANY_OPTIONS = [
	{ label: "One", value: "one" },
	{ label: "Multiple", value: "multiple" }
];
const MULTIPLE = "multiple";
const ONE = "one";

// Mirrors InvocableDmlInsertRecords.Input
const SETTINGS = [
	{
		name: "accessLevel",
		label: "Access Level",
		type: "String",
		picklistValues: ACCESS_LEVELS,
		helpText:
			"USER_MODE (default) enforces the running user's object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores them."
	},
	{
		name: "allOrNone",
		label: "All or None",
		type: "Boolean",
		helpText:
			"When true (default), any failure rolls back every record and fails the action. When false, valid records are inserted, and failures are reported in the results."
	}
];
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

/**
 * Custom Property Editor for the Insert Records action (`InvocableDmlInsertRecords`). Mirrors Flow Builder's
 * Create Records element: one Records input that saves to `record` or `recordCollection`, and types the action's
 * generic inputs and outputs to the chosen object.
 */
export default class DmlInsertRecordsEditor extends LightningElement {
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
	 * @description From Flow Builder: the action's generic object types; set via events, never read
	 * @type {Array}
	 */
	@api genericTypeMappings;

	_errors = {};
	_howMany = ONE;
	_inputVariables = [];
	_values = {};

	// **** GETTERS **** //
	get dmlOptions() {
		return this._initFields(DML_OPTIONS);
	}

	get elementName() {
		return this.elementInfo?.apiName;
	}

	get howMany() {
		return this._howMany;
	}

	get howManyOptions() {
		return HOW_MANY_OPTIONS;
	}

	get isMultiple() {
		return this._howMany === MULTIPLE;
	}

	get records() {
		const name = this.recordsName;
		const input = this._values[name];
		return { name, value: input?.value, valueDataType: input?.valueDataType, errorMessage: this._errors[name] };
	}

	get recordsHeading() {
		return this.isMultiple ? "Insert Records from These Values" : "Insert a Record from These Values";
	}

	get recordsName() {
		return this.isMultiple ? "recordCollection" : "record";
	}

	get settings() {
		return this._initFields(SETTINGS);
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
	 * @description Flow Builder calls this after every change and before saving; any error badges the element and
	 * blocks activation, so only configurations the action can't run are flagged
	 * @returns {Array} `{ key, errorString }` for each problem; empty when the configuration is valid
	 */
	@api
	validate() {
		const checks = [this._validateRecords(), this._validateAccessLevel(), ...this._validateBooleans()];
		const errors = checks.filter(Boolean);
		this._errors = Object.fromEntries(errors.map((error) => [error.key, error.errorString]));
		return errors;
	}

	// **** HANDLERS **** //
	/**
	 * @description Switches between One and Multiple, dropping the other input so the action only gets one
	 * @param {CustomEvent} event Change on the radio group
	 */
	handleHowManyChange(event) {
		const previousName = this.recordsName;
		this._howMany = event.detail.value;
		if (this._values[previousName]?.value != null) {
			this._deleteInput(previousName);
		}
	}

	/**
	 * @description Saves a picker's value to the action, or removes it when cleared
	 * @param {CustomEvent} event Change on a picker: `{ name, value, valueDataType }`
	 */
	handleInputChange(event) {
		const { name, value, valueDataType } = event.detail;
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
	 * @description Saves the records, then types every generic input and output to their object, which Flow
	 * Builder needs before it can save the flow
	 * @param {CustomEvent} event Change on the records picker: `{ name, value, valueDataType, objectType }`
	 */
	handleRecordsChange(event) {
		this.handleInputChange(event);
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
				labelIcon: LABEL_ICONS[definition.type],
				value: input?.value,
				valueDataType: input?.valueDataType
			};
		});
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
	 * @description Checks that a literal access level is one the action accepts.
	 * @returns {Object} An error, or null
	 */
	_validateAccessLevel() {
		const input = this._values.accessLevel;
		const isLiteral = input?.value != null && input.valueDataType !== "reference";
		const level = String(input?.value).toUpperCase();
		const isValid = !isLiteral || ACCESS_LEVELS.some((option) => option.value === level);
		return isValid ? null : { key: "accessLevel", errorString: "Enter USER_MODE or SYSTEM_MODE." };
	}

	/**
	 * @description Checks that literal booleans are true or false.
	 * @returns {Array} An error for each invalid boolean input
	 */
	_validateBooleans() {
		const booleans = [...SETTINGS, ...DML_OPTIONS].filter((definition) => definition.type === "Boolean");
		return booleans
			.filter((definition) => {
				const input = this._values[definition.name];
				const isLiteral = input?.value != null && input.valueDataType !== "reference";
				return isLiteral && !BOOLEAN_LITERALS.includes(input.value);
			})
			.map((definition) => ({ key: definition.name, errorString: "Enter True or False." }));
	}

	/**
	 * @description Checks that records were chosen.
	 * @returns {Object} An error, or null
	 */
	_validateRecords() {
		const name = this.recordsName;
		const label = this.isMultiple ? "record collection" : "record";
		return this._values[name]?.value == null ? { key: name, errorString: `Select a ${label}.` } : null;
	}
}
