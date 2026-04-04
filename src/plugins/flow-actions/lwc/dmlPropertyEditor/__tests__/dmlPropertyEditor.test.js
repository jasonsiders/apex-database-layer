import { createElement } from 'lwc';
import DmlPropertyEditor from 'c/dmlPropertyEditor';

describe('c-dml-property-editor', () => {
	function createComponent(props = {}) {
		const element = createElement('c-dml-property-editor', { is: DmlPropertyEditor });
		Object.assign(element, props);
		document.body.appendChild(element);
		return element;
	}

	// Dispatches from inside the shadow so handlers on the editor div fire.
	function dispatchFieldChange(element, name, value, valueDataType) {
		element.shadowRoot.querySelector('.editor').dispatchEvent(
			new CustomEvent('fieldchange', {
				bubbles: true,
				composed: true,
				detail: { name, value, valueDataType }
			})
		);
	}

	function dispatchFieldIncludedChange(element, name, included) {
		element.shadowRoot.querySelector('.editor').dispatchEvent(
			new CustomEvent('fieldincludedchange', {
				bubbles: true,
				composed: true,
				detail: { name, included }
			})
		);
	}

	afterEach(() => {
		while (document.body.firstChild) {
			document.body.removeChild(document.body.firstChild);
		}
	});

	// ── Rendering ─────────────────────────────────────────────────────────────

	it('renders 13 flow-combobox rows for all input fields', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		const comboboxes = element.shadowRoot.querySelectorAll('c-flow-combobox');
		expect(comboboxes).toHaveLength(13);
	});

	it('renders three section headers', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		const headings = [...element.shadowRoot.querySelectorAll('.section-title')].map((h) => h.textContent);
		expect(headings).toEqual(['Records', 'Options', 'DML Options']);
	});

	// ── inputVariables seeding via validate() ─────────────────────────────────

	it('validate returns empty array when record is seeded via inputVariables', () => {
		const element = createComponent({
			inputVariables: [{ name: 'record', value: '{!myRecord}', valueDataType: 'reference' }]
		});

		expect(element.validate()).toEqual([]);
	});

	it('validate returns empty array when records is seeded via inputVariables', () => {
		const element = createComponent({
			inputVariables: [{ name: 'records', value: '{!myRecords}', valueDataType: 'reference' }]
		});

		expect(element.validate()).toEqual([]);
	});

	it('preserves seeded dmlOptions sub-fields when a new DML field changes', async () => {
		const element = createComponent({
			inputVariables: [
				{
					name: 'dmlOptions',
					value: { allowFieldTruncation: true },
					valueDataType: 'SObject'
				}
			]
		});
		await Promise.resolve();

		const cpeEvents = [];
		element.addEventListener('configuration_editor_input_value_changed', (e) => cpeEvents.push(e));

		dispatchFieldChange(element, 'localeOptions', 'en_US', 'String');

		const composed = cpeEvents[0].detail.newValue;
		// Seeded value is preserved in the composed object alongside the new field.
		expect(composed.allowFieldTruncation).toBe(true);
		expect(composed.localeOptions).toBe('en_US');
	});

	// ── fieldchange → CPE event ────────────────────────────────────────────────

	it('dispatches configuration_editor_input_value_changed for a top-level field change', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		const cpeEvents = [];
		element.addEventListener('configuration_editor_input_value_changed', (e) => cpeEvents.push(e));

		dispatchFieldChange(element, 'record', '{!myRecord}', 'reference');

		expect(cpeEvents).toHaveLength(1);
		expect(cpeEvents[0].detail.name).toBe('record');
		expect(cpeEvents[0].detail.newValue).toBe('{!myRecord}');
		expect(cpeEvents[0].detail.newValueDataType).toBe('reference');
	});

	it('dispatches dmlOptions CPE event with composed object when a DML sub-field changes', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		const cpeEvents = [];
		element.addEventListener('configuration_editor_input_value_changed', (e) => cpeEvents.push(e));

		dispatchFieldChange(element, 'allowFieldTruncation', true, 'Boolean');

		expect(cpeEvents).toHaveLength(1);
		expect(cpeEvents[0].detail.name).toBe('dmlOptions');
		expect(cpeEvents[0].detail.newValue.allowFieldTruncation).toBe(true);
		expect(cpeEvents[0].detail.newValue.assignmentRuleHeader).toBeNull();
	});

	it('includes assignmentRuleHeader in dmlOptions only when a sub-field is set', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		const cpeEvents = [];
		element.addEventListener('configuration_editor_input_value_changed', (e) => cpeEvents.push(e));

		dispatchFieldChange(element, 'assignmentRuleId', 'ruleId123', 'String');

		const composed = cpeEvents[0].detail.newValue;
		expect(composed.assignmentRuleHeader).not.toBeNull();
		expect(composed.assignmentRuleHeader.assignmentRuleId).toBe('ruleId123');
		expect(composed.duplicateRuleHeader).toBeNull();
		expect(composed.emailHeader).toBeNull();
	});

	it('includes emailHeader in dmlOptions only when a sub-field is set', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		const cpeEvents = [];
		element.addEventListener('configuration_editor_input_value_changed', (e) => cpeEvents.push(e));

		dispatchFieldChange(element, 'triggerUserEmail', true, 'Boolean');

		const composed = cpeEvents[0].detail.newValue;
		expect(composed.emailHeader).not.toBeNull();
		expect(composed.emailHeader.triggerUserEmail).toBe(true);
		expect(composed.assignmentRuleHeader).toBeNull();
	});

	// ── fieldincludedchange ────────────────────────────────────────────────────

	it('dispatches null CPE event for a top-level field when excluded', async () => {
		const element = createComponent({
			inputVariables: [{ name: 'record', value: '{!myRecord}', valueDataType: 'reference' }]
		});
		await Promise.resolve();

		const cpeEvents = [];
		element.addEventListener('configuration_editor_input_value_changed', (e) => cpeEvents.push(e));

		dispatchFieldIncludedChange(element, 'record', false);

		expect(cpeEvents).toHaveLength(1);
		expect(cpeEvents[0].detail.name).toBe('record');
		expect(cpeEvents[0].detail.newValue).toBeNull();
	});

	it('clears dmlOptions sub-field in composed value when excluded', async () => {
		const element = createComponent({
			inputVariables: [
				{
					name: 'dmlOptions',
					value: { allowFieldTruncation: true },
					valueDataType: 'SObject'
				}
			]
		});
		await Promise.resolve();

		const cpeEvents = [];
		element.addEventListener('configuration_editor_input_value_changed', (e) => cpeEvents.push(e));

		dispatchFieldIncludedChange(element, 'allowFieldTruncation', false);

		expect(cpeEvents).toHaveLength(1);
		expect(cpeEvents[0].detail.name).toBe('dmlOptions');
		expect(cpeEvents[0].detail.newValue.allowFieldTruncation).toBeNull();
	});

	it('makes record required again and fails validate after excluding it', async () => {
		const element = createComponent({
			inputVariables: [{ name: 'record', value: '{!myRecord}', valueDataType: 'reference' }]
		});
		await Promise.resolve();

		// Excluding the only set record-type field should cause validate to fail.
		dispatchFieldIncludedChange(element, 'record', false);

		expect(element.validate()).toHaveLength(1);
	});

	// ── validate() ───────────────────────────────────────────────────────────

	it('validate returns empty array when record is set via fieldchange', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		dispatchFieldChange(element, 'record', '{!myRecord}', 'reference');
		dispatchFieldIncludedChange(element, 'record', true);

		expect(element.validate()).toEqual([]);
	});

	it('validate returns empty array when records is set via fieldchange', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		dispatchFieldChange(element, 'records', '{!myRecords}', 'reference');
		dispatchFieldIncludedChange(element, 'records', true);

		expect(element.validate()).toEqual([]);
	});

	it('validate returns error when neither record nor records is provided', () => {
		const element = createComponent({ inputVariables: [] });

		const errors = element.validate();
		expect(errors).toHaveLength(1);
		expect(errors[0].key).toBe('record');
		expect(errors[0].errorString).toContain('SObject Record');
	});

	// ── generic type mapping ──────────────────────────────────────────────────

	it('passes type-name T__record to the record combobox', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		const combobox = element.shadowRoot.querySelectorAll('c-flow-combobox')[0];
		expect(combobox.typeName).toBe('T__record');
	});

	it('passes type-name T__records to the records combobox', async () => {
		const element = createComponent({ inputVariables: [] });
		await Promise.resolve();

		const combobox = element.shadowRoot.querySelectorAll('c-flow-combobox')[1];
		expect(combobox.typeName).toBe('T__records');
	});

	it('passes typeValue from genericTypeMappings to the record combobox', async () => {
		const element = createComponent({
			inputVariables: [],
			genericTypeMappings: [{ typeName: 'T__record', typeValue: 'Account' }]
		});
		await Promise.resolve();

		const combobox = element.shadowRoot.querySelectorAll('c-flow-combobox')[0];
		expect(combobox.typeValue).toBe('Account');
	});
});
