# Milestone 3 — native Lightning workbench

The Strategic Deal Assurance Lightning app contains Deal Workbench, Opportunities, Accounts and Reports. Its Opportunity record-page override is app-specific. The new Opportunity layout is available but not assigned globally or to profiles, preserving existing layouts.

## UI contract

strategicDealWorkbench uses Lightning Data Service record-edit-form, restricted to eight input fields. Names must start with SYN- in this UI; this is a demo safeguard, not server-wide synthetic-data enforcement. Derived outcomes never appear as inputs. Save failures are sanitized, duplicate submits are blocked while busy, and successful saves refresh the policy card. Existing records can be edited from their app-specific record page.

strategicDealPolicyCard displays status, explanation, applied/active policy versions, USD thresholds and the latest five evaluations. It provides loading, empty, error, inactive-rule and version-mismatch states plus manual refresh. Stable hooks include save-evaluate-v1, approval-status, policy-threshold, applied-rule-version and evaluation-history. Accessible labels/status regions accompany hooks; no full accessibility audit is claimed.

## Read boundary and permissions

StrategicDealPolicyController is with sharing. A WITH USER_MODE Opportunity query checks parent record access and every returned parent field, including Amount and Discount. Only after that succeeds does a private without-sharing helper query at most five evidence rows in system mode. The DTO excludes record/user identifiers, input hashes and raw errors. This deliberate narrow read elevation is necessary because the private lookup-based evidence object does not inherit parent sharing. The helper is not a client endpoint, performs no writes, and cannot bypass the public method's parent gate.

All four permission sets gain the app, tab, controller, Account read-only access, and Opportunity.AccountId access (editable only for writer personas). No direct evidence CRUD, Delete, View All, Modify All or approval authority is added. API Enabled remains granted only by the integration set. The user approved assigning Strategic_Deal_User to the currently authorized demo identity. Permissions are additive: this does not remove pre-existing administrator rights. Security denial tests use Minimum Access - Salesforce users, not the demo administrator.

The historical milestone-2 permission matrix and reports remain unchanged. Permission-set description text from milestone 2 still calls the reader deferred; the deployed controller/class access and this milestone's contract supersede that stale description.

## Verification and remaining gates

Use manifest/milestone-3.xml, the three named Apex suites in scripts/test-milestone-3.ps1, npm run test:unit -- -- --runInBand and npm run lint. Jest exercises component behavior with mocked Salesforce services; it is not browser E2E proof. The current Jest coverage invocation does not instrument component files, so no JavaScript coverage percentage is claimed.

Full release readiness still requires the external assurance/API contract, repeatable UI/API harness, seed/reset workflow, native approval if retained in scope, fault injection, native Flow tests and Salesforce Code Analyzer. Policy baseline remains strictly Amount > USD 50,000,000 and Discount > 15%, with strategic=true. No currency setting, policy threshold, REST endpoint, native approval, commits or baseline tags are changed here.
