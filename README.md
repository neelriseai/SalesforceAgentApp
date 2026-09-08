# Salesforce Agent Demo Application

Native Salesforce demo system for a separately developed assurance/testing agent. The Salesforce DX project is in [`strategic-deal-assurance/`](strategic-deal-assurance/). Salesforce owns CRM records, deterministic strategic-deal policy and native human approval; the external agent owns planning, test execution, analysis and any explicitly approved repair.

For the dedicated hackathon org, the approved autonomous MVP lane uses the local `caip-dev` Salesforce CLI authorization for REST, scoped metadata operations and short-lived browser sessions. JWT/certificate setup and a second integration user are optional production-hardening steps, not prerequisites. Reauthorization still requires one private browser login whenever Salesforce expires the CLI session.

## Start here

| Reader | Entry point |
|---|---|
| Agent developer | [Agent integration guide](strategic-deal-assurance/docs/agent-integration-guide.md) |
| Agent authentication / org setup | [External-agent provisioning](strategic-deal-assurance/docs/external-agent-provisioning.md), [integration requirement](strategic-deal-assurance/requirements/BR-AGENT-INTEGRATION.md) |
| Agent runtime / ingestion | [Interface contract](strategic-deal-assurance/contracts/agent-interface.json), [knowledge graph](strategic-deal-assurance/knowledge/application-graph.json), [project index](strategic-deal-assurance/knowledge/project-index.json) |
| Application architecture | [Knowledge graph overview](strategic-deal-assurance/docs/application-knowledge-graph.md), [project map](strategic-deal-assurance/docs/project-index.md) |
| Human demo tester | [42 detailed manual cases](strategic-deal-assurance/docs/manual-test-cases.md), [test plan](strategic-deal-assurance/docs/test-plan.md), [rule configuration guide](strategic-deal-assurance/docs/demo-rules-guide.md) |
| Salesforce maintainer | [Project README](strategic-deal-assurance/README.md), [repository instructions](AGENTS.md), [project instructions](strategic-deal-assurance/AGENTS.md) |

## What exists

Locator-demo scope: Salesforce changes the UI; it contains **no XPath healer**. The assisted variant is implemented. A recorded runnable XPath baseline, external-agent healing integration and advanced no-explicit-hint variant remain future work; nine-target failure/recovery is not yet browser-proven. See the [status and demo boundaries](strategic-deal-assurance/docs/locator-healing-demo.md#implementation-status-and-showcase-boundary).

- A no-code [multi-field locator drift demo](strategic-deal-assurance/docs/locator-healing-demo.md): three App Builder variants change eight field hooks, ordering/sections and the save action; six detailed scenarios guide external-agent metadata/DOM recovery without changing business rules.
- Lightning app: **Strategic Deal Assurance**, with a deal workbench, policy/evaluation card, native approval panel and deployed narrow read-only agent policy/evidence REST endpoint.
- Active rule: strategic AND Amount **> USD 50,000,000** AND Discount **> 15%**. Missing required approver produces Configuration Error. No currency conversion.
- Native owner submission, separate assigned VP approval/rejection, owner recall and normal-user record locking.
- Native Accounts, Contacts, Leads, Opportunities, Cases, Tasks and Campaigns. A create-only loader prepares **368 linked business records + 40 initial policy evaluations**, separate from the original seven-case boundary dataset.
- Eight optional CRM save guards, editable in Salesforce Setup and OFF by default: account/contact reassignment, lead qualification, won-deal minimum/primary contact, case resolution, task due date and active-campaign response.
- A unified **42-case / 232-step manual suite**, with exact fixtures, independent expectations, negative checks, actors, restoration steps and a [machine-readable automation specification](strategic-deal-assurance/data/manual-test-suite.json). This includes the original ten CRM workflows.
- Versioned Salesforce metadata, Apex/Jest tests, scoped deployment manifests and sanitized milestone evidence.

## Find Cases, Tasks, Campaigns and Reports

Select **SDA Demo Cases**, **SDA Demo Tasks** or **SDA Demo Campaigns** from each module's list dropdown, rather than Recently Viewed/Today. Reports are under **Reports > All Folders > SDA Demo Reports**. See the [visibility guide](strategic-deal-assurance/docs/demo-data-visibility.md) for exact steps and supplemental verification cases.

A separate create-only expansion adds **186 records** without touching the original fixtures: combined SYN-MM totals are **60 Cases, 120 Tasks, 10 Campaigns, 34 Accounts and 80 Contacts** (554 business records overall). Five saved reports cover Cases, Tasks, Campaigns, Opportunities and Accounts. Dates/permissions still apply; these views do not grant extra record access.

## Important integration boundaries

The local Salesforce CLI uses two verified aliases: owner-approved `caip-dev` brokers REST, scoped metadata and administrator browser sessions; `caip-vp` maps to Synthetic Regional VP and adds only transport to its existing approver authority. This preserves administrator-versus-approver separation for the hackathon. Dedicated human-versus-bot users and a portable API client remain optional production hardening.

Milestone 9 deployed a narrow `GET /services/apexrest/sda/v1/policy/{OpportunityId}` facade and passed 50 Apex tests plus an administrator HTTP-200 smoke test. It is not a CRM write proxy or authentication endpoint; standard Salesforce REST handles CRUD and native REST handles approvals. Direct evaluation-object access remains withheld. Dedicated-identity API-01–06 execution is optional/pending; read the integration/provisioning guides before claiming least-privilege parity.

## Local checks

```powershell
cd strategic-deal-assurance
npm ci
npm run manual:check
npm run manual:test
npm run visibility:test
npm run catalog:check
npm run catalog:test
npm run test:unit -- -- --runInBand
npm run lint
powershell -NoProfile -File scripts/demo/test-multi-module-local.ps1
powershell -NoProfile -File scripts/demo/test-reset-local.ps1
```

`npm run catalog:build` regenerates the source-derived graph/index. It makes no Salesforce calls. Live Apex testing, deployment and seeding require the explicitly verified `caip-dev` org; follow the guide rather than deploying the scaffold's broad package manifest.

## Evidence, secrets and release status

See [milestone 8 verification](strategic-deal-assurance/evidence/milestone-8-verification.md) for the locator deployment, 27 LWC tests and recorded 51-test post-deploy Apex run; [milestone 7](strategic-deal-assurance/evidence/milestone-7-verification.md) covers the data/report expansion. Earlier results remain historical. The **42-case manual browser suite and six LH cases are specified, not marked executed**. A repeatable external API/UI harness, full tagged release reset and dedicated agent OAuth setup are still pending.

Only synthetic plans and sanitized reports belong in Git. Credentials, `.sf`, `.sfdx`, `.env`, browser profiles and raw artifacts are ignored. Supply org URLs, usernames and secret-store references locally; never publish tokens, passwords, activation links or session URLs. A source snapshot or push does not certify a live org or authorize writes to it.
