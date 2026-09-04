# Milestone 8: configurable multi-field locator drift

Date: 2026-09-04. Target: locally bound dedicated Developer Edition (`caip-dev`); runtime org/user/record IDs and credentials omitted.

## Scope

- Only `strategicDealWorkbench` deployed through `manifest/milestone-8-locator-demo.xml`.
- Three App Builder presentation variants; eight field hooks/order/grouping and save action drift. Baseline is the default; no page assignment or explicit page property was overwritten.
- No business rule/Flow/Apex/permission/user/data changes and no native approval submission. No Git commit/push was made during the deployment verification; a subsequent user-authorized publication includes milestones 7 and 8 together.
- The prior data-visibility milestone's changes are preserved in that publication scope.

## Verification

- Deployment succeeded: one component, zero component errors, 47 deployment test completions, zero test errors. Named suites: DemoBusinessRulesTest, StrategicDiscountPolicyTest, StrategicDiscountFlowTest, StrategicDealPolicyControllerTest, StrategicDealApprovalControllerTest.
- LWC Jest: three suites, 27/27 tests passed. New assertions cover all three variants, eight field identities, unchanged allowlisted submission, disabled save during a transaction, stale hooks, section/order changes, baseline reset, unknown-variant fallback and no automatic submit on configuration change.
- Independent post-deployment Apex run: **51/51 passed, 100% reported test-run coverage**, using the five-suite org-bound runner `scripts/test-milestone-6.ps1`. This coverage value concerns the Apex run, not browser/LWC coverage.
- Local locator specification checks: 3/3 passed. Catalog/security/link checks: 7/7 passed. Existing visibility checks: 3/3 passed. Existing manual suite checks: 3/3 passed, with 42 cases / 232 steps still fresh. New LH specification: six cases / 20 steps, separately indexed.
- `git diff --check` passed. Windows process-spawn restrictions required rerunning the Node worker-based tests outside the sandbox; those completed successfully. The initial Jest command argument forwarding was corrected before the successful 27-test run.

## Explicit limits

- Implemented level is assisted: explicit DOM identity hints remain. The app contains no healer. The recorded executable baseline XPath harness and advanced no-explicit-hint mode are not implemented, and no universal failure of existing XPath strategies is guaranteed. Nine-target recovery must be proven using actual recorded browser targets and the external agent.
- LH-01–06 remain **NOT_RUN** browser/agent specifications, not successful healing evidence. The external agent/healer is not part of this repository.
- Browser discovery found the Deal Workbench. Its current navigation/input visibility was consistent with a restricted session, but profile identity was not verified: the profile-menu read timed out before command dispatch. No administrator App Builder save or runtime variant switch was performed through that session.
- Salesforce base components are mocked in Jest. Browser accessibility, real DOM/shadow traversal, correct input entry/persisted values under each changed variant and external-agent candidate selection still require the documented admin/editor walkthrough.
- Existing VP restrictions remain; no locator strategy may bypass denied field access. Metadata authorization is required independently of browser access.
