import { LightningElement, api } from "lwc";

/**
 * @description The actions' Access Level choices, which Apex parses with `DatabaseLayerUtils.AccessLevels.parse`
 */
export const ACCESS_LEVELS = [
	{ label: "User Mode", value: "USER_MODE" },
	{ label: "System Mode", value: "SYSTEM_MODE" }
];
/**
 * @description Help for the actions' Access Level input, matching its description in Apex
 */
export const ACCESS_LEVEL_HELP =
	"USER_MODE (default) enforces the running user's object permissions, field-level security, and sharing rules. SYSTEM_MODE ignores all three, like Get Records in a flow that runs in system context without sharing.";
/**
 * @description A combobox's empty choice. Flow Builder can't save a blank literal, so choosing it removes the input.
 */
export const NONE_OPTION = { label: "--None--", value: "" };

/**
 * @description Base class for this package's Custom Property Editors: takes Flow Builder's inputs, indexes the
 * action's saved values, and sends Flow Builder the editor's changes. Each editor keeps its own `inputVariables` and
 * `validate()`.
 */
export default class FlowPropertyEditor extends LightningElement {
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

	_errors = {};
	_inputVariables = [];
	_values = {};

	// **** GETTERS **** //
	get elementName() {
		return this.elementInfo?.apiName;
	}

	// **** PRIVATE **** //
	/**
	 * @description Tells Flow Builder to remove an input's value
	 * @param {String} name The input's name
	 */
	_deleteInput(name) {
		this._dispatch("configuration_editor_input_value_deleted", { name });
	}

	/**
	 * @description Fires a Custom Property Editor event to Flow Builder
	 * @param {String} type The event type
	 * @param {Object} detail The event's details
	 */
	_dispatch(type, detail) {
		this.dispatchEvent(new CustomEvent(type, { bubbles: true, cancelable: false, composed: true, detail }));
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
	 * @description Saves a value to the action, or removes it when cleared, since Flow Builder can't save a blank
	 * @param {String} name The input's name
	 * @param {String} value The value
	 * @param {String} valueDataType The value's data type
	 */
	_saveInput(name, value, valueDataType) {
		if (value == null || value === "") {
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
	 * @description Types one of the action's generic inputs or outputs to an object, once it's known
	 * @param {String} typeName The generic type, ex: `U__records`
	 * @param {String} typeValue The object, ex: `Account`
	 */
	_setGenericType(typeName, typeValue) {
		if (typeValue) {
			this._dispatch("configuration_editor_generic_type_mapping_changed", { typeName, typeValue });
		}
	}
}
