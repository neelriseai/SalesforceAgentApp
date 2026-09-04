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
    const expectedFields = ['Name', 'AccountId', 'StageName', 'CloseDate', 'Amount', 'Strategic_Deal__c', 'Discount__c', 'Regional_VP_Approver__c'];
    it.each(['baseline', 'reordered', 'regrouped'])('preserves eight unique metadata identities and the LDS payload in %s', async (variant) => {
        const element = mount(); element.locatorVariant = variant; await flush();
        const wrappers = [...element.shadowRoot.querySelectorAll('[data-field-api]')];
        expect(wrappers.map(node => node.dataset.fieldApi).sort()).toEqual([...expectedFields].sort());
        wrappers.forEach(node => {
            expect(node.dataset.testid).toBe(`deal-${variant}-${node.dataset.fieldApi}`);
            expect(node.querySelector('lightning-input-field').fieldName).toBe(node.dataset.fieldApi);
        });
        const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        const spy = jest.spyOn(form, 'submit');
        const inputs = { Name: 'SYN-LH-Test', AccountId: null, StageName: 'Prospecting', CloseDate: '2026-12-15', Amount: 60000000, Strategic_Deal__c: true, Discount__c: 15, Regional_VP_Approver__c: null };
        submit(form, { ...inputs, Approval_Status__c: 'Approved' }); await flush();
        expect(spy).toHaveBeenCalledWith(inputs);
        expect(element.shadowRoot.querySelector('[data-action="save-evaluate"]').disabled).toBe(true);
    });
    it('breaks old hooks, changes order and action name, then restores baseline', async () => {
        const element = mount();
        element.locatorVariant = 'reordered'; await flush();
        expect(element.shadowRoot.querySelector('[data-testid="save-evaluate-v1"]')).toBeNull();
        expect(element.shadowRoot.querySelector('[data-testid="deal-baseline-Amount"]')).toBeNull();
        expect(element.shadowRoot.querySelector('lightning-input-field').fieldName).toBe('Discount__c');
        expect(element.shadowRoot.querySelector('[data-action="save-evaluate"]').label).toBe('Save proposal and check policy');
        element.locatorVariant = 'regrouped'; await flush();
        expect(element.shadowRoot.querySelectorAll('section')).toHaveLength(2);
        expect(element.shadowRoot.querySelector('lightning-input-field').fieldName).toBe('Strategic_Deal__c');
        element.locatorVariant = 'baseline'; await flush();
        expect([...element.shadowRoot.querySelectorAll('lightning-input-field')].map(f => f.fieldName)).toEqual(expectedFields);
        expect(element.shadowRoot.querySelector('[data-testid="save-evaluate-v1"]').label).toBe('Save and Evaluate');
    });
    it('falls back safely for unknown variants and never auto-submits on layout change', async () => {
        const element = mount(); const form = element.shadowRoot.querySelector('lightning-record-edit-form');
        const spy = jest.spyOn(form, 'submit');
        element.locatorVariant = 'regrouped'; await flush();
        element.locatorVariant = 'constructor'; await flush();
        expect(element.shadowRoot.querySelector('[data-locator-variant]').dataset.locatorVariant).toBe('baseline');
        expect(spy).not.toHaveBeenCalled();
    });
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
