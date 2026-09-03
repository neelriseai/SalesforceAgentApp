# Milestone 4 verification: native Regional VP approval

Verification date: 2026-09-04 (Asia/Calcutta). Target: explicitly authorized dedicated Developer Edition alias caip-dev. This is a sanitized implementation report, not a full showcase release certification. Org, user, record and job identifiers, email addresses, credentials, activation links and raw logs are intentionally omitted.

## Deployment and automated checks

- Scoped manifest: manifest/milestone-4.xml. Deployment succeeded: 13 components, 32 test methods, zero errors. The native approval process is active.
- Separate post-deployment regression: 35/35 Apex results passed, including three test setup results; test-run coverage 99%.
- Class coverage: StrategicDiscountPolicy 52/52 lines; StrategicDealPolicyController 39/39; StrategicDealApprovalController 62/63.
- Local component tests: 22 tests in three suites passed. ESLint passed.
- Seven new Apex methods execute the actual native approval engine with separate minimum-access test users: approve, reject, recall/resubmit, native lock and unlock, duplicate submission, exact boundary, self-approval, wrong actor/actions and stale stored eligibility. These are not browser tests.
- Component tests mock Apex and Lightning services; they verify action rendering, error handling and refresh behavior, not live Salesforce authorization.
- Preflight found no Opportunity Workflow; unrelated Case Workflow was not deployed or changed. The org's optional Apex lock/unlock API preference was left unchanged. Native locks were tested through denied ordinary-owner edits.

## Separate approver and demo data

- Provisioned one Synthetic Regional VP with Minimum Access - Salesforce and Regional_VP_Approver. No existing administrator account was changed. The user approved reusing the current account's email inbox; the address was read at runtime rather than saved in source.
- Salesforce activation/password setup was performed privately by the user, who reported completion. No password was collected.
- Reset Preview detected six approver changes, Apply changed those six managed records without creating records, and Verify passed all seven cases. Policy evaluation count changed from 7 to 13 during Apply and stayed 13 during Verify. The missing-approver case was unchanged.
- Reset now refuses pending native requests on managed records. The separate VP is selected by its exact synthetic identity; no persisted user ID is required in source.

## Live browser observations

- Opened the app-specific Opportunity page for SYN-SDA-04 Above 15 Percent in the existing owner session. Confirmed USD 50,000,000.01, discount 15.01%, strategic flag, Synthetic Regional VP lookup and pending policy eligibility.
- Submitted once using the live Regional VP Approval panel. The panel showed Latest request: Pending, record-lock notice and Recall Approval, without Approve/Reject for the owner.
- Independent read-only org query confirmed Pending, exactly one work item, and assignment to the separate demo VP.
- Separate VP password setup is user-confirmed. The VP's browser decision is not yet observed: Chrome's control connection timed out. The user has been given the manual approval step; the live request is deliberately left pending, not approved through an administrator override.

## Boundaries and remaining gates

### Lightning-access correction (2026-09-04)

The user reported that the separate VP could not enter Lightning Experience. Read-only inspection confirmed LightningExperienceUser was false in both the profile-owned permission set and assigned Regional_VP_Approver permission set. This was an initial implementation omission, not a password problem. Added only LightningExperienceUser to Regional_VP_Approver and deployed the single permission set through manifest/milestone-4-lightning-access.xml. Deployment succeeded with one component and seven native approval tests, zero errors. Live assignment verification then returned LightningExperienceUser=true, ModifyAllData=false and ApiEnabled=false. Separate post-deployment regression again passed 35/35 results with 99% test-run coverage. Browser entry after correction and the VP's live decision await user verification. Original milestone-4-source-hashes.json describes the pre-correction source; the changed permission set and corrective manifest are fingerprinted in milestone-4-lightning-access-source-hashes.json.

The rule remains strictly strategic AND amount > USD 50,000,000 AND discount > 15%, with no FX conversion. Native request history and policy-evaluation evidence are distinct. Normal users cannot directly edit derived outcomes or evaluation evidence. See docs/milestone-4-design.md for administrator overrides, lookup-based routing and standard-API submission limitations.

A custom external REST API remains deferred. The separate agent may use standard Salesforce APIs; this milestone's controller is an internal Lightning adapter. A repeatable external API/UI harness, full release/reset evidence and the actual VP-session browser decision remain unverified. No repository commit, push, tag, destructive deployment or data deletion was performed for this milestone.

## Subsequent VP confirmation

After the Lightning-access correction, the user reported successfully approving the original SYN-SDA-04 deal using the separate VP login. Read-only verification confirmed Opportunity status Approved, latest native request Approved, and the approval step actor matching the synthetic VP alias. This supersedes the pending-decision notes above. The decision was performed by the user; it was not an agent-observed click or a repeatable browser-suite execution. The VP's inability to save deal inputs is intentional read-only access; the currently visible Save and Evaluate button is a known UI clarity limitation.
