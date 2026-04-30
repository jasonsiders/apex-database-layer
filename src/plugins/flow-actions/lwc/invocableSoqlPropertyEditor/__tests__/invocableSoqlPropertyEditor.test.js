import { createElement } from "@lwc/engine-dom";
import InvocableSoqlPropertyEditor from "c/invocableSoqlPropertyEditor";
import Toast from "lightning/toast";
import validateQuery from "@salesforce/apex/InvocableSoql.validateQuery";

jest.mock(
	"@salesforce/apex/InvocableSoql.validateQuery",
	() => ({ default: jest.fn().mockResolvedValue(undefined) }),
	{ virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-invocable-soql-property-editor", () => {
	function createComponent(props = {}) {
		const element = createElement("c-invocable-soql-property-editor", {
			is: InvocableSoqlPropertyEditor
		});
		Object.assign(element, props);
		document.body.appendChild(element);
		return element;
	}

	function getButtonByLabel(element, label) {
		return Array.from(element.shadowRoot.querySelectorAll("lightning-button")).find(
			(button) => button.label === label
		);
	}

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
		jest.clearAllMocks();
	});

	it("renders the query code editor", () => {
		const element = createComponent();
		expect(element.shadowRoot.querySelector(".code-editor")).not.toBeNull();
	});

	it("populates the query editor from inputVariables", async () => {
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" }]
		});
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".code-editor").value).toBe("SELECT Id FROM Account");
	});

	it("validate() calls validateQuery with the current query", () => {
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" }]
		});
		element.validate();
		expect(validateQuery).toHaveBeenCalledWith({ queryToValidate: "SELECT Id FROM Account", bindKeys: [] });
	});

	it("validate() calls validateQuery with bind keys from current binds", () => {
		const binds = [{ key: "recordId", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [
				{ name: "query", value: "SELECT Id FROM Account WHERE Id = :recordId", valueDataType: "String" },
				{ name: "binds", value: binds, valueDataType: "sobject" }
			]
		});
		element.validate();
		expect(validateQuery).toHaveBeenCalledWith({
			queryToValidate: "SELECT Id FROM Account WHERE Id = :recordId",
			bindKeys: ["recordId"]
		});
	});

	it("validate() returns [] when validateQuery does not throw", async () => {
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" }]
		});
		expect(await element.validate()).toEqual([]);
		expect(Toast.show).not.toHaveBeenCalled();
	});

	it("validate() shows error toast when validateQuery rejects", async () => {
		validateQuery.mockRejectedValueOnce({ body: { message: "Invalid query syntax" } });
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT FROM Account", valueDataType: "String" }]
		});
		await element.validate();
		expect(Toast.show).toHaveBeenCalledWith(
			expect.objectContaining({ message: "Invalid query syntax", variant: "error" }),
			expect.any(Object)
		);
	});

	it("handleValidate() shows a success toast when validateQuery resolves", async () => {
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" }]
		});
		getButtonByLabel(element, "Validate").click();
		await flushPromises();
		expect(Toast.show).toHaveBeenCalledTimes(1);
		expect(Toast.show).toHaveBeenCalledWith(
			expect.objectContaining({ label: expect.stringMatching(/valid/i), variant: "success" }),
			expect.any(Object)
		);
	});

	it("handleValidate() shows an error toast when validateQuery rejects", async () => {
		validateQuery.mockRejectedValueOnce({ body: { message: "Unknown field: Namee" } });
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Namee FROM Account", valueDataType: "String" }]
		});
		getButtonByLabel(element, "Validate").click();
		await flushPromises();
		expect(Toast.show).toHaveBeenCalledWith(
			expect.objectContaining({ message: "Unknown field: Namee", variant: "error" }),
			expect.any(Object)
		);
	});

	it("dispatches configuration_editor_input_value_changed when query is entered", () => {
		const element = createComponent();
		const events = [];
		element.addEventListener("configuration_editor_input_value_changed", (e) => events.push(e));

		const textarea = element.shadowRoot.querySelector(".code-editor");
		textarea.value = "SELECT Id FROM Contact";
		textarea.dispatchEvent(new Event("change"));

		expect(events).toHaveLength(1);
		expect(events[0].detail).toEqual({
			name: "query",
			newValue: "SELECT Id FROM Contact",
			newValueDataType: "String"
		});
	});

	it("dispatches configuration_editor_input_value_deleted when query is cleared", () => {
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" }]
		});
		const deletedEvents = [];
		element.addEventListener("configuration_editor_input_value_deleted", (e) => deletedEvents.push(e));

		const textarea = element.shadowRoot.querySelector(".code-editor");
		textarea.value = "";
		textarea.dispatchEvent(new Event("change"));

		expect(deletedEvents).toHaveLength(1);
		expect(deletedEvents[0].detail.name).toBe("query");
	});

	it("renders an Add Bind Variable button", () => {
		const element = createComponent();
		expect(element.shadowRoot.querySelector("lightning-button")).not.toBeNull();
	});

	it("dispatches configuration_editor_input_value_changed with a new bind when Add is clicked", async () => {
		const element = createComponent({ inputVariables: [] });
		const events = [];
		element.addEventListener("configuration_editor_input_value_changed", (e) => events.push(e));

		getButtonByLabel(element, "Add Variable").click();
		await Promise.resolve();

		expect(events).toHaveLength(1);
		expect(events[0].detail.name).toBe("binds");
		expect(events[0].detail.newValue).toHaveLength(1);
		expect(events[0].detail.newValue[0]).toEqual({
			key: "",
			textValue: "",
			typeName: "String",
			isCollection: false
		});
		expect(element.shadowRoot.querySelectorAll("c-flow-untyped-variable-input")).toHaveLength(1);
	});

	it("updates a bind variable when a child emits change", () => {
		const initial = [{ key: "recordId", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [{ name: "binds", value: initial, valueDataType: "sobject" }]
		});
		const events = [];
		element.addEventListener("configuration_editor_input_value_changed", (e) => events.push(e));

		const bindInput = element.shadowRoot.querySelector("c-flow-untyped-variable-input");
		bindInput.dispatchEvent(
			new CustomEvent("change", {
				detail: { index: 0, variable: { key: "accountId", textValue: "", typeName: "Id", isCollection: false } }
			})
		);

		expect(events).toHaveLength(1);
		expect(events[0].detail.newValue[0].key).toBe("accountId");
	});

	it("dispatches configuration_editor_input_value_deleted for binds when last bind is removed", () => {
		const initial = [{ key: "recordId", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [{ name: "binds", value: initial, valueDataType: "sobject" }]
		});
		const deletedEvents = [];
		element.addEventListener("configuration_editor_input_value_deleted", (e) => deletedEvents.push(e));

		const bindInput = element.shadowRoot.querySelector("c-flow-untyped-variable-input");
		bindInput.dispatchEvent(new CustomEvent("remove", { detail: { index: 0 } }));

		expect(deletedEvents).toHaveLength(1);
		expect(deletedEvents[0].detail.name).toBe("binds");
	});
});
