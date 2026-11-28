import { LightningElement, api } from "lwc";
import { getFieldOptions, resolveField } from "c/soqlFieldMenu";

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
	 * @description Paths whose fields are all stored by other rows, ex: `["", "Account"]`, which offer only
	 * relationships
	 * @type {Array}
	 */
	@api coveredPaths;

	/**
	 * @description Lists the options under a path, for the picker
	 * @param {String} parentPath The relationships drilled into
	 * @returns {Promise<Object>} `{ parent, sections }`
	 */
	loadOptions = (parentPath) => getFieldOptions(this.objectApiName, parentPath, this.filter, this.coveredPaths);

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
