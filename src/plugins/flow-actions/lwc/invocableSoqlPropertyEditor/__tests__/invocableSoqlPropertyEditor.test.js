import { createElement } from "@lwc/engine-dom";
import InvocableSoqlPropertyEditor from "c/invocableSoqlPropertyEditor";
import validateQuery from "@salesforce/apex/InvocableSoql.validateQuery";

jest.mock("@salesforce/apex/InvocableSoql.validateQuery", () => ({ default: jest.fn().mockResolvedValue(undefined) }), {
	virtual: true
});

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

	function expectFlowEventContract(event) {
		expect(event.bubbles).toBe(true);
		expect(event.composed).toBe(true);
		expect(event.cancelable).toBe(false);
	}

	function expectSerializedBinds(event, expectedBinds) {
		expect(event.detail.name).toBe("bindsJson");
		expect(event.detail.newValueDataType).toBe("String");
		expect(JSON.parse(event.detail.newValue)).toEqual(expectedBinds);
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
				{ name: "bindsJson", value: JSON.stringify(binds), valueDataType: "String" }
			]
		});
		element.validate();
		expect(validateQuery).toHaveBeenCalledWith({
			queryToValidate: "SELECT Id FROM Account WHERE Id = :recordId",
			bindKeys: ["recordId"]
		});
	});

	it("validate() sets custom validity on orphaned bind variables", async () => {
		const binds = [
			{ key: "name", textValue: "", typeName: "String", isCollection: false },
			{ key: "foo", textValue: "", typeName: "String", isCollection: false }
		];
		const element = createComponent({
			inputVariables: [
				{ name: "query", value: "SELECT Id FROM Account WHERE Name = :name", valueDataType: "String" },
				{ name: "bindsJson", value: JSON.stringify(binds), valueDataType: "String" }
			]
		});
		await Promise.resolve();
		const [, orphanedBindInput] = element.shadowRoot.querySelectorAll("c-soql-bind-input");
		const keyInput = orphanedBindInput.shadowRoot.querySelector('[data-id="key"]');
		const setCustomValidity = jest.spyOn(keyInput, "setCustomValidity");
		const reportValidity = jest.spyOn(keyInput, "reportValidity");

		const result = await element.validate();

		expect(validateQuery).not.toHaveBeenCalled();
		expect(result).toEqual([
			{
				key: "bindsJson",
				errorString: 'Bind variable "foo" is not referenced by the query.'
			}
		]);
		expect(setCustomValidity).toHaveBeenLastCalledWith('Bind variable "foo" is not referenced by the query.');
		expect(reportValidity).toHaveBeenCalled();
	});

	it("validate() sets custom validity on duplicate bind variables", async () => {
		const binds = [
			{ key: "name", textValue: "", typeName: "String", isCollection: false },
			{ key: "name", textValue: "", typeName: "String", isCollection: false }
		];
		const element = createComponent({
			inputVariables: [
				{ name: "query", value: "SELECT Id FROM Account WHERE Name = :name", valueDataType: "String" },
				{ name: "bindsJson", value: JSON.stringify(binds), valueDataType: "String" }
			]
		});
		await Promise.resolve();
		const [firstBindInput, secondBindInput] = element.shadowRoot.querySelectorAll("c-soql-bind-input");
		const firstSetCustomValidity = jest.spyOn(
			firstBindInput.shadowRoot.querySelector('[data-id="key"]'),
			"setCustomValidity"
		);
		const secondSetCustomValidity = jest.spyOn(
			secondBindInput.shadowRoot.querySelector('[data-id="key"]'),
			"setCustomValidity"
		);

		const result = await element.validate();

		expect(validateQuery).not.toHaveBeenCalled();
		expect(result).toEqual([
			{
				key: "bindsJson",
				errorString: 'Bind variable "name" is already defined.'
			},
			{
				key: "bindsJson",
				errorString: 'Bind variable "name" is already defined.'
			}
		]);
		expect(firstSetCustomValidity).toHaveBeenLastCalledWith('Bind variable "name" is already defined.');
		expect(secondSetCustomValidity).toHaveBeenLastCalledWith('Bind variable "name" is already defined.');
	});

	it("validate() sets custom validity on bind names with spaces or special characters", async () => {
		const binds = [{ key: "bad key!", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [
				{ name: "query", value: "SELECT Id FROM Account WHERE Name = :bad_key", valueDataType: "String" },
				{ name: "bindsJson", value: JSON.stringify(binds), valueDataType: "String" }
			]
		});
		await Promise.resolve();
		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		const setCustomValidity = jest.spyOn(
			bindInput.shadowRoot.querySelector('[data-id="key"]'),
			"setCustomValidity"
		);

		const result = await element.validate();

		expect(validateQuery).not.toHaveBeenCalled();
		expect(result).toEqual([
			{
				key: "bindsJson",
				errorString:
					"Bind variable names can contain only letters, numbers, and underscores, and must start with a letter or underscore."
			}
		]);
		expect(setCustomValidity).toHaveBeenLastCalledWith(
			"Bind variable names can contain only letters, numbers, and underscores, and must start with a letter or underscore."
		);
	});

	it("validate() sets custom validity on bind names that start with a number", async () => {
		const binds = [{ key: "1name", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [
				{ name: "query", value: "SELECT Id FROM Account WHERE Name = :name", valueDataType: "String" },
				{ name: "bindsJson", value: JSON.stringify(binds), valueDataType: "String" }
			]
		});
		await Promise.resolve();
		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		const setCustomValidity = jest.spyOn(
			bindInput.shadowRoot.querySelector('[data-id="key"]'),
			"setCustomValidity"
		);

		await element.validate();

		expect(setCustomValidity).toHaveBeenLastCalledWith(
			"Bind variable names can contain only letters, numbers, and underscores, and must start with a letter or underscore."
		);
	});

	it("validate() flags all bind variables as orphaned when the query has no bind references", async () => {
		const binds = [{ key: "name", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [
				{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" },
				{ name: "bindsJson", value: JSON.stringify(binds), valueDataType: "String" }
			]
		});
		await Promise.resolve();
		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		const setCustomValidity = jest.spyOn(
			bindInput.shadowRoot.querySelector('[data-id="key"]'),
			"setCustomValidity"
		);

		await element.validate();

		expect(setCustomValidity).toHaveBeenLastCalledWith('Bind variable "name" is not referenced by the query.');
	});

	it("validate() ignores bind-like text inside quoted query literals", async () => {
		const binds = [{ key: "foo", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [
				{ name: "query", value: "SELECT Id FROM Account WHERE Name = ':foo'", valueDataType: "String" },
				{ name: "bindsJson", value: JSON.stringify(binds), valueDataType: "String" }
			]
		});
		await Promise.resolve();
		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		const setCustomValidity = jest.spyOn(
			bindInput.shadowRoot.querySelector('[data-id="key"]'),
			"setCustomValidity"
		);

		await element.validate();

		expect(setCustomValidity).toHaveBeenLastCalledWith('Bind variable "foo" is not referenced by the query.');
	});

	it("clears orphaned bind custom validity when the query is edited to use the bind", async () => {
		const binds = [{ key: "foo", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [
				{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" },
				{ name: "bindsJson", value: JSON.stringify(binds), valueDataType: "String" }
			]
		});
		await Promise.resolve();
		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		const keyInput = bindInput.shadowRoot.querySelector('[data-id="key"]');
		const setCustomValidity = jest.spyOn(keyInput, "setCustomValidity");

		await element.validate();
		const textarea = element.shadowRoot.querySelector(".code-editor");
		textarea.value = "SELECT Id FROM Account WHERE Name = :foo";
		textarea.dispatchEvent(new Event("input"));
		await Promise.resolve();

		expect(setCustomValidity).toHaveBeenLastCalledWith("");
	});

	it("validate() returns [] when validateQuery does not throw", async () => {
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" }]
		});
		expect(await element.validate()).toEqual([]);
	});

	it("validate() renders an inline SLDS error when validateQuery rejects", async () => {
		validateQuery.mockRejectedValueOnce({ body: { message: "Invalid query syntax" } });
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT FROM Account", valueDataType: "String" }]
		});
		await element.validate();
		await Promise.resolve();
		const errorEl = element.shadowRoot.querySelector(".slds-form-element__help");
		expect(errorEl).not.toBeNull();
		expect(errorEl.textContent).toBe("Error: Invalid query syntax");
		expect(element.shadowRoot.querySelector(".slds-has-error")).not.toBeNull();
	});

	it("handleValidate() renders an inline SLDS success message when validateQuery resolves", async () => {
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Id FROM Account", valueDataType: "String" }]
		});
		getButtonByLabel(element, "Validate").click();
		await flushPromises();
		const successEl = element.shadowRoot.querySelector(".slds-text-color_success");
		expect(successEl).not.toBeNull();
		expect(successEl.textContent).toBe("✓ Valid");
	});

	it("validate() clears the inline error when validateQuery resolves after a prior failure", async () => {
		validateQuery.mockRejectedValueOnce({ body: { message: "Bad query" } });
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT FROM Account", valueDataType: "String" }]
		});
		await element.validate();
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".slds-form-element__help")).not.toBeNull();

		await element.validate();
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".slds-form-element__help")).toBeNull();
		expect(element.shadowRoot.querySelector(".slds-has-error")).toBeNull();
	});

	it("handleValidate() renders an inline SLDS error when validateQuery rejects", async () => {
		validateQuery.mockRejectedValueOnce({ body: { message: "Unknown field: Namee" } });
		const element = createComponent({
			inputVariables: [{ name: "query", value: "SELECT Namee FROM Account", valueDataType: "String" }]
		});
		getButtonByLabel(element, "Validate").click();
		await flushPromises();
		const errorEl = element.shadowRoot.querySelector(".slds-form-element__help");
		expect(errorEl).not.toBeNull();
		expect(errorEl.textContent).toBe("Error: Unknown field: Namee");
		expect(element.shadowRoot.querySelector(".slds-has-error")).not.toBeNull();
	});

	it("dispatches configuration_editor_input_value_changed when query is entered", () => {
		const element = createComponent();
		const events = [];
		element.addEventListener("configuration_editor_input_value_changed", (e) => events.push(e));

		const textarea = element.shadowRoot.querySelector(".code-editor");
		textarea.value = "SELECT Id FROM Contact";
		textarea.dispatchEvent(new Event("input"));

		expect(events).toHaveLength(1);
		expectFlowEventContract(events[0]);
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
		textarea.dispatchEvent(new Event("input"));

		expect(deletedEvents).toHaveLength(1);
		expectFlowEventContract(deletedEvents[0]);
		expect(deletedEvents[0].detail).toEqual({ name: "query" });
	});

	it("dispatches generic output type mappings when the query root object is entered", () => {
		const element = createComponent();
		const events = [];
		element.addEventListener("configuration_editor_generic_type_mapping_changed", (e) => events.push(e));

		const textarea = element.shadowRoot.querySelector(".code-editor");
		textarea.value = "SELECT Id FROM Account";
		textarea.dispatchEvent(new Event("input"));

		expect(events).toHaveLength(2);
		expectFlowEventContract(events[0]);
		expect(events.map((event) => event.detail)).toEqual([
			{ typeName: "U__allResults", typeValue: "Account" },
			{ typeName: "U__firstResult", typeValue: "Account" }
		]);
	});

	it("uses the top-level query object for generic output type mappings", () => {
		const element = createComponent();
		const events = [];
		element.addEventListener("configuration_editor_generic_type_mapping_changed", (e) => events.push(e));

		const textarea = element.shadowRoot.querySelector(".code-editor");
		textarea.value = "SELECT Id, (SELECT Id FROM Contacts) FROM Account";
		textarea.dispatchEvent(new Event("input"));

		expect(events.map((event) => event.detail.typeValue)).toEqual(["Account", "Account"]);
	});

	it("renders an Add Bind Variable button", () => {
		const element = createComponent();
		expect(element.shadowRoot.querySelector("lightning-button")).not.toBeNull();
	});

	it("dispatches configuration_editor_input_value_changed with serialized binds when Add is clicked", async () => {
		const element = createComponent({ inputVariables: [] });
		const events = [];
		element.addEventListener("configuration_editor_input_value_changed", (e) => events.push(e));

		getButtonByLabel(element, "Add Variable").click();
		await Promise.resolve();

		expect(events).toHaveLength(1);
		expectFlowEventContract(events[0]);
		expectSerializedBinds(events[0], [
			{
				key: "",
				textValue: "",
				typeName: "String",
				isCollection: false
			}
		]);
		expect(element.shadowRoot.querySelectorAll("c-soql-bind-input")).toHaveLength(1);
	});

	it("passes builderContext to bind input for resource derivation", async () => {
		const builderContext = {
			variables: [
				{ name: "accountName", dataType: "String" },
				{
					name: "opp",
					label: "opp",
					dataType: "SObject",
					objectType: "Opportunity",
					fields: [
						{ name: "Name", dataType: "String" },
						{ name: "CloseDate", dataType: "Date" }
					]
				}
			]
		};
		const element = createComponent({ builderContext });

		getButtonByLabel(element, "Add Variable").click();
		await Promise.resolve();

		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		expect(bindInput.builderContext).toEqual(builderContext);
	});

	it("passes builderContext through to flow combobox for resource derivation", async () => {
		const builderContext = {
			variables: [{ name: "accountName", label: "accountName" }],
			recordVariables: [
				{
					name: "opp",
					label: "opp",
					objectType: "Opportunity",
					fields: [{ name: "Name", dataType: "String" }]
				}
			]
		};
		const element = createComponent({ builderContext });

		getButtonByLabel(element, "Add Variable").click();
		await Promise.resolve();

		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		const valueCombobox = bindInput.shadowRoot.querySelector("c-flow-combobox");
		expect(valueCombobox.builderContext).toEqual(builderContext);
	});

	it("passes builderContext with recordLookups to bind input", async () => {
		const builderContext = {
			variables: [{ name: "Get_Records", label: "Get Records" }],
			recordLookups: [
				{
					name: "Get_Records",
					label: "Get Records",
					object: "Account",
					getFirstRecordOnly: true,
					queriedFields: ["Id", "Name"]
				}
			]
		};
		const element = createComponent({ builderContext });

		getButtonByLabel(element, "Add Variable").click();
		await Promise.resolve();

		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		expect(bindInput.builderContext).toEqual(builderContext);
	});

	it("updates a bind variable when a child emits change", () => {
		const initial = [{ key: "recordId", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [{ name: "bindsJson", value: JSON.stringify(initial), valueDataType: "String" }]
		});
		const events = [];
		element.addEventListener("configuration_editor_input_value_changed", (e) => events.push(e));

		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		bindInput.dispatchEvent(
			new CustomEvent("change", {
				detail: { index: 0, patch: { key: "accountId", typeName: "Id" } }
			})
		);

		expect(events).toHaveLength(1);
		expectFlowEventContract(events[0]);
		expectSerializedBinds(events[0], [{ key: "accountId", textValue: "", typeName: "Id", isCollection: false }]);
	});

	it("removes the selected bind variable when a child emits a string index", async () => {
		const initial = [
			{ key: "recordId", textValue: "", typeName: "String", isCollection: false },
			{ key: "accountId", textValue: "", typeName: "String", isCollection: false }
		];
		const element = createComponent({
			inputVariables: [{ name: "bindsJson", value: JSON.stringify(initial), valueDataType: "String" }]
		});
		const events = [];
		element.addEventListener("configuration_editor_input_value_changed", (e) => events.push(e));

		const [, secondBindInput] = element.shadowRoot.querySelectorAll("c-soql-bind-input");
		secondBindInput.dispatchEvent(new CustomEvent("remove", { detail: { index: "1" } }));
		await Promise.resolve();

		expect(events).toHaveLength(1);
		expectFlowEventContract(events[0]);
		expectSerializedBinds(events[0], [{ key: "recordId", textValue: "", typeName: "String", isCollection: false }]);
		expect(element.shadowRoot.querySelectorAll("c-soql-bind-input")).toHaveLength(1);
	});

	it("dispatches configuration_editor_input_value_deleted for bindsJson when last bind is removed", () => {
		const initial = [{ key: "recordId", textValue: "", typeName: "String", isCollection: false }];
		const element = createComponent({
			inputVariables: [{ name: "bindsJson", value: JSON.stringify(initial), valueDataType: "String" }]
		});
		const deletedEvents = [];
		element.addEventListener("configuration_editor_input_value_deleted", (e) => deletedEvents.push(e));

		const bindInput = element.shadowRoot.querySelector("c-soql-bind-input");
		bindInput.dispatchEvent(new CustomEvent("remove", { detail: { index: 0 } }));

		expect(deletedEvents).toHaveLength(1);
		expectFlowEventContract(deletedEvents[0]);
		expect(deletedEvents[0].detail).toEqual({ name: "bindsJson" });
	});

});
