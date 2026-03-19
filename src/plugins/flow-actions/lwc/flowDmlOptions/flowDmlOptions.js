import { LightningElement, api, track } from "lwc";

const DEFAULT_ASSIGNMENT_RULE = { assignmentRuleId: null, useDefaultRule: false };
const DEFAULT_DUPLICATE_RULE = { allowSave: false, runAsCurrentUser: false };
const DEFAULT_EMAIL_HEADER = {
	triggerAutoResponseEmail: false,
	triggerOtherEmail: false,
	triggerUserEmail: false
};

const BOOLEAN_OPTIONS = [
	{ label: "True", value: "true" },
	{ label: "False", value: "false" }
];

const LOCALE_CODES = [
	"ar",
	"ar_AE",
	"bg_BG",
	"ca_ES",
	"cs_CZ",
	"da_DK",
	"de",
	"de_AT",
	"de_CH",
	"el_GR",
	"en_AU",
	"en_CA",
	"en_GB",
	"en_IE",
	"en_IN",
	"en_NZ",
	"en_SG",
	"en_US",
	"en_ZA",
	"es",
	"es_AR",
	"es_BO",
	"es_CL",
	"es_CO",
	"es_CR",
	"es_DO",
	"es_EC",
	"es_ES",
	"es_GT",
	"es_HN",
	"es_MX",
	"es_NI",
	"es_PA",
	"es_PE",
	"es_PR",
	"es_PY",
	"es_SV",
	"es_US",
	"es_UY",
	"es_VE",
	"et_EE",
	"fi_FI",
	"fr",
	"fr_BE",
	"fr_CA",
	"fr_CH",
	"fr_FR",
	"ga_IE",
	"he_IL",
	"hi_IN",
	"hr_HR",
	"hu_HU",
	"hy_AM",
	"id_ID",
	"is_IS",
	"it",
	"it_CH",
	"it_IT",
	"ja_JP",
	"ko_KR",
	"lt_LT",
	"lv_LV",
	"ms_MY",
	"mt_MT",
	"nl_BE",
	"nl_NL",
	"no_NO",
	"pl_PL",
	"pt_BR",
	"pt_PT",
	"ro_RO",
	"ru_RU",
	"sk_SK",
	"sl_SI",
	"sq_AL",
	"sr_BA",
	"sr_RS",
	"sv_SE",
	"th_TH",
	"tr_TR",
	"uk_UA",
	"vi_VN",
	"zh_CN",
	"zh_HK",
	"zh_TW"
];

const LOCALE_OPTIONS = LOCALE_CODES.map((localeCode) => ({ label: localeCode, value: localeCode }));

const FIELD_METADATA = {
	allowFieldTruncation: {
		label: "Allow Field Truncation",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	},
	localeOptions: {
		label: "Locale",
		dataType: "String",
		inputType: "picklist",
		options: LOCALE_OPTIONS,
		placeholder: "Select a locale"
	},
	assignmentRuleId: {
		label: "Assignment Rule ID",
		dataType: "String",
		inputType: "text"
	},
	useDefaultRule: {
		label: "Use Default Rule",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	},
	allowSave: {
		label: "Allow Save",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	},
	runAsCurrentUser: {
		label: "Run As Current User",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	},
	triggerAutoResponseEmail: {
		label: "Trigger Auto-Response Email",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	},
	triggerOtherEmail: {
		label: "Trigger Other Email",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	},
	triggerUserEmail: {
		label: "Trigger User Email",
		dataType: "Boolean",
		inputType: "boolean",
		options: BOOLEAN_OPTIONS,
		defaultValue: false
	}
};

const SECTION_FIELDS = {
	assignmentRuleHeader: ["assignmentRuleId", "useDefaultRule"],
	duplicateRuleHeader: ["allowSave", "runAsCurrentUser"],
	emailHeader: ["triggerAutoResponseEmail", "triggerOtherEmail", "triggerUserEmail"]
};

const CATEGORY_LABELS = {
	constants: "Constant",
	formulas: "Formula",
	variables: "Variable"
};

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

function hasOwnValue(container, key) {
	return !!container && Object.prototype.hasOwnProperty.call(container, key);
}

function normalizeReferenceName(value) {
	if (typeof value !== "string") {
		return null;
	}

	if (value.startsWith("{!") && value.endsWith("}")) {
		return value.slice(2, -1);
	}

	return value;
}

function isReferenceValue(value) {
	return typeof value === "string" && value.startsWith("{!") && value.endsWith("}");
}

function cloneValue(value) {
	return value ? JSON.parse(JSON.stringify(value)) : {};
}

function removePath(container, path) {
	const parts = path.split(".");
	const fieldName = parts.pop();
	let cursor = container;

	for (const part of parts) {
		if (!cursor[part]) {
			return container;
		}

		cursor = cursor[part];
	}

	delete cursor[fieldName];
	return container;
}

function setPath(container, path, value) {
	const parts = path.split(".");
	const fieldName = parts.pop();
	let cursor = container;

	for (const part of parts) {
		cursor[part] = cursor[part] ?? {};
		cursor = cursor[part];
	}

	cursor[fieldName] = value;
	return container;
}

function pruneEmptyObjects(container) {
	const next = cloneValue(container);

	Object.keys(SECTION_FIELDS).forEach((sectionName) => {
		if (!next[sectionName] || !Object.keys(next[sectionName]).length) {
			delete next[sectionName];
		}
	});

	return next;
}

export default class FlowDmlOptions extends LightningElement {
	@api builderContext = {};

	@track _includedState = {};
	_value = {};

	@api
	get value() {
		return this._value;
	}

	set value(nextValue) {
		this._value = nextValue ?? {};
		this._initializeIncludedState();
	}

	get safeValue() {
		return this._value ?? {};
	}

	get assignmentRule() {
		return this.safeValue.assignmentRuleHeader ?? DEFAULT_ASSIGNMENT_RULE;
	}

	get duplicateRule() {
		return this.safeValue.duplicateRuleHeader ?? DEFAULT_DUPLICATE_RULE;
	}

	get emailHeader() {
		return this.safeValue.emailHeader ?? DEFAULT_EMAIL_HEADER;
	}

	get topLevelFields() {
		return ["allowFieldTruncation", "localeOptions"].map((fieldName) => this._buildFieldConfig(fieldName));
	}

	get assignmentRuleFields() {
		return SECTION_FIELDS.assignmentRuleHeader.map((fieldName) =>
			this._buildFieldConfig(fieldName, "assignmentRuleHeader")
		);
	}

	get duplicateRuleFields() {
		return SECTION_FIELDS.duplicateRuleHeader.map((fieldName) =>
			this._buildFieldConfig(fieldName, "duplicateRuleHeader")
		);
	}

	get emailHeaderFields() {
		return SECTION_FIELDS.emailHeader.map((fieldName) => this._buildFieldConfig(fieldName, "emailHeader"));
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

	_initializeIncludedState() {
		const nextState = {};

		["allowFieldTruncation", "localeOptions"].forEach((fieldName) => {
			nextState[fieldName] = hasOwnValue(this.safeValue, fieldName);
		});

		Object.entries(SECTION_FIELDS).forEach(([sectionName, fieldNames]) => {
			fieldNames.forEach((fieldName) => {
				nextState[`${sectionName}.${fieldName}`] = hasOwnValue(this.safeValue[sectionName], fieldName);
			});
		});

		this._includedState = nextState;
	}

	_buildFieldConfig(fieldName, sectionName) {
		const metadata = FIELD_METADATA[fieldName];
		const path = sectionName ? `${sectionName}.${fieldName}` : fieldName;
		const container = sectionName ? (this.safeValue[sectionName] ?? {}) : this.safeValue;
		const rawValue = container[fieldName];

		return {
			key: path,
			name: path,
			label: metadata.label,
			dataType: metadata.dataType,
			inputType: metadata.inputType,
			options: metadata.options ?? [],
			defaultValue: metadata.defaultValue,
			placeholder: metadata.placeholder,
			included: this._includedState[path] ?? false,
			value: rawValue,
			valueDataType: isReferenceValue(rawValue) ? "reference" : metadata.dataType,
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
						typeof resource.dataType === "string"
							? resource.dataType?.endsWith("[]") ||
								resource.isCollection === true ||
								resource.isCollection === "true"
							: false
				}))
		);
	}

	_buildResourceOptions(metadata) {
		return this.availableResources
			.filter((resource) => this._matchesResource(metadata, resource))
			.map((resource) => ({
				...resource,
				label: resource.label,
				value: resource.value
			}));
	}

	_matchesResource(metadata, resource) {
		if (metadata.dataType === "Boolean") {
			return resource.dataType === "Boolean";
		}

		return (
			!resource.isCollection &&
			!resource.objectType &&
			(resource.dataType === "String" || resource.dataType === undefined || resource.dataType === null)
		);
	}

	_emit(updated) {
		this.dispatchEvent(
			new CustomEvent("dmloptionschange", {
				bubbles: true,
				composed: true,
				detail: { value: updated }
			})
		);
	}

	handleFieldChange(event) {
		const { name, value } = event.detail;
		const updated = setPath(cloneValue(this.safeValue), name, value);
		this._includedState = { ...this._includedState, [name]: true };
		this._emit(pruneEmptyObjects(updated));
	}

	handleFieldIncludedChange(event) {
		const { name, included } = event.detail;
		const updatedState = { ...this._includedState, [name]: included };
		this._includedState = updatedState;

		const metadata = FIELD_METADATA[name.split(".").pop()];
		const updated = cloneValue(this.safeValue);

		if (included) {
			setPath(updated, name, metadata.defaultValue ?? null);
			this._emit(pruneEmptyObjects(updated));
			return;
		}

		this._emit(pruneEmptyObjects(removePath(updated, name)));
	}

	get selectedReferenceNames() {
		return new Set(
			Object.values(this.safeValue)
				.flatMap((value) =>
					value && typeof value === "object" && !Array.isArray(value) ? Object.values(value) : [value]
				)
				.map((value) => normalizeReferenceName(value))
				.filter(Boolean)
		);
	}
}
