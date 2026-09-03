# Milestone 2 — live Flow and permissions verification

## Outcome

Deployed to the explicitly authorized Developer Edition alias caip-dev. Flow Strategic_Discount_Approval is active at version 1. This is an implementation checkpoint, not a full LIVE_SHOWCASE release decision.

- Final dry-run: Succeeded, 21/21 test methods, no component/test failures.
- Actual deployment: Succeeded at 2026-09-03T20:32:37Z (2026-09-04 India time); checkOnly=false; 10/10 components; 21/21 test methods; no errors.
- Separate post-deployment run through scripts/test-milestone-2.ps1: CLI exit 0, Passed, 22 passing results, 0 failures, 100% policy-class coverage.
- Result reconciliation: 10 policy methods + 11 Flow/security methods + the successful setupLimitedIdentity @TestSetup result. Deploy reports 21 test methods; the separate Apex runner includes setup in its count of 22.
- Policy coverage: 52/52 executable lines. This is Apex coverage, not a native Flow coverage percentage.
- Live metadata read-back confirmed active Flow version 1, all four permission sets, and Amount USD display label.
- User expressly chose USD; default currency remained USD. Numeric amount threshold remains 50,000,000 and discount threshold remains strictly greater than 15. No FX conversion or org currency setting change.

## Verified assertions

- Exact USD 50,000,000 and exact 15% do not require approval; above both boundaries does.
- Missing approver fails closed, with evidence recording that approval is required.
- Null discount executes the real invocable Flow path without failure.
- Each relevant create/update produces one evidence row and matching derived outcome/version/time.
- Changed input with unchanged status still creates a new snapshot and distinct correlation/hash.
- Irrelevant and output-only updates produce no new evaluation and do not reset an Approved state.
- 200-record bulk insert produces exactly 200 evaluation rows and correct alternating strategic/non-strategic outcomes.
- Minimum Access - Salesforce plus only Strategic_Deal_User can create inputs with user-mode DML; system-context Flow writes the derived outcome.
- That limited user cannot edit outcome fields or directly read/create/edit/delete evidence. An attempted user-mode approval-status update is rejected.
- All four permission-set definitions match the intended Opportunity CRUD/field/API matrix, without global or all-record elevation.

## Scope and limitations

- No permission sets assigned to real users. Tests create temporary users/assignments and synthetic records, all rolled back by Apex test execution.
- No LWC, Lightning app/page, parent-authorized history reader, external REST facade or native approval process yet.
- Evidence remains Private with no direct normal-user CRUD. Parent-based history access is deferred, not claimed.
- Fault connectors are present on action/update/create and route to a sanitized transactional Custom Error. Deliberate runtime fault injection is not covered by this test run.
- Apex tests execute the real Flow but are not native FlowTest results; native Flow tests were not run.
- Salesforce Code Analyzer remains uninstalled/not run. Static security clearance and full showcase readiness are not claimed.
- API names containing INR are intentionally retained as legacy identifiers; user-facing amount labels and policy explanation use USD.
- No commits or baseline tag created; working tree remains uncommitted. No secrets or raw org/job/user identifiers are included in this report.

## Artifacts

- Deployment scope: manifest/milestone-2.xml
- Repeat tests: scripts/test-milestone-2.ps1
- Source hashes: evidence/milestone-2-source-hashes.json (explicitly scoped, not a full repository snapshot)
- Permission contract: evidence/metadata/permission-matrix.json
- Implementation details and remaining gates: docs/milestone-2-design.md
