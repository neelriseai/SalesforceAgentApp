# Native Regional VP approval

This milestone uses Salesforce's native ApprovalProcess and Approval.process engine. StrategicDealApprovalController is an internal Lightning adapter, not an Apex REST facade. A separate assurance agent can continue using Salesforce's standard APIs; a custom external API is deferred until its integration needs are known.

## Lifecycle

1. Save and Evaluate still calculates policy eligibility. Pending Regional VP alone does not mean a request was submitted.
2. The owner uses Submit for Approval. Eligibility must be pending, the name synthetic, and the configured approver active and different from the owner. The internal controller rechecks the central policy and applied version.
3. Native submission creates a ProcessInstance/work item routed to Regional_VP_Approver__c and locks the record against ordinary edits.
4. Only the actual assigned actor is offered Approve/Reject in the app. The internal adapter explicitly rejects self-decision and does not grant an administrator override.
5. Approval sets Approved; rejection sets Rejected. Both unlock the record. These field updates do not change policy inputs or add evaluation rows.
6. The submitter can recall a pending request. Native history becomes Removed, the record unlocks, and policy status returns to Pending Regional VP, permitting resubmission.
7. After rejection/approval, changing relevant inputs causes a new policy evaluation. If eligible, the owner may submit a new request. An unchanged rejected record cannot simply be resubmitted through the app.

The Regional VP Approval panel displays latest native request state, actions permitted for the current actor, lock information and the latest request's ten most recent native history steps. It does not return IDs, people names or comments. Policy evaluation history remains a separate immutable-to-normal-users record of the policy input decision; it is not overwritten by a human approval.

## Security and limitations

- The controller is with sharing, queries the parent Opportunity and fields WITH USER_MODE, then summarizes that parent's matching native process. Process data is read in system mode only after the parent check. Server-side transition checks are repeated on every action; hiding buttons is not the authorization mechanism.
- One named native process is selected explicitly; entry criteria cannot be skipped by the internal adapter. No numeric threshold is duplicated in the approval definition.
- The native formula supports stored eligibility, synthetic name, active approver and owner/approver separation. It does not support the attempted Custom Metadata reference. The app additionally revalidates current configuration. Other callers using standard native submission APIs must ensure current policy evaluation before submitting; this milestone does not add a universal API interception layer.
- Native platform administrator capabilities remain. AdminOnly record editability allows administrators to edit locked records, and standard Salesforce administrative approval overrides are not removed. Use the separate minimum-access personas, not an administrator session, to demonstrate ordinary-user restrictions.
- Routing is to the configured user lookup, not an organizational title check. Choosing/maintaining an approved roster of Regional VPs is an operator responsibility; do not treat the lookup label as role attestation.
- Approval is explicit, not automatic on every save. No custom outbound email alert, webhook or integration is added. Native assignment notifications may occur.
- Regional_VP_Approver remains read-only on Opportunity fields, with no direct outcome/evidence editing or administrative grants. Native assignment supplies the right to decide the assigned request.
- The new separate user uses Minimum Access - Salesforce plus Regional_VP_Approver only. Activation/password setup must be completed by the user through Salesforce email; no credentials are stored in source.
- Regional_VP_Approver explicitly includes LightningExperienceUser. The org's minimum-access profile did not supply this UI prerequisite; Apex engine tests alone did not detect the initial omission. The correction adds no API, administrator or data-editing rights.
- The reset refuses managed records with pending native ProcessInstance requests. Finish or recall requests before resetting; it does not silently cancel approval processes or delete their history. The org-wide Apex lock/unlock API preference stays unchanged; native approval locking is verified by attempted owner edits.

## Verification

manifest/milestone-4.xml contains the one approval definition, three Opportunity Workflow field updates, internal controller/tests, approval panel/workbench and four existing permission sets with class access. Preflight found no existing Opportunity Workflow; the unrelated Case Workflow remains untouched.

StrategicDealApprovalControllerTest uses distinct minimum-access owner and approver test users to execute native submit/approve/reject/recall, verify locking and policy-evidence counts, block duplicate submission, exact-boundary submission, self-approval through both app and native entry, non-owner submission, unsupported actions and stale app eligibility. These test users roll back and are distinct from the persistent demo VP account.

Use scripts/test-milestone-4.ps1 for all four Apex suites, npm run test:unit -- -- --runInBand for component tests and npm run lint. Reports must distinguish native engine tests, component mocks, live browser checks and email delivery/activation, which cannot be inferred from a successful user-insert request.
