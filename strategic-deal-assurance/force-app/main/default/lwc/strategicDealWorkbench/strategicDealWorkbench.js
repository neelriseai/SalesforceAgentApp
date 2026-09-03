import { LightningElement, api } from 'lwc';
import OPPORTUNITY from '@salesforce/schema/Opportunity';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

const INPUT_FIELDS = ['Name', 'AccountId', 'StageName', 'CloseDate', 'Amount', 'Strategic_Deal__c', 'Discount__c', 'Regional_VP_Approver__c'];
export default class StrategicDealWorkbench extends LightningElement {
    @api recordId;
    objectApiName = OPPORTUNITY;
    selectedId;
    busy = false;
    message = '';
    error = '';
    refreshKey = 0;
    get currentId() { return this.recordId || this.selectedId; }
    get canStartNew() { return !this.recordId && Boolean(this.selectedId); }
    get heading() { return this.currentId ? 'Edit strategic deal' : 'Create a strategic deal'; }
    get defaultName() { return this.currentId ? undefined : 'SYN-Strategic Deal'; }
    handleSubmit(event) {
        event.preventDefault();
        if (this.busy) { return; }
        this.error = '';
        this.message = '';
        const supplied = event.detail.fields;
        if (!supplied.Name?.trim().startsWith('SYN-')) {
            this.error = 'Use a synthetic Opportunity name beginning with SYN-.';
            return;
        }
        const fields = {};
        INPUT_FIELDS.forEach((name) => { if (Object.hasOwn(supplied, name)) { fields[name] = supplied[name]; } });
        this.busy = true;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
    async handleSuccess(event) {
        this.selectedId = event.detail.id;
        // The synchronous after-save Flow has completed when LDS reports success.
        try {
            await notifyRecordUpdateAvailable([{ recordId: this.currentId }]);
            this.refreshKey += 1;
            this.message = 'Saved successfully. The policy results are shown below.';
        } catch {
            this.message = 'Saved successfully, but refresh is unavailable. Use Refresh policy to reload results.';
        } finally { this.busy = false; }
    }
    handleError() {
        this.busy = false;
        this.message = '';
        this.error = 'The deal could not be saved. Check required fields, permissions, and your connection, then try again.';
    }
    async handleApprovalChange() {
        try { await notifyRecordUpdateAvailable([{ recordId: this.currentId }]); }
        catch { this.message = 'Approval completed. Refresh to reload record details.'; }
        this.refreshKey += 1;
    }
    startNew() {
        this.selectedId = undefined;
        this.message = '';
        this.error = '';
        this.template.querySelectorAll('lightning-input-field').forEach((field) => field.reset());
    }
}
