# Salesforce Agent Demo Application

Native Salesforce demo system for a separately developed assurance/testing agent. The Salesforce DX project is in [`strategic-deal-assurance/`](strategic-deal-assurance/). Salesforce owns CRM records, deterministic strategic-deal policy and native human approval; the external agent owns planning, test execution, analysis and any explicitly approved repair.

## Start here

| Reader | Entry point |
|---|---|
| Agent developer | [Agent integration guide](strategic-deal-assurance/docs/agent-integration-guide.md) |
| Agent runtime / ingestion | [Interface contract](strategic-deal-assurance/contracts/agent-interface.json), [knowledge graph](strategic-deal-assurance/knowledge/application-graph.json), [project index](strategic-deal-assurance/knowledge/project-index.json) |
| Application architecture | [Knowledge graph overview](strategic-deal-assurance/docs/application-knowledge-graph.md), [project map](strategic-deal-assurance/docs/project-index.md) |
| Human demo tester | [42 detailed manual cases](strategic-deal-assurance/docs/manual-test-cases.md), [test plan](strategic-deal-assurance/docs/test-plan.md), [rule configuration guide](strategic-deal-assurance/docs/demo-rules-guide.md) |
| Salesforce maintainer | [Project README](strategic-deal-assurance/README.md), [repository instructions](AGENTS.md), [project instructions](strategic-deal-assurance/AGENTS.md) |

## What exists

- Lightning app: **Strategic Deal Assurance**, with a deal workbench, policy/evaluation card and native approval panel.
- Active rule: strategic AND Amount **> USD 50,000,000** AND Discount **> 15%**. Missing required approver produces Configuration Error. No currency conversion.
- Native owner submission, separate assigned VP approval/rejection, owner recall and normal-user record locking.
- Native Accounts, Contacts, Leads, Opportunities, Cases, Tasks and Campaigns. A create-only loader prepares **368 linked business records + 40 initial policy evaluations**, separate from the original seven-case boundary dataset.
- Eight optional CRM save guards, editable in Salesforce Setup and OFF by default: account/contact reassignment, lead qualification, won-deal minimum/primary contact, case resolution, task due date and active-campaign response.
- A unified **42-case / 232-step manual suite**, with exact fixtures, independent expectations, negative checks, actors, restoration steps and a [machine-readable automation specification](strategic-deal-assurance/data/manual-test-suite.json). This includes the original ten CRM workflows.
- Versioned Salesforce metadata, Apex/Jest tests, scoped deployment manifests and sanitized milestone evidence.

## Important integration boundaries

The existing local Salesforce CLI authorization is an **operator lane**, not portable agent credentials. The two human browser sessions are separate from an API integration. `Change_Assurance_Integration` defines limited Opportunity access, but this repository does not provision a dedicated authenticated agent client/user or grant access to every CRM module.

There is **no custom Apex REST facade**. The `@AuraEnabled` controllers serve Lightning and are not public HTTP endpoints. Standard Salesforce REST APIs are available only with suitable OAuth, object/field permissions and sharing. Direct evaluation-object access is intentionally withheld; the browser's parent-authorized history reader exposes only narrow summaries. Read the integration guide before assuming API parity.

## Local checks

```powershell
cd strategic-deal-assurance
npm ci
npm run manual:check
npm run manual:test
npm run catalog:check
npm run catalog:test
npm run test:unit -- -- --runInBand
npm run lint
powershell -NoProfile -File scripts/demo/test-multi-module-local.ps1
powershell -NoProfile -File scripts/demo/test-reset-local.ps1
```

`npm run catalog:build` regenerates the source-derived graph/index. It makes no Salesforce calls. Live Apex testing, deployment and seeding require the explicitly verified `caip-dev` org; follow the guide rather than deploying the scaffold's broad package manifest.

## Evidence, secrets and release status

See [milestone 6 verification](strategic-deal-assurance/evidence/milestone-6-verification.md) for current named Apex and local checks; earlier 35/35 Apex results remain historical. The **42-case manual browser suite is specified, not marked executed**. A repeatable external API/UI harness, full tagged release reset and dedicated agent OAuth setup are still pending.

Only synthetic plans and sanitized reports belong in Git. Credentials, `.sf`, `.sfdx`, `.env`, browser profiles and raw artifacts are ignored. Supply org URLs, usernames and secret-store references locally; never publish tokens, passwords, activation links or session URLs. A source snapshot or push does not certify a live org or authorize writes to it.
