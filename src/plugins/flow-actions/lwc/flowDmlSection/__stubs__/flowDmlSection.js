import { LightningElement, api } from "lwc";

/**
 * Pass-through stub for c-flow-dml-section used in Jest tests.
 * Always renders slot content so that nested elements are accessible via querySelectorAll.
 */
export default class FlowDmlSection extends LightningElement {
	@api label;
	@api isRequired;
}
