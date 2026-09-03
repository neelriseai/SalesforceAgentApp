# Milestone 6 — configurable demo rules and detailed test catalog

Verification date: 2026-09-04 local (Asia/Calcutta); tool receipts fall on 2026-09-03 UTC. Target: previously bound non-production Developer Edition alias `caip-dev`. Runtime org/user/record/deployment IDs and raw output are intentionally omitted.

## Deployed scope

`manifest/milestone-6-demo-rules.xml` deployed successfully with RunSpecifiedTests and all five named suites: DemoBusinessRulesTest, StrategicDiscountPolicyTest, StrategicDiscountFlowTest, StrategicDealPolicyControllerTest and StrategicDealApprovalControllerTest. Final deployment reported zero component errors and zero test errors.

- Eight OFF Custom Metadata records, five configuration fields and an editable Custom Metadata layout.
- With-sharing DemoBusinessRules service and seven thin object triggers.
- Case Demo Resolution field, placement on the existing Case-Case Layout and narrow field-only Demo_Rule_Operator permission set.
- DemoBusinessRulesTest: 16 test methods; transaction-local metadata overrides exercise enabled/disabled behavior without persisting configuration changes.

Earlier deployment attempts failed and rolled back: Custom Metadata TextArea/layout requirements were corrected, and API 67 test-fixture operations were made explicitly system-mode to avoid read-only/FLS fixture failures. This change is confined to rollback-only test setup/operations. Production related-record queries remain explicitly WITH USER_MODE. A composed-error assertion was changed to validate both rules sequentially without assuming Salesforce exposes two simultaneous error entries.

## Post-deployment evidence

| Check | Observed result |
|---|---|
| Separate post-deployment run, all five suites | **51/51 passed**, 0 failing; CLI testRunCoverage **100%** for that run, not a universal org coverage claim |
| Native Lead conversion | Unqualified conversion rejected and rolled back; Account/Contact counts unchanged; qualified conversion succeeded in test transaction |
| Bulk behavior | 200-Account partial-save case and 200-Opportunity primary-role case passed; query-budget assertion passed |
| Rule configuration readback | Eight records present, Enabled=false, Rule Version=baseline-off-v1; minimum=100000, Lead required status=Working - Contacted |
| Strategic policy readback | Active=true, minimum USD 50000000, discount 15, version baseline-15; unchanged |
| Operator permission assignment | Demo_Rule_Operator assigned only to current authorized operator; no new VP/admin/API/object grants |
| Case REST describe | Demo_Resolution__c exists, createable=true, updateable=true for operator |
| Operator layout REST read | Demo_Resolution__c present in returned Case layouts |
| Existing multi-module Verify | 368 business rows, 40 evaluations, all 40 policy results match, no drift; 0 inserted/committed rows |
| Jest | 22 tests in three suites passed |
| ESLint | Passed |
| Local reset plan test | Passed; seven cases, no live org calls |
| Local multi-module plan test | Passed; 368 rows, nine object types, independent policy oracle, no live org calls |
| Manual specification | 42 cases / 232 detailed action-and-result steps generated; NOT_RUN, not browser execution evidence |
| Manual catalog checks | 3/3 passed; generated JSON/Markdown freshness verified |
| Knowledge catalog checks | 7/7 passed; deterministic graph, source links, fixture/rule mappings and publish-safety checks |

Node test child processes required running outside the restricted Windows filesystem sandbox; the initial EPERM was a runner-environment issue, not a test assertion failure.

## Browser and release limitations

The browser inventory was readable, but selecting the logged-in Salesforce tab timed out. No browser rule toggle/save walkthrough is claimed for this milestone. Field and layout availability above is REST evidence, not a screenshot or complete UI interaction. The 42-case manual suite remains unexecuted as a suite. Existing original approval browser verification belongs to its earlier milestone.

Enabled-branch guard behavior was tested via real Salesforce DML/native conversion with test-only metadata overrides; no live production-context Enabled switch was changed in this milestone. Readback verifies the deployed baseline metadata. A future RULE-01/RULE-08 browser run should demonstrate an actual Setup toggle followed by a native save.

No persistent business data was inserted/updated/deleted by the implementation verification. No Lead was permanently converted; test transactions roll back. No active approval was canceled, no original approved Opportunity overwritten and no real customer messages sent. No dedicated external-agent OAuth lane or API/UI automation harness was created.

The implementation is a scoped synthetic-demo rule layer. Prefixes remain editable; additional status values, primary-role changes after close and global User/permission administration are not covered. See the requirement, operator guide and test plan before extending its claims.
