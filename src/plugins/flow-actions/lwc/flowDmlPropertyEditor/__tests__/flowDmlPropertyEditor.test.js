import { createElement } from "lwc";
import FlowDmlPropertyEditor from "c/flowDmlPropertyEditor";
import Toast from "lightning/toast";

jest.mock(
	"lightning/toast",
	() => ({
		__esModule: true,
		default: {
			show: jest.fn()
		}
	}),
	{ virtual: true }
);

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
const flushPromises = () => Promise.resolve();

describe("c-flow-dml-property-editor", () => {
	function createComponent(props = {}) {
		const element = createElement("c-flow-dml-property-editor", { is: FlowDmlPropertyEditor });
		Object.assign(element, props);
		document.body.appendChild(element);
		return element;
	}

	function getField(element, name) {
		return (
			[...element.shadowRoot.querySelectorAll("c-flow-combobox")].find((field) => field.name === name) ?? null
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

	function captureGenericTypeMappingChangedEvent(element) {
		const handler = jest.fn();
		element.addEventListener("configuration_editor_generic_type_mapping_changed", handler);
		return handler;
	}

	afterEach(() => {
		Toast.show.mockClear();
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
				newValueDataType: "SObject"
			});
		});

		it("emits a generic type mapping when a top-level record resource is selected", () => {
			const element = createComponent({
				inputVariables: BASE_VARS,
				builderContext: {
					variables: [{ name: "accountRecord", dataType: "SObject", objectType: "Account" }]
				}
			});
			const handler = captureGenericTypeMappingChangedEvent(element);

			getField(element, "record").dispatchEvent(
				new CustomEvent("fieldchange", {
					detail: {
						name: "record",
						value: "{!accountRecord}",
						valueDataType: "reference"
					}
				})
			);

			expect(handler).toHaveBeenCalledTimes(2);
			expect(handler.mock.calls.map((call) => call[0].detail)).toEqual([
				{ typeName: "T__record", typeValue: "Account" },
				{ typeName: "T__records", typeValue: "Account" }
			]);
		});

		it("maps a selected record resource to the field's SObject data type for Flow Builder", async () => {
			const element = createComponent({
				inputVariables: BASE_VARS
			});
			const handler = captureChangedEvent(element);
			const field = getField(element, "record");

			field.dispatchEvent(
				new CustomEvent("fieldchange", {
					detail: {
						name: "record",
						value: "{!record}",
						valueDataType: "reference"
					}
				})
			);
			await flushPromises();

			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "record",
				newValue: "{!record}",
				newValueDataType: "SObject"
			});
			expect(getField(element, "record").value).toBe("{!record}");
			expect(element.validate()).toBeUndefined();
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
				newValueDataType: "Apex"
			});
		});

		it("emits an Apex-defined data type when DML options change", () => {
			const element = createComponent({
				inputVariables: [
					...BASE_VARS,
					{ name: "dmlOptions", value: null, dataType: "apex://test.FlowDmlOptions" }
				]
			});
			const handler = captureChangedEvent(element);

			element.shadowRoot.querySelector("c-flow-dml-options").dispatchEvent(
				new CustomEvent("dmloptionschange", {
					detail: {
						value: {
							allowFieldTruncation: false
						}
					}
				})
			);

			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "dmlOptions",
				newValue: {
					allowFieldTruncation: false
				},
				newValueDataType: "Apex"
			});
		});

		it("normalizes legacy top-level dmlOptions values on load", async () => {
			const element = createComponent();
			const handler = captureChangedEvent(element);

			element.inputVariables = [
				...BASE_VARS,
				{
					name: "dmlOptions",
					value: {
						assignmentRuleHeader: {
							useDefaultRule: true
						}
					},
					dataType: "apex://test.FlowDmlOptions"
				}
			];

			await flushPromises();

			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "dmlOptions",
				newValue: {
					useDefaultRule: true
				},
				newValueDataType: "Apex"
			});
		});

		it("normalizes malformed apex-defined data types on load", async () => {
			const element = createComponent();
			const handler = captureChangedEvent(element);

			element.inputVariables = [
				...BASE_VARS,
				{
					name: "dmlOptions",
					value: {
						allowFieldTruncation: true
					},
					dataType: "FlowDmlOptions"
				}
			];

			await flushPromises();

			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "dmlOptions",
				newValue: {
					allowFieldTruncation: true
				},
				newValueDataType: "Apex"
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

		it("filters record id collections to string collections only", () => {
			const element = createComponent({
				inputVariables: DELETE_VARS,
				builderContext: {
					variables: [
						{ name: "recordCollection", dataType: "SObject[]", objectType: "Account", isCollection: true },
						{ name: "recordIdCollection", dataType: "String[]", isCollection: true }
					]
				}
			});

			const resourceOptions = getField(element, "recordIds").resourceOptions;
			expect(resourceOptions).toEqual(
				expect.arrayContaining([
					expect.objectContaining({
						value: "{!recordIdCollection}",
						pillLabel: "recordIdCollection"
					})
				])
			);
			expect(resourceOptions).not.toEqual(
				expect.arrayContaining([
					expect.objectContaining({
						value: "{!recordCollection}"
					})
				])
			);
		});
	});

	describe("validate()", () => {
		it("requires record or records for BASE actions", async () => {
			const element = createComponent({
				inputVariables: BASE_VARS,
				elementInfo: {
					apiName: "Insert_Record_s"
				}
			});
			expect(element.validate()).toEqual([
				{
					key: "record",
					errorString: "Provide at least one record or a collection of records."
				}
			]);
			await flushPromises();
			expect(Toast.show).toHaveBeenCalledTimes(1);
			expect(Toast.show.mock.calls[0][0]).toEqual(
				expect.objectContaining({
					label: "Insert_Record_s: Validation Error",
					message: "Provide at least one record or a collection of records.",
					variant: "error",
					mode: "dismissible"
				})
			);
			expect(getField(element, "record").errorMessage).toBe(
				"Provide at least one record or a collection of records."
			);
		});

		it("pins the BASE required-field error to records when only the records toggle is on", async () => {
			const element = createComponent({ inputVariables: BASE_VARS });

			getField(element, "records").dispatchEvent(
				new CustomEvent("fieldincludedchange", {
					detail: { name: "records", included: true }
				})
			);
			getField(element, "record").dispatchEvent(
				new CustomEvent("fieldincludedchange", {
					detail: { name: "record", included: false }
				})
			);

			expect(element.validate()).toEqual([
				{
					key: "records",
					errorString: "Provide at least one record or a collection of records."
				}
			]);
			await flushPromises();
			expect(getField(element, "records").errorMessage).toBe(
				"Provide at least one record or a collection of records."
			);
			expect(getField(element, "record").errorMessage).toBeUndefined();
		});

		it("surfaces a field error after the field is blurred", async () => {
			const element = createComponent({ inputVariables: BASE_VARS });

			getField(element, "record").dispatchEvent(
				new CustomEvent("fieldblur", {
					detail: {
						name: "record"
					}
				})
			);

			await flushPromises();

			expect(getField(element, "record").errorMessage).toBe(
				"Provide at least one record or a collection of records."
			);
			expect(Toast.show).not.toHaveBeenCalled();
		});

		it("accepts a selected record reference for BASE actions", async () => {
			const element = createComponent({
				inputVariables: BASE_VARS,
				builderContext: {
					variables: [{ name: "accountRecord", dataType: "SObject", objectType: "Account" }]
				},
				genericTypeMappings: [
					{ typeName: "T__record", typeValue: "Account" },
					{ typeName: "T__records", typeValue: "Account" }
				]
			});

			element.validate();
			await flushPromises();

			getField(element, "record").dispatchEvent(
				new CustomEvent("fieldchange", {
					detail: {
						name: "record",
						value: "{!accountRecord}",
						valueDataType: "reference"
					}
				})
			);
			await flushPromises();

			expect(element.validate()).toBeUndefined();
			await flushPromises();
			expect(getField(element, "record").errorMessage).toBeUndefined();
		});

		it("does not report a type mapping error when a partial mapping is present and the correction is pending", async () => {
			// T__record is confirmed correct; T__records is missing but the component self-heals
			// by emitting the correction in renderedCallback — pending mapping counts as valid
			const element = createComponent({
				inputVariables: [
					{ name: "record", value: "{!accountRecord}", valueDataType: "SObject" },
					{ name: "records", value: [] }
				],
				builderContext: {
					variables: [{ name: "accountRecord", dataType: "SObject", objectType: "Account" }]
				},
				genericTypeMappings: [{ typeName: "T__record", typeValue: "Account" }]
			});

			await flushPromises();
			expect(element.validate()).toBeUndefined();
			await flushPromises();
			expect(getField(element, "record").errorMessage).toBeUndefined();
		});

		it("does not report a type mapping error when the mapping is pending (emitted but not yet confirmed)", async () => {
			const element = createComponent({
				inputVariables: [
					{ name: "record", value: "{!accountRecord}", valueDataType: "SObject" },
					{ name: "records", value: [] }
				],
				builderContext: {
					variables: [{ name: "accountRecord", dataType: "SObject", objectType: "Account" }]
				},
				genericTypeMappings: []
			});

			await flushPromises();

			expect(element.validate()).toBeUndefined();
		});

		it("does not report a type mapping error when confirmed mappings are wrong but the correction is pending", async () => {
			// Both T__record and T__records are confirmed as Contact, but should be Account.
			// renderedCallback emits corrections (Account) — pending values suppress the error.
			const element = createComponent({
				inputVariables: [
					{ name: "record", value: "{!accountRecord}", valueDataType: "SObject" },
					{ name: "records", value: [] }
				],
				builderContext: {
					variables: [{ name: "accountRecord", dataType: "SObject", objectType: "Account" }]
				},
				genericTypeMappings: [
					{ typeName: "T__record", typeValue: "Contact" },
					{ typeName: "T__records", typeValue: "Contact" }
				]
			});

			await flushPromises();
			expect(element.validate()).toBeUndefined();
		});

		it("deduplicates identical toast messages across repeated validate calls", () => {
			const element = createComponent({
				inputVariables: BASE_VARS,
				elementInfo: {
					apiName: "Insert_Record_s"
				}
			});

			expect(element.validate()).toHaveLength(1);
			expect(element.validate()).toHaveLength(1);

			expect(Toast.show).toHaveBeenCalledTimes(1);
		});

		it("falls back to the action label when the element api name is blank", () => {
			const element = createComponent({
				inputVariables: BASE_VARS,
				elementInfo: {
					apiName: ""
				},
				builderContext: {
					actionCalls: [
						{
							name: "",
							label: "Insert Record(s)",
							inputParameters: [{ name: "record" }, { name: "records" }]
						}
					]
				}
			});

			expect(element.validate()).toHaveLength(1);
			expect(Toast.show.mock.calls[0][0]).toEqual(
				expect.objectContaining({
					label: "Insert Record(s): Validation Error"
				})
			);
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

			expect(element.validate()).toBeUndefined();
		});

		it("shows the base input validation message on the record field", async () => {
			const element = createComponent({ inputVariables: UPSERT_VARS });

			expect(element.validate()).toEqual([
				{
					key: "baseInput.record",
					errorString: "Provide at least one record or a collection of records in Base Input."
				}
			]);
			await flushPromises();
			expect(getField(element, "baseInput.record").errorMessage).toBe(
				"Provide at least one record or a collection of records in Base Input."
			);
		});

		it("pins the UPSERT base input required-field error to baseInput.records when only the records toggle is on", async () => {
			const element = createComponent({ inputVariables: UPSERT_VARS });

			getField(element, "baseInput.records").dispatchEvent(
				new CustomEvent("fieldincludedchange", {
					detail: { name: "baseInput.records", included: true }
				})
			);
			getField(element, "baseInput.record").dispatchEvent(
				new CustomEvent("fieldincludedchange", {
					detail: { name: "baseInput.record", included: false }
				})
			);

			expect(element.validate()).toEqual([
				{
					key: "baseInput.records",
					errorString: "Provide at least one record or a collection of records in Base Input."
				}
			]);
			await flushPromises();
			expect(getField(element, "baseInput.records").errorMessage).toBe(
				"Provide at least one record or a collection of records in Base Input."
			);
			expect(getField(element, "baseInput.record").errorMessage).toBeUndefined();
		});

		it("rejects an invalid literal for record inputs", async () => {
			const element = createComponent({ inputVariables: BASE_VARS });

			getField(element, "record").dispatchEvent(
				new CustomEvent("fieldchange", {
					detail: {
						name: "record",
						value: "not-a-record",
						valueDataType: "String"
					}
				})
			);

			expect(element.validate()).toEqual([
				{
					key: "record",
					errorString: "SObject Record must be a record value or record resource."
				}
			]);
			await flushPromises();
			expect(getField(element, "record").errorMessage).toBe(
				"SObject Record must be a record value or record resource."
			);
		});

		it("rejects an invalid literal for boolean inputs", async () => {
			const element = createComponent({
				inputVariables: [...BASE_VARS, { name: "allOrNone", value: true }]
			});

			getField(element, "allOrNone").dispatchEvent(
				new CustomEvent("fieldchange", {
					detail: {
						name: "allOrNone",
						value: "maybe",
						valueDataType: "String"
					}
				})
			);

			expect(element.validate()).toEqual([
				{
					key: "record",
					errorString: "Provide at least one record or a collection of records."
				},
				{
					key: "allOrNone",
					errorString: "All Or None must be a Boolean value or Boolean resource."
				}
			]);
			await flushPromises();
			expect(getField(element, "allOrNone").errorMessage).toBe(
				"All Or None must be a Boolean value or Boolean resource."
			);
		});
	});
});
