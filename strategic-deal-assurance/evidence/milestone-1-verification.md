# Milestone 1 — live verification

This is a sanitized implementation checkpoint, not a LIVE_SHOWCASE release decision.

## Results

- Target: verified Developer Edition, explicitly authorized alias `caip-dev`.
- Project API: 67.0. Salesforce CLI: 2.149.9.
- Local XML parsing: 30 XML files passed, including the milestone manifest.
- Dry-run deployment: succeeded; 29/29 components; 10/10 tests; no component/test errors.
- Actual deployment: succeeded at 2026-09-03T20:05:04Z; checkOnly=false; 29/29 components; 10/10 tests; no errors.
- Deployment policy coverage: 52/52 executable lines, 100%.
- Independent post-deployment run started 2026-09-03T20:05:31Z: Passed; 10 passed, 0 failed, 0 skipped; 100% policy coverage.
- Completed test retrieval separately confirmed CLI exit code 0 and Passed outcome.
- Live Default custom metadata query: Active=true; Minimum_Amount_INR=50000000; Discount_Threshold_Percent=15; Rule_Version=baseline-15.
- Tooling API FieldDefinition verification: all seven Opportunity fields, 13 evaluation fields, and four policy metadata fields are present with expected types; the evaluation Opportunity lookup is required.
- Baseline tests include strict boundaries, null inputs, missing/blank approver, invalid configuration, normalized hashes and 200 ordered input/output pairs with no DML/SOQL.

## Source fingerprints (SHA-256)

| Asset | Hash |
|---|---|
| StrategicDiscountPolicy.cls | ad95d4b2da19c7480232f35b0ad18699d9adad85e5610aa1eb4c1d27be8649cd |
| StrategicDiscountPolicyTest.cls | 647d784594cd3fb2e85e5ad8a553247ce02a7380bbc1dbdeedc058e247f49513 |
| Strategic_Discount_Rule.Default.md-meta.xml | 349979f1cae2ff12089a903af7438dc81ca36be20df9130bcf5fc1d05a265fa3 |
| manifest/milestone-1.xml | ef334ff432e6fc96835e8e9fec41ef7c6be08b43694fc5f0eb641446d1f05cfe |

## Limitations and remaining gates

- No commit/tag created: source is an uncommitted first milestone, not a tagged full baseline.
- No Flow/LWC/API facade/native approval/permission set/seed data deployed.
- Record describes are permission-filtered. Newly deployed field visibility requires the later explicit permission-set milestone.
- Evaluation object starts Private; parent-aware sharing and append-only normal-user access are not yet implemented.
- No actual Opportunity or evaluation records were created by this milestone. Policy tests are not evidence of end-to-end Flow behavior.
- Salesforce Code Analyzer is not installed and was not run. Org compilation/tests and local XML checks passed; static-analysis security clearance is not claimed.
- Evidence omits usernames, domain, org and job identifiers. This sanitized summary is not the full evidence ingestion contract; full traceable run manifests remain a later milestone.

## Reproduce tests

From the DX project directory, run `powershell -NoProfile -File scripts/test-milestone-1.ps1` after CLI authorization. The script runs named tests and emits only the non-identifying summary. Inspect failures locally.
