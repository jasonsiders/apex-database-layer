import { LightningElement, api, track } from 'lwc';

const ACCESS_LEVEL_OPTIONS = [
    { label: 'User Mode', value: 'USER_MODE' },
    { label: 'System Mode', value: 'SYSTEM_MODE' }
];

const DEFAULT_DML_OPTIONS = {
    allowFieldTruncation: false,
    localeOptions: null,
    assignmentRuleHeader: { assignmentRuleId: null, useDefaultRule: false },
    duplicateRuleHeader: { allowSave: false, runAsCurrentUser: false },
    emailHeader: { triggerAutoResponseEmail: false, triggerOtherEmail: false, triggerUserEmail: false }
};

const DEFAULT_BASE_INPUT = {
    accessLevelName: 'USER_MODE',
    allOrNone: true,
    dmlOptions: DEFAULT_DML_OPTIONS,
    record: null,
    records: []
};

function detectActionType(inputVariables) {
    const names = new Set((inputVariables || []).map(v => v.name));
    if (names.has('leadId')) return 'CONVERT';
    if (names.has('externalIdField')) return 'UPSERT';
    if (names.has('recordId') || names.has('recordIds')) return 'DELETE';
    return 'BASE';
}

export default class FlowDmlPropertyEditor extends LightningElement {
    @api inputVariables = [];
    @api outputVariables = [];
    @api genericTypeMappings = [];

    @track _vals = {};

    connectedCallback() {
        this._vals = this._buildVals();
    }

    _get(name) {
        return (this.inputVariables || []).find(v => v.name === name)?.value;
    }

    _buildVals() {
        const type = detectActionType(this.inputVariables);
        if (type === 'BASE') {
            return {
                record: this._get('record') ?? null,
                records: this._get('records') ?? [],
                accessLevelName: this._get('accessLevelName') ?? 'USER_MODE',
                allOrNone: this._get('allOrNone') ?? true,
                dmlOptions: this._get('dmlOptions') ?? { ...DEFAULT_DML_OPTIONS }
            };
        }
        if (type === 'DELETE') {
            return {
                recordId: this._get('recordId') ?? null,
                recordIds: this._get('recordIds') ?? [],
                baseInput: this._get('baseInput') ?? { ...DEFAULT_BASE_INPUT }
            };
        }
        if (type === 'UPSERT') {
            return {
                externalIdField: this._get('externalIdField') ?? null,
                baseInput: this._get('baseInput') ?? { ...DEFAULT_BASE_INPUT }
            };
        }
        // CONVERT
        return {
            leadId: this._get('leadId') ?? null,
            accountId: this._get('accountId') ?? null,
            accountName: this._get('accountName') ?? null,
            contactId: this._get('contactId') ?? null,
            convertedStatus: this._get('convertedStatus') ?? null,
            doNotCreateOpportunity: this._get('doNotCreateOpportunity') ?? false,
            opportunityId: this._get('opportunityId') ?? null,
            opportunityName: this._get('opportunityName') ?? null,
            overwriteLeadSource: this._get('overwriteLeadSource') ?? false,
            ownerId: this._get('ownerId') ?? null,
            sendNotificationEmail: this._get('sendNotificationEmail') ?? false,
            accessLevelName: this._get('accessLevelName') ?? 'USER_MODE',
            allOrNone: this._get('allOrNone') ?? true,
            dmlOptions: this._get('dmlOptions') ?? { ...DEFAULT_DML_OPTIONS }
        };
    }

    get vals() {
        return this._vals;
    }

    get baseInputVal() {
        return this._vals.baseInput ?? { ...DEFAULT_BASE_INPUT };
    }

    get actionType() {
        return detectActionType(this.inputVariables);
    }

    get isGroupA() { return this.actionType === 'BASE'; }
    get isGroupB() { return this.actionType === 'DELETE'; }
    get isGroupC() { return this.actionType === 'UPSERT'; }
    get isGroupD() { return this.actionType === 'CONVERT'; }

    get accessLevelOptions() {
        return ACCESS_LEVEL_OPTIONS;
    }

    _emit(name, newValue, newValueDataType) {
        this.dispatchEvent(new CustomEvent('configuration_editor_input_value_changed', {
            bubbles: true,
            cancelable: false,
            detail: { name, newValue, newValueDataType }
        }));
    }

    // Handlers for top-level flat variables (Groups A, D, and scalars in B/C)
    handleText(event) {
        const { name } = event.target;
        const value = event.target.value;
        this._vals = { ...this._vals, [name]: value };
        this._emit(name, value, 'String');
    }

    handleToggle(event) {
        const { name } = event.target;
        const checked = event.target.checked;
        this._vals = { ...this._vals, [name]: checked };
        this._emit(name, checked, 'Boolean');
    }

    handleCombobox(event) {
        const { name } = event.target;
        const value = event.detail.value;
        this._vals = { ...this._vals, [name]: value };
        this._emit(name, value, 'String');
    }

    // Handlers for baseInput sub-fields (Groups B, C)
    // Input names use "baseInput_<fieldName>" convention to avoid collision
    handleBaseInputText(event) {
        const field = event.target.name.replace('baseInput_', '');
        const value = event.target.value;
        const updated = { ...this._vals.baseInput, [field]: value };
        this._vals = { ...this._vals, baseInput: updated };
        this._emit('baseInput', updated, 'FlowDmlBaseInput');
    }

    handleBaseInputToggle(event) {
        const field = event.target.name.replace('baseInput_', '');
        const checked = event.target.checked;
        const updated = { ...this._vals.baseInput, [field]: checked };
        this._vals = { ...this._vals, baseInput: updated };
        this._emit('baseInput', updated, 'FlowDmlBaseInput');
    }

    handleBaseInputCombobox(event) {
        const field = event.target.name.replace('baseInput_', '');
        const value = event.detail.value;
        const updated = { ...this._vals.baseInput, [field]: value };
        this._vals = { ...this._vals, baseInput: updated };
        this._emit('baseInput', updated, 'FlowDmlBaseInput');
    }

    // DML Options change from flowDmlOptions sub-component
    handleDmlOptionsChange(event) {
        const updated = event.detail.value;
        this._vals = { ...this._vals, dmlOptions: updated };
        this._emit('dmlOptions', updated, 'FlowDmlOptions');
    }

    handleBaseInputDmlOptionsChange(event) {
        const updatedDmlOptions = event.detail.value;
        const updatedBaseInput = { ...this._vals.baseInput, dmlOptions: updatedDmlOptions };
        this._vals = { ...this._vals, baseInput: updatedBaseInput };
        this._emit('baseInput', updatedBaseInput, 'FlowDmlBaseInput');
    }

    @api validate() {
        const errors = [];
        const type = this.actionType;

        if (type === 'BASE') {
            if (!this._vals.record && !this._vals.records?.length) {
                errors.push({ key: 'record', errorString: 'Provide at least one record or a collection of records.' });
            }
        } else if (type === 'DELETE') {
            if (!this._vals.recordId && !this._vals.recordIds?.length) {
                errors.push({ key: 'recordId', errorString: 'Provide at least one Record Id or a collection of Record Ids.' });
            }
        } else if (type === 'UPSERT') {
            const base = this._vals.baseInput ?? {};
            if (!base.record && !base.records?.length) {
                errors.push({ key: 'baseInput', errorString: 'Provide at least one record or a collection of records in Base Input.' });
            }
        } else if (type === 'CONVERT') {
            if (!this._vals.leadId) {
                errors.push({ key: 'leadId', errorString: 'Lead ID is required.' });
            }
        }
        return errors;
    }
}
