import { createElement } from '@lwc/engine-dom';
import FlowUntypedVariableInput from 'c/flowUntypedVariableInput';

describe('c-flow-untyped-variable-input', () => {
    function createComponent(props = {}) {
        const element = createElement('c-flow-untyped-variable-input', {
            is: FlowUntypedVariableInput
        });
        Object.assign(element, props);
        document.body.appendChild(element);
        return element;
    }

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    const defaultVariable = { key: 'recordId', textValue: '{!myRecord.Id}', typeName: 'Id', isCollection: false };

    it('renders key, type, is-collection, and remove inputs', () => {
        const element = createComponent({ variable: defaultVariable });
        expect(element.shadowRoot.querySelector('[data-id="key"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-id="type-name"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('[data-id="is-collection"]')).not.toBeNull();
        expect(element.shadowRoot.querySelector('lightning-button-icon')).not.toBeNull();
    });

    it('reflects variable props into inputs', async () => {
        const element = createComponent({ variable: defaultVariable });
        await Promise.resolve();
        expect(element.shadowRoot.querySelector('[data-id="key"]').value).toBe('recordId');
        expect(element.shadowRoot.querySelector('[data-id="type-name"]').value).toBe('Id');
        expect(element.shadowRoot.querySelector('[data-id="is-collection"]').checked).toBe(false);
    });

    it('emits change with updated key when key input changes', () => {
        const element = createComponent({ index: 0, variable: defaultVariable });
        const events = [];
        element.addEventListener('change', (e) => events.push(e));

        const keyInput = element.shadowRoot.querySelector('[data-id="key"]');
        keyInput.value = 'accountId';
        keyInput.dispatchEvent(new Event('change'));

        expect(events).toHaveLength(1);
        expect(events[0].detail).toEqual({ index: 0, variable: { ...defaultVariable, key: 'accountId' } });
    });

    it('emits change with updated typeName when type input changes', () => {
        const element = createComponent({ index: 1, variable: defaultVariable });
        const events = [];
        element.addEventListener('change', (e) => events.push(e));

        const typeInput = element.shadowRoot.querySelector('[data-id="type-name"]');
        typeInput.value = 'String';
        typeInput.dispatchEvent(new Event('change'));

        expect(events).toHaveLength(1);
        expect(events[0].detail).toEqual({ index: 1, variable: { ...defaultVariable, typeName: 'String' } });
    });

    it('emits change with updated isCollection when toggle changes', () => {
        const element = createComponent({ index: 0, variable: defaultVariable });
        const events = [];
        element.addEventListener('change', (e) => events.push(e));

        const toggle = element.shadowRoot.querySelector('[data-id="is-collection"]');
        toggle.checked = true;
        toggle.dispatchEvent(new Event('change'));

        expect(events).toHaveLength(1);
        expect(events[0].detail).toEqual({ index: 0, variable: { ...defaultVariable, isCollection: true } });
    });

    it('emits change with updated textValue when value combobox changes', () => {
        const element = createComponent({ index: 0, variable: defaultVariable });
        const events = [];
        element.addEventListener('change', (e) => events.push(e));

        element.shadowRoot.querySelector('[data-id="value"]').dispatchEvent(
            new CustomEvent('fieldchange', { detail: { name: 'textValue', value: '{!newVar}', valueDataType: 'reference' } })
        );

        expect(events).toHaveLength(1);
        expect(events[0].detail).toEqual({ index: 0, variable: { ...defaultVariable, textValue: '{!newVar}' } });
    });

    it('emits remove event with index when remove button is clicked', () => {
        const element = createComponent({ index: 2, variable: defaultVariable });
        const events = [];
        element.addEventListener('remove', (e) => events.push(e));

        element.shadowRoot.querySelector('lightning-button-icon').click();

        expect(events).toHaveLength(1);
        expect(events[0].detail).toEqual({ index: 2 });
    });
});
