import { filterSections, getChildSections, getRootSections, parseInput, resolveItem } from "c/flowResourceMenu";
import CONTEXT from "./data/context.json";
import ACCOUNT from "./data/accountDescribe.json";
import USER from "./data/userDescribe.json";

const DESCRIBES = { Account: ACCOUNT, User: USER };
const describeObject = jest.fn((objectApiName) => Promise.resolve(DESCRIBES[objectApiName]));
const context = { ...CONTEXT, objectLabels: { Account: { label: "Account", labelPlural: "Accounts" } } };

const BOOLEAN = { dataType: "Boolean" };
const RECORD = { dataType: "SObject", isCollection: false };
const RECORDS = { dataType: "SObject", isCollection: true };
const TEXT = { dataType: "String" };

function labelsBySection(sections) {
	return Object.fromEntries(sections.map((section) => [section.label, section.items.map((item) => item.label)]));
}

function findItem(sections, value) {
	return sections.flatMap((section) => section.items).find((item) => item.value === value);
}

describe("c-flow-resource-menu", () => {
	describe("getRootSections", () => {
		it("lists every scalar resource for a text input, in Flow Builder's order", () => {
			const sections = getRootSections(context, TEXT);

			expect(labelsBySection(sections)).toEqual({
				"Quick Resources": ["Current Item from Loop Loop Accounts"],
				Action: ["Outputs from Insert Spike"],
				Choices: ["choiceA"],
				Constants: ["constText"],
				Formulas: ["formulaBool"],
				"Record Variables": ["accountVar", "contactVar"],
				"Screen Components": ["agreeBox", "nameInput"],
				"Simple Variables": ["boolVar", "textVar"],
				Stages: ["Stage One"],
				"Text Templates": ["tmplText"],
				"Global Constants": ["False", "True", "Blank Value (Empty String)"],
				"Global Variables": [
					"API",
					"Running Flow Interview",
					"Running Org",
					"Running User",
					"Running User Profile",
					"Running User Role",
					"System"
				]
			});
		});

		it("lists only boolean resources, and containers of them, for a boolean input", () => {
			const sections = getRootSections(context, BOOLEAN);

			expect(labelsBySection(sections)).toEqual({
				"Quick Resources": ["Current Item from Loop Loop Accounts"],
				Action: ["Outputs from Insert Spike"],
				Formulas: ["formulaBool"],
				"Record Variables": ["accountVar", "contactVar"],
				"Screen Components": ["agreeBox"],
				"Simple Variables": ["boolVar"],
				"Global Constants": ["False", "True"],
				"Global Variables": ["Running User", "Running User Profile", "Running User Role"]
			});
		});

		it("makes records selectable, not drillable, for a record input", () => {
			const sections = getRootSections(context, RECORD);

			expect(labelsBySection(sections)).toEqual({
				"Quick Resources": ["Current Item from Loop Loop Accounts"],
				Action: ["Outputs from Insert Spike"],
				"Record Variables": ["accountVar", "contactVar"]
			});
			const accountVar = findItem(sections, "accountVar");
			expect(accountVar).toMatchObject({ isSelectable: true, isDrillable: false, objectType: "Account" });
			expect(findItem(sections, "Insert_Spike")).toMatchObject({ isSelectable: false, isDrillable: true });
		});

		it("lists record collections for a record collection input", () => {
			const sections = getRootSections(context, RECORDS);

			expect(labelsBySection(sections)).toEqual({
				Action: ["Outputs from Insert Spike"],
				"Get Records": ["Accounts from Get Accounts"],
				"Record Collections": ["accountsVar"]
			});
			expect(findItem(sections, "Get_Accounts")).toMatchObject({
				icon: "utility:record_collection",
				isCollection: true,
				objectType: "Account"
			});
		});

		it("restricts records to the input's object, when it has one", () => {
			const sections = getRootSections(context, { ...RECORD, objectType: "Contact" });

			expect(labelsBySection(sections)).toEqual({ "Record Variables": ["contactVar"] });
		});

		it("lists picklist values first, as literals", () => {
			const picklistValues = [
				{ label: "User Mode", value: "USER_MODE" },
				{ label: "System Mode", value: "SYSTEM_MODE" }
			];
			const sections = getRootSections(context, { ...TEXT, picklistValues });

			expect(sections[0].label).toBe("Picklist Values");
			expect(sections[0].items).toEqual([
				expect.objectContaining({
					label: "User Mode",
					value: "USER_MODE",
					isLiteral: true,
					isSelectable: true
				}),
				expect.objectContaining({
					label: "System Mode",
					value: "SYSTEM_MODE",
					isLiteral: true,
					isSelectable: true
				})
			]);
		});

		it("falls back to the object's API name when its labels aren't known yet", () => {
			const sections = getRootSections({ ...context, objectLabels: {} }, RECORDS);

			expect(findItem(sections, "Get_Accounts").label).toBe("Account from Get Accounts");
		});

		it("types a loop's current item from the action output it iterates over", () => {
			const loops = [
				{ name: "Loop_Outputs", label: "Loop Outputs", collectionReference: "Insert_Spike.recordCollection" }
			];
			const builderContext = { ...context.builderContext, loops };

			const sections = getRootSections({ ...context, builderContext }, RECORD);

			expect(findItem(sections, "Loop_Outputs")).toMatchObject({ objectType: "Account", isSelectable: true });
		});

		it("handles an empty builder context", () => {
			const sections = getRootSections({ builderContext: {}, automaticOutputVariables: {} }, TEXT);

			expect(sections.map((section) => section.label)).toEqual(["Global Constants", "Global Variables"]);
		});
	});

	describe("position in the flow", () => {
		it("lists outputs only from elements that can run before the one being edited", () => {
			const sections = labelsBySection(getRootSections({ ...context, elementName: "Create_Native" }, TEXT));

			expect(sections.Action).toEqual(["Outputs from Insert Spike"]);
			expect(sections["Quick Resources"]).toBeUndefined();
			expect(sections["Screen Components"]).toBeUndefined();
		});

		it("lists a loop's current item, and the element's own outputs, inside the loop", () => {
			const sections = labelsBySection(getRootSections({ ...context, elementName: "Insert_Spike" }, TEXT));

			expect(sections["Quick Resources"]).toEqual(["Current Item from Loop Loop Accounts"]);
			expect(sections.Action).toEqual(["Outputs from Insert Spike"]);
		});

		it("omits an element's own outputs when it can't run twice", () => {
			const sections = labelsBySection(getRootSections({ ...context, elementName: "Get_Accounts" }, RECORDS));

			expect(sections).toEqual({ "Record Collections": ["accountsVar"] });
		});

		it("follows scheduled paths, decision outcomes, and wait events", () => {
			const builderContext = {
				start: { scheduledPaths: [{ connector: { targetReference: "Act" } }] },
				actionCalls: [
					{
						name: "Act",
						label: "Act",
						storeOutputAutomatically: true,
						connector: { targetReference: "Decide" }
					}
				],
				decisions: [{ name: "Decide", rules: [{ connector: { targetReference: "Hold" } }] }],
				waits: [{ name: "Hold", waitEvents: [{ connector: { targetReference: "Target" } }] }],
				recordCreates: [{ name: "Target" }]
			};
			const automaticOutputVariables = {
				Act: [{ name: "message", label: "Message", dataType: "string", maxOccurs: 1 }]
			};

			const sections = getRootSections({ builderContext, automaticOutputVariables, elementName: "Target" }, TEXT);

			expect(labelsBySection(sections).Action).toEqual(["Outputs from Act"]);
		});

		it("offers the triggering record, and its prior values, in record-triggered flows", () => {
			const start = {
				...context.builderContext.start,
				object: "Account",
				triggerType: "RecordAfterSave",
				recordTriggerType: "CreateAndUpdate"
			};
			const builderContext = { ...context.builderContext, start };

			const sections = getRootSections({ ...context, builderContext, elementName: "Create_Native" }, RECORD);

			expect(labelsBySection(sections)["Quick Resources"]).toEqual([
				"Triggering Account",
				"Prior Values of Triggering Account"
			]);
			expect(findItem(sections, "$Record")).toMatchObject({
				objectType: "Account",
				icon: "utility:record_alt",
				isSelectable: true
			});
		});

		it("omits prior values when records are only created", async () => {
			const start = { object: "Account", triggerType: "RecordAfterSave", recordTriggerType: "Create" };
			const builderContext = { ...context.builderContext, start };

			const sections = getRootSections({ ...context, builderContext, objectLabels: {} }, TEXT);

			expect(labelsBySection(sections)["Quick Resources"]).toEqual([
				"Triggering Account",
				"Current Item from Loop Loop Accounts"
			]);
			const item = await resolveItem("$Record.Name", { ...context, builderContext }, describeObject);
			expect(item).toMatchObject({ pathLabel: "$Record > Account Name" });
		});
	});

	describe("getChildSections", () => {
		it("lists a record's relationship fields, then its fields sorted by type and label", async () => {
			const accountVar = findItem(getRootSections(context, TEXT), "accountVar");

			const sections = await getChildSections(accountVar, context, TEXT, describeObject);

			expect(labelsBySection(sections)).toEqual({
				"Relationship Fields": ["Owner ID", "Parent Account ID", "Owner ID", "Parent Account ID"],
				"Record Fields": [
					"Deleted",
					"Annual Revenue",
					"Last Activity",
					"Created Date",
					"Employees",
					"Industry",
					"Account ID",
					"Account Name"
				]
			});
			expect(sections[0].items[0]).toMatchObject({
				value: "accountVar.Owner",
				objectType: "User",
				isDrillable: true,
				isSelectable: false,
				pathLabel: "accountVar > Owner ID"
			});
			expect(sections[0].items[2]).toMatchObject({
				value: "accountVar.OwnerId",
				icon: "utility:text",
				isSelectable: true
			});
			expect(findItem(sections, "accountVar.IsDeleted")).toMatchObject({
				dataType: "Boolean",
				icon: "utility:toggle"
			});
		});

		it("lists only matching fields, and relationships, for a boolean input", async () => {
			const accountVar = findItem(getRootSections(context, BOOLEAN), "accountVar");

			const sections = await getChildSections(accountVar, context, BOOLEAN, describeObject);

			expect(labelsBySection(sections)).toEqual({
				"Relationship Fields": ["Owner ID", "Parent Account ID"],
				"Record Fields": ["Deleted"]
			});
		});

		it("lists an action's outputs", async () => {
			const action = findItem(getRootSections(context, TEXT), "Insert_Spike");

			const sections = await getChildSections(action, context, TEXT, describeObject);

			expect(labelsBySection(sections)).toEqual({ Outputs: ["Record", "Message"] });
			expect(findItem(sections, "Insert_Spike.record")).toMatchObject({
				isDrillable: true,
				objectType: "Account"
			});
			expect(findItem(sections, "Insert_Spike.message")).toMatchObject({
				isSelectable: true,
				pathLabel: "Outputs from Insert Spike > Message"
			});
		});

		it("lists an action's record outputs for a record input", async () => {
			const action = findItem(getRootSections(context, RECORDS), "Insert_Spike");

			const sections = await getChildSections(action, context, RECORDS, describeObject);

			expect(labelsBySection(sections)).toEqual({ Outputs: ["Record Collection"] });
		});

		it("lists a global variable's fields", async () => {
			const user = findItem(getRootSections(context, TEXT), "$User");

			const sections = await getChildSections(user, context, BOOLEAN, describeObject);

			expect(labelsBySection(sections)).toEqual({ "Running User": ["IsActive"] });
			expect(sections[0].items[0]).toMatchObject({ value: "$User.IsActive", pathLabel: "$User > IsActive" });
		});

		it("lists every $Api endpoint", async () => {
			const api = findItem(getRootSections(context, TEXT), "$Api");

			const sections = await getChildSections(api, context, TEXT, describeObject);

			const values = sections[0].items.map((item) => item.value);
			expect(values).toContain("$Api.Enterprise_Server_URL_25");
			expect(values).toContain("$Api.Partner_Server_URL_680");
			expect(values).toHaveLength(136);
		});

		it("returns nothing for items that can't be drilled into", async () => {
			const textVar = findItem(getRootSections(context, TEXT), "textVar");

			expect(await getChildSections(textVar, context, TEXT, describeObject)).toEqual([]);
		});
	});

	describe("filterSections", () => {
		it("matches labels and values, ignoring case, and drops empty sections", () => {
			const sections = filterSections(getRootSections(context, TEXT), "ACC");

			expect(labelsBySection(sections)).toEqual({
				"Quick Resources": ["Current Item from Loop Loop Accounts"],
				"Record Variables": ["accountVar"]
			});
		});

		it("finds global resources by their $ prefix", () => {
			const sections = filterSections(getRootSections(context, BOOLEAN), "$");

			expect(sections.map((section) => section.label)).toEqual(["Global Constants", "Global Variables"]);
		});

		it("returns every section for a blank search", () => {
			const sections = getRootSections(context, TEXT);

			expect(filterSections(sections, "")).toEqual(sections);
		});
	});

	describe("resolveItem", () => {
		it("resolves a drilled reference, with labels for each step", async () => {
			const item = await resolveItem("accountVar.Owner.Email", context, describeObject);

			expect(item).toMatchObject({
				value: "accountVar.Owner.Email",
				pathLabel: "accountVar > Owner ID > Email",
				icon: "utility:text"
			});
		});

		it("resolves global constants and variables", async () => {
			expect(await resolveItem("$GlobalConstant.True", context, describeObject)).toMatchObject({
				pathLabel: "True"
			});
			expect(await resolveItem("$User.Email", context, describeObject)).toMatchObject({
				pathLabel: "$User > Email"
			});
		});

		it("returns null for unknown references", async () => {
			expect(await resolveItem("missingVar", context, describeObject)).toBeNull();
			expect(await resolveItem("accountVar.Missing__c", context, describeObject)).toBeNull();
			expect(await resolveItem("textVar.Length", context, describeObject)).toBeNull();
		});
	});

	describe("parseInput", () => {
		it("splits a partial merge field into its parent path and search term", () => {
			expect(parseInput("{!accountVar.Owner.Em")).toEqual({
				isReference: true,
				isComplete: false,
				parentPath: "accountVar.Owner",
				searchTerm: "Em"
			});
			expect(parseInput("{!acc")).toEqual({
				isReference: true,
				isComplete: false,
				parentPath: "",
				searchTerm: "acc"
			});
		});

		it("recognizes a complete merge field", () => {
			expect(parseInput(" {!accountVar.Name} ")).toEqual({
				isReference: true,
				isComplete: true,
				path: "accountVar.Name"
			});
		});

		it("treats anything else as a search term", () => {
			expect(parseInput("hello")).toEqual({
				isReference: false,
				isComplete: false,
				parentPath: "",
				searchTerm: "hello"
			});
			expect(parseInput(undefined)).toEqual({
				isReference: false,
				isComplete: false,
				parentPath: "",
				searchTerm: ""
			});
		});
	});
});
