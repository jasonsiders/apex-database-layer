import { createElement } from "@lwc/engine-dom";
import SoqlBindInput from "c/soqlBindInput";

describe("c-soql-bind-input", () => {
	function createComponent(props = {}) {
		const element = createElement("c-soql-bind-input", {
			is: SoqlBindInput
		});
		Object.assign(element, props);
		document.body.appendChild(element);
		return element;
	}

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	const defaultVariable = { key: "recordId", textValue: "{!myRecord.Id}", typeName: "String", isCollection: false };

	it("renders key, type, value, and remove inputs", () => {
		const element = createComponent({ variable: defaultVariable });
		expect(element.shadowRoot.querySelector('[data-id="key"]')).not.toBeNull();
		expect(element.shadowRoot.querySelector('[data-id="type"]')).not.toBeNull();
		expect(element.shadowRoot.querySelector('[data-id="value"]')).not.toBeNull();
		expect(element.shadowRoot.querySelector("lightning-button-icon")).not.toBeNull();
	});

	it("reflects variable props into inputs", async () => {
		const element = createComponent({ variable: defaultVariable });
		await Promise.resolve();
		expect(element.shadowRoot.querySelector('[data-id="key"]').value).toBe("recordId");
		expect(element.shadowRoot.querySelector('[data-id="type"]').value).toBe("Text");
	});

	it("passes builderContext to the value combobox", async () => {
		const builderContext = { variables: [{ name: "myVar", dataType: "String" }] };
		const element = createComponent({
			variable: defaultVariable,
			builderContext
		});
		await Promise.resolve();

		const valueInput = element.shadowRoot.querySelector('[data-id="value"]');
		expect(valueInput.builderContext).toEqual(builderContext);
	});

	it("passes fieldDataType and fieldIsCollection to the value combobox based on selected type", async () => {
		const builderContext = { variables: [] };
		const element = createComponent({
			variable: { ...defaultVariable, typeName: "SObject", isCollection: true },
			builderContext
		});
		await Promise.resolve();

		const valueInput = element.shadowRoot.querySelector('[data-id="value"]');
		expect(valueInput.fieldDataType).toBe("SObject");
		expect(valueInput.fieldIsCollection).toBe(true);
	});

	it("emits change with updated key when key input changes", () => {
		const element = createComponent({ index: 0, variable: defaultVariable });
		const events = [];
		element.addEventListener("change", (e) => events.push(e));

		const keyInput = element.shadowRoot.querySelector('[data-id="key"]');
		keyInput.value = "accountId";
		keyInput.dispatchEvent(new Event("change"));

		expect(events).toHaveLength(1);
		expect(events[0].detail).toEqual({ index: 0, patch: { key: "accountId" } });
	});

	it("sets custom validity on the bind name input when validate() receives an error", () => {
		const element = createComponent({ variable: defaultVariable });
		const keyInput = element.shadowRoot.querySelector('[data-id="key"]');
		const setCustomValidity = jest.spyOn(keyInput, "setCustomValidity");
		const reportValidity = jest.spyOn(keyInput, "reportValidity");

		expect(element.validate("Bind variable is not referenced by the query.")).toBe(false);

		expect(setCustomValidity).toHaveBeenLastCalledWith("Bind variable is not referenced by the query.");
		expect(reportValidity).toHaveBeenCalled();
	});

	it("clears custom validity when the bind name is edited", () => {
		const element = createComponent({ variable: defaultVariable });
		const keyInput = element.shadowRoot.querySelector('[data-id="key"]');
		const setCustomValidity = jest.spyOn(keyInput, "setCustomValidity");

		element.validate("Bind variable is not referenced by the query.");
		keyInput.value = "accountId";
		keyInput.dispatchEvent(new Event("input"));

		expect(setCustomValidity).toHaveBeenLastCalledWith("");
	});

	it("emits change with updated typeName when type input changes", () => {
		const element = createComponent({ index: 1, variable: defaultVariable });
		const events = [];
		element.addEventListener("change", (e) => events.push(e));

		const typeInput = element.shadowRoot.querySelector('[data-id="type"]');
		typeInput.dispatchEvent(new CustomEvent("change", { detail: { value: "Number" } }));

		expect(events).toHaveLength(1);
		expect(events[0].detail).toEqual({
			index: 1,
			patch: { typeName: "Decimal", isCollection: false }
		});
	});

	it("emits change with updated isCollection when a collection type is selected", () => {
		const element = createComponent({ index: 0, variable: defaultVariable });
		const events = [];
		element.addEventListener("change", (e) => events.push(e));

		element.shadowRoot
			.querySelector('[data-id="type"]')
			.dispatchEvent(new CustomEvent("change", { detail: { value: "Text (Collection)" } }));

		expect(events).toHaveLength(1);
		expect(events[0].detail).toEqual({ index: 0, patch: { typeName: "String", isCollection: true } });
	});

	it("emits change with updated textValue when value combobox changes", () => {
		const element = createComponent({ index: 0, variable: defaultVariable });
		const events = [];
		element.addEventListener("change", (e) => events.push(e));

		element.shadowRoot.querySelector('[data-id="value"]').dispatchEvent(
			new CustomEvent("fieldchange", {
				detail: { name: "textValue", value: "{!newVar}", valueDataType: "reference" }
			})
		);

		expect(events).toHaveLength(1);
		expect(events[0].detail).toEqual({ index: 0, patch: { textValue: "{!newVar}" } });
	});

	it("emits remove event with index when remove button is clicked", () => {
		const element = createComponent({ index: 2, variable: defaultVariable });
		const events = [];
		element.addEventListener("remove", (e) => events.push(e));

		element.shadowRoot.querySelector("lightning-button-icon").click();

		expect(events).toHaveLength(1);
		expect(events[0].detail).toEqual({ index: 2 });
	});
});
