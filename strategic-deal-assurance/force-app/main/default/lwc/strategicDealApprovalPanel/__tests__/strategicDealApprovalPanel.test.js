import { createElement } from 'lwc';
import Panel from 'c/strategicDealApprovalPanel';
import getState from '@salesforce/apex/StrategicDealApprovalController.getState';
import act from '@salesforce/apex/StrategicDealApprovalController.act';
import { refreshApex } from '@salesforce/apex';
jest.mock('@salesforce/apex/StrategicDealApprovalController.getState', () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return { default: createApexTestWireAdapter(jest.fn()) };
}, { virtual: true });
jest.mock('@salesforce/apex/StrategicDealApprovalController.act', () => ({ default: jest.fn(() => Promise.resolve()) }), { virtual: true });
jest.mock('@salesforce/apex', () => ({ refreshApex: jest.fn(() => Promise.resolve()) }), { virtual: true });
const base = { status: 'Not submitted', locked: false, canSubmit: true, canDecide: false, canRecall: false, needsSeparateApprover: false, history: [] };
const flush = async () => { await Promise.resolve(); await Promise.resolve(); await Promise.resolve(); await Promise.resolve(); await Promise.resolve(); await Promise.resolve(); await Promise.resolve(); await Promise.resolve(); };
function mount() {
    const el = createElement('c-strategic-deal-approval-panel', { is: Panel });
    el.recordId = '006000000000001AAA'; document.body.appendChild(el); return el;
}
afterEach(() => { while (document.body.firstChild) { document.body.removeChild(document.body.firstChild); } jest.clearAllMocks(); });
it('offers submission only when the server permits it', async () => {
    const el = mount(); getState.emit(base); await flush();
    expect(el.shadowRoot.querySelector('[data-action="Submit"]')).not.toBeNull();
    expect(el.shadowRoot.querySelector('[data-action="Approve"]')).toBeNull();
});
it('shows assigned approver actions and native history', async () => {
    const el = mount(); getState.emit({ ...base, status: 'Pending', locked: true, canSubmit: false, canDecide: true, history: [{ status: 'Started', occurredAt: '2026-09-04T00:00:00Z' }] }); await flush();
    expect(el.shadowRoot.querySelector('[data-action="Approve"]')).not.toBeNull();
    expect(el.shadowRoot.querySelector('[data-action="Reject"]')).not.toBeNull();
    expect(el.shadowRoot.textContent).toContain('Record locked');
    expect(el.shadowRoot.querySelector('li').textContent).toContain('Started');
});
it('submits once, refreshes and tells the parent', async () => {
    const el = mount(); const changed = jest.fn(); el.addEventListener('approvalchange', changed);
    getState.emit(base); await flush(); const button = el.shadowRoot.querySelector('[data-action="Submit"]'); button.click(); button.click(); await flush();
    expect(act).toHaveBeenCalledTimes(1); expect(act).toHaveBeenCalledWith({ opportunityId: el.recordId, action: 'Submit' });
    expect(refreshApex).toHaveBeenCalled(); expect(changed).toHaveBeenCalledTimes(1);
});
it('sanitizes failures and recovers controls', async () => {
    const el = mount(); getState.emit(base); await flush(); act.mockRejectedValueOnce(new Error('secret'));
    el.shadowRoot.querySelector('[data-action="Submit"]').click(); await flush();
    expect(el.shadowRoot.querySelector('[role="alert"]').textContent).toContain('unavailable');
    expect(el.shadowRoot.textContent).not.toContain('secret'); expect(el.shadowRoot.querySelector('[data-action="Submit"]').disabled).toBe(false);
});
it('clears old state when selecting another record or losing access', async () => {
    const el = mount(); getState.emit(base); await flush(); el.recordId = '006000000000002AAA'; await flush();
    expect(el.shadowRoot.querySelector('[data-action="Submit"]')).toBeNull();
    getState.error({ message: 'private' }); await flush(); expect(el.shadowRoot.textContent).not.toContain('private');
});
it('refreshes after saves and hides controls if refresh fails', async () => {
    const el = mount(); getState.emit(base); await flush(); refreshApex.mockRejectedValueOnce(new Error('private')); el.refreshKey = 1; await flush();
    expect(el.shadowRoot.querySelector('[data-action="Submit"]')).toBeNull(); expect(el.shadowRoot.textContent).toContain('could not be refreshed');
});
it('offers recall only to submitter and explains separate-user requirement', async () => {
    const el = mount(); getState.emit({ ...base, canSubmit: false, canRecall: true, needsSeparateApprover: true }); await flush();
    expect(el.shadowRoot.querySelector('[data-action="Recall"]')).not.toBeNull(); expect(el.shadowRoot.textContent).toContain('other than the deal owner');
});
