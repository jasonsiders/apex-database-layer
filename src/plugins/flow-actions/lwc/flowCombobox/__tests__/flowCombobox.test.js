import { createElement } from "lwc";
import FlowCombobox from "c/flowCombobox";
import describeSObjectFields from "@salesforce/apex/InvocableSoql.describeSObjectFields";

jest.mock("@salesforce/apex/InvocableSoql.describeSObjectFields", () => ({ default: jest.fn() }), {
	virtual: true
});

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-flow-combobox", () => {
	function createComponent(props = {}) {
		const element = createElement("c-flow-combobox", { is: FlowCombobox });
		Object.assign(element, props);
		document.body.appendChild(element);
		return element;
	}

	function getTextInput(element) {
		return (
			element.shadowRoot.querySelector('[data-id="resource-input"]') ??
			element.shadowRoot.querySelector("lightning-input")
		);
	}

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
		jest.clearAllMocks();
	});

	it("shows grouped resource options when the searchable input is focused with an empty query", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			resourceOptions: [
				{
					label: "Variable: record",
					value: "{!record}",
					pillLabel: "record",
					referenceName: "record",
					objectType: "Account"
				},
				{
					label: "Variable: accountRecord",
					value: "{!accountRecord}",
					pillLabel: "accountRecord",
					referenceName: "accountRecord",
					dataType: "String"
				}
			]
		});

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();

		const sections = [...element.shadowRoot.querySelectorAll(".resource-section-title")].map((section) =>
			section.textContent.trim()
		);
		expect(sections).toEqual(["Record Variables", "Variables"]);
		expect(element.shadowRoot.querySelectorAll(".resource-option")).toHaveLength(2);
		expect(element.shadowRoot.querySelector(".resource-combobox").className).toContain("slds-is-open");
	});

	it("filters resource options inline as text is entered", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			resourceOptions: [
				{ label: "Variable: record", value: "{!record}", pillLabel: "record", referenceName: "record" },
				{
					label: "Variable: accountRecord",
					value: "{!accountRecord}",
					pillLabel: "accountRecord",
					referenceName: "accountRecord"
				}
			]
		});

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		input.value = "acc";
		input.dispatchEvent(new Event("input"));
		await Promise.resolve();

		const options = [...element.shadowRoot.querySelectorAll(".resource-option")];
		expect(options).toHaveLength(1);
		expect(element.shadowRoot.querySelector(".resource-dropdown-header").textContent).toContain("All Resources");
		expect(element.shadowRoot.querySelector(".resource-section-title").textContent).toContain("Variables");
		expect(options[0].textContent).toContain("accountRecord");
	});

	it("shows literal values alongside compatible resources for picklist fields", async () => {
		const element = createComponent({
			name: "localeOptions",
			label: "Locale",
			fieldDataType: "String",
			inputType: "picklist",
			included: true,
			options: [
				{ label: "en_US", value: "en_US" },
				{ label: "fr_FR", value: "fr_FR" }
			],
			resourceOptions: [
				{
					label: "Variable: localeVar",
					value: "{!localeVar}",
					pillLabel: "localeVar",
					referenceName: "localeVar",
					dataType: "String"
				}
			]
		});

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();

		const sections = [...element.shadowRoot.querySelectorAll(".resource-section-title")].map((section) =>
			section.textContent.trim()
		);
		expect(element.shadowRoot.querySelector(".resource-dropdown-header").textContent).toContain(
			"All Values and Resources"
		);
		expect(sections).toEqual(["Values", "Variables"]);
		expect(element.shadowRoot.querySelectorAll(".resource-option")).toHaveLength(3);
	});

	it("uses the picklist icon for picklist literal values", async () => {
		const element = createComponent({
			name: "localeOptions",
			label: "Locale",
			fieldDataType: "String",
			inputType: "picklist",
			included: true,
			options: [{ label: "en_US", value: "en_US" }]
		});

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();

		expect(element.shadowRoot.querySelector(".resource-option lightning-icon").iconName).toBe(
			"utility:picklist_type"
		);
	});

	it("keeps matching picklist values visible while typing a partial search", async () => {
		const element = createComponent({
			name: "accessLevelName",
			label: "Access Level",
			fieldDataType: "String",
			inputType: "picklist",
			included: true,
			options: [
				{ label: "User Mode", value: "USER_MODE" },
				{ label: "System Mode", value: "SYSTEM_MODE" }
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		input.value = "user";
		input.dispatchEvent(new Event("input"));
		input.dispatchEvent(new Event("change"));
		await Promise.resolve();

		expect(handler).not.toHaveBeenCalled();
		expect(element.classList.contains("resource-picker-open")).toBe(true);
		expect(element.shadowRoot.querySelector(".resource-option").textContent).toContain("User Mode");
	});

	it("accepts unmatched picklist search text as a raw literal on blur", async () => {
		const element = createComponent({
			name: "accessLevelName",
			label: "Access Level",
			fieldDataType: "String",
			inputType: "picklist",
			included: true,
			options: [
				{ label: "User Mode", value: "USER_MODE" },
				{ label: "System Mode", value: "SYSTEM_MODE" }
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		input.value = "user";
		input.dispatchEvent(new Event("input"));
		input.dispatchEvent(new CustomEvent("blur"));
		await Promise.resolve();

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "accessLevelName",
			value: "user",
			valueDataType: "String"
		});
		expect(getTextInput(element).value).toBe("user");
		expect(element.classList.contains("resource-picker-open")).toBe(false);
	});

	it("emits a reference value when a filtered resource is selected", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			resourceOptions: [
				{ label: "Variable: record", value: "{!record}", pillLabel: "record", referenceName: "record" }
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();

		element.shadowRoot.querySelector(".resource-option").click();
		await Promise.resolve();

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "record",
			value: "{!record}",
			valueDataType: "reference"
		});
		expect(element.shadowRoot.querySelector(".selected-resource-pill .slds-pill__label").textContent).toBe(
			"record"
		);
		expect(element.classList.contains("resource-picker-open")).toBe(false);
	});

	it("keeps a clicked resource selection from being overwritten by the typed search text", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			resourceOptions: [
				{ label: "Variable: record", value: "{!record}", pillLabel: "record", referenceName: "record" }
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		input.value = "record";
		input.dispatchEvent(new Event("input"));
		await Promise.resolve();

		const option = element.shadowRoot.querySelector(".resource-option");
		option.dispatchEvent(new MouseEvent("mousedown", { bubbles: true }));
		input.dispatchEvent(new Event("change"));
		option.click();
		await Promise.resolve();

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "record",
			value: "{!record}",
			valueDataType: "reference"
		});
	});

	it("shows only flow resources in the boolean dropdown", async () => {
		const element = createComponent({
			name: "allOrNone",
			label: "All Or None",
			fieldDataType: "Boolean",
			inputType: "boolean",
			included: true,
			options: [
				{ label: "True", value: "true" },
				{ label: "False", value: "false" }
			],
			resourceOptions: [
				{
					label: "Global Constant: True",
					value: "{!$GlobalConstant.True}",
					pillLabel: "$GlobalConstant.True",
					referenceName: "$GlobalConstant.True",
					dataType: "Boolean"
				}
			]
		});

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();

		expect(element.shadowRoot.querySelector(".resource-dropdown-header").textContent).toContain("All Resources");
		expect(
			[...element.shadowRoot.querySelectorAll(".resource-section-title")].map((section) =>
				section.textContent.trim()
			)
		).toEqual(["Global Constants"]);
		expect(element.shadowRoot.querySelector(".resource-option").textContent).toContain("True");
	});

	it("handles non-string field values when filtering resource options", async () => {
		const element = createComponent({
			name: "useDefaultRule",
			label: "Use Default Rule",
			fieldDataType: "Boolean",
			inputType: "boolean",
			value: false,
			included: true,
			resourceOptions: [
				{
					label: "Global Constant: False",
					value: "{!$GlobalConstant.False}",
					pillLabel: "$GlobalConstant.False",
					referenceName: "$GlobalConstant.False",
					dataType: "Boolean"
				}
			]
		});

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();

		expect(element.shadowRoot.querySelector(".resource-dropdown")).not.toBeNull();
		expect(element.shadowRoot.querySelector(".resource-option").textContent).toContain("False");
	});

	it("emits a literal value when the searchable input is blurred without selecting a resource", async () => {
		const element = createComponent({
			name: "ownerId",
			label: "Owner ID",
			fieldDataType: "String",
			included: true,
			resourceOptions: [
				{ label: "Variable: userId", value: "{!userId}", pillLabel: "userId", referenceName: "userId" }
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		const input = getTextInput(element);
		input.value = "005-test";
		input.dispatchEvent(new Event("input"));
		input.dispatchEvent(new CustomEvent("blur"));

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "ownerId",
			value: "005-test",
			valueDataType: "String"
		});
	});

	it("shows an empty-state row when no resources match the current input", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			resourceOptions: [
				{ label: "Variable: record", value: "{!record}", pillLabel: "record", referenceName: "record" }
			]
		});

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		input.value = "nomatch";
		input.dispatchEvent(new Event("input"));
		await Promise.resolve();

		expect(element.shadowRoot.querySelector(".resource-empty")).not.toBeNull();
		expect(element.shadowRoot.querySelector(".resource-empty").textContent).toContain(
			"No matching values or resources"
		);
	});

	it("renders resources that use an unrecognized category key", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			resourceOptions: [
				{
					label: "Variable: record",
					value: "{!record}",
					pillLabel: "record",
					referenceName: "record",
					category: "recordVariable"
				}
			]
		});

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();

		expect(element.shadowRoot.querySelector(".resource-section-title").textContent).toContain("Record Variable");
		expect(element.shadowRoot.querySelector(".resource-option").textContent).toContain("record");
	});

	it("closes the resource dropdown on blur and raises the host stacking context only while it is open", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			resourceOptions: [
				{ label: "Variable: record", value: "{!record}", pillLabel: "record", referenceName: "record" }
			]
		});

		const input = getTextInput(element);
		input.dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();
		expect(element.classList.contains("resource-picker-open")).toBe(true);
		expect(element.shadowRoot.querySelector(".resource-dropdown")).not.toBeNull();

		input.dispatchEvent(new CustomEvent("blur"));
		await Promise.resolve();
		expect(element.classList.contains("resource-picker-open")).toBe(false);
		expect(element.shadowRoot.querySelector(".resource-dropdown")).toBeNull();
	});

	it("renders a type-specific icon as the type marker", () => {
		const element = createComponent({ name: "f", label: "F", fieldDataType: "Boolean", included: true });
		expect(element.shadowRoot.querySelector(".type-marker-icon")).not.toBeNull();
		expect(element.shadowRoot.querySelector(".type-marker-icon").iconName).toBe("utility:toggle");
		expect(element.shadowRoot.querySelector(".type-marker")).toBeNull();
	});

	it("shows a drillable chevron for SObject resources and none for scalar resources", async () => {
		const element = createComponent({
			name: "rec",
			label: "Rec",
			included: true,
			resourceOptions: [
				{
					label: "Variable: record",
					value: "{!record}",
					pillLabel: "record",
					referenceName: "record",
					objectType: "Account"
				},
				{
					label: "Variable: textVar",
					value: "{!textVar}",
					pillLabel: "textVar",
					referenceName: "textVar",
					dataType: "String"
				}
			]
		});
		getTextInput(element).dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();
		const options = element.shadowRoot.querySelectorAll(".resource-option");
		expect(options[0].querySelector(".resource-option-chevron")).not.toBeNull();
		expect(options[1].querySelector(".resource-option-chevron")).toBeNull();
	});

	it("drills into non-selectable SObject resources and emits the selected field reference", async () => {
		const element = createComponent({
			name: "value",
			label: "Value",
			fieldDataType: "String",
			included: true,
			resourceOptions: [
				{
					label: "Variable: opp",
					value: "{!opp}",
					pillLabel: "opp",
					referenceName: "opp",
					dataType: "SObject",
					isDrillable: true,
					isSelectable: false
				},
				{
					label: "Field: opp.Name",
					value: "{!opp.Name}",
					pillLabel: "opp.Name",
					referenceName: "opp.Name",
					displayLabel: "opp.Name",
					dataType: "String",
					category: "recordFields",
					parentReferenceName: "opp",
					parentObjectType: "Opportunity"
				},
				{
					label: "Variable: accountName",
					value: "{!accountName}",
					pillLabel: "accountName",
					referenceName: "accountName",
					dataType: "String"
				}
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		getTextInput(element).dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();

		const rootOptions = [...element.shadowRoot.querySelectorAll(".resource-option")].map((option) =>
			option.textContent.trim()
		);
		expect(rootOptions.join(" ")).toContain("opp");
		expect(rootOptions.join(" ")).toContain("accountName");
		expect(rootOptions.join(" ")).not.toContain("opp.Name");

		element.shadowRoot.querySelector(".resource-option").click();
		await Promise.resolve();

		expect(handler).not.toHaveBeenCalled();
		expect(element.shadowRoot.querySelector(".resource-dropdown-header").textContent).toContain(
			"All Resources > opp"
		);
		expect(element.shadowRoot.querySelector(".resource-option").textContent).toContain("opp.Name");

		element.shadowRoot.querySelector(".resource-option").click();
		await Promise.resolve();

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "value",
			value: "{!opp.Name}",
			valueDataType: "reference"
		});
	});

	it("loads SObject fields when a drillable resource has no preloaded child options", async () => {
		describeSObjectFields.mockResolvedValueOnce([
			{ name: "Name", label: "Account Name", dataType: "String" },
			{ name: "CreatedDate", label: "Created Date", dataType: "DateTime" }
		]);
		const element = createComponent({
			name: "value",
			label: "Value",
			fieldDataType: "String",
			included: true,
			resourceOptions: [
				{
					label: "Variable: account",
					value: "{!account}",
					pillLabel: "account",
					referenceName: "account",
					objectType: "Account",
					dataType: "SObject",
					isSelectable: false
				}
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		getTextInput(element).dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();
		element.shadowRoot.querySelector(".resource-option").click();
		await flushPromises();

		expect(describeSObjectFields).toHaveBeenCalledWith({ objectApiName: "Account" });
		const optionText = [...element.shadowRoot.querySelectorAll(".resource-option")]
			.map((option) => option.textContent)
			.join(" ");
		expect(optionText).toContain("Account Name");
		expect(optionText).not.toContain("Created Date");

		element.shadowRoot.querySelector(".resource-option").click();
		await Promise.resolve();

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "value",
			value: "{!account.Name}",
			valueDataType: "reference"
		});
	});

	it("selects lookup IDs from relationship field rows", async () => {
		describeSObjectFields.mockResolvedValueOnce([
			{
				name: "AccountId",
				label: "Account ID",
				dataType: "String",
				relationshipName: "Account",
				relationshipObjectType: "Account",
				relationshipObjectTypes: ["Account"]
			}
		]);
		const element = createComponent({
			name: "value",
			label: "Value",
			fieldDataType: "String",
			included: true,
			resourceOptions: [
				{
					label: "Variable: opp",
					value: "{!opp}",
					pillLabel: "opp",
					referenceName: "opp",
					objectType: "Opportunity",
					dataType: "SObject",
					isSelectable: false
				}
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		getTextInput(element).dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();
		element.shadowRoot.querySelector(".resource-option").click();
		await flushPromises();

		element.shadowRoot.querySelector(".resource-option").click();
		await Promise.resolve();

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "value",
			value: "{!opp.AccountId}",
			valueDataType: "reference"
		});
	});

	it("drills through relationship fields and emits grandparent field references", async () => {
		describeSObjectFields
			.mockResolvedValueOnce([
				{
					name: "AccountId",
					label: "Account ID",
					dataType: "String",
					relationshipName: "Account",
					relationshipObjectType: "Account",
					relationshipObjectTypes: ["Account"]
				}
			])
			.mockResolvedValueOnce([{ name: "Name", label: "Account Name", dataType: "String" }]);
		const element = createComponent({
			name: "value",
			label: "Value",
			fieldDataType: "String",
			included: true,
			resourceOptions: [
				{
					label: "Variable: opp",
					value: "{!opp}",
					pillLabel: "opp",
					referenceName: "opp",
					objectType: "Opportunity",
					dataType: "SObject",
					isSelectable: false
				}
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		getTextInput(element).dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();
		element.shadowRoot.querySelector(".resource-option").click();
		await flushPromises();

		const relationshipOption = element.shadowRoot.querySelector(".resource-option");
		expect(relationshipOption.textContent).toContain("Account ID");
		expect(relationshipOption.querySelector(".resource-option-chevron")).not.toBeNull();

		relationshipOption.querySelector(".resource-option-chevron").click();
		await flushPromises();

		expect(describeSObjectFields).toHaveBeenNthCalledWith(1, { objectApiName: "Opportunity" });
		expect(describeSObjectFields).toHaveBeenNthCalledWith(2, { objectApiName: "Account" });
		expect(element.shadowRoot.querySelector(".resource-dropdown-header").textContent).toContain(
			"All Resources > Account ID"
		);
		expect(element.shadowRoot.querySelector(".resource-option").textContent).toContain("Account Name");
		expect(element.shadowRoot.querySelector(".resource-option .slds-truncate").title).toBe("{!opp.Account.Name}");

		element.shadowRoot.querySelector(".resource-option").click();
		await Promise.resolve();

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "value",
			value: "{!opp.Account.Name}",
			valueDataType: "reference"
		});
		expect(element.shadowRoot.querySelector(".selected-resource-pill").title).toBe("{!opp.Account.Name}");
	});

	it("accepts a typed relationship reference and converts it to a selected resource pill", async () => {
		describeSObjectFields
			.mockResolvedValueOnce([
				{
					name: "AccountId",
					label: "Account ID",
					dataType: "String",
					relationshipName: "Account",
					relationshipObjectType: "Account",
					relationshipObjectTypes: ["Account"]
				}
			])
			.mockResolvedValueOnce([{ name: "Name", label: "Account Name", dataType: "String" }]);
		const element = createComponent({
			name: "value",
			label: "Value",
			fieldDataType: "String",
			included: true,
			resourceOptions: [
				{
					label: "Variable: opp",
					value: "{!opp}",
					pillLabel: "opp",
					referenceName: "opp",
					objectType: "Opportunity",
					dataType: "SObject",
					isSelectable: false
				}
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		const input = getTextInput(element);
		const setCustomValidity = jest.spyOn(input, "setCustomValidity");
		input.value = "{!opp.Account.Name}";
		input.dispatchEvent(new Event("input"));
		input.dispatchEvent(new CustomEvent("blur"));
		await flushPromises();

		expect(describeSObjectFields).toHaveBeenNthCalledWith(1, { objectApiName: "Opportunity" });
		expect(describeSObjectFields).toHaveBeenNthCalledWith(2, { objectApiName: "Account" });
		expect(setCustomValidity).toHaveBeenLastCalledWith("");
		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "value",
			value: "{!opp.Account.Name}",
			valueDataType: "reference"
		});
		expect(element.shadowRoot.querySelector(".selected-resource-pill .slds-pill__label").textContent.trim()).toBe(
			"Account Name"
		);
		expect(element.shadowRoot.querySelector(".selected-resource-pill").title).toBe("{!opp.Account.Name}");
	});

	it("sets custom validity when a typed resource reference cannot be resolved", async () => {
		const element = createComponent({
			name: "value",
			label: "Value",
			fieldDataType: "String",
			included: true,
			resourceOptions: [
				{
					label: "Variable: opp",
					value: "{!opp}",
					pillLabel: "opp",
					referenceName: "opp",
					objectType: "Opportunity",
					dataType: "SObject",
					isSelectable: false
				}
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);

		const input = getTextInput(element);
		const setCustomValidity = jest.spyOn(input, "setCustomValidity");
		const reportValidity = jest.spyOn(input, "reportValidity");
		input.value = "{!adsf}";
		input.dispatchEvent(new Event("input"));
		input.dispatchEvent(new CustomEvent("blur"));
		await flushPromises();

		expect(handler).not.toHaveBeenCalled();
		expect(setCustomValidity).toHaveBeenLastCalledWith("Enter a valid Flow resource reference.");
		expect(reportValidity).toHaveBeenCalled();
		expect(getTextInput(element).value).toBe("{!adsf}");
	});

	it("stops drilling relationship fields after five parent levels", async () => {
		describeSObjectFields.mockResolvedValueOnce([
			{
				name: "ManagerId",
				label: "Manager ID",
				dataType: "String",
				relationshipName: "Manager",
				relationshipObjectType: "User",
				relationshipObjectTypes: ["User"]
			}
		]);
		const element = createComponent({
			name: "value",
			label: "Value",
			fieldDataType: "String",
			included: true,
			resourceOptions: [
				{
					label: "Variable: deepUser",
					value: "{!deepUser}",
					pillLabel: "deepUser",
					referenceName: "deepUser",
					objectType: "User",
					dataType: "SObject",
					relationshipDepth: 5,
					isSelectable: false
				}
			]
		});

		getTextInput(element).dispatchEvent(new CustomEvent("focus"));
		await Promise.resolve();
		element.shadowRoot.querySelector(".resource-option").click();
		await flushPromises();

		expect(element.shadowRoot.querySelector(".resource-option").textContent).toContain("Manager ID");
		expect(element.shadowRoot.querySelector(".resource-option-chevron")).toBeNull();
	});

	it("does not commit a typed literal on blur for boolean fields", async () => {
		const element = createComponent({
			name: "allOrNone",
			label: "All Or None",
			fieldDataType: "Boolean",
			inputType: "boolean",
			included: true,
			options: [
				{ label: "True", value: "true" },
				{ label: "False", value: "false" }
			]
		});
		const handler = jest.fn();
		element.addEventListener("fieldchange", handler);
		const input = getTextInput(element);
		input.value = "True";
		input.dispatchEvent(new Event("input"));
		input.dispatchEvent(new CustomEvent("blur"));
		await Promise.resolve();
		expect(handler).not.toHaveBeenCalled();
	});

	it("shows an error message and slds-has-error class when validate() is called with an error", async () => {
		const element = createComponent({ name: "record", label: "SObject Record", included: true });
		element.validate("This field is required.");
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".field-error").textContent).toBe("This field is required.");
		expect(element.shadowRoot.querySelector(".slds-has-error")).not.toBeNull();
	});

	it("clears the validation error when a new value is set", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			resourceOptions: [
				{ label: "Variable: record", value: "{!record}", pillLabel: "record", referenceName: "record" }
			]
		});
		element.validate("This field is required.");
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".field-error")).not.toBeNull();

		element.value = "{!record}";
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".field-error")).toBeNull();
		expect(element.shadowRoot.querySelector(".slds-has-error")).toBeNull();
	});

	it("validate() returns false when an error is provided and true when cleared", () => {
		const element = createComponent({ name: "record", label: "SObject Record", included: true });
		expect(element.validate("Something is wrong")).toBe(false);
		expect(element.validate(null)).toBe(true);
	});

	it("shows errorMessage prop as a fallback when validate() has not been called", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			errorMessage: "Prop error"
		});
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".field-error").textContent).toBe("Prop error");
	});

	it("validate() error takes precedence over the errorMessage prop", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			included: true,
			errorMessage: "Prop error"
		});
		element.validate("Validate error");
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".field-error").textContent).toBe("Validate error");
	});

	// ── SObject type picker ────────────────────────────────────────────────────

	it("renders the type picker when fieldDataType is SObject and typeName is set", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			fieldDataType: "SObject",
			typeName: "T__record",
			resourceOptions: [
				{ label: "Account Var", value: "{!acc}", pillLabel: "acc", referenceName: "acc", objectType: "Account" }
			]
		});
		await Promise.resolve();
		expect(element.shadowRoot.querySelector('[data-id="type-picker"]')).not.toBeNull();
	});

	it("does not render the type picker when typeName is not set", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			fieldDataType: "SObject",
			resourceOptions: []
		});
		await Promise.resolve();
		expect(element.shadowRoot.querySelector('[data-id="type-picker"]')).toBeNull();
	});

	it("does not render the type picker when fieldDataType is not SObject", async () => {
		const element = createComponent({
			name: "myField",
			label: "My Field",
			fieldDataType: "String",
			typeName: "T__record",
			resourceOptions: []
		});
		await Promise.resolve();
		expect(element.shadowRoot.querySelector('[data-id="type-picker"]')).toBeNull();
	});

	it("type picker options are unique objectType values from resourceOptions", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			fieldDataType: "SObject",
			typeName: "T__record",
			resourceOptions: [
				{ label: "Acc1", value: "{!acc1}", pillLabel: "acc1", referenceName: "acc1", objectType: "Account" },
				{ label: "Acc2", value: "{!acc2}", pillLabel: "acc2", referenceName: "acc2", objectType: "Account" },
				{ label: "Con1", value: "{!con1}", pillLabel: "con1", referenceName: "con1", objectType: "Contact" }
			]
		});
		await Promise.resolve();
		const picker = element.shadowRoot.querySelector('[data-id="type-picker"]');
		expect(picker.options).toEqual([
			{ label: "Account", value: "Account" },
			{ label: "Contact", value: "Contact" }
		]);
	});

	it("type picker is seeded from the typeValue prop", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			fieldDataType: "SObject",
			typeName: "T__record",
			typeValue: "Account",
			resourceOptions: [
				{ label: "Acc", value: "{!acc}", pillLabel: "acc", referenceName: "acc", objectType: "Account" }
			]
		});
		await Promise.resolve();
		const picker = element.shadowRoot.querySelector('[data-id="type-picker"]');
		expect(picker.value).toBe("Account");
	});

	it("dispatches configuration_editor_generic_type_mapping_changed when type is selected", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			fieldDataType: "SObject",
			typeName: "T__record",
			resourceOptions: [
				{ label: "Acc", value: "{!acc}", pillLabel: "acc", referenceName: "acc", objectType: "Account" }
			]
		});
		await Promise.resolve();

		const typeMappingEvents = [];
		element.addEventListener("configuration_editor_generic_type_mapping_changed", (e) => typeMappingEvents.push(e));

		element.shadowRoot
			.querySelector('[data-id="type-picker"]')
			.dispatchEvent(new CustomEvent("change", { detail: { value: "Account" } }));

		expect(typeMappingEvents).toHaveLength(1);
		expect(typeMappingEvents[0].detail.typeName).toBe("T__record");
		expect(typeMappingEvents[0].detail.typeValue).toBe("Account");
	});

	it("type picker renders and requires selection even when the field is not included", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			fieldDataType: "SObject",
			typeName: "T__record",
			included: false,
			resourceOptions: [
				{ label: "Acc", value: "{!acc}", pillLabel: "acc", referenceName: "acc", objectType: "Account" }
			]
		});
		await Promise.resolve();
		expect(element.shadowRoot.querySelector('[data-id="type-picker"]')).not.toBeNull();
	});

	it("hides the variable picker until typeValue is set for SObject fields", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			fieldDataType: "SObject",
			typeName: "T__record",
			included: true,
			resourceOptions: [
				{ label: "Acc", value: "{!acc}", pillLabel: "acc", referenceName: "acc", objectType: "Account" }
			]
		});
		await Promise.resolve();
		expect(element.shadowRoot.querySelector('[data-id="resource-input"]')).toBeNull();
	});

	it("shows the variable picker after typeValue is set for SObject fields", async () => {
		const element = createComponent({
			name: "record",
			label: "SObject Record",
			fieldDataType: "SObject",
			typeName: "T__record",
			typeValue: "Account",
			included: true,
			resourceOptions: [
				{ label: "Acc", value: "{!acc}", pillLabel: "acc", referenceName: "acc", objectType: "Account" }
			]
		});
		await Promise.resolve();
		expect(element.shadowRoot.querySelector('[data-id="resource-input"]')).not.toBeNull();
	});
});
