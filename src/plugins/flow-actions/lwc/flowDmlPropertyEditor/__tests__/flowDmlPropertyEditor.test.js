import { createElement } from "lwc";
import FlowDmlPropertyEditor from "c/flowDmlPropertyEditor";

const BASE_VARS = [
	{ name: "record", value: null },
	{ name: "records", value: [] },
	{ name: "accessLevelName", value: "USER_MODE" },
	{ name: "allOrNone", value: true },
	{ name: "dmlOptions", value: null }
];

const DELETE_VARS = [
	{ name: "recordId", value: null },
	{ name: "recordIds", value: [] },
	{ name: "baseInput", value: null }
];

const UPSERT_VARS = [{ name: "externalIdField", value: null }, { name: "baseInput", value: null }];

const CONVERT_VARS = [
	{ name: "leadId", value: null },
	{ name: "accountId", value: null },
	{ name: "accountName", value: null },
	{ name: "contactId", value: null },
	{ name: "convertedStatus", value: null },
	{ name: "doNotCreateOpportunity", value: false },
	{ name: "opportunityId", value: null },
	{ name: "opportunityName", value: null },
	{ name: "overwriteLeadSource", value: false },
	{ name: "ownerId", value: null },
	{ name: "sendNotificationEmail", value: false },
	{ name: "accessLevelName", value: "USER_MODE" },
	{ name: "allOrNone", value: true },
	{ name: "dmlOptions", value: null }
];

describe("c-flow-dml-property-editor", () => {
	function createComponent(props = {}) {
		const element = createElement("c-flow-dml-property-editor", { is: FlowDmlPropertyEditor });
		Object.assign(element, props);
		document.body.appendChild(element);
		return element;
	}

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	function getInput(element, name) {
		return (
			[...element.shadowRoot.querySelectorAll("lightning-input")].find(
				(el) => el.name === name
			) ?? null
		);
	}

	function getCombobox(element, name) {
		return (
			[...element.shadowRoot.querySelectorAll("lightning-combobox")].find(
				(el) => el.name === name
			) ?? null
		);
	}

	function getDmlOptions(element) {
		return element.shadowRoot.querySelector("c-flow-dml-options");
	}

	function captureConfigEvent(element) {
		const handler = jest.fn();
		element.addEventListener("configuration_editor_input_value_changed", handler);
		return handler;
	}

	function fireText(stub, name, value) {
		stub.name = name;
		stub.value = value;
		stub.dispatchEvent(new CustomEvent("change"));
	}

	function fireToggle(stub, name, checked) {
		stub.name = name;
		stub.checked = checked;
		stub.dispatchEvent(new CustomEvent("change"));
	}

	function fireCombobox(stub, name, value) {
		stub.name = name;
		stub.dispatchEvent(new CustomEvent("change", { detail: { value } }));
	}

	describe("action type detection and rendering", () => {
		it("renders Group A (BASE) when no identifying variables are present", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			expect(getInput(element, "record")).not.toBeNull();
		});

		it("does not render Group B/C/D elements for BASE type", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			expect(getInput(element, "recordId")).toBeFalsy();
			expect(getInput(element, "externalIdField")).toBeFalsy();
			expect(getInput(element, "leadId")).toBeFalsy();
		});

		it("renders Group B (DELETE) when recordId is present", () => {
			const element = createComponent({ inputVariables: DELETE_VARS });
			expect(getInput(element, "recordId")).not.toBeNull();
		});

		it("renders Group B (DELETE) when recordIds is present without recordId", () => {
			const element = createComponent({ inputVariables: [{ name: "recordIds", value: [] }] });
			expect(getInput(element, "recordIds")).not.toBeNull();
		});

		it("renders Group C (UPSERT) when externalIdField is present", () => {
			const element = createComponent({ inputVariables: UPSERT_VARS });
			expect(getInput(element, "externalIdField")).not.toBeNull();
		});

		it("renders Group D (CONVERT) when leadId is present", () => {
			const element = createComponent({ inputVariables: CONVERT_VARS });
			expect(getInput(element, "leadId")).not.toBeNull();
		});

		it("does not render Group A fields when rendering Group D", () => {
			const element = createComponent({ inputVariables: CONVERT_VARS });
			expect(getInput(element, "record")).toBeFalsy();
		});
	});

	describe("initial values from inputVariables", () => {
		it("populates record in Group A from inputVariables", () => {
			const vars = BASE_VARS.map((v) => (v.name === "record" ? { ...v, value: "acc001" } : v));
			const element = createComponent({ inputVariables: vars });
			expect(getInput(element, "record").value).toBe("acc001");
		});

		it("defaults accessLevelName to USER_MODE when inputVariables is empty", () => {
			const element = createComponent({ inputVariables: [] });
			expect(getCombobox(element, "accessLevelName").value).toBe("USER_MODE");
		});

		it("populates recordId in Group B from inputVariables", () => {
			const vars = DELETE_VARS.map((v) => (v.name === "recordId" ? { ...v, value: "001abc" } : v));
			const element = createComponent({ inputVariables: vars });
			expect(getInput(element, "recordId").value).toBe("001abc");
		});

		it("populates externalIdField in Group C from inputVariables", () => {
			const vars = UPSERT_VARS.map((v) =>
				v.name === "externalIdField" ? { ...v, value: "MyField__c" } : v
			);
			const element = createComponent({ inputVariables: vars });
			expect(getInput(element, "externalIdField").value).toBe("MyField__c");
		});

		it("populates leadId in Group D from inputVariables", () => {
			const vars = CONVERT_VARS.map((v) => (v.name === "leadId" ? { ...v, value: "00Qabc" } : v));
			const element = createComponent({ inputVariables: vars });
			expect(getInput(element, "leadId").value).toBe("00Qabc");
		});
	});

	describe("Group A (BASE) — Insert/Update", () => {
		it("emits configuration_editor_input_value_changed with String type on text input change", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			const handler = captureConfigEvent(element);
			fireText(getInput(element, "record"), "record", "acc001");
			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "record",
				newValue: "acc001",
				newValueDataType: "String"
			});
		});

		it("emits configuration_editor_input_value_changed with Boolean type on toggle change", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			const handler = captureConfigEvent(element);
			fireToggle(getInput(element, "allOrNone"), "allOrNone", false);
			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "allOrNone",
				newValue: false,
				newValueDataType: "Boolean"
			});
		});

		it("emits configuration_editor_input_value_changed with String type on combobox change", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			const handler = captureConfigEvent(element);
			fireCombobox(getCombobox(element, "accessLevelName"), "accessLevelName", "SYSTEM_MODE");
			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "accessLevelName",
				newValue: "SYSTEM_MODE",
				newValueDataType: "String"
			});
		});

		it("emits configuration_editor_input_value_changed with FlowDmlOptions type on dmlOptions change", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			const handler = captureConfigEvent(element);
			const updatedOpts = { allowFieldTruncation: true };
			getDmlOptions(element).dispatchEvent(
				new CustomEvent("dmloptionschange", { detail: { value: updatedOpts } })
			);
			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "dmlOptions",
				newValue: updatedOpts,
				newValueDataType: "FlowDmlOptions"
			});
		});
	});

	describe("Group B (DELETE) — Delete / Purge / Undelete", () => {
		it("emits String event for recordId text change", () => {
			const element = createComponent({ inputVariables: DELETE_VARS });
			const handler = captureConfigEvent(element);
			fireText(getInput(element, "recordId"), "recordId", "001xyz");
			expect(handler.mock.calls[0][0].detail).toEqual({
				name: "recordId",
				newValue: "001xyz",
				newValueDataType: "String"
			});
		});

		it("emits FlowDmlBaseInput event for baseInput_record text change", () => {
			const element = createComponent({ inputVariables: DELETE_VARS });
			const handler = captureConfigEvent(element);
			fireText(getInput(element, "baseInput_record"), "baseInput_record", "accRec");
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("baseInput");
			expect(detail.newValue.record).toBe("accRec");
			expect(detail.newValueDataType).toBe("FlowDmlBaseInput");
		});

		it("emits FlowDmlBaseInput event for baseInput_allOrNone toggle change", () => {
			const element = createComponent({ inputVariables: DELETE_VARS });
			const handler = captureConfigEvent(element);
			fireToggle(getInput(element, "baseInput_allOrNone"), "baseInput_allOrNone", false);
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("baseInput");
			expect(detail.newValue.allOrNone).toBe(false);
			expect(detail.newValueDataType).toBe("FlowDmlBaseInput");
		});

		it("emits FlowDmlBaseInput event for baseInput_accessLevelName combobox change", () => {
			const element = createComponent({ inputVariables: DELETE_VARS });
			const handler = captureConfigEvent(element);
			fireCombobox(
				getCombobox(element, "baseInput_accessLevelName"),
				"baseInput_accessLevelName",
				"SYSTEM_MODE"
			);
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("baseInput");
			expect(detail.newValue.accessLevelName).toBe("SYSTEM_MODE");
			expect(detail.newValueDataType).toBe("FlowDmlBaseInput");
		});

		it("emits updated baseInput containing dmlOptions on baseInput dmlOptions change", () => {
			const element = createComponent({ inputVariables: DELETE_VARS });
			const handler = captureConfigEvent(element);
			const updatedOpts = { allowFieldTruncation: true };
			getDmlOptions(element).dispatchEvent(
				new CustomEvent("dmloptionschange", { detail: { value: updatedOpts } })
			);
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("baseInput");
			expect(detail.newValue.dmlOptions).toEqual(updatedOpts);
			expect(detail.newValueDataType).toBe("FlowDmlBaseInput");
		});
	});

	describe("Group C (UPSERT)", () => {
		it("emits String event for externalIdField text change", () => {
			const element = createComponent({ inputVariables: UPSERT_VARS });
			const handler = captureConfigEvent(element);
			fireText(getInput(element, "externalIdField"), "externalIdField", "My_Field__c");
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("externalIdField");
			expect(detail.newValue).toBe("My_Field__c");
			expect(detail.newValueDataType).toBe("String");
		});

		it("emits FlowDmlBaseInput event for baseInput_record text change", () => {
			const element = createComponent({ inputVariables: UPSERT_VARS });
			const handler = captureConfigEvent(element);
			fireText(getInput(element, "baseInput_record"), "baseInput_record", "accRec");
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("baseInput");
			expect(detail.newValue.record).toBe("accRec");
			expect(detail.newValueDataType).toBe("FlowDmlBaseInput");
		});

		it("emits FlowDmlBaseInput event for baseInput_allOrNone toggle change", () => {
			const element = createComponent({ inputVariables: UPSERT_VARS });
			const handler = captureConfigEvent(element);
			fireToggle(getInput(element, "baseInput_allOrNone"), "baseInput_allOrNone", false);
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("baseInput");
			expect(detail.newValue.allOrNone).toBe(false);
			expect(detail.newValueDataType).toBe("FlowDmlBaseInput");
		});

		it("emits updated baseInput containing dmlOptions on baseInput dmlOptions change", () => {
			const element = createComponent({ inputVariables: UPSERT_VARS });
			const handler = captureConfigEvent(element);
			const updatedOpts = { allowFieldTruncation: true };
			getDmlOptions(element).dispatchEvent(
				new CustomEvent("dmloptionschange", { detail: { value: updatedOpts } })
			);
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("baseInput");
			expect(detail.newValue.dmlOptions).toEqual(updatedOpts);
			expect(detail.newValueDataType).toBe("FlowDmlBaseInput");
		});
	});

	describe("Group D (CONVERT)", () => {
		it("emits String event for leadId text change", () => {
			const element = createComponent({ inputVariables: CONVERT_VARS });
			const handler = captureConfigEvent(element);
			fireText(getInput(element, "leadId"), "leadId", "00Qabc");
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("leadId");
			expect(detail.newValue).toBe("00Qabc");
			expect(detail.newValueDataType).toBe("String");
		});

		it("emits Boolean event for doNotCreateOpportunity toggle change", () => {
			const element = createComponent({ inputVariables: CONVERT_VARS });
			const handler = captureConfigEvent(element);
			fireToggle(getInput(element, "doNotCreateOpportunity"), "doNotCreateOpportunity", true);
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("doNotCreateOpportunity");
			expect(detail.newValue).toBe(true);
			expect(detail.newValueDataType).toBe("Boolean");
		});

		it("emits String event for accountId text change", () => {
			const element = createComponent({ inputVariables: CONVERT_VARS });
			const handler = captureConfigEvent(element);
			fireText(getInput(element, "accountId"), "accountId", "001accId");
			expect(handler.mock.calls[0][0].detail.name).toBe("accountId");
			expect(handler.mock.calls[0][0].detail.newValueDataType).toBe("String");
		});

		it("emits FlowDmlOptions event for dmlOptions change", () => {
			const element = createComponent({ inputVariables: CONVERT_VARS });
			const handler = captureConfigEvent(element);
			const updatedOpts = { allowFieldTruncation: true };
			getDmlOptions(element).dispatchEvent(
				new CustomEvent("dmloptionschange", { detail: { value: updatedOpts } })
			);
			const detail = handler.mock.calls[0][0].detail;
			expect(detail.name).toBe("dmlOptions");
			expect(detail.newValue).toEqual(updatedOpts);
			expect(detail.newValueDataType).toBe("FlowDmlOptions");
		});
	});

	describe("validate()", () => {
		describe("BASE type", () => {
			it("returns an error when neither record nor records is set", () => {
				const element = createComponent({ inputVariables: BASE_VARS });
				const errors = element.validate();
				expect(errors).toHaveLength(1);
				expect(errors[0].key).toBe("record");
			});

			it("returns no errors when record is set", async () => {
				const element = createComponent({ inputVariables: BASE_VARS });
				fireText(getInput(element, "record"), "record", "acc001");
				await Promise.resolve();
				expect(element.validate()).toHaveLength(0);
			});

			it("returns no errors when records is non-empty", async () => {
				const element = createComponent({ inputVariables: BASE_VARS });
				fireText(getInput(element, "records"), "records", ["acc001"]);
				await Promise.resolve();
				expect(element.validate()).toHaveLength(0);
			});
		});

		describe("DELETE type", () => {
			it("returns an error when neither recordId nor recordIds is set", () => {
				const element = createComponent({ inputVariables: DELETE_VARS });
				const errors = element.validate();
				expect(errors).toHaveLength(1);
				expect(errors[0].key).toBe("recordId");
			});

			it("returns no errors when recordId is set", async () => {
				const element = createComponent({ inputVariables: DELETE_VARS });
				fireText(getInput(element, "recordId"), "recordId", "001abc");
				await Promise.resolve();
				expect(element.validate()).toHaveLength(0);
			});

			it("returns no errors when recordIds is non-empty", async () => {
				const element = createComponent({ inputVariables: DELETE_VARS });
				fireText(getInput(element, "recordIds"), "recordIds", ["001abc"]);
				await Promise.resolve();
				expect(element.validate()).toHaveLength(0);
			});
		});

		describe("UPSERT type", () => {
			it("returns an error when baseInput has no record or records", () => {
				const element = createComponent({ inputVariables: UPSERT_VARS });
				const errors = element.validate();
				expect(errors).toHaveLength(1);
				expect(errors[0].key).toBe("baseInput");
			});

			it("returns no errors when baseInput.record is set via text change", async () => {
				const element = createComponent({ inputVariables: UPSERT_VARS });
				fireText(getInput(element, "baseInput_record"), "baseInput_record", "accRec");
				await Promise.resolve();
				expect(element.validate()).toHaveLength(0);
			});
		});

		describe("CONVERT type", () => {
			it("returns an error when leadId is not set", () => {
				const element = createComponent({ inputVariables: CONVERT_VARS });
				const errors = element.validate();
				expect(errors).toHaveLength(1);
				expect(errors[0].key).toBe("leadId");
			});

			it("returns no errors when leadId is set", async () => {
				const element = createComponent({ inputVariables: CONVERT_VARS });
				fireText(getInput(element, "leadId"), "leadId", "00Qabc");
				await Promise.resolve();
				expect(element.validate()).toHaveLength(0);
			});
		});
	});

	describe("accessLevelOptions", () => {
		it("provides USER_MODE and SYSTEM_MODE as combobox options", () => {
			const element = createComponent({ inputVariables: BASE_VARS });
			const combo = getCombobox(element, "accessLevelName");
			const values = combo.options.map((o) => o.value);
			expect(values).toContain("USER_MODE");
			expect(values).toContain("SYSTEM_MODE");
		});
	});
});
