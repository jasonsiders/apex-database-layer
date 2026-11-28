/**
 * @description Builds the menus for `c-soql-field-path` from `InvocableSoql.getFields`: an object's fields, and its
 * parents' fields through its relationships, as deep as SOQL allows.
 */
import getFields from "@salesforce/apex/InvocableSoql.getFields";
import { initSection, parsePath } from "c/flowResourceMenu";

// SOQL rejects a seventh relationship: "cannot query foreign key relationships more than 5 levels away from the root"
const MAX_RELATIONSHIPS = 6;
// Field describes, by object, shared by every picker and the editor; a failed describe is forgotten, so it retries
const FIELDS_BY_OBJECT = new Map();
// Ends the path that stores every field of its object, ex: "Account.*"; InvocableSoql.ALL_FIELDS
const ALL_FIELDS = "*";
const NO_OPTIONS = { parent: null, sections: [] };
const TYPE_ICONS = {
	BOOLEAN: "utility:toggle",
	CURRENCY: "utility:currency",
	DATE: "utility:event",
	DATETIME: "utility:date_time",
	DOUBLE: "utility:topic2",
	INTEGER: "utility:topic2",
	LONG: "utility:topic2",
	MULTIPICKLIST: "utility:multi_picklist",
	PERCENT: "utility:topic2",
	PICKLIST: "utility:picklist_type",
	TIME: "utility:clock"
};

/**
 * @description Describes an object's fields via `InvocableSoql.getFields`, once per object
 * @param {String} objectApiName The object
 * @returns {Promise<Array>} The object's fields
 */
export function loadFields(objectApiName) {
	if (!FIELDS_BY_OBJECT.has(objectApiName)) {
		const request = getFields({ objectApiName }).catch((error) => {
			FIELDS_BY_OBJECT.delete(objectApiName);
			throw error;
		});
		FIELDS_BY_OBJECT.set(objectApiName, request);
	}
	return FIELDS_BY_OBJECT.get(objectApiName);
}

/**
 * @description Finds the field a path names, following its relationships
 * @param {String} objectApiName The object the path starts from
 * @param {String} path A field path, ex: `Account.Owner.Name`
 * @returns {Promise<Object>} The field, or null if the path doesn't resolve
 */
export async function resolveField(objectApiName, path) {
	const segments = path?.split(".") ?? [];
	const name = segments.pop();
	const level = name ? await resolveLevel(objectApiName, segments) : null;
	return level?.fields.find((field) => field.apiName === name) ?? null;
}

/**
 * @description Lists the options under a path for `c-flow-resource-picker`'s `loadOptions`: the relationships to drill
 * into, while SOQL allows another, and the fields to pick
 * @param {String} objectApiName The object the path starts from
 * @param {String} parentPath The relationships drilled into, ex: `Account.Owner`; blank for the object's own fields
 * @param {String} filter `filterable` or `sortable` to offer only fields that can filter or sort; blank for any
 * @param {Array} coveredPaths Paths whose fields are all stored already, ex: `["Account"]`, which offer only
 * relationships
 * @returns {Promise<Object>} `{ parent, sections }`, or no options if the path isn't a chain of relationships
 */
export async function getFieldOptions(objectApiName, parentPath, filter, coveredPaths = []) {
	const segments = parentPath ? parentPath.split(".") : [];
	const level = await resolveLevel(objectApiName, segments);
	const isCovered = coveredPaths.includes(parentPath);
	return level ? { parent: level.option, sections: initSections(level, filter, isCovered) } : NO_OPTIONS;
}

/**
 * @description The path whose fields an All Fields selection stores, ex: "Account" for "Account.*"
 * @param {String} field A stored field
 * @returns {String} The path, blank for the queried object, or null if the field isn't All Fields
 */
export function getAllFieldsPath(field) {
	return field?.endsWith(ALL_FIELDS) ? parsePath(field).parentPath : null;
}

/**
 * @description Follows relationships from an object, stopping where SOQL does
 * @param {String} objectApiName The object to start from
 * @param {Array} segments Relationship names, ex: `["Account", "Owner"]`
 * @returns {Promise<Object>} The last relationship's level, from `initLevel`, or null if a segment isn't a relationship
 */
function resolveLevel(objectApiName, segments) {
	const start = objectApiName ? initLevel(objectApiName, null, 0) : Promise.resolve(null);
	// Each level needs the one above it, so the levels load in order
	return segments.reduce((pending, segment) => pending.then((level) => descendTo(level, segment)), start);
}

/**
 * @description The level below a relationship, by its name, while SOQL allows another
 * @param {Object} level The relationship's level, or null
 * @param {String} segment The relationship name, ex: `Owner`
 * @returns {Promise<Object>} The related object's level, or null if the segment isn't a relationship
 */
function descendTo(level, segment) {
	const relationship = level?.fields.find((field) => isRelationship(field) && field.relationshipName === segment);
	return relationship && level.depth < MAX_RELATIONSHIPS ? descend(level, relationship) : null;
}

/**
 * @description Describes a level's object; one that can't be described has no fields
 * @param {String} objectApiName The level's object
 * @param {Object} option The relationship's option that leads to the level, or null for the starting object
 * @param {Number} depth How many relationships lead to the level
 * @returns {Promise<Object>} `{ objectApiName, option, depth, fields }`
 */
async function initLevel(objectApiName, option, depth) {
	const fields = await loadFields(objectApiName).catch(() => []);
	return { objectApiName, option, depth, fields };
}

/**
 * @description The level below a relationship
 * @param {Object} level The relationship's level
 * @param {Object} relationship The lookup field
 * @returns {Promise<Object>} The related object's level
 */
function descend(level, relationship) {
	const option = initRelationshipOption(relationship, level.option);
	return initLevel(relationship.referenceTo, option, level.depth + 1);
}

/**
 * @description Whether a field is a lookup that a path can follow
 * @param {Object} field The field
 * @returns {Boolean} True if the field has a relationship to drill into
 */
function isRelationship(field) {
	return Boolean(field.relationshipName && field.referenceTo);
}

/**
 * @description Lists a level's options: All Fields, then, like Flow Builder's field menus, lookups, then the other
 * fields, each by label
 * @param {Object} level The level from `resolveLevel`
 * @param {String} filter `filterable` or `sortable` to offer only fields that can filter or sort; blank for any
 * @param {Boolean} isCovered Whether the level's fields are all stored already
 * @returns {Array} An All Fields section, then "Relationship Fields" and "Record Fields"
 */
function initSections(level, filter, isCovered) {
	const isUsable = (field) =>
		!isCovered && (!filter || (filter === "filterable" ? field.isFilterable : field.isSortable));
	const canDrill = level.depth < MAX_RELATIONSHIPS;
	const usable = level.fields.filter(isUsable);
	// A level whose fields are all stored already offers only its parents' fields, through its lookups
	const lookups = level.fields.filter((field) => isRelationship(field) && (canDrill || isUsable(field)));
	const lookupOptions = lookups.map((field) => initLookupOption(field, level.option, isUsable(field), canDrill));
	const recordOptions = usable
		.filter((field) => !isRelationship(field))
		.map((field) => initFieldOption(field, level.option));
	// Conditions and sorts take one field, so only stored fields offer All Fields, and only for an object with fields
	const canSelectAll = !filter && usable.length > 0;
	const allFieldsOptions = canSelectAll ? [initAllFieldsOption(level)] : [];
	// All Fields leads the menu in a section of its own, which has no header, set apart by a divider
	const allFieldsSection = { ...initSection("", allFieldsOptions), hasDivider: true };
	return [
		allFieldsSection,
		initSection("Relationship Fields", lookupOptions),
		initSection("Record Fields", recordOptions)
	];
}

/**
 * @description Extends a parent's path by one step
 * @param {Object} parent The drilled-into relationship's option, or null at the top
 * @param {String} name The step's API name
 * @param {String} label The step's label
 * @returns {Object} `{ value, pathLabel }`, ex: `Account.Name` and `Account > Account Name`
 */
function joinPath(parent, name, label) {
	return parent
		? { value: `${parent.value}.${name}`, pathLabel: `${parent.pathLabel} > ${label}` }
		: { value: name, pathLabel: label };
}

/**
 * @description Builds a level's option for its parent, by its lookup's label, like Flow Builder: `Account ID`
 * @param {Object} field The lookup field
 * @param {Object} parent The drilled-into relationship's option, or null at the top
 * @returns {Object} `{ value, pathLabel }`, ex: `Account` and `Account ID`
 */
function initRelationshipOption(field, parent) {
	return joinPath(parent, field.relationshipName, field.label);
}

/**
 * @description Builds a lookup's option, which, like Flow Builder, selects its ID and drills into its object
 * @param {Object} field The lookup field
 * @param {Object} parent The drilled-into relationship's option, or null at the top
 * @param {Boolean} isSelectable Whether the ID can be picked
 * @param {Boolean} isDrillable Whether SOQL allows another relationship
 * @returns {Object} The option
 */
function initLookupOption(field, parent, isSelectable, isDrillable) {
	const relationship = initRelationshipOption(field, parent);
	return {
		...initFieldOption(field, parent),
		drillValue: relationship.value,
		icon: "utility:record_lookup",
		isSelectable,
		isDrillable
	};
}

/**
 * @description Builds the option that stores every field of a level's object
 * @param {Object} level The level from `resolveLevel`
 * @returns {Object} The option, ex: "Account.*", shown as "Account > All Fields"
 */
function initAllFieldsOption(level) {
	const path = joinPath(level.option, ALL_FIELDS, "All Fields");
	return {
		...path,
		label: "All Fields",
		description: level.objectApiName,
		icon: "utility:list",
		isSelectable: true
	};
}

/**
 * @description Builds the option for a field
 * @param {Object} field The field
 * @param {Object} parent The drilled-into relationship's option, or null at the top
 * @returns {Object} The option
 */
function initFieldOption(field, parent) {
	const path = joinPath(parent, field.apiName, field.label);
	return {
		...path,
		label: field.label,
		description: field.apiName,
		icon: TYPE_ICONS[field.type] ?? "utility:text",
		isSelectable: true
	};
}
