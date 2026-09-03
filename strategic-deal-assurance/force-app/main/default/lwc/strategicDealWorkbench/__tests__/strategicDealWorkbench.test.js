import { createElement } from 'lwc';
import StrategicDealWorkbench from 'c/strategicDealWorkbench';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
jest.mock('lightning/uiRecordApi', () => ({ notifyRecordUpdateAvailable: jest.fn(() => Promise.resolve()) }), { virtual: true });
jest.mock('@salesforce/apex/StrategicDealPolicyController.getPolicy', () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return { default: createApexTestWireAdapter(jest.fn()) };
}, { virtual: true });
const flush = async () => { await Promise.resolve(); await Promise.resolve(); };
function mount(recordId) {
    const element = createElement('c-strategic-deal-workbench', { is: StrategicDealWorkbench });
    element.recordId = recordId;
    document.body.appendChild(element);
    return element;
}
function submit(form, fields) { form.dispatchEvent(new CustomEvent('submit', { detail: { fields }, cancelable: true })); }
afterEach(() => { while (document.body.firstChild) { document.body.removeChild(document.body.firstChild); } jest.clearAllMocks(); });
describe('BR-STRATEGIC-DISCOUNT workbench', () => {
    it('renders only allowed inputs and stable accessible save hook', () => {
        const element = mount();
        const fields = [...element.shadowRoot.querySelectorAll('lightning-input-field')].map(field => field.fieldName);
        expect(fields).toHaveLength(8);
        expect(fields).not.toContain('Approval_Status__c');
        expect(element.shadowRoot.querySelector('[data-testid="save-evaluate-v1"]').label).toBe('Save and Evaluate');
    });
    it('rejects non-synthetic names before saving', async () => {
        const element = mount(); const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        const spy = jest.spyOn(form, 'submit'); submit(form, { Name: 'Real client' }); await flush();
        expect(spy).not.toHaveBeenCalled();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toContain('SYN-');
    });
    it('allowlists fields and blocks a duplicate submit while saving', async () => {
        const element = mount(); const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        const spy = jest.spyOn(form, 'submit');
        submit(form, { Name: 'SYN-Test', Amount: 60000000, Approval_Status__c: 'Approved' });
        submit(form, { Name: 'SYN-Test' }); await flush();
        expect(spy).toHaveBeenCalledTimes(1);
        expect(spy).toHaveBeenCalledWith({ Name: 'SYN-Test', Amount: 60000000 });
        expect(element.shadowRoot.querySelector('[data-testid="save-evaluate-v1"]').disabled).toBe(true);
    });
    it('shows policy for a saved record and announces success', async () => {
        const element = mount(); const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        form.dispatchEvent(new CustomEvent('success', { detail: { id: '006000000000001AAA' } })); await flush();
        expect(notifyRecordUpdateAvailable).toHaveBeenCalledWith([{ recordId: '006000000000001AAA' }]);
        expect(element.shadowRoot.querySelector('c-strategic-deal-policy-card').recordId).toBe('006000000000001AAA');
        expect(element.shadowRoot.textContent).toContain('Saved successfully');
    });
    it('distinguishes a successful save from a failed refresh', async () => {
        notifyRecordUpdateAvailable.mockRejectedValueOnce(new Error('offline'));
        const element = mount(); element.shadowRoot.querySelector('lightning-record-edit-form').dispatchEvent(new CustomEvent('success', { detail: { id: '006000000000001AAA' } })); await flush();
        expect(element.shadowRoot.textContent).toContain('Saved successfully, but refresh');
    });
    it('sanitizes errors and lets the user retry', async () => {
        const element = mount(); const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        form.dispatchEvent(new CustomEvent('error', { detail: { message: 'sensitive debug' } })); await flush();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toContain('could not be saved');
        expect(element.shadowRoot.textContent).not.toContain('sensitive debug');
        expect(element.shadowRoot.querySelector('[data-testid="save-evaluate-v1"]').disabled).toBe(false);
    });
    it('uses the record page ID for editing', () => {
        const element = mount('006000000000001AAA');
        expect(element.shadowRoot.querySelector('lightning-record-edit-form').recordId).toBe('006000000000001AAA');
        expect(element.shadowRoot.textContent).toContain('Edit strategic deal');
    });
    it('refreshes record and policy after a native approval action', async () => {
        const element = mount('006000000000001AAA');
        element.shadowRoot.querySelector('c-strategic-deal-approval-panel').dispatchEvent(new CustomEvent('approvalchange'));
        await flush();
        expect(notifyRecordUpdateAvailable).toHaveBeenCalledWith([{ recordId: '006000000000001AAA' }]);
        expect(element.shadowRoot.querySelector('c-strategic-deal-policy-card').refreshKey).toBe(1);
    });
});
