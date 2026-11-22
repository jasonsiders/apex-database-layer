import { createElement } from "lwc";
import SoqlFieldPath, { getFieldOptions, loadFields, resolveField } from "c/soqlFieldPath";
import getFields from "@salesforce/apex/InvocableSoql.getFields";
import FIELDS from "./data/fields.json";

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

function values(sections) {
	return sections.flatMap((section) => section.items).map((item) => item.value);
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

	describe("getFieldOptions", () => {
		it("offers All Fields first at each level, but not for filtering or sorting", async () => {
			const findAll = ({ sections }) =>
				sections.flatMap((section) => section.items).find((item) => item.value.endsWith("*"));
			const top = await getFieldOptions("Contact", "");
			const account = await getFieldOptions("Contact", "Account");
			const filterable = await getFieldOptions("Contact", "", "filterable");
			const sortable = await getFieldOptions("Contact", "Account", "sortable");

			expect(findAll(top)).toMatchObject({ value: "*", label: "All Fields", isSelectable: true });
			expect(top.sections[1].items[0].value).toBe("*");
			expect(findAll(account)).toMatchObject({ value: "Account.*", pathLabel: "Account > All Fields" });
			expect(findAll(filterable)).toBeUndefined();
			expect(findAll(sortable)).toBeUndefined();
		});

		it("offers only sortable fields for sorting", async () => {
			const { sections } = await getFieldOptions("Contact", "", "sortable");

			expect(values(sections)).not.toContain("Interests__c");
			expect(values(sections)).toContain("Birthdate");
		});

		it("stops offering relationships at SOQL's limit of 6", async () => {
			const fifth = await getFieldOptions("Contact", "Account.Owner.Manager.Manager.Manager");
			const sixth = await getFieldOptions("Contact", "Account.Owner.Manager.Manager.Manager.Manager");
			const seventh = await getFieldOptions("Contact", "Account.Owner.Manager.Manager.Manager.Manager.Manager");

			expect(values(fifth.sections)).toContain("Account.Owner.Manager.Manager.Manager.Manager");
			expect(sixth.parent.pathLabel).toBe("Account > Owner > Manager > Manager > Manager > Manager");
			expect(values(sixth.sections)).toEqual(
				expect.arrayContaining(["Account.Owner.Manager.Manager.Manager.Manager.ManagerId"])
			);
			expect(sixth.sections.flatMap((section) => section.items).some((item) => item.isDrillable)).toBe(false);
			expect(seventh).toEqual({ parent: null, sections: [] });
		});

		it("offers nothing under a path that isn't a relationship", async () => {
			expect(await getFieldOptions("Contact", "Nope")).toEqual({ parent: null, sections: [] });
			expect(await getFieldOptions(null, "")).toEqual({ parent: null, sections: [] });
			getFields.mockImplementationOnce(() => Promise.reject(new Error("No access")));
			expect(values((await getFieldOptions("Secret__c", "")).sections)).toEqual([]);
		});
	});

	describe("resolveField", () => {
		it("follows relationships to a field, and returns null for unknown paths", async () => {
			expect(await resolveField("Contact", "Account.Owner.IsActive")).toMatchObject({ type: "BOOLEAN" });
			expect(await resolveField("Contact", "Nope.Name")).toBeNull();
			expect(await resolveField("Contact", null)).toBeNull();
		});
	});

	describe("loadFields", () => {
		it("describes each object once, and retries one that failed", async () => {
			getFields.mockImplementationOnce(() => Promise.reject(new Error("Unknown")));

			await expect(loadFields("Broken__c")).rejects.toThrow("Unknown");
			await loadFields("Broken__c");
			await loadFields("Broken__c");

			expect(getFields.mock.calls.filter(([args]) => args.objectApiName === "Broken__c")).toHaveLength(2);
		});
	});
});
