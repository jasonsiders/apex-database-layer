import { createElement } from "lwc";
import FlowDmlSection from "../flowDmlSection";

describe("c-flow-dml-section", () => {
	function createComponent(props = {}) {
		const element = createElement("c-flow-dml-section", { is: FlowDmlSection });
		Object.assign(element, props);
		document.body.appendChild(element);
		return element;
	}

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	it("displays the section label", () => {
		const element = createComponent({ label: "My Section" });
		expect(element.shadowRoot.querySelector(".section-label").textContent).toBe("My Section");
	});

	it("starts collapsed when the section is collapsible", () => {
		const element = createComponent({ label: "Section" });
		expect(element.shadowRoot.querySelector(".section-body")).toBeNull();
		expect(element.shadowRoot.querySelector("lightning-icon").iconName).toBe("utility:chevronright");
	});

	it("toggles open and closed when the header is clicked", async () => {
		const element = createComponent({ label: "Section" });
		const header = element.shadowRoot.querySelector(".section-header");

		header.click();
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".section-body")).not.toBeNull();
		expect(element.shadowRoot.querySelector("lightning-icon").iconName).toBe("utility:chevrondown");

		header.click();
		await Promise.resolve();
		expect(element.shadowRoot.querySelector(".section-body")).toBeNull();
	});

	it("stays expanded and hides the chevron when the section is required", () => {
		const element = createComponent({ label: "Section", isRequired: true });
		expect(element.shadowRoot.querySelector(".section-body")).not.toBeNull();
		expect(element.shadowRoot.querySelector("lightning-icon")).toBeNull();
	});

	it("supports non-collapsible expanded sections", () => {
		const element = createComponent({ label: "Always Open", expanded: true, collapsible: false });
		expect(element.shadowRoot.querySelector(".section-body")).not.toBeNull();
		expect(element.shadowRoot.querySelector("lightning-icon")).toBeNull();
	});
});
