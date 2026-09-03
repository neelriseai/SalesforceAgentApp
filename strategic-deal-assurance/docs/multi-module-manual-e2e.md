# Cross-module demo: 10 manual end-to-end use cases

Milestone 6 prerequisite: restore all eight **Demo Business Rule** switches to OFF before these baseline cases. The current [complete manual suite](manual-test-cases.md) includes these ten cases plus strategic-policy, configurable-rule, approval, security and restoration cases. Read the [test plan](test-plan.md) and [configuration guide](demo-rules-guide.md); this original guide remains the detailed baseline workflow reference.

This pack adds native CRM scenarios and a linked synthetic dataset to the existing strategic-deal app. It does not add ten custom automation engines. Case escalation, campaign response changes and pipeline progression are manual native workflows unless explicitly stated otherwise. The separately developed assurance agent can use these objectives and expected results as test inputs.

## Start here

- Sign in with your original demo administrator for MM-01–08 and MM-10. MM-09 also needs the separate Synthetic Regional VP login. No new licensed users were created.
- Open App Launcher > Strategic Deal Assurance. The navigation includes Accounts, Contacts, Opportunities, Leads, Cases, Tasks and Campaigns (some tabs may be under the overflow menu).
- Switch Recently Viewed to an all-records list. Records loaded through the CLI may not be Recently Viewed. Search the exact `SYN-MM-` fixture name. Where a list has a different name, select an equivalent unfiltered list.
- The original administrator is a practical business-operator stand-in, not evidence of least-privilege access for every module. VP permissions stay restricted; do not grant more access simply to make a negative test pass.
- If Contact Roles or Related are absent on the custom Opportunity page, open the same record through the standard Sales app. Do not switch to another similarly named record.
- Keep all input synthetic. No email, SMS, external system calls, password sharing, user deactivation or deletion is part of these tests.
- Suggested order: MM-10, MM-01, MM-02, MM-04, MM-05, MM-06, MM-07, MM-08, MM-09, then MM-03 LAST. Finish each cleanup before the next case.
- Run the read-only dataset Verify command before testing. A loader receipt is not proof that these browser workflows passed. Record actual results in `multi-module-test-results.md`.

## Dataset

| Module / relationship | New records |
|---|---:|
| Accounts (4 groups + 20 customers) | 24 |
| Contacts (3 per customer) | 60 |
| Opportunities (2 per customer) | 40 |
| Leads | 30 |
| Cases | 30 |
| Tasks | 60 |
| Campaigns | 4 |
| Campaign members | 40 |
| Opportunity contact roles (2 per deal) | 80 |
| **Business records** | **368** |
| Flow-created policy evaluations at initial load | 40 |

Names use `SYN-MM-` plus A=Account, C=Contact, O=Opportunity, L=Lead, S=Support Case, T=Task, M=Campaign. Contact/Lead full names start with Synthetic. Emails use reserved `example.invalid` addresses. Close dates are 2026-12-31 and task due dates 2026-12-15, not rolling dates. Review these dates before future-year demos.

The forty initial deals include 24 Not Required, 8 Pending Regional VP and 8 Configuration Error outcomes. Pending eligibility does NOT create a native approval request. The original seven `SYN-SDA-` deals, earlier UI fixture and already-approved original request are outside this dataset.

## Case index

| ID | Use case | Main modules |
|---|---|---|
| MM-01 | Account hierarchy and subsidiary reassignment | Account |
| MM-02 | Contact reassignment between customer accounts | Contact, Account, Case |
| MM-03 | Lead qualification and conversion into a customer deal | Lead, Account, Contact, Opportunity |
| MM-04 | Opportunity pipeline progression without policy-input changes | Opportunity, Account |
| MM-05 | Buying-team contact roles and primary contact | Opportunity, Contact, OpportunityContactRole |
| MM-06 | Customer support case triage and closure | Case, Account, Contact |
| MM-07 | Case follow-up task and activity completion | Task, Case, Contact |
| MM-08 | Campaign member response tracking | Campaign, CampaignMember, Contact, Lead |
| MM-09 | User separation, assigned approval and rejection | User, Opportunity, ApprovalProcess |
| MM-10 | Customer 360 relationship reconciliation | Account, Contact, Opportunity, Case, Task, CampaignMember |

## MM-01 — Account hierarchy and subsidiary reassignment

Objective: Verify that changing a subsidiary's parent updates the account hierarchy without moving its contacts or deals.

Login: Original demo administrator (business-operator stand-in).

Fixtures: `SYN-MM-A06 Customer`, `SYN-MM-A02 Group`, `SYN-MM-A01 Group`.

Starting state: A06 belongs to A02; A01 and A02 each have five seeded children. A06 has contacts C04–C06 and deals O03–O04.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | Open Accounts, choose All Accounts, search SYN-MM-A06 and open the Customer record. | Account Name is SYN-MM-A06 Customer; Parent Account is SYN-MM-A02 Group. |
| 2 | Use the account's View Account Hierarchy action (often in the action dropdown). | A06 is shown under A02. |
| 3 | Edit A06. Change only Parent Account to SYN-MM-A01 Group and save. | A06 saves under A01; no new Account is created. |
| 4 | Reopen the hierarchy and A06's Related tab. | A01 now has six seeded children and A02 four. A06 still has contacts C04–C06 and deals O03–O04. |
| 5 | Reload the record and inspect Parent Account again. | The changed parent persists; the account retains its original name and marker. |

Negative/safety check: Do not select a non-SYN account as parent. Moving a parent is not an instruction to move contact/account lookups.

Cleanup/repeat: Restore A06 Parent Account to SYN-MM-A02 Group; confirm five seeded children under each group.

Capture: Before/after hierarchy and the unchanged contact/deal lists.

## MM-02 — Contact reassignment between customer accounts

Objective: Verify contact-to-account reassignment and detect that an existing case's Account is not automatically rewritten.

Login: Original demo administrator.

Fixtures: `Synthetic SYN-MM-C04`, `SYN-MM-A06 Customer`, `SYN-MM-A07 Customer`, `SYN-MM-S04 Support`.

Starting state: C04 belongs to A06. S04 links C04 and A06. A06 and A07 each have three seeded contacts.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | Open Contacts, use an all-records list and search SYN-MM-C04. | The record is Synthetic SYN-MM-C04; Account is A06; the email ends in example.invalid. |
| 2 | Edit the Contact's Account Name to SYN-MM-A07 Customer; leave Name and Description unchanged; save. | C04 now links A07. |
| 3 | Open A06 and A07 > Related > Contacts. | A06 has two seeded contacts; A07 has four. C04 appears under A07. |
| 4 | Open SYN-MM-S04 Support and inspect Contact Name and Account Name. | Contact remains C04; Case Account remains A06. Native contact reassignment does not promise a case-account cascade. |
| 5 | Reload C04 and then restore its Account to A06. | C04 returns to A06 and both accounts again have three seeded contacts. |

Negative/safety check: If the business wants automatic case-account alignment, that is a new rule to design—not behavior to assume from this fixture.

Cleanup/repeat: Restore C04 to A06. Do not modify S04's customer relationship during this test.

Capture: Contact and both account lists before/after; S04's unchanged relationships.

## MM-03 — Lead qualification and conversion into a customer deal

Objective: Verify native lead conversion links an existing customer to a new contact and a new synthetic Opportunity.

Login: Original demo administrator.

Fixtures: `Synthetic SYN-MM-L30`, `SYN-MM-A24 Customer`.

Starting state: Run this test LAST. L30 is unconverted and is not one of the seeded campaign members. Conversion is a one-way business operation in the normal UI.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | Open Leads, choose All Open Leads or an equivalent all-records list, and find SYN-MM-L30. | Lead is Synthetic SYN-MM-L30; Company is SYN-MM-L30 Prospect; Status is Open - Not Contacted. |
| 2 | Edit Status to Working - Contacted and save. | The qualification state persists; the record is still a Lead. |
| 3 | Use Convert. Select existing Account SYN-MM-A24 Customer, choose to create a new Contact, and create a new Opportunity named SYN-MM-L30 Converted Deal. | The conversion form identifies only the synthetic customer and new synthetic records. Disable optional notification-email choices if shown. |
| 4 | Confirm Convert and open the resulting Account, Contact and Opportunity links. | Exactly one new Contact and one new Opportunity are linked to A24; no additional Account was requested. |
| 5 | Inspect the converted Lead or conversion confirmation and the new Opportunity. | Lead is converted. The Opportunity is named SYN-MM-L30 Converted Deal; its Account is A24. With no qualifying strategic inputs entered, policy status is Not Required. |
| 6 | Search the ordinary open-lead list for L30, then inspect A24's Related lists. | L30 no longer appears as an open Lead. A24 has the new Contact and Opportunity in addition to its original fixtures. |

Negative/safety check: Do not convert twice or reuse a similarly named real prospect. If duplicate detection appears, review the exact synthetic matches instead of bypassing it blindly.

Cleanup/repeat: No automatic unconvert or deletion. Record the conversion as consumed; use unconverted L29, then L28, on later runs with corresponding unique Opportunity names. Verify reports Lead status drift intentionally.

Capture: Conversion confirmation plus the three linked records; capture only synthetic record details.

## MM-04 — Opportunity pipeline progression without policy-input changes

Objective: Verify sales-stage changes persist while the strategic policy and evaluation count stay unchanged when policy inputs did not change.

Login: Original demo administrator.

Fixtures: `SYN-MM-O01 Deal`, `SYN-MM-A05 Customer`.

Starting state: O01: Prospecting, USD 101,000, 5% discount, strategic=false, policy Not Required, one initial evaluation.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | Open Opportunities in Strategic Deal Assurance; use All Opportunities and search SYN-MM-O01. | The workbench shows the expected input values and Not Required. |
| 2 | Record the existing evaluation-history count and newest timestamp. Change only Stage to Qualification; click Save and Evaluate. | Stage becomes Qualification; policy remains Not Required; no new policy evaluation is created. |
| 3 | Change only Stage to Closed Won and save. | Stage is Closed Won. Amount stays USD 101,000 and policy stays Not Required. |
| 4 | Reload the Opportunity and inspect its Account's related Opportunities. | The same deal appears as Closed Won under A05; no duplicate Opportunity was created. |
| 5 | Compare evaluation history with the first step. | The count and newest evaluation timestamp are unchanged. A stage-only change is not a strategic-input change. |

Negative/safety check: Do not change Amount, Discount, Strategic Deal or Regional VP Approver in this test: those are policy inputs and would create evaluation evidence.

Cleanup/repeat: Restore Stage to Prospecting, leaving the other values unchanged.

Capture: Before/after stage, amount, policy status and evaluation history.

## MM-05 — Buying-team contact roles and primary contact

Objective: Verify a deal can retain multiple buying-team contacts while changing its primary contact and role.

Login: Original demo administrator.

Fixtures: `SYN-MM-O03 Deal`, `Synthetic SYN-MM-C04`, `Synthetic SYN-MM-C05`.

Starting state: O03 belongs to A06; C04 is the primary Decision Maker and C05 is the non-primary Technical Buyer.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | Open O03 and find Related > Contact Roles. If the app's custom record page has no Related tab, open the same Opportunity in the standard Sales app. | There are two roles: C04 Decision Maker (primary), C05 Technical Buyer. |
| 2 | Use Edit Contact Roles or the related-list edit action. Make C05 the primary contact and change its role to Economic Buyer. | After saving, C05 is primary and its role is Economic Buyer. |
| 3 | Reload the Contact Roles list and count the primary flags. | Exactly two contacts remain linked and exactly one is primary; C04 is no longer primary. |
| 4 | Open C04 and C05 and inspect their Account links. | Both still belong to A06. Changing deal roles does not reparent the Contacts. |
| 5 | Inspect O03's strategic policy/history. | No policy-input changes were made, so the policy result and evaluation count remain unchanged. |

Negative/safety check: Do not add a duplicate role for the same Opportunity/Contact pair. If the UI cannot edit roles, report access/layout behavior rather than change global security.

Cleanup/repeat: Restore C04 as primary Decision Maker and C05 as non-primary Technical Buyer.

Capture: Both contact roles, the single primary flag and unchanged Contact accounts.

## MM-06 — Customer support case triage and closure

Objective: Verify manual case triage, priority changes and resolution while preserving the customer/contact links.

Login: Original demo administrator (service-operator stand-in).

Fixtures: `SYN-MM-S01 Support`, `SYN-MM-A05 Customer`, `Synthetic SYN-MM-C01`.

Starting state: S01: New, Medium, Origin Web, Account A05, Contact C01. No custom SLA or automatic escalation rule is part of this scenario.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | Open Cases; choose All Cases and find Subject SYN-MM-S01 Support. | Status New, Priority Medium, Account A05 and Contact C01 are visible. |
| 2 | Edit Status to Working and Priority to High, then save. | The case persists as Working/High; account and contact remain unchanged. |
| 3 | Open the Account and Contact from the Case and inspect their related cases. | The same S01 is associated with the intended synthetic customer/contact. |
| 4 | Return to the Case and set Status to Closed (or use Close Case). Leave any optional email-notification checkbox off. | Case is closed; the record is retained and relationships are unchanged. |
| 5 | Reload the record; compare open versus all-case lists. | It no longer qualifies for an open-case list but remains available in All Cases. |

Negative/safety check: Escalation here is manual status/priority management, not a timed SLA, email-to-case integration or real customer notification.

Cleanup/repeat: Reopen by restoring Status New and Priority Medium. Keep the Description marker and links unchanged.

Capture: Working/High and Closed states, case number/subject, and linked Account/Contact.

## MM-07 — Case follow-up task and activity completion

Objective: Verify an assigned follow-up task is linked to both the correct case and person and moves to completed activity.

Login: Original demo administrator.

Fixtures: `SYN-MM-T41 Follow Up`, `SYN-MM-S01 Support`, `Synthetic SYN-MM-C01`.

Starting state: T41: Not Started, Normal priority, due 2026-12-15, Assigned To current operator, Related To S01, Name C01.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | Open Tasks, use an all-tasks list, and search SYN-MM-T41 Follow Up. | Confirm the expected assignee, due date, Related To case and Name contact. |
| 2 | Open the Related To case and check its activity timeline; return to the Task. | The task is associated with S01, not another support case. |
| 3 | Change Task Status to In Progress and save. | Status persists; the due date and relationships do not change. |
| 4 | Mark the task Complete or edit Status to Completed. | Task is Completed and is shown among past/completed activities. |
| 5 | Open S01 and C01 and inspect available activity timelines, expanding completed activity if needed. | The completed follow-up still refers to the same case/contact; it was not deleted. |

Negative/safety check: Do not use Send Email or assign the task to a real unrelated user. Completing a task does not automatically close its Case.

Cleanup/repeat: Restore Task Status Not Started. Retain the original due date, owner and relationships.

Capture: Task relationship fields plus the completed activity state.

## MM-08 — Campaign member response tracking

Objective: Verify changing one member's response updates campaign response tracking without duplicating members or sending a message.

Login: Original demo administrator with the user-approved Marketing User setting.

Fixtures: `SYN-MM-M01 Outreach`, `Synthetic SYN-MM-C01`, `SYN-MM-M03 Outreach`.

Starting state: Four Campaigns exist, with ten members each. M01/M02 have Contacts; M03/M04 have Leads. All forty members initially have Status Sent.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | Open Campaigns, choose All Campaigns and open SYN-MM-M01 Outreach. | Campaign is active and Planned; its Campaign Members list contains ten Contacts. |
| 2 | Find Synthetic SYN-MM-C01 in Campaign Members and open Edit for that member. | The membership status is Sent. This is a status label, not evidence an email was sent. |
| 3 | Change only the member Status to Responded and save. | The same member is now Responded; member count remains ten. |
| 4 | Refresh campaign statistics and the Campaign Members list. | One member is responded (initially none); membership count did not increase. |
| 5 | Open C01 and check Campaign History, then inspect M03's member list. | C01 remains linked to M01. M03 contains ten Lead members, demonstrating both supported person types. |

Negative/safety check: Do not click Send List Email or any campaign-send action. This use case does not send marketing communications.

Cleanup/repeat: Restore C01's M01 membership Status to Sent; response count returns to its prior value.

Capture: Member before/after status and unchanged total membership count.

## MM-09 — User separation, assigned approval and rejection

Objective: Verify the owner submits a deal, the separate VP can decide it but cannot edit its inputs, and rejection preserves native history.

Login: Two sessions: original demo owner/administrator and Synthetic Regional VP.

Fixtures: `SYN-MM-O02 Deal`, `Synthetic Regional VP`.

Starting state: O02: USD 60m, 20% discount, strategic=true, VP lookup set, Pending Regional VP policy eligibility, no native request initially. The VP uses the activated account and separate browser session.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | As owner, open O02 and confirm the input values and VP lookup. Click Submit for Approval in Regional VP Approval. | Latest native request becomes Pending. The owner is offered Recall, not the app's Approve/Reject. |
| 2 | In the separate VP session, open the same Opportunity and refresh the approval panel. | The assigned VP sees Approve and Reject. |
| 3 | Inspect the deal-input area as VP. Do not attempt to work around its permissions. | The VP cannot save input changes. Save and Evaluate may still be visible because the current workbench does not hide it by role; failed saving must not change the record. |
| 4 | As VP, click Reject. | Native request and Opportunity approval status become Rejected. The final decision is recorded and the ordinary-user approval lock is released. |
| 5 | As owner, refresh the page and try to locate a valid Submit action without changing inputs. | The app does not offer an unchanged rejected record for resubmission. History shows rejection. |
| 6 | As owner, change Discount to 21 and Save and Evaluate; submit the newly eligible deal; then Recall Approval as the owner. | A fresh evaluation yields Pending Regional VP; a second native request can be submitted and recalled. Its native status becomes Removed and policy status returns to Pending Regional VP. |

Negative/safety check: Never demonstrate owner/approver separation using an administrator override. This demo owner is an admin, so ordinary-owner edit locking is established by the separate Apex security tests, not this owner's UI session.

Cleanup/repeat: Ensure there is no pending request. Restore Discount to 20 via Save and Evaluate. Native history and extra evaluation rows remain intentionally; do not delete them.

Capture: Separate-session action availability, rejection, second-request recall and final eligibility. No passwords or activation links.

## MM-10 — Customer 360 relationship reconciliation

Objective: Trace a customer's sales, service, buying-team and follow-up records and verify counts/relationships across modules.

Login: Original demo administrator.

Fixtures: `SYN-MM-A05 Customer`, `SYN-MM-A01 Group`, `Synthetic SYN-MM-C01 through C03`, `SYN-MM-O01 Deal`, `SYN-MM-O02 Deal`, `SYN-MM-S01 through S03`.

Starting state: Run before mutations or after their documented cleanup. These are native related lists, not a newly built Customer 360 dashboard.

| Step | Manual action | Expected result |
|---|---|---|
| 1 | Open A05 and inspect Details and Related lists. | Parent is A01; there are three seeded Contacts (C01–C03), two Opportunities (O01–O02) and three Cases (S01–S03). |
| 2 | Open both Opportunities and verify Account, Amount, and Contact Roles. | Both belong to A05. Amounts are USD 101,000 and USD 60,000,000, totaling USD 60,101,000. Each has C01 and C02 as its two buying-team contacts. |
| 3 | Open each of the three Cases and follow its Contact link. | S01→C01, S02→C02, S03→C03; all three Cases also point to A05. |
| 4 | Find tasks T01–T03, T21–T22 and T41–T43 in Tasks and inspect their relationship fields. | Eight seeded tasks connect to this customer: three directly to A05, two to its deals and three to its cases. These may not all aggregate into one Account timeline. |
| 5 | Inspect C01–C03's Campaign History or M01's Campaign Members list. | All three are members of M01. No duplicate Contact record is required to link sales, service and marketing. |
| 6 | Record the counts and compare every link with the expected graph. | All joins resolve to the same synthetic customer. A similarly named unrelated record is a failure, even if aggregate counts happen to match. |

Negative/safety check: Do not treat record-name resemblance as proof of a relationship. Open the lookup links; do not assume account-level automatic activity or campaign rollups.

Cleanup/repeat: Read-only test; no cleanup needed. Restore earlier scenario mutations before claiming a pristine baseline.

Capture: Related-list counts, lookup links and the USD 60,101,000 two-deal total.

## Pass/fail and repeatability

A case passes only when every expected result is observed using the stated actor and real Salesforce records. Mark missing permissions, missing UI controls or blocked login as Blocked with the exact symptom; do not substitute API success for a browser pass. An unexpected business outcome is Failed. Record timestamp, step, actual outcome and a sanitized screenshot/reference. Never include passwords, activation links or session tokens.

The loader is create-only, not a destructive reset. `Verify` compares starting fields/relationships and policy outputs; deliberate manual changes appear as drift. `Apply` does not erase these changes. Follow per-case cleanup for reversible edits. Lead conversion is intentionally not auto-reversed, and approval/evaluation histories accumulate. See `multi-module-data.md` for commands and limitations.
