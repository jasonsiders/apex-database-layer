import { LightningElement, api, track } from "lwc";

export default class FlowDmlSection extends LightningElement {
	@api label;
	@api isRequired = false;

	@track _isExpanded;

	get isRequiredSection() {
		return !!this.isRequired && this.isRequired !== "false";
	}

	connectedCallback() {
		this._isExpanded = this.isRequiredSection;
	}

	get isExpanded() {
		return this._isExpanded;
	}

	get chevronIcon() {
		return this._isExpanded ? "utility:chevrondown" : "utility:chevronright";
	}

	handleToggle() {
		this._isExpanded = !this._isExpanded;
	}
}
