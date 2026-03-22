import { LightningElement, api, track } from "lwc";
import Toast from "lightning/toast";

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

const APEX_DEFINED_PREFIX = "apex://";
const APEX_DATA_TYPE = "Apex";
const APEX_DEFINED_INPUT_CLASS_NAMES = {
	baseInput: "FlowDmlBaseInput",
	dmlOptions: "FlowDmlOptions"
};
const LEGACY_DML_OPTION_SECTIONS = {
	assignmentRuleHeader: ["assignmentRuleId", "useDefaultRule"],
	duplicateRuleHeader: ["allowSave", "runAsCurrentUser"],
	emailHeader: ["triggerAutoResponseEmail", "triggerOtherEmail", "triggerUserEmail"]
};
const SHARED_GENERIC_INPUT_GROUPS = [["record", "records"]];
const VALIDATION_DEPENDENCIES = {
	record: ["record", "records"],
	recordId: ["recordId", "recordIds"],
	"baseInput.record": ["baseInput.record", "baseInput.records"],
	leadId: ["leadId"]
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

function isPlainObject(value) {
	return !!value && typeof value === "object" && !Array.isArray(value);
}

function isReferenceValue(valueDataType, value) {
	return (
		valueDataType === "reference" || (typeof value === "string" && value.startsWith("{!") && value.endsWith("}"))
	);
}

function normalizeReferenceName(value) {
	if (typeof value !== "string") {
		return "";
	}

	if (value.startsWith("{!") && value.endsWith("}")) {
		return value.slice(2, -1);
	}

	return value;
}

function isCollectionResource(resource) {
	return (
		resource?.isCollection === true ||
		resource?.isCollection === "true" ||
		(typeof resource?.dataType === "string" && resource.dataType.endsWith("[]"))
	);
}

function getBaseResourceDataType(resource) {
	if (typeof resource?.dataType !== "string") {
		return resource?.dataType;
	}

	return resource.dataType.endsWith("[]") ? resource.dataType.slice(0, -2) : resource.dataType;
}

function matchesResourceType(metadata, resource) {
	const resourceIsCollection = isCollectionResource(resource);
	const resourceDataType = getBaseResourceDataType(resource);
	const expectsCollection = metadata.isCollection === true;

	if (expectsCollection !== resourceIsCollection) {
		return false;
	}

	if (metadata.dataType === "SObject") {
		return !!resource.objectType;
	}

	if (resource.objectType) {
		return false;
	}

	if (metadata.dataType === "String") {
		return resourceDataType === "String" || resourceDataType === undefined || resourceDataType === null;
	}

	return resourceDataType === metadata.dataType;
}

function isValidLiteralForMetadata(metadata, value) {
	if (!hasMeaningfulValue(value) || isReferenceValue(null, value)) {
		return true;
	}

	if (metadata.isCollection) {
		if (!Array.isArray(value)) {
			return false;
		}

		if (metadata.dataType === "String") {
			return value.every((item) => typeof item === "string");
		}

		if (metadata.dataType === "SObject") {
			return value.every((item) => isPlainObject(item));
		}

		if (metadata.dataType === "Boolean") {
			return value.every((item) => typeof item === "boolean");
		}

		return true;
	}

	if (metadata.dataType === "String") {
		return typeof value === "string";
	}

	if (metadata.dataType === "Boolean") {
		return typeof value === "boolean";
	}

	if (metadata.dataType === "SObject") {
		return isPlainObject(value);
	}

	return true;
}

function buildTypeValidationMessage(metadata) {
	if (metadata.dataType === "Boolean") {
		return `${metadata.label} must be a Boolean value or Boolean resource.`;
	}

	if (metadata.isCollection && metadata.dataType === "SObject") {
		return `${metadata.label} must be a record collection or collection resource.`;
	}

	if (metadata.dataType === "SObject") {
		return `${metadata.label} must be a record value or record resource.`;
	}

	if (metadata.isCollection && metadata.dataType === "String") {
		return `${metadata.label} must be a text collection or collection resource.`;
	}

	return `${metadata.label} must be a ${metadata.dataType} value.`;
}

function cloneValue(value) {
	return value ? JSON.parse(JSON.stringify(value)) : {};
}

function normalizeDmlOptionsValue(value) {
	const next = cloneValue(value);

	Object.entries(LEGACY_DML_OPTION_SECTIONS).forEach(([sectionName, fieldNames]) => {
		const sectionValue = next[sectionName];

		if (!sectionValue || typeof sectionValue !== "object" || Array.isArray(sectionValue)) {
			delete next[sectionName];
			return;
		}

		fieldNames.forEach((fieldName) => {
			if (!hasOwnValue(next, fieldName) && hasOwnValue(sectionValue, fieldName)) {
				next[fieldName] = sectionValue[fieldName];
			}
		});

		delete next[sectionName];
	});

	return next;
}

function valuesAreEqual(left, right) {
	return JSON.stringify(left ?? null) === JSON.stringify(right ?? null);
}

function normalizeStringValue(value) {
	return typeof value === "string" ? value.trim() : "";
}

function buildGenericTypeName(inputName) {
	const normalizedName = normalizeStringValue(inputName);
	return normalizedName ? `T__${normalizedName}` : "";
}

function getSharedGenericInputGroup(fieldName) {
	return SHARED_GENERIC_INPUT_GROUPS.find((group) => group.includes(fieldName)) ?? [fieldName];
}

function extractActionCallInputNames(actionCall) {
	const inputNames = new Set();

	[actionCall?.inputParameters, actionCall?.inputVariables, actionCall?.inputAssignments].forEach((collection) => {
		if (!Array.isArray(collection)) {
			return;
		}

		collection.forEach((input) => {
			const name = normalizeStringValue(input?.name);

			if (name) {
				inputNames.add(name);
			}
		});
	});

	return inputNames;
}

function doSetsMatch(left, right) {
	if (left.size !== right.size) {
		return false;
	}

	return [...left].every((value) => right.has(value));
}

function isApexDefinedDataType(dataType, className) {
	if (typeof dataType !== "string" || !dataType) {
		return false;
	}

	if (dataType.toLowerCase() === APEX_DATA_TYPE.toLowerCase()) {
		return true;
	}

	if (dataType === className || dataType.endsWith(`.${className}`)) {
		return true;
	}

	return dataType.startsWith(APEX_DEFINED_PREFIX);
}

function hasMalformedApexDefinedDataType(dataType, className) {
	if (typeof dataType !== "string" || !dataType) {
		return false;
	}

	return dataType !== APEX_DATA_TYPE && isApexDefinedDataType(dataType, className);
}

export default class FlowDmlPropertyEditor extends LightningElement {
	_inputVariables = [];
	_genericTypeMappings = [];
	_pendingNormalizationChanges = [];
	_pendingGenericTypeMappingValues = new Map();
	_hasValidated = false;
	_lastToastSignature = null;
	_skipNextIncludedHydration = false;

	@api outputVariables = [];
	@api builderContext = {};
	@api elementInfo = {};

	@track _vals = {};
	@track _includedState = {};
	@track _fieldErrors = {};
	@track _touchedFields = {};

	@api
	get inputVariables() {
		return this._inputVariables;
	}

	set inputVariables(nextValue) {
		this._inputVariables = nextValue ?? [];
		if (this._skipNextIncludedHydration) {
			this._skipNextIncludedHydration = false;
			this._vals = this._buildVals();
			this._pendingNormalizationChanges = this._collectLegacyNormalizationChanges();
		} else {
			this._hydrateState();
		}
	}

	@api
	get genericTypeMappings() {
		return this._genericTypeMappings;
	}

	set genericTypeMappings(nextValue) {
		this._genericTypeMappings = Array.isArray(nextValue) ? nextValue : [];
		const persistedMappings = new Map(
			this._genericTypeMappings
				.map((mapping) => [normalizeStringValue(mapping?.typeName), normalizeStringValue(mapping?.typeValue)])
				.filter(([typeName]) => !!typeName)
		);

		[...this._pendingGenericTypeMappingValues.entries()].forEach(([typeName, typeValue]) => {
			if (persistedMappings.get(typeName) === typeValue) {
				this._pendingGenericTypeMappingValues.delete(typeName);
			}
		});

		this._refreshValidationErrors();
	}

	connectedCallback() {
		this._hydrateState();
	}

	renderedCallback() {
		if (!this._pendingNormalizationChanges.length) {
			this._syncInferredGenericTypeMappings();
			return;
		}

		const pendingChanges = [...this._pendingNormalizationChanges];
		this._pendingNormalizationChanges = [];

		pendingChanges.forEach(({ name, value, className }) => {
			this._emitChange(name, value, this._getApexDefinedValueDataType(name, className));
		});
		this._syncInferredGenericTypeMappings();
	}

	get inputVariableMap() {
		return new Map((this._inputVariables || []).map((variable) => [variable.name, variable]));
	}

	get configuredBaseInput() {
		return this._get("baseInput") ?? {};
	}

	get apexValueTypeNamespace() {
		const firstApexType = (this._inputVariables || [])
			.map((variable) => variable?.valueDataType)
			.find(
				(valueDataType) => typeof valueDataType === "string" && valueDataType.startsWith(APEX_DEFINED_PREFIX)
			);

		if (!firstApexType) {
			return "";
		}

		const qualifiedName = firstApexType.slice(APEX_DEFINED_PREFIX.length);
		const dotIndex = qualifiedName.indexOf(".");
		return dotIndex === -1 ? "" : qualifiedName.slice(0, dotIndex);
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

	get inputVariableNames() {
		return new Set(
			(this._inputVariables || []).map((variable) => normalizeStringValue(variable?.name)).filter(Boolean)
		);
	}

	get currentActionCall() {
		const actionCalls = this.builderContext?.actionCalls ?? [];
		const apiName = normalizeStringValue(this.elementInfo?.apiName || this.elementInfo?.name);

		if (apiName) {
			return (
				actionCalls.find(
					(actionCall) =>
						normalizeStringValue(actionCall?.name) === apiName ||
						normalizeStringValue(actionCall?.apiName) === apiName
				) ?? null
			);
		}

		const matchingActionCalls = actionCalls.filter((actionCall) =>
			doSetsMatch(extractActionCallInputNames(actionCall), this.inputVariableNames)
		);

		return matchingActionCalls.length === 1 ? matchingActionCalls[0] : null;
	}

	get toastContextLabel() {
		return (
			normalizeStringValue(this.elementInfo?.apiName) ||
			normalizeStringValue(this.currentActionCall?.label) ||
			normalizeStringValue(this.currentActionCall?.name) ||
			normalizeStringValue(this.elementInfo?.label) ||
			normalizeStringValue(this.elementInfo?.name)
		);
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

	get genericTypeMappingMap() {
		return new Map(
			(this.genericTypeMappings || [])
				.map((mapping) => [normalizeStringValue(mapping?.typeName), normalizeStringValue(mapping?.typeValue)])
				.filter(([typeName]) => !!typeName)
		);
	}

	_hydrateState() {
		this._vals = this._buildVals();
		this._includedState = this._buildIncludedState();
		this._pendingNormalizationChanges = this._collectLegacyNormalizationChanges();
		this._touchedFields = {};
		this._fieldErrors = {};
		const hasMeaningfulInput = (this._inputVariables || []).some((v) => hasMeaningfulValue(v?.value));
		if (hasMeaningfulInput) {
			this._hasValidated = true;
		}
		this._refreshValidationErrors();
	}

	_get(name) {
		return this.inputVariableMap.get(name)?.value;
	}

	_getValueDataType(name) {
		const variable = this.inputVariableMap.get(name);
		return variable?.valueDataType ?? variable?.dataType;
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
			resourceOptions: this._buildResourceOptions(metadata),
			errorMessage: this._fieldErrors[path]
		};
	}

	_getApexDefinedValueDataType(name, className) {
		const existingValueDataType = this._getValueDataType(name);
		if (isApexDefinedDataType(existingValueDataType, className)) {
			return APEX_DATA_TYPE;
		}

		return APEX_DATA_TYPE;
	}

	_collectLegacyNormalizationChanges() {
		const pendingChanges = new Map();
		const queueChange = (name, value, className) => {
			pendingChanges.set(name, { name, value, className });
		};
		const rawDmlOptions = this._get("dmlOptions");
		const normalizedDmlOptions = normalizeDmlOptionsValue(rawDmlOptions);
		const dmlOptionsTypeMalformed = hasMalformedApexDefinedDataType(
			this._getValueDataType("dmlOptions"),
			"FlowDmlOptions"
		);

		if (!valuesAreEqual(rawDmlOptions, normalizedDmlOptions) || dmlOptionsTypeMalformed) {
			queueChange("dmlOptions", normalizedDmlOptions, "FlowDmlOptions");
		}

		const rawBaseInput = cloneValue(this._get("baseInput"));
		const normalizedBaseInput = hasOwnValue(rawBaseInput, "dmlOptions")
			? {
					...rawBaseInput,
					dmlOptions: normalizeDmlOptionsValue(rawBaseInput.dmlOptions)
				}
			: rawBaseInput;
		const baseInputTypeMalformed = hasMalformedApexDefinedDataType(
			this._getValueDataType("baseInput"),
			"FlowDmlBaseInput"
		);

		if (
			(!valuesAreEqual(rawBaseInput, normalizedBaseInput) || baseInputTypeMalformed) &&
			this.inputVariableMap.has("baseInput")
		) {
			queueChange("baseInput", normalizedBaseInput, "FlowDmlBaseInput");
		}

		Object.entries(APEX_DEFINED_INPUT_CLASS_NAMES).forEach(([name, className]) => {
			const malformedType = hasMalformedApexDefinedDataType(this._getValueDataType(name), className);

			if (!malformedType || pendingChanges.has(name) || !this.inputVariableMap.has(name)) {
				return;
			}

			queueChange(name, cloneValue(this._get(name)), className);
		});

		return [...pendingChanges.values()];
	}

	_flattenBuilderResources() {
		return ["variables", "formulas", "constants"].flatMap((category) =>
			(this.builderContext?.[category] ?? [])
				.filter((resource) => !!resource?.name)
				.map((resource) => {
					const isCollection =
						resource.isCollection === true ||
						resource.isCollection === "true" ||
						(typeof resource.dataType === "string" && resource.dataType.endsWith("[]"));
					const resolvedCategory =
						category === "variables" && resource.objectType
							? isCollection
								? "recordCollections"
								: "recordVariables"
							: category;

					return {
						name: resource.name,
						label: `${CATEGORY_LABELS[category] ?? "Resource"}: ${resource.name}`,
						pillLabel: resource.name,
						value: `{!${resource.name}}`,
						referenceName: resource.name,
						category: resolvedCategory,
						dataType: resource.dataType,
						objectType: resource.objectType,
						isCollection
					};
				})
		);
	}

	_buildResourceOptions(metadata) {
		return this.availableResources.filter((resource) => this._matchesResource(metadata, resource));
	}

	_matchesResource(metadata, resource) {
		return matchesResourceType(metadata, resource);
	}

	_findResourceByValue(value) {
		const referenceName = normalizeReferenceName(value);

		if (!referenceName) {
			return null;
		}

		return (
			this.availableResources.find(
				(resource) =>
					resource.referenceName === referenceName || normalizeReferenceName(resource.value) === referenceName
			) ?? null
		);
	}

	_resolveExpectedGenericType(name, value) {
		if (name.includes(".")) {
			return "";
		}

		const metadata = FIELD_METADATA[name];

		if (metadata?.dataType !== "SObject" || !isReferenceValue(null, value)) {
			return "";
		}

		return this._findResourceByValue(value)?.objectType ?? "";
	}

	_resolveExpectedGenericTypeForGroup(fieldNames, overrideValues = {}) {
		for (const fieldName of fieldNames) {
			const value = Object.prototype.hasOwnProperty.call(overrideValues, fieldName)
				? overrideValues[fieldName]
				: this._vals[fieldName];
			const expectedType = this._resolveExpectedGenericType(fieldName, value);

			if (expectedType) {
				return expectedType;
			}
		}

		return "";
	}

	_emitGenericTypeMappingChanges(fieldNames, typeValue) {
		if (!typeValue) {
			return;
		}

		fieldNames.forEach((fieldName) => {
			const typeName = buildGenericTypeName(fieldName);

			if (
				!typeName ||
				this.genericTypeMappingMap.get(typeName) === typeValue ||
				this._pendingGenericTypeMappingValues.get(typeName) === typeValue
			) {
				return;
			}

			this._pendingGenericTypeMappingValues.set(typeName, typeValue);
			this.dispatchEvent(
				new CustomEvent("configuration_editor_generic_type_mapping_changed", {
					bubbles: true,
					composed: true,
					cancelable: false,
					detail: { typeName, typeValue }
				})
			);
		});
	}

	_syncInferredGenericTypeMappings() {
		SHARED_GENERIC_INPUT_GROUPS.forEach((fieldNames) => {
			const expectedType = this._resolveExpectedGenericTypeForGroup(fieldNames);
			this._emitGenericTypeMappingChanges(fieldNames, expectedType);
		});
	}

	_resolveEmittedValueDataType(name, value, valueDataType) {
		if (!isReferenceValue(valueDataType, value)) {
			return valueDataType;
		}

		const pathParts = name.split(".");
		const fieldName = pathParts[pathParts.length - 1];
		const metadata = FIELD_METADATA[fieldName];

		if (!metadata) {
			return valueDataType;
		}

		if (pathParts.length === 1) {
			const existingValueDataType = this._getValueDataType(name);

			if (existingValueDataType && existingValueDataType !== "reference") {
				return existingValueDataType;
			}
		}

		return metadata.dataType;
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
		const emittedValueDataType = this._resolveEmittedValueDataType(name, value, valueDataType);

		if (name.startsWith("baseInput.")) {
			const fieldName = name.replace("baseInput.", "");
			const updated = { ...this.baseInputVal, [fieldName]: value };
			this._vals = { ...this._vals, baseInput: updated };
			this._includedState = { ...this._includedState, [name]: true };
			this._skipNextIncludedHydration = true;
			this._markFieldTouched(name);
			this._emitChange("baseInput", updated, this._getApexDefinedValueDataType("baseInput", "FlowDmlBaseInput"));
			this._refreshValidationErrors();
			return;
		}

		this._vals = { ...this._vals, [name]: value };
		this._includedState = { ...this._includedState, [name]: true };
		this._skipNextIncludedHydration = true;
		this._markFieldTouched(name);
		this._emitGenericTypeMappingChanges(
			getSharedGenericInputGroup(name),
			this._resolveExpectedGenericTypeForGroup(getSharedGenericInputGroup(name), { [name]: value })
		);
		this._emitChange(name, value, emittedValueDataType);
		this._refreshValidationErrors();
	}

	_collectGenericTypeMappingErrors(fieldNames) {
		const expectedType = this._resolveExpectedGenericTypeForGroup(fieldNames);

		if (!expectedType) {
			return [];
		}

		const configuredFieldNames = fieldNames.filter((fieldName) => this.inputVariableMap.has(fieldName));
		const activeFieldName = configuredFieldNames[0] ?? fieldNames[0] ?? "record";
		const metadata = FIELD_METADATA[activeFieldName];
		const hasMissingOrMismatchedMapping = configuredFieldNames.some(
			(fieldName) => this.genericTypeMappingMap.get(buildGenericTypeName(fieldName)) !== expectedType
		);

		if (!metadata || !hasMissingOrMismatchedMapping) {
			return [];
		}

		return [
			{
				key: activeFieldName,
				errorString: `${metadata.label} must use an ${expectedType} object type mapping.`
			}
		];
	}

	handleFieldIncludedChange(event) {
		const { name, included } = event.detail;
		const pathParts = name.split(".");
		const fieldName = pathParts[pathParts.length - 1];
		const metadata = FIELD_METADATA[fieldName];

		this._includedState = { ...this._includedState, [name]: included };
		this._markFieldTouched(name);

		if (name.startsWith("baseInput.")) {
			const updated = { ...this.baseInputVal };

			if (included) {
				if (!hasOwnValue(updated, fieldName) && metadata.defaultValue !== undefined) {
					updated[fieldName] = metadata.defaultValue;
					this._vals = { ...this._vals, baseInput: updated };
					this._emitChange(
						"baseInput",
						updated,
						this._getApexDefinedValueDataType("baseInput", "FlowDmlBaseInput")
					);
				}

				this._refreshValidationErrors();
				return;
			}

			delete updated[fieldName];
			this._vals = { ...this._vals, baseInput: updated };
			this._emitChange("baseInput", updated, this._getApexDefinedValueDataType("baseInput", "FlowDmlBaseInput"));
			this._refreshValidationErrors();
			return;
		}

		if (included) {
			if ((this._vals[name] === undefined || this._vals[name] === null) && metadata.defaultValue !== undefined) {
				this._vals = { ...this._vals, [name]: metadata.defaultValue };
				this._emitChange(name, metadata.defaultValue, metadata.dataType);
			}

			this._refreshValidationErrors();
			return;
		}

		const resetValue = metadata.defaultValue ?? (metadata.isCollection ? [] : null);
		this._vals = { ...this._vals, [name]: resetValue };
		this._emitDelete(name);
		this._refreshValidationErrors();
	}

	handleFieldBlur(event) {
		this._markFieldTouched(event.detail.name);
		this._refreshValidationErrors();
	}

	handleDmlOptionsChange(event) {
		const updated = event.detail.value;
		this._vals = { ...this._vals, dmlOptions: updated };
		this._emitChange("dmlOptions", updated, this._getApexDefinedValueDataType("dmlOptions", "FlowDmlOptions"));
		this._refreshValidationErrors();
	}

	handleBaseInputDmlOptionsChange(event) {
		const updatedBaseInput = { ...this.baseInputVal, dmlOptions: event.detail.value };
		this._vals = { ...this._vals, baseInput: updatedBaseInput };
		this._emitChange(
			"baseInput",
			updatedBaseInput,
			this._getApexDefinedValueDataType("baseInput", "FlowDmlBaseInput")
		);
		this._refreshValidationErrors();
	}

	_collectTypeValidationErrors(fieldNames, scope) {
		const container = scope ? this.baseInputVal : this._vals;

		return fieldNames.flatMap((fieldName) => {
			const metadata = FIELD_METADATA[fieldName];
			const path = scope ? `${scope}.${fieldName}` : fieldName;
			const isIncluded = this._includedState[path] ?? metadata.required ?? false;
			const value = container?.[fieldName];

			if (!isIncluded || !metadata || isValidLiteralForMetadata(metadata, value)) {
				return [];
			}

			return [
				{
					key: path,
					errorString: buildTypeValidationMessage(metadata)
				}
			];
		});
	}

	_collectValidationErrors() {
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
					key: "baseInput.record",
					errorString: "Provide at least one record or a collection of records in Base Input."
				});
			}
		} else if (type === "CONVERT" && !this._vals.leadId) {
			errors.push({ key: "leadId", errorString: "Lead ID is required." });
		}

		if (type === "BASE") {
			errors.push(...this._collectTypeValidationErrors(["record", "records", "accessLevelName", "allOrNone"]));
			errors.push(...this._collectGenericTypeMappingErrors(["record", "records"]));
		} else if (type === "DELETE") {
			errors.push(...this._collectTypeValidationErrors(["recordId", "recordIds"]));
			errors.push(
				...this._collectTypeValidationErrors(["record", "records", "accessLevelName", "allOrNone"], "baseInput")
			);
		} else if (type === "UPSERT") {
			errors.push(...this._collectTypeValidationErrors(["externalIdField"]));
			errors.push(
				...this._collectTypeValidationErrors(["record", "records", "accessLevelName", "allOrNone"], "baseInput")
			);
		} else if (type === "CONVERT") {
			errors.push(
				...this._collectTypeValidationErrors([
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
					"sendNotificationEmail",
					"accessLevelName",
					"allOrNone"
				])
			);
		}

		return errors;
	}

	_setValidationErrors(errors) {
		this._fieldErrors = errors.reduce((result, error) => ({ ...result, [error.key]: error.errorString }), {});
	}

	_markFieldTouched(name) {
		this._touchedFields = { ...this._touchedFields, [name]: true };
	}

	_isErrorVisible(errorKey) {
		if (this._hasValidated) {
			return true;
		}

		return (VALIDATION_DEPENDENCIES[errorKey] ?? [errorKey]).some((name) => this._touchedFields[name]);
	}

	_filterVisibleErrors(errors) {
		return errors.filter((error) => this._isErrorVisible(error.key));
	}

	_showValidationToast(errors) {
		const messages = [...new Set(errors.map((error) => error.errorString))];
		const contextLabel = this.toastContextLabel;
		const signature = JSON.stringify({ contextLabel, messages });

		if (!messages.length) {
			this._lastToastSignature = null;
			return;
		}

		if (signature === this._lastToastSignature) {
			return;
		}

		this._lastToastSignature = signature;
		Toast.show(
			{
				label: contextLabel
					? `${contextLabel}: ${messages.length === 1 ? "Validation Error" : "Validation Errors"}`
					: messages.length === 1
						? "Validation Error"
						: "Validation Errors",
				message: messages.join(" "),
				variant: "error",
				mode: "dismissible"
			},
			this
		);
	}

	_refreshValidationErrors() {
		this._setValidationErrors(this._filterVisibleErrors(this._collectValidationErrors()));
	}

	@api validate() {
		const errors = this._collectValidationErrors();
		this._hasValidated = true;
		this._setValidationErrors(errors);
		this._showValidationToast(errors);
		return errors;
	}
}
