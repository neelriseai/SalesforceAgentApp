import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getPolicy from '@salesforce/apex/StrategicDealPolicyController.getPolicy';

export default class StrategicDealPolicyCard extends LightningElement {
    _recordId;
    _refreshKey;
    wiredResult;
    view;
    loading = true;
    error;
    @api get recordId() { return this._recordId; }
    set recordId(value) {
        if (this._recordId !== value) {
            this._recordId = value;
            this.view = undefined;
            this.error = undefined;
            this.loading = Boolean(value);
        }
    }
    @api get refreshKey() { return this._refreshKey; }
    set refreshKey(value) {
        if (this._refreshKey !== value) {
            this._refreshKey = value;
            if (this.wiredResult) { this.refresh(); }
        }
    }
    @wire(getPolicy, { opportunityId: '$_recordId' })
    policy(result) {
        this.wiredResult = result;
        if (result.data) {
            this.view = result.data;
            this.error = undefined;
            this.loading = false;
        } else if (result.error) {
            this.view = undefined;
            this.error = 'Policy information is unavailable or you do not have access.';
            this.loading = false;
        }
    }
    @api async refresh() {
        if (!this.wiredResult || !this._recordId) { return; }
        this.loading = true;
        try { await refreshApex(this.wiredResult); }
        catch {
            this.view = undefined;
            this.error = 'Policy information could not be refreshed. Try again.';
        } finally { this.loading = false; }
    }
    get hasRecord() { return Boolean(this._recordId); }
    get showView() { return Boolean(this.view) && !this.error; }
    get hasHistory() { return (this.view?.history?.length || 0) > 0; }
    get historyRows() {
        return (this.view?.history || []).map((row, index) => ({ ...row, key: `evaluation-${index}` }));
    }
    get statusClass() {
        return this.view?.status === 'Configuration Error' ? 'status status_error' : 'status';
    }
    get configurationWarning() { return this.view && !this.view.ruleActive; }
    get ruleVersionMismatch() {
        return this.view && this.view.activeRuleVersion !== this.view.appliedRuleVersion;
    }
}
