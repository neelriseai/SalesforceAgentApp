# Repeatable demo data and non-destructive reset

This checkpoint prepares the Salesforce app for repeatable demonstrations. It does not build your separate assurance agent, add a REST facade, or install Selenium/RestAssured.

## What is loaded

One Account named `SYN-SDA Demo Account` and seven Opportunities beginning `SYN-SDA-01` through `SYN-SDA-07` are defined in data/baseline-15-plan.json. All are USD; stage is Prospecting and close date is December 31, 2026. The baseline is literal and repeatable, not a moving date. Advance the plan deliberately before future-year demonstrations.

| Case | Expected outcome |
|---|---|
| Non-strategic, USD 60m, 20% | Not Required |
| Strategic, exactly USD 50m, 20% | Not Required |
| Strategic, USD 50,000,000.01, exactly 15% | Not Required |
| Same amount, 15.01%, approver present | Pending Regional VP |
| Same amount/discount, approver absent | Configuration Error |
| Null discount | Not Required |
| Null amount | Not Required |

When the separately provisioned Synthetic Regional VP user is active, it is used as the fixture approver. An older checkout/org without that user falls back to the operator for policy-only demonstrations; native self-approval is blocked. Pending Regional VP is a policy status, not an actual request until the owner submits it.

## Commands

Run from the strategic-deal-assurance project folder. Existing Salesforce CLI authorization for caip-dev is enough; do not put passwords or tokens in scripts.

```powershell
# Preview only (the default): no record writes.
powershell -NoProfile -File scripts/demo/reset-baseline.ps1

# Create missing managed fixtures or restore their starting values.
powershell -NoProfile -File scripts/demo/reset-baseline.ps1 -Mode Apply -ConfirmDataReset

# Check the saved state without changing it.
powershell -NoProfile -File scripts/demo/reset-baseline.ps1 -Mode Verify

# Exercise real drift and restoration, then roll the entire rehearsal back.
powershell -NoProfile -File scripts/demo/reset-baseline.ps1 -Mode Rehearse -ConfirmDataReset

# Local checks, no Salesforce calls.
powershell -NoProfile -File scripts/demo/test-reset-local.ps1
```

The first binding was already established on this computer. On a different checkout, first verify that caip-dev points to the intended dedicated org, then run Preview with `-BindDemoOrg`. The script stores only the alias and SHA-256 org fingerprint in ignored `.sf/demo-data-binding.json`, never auth details. A mismatch stops execution; `-BindDemoOrg` does not overwrite an existing binding.

Open App Launcher > Strategic Deal Assurance > Opportunities. Choose an appropriate list view (Recently Viewed may not show records created by the CLI), and search `SYN-SDA`. Open a record to use the app's workbench. Your earlier `SYN-UI-Boundary-20260904` record is outside this dataset and is not reset.

## Safety and behavior

- Restricted to locally bound caip-dev, Developer Edition, USD, active baseline-15, 50m amount and 15% discount. It refuses policy drift instead of redeploying metadata.
- Administrative operator profile is required. No new permissions are granted. Ordinary sales users use the app, not this reset utility.
- AccountNumber stores the reserved account marker; Opportunity.NextStep stores each reserved case marker. Existing exact-name collisions, duplicate markers, or a different owner cause an abort. These fields are dataset identifiers, not a security boundary: do not manually remove/change them.
- Queries use exact names/markers, not `SYN-%` bulk cleanup. Record DML runs in user mode. The existing parent-checked controller reads one sample latest-history summary; direct evidence-field privileges are not added.
- Missing records are inserted. Drifted input values are restored. Unchanged records receive no DML, so repeating Apply adds no records or evidence.
- Output-only status/version drift is restored by two real strategic-flag changes through the Flow, not by forging derived output fields. Both evaluations are retained. Normal relevant input restoration adds one evaluation.
- Rehearse temporarily changes one discount and one stored outcome, resets them using the same path, verifies results, then rolls back all its writes. It executes live Salesforce transactions but is labelled simulation because nothing is committed. It must run only while the dedicated demo org has no additional consequential automations.
- Assertions are inside the transaction; an unhandled failure rolls back its data writes. Missing/ambiguous CLI receipt is not proof of rollback: run Verify before retrying.
- A local mutex prevents overlapping runs on this computer; existing account/fixture rows are locked during a transaction. Do not run this utility concurrently from other computers, especially first-time seeding. Markers are not unique database keys, and this is not a distributed idempotency service.
- If both a fixture's name and marker are manually changed, it cannot be rediscovered by this version. Stop and reconcile manually rather than creating a replacement. Other fields (such as extra notes, products, contacts, files and unrelated records) are outside reset scope.
- No record/evidence deletion, schema change, policy redeployment, commit/tag or permission change. History accumulates intentionally; this restores starting values, not a blank audit log.
- Outstanding native approvals block reset. Finish or recall those requests first; the script does not bypass native approval locks or cancel work items.

## Evidence and limitations

Each successful run writes a unique ignored artifacts/demo-data/<run-id>/result.json containing sanitized counts, independent case results, hashes and timestamps. The generated request.apex contains only synthetic data and a fingerprint. Raw logs, credentials and IDs are not written. Failure may leave a request artifact without a success receipt.

Verify checks all seven inputs/outcomes, total evidence count for write modes, and the above-threshold case's latest history via the secure reader. It is not a full per-case history audit. Existing Apex/Flow suites supply broader snapshot/security coverage; run scripts/test-milestone-3.ps1 separately.

The guide's full release reset (clean Git tag, exact metadata redeploy, destructive cleanup and complete API/UI suite) is not implemented here. There is no tagged baseline yet. Receipts say DATA_CHECKPOINT and cleanTaggedReleaseVerified=false; they do not certify LIVE_SHOWCASE readiness.

## What API/UI automation would mean later

API tests would create or update a synthetic Opportunity without clicking the browser and verify the stored outcome/history. UI tests would open Salesforce, enter values, click Save and Evaluate, and check the displayed result. For example, both could check that 15% is Not Required while 15.01% with an approver is Pending Regional VP.

They are repeatable test assets for this demo app, not the separately developed agent. Your assurance agent could later analyze, execute or repair them as part of its demonstration. The guide proposes Java RestAssured for API tests and Selenium/TestNG for UI tests; those are not installed or implemented by this checkpoint. Scope and ownership should be agreed before building them, especially if your separate agent already supplies these tests.
