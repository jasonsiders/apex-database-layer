import { getFieldOptions, loadFields, resolveField } from "c/soqlFieldMenu";
import getFields from "@salesforce/apex/InvocableSoql.getFields";
import FIELDS from "./data/fields.json";

jest.mock("@salesforce/apex/InvocableSoql.getFields", () => ({ default: jest.fn() }), { virtual: true });

function values(sections) {
	return sections.flatMap((section) => section.items).map((item) => item.value);
}

beforeEach(() => {
	getFields.mockImplementation(({ objectApiName }) => Promise.resolve(FIELDS[objectApiName] ?? []));
});

afterEach(() => {
	jest.clearAllMocks();
});

describe("getFieldOptions", () => {
	it("offers All Fields at the top of each level, but not for filtering or sorting", async () => {
		const findAll = ({ sections }) =>
			sections.flatMap((section) => section.items).find((item) => item.value.endsWith("*"));
		const top = await getFieldOptions("Contact", "");
		const account = await getFieldOptions("Contact", "Account");
		const filterable = await getFieldOptions("Contact", "", "filterable");
		const sortable = await getFieldOptions("Contact", "Account", "sortable");

		expect(findAll(top)).toMatchObject({ value: "*", label: "All Fields", isSelectable: true });
		expect(top.sections[0].items.map((item) => item.value)).toEqual(["*"]);
		expect(findAll(account)).toMatchObject({ value: "Account.*", pathLabel: "Account ID > All Fields" });
		expect(findAll(filterable)).toBeUndefined();
		expect(findAll(sortable)).toBeUndefined();
	});

	it("offers only relationships on a level whose fields are all stored", async () => {
		const covered = await getFieldOptions("Contact", "", null, [""]);
		const parent = await getFieldOptions("Contact", "Account", null, [""]);

		expect(values(covered.sections)).toEqual(["AccountId"]);
		expect(covered.sections[1].items[0]).toMatchObject({ isDrillable: true, isSelectable: false });
		expect(values(parent.sections)).toContain("Account.*");
	});

	it("offers each lookup once, by its label, to select its ID or drill into its object", async () => {
		const { sections } = await getFieldOptions("Contact", "");
		const account = await getFieldOptions("Contact", "Account");

		expect(sections[1].items).toEqual([
			expect.objectContaining({
				value: "AccountId",
				drillValue: "Account",
				label: "Account ID",
				pathLabel: "Account ID",
				isSelectable: true,
				isDrillable: true
			})
		]);
		expect(account.parent).toEqual({ value: "Account", pathLabel: "Account ID" });
		expect(values(account.sections)).toContain("Account.OwnerId");
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

		const drillValues = (sections) => sections.flatMap((section) => section.items).map((item) => item.drillValue);
		expect(drillValues(fifth.sections)).toContain("Account.Owner.Manager.Manager.Manager.Manager");
		expect(sixth.parent.pathLabel).toBe(
			"Account ID > Owner ID > Manager ID > Manager ID > Manager ID > Manager ID"
		);
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
