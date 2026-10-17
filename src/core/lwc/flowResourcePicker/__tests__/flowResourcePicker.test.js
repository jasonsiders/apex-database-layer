import { createElement } from "lwc";
import FlowResourcePicker from "c/flowResourcePicker";
import describeObject from "@salesforce/apex/FlowResourcePickerController.describeObject";
import CONTEXT from "../../flowResourceMenu/__tests__/data/context.json";
import ACCOUNT from "../../flowResourceMenu/__tests__/data/accountDescribe.json";
import USER from "../../flowResourceMenu/__tests__/data/userDescribe.json";

jest.mock("@salesforce/apex/FlowResourcePickerController.describeObject", () => ({ default: jest.fn() }), {
	virtual: true
});

const DESCRIBES = { Account: ACCOUNT, User: USER };

async function flush() {
	for (let i = 0; i < 5; i++) {
		// eslint-disable-next-line no-await-in-loop, @lwc/lwc/no-async-operation
		await new Promise((resolve) => setTimeout(resolve, 0));
	}
}

async function render(props = {}) {
	const element = createElement("c-flow-resource-picker", { is: FlowResourcePicker });
	Object.assign(element, {
		name: "accessLevel",
		label: "Access Level",
		builderContext: CONTEXT.builderContext,
		automaticOutputVariables: CONTEXT.automaticOutputVariables,
		...props
	});
	const onChange = jest.fn();
	element.addEventListener("change", onChange);
	document.body.appendChild(element);
	await flush();
	return { element, onChange };
}

function input(element) {
	return element.shadowRoot.querySelector('input[role="combobox"]');
}

function options(element) {
	return [...element.shadowRoot.querySelectorAll('[role="option"]')];
}

function optionLabels(element) {
	return options(element).map((candidate) => candidate.dataset.label);
}

function sectionLabels(element) {
	return [...element.shadowRoot.querySelectorAll(".slds-listbox__option-header")].map((header) => header.textContent);
}

function pillLabel(element) {
	return element.shadowRoot.querySelector(".slds-pill__label")?.textContent;
}

function option(element, label) {
	return options(element).find((candidate) => candidate.dataset.label === label);
}

async function type(element, text) {
	const field = input(element);
	field.value = text;
	field.dispatchEvent(new CustomEvent("input"));
	await flush();
}

async function open(element) {
	input(element).dispatchEvent(new CustomEvent("focus"));
	await flush();
}

async function blur(element) {
	element.shadowRoot
		.querySelector(".slds-combobox")
		.dispatchEvent(new FocusEvent("focusout", { relatedTarget: null }));
	await flush();
}

async function press(element, key) {
	input(element).dispatchEvent(new KeyboardEvent("keydown", { key }));
	await flush();
}

function lastChange(onChange) {
	return onChange.mock.calls.at(-1)[0].detail;
}

describe("c-flow-resource-picker", () => {
	beforeEach(() => {
		describeObject.mockImplementation(({ objectApiName }) => Promise.resolve(DESCRIBES[objectApiName]));
	});

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
		jest.clearAllMocks();
	});

	it("renders a labeled, closed combobox", async () => {
		const { element } = await render({ required: true, helpText: "Pick one" });

		expect(element.shadowRoot.querySelector("label").textContent).toContain("Access Level");
		expect(element.shadowRoot.querySelector("abbr.slds-required")).not.toBeNull();
		expect(element.shadowRoot.querySelector("lightning-helptext").content).toBe("Pick one");
		expect(input(element).placeholder).toBe("Enter value or search resources...");
		expect(input(element).getAttribute("aria-expanded")).toBe("false");
		expect(options(element)).toHaveLength(0);
	});

	it("lists the flow's resources when focused", async () => {
		const { element } = await render();

		await open(element);

		expect(input(element).getAttribute("aria-expanded")).toBe("true");
		expect(element.shadowRoot.querySelector(".picker-header").textContent).toBe("All Resources");
		expect(sectionLabels(element)).toContain("Simple Variables");
		expect(optionLabels(element)).toContain("textVar");
		expect(optionLabels(element)).toContain("Current Item from Loop Loop Accounts");
	});

	it("labels Get Records outputs with the object's plural label", async () => {
		const { element } = await render({ type: "SObject", isCollection: true });

		await open(element);

		expect(optionLabels(element)).toContain("Accounts from Get Accounts");
	});

	it("filters resources as the user types", async () => {
		const { element } = await render();
		await open(element);

		await type(element, "text");

		expect(optionLabels(element)).toEqual(["constText", "textVar", "tmplText"]);
	});

	it("shows an empty state when nothing matches", async () => {
		const { element } = await render();
		await open(element);

		await type(element, "zzz");

		expect(options(element)).toHaveLength(0);
		expect(element.shadowRoot.querySelector(".picker-empty").textContent).toContain(
			"couldn't find any matching resources"
		);
	});

	it("selects a resource as a reference, and shows it as a pill", async () => {
		const { element, onChange } = await render();
		await open(element);

		option(element, "textVar").click();
		await flush();

		expect(lastChange(onChange)).toEqual({ name: "accessLevel", value: "textVar", valueDataType: "reference" });
		expect(pillLabel(element)).toBe("textVar");
		expect(options(element)).toHaveLength(0);
	});

	it("selects a picklist value as a literal", async () => {
		const picklistValues = [{ label: "System Mode", value: "SYSTEM_MODE" }];
		const { element, onChange } = await render({ picklistValues });
		await open(element);

		option(element, "System Mode").click();
		await flush();

		expect(lastChange(onChange)).toEqual({ name: "accessLevel", value: "SYSTEM_MODE", valueDataType: "String" });
		expect(input(element).value).toBe("SYSTEM_MODE");
	});

	it("drills into records and their relationships, with breadcrumbs", async () => {
		const { element, onChange } = await render();
		await open(element);

		option(element, "accountVar").click();
		await flush();

		expect(input(element).value).toBe("{!accountVar.");
		expect(sectionLabels(element)).toEqual(["Relationship Fields", "Record Fields"]);
		const crumbs = [...element.shadowRoot.querySelectorAll("lightning-breadcrumb")].map((crumb) => crumb.label);
		expect(crumbs).toEqual(["All Resources", "accountVar"]);

		option(element, "Owner ID").click();
		await flush();
		expect(input(element).value).toBe("{!accountVar.Owner.");

		option(element, "Email").click();
		await flush();
		expect(lastChange(onChange)).toEqual({
			name: "accessLevel",
			value: "accountVar.Owner.Email",
			valueDataType: "reference"
		});
		expect(pillLabel(element)).toBe("accountVar > Owner ID > Email");
	});

	it("navigates back up through the breadcrumbs", async () => {
		const { element } = await render();
		await open(element);
		option(element, "accountVar").click();
		await flush();

		element.shadowRoot
			.querySelector('lightning-breadcrumb[data-index="-1"]')
			.dispatchEvent(new CustomEvent("click"));
		await flush();

		expect(input(element).value).toBe("");
		expect(element.shadowRoot.querySelector(".picker-header").textContent).toBe("All Resources");
	});

	it("drills by typing a merge field path", async () => {
		const { element } = await render();
		await open(element);

		await type(element, "{!accountVar.Own");

		expect(optionLabels(element)).toEqual(["Owner ID", "Owner ID"]);
	});

	it("supports keyboard navigation", async () => {
		const { element, onChange } = await render({ type: "Boolean" });
		await open(element);
		await press(element, "Escape");
		expect(input(element).getAttribute("aria-expanded")).toBe("false");

		await press(element, "ArrowDown");
		await press(element, "ArrowDown");
		await press(element, "ArrowUp");
		const active = element.shadowRoot.querySelector('[role="option"][aria-selected="true"]');
		expect(active.dataset.label).toBe("Current Item from Loop Loop Accounts");
		expect(input(element).getAttribute("aria-activedescendant")).toBe(active.id);

		await type(element, "boolVar");
		await press(element, "ArrowDown");
		await press(element, "Enter");
		expect(lastChange(onChange)).toEqual({ name: "accessLevel", value: "boolVar", valueDataType: "reference" });
	});

	it("keeps a chosen resource when the input loses focus to its pill", async () => {
		const { element, onChange } = await render();
		await open(element);
		await type(element, "textVar");
		await press(element, "ArrowDown");
		await press(element, "Enter");

		// In the browser, swapping the input for a pill blurs it
		await blur(element);

		expect(onChange).toHaveBeenCalledTimes(1);
		expect(pillLabel(element)).toBe("textVar");
	});

	it("discards an unfinished merge field when focus leaves", async () => {
		const { element, onChange } = await render({ value: "textVar", valueDataType: "reference" });
		element.shadowRoot.querySelector(".picker-pill-edit").click();
		await flush();

		await type(element, "{!accountVar.");
		await blur(element);

		expect(onChange).not.toHaveBeenCalled();
		expect(pillLabel(element)).toBe("textVar");
	});

	it("drills when Enter is pressed on a container", async () => {
		const { element } = await render();
		await open(element);
		await type(element, "accountVar");

		await press(element, "ArrowDown");
		await press(element, "Enter");

		expect(input(element).value).toBe("{!accountVar.");
	});

	it("commits typed text when focus leaves", async () => {
		const { element, onChange } = await render();
		await open(element);

		await type(element, "{!textVar}");
		await blur(element);
		expect(lastChange(onChange)).toEqual({ name: "accessLevel", value: "textVar", valueDataType: "reference" });

		element.shadowRoot.querySelector(".picker-pill-remove").click();
		await flush();
		expect(lastChange(onChange)).toEqual({ name: "accessLevel", value: null, valueDataType: null });

		await type(element, "plain text");
		await press(element, "Enter");
		expect(lastChange(onChange)).toEqual({ name: "accessLevel", value: "plain text", valueDataType: "String" });
	});

	it("commits typed true/false as a boolean global constant", async () => {
		const { element, onChange } = await render({ type: "Boolean" });
		await open(element);

		await type(element, "TRUE");
		await blur(element);

		expect(lastChange(onChange)).toEqual({
			name: "accessLevel",
			value: "$GlobalConstant.True",
			valueDataType: "Boolean"
		});
	});

	it("saves global constants with their own data type, as Flow Builder requires", async () => {
		const { element, onChange } = await render();
		await open(element);

		option(element, "Blank Value (Empty String)").click();
		await flush();
		expect(lastChange(onChange)).toEqual({
			name: "accessLevel",
			value: "$GlobalConstant.EmptyString",
			valueDataType: "String"
		});

		element.shadowRoot.querySelector(".picker-pill-edit").click();
		await flush();
		await type(element, "{!$GlobalConstant.False}");
		await blur(element);
		expect(lastChange(onChange)).toEqual({
			name: "accessLevel",
			value: "$GlobalConstant.False",
			valueDataType: "Boolean"
		});
	});

	it("clears the value when the text is erased", async () => {
		const { element, onChange } = await render({ value: "SYSTEM_MODE", valueDataType: "String" });
		expect(input(element).value).toBe("SYSTEM_MODE");
		await open(element);

		await type(element, "");
		await blur(element);

		expect(lastChange(onChange)).toEqual({ name: "accessLevel", value: null, valueDataType: null });
	});

	it("does not re-emit an unchanged value", async () => {
		const { element, onChange } = await render({ value: "SYSTEM_MODE", valueDataType: "String" });
		await open(element);

		await blur(element);

		expect(onChange).not.toHaveBeenCalled();
	});

	it("shows existing references as pills, with resolved labels", async () => {
		const { element } = await render({ value: "accountVar.Owner.Email", valueDataType: "reference" });

		expect(pillLabel(element)).toBe("accountVar > Owner ID > Email");
		expect(element.shadowRoot.querySelector(".picker-pill lightning-icon").iconName).toBe("utility:text");
		const remove = element.shadowRoot.querySelector(".picker-pill-remove");
		expect(remove.alternativeText).toBe("Remove accountVar > Owner ID > Email");
	});

	it("shows boolean values as global constant pills", async () => {
		const { element } = await render({ type: "Boolean", value: "$GlobalConstant.True", valueDataType: "Boolean" });
		expect(pillLabel(element)).toBe("True");

		element.value = false;
		await flush();
		expect(pillLabel(element)).toBe("False");
	});

	it("shows unknown references as-is", async () => {
		const { element } = await render({ value: "deletedVar", valueDataType: "reference" });

		expect(pillLabel(element)).toBe("deletedVar");
	});

	it("edits a pill's reference when clicked", async () => {
		const { element } = await render({ value: "accountVar.Owner.Email", valueDataType: "reference" });

		element.shadowRoot.querySelector(".picker-pill-edit").click();
		await flush();

		expect(input(element).value).toBe("{!accountVar.Owner.Email}");
		expect(optionLabels(element)).toEqual(["Email"]);
		const icons = [...option(element, "Email").querySelectorAll("lightning-icon")].map((icon) => icon.iconName);
		expect(icons).toContain("utility:check");
	});

	it("shows an error message", async () => {
		const { element } = await render({ errorMessage: "Enter a valid value." });

		expect(element.shadowRoot.querySelector(".slds-form-element").classList).toContain("slds-has-error");
		expect(element.shadowRoot.querySelector(".slds-form-element__help").textContent).toBe("Enter a valid value.");
	});

	it("exposes its inputs, and keeps focus in the input while the menu is clicked", async () => {
		const { element } = await render({ value: "textVar", valueDataType: "reference" });
		expect(element.value).toBe("textVar");
		expect(element.valueDataType).toBe("reference");
		expect(element.builderContext).toEqual(CONTEXT.builderContext);

		element.shadowRoot.querySelector(".picker-pill-edit").click();
		await flush();
		const mouseDown = new CustomEvent("mousedown", { cancelable: true });
		element.shadowRoot.querySelector('[role="listbox"]').dispatchEvent(mouseDown);

		expect(mouseDown.defaultPrevented).toBe(true);
	});

	it("relabels Get Records outputs when labels arrive while the menu is open", async () => {
		const lead = { label: "Lead", labelPlural: "Leads" };
		describeObject.mockImplementation(({ objectApiName }) => {
			return objectApiName === "Lead" ? Promise.resolve(lead) : Promise.reject(new Error("nope"));
		});
		const { element } = await render({ type: "SObject", isCollection: true });
		await open(element);

		const lookup = { getFirstRecordOnly: false, storeOutputAutomatically: true };
		const recordLookups = [
			{ ...lookup, name: "Get_Leads", label: "Get Leads", object: "Lead" },
			{ ...lookup, name: "Get_Things", label: "Get Things", object: "Thing__c" }
		];
		element.builderContext = { ...CONTEXT.builderContext, recordLookups };
		await flush();

		expect(optionLabels(element)).toEqual(
			expect.arrayContaining(["Leads from Get Leads", "Thing__c from Get Things"])
		);
	});

	it("scopes resources to the element being edited, and labels the triggering record", async () => {
		const start = {
			...CONTEXT.builderContext.start,
			object: "Account",
			triggerType: "RecordAfterSave",
			recordTriggerType: "Update"
		};
		const { element } = await render({
			elementName: "Create_Native",
			builderContext: { ...CONTEXT.builderContext, start }
		});

		await open(element);

		expect(optionLabels(element)).toEqual(
			expect.arrayContaining(["Triggering Account", "Prior Values of Triggering Account"])
		);
		expect(optionLabels(element)).not.toContain("Current Item from Loop Loop Accounts");
	});

	it("retries a describe that failed", async () => {
		const lookup = { getFirstRecordOnly: false, storeOutputAutomatically: true };
		const recordLookups = [{ ...lookup, name: "Get_Opps", label: "Get Opps", object: "Opportunity" }];
		const builderContext = { ...CONTEXT.builderContext, recordLookups };
		describeObject.mockImplementation(() => Promise.reject(new Error("nope")));
		const { element } = await render({ type: "SObject", isCollection: true, builderContext });

		describeObject.mockImplementation(() =>
			Promise.resolve({ label: "Opportunity", labelPlural: "Opportunities" })
		);
		element.builderContext = { ...builderContext };
		await open(element);

		expect(optionLabels(element)).toContain("Opportunities from Get Opps");
	});

	it("shows the latest value when an earlier one resolves late", async () => {
		let resolveCase;
		describeObject.mockImplementation(({ objectApiName }) => {
			return objectApiName === "Case"
				? new Promise((resolve) => {
						resolveCase = resolve;
					})
				: Promise.resolve(DESCRIBES[objectApiName]);
		});
		const caseVar = { name: "caseVar", dataType: "SObject", objectType: "Case", isCollection: false };
		const variables = [...CONTEXT.builderContext.variables, caseVar];
		const builderContext = { ...CONTEXT.builderContext, variables };
		const { element } = await render({ builderContext, value: "caseVar.Subject", valueDataType: "reference" });

		element.value = "textVar";
		await flush();
		resolveCase({ apiName: "Case", fields: [{ apiName: "Subject", dataType: "STRING", label: "Subject" }] });
		await flush();

		expect(pillLabel(element)).toBe("textVar");
	});

	it("survives describe failures", async () => {
		describeObject.mockImplementation(() => Promise.reject(new Error("nope")));
		const { element } = await render({ builderContext: { ...CONTEXT.builderContext, recordLookups: [] } });
		await open(element);

		option(element, "contactVar").click();
		await flush();

		expect(options(element)).toHaveLength(0);
	});
});
