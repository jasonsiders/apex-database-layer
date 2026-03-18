import { createElement } from "lwc";
// Import via relative path to use the real implementation, not the jest stub
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

	describe("label", () => {
		it("displays the label text", () => {
			const element = createComponent({ label: "My Section" });
			const span = element.shadowRoot.querySelector(".section-label");
			expect(span.textContent).toBe("My Section");
		});
	});

	describe("collapsible behavior (isRequired = false)", () => {
		it("starts collapsed: section body is not rendered", () => {
			const element = createComponent({ label: "Section" });
			expect(element.shadowRoot.querySelector(".section-body")).toBeNull();
		});

		it("shows a right-pointing chevron when collapsed", () => {
			const element = createComponent({ label: "Section" });
			const icon = element.shadowRoot.querySelector("lightning-icon");
			expect(icon.iconName).toBe("utility:chevronright");
		});

		it("expands when the header is clicked", async () => {
			const element = createComponent({ label: "Section" });
			element.shadowRoot.querySelector(".section-header").click();
			await Promise.resolve();
			expect(element.shadowRoot.querySelector(".section-body")).not.toBeNull();
		});

		it("shows a down-pointing chevron when expanded", async () => {
			const element = createComponent({ label: "Section" });
			element.shadowRoot.querySelector(".section-header").click();
			await Promise.resolve();
			expect(element.shadowRoot.querySelector("lightning-icon").iconName).toBe("utility:chevrondown");
		});

		it("collapses again when the header is clicked a second time", async () => {
			const element = createComponent({ label: "Section" });
			const header = element.shadowRoot.querySelector(".section-header");
			header.click();
			await Promise.resolve();
			header.click();
			await Promise.resolve();
			expect(element.shadowRoot.querySelector(".section-body")).toBeNull();
		});
	});

	describe("required behavior (isRequired = true)", () => {
		it("is expanded by default", () => {
			const element = createComponent({ label: "Section", isRequired: true });
			expect(element.shadowRoot.querySelector(".section-body")).not.toBeNull();
		});

		it("renders the required header (no toggle chevron)", () => {
			const element = createComponent({ label: "Section", isRequired: true });
			expect(element.shadowRoot.querySelector(".section-header_required")).not.toBeNull();
			expect(element.shadowRoot.querySelector("lightning-icon")).toBeNull();
		});

		it('treats the string "true" the same as boolean true', () => {
			const element = createComponent({ label: "Section", isRequired: "true" });
			expect(element.shadowRoot.querySelector(".section-body")).not.toBeNull();
			expect(element.shadowRoot.querySelector("lightning-icon")).toBeNull();
		});

		it('treats the string "false" the same as boolean false', () => {
			const element = createComponent({ label: "Section", isRequired: "false" });
			expect(element.shadowRoot.querySelector(".section-body")).toBeNull();
			expect(element.shadowRoot.querySelector("lightning-icon").iconName).toBe("utility:chevronright");
		});
	});
});
