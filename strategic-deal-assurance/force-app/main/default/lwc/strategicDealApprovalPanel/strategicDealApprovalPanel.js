import { LightningElement, api, wire } from 'lwc';
import getState from '@salesforce/apex/StrategicDealApprovalController.getState';
import act from '@salesforce/apex/StrategicDealApprovalController.act';
import { refreshApex } from '@salesforce/apex';
export default class StrategicDealApprovalPanel extends LightningElement {
    _recordId;
    @api get recordId() { return this._recordId; }
    set recordId(value) {
        if (this._recordId !== value) {
            this._recordId = value;
            this.state = undefined;
            this.error = undefined;
            this.message = undefined;
        }
    }
    _refreshKey;
    result;
    state;
    error;
    message;
    busy = false;
    @api get refreshKey() { return this._refreshKey; }
    set refreshKey(value) {
        if (this._refreshKey !== value) {
            this._refreshKey = value;
            if (this.result && this.recordId) { this.refresh(); }
        }
    }
    @wire(getState, { opportunityId: '$recordId' })
    load(result) {
        this.result = result;
        this.state = result.data;
        this.error = result.error ? 'Approval information unavailable. Check access and refresh.' : undefined;
    }
    get rows() { return (this.state?.history || []).map((row, index) => ({ ...row, key: `approval-${index}` })); }
    get hasHistory() { return this.rows.length > 0; }
    async refresh() {
        try { await refreshApex(this.result); }
        catch { this.state = undefined; this.error = 'Approval information could not be refreshed.'; }
    }
    async handleAction(event) {
        if (this.busy) { return; }
        const action = event.currentTarget.dataset.action;
        this.busy = true;
        this.error = undefined;
        this.message = undefined;
        try {
            await act({ opportunityId: this.recordId, action });
            this.message = 'Approval action completed.';
            await this.refresh();
            this.dispatchEvent(new CustomEvent('approvalchange'));
        } catch {
            this.error = 'Approval action unavailable. Check your role, assigned approver and current state, then refresh.';
        } finally { this.busy = false; }
    }
}
