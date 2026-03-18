import { LightningElement, api } from "lwc";

const DEFAULT_ASSIGNMENT_RULE = { assignmentRuleId: null, useDefaultRule: false };
const DEFAULT_DUPLICATE_RULE = { allowSave: false, runAsCurrentUser: false };
const DEFAULT_EMAIL_HEADER = { triggerAutoResponseEmail: false, triggerOtherEmail: false, triggerUserEmail: false };

export default class FlowDmlOptions extends LightningElement {
	@api value;

	get safeValue() {
		return this.value ?? {};
	}

	get assignmentRule() {
		return this.safeValue.assignmentRuleHeader ?? DEFAULT_ASSIGNMENT_RULE;
	}

	get duplicateRule() {
		return this.safeValue.duplicateRuleHeader ?? DEFAULT_DUPLICATE_RULE;
	}

	get emailHeader() {
		return this.safeValue.emailHeader ?? DEFAULT_EMAIL_HEADER;
	}

	_emit(updated) {
		this.dispatchEvent(new CustomEvent("dmloptionschange", { detail: { value: updated } }));
	}

	_merge(patch) {
		this._emit({ ...this.safeValue, ...patch });
	}

	handleText(event) {
		this._merge({ [event.target.name]: event.target.value });
	}

	handleToggle(event) {
		this._merge({ [event.target.name]: event.target.checked });
	}

	handleAssignmentRuleText(event) {
		this._merge({
			assignmentRuleHeader: { ...this.assignmentRule, [event.target.name]: event.target.value }
		});
	}

	handleAssignmentRuleToggle(event) {
		this._merge({
			assignmentRuleHeader: { ...this.assignmentRule, [event.target.name]: event.target.checked }
		});
	}

	handleDuplicateRuleToggle(event) {
		this._merge({
			duplicateRuleHeader: { ...this.duplicateRule, [event.target.name]: event.target.checked }
		});
	}

	handleEmailHeaderToggle(event) {
		this._merge({
			emailHeader: { ...this.emailHeader, [event.target.name]: event.target.checked }
		});
	}
}
