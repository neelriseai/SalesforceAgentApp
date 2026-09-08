# Application knowledge graph

The full [machine-readable graph](../knowledge/application-graph.json) contains typed nodes and directed, source-attributed edges for metadata, permissions, components, tests, datasets, 554 logical fixtures, 42 manual scenarios, six locator cases and six agent-API cases. These compact views show its main relationships; the JSON has field-level detail. Nothing in the graph grants an agent permission to execute an action.

Milestone 9 adds `requirement:BR-AGENT-INTEGRATION`, `apex:StrategicDealAgentApi`, its test and API case edges. Source implementation does not mean live deployment or identity validation; the current CLI authorization must be refreshed first.

## Business record relationships

`config:workbench.locatorVariant.implementationStatus` distinguishes implemented assisted presentation from the unimplemented recorded XPath harness and proposed advanced no-explicit-hint mode. Nine-target browser healing is not demonstrated; the app contains no healer. Consumers must not infer implementation or execution from the existence of a scenario node.

The graph also includes six `locator-use-case` nodes and `config:workbench.locatorVariant`, linked to the Workbench, both page configuration surfaces and all eight input field identities. These presentation-only scenarios are separate from the 42 business cases; their browser/healer execution is not certified by static graph edges. See the [locator guide](locator-healing-demo.md).

```mermaid
flowchart LR
  AG[Parent Account] -->|ParentId hierarchy| A[Customer Account]
  A -->|AccountId| C[Contact]
  A -->|AccountId| O[Opportunity]
  O --> R[Opportunity Contact Role]
  R --> C
  A --> S[Case]
  S -->|ContactId| C
  T[Task] -->|WhoId| C
  T -->|WhatId| A
  T -->|WhatId| O
  T -->|WhatId| S
  M[Campaign] --> CM[Campaign Member]
  CM --> C
  CM --> L[Lead]
  O -->|Regional VP Approver lookup| U[Separate User]
```

Arrows here emphasize business relationships, not cardinality constraints. A Campaign Member links one Contact OR Lead. Task references are polymorphic. The fixture graph uses logical keys such as `fixture:A05` and `fixture:O02`, never deployed record IDs or credentials.

## Policy and human approval

```mermaid
flowchart TD
  EDIT[Authorized input save] --> F[After-save Flow]
  F --> P[StrategicDiscountPolicy]
  CFG[Default Custom Metadata] -->|threshold and version| P
  P --> OUT[Derived Opportunity status]
  OUT --> E[One private policy evaluation]
  UI[Policy card] --> PC[Parent-authorized policy controller]
  PC --> OUT
  PC -->|latest five summaries| E
  OWNER[Owner submits explicitly] --> AC[Approval controller: recheck policy]
  AC --> AP[Native ApprovalProcess]
  AP --> LOCK[Pending work item and ordinary-user lock]
  VP[Assigned separate VP] -->|Approve or Reject| AP
  AP --> FINAL[Approved or Rejected; unlock]
  OWNER -->|Recall| AP
  AP --> RECALL[Native Removed; eligibility Pending Regional VP]
```

Policy eligibility is not an approval request. Human decisions change the derived status through native field updates but do not append policy-input evaluations. Relevant input changes evaluate again; unrelated Stage/Name changes do not. Admin overrides remain outside the app's restrictive action adapter.

## Configurable CRM save guards

Eight `config:Demo_Business_Rule.<key>` nodes connect to the seven `apex-trigger` nodes, the `DemoBusinessRules` service, affected objects and manual-case IDs. The service reads current Custom Metadata, rejects invalid saves and never writes data itself. Lead conversion uses after-update rollback; other guarded saves use before triggers.

Follow `tests_configuration` from a manual case to the rule, `configures` to its trigger, and `guards_save_of` to affected objects. `DemoBusinessRulesTest` links to all eight rule records. Default values in this source graph are OFF and may differ from the live org during a demo. Scope prefixes are not security guarantees; see the [rule guide](demo-rules-guide.md).

## Agent access boundaries

```mermaid
flowchart LR
  AGENT[External agent] -->|approved interactive session| B[Lightning browser]
  B --> W[Workbench / policy / approval panels]
  W --> LDS[Lightning Data Service]
  W --> AURA[Internal AuraEnabled controllers]
  AGENT -. dedicated OAuth and permissions needed .-> REST[Standard Salesforce REST]
  REST --> CRM[Permitted CRM records]
  EVID[Private evaluation evidence] -. no direct ordinary API CRUD .-> REST
  CUSTOM[Custom Apex REST facade: not implemented]
```

Dashed edges describe limitations/prerequisites, not active access grants. The UI's narrow private-history reader is not an external API. The current integration permission set grants Opportunity input operations and Account read only, not all seeded modules. Read the [agent guide](agent-integration-guide.md) before designing connectors or API tests.

## Visibility and reporting

The graph includes five `saved-report` nodes, three `list-view` nodes and the independent `SDA-VISIBILITY-EXPANSION-v1` dataset (186 rows). Reports read synthetic scoped data; list-view filters are recorded as source facts, not proof of effective user access. Original fixture keys/relationships remain unchanged. See [visibility guide](demo-data-visibility.md) for expected counts and run instructions.

## Graph schema and traversal

Top level: `schemaVersion`, `apiVersion`, `sourceSnapshot`, `provenance`, `authorization`, `nodes`, `edges`.

- Node: stable `id`, `kind`, human `label`, source path and type-specific attributes. Kinds include object, field, apex-class, apex-test, apex-trigger, custom-metadata-record, flow, permission-set, approval-process, workflow-field-update, lightning-component/page/app, capability, dataset, synthetic-fixture, manual-use-case and file.
- Edge: stable `id`, `from`, `relation`, `to`, `source`, optional relationship details. Examples: `has_field`, `references`, `reads`, `writes`, `calls`, `appends`, `routes_via`, `tests`, `object_grant`, `field_grant`, `contains`.
- File paths and edge provenance use repository-relative paths. Static fields parsed from custom XML include type, label, requiredness, precision/scale and picklist values. Standard fields referenced by fixtures require runtime describe for complete schema/permissions.
- Permission edges describe additive source grants, not a user's complete effective access. Historical evidence is not treated as current runtime authority.
- `sourceSnapshot` fingerprints the repository candidates excluding generated graph/index outputs, using UTF-8 text normalized to LF. No timestamps or machine-specific paths are included, making regeneration deterministic across checkouts.

Useful traversals: policy configuration → pure policy → Flow/output/evidence → UI/tests; Opportunity field → field grants; manual case → modules/dataset → fixture references; approval process → routing lookup → User and native request history. For an impact-analysis decision, read the connected source and obtain current runtime evidence; the graph does not model every possible standard Salesforce dependency.

## Regenerate and validate

```powershell
npm run catalog:build
npm run catalog:check
npm run catalog:test
```

Run inside the Salesforce project. The generator uses only Node built-ins and Git's tracked/unignored file inventory; it does not query Salesforce or emit auth state. Tests reject duplicate/dangling graph IDs, missing sources, missing scenarios, incorrect core policy facts and common auth/secret artifacts in publish candidates. It is a focused safety check, not a guarantee that every possible secret format is detected.
