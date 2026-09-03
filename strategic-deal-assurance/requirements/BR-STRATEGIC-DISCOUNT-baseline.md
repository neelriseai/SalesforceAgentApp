# BR-STRATEGIC-DISCOUNT — baseline-15

Regional VP approval is required only when a strategic Opportunity has Amount > USD 50,000,000 AND Discount > 15 percent. The user chose to keep the demo in USD on 2026-09-04. The numeric threshold is unchanged; no foreign-exchange conversion is performed. The org's default currency was verified as USD before Flow activation. Multi-currency conversion is out of scope.

Amount_INR__c and Minimum_Amount_INR__c remain legacy API identifiers from milestone 1 to avoid a destructive schema migration. Their user-facing labels and business meaning now use USD. No full baseline tag existed before this correction.

| Obligation | Input | Expected |
|---|---|---|
| OBL-AMOUNT-EXACT | Strategic, 50,000,000, 20%, approver present | Not Required |
| OBL-DISCOUNT-EXACT | Strategic, 50,000,000.01, 15%, approver present | Not Required |
| OBL-DISCOUNT-ABOVE | Strategic, 50,000,000.01, 15.01%, approver present | Pending Regional VP |
| OBL-MISSING-APPROVER | Both boundaries exceeded, approver absent/blank | Configuration Error; approvalRequired=true |
| OBL-NON-STRATEGIC | Non-strategic, 60,000,000, 20% | Not Required |
| OBL-NULL-INPUT | Null amount/discount/strategic flag/input | Not Required with valid config |
| OBL-INVALID-CONFIG | Missing/inactive config, invalid thresholds or blank rule version | Configuration Error; configurationValid=false |
| OBL-BULK | 200 mixed input records | Ordered one-to-one output; no DML/SOQL |
| OBL-HASH | Equivalent decimal scale, different present approver IDs | Same non-identifying input hash |

Tests use explicit independent oracles. A future 10% requirement is not part of this baseline.
OBL-PERMISSION-BYPASS and OBL-FLOW-IDEMPOTENT are verified by milestone-2 Apex integration tests executing the real record-triggered Flow. External API/UI permission tests and parent-aware evaluation-history reads remain later milestones.
