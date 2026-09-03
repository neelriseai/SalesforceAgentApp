# Demo data/reset checkpoint verification

Verified 2026-09-04 India time against the authorized caip-dev Developer Edition. This is DATA_CHECKPOINT evidence, not a full tagged LIVE_SHOWCASE release.

## Results

| Live check | Result |
|---|---|
| Read-only Preview | One account and seven Opportunities planned; zero records written |
| First Apply | One account and seven Opportunities created; seven evaluations; all seven explicit outcomes passed |
| Second Apply | Zero creates, zero updates; evidence remained 7; all seven cases passed |
| Rehearse | Temporarily changed a discount and an output-only approval status; reset two fixtures; four expected new evaluations (7 to 11); all seven cases passed; entire transaction rolled back |
| Verify after rehearsal | Zero differences; seven retained evaluations; all seven cases passed; latest above-threshold history matched baseline |
| Existing manual demo | SYN-UI-Boundary-20260904 still USD 60m, 15.01%, Configuration Error; outside managed reset scope |
| Regression suite | 27/27 Apex results passed including setups; 100% reported test-run coverage |
| Local checks | PowerShell parsing, seven-case plan checks and both mandatory write-confirmation guards passed; zero live calls in local tests |

All successful commands exited 0. The deployed policy remains active baseline-15, USD 50,000,000 and strictly above 15%. Expectations are literal in the data plan, not obtained from the policy being checked.

## Safety boundary

No data/evidence deleted. No Salesforce metadata, permissions, currency setting or threshold deployed/changed. No new plugin, test framework or external endpoint installed. No commit, push or tag created. One local ignored org-fingerprint binding was created. The currently authorized demo identity serves as functional approver; this does not implement independent approval authority or native approval.

Initial read-only development attempts exposed Organization currency-field differences, anonymous-Apex access restrictions and HTML-escaped debug delimiters. Those were corrected before the successful seed: currency is checked via UserInfo, DML/query access is explicitly user-mode, a sample history is read through the existing parent-authorized controller, and receipt text is decoded before parsing. These failed attempts did not seed records.

The reset is data-only and preserves audit history. It is not the guide's destructive clean-tag/metadata reset. Org mismatch, policy drift and record collision guards are present; their deliberately induced live negative cases were not run. Cross-computer concurrency is not guaranteed. Markers must be retained. Verify audits every fixture's inputs/outcome and one latest-history sample, not every evidence field on every row.

The rehearsal used real Salesforce DML and Flow execution, but was explicitly rolled back. Its 11-row in-transaction count is not retained state; the subsequent independent Verify observed seven rows. No native approval was invoked. Browser navigation of the newly seeded cases was not repeated in this checkpoint; milestone-3 browser verification remains separate evidence.

Successful per-run sanitized receipts are in ignored artifacts/demo-data/<run-id>/result.json. Raw logs, auth state, identities and record IDs are not included here. The generated request files contain synthetic data and a non-secret fingerprint. No Java API/UI automation suite has been added.

## Source fingerprints (SHA-256)

| File | Hash |
|---|---|
| data/baseline-15-plan.json | 57e0b5d40caeb654e99ce217c757df2169356cd951c644f6abd68045c98453c1 |
| scripts/demo/reset-baseline.ps1 | 754eeaf6732c7cb9b80ce15c7d82934df3e682f28493a00324b7f7938fcc86b8 |
| scripts/demo/reset-baseline.apex.template | 7d6816a0c3aa4da452354a9dd644fba1bc1a485049246abfbfc161aabc0f7131 |
| scripts/demo/test-reset-local.ps1 | 4ebc4c1d74f250c94bd1f6b7ab7a9603fbf17f8940e22d813ba66d5ebbac8a13 |

Usage, limitations and the distinction between the app tests and the separate assurance agent are documented in docs/demo-data-reset.md.
