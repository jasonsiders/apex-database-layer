import { createElement } from "lwc";
import SoqlFieldPath from "c/soqlFieldPath";
import getFields from "@salesforce/apex/InvocableSoql.getFields";
import FIELDS from "../../soqlFieldMenu/__tests__/data/fields.json";

jest.mock("@salesforce/apex/InvocableSoql.getFields", () => ({ default: jest.fn() }), { virtual: true });

async function flush() {
	for (let i = 0; i < 5; i++) {
		// eslint-disable-next-line no-await-in-loop, @lwc/lwc/no-async-operation
		await new Promise((resolve) => setTimeout(resolve, 0));
	}
}

async function render(props = {}) {
	const element = createElement("c-soql-field-path", { is: SoqlFieldPath });
	Object.assign(element, { label: "Field", objectApiName: "Contact", ...props });
	const onChange = jest.fn();
	element.addEventListener("change", onChange);
	document.body.appendChild(element);
	await flush();
	return { element, onChange };
}

function pickers(element) {
	return [...element.shadowRoot.querySelectorAll("c-flow-resource-picker")];
}

function menu(element) {
	return pickers(element)[0].shadowRoot;
}

function input(element) {
	return menu(element).querySelector('input[role="combobox"]');
}

function options(element) {
	return [...menu(element).querySelectorAll('[role="option"]')];
}

function optionLabels(element) {
	return options(element).map((option) => option.dataset.label);
}

function crumbs(element) {
	return [...menu(element).querySelectorAll("lightning-breadcrumb")].map((crumb) => crumb.label);
}

function pillLabel(element) {
	return menu(element).querySelector(".slds-pill__label")?.textContent;
}

async function open(element) {
	input(element).dispatchEvent(new CustomEvent("focus"));
	await flush();
}

async function choose(element, label) {
	options(element)
		.find((option) => option.dataset.label === label)
		.click();
	await flush();
}

async function type(element, text) {
	input(element).value = text;
	input(element).dispatchEvent(new CustomEvent("input"));
	await flush();
}

describe("c-soql-field-path", () => {
	beforeEach(() => {
		getFields.mockImplementation(({ objectApiName }) => Promise.resolve(FIELDS[objectApiName] ?? []));
	});

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
		jest.clearAllMocks();
	});

	it("lists relationships to drill into, then fields by label, in one picker", async () => {
		const { element } = await render({ filter: "filterable" });

		expect(pickers(element)).toHaveLength(1);
		expect(pickers(element)[0].label).toBe("Field");
		await open(element);

		const headers = [...menu(element).querySelectorAll(".slds-listbox__option-header")];
		expect(headers.map((header) => header.textContent.trim())).toEqual(["Relationship Fields", "Record Fields"]);
		expect(optionLabels(element).slice(0, 2)).toEqual(["Account", "Account ID"]);
		expect(optionLabels(element)).toContain("Last Name");
		// Long text fields can't filter:
		expect(optionLabels(element)).not.toContain("Contact Description");
		const icons = [...options(element)[0].querySelectorAll("lightning-icon")].map((icon) => icon.iconName);
		expect(icons).toContain("utility:chevronright");
	});

	it("drills through relationships in place, and fires change with the picked field", async () => {
		const { element, onChange } = await render();
		await open(element);

		await choose(element, "Account");
		expect(input(element).value).toBe("Account.");
		expect(crumbs(element)).toEqual(["All Resources", "Account"]);
		expect(onChange).not.toHaveBeenCalled();

		await choose(element, "Owner");
		expect(crumbs(element)).toEqual(["All Resources", "Account", "Owner"]);
		await choose(element, "Full Name");

		expect(onChange.mock.calls.at(-1)[0].detail).toEqual({
			value: "Account.Owner.Name",
			field: expect.objectContaining({ apiName: "Name", label: "Full Name" })
		});
		expect(pickers(element)).toHaveLength(1);
		expect(pillLabel(element)).toBe("Account > Owner > Full Name");
	});

	it("drills and searches as a dotted path is typed", async () => {
		const { element } = await render();
		await open(element);

		await type(element, "Account.Own");

		expect(optionLabels(element)).toEqual(["Owner", "Owner ID"]);
	});

	it("shows a saved path as a pill, and edits it as its API path", async () => {
		const { element } = await render({ value: "Account.Owner.IsActive" });

		expect(pillLabel(element)).toBe("Account > Owner > Active");
		menu(element).querySelector(".picker-pill-edit").click();
		await flush();

		expect(input(element).value).toBe("Account.Owner.IsActive");
	});

	it("picks All Fields of the object or a parent, for stored fields", async () => {
		const { element, onChange } = await render({ value: "Account.*" });
		expect(pillLabel(element)).toBe("Account > All Fields");

		menu(element).querySelector(".picker-pill-remove").click();
		await flush();
		await open(element);
		await choose(element, "All Fields");

		expect(onChange.mock.calls.at(-1)[0].detail).toEqual({ value: "*", field: null });
		expect(pillLabel(element)).toBe("All Fields");
	});

	it("lists All Fields at the top of the menu, without a header", async () => {
		const { element } = await render();
		await open(element);

		const headers = [...menu(element).querySelectorAll(".slds-listbox__option-header")];
		expect(optionLabels(element)[0]).toBe("All Fields");
		expect(headers.map((header) => header.textContent.trim())).toEqual(["Relationship Fields", "Record Fields"]);
	});

	it("hides the fields of levels other rows store in full", async () => {
		const { element } = await render({ coveredPaths: [""] });
		await open(element);

		expect(optionLabels(element)).toEqual(["Account"]);
	});

	it("fires null when the field is cleared", async () => {
		const { element, onChange } = await render({ value: "LastName" });

		menu(element).querySelector(".picker-pill-remove").click();
		await flush();

		expect(onChange.mock.calls.at(-1)[0].detail).toEqual({ value: null, field: null });
	});

	it("shows nothing to pick when an object can't be described", async () => {
		const { element } = await render({ objectApiName: "Missing__c" });
		await open(element);

		expect(options(element)).toHaveLength(0);
		expect(menu(element).querySelector(".picker-empty").textContent).toContain("couldn't find any matching fields");
		input(element).dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowDown" }));
		await flush();
		expect(input(element).getAttribute("aria-activedescendant")).toBeNull();
	});
});
