# BR-DEMO-CONFIGURABLE-RULES

User-approved milestone: eight optional, manually configurable CRM save restrictions, with detailed manual and future-automation tests. These are application behavior, not merely test expectations. The separate assurance agent must keep approved requirements independent of runtime configuration.

## Required behavior

| Key | Condition when Enabled=true | Pass condition / effect |
|---|---|---|
| Account_Reparent | Update changes ParentId | Reject, including assigning/clearing a parent; unchanged parent allowed |
| Contact_Reparent | Update changes AccountId | Reject, including assigning/clearing an Account; unchanged Account allowed |
| Lead_Qualification | Native conversion changes IsConverted false to true | Previously persisted Status equals Required_Value__c |
| Opportunity_Minimum | Insert/update with StageName exactly Closed Won | Amount non-null and >= Number_Value__c, in USD |
| Opportunity_Primary_Contact | Insert/update with StageName exactly Closed Won | At least one existing, user-readable OpportunityContactRole has IsPrimary=true |
| Case_Resolution | Insert/update with Status exactly Closed | Demo_Resolution__c nonblank after whitespace check |
| Task_Due_Date | Insert/update with Status exactly Completed | ActivityDate non-null; past dates allowed |
| Campaign_Active | Update changes CampaignMember.Status | Parent Campaign IsActive=true |

Scope: Account.Name, Contact.LastName, Lead.LastName, Opportunity.Name, Case.Subject and Task.Subject beginning `SYN-MM-` or `SYN-RULE-`. An update is in scope if either old or new value matches. Campaign scope uses current Campaign.Name. Prefixes target a dedicated demo, not immutable security labels. A separately saved rename can remove future scope; do not treat this as production enforcement.

All eight Enabled defaults are false, Rule Version `baseline-off-v1`. Opportunity minimum default 100000 USD; Lead required status `Working - Contacted`. Other numeric/text slots are unused. Instructions are documentation, not executable expressions. Renaming a record API name does not create a new supported rule.

Missing configuration, or an enabled rule with blank version, fails closed at the relevant guarded action. Enabled minimum must be non-null/non-negative; enabled Lead required status must be nonblank. An unknown nonblank Lead status will never match; operators must verify current picklist API values. A disabled rule does not validate unused parameters.

## Boundaries

- Existing strategic policy remains strictly strategic AND Amount > 50000000 USD AND Discount > 15. It is separate from the inclusive Closed Won minimum. No duplicate strategic threshold is introduced.
- No replacement of native approval routing, self-approval prohibition, permissions or locking. Customer 360 is reconciliation across relationships, not a ninth save rule.
- Save guards use addError and perform no DML, no cascading repair, no emails and no scheduled processing. Lead failure rolls back the native conversion transaction; allowed conversion is not automatically reversible.
- Related primary-contact and campaign checks use WITH USER_MODE in a with-sharing service. Missing related-record access must not be resolved by granting admin permissions; report an access/configuration failure.
- Rules run on browser/API DML reaching these triggers; API permissions are not newly provisioned. No custom REST endpoint or rule-write endpoint is added.
- No enforcement on deleting/unmarking a primary Contact Role after closing a deal; next Opportunity save checks again. No enforcement on campaign-member insertion, campaign deactivation, or User administration. This is the approved action-specific demo scope, not a universal data invariant.
- Exact status API values are intentionally scoped to this demo. Additional won/closed/completed statuses or new rule predicates require reviewed implementation changes.
- Changing metadata affects the next relevant save, not historical records, policy evidence or pending approval requests. No mass re-evaluation or auto-reset.
- Existing seven SYN-SDA fixtures are outside these new guards. Existing SYN-MM workflow expectations assume the new guards disabled.

## Acceptance evidence

Named Apex tests exercise defaults, enabled/disabled outcomes, atomic rejection, strict/inclusive boundaries, native Lead conversion rollback, composed rules, 200-record bulk and partial saves, scope and unchanged strategic history. Manual specifications do not prove browser execution. Use the complete manual suite and explicit run ledger; preserve partial failures and cleanup evidence.
