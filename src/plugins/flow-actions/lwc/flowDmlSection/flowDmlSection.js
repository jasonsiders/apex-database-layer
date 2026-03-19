import { LightningElement, api, track } from "lwc";

export default class FlowDmlSection extends LightningElement {
	@api label;
	@api isRequired = false;
	@api expanded = false;
	@api collapsible;

	@track _isExpanded;

	get isRequiredSection() {
		return !!this.isRequired && this.isRequired !== "false";
	}

	get isCollapsible() {
		return this.collapsible !== false && this.collapsible !== "false" && !this.isRequiredSection;
	}

	connectedCallback() {
		this._isExpanded = this.isRequiredSection || this.expanded === true || this.expanded === "true";
	}

	get isExpanded() {
		return this._isExpanded;
	}

	get chevronIcon() {
		return this._isExpanded ? "utility:chevrondown" : "utility:chevronright";
	}

	handleToggle() {
		if (!this.isCollapsible) {
			return;
		}

		this._isExpanded = !this._isExpanded;
	}
}
