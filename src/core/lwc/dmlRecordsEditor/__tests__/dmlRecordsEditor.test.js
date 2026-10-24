import { createElement } from "lwc";
import DmlRecordsEditor from "c/dmlRecordsEditor";
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import getMatchFields from "@salesforce/apex/InvocableDmlUpsertRecords.getMatchFields";
import CONTEXT from "../../flowResourceMenu/__tests__/data/context.json";

jest.mock(
	"@salesforce/apex/InvocableDmlUpsertRecords.getMatchFields",
	() => {
		const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
		return { default: createApexTestWireAdapter(jest.fn()) };
	},
	{ virtual: true }
);

const OPTION_NAMES = [
	"accessLevel",
	"allOrNone",
	"allowDuplicates",
	"useDefaultAssignmentRule",
	"assignmentRuleId",
	"allowFieldTruncation",
	"triggerUserEmail",
	"triggerAutoResponseEmail",
	"triggerOtherEmail",
	"runDuplicateRulesAsCurrentUser",
	"localeOptions"
];

async function flush() {
	for (let i = 0; i < 3; i++) {
		// eslint-disable-next-line no-await-in-loop, @lwc/lwc/no-async-operation
		await new Promise((resolve) => setTimeout(resolve, 0));
	}
}

async function render(inputVariables = [], actionName = "InvocableDmlInsertRecords") {
	const element = createElement("c-dml-records-editor", { is: DmlRecordsEditor });
	Object.assign(element, {
		elementInfo: { apiName: "Dml_Element", type: "Action", actionName },
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

function inputNames(element, root = element.shadowRoot) {
	return [...root.querySelectorAll("[data-name]")].map((child) => child.dataset.name);
}

function optionInput(element, name) {
	return accordion(element).querySelector(`[data-name="${name}"]`);
}

function accordion(element) {
	return element.shadowRoot.querySelector("lightning-accordion");
}

function headings(element) {
	return [...element.shadowRoot.querySelectorAll("h3")].map((heading) => heading.textContent);
}

function radios(element) {
	return [...element.shadowRoot.querySelectorAll("lightning-input")].filter((input) => input.type === "radio");
}

async function chooseMatchMode(element, label) {
	radios(element)
		.find((radio) => radio.label === label)
		.dispatchEvent(new CustomEvent("change"));
	await flush();
}

const MATCH_FIELDS = [
	{ apiName: "Legacy_Id__c", label: "Legacy ID", isExternalId: true },
	{ apiName: "Email", label: "Email", isExternalId: false },
	{ apiName: "Erp_Id__c", label: "ERP ID", isExternalId: true }
];

// Chooses through the picker's own menu, like a user, so the editor gets the event the picker really sends
async function choose(element, name, label) {
	const root = picker(element, name).shadowRoot;
	const pillEdit = root.querySelector(".picker-pill-edit");
	if (pillEdit) {
		pillEdit.click();
		pillEdit.dispatchEvent(new FocusEvent("focusout", { bubbles: true, relatedTarget: null }));
		await flush();
	}
	const field = root.querySelector('input[role="combobox"]');
	field.value = label;
	field.dispatchEvent(new CustomEvent("input"));
	await flush();
	root.querySelector(`[role="option"][data-label="${label}"]`).click();
	await flush();
}

describe("c-dml-records-editor", () => {
	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	it("starts with a single record input, and a static input for every option", async () => {
		const { element } = await render();

		const radio = element.shadowRoot.querySelector("lightning-radio-group");
		expect(radio.label).toBe("How Many Records to Insert");
		expect(radio.value).toBe("one");
		const record = picker(element, "record");
		expect(record).toMatchObject({ label: "Record", required: true, type: "SObject", isCollection: false });
		expect(picker(element, "recordCollection")).toBeNull();
		const accessLevel = optionInput(element, "accessLevel");
		expect(accessLevel.tagName).toBe("LIGHTNING-COMBOBOX");
		expect(accessLevel.options).toEqual([
			{ label: "User Mode", value: "USER_MODE" },
			{ label: "System Mode", value: "SYSTEM_MODE" }
		]);
		const allOrNone = optionInput(element, "allOrNone");
		expect(allOrNone.tagName).toBe("LIGHTNING-COMBOBOX");
		expect(allOrNone.options).toEqual([
			{ label: "True", value: "$GlobalConstant.True" },
			{ label: "False", value: "$GlobalConstant.False" }
		]);
		expect(optionInput(element, "localeOptions").tagName).toBe("LIGHTNING-COMBOBOX");
	});

	it("offers the org's user locales that DmlOptions accepts by code, and a way to unset it", async () => {
		const { element } = await render();

		expect(getPicklistValues.getLastConfig()).toEqual({
			recordTypeId: "012000000000000AAA",
			fieldApiName: { objectApiName: "User", fieldApiName: "LocaleSidKey" }
		});
		getPicklistValues.emit({
			values: [
				{ label: "English (United States)", value: "en_US", attributes: null, validFor: [] },
				{ label: "German (Germany)", value: "de_DE", attributes: null, validFor: [] },
				{ label: "Chinese (China, Pinyin Ordering)", value: "zh_CN_PINYIN", attributes: null, validFor: [] }
			]
		});
		await flush();

		expect(optionInput(element, "localeOptions").options).toEqual([
			{ label: "--None--", value: "" },
			{ label: "de_DE", value: "de_DE" },
			{ label: "en_US", value: "en_US" }
		]);
	});

	it("only looks up locales for actions with Locale Options", async () => {
		await render([], "InvocableDmlDeleteRecords");

		expect(getPicklistValues.getLastConfig()?.recordTypeId).toBeUndefined();
	});

	it("shows each option's default until it's set", async () => {
		const { element } = await render();

		expect(optionInput(element, "accessLevel").value).toBe("USER_MODE");
		expect(optionInput(element, "allOrNone").value).toBe("$GlobalConstant.True");
		expect(optionInput(element, "allowDuplicates").value).toBe("$GlobalConstant.False");
	});

	it("only lets Assignment Rule ID take a resource, since rule IDs differ between orgs", async () => {
		const { element } = await render();

		const resourceOptions = [...accordion(element).querySelectorAll("c-flow-resource-picker")];
		expect(resourceOptions.map((child) => child.name)).toEqual(["assignmentRuleId"]);
		expect(resourceOptions[0].helpText).toContain("differ between orgs");
	});

	it("collapses every option into one DML Options section, most used first", async () => {
		const { element } = await render();

		const options = accordion(element);
		const section = options.querySelector("lightning-accordion-section");
		expect(options.allowMultipleSectionsOpen).toBe(true);
		expect(options.activeSectionName).toBeUndefined();
		expect(section.label).toBe("DML Options");
		expect(inputNames(element, section)).toEqual(OPTION_NAMES);
	});

	it("tells each picker which element is being edited", async () => {
		const { element } = await render();

		element.elementInfo = { apiName: "Insert_Spike", type: "Action", actionName: "InvocableDmlInsertRecords" };
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
		expect(optionInput(element, "accessLevel").value).toBe("SYSTEM_MODE");
		expect(optionInput(element, "allOrNone").value).toBe("$GlobalConstant.False");
		expect(element.inputVariables).toHaveLength(3);
	});

	it("saves the chosen records, and types the action's generic inputs and outputs to their object", async () => {
		const { element, events } = await render();

		await choose(element, "record", "accountVar");

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

		const change = (name, detail) =>
			optionInput(element, name).dispatchEvent(new CustomEvent("change", { detail }));
		change("accessLevel", { value: "SYSTEM_MODE" });
		change("allOrNone", { value: "$GlobalConstant.False" });
		change("allowDuplicates", { value: "$GlobalConstant.True" });
		change("localeOptions", { value: "en_US" });
		change("localeOptions", { value: "" });
		await choose(element, "assignmentRuleId", "textVar");

		const saved = (name, newValue, newValueDataType) => ({
			type: "configuration_editor_input_value_changed",
			detail: { name, newValue, newValueDataType }
		});
		expect(events).toEqual([
			saved("accessLevel", "SYSTEM_MODE", "String"),
			saved("allOrNone", "$GlobalConstant.False", "Boolean"),
			saved("allowDuplicates", "$GlobalConstant.True", "Boolean"),
			saved("localeOptions", "en_US", "String"),
			{ type: "configuration_editor_input_value_deleted", detail: { name: "localeOptions" } },
			saved("assignmentRuleId", "textVar", "reference")
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

		expect(element.validate()).toEqual([{ key: "record", errorString: "Enter a value." }]);
		await flush();
		expect(picker(element, "record").errorMessage).toBe("Enter a value.");

		await choose(element, "record", "accountVar");
		expect(picker(element, "record").errorMessage).toBeUndefined();
	});

	it("treats the blank inputs Flow Builder sends for a new action as unset", async () => {
		const blank = (name) => ({ name, value: "", valueDataType: "" });
		const inputVariables = ["record", "recordCollection", "externalIdField", ...OPTION_NAMES].map(blank);

		const { element } = await render(inputVariables);
		const upsert = await render(inputVariables, "InvocableDmlUpsertRecords");

		expect(element.shadowRoot.querySelector("lightning-radio-group").value).toBe("one");
		expect(element.validate()).toEqual([{ key: "record", errorString: "Enter a value." }]);
		expect(radios(upsert.element).find((radio) => radio.checked).label).toBe("Record ID");
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

	it("takes one record or a collection in one input for the other actions, like Update and Delete Records", async () => {
		const { element } = await render([], "InvocableDmlDeleteRecords");

		expect(element.shadowRoot.querySelector("lightning-radio-group")).toBeNull();
		expect(picker(element, "record")).toMatchObject({ label: "Record or Record Collection", required: true });
		expect(picker(element, "record").isCollection).toBeUndefined();
		expect(headings(element)).toEqual(["Select Record(s) to Delete"]);
		expect(element.shadowRoot.querySelector("p").textContent).toContain("include IDs");
		expect(inputNames(element)).toEqual(["record", "accessLevel", "allOrNone"]);
		expect(element.validate()).toEqual([{ key: "record", errorString: "Enter a value." }]);
	});

	it("saves the records to the input matching their shape, dropping the other input", async () => {
		const { element, events } = await render(
			[{ name: "record", value: "accountVar", valueDataType: "reference" }],
			"InvocableDmlUpdateRecords"
		);

		await choose(element, "record", "accountsVar");

		expect(events.slice(0, 2)).toEqual([
			{ type: "configuration_editor_input_value_deleted", detail: { name: "record" } },
			{
				type: "configuration_editor_input_value_changed",
				detail: { name: "recordCollection", newValue: "accountsVar", newValueDataType: "reference" }
			}
		]);
		expect(picker(element, "recordCollection")).not.toBeNull();
	});

	it("shows each action's own options", async () => {
		const optionsByAction = {
			InvocableDmlEmptyRecycleBin: [],
			InvocableDmlUndeleteRecords: ["accessLevel", "allOrNone"],
			InvocableDmlUpdateRecords: OPTION_NAMES,
			InvocableDmlUpsertRecords: ["accessLevel", "allOrNone"]
		};

		for (const [actionName, options] of Object.entries(optionsByAction)) {
			// eslint-disable-next-line no-await-in-loop
			const { element } = await render([], actionName);
			expect(inputNames(element)).toEqual(["record", ...options]);
			expect(Boolean(accordion(element))).toBe(options.length > 0);
			document.body.removeChild(element);
		}
	});

	it("matches upserted records on their ID by default, or on a chosen field, like Flow Builder's upsert", async () => {
		const { element, events } = await render([], "InvocableDmlUpsertRecords");
		element.genericTypeMappings = [{ typeName: "T__record", typeValue: "Account" }];
		await flush();
		expect(getMatchFields.getLastConfig()).toEqual({ objectApiName: "Account" });
		getMatchFields.emit(MATCH_FIELDS);
		await flush();

		expect(radios(element).map((radio) => [radio.label, radio.checked])).toEqual([
			["Record ID", true],
			["External ID", false],
			["Standard Field", false]
		]);
		expect(picker(element, "externalIdField")).toBeNull();
		expect(element.validate()).toEqual([{ key: "record", errorString: "Enter a value." }]);

		await chooseMatchMode(element, "External ID");
		const field = picker(element, "externalIdField");
		expect(field).toMatchObject({
			placeholder: "Search external ID fields...",
			isPicklistOnly: true,
			required: true
		});
		expect(field.picklistValues.map((option) => [option.label, option.description])).toEqual([
			["Erp_Id__c", "ERP ID"],
			["Legacy_Id__c", "Legacy ID"]
		]);
		expect(element.validate()).toContainEqual({ key: "externalIdField", errorString: "Enter a value." });

		await choose(element, "externalIdField", "Erp_Id__c");
		expect(events.at(-1)).toEqual({
			type: "configuration_editor_input_value_changed",
			detail: { name: "externalIdField", newValue: "Erp_Id__c", newValueDataType: "String" }
		});
	});

	it("shows a saved standard field in its mode, and drops it for another mode", async () => {
		const { element, events } = await render(
			[{ name: "externalIdField", value: "Email", valueDataType: "String" }],
			"InvocableDmlUpsertRecords"
		);
		await choose(element, "record", "contactVar");
		expect(getMatchFields.getLastConfig()).toEqual({ objectApiName: "Contact" });
		getMatchFields.emit(MATCH_FIELDS);
		await flush();

		expect(radios(element).find((radio) => radio.checked).label).toBe("Standard Field");
		expect(picker(element, "externalIdField")).toMatchObject({
			value: "Email",
			placeholder: "Search standard fields..."
		});
		expect(picker(element, "externalIdField").picklistValues.map((option) => option.value)).toEqual(["Email"]);

		events.length = 0;
		await chooseMatchMode(element, "Record ID");
		expect(events).toEqual([
			{ type: "configuration_editor_input_value_deleted", detail: { name: "externalIdField" } }
		]);
		expect(picker(element, "externalIdField")).toBeNull();
	});

	it("drops the match field when the records switch to another object, and asks for a new one", async () => {
		const { element, events } = await render(
			[{ name: "externalIdField", value: "Legacy_Id__c", valueDataType: "String" }],
			"InvocableDmlUpsertRecords"
		);
		element.genericTypeMappings = [{ typeName: "T__record", typeValue: "Account" }];
		await flush();

		await choose(element, "record", "accountVar");
		expect(events.map((event) => event.detail.name)).not.toContain("externalIdField");

		await choose(element, "record", "contactVar");
		expect(events).toContainEqual({
			type: "configuration_editor_input_value_deleted",
			detail: { name: "externalIdField" }
		});
		// Flow Builder re-sends the inputs without the deleted one
		element.inputVariables = [{ name: "record", value: "contactVar", valueDataType: "reference" }];
		await flush();
		expect(radios(element).find((radio) => radio.checked).label).toBe("External ID");
		expect(element.validate()).toEqual([{ key: "externalIdField", errorString: "Enter a value." }]);
	});

	it("only looks up match fields for Upsert Records", async () => {
		const { element } = await render([], "InvocableDmlUpdateRecords");
		element.genericTypeMappings = [{ typeName: "T__record", typeValue: "Account" }];
		await flush();

		expect(radios(element)).toHaveLength(0);
		expect(getMatchFields.getLastConfig()?.objectApiName).toBeUndefined();
	});
});
