# Source-owned live operation declarations

[source-operations.json](../contracts/source-operations.json) is a closed versioned declaration,
referenced by [agent-interface.json](../contracts/agent-interface.json). Its locator is relative
to the local Git repository root, including the Salesforce DX subproject prefix. It contains
source facts, not credentials, record IDs, aliases or execution/deployment authority.

The exact seven-member Opportunity dataset comes from [baseline-15-plan.json](../data/baseline-15-plan.json)
and [the baseline reset template](../scripts/demo/reset-baseline.apex.template). Each marker is
the plan dataset plus its case key, stored in `NextStep`; the independently enrolled actor must
own every member (`OwnerId`). Names are displayed fields, never ownership evidence. All seven
members are read separately, including null amount and null discount boundaries. No subset is
silently substituted for the complete plan.

The standard GET projects explicit source fields, including identity, ownership and policy
outputs. Salesforce transport `attributes` are declared separately. The custom GET uses
[StrategicDealAgentApi](../force-app/main/default/classes/StrategicDealAgentApi.cls), declares the
complete nested success response, and permits at most 20 history entries for the declared
`limit=20` route. Each history item binds the requested authorized parent. Nullable source
fields remain nullable but required: absence is not the same as a present null.

Response schema **1.1.0 is a local candidate**, not a deployed/live-verified baseline. It adds
only `opportunity.id` and `history[].opportunityId`, both taken from the parent ID already
authorized with `WITH USER_MODE`. No caller, owner, approver or other user IDs are exposed by
the custom API. [Independent Apex tests](../force-app/main/default/classes/StrategicDealAgentApiTest.cls)
assert exact parent echoes, every history relationship, safe uniform missing/inaccessible
responses, and absence of unrelated parent/user IDs. These tests require a separately authorized
Salesforce execution; local Node source-contract checks are not Apex or live API pass evidence.

The browser declaration identifies the existing `strategicDealWorkbench` source node and its
record-page/application surface, limited to read-only locator-rebind preview. It does not grant
save, approval or metadata actions. The runtime must resolve exact current source/DOM context.

The closed `locatorRebind` contract selects the authorized `discount-exact` dataset member by
its `NextStep` marker, never by a committed record ID. It binds only `Strategic_Deal_Record_Page`,
component `c:strategicDealWorkbench`, instance `dealWorkbench`, property `locatorVariant`, and
the single alternate `reordered`. The exact `SET_SCALAR` declaration admits only ABSENT or
PRESENT with value `baseline`; the LWC default must also equal the declared `baseline` value.
The current source page has no property entry, so insertion is explicitly source-declared rather
than inferred from the default or supplied by a caller. Any other current value is blocked.
`PREIMAGE_EXACT` requires restoration of the exact observed
live metadata preimage, including property absence; it does not overwrite the page with a
hardcoded `baseline` value. Other pages, assignments and component instances are outside scope.

All nine sorted obligations are mandatory: AccountId, Amount, CloseDate, Discount__c, Name,
Regional_VP_Approver__c, StageName, Strategic_Deal__c and the `save-evaluate` action. Each records
its baseline `data-testid` identity and exact semantic object/field or action identity. Fields
require visible/enabled/editable checks; the save probe requires visible/enabled checks only.
`dataMutation: FORBIDDEN` means no fill, click, save, record creation or evaluation side effect.
This is a **FOUNDATION** source/compiler contract, not a live run or execution authorization.

Before live execution: verify the current local Git candidate and graph, resolve and prove
all dataset members, review the complete target plan, validate/deploy the API candidate only
under explicit authorization, then obtain fresh per-member live receipts. Historical schema
1.0.0 smoke evidence cannot be reused for schema 1.1.0.

The declaration also identifies exact non-Salesforce files: documentation, generated indexes,
catalog scripts and local API test specifications. Every changed file remains recorded with its
base/candidate bytes. These files require the complete local Node catalog/API tests plus deterministic
catalog regeneration/currentness validation. Their declarations cannot reclassify Salesforce source
or the consumed agent/operation contracts as nonruntime. Unknown files remain blocking. Missing or
failed host-attested local receipts block candidate completion; passing a local command by itself
is not a durable Salesforce acceptance receipt or permission to deploy.

Both local obligations explicitly retain `CANDIDATE_CHECK_ONLY`, `DEPLOYED_CANDIDATE` and
`RESTORED_BASELINE` applicability. They request deferral only for read-only `LIVE_BASELINE`
observation; the request grants nothing by itself. Neo must independently pin a host phase policy
to the exact obligation, full input tree, source contract and changed nonruntime paths/categories.
It must record these tests as unresolved, never passed, and allow only standard/custom GET and
bounded metadata retrieval after current org/actor classification. Without that exact host policy,
the default is to require all local evidence before any Salesforce operation. Candidate, restore
and release acceptance still require the complete local obligations and independent live evidence.
