/**
 * Builds the menus for `c-flow-resource-picker` from a Custom Property Editor's `builderContext`, mirroring the
 * categories, order, icons, and drill-down of Flow Builder's own resource picker.
 */
const DRILL_GLOBAL = "global";
const DRILL_OUTPUTS = "outputs";
const DRILL_RECORD = "record";
const ICON_RECORD = "utility:record_alt";
const ICON_RECORD_COLLECTION = "utility:record_collection";
const SOBJECT = "SObject";

// Flow Builder's own message for an empty required input, shared by the picker and the editors that validate it
export const REQUIRED_ERROR = "Enter a value.";
// The data type Flow Builder saves for an input set to a resource, not a typed-in value
export const REFERENCE = "reference";
// Shared, since creating a collator per comparison makes sorting large menus slow
const LABEL_COLLATOR = new Intl.Collator(undefined, { sensitivity: "base" });
const TYPE_ORDER = ["Boolean", "Currency", "Date", "DateTime", "Multipicklist", "Number", "Picklist", "String", "Time"];

// UI API field data types that Flow treats as something other than text
const FLOW_TYPES_BY_FIELD_TYPE = {
	Boolean: "Boolean",
	Currency: "Currency",
	Date: "Date",
	DateTime: "DateTime",
	Double: "Number",
	Int: "Number",
	Long: "Number",
	MultiPicklist: "Multipicklist",
	Percent: "Number",
	Picklist: "Picklist",
	Time: "Time"
};

// automaticOutputVariables report data types in lowercase
const FLOW_TYPES_BY_OUTPUT_TYPE = {
	apex: "Apex",
	boolean: "Boolean",
	currency: "Currency",
	date: "Date",
	datetime: "DateTime",
	number: "Number",
	sobject: SOBJECT,
	string: "String"
};

const TYPE_ICONS = {
	Boolean: "utility:toggle",
	Currency: "utility:currency",
	Date: "utility:event",
	DateTime: "utility:date_time",
	Multipicklist: "utility:multi_picklist",
	Number: "utility:topic2",
	Picklist: "utility:picklist_type",
	Time: "utility:clock"
};

// shortcut: Flow Builder's $Api endpoints as of API v68.0; add new versions as they ship
const API_VERSIONS = [25, 30, 40, 50, 60, 70, 80, 90, 100, 110, 111];
for (let version = 120; version <= 680; version += 10) {
	API_VERSIONS.push(version);
}
const API_FIELDS = API_VERSIONS.flatMap((version) => [
	`Enterprise_Server_URL_${version}`,
	`Partner_Server_URL_${version}`
]);

// Flow Builder lists a fixed set of fields for each global variable, by API name
const GLOBAL_VARIABLES = [
	{ value: "$Api", label: "API", icon: "utility:system_and_global_variable", fields: { String: API_FIELDS.sort() } },
	{
		value: "$Flow",
		label: "Running Flow Interview",
		icon: "utility:flow",
		fields: {
			Date: ["CurrentDate"],
			DateTime: ["CurrentDateTime", "InterviewStartTime"],
			String: ["CurrentRecord", "CurrentStage", "FaultMessage", "InterviewGuid"]
		}
	},
	{
		value: "$Organization",
		label: "Running Org",
		icon: "utility:company",
		fields: {
			Number: ["Latitude", "Longitude"],
			Picklist: ["GeocodeAccuracy", "UiSkin"],
			String: [
				"Address",
				"City",
				"Country",
				"Division",
				"Fax",
				"GoogleAppsDomain",
				"Id",
				"Name",
				"Phone",
				"PostalCode",
				"State",
				"Street"
			]
		}
	},
	{
		value: "$User",
		label: "Running User",
		icon: "utility:user",
		fields: {
			Boolean: ["IsActive"],
			Number: ["Latitude", "Longitude"],
			Picklist: [
				"EndDay",
				"GeocodeAccuracy",
				"LanguageLocaleKey",
				"LocaleSidKey",
				"StartDay",
				"TimeZoneSidKey",
				"UserType"
			],
			String: [
				"Address",
				"Alias",
				"City",
				"CommunityNickname",
				"CompanyName",
				"ContactId",
				"Country",
				"Department",
				"Division",
				"Email",
				"EmployeeNumber",
				"Extension",
				"Fax",
				"FederationIdentifier",
				"FirstName",
				"Id",
				"LastName",
				"ManagerId",
				"MobilePhone",
				"Phone",
				"PostalCode",
				"ProfileId",
				"Signature",
				"State",
				"Street",
				"Title",
				"UITheme",
				"UIThemeDisplayed",
				"Username",
				"UserRoleId"
			]
		}
	},
	{
		value: "$Profile",
		label: "Running User Profile",
		icon: "utility:user_role",
		fields: {
			Boolean: ["ManageUsers"],
			DateTime: ["CreatedDate", "LastModifiedDate"],
			Picklist: ["UsageType", "UserType"],
			String: ["CreatedById", "Description", "Id", "LastModifiedById", "Name"]
		}
	},
	{
		value: "$UserRole",
		label: "Running User Role",
		icon: "utility:user_role",
		fields: {
			Boolean: ["MayForecastManagerShare"],
			DateTime: ["LastModifiedDate"],
			Picklist: [
				"CaseAccessForAccountOwner",
				"ContactAccessForAccountOwner",
				"OpportunityAccessForAccountOwner",
				"PortalRole",
				"PortalType"
			],
			String: ["DeveloperName", "Id", "LastModifiedById", "Name", "RollupDescription"]
		}
	},
	{
		value: "$System",
		label: "System",
		icon: "utility:system_and_global_variable",
		fields: { DateTime: ["OriginDateTime"] }
	}
];

// Built once, since canDrill checks $Api's ~140 fields on every keystroke
const GLOBALS_BY_VALUE = new Map(GLOBAL_VARIABLES.map((global) => [global.value, initGlobal(global)]));
// Scopes walk the flow's connectors, so each builder context gets one per element, not one per keystroke
const SCOPES = new WeakMap();

const GLOBAL_CONSTANTS = [
	{ value: "$GlobalConstant.False", label: "False", dataType: "Boolean" },
	{ value: "$GlobalConstant.True", label: "True", dataType: "Boolean" },
	{ value: "$GlobalConstant.EmptyString", label: "Blank Value (Empty String)", dataType: "String" }
];

/**
 * @description Builds the top-level menu: every resource in the flow that fits the target input, or contains one that does.
 * @param {Object} context `{ builderContext, automaticOutputVariables, objectLabels }`
 * @param {Object} target The input being configured: `{ dataType, isCollection, isPicklistOnly, objectType, picklistValues }`. Null includes everything; a record target without `isCollection` takes either.
 * @returns {Array} Sections of `{ label, items, hasDivider }`, in Flow Builder's order
 */
export function getRootSections(context, target) {
	const picklistItems = (target?.picklistValues ?? []).map(initPicklistItem);
	const picklist = initSection("Picklist Values", picklistItems, false);
	// A picklist-only target skips building the resources it would discard
	const sections = target?.isPicklistOnly ? [picklist] : [picklist, ...initResourceSections(context)];
	return applyTarget(sections, target, context);
}

/**
 * @description Builds the menu for drilling into an item: a record's fields, an action's outputs, or a global variable's fields.
 * @param {Object} item The item to drill into
 * @param {Object} context `{ builderContext, automaticOutputVariables, objectLabels }`
 * @param {Object} target The input being configured. Null includes everything.
 * @param {Function} describeObject Resolves an object's describe, given its API name
 * @returns {Promise<Array>} Sections of `{ label, items }`
 */
export async function getChildSections(item, context, target, describeObject) {
	const loaders = {
		[DRILL_GLOBAL]: getGlobalSections,
		[DRILL_OUTPUTS]: getOutputSections,
		[DRILL_RECORD]: getRecordSections
	};
	// Flow can't reference a collection's fields, so a collection has nothing to drill into, even when typed
	const loader = item?.isCollection ? null : loaders[item?.drillType];
	const sections = loader ? await loader(item, context, describeObject) : [];
	return applyTarget(sections, target, context);
}

/**
 * @description Narrows a menu to items whose label or value contains the search term.
 * @param {Array} sections The menu to filter
 * @param {String} searchTerm Case-insensitive text to look for
 * @returns {Array} The matching sections, without any that end up empty
 */
export function filterSections(sections, searchTerm) {
	const term = searchTerm?.trim()?.toLowerCase() ?? "";
	return sections
		.map((section) => ({ ...section, items: section.items.filter((item) => matchesSearch(item, term)) }))
		.filter((section) => section.items.length);
}

/**
 * @description Finds the item for a reference, walking through each step of a drilled path.
 * @param {String} path A reference, without merge field braces, ex: `accountVar.Owner.Email`
 * @param {Object} context `{ builderContext, automaticOutputVariables, objectLabels }`
 * @param {Function} describeObject Resolves an object's describe, given its API name
 * @returns {Promise<Object>} The matching item, or null if the reference doesn't exist
 */
export async function resolveItem(path, context, describeObject) {
	let sections = getRootSections(context, null);
	let item = null;
	let value = "";
	for (const segment of path?.split(".") ?? []) {
		value = value ? `${value}.${segment}` : segment;
		const match = findItem(sections, value);
		item = match ?? item;
		// The last item's children aren't needed, so its object isn't described
		if (match && value !== path) {
			// eslint-disable-next-line no-await-in-loop
			sections = await getChildSections(match, context, null, describeObject);
		}
	}
	return item?.value === path ? item : null;
}

/**
 * @description Reads a boolean literal as the global constant Flow Builder saves it as, ex: `true` or "TRUE" as
 * `$GlobalConstant.True`.
 * @param {*} value A literal value, or a boolean global constant
 * @returns {String} `$GlobalConstant.True` or `$GlobalConstant.False`, or null if the value isn't a boolean
 */
export function toBooleanConstant(value) {
	const text = String(value).trim().toLowerCase();
	const matches = (constant) => [constant.label, constant.value].some((name) => name.toLowerCase() === text);
	const constant = GLOBAL_CONSTANTS.find((candidate) => candidate.dataType === "Boolean" && matches(candidate));
	return constant?.value ?? null;
}

/**
 * @description Reads the picker's text: a partial or complete merge field, or a plain search term.
 * @param {String} text The text in the picker's input
 * @returns {Object} `{ isReference, isComplete, path, parentPath, searchTerm }`, where `path` has no merge field braces,
 * and a reference's last segment is its search term, ex: `{!accountVar.Na` searches `accountVar` for `Na`
 */
export function parseInput(text) {
	const trimmed = text?.trim() ?? "";
	const isReference = trimmed.startsWith("{!");
	const isComplete = isReference && trimmed.endsWith("}");
	const body = isReference ? trimmed.slice(2) : trimmed;
	const path = isComplete ? body.slice(0, -1) : body;
	const lastDot = isReference ? path.lastIndexOf(".") : -1;
	return {
		isReference,
		isComplete,
		path,
		parentPath: path.slice(0, Math.max(lastDot, 0)),
		searchTerm: path.slice(lastDot + 1)
	};
}

/**
 * @description Orders items alphabetically by label, ignoring case.
 * @param {Object} first An item or field
 * @param {Object} second Another item or field
 * @returns {Number} The sort order
 */
export function compareLabels(first, second) {
	return LABEL_COLLATOR.compare(first.label, second.label);
}

/**
 * @description Whether the target input accepts the item.
 * @param {Object} item The item to evaluate
 * @param {Object} target The input being configured. Null accepts everything.
 * @returns {Boolean} True if the item can be selected
 */
export function isAssignable(item, target) {
	const isRecordTarget = target?.dataType === SOBJECT;
	const matchesObject = !target?.objectType || item.objectType === target.objectType;
	const matchesShape = target?.isCollection == null || item.isCollection === target.isCollection;
	const matchesRecord = item.dataType === SOBJECT && matchesShape && matchesObject;
	const isScalar = Boolean(item.dataType) && !item.isCollection && ![SOBJECT, "Apex"].includes(item.dataType);
	const matchesScalar = isScalar && item.dataType === target?.dataType;
	// Typing mustn't reach values that a picklist-only target doesn't list
	const isListed =
		Boolean(item.isLiteral) && (target?.picklistValues ?? []).some(({ value }) => value === item.value);
	const matchesMode = !target?.isPicklistOnly || isListed;
	return !target || (matchesMode && (isRecordTarget ? matchesRecord : matchesScalar));
}

// **** PRIVATE **** //
/**
 * @description Marks each item as selectable and/or drillable for the target, dropping items that are neither.
 * @param {Array} sections The sections to evaluate
 * @param {Object} target The input being configured. Null includes everything.
 * @param {Object} context Used to look up action outputs
 * @returns {Array} The sections with at least one remaining item
 */
function applyTarget(sections, target, context) {
	return sections
		.map((section) => ({
			...section,
			items: section.items
				.map((item) => ({
					...item,
					isSelectable: isAssignable(item, target),
					isDrillable: canDrill(item, target, context)
				}))
				.filter((item) => item.isSelectable || item.isDrillable)
		}))
		.filter((section) => section.items.length);
}

/**
 * @description Whether an item could contain something the target accepts.
 * @param {Object} item The item to evaluate
 * @param {Object} target The input being configured
 * @param {Object} context Used to look up action outputs
 * @returns {Boolean} True if drilling into the item could find a match
 */
function canDrill(item, target, context) {
	const isRecordTarget = target?.dataType === SOBJECT;
	const checks = {
		[DRILL_GLOBAL]: () => findGlobal(item.value).items.some((field) => isAssignable(field, target)),
		[DRILL_OUTPUTS]: () =>
			initOutputItems(item, context).some(
				(output) => isAssignable(output, target) || canDrill(output, target, context)
			),
		[DRILL_RECORD]: () => !item.isCollection && !isRecordTarget
	};
	return checks[item.drillType]?.() ?? false;
}

/**
 * @description Finds the item with the given value.
 * @param {Array} sections The sections to search
 * @param {String} value The value to find
 * @returns {Object} The matching item, if any
 */
function findItem(sections, value) {
	return sections.flatMap((section) => section.items).find((item) => item.value === value);
}

/**
 * @description Finds a global variable's definition, with its fields as items.
 * @param {String} value The global variable, ex: `$User`
 * @returns {Object} `{ label, items }`
 */
function findGlobal(value) {
	return GLOBALS_BY_VALUE.get(value);
}

/**
 * @description Lists a global variable's fields.
 * @param {Object} item The global variable's item
 * @returns {Array} One section, labeled for the global variable
 */
function getGlobalSections(item) {
	const global = findGlobal(item.value);
	return [initSection(global.label, global.items, false)];
}

/**
 * @description Lists an action's automatically stored outputs.
 * @param {Object} item The action's item
 * @param {Object} context Used to look up action outputs
 * @returns {Array} One "Outputs" section
 */
function getOutputSections(item, context) {
	const outputs = initOutputItems(item, context);
	return [initSection("Outputs", outputs, false)];
}

/**
 * @description Lists a record's fields; an object that can't be described (deleted, or no access) has none to drill into
 * @param {Object} item The record's item
 * @param {Object} context Unused; matches the other loaders' signature
 * @param {Function} describeObject Resolves an object's describe, given its API name
 * @returns {Promise<Array>} "Relationship Fields" and "Record Fields" sections
 */
async function getRecordSections(item, context, describeObject) {
	const describe = await describeObject(item.objectType).catch(() => null);
	const fields = Object.values(describe?.fields ?? {});
	return initRecordSections(fields, item);
}

/**
 * @description Lists lookups first, as drillable relationships and then as Ids, then the other fields by type and
 * label, matching Flow Builder's order
 * @param {Array} fields The object's field describes
 * @param {Object} item The record's item
 * @returns {Array} "Relationship Fields" and "Record Fields" sections
 */
function initRecordSections(fields, item) {
	const sorted = [...fields].sort(compareLabels);
	const lookups = sorted.filter((field) => field.relationshipName && field.referenceToInfos?.length);
	const others = sorted.filter((field) => !lookups.includes(field));
	const relationships = lookups.map((field) => initRelationshipItem(field, item));
	const lookupIds = lookups.map((field) => initFieldItem(field, item));
	const recordFields = others.map((field) => initFieldItem(field, item)).sort(compareTypes);
	return [
		initSection("Relationship Fields", [...relationships, ...lookupIds], false),
		initSection("Record Fields", recordFields, false)
	];
}

/**
 * @description Builds an item for each action with automatically stored outputs.
 * @param {Object} builderContext The CPE's builder context
 * @param {Object} context Used to look up action outputs
 * @param {Object} scope Which elements can run before the one being edited
 * @returns {Array} The action items
 */
function initActionItems(builderContext, context, scope) {
	const hasOutputs = (action) => action.storeOutputAutomatically && context?.automaticOutputVariables?.[action.name];
	return (builderContext.actionCalls ?? [])
		.filter((action) => hasOutputs(action) && scope.isUpstream(action.name))
		.map((action) =>
			initItem({
				value: action.name,
				label: `Outputs from ${action.label}`,
				icon: "utility:fallback",
				drillType: DRILL_OUTPUTS
			})
		);
}

/**
 * @description Builds an item for an object field.
 * @param {Object} field The field's describe
 * @param {Object} parent The record the field belongs to
 * @returns {Object} The field's item
 */
function initFieldItem(field, parent) {
	const dataType = FLOW_TYPES_BY_FIELD_TYPE[field.dataType] ?? "String";
	const value = `${parent.value}.${field.apiName}`;
	return initItem({ value, label: field.label, pathLabel: `${parent.pathLabel} > ${field.label}`, dataType });
}

/**
 * @description Builds the item for each Collection Filter element: a collection like the one it filters. Collection
 * Sort elements sort in place, so they add no resource.
 * @param {Object} builderContext The CPE's builder context
 * @param {Array} collections Items the filters may filter
 * @param {Object} context Used to look up action outputs and object labels
 * @param {Object} scope Which filters can run before the element being edited
 * @returns {Array} The filter items
 */
function initFilterItems(builderContext, collections, context, scope) {
	const filters = (builderContext.collectionProcessors ?? []).filter(
		(processor) => processor.elementSubtype === "FilterCollectionProcessor"
	);
	// shortcut: a filter of a filter resolves only when listed after it; resolve recursively if flows list them out of order
	const items = filters.reduce((filtered, filter) => {
		const source =
			[...collections, ...filtered].find((item) => item.value === filter.collectionReference) ??
			resolveOutput(filter.collectionReference, context);
		return [...filtered, initFilterItem(filter, source, context)];
	}, []);
	return items.filter((item) => scope.isUpstream(item.value));
}

/**
 * @description Builds a Collection Filter element's item, labeled like Get Records'.
 * @param {Object} filter The Collection Filter element
 * @param {Object} source The item for the collection it filters, if known
 * @param {Object} context Supplies the object's labels, once known
 * @returns {Object} The filter's item
 */
function initFilterItem(filter, source, context) {
	const isRecord = source?.dataType === SOBJECT;
	const objectLabel = context?.objectLabels?.[source?.objectType]?.labelPlural ?? source?.objectType;
	return initItem({
		value: filter.name,
		label: isRecord ? `${objectLabel} from ${filter.label}` : filter.label,
		dataType: source?.dataType,
		objectType: source?.objectType,
		isCollection: true,
		drillType: isRecord ? DRILL_RECORD : null
	});
}

/**
 * @description Builds a global variable's fields as items.
 * @param {Object} global The global variable's definition
 * @returns {Object} `{ label, items }`
 */
function initGlobal(global) {
	const items = Object.entries(global.fields).flatMap(([dataType, names]) =>
		names.map((name) =>
			initItem({
				value: `${global.value}.${name}`,
				label: name,
				pathLabel: `${global.value} > ${name}`,
				dataType
			})
		)
	);
	return { label: global.label, items };
}

/**
 * @description Builds a global variable's item.
 * @param {Object} global The global variable's definition
 * @returns {Object} The global variable's item
 */
function initGlobalItem(global) {
	return initItem({
		value: global.value,
		label: global.label,
		pathLabel: global.value,
		icon: global.icon,
		drillType: DRILL_GLOBAL
	});
}

/**
 * @description Applies defaults to an item, deriving its icon from its data type.
 * @param {Object} props The item's properties
 * @returns {Object} The item
 */
function initItem(props) {
	const isRecord = props.dataType === SOBJECT;
	const recordIcon = props.isCollection ? ICON_RECORD_COLLECTION : ICON_RECORD;
	const typeIcon = TYPE_ICONS[props.dataType] ?? "utility:text";
	const icon = isRecord ? recordIcon : typeIcon;
	return { icon, isCollection: false, isLiteral: false, drillType: null, pathLabel: props.label, ...props };
}

/**
 * @description Builds the "Current Item from Loop" item for each loop that stores its current item automatically.
 * @param {Object} builderContext The CPE's builder context
 * @param {Array} collections Items the loops may iterate over
 * @param {Object} context Used to look up action outputs
 * @param {Object} scope Which loops contain the element being edited
 * @returns {Array} The loop items
 */
function initLoopItems(builderContext, collections, context, scope) {
	return (builderContext.loops ?? [])
		.filter((loop) => !loop.assignNextValueToReference && scope.isInLoop(loop))
		.map((loop) => {
			const collection =
				collections.find((item) => item.value === loop.collectionReference) ??
				resolveOutput(loop.collectionReference, context);
			const isRecord = collection?.dataType === SOBJECT;
			return initItem({
				value: loop.name,
				label: `Current Item from Loop ${loop.label}`,
				dataType: collection?.dataType,
				objectType: collection?.objectType,
				drillType: isRecord ? DRILL_RECORD : null
			});
		});
}

/**
 * @description Builds the item for a Get Records element that stores its output automatically.
 * @param {Object} lookup The Get Records element
 * @param {Object} context Supplies the object's labels, once known
 * @returns {Object} The lookup's item
 */
function initLookupItem(lookup, context) {
	const isCollection = !lookup.getFirstRecordOnly;
	const labels = context?.objectLabels?.[lookup.object];
	const objectLabel = (isCollection ? labels?.labelPlural : labels?.label) ?? lookup.object;
	return initItem({
		value: lookup.name,
		label: `${objectLabel} from ${lookup.label}`,
		dataType: SOBJECT,
		objectType: lookup.object,
		isCollection,
		drillType: DRILL_RECORD
	});
}

/**
 * @description Builds the items for an action's outputs, records first.
 * @param {Object} action The action's item
 * @param {Object} context Used to look up action outputs
 * @returns {Array} The output items
 */
function initOutputItems(action, context) {
	const outputs = context?.automaticOutputVariables?.[action.value] ?? [];
	return outputs
		.map((output) => {
			const dataType = FLOW_TYPES_BY_OUTPUT_TYPE[output.dataType] ?? "String";
			return initItem({
				value: `${action.value}.${output.name}`,
				label: output.label ?? output.name,
				pathLabel: `${action.pathLabel} > ${output.label ?? output.name}`,
				dataType,
				objectType: output.sobjectType,
				isCollection: output.maxOccurs > 1,
				drillType: dataType === SOBJECT ? DRILL_RECORD : null
			});
		})
		.sort(
			(first, second) =>
				Number(second.dataType === SOBJECT) - Number(first.dataType === SOBJECT) || compareLabels(first, second)
		);
}

/**
 * @description Builds a literal item for a picklist value.
 * @param {Object} picklistValue `{ label, value }`, optionally with a `description` and `icon`
 * @returns {Object} The picklist value's item
 */
function initPicklistItem(picklistValue) {
	return initItem({ icon: "utility:picklist_type", ...picklistValue, dataType: "String", isLiteral: true });
}

/**
 * @description Builds the item for a lookup relationship, which drills into the related record.
 * @param {Object} field The lookup field's describe
 * @param {Object} parent The record the field belongs to
 * @returns {Object} The relationship's item
 */
function initRelationshipItem(field, parent) {
	return initItem({
		value: `${parent.value}.${field.relationshipName}`,
		label: field.label,
		pathLabel: `${parent.pathLabel} > ${field.label}`,
		dataType: SOBJECT,
		// shortcut: polymorphic lookups (ex: Owner on Case) drill into their first type; list each type if users need others
		objectType: field.referenceToInfos[0].apiName,
		drillType: DRILL_RECORD
	});
}

/**
 * @description Builds the menu's resource sections: every resource in the flow, plus global constants and variables.
 * @param {Object} context `{ builderContext, automaticOutputVariables, objectLabels }`
 * @returns {Array} Sections of `{ label, items, hasDivider }`, in Flow Builder's order
 */
function initResourceSections(context) {
	const builderContext = context?.builderContext ?? {};
	const scope = getScope(builderContext, context?.elementName);
	const variables = (builderContext.variables ?? []).map(initVariableItem);
	const lookups = (builderContext.recordLookups ?? [])
		.filter((lookup) => lookup.storeOutputAutomatically && scope.isUpstream(lookup.name))
		.map((lookup) => initLookupItem(lookup, context));
	const filters = initFilterItems(builderContext, [...variables, ...lookups], context, scope);
	const loops = initLoopItems(builderContext, [...variables, ...lookups, ...filters], context, scope);
	const triggers = initTriggerItems(builderContext, context);
	const quickResources = initSection("Quick Resources", [...triggers, ...loops], false);
	const actions = initActionItems(builderContext, context, scope);
	const choices = (builderContext.choices ?? []).map(initTypedItem);
	const constants = (builderContext.constants ?? []).map(initTypedItem);
	const formulas = (builderContext.formulas ?? []).map(initTypedItem);
	const records = variables.filter((item) => item.dataType === SOBJECT);
	const recordCollections = records.filter((item) => item.isCollection);
	const recordVariables = records.filter((item) => !item.isCollection);
	const screenComponents = initScreenItems(builderContext, scope);
	const simpleVariables = variables.filter((item) => item.dataType !== SOBJECT);
	const stages = (builderContext.stages ?? []).map(initStageItem);
	const textTemplates = (builderContext.textTemplates ?? []).map(initTextTemplateItem);
	const globalConstants = GLOBAL_CONSTANTS.map((constant) => initItem(constant));
	const globalVariables = GLOBAL_VARIABLES.map(initGlobalItem);
	return [
		// Flow Builder divides quick resources from the rest of the menu
		{ ...quickResources, hasDivider: true },
		initSection("Action", actions),
		initSection("Collection Filter", filters),
		initSection("Get Records", lookups),
		initSection("Choices", choices),
		initSection("Constants", constants),
		initSection("Formulas", formulas),
		initSection("Record Collections", recordCollections),
		initSection("Record Variables", recordVariables),
		initSection("Screen Components", screenComponents),
		initSection("Simple Variables", simpleVariables),
		initSection("Stages", stages),
		initSection("Text Templates", textTemplates),
		initSection("Global Constants", globalConstants, false),
		initSection("Global Variables", globalVariables, false)
	];
}

/**
 * @description Builds the items for screen components that store a value, including those nested in sections.
 * @param {Object} builderContext The CPE's builder context
 * @param {Object} scope Which screens can run before the element being edited
 * @returns {Array} The screen component items
 */
function initScreenItems(builderContext, scope) {
	const flatten = (fields) => fields.flatMap((field) => [field, ...flatten(field.fields ?? [])]);
	const screens = (builderContext.screens ?? []).filter((screen) => scope.isUpstream(screen.name));
	const fields = screens.flatMap((screen) => flatten(screen.fields ?? []));
	return fields.filter((field) => field.dataType).map(initTypedItem);
}

/**
 * @description Wraps items in a section, sorted by label unless Flow Builder uses a fixed order.
 * @param {String} label The section's label
 * @param {Array} items The section's items
 * @param {Boolean} isSorted Whether to sort the items by label
 * @returns {Object} `{ label, items }`, with a unique key on each item
 */
function initSection(label, items, isSorted = true) {
	const ordered = isSorted ? [...items].sort(compareLabels) : items;
	return { label, items: ordered.map((item) => ({ ...item, key: `${label}:${item.value}` })) };
}

/**
 * @description Builds a stage's item.
 * @param {Object} stage The stage
 * @returns {Object} The stage's item
 */
function initStageItem(stage) {
	return initItem({ value: stage.name, label: stage.label, dataType: "String", icon: "utility:stage" });
}

/**
 * @description Builds a text template's item.
 * @param {Object} template The text template
 * @returns {Object} The text template's item
 */
function initTextTemplateItem(template) {
	return initItem({ value: template.name, label: template.name, dataType: "String", icon: "utility:text_template" });
}

/**
 * @description Builds an item for a named resource of a given type.
 * @param {Object} resource The resource's `{ name, dataType }`: its API name and Flow data type
 * @returns {Object} The resource's item
 */
function initTypedItem({ name, dataType }) {
	return initItem({ value: name, label: name, dataType });
}

/**
 * @description Builds a variable's item.
 * @param {Object} variable The variable
 * @returns {Object} The variable's item
 */
function initVariableItem(variable) {
	const isRecord = variable.dataType === SOBJECT;
	return initItem({
		value: variable.name,
		label: variable.name,
		dataType: variable.dataType,
		objectType: variable.objectType,
		isCollection: Boolean(variable.isCollection),
		drillType: isRecord ? DRILL_RECORD : null
	});
}

/**
 * @description Whether an item's label or value contains the search term.
 * @param {Object} item The item to evaluate
 * @param {String} term Lowercase search term
 * @returns {Boolean} True if the item matches
 */
function matchesSearch(item, term) {
	return `${item.label}\n${item.value}`.toLowerCase().includes(term);
}

/**
 * @description Finds the action output that a reference like `Action_Name.outputName` points to.
 * @param {String} reference The reference to resolve
 * @param {Object} context Used to look up action outputs
 * @returns {Object} The output's item, if any
 */
function resolveOutput(reference, context) {
	const [actionName] = reference?.split(".") ?? [];
	const action = initItem({ value: actionName, label: actionName });
	return initOutputItems(action, context).find((output) => output.value === reference);
}

/**
 * @description Finds every element that can run before the target, by walking its connectors backwards.
 * @param {Array} elements Every element in the flow
 * @param {String} target The element's API name
 * @returns {Set} The API names of elements that lead to the target; includes the target if it's in a loop
 */
function findSources(elements, target) {
	const sourcesByTarget = new Map();
	elements.forEach((element) => {
		getTargets(element).forEach((next) =>
			sourcesByTarget.set(next, [...(sourcesByTarget.get(next) ?? []), element.name])
		);
	});
	const sources = new Set();
	const queue = [target];
	for (let index = 0; index < queue.length; index++) {
		const unseen = (sourcesByTarget.get(queue[index]) ?? []).filter((source) => !sources.has(source));
		unseen.forEach((source) => sources.add(source));
		queue.push(...unseen);
	}
	return sources;
}

/**
 * @description Finds the elements in a loop's "For Each" path.
 * @param {Map} elementsByName Every element in the flow, by API name
 * @param {Object} loop The loop
 * @returns {Set} The API names of elements that run once per item
 */
function findLoopBody(elementsByName, loop) {
	const body = new Set();
	const queue = [loop.nextValueConnector?.targetReference].filter(Boolean);
	// An index, not shift(), keeps the walk linear in large flows
	for (let index = 0; index < queue.length; index++) {
		const current = queue[index];
		if (current !== loop.name && !body.has(current)) {
			body.add(current);
			const element = elementsByName.get(current) ?? {};
			queue.push(...getTargets(element));
		}
	}
	return body;
}

/**
 * @description Lists the elements an element connects to, through any of its paths.
 * @param {Object} element A flow element
 * @returns {Array} The API names of the connected elements
 */
function getTargets(element) {
	const connectors = [
		element.connector,
		element.defaultConnector,
		element.faultConnector,
		element.nextValueConnector,
		element.noMoreValuesConnector,
		...(element.rules ?? []).map((rule) => rule.connector),
		...(element.scheduledPaths ?? []).map((path) => path.connector),
		...(element.waitEvents ?? []).map((event) => event.connector)
	];
	return connectors.map((connector) => connector?.targetReference).filter(Boolean);
}

/**
 * @description Works out which elements' outputs are available to the element being edited, like Flow Builder: only
 * those that can run before it, and loop items only inside the loop. Unknown elements see everything.
 * @param {Object} builderContext The CPE's builder context
 * @param {String} elementName The API name of the element being edited
 * @returns {Object} `{ isUpstream(name), isInLoop(loop) }`
 */
function initScope(builderContext, elementName) {
	// Every list in the context, so new element types are walked too; resources like variables have no connectors
	const lists = Object.values(builderContext).filter(Array.isArray);
	const elements = [builderContext.start ?? {}, ...lists.flat()];
	const elementsByName = new Map(elements.map((element) => [element.name, element]));
	const isKnown = Boolean(elementName) && elementsByName.has(elementName);
	const sources = isKnown ? findSources(elements, elementName) : null;
	const loopBodies = new Map();
	const getLoopBody = (loop) => {
		if (!loopBodies.has(loop.name)) {
			loopBodies.set(loop.name, findLoopBody(elementsByName, loop));
		}
		return loopBodies.get(loop.name);
	};
	return {
		isInLoop: (loop) => !sources || getLoopBody(loop).has(elementName),
		isUpstream: (name) => !sources || sources.has(name)
	};
}

/**
 * @description Reuses the scope already worked out for this builder context and element, since Flow Builder sends a
 * new builder context whenever the flow changes
 * @param {Object} builderContext The CPE's builder context
 * @param {String} elementName The API name of the element being edited
 * @returns {Object} `{ isUpstream(name), isInLoop(loop) }`
 */
function getScope(builderContext, elementName) {
	const scopes = SCOPES.get(builderContext) ?? new Map();
	if (!scopes.has(elementName)) {
		scopes.set(elementName, initScope(builderContext, elementName));
		SCOPES.set(builderContext, scopes);
	}
	return scopes.get(elementName);
}

/**
 * @description Builds the items for a record-triggered flow's triggering record and, for updates, its prior values.
 * @param {Object} builderContext The CPE's builder context
 * @param {Object} context Supplies the object's label, once known
 * @returns {Array} The `$Record` and `$Record__Prior` items, if the flow has a triggering record
 */
function initTriggerItems(builderContext, context) {
	const start = builderContext.start ?? {};
	const objectLabel = context?.objectLabels?.[start.object]?.label ?? start.object;
	const hasPriorValues = ["CreateAndUpdate", "Update"].includes(start.recordTriggerType);
	const triggers = [
		{ value: "$Record", label: `Triggering ${objectLabel}` },
		{ value: "$Record__Prior", label: `Prior Values of Triggering ${objectLabel}` }
	];
	const count = hasPriorValues ? 2 : 1;
	return (start.object ? triggers.slice(0, count) : []).map((trigger) =>
		initItem({
			...trigger,
			pathLabel: trigger.value,
			dataType: SOBJECT,
			objectType: start.object,
			drillType: DRILL_RECORD
		})
	);
}

/**
 * @description Orders items by data type, then by label, like Flow Builder's field lists.
 * @param {Object} first An item
 * @param {Object} second Another item
 * @returns {Number} The sort order
 */
function compareTypes(first, second) {
	return TYPE_ORDER.indexOf(first.dataType) - TYPE_ORDER.indexOf(second.dataType) || compareLabels(first, second);
}
