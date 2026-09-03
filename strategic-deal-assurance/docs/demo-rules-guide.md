# Demo rule configuration and operator guide

This milestone lets the administrator change eight CRM guard rules directly in Salesforce Setup. No code edit or deployment is needed to toggle these existing rules, change the won-deal minimum or change the required Lead status. The existing strategic discount settings remain in their own metadata type. Creating an entirely new predicate still needs implementation work.

Read the [approved requirement](../requirements/BR-DEMO-CONFIGURABLE-RULES.md), [test plan](test-plan.md), [42 detailed test cases](manual-test-cases.md) and [machine-readable suite](../data/manual-test-suite.json). This guide describes controls; it does not authorize an agent to change rules without an approved demo task.

## 1. Open the settings

1. Sign in as the original demo administrator, not Synthetic Regional VP. Keep two-login approval sessions separate.
2. Click the gear > Setup. Enter **Custom Metadata Types** in Quick Find.
3. Find **Demo Business Rule** and click **Manage Records**.
4. Identify the intended record using its API name in the table below; click **Edit**.
5. Set Enabled and the relevant parameter. Set a meaningful Rule Version such as `demo-min-120k-v1`; never change the record API name or Protected flag.
6. Save, reopen and verify the values. Return to the normal app, refresh the target record and perform the specified save. Each request loads current metadata; a change does not rewrite existing records.
7. After the demo restore the baseline, reopen settings to verify, and restore the data using the case's cleanup steps.

Salesforce supports [declarative editing of Custom Metadata records](https://help.salesforce.com/s/articleView?id=platform.custommetadatatypes_ui_populate.htm&language=en_US&type=5). Metadata administration requires the administrator's existing Setup privileges; the new permission set does not grant those privileges.

## 2. Configuration catalog

| Record API name | When enabled | Parameter | Default | Tests |
|---|---|---|---|---|
| Account_Reparent | Blocks Parent Account changes | None | Off | RULE-01, RULE-16 |
| Contact_Reparent | Blocks Contact Account changes | None | Off | RULE-02 |
| Lead_Qualification | Blocks conversion unless saved prior status matches | Required Value (Lead Status) | Off; Working - Contacted | RULE-03, RULE-15 |
| Opportunity_Minimum | Blocks Closed Won below minimum or with blank Amount | Numeric Value in USD; inclusive >= | Off; 100000 | RULE-04–08, RULE-13–14 |
| Opportunity_Primary_Contact | Requires an existing primary Contact Role on Closed Won save | None | Off | RULE-09, RULE-13 |
| Case_Resolution | Requires Demo Resolution on Closed save | None | Off | RULE-10 |
| Task_Due_Date | Requires Due Date on Completed save | None | Off | RULE-11 |
| Campaign_Active | Blocks member response changes on inactive campaigns | None | Off | RULE-12 |

Every baseline Rule Version is `baseline-off-v1`. Numeric Value is used only by Opportunity_Minimum; Required Value only by Lead_Qualification. Instructions are explanatory text, not executable logic. All settings are global within the allowed synthetic scope, not per-user switches.

The scope is `SYN-MM-` or `SYN-RULE-` on each record's Name, LastName or Subject. Campaign member scope comes from Campaign.Name. The original SYN-SDA discount records and unrelated records are not targeted. Old and new prefixes are checked for direct record updates, so renaming and reparenting in one save cannot evade the guard. These editable prefixes are not a security mechanism.

## 3. Five-minute demo: change the minimum

1. Confirm `SYN-MM-O01 Deal` has Stage=Prospecting and Amount=101000, Strategic Deal=false, Discount=5. Keep Opportunity_Primary_Contact disabled.
2. Enable Opportunity_Minimum, set Numeric Value=120000, Rule Version=`demo-min-120k-v1`.
3. On O01 change only Stage to Closed Won and save. Expect `DEMO_RULE Opportunity_Minimum`; refresh and confirm Stage is still Prospecting. A toast alone is insufficient evidence.
4. Change Numeric Value to 100000 and version to `demo-min-100k-v1` in Setup.
5. Retry the same Stage change. Expect success at the same Amount=101000. A stage-only save must not create a new strategic evaluation.
6. Restore O01 to Prospecting. Set Enabled=false, Numeric Value=100000 and Rule Version=`baseline-off-v1`.

Tell the agent whether 120000 is an approved new requirement or an intentionally injected defect. In a defect demonstration, expected behavior stays at the approved baseline; the agent must not simply read the incorrect runtime setting and adopt it as its test oracle. Detection does not authorize automatic repair.

## 4. Strategic discount configuration is separate

Open Custom Metadata Types > **Strategic Discount Rule** > Manage Records > **Default**. Baseline: Active=true, Minimum Amount USD=50000000, Discount Threshold Percent=15, Rule Version=`baseline-15`.

The approval predicate uses strict `>` for amount and discount; the optional Closed Won minimum uses inclusive `>=`. Do not confuse 100000 and 50000000 or their purposes. The legacy field API name Minimum_Amount_INR__c stores USD; no FX conversion occurs.

POLICY-08 demonstrates 15→20 using a strategic USD 60m, 18% discount deal. A new save under 20 yields Not Required. Existing deals retain their stored policy until a genuine policy-input change occurs. **Save and Evaluate is not a force-recompute button**; an unchanged save or stage-only change does not refresh stale strategic evidence. There is no bulk re-evaluation control. Do not covertly toggle an input or overwrite the result to hide stale state.

Inactive strategic configuration means Configuration Error, not approval bypass. By contrast, disabling an optional Demo Business Rule removes that extra restriction. Native approval routing/identity checks always remain in place.

## 5. Case resolution and access

The new field is **Case.Demo_Resolution__c**, label **Demo Resolution**. It is added next to Description on the existing `Case-Case Layout`. Open the Case Details > Edit to fill it, then close the Case. Some Close Case quick actions do not show every field; save the resolution in Details first. Do not overwrite Description, which contains the fixture marker.

`Demo_Rule_Operator` grants only read/edit on this field. The current administrator needs that assignment if field access is absent; it does not grant Case CRUD, API Enabled, metadata administration or new VP access. Do not assign it to the VP to make a negative test pass. Other Case page layouts/dynamic forms may need an explicitly reviewed field placement; this deployment does not replace all layouts or profile assignments.

The source Case layout preserves the retrieved demo layout, including pre-existing sample-field references. Its summary label is sanitized rather than publishing a runtime ID. A fresh org lacking those sample fields must adapt that layout before deployment; the deployment manifest is scoped to the bound demo org.

## 6. Save errors, boundaries and recovery

- `DEMO_RULE <key>` means a business restriction rejected the action. Compare to the approved test expectation; expected rejection is a passing negative test.
- `DEMO_CONFIG` means missing/invalid configuration or inability to verify required context. Fix only under authorized operator scope. Enabled rules require a version; enabled minimum must be non-negative; Lead required status must be nonblank and should be an exact valid status API value.
- Standard permission/sharing/locking errors are not necessarily rule failures. The primary-contact and campaign queries are user-mode; related data access is required. Never grant administrator rights to bypass a failed test.
- Closed Won, Closed and Completed are exact status API values used by this demo. Additional/custom values are not automatically covered.
- Primary-contact validation happens when saving an Opportunity, not on a later Contact Role deletion/edit. Create a deal as open, add its roles, then close it. This is not a continuously enforced count invariant.
- Lead qualification inspects the saved pre-conversion status. Save qualification first, then convert. A rejected conversion rolls back; a successful conversion consumes that Lead. Never retry blindly after timeout.
- Task due-date rule checks presence, not whether overdue. Case resolution checks nonblank text, not semantic adequacy. Campaign rule validates member Status changes, not membership creation or outbound messages.

Restore settings before data cleanup if the restriction would block cleanup. Disable all eight guards, restore their baseline versions/parameters, then restore touched fixture fields. Retain policy and native approval history. The multi-module loader is create-only; re-running it does not undo edits or unconvert Leads. New `SYN-RULE-...-{run}` records belong to a protected local run ledger and are not automatically deleted/reset.

## 7. Implementation and maintenance

`DemoBusinessRules` is a with-sharing service called by seven thin object triggers. Six run before applicable inserts/updates; the Lead guard uses after-update addError to roll back native conversion. The service performs no DML and bulk-loads related context. There is no new custom REST API, external-agent credential or permission expansion across CRM modules.

Use `manifest/milestone-6-demo-rules.xml` only on the verified non-production org. Its eight Custom Metadata records contain the OFF baseline, so redeploying the manifest will restore those configuration values; never redeploy during an intentional changed-rule demo. UI edits do not change Git. For an approved permanent change, retrieve/reconcile source, update requirements and independent tests, then regenerate both manual and knowledge artifacts.

Historical milestone reports are unchanged. Current verification is recorded separately in [milestone 6 evidence](../evidence/milestone-6-verification.md). Full browser execution and a future API/UI automation harness remain separate acceptance gates.
