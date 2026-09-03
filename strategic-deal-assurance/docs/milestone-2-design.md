# Milestone 2 — Flow and permission sets

## User currency decision

The user requested all USD on 2026-09-04 after the org default currency was verified as USD. Threshold remains numerically 50,000,000; discount comparison remains strictly above 15%. There is no FX conversion or org currency change. Existing API fields Amount_INR__c and Minimum_Amount_INR__c are legacy identifiers; labels and policy explanations are USD. The milestone-1 report is historical and its source fingerprints intentionally remain unchanged.

## Flow

Strategic_Discount_Approval is an after-save Opportunity Flow on create/update. Start admits only a new record or changes in Amount, Discount__c, Strategic_Deal__c, or Regional_VP_Approver__c.

1. Invoke StrategicDiscountPolicy (no repeated numeric thresholds in Flow).
2. Update status/reason/version/evaluated time, in the same transaction.
3. Create one evaluation snapshot with the Flow interview GUID, normalized input hash, version, time and approver presence only.

Every relevant update creates evidence, including unchanged outcomes. Output-only updates fail the Start condition; unrelated edits do not reset Approved/Rejected states. No static Boolean recursion guard is used, so bulk records are not skipped.

All three fallible elements have a fault connector to a Custom Error element, which fails the transaction with a sanitized message. No partial success is silently accepted. Deliberately inducing every platform-fault branch is a separate remaining test gate; the current Apex suite verifies normal real Flow DML, not injected Flow failures.

Record-triggered Flow runs in system context to write fields the initiating user cannot edit. This is narrowly bounded to four derived Opportunity fields and one evaluation record. It grants no privileges or direct evidence-object access to the caller. There are no UI/API endpoints in this milestone.

## Permission sets

| Set | Opportunity | Outcome fields | Direct evidence | API Enabled |
|---|---|---|---|---|
| Strategic_Deal_User | Read/Create/Edit, inputs editable | Read only | None | Not granted |
| Regional_VP_Approver | Read-only review | Read only | None | Not granted |
| Change_Assurance_Integration | Read/Create/Edit, inputs editable | Read only | None | Granted |
| Strategic_Deal_UI_Runner | Read/Create/Edit, inputs editable | Read only | None | Not granted |

No Delete, View All, Modify All, setup administration or approval authority. Application/controller/REST class access is deferred until those components exist. Permission sets are additive: these definitions do not revoke grants from a user's profile or other sets. Apex security tests use Minimum Access - Salesforce plus only Strategic_Deal_User, never an administrator to prove denial.

The evaluation object remains Private. Its Opportunity lookup does not inherit parent sharing. Granting direct read would allow an evidence owner to retain access after losing parent access, so normal users receive no direct evidence CRUD yet. A future reader must explicitly authorize the parent Opportunity in user mode before providing a narrow history DTO. Do not claim parent-aware history access or immutable admin-level evidence in this milestone.

No real-user permission assignments are made automatically. Test-created users and their assignments roll back with Apex tests. Choose actual sales/API/UI identities before assigning these sets for a demo.

## Tests and remaining scope

StrategicDiscountFlowTest uses Opportunity DML to execute the deployed Flow. It is explicitly an Apex integration substitute, not a native FlowTest result. Covers exact/above amount and discount boundaries, missing approver, null discount, unchanged-outcome evidence, unrelated/output-only re-entry, all trigger input categories, 200-record create, sales-user FLS denials and the four-set grant matrix.

Native Flow tests, forced fault injection, Code Analyzer, parent-checked history reader, runtime correlation from an external API request, durable-resume idempotency, LWC/app/pages and native approval remain separate gates. Flow interview GUID is a transaction correlation token, not an external idempotency key.

Use manifest/milestone-2.xml for this slice. No destructive changes. Use scripts/test-milestone-2.ps1 to repeat both Apex suites after deployment.
