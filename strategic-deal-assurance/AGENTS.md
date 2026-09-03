# Strategic Deal Assurance

## Scope

Build a deterministic Salesforce system-under-test for a separately developed assurance agent.
Risk, repair approval, RCA, and release decisions stay outside Salesforce.

## Rules

- Use DX format in force-app/main/default and API 67.0 from sfdx-project.json.
- Use only the explicitly verified non-production org alias caip-dev.
- The numeric source of truth is Strategic_Discount_Rule.Default custom metadata.
- Approval requires strategic=true, amount strictly greater than USD 50,000,000, and discount strictly greater than the configured threshold (15 baseline). User explicitly chose USD on 2026-09-04; no FX conversion.
- Amount_INR__c and Minimum_Amount_INR__c are legacy API names only; labels and stored amounts use USD. Do not delete/rename deployed fields without separate approval.
- Missing approver when approval is required produces Configuration Error.
- Explicit with sharing; bulk-safe Apex; no queries/DML in loops. Specify user-mode access for future data operations.
- Synthetic data only. No credentials, tokens, session URLs, private keys, org identifiers, or real people in tracked files.
- No destructive deployments or data deletion without scoped approval.
- Evaluation evidence is intended to be append-only for normal users; implement writer/sharing before claiming that end-to-end guarantee.
- Do not grant public evaluation access or broad administrative permissions.
- Future Flow must log every relevant input change, including when the decision stays unchanged; outcome-only re-entry logs nothing.
- Preserve the 15% baseline until the explicit change-demo milestone.
- Independently asserted test expectations must not be derived from the custom metadata under test.

## Verification

- Deploy only the requested milestone manifest, with named tests and explicit test level.
- Run Apex tests with coverage after deployment; do not substitute local parsing for org execution.
- Keep generated raw outputs ignored. Commit only sanitized reports with explicit omissions.
- Do not mark the full app complete before Flow, security, LWC, API/UI tests, and reset evidence exist.
