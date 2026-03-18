import { createElement } from "lwc";
import FlowDmlOptions from "c/flowDmlOptions";

describe("c-flow-dml-options", () => {
	function createComponent(props = {}) {
		const element = createElement("c-flow-dml-options", { is: FlowDmlOptions });
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

	function fireToggle(element, name, checked) {
		const input = getInput(element, name);
		input.name = name;
		input.checked = checked;
		input.dispatchEvent(new CustomEvent("change"));
	}

	function fireText(element, name, value) {
		const input = getInput(element, name);
		input.name = name;
		input.value = value;
		input.dispatchEvent(new CustomEvent("change"));
	}

	function captureEvent(element, eventName) {
		const handler = jest.fn();
		element.addEventListener(eventName, handler);
		return handler;
	}

	it("renders without errors when no value prop is provided", () => {
		expect(() => createComponent()).not.toThrow();
	});

	describe("top-level fields", () => {
		it("emits dmloptionschange with updated allowFieldTruncation on toggle", () => {
			const element = createComponent();
			const handler = captureEvent(element, "dmloptionschange");
			fireToggle(element, "allowFieldTruncation", true);
			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail.value.allowFieldTruncation).toBe(true);
		});

		it("emits dmloptionschange with updated localeOptions on text change", () => {
			const element = createComponent();
			const handler = captureEvent(element, "dmloptionschange");
			fireText(element, "localeOptions", "en_US");
			expect(handler).toHaveBeenCalledTimes(1);
			expect(handler.mock.calls[0][0].detail.value.localeOptions).toBe("en_US");
		});

		it("preserves other top-level fields when emitting a partial update", () => {
			const element = createComponent({ value: { allowFieldTruncation: true, localeOptions: "en_US" } });
			const handler = captureEvent(element, "dmloptionschange");
			fireText(element, "localeOptions", "fr_FR");
			const emitted = handler.mock.calls[0][0].detail.value;
			expect(emitted.allowFieldTruncation).toBe(true);
			expect(emitted.localeOptions).toBe("fr_FR");
		});

		it("reflects a provided allowFieldTruncation value on the toggle input", () => {
			const element = createComponent({ value: { allowFieldTruncation: true } });
			expect(getInput(element, "allowFieldTruncation").checked).toBe(true);
		});

		it("reflects a provided localeOptions value on the text input", () => {
			const element = createComponent({ value: { localeOptions: "en_US" } });
			expect(getInput(element, "localeOptions").value).toBe("en_US");
		});
	});

	describe("assignmentRuleHeader", () => {
		it("emits dmloptionschange with nested assignmentRuleHeader on assignmentRuleId text change", () => {
			const element = createComponent();
			const handler = captureEvent(element, "dmloptionschange");
			fireText(element, "assignmentRuleId", "rule123");
			const rule = handler.mock.calls[0][0].detail.value.assignmentRuleHeader;
			expect(rule.assignmentRuleId).toBe("rule123");
			expect(rule.useDefaultRule).toBe(false);
		});

		it("emits dmloptionschange with nested assignmentRuleHeader on useDefaultRule toggle", () => {
			const element = createComponent();
			const handler = captureEvent(element, "dmloptionschange");
			fireToggle(element, "useDefaultRule", true);
			const rule = handler.mock.calls[0][0].detail.value.assignmentRuleHeader;
			expect(rule.useDefaultRule).toBe(true);
			expect(rule.assignmentRuleId).toBeNull();
		});
	});

	describe("duplicateRuleHeader", () => {
		it("emits dmloptionschange with nested duplicateRuleHeader on allowSave toggle", () => {
			const element = createComponent();
			const handler = captureEvent(element, "dmloptionschange");
			fireToggle(element, "allowSave", true);
			const rule = handler.mock.calls[0][0].detail.value.duplicateRuleHeader;
			expect(rule.allowSave).toBe(true);
			expect(rule.runAsCurrentUser).toBe(false);
		});

		it("emits dmloptionschange with nested duplicateRuleHeader on runAsCurrentUser toggle", () => {
			const element = createComponent();
			const handler = captureEvent(element, "dmloptionschange");
			fireToggle(element, "runAsCurrentUser", true);
			const rule = handler.mock.calls[0][0].detail.value.duplicateRuleHeader;
			expect(rule.runAsCurrentUser).toBe(true);
			expect(rule.allowSave).toBe(false);
		});
	});

	describe("emailHeader", () => {
		it("emits dmloptionschange with nested emailHeader on triggerAutoResponseEmail toggle", () => {
			const element = createComponent();
			const handler = captureEvent(element, "dmloptionschange");
			fireToggle(element, "triggerAutoResponseEmail", true);
			const header = handler.mock.calls[0][0].detail.value.emailHeader;
			expect(header.triggerAutoResponseEmail).toBe(true);
			expect(header.triggerOtherEmail).toBe(false);
			expect(header.triggerUserEmail).toBe(false);
		});

		it("emits dmloptionschange with nested emailHeader on triggerOtherEmail toggle", () => {
			const element = createComponent();
			const handler = captureEvent(element, "dmloptionschange");
			fireToggle(element, "triggerOtherEmail", true);
			const header = handler.mock.calls[0][0].detail.value.emailHeader;
			expect(header.triggerOtherEmail).toBe(true);
		});

		it("emits dmloptionschange with nested emailHeader on triggerUserEmail toggle", () => {
			const element = createComponent();
			const handler = captureEvent(element, "dmloptionschange");
			fireToggle(element, "triggerUserEmail", true);
			const header = handler.mock.calls[0][0].detail.value.emailHeader;
			expect(header.triggerUserEmail).toBe(true);
		});
	});
});
