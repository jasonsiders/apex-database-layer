import { api, wire } from "lwc";
import getObjects from "@salesforce/apex/InvocableSoql.getObjects";
import { DATE_LITERAL_PATTERN, REFERENCE, REQUIRED_ERROR, compareLabels, toBooleanConstant } from "c/flowResourceMenu";
import FlowPropertyEditor, { ACCESS_LEVELS, NONE_OPTION } from "c/flowPropertyEditor";
import { resolveField } from "c/soqlFieldMenu";
import {
	OPERATORS,
	RECORD_SLOT_PREFIX,
	SLOT_COUNT,
	SLOT_PREFIXES,
	dropCoveredFields,
	hasMixedOperators,
	isWellFormed,
	parseDefinition,
	toCoveredPaths,
	toKind,
	toSlotNames,
	toValueField,
	validateRange
} from "c/soqlQueryDefinition";

/** @description Help for the Access Level input, matching its description in Apex */
const ACCESS_LEVEL_HELP =
	"USER_MODE (default) enforces the running user's object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores object permissions and field-level security, but sharing rules still apply unless the InvocableSoqlSystemModeWithoutSharing parameter is true.";
const CUSTOM = "CUSTOM";
// Condition Requirements for a query without a WHERE clause
const NO_FILTER = "NONE";
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
// Flow saves Boolean and blank literals as global constants; the definition holds their text. A Map, since typed text
// like "toString" would read an inherited property of an object
const GLOBAL_CONSTANT_VALUES = new Map([
	["$GlobalConstant.EmptyString", ""],
	["$GlobalConstant.False", "false"],
	["$GlobalConstant.True", "true"]
]);
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
	IS_NULL: "Is Null",
	LESS_OR_EQUAL: "Less Than or Equal",
	LESS_THAN: "Less Than",
	LIKE: "Like",
	NOT_EQUALS: "Does Not Equal",
	NOT_IN: "Not In",
	STARTS_WITH: "Starts With"
};
// Operators that take a collection, and those that take INCLUDES or EXCLUDES picklist values
const COLLECTION_OPERATORS = ["IN", "NOT_IN"];
const MULTI_VALUE_OPERATORS = ["INCLUDES", "EXCLUDES"];
// Combobox options for each kind's operators, built once
const OPERATOR_OPTIONS = Object.fromEntries(
	Object.entries(OPERATORS).map(([kind, operators]) => [
		kind,
		operators.map((operator) => ({ label: OPERATOR_LABELS[operator], value: operator }))
	])
);
const RECORD_SLOTS = toSlotNames(RECORD_SLOT_PREFIX);
// The Limit and Offset inputs' bounds, which they show but don't enforce; SOQL rejects an offset over 2,000
const ROW_LIMIT_RANGE = { min: 1, max: 50000, errorString: "Enter a whole-number limit from 1 to 50,000." };
const ROW_OFFSET_RANGE = {
	min: 0,
	max: 2000,
	errorString: "Enter a whole-number offset from 0 to 2,000, the most SOQL can skip."
};
const USAGES = [
	NONE_OPTION,
	{ label: "All Rows (include deleted and archived records)", value: "ALL_ROWS" },
	{ label: "For Update (lock the records for this transaction)", value: "FOR_UPDATE" }
];

/**
 * @description Custom Property Editor for `SOQL: Get Record(s)` (`InvocableSoql`). Mirrors Flow Builder's Get Records:
 * pick an object, filter it by conditions on its own or its parents' fields, sort it, and choose fields to store, plus
 * the query options Get Records lacks. Saves the query as JSON in `queryDefinition`, and each value that comes from a
 * resource to a free slot input of its type, which the query names.
 */
export default class SoqlQueryEditor extends FlowPropertyEditor {
	accessLevelHelp = ACCESS_LEVEL_HELP;
	accessLevels = ACCESS_LEVELS;
	directions = DIRECTIONS;
	nullOrders = NULL_ORDERS;
	rowLimitRange = ROW_LIMIT_RANGE;
	rowOffsetRange = ROW_OFFSET_RANGE;
	usages = USAGES;
	_definition = parseDefinition();
	// Each condition's field, by path, once resolved
	_fields = {};
	// Once Flow Builder validates, errors track each change, so a fixed problem's error clears
	_hasValidated = false;
	_isCustomLogic = false;
	_objects = [];
	// The JSON this editor last saved, so Flow Builder echoing it back doesn't reset rows still being filled in
	_savedJson;

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

	get errors() {
		return this._errors;
	}

	get fields() {
		return this._definition.fields.map((field, index) => ({
			key: `${index}:${field}`,
			index,
			value: field,
			coveredPaths: this._findCoveredPaths(index)
		}));
	}

	get isCustomLogic() {
		return this.logicMode === CUSTOM;
	}

	get isFiltered() {
		return this.logicMode !== NO_FILTER;
	}

	get logicMode() {
		const logic = this._definition.conditionLogic?.trim()?.toUpperCase() || "AND";
		const isPreset = logic === "AND" || logic === "OR";
		const presetMode = this._definition.conditions.length ? logic : NO_FILTER;
		return isPreset && !this._isCustomLogic ? presetMode : CUSTOM;
	}

	get logicOptions() {
		const none = { label: `None—Get All ${this._getObjectLabel()} Records`, value: NO_FILTER };
		return [none, ...LOGIC_OPTIONS];
	}

	get objectApiName() {
		return this._definition.objectApiName;
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

	get sectionLabels() {
		const label = this._getObjectLabel();
		return {
			filter: `Filter ${label} Records`,
			sort: `Sort and Limit ${label} Records`,
			fields: `Select ${label} Fields to Store`
		};
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
		this._hasValidated = true;
		return this._refreshErrors();
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
	 * @description Adds an empty condition; custom logic gains ` AND n`, so the new condition applies, like Flow
	 * Builder
	 */
	handleAddCondition() {
		const conditions = [...this._definition.conditions, { field: null, operator: null }];
		const logic = this._definition.conditionLogic;
		// Parenthesized, since SOQL can't mix AND and OR without parentheses, ex: `(1 OR 2) AND 3`
		const appended = logic?.trim() ? `(${logic}) AND ${conditions.length}` : String(conditions.length);
		const conditionLogic = this.isCustomLogic ? appended : logic;
		this._updateDefinition({ conditions, conditionLogic });
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
	 * @description Saves a field to store, dropping any the rows' All Fields selections already store
	 * @param {CustomEvent} event Change on a field path: `{ value }`
	 */
	handleFieldChange(event) {
		const index = Number(event.target.dataset.index);
		const fields = [...this._definition.fields];
		fields[index] = event.detail.value;
		const keptFields = dropCoveredFields(fields);
		this._updateDefinition({ fields: keptFields });
	}

	/**
	 * @description Saves the row limit, or removes it when cleared
	 * @param {CustomEvent} event Change on the limit input
	 */
	handleLimitChange(event) {
		const rowLimit = this._toNumber(event.detail.value);
		this._updateDefinition({ rowLimit });
	}

	/**
	 * @description Switches between no filter, AND, OR, and custom logic; no filter removes every condition, and its
	 * slots
	 * @param {CustomEvent} event Change on the condition requirements combobox
	 */
	handleLogicChange(event) {
		const mode = event.detail.value;
		this._isCustomLogic = mode === CUSTOM;
		if (mode === NO_FILTER) {
			this._releaseAllSlots();
			this._updateDefinition({ conditions: [], conditionLogic: "AND" });
		} else {
			this._filterBy(mode);
		}
	}

	/**
	 * @description Switches the object, starting the query over, since its fields belong to the old object
	 * @param {CustomEvent} event Change on the object picker
	 */
	handleObjectChange(event) {
		const objectApiName = event.detail.value;
		if (objectApiName !== this.objectApiName) {
			this._releaseAllSlots();
			this._isCustomLogic = false;
			// Replaced, not merged, so the old object's logic and options go too
			this._definition = parseDefinition();
			this._updateDefinition({ objectApiName });
			this._setGenericTypes(objectApiName);
		}
	}

	/**
	 * @description Saves the row offset, or removes it when cleared
	 * @param {CustomEvent} event Change on the offset input
	 */
	handleOffsetChange(event) {
		const rowOffset = this._toNumber(event.detail.value);
		this._updateDefinition({ rowOffset });
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
		const removed = index + 1;
		this._releaseSlot(this._definition.conditions[index]);
		// Later conditions move up a number; a reference to the removed one becomes `?`, which validate() flags
		const renumber = (text) => {
			const number = Number(text);
			return number === removed ? "?" : String(number > removed ? number - 1 : number);
		};
		const logic = this._definition.conditionLogic;
		const conditions = this._definition.conditions.filter((_, position) => position !== index);
		const conditionLogic = this.isCustomLogic ? logic.replace(/\d+/g, renumber) : logic;
		this._updateDefinition({ conditions, conditionLogic });
	}

	/**
	 * @description Removes a field to store
	 * @param {Event} event Click on a field's remove button
	 */
	handleRemoveField(event) {
		const index = Number(event.target.dataset.index);
		const fields = this._definition.fields.filter((_, position) => position !== index);
		this._updateDefinition({ fields });
	}

	/**
	 * @description Removes a sort field
	 * @param {Event} event Click on a sort field's remove button
	 */
	handleRemoveSort(event) {
		const index = Number(event.target.dataset.index);
		const orderBy = this._definition.orderBy.filter((_, position) => position !== index);
		this._updateDefinition({ orderBy });
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
	 * @description Filters by AND, OR, or custom logic, starting a condition when there are none, like Get Records;
	 * custom logic starts as AND of every condition
	 * @param {String} mode `AND`, `OR`, or `CUSTOM`
	 */
	_filterBy(mode) {
		const existing = this._definition.conditions;
		const conditions = existing.length ? existing : [{ field: null, operator: null }];
		const numbers = conditions.map((condition, index) => index + 1);
		this._updateDefinition({ conditions, conditionLogic: mode === CUSTOM ? numbers.join(" AND ") : mode });
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
		return toSlotNames(prefix).find((name) => !used.includes(name)) ?? null;
	}

	/**
	 * @description Lists the paths other rows store all the fields of, so a row's picker offers only their parents
	 * @param {Number} index The row
	 * @returns {Array} The paths, ex: `["", "Account"]` for `*` and `Account.*`
	 */
	_findCoveredPaths(index) {
		const otherFields = this._definition.fields.filter((_, position) => position !== index);
		return toCoveredPaths(otherFields);
	}

	/**
	 * @description The chosen object's label, for the section headings and None option
	 * @returns {String} The label, or the API name until the objects load
	 */
	_getObjectLabel() {
		const object = this._objects.find((candidate) => candidate.value === this.objectApiName);
		return object?.label ?? this.objectApiName;
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
		const operatorOptions = condition.field ? OPERATOR_OPTIONS[toKind(field)] : [];
		const target = this._initTarget(field, condition.operator);
		const slotValue = condition.slot ? this._values[condition.slot]?.value : null;
		const literal = condition.dateLiteral ?? condition.values?.[0] ?? condition.value;
		// Like Get Records, later rows read AND or OR, and custom logic numbers every row
		const joiner = index > 0 ? this.logicMode : "";
		return {
			key: `${index}:${condition.field}`,
			index,
			prefix: this.isCustomLogic ? String(index + 1) : joiner,
			field: condition.field,
			isOperatorDisabled: !condition.field,
			operator: condition.operator,
			operatorOptions,
			hasValue: Boolean(target),
			target: target ?? {},
			value: slotValue ?? literal,
			valueDataType: slotValue ? REFERENCE : "String",
			errorMessage: condition.error ?? this._errors[`condition-${index}`]
		};
	}

	/**
	 * @description Saves a typed or picked value in the definition: a date literal, an INCLUDES or EXCLUDES value, a
	 * boolean, or any other literal
	 * @param {Object} condition The condition
	 * @param {String} value The value, or null to clear it
	 * @returns {Object} The condition, with the value
	 */
	_initLiteral(condition, value) {
		const fieldType = toValueField(this._fields[condition.field], condition.operator)?.type;
		// A typed boolean saves in lowercase, ex: TRUE as true, which is all Apex's JSON parser reads
		const constant = fieldType === "BOOLEAN" ? (toBooleanConstant(value) ?? value) : value;
		const text = GLOBAL_CONSTANT_VALUES.get(constant) ?? value;
		const isDateField = ["DATE", "DATETIME"].includes(fieldType);
		const isDateLiteral = isDateField && DATE_LITERAL_PATTERN.test(text ?? "");
		const isMultiValue = MULTI_VALUE_OPERATORS.includes(condition.operator);
		const base = { field: condition.field, operator: condition.operator };
		const literal = isMultiValue ? { values: [text] } : { value: text };
		const saved = isDateLiteral ? { dateLiteral: text } : literal;
		return text == null ? base : { ...base, ...saved };
	}

	/**
	 * @description The value input a condition needs: True or False for Is Null; picklist values only for INCLUDES
	 * and EXCLUDES; a collection for IN and NOT IN, which also takes record collections of the field's object on ID
	 * fields, or of any object on polymorphic lookups; else one value
	 * @param {Object} conditionField The condition's field
	 * @param {String} operator The condition's operator
	 * @returns {Object} Properties for `c-flow-resource-picker`, or null until an operator is picked
	 */
	_initTarget(conditionField, operator) {
		const field = toValueField(conditionField, operator);
		const type = FLOW_TYPES[field?.type] ?? "String";
		const isCollection = COLLECTION_OPERATORS.includes(operator);
		const isDate = type === "Date" || type === "DateTime";
		const picklistValues = isDate ? DATE_LITERALS : (field?.picklistValues ?? []);
		const target = {
			acceptsRecords: isCollection && toKind(field) === "id",
			allowsDateLiterals: isDate,
			isCollection,
			isPicklistOnly: MULTI_VALUE_OPERATORS.includes(operator),
			// The object whose IDs the field holds; a lookup to several objects takes collections of any of them
			objectType: field?.isPolymorphic ? null : field?.referenceTo,
			picklistValues: isCollection ? [] : picklistValues,
			type
		};
		return operator ? target : null;
	}

	/**
	 * @description Finds the query's problems, and shows each by its input
	 * @returns {Array} `{ key, errorString }` for each problem; empty when the query is valid
	 */
	_refreshErrors() {
		const objectError = this.objectApiName ? null : { key: "objectApiName", errorString: REQUIRED_ERROR };
		const conditionErrors = this._definition.conditions.map((condition, index) =>
			this._validateCondition(condition, index)
		);
		const logicError = this._validateLogic();
		const usageError = this._validateUsage();
		const limitError = validateRange("rowLimit", this.rowLimit, ROW_LIMIT_RANGE);
		const offsetError = validateRange("rowOffset", this.rowOffset, ROW_OFFSET_RANGE);
		const checks = [objectError, ...conditionErrors, logicError, limitError, offsetError, usageError];
		return this._setErrors(checks);
	}

	/**
	 * @description Removes every condition's slot input, before the conditions are cleared
	 */
	_releaseAllSlots() {
		this._definition.conditions.forEach((condition) => this._releaseSlot(condition));
	}

	/**
	 * @description Removes a condition's slot input, once the condition stops using it
	 * @param {Object} condition The condition
	 */
	_releaseSlot(condition) {
		if (condition?.slot) {
			this._deleteInput(condition.slot);
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
		const requests = paths.map((path) => resolveField(objectApiName, path));
		const fields = await Promise.all(requests);
		const entries = paths.map((path, index) => [path, fields[index]]);
		this._fields = { ...this._fields, ...Object.fromEntries(entries) };
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
		if (slot) {
			if (condition.slot !== slot) {
				this._releaseSlot(condition);
			}
			this._saveInput(slot, reference, REFERENCE);
			this._values = { ...this._values, [slot]: { name: slot, value: reference, valueDataType: REFERENCE } };
			this._replaceCondition(index, { field: condition.field, operator: condition.operator, slot });
			this._setGenericType(`T__${slot}`, objectType);
		} else {
			// Keeping the old value would save it in place of the picked resource, once Done clears the error
			const error = `This action takes up to ${SLOT_COUNT} resources of this type.`;
			this._releaseSlot(condition);
			this._replaceCondition(index, { field: condition.field, operator: condition.operator, error });
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
	 * @description Reads a number input, which blank clears. A fraction stays as typed, so validate flags it
	 * @param {String} value The input's value
	 * @returns {Number} The number, or null
	 */
	_toNumber(value) {
		return value === "" || value == null ? null : Number(value);
	}

	/**
	 * @description Merges changes into the definition, then saves it as JSON, without rows still being filled in
	 * @param {Object} changes The definition's new properties
	 */
	_updateDefinition(changes) {
		this._definition = { ...this._definition, ...changes };
		const { conditions, fields, orderBy } = this._definition;
		const definition = {
			...this._definition,
			// A condition's error stays with its row, not the saved definition
			conditions: conditions.map((condition) => ({ ...condition, error: undefined })),
			fields: fields.filter(Boolean),
			orderBy: orderBy.filter((sortOrder) => sortOrder.field)
		};
		this._savedJson = JSON.stringify(definition);
		this._saveInput("queryDefinition", this._savedJson, "String");
		if (this._hasValidated) {
			this._refreshErrors();
		}
	}

	/**
	 * @description Checks that a condition has a field, an operator, and a value Apex takes
	 * @param {Object} condition The condition
	 * @param {Number} index The condition's position
	 * @returns {Object} An error, or null
	 */
	_validateCondition(condition, index) {
		const hasValue =
			Boolean(condition.slot) || condition.value != null || condition.values || condition.dateLiteral;
		const isComplete = condition.field && condition.operator && hasValue;
		const errorString = isComplete ? this._validateValue(condition) : (condition.error ?? REQUIRED_ERROR);
		return errorString ? { key: `condition-${index}`, errorString } : null;
	}

	/**
	 * @description Checks a typed value: Apex rejects a fraction for a whole-number field
	 * @param {Object} condition A complete condition
	 * @returns {String} An error, or null
	 */
	_validateValue(condition) {
		const fieldType = toValueField(this._fields[condition.field], condition.operator)?.type;
		const isWholeNumber = ["INTEGER", "LONG"].includes(fieldType);
		// Checks the text, since a JS number rounds off a fraction Apex's Decimal keeps, ex: 42.0000000000000001
		const isFraction = isWholeNumber && /\.\d*[1-9]/.test(condition.value ?? "");
		return isFraction ? "Enter a whole number." : null;
	}

	/**
	 * @description Checks custom logic: only condition numbers, AND, OR, NOT, and parentheses, well formed, naming each
	 * condition exactly, since a condition the logic leaves out doesn't apply, with AND and OR in separate parentheses
	 * @returns {Object} An error, or null
	 */
	_validateLogic() {
		const logic = this._definition.conditionLogic ?? "";
		const numbers = new Set((logic.match(/\d+/g) ?? []).map(Number));
		const expected = this._definition.conditions.map((condition, index) => index + 1);
		// \d, not \d+: the group repeats anyway, and \d+ in a repeated group backtracks exponentially on long digit runs
		const isValidText = /^(\s|\d|AND|OR|NOT|\(|\))*$/i.test(logic);
		const isExact = numbers.size === expected.length && expected.every((number) => numbers.has(number));
		const isGrouped = !hasMixedOperators(logic);
		const isValid = !this.isCustomLogic || (isValidText && isWellFormed(logic) && isExact && isGrouped);
		return isValid
			? null
			: { key: "conditionLogic", errorString: "Enter valid condition logic, ex: 1 AND (2 OR 3)." };
	}

	/**
	 * @description Checks the Rows option: SOQL rejects sort fields with For Update, and Apex rejects an offset
	 * @returns {Object} An error, or null
	 */
	_validateUsage() {
		const isSorted = this._definition.orderBy.some((sortOrder) => sortOrder.field);
		const isSkipped = this._definition.rowOffset != null;
		const isLocked = this._definition.usage === "FOR_UPDATE";
		const errorString = isSorted
			? "SOQL can't sort the records it locks. Remove the sort fields, or pick another Rows option."
			: "SOQL can't skip the records it locks. Remove the offset, or pick another Rows option.";
		return isLocked && (isSorted || isSkipped) ? { key: "usage", errorString } : null;
	}
}
