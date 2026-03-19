import { LightningElement, api, track } from "lwc";

const ACCESS_LEVEL_OPTIONS = [
	{ label: "User Mode", value: "USER_MODE" },
	{ label: "System Mode", value: "SYSTEM_MODE" }
];

const BOOLEAN_OPTIONS = [
	{ label: "True", value: "true" },
	{ label: "False", value: "false" }
];

const GLOBAL_RESOURCE_OPTIONS = [
	{
		name: "$GlobalConstant.True",
		label: "Global Constant: True",
		pillLabel: "$GlobalConstant.True",
		value: "{!$GlobalConstant.True}",
		referenceName: "$GlobalConstant.True",
		dataType: "Boolean",
		isCollection: false
	},
	{
		name: "$GlobalConstant.False",
		label: "Global Constant: False",
		pillLabel: "$GlobalConstant.False",
		value: "{!$GlobalConstant.False}",
		referenceName: "$GlobalConstant.False",
		dataType: "Boolean",
		isCollection: false
	},
	{
		name: "$GlobalConstant.EmptyString",
		label: "Global Constant: Blank Value (Empty String)",
		pillLabel: "$GlobalConstant.EmptyString",
		value: "{!$GlobalConstant.EmptyString}",
		referenceName: "$GlobalConstant.EmptyString",
		dataType: "String",
		isCollection: false
	}
];

const CATEGORY_LABELS = {
	constants: "Constant",
	formulas: "Formula",
	variables: "Variable"
};

const FIELD_METADATA = {
	record: {
		label: "SObject Record",
		helpText: "A single SObject record to be processed.",
		dataType: "SObject",
		inputType: "text"
	},
	records: {
		label: "SObject Records [collection]",
		helpText: "A collection of SObject records to be processed.",
		dataType: "SObject",
		inputType: "text",
		isCollection: true
	},
	recordId: {
		label: "Record Id [single]",
		helpText: "The Id of a single SObject record to be processed.",
		dataType: "String",
		inputType: "text"
	},
	recordIds: {
		label: "Record Ids [collection]",
		helpText: "A collection of SObject record Ids to be processed.",
		dataType: "String",
		inputType: "text",
		isCollection: true
	},
	accessLevelName: {
		label: "Access Level",
		helpText: "Specifies whether the method runs in SYSTEM_MODE or USER_MODE. User Mode is the default.",
		dataType: "String",
		inputType: "picklist",
		options: ACCESS_LEVEL_OPTIONS,
		defaultValue: "USER_MODE"
	},
	allOrNone: {
		label: "All Or None",
		helpText: "Specifies whether the operation allows partial success. True is the default.",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: true
	},
	externalIdField: {
		label: "External ID Field",
		helpText: "The API Name of the field to use as the upsert primary key.",
		dataType: "String",
		inputType: "text"
	},
	leadId: {
		label: "Lead ID",
		helpText: "The ID of the Lead to be converted.",
		dataType: "String",
		inputType: "text",
		required: true
	},
	accountId: {
		label: "Account ID",
		helpText: "The ID of an existing Account to merge the converted lead into.",
		dataType: "String",
		inputType: "text"
	},
	accountName: {
		label: "Account Name",
		helpText: "The name of the Account to create during lead conversion.",
		dataType: "String",
		inputType: "text"
	},
	contactId: {
		label: "Contact ID",
		helpText: "The ID of an existing Contact to merge the converted lead into.",
		dataType: "String",
		inputType: "text"
	},
	convertedStatus: {
		label: "Converted Status",
		helpText: "The Lead status value to set on conversion.",
		dataType: "String",
		inputType: "text"
	},
	doNotCreateOpportunity: {
		label: "Do Not Create Opportunity",
		helpText: "If true, no Opportunity is created when the lead is converted.",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	},
	opportunityId: {
		label: "Opportunity ID",
		helpText: "The ID of an existing Opportunity to attach the converted lead to.",
		dataType: "String",
		inputType: "text"
	},
	opportunityName: {
		label: "Opportunity Name",
		helpText: "The name of the Opportunity to create during lead conversion.",
		dataType: "String",
		inputType: "text"
	},
	overwriteLeadSource: {
		label: "Overwrite Lead Source",
		helpText: "If true, overwrites the Lead Source on the target Contact and Account.",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	},
	ownerId: {
		label: "Owner ID",
		helpText: "The ID of the user to own any newly-created records.",
		dataType: "String",
		inputType: "text"
	},
	sendNotificationEmail: {
		label: "Send Notification Email",
		helpText: "If true, sends a notification email to the owner of the converted records.",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	}
};

function detectActionType(inputVariables) {
	const names = new Set((inputVariables || []).map((variable) => variable.name));

	if (names.has("leadId")) {
		return "CONVERT";
	}

	if (names.has("externalIdField")) {
		return "UPSERT";
	}

	if (names.has("recordId") || names.has("recordIds")) {
		return "DELETE";
	}

	return "BASE";
}

function hasOwnValue(container, key) {
	return !!container && Object.prototype.hasOwnProperty.call(container, key);
}

function hasMeaningfulValue(value) {
	if (value === false || value === 0) {
		return true;
	}

	if (Array.isArray(value)) {
		return value.length > 0;
	}

	if (value && typeof value === "object") {
		return true;
	}

	return value !== null && value !== undefined && value !== "";
}

function isReferenceValue(valueDataType, value) {
	return (
		valueDataType === "reference" || (typeof value === "string" && value.startsWith("{!") && value.endsWith("}"))
	);
}

function cloneValue(value) {
	return value ? JSON.parse(JSON.stringify(value)) : {};
}

export default class FlowDmlPropertyEditor extends LightningElement {
	_inputVariables = [];

	@api outputVariables = [];
	@api genericTypeMappings = [];
	@api builderContext = {};

	@track _vals = {};
	@track _includedState = {};

	@api
	get inputVariables() {
		return this._inputVariables;
	}

	set inputVariables(nextValue) {
		this._inputVariables = nextValue ?? [];
		this._hydrateState();
	}

	connectedCallback() {
		this._hydrateState();
	}

	get inputVariableMap() {
		return new Map((this._inputVariables || []).map((variable) => [variable.name, variable]));
	}

	get configuredBaseInput() {
		return this._get("baseInput") ?? {};
	}

	get vals() {
		return this._vals;
	}

	get baseInputVal() {
		return this._vals.baseInput ?? {};
	}

	get actionType() {
		return detectActionType(this._inputVariables);
	}

	get isGroupA() {
		return this.actionType === "BASE";
	}

	get isGroupB() {
		return this.actionType === "DELETE";
	}

	get isGroupC() {
		return this.actionType === "UPSERT";
	}

	get isGroupD() {
		return this.actionType === "CONVERT";
	}

	get baseRecordFields() {
		return this._buildFieldConfigs(["record", "records"]);
	}

	get deleteRecordFields() {
		return [
			...this._buildBaseInputFieldConfigs(["record", "records"]),
			...this._buildFieldConfigs(["recordId", "recordIds"])
		];
	}

	get upsertRecordFields() {
		return this._buildBaseInputFieldConfigs(["record", "records"]);
	}

	get baseSettingFields() {
		return this._buildFieldConfigs(["accessLevelName", "allOrNone"]);
	}

	get baseInputSettingFields() {
		return this._buildBaseInputFieldConfigs(["accessLevelName", "allOrNone"]);
	}

	get upsertSettingFields() {
		return this._buildFieldConfigs(["externalIdField"]);
	}

	get convertInputFields() {
		return this._buildFieldConfigs([
			"leadId",
			"accountId",
			"accountName",
			"contactId",
			"convertedStatus",
			"doNotCreateOpportunity",
			"opportunityId",
			"opportunityName",
			"overwriteLeadSource",
			"ownerId",
			"sendNotificationEmail"
		]);
	}

	get convertSettingFields() {
		return this._buildFieldConfigs(["accessLevelName", "allOrNone"]);
	}

	get availableResources() {
		const deduped = new Map();

		[...GLOBAL_RESOURCE_OPTIONS, ...this._flattenBuilderResources()].forEach((resource) => {
			if (!resource?.referenceName) {
				return;
			}

			deduped.set(resource.referenceName, resource);
		});

		return [...deduped.values()];
	}

	_hydrateState() {
		this._vals = this._buildVals();
		this._includedState = this._buildIncludedState();
	}

	_get(name) {
		return this.inputVariableMap.get(name)?.value;
	}

	_getValueDataType(name) {
		return this.inputVariableMap.get(name)?.valueDataType;
	}

	_buildVals() {
		const type = detectActionType(this._inputVariables);

		if (type === "BASE") {
			return {
				record: this._get("record") ?? null,
				records: this._get("records") ?? [],
				accessLevelName: this._get("accessLevelName"),
				allOrNone: this._get("allOrNone"),
				dmlOptions: this._get("dmlOptions")
			};
		}

		if (type === "DELETE") {
			return {
				recordId: this._get("recordId") ?? null,
				recordIds: this._get("recordIds") ?? [],
				baseInput: cloneValue(this._get("baseInput"))
			};
		}

		if (type === "UPSERT") {
			return {
				externalIdField: this._get("externalIdField") ?? null,
				baseInput: cloneValue(this._get("baseInput"))
			};
		}

		return {
			leadId: this._get("leadId") ?? null,
			accountId: this._get("accountId") ?? null,
			accountName: this._get("accountName") ?? null,
			contactId: this._get("contactId") ?? null,
			convertedStatus: this._get("convertedStatus") ?? null,
			doNotCreateOpportunity: this._get("doNotCreateOpportunity"),
			opportunityId: this._get("opportunityId") ?? null,
			opportunityName: this._get("opportunityName") ?? null,
			overwriteLeadSource: this._get("overwriteLeadSource"),
			ownerId: this._get("ownerId") ?? null,
			sendNotificationEmail: this._get("sendNotificationEmail"),
			accessLevelName: this._get("accessLevelName"),
			allOrNone: this._get("allOrNone"),
			dmlOptions: this._get("dmlOptions")
		};
	}

	_buildIncludedState() {
		const nextState = {};

		Object.entries(FIELD_METADATA).forEach(([fieldName, metadata]) => {
			nextState[fieldName] = metadata.required || this._isTopLevelFieldConfigured(fieldName);
			nextState[`baseInput.${fieldName}`] = metadata.required || hasOwnValue(this.configuredBaseInput, fieldName);
		});

		return nextState;
	}

	_isTopLevelFieldConfigured(fieldName) {
		const variable = this.inputVariableMap.get(fieldName);

		if (!variable) {
			return false;
		}

		if (variable.valueDataType === "reference") {
			return true;
		}

		return hasMeaningfulValue(variable.value);
	}

	_buildFieldConfigs(fieldNames) {
		return fieldNames.map((fieldName) => this._buildFieldConfig(fieldName));
	}

	_buildBaseInputFieldConfigs(fieldNames) {
		return fieldNames.map((fieldName) => this._buildFieldConfig(fieldName, "baseInput"));
	}

	_buildFieldConfig(fieldName, scope) {
		const metadata = FIELD_METADATA[fieldName];
		const path = scope ? `${scope}.${fieldName}` : fieldName;
		const value = scope ? this.baseInputVal[fieldName] : this._vals[fieldName];
		const valueDataType = scope
			? isReferenceValue(null, value)
				? "reference"
				: metadata.dataType
			: isReferenceValue(this._getValueDataType(fieldName), value)
				? "reference"
				: metadata.dataType;

		return {
			key: path,
			name: path,
			label: metadata.label,
			helpText: metadata.helpText,
			dataType: metadata.dataType,
			inputType: metadata.inputType,
			options: metadata.options ?? [],
			defaultValue: metadata.defaultValue,
			required: metadata.required ?? false,
			included: this._includedState[path] ?? metadata.required ?? false,
			value,
			valueDataType,
			resourceOptions: this._buildResourceOptions(metadata)
		};
	}

	_flattenBuilderResources() {
		return ["variables", "formulas", "constants"].flatMap((category) =>
			(this.builderContext?.[category] ?? [])
				.filter((resource) => !!resource?.name)
				.map((resource) => ({
					name: resource.name,
					label: `${CATEGORY_LABELS[category] ?? "Resource"}: ${resource.name}`,
					pillLabel: resource.name,
					value: `{!${resource.name}}`,
					referenceName: resource.name,
					dataType: resource.dataType,
					objectType: resource.objectType,
					isCollection:
						resource.isCollection === true ||
						resource.isCollection === "true" ||
						(typeof resource.dataType === "string" && resource.dataType.endsWith("[]"))
				}))
		);
	}

	_buildResourceOptions(metadata) {
		return this.availableResources.filter((resource) => this._matchesResource(metadata, resource));
	}

	_matchesResource(metadata, resource) {
		if (metadata.dataType === "Boolean") {
			return resource.dataType === "Boolean";
		}

		if (metadata.isCollection) {
			return resource.isCollection === true;
		}

		if (metadata.dataType === "SObject") {
			return !resource.isCollection && !!resource.objectType;
		}

		return (
			!resource.isCollection &&
			!resource.objectType &&
			(resource.dataType === "String" || resource.dataType === undefined || resource.dataType === null)
		);
	}

	_emitChange(name, newValue, newValueDataType) {
		this.dispatchEvent(
			new CustomEvent("configuration_editor_input_value_changed", {
				bubbles: true,
				composed: true,
				cancelable: false,
				detail: { name, newValue, newValueDataType }
			})
		);
	}

	_emitDelete(name) {
		this.dispatchEvent(
			new CustomEvent("configuration_editor_input_value_deleted", {
				bubbles: true,
				composed: true,
				cancelable: false,
				detail: { name }
			})
		);
	}

	handleFieldChange(event) {
		const { name, value, valueDataType } = event.detail;

		if (name.startsWith("baseInput.")) {
			const fieldName = name.replace("baseInput.", "");
			const updated = { ...this.baseInputVal, [fieldName]: value };
			this._vals = { ...this._vals, baseInput: updated };
			this._includedState = { ...this._includedState, [name]: true };
			this._emitChange("baseInput", updated, "FlowDmlBaseInput");
			return;
		}

		this._vals = { ...this._vals, [name]: value };
		this._includedState = { ...this._includedState, [name]: true };
		this._emitChange(name, value, valueDataType);
	}

	handleFieldIncludedChange(event) {
		const { name, included } = event.detail;
		const pathParts = name.split(".");
		const fieldName = pathParts[pathParts.length - 1];
		const metadata = FIELD_METADATA[fieldName];

		this._includedState = { ...this._includedState, [name]: included };

		if (name.startsWith("baseInput.")) {
			const updated = { ...this.baseInputVal };

			if (included) {
				if (!hasOwnValue(updated, fieldName) && metadata.defaultValue !== undefined) {
					updated[fieldName] = metadata.defaultValue;
					this._vals = { ...this._vals, baseInput: updated };
					this._emitChange("baseInput", updated, "FlowDmlBaseInput");
				}

				return;
			}

			delete updated[fieldName];
			this._vals = { ...this._vals, baseInput: updated };
			this._emitChange("baseInput", updated, "FlowDmlBaseInput");
			return;
		}

		if (included) {
			if ((this._vals[name] === undefined || this._vals[name] === null) && metadata.defaultValue !== undefined) {
				this._vals = { ...this._vals, [name]: metadata.defaultValue };
				this._emitChange(name, metadata.defaultValue, metadata.dataType);
			}

			return;
		}

		const resetValue = metadata.defaultValue ?? (metadata.isCollection ? [] : null);
		this._vals = { ...this._vals, [name]: resetValue };
		this._emitDelete(name);
	}

	handleDmlOptionsChange(event) {
		const updated = event.detail.value;
		this._vals = { ...this._vals, dmlOptions: updated };
		this._emitChange("dmlOptions", updated, "FlowDmlOptions");
	}

	handleBaseInputDmlOptionsChange(event) {
		const updatedBaseInput = { ...this.baseInputVal, dmlOptions: event.detail.value };
		this._vals = { ...this._vals, baseInput: updatedBaseInput };
		this._emitChange("baseInput", updatedBaseInput, "FlowDmlBaseInput");
	}

	@api validate() {
		const errors = [];
		const type = this.actionType;

		if (type === "BASE") {
			if (!this._vals.record && !this._vals.records?.length) {
				errors.push({ key: "record", errorString: "Provide at least one record or a collection of records." });
			}
		} else if (type === "DELETE") {
			if (!this._vals.recordId && !this._vals.recordIds?.length) {
				errors.push({
					key: "recordId",
					errorString: "Provide at least one Record Id or a collection of Record Ids."
				});
			}
		} else if (type === "UPSERT") {
			const base = this._vals.baseInput ?? {};

			if (!base.record && !base.records?.length) {
				errors.push({
					key: "baseInput",
					errorString: "Provide at least one record or a collection of records in Base Input."
				});
			}
		} else if (type === "CONVERT" && !this._vals.leadId) {
			errors.push({ key: "leadId", errorString: "Lead ID is required." });
		}

		return errors;
	}
}
