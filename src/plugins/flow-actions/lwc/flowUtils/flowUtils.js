/** Standard Flow data type string constant. */
export const DATA_TYPE_STRING = "String";

/** Defines the structure and order of resource collections available in Flow Builder. */
export const RESOURCE_COLLECTIONS = [
	{ key: "variables", labelPrefix: "Variable" },
	{ key: "recordVariables", category: "recordVariables", labelPrefix: "Variable", dataType: "SObject" },
	{
		key: "recordCollections",
		category: "recordCollections",
		labelPrefix: "Variable",
		dataType: "SObject",
		isCollection: true
	},
	{ key: "constants", category: "constants", labelPrefix: "Constant" },
	{ key: "formulas", category: "formulas", labelPrefix: "Formula" },
	{ key: "recordLookups", labelPrefix: "Record" },
	{ key: "recordCreates", labelPrefix: "Record" },
	{ key: "recordUpdates", labelPrefix: "Record" }
];

/**
 * Ensures value is an array. Returns the value if already an array, otherwise returns empty array.
 * @param {*} value - The value to normalize to array form
 * @returns {Array} The value as an array, or empty array if value is not an array
 */
export function asArray(value) {
	return Array.isArray(value) ? value : [];
}

/**
 * Reads a resource collection from builder context, checking multiple possible locations.
 * @param {Object} builderContext - The Flow Builder context object
 * @param {string} key - The collection key to read (e.g., 'variables', 'recordVariables')
 * @returns {Array} The resource collection, or empty array if not found
 */
export function readCollection(builderContext, key) {
	return asArray(builderContext?.[key] ?? builderContext?.resources?.[key] ?? builderContext?.flow?.[key]);
}

/**
 * Extracts the name from a resource, checking multiple possible name properties.
 * @param {Object} resource - The resource object
 * @returns {string|null} The resource name, or null if not found
 */
export function readName(resource) {
	return resource?.name ?? resource?.apiName ?? resource?.fullName ?? resource?.developerName ?? null;
}

/**
 * Extracts a display label from a resource, checking multiple possible label properties.
 * @param {Object} resource - The resource object
 * @param {string} fallback - Fallback value if no label is found
 * @returns {string} The resource label, or fallback value
 */
export function readLabel(resource, fallback) {
	return resource?.label ?? resource?.masterLabel ?? resource?.displayName ?? fallback;
}

/**
 * Extracts the SObject type from a resource, checking multiple possible type properties.
 * @param {Object} resource - The resource object
 * @returns {string|null} The SObject type name, or null if not found or not a string
 */
export function readObjectType(resource) {
	const objectType =
		resource?.objectType ??
		resource?.objectTypeName ??
		resource?.sobjectType ??
		resource?.sObjectType ??
		resource?.objectApiName ??
		resource?.entityName ??
		resource?.object ??
		resource?.typeValue ??
		null;
	return typeof objectType === "string" ? objectType : null;
}

/**
 * Normalizes a raw data type string to a canonical Flow data type.
 * Maps various vendor and format variations to standard Flow types.
 * @param {string} dataType - The raw data type to normalize
 * @param {string} [objectType] - Optional SObject type; presence indicates SObject data type
 * @returns {string|null} Normalized data type (SObject, String, DateTime, Date, Time, Boolean, Decimal), or original value if no match
 */
export function normalizeDataType(dataType, objectType) {
	const normalized = String(dataType ?? "")
		.trim()
		.toLowerCase();

	if (objectType || ["sobject", "record", "apex"].includes(normalized)) {
		return "SObject";
	}
	if (
		["string", "text", "textarea", "picklist", "multipicklist", "id", "email", "phone", "url"].includes(normalized)
	) {
		return "String";
	}
	if (["datetime", "date/time"].includes(normalized)) {
		return "DateTime";
	}
	if (normalized === "date") {
		return "Date";
	}
	if (normalized === "time") {
		return "Time";
	}
	if (normalized === "boolean") {
		return "Boolean";
	}
	if (["decimal", "double", "currency", "integer", "int", "long", "number", "percent"].includes(normalized)) {
		return "Decimal";
	}
	return dataType ?? null;
}

/**
 * Determines whether a resource represents a collection, checking multiple possible properties.
 * @param {Object} resource - The resource object
 * @param {boolean} [defaultValue=false] - Default value if no collection indicator is found
 * @returns {boolean} Whether the resource is a collection
 */
export function readIsCollection(resource, defaultValue = false) {
	if (resource?.isCollection !== undefined) {
		return resource.isCollection === true || resource.isCollection === "true";
	}
	if (resource?.getFirstRecordOnly !== undefined) {
		return resource.getFirstRecordOnly !== true && resource.getFirstRecordOnly !== "true";
	}
	if (String(resource?.dataType ?? "").endsWith("[]")) {
		return true;
	}
	return defaultValue;
}

/**
 * Wraps a reference name in Flow reference syntax.
 * @param {string} referenceName - The name to wrap as a reference
 * @returns {string} Flow reference syntax {!name}, or empty string if name is falsy
 */
export function toReferenceValue(referenceName) {
	return referenceName ? `{!${referenceName}}` : "";
}

/**
 * Checks whether a resource has field metadata that can be drilled into.
 * @param {Object} resource - The resource object
 * @returns {boolean} True if the resource has accessible field information
 */
export function hasFieldMetadata(resource) {
	return [
		resource?.fields,
		resource?.fieldDefinitions,
		resource?.properties,
		resource?.queriedFields,
		resource?.fieldNames,
		resource?.objectInfo?.fields ? Object.values(resource.objectInfo.fields) : null
	].some((source) => Array.isArray(source) && source.length > 0);
}

/**
 * Builds a standardized option object from a Flow resource for use in selectors and dropdowns.
 * Extracts and normalizes metadata into a consistent format.
 * @param {Object} resource - The Flow resource to convert
 * @param {Object} [options={}] - Configuration overrides
 * @param {string} [options.category] - Resource category label
 * @param {string} [options.labelPrefix] - Prefix for the option label
 * @param {string} [options.referenceName] - Override for the reference name
 * @param {string} [options.dataType] - Default data type if resource doesn't specify one
 * @param {boolean} [options.isCollection] - Default collection flag if resource doesn't specify one
 * @returns {Object|null} Standardized option object with label, value, dataType, etc., or null if resource lacks a name
 */
export function buildResourceOption(
	resource,
	{ category, labelPrefix, referenceName, dataType: defaultDataType, isCollection } = {}
) {
	const name = referenceName ?? resource?.referenceName ?? readName(resource);
	if (!name) {
		return null;
	}

	const objectType = readObjectType(resource);
	const rawDataType = resource?.dataType ?? resource?.valueDataType ?? resource?.type ?? defaultDataType;
	const hasFields = hasFieldMetadata(resource);
	const dataType = normalizeDataType(rawDataType, objectType || hasFields) ?? DATA_TYPE_STRING;
	const displayLabel = readLabel(resource, name);
	const label = resource?.label ?? (labelPrefix ? `${labelPrefix}: ${displayLabel}` : displayLabel);

	return {
		label,
		value: resource?.value ?? toReferenceValue(name),
		pillLabel: resource?.pillLabel ?? name,
		referenceName: name,
		displayLabel,
		dataType,
		valueDataType: dataType,
		objectType,
		isDrillable: dataType === "SObject" && hasFields,
		isCollection: readIsCollection(resource, isCollection === true),
		category: resource?.category ?? category
	};
}

/**
 * Extracts the field name from a field object or string.
 * @param {Object|string} field - The field to extract name from
 * @returns {string|null} The field name, or null if not found
 */
export function readFieldName(field) {
	if (typeof field === "string") {
		return field;
	}
	return field?.name ?? field?.apiName ?? field?.fieldApiName ?? field?.qualifiedApiName ?? null;
}

/**
 * Extracts the data type from a field object.
 * @param {Object|string} field - The field to extract data type from
 * @returns {string|null} The field's data type, or null if field is a string or data type not found
 */
export function readFieldDataType(field) {
	return typeof field === "string" ? null : (field?.dataType ?? field?.valueDataType ?? field?.type);
}

/**
 * Builds standardized option objects for all fields within a parent resource.
 * Used for drilling down into SObject types to select individual fields.
 * @param {Object} resource - The parent resource containing fields
 * @param {Object} parentOption - The parent option object (provides referenceName, displayLabel, objectType)
 * @returns {Array} Array of field option objects, one per field in the resource
 */
export function readFieldOptions(resource, parentOption) {
	const fieldSources = [
		resource?.fields,
		resource?.fieldDefinitions,
		resource?.properties,
		resource?.queriedFields,
		resource?.fieldNames,
		resource?.objectInfo?.fields ? Object.values(resource.objectInfo.fields) : null
	];
	const fields = fieldSources.find((source) => Array.isArray(source)) ?? [];

	return fields
		.map((field) => {
			const fieldName = readFieldName(field);
			if (!fieldName) {
				return null;
			}

			const referenceName = `${parentOption.referenceName}.${fieldName}`;
			const displayLabel = `${parentOption.displayLabel}.${readLabel(field, fieldName)}`;
			const dataType = normalizeDataType(readFieldDataType(field));
			return {
				label: `Field: ${displayLabel}`,
				value: toReferenceValue(referenceName),
				pillLabel: referenceName,
				referenceName,
				displayLabel,
				dataType,
				valueDataType: dataType,
				objectType: null,
				parentObjectType: parentOption.objectType,
				parentReferenceName: parentOption.referenceName,
				isCollection: readIsCollection(field),
				category: "recordFields"
			};
		})
		.filter(Boolean);
}

/**
 * Scores a resource option for metadata completeness.
 * Used by deduplication logic to prefer options with more metadata when merging duplicates.
 * @param {Object} option - The option to score
 * @returns {number} Score from 0-4 based on number of metadata properties present
 */
export function scoreResourceOption(option) {
	return [
		option?.dataType ? 1 : 0,
		option?.objectType ? 1 : 0,
		option?.category ? 1 : 0,
		option?.parentObjectType ? 1 : 0
	].reduce((sum, value) => sum + value, 0);
}

/**
 * Builds standardized option objects for all output parameters of a Flow action.
 * @param {Object} action - The Flow action containing output parameters
 * @returns {Array} Array of action output option objects, empty if action has no name or outputs
 */
export function readActionOutputOptions(action) {
	const actionName = readName(action);
	if (!actionName) {
		return [];
	}

	const outputs = asArray(action?.outputParameters ?? action?.outputVariables ?? action?.outputs);
	return outputs
		.map((output) => {
			const outputName = readName(output);
			if (!outputName) {
				return null;
			}

			return buildResourceOption(output, {
				category: "actionOutputs",
				labelPrefix: "Action Output",
				referenceName: `${actionName}.${outputName}`
			});
		})
		.filter(Boolean);
}

/**
 * Deduplicates resource options by reference name or value, keeping the option with the best metadata.
 * When duplicates are found, the version with the higher score (more metadata) is retained.
 * @param {Array} options - Array of option objects to deduplicate
 * @returns {Array} Deduplicated array with the highest-scoring option for each unique reference
 */
export function dedupeResourceOptions(options) {
	const indexesByKey = new Map();
	const result = [];

	for (const option of options) {
		const key = option?.referenceName ?? option?.value;
		if (!key) {
			continue;
		}

		if (!indexesByKey.has(key)) {
			indexesByKey.set(key, result.length);
			result.push(option);
			continue;
		}

		const existingIndex = indexesByKey.get(key);
		if (scoreResourceOption(option) > scoreResourceOption(result[existingIndex])) {
			result[existingIndex] = option;
		}
	}

	return result;
}

/**
 * Builds a standardized option object for a global Flow constant or variable.
 * @private
 * @param {Object} params - Configuration object
 * @param {string} params.referenceName - The global reference name (e.g., $GlobalConstant.True)
 * @param {string} params.displayLabel - Display label for the option
 * @param {string} params.dataType - The data type of the constant/variable
 * @param {string} [params.objectType] - Optional SObject type if applicable
 * @param {string} [params.parentReferenceName] - Optional parent reference if this is a child property
 * @param {boolean} [params.isDrillable=false] - Whether the option can be drilled into to select child properties
 * @param {string} [params.iconName] - Optional icon name for UI display
 * @returns {Object} Standardized option object for the global resource
 */
function buildStandardResourceOption({
	referenceName,
	displayLabel,
	dataType,
	objectType,
	parentReferenceName,
	isDrillable = false,
	iconName
}) {
	const category = referenceName.startsWith("$GlobalConstant.") ? "globalConstants" : "globalVariables";
	const labelPrefix = category === "globalConstants" ? "Global Constant" : "Global Variable";
	return {
		label: `${labelPrefix}: ${displayLabel}`,
		value: toReferenceValue(referenceName),
		pillLabel: referenceName,
		referenceName,
		displayLabel,
		dataType,
		valueDataType: dataType,
		objectType,
		parentReferenceName,
		isCollection: false,
		isDrillable,
		iconName,
		category
	};
}

/**
 * Pre-built option objects for Flow's global constants, variables, and system values.
 * Includes $GlobalConstant values (True, False, EmptyString), $Api, $Flow, $Organization, $User, $Profile, $UserRole, and $System.
 * These are automatically available in any Flow and can be used without being explicitly defined.
 */
export const STANDARD_RESOURCE_OPTIONS = [
	buildStandardResourceOption({ referenceName: "$GlobalConstant.False", displayLabel: "False", dataType: "Boolean" }),
	buildStandardResourceOption({ referenceName: "$GlobalConstant.True", displayLabel: "True", dataType: "Boolean" }),
	buildStandardResourceOption({
		referenceName: "$GlobalConstant.EmptyString",
		displayLabel: "Blank Value (Empty String)",
		dataType: "String"
	}),
	buildStandardResourceOption({
		referenceName: "$Api",
		displayLabel: "API",
		dataType: "SObject",
		isDrillable: true,
		iconName: "utility:world"
	}),
	buildStandardResourceOption({
		referenceName: "$Api.Session_ID",
		displayLabel: "Session ID",
		dataType: "String",
		parentReferenceName: "$Api"
	}),
	buildStandardResourceOption({
		referenceName: "$Flow",
		displayLabel: "Running Flow Interview",
		dataType: "SObject",
		isDrillable: true,
		iconName: "utility:flow"
	}),
	buildStandardResourceOption({
		referenceName: "$Flow.FaultMessage",
		displayLabel: "Fault Message",
		dataType: "String",
		parentReferenceName: "$Flow"
	}),
	buildStandardResourceOption({
		referenceName: "$Flow.CurrentDate",
		displayLabel: "Current Date",
		dataType: "Date",
		parentReferenceName: "$Flow"
	}),
	buildStandardResourceOption({
		referenceName: "$Flow.CurrentDateTime",
		displayLabel: "Current Date/Time",
		dataType: "DateTime",
		parentReferenceName: "$Flow"
	}),
	buildStandardResourceOption({
		referenceName: "$Flow.InterviewStartTime",
		displayLabel: "Interview Start Time",
		dataType: "DateTime",
		parentReferenceName: "$Flow"
	}),
	buildStandardResourceOption({
		referenceName: "$Organization",
		displayLabel: "Running Org",
		dataType: "SObject",
		objectType: "Organization",
		isDrillable: true,
		iconName: "utility:company"
	}),
	buildStandardResourceOption({
		referenceName: "$User",
		displayLabel: "Running User",
		dataType: "SObject",
		objectType: "User",
		isDrillable: true,
		iconName: "utility:user"
	}),
	buildStandardResourceOption({
		referenceName: "$Profile",
		displayLabel: "Running User Profile",
		dataType: "SObject",
		objectType: "Profile",
		isDrillable: true,
		iconName: "utility:user"
	}),
	buildStandardResourceOption({
		referenceName: "$UserRole",
		displayLabel: "Running User Role",
		dataType: "SObject",
		objectType: "UserRole",
		isDrillable: true,
		iconName: "utility:user"
	}),
	buildStandardResourceOption({
		referenceName: "$System",
		displayLabel: "System",
		dataType: "SObject",
		isDrillable: true,
		iconName: "utility:world"
	}),
	buildStandardResourceOption({
		referenceName: "$System.OriginDateTime",
		displayLabel: "Origin Date/Time",
		dataType: "DateTime",
		parentReferenceName: "$System"
	})
];
