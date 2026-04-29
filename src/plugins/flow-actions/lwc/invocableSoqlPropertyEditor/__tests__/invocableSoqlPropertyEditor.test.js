import { createElement } from "@lwc/engine-dom";
import InvocableSoqlPropertyEditor from "c/invocableSoqlPropertyEditor";
import Toast from "lightning/toast";

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

	it("validate() returns an error when query is empty", () => {
		const element = createComponent({ inputVariables: [] });
		const errors = element.validate();
		expect(errors).toHaveLength(1);
		expect(errors[0]).toEqual({ key: "query", errorString: "Missing required field: Query" });
		expect(Toast.show).toHaveBeenCalledWith(
			{ message: "Missing required field: Query", variant: "error" },
			expect.any(Object)
		);
	});

	it("validate() returns no errors when query is set", () => {
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" }]
		});
		expect(element.validate()).toHaveLength(0);
		expect(Toast.show).not.toHaveBeenCalled();
	});

	it("handleValidate() shows an error toast when query is empty", () => {
		const element = createComponent({ inputVariables: [] });

		getButtonByLabel(element, "Validate").click();

		expect(Toast.show).toHaveBeenCalledTimes(1);
		expect(Toast.show).toHaveBeenCalledWith(
			{ message: "Missing required field: Query", variant: "error" },
			expect.any(Object)
		);
	});

	it("handleValidate() shows a success toast when query is set", () => {
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" }]
		});

		getButtonByLabel(element, "Validate").click();

		expect(Toast.show).toHaveBeenCalledTimes(1);
		expect(Toast.show).toHaveBeenCalledWith({ label: "Valid", variant: "success" }, expect.any(Object));
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
