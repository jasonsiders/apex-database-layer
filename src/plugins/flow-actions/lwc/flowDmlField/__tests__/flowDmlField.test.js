import { createElement } from "lwc";
import FlowDmlField from "c/flowDmlField";

describe("c-flow-dml-field", () => {
	function createComponent(props = {}) {
		const element = createElement("c-flow-dml-field", { is: FlowDmlField });
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
		expect(element.classList.contains("resource-picker-open")).toBe(false);
	});

	it("emits a literal boolean when the typed value matches a boolean choice", () => {
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
		input.dispatchEvent(new Event("change"));

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail).toEqual({
			name: "allOrNone",
			value: true,
			valueDataType: "Boolean"
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

	it("emits a literal value when the searchable input is changed without selecting a resource", async () => {
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
		input.dispatchEvent(new Event("change"));

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
});
