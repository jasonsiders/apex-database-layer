import { createElement } from "lwc";
import SoqlFieldPath, { loadFields, resolveField } from "c/soqlFieldPath";
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

function steps(element) {
	return [...element.shadowRoot.querySelectorAll("c-flow-resource-picker")];
}

async function pick(element, index, value) {
	steps(element)[index].dispatchEvent(new CustomEvent("change", { detail: { value, valueDataType: "String" } }));
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

	it("lists relationships to drill into, then fields, by API name", async () => {
		const { element } = await render({ filter: "filterable" });

		const [step] = steps(element);
		const values = step.picklistValues.map((option) => option.value);
		expect(values[0]).toBe("Account >");
		expect(values).toContain("LastName");
		// Long text fields can't filter:
		expect(values).not.toContain("Description");
		expect(step.label).toBe("Field");
		expect(step.isPicklistOnly).toBe(true);
	});

	it("drills through relationships, and fires change once a field is picked", async () => {
		const { element, onChange } = await render();

		await pick(element, 0, "Account >");
		expect(onChange).not.toHaveBeenCalled();
		expect(steps(element)).toHaveLength(2);
		expect(steps(element)[1].variant).toBe("label-hidden");

		await pick(element, 1, "Owner >");
		await pick(element, 2, "Name");

		expect(onChange.mock.calls.at(-1)[0].detail).toEqual({
			value: "Account.Owner.Name",
			field: expect.objectContaining({ apiName: "Name", label: "Full Name" })
		});
	});

	it("shows a saved path as one step per relationship", async () => {
		const { element } = await render({ value: "Account.Owner.Name" });

		expect(steps(element).map((step) => step.value)).toEqual(["Account >", "Owner >", "Name"]);
	});

	it("drops later steps when an earlier one changes, and fires null when the path is cleared", async () => {
		const { element, onChange } = await render({ value: "Account.Name" });

		await pick(element, 0, "LastName");
		expect(steps(element)).toHaveLength(1);
		expect(onChange.mock.calls.at(-1)[0].detail).toMatchObject({ value: "LastName" });

		await pick(element, 0, null);
		expect(onChange.mock.calls.at(-1)[0].detail).toEqual({ value: null, field: null });
	});

	it("shows only sortable fields for sorting", async () => {
		const { element } = await render({ filter: "sortable" });

		const values = steps(element)[0].picklistValues.map((option) => option.value);
		expect(values).not.toContain("Interests__c");
		expect(values).toContain("Birthdate");
	});

	it("shows nothing to pick when an object can't be described", async () => {
		const { element } = await render({ objectApiName: "Missing__c" });

		expect(steps(element)[0].picklistValues).toEqual([]);
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
