import { createElement } from "lwc";
import DmlRecordsEditor from "c/dmlRecordsEditor";
import CONTEXT from "../../flowResourceMenu/__tests__/data/context.json";

const OPTION_NAMES = [
	"accessLevel",
	"allOrNone",
	"allowDuplicates",
	"allowFieldTruncation",
	"assignmentRuleId",
	"localeOptions",
	"runDuplicateRulesAsCurrentUser",
	"triggerAutoResponseEmail",
	"triggerOtherEmail",
	"triggerUserEmail",
	"useDefaultAssignmentRule"
];

async function flush() {
	for (let i = 0; i < 3; i++) {
		// eslint-disable-next-line no-await-in-loop, @lwc/lwc/no-async-operation
		await new Promise((resolve) => setTimeout(resolve, 0));
	}
}

async function render(inputVariables = []) {
	const element = createElement("c-dml-records-editor", { is: DmlRecordsEditor });
	Object.assign(element, {
		inputVariables,
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
	await flush();
	return { element, events };
}

function picker(element, name) {
	return element.shadowRoot.querySelector(`c-flow-resource-picker[data-name="${name}"]`);
}

function changePicker(element, name, detail) {
	picker(element, name).dispatchEvent(new CustomEvent("change", { detail: { name, ...detail } }));
}

describe("c-dml-records-editor", () => {
	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	it("starts with a single record input, and a picker for every option", async () => {
		const { element } = await render();

		const radio = element.shadowRoot.querySelector("lightning-radio-group");
		expect(radio.label).toBe("How Many Records to Insert");
		expect(radio.value).toBe("one");
		const record = picker(element, "record");
		expect(record).toMatchObject({ label: "Record", required: true, type: "SObject", isCollection: false });
		expect(picker(element, "recordCollection")).toBeNull();
		OPTION_NAMES.forEach((name) => expect(picker(element, name)).not.toBeNull());
		expect(picker(element, "accessLevel").picklistValues).toEqual([
			{ label: "User Mode", value: "USER_MODE" },
			{ label: "System Mode", value: "SYSTEM_MODE" }
		]);
		expect(picker(element, "allOrNone").type).toBe("Boolean");
		expect(picker(element, "localeOptions").type).toBe("String");
	});

	it("tells each picker which element is being edited", async () => {
		const { element } = await render();

		element.elementInfo = { apiName: "Insert_Spike", type: "Action" };
		await flush();

		const pickers = [...element.shadowRoot.querySelectorAll("c-flow-resource-picker")];
		expect(pickers.map((child) => child.elementName)).toEqual(pickers.map(() => "Insert_Spike"));
	});

	it("shows the saved configuration", async () => {
		const { element } = await render([
			{ name: "recordCollection", value: "accountsVar", valueDataType: "reference" },
			{ name: "accessLevel", value: "SYSTEM_MODE", valueDataType: "String" },
			{ name: "allOrNone", value: "$GlobalConstant.False", valueDataType: "Boolean" }
		]);

		expect(element.shadowRoot.querySelector("lightning-radio-group").value).toBe("multiple");
		expect(picker(element, "recordCollection")).toMatchObject({
			value: "accountsVar",
			valueDataType: "reference",
			isCollection: true
		});
		expect(picker(element, "accessLevel")).toMatchObject({ value: "SYSTEM_MODE", valueDataType: "String" });
		expect(picker(element, "allOrNone")).toMatchObject({
			value: "$GlobalConstant.False",
			valueDataType: "Boolean"
		});
		expect(element.inputVariables).toHaveLength(3);
	});

	it("saves the chosen records, and types the action's generic inputs and outputs to their object", async () => {
		const { element, events } = await render();

		changePicker(element, "record", { value: "accountVar", valueDataType: "reference", objectType: "Account" });

		expect(events).toEqual([
			{
				type: "configuration_editor_input_value_changed",
				detail: { name: "record", newValue: "accountVar", newValueDataType: "reference" }
			},
			...["T__record", "T__recordCollection", "U__record", "U__recordCollection"].map((typeName) => ({
				type: "configuration_editor_generic_type_mapping_changed",
				detail: { typeName, typeValue: "Account" }
			}))
		]);
	});

	it("saves options, and deletes them when cleared", async () => {
		const { element, events } = await render();

		changePicker(element, "accessLevel", { value: "SYSTEM_MODE", valueDataType: "String" });
		changePicker(element, "accessLevel", { value: null, valueDataType: null });

		expect(events).toEqual([
			{
				type: "configuration_editor_input_value_changed",
				detail: { name: "accessLevel", newValue: "SYSTEM_MODE", newValueDataType: "String" }
			},
			{ type: "configuration_editor_input_value_deleted", detail: { name: "accessLevel" } }
		]);
	});

	it("switches between one record and a collection, dropping the other input", async () => {
		const { element, events } = await render([{ name: "record", value: "accountVar", valueDataType: "reference" }]);
		const radio = element.shadowRoot.querySelector("lightning-radio-group");

		radio.dispatchEvent(new CustomEvent("change", { detail: { value: "multiple" } }));
		await flush();

		expect(events).toEqual([{ type: "configuration_editor_input_value_deleted", detail: { name: "record" } }]);
		expect(picker(element, "record")).toBeNull();
		expect(picker(element, "recordCollection")).toMatchObject({ label: "Record Collection", isCollection: true });
	});

	it("requires records", async () => {
		const { element } = await render();

		expect(element.validate()).toEqual([{ key: "record", errorString: "Select a record." }]);
		await flush();
		expect(picker(element, "record").errorMessage).toBe("Select a record.");
	});

	it("rejects literals the action can't use", async () => {
		const { element } = await render([
			{ name: "recordCollection", value: "accountsVar", valueDataType: "reference" },
			{ name: "accessLevel", value: "GOD_MODE", valueDataType: "String" },
			{ name: "allOrNone", value: "maybe", valueDataType: "Boolean" }
		]);

		expect(element.validate()).toEqual([
			{ key: "accessLevel", errorString: "Enter USER_MODE or SYSTEM_MODE." },
			{ key: "allOrNone", errorString: "Enter True or False." }
		]);
	});

	it("accepts a complete configuration", async () => {
		const { element } = await render([
			{ name: "record", value: "accountVar", valueDataType: "reference" },
			{ name: "accessLevel", value: "system_mode", valueDataType: "String" },
			{ name: "allOrNone", value: false, valueDataType: "Boolean" },
			{ name: "allowDuplicates", value: "$GlobalConstant.True", valueDataType: "Boolean" },
			{ name: "triggerUserEmail", value: "boolVar", valueDataType: "reference" }
		]);

		expect(element.validate()).toEqual([]);
	});
});
