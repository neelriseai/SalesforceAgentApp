# Two-login approval walkthrough

Use separate browser sessions for the existing demo owner and Synthetic Regional VP. Complete Salesforce activation and sign-in privately; never put passwords, activation links or session tokens into the repository or chat.

## Owner session

1. Open App Launcher > Strategic Deal Assurance > Opportunities. Select All Opportunities if Recently Viewed is empty.
2. Open SYN-SDA-04 Above 15 Percent. Its USD amount is 50,000,000.01, discount is 15.01%, strategic flag is selected, and the approver should be Synthetic Regional VP.
3. Confirm policy status Pending Regional VP. This is eligibility, not proof of submission.
4. In Regional VP Approval, click Submit for Approval once. Confirm Latest request: Pending, the lock notice, and Recall Approval. The owner should not see Approve or Reject.

## Regional VP session

1. Sign in as the separately provisioned Synthetic Regional VP. Open the same app and Opportunity.
2. In Regional VP Approval, confirm the pending request and Approve/Reject actions. Click Approve for the happy-path demo.
3. Refresh the owner session's approval panel and policy card. Native request status and the Opportunity approval status should be Approved. The policy evaluation rows should not increase just because of the human decision.

If the browser shows stale components after deployment, reload the page. If the separate user cannot open the app or record, report the exact error; do not grant administrator access as a workaround.

The Regional_VP_Approver permission set explicitly enables LightningExperienceUser because the minimum-access profile does not provide it in this org. If an existing session still reports that Lightning is unavailable after assignment, refresh or sign out and sign back in as the VP. This permission does not grant administrator, API or record-editing access.

## Rejection, recall and reset

An owner can recall a pending request, returning policy status to Pending Regional VP while native request history records Removed. Approval/rejection unlock the record. Changing a relevant policy input after a final decision causes a new evaluation and may make a new request eligible; an unchanged rejected record cannot be resubmitted through the app.

Do not run Apply reset against pending approvals. Finish or explicitly recall them first. See demo-data-reset.md for Preview, Apply, Verify and rollback-only Rehearse. Reset does not delete native request history or silently cancel a request.

The existing demo owner is an administrator: that session cannot demonstrate ordinary-user edit restrictions. Automated Apex tests use a minimum-access owner and a distinct approver to verify native locking and separation of duties. Native administrator overrides remain available outside this app.
