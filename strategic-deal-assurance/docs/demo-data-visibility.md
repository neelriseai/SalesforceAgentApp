# Find the demo data, extra records and reports

The original data was present even when the administrator saw empty/single-record screens: read-only counts showed 30 SYN-MM Cases, 60 Tasks and four Campaigns. The org also had 30 platform sample reports, but none were the dedicated reports below. The precise browser filter was not observed; Recently Viewed, Today, active-only and date filters can produce a smaller view than the actual data population. Adding records does not automatically populate Recently Viewed.

## Where to look as administrator

1. Open App Launcher > **Strategic Deal Assurance**.
2. Choose Cases, Tasks or Campaigns; tabs can be under the navigation overflow menu.
3. Click the list-name dropdown (for example Recently Viewed or Today's Tasks), then select **SDA Demo Cases**, **SDA Demo Tasks** or **SDA Demo Campaigns**.
4. Clear any text search or extra filters. Refresh. Pin the selected list using the pin icon if available, so subsequent visits use it. Pinning is a user preference; the deployment does not force it.
5. These named views include accessible SYN-MM records without a date, status or recent-visit restriction. They do not grant additional record access. Use the original administrator, not the restricted VP, for cross-module demos.
6. For reports, choose **Reports > All Folders > SDA Demo Reports**. Alternatively, search All Reports for **SDA Demo**. Open a report and click **Run**; do not remain on Recently Viewed or expect the report list itself to display business rows.

## Added population

| Object | Original SYN-MM | Added | Combined SYN-MM |
|---|---:|---:|---:|
| Accounts | 24 | 10 | 34 |
| Contacts | 60 | 20 | 80 |
| Opportunities | 40 | 0 | 40 |
| Leads | 30 | 0 | 30 |
| Cases | 30 | 30 | 60 |
| Tasks | 60 | 60 | 120 |
| Campaigns | 4 | 6 | 10 |
| Campaign members | 40 | 60 | 100 |
| Opportunity Contact Roles | 80 | 0 | 80 |
| **Business records** | **368** | **186** | **554** |

The original 40 policy evaluations and separate SYN-SDA fixtures are unchanged. New records use keys XA (Accounts), XC (Contacts), XS (Cases), XT (Tasks), XM (Campaigns). Distinct synthetic companies include Aurora Analytics and Birch Manufacturing. Extra records are linked to separate new Accounts/Contacts, so the original MM-10 customer counts and all original fixture identities stay intact.

The extra Cases are ten New, ten Working and ten Closed; the extra Tasks are twenty Not Started, twenty In Progress and twenty Completed. There are four active and two inactive new Campaigns, each with ten Contact members and three Responded members. Sent/Responded are status labels; no marketing email is sent. Closed cases contain a synthetic resolution narrative.

Task dates are fixed around **2026-09-04**, plus original tasks due 2026-12-15. Today/Overdue views change with time and the user's timezone; the SDA Demo Tasks view is date-independent. The expansion loader does not roll dates forward automatically.

## Saved reports

| Report | Initial expected rows | Grouping |
|---|---:|---|
| SDA Demo Cases | 60 | Status |
| SDA Demo Tasks | 120 | Status |
| SDA Demo Campaigns | 10 | Campaign Status |
| SDA Demo Opportunities | 40 | Stage |
| SDA Demo Accounts | 34 | Account Type |

Reports filter names/subjects beginning SYN-MM-. Task reporting uses Activities with Contacts because every seeded Task has a Contact link; it is not a universal all-activities report. Task parameters include open and completed tasks, excluding Events. Campaign reporting uses the platform's **All campaigns** scope, including inactive records. Other reports use all accessible organization records. Date-filterable reports use 2020-01-01 through 2035-12-31; CampaignList has no time-frame filter. Missing dates or data outside that range require an explicitly reviewed report change.

The native Opportunity probability parameter `>0` is Salesforce's API value for the label **All**, as confirmed through report-type describe; it is not a custom probability predicate added by this project. Grouped fields appear as group headings rather than duplicate detail columns. Expand groups or enable details to see individual rows.

The folder is Shared, with no added broad data permissions or VP privileges. Administrator access is verified separately from future ordinary-user/report-folder sharing. If another persona needs these reports, design its folder and object access explicitly; do not grant admin access.

## Supplemental manual verification cases

These are additional visibility checks alongside the [42-case suite](manual-test-cases.md), not replacements for its behavioral tests. Capture actor, source version, filter values, actual counts and cleanup status. Browser checks remain NOT_RUN until executed in the browser; server report runs are a different evidence type.

### VIS-01 — Find all demo records

1. As administrator open Cases, select SDA Demo Cases and clear search. Expect 60 scoped records before further manual changes; pages may show only the first subset, so check total/count or paginate.
2. Find `SYN-MM-XS01 Access issue`; confirm New/High and an XA customer plus XC contact. Do not edit it.
3. Open Tasks, select SDA Demo Tasks. Expect 120 total: 80 Not Started, 20 In Progress, 20 Completed at initial load.
4. Find `SYN-MM-XT01 Customer follow up`; confirm it links XS01 and that case's Contact. Also verify a Completed XT task remains visible.
5. Open Campaigns, select SDA Demo Campaigns. Expect ten campaigns, including inactive XM05/XM06. An Active-only view would show only eight.
6. Refresh each view to prove the results persist; optionally pin the view. Cleanup: none; no record writes are required.

### VIS-02 — Run and reconcile saved reports

1. Open Reports > All Folders > SDA Demo Reports. Expect five reports with the names above, not five business records.
2. Open SDA Demo Cases and Run. Expect 60 rows grouped 20 New / 20 Working / 10 Escalated / 10 Closed. Compare with the Cases view using the same prefix.
3. Run SDA Demo Tasks. Expect 120 rows grouped 80 Not Started / 20 In Progress / 20 Completed. Confirm fixed-date tasks are not lost to Today/This Week filters.
4. Run SDA Demo Campaigns. Expect ten rows, including two inactive records; expansion members total 60 and responses total 18 across six campaigns.
5. Run SDA Demo Opportunities and Accounts. Expect 40 and 34 rows respectively. Original customer/deal relationships must be unchanged.
6. Record any discrepancy before changing filters; report row counts can legitimately change after authorized manual conversions/inserts. Cleanup: discard unsaved report edits; never save a narrowed test filter over the baseline report without authorization.

### VIS-03 — Create-only repeatability and original-fixture isolation

1. As operator run expansion Verify below. Expect 186 existing rows, baselineMatches=true and zero committedRows after a pristine load.
2. Run the original multi-module Verify. Expect 368 original rows, 40 matching policy results and no unexplained drift.
3. Re-run expansion Apply only with explicit write authorization. When complete data exists, expect zero inserts and zero updates; this does not reset edited records.
4. Inspect original SYN-MM-A05 Customer and compare MM-10 relationships: original three Contacts, two Opportunities, three Cases remain unchanged because expansion uses XA customers.
5. Cleanup: none. Do not delete or recreate records merely to make a verifier pass. Investigate renamed, missing, duplicate or manually changed fixtures.

## Operator commands and safety

```powershell
powershell -NoProfile -File scripts/demo/seed-visibility-expansion.ps1 -Mode Preview
powershell -NoProfile -File scripts/demo/seed-visibility-expansion.ps1 -Mode Rehearse -ConfirmDataInsert
powershell -NoProfile -File scripts/demo/seed-visibility-expansion.ps1 -Mode Apply -ConfirmDataInsert
powershell -NoProfile -File scripts/demo/seed-visibility-expansion.ps1 -Mode Verify
npm run visibility:test
```

Only the bound Developer Edition caip-dev and administrator are allowed. The runner reuses the existing bulk user-mode CrossModuleFixtures helper, disables DML email options and holds the same local mutex. Eight optional guards must be OFF; it never changes them automatically. It is create-only, refuses partial datasets/collisions/deleted fixtures, and never overwrites existing records or converts Leads. Rehearse inserts, verifies and rolls back in one transaction. Unknown write outcome requires Verify before retry.

Plan: `data/visibility-expansion-plan.json`. Receipts: ignored `artifacts/visibility-expansion/<run>/result.json`. New views/reports: scoped `manifest/milestone-7-demo-visibility.xml`, which does not redeploy rule defaults, application code or existing reports. A failed metadata deployment does not undo a separately committed data load; verify each lane independently.
