import { createElement } from "lwc";
import FlowDmlOptions from "c/flowDmlOptions";

describe("c-flow-dml-options", () => {
	function createComponent(props = {}) {
		const element = createElement("c-flow-dml-options", { is: FlowDmlOptions });
		Object.assign(element, props);
		document.body.appendChild(element);
		return element;
	}

	function getField(element, name) {
		return (
			[...element.shadowRoot.querySelectorAll("c-flow-combobox")].find((field) => field.name === name) ?? null
		);
	}

	function captureEvent(element) {
		const handler = jest.fn();
		element.addEventListener("dmloptionschange", handler);
		return handler;
	}

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	it("renders locale as a picklist with Salesforce locale options", () => {
		const element = createComponent();
		const localeField = getField(element, "localeOptions");

		expect(localeField).not.toBeNull();
		expect(localeField.inputType).toBe("picklist");
		expect(localeField.options.map((option) => option.value)).toContain("en_US");
	});

	it("renders booleans as true/false picklists", () => {
		const element = createComponent();
		const field = getField(element, "allowFieldTruncation");

		expect(field.inputType).toBe("boolean");
		expect(field.options).toEqual([
			{ label: "True", value: "true" },
			{ label: "False", value: "false" }
		]);
	});

	it("emits updated top-level values when a field changes", () => {
		const element = createComponent();
		const handler = captureEvent(element);

		getField(element, "allowFieldTruncation").dispatchEvent(
			new CustomEvent("fieldchange", {
				detail: {
					name: "allowFieldTruncation",
					value: true,
					valueDataType: "Boolean"
				}
			})
		);

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail.value.allowFieldTruncation).toBe(true);
	});

	it("removes nested values when an included toggle is turned off", () => {
		const element = createComponent({
			value: {
				assignmentRuleId: "01Qxx0000000001",
				useDefaultRule: true
			}
		});
		const handler = captureEvent(element);

		getField(element, "useDefaultRule").dispatchEvent(
			new CustomEvent("fieldincludedchange", {
				detail: {
					name: "useDefaultRule",
					included: false
				}
			})
		);

		expect(handler).toHaveBeenCalledTimes(1);
		expect(handler.mock.calls[0][0].detail.value).toEqual({
			assignmentRuleId: "01Qxx0000000001"
		});
	});

	it("surfaces flow resources to nested fields", () => {
		const element = createComponent({
			builderContext: {
				variables: [{ name: "myBooleanVar", dataType: "Boolean" }]
			}
		});

		const field = getField(element, "allowFieldTruncation");
		expect(field.resourceOptions).toEqual(
			expect.arrayContaining([
				expect.objectContaining({
					value: "{!myBooleanVar}",
					pillLabel: "myBooleanVar"
				})
			])
		);
	});
});
