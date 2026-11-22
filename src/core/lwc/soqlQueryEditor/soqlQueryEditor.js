import { LightningElement, api, wire } from "lwc";
import getObjects from "@salesforce/apex/InvocableSoql.getObjects";
import { REFERENCE, REQUIRED_ERROR, compareLabels } from "c/flowResourceMenu";
import { resolveField } from "c/soqlFieldPath";

const ACCESS_LEVELS = [
	{ label: "User Mode", value: "USER_MODE" },
	{ label: "System Mode", value: "SYSTEM_MODE" }
];
const CUSTOM = "CUSTOM";
// SOQL's date literals, ex: TODAY or LAST_N_DAYS:30, which the action renders in place instead of binding
const DATE_LITERAL_PATTERN = /^[A-Z_0-9]+(:\d+)?$/;
const DATE_LITERALS = [
	"TODAY",
	"YESTERDAY",
	"TOMORROW",
	"THIS_WEEK",
	"LAST_WEEK",
	"NEXT_WEEK",
	"THIS_MONTH",
	"LAST_MONTH",
	"NEXT_MONTH",
	"LAST_90_DAYS",
	"NEXT_90_DAYS",
	"THIS_QUARTER",
	"LAST_QUARTER",
	"NEXT_QUARTER",
	"THIS_YEAR",
	"LAST_YEAR",
	"NEXT_YEAR"
].map((value) => ({ label: value, value, icon: "utility:event" }));
const DIRECTIONS = [
	{ label: "Ascending", value: "ASCENDING" },
	{ label: "Descending", value: "DESCENDING" }
];
// Flow types for each field type; the rest are text
const FLOW_TYPES = {
	BOOLEAN: "Boolean",
	CURRENCY: "Number",
	DATE: "Date",
	DATETIME: "DateTime",
	DOUBLE: "Number",
	INTEGER: "Number",
	LONG: "Number",
	PERCENT: "Number",
	TIME: "Time"
};
// Flow saves Boolean and blank literals as global constants; the definition holds their text
const GLOBAL_CONSTANT_VALUES = {
	"$GlobalConstant.EmptyString": "",
	"$GlobalConstant.False": "false",
	"$GlobalConstant.True": "true"
};
const LOGIC_OPTIONS = [
	{ label: "All Conditions Are Met (AND)", value: "AND" },
	{ label: "Any Condition Is Met (OR)", value: "OR" },
	{ label: "Custom Condition Logic Is Met", value: CUSTOM }
];
const NULL_ORDERS = [
	{ label: "Nulls First", value: "NULLS_FIRST" },
	{ label: "Nulls Last", value: "NULLS_LAST" }
];
// Wording follows Flow Builder's Get Records
const OPERATOR_LABELS = {
	CONTAINS: "Contains",
	ENDS_WITH: "Ends With",
	EQUALS: "Equals",
	EXCLUDES: "Excludes",
	GREATER_OR_EQUAL: "Greater Than or Equal",
	GREATER_THAN: "Greater Than",
	IN: "In",
	INCLUDES: "Includes",
	IS_NOT_NULL: "Is Not Null",
	IS_NULL: "Is Null",
	LESS_OR_EQUAL: "Less Than or Equal",
	LESS_THAN: "Less Than",
	LIKE: "Like",
	NOT_EQUALS: "Does Not Equal",
	NOT_IN: "Not In",
	STARTS_WITH: "Starts With"
};
const COMPARISONS = ["LESS_THAN", "GREATER_THAN", "LESS_OR_EQUAL", "GREATER_OR_EQUAL"];
const NULL_CHECKS = ["IS_NULL", "IS_NOT_NULL"];
// The operators each kind of field offers, in Get Records' order
const OPERATORS = {
	boolean: ["EQUALS", "NOT_EQUALS"],
	id: ["EQUALS", "NOT_EQUALS", "IN", "NOT_IN", ...NULL_CHECKS],
	multipicklist: ["INCLUDES", "EXCLUDES", "EQUALS", "NOT_EQUALS", ...NULL_CHECKS],
	ordered: ["EQUALS", "NOT_EQUALS", ...COMPARISONS, "IN", "NOT_IN", ...NULL_CHECKS],
	text: ["EQUALS", "NOT_EQUALS", "CONTAINS", "STARTS_WITH", "ENDS_WITH", "LIKE", "IN", "NOT_IN", ...NULL_CHECKS],
	// Flow has no Time collections, so Time fields can't use IN
	time: ["EQUALS", "NOT_EQUALS", ...COMPARISONS, ...NULL_CHECKS]
};
const KINDS = {
	BOOLEAN: "boolean",
	CURRENCY: "ordered",
	DATE: "ordered",
	DATETIME: "ordered",
	DOUBLE: "ordered",
	ID: "id",
	INTEGER: "ordered",
	LONG: "ordered",
	MULTIPICKLIST: "multipicklist",
	PERCENT: "ordered",
	REFERENCE: "id",
	TIME: "time"
};
const RECORD_SLOT_PREFIX = "recordCollection";
// Mirrors InvocableSoql.Input's slots: 10 of each, named by type, ex: text1 or numberCollection3
const SLOT_COUNT = 10;
const SLOT_PREFIXES = {
	Boolean: "boolean",
	Date: "date",
	DateTime: "dateTime",
	Number: "number",
	String: "text",
	Time: "time"
};
const RECORD_SLOTS = Array.from({ length: SLOT_COUNT }, (_, index) => `${RECORD_SLOT_PREFIX}${index + 1}`);
const USAGES = [
	// Flow Builder can't save a blank literal, so choosing None removes the option
	{ label: "--None--", value: "" },
	{ label: "All Rows (include deleted and archived records)", value: "ALL_ROWS" },
	{ label: "For Update (lock the records for this transaction)", value: "FOR_UPDATE" }
];

/**
 * @description The kind of field, which picks its operators and value type
 * @param {Object} field The field, from `InvocableSoql.getFields`
 * @returns {String} A key of `OPERATORS`
 */
function toKind(field) {
	return KINDS[field?.type] ?? "text";
}

/**
 * @description Parses the saved definition, filling in anything it lacks
 * @param {String} json The `queryDefinition` input's value
 * @returns {Object} The definition
 */
function parseDefinition(json) {
	let parsed = {};
	try {
		parsed = JSON.parse(json || "{}");
	} catch (error) {
		// A definition edited by hand into invalid JSON starts over, rather than breaking the editor
		parsed = {};
	}
	return { conditions: [], fields: [], orderBy: [], ...parsed };
}

/**
 * @description Custom Property Editor for `SOQL: Get Record(s)` (`InvocableSoql`). Mirrors Flow Builder's Get Records:
 * pick an object, filter it by conditions on its own or its parents' fields, sort it, and choose fields to store, plus
 * the query options Get Records lacks. Saves the query as JSON in `queryDefinition`, and each value that comes from a
 * resource to a free slot input of its type, which the query names.
 */
export default class SoqlQueryEditor extends LightningElement {
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
	 * @description From Flow Builder: the action's generic object types
	 * @type {Array}
	 */
	@api genericTypeMappings;

	accessLevels = ACCESS_LEVELS;
	directions = DIRECTIONS;
	logicOptions = LOGIC_OPTIONS;
	nullOrders = NULL_ORDERS;
	usages = USAGES;
	_definition = parseDefinition();
	_errors = {};
	// Each condition's field, by path, once resolved
	_fields = {};
	_inputVariables = [];
	_isCustomLogic = false;
	_objects = [];
	// The JSON this editor last saved, so Flow Builder echoing it back doesn't reset rows still being filled in
	_savedJson;
	_values = {};

	// **** GETTERS **** //
	get accessLevel() {
		return this._values.accessLevel?.value ?? "USER_MODE";
	}

	get conditionLogic() {
		return this._definition.conditionLogic;
	}

	get conditions() {
		return this._definition.conditions.map((condition, index) => this._initCondition(condition, index));
	}

	get elementName() {
		return this.elementInfo?.apiName;
	}

	get errors() {
		return this._errors;
	}

	get fields() {
		return this._definition.fields.map((field, index) => ({ key: `${index}:${field}`, index, value: field }));
	}

	get hasConditions() {
		return this._definition.conditions.length > 0;
	}

	get isCustomLogic() {
		return this.logicMode === CUSTOM;
	}

	get logicMode() {
		const logic = this._definition.conditionLogic?.trim()?.toUpperCase() || "AND";
		const isPreset = logic === "AND" || logic === "OR";
		return isPreset && !this._isCustomLogic ? logic : CUSTOM;
	}

	get objectApiName() {
		return this._definition.objectApiName;
	}

	get objectLabel() {
		const object = this._objects.find((candidate) => candidate.value === this.objectApiName);
		return object?.label ?? this.objectApiName;
	}

	get objectOptions() {
		return this._objects;
	}

	get orderBy() {
		return this._definition.orderBy.map((sortOrder, index) => ({
			...sortOrder,
			key: `${index}:${sortOrder.field}`,
			index,
			direction: sortOrder.direction ?? "ASCENDING",
			nullOrder: sortOrder.nullOrder ?? "NULLS_LAST"
		}));
	}

	get rowLimit() {
		return this._definition.rowLimit;
	}

	get rowOffset() {
		return this._definition.rowOffset;
	}

	get usage() {
		return this._definition.usage ?? "";
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
		const json = this._values.queryDefinition?.value;
		if (json !== this._savedJson) {
			this._savedJson = json;
			this._definition = parseDefinition(json);
			this._resolveFields();
		}
	}

	// **** API METHODS **** //
	/**
	 * @description Flow Builder calls this when the panel closes and before saving; any error badges the element and
	 * blocks activation, so only queries the action can't run are flagged
	 * @returns {Array} `{ key, errorString }` for each problem; empty when the query is valid
	 */
	@api
	validate() {
		const objectError = this.objectApiName ? null : { key: "objectApiName", errorString: REQUIRED_ERROR };
		const conditionErrors = this._definition.conditions.map((condition, index) =>
			this._validateCondition(condition, index)
		);
		const errors = [objectError, ...conditionErrors, this._validateLogic()].filter(Boolean);
		const errorEntries = errors.map((error) => [error.key, error.errorString]);
		this._errors = Object.fromEntries(errorEntries);
		return errors;
	}

	// **** WIRED **** //
	/**
	 * @description Lists the objects the running user can query, by label like Get Records
	 * @param {Object} response The wire's `{ data, error }`
	 */
	@wire(getObjects)
	wiredObjects(response) {
		const options = (response?.data ?? []).map((object) => ({
			label: object.label,
			value: object.apiName,
			description: object.apiName,
			icon: "utility:record"
		}));
		this._objects = options.sort(compareLabels);
	}

	// **** HANDLERS **** //
	/**
	 * @description Saves the access level
	 * @param {CustomEvent} event Change on the access level combobox
	 */
	handleAccessLevelChange(event) {
		this._saveInput("accessLevel", event.detail.value, "String");
	}

	/**
	 * @description Adds an empty condition
	 */
	handleAddCondition() {
		this._updateDefinition({ conditions: [...this._definition.conditions, { field: null, operator: null }] });
	}

	/**
	 * @description Adds an empty field to store
	 */
	handleAddField() {
		this._updateDefinition({ fields: [...this._definition.fields, null] });
	}

	/**
	 * @description Adds an empty sort field
	 */
	handleAddSort() {
		this._updateDefinition({ orderBy: [...this._definition.orderBy, { field: null }] });
	}

	/**
	 * @description Saves a condition's field, resetting its operator and value, which may not suit the new field
	 * @param {CustomEvent} event Change on a condition's field path: `{ value, field }`
	 */
	handleConditionFieldChange(event) {
		const index = Number(event.target.dataset.index);
		const { value, field } = event.detail;
		this._fields = { ...this._fields, [value]: field };
		this._releaseSlot(this._definition.conditions[index]);
		const operator = value ? OPERATORS[toKind(field)][0] : null;
		this._replaceCondition(index, { field: value, operator });
	}

	/**
	 * @description Saves a condition's value: a resource goes to a slot input; anything else stays in the definition
	 * @param {CustomEvent} event Change on a condition's value picker: `{ value, valueDataType, objectType }`
	 */
	handleConditionValueChange(event) {
		const index = Number(event.target.dataset.index);
		const { value, valueDataType, objectType } = event.detail;
		const condition = this._definition.conditions[index];
		const isReference = valueDataType === REFERENCE;
		if (isReference) {
			this._saveSlotValue(index, value, objectType);
		} else {
			this._releaseSlot(condition);
			this._replaceCondition(index, this._initLiteral(condition, value));
		}
	}

	/**
	 * @description Saves custom condition logic, ex: `1 AND (2 OR 3)`
	 * @param {CustomEvent} event Change on the condition logic input
	 */
	handleCustomLogicChange(event) {
		this._updateDefinition({ conditionLogic: event.detail.value });
	}

	/**
	 * @description Saves a field to store
	 * @param {CustomEvent} event Change on a field path: `{ value }`
	 */
	handleFieldChange(event) {
		const index = Number(event.target.dataset.index);
		const fields = [...this._definition.fields];
		fields[index] = event.detail.value;
		this._updateDefinition({ fields });
	}

	/**
	 * @description Saves the row limit, or removes it when cleared
	 * @param {CustomEvent} event Change on the limit input
	 */
	handleLimitChange(event) {
		this._updateDefinition({ rowLimit: this._toInteger(event.detail.value) });
	}

	/**
	 * @description Switches between AND, OR, and custom logic; custom logic starts as AND of every condition, like
	 * Flow Builder
	 * @param {CustomEvent} event Change on the condition requirements combobox
	 */
	handleLogicChange(event) {
		const mode = event.detail.value;
		const numbers = this._definition.conditions.map((condition, index) => index + 1);
		this._isCustomLogic = mode === CUSTOM;
		this._updateDefinition({ conditionLogic: mode === CUSTOM ? numbers.join(" AND ") : mode });
	}

	/**
	 * @description Switches the object, starting the query over, since its fields belong to the old object
	 * @param {CustomEvent} event Change on the object picker
	 */
	handleObjectChange(event) {
		const objectApiName = event.detail.value;
		if (objectApiName !== this.objectApiName) {
			this._definition.conditions.forEach((condition) => this._releaseSlot(condition));
			this._isCustomLogic = false;
			this._updateDefinition({ ...parseDefinition(), objectApiName });
			this._setGenericTypes(objectApiName);
		}
	}

	/**
	 * @description Saves the row offset, or removes it when cleared
	 * @param {CustomEvent} event Change on the offset input
	 */
	handleOffsetChange(event) {
		this._updateDefinition({ rowOffset: this._toInteger(event.detail.value) });
	}

	/**
	 * @description Saves a condition's operator, clearing a value that doesn't suit it, ex: text for IN
	 * @param {CustomEvent} event Change on a condition's operator combobox
	 */
	handleOperatorChange(event) {
		const index = Number(event.target.dataset.index);
		const condition = this._definition.conditions[index];
		const operator = event.detail.value;
		const field = this._fields[condition.field];
		const isSameValueType = this._getValueKey(field, operator) === this._getValueKey(field, condition.operator);
		if (!isSameValueType) {
			this._releaseSlot(condition);
		}
		const cleared = { field: condition.field, operator };
		this._replaceCondition(index, isSameValueType ? { ...condition, operator } : cleared);
	}

	/**
	 * @description Removes a condition, and its slot input
	 * @param {Event} event Click on a condition's remove button
	 */
	handleRemoveCondition(event) {
		const index = Number(event.target.dataset.index);
		this._releaseSlot(this._definition.conditions[index]);
		this._updateDefinition({ conditions: this._definition.conditions.filter((_, position) => position !== index) });
	}

	/**
	 * @description Removes a field to store
	 * @param {Event} event Click on a field's remove button
	 */
	handleRemoveField(event) {
		const index = Number(event.target.dataset.index);
		this._updateDefinition({ fields: this._definition.fields.filter((_, position) => position !== index) });
	}

	/**
	 * @description Removes a sort field
	 * @param {Event} event Click on a sort field's remove button
	 */
	handleRemoveSort(event) {
		const index = Number(event.target.dataset.index);
		this._updateDefinition({ orderBy: this._definition.orderBy.filter((_, position) => position !== index) });
	}

	/**
	 * @description Saves a sort field's field, direction, or null order, named by the input's `data-property`
	 * @param {CustomEvent} event Change on a sort field's input
	 */
	handleSortChange(event) {
		const { index, property } = event.target.dataset;
		const orderBy = [...this._definition.orderBy];
		orderBy[Number(index)] = { ...orderBy[Number(index)], [property]: event.detail.value };
		this._updateDefinition({ orderBy });
	}

	/**
	 * @description Saves ALL ROWS or FOR UPDATE, or removes it when None is chosen
	 * @param {CustomEvent} event Change on the rows combobox
	 */
	handleUsageChange(event) {
		this._updateDefinition({ usage: event.detail.value || null });
	}

	// **** PRIVATE **** //
	/**
	 * @description Fires a Custom Property Editor event to Flow Builder
	 * @param {String} type The event type
	 * @param {Object} detail The event's details
	 */
	_dispatch(type, detail) {
		this.dispatchEvent(new CustomEvent(type, { bubbles: true, cancelable: false, composed: true, detail }));
	}

	/**
	 * @description Finds the lowest slot of a type that no other condition uses
	 * @param {String} prefix The slot type, ex: `text` or `recordCollection`
	 * @param {Number} index The condition taking the slot, whose own slot counts as free
	 * @returns {String} The slot's name, or null when all of them are taken
	 */
	_findFreeSlot(prefix, index) {
		const used = this._definition.conditions
			.filter((condition, position) => position !== index)
			.map((condition) => condition.slot);
		const names = Array.from({ length: SLOT_COUNT }, (_, position) => `${prefix}${position + 1}`);
		return names.find((name) => !used.includes(name)) ?? null;
	}

	/**
	 * @description The value input a field and operator need; conditions whose operator changes keep their value only
	 * when this stays the same
	 * @param {Object} field The condition's field
	 * @param {String} operator The condition's operator
	 * @returns {String} A key for the value's type and shape
	 */
	_getValueKey(field, operator) {
		const target = this._initTarget(field, operator);
		return target ? `${target.type}:${target.isCollection}:${target.isPicklistOnly}` : null;
	}

	/**
	 * @description Combines a condition with what its row shows: operators, value input, and saved value
	 * @param {Object} condition The saved condition
	 * @param {Number} index The condition's position
	 * @returns {Object} The row, ready for the template
	 */
	_initCondition(condition, index) {
		const field = this._fields[condition.field];
		const operators = condition.field ? OPERATORS[toKind(field)] : [];
		const target = this._initTarget(field, condition.operator);
		const slotValue = condition.slot ? this._values[condition.slot]?.value : null;
		const literal = condition.dateLiteral ?? condition.values?.[0] ?? condition.value;
		return {
			key: `${index}:${condition.field}`,
			index,
			number: index + 1,
			field: condition.field,
			operator: condition.operator,
			operatorOptions: operators.map((operator) => ({ label: OPERATOR_LABELS[operator], value: operator })),
			hasValue: Boolean(target),
			target: target ?? {},
			value: slotValue ?? literal,
			valueDataType: slotValue ? REFERENCE : "String",
			errorMessage: this._errors[`condition-${index}`]
		};
	}

	/**
	 * @description Saves a typed or picked value in the definition: a date literal, an INCLUDES or EXCLUDES value, or
	 * any other literal
	 * @param {Object} condition The condition
	 * @param {String} value The value, or null to clear it
	 * @returns {Object} The condition, with the value
	 */
	_initLiteral(condition, value) {
		const text = GLOBAL_CONSTANT_VALUES[value] ?? value;
		const isDateField = ["DATE", "DATETIME"].includes(this._fields[condition.field]?.type);
		const isDateLiteral = isDateField && DATE_LITERAL_PATTERN.test(text ?? "");
		const isMultiValue = ["INCLUDES", "EXCLUDES"].includes(condition.operator);
		const base = { field: condition.field, operator: condition.operator };
		const literal = isMultiValue ? { values: [text] } : { value: text };
		const saved = isDateLiteral ? { dateLiteral: text } : literal;
		return text == null ? base : { ...base, ...saved };
	}

	/**
	 * @description The value input a condition needs: none for null checks; picklist values only for INCLUDES and
	 * EXCLUDES; a collection for IN and NOT IN, which takes record collections on ID fields; else one value
	 * @param {Object} field The condition's field
	 * @param {String} operator The condition's operator
	 * @returns {Object} Properties for `c-flow-resource-picker`, or null when the operator takes no value
	 */
	_initTarget(field, operator) {
		const kind = toKind(field);
		const type = FLOW_TYPES[field?.type] ?? "String";
		const isCollection = ["IN", "NOT_IN"].includes(operator);
		const isPicklistOnly = ["INCLUDES", "EXCLUDES"].includes(operator);
		const isDate = type === "Date" || type === "DateTime";
		const fieldValues = (field?.picklistValues ?? []).map(({ label, value }) => ({ label, value }));
		const picklistValues = isDate && !isCollection ? DATE_LITERALS : fieldValues;
		const target = {
			acceptsRecords: isCollection && kind === "id",
			allowsDateLiterals: isDate,
			isCollection,
			isPicklistOnly,
			picklistValues: isCollection ? [] : picklistValues,
			type
		};
		return operator && !NULL_CHECKS.includes(operator) ? target : null;
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
	 * @description Removes a condition's slot input, once the condition stops using it
	 * @param {Object} condition The condition
	 */
	_releaseSlot(condition) {
		if (condition?.slot) {
			this._dispatch("configuration_editor_input_value_deleted", { name: condition.slot });
		}
	}

	/**
	 * @description Replaces a condition outright, then saves
	 * @param {Number} index The condition's position
	 * @param {Object} condition The new condition
	 */
	_replaceCondition(index, condition) {
		const conditions = [...this._definition.conditions];
		conditions[index] = condition;
		this._updateDefinition({ conditions });
	}

	/**
	 * @description Looks up each condition's field, so its row offers the right operators and values
	 */
	async _resolveFields() {
		const { objectApiName, conditions } = this._definition;
		const paths = conditions.map((condition) => condition.field).filter(Boolean);
		const fields = await Promise.all(paths.map((path) => resolveField(objectApiName, path)));
		const entries = paths.map((path, index) => [path, fields[index]]);
		this._fields = { ...this._fields, ...Object.fromEntries(entries) };
	}

	/**
	 * @description Saves the definition as JSON, without rows still being filled in
	 */
	_saveDefinition() {
		const { fields, orderBy } = this._definition;
		const definition = {
			...this._definition,
			fields: fields.filter(Boolean),
			orderBy: orderBy.filter((sortOrder) => sortOrder.field)
		};
		this._savedJson = JSON.stringify(definition);
		this._saveInput("queryDefinition", this._savedJson, "String");
	}

	/**
	 * @description Saves a value to the action, or removes it when cleared
	 * @param {String} name The input's name
	 * @param {String} value The value
	 * @param {String} valueDataType The value's data type
	 */
	_saveInput(name, value, valueDataType) {
		if (value == null || value === "") {
			this._dispatch("configuration_editor_input_value_deleted", { name });
		} else {
			this._dispatch("configuration_editor_input_value_changed", {
				name,
				newValue: value,
				newValueDataType: valueDataType
			});
		}
	}

	/**
	 * @description Saves a resource to the condition's slot, keeping its slot if the type is unchanged. Record
	 * collections also type their slot's generic input to their object, which Flow Builder needs to save the flow.
	 * @param {Number} index The condition's position
	 * @param {String} reference The resource
	 * @param {String} objectType A record collection's object
	 */
	_saveSlotValue(index, reference, objectType) {
		const condition = this._definition.conditions[index];
		const target = this._initTarget(this._fields[condition.field], condition.operator);
		const typePrefix = SLOT_PREFIXES[target.type] + (target.isCollection ? "Collection" : "");
		const prefix = objectType ? RECORD_SLOT_PREFIX : typePrefix;
		const slot = this._findFreeSlot(prefix, index);
		const tooManyError = `This action takes up to ${SLOT_COUNT} resources of this type.`;
		this._errors = { ...this._errors, [`condition-${index}`]: slot ? undefined : tooManyError };
		if (slot) {
			if (condition.slot !== slot) {
				this._releaseSlot(condition);
			}
			this._saveInput(slot, reference, REFERENCE);
			this._values = { ...this._values, [slot]: { name: slot, value: reference, valueDataType: REFERENCE } };
			this._replaceCondition(index, { field: condition.field, operator: condition.operator, slot });
			this._setGenericType(`T__${slot}`, objectType);
		}
	}

	/**
	 * @description Types one of the action's generic inputs or outputs to an object
	 * @param {String} typeName The generic type, ex: `U__records`
	 * @param {String} typeValue The object, ex: `Account`
	 */
	_setGenericType(typeName, typeValue) {
		if (typeValue) {
			this._dispatch("configuration_editor_generic_type_mapping_changed", { typeName, typeValue });
		}
	}

	/**
	 * @description Types the outputs to the queried object, and the record collection slots too, since Flow Builder
	 * needs every generic input typed before it can save the flow; a slot in use is retyped when it gets its value
	 * @param {String} objectApiName The queried object
	 */
	_setGenericTypes(objectApiName) {
		const typeNames = ["U__record", "U__records", ...RECORD_SLOTS.map((slot) => `T__${slot}`)];
		typeNames.forEach((typeName) => this._setGenericType(typeName, objectApiName));
	}

	/**
	 * @description Reads a number input, which blank clears
	 * @param {String} value The input's value
	 * @returns {Number} The whole number, or null
	 */
	_toInteger(value) {
		return value === "" || value == null ? null : parseInt(value, 10);
	}

	/**
	 * @description Merges changes into the definition, then saves it; a fixed input clears its own error, since errors
	 * only refresh in validate()
	 * @param {Object} changes The definition's new properties
	 */
	_updateDefinition(changes) {
		this._definition = { ...this._definition, ...changes };
		this._saveDefinition();
	}

	/**
	 * @description Checks that a condition has a field, an operator, and a value when its operator needs one
	 * @param {Object} condition The condition
	 * @param {Number} index The condition's position
	 * @returns {Object} An error, or null
	 */
	_validateCondition(condition, index) {
		const needsValue = !NULL_CHECKS.includes(condition.operator);
		const hasValue =
			Boolean(condition.slot) || condition.value != null || condition.values || condition.dateLiteral;
		const isComplete = condition.field && condition.operator && (hasValue || !needsValue);
		return isComplete ? null : { key: `condition-${index}`, errorString: REQUIRED_ERROR };
	}

	/**
	 * @description Checks custom logic: only condition numbers, AND, OR, NOT, and parentheses, with each number naming
	 * a condition
	 * @returns {Object} An error, or null
	 */
	_validateLogic() {
		const logic = this._definition.conditionLogic ?? "";
		const numbers = logic.match(/\d+/g) ?? [];
		const count = this._definition.conditions.length;
		const isValidText = /^(\s|\d+|AND|OR|NOT|\(|\))*$/i.test(logic);
		const isInRange = numbers.every((number) => Number(number) >= 1 && Number(number) <= count);
		const isValid = !this.isCustomLogic || (logic.trim() !== "" && isValidText && isInRange);
		return isValid
			? null
			: { key: "conditionLogic", errorString: "Enter valid condition logic, ex: 1 AND (2 OR 3)." };
	}
}
