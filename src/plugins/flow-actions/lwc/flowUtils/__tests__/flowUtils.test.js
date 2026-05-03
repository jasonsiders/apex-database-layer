import {
	DATA_TYPE_STRING,
	RESOURCE_COLLECTIONS,
	asArray,
	readCollection,
	readName,
	readLabel,
	readObjectType,
	normalizeDataType,
	readIsCollection,
	toReferenceValue,
	hasFieldMetadata,
	buildResourceOption,
	readFieldName,
	readFieldDataType,
	readFieldOptions,
	scoreResourceOption,
	readActionOutputOptions,
	dedupeResourceOptions
} from "c/flowUtils";

describe("c-flow-utils", () => {
	describe("normalizeDataType", () => {
		it("returns 'DateTime' for 'datetime' input", () => {
			expect(normalizeDataType("datetime")).toBe("DateTime");
		});

		it("returns 'DateTime' for 'date/time' input", () => {
			expect(normalizeDataType("date/time")).toBe("DateTime");
		});

		it("returns 'Time' for 'time' input", () => {
			expect(normalizeDataType("time")).toBe("Time");
		});

		it("returns 'Boolean' for 'boolean' input", () => {
			expect(normalizeDataType("boolean")).toBe("Boolean");
		});

		it("returns 'Decimal' for 'decimal' input", () => {
			expect(normalizeDataType("decimal")).toBe("Decimal");
		});

		it("returns 'Decimal' for 'double' input", () => {
			expect(normalizeDataType("double")).toBe("Decimal");
		});

		it("returns 'Decimal' for 'currency' input", () => {
			expect(normalizeDataType("currency")).toBe("Decimal");
		});

		it("returns 'Decimal' for 'integer' input", () => {
			expect(normalizeDataType("integer")).toBe("Decimal");
		});

		it("returns 'Decimal' for 'number' input", () => {
			expect(normalizeDataType("number")).toBe("Decimal");
		});

		it("returns 'SObject' when objectType is provided", () => {
			expect(normalizeDataType("String", "Account")).toBe("SObject");
		});

		it("returns 'String' for 'text' input", () => {
			expect(normalizeDataType("text")).toBe("String");
		});

		it("returns original dataType when unknown", () => {
			expect(normalizeDataType("UnknownType")).toBe("UnknownType");
		});
	});

	describe("readIsCollection", () => {
		it("returns true when isCollection is explicitly true", () => {
			expect(readIsCollection({ isCollection: true })).toBe(true);
		});

		it("returns true when isCollection is string 'true'", () => {
			expect(readIsCollection({ isCollection: "true" })).toBe(true);
		});

		it("returns false when isCollection is false", () => {
			expect(readIsCollection({ isCollection: false })).toBe(false);
		});

		it("returns true when getFirstRecordOnly is false", () => {
			expect(readIsCollection({ getFirstRecordOnly: false })).toBe(true);
		});

		it("returns false when getFirstRecordOnly is true", () => {
			expect(readIsCollection({ getFirstRecordOnly: true })).toBe(false);
		});

		it("returns true when dataType ends with []", () => {
			expect(readIsCollection({ dataType: "String[]" })).toBe(true);
		});

		it("returns false for empty object with no default", () => {
			expect(readIsCollection({})).toBe(false);
		});

		it("returns provided defaultValue when no collection indicator", () => {
			expect(readIsCollection({}, true)).toBe(true);
		});
	});

	describe("buildResourceOption", () => {
		it("returns null when resource has no name", () => {
			expect(buildResourceOption({})).toBeNull();
		});

		it("returns null when resource is undefined", () => {
			expect(buildResourceOption(undefined)).toBeNull();
		});

		it("returns null when all name sources are missing", () => {
			expect(buildResourceOption({ label: "Test" })).toBeNull();
		});

		it("builds option with provided referenceName parameter", () => {
			const option = buildResourceOption({ label: "Test" }, { referenceName: "testRef" });
			expect(option.referenceName).toBe("testRef");
			expect(option.value).toBe("{!testRef}");
		});

		it("normalizes dataType and sets valueDataType", () => {
			const option = buildResourceOption({ name: "strVar", dataType: "text" }, { labelPrefix: "Variable" });
			expect(option.dataType).toBe("String");
			expect(option.valueDataType).toBe("String");
		});

		it("marks SObject with fields as drillable", () => {
			const option = buildResourceOption(
				{ name: "acct", dataType: "SObject", fields: [{ name: "Id" }] },
				{ labelPrefix: "Variable" }
			);
			expect(option.isDrillable).toBe(true);
		});

		it("marks SObject without fields as not drillable", () => {
			const option = buildResourceOption({ name: "acct", dataType: "SObject" }, { labelPrefix: "Variable" });
			expect(option.isDrillable).toBe(false);
		});
	});

	describe("readFieldOptions", () => {
		it("returns empty array when resource has no fields", () => {
			const parentOption = {
				referenceName: "account",
				displayLabel: "Account",
				objectType: "Account"
			};
			const options = readFieldOptions({ fields: [] }, parentOption);
			expect(options).toEqual([]);
		});

		it("filters out fields with no name", () => {
			const parentOption = {
				referenceName: "account",
				displayLabel: "Account",
				objectType: "Account"
			};
			const resource = {
				fields: [
					{ name: "Id", dataType: "id" },
					{ dataType: "String" }, // No name
					{ name: "Name", dataType: "String" }
				]
			};
			const options = readFieldOptions(resource, parentOption);
			expect(options).toHaveLength(2);
			expect(options[0].referenceName).toBe("account.Id");
			expect(options[1].referenceName).toBe("account.Name");
		});

		it("builds field options with correct labels and references", () => {
			const parentOption = {
				referenceName: "account",
				displayLabel: "Account",
				objectType: "Account"
			};
			const resource = {
				fields: [{ name: "Name", dataType: "String", label: "Account Name" }]
			};
			const options = readFieldOptions(resource, parentOption);
			expect(options[0].label).toBe("Field: Account.Account Name");
			expect(options[0].referenceName).toBe("account.Name");
			expect(options[0].parentReferenceName).toBe("account");
			expect(options[0].category).toBe("recordFields");
		});
	});

	describe("scoreResourceOption", () => {
		it("returns 0 for option with no attributes", () => {
			expect(scoreResourceOption({})).toBe(0);
		});

		it("returns 1 when only dataType is present", () => {
			expect(scoreResourceOption({ dataType: "String" })).toBe(1);
		});

		it("returns 2 when dataType and objectType are present", () => {
			expect(scoreResourceOption({ dataType: "SObject", objectType: "Account" })).toBe(2);
		});

		it("returns 3 when dataType, objectType, and category are present", () => {
			expect(
				scoreResourceOption({
					dataType: "SObject",
					objectType: "Account",
					category: "recordVariables"
				})
			).toBe(3);
		});

		it("returns 4 when all attributes are present", () => {
			expect(
				scoreResourceOption({
					dataType: "SObject",
					objectType: "Account",
					category: "recordVariables",
					parentObjectType: "Contact"
				})
			).toBe(4);
		});
	});

	describe("dedupeResourceOptions", () => {
		it("returns empty array for empty input", () => {
			expect(dedupeResourceOptions([])).toEqual([]);
		});

		it("removes duplicates by referenceName, keeping first occurrence", () => {
			const options = [
				{ referenceName: "var1", dataType: "String" },
				{ referenceName: "var1", dataType: "String" }, // duplicate
				{ referenceName: "var2", dataType: "String" }
			];
			const result = dedupeResourceOptions(options);
			expect(result).toHaveLength(2);
			expect(result[0].referenceName).toBe("var1");
			expect(result[1].referenceName).toBe("var2");
		});

		it("replaces option with lower score when duplicate has higher score", () => {
			const options = [
				{ referenceName: "var1", dataType: "String" }, // score 1
				{
					referenceName: "var1",
					dataType: "String",
					objectType: "Account",
					category: "recordVariables"
				} // score 3
			];
			const result = dedupeResourceOptions(options);
			expect(result).toHaveLength(1);
			expect(result[0].objectType).toBe("Account");
			expect(result[0].category).toBe("recordVariables");
		});

		it("keeps first option when scores are equal", () => {
			const options = [
				{ referenceName: "var1", dataType: "String", objectType: "Account" },
				{ referenceName: "var1", dataType: "String", objectType: "Contact" }
			];
			const result = dedupeResourceOptions(options);
			expect(result[0].objectType).toBe("Account");
		});

		it("skips options with no referenceName or value", () => {
			const options = [
				{ dataType: "String" }, // no key
				{ referenceName: "var1", dataType: "String" },
				{ value: "literal", dataType: "String" }
			];
			const result = dedupeResourceOptions(options);
			expect(result).toHaveLength(2);
		});

		it("uses value as key when referenceName is not present", () => {
			const options = [
				{ value: "val1", dataType: "String" },
				{ value: "val1", dataType: "String", objectType: "Account" }
			];
			const result = dedupeResourceOptions(options);
			expect(result).toHaveLength(1);
			expect(result[0].objectType).toBe("Account");
		});
	});

	describe("toReferenceValue", () => {
		it("wraps referenceName in {! }}", () => {
			expect(toReferenceValue("myVar")).toBe("{!myVar}");
		});

		it("returns empty string for null referenceName", () => {
			expect(toReferenceValue(null)).toBe("");
		});

		it("returns empty string for undefined referenceName", () => {
			expect(toReferenceValue(undefined)).toBe("");
		});

		it("returns empty string for empty string referenceName", () => {
			expect(toReferenceValue("")).toBe("");
		});
	});

	describe("readName", () => {
		it("returns name property when present", () => {
			expect(readName({ name: "test" })).toBe("test");
		});

		it("falls back to apiName", () => {
			expect(readName({ apiName: "test" })).toBe("test");
		});

		it("falls back to fullName", () => {
			expect(readName({ fullName: "test" })).toBe("test");
		});

		it("falls back to developerName", () => {
			expect(readName({ developerName: "test" })).toBe("test");
		});

		it("returns null when no name source present", () => {
			expect(readName({})).toBeNull();
		});
	});

	describe("readLabel", () => {
		it("returns label when present", () => {
			expect(readLabel({ label: "Test Label" })).toBe("Test Label");
		});

		it("falls back to masterLabel", () => {
			expect(readLabel({ masterLabel: "Master" })).toBe("Master");
		});

		it("falls back to displayName", () => {
			expect(readLabel({ displayName: "Display" })).toBe("Display");
		});

		it("returns fallback value when no label source present", () => {
			expect(readLabel({}, "Default")).toBe("Default");
		});
	});

	describe("readObjectType", () => {
		it("returns objectType when present", () => {
			expect(readObjectType({ objectType: "Account" })).toBe("Account");
		});

		it("falls back to sobjectType", () => {
			expect(readObjectType({ sobjectType: "Account" })).toBe("Account");
		});

		it("falls back to sObjectType", () => {
			expect(readObjectType({ sObjectType: "Account" })).toBe("Account");
		});

		it("returns null for non-string objectType", () => {
			expect(readObjectType({ objectType: {} })).toBeNull();
		});

		it("returns null when no objectType present", () => {
			expect(readObjectType({})).toBeNull();
		});
	});

	describe("readFieldName", () => {
		it("returns string directly when field is a string", () => {
			expect(readFieldName("fieldName")).toBe("fieldName");
		});

		it("returns name property when field is object", () => {
			expect(readFieldName({ name: "test" })).toBe("test");
		});

		it("falls back to apiName", () => {
			expect(readFieldName({ apiName: "test" })).toBe("test");
		});

		it("returns null when no name source present", () => {
			expect(readFieldName({})).toBeNull();
		});
	});

	describe("readFieldDataType", () => {
		it("returns null when field is a string", () => {
			expect(readFieldDataType("fieldName")).toBeNull();
		});

		it("returns dataType property when field is object", () => {
			expect(readFieldDataType({ dataType: "String" })).toBe("String");
		});

		it("falls back to valueDataType", () => {
			expect(readFieldDataType({ valueDataType: "Decimal" })).toBe("Decimal");
		});

		it("returns undefined when field is object but has no type", () => {
			expect(readFieldDataType({ name: "test" })).toBeUndefined();
		});
	});

	describe("hasFieldMetadata", () => {
		it("returns true when resource has fields array", () => {
			expect(hasFieldMetadata({ fields: [{ name: "Id" }] })).toBe(true);
		});

		it("returns true when resource has fieldDefinitions array", () => {
			expect(hasFieldMetadata({ fieldDefinitions: [{ name: "Id" }] })).toBe(true);
		});

		it("returns true when resource has objectInfo.fields", () => {
			expect(
				hasFieldMetadata({
					objectInfo: { fields: { Id: { name: "Id" }, Name: { name: "Name" } } }
				})
			).toBe(true);
		});

		it("returns false when resource has no field metadata", () => {
			expect(hasFieldMetadata({})).toBe(false);
		});

		it("returns false when fields array is empty", () => {
			expect(hasFieldMetadata({ fields: [] })).toBe(false);
		});
	});

	describe("asArray", () => {
		it("returns array when value is array", () => {
			expect(asArray([1, 2, 3])).toEqual([1, 2, 3]);
		});

		it("returns empty array when value is not array", () => {
			expect(asArray("string")).toEqual([]);
			expect(asArray(null)).toEqual([]);
			expect(asArray(undefined)).toEqual([]);
		});
	});

	describe("readCollection", () => {
		it("reads collection from builderContext directly", () => {
			const builderContext = { variables: [{ name: "var1" }] };
			expect(readCollection(builderContext, "variables")).toEqual([{ name: "var1" }]);
		});

		it("reads collection from builderContext.resources", () => {
			const builderContext = { resources: { variables: [{ name: "var1" }] } };
			expect(readCollection(builderContext, "variables")).toEqual([{ name: "var1" }]);
		});

		it("reads collection from builderContext.flow", () => {
			const builderContext = { flow: { variables: [{ name: "var1" }] } };
			expect(readCollection(builderContext, "variables")).toEqual([{ name: "var1" }]);
		});

		it("returns empty array when collection not found", () => {
			expect(readCollection({}, "variables")).toEqual([]);
		});

		it("returns empty array for null builderContext", () => {
			expect(readCollection(null, "variables")).toEqual([]);
		});
	});

	describe("readActionOutputOptions", () => {
		it("returns empty array when action has no name", () => {
			expect(readActionOutputOptions({})).toEqual([]);
		});

		it("returns empty array when action has no outputs", () => {
			expect(readActionOutputOptions({ name: "myAction" })).toEqual([]);
		});

		it("builds options from action outputParameters", () => {
			const action = {
				name: "myAction",
				outputParameters: [{ name: "result", dataType: "String" }]
			};
			const options = readActionOutputOptions(action);
			expect(options).toHaveLength(1);
			expect(options[0].referenceName).toBe("myAction.result");
			expect(options[0].category).toBe("actionOutputs");
			expect(options[0].label).toBe("Action Output: myAction.result");
		});

		it("filters out outputs without names", () => {
			const action = {
				name: "myAction",
				outputParameters: [
					{ name: "result", dataType: "String" },
					{ dataType: "String" } // no name
				]
			};
			const options = readActionOutputOptions(action);
			expect(options).toHaveLength(1);
		});
	});

	describe("RESOURCE_COLLECTIONS", () => {
		it("exports array with expected keys", () => {
			const keys = RESOURCE_COLLECTIONS.map((rc) => rc.key);
			expect(keys).toContain("variables");
			expect(keys).toContain("recordVariables");
			expect(keys).toContain("recordCollections");
			expect(keys).toContain("constants");
			expect(keys).toContain("formulas");
			expect(keys).toContain("recordLookups");
			expect(keys).toContain("recordCreates");
			expect(keys).toContain("recordUpdates");
		});
	});

	describe("DATA_TYPE_STRING", () => {
		it("exports 'String' constant", () => {
			expect(DATA_TYPE_STRING).toBe("String");
		});
	});
});
