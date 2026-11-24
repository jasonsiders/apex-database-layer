/**
 * @description Reads and checks the query definition that `c-soql-query-editor` saves for `InvocableSoql`: its slot
 * inputs, condition logic, condition fields, and the fields All Fields selections store.
 */
import { parsePath } from "c/flowResourceMenu";
import { getAllFieldsPath } from "c/soqlFieldMenu";

// Mirrors InvocableSoql.Input's slots: 5 of each type, ex: text1 to text5
export const SLOT_COUNT = 5;
// Like Get Records, Is Null takes True or False: False finds the records whose field has a value
const NULL_CHECK_FIELD = { type: "BOOLEAN" };
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

/**
 * @description Names a slot type's slots, ex: `text1` to `text5`, matching `InvocableSoql.Input`
 * @param {String} prefix The slot type, ex: `text`
 * @returns {Array} The slot names
 */
export function toSlotNames(prefix) {
	return Array.from({ length: SLOT_COUNT }, (_, index) => `${prefix}${index + 1}`);
}

/**
 * @description Checks a saved limit or offset against its input's bounds
 * @param {String} key The input's `data-name`
 * @param {Number} value The saved number, or null
 * @param {Object} range `{ min, max, errorString }`
 * @returns {Object} An error, or null
 */
export function validateRange(key, value, range) {
	const isValid = value == null || (value >= range.min && value <= range.max);
	return isValid ? null : { key, errorString: range.errorString };
}

/**
 * @description Whether custom logic mixes AND and OR without parentheses, ex: `1 OR 2 AND 3`, which SOQL rejects
 * @param {String} logic The custom logic
 * @returns {Boolean} True if any one level of parentheses has both AND and OR
 */
export function hasMixedOperators(logic) {
	const levels = [new Set()];
	let isMixed = false;
	for (const token of logic.toUpperCase().match(/AND|OR|\(|\)/g) ?? []) {
		if (token === "(") {
			levels.push(new Set());
		} else if (token === ")") {
			levels.pop();
		} else {
			const level = levels.at(-1) ?? new Set();
			level.add(token);
			isMixed = isMixed || level.size > 1;
		}
	}
	return isMixed;
}

/**
 * @description Whether custom logic is well formed: operands, ex: `1`, `NOT 1`, or `(1 OR 2)`, joined by AND or OR,
 * with balanced parentheses, since SOQL fails every query that isn't
 * @param {String} logic The custom logic
 * @returns {Boolean} True if well formed
 */
export function isWellFormed(logic) {
	let depth = 0;
	let isOperandNext = true;
	let isValid = true;
	for (const token of logic.toUpperCase().match(/\d+|AND|OR|NOT|\(|\)/g) ?? []) {
		const isOperand = token === "NOT" || token === "(" || /^\d+$/.test(token);
		depth += token === "(" ? 1 : 0;
		depth -= token === ")" ? 1 : 0;
		isValid = isValid && isOperand === isOperandNext && depth >= 0;
		isOperandNext = ["AND", "OR", "NOT", "("].includes(token);
	}
	return isValid && !isOperandNext && depth === 0;
}

/**
 * @description The field whose type a condition's value takes: a boolean for Is Null, else the condition's field
 * @param {Object} field The condition's field
 * @param {String} operator The condition's operator
 * @returns {Object} The field, or a stand-in boolean field
 */
export function toValueField(field, operator) {
	return operator === "IS_NULL" ? NULL_CHECK_FIELD : field;
}

/**
 * @description The kind of field, which picks its operators and value type
 * @param {Object} field The field, from `InvocableSoql.getFields`
 * @returns {String} A key of `OPERATORS`
 */
export function toKind(field) {
	return KINDS[field?.type] ?? "text";
}

/**
 * @description Parses the saved definition, filling in anything it lacks
 * @param {String} json The `queryDefinition` input's value
 * @returns {Object} The definition
 */
export function parseDefinition(json) {
	let parsed = {};
	try {
		parsed = JSON.parse(json || "{}");
	} catch {
		// A definition edited by hand into invalid JSON starts over, rather than breaking the editor
		parsed = {};
	}
	return { conditions: [], fields: [], orderBy: [], ...parsed };
}

/**
 * @description Drops the stored fields an All Fields selection already stores, ex: Account.Name beside Account.*
 * @param {Array} fields The stored fields, with null for rows not yet picked
 * @returns {Array} The fields to keep
 */
export function dropCoveredFields(fields) {
	const allFieldsPaths = toCoveredPaths(fields);
	const coveredPaths = new Set(allFieldsPaths);
	return fields.filter((field) => !isCoveredField(field, coveredPaths));
}

/**
 * @description Whether an All Fields selection stores the field already, ex: Account.Name beside Account.*
 * @param {String} field A stored field, or null for a row not yet picked
 * @param {Set} coveredPaths The paths All Fields selections store
 * @returns {Boolean} True if the field is redundant
 */
function isCoveredField(field, coveredPaths) {
	const parentPath = field == null ? null : parsePath(field).parentPath;
	return getAllFieldsPath(field) == null && coveredPaths.has(parentPath);
}

/**
 * @description The paths whose fields All Fields selections store, ex: `["", "Account"]` for `*` and `Account.*`
 * @param {Array} fields The stored fields, with null for rows not yet picked
 * @returns {Array} The paths
 */
export function toCoveredPaths(fields) {
	return fields.map(getAllFieldsPath).filter((path) => path != null);
}
