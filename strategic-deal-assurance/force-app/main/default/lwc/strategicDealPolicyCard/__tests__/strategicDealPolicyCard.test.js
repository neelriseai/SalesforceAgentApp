import { createElement } from 'lwc';
import StrategicDealPolicyCard from 'c/strategicDealPolicyCard';
import getPolicy from '@salesforce/apex/StrategicDealPolicyController.getPolicy';
import { refreshApex } from '@salesforce/apex';
jest.mock('@salesforce/apex/StrategicDealPolicyController.getPolicy', () => {
    const { createApexTestWireAdapter } = require('@salesforce/sfdx-lwc-jest');
    return { default: createApexTestWireAdapter(jest.fn()) };
}, { virtual: true });
jest.mock('@salesforce/apex', () => ({ refreshApex: jest.fn(() => Promise.resolve()) }), { virtual: true });
const view = { status: 'Pending Regional VP', reason: 'Synthetic policy reason', appliedRuleVersion: 'baseline-15',
    activeRuleVersion: 'baseline-15', discountThreshold: 15, amountThreshold: 50000000, ruleActive: true,
    evaluatedAt: '2026-09-04T00:00:00.000Z', history: [{ outcome: 'Pending Regional VP', ruleVersion: 'baseline-15',
        evaluatedAt: '2026-09-04T00:00:00.000Z', amount: 60000000, discount: 20 }] };
const flush = async () => { await Promise.resolve(); await Promise.resolve(); };
function mount(recordId = '006000000000001AAA') {
    const element = createElement('c-strategic-deal-policy-card', { is: StrategicDealPolicyCard });
    if (recordId) { element.recordId = recordId; }
    document.body.appendChild(element);
    return element;
}
afterEach(() => { while (document.body.firstChild) { document.body.removeChild(document.body.firstChild); } jest.clearAllMocks(); });
describe('BR-STRATEGIC-DISCOUNT policy card', () => {
    it('shows a selection prompt without a record', async () => {
        const element = mount(null); await flush();
        expect(element.shadowRoot.textContent).toContain('Create or select an Opportunity');
    });
    it('shows loading then accessible status, active rule and history', async () => {
        const element = mount(); await flush();
        expect(element.shadowRoot.textContent).toContain('Loading policy information');
        getPolicy.emit(view); await flush();
        expect(element.shadowRoot.querySelector('[data-testid="approval-status"]').textContent).toBe('Pending Regional VP');
        expect(element.shadowRoot.querySelector('[data-testid="policy-threshold"]').textContent).toContain('15%');
        expect(element.shadowRoot.querySelector('[data-testid="evaluation-history"] li')).not.toBeNull();
        expect(element.shadowRoot.textContent).not.toContain('006000000000001AAA');
    });
    it('handles an empty history', async () => {
        const element = mount(); getPolicy.emit({ ...view, history: [] }); await flush();
        expect(element.shadowRoot.textContent).toContain('No evaluations yet');
    });
    it('hides stale values and sanitizes no-access/server errors', async () => {
        const element = mount(); getPolicy.emit(view); await flush();
        getPolicy.error({ message: 'SECRET raw server exception' }); await flush();
        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toContain('unavailable');
        expect(element.shadowRoot.textContent).not.toContain('SECRET');
        expect(element.shadowRoot.querySelector('[data-testid="approval-status"]')).toBeNull();
    });
    it('refreshes the cache after a parent save', async () => {
        const element = mount(); getPolicy.emit(view); await flush();
        element.refreshKey = 1; await flush();
        expect(refreshApex).toHaveBeenCalledTimes(1);
    });
    it('handles refresh failure without exposing the exception', async () => {
        const element = mount(); getPolicy.emit(view); await flush();
        refreshApex.mockRejectedValueOnce(new Error('private server information'));
        await element.refresh(); await flush();
        expect(element.shadowRoot.textContent).toContain('could not be refreshed');
        expect(element.shadowRoot.textContent).not.toContain('private server');
    });
    it('warns about inactive config and a changed rule version', async () => {
        const element = mount(); getPolicy.emit({ ...view, ruleActive: false, activeRuleVersion: 'change-10' }); await flush();
        expect(element.shadowRoot.textContent).toContain('inactive or missing');
        expect(element.shadowRoot.textContent).toContain('differs from the last evaluation');
    });
});
