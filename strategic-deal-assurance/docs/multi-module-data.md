# Cross-module synthetic dataset operations

Dataset: SDA-CROSS-MODULE-v1. Source: data/multi-module-plan.json. The plan contains 368 business rows across nine object/relationship types, plus 40 initial Flow-created evaluation rows. Ten scenario definitions are available in data/multi-module-use-cases.json and the human-readable docs/multi-module-manual-e2e.md.

## Commands

Run from the strategic-deal-assurance project directory using the existing authorized caip-dev CLI alias. Never add passwords, tokens or login URLs to these commands.

```powershell
# No record writes. Shows whether fixtures already exist.
powershell -NoProfile -File scripts/demo/seed-multi-module.ps1 -Mode Preview

# First-time load only. Existing complete fixtures are left unchanged.
powershell -NoProfile -File scripts/demo/seed-multi-module.ps1 -Mode Apply -ConfirmDataInsert

# Read-only comparison of stored starting values, links and policy outputs.
powershell -NoProfile -File scripts/demo/seed-multi-module.ps1 -Mode Verify

# First-time insert/validation followed by transaction rollback.
# If data is already present, this only compares it; it does not reset/rehearse UI actions.
powershell -NoProfile -File scripts/demo/seed-multi-module.ps1 -Mode Rehearse -ConfirmDataInsert

# Local plan, relationship, oracle and write-confirmation checks; no org calls.
powershell -NoProfile -File scripts/demo/test-multi-module-local.ps1
```

## Safety contract

- Requires the existing ignored .sf/demo-data-binding.json fingerprint, dedicated Developer Edition, administrative operator and unchanged USD baseline-15 policy. It never rebinds the org automatically.
- Requires the single active Synthetic Regional VP already provisioned. No extra licensed users are created. The user separately approved enabling Marketing User for the current demo administrator to allow Campaign creation. The VP's permissions are unchanged.
- The only metadata change in this milestone is the existing app's navigation/description through manifest/milestone-5-navigation.xml. Standard native objects supply the other modules. No new custom Flow, trigger, validation rule, SLA, outbound integration or API facade is added.
- All records use synthetic names and reserved example.invalid email addresses. DML email options are disabled. Preflight found no Apex triggers and only the strategic Opportunity record-triggered Flow; Case Workflow contained an unused field-update definition, not an active rule. No campaign-send action is executed. Recheck automation before rerunning in a changed org; arbitrary future automation is not suppressed by this script.
- CRUD/FLS/sharing are enforced through user-mode queries and DML. Source contains no org/user/record IDs. Runtime logical relationships resolve from inserted records or exact matches; the VP and current operator are runtime references.
- The loader is CREATE-ONLY. It never updates or deletes an existing business record, converts a lead, submits/recalls an approval, repairs field drift, or overwrites evaluation evidence. New Opportunities are evaluated by the existing Flow, not by assigning derived fields.
- Exact-name matching plus reserved marker/owner checks prevents adopting unrelated records. Account.AccountNumber and Opportunity.NextStep are also checked for marker collisions. Deleted matching fixtures block creation. All initial writes are one transaction; failed validation rolls back the load.
- Partial datasets are refused in write modes. Do not rename/remove reserved names and markers. Other object markers are in Description (not filterable), so an entirely renamed dataset cannot be rediscovered reliably. This is a local demo tool, not a distributed idempotency service. Do not seed from multiple computers concurrently. A local mutex prevents overlapping local runs.
- A complete existing dataset receives zero DML. Verify/Apply report baselineMatches and drift without restoring values. A successful command is not necessarily a pristine-baseline pass: inspect baselineMatches. Manual lead conversion, added relationships and final approval states can intentionally produce drift.
- The verifier checks every planned input/relationship field and independently checks expected policy outputs. Evaluation count is observed, not required to stay at 40 after manual tests. It does not perform a complete historical-evidence audit or discover arbitrary extra unrelated records.
- Unique ignored artifacts/multi-module/<run>/result.json receipts contain counts, simulation flag, drift keys and source hashes. Generated request.apex uses a compressed copy of the checked-in synthetic plan to fit the anonymous Apex source-size limit. No credential is embedded. Raw org logs are not persisted by the wrapper.
- Do not retry a write merely because a response was lost. First use Verify. Rehearse receipts describe real Salesforce transactions that were rolled back; they are not committed data or live browser execution evidence.

## Repeat manual tests

Use the cleanup for each scenario in the manual guide. Most tests restore a field's initial value; these normal edits do not remove history. MM-03 lead conversion is a one-way normal-UI operation and consumes one fixture; use another unconverted synthetic Lead for a later run. MM-09 leaves native approval history and additional evaluations intentionally. There is no blanket delete-and-reseed reset for this dataset.

Existing SYN-SDA baseline data has its own reset utility. Do not run that reset expecting it to touch SYN-MM records, and do not use this loader to reset the already-approved original deal.

## References

The loader uses Salesforce's [user-mode data operations](https://developer.salesforce.com/blogs/2023/05/write-simplified-and-secure-apex-with-spring-23-updates), [native ZIP support](https://developer.salesforce.com/blogs/2025/02/reading-excel-files-using-the-apex-zip-functionality), and [DML email options](https://help.salesforce.com/s/articleView?id=000385486&language=en_US&type=1). Campaign tests use [native campaign-member statuses](https://help.salesforce.com/s/articleView?id=sf.campaigns_customize_member_status_parent.htm&language=en_US), not a marketing-send integration.
## Configurable-rule prerequisite

Before baseline seeding, verification or the original MM workflows, restore all eight Demo Business Rules to OFF and the strategic discount to baseline-15. See [configuration guide](demo-rules-guide.md) and [complete test plan](test-plan.md). New SYN-RULE per-run fixtures are outside this create-only loader's ownership; it neither restores their fields nor removes them. Successful Lead conversion remains consumed.
