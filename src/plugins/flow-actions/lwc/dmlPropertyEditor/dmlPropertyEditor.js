import { LightningElement, api } from 'lwc';

const BOOL_OPTIONS = [
	{ label: 'True', value: true },
	{ label: 'False', value: false }
];

const ACCESS_LEVEL_OPTIONS = [
	{ label: 'User Mode', value: 'USER_MODE' },
	{ label: 'System Mode', value: 'SYSTEM_MODE' }
];

const DML_FIELD_NAMES = new Set([
	'allowFieldTruncation',
	'localeOptions',
	'assignmentRuleId',
	'useDefaultRule',
	'allowSave',
	'runAsCurrentUser',
	'triggerAutoResponseEmail',
	'triggerOtherEmail',
	'triggerUserEmail'
]);

export default class DmlPropertyEditor extends LightningElement {
	@api genericTypeMappings;
	@api builderContext;

	_inputVariables;
	_values = {};
	_included = {};
	_dmlFields = {};

	@api
	get inputVariables() {
		return this._inputVariables;
	}

	set inputVariables(next) {
		this._inputVariables = next;
		this._seedValues(next ?? []);
	}

	@api validate() {
		const recordSet = this._included.record && this._values.record?.value != null;
		const recordsSet = this._included.records && this._values.records?.value != null;
		const recordCombobox = this.template.querySelector('c-flow-combobox[name="record"]');
		if (recordSet || recordsSet) {
			recordCombobox?.validate(null);
			return [];
		}
		const errorString = 'Provide at least one of "SObject Record" or "SObject Records".';
		recordCombobox?.validate(errorString);
		return [{ key: 'record', errorString }];
	}

	// ── Seeding ───────────────────────────────────────────────────────────────

	_seedValues(vars) {
		vars.forEach(({ name, value, valueDataType }) => {
			if (name === 'dmlOptions') {
				this._seedDmlFields(value);
			} else {
				this._values = { ...this._values, [name]: { value, valueDataType } };
			}
			if (value != null) {
				this._included = { ...this._included, [name]: true };
			}
		});
	}

	_seedDmlFields(obj) {
		if (!obj) return;
		const set = (name, value) => {
			if (value == null) return;
			this._dmlFields = { ...this._dmlFields, [name]: { value, valueDataType: null } };
			this._included = { ...this._included, [name]: true };
		};
		set('allowFieldTruncation', obj.allowFieldTruncation);
		set('localeOptions', obj.localeOptions);
		set('assignmentRuleId', obj.assignmentRuleHeader?.assignmentRuleId);
		set('useDefaultRule', obj.assignmentRuleHeader?.useDefaultRule);
		set('allowSave', obj.duplicateRuleHeader?.allowSave);
		set('runAsCurrentUser', obj.duplicateRuleHeader?.runAsCurrentUser);
		set('triggerAutoResponseEmail', obj.emailHeader?.triggerAutoResponseEmail);
		set('triggerOtherEmail', obj.emailHeader?.triggerOtherEmail);
		set('triggerUserEmail', obj.emailHeader?.triggerUserEmail);
	}

	// ── Resource Options ──────────────────────────────────────────────────────

	get _allVars() {
		return this.builderContext?.variables ?? [];
	}

	_toResourceOption(v) {
		return {
			referenceName: v.name,
			value: '{!' + v.name + '}',
			label: v.label ?? v.name,
			pillLabel: v.name,
			objectType: v.objectType,
			isCollection: v.isCollection ?? false,
			dataType: v.dataType
		};
	}

	get sobjectVars() {
		return this._allVars.filter((v) => v.objectType && !v.isCollection).map((v) => this._toResourceOption(v));
	}

	get sobjectCollectionVars() {
		return this._allVars.filter((v) => v.objectType && v.isCollection).map((v) => this._toResourceOption(v));
	}

	get stringVars() {
		return this._allVars.filter((v) => v.dataType === 'String' && !v.objectType).map((v) => this._toResourceOption(v));
	}

	get booleanVars() {
		return this._allVars.filter((v) => v.dataType === 'Boolean').map((v) => this._toResourceOption(v));
	}

	// ── Static options ────────────────────────────────────────────────────────

	get boolOptions() {
		return BOOL_OPTIONS;
	}

	get accessLevelOptions() {
		return ACCESS_LEVEL_OPTIONS;
	}

	// ── Per-field value/included/valueDataType getters ────────────────────────

	_val(name) {
		return this._values[name]?.value ?? null;
	}

	_dmlVal(name) {
		return this._dmlFields[name]?.value ?? null;
	}

	_isIncluded(name) {
		return this._included[name] ?? false;
	}

	_vdt(name) {
		return this._values[name]?.valueDataType ?? null;
	}

	_dmlVdt(name) {
		return this._dmlFields[name]?.valueDataType ?? null;
	}

	get recordValue() { return this._val('record'); }
	get recordsValue() { return this._val('records'); }
	get accessLevelNameValue() { return this._val('accessLevelName'); }
	get allOrNoneValue() { return this._val('allOrNone'); }
	get allowFieldTruncationValue() { return this._dmlVal('allowFieldTruncation'); }
	get localeOptionsValue() { return this._dmlVal('localeOptions'); }
	get assignmentRuleIdValue() { return this._dmlVal('assignmentRuleId'); }
	get useDefaultRuleValue() { return this._dmlVal('useDefaultRule'); }
	get allowSaveValue() { return this._dmlVal('allowSave'); }
	get runAsCurrentUserValue() { return this._dmlVal('runAsCurrentUser'); }
	get triggerAutoResponseEmailValue() { return this._dmlVal('triggerAutoResponseEmail'); }
	get triggerOtherEmailValue() { return this._dmlVal('triggerOtherEmail'); }
	get triggerUserEmailValue() { return this._dmlVal('triggerUserEmail'); }

	get recordIncluded() { return this._isIncluded('record'); }
	get recordsIncluded() { return this._isIncluded('records'); }
	get accessLevelNameIncluded() { return this._isIncluded('accessLevelName'); }
	get allOrNoneIncluded() { return this._isIncluded('allOrNone'); }
	get allowFieldTruncationIncluded() { return this._isIncluded('allowFieldTruncation'); }
	get localeOptionsIncluded() { return this._isIncluded('localeOptions'); }
	get assignmentRuleIdIncluded() { return this._isIncluded('assignmentRuleId'); }
	get useDefaultRuleIncluded() { return this._isIncluded('useDefaultRule'); }
	get allowSaveIncluded() { return this._isIncluded('allowSave'); }
	get runAsCurrentUserIncluded() { return this._isIncluded('runAsCurrentUser'); }
	get triggerAutoResponseEmailIncluded() { return this._isIncluded('triggerAutoResponseEmail'); }
	get triggerOtherEmailIncluded() { return this._isIncluded('triggerOtherEmail'); }
	get triggerUserEmailIncluded() { return this._isIncluded('triggerUserEmail'); }

	get recordValueDataType() { return this._vdt('record'); }
	get recordsValueDataType() { return this._vdt('records'); }
	get accessLevelNameValueDataType() { return this._vdt('accessLevelName'); }
	get allOrNoneValueDataType() { return this._vdt('allOrNone'); }
	get allowFieldTruncationValueDataType() { return this._dmlVdt('allowFieldTruncation'); }
	get localeOptionsValueDataType() { return this._dmlVdt('localeOptions'); }
	get assignmentRuleIdValueDataType() { return this._dmlVdt('assignmentRuleId'); }
	get useDefaultRuleValueDataType() { return this._dmlVdt('useDefaultRule'); }
	get allowSaveValueDataType() { return this._dmlVdt('allowSave'); }
	get runAsCurrentUserValueDataType() { return this._dmlVdt('runAsCurrentUser'); }
	get triggerAutoResponseEmailValueDataType() { return this._dmlVdt('triggerAutoResponseEmail'); }
	get triggerOtherEmailValueDataType() { return this._dmlVdt('triggerOtherEmail'); }
	get triggerUserEmailValueDataType() { return this._dmlVdt('triggerUserEmail'); }

	// ── Event Handlers ────────────────────────────────────────────────────────

	handleFieldChange(event) {
		const { name, value, valueDataType } = event.detail;
		DML_FIELD_NAMES.has(name)
			? this._handleDmlFieldChange(name, value, valueDataType)
			: this._handleTopLevelFieldChange(name, value, valueDataType);
	}

	_handleTopLevelFieldChange(name, value, valueDataType) {
		this._values = { ...this._values, [name]: { value, valueDataType } };
		this._dispatchChange(name, value, valueDataType);
	}

	_handleDmlFieldChange(name, value, valueDataType) {
		this._dmlFields = { ...this._dmlFields, [name]: { value, valueDataType } };
		const composed = this._composeDmlOptions();
		this._values = { ...this._values, dmlOptions: { value: composed, valueDataType: 'SObject' } };
		this._dispatchChange('dmlOptions', composed, 'SObject');
	}

	handleFieldIncludedChange(event) {
		const { name, included } = event.detail;
		this._included = { ...this._included, [name]: included };
		if (!included) this._clearField(name);
	}

	_clearField(name) {
		DML_FIELD_NAMES.has(name)
			? this._handleDmlFieldChange(name, null, null)
			: this._handleTopLevelFieldChange(name, null, null);
	}

	// ── DML Options Composition ───────────────────────────────────────────────

	_composeDmlOptions() {
		return {
			allowFieldTruncation: this._dmlFields.allowFieldTruncation?.value ?? null,
			localeOptions: this._dmlFields.localeOptions?.value ?? null,
			assignmentRuleHeader: this._buildIfAny(['assignmentRuleId', 'useDefaultRule'], {
				assignmentRuleId: this._dmlFields.assignmentRuleId?.value ?? null,
				useDefaultRule: this._dmlFields.useDefaultRule?.value ?? null
			}),
			duplicateRuleHeader: this._buildIfAny(['allowSave', 'runAsCurrentUser'], {
				allowSave: this._dmlFields.allowSave?.value ?? null,
				runAsCurrentUser: this._dmlFields.runAsCurrentUser?.value ?? null
			}),
			emailHeader: this._buildIfAny(['triggerAutoResponseEmail', 'triggerOtherEmail', 'triggerUserEmail'], {
				triggerAutoResponseEmail: this._dmlFields.triggerAutoResponseEmail?.value ?? null,
				triggerOtherEmail: this._dmlFields.triggerOtherEmail?.value ?? null,
				triggerUserEmail: this._dmlFields.triggerUserEmail?.value ?? null
			})
		};
	}

	_buildIfAny(fieldNames, obj) {
		return fieldNames.some((n) => this._dmlFields[n]?.value != null) ? obj : null;
	}

	// ── CPE Event Dispatch ────────────────────────────────────────────────────

	get recordTypeValue() {
		return (this.genericTypeMappings ?? []).find((m) => m.typeName === 'T__record')?.typeValue ?? null;
	}

	get recordsTypeValue() {
		return (this.genericTypeMappings ?? []).find((m) => m.typeName === 'T__records')?.typeValue ?? null;
	}

	_dispatchChange(name, newValue, newValueDataType) {
		this.dispatchEvent(
			new CustomEvent('configuration_editor_input_value_changed', {
				bubbles: true,
				cancelable: false,
				composed: true,
				detail: { name, newValue, newValueDataType }
			})
		);
	}
}
