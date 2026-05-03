export const DATA_TYPE_STRING = "String";

export function asArray(value) {
	return Array.isArray(value) ? value : [];
}

export function readCollection(builderContext, key) {
	return asArray(builderContext?.[key] ?? builderContext?.resources?.[key] ?? builderContext?.flow?.[key]);
}

export function readName(resource) {
	return resource?.name ?? resource?.apiName ?? resource?.fullName ?? resource?.developerName ?? null;
}

export function readLabel(resource, fallback) {
	return resource?.label ?? resource?.masterLabel ?? resource?.displayName ?? fallback;
}

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

export function normalizeDataType(dataType, objectType) {
	const normalized = String(dataType ?? "")
		.trim()
		.toLowerCase();

	if (objectType || ["sobject", "record", "apex"].includes(normalized)) {
		return "SObject";
	}
	if (["string", "text", "textarea", "picklist", "multipicklist", "id", "email", "phone", "url"].includes(normalized)) {
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
	if (["decimal", "double", "currency", "integer", "int", "long", "number"].includes(normalized)) {
		return "Decimal";
	}
	return dataType ?? null;
}

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

export function toReferenceValue(referenceName) {
	return referenceName ? `{!${referenceName}}` : "";
}

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

export function readFieldName(field) {
	if (typeof field === "string") {
		return field;
	}
	return field?.name ?? field?.apiName ?? field?.fieldApiName ?? field?.qualifiedApiName ?? null;
}

export function readFieldDataType(field) {
	return typeof field === "string" ? null : (field?.dataType ?? field?.valueDataType ?? field?.type);
}

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

export function scoreResourceOption(option) {
	return [
		option?.dataType ? 1 : 0,
		option?.objectType ? 1 : 0,
		option?.category ? 1 : 0,
		option?.parentObjectType ? 1 : 0
	].reduce((sum, value) => sum + value, 0);
}

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
