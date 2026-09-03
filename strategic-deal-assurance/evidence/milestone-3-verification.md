# Milestone 3 — Lightning app verification

Verified 2026-09-04 (India time) in the authorized Developer Edition alias caip-dev. This is an implementation checkpoint, not a full LIVE_SHOWCASE release.

## Deployment and automated checks

- Final validation: Succeeded, 25 test methods, zero component/test errors.
- Actual scoped deployment: Succeeded, 14 components, 25 test methods, zero errors.
- Separate post-deployment Apex run: Passed, 27 results including two test setups, zero failures. Policy: 52/52 executable lines covered; controller: 39/39, both 100%.
- Result reconciliation: 10 policy tests + 11 Flow/security tests + 4 reader tests = 25 methods. The standalone runner additionally reports both successful test setups.
- Jest: 14 tests across two component suites passed. ESLint exit 0. The coverage invocation emitted an empty instrumented-file table; JavaScript coverage percentage is not established.
- Controller tests verify minimum-access user success, denial without parent permissions, invalid/missing IDs, latest-five history and a narrow DTO without parent/user identifiers. Flow/security grant tests include the new read-only Account dependency.
- Strategic_Deal_User assignment to the currently authorized demo identity succeeded (one success, no failures), following explicit user consent. No other real-user assignments made.
- Live custom metadata read-back: Default active; amount 50,000,000; discount 15; version baseline-15. USD remains unchanged.

## Browser smoke test

Chrome extension attempts timed out. The existing authenticated in-app browser session worked; no credentials were requested, copied or written to the repository. Initial direct-tab navigation returned Page doesn't exist before the new app was launched. App Launcher search found Strategic Deal Assurance; following its observed app link loaded Deal Workbench successfully.

Created one retained synthetic Opportunity, SYN-UI-Boundary-20260904, through the deployed Lightning form:

1. Amount USD 60,000,000; strategic=true; discount exactly 15%; no approver; close date September 30, 2026. Save succeeded. Card showed Not Required, baseline-15 and one matching history entry.
2. An automation text-replacement attempt appended digits to the formatted percent input (1515.01%). Salesforce rejected that save, and the UI showed a sanitized error without adding history. Replacing the input using select-all/backspace corrected it to the visibly verified 15.01%.
3. Save at 15.01% succeeded. Without manual refresh, the card changed to Configuration Error with the missing-approver explanation, and history showed the new 15.01% row followed by the original 15% row.

Observed required fields, input-only editor, disabled controls while saving, success/error messages, USD thresholds, policy versions and history. The browser is left open on the saved synthetic deal. No record deletion or native approval action was performed. The current demo identity may already have administrator grants; the browser smoke test does not prove least privilege. Apex minimum-access tests provide the scoped permission assertions.

## Limitations and follow-up

- App-page create/edit was browser-verified. App-specific Opportunity record-page navigation, Account/User lookup selection, Start new, manual refresh, desktop/mobile breakpoint coverage and all user personas were not individually live-tested.
- A narrow viewport screenshot was inspected; stitched full-page capture showed capture artifacts, so no pixel-perfect/full accessibility certification is claimed.
- App-specific record-page metadata deployed; the new layout is not globally/profile assigned. Existing layouts remain untouched.
- The permission-set descriptions still contain a historical deferred-reader sentence; actual deployed class access and milestone-3 design supersede it.
- No external REST facade/correlation, durable idempotency, native approval, formal Selenium/RestAssured harness or repeatable seed/reset workflow yet.
- Code Analyzer, native FlowTest execution and deliberate Flow fault injection remain unverified. Apex integration tests are not native Flow coverage.
- Dependencies installed from npm with lifecycle scripts disabled. Existing deprecated transitive development packages were not broadly upgraded; no dependency security audit is claimed.
- Evidence remains private with no direct normal-user CRUD. Reader elevation is parent-gated and read-only, not administrator-proof immutability.
- All changes remain uncommitted. No destructive deployment, policy mutation, FX conversion, org currency change, commit, push or baseline tag occurred.
- This report intentionally excludes org/user/record/job identifiers, session URLs and raw logs.

## Repeat and inspect

- manifest/milestone-3.xml
- scripts/test-milestone-3.ps1
- docs/milestone-3-design.md
- evidence/milestone-3-source-hashes.json
- npm run test:unit -- -- --runInBand
- npm run lint
