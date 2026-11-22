import { createElement } from "lwc";
import { readFileSync } from "fs";
import path from "path";
import SoqlQueryEditor from "c/soqlQueryEditor";
import getObjects from "@salesforce/apex/InvocableSoql.getObjects";
import getFields from "@salesforce/apex/InvocableSoql.getFields";
import CONTEXT from "../../flowResourceMenu/__tests__/data/context.json";
import FIELDS from "../../soqlFieldPath/__tests__/data/fields.json";

jest.mock(
	"@salesforce/apex/InvocableSoql.getObjects",
	() => {
		const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
		return { default: createApexTestWireAdapter(jest.fn()) };
	},
	{ virtual: true }
);
jest.mock("@salesforce/apex/InvocableSoql.getFields", () => ({ default: jest.fn() }), { virtual: true });

const OBJECTS = [
	{ apiName: "Contact", label: "Contact" },
	{ apiName: "Account", label: "Account" }
];

async function flush() {
	for (let i = 0; i < 5; i++) {
		// eslint-disable-next-line no-await-in-loop, @lwc/lwc/no-async-operation
		await new Promise((resolve) => setTimeout(resolve, 0));
	}
}

async function render(definition, inputs = []) {
	const element = createElement("c-soql-query-editor", { is: SoqlQueryEditor });
	const saved = definition
		? [{ name: "queryDefinition", value: JSON.stringify(definition), valueDataType: "String" }]
		: [];
	Object.assign(element, {
		elementInfo: { apiName: "Get_Contacts", type: "Action", actionName: "InvocableSoql" },
		inputVariables: [...saved, ...inputs],
		builderContext: CONTEXT.builderContext,
		automaticOutputVariables: CONTEXT.automaticOutputVariables,
		genericTypeMappings: []
	});
	const events = [];
	const listener = (event) => events.push({ type: event.type, detail: event.detail });
	[
		"configuration_editor_input_value_changed",
		"configuration_editor_input_value_deleted",
		"configuration_editor_generic_type_mapping_changed"
	].forEach((type) => element.addEventListener(type, listener));
	document.body.appendChild(element);
	getObjects.emit(OBJECTS);
	await flush();
	return { element, events };
}

function savedDefinition(events) {
	const saves = events.filter(
		(event) => event.type === "configuration_editor_input_value_changed" && event.detail.name === "queryDefinition"
	);
	return JSON.parse(saves.at(-1).detail.newValue);
}

function rows(element, name) {
	return [...element.shadowRoot.querySelectorAll(`[data-name="${name}"]`)];
}

function valuePicker(element, index) {
	return rows(element, "condition")[index].querySelector('[data-role="value"]');
}

async function fire(target, detail) {
	target.dispatchEvent(new CustomEvent("change", { detail }));
	await flush();
}

async function pickField(element, index, value) {
	const fieldPath = rows(element, "condition")[index].querySelector("c-soql-field-path");
	const objectApiName = "Contact";
	const field = value.includes(".")
		? FIELDS.Account.find((candidate) => candidate.apiName === value.split(".")[1])
		: FIELDS[objectApiName].find((candidate) => candidate.apiName === value);
	await fire(fieldPath, { value, field });
}

function withCondition(condition) {
	return { objectApiName: "Contact", fields: [], conditions: [condition], orderBy: [] };
}

describe("c-soql-query-editor", () => {
	beforeEach(() => {
		getFields.mockImplementation(({ objectApiName }) => Promise.resolve(FIELDS[objectApiName] ?? []));
	});

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
		jest.clearAllMocks();
	});

	it("offers the objects by label, and only the object picker until one is chosen", async () => {
		const { element } = await render();

		const picker = element.shadowRoot.querySelector('c-flow-resource-picker[data-name="objectApiName"]');
		expect(picker.picklistValues.map((option) => option.value)).toEqual(["Account", "Contact"]);
		expect(element.shadowRoot.querySelectorAll("c-soql-field-path")).toHaveLength(0);
	});

	it("starts the query when an object is chosen, typing the outputs and record slots to it", async () => {
		const { element, events } = await render();

		const picker = element.shadowRoot.querySelector('c-flow-resource-picker[data-name="objectApiName"]');
		await fire(picker, { value: "Contact", valueDataType: "String" });

		expect(savedDefinition(events)).toEqual({ conditions: [], fields: [], orderBy: [], objectApiName: "Contact" });
		const mappings = events.filter((event) => event.type === "configuration_editor_generic_type_mapping_changed");
		expect(mappings.map((event) => event.detail.typeName)).toEqual([
			"U__record",
			"U__records",
			...Array.from({ length: 10 }, (_, index) => `T__recordCollection${index + 1}`)
		]);
		expect(mappings.every((event) => event.detail.typeValue === "Contact")).toBe(true);
	});

	it("starts over when the object changes, releasing slots", async () => {
		// The old object's logic and options go too:
		const definition = {
			...withCondition({ field: "LastName", operator: "EQUALS", slot: "text1" }),
			conditionLogic: "1",
			rowLimit: 5
		};
		const { element, events } = await render(definition, [
			{ name: "text1", value: "textVar", valueDataType: "reference" }
		]);

		const picker = element.shadowRoot.querySelector('c-flow-resource-picker[data-name="objectApiName"]');
		await fire(picker, { value: "Account", valueDataType: "String" });

		expect(events).toContainEqual({ type: "configuration_editor_input_value_deleted", detail: { name: "text1" } });
		expect(savedDefinition(events)).toEqual({ conditions: [], fields: [], orderBy: [], objectApiName: "Account" });
	});

	it("adds a condition, defaulting its operator to the field's first", async () => {
		const { element, events } = await render(withCondition({ field: null, operator: null }));

		await pickField(element, 0, "LastName");

		expect(savedDefinition(events).conditions).toEqual([{ field: "LastName", operator: "EQUALS" }]);
		const operator = rows(element, "condition")[0].querySelector('[data-role="operator"]');
		expect(operator.options.map((option) => option.value)).toEqual([
			"EQUALS",
			"NOT_EQUALS",
			"CONTAINS",
			"STARTS_WITH",
			"ENDS_WITH",
			"LIKE",
			"IN",
			"NOT_IN",
			"IS_NULL",
			"IS_NOT_NULL"
		]);
	});

	it("saves a resource to the first free slot of its type, and a literal in the definition", async () => {
		const { element, events } = await render({
			objectApiName: "Contact",
			fields: [],
			conditions: [
				{ field: "LastName", operator: "EQUALS" },
				{ field: "LeadSource", operator: "EQUALS" }
			],
			orderBy: []
		});

		await fire(valuePicker(element, 0), { value: "textVar", valueDataType: "reference" });
		await fire(valuePicker(element, 1), { value: "Account.Name", valueDataType: "reference" });

		expect(events).toContainEqual({
			type: "configuration_editor_input_value_changed",
			detail: { name: "text2", newValue: "Account.Name", newValueDataType: "reference" }
		});
		expect(savedDefinition(events).conditions).toEqual([
			{ field: "LastName", operator: "EQUALS", slot: "text1" },
			{ field: "LeadSource", operator: "EQUALS", slot: "text2" }
		]);
		// Picklist fields offer their values:
		expect(valuePicker(element, 1).picklistValues.map((option) => option.value)).toEqual(["Web", "Phone Inquiry"]);

		await fire(valuePicker(element, 0), { value: "Smith", valueDataType: "String" });

		expect(events).toContainEqual({ type: "configuration_editor_input_value_deleted", detail: { name: "text1" } });
		expect(savedDefinition(events).conditions[0]).toEqual({
			field: "LastName",
			operator: "EQUALS",
			value: "Smith"
		});
	});

	it("saves a record collection for an ID field's IN, typing its slot to the collection's object", async () => {
		const { element, events } = await render(withCondition({ field: "AccountId", operator: "IN" }));

		const picker = valuePicker(element, 0);
		// AccountId holds Account IDs, so only Account collections can match:
		expect(picker).toMatchObject({
			type: "String",
			isCollection: true,
			acceptsRecords: true,
			objectType: "Account"
		});
		await fire(picker, {
			value: "accountsVar",
			valueDataType: "reference",
			objectType: "Account",
			isCollection: true
		});

		expect(savedDefinition(events).conditions[0]).toEqual({
			field: "AccountId",
			operator: "IN",
			slot: "recordCollection1"
		});
		expect(events).toContainEqual({
			type: "configuration_editor_generic_type_mapping_changed",
			detail: { typeName: "T__recordCollection1", typeValue: "Account" }
		});
	});

	it("restricts a parent ID's record collections to the parent's object", async () => {
		const { element } = await render(withCondition({ field: "Account.Id", operator: "IN" }));

		expect(valuePicker(element, 0)).toMatchObject({ acceptsRecords: true, objectType: "Account" });
	});

	it("saves typed collections to collection slots of their type", async () => {
		const { element, events } = await render(withCondition({ field: "Birthdate", operator: "IN" }));

		await fire(valuePicker(element, 0), { value: "datesVar", valueDataType: "reference" });

		expect(savedDefinition(events).conditions[0].slot).toBe("dateCollection1");
	});

	it("saves date literals, boolean constants, and multi-select values in the definition", async () => {
		const { element, events } = await render({
			objectApiName: "Contact",
			fields: [],
			conditions: [
				{ field: "Birthdate", operator: "EQUALS" },
				{ field: "DoNotCall", operator: "EQUALS" },
				{ field: "Interests__c", operator: "INCLUDES" }
			],
			orderBy: []
		});
		expect(valuePicker(element, 0)).toMatchObject({ type: "Date", allowsDateLiterals: true });
		expect(valuePicker(element, 0).picklistValues[0].value).toBe("TODAY");
		expect(valuePicker(element, 2)).toMatchObject({ isPicklistOnly: true });

		await fire(valuePicker(element, 0), { value: "LAST_N_DAYS:30", valueDataType: "Date" });
		await fire(valuePicker(element, 1), { value: "$GlobalConstant.True", valueDataType: "Boolean" });
		await fire(valuePicker(element, 2), { value: "Golf", valueDataType: "String" });

		expect(savedDefinition(events).conditions).toEqual([
			{ field: "Birthdate", operator: "EQUALS", dateLiteral: "LAST_N_DAYS:30" },
			{ field: "DoNotCall", operator: "EQUALS", value: "true" },
			{ field: "Interests__c", operator: "INCLUDES", values: ["Golf"] }
		]);
	});

	it("clears a value that doesn't suit a new operator, and keeps one that does", async () => {
		const { element, events } = await render(
			withCondition({ field: "LastName", operator: "EQUALS", slot: "text1" }),
			[{ name: "text1", value: "textVar", valueDataType: "reference" }]
		);
		const operator = () => rows(element, "condition")[0].querySelector('[data-role="operator"]');

		await fire(operator(), { value: "CONTAINS" });
		expect(savedDefinition(events).conditions[0]).toEqual({
			field: "LastName",
			operator: "CONTAINS",
			slot: "text1"
		});

		await fire(operator(), { value: "IS_NULL" });
		expect(savedDefinition(events).conditions[0]).toEqual({ field: "LastName", operator: "IS_NULL" });
		expect(events).toContainEqual({ type: "configuration_editor_input_value_deleted", detail: { name: "text1" } });
		expect(valuePicker(element, 0)).toBeNull();
	});

	it("resets a condition's operator and value when its field changes", async () => {
		const { element, events } = await render(withCondition({ field: "LastName", operator: "EQUALS", value: "x" }));

		await pickField(element, 0, "Account.AnnualRevenue");

		expect(savedDefinition(events).conditions[0]).toEqual({ field: "Account.AnnualRevenue", operator: "EQUALS" });
		expect(valuePicker(element, 0).type).toBe("Number");
	});

	it("flags a condition when every slot of its type is taken", async () => {
		const conditions = Array.from({ length: 11 }, (_, index) => ({
			field: "LastName",
			operator: "EQUALS",
			...(index < 10 ? { slot: `text${index + 1}` } : {})
		}));
		const { element, events } = await render({ objectApiName: "Contact", fields: [], conditions, orderBy: [] });

		await fire(valuePicker(element, 10), { value: "textVar", valueDataType: "reference" });

		expect(events.some((event) => event.type === "configuration_editor_input_value_changed")).toBe(false);
		expect(rows(element, "condition")[10].textContent).toContain("up to 10 resources");
	});

	it("removes a condition and its slot", async () => {
		const { element, events } = await render(
			withCondition({ field: "LastName", operator: "EQUALS", slot: "text1" })
		);

		rows(element, "condition")[0].querySelector("lightning-button-icon").click();
		await flush();

		expect(events).toContainEqual({ type: "configuration_editor_input_value_deleted", detail: { name: "text1" } });
		expect(savedDefinition(events).conditions).toEqual([]);
	});

	it("shows a saved slot's resource, and keeps unfinished rows when Flow Builder echoes the definition", async () => {
		const definition = withCondition({ field: "LastName", operator: "EQUALS", slot: "text1" });
		const slotInput = { name: "text1", value: "textVar", valueDataType: "reference" };
		const { element, events } = await render(definition, [slotInput]);
		expect(valuePicker(element, 0)).toMatchObject({ value: "textVar", valueDataType: "reference" });

		element.shadowRoot.querySelector('lightning-button[data-name="addCondition"]').click();
		await flush();
		const echoed = { name: "queryDefinition", value: events.at(-1).detail.newValue, valueDataType: "String" };
		element.inputVariables = [echoed, slotInput];
		await flush();

		expect(rows(element, "condition")).toHaveLength(2);
	});

	it("switches to custom logic, starting from AND of every condition, and validates it", async () => {
		const { element, events } = await render({
			objectApiName: "Contact",
			fields: [],
			conditions: [
				{ field: "LastName", operator: "IS_NULL" },
				{ field: "LeadSource", operator: "IS_NULL" }
			],
			orderBy: []
		});
		const logic = element.shadowRoot.querySelector('lightning-combobox[data-name="conditionLogic"]');

		await fire(logic, { value: "CUSTOM" });
		expect(savedDefinition(events).conditionLogic).toBe("1 AND 2");
		expect(element.validate()).toEqual([]);

		const custom = element.shadowRoot.querySelector('lightning-input[data-name="customLogic"]');
		await fire(custom, { value: "1 OR 3" });
		expect(element.validate()).toEqual([{ key: "conditionLogic", errorString: expect.any(String) }]);
		await fire(custom, { value: "1; DELETE" });
		expect(element.validate()).toHaveLength(1);

		await fire(logic, { value: "OR" });
		expect(savedDefinition(events).conditionLogic).toBe("OR");
	});

	it("joins conditions with AND or OR, numbers them for custom logic, and disables an operator until its field is picked, like Get Records", async () => {
		const conditions = [
			{ field: "LastName", operator: "IS_NULL" },
			{ field: null, operator: null }
		];
		const { element } = await render({ objectApiName: "Contact", fields: [], conditions, orderBy: [] });
		const prefixes = () =>
			rows(element, "condition").map((row) => row.querySelector(".editor-row-prefix").textContent.trim());
		const logic = element.shadowRoot.querySelector('lightning-combobox[data-name="conditionLogic"]');

		expect(prefixes()).toEqual(["", "AND"]);
		const operators = rows(element, "condition").map((row) => row.querySelector('[data-role="operator"]'));
		expect(operators.map((operator) => operator.disabled)).toEqual([false, true]);
		await fire(logic, { value: "OR" });
		expect(prefixes()).toEqual(["", "OR"]);
		await fire(logic, { value: "CUSTOM" });
		expect(prefixes()).toEqual(["1", "2"]);
	});

	it("keeps custom logic in step as conditions are added and removed", async () => {
		const { element, events } = await render({
			objectApiName: "Contact",
			fields: [],
			conditions: [
				{ field: "LastName", operator: "IS_NULL" },
				{ field: "LeadSource", operator: "IS_NULL" },
				{ field: "Birthdate", operator: "IS_NULL" }
			],
			conditionLogic: "1 OR (2 AND 3)",
			orderBy: []
		});

		element.shadowRoot.querySelector('lightning-button[data-name="addCondition"]').click();
		await flush();
		// Parenthesized, since SOQL can't mix AND and OR without them:
		expect(savedDefinition(events).conditionLogic).toBe("(1 OR (2 AND 3)) AND 4");

		rows(element, "condition")[0].querySelector("lightning-button-icon").click();
		await flush();
		// The removed condition's number can't be guessed, so it's flagged for the user to fix:
		expect(savedDefinition(events).conditionLogic).toBe("(? OR (1 AND 2)) AND 3");
		// The added condition is still empty, so it's flagged too:
		expect(element.validate().map((error) => error.key)).toEqual(["condition-2", "conditionLogic"]);

		const custom = element.shadowRoot.querySelector('lightning-input[data-name="customLogic"]');
		await fire(custom, { value: "1 AND 2" });
		// Condition 3 isn't named, so it wouldn't apply:
		expect(element.validate().map((error) => error.key)).toEqual(["condition-2", "conditionLogic"]);
		await fire(custom, { value: "1 OR 2 AND 3" });
		expect(element.validate().map((error) => error.key)).toEqual(["condition-2", "conditionLogic"]);
		await fire(custom, { value: "1 OR (2 AND NOT 3)" });
		expect(element.validate().map((error) => error.key)).toEqual(["condition-2"]);
	});

	it("saves typed booleans in lowercase, which Apex reads", async () => {
		const { element, events } = await render(withCondition({ field: "DoNotCall", operator: "EQUALS" }));

		await fire(valuePicker(element, 0), { value: "TRUE", valueDataType: "Boolean" });

		expect(savedDefinition(events).conditions[0]).toEqual({
			field: "DoNotCall",
			operator: "EQUALS",
			value: "true"
		});
	});

	it("flags a missing object, and incomplete conditions", async () => {
		const { element } = await render();
		expect(element.validate()).toEqual([{ key: "objectApiName", errorString: "Enter a value." }]);

		const withIncomplete = await render(withCondition({ field: "LastName", operator: "EQUALS" }));
		expect(withIncomplete.element.validate()).toEqual([{ key: "condition-0", errorString: "Enter a value." }]);
	});

	it("saves sort fields and fields to store, without unfinished rows", async () => {
		const { element, events } = await render(withCondition({ field: "LastName", operator: "IS_NOT_NULL" }));

		element.shadowRoot.querySelector('lightning-button[data-name="addSort"]').click();
		element.shadowRoot.querySelector('lightning-button[data-name="addField"]').click();
		await flush();
		expect(savedDefinition(events)).toMatchObject({ fields: [], orderBy: [] });

		const sortRow = rows(element, "sortOrder")[0];
		await fire(sortRow.querySelector("c-soql-field-path"), { value: "Account.Name" });
		await fire(sortRow.querySelector('[data-property="direction"]'), { value: "DESCENDING" });
		await fire(rows(element, "field")[0].querySelector("c-soql-field-path"), { value: "Account.Owner.Name" });

		expect(savedDefinition(events)).toMatchObject({
			fields: ["Account.Owner.Name"],
			orderBy: [{ field: "Account.Name", direction: "DESCENDING" }]
		});

		rows(element, "sortOrder")[0].querySelector("lightning-button-icon").click();
		rows(element, "field")[0].querySelector("lightning-button-icon").click();
		await flush();
		expect(savedDefinition(events)).toMatchObject({ fields: [], orderBy: [] });
	});

	it("drops stored fields that All Fields covers, then offers only the parents' fields there", async () => {
		const fields = ["LastName", "Account.Name", "Account.Owner.Name"];
		const { element, events } = await render({ objectApiName: "Contact", fields, conditions: [], orderBy: [] });
		const fieldPaths = () => rows(element, "field").map((row) => row.querySelector("c-soql-field-path"));
		const addField = async () => {
			element.shadowRoot.querySelector('lightning-button[data-name="addField"]').click();
			await flush();
		};

		await addField();
		await fire(fieldPaths().at(-1), { value: "*", field: null });
		expect(savedDefinition(events).fields).toEqual(["Account.Name", "Account.Owner.Name", "*"]);

		await addField();
		await fire(fieldPaths().at(-1), { value: "Account.*", field: null });
		expect(savedDefinition(events).fields).toEqual(["Account.Owner.Name", "*", "Account.*"]);
		// Each picker hides the fields other rows' All Fields already store, keeping its own value pickable:
		expect(fieldPaths().map((fieldPath) => fieldPath.coveredPaths)).toEqual([["", "Account"], ["Account"], [""]]);
	});

	it("saves the query options and access level", async () => {
		const { element, events } = await render(withCondition({ field: "LastName", operator: "IS_NOT_NULL" }));
		const input = (name) => element.shadowRoot.querySelector(`[data-name="${name}"]`);

		await fire(input("rowLimit"), { value: "10" });
		await fire(input("rowOffset"), { value: "5" });
		await fire(input("usage"), { value: "FOR_UPDATE" });
		await fire(input("accessLevel"), { value: "SYSTEM_MODE" });
		expect(savedDefinition(events)).toMatchObject({ rowLimit: 10, rowOffset: 5, usage: "FOR_UPDATE" });
		expect(events).toContainEqual({
			type: "configuration_editor_input_value_changed",
			detail: { name: "accessLevel", newValue: "SYSTEM_MODE", newValueDataType: "String" }
		});

		await fire(input("rowLimit"), { value: "" });
		await fire(input("usage"), { value: "" });
		expect(savedDefinition(events)).toMatchObject({ rowLimit: null, usage: null });
	});

	it("only assigns slots that InvocableSoql.Input declares", () => {
		// Every slot type the editor can assign: one per value type, plus collections for the kinds that offer IN
		const prefixes = ["text", "number", "date", "dateTime", "time", "boolean"].concat(
			["text", "number", "date", "dateTime", "record"].map((prefix) => `${prefix}Collection`)
		);
		const source = readFileSync(path.resolve(__dirname, "../../../classes/InvocableSoql.cls"), "utf8");
		const declared = new Set([...source.matchAll(/public [\w<>]+ (\w+\d+);/g)].map((match) => match[1]));

		const expected = prefixes.flatMap((prefix) =>
			Array.from({ length: 10 }, (_, index) => `${prefix}${index + 1}`)
		);
		expect(expected.filter((name) => !declared.has(name))).toEqual([]);
		expect(declared.size).toBe(expected.length);
	});

	it("starts over from a definition that isn't valid JSON", async () => {
		const element = createElement("c-soql-query-editor", { is: SoqlQueryEditor });
		element.inputVariables = [{ name: "queryDefinition", value: "{not json", valueDataType: "String" }];
		document.body.appendChild(element);
		await flush();

		expect(element.validate()).toEqual([{ key: "objectApiName", errorString: "Enter a value." }]);
	});
});
