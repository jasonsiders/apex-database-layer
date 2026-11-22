import { LightningElement, api } from "lwc";
import getFields from "@salesforce/apex/InvocableSoql.getFields";
import { compareLabels, initSection } from "c/flowResourceMenu";

// SOQL rejects a seventh relationship: "cannot query foreign key relationships more than 5 levels away from the root"
const MAX_RELATIONSHIPS = 6;
// Field describes, by object, shared by every picker and the editor; a failed describe is forgotten, so it retries
const FIELDS_BY_OBJECT = new Map();
// Ends the path that stores every field of its object, ex: "Account.*"; InvocableSoqlQuery.ALL_FIELDS
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
 * @returns {Promise<Object>} `{ parent, sections }`, or no options if the path isn't a chain of relationships
 */
export async function getFieldOptions(objectApiName, parentPath, filter) {
	const segments = parentPath ? parentPath.split(".") : [];
	const level = await resolveLevel(objectApiName, segments);
	return level ? { parent: level.option, sections: initSections(level, filter) } : NO_OPTIONS;
}

/**
 * @description Follows relationships from an object, stopping where SOQL does
 * @param {String} objectApiName The object to start from
 * @param {Array} segments Relationship names, ex: `["Account", "Owner"]`
 * @returns {Promise<Object>} The last relationship's level, from `initLevel`, or null if a segment isn't a relationship
 */
async function resolveLevel(objectApiName, segments) {
	let level = objectApiName ? await initLevel(objectApiName, null, 0) : null;
	for (const segment of segments) {
		const relationship = level?.fields.find((field) => isRelationship(field) && field.relationshipName === segment);
		// eslint-disable-next-line no-await-in-loop
		level = relationship && level.depth < MAX_RELATIONSHIPS ? await descend(level, relationship) : null;
	}
	return level;
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
 * @description Lists a level's options, like Flow Builder's field menus: relationships and lookup IDs, then the other
 * fields, each by label
 * @param {Object} level The level from `resolveLevel`
 * @param {String} filter `filterable` or `sortable` to offer only fields that can filter or sort; blank for any
 * @returns {Array} "Relationship Fields" and "Record Fields" sections
 */
function initSections(level, filter) {
	const isUsable = (field) => !filter || (filter === "filterable" ? field.isFilterable : field.isSortable);
	const canDrill = level.depth < MAX_RELATIONSHIPS;
	const relationships = canDrill ? level.fields.filter(isRelationship) : [];
	const usable = level.fields.filter(isUsable);
	const toFieldOption = (field) => initFieldOption(field, level.option);
	const relationshipOptions = relationships.map((field) => initRelationshipOption(field, level.option));
	const lookupOptions = usable.filter(isRelationship).map(toFieldOption);
	const recordOptions = usable.filter((field) => !isRelationship(field)).map(toFieldOption);
	// Only stored fields take every field of an object, since a condition or sort needs one; nor does an object without any
	const canSelectAll = !filter && level.fields.length > 0;
	const allFieldsOptions = canSelectAll ? [initAllFieldsOption(level)] : [];
	// Relationships come before lookup IDs, like Flow Builder, so the section sorts each group, not the whole list
	const relationshipItems = [...relationshipOptions.sort(compareLabels), ...lookupOptions.sort(compareLabels)];
	const recordItems = [...allFieldsOptions, ...recordOptions.sort(compareLabels)];
	return [
		initSection("Relationship Fields", relationshipItems, false),
		initSection("Record Fields", recordItems, false)
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
 * @description Builds the option for a relationship, which drills into its object
 * @param {Object} field The lookup field
 * @param {Object} parent The drilled-into relationship's option, or null at the top
 * @returns {Object} The option
 */
function initRelationshipOption(field, parent) {
	const name = field.relationshipName;
	const path = joinPath(parent, name, name);
	return {
		...path,
		label: name,
		description: `${field.label} (${field.referenceTo})`,
		icon: "utility:record_lookup",
		isDrillable: true
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

/**
 * @description Picks a field of an object, or of a parent object through its relationships, ex: `Account.Owner.Name`,
 * in one searchable picker that drills into relationships like Flow Builder's resource menu. Fires `change` with
 * `{ value, field }` once a field is picked, and `{ value: null, field: null }` when it's cleared.
 */
export default class SoqlFieldPath extends LightningElement {
	/**
	 * @description `filterable` or `sortable` to offer only fields that can filter or sort
	 * @type {String}
	 */
	@api filter;
	/**
	 * @description The picker's label
	 * @type {String}
	 */
	@api label;
	/**
	 * @description The object the path starts from
	 * @type {String}
	 */
	@api objectApiName;
	/**
	 * @description The picked field's path, ex: `Account.Name`
	 * @type {String}
	 */
	@api value;

	/**
	 * @description Lists the options under a path, for the picker
	 * @param {String} parentPath The relationships drilled into
	 * @returns {Promise<Object>} `{ parent, sections }`
	 */
	loadOptions = (parentPath) => getFieldOptions(this.objectApiName, parentPath, this.filter);

	// **** HANDLERS **** //
	/**
	 * @description Fires `change` with the picked path and its field
	 * @param {CustomEvent} event Change on the picker
	 */
	async handleChange(event) {
		const value = event.detail.value;
		const field = await resolveField(this.objectApiName, value);
		this.dispatchEvent(new CustomEvent("change", { detail: { value, field } }));
	}
}
