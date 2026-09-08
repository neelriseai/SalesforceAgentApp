# Project index

All paths below are relative to the Salesforce DX project unless stated otherwise. Machine-readable [project-index.json](../knowledge/project-index.json) uses repository-root paths, includes source fingerprints and declares its generated-output exclusions. [application-graph.json](../knowledge/application-graph.json) adds semantic dependencies and logical fixture relationships.

## Find the right entry point

The locator entry points describe **assisted UI drift**, not an in-app healer. The recorded XPath harness, external-agent integration and advanced no-explicit-hint variant are not implemented. Their status is machine-readable in `data/locator-healing-suite.json` and `contracts/agent-interface.json`, and carried into `config:workbench.locatorVariant` in the graph.

For multi-field locator drift: [no-code guide](locator-healing-demo.md), [six LH cases](../data/locator-healing-suite.json), [scoped manifest](../manifest/milestone-8-locator-demo.xml) and [verification](../evidence/milestone-8-verification.md).

| Task | Read / use |
|---|---|
| Connect an external agent safely | [Agent integration guide](agent-integration-guide.md), [interface contract](../contracts/agent-interface.json), [.env.example](../.env.example) |
| Provision CLI/JWT and review deferred org settings | [External-agent provisioning](external-agent-provisioning.md), [integration requirement](../requirements/BR-AGENT-INTEGRATION.md), [API cases](../data/agent-api-test-suite.json) |
| Inspect the narrow policy/evidence API | [REST class](../force-app/main/default/classes/StrategicDealAgentApi.cls), [tests](../force-app/main/default/classes/StrategicDealAgentApiTest.cls), [milestone manifest](../manifest/milestone-9-agent-api.xml) |
| Understand the data/automation architecture | [Knowledge graph overview](application-knowledge-graph.md), [generated graph](../knowledge/application-graph.json) |
| Check the strict approval rule | [Baseline requirement](../requirements/BR-STRATEGIC-DISCOUNT-baseline.md), [policy Apex](../force-app/main/default/classes/StrategicDiscountPolicy.cls), [Default configuration](../force-app/main/default/customMetadata/Strategic_Discount_Rule.Default.md-meta.xml) |
| Trace a saved input to evidence | [Active Flow](../force-app/main/default/flows/Strategic_Discount_Approval.flow-meta.xml), [evaluation schema](../force-app/main/default/objects/Strategic_Deal_Evaluation__c/Strategic_Deal_Evaluation__c.object-meta.xml) |
| Inspect policy-history authorization | [Policy controller](../force-app/main/default/classes/StrategicDealPolicyController.cls), [policy component](../force-app/main/default/lwc/strategicDealPolicyCard/strategicDealPolicyCard.js) |
| Inspect native approval authorization | [Approval controller](../force-app/main/default/classes/StrategicDealApprovalController.cls), [process](../force-app/main/default/approvalProcesses/Opportunity.Strategic_Opportunity_Regional_VP.approvalProcess-meta.xml), [final/recall actions](../force-app/main/default/workflows/Opportunity.workflow-meta.xml) |
| Find browser labels / input allowlist | [Workbench HTML](../force-app/main/default/lwc/strategicDealWorkbench/strategicDealWorkbench.html), [workbench JS](../force-app/main/default/lwc/strategicDealWorkbench/strategicDealWorkbench.js), [approval panel](../force-app/main/default/lwc/strategicDealApprovalPanel/strategicDealApprovalPanel.html) |
| Review privileges | [Permission sets](../force-app/main/default/permissionsets/), [current integration limits](agent-integration-guide.md) |
| Configure optional demo rules | [Rule guide](demo-rules-guide.md), [requirement](../requirements/BR-DEMO-CONFIGURABLE-RULES.md), [guard service](../force-app/main/default/classes/DemoBusinessRules.cls) |
| Build a future automation suite | [42 detailed cases](manual-test-cases.md), [JSON suite](../data/manual-test-suite.json), [test plan](test-plan.md) |
| Run original baseline demos | [Ten-case guide](multi-module-manual-e2e.md), [machine-readable cases](../data/multi-module-use-cases.json), [result sheet](multi-module-test-results.md), [two-login approval](approval-demo-walkthrough.md) |
| Find populated demo views/reports | [Visibility guide](demo-data-visibility.md), [expansion plan](../data/visibility-expansion-plan.json), [expansion runner](../scripts/demo/seed-visibility-expansion.ps1) |
| Prepare/reconcile fixtures | [Multi-module operations](multi-module-data.md), [baseline reset](demo-data-reset.md) |
| Build/check this index | [Catalog generator](../scripts/catalog/build-project-index.mjs), [catalog tests](../scripts/catalog/catalog.test.mjs) |

## Directory map

```text
SalesforceAgentApp/                  repository root
  README.md                         first entry for humans and agents
  AGENTS.md                         workspace instructions
  strategic-deal-assurance/          Salesforce DX project / command working directory
    contracts/                      current agent interface and safety contract
    knowledge/                      generated graph and hashed project inventory
    requirements/                   independent policy obligations
    force-app/main/default/
      applications/, tabs/          app navigation
      objects/, customMetadata/     custom fields, evidence object and policy
      classes/                      policy/controllers/save guards, REST facade and six Apex test suites
      reports/                      five saved synthetic-data reports and dedicated folder
      triggers/                     seven synthetic-record save-guard entry points
      flows/                        record-triggered evaluation and evidence writer
      approvalProcesses/, workflows/ native approval and final/recall field updates
      permissionsets/               six additive capability sets, including transport-only API access
      lwc/                          three components and component tests
      flexipages/, layouts/         Lightning pages, rule settings and Case resolution layout
    manifest/                       scoped deployment slices
    data/                           synthetic fixture plans and manual-case catalog
    docs/                           current integration, operation and test guides
    evidence/                       sanitized historical milestone reports/hashes
    scripts/catalog/                local source graph/index generation and tests
    scripts/demo/                   operator-only seed/reset/user setup utilities
    scripts/test-milestone-*.ps1     named live Apex regression runners
    .sf/, .sfdx/, artifacts/         ignored local state; never ingest or publish auth
```

## Runtime entry points

- App API name: `Strategic_Deal_Assurance`; visible label: Strategic Deal Assurance.
- Workbench tab/page: `Strategic_Deal_Workbench`; Opportunity page: `Strategic_Deal_Record_Page`.
- LWC: `strategicDealWorkbench`, `strategicDealPolicyCard`, `strategicDealApprovalPanel`.
- Pure policy: `StrategicDiscountPolicy.evaluate(List<Input>)`, invoked by `Strategic_Discount_Approval` Flow.
- Internal UI readers/actions: `StrategicDealPolicyController.getPolicy`, `StrategicDealApprovalController.getState` and `.act`.
- Custom read-only facade source: `GET /services/apexrest/sda/v1/policy/{OpportunityId}` via `StrategicDealAgentApi`; live deployment/external identity pending.
- Native process developer name: `Strategic_Opportunity_Regional_VP`, on Opportunity.
- Standard CRM/native approval REST remain conditional on separate OAuth and privileges. The custom endpoint is narrow policy/history read only, never a generic proxy.

## Tests and manifests

| Slice | Manifest | Named tests / main change |
|---|---|---|
| 1 | [milestone-1.xml](../manifest/milestone-1.xml) | StrategicDiscountPolicyTest; fields/config/evidence schema |
| 2 | [milestone-2.xml](../manifest/milestone-2.xml) | Adds StrategicDiscountFlowTest; active Flow/permissions |
| 3 | [milestone-3.xml](../manifest/milestone-3.xml) | Adds StrategicDealPolicyControllerTest; Lightning app/history |
| 4 | [milestone-4.xml](../manifest/milestone-4.xml) | Adds StrategicDealApprovalControllerTest; native approval |
| VP UI correction | [milestone-4-lightning-access.xml](../manifest/milestone-4-lightning-access.xml) | One permission set; LightningExperienceUser |
| 5 | [milestone-5-navigation.xml](../manifest/milestone-5-navigation.xml) | One app; cross-module navigation |
| 6 | [milestone-6-demo-rules.xml](../manifest/milestone-6-demo-rules.xml) | DemoBusinessRulesTest plus previous four suites; eight OFF rules, seven triggers, Case resolution/layout |
| 7 | [milestone-7-demo-visibility.xml](../manifest/milestone-7-demo-visibility.xml) | Three named list views and five reports; no rule/default/code redeployment |
| 8 | [milestone-8-locator-demo.xml](../manifest/milestone-8-locator-demo.xml) | Workbench presentation variants; browser healing not proven |
| 9 | [milestone-9-agent-api.xml](../manifest/milestone-9-agent-api.xml) | StrategicDealAgentApiTest plus five regressions; source prepared, org validation pending refreshed CLI auth |

The regression runner [test-milestone-6.ps1](../scripts/test-milestone-6.ps1) now names all six suites; its filename is retained for compatibility. Component tests are under each LWC's `__tests__`. Local checks do not establish live UI/API behavior. Do not use broad `package.xml` as routine scope.

## Evidence index and freshness

| Evidence | Scope / interpretation |
|---|---|
| [Milestone 1](../evidence/milestone-1-verification.md) | Initial pure policy/metadata snapshot |
| [Milestone 2](../evidence/milestone-2-verification.md) | Flow/security snapshot; associated permission matrix is historical |
| [Milestone 3](../evidence/milestone-3-verification.md) | Lightning/history implementation snapshot |
| [Original data reset](../evidence/demo-data-reset-verification.md) | Seven boundary fixtures and restore/rehearse behavior |
| [Milestone 4](../evidence/milestone-4-verification.md) | Native approval, Lightning permission correction, later VP confirmation |
| [Milestone 5](../evidence/milestone-5-verification.md) | 368-row load, no-op rerun, source/API validation and navigation smoke |
| [Milestone 6](../evidence/milestone-6-verification.md) | Configurable rule deployment and regression; manual specs do not certify browser execution |
| [Milestone 7](../evidence/milestone-7-verification.md) | 186-row expansion, named views, five live report counts and unchanged original fixtures |
| [Manual results](multi-module-test-results.md) | Ten-case browser suite remains Not run until explicitly executed |

Historical source-hash files intentionally refer to their original snapshots. They are not expected to match files changed by later milestones. The generated project index is the current LF-normalized source fingerprint, not a substitute for fresh live test receipts. Runtime IDs/auth files are intentionally absent from the source graph.
