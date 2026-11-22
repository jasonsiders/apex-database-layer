import { LightningElement, api } from "lwc";
import getFields from "@salesforce/apex/InvocableSoql.getFields";
import { compareLabels } from "c/flowResourceMenu";

// A relationship's option ends with " >", like Flow Builder's drillable fields; API names have no spaces
const RELATIONSHIP_SUFFIX = " >";
// Field describes, by object, shared by every picker and the editor; a failed describe is forgotten, so it retries
const FIELDS_BY_OBJECT = new Map();
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
	const [name, ...rest] = path?.split(".") ?? [];
	const fields = objectApiName && name ? await loadFields(objectApiName).catch(() => []) : [];
	const parent = rest.length ? fields.find((candidate) => candidate.relationshipName === name) : null;
	const field = rest.length ? null : fields.find((candidate) => candidate.apiName === name);
	return parent ? resolveField(parent.referenceTo, rest.join(".")) : (field ?? null);
}

/**
 * @description Lists a level's options: relationships first, to drill into, then fields, by label
 * @param {Array} fields The object's fields
 * @param {String} filter `filterable` or `sortable` to offer only fields that can filter or sort; blank for any
 * @returns {Array} Options for `c-flow-resource-picker`
 */
function initOptions(fields, filter) {
	const isUsable = (field) => !filter || (filter === "filterable" ? field.isFilterable : field.isSortable);
	const relationships = fields
		.filter((field) => field.relationshipName && field.referenceTo)
		.map((field) => ({
			label: field.relationshipName + RELATIONSHIP_SUFFIX,
			value: field.relationshipName + RELATIONSHIP_SUFFIX,
			description: `${field.label} (${field.referenceTo})`,
			icon: "utility:record_lookup"
		}));
	const options = fields.filter(isUsable).map((field) => ({
		label: field.apiName,
		value: field.apiName,
		description: field.label,
		icon: TYPE_ICONS[field.type] ?? "utility:text"
	}));
	return [...relationships.sort(compareLabels), ...options.sort(compareLabels)];
}

/**
 * @description Picks a field of an object, or of a parent object through its relationships, ex: `Account.Owner.Name`.
 * Each step is a searchable picker; picking a relationship adds a step for its object. Fires `change` with
 * `{ value, field }` once a field is picked, and `{ value: null, field: null }` when the first step is cleared. An
 * unfinished path fires nothing, so the editor keeps the last field until another is picked.
 */
export default class SoqlFieldPath extends LightningElement {
	/**
	 * @description Shown below the last step, ex: from the editor's `validate()`
	 * @type {String}
	 */
	@api errorMessage;
	/**
	 * @description `filterable` or `sortable` to offer only fields that can filter or sort
	 * @type {String}
	 */
	@api filter;
	/**
	 * @description The first step's label
	 * @type {String}
	 */
	@api label;
	/**
	 * @description Marks the label with an asterisk
	 * @type {Boolean}
	 */
	@api required = false;

	// Whether the last segment is a relationship being drilled into, not yet a field
	_isPending = false;
	_levels = [];
	_loadId = 0;
	_objectApiName;
	_segments = [];
	_value;

	// **** GETTERS **** //
	get levels() {
		const lastIndex = this._levels.length - 1;
		return this._levels.map((level, index) => ({
			...level,
			key: `${index}:${level.objectApiName}`,
			errorMessage: index === lastIndex ? this.errorMessage : null,
			label: index === 0 ? this.label : `${this.label} on ${level.objectApiName}`,
			required: index === 0 && this.required,
			variant: index === 0 ? null : "label-hidden"
		}));
	}

	// **** API SETTERS **** //
	/**
	 * @description The object the path starts from
	 * @type {String}
	 */
	@api
	get objectApiName() {
		return this._objectApiName;
	}
	set objectApiName(value) {
		this._objectApiName = value;
		this._loadLevels();
	}

	/**
	 * @description The picked field's path, ex: `Account.Name`
	 * @type {String}
	 */
	@api
	get value() {
		return this._value;
	}
	set value(value) {
		this._value = value;
		this._segments = value ? value.split(".") : [];
		this._isPending = false;
		this._loadLevels();
	}

	// **** HANDLERS **** //
	/**
	 * @description Drills into a picked relationship, or finishes the path with a picked field; clearing a step drops
	 * the steps after it
	 * @param {CustomEvent} event Change on a step's picker
	 */
	async handleLevelChange(event) {
		const index = Number(event.target.dataset.index);
		const picked = event.detail.value;
		const isRelationship = picked?.endsWith(RELATIONSHIP_SUFFIX) ?? false;
		const segment = isRelationship ? picked.slice(0, -RELATIONSHIP_SUFFIX.length) : picked;
		this._segments = [...this._segments.slice(0, index), ...(segment ? [segment] : [])];
		this._isPending = isRelationship;
		const isComplete = Boolean(segment) && !isRelationship;
		const isCleared = this._segments.length === 0;
		this._value = isComplete ? this._segments.join(".") : this._value;
		this._value = isCleared ? null : this._value;
		this._loadLevels();
		if (isComplete || isCleared) {
			const field = isComplete ? await resolveField(this._objectApiName, this._value) : null;
			this.dispatchEvent(new CustomEvent("change", { detail: { value: this._value, field } }));
		}
	}

	// **** PRIVATE **** //
	/**
	 * @description Builds a step per segment, plus an empty step after a relationship, describing each step's object
	 */
	async _loadLevels() {
		const loadId = ++this._loadId;
		const levels = [];
		let objectApiName = this._objectApiName;
		// One step per segment, plus one to pick into, until the path reaches a field or an unknown relationship
		for (let index = 0; objectApiName && index <= this._segments.length; index++) {
			// eslint-disable-next-line no-await-in-loop
			const fields = await loadFields(objectApiName).catch(() => []);
			const segment = this._segments[index];
			const parent = segment ? fields.find((field) => field.relationshipName === segment) : null;
			const lastIndex = this._segments.length - 1;
			const isDrilled = Boolean(parent) && (index < lastIndex || (index === lastIndex && this._isPending));
			const value = isDrilled ? segment + RELATIONSHIP_SUFFIX : segment;
			levels.push({ index, objectApiName, picklistValues: initOptions(fields, this.filter), value });
			objectApiName = isDrilled ? parent.referenceTo : null;
		}
		if (loadId === this._loadId) {
			this._levels = levels;
		}
	}
}
