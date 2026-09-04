# Application test plan and future automation handoff

## Scope and artifacts

Locator showcase acceptance is distinct from component tests: record eight working field locators plus Save, change the runtime variant, prove all nine old targets invalid or wrong by identity before any write, then have the external agent recover and verify persisted results. Resilient locators are passes, not healing events. The runnable baseline XPath harness and advanced no-explicit-hint variant are not implemented; the current LH specification covers the assisted level only. Salesforce must not contain the healer or roll back presentation to conceal a failed locator.

Execute the supplemental **LH-01–06 / 20-step locator suite** in [JSON](../data/locator-healing-suite.json) and the [operator/recovery guide](locator-healing-demo.md). It covers all eight Opportunity input mappings plus the save action across three configurable layouts, authorization denial, ambiguous candidates and restoration. Require independent persisted-value checks, zero wrong-field writes, zero unapproved submissions and abstention on uncertain identity. Source/Jest and Apex test results do not certify browser-based healing; [milestone 8 evidence](../evidence/milestone-8-verification.md) records the distinction.

For the later data-visibility expansion, also execute VIS-01–03 in the [demo data and reports guide](demo-data-visibility.md). These supplemental cases check three named views, five saved reports and create-only repeatability; the original 42-case behavioral specification remains unchanged.

The unified [manual suite](manual-test-cases.md) contains **42 cases / 232 action-and-expected-result steps**. Its [JSON companion](../data/manual-test-suite.json) provides stable IDs, actor, modules, fixture names, preconditions, exact data where applicable, ordered steps, negative checks, cleanup and evidence requirements. All generated case statuses are NOT_RUN specifications, not test results.

| Group | Cases | Coverage |
|---|---:|---|
| MM-01–10 | 10 | Existing Account, Contact, Lead, Opportunity, roles, Case, Task, Campaign, User approval and Customer 360 workflows |
| POLICY-01–07 | 7 | Original strategic predicate, exact boundaries, missing approver and null inputs; new per-run records protect original approved fixtures |
| RULE-01–17 | 17 | Eight configurable rules, on/off, thresholds, blanks, whitespace, atomic rejection, composition, configuration errors, scope and original-regression compatibility |
| POLICY-08–09 | 2 | Changed/inactive strategic policy, stale stored evaluations and current-policy app submission check |
| APPROVAL-01–03 | 3 | Separate-actor approve/reject and owner recall; native vs policy history |
| SECURITY-01–02 | 2 | VP input/configuration restrictions and synthetic-scope isolation |
| RECOVERY-01 | 1 | Restoration, conversion accounting, pending requests and data reconciliation |

RULE-17 references the ten MM cases as a regression grouping; do not count it as additional independent execution evidence for those cases. This is a detailed suite for implemented behavior, not a claim of every conceivable Salesforce test, load test, accessibility check or enterprise security certification.

## Common preflight (required for every run)

1. Record source commit/graph snapshot, environment binding, actor role and a unique run suffix in a protected local artifact. Verify dedicated `caip-dev` Developer Edition; refuse production. Keep real runtime IDs and auth out of Git.
2. Establish separate owner and VP sessions. Passwords/MFA stay private. Admin is a convenient cross-module operator, not proof of ordinary-user permissions. Future API personas need separately approved OAuth and least-privilege grants; existing integration set is not full-module access.
3. Read Demo Business Rule records: eight expected API names, all Enabled=false, Rule Version=baseline-off-v1, minimum=100000, Lead required status=Working - Contacted. Read Strategic Discount Rule Default: Active=true, minimum=50000000, threshold=15, version=baseline-15.
4. Confirm required current picklist API values and field access: Prospecting, Qualification, Closed Won; New, Working, Closed; Not Started, In Progress, Completed; Open - Not Contacted, Working - Contacted; Sent, Responded. Do not silently substitute a differently behaving value.
5. Run read-only dataset Verify or compare exact fixtures against the versioned plan. Investigate drift before testing. Seeded data is not Recently Viewed; use all-records lists. Require one exact record match; stop on duplicates.
6. Confirm no pending native approvals on records to edit. Finish/recall only under the named actor and explicit case scope. Never bypass locks.
7. Confirm Case Demo Resolution is visible/editable to the demo operator. If absent, record a layout/FLS blocker. For Contact Roles use the standard Sales app on the same Opportunity if the custom app page lacks Related.
8. Dates are fixed in 2026. Review before a future-year run; record an approved date substitution rather than silently changing the test. Use synthetic names and example.invalid emails only. Leave outbound-email/assignment-notification options off.

## Run order and isolation

Run Customer 360 (MM-10) before mutations. Then MM-01,02,04–09 with cleanup after each; strategic baseline cases; individual rule cases; combined/configuration-error cases; strategic policy changes; approval/security cases. Run RULE-03, RULE-15 and MM-03 conversion cases last. End with RECOVERY-01.

Run serially in this shared demo org: metadata settings are global. Never have one worker alter thresholds while another assumes baseline. Future parallel automation needs isolated orgs or an explicit exclusive configuration lease. A test marks configuration state dirty before editing and restores it in finally/teardown; failed cleanup must fail/block the run, not be swallowed.

The 368-row seed dataset contains 24 Accounts, 60 Contacts, 40 Opportunities, 30 Leads, 30 Cases, 60 Tasks, 4 Campaigns, 40 CampaignMembers and 80 Contact Roles, plus initial policy evaluations. New named SYN-RULE fixtures are created by the specified manual step, not automatically by this milestone. Use each case's exact lookup targets and locally retain returned IDs. Normal Lead conversion cannot be undone; a consumed lead is never a retry fixture.

## Assertion and evidence requirements

For each step: capture the attempted action, expected outcome from the approved requirement, actual UI message, saved values after a fresh read and relevant relationships/counts. For a blocked save prove that all intended edits rolled back. For a successful save verify persistence and no unintended side effects. If UI hides an error detail, corroborate through an approved read lane; do not declare a pass based on a generic toast.

Policy metadata, stored Opportunity eligibility and native ProcessInstance state are distinct. A Pending Regional VP eligibility label does not prove a submitted work item. Stage/role-only changes should not manufacture policy history; genuine amount/discount changes do. Existing history may exceed the card's five-row summary limit, so use latest timestamp/version or approved administrative test evidence; do not claim a total count from a truncated card.

Expected answers must not be calculated solely from the live configuration under test. For approved policy change, version the new requirement and expectations. For injected drift, retain baseline expectations and require the agent to detect the discrepancy. An assurance agent must not repair metadata, overwrite derived results or broaden permissions merely to make tests pass.

## Execution ledger schema

Keep actual results under ignored `artifacts/manual-runs/<run>/`, not in generated specifications. One record per case:

```json
{
  "runId": "local-unique-run",
  "caseId": "RULE-01",
  "sourceCommit": "resolved-at-run-time",
  "actorRole": "demo-operator",
  "evidenceType": "live-ui",
  "status": "NOT_RUN",
  "configurationBefore": {},
  "approvedExpectedConfiguration": {},
  "configurationAfter": {},
  "steps": [{"number": 1, "status": "NOT_RUN", "expected": "", "actual": "", "evidencePath": ""}],
  "cleanupStatus": "NOT_RUN",
  "consumedFixtures": [],
  "limitations": []
}
```

Allowed results: NOT_RUN, PASSED, FAILED, BLOCKED. Record UTC start/end times in real executions. Use logical fixture names in publishable summaries; protect runtime IDs locally. Distinguish `apex-integration`, `live-ui`, `live-api`, `unit-mock`, and `rollback-rehearsal`. A server-side test does not mark browser cases passed. Never log tokens, headers, passwords, activation links or browser session URLs.

## Automation mapping

- Feed `data/manual-test-suite.json` to the future planner; do not parse screenshots as the only scenario specification.
- Browser operations: fresh accessible labels, exact fixture identity, fields by API mapping/label, current UI state. Scope locators to the correct component; inspect shadow DOM. Avoid generated IDs/classes and positional selectors. Save and Evaluate visibility does not imply edit rights.
- API operations: approved OAuth, runtime describe for CRUD/FLS, exact object/record resolution and readback. Ordinary sObject REST cannot write Custom Metadata records; operator Setup or separately authorized Metadata API is needed. Do not replay internal Aura requests.
- Negative tests: inspect every SaveResult/REST error and persisted state. Bulk/Composite partial success is not atomic across every member. Do not blindly retry committed rows or native conversion/approval operations after timeout.
- Configuration changes are operator actions, not privileges automatically granted to the test actor. Never put an administrator token into a VP/integration run to overcome a denial.
- Convert textual lookup names to resolved IDs only at runtime; `@A05` fixture references and `{run}` are not Salesforce IDs. Keep a create/convert/submit operation ledger to avoid duplicates.

## Server-side and local regression

`DemoBusinessRulesTest` tests all switches via transaction-local, @TestVisible metadata overrides available only while Test.isRunningTest(). Production cannot invoke that override. A separate baseline test reads deployed Custom Metadata and independently asserts eight OFF records and fixed defaults. Native Lead conversion tests prove trigger execution and rollback in the target org. Bulk tests use 200 records and inspect partial-save results/query counts. Test fixtures/guard assertions use explicit system-mode DML to isolate rule behavior from field-permission setup; related-record queries in the production service remain user-mode. These tests do not prove ordinary-actor CRUD/FLS or simulate all UI paths or establish an external OAuth lane.

Run the five Apex suites with coverage using `scripts/test-milestone-6.ps1`. Restore baseline first; changing the intended baseline during a demo should fail baseline assertions until restoration. Also run:

```powershell
npm run manual:build
npm run manual:check
npm run manual:test
npm run catalog:build
npm run catalog:check
npm run catalog:test
npm run test:unit -- -- --runInBand
npm run lint
powershell -NoProfile -File scripts/demo/test-reset-local.ps1
powershell -NoProfile -File scripts/demo/test-multi-module-local.ps1
```

Future extension gates: dedicated API identity/permissions and actual API cases; repeatable browser runner for all 42 cases; 200-record API partial success and governor evidence per object; accessibility/responsiveness; metadata-change audit collection; production-grade immutable scope and every-status coverage if required. These are not claimed complete by the current demo milestone.
