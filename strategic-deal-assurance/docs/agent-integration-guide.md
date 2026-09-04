# Agent integration guide

This is the current handoff contract for an external agent interacting with **Strategic Deal Assurance**. It describes implemented behavior, supported platform options and unresolved integration work separately. It is not authorization to change an org. The versioned [interface contract](../contracts/agent-interface.json) is the machine-readable companion.

## 1. Read and ingest in this order

1. `AGENTS.md` at repository and project roots: operator constraints.
2. `contracts/agent-interface.json`: capabilities, role boundaries, fields and safety gates.
3. This guide and [project index](project-index.md): runtime and source entry points.
4. `knowledge/application-graph.json`: metadata dependencies, lifecycle, permissions, logical fixture relationships and test mappings.
5. `knowledge/project-index.json`: repository-relative file paths and LF-normalized SHA-256 source fingerprints.
6. `data/manual-test-suite.json`, [complete manual suite](manual-test-cases.md), [test plan](test-plan.md) and [rule configuration guide](demo-rules-guide.md): 42 cases / 232 steps, exact fixtures, cleanup and future automation contract. The original ten-case file remains the native-workflow source.
7. Relevant `force-app/main/default` source and `requirements/BR-STRATEGIC-DISCOUNT-baseline.md`: implementation and policy authority.

The graph is a static source snapshot, not a live org export, entitlement engine or complete Apex call graph. Source-derived and curated relationship edges have provenance. Check `npm run catalog:check` after checkout. When source changes, regenerate with `npm run catalog:build`. Do not infer a live deployment solely from files or hashes.

Historical evidence is deliberately preserved. In particular, `evidence/metadata/permission-matrix.json` is a milestone-2 snapshot; its deferred-reader/assignment/approval notes are NOT the current security contract. Some permission-set descriptions also retain old prose. Effective grants come from XML plus the current user's profile, assignments, sharing and runtime describe checks.

## 2. Environment and authentication

| Lane | Available now | What the external agent must do |
|---|---|---|
| Operator CLI | Locally authorized alias `caip-dev` | Use only on the authorized operator's machine; verify the target org. Never export its auth file/token to another service. |
| Owner browser | Existing demo administrator | Interactive login/MFA; acts as the sales/service/marketing stand-in. Do not treat admin capabilities as normal-user security evidence. |
| VP browser | Separate Synthetic Regional VP | Interactive login/MFA; Minimum Access profile + Regional_VP_Approver. Keep sessions distinct. |
| Dedicated agent API | Not provisioned by this repository | Use an explicitly approved Salesforce OAuth client and a suitable least-privilege user. Configure account/client approval before writes. |
| Separate multi-module personas | Not provisioned | Additional sales/service/marketing/API permissions require a scoped design; the existing integration set is not all-module access. |

Project API version is **67.0**. The current org is a dedicated Developer Edition, with USD, but its hostnames/IDs are intentionally not published. Obtain the REST `instance_url` from the approved OAuth response and the Lightning base URL from the target org. Do not construct one by guessing the other. Sample local configuration is [.env.example](../.env.example); the supplied CLI runners do not read it automatically.

Store client secrets, private keys and refresh tokens in your agent service's secret manager/OS credential store. Inject access tokens only at runtime into the HTTP Authorization header. Never put them in Git, logs, URL query strings, screenshots or prompts. A logged-in browser session is sufficient for browser operations, not for an unrelated backend's REST authentication. Do not scrape browser cookies or replay internal Aura requests as an API.

No new plugin is required for local Salesforce CLI work. Your separately built agent can use its Salesforce SDK, an approved connector or ordinary HTTPS REST client. Library choice does not supply authentication, permissions or record sharing. The CLI and browser are separate trust lanes.

## 3. Startup checklist and runtime discovery

1. Start read-only. Verify environment identity against your locally approved org binding; refuse production or an unexpected org.
2. Identify the actual authenticated user and lane. Verify expected profile/permission assignments without logging private user details.
3. Obtain available API versions and perform sObject describe for each object needed by the task. Inspect object createable/updateable and field createable/updateable, required fields, active picklists and record-type choices. Object describe alone does not establish access to a specific record.
4. Resolve the exact synthetic record by a stable stored ID from the current environment or its scoped name/marker. Zero matches means absent; multiple matches means STOP and reconcile. Never select the first fuzzy name match.
5. Read the central policy and current record state. Treat missing/inactive configuration or stale version as an explicit failure, not permission to change policy.
6. Confirm the requested action is authorized for this task/persona. Read-only analysis does not authorize edits, approval decisions, lead conversion, deletion, permission changes or metadata repair.
7. After a write, read back the exact record. On timeout, inspect its current state before retrying; Salesforce may have committed despite a lost response.

No universally unique external ID or idempotency endpoint was implemented. Names/markers and local runner mutexes reduce mistakes but do not provide distributed exactly-once behavior. Keep an operation ledger in your agent if it needs reliable retries.

## 4. Object and relationship map

| Object | Useful fields / relationships | Demo role |
|---|---|---|
| Account | `Name`, `AccountNumber`, `ParentId`, `OwnerId`, `Type`, `Industry` | Parent/customer hierarchy |
| Contact | `FirstName`, `LastName`, `AccountId`, `Email`, `Title`, `OwnerId` | Customer people |
| Lead | `LastName`, `Company`, `Status`, `IsConverted`, conversion links | Qualification/conversion; normal conversion is not auto-reversible |
| Opportunity | `AccountId`, `OwnerId`, `Name`, `StageName`, `CloseDate`, `Amount`, custom policy fields below | Sales/policy/approval |
| OpportunityContactRole | `OpportunityId`, `ContactId`, `Role`, `IsPrimary` | Two buying-team members per seeded deal |
| Case | `Subject`, `CaseNumber`, `AccountId`, `ContactId`, `Status`, `Priority`, `Origin`, `OwnerId` | Manual service workflow, not a custom SLA engine |
| Task | `Subject`, `WhoId`, `WhatId`, `Status`, `Priority`, `ActivityDate`, `OwnerId` | Contact plus account/deal/case follow-up |
| Campaign | `Name`, `Status`, `Type`, `IsActive`, dates | Native campaign tracking; creation needs Marketing User capability |
| CampaignMember | `CampaignId`, `ContactId` OR `LeadId`, `Status` | Ten members per seeded campaign; Sent is a label, not proof of an email |
| User | `Id`, `IsActive`; exact approved identity | Owner/assigned approver; do not create/deactivate/change users automatically |
| Strategic_Discount_Rule__mdt | `Default` record and four policy fields | Central configuration |
| Strategic_Deal_Evaluation__c | Required `Opportunity__c` lookup and input/result snapshot | Private policy evidence; no ordinary direct CRUD |
| ProcessInstance / Workitem / Step | Target record, state, actor, native history | Human approval, separate from policy evidence |

Use runtime describe for precise child relationship names and optional fields. `Task.WhatId`/`WhoId` and native process targets are polymorphic; the graph records the types used in these fixtures, not every type Salesforce supports.

## 5. Opportunity field contract and policy

The workbench's eight-field input allowlist is `Name`, `AccountId`, `StageName`, `CloseDate`, `Amount`, `Strategic_Deal__c`, `Discount__c`, `Regional_VP_Approver__c`. Keep names prefixed `SYN-`; use percentage points (`15` = 15%, **not** `0.15`), USD numeric amounts and ISO dates `YYYY-MM-DD` in APIs.

Do NOT assign `Approval_Status__c`, `Approval_Reason__c`, `Policy_Rule_Version__c`, or `Policy_Evaluated_At__c` directly. Salesforce Flow/native approval own those values. Do not directly create/update/delete evaluation evidence.

The current predicate is strict: strategic=true **AND Amount > 50,000,000 AND Discount > 15**. The thresholds/version come from `Strategic_Discount_Rule__mdt.Default`: `Active__c`, `Minimum_Amount_INR__c`, `Discount_Threshold_Percent__c`, `Rule_Version__c`. Despite two legacy INR API names, both `Minimum_Amount_INR__c` and evaluation `Amount_INR__c` mean USD here; no FX conversion occurs.

| Inputs / condition | Expected policy status |
|---|---|
| Any boundary not exceeded, or strategic=false | Not Required |
| Exactly USD 50,000,000 or exactly 15% | Not Required |
| All conditions met; approver present | Pending Regional VP |
| All conditions met; approver absent | Configuration Error |
| Missing/inactive/invalid central configuration | Configuration Error |

Create or change any of `Amount`, `Discount__c`, `Strategic_Deal__c`, `Regional_VP_Approver__c`: after-save Flow evaluates once, updates derived values and appends one evaluation. Changes only to Name/Stage/CloseDate or outputs do not add policy evaluations. The synchronous transaction fails atomically on Flow faults.

Policy evaluation only checks that an approver identifier is present. Native submission additionally requires active, separate owner/approver identities and synthetic name. A lookup labelled Regional VP is not organizational-title attestation.

After human approval/rejection, changing a relevant input can reset eligibility and require a new approval. An unchanged save does not force re-evaluation after metadata-only policy drift. Do not secretly toggle a field to manufacture evidence; surface the stale version and seek the approved maintenance workflow.

## 5a. Configurable cross-module save guards

The [approved rule requirement](../requirements/BR-DEMO-CONFIGURABLE-RULES.md) defines eight optional restrictions read from `Demo_Business_Rule__mdt`. All source defaults are OFF, version `baseline-off-v1`. Metadata administration stays with the approved operator; there is no new custom rule-write API or agent admin grant.

Rules cover Account parent changes, Contact Account changes, saved Lead qualification before native conversion, Closed Won minimum amount (inclusive >= 100000 USD baseline), Closed Won primary Contact Role, Closed Case resolution, Completed Task due date and member response updates on inactive Campaigns. This minimum is separate from the strict USD 50m / 15% strategic-approval predicate.

New field `Case.Demo_Resolution__c` is writable only with appropriate field and Case permissions. `Demo_Rule_Operator` grants that field, not Case CRUD, metadata administration or API access. Original integration permission sets do not gain these CRM privileges.

`DemoBusinessRules` and seven triggers enforce the optional rules on native saves. Six are before triggers; Lead uses after-update addError to roll back conversion. Related primary-role/campaign reads are WITH USER_MODE. Only names/last names/subjects beginning SYN-MM- or SYN-RULE- are targeted (old or new name on direct updates; current Campaign name for membership). Editable prefixes are not immutable security labels.

`DEMO_RULE <key>` denotes a business rejection; `DEMO_CONFIG` denotes configuration/context failure. Verify persisted state after both success and failure; no evaluation/approval field may be directly patched to override a rejection. Metadata edits affect the next relevant save; they do not refresh existing strategic outcomes or auto-run all tests.

Exact guarded status API values are Closed Won, Closed and Completed. Lead requires a separately saved pre-conversion Status matching the configured Required Value. Primary-role enforcement runs on Opportunity save, not later role deletion. Campaign enforcement runs on member Status updates, not inserts. Customer 360 remains read-only reconciliation. No new User-management, SLA or outbound messaging engine exists.

Ingest `data/manual-test-suite.json` as the test specification, not an execution receipt. Approved expected behavior must be independent from runtime settings: a deliberate incorrect threshold must not become the agent's expected answer. Every configuration change/repair needs explicit task scope. Ordinary sObject REST cannot update Custom Metadata; do not replay Aura to work around that.

## 6. Browser interaction contract

**Responsibility split:** Salesforce only changes presentation; it does not heal XPath. The current scenario is assisted by explicit DOM field-identity hints. A recorded executable baseline locator suite, external-agent integration and advanced no-explicit-hint mode remain future work. Capture actual before/after target validity and verify all eight saved inputs before claiming nine-target healing. The [demo status](locator-healing-demo.md#implementation-status-and-showcase-boundary) is authoritative about these implementation limits.

The table below describes the **baseline** presentation. The [locator-healing demo](locator-healing-demo.md) adds per-page `locatorVariant` configuration (`baseline`, `reordered`, `regrouped`) in App Builder. Changed variants deliberately alter eight field hooks/order/regions and the save label/hook. Ingest [LH-01–06](../data/locator-healing-suite.json); correlate current metadata and fresh scoped DOM using `data-object-api`, `data-field-api` and `data-action`, not stale labels or positions. Business semantics/permissions remain unchanged; a missing editable field for VP is not a healing opportunity. Do not infer browser execution or healer implementation from this specification.

Open App Launcher > **Strategic Deal Assurance**. Use an all-records list instead of Recently Viewed for CLI-seeded data. New data uses `SYN-MM-`; the original policy fixtures use `SYN-SDA-`. Resolve the intended record once and retain its environment-specific ID locally.

| Component / region | Stable semantics | Expected behavior |
|---|---|---|
| Deal inputs | Field labels Name, Account Name, Stage, Close Date, Amount, Strategic Deal, Discount, Regional VP Approver | Authorized owner/editor changes inputs |
| Workbench save | Button **Save and Evaluate**; source test hook `data-testid="save-evaluate-v1"` | LDS save; wait for success or error and refreshed policy |
| Policy card | **Strategic Deal Policy**, **Refresh policy**, Approval Status, rule versions, Evaluation History | Latest five parent-authorized summaries |
| Approval panel | **Regional VP Approval**, **Refresh approval**, Latest request | Current native request; latest ten history steps for that request |
| Role-dependent actions | **Submit for Approval**, **Approve**, **Reject**, **Recall Approval** | Server checks actor/state again; a hidden button is not the security control |

Scope locators to the component/region and verify uniqueness. Prefer fresh accessible roles/names or the explicit custom test hook. Generated Lightning IDs/classes and positional XPath are unstable. `data-testid` lives on a custom/base component boundary; inspect actual browser/shadow DOM rather than assuming every driver sees it identically. Do not bypass security controls to reach hidden buttons.

The VP can read and decide assigned requests but cannot edit deal inputs. **Save and Evaluate is currently still visible for that account**; do not interpret visibility as edit permission. A clear role-specific read-only presentation is a remaining UI improvement. LightningExperienceUser was explicitly added to the VP permission set; stale sessions may need sign-out/sign-in.

The app-specific Opportunity page focuses on policy and approval and may not expose native Related/Contact Roles lists. Use the same record in the standard Sales app for those manual tests. On narrow screens, module tabs are in Show more navigation items. See the manual guide for exact case steps and cleanup.

### Named views and saved reports

When Recently Viewed or Today looks empty, select **SDA Demo Cases**, **SDA Demo Tasks** or **SDA Demo Campaigns** from the list dropdown. They filter SYN-MM names/subjects and have no date/status restriction. Five reports live in **SDA Demo Reports**; open and Run rather than treating the Reports list as business data. See [visibility guide](demo-data-visibility.md) for report filters and three supplemental manual checks.

A separate 186-record expansion gives combined SYN-MM totals of 60 Cases, 120 Tasks, 10 Campaigns, 34 Accounts and 80 Contacts. It uses independent XA/XC customers/people, preserving original scenario relationships. Runtime report results remain subject to record/field/folder permissions. Existing integration/VP permissions are not expanded by these views or reports.

## 7. Native approval lifecycle

1. Save/evaluate as owner. `Pending Regional VP` is eligibility, not a submitted request.
2. Owner clicks Submit for Approval. The internal controller rechecks current policy and applied version, then calls the named native process with criteria enabled.
3. Salesforce creates the native request/work item and locks against ordinary edits. AdminOnly editability retains native administrator overrides outside the custom app.
4. Only the assigned actor, distinct from the submitter, can Approve/Reject through the app. Approved/Rejected sets the Opportunity's status and unlocks it without appending policy evidence.
5. The submitter can Recall. Native request becomes `Removed`; Opportunity eligibility returns to `Pending Regional VP`, and the record unlocks.
6. An unchanged rejected deal cannot resubmit through the app. A relevant edit causes a new evaluation; submit again only when eligible. Preserve previous native and policy history.

Never confuse `Opportunity.Approval_Status__c`, a ProcessInstance status and a ProcessInstanceStep status. The latest-request DTO is not a full historical archive. Its `locked` flag reflects this process's pending state, not a general-purpose query of every possible lock. The optional org-wide Apex lock/unlock preference remains unchanged.

## 8. Standard REST recipes and limits

These are **platform request shapes**, not proof that a dedicated agent API lane was configured or E2E-tested. Authenticate first, perform describe/access checks, URL-encode SOQL, and use the OAuth-provided `instance_url`. Send `Authorization: Bearer <runtime token>` and JSON content type; never record that header in logs. Follow `nextRecordsUrl` for pagination after checking it belongs to the same authorized instance.

Read record metadata and an exact fixture:

```text
GET {instance_url}/services/data/v67.0/sobjects/Opportunity/describe
GET {instance_url}/services/data/v67.0/query?q={URL-encoded SOQL}
```

```sql
SELECT Id, Name, AccountId, OwnerId, StageName, Amount, Discount__c,
       Strategic_Deal__c, Regional_VP_Approver__c, Approval_Status__c,
       Policy_Rule_Version__c, Policy_Evaluated_At__c
FROM Opportunity
WHERE Name = 'SYN-MM-O02 Deal'
  AND NextStep = 'SDA-CROSS-MODULE-v1|O02'
```

Require exactly one row before an edit. For an explicitly authorized policy-input change:

```text
PATCH {instance_url}/services/data/v67.0/sobjects/Opportunity/{resolved_id}
```

```json
{"Discount__c": 21}
```

Read back the stored inputs/outcome/version. An HTTP success alone does not assert the correct policy result. Never PATCH an outcome to force the test to pass. To create a new synthetic deal, use POST to the object collection, supply the eight allowed input fields required for your scenario, and resolve Account/approver IDs in the current environment. Do not overwrite the fixture plan's reserved markers or mix different personas' credentials.

For policy configuration, an authorized API identity can attempt a SOQL read of `Strategic_Discount_Rule__mdt` filtered by `DeveloperName = 'Default'`. If denied, report the missing capability; do not escalate to metadata administration. Ordinary agents must not change the threshold or rule version without separate authorization.

Native approval REST submission uses the **Opportunity ID** as context:

```text
POST {instance_url}/services/data/v67.0/process/approvals/
```

```json
{
  "requests": [{
    "actionType": "Submit",
    "contextId": "<resolved Opportunity ID>",
    "processDefinitionNameOrId": "Strategic_Opportunity_Regional_VP",
    "skipEntryCriteria": false
  }]
}
```

Approval/rejection uses the **pending work-item ID**, not the Opportunity ID:

```json
{"requests":[{"actionType":"Approve","contextId":"<assigned pending work-item ID>"}]}
```

Use the assigned approver's authorized API identity if one is separately provisioned. The existing VP permission set has **no API Enabled grant**, so the current approved VP lane is the browser. Do not add `contextActorId`, arbitrary `nextApproverIds`, or `skipEntryCriteria:true` to bypass routing/authorization. Native bulk requests can partially succeed; inspect every result and reconcile committed items before retrying. Recall through the existing Lightning panel is the documented tested path here.

Critical limitation: standard approval APIs do not execute `StrategicDealApprovalController`'s extra current-policy recomputation. Validate current metadata, inputs and applied version before native API submission and abstain on stale state. The native formula itself enforces stored eligibility, active separate approver and synthetic name; it is not a universal current-policy API interception layer.

`StrategicDealPolicyController.getPolicy`, `StrategicDealApprovalController.getState` and `.act` are `@AuraEnabled` methods, **not `/services/apexrest/...` endpoints**. Do not invent HTTP URLs for them. Direct `Strategic_Deal_Evaluation__c` SOQL access is withheld from normal/integration personas. Its UI DTO omits IDs/correlation/hash and limits history to five rows. If your agent requires full correlated history over REST, a separately approved narrow read API/security design is still needed.

## 9. Fixtures, verification and reset

| Dataset | Scope | Loader behavior |
|---|---|---|
| `SDA-DEMO-BASELINE-15-v1` | One Account + seven boundary Opportunities | `reset-baseline.ps1`: guarded restore; blocks pending native approvals; history retained |
| `SDA-CROSS-MODULE-v1` | 368 linked business records + 40 initial evaluations | `seed-multi-module.ps1`: create-only, no overwrites/deletes; Verify reports drift |
| `SDA-VISIBILITY-EXPANSION-v1` | 186 additional business rows with independent Accounts/Contacts | `seed-visibility-expansion.ps1`: create-only, original dataset untouched |

All three use locally bound `caip-dev`, synthetic markers and an administrative operator. They are operator tools, **not endpoints or permissions for an agent runtime**. Read [baseline reset](demo-data-reset.md) and [multi-module operations](multi-module-data.md) before executing them. Write switches are explicit. Never silently run a baseline reset after an approval or a failed test.

Dates are fixed in 2026, not rolling. Multi-module plan logical references such as `@A05` and `@vp` are not Salesforce IDs; resolve the matching current-environment records. Marker-only keys are not database-enforced uniqueness. Original `SYN-UI-` fixtures are outside both datasets.

Manual MM-03 lead conversion consumes a Lead and is not auto-reversed; approval history/evaluations intentionally accumulate. Most other scenarios provide field restoration steps. Keep the ten-case [result sheet](multi-module-test-results.md) honest: seeding or Apex success does not mark browser cases Passed.

## 10. Testing, impact analysis and evidence

```powershell
# Run from strategic-deal-assurance
npm run catalog:build
npm run catalog:check
npm run catalog:test
npm run test:unit -- -- --runInBand
npm run lint
powershell -NoProfile -File scripts/demo/test-reset-local.ps1
powershell -NoProfile -File scripts/demo/test-multi-module-local.ps1
# Requires the separately authorized demo org:
powershell -NoProfile -File scripts/test-milestone-6.ps1
```

Use graph paths to identify affected artifacts: requirement → policy/config → Flow/derived fields/evidence → controllers/UI/permissions → Apex/Jest/manual cases. Inspect the referenced source before recommending a repair; the graph is intentionally not exhaustive static analysis. Regenerate after any source edit.

For an external-agent run, record source snapshot/commit, environment fingerprint, actor role (not token), logical fixture key, operation, before/after values, expected vs actual, rule version, UTC times and evidence type (live API/live UI/unit/rollback rehearsal). Store real record IDs only in protected local run artifacts if needed for correlation. The policy input hash normalizes amount/discount to two decimals and approver presence, not identity; it is not an operation ID or proof two events are the same.

Separate failures: authentication/environment; CRUD/FLS/sharing; configuration/stale version; fixture drift/duplicate; policy defect; wrong assertion; UI locator/layout; pending approval lock. Do not label all denied writes as product failures or all API tests as browser evidence. On insufficient evidence, report Blocked/Incomplete rather than claim success.

Milestone-5 recorded 35/35 Apex results with 99% coverage; that remains historical. See [milestone-6 evidence](../evidence/milestone-6-verification.md) for current five-suite regression and optional-rule checks; component tests are mocks. The original two-login approval was user-completed and backend-verified. The unified 42-case manual suite is prepared, not a completed browser suite. Full external API/UI automation, Code Analyzer release gates, a clean tagged reset and dedicated agent OAuth remain outstanding.

## 11. Deployment and source maintenance

Do not deploy merely to inspect or connect. For an explicitly authorized rebuild into the verified non-production org, use scoped manifests in order: milestone-1, milestone-2, milestone-3, milestone-4, milestone-4-lightning-access, milestone-5-navigation, milestone-6-demo-rules, milestone-7-demo-visibility, each with its named tests and explicit test level. Review native Workflow/ApprovalProcess conflicts and licenses before deployment. Avoid the broad scaffold `manifest/package.xml`. Milestone 6 includes OFF Custom Metadata values and will restore those settings on deployment; do not redeploy mid-demo. Its Case layout references pre-existing Developer Edition sample fields; adapt explicitly for a different org.

Metadata in Git is the reproducible source; retrieved runtime authorization is not. User activation, permission assignment, Marketing User enablement and local org binding are environment setup actions that require appropriate authorization. The seed scripts do not silently grant missing permissions. A Git push neither deploys the org nor creates API credentials.

## 12. Official platform references

- [Object data through Salesforce platform APIs](https://developer.salesforce.com/blogs/2024/04/accessing-object-data-with-salesforce-platform-apis)
- [REST API guide, including approvals and partial request results](https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/api_rest.pdf)
- [Salesforce-maintained approval request collection](https://www.postman.com/salesforce-developers/salesforce-developers/request/jpgw88m/process-approvals-submit)
- [Secure user-mode Apex operations](https://developer.salesforce.com/blogs/2023/05/write-simplified-and-secure-apex-with-spring-23-updates)
- [Lightning Experience user access](https://help.salesforce.com/s/articleView?id=sf.lex_enable_intro.htm&language=en_US&type=5)

API options are platform capabilities, not additional implemented app endpoints. Use the target org's current API discovery and approved authentication configuration before execution.
