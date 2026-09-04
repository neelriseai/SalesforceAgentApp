# Milestone 7 — more synthetic data, named views and saved reports

Date: 2026-09-04 Asia/Calcutta (2026-09-03 UTC tool receipts). Scope: fingerprint-bound caip-dev Developer Edition, existing demo administrator. Runtime identifiers and raw authenticated responses are not published.

## Initial read-only findings

- Original data was present: 30 SYN-MM Cases, 60 Tasks and four Campaigns.
- The administrator confirmed the viewing persona. The active browser filter was not observed, so an exact UI root cause is not claimed. Recently Viewed/Today/active-only/date filters are possible explanations.
- Thirty existing reports were platform sample/enablement reports, not this app's dedicated demo reports. Existing reports and filters were not changed.

## Data expansion

The create-only plan adds 186 business records: 10 Accounts, 20 Contacts, 30 Cases, 60 Tasks, six Campaigns and 60 CampaignMembers. Expansion relationships use independent XA/XC Accounts/Contacts to preserve the original 368-row dataset and its Customer 360 assertions.

The first rollback rehearsal encountered native duplicate detection on overly similar synthetic names. No bypass flag or duplicate-rule change was used. Distinct synthetic company/contact names resolved the collision. The next rehearsal inserted and verified all 186 rows, then rolled back with zero committed rows.

Apply then committed exactly 186 rows. Subsequent Verify reported baselineMatches=true, zero drift and zero new writes. No existing records were updated or deleted, no Lead converted, and no approval submitted/recalled. Email options were disabled; campaign response labels did not send messages. No users/licenses/permissions were added.

A repeat Apply confirmed idempotency: 186 existing rows, zero inserted/committed rows and no drift. The original multi-module Verify independently confirmed all 368 original rows, 40 matching policy results, 40 evaluation rows and no drift.

## Metadata and runtime reporting

`manifest/milestone-7-demo-visibility.xml` deployed three ListViews, one dedicated report folder and five reports. Final deployment succeeded with zero component/test errors and the five named Apex suites. It does not redeploy code, rule values or pre-existing report definitions.

Earlier failed metadata attempts rolled back. Corrections used report-type describe evidence: grouped fields removed from duplicate detail columns, CampaignList's unsupported time-frame filter removed, Campaign scope set to orgAll (All campaigns), Opportunity probability parameter set to >0 (the platform's All label), Task list filter field set to SUBJECT.

All five reports were executed via Salesforce Analytics REST as the operator, each with HTTP 200 and allData=true:

| Report | Verified RowCount |
|---|---:|
| SDA Demo Accounts | 34 |
| SDA Demo Campaigns | 10 |
| SDA Demo Cases | 60 |
| SDA Demo Opportunities | 40 |
| SDA Demo Tasks | 120 |

REST describe confirmed the three named list-view queries filter only the intended SYN-MM name/subject prefix, with no date/status restriction. These are runtime API checks, not browser screenshots or proof that the user has selected/pinned that view.

## Local checks and boundaries

- Separate post-deployment Apex run: 51/51 passed, zero failing, testRunCoverage 100% for that named-suite run.

- Visibility plan tests: 3/3 passed (186 unique keys, no baseline collisions, relationship alignment, varied statuses, five scoped reports and three unbounded-date views).
- Catalog tests: 7/7 passed, including source links, secret-pattern checks and updated fixture/report/view graph. Graph now includes 554 fixture nodes across both datasets.
- Original 42 behavioral cases remain unchanged; three supplemental VIS manual cases are documented. Their browser steps are NOT_RUN until actually executed.
- Combined counts are initial baseline expectations, not immutable totals after future authorized edits/conversions. Task dates are fixed, not automatically rolling.
- Report folder visibility and underlying CRUD/FLS/sharing remain separate. No VP or external-agent privileges were expanded.
- A dedicated external OAuth lane and repeatable browser automation remain outside this milestone.
