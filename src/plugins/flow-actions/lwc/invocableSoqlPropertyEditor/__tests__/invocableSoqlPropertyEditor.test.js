import { createElement } from '@lwc/engine-dom';
import InvocableSoqlPropertyEditor from 'c/invocableSoqlPropertyEditor';

describe('c-invocable-soql-property-editor', () => {
    function createComponent(props = {}) {
        const element = createElement('c-invocable-soql-property-editor', {
            is: InvocableSoqlPropertyEditor
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

    it('renders the query textarea', () => {
        const element = createComponent();
        expect(element.shadowRoot.querySelector('lightning-textarea')).not.toBeNull();
    });

    it('populates the query textarea from inputVariables', async () => {
        const element = createComponent({
            inputVariables: [{ name: 'query', value: 'SELECT Id FROM Account', valueDataType: 'String' }]
        });
        await Promise.resolve();
        expect(element.shadowRoot.querySelector('lightning-textarea').value).toBe('SELECT Id FROM Account');
    });

    it('validate() returns an error when query is empty', () => {
        const element = createComponent({ inputVariables: [] });
        const errors = element.validate();
        expect(errors).toHaveLength(1);
        expect(errors[0].key).toBe('query');
    });

    it('validate() returns no errors when query is set', () => {
        const element = createComponent({
            inputVariables: [{ name: 'query', value: 'SELECT Id FROM Account', valueDataType: 'String' }]
        });
        expect(element.validate()).toHaveLength(0);
    });

    it('dispatches configuration_editor_input_value_changed when query is entered', () => {
        const element = createComponent();
        const events = [];
        element.addEventListener('configuration_editor_input_value_changed', (e) => events.push(e));

        element.shadowRoot.querySelector('lightning-textarea').dispatchEvent(
            new CustomEvent('change', { detail: { value: 'SELECT Id FROM Contact' } })
        );

        expect(events).toHaveLength(1);
        expect(events[0].detail).toEqual({
            name: 'query',
            newValue: 'SELECT Id FROM Contact',
            newValueDataType: 'String'
        });
    });

    it('dispatches configuration_editor_input_value_deleted when query is cleared', () => {
        const element = createComponent({
            inputVariables: [{ name: 'query', value: 'SELECT Id FROM Account', valueDataType: 'String' }]
        });
        const deletedEvents = [];
        element.addEventListener('configuration_editor_input_value_deleted', (e) => deletedEvents.push(e));

        element.shadowRoot.querySelector('lightning-textarea').dispatchEvent(
            new CustomEvent('change', { detail: { value: null } })
        );

        expect(deletedEvents).toHaveLength(1);
        expect(deletedEvents[0].detail.name).toBe('query');
    });
});
