# Milestone 5: cross-module scenarios and bulk synthetic data

Verified 2026-09-04 (Asia/Calcutta) in the explicitly authorized Developer Edition alias caip-dev. This report intentionally omits org/user/record/job identifiers, private email addresses, credentials and raw logs.

## Delivered scope

- Ten additional native CRM manual use cases, 53 action/expected-result steps, explicit objectives, actors, fixtures, negative checks, cleanup and evidence instructions.
- Machine-readable scenario catalog plus a manual result sheet initially marked Not run.
- 368 linked business records: 24 Accounts, 60 Contacts, 40 Opportunities, 30 Leads, 30 Cases, 60 Tasks, 4 Campaigns, 40 Campaign Members and 80 Opportunity Contact Roles.
- 40 policy evaluations created by the existing Flow at initial Opportunity insertion; not directly inserted by the loader. All forty independently expected policy outcomes matched: 24 Not Required, 8 Pending Regional VP, 8 Configuration Error.
- Create-only loader, read-only verification, rollback-only first-load rehearsal and local validation tests. Original SYN-SDA fixtures and the previously approved original request were not edited.

## Preflight and authorized changes

Object describe verified required fields and active picklist values for all nine target object/relationship types. No Apex triggers were returned. The only active record-triggered Flow was Strategic_Discount_Approval on Opportunity; managed action/capability flows were not invoked. Retrieved Case Workflow contained a field-update definition but no active workflow rule. Existing Opportunity Workflow was left unchanged.

Campaign create access was initially unavailable because Marketing User was off for the current administrator. The user explicitly authorized enabling that setting. The scoped operator-only script enabled it; subsequent user-mode Campaign insertion succeeded. No extra users/licenses were created, and the VP's permission set was not changed.

The existing app was retrieved for comparison before extending its navigation. Scoped manifest milestone-5-navigation.xml deployed one CustomApplication successfully, with 32 named Apex test methods and zero errors. It adds Contacts, Leads, Cases, Tasks and Campaigns while preserving the Opportunity record-page override. No custom object, Flow, trigger, approval rule, global layout assignment or external API was deployed.

## Execution evidence

| Check | Observed result |
|---|---|
| Preview | No existing new-dataset fixtures or collisions; zero writes |
| Rehearse | 368 rows inserted, all fields/relationships and 40 policy outcomes verified, entire transaction rolled back; zero committed rows |
| Initial Apply | Started with zero fixtures, committed 368 business rows; 40 evaluations; baselineMatches=true; no drift |
| Repeat Apply | Found all 368 rows; inserted/committed zero; evaluation count remained 40; baselineMatches=true |
| Separate Verify | All nine object counts, planned fields/links and forty policy outcomes match; zero drift |
| Post-deployment Apex regression | 35/35 results passed including setup; 99% test-run coverage |
| Local dataset tests | 368 rows, unique keys/references, reserved emails, no derived output assignments, independent 24/8/8 policy oracle, buying-team/customer relationships, case/contact links, ten complete scenario definitions and two write guards passed |
| Original reset local tests | Seven original fixtures and write guards still pass |

Ignored per-run artifacts contain sanitized receipts with plan/runner hashes. The initial uncompressed preview exceeded anonymous Apex's source-size limit and performed no writes. The final runner transports the same readable checked-in plan in a ZIP envelope using native Apex Compression and enforces a conservative source-size bound. The final code passed the subsequent rehearsal, Apply and verification checks.

## Browser smoke and limitations

In the existing administrator browser session, refreshed the original deal and observed policy status Approved and latest native request Approved. Expanded app navigation showed Accounts, Contacts, Leads, Cases, Tasks, Campaigns and Reports. Used All Accounts and searched the new synthetic prefix; opened SYN-MM-A05 Customer. Its native page rendered View Account Hierarchy, Related/Details, Contacts/Opportunities/Cases sections and linked synthetic follow-up activities. This is a navigation/render smoke check, not a pass for all ten workflows.

The manual suite is prepared but NOT executed end to end. Native lead conversion, each documented business edit and the new rejection/recall browser scenario must be recorded during a real walkthrough. The source data and native APIs being valid does not establish all browser behavior or layout availability. The guide includes standard Sales-app fallback for Contact Roles because the custom Opportunity page focuses on policy and approval.

No new custom campaign-send integration, timed case escalation/SLA, user-provisioning workflow, automated Customer 360 dashboard or external agent endpoint is claimed. Most scenarios use the existing administrator as the business-operator stand-in; only approval uses the separately provisioned restricted VP. Additional least-privilege sales/service/marketing personas remain a separate design decision.

Lead conversion consumes a fixture and is not automatically reversed. Final approval states and extra relationship rows may intentionally cause Verify drift. The create-only loader never resets these changes, deletes history or overwrites existing records. Full automated external API/UI coverage and tagged release readiness remain outside this milestone. No commit, push, tag, destructive deployment or data deletion was performed.
