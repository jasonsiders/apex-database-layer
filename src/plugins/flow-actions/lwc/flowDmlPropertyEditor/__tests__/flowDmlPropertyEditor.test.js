import { createElement } from "lwc";
import FlowDmlPropertyEditor from "c/flowDmlPropertyEditor";

const BASE_VARS = [
	{ name: "record", value: null },
	{ name: "records", value: [] }
];

const DELETE_VARS = [
	{ name: "recordId", value: null },
	{ name: "recordIds", value: [] },
	{ name: "baseInput", value: {} }
];

const UPSERT_VARS = [
	{ name: "externalIdField", value: null },
	{ name: "baseInput", value: {} }
];

const CONVERT_VARS = [{ name: "leadId", value: null }];

describe("c-flow-dml-property-editor", () => {
	function createComponent(props = {}) {
		const element = createElement("c-flow-dml-property-editor", { is: FlowDmlPropertyEditor });
		Object.assign(element, props);
		document.body.appendChild(element);
		return element;
	}

	function getField(element, name) {
		return (
			[...element.shadowRoot.querySelectorAll("c-flow-dml-field")].find((field) => field.name === name) ?? null
		);
	}

	function getSections(element) {
		return [...element.shadowRoot.querySelectorAll("c-flow-dml-section")];
	}

	function captureChangedEvent(element) {
		const handler = jest.fn();
		element.addEventListener("configuration_editor_input_value_changed", handler);
		return handler;
	}

	function captureDeletedEvent(element) {
		const handler = jest.fn();
		element.addEventListener("configuration_editor_input_value_deleted", handler);
		return handler;
	}

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	describe("rendering", () => {
		it("renders the record inputs section first for BASE actions and keeps it open", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			const [firstSection] = getSections(element);

			expect(firstSection.label).toBe("Record Inputs");
			expect(firstSection.expanded).toBe("true");
			expect(firstSection.collapsible).toBe("false");
			expect(getField(element, "record")).not.toBeNull();
			expect(getField(element, "records")).not.toBeNull();
		});

		it("groups delete record inputs together at the top", () => {
			const element = createComponent({ inputVariables: DELETE_VARS });

			expect(getField(element, "baseInput.record")).not.toBeNull();
			expect(getField(element, "baseInput.records")).not.toBeNull();
			expect(getField(element, "recordId")).not.toBeNull();
			expect(getField(element, "recordIds")).not.toBeNull();
		});

		it("renders booleans as true/false picklists instead of toggles", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			const field = getField(element, "allOrNone");

			expect(field).not.toBeNull();
			expect(field.inputType).toBe("boolean");
			expect(field.options).toEqual([
				{ label: "True", value: "true" },
				{ label: "False", value: "false" }
			]);
		});

		it("marks leadId as required for convert actions", () => {
			const element = createComponent({ inputVariables: CONVERT_VARS });
			expect(getField(element, "leadId").required).toBe(true);
		});
	});

	describe("events", () => {
		it("emits a reference change when a resource is selected", () => {
			const element = createComponent({
				inputVariables: BASE_VARS,
				builderContext: {
					variables: [{ name: "accountRecord", dataType: "SObject", objectType: "Account" }]
				}
			});
			const handler = captureChangedEvent(element);

			getField(element, "record").dispatchEvent(
				new CustomEvent("fieldchange", {
					detail: {
						name: "record",
						value: "{!accountRecord}",
						valueDataType: "reference"
					}
				})
			);

			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "record",
				newValue: "{!accountRecord}",
				newValueDataType: "reference"
			});
		});

		it("emits a delete event when an optional top-level field is excluded", () => {
			const element = createComponent({
				inputVariables: [...BASE_VARS, { name: "accessLevelName", value: "SYSTEM_MODE" }]
			});
			const handler = captureDeletedEvent(element);

			getField(element, "accessLevelName").dispatchEvent(
				new CustomEvent("fieldincludedchange", {
					detail: {
						name: "accessLevelName",
						included: false
					}
				})
			);

			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({ name: "accessLevelName" });
		});

		it("emits an updated baseInput object when nested fields change", () => {
			const element = createComponent({ inputVariables: DELETE_VARS });
			const handler = captureChangedEvent(element);

			getField(element, "baseInput.allOrNone").dispatchEvent(
				new CustomEvent("fieldchange", {
					detail: {
						name: "baseInput.allOrNone",
						value: false,
						valueDataType: "Boolean"
					}
				})
			);

			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "baseInput",
				newValue: { allOrNone: false },
				newValueDataType: "FlowDmlBaseInput"
			});
		});
	});

	describe("resource options", () => {
		it("filters record resources for record inputs", () => {
			const element = createComponent({
				inputVariables: BASE_VARS,
				builderContext: {
					variables: [
						{ name: "accountRecord", dataType: "SObject", objectType: "Account" },
						{ name: "stringVar", dataType: "String" }
					]
				}
			});

			const resourceOptions = getField(element, "record").resourceOptions;
			expect(resourceOptions).toEqual(
				expect.arrayContaining([
					expect.objectContaining({
						value: "{!accountRecord}",
						pillLabel: "accountRecord"
					})
				])
			);
			expect(resourceOptions).not.toEqual(
				expect.arrayContaining([
					expect.objectContaining({
						value: "{!stringVar}"
					})
				])
			);
		});
	});

	describe("validate()", () => {
		it("requires record or records for BASE actions", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			expect(element.validate()).toEqual([
				{
					key: "record",
					errorString: "Provide at least one record or a collection of records."
				}
			]);
		});

		it("accepts a selected record reference for BASE actions", () => {
			const element = createComponent({ inputVariables: BASE_VARS });

			getField(element, "record").dispatchEvent(
				new CustomEvent("fieldchange", {
					detail: {
						name: "record",
						value: "{!accountRecord}",
						valueDataType: "reference"
					}
				})
			);

			expect(element.validate()).toEqual([]);
		});

		it("requires leadId for convert actions", () => {
			const element = createComponent({ inputVariables: CONVERT_VARS });
			expect(element.validate()).toEqual([{ key: "leadId", errorString: "Lead ID is required." }]);
		});

		it("accepts baseInput record references for upsert actions", () => {
			const element = createComponent({ inputVariables: UPSERT_VARS });

			getField(element, "baseInput.record").dispatchEvent(
				new CustomEvent("fieldchange", {
					detail: {
						name: "baseInput.record",
						value: "{!accountRecord}",
						valueDataType: "reference"
					}
				})
			);

			expect(element.validate()).toEqual([]);
		});
	});
});
