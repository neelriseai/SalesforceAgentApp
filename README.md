# Salesforce Agent Demo Application

Native Salesforce demo system for a separately developed assurance/testing agent. The Salesforce DX project is in [`strategic-deal-assurance/`](strategic-deal-assurance/). Salesforce owns CRM records, deterministic strategic-deal policy and native human approval; the external agent owns planning, test execution, analysis and any explicitly approved repair.

## Start here

| Reader | Entry point |
|---|---|
| Agent developer | [Agent integration guide](strategic-deal-assurance/docs/agent-integration-guide.md) |
| Agent runtime / ingestion | [Interface contract](strategic-deal-assurance/contracts/agent-interface.json), [knowledge graph](strategic-deal-assurance/knowledge/application-graph.json), [project index](strategic-deal-assurance/knowledge/project-index.json) |
| Application architecture | [Knowledge graph overview](strategic-deal-assurance/docs/application-knowledge-graph.md), [project map](strategic-deal-assurance/docs/project-index.md) |
| Human demo tester | [10 manual E2E scenarios](strategic-deal-assurance/docs/multi-module-manual-e2e.md), [result sheet](strategic-deal-assurance/docs/multi-module-test-results.md) |
| Salesforce maintainer | [Project README](strategic-deal-assurance/README.md), [repository instructions](AGENTS.md), [project instructions](strategic-deal-assurance/AGENTS.md) |

## What exists

- Lightning app: **Strategic Deal Assurance**, with a deal workbench, policy/evaluation card and native approval panel.
- Active rule: strategic AND Amount **> USD 50,000,000** AND Discount **> 15%**. Missing required approver produces Configuration Error. No currency conversion.
- Native owner submission, separate assigned VP approval/rejection, owner recall and normal-user record locking.
- Native Accounts, Contacts, Leads, Opportunities, Cases, Tasks and Campaigns. A create-only loader prepares **368 linked business records + 40 initial policy evaluations**, separate from the original seven-case boundary dataset.
- Ten additional manual use cases with 53 steps, independent expected results, roles and cleanup instructions.
- Versioned Salesforce metadata, Apex/Jest tests, scoped deployment manifests and sanitized milestone evidence.

## Important integration boundaries

The existing local Salesforce CLI authorization is an **operator lane**, not portable agent credentials. The two human browser sessions are separate from an API integration. `Change_Assurance_Integration` defines limited Opportunity access, but this repository does not provision a dedicated authenticated agent client/user or grant access to every CRM module.

There is **no custom Apex REST facade**. The `@AuraEnabled` controllers serve Lightning and are not public HTTP endpoints. Standard Salesforce REST APIs are available only with suitable OAuth, object/field permissions and sharing. Direct evaluation-object access is intentionally withheld; the browser's parent-authorized history reader exposes only narrow summaries. Read the integration guide before assuming API parity.

## Local checks

```powershell
cd strategic-deal-assurance
npm ci
npm run catalog:check
npm run catalog:test
npm run test:unit -- -- --runInBand
npm run lint
powershell -NoProfile -File scripts/demo/test-multi-module-local.ps1
powershell -NoProfile -File scripts/demo/test-reset-local.ps1
```

`npm run catalog:build` regenerates the source-derived graph/index. It makes no Salesforce calls. Live Apex testing, deployment and seeding require the explicitly verified `caip-dev` org; follow the guide rather than deploying the scaffold's broad package manifest.

## Evidence, secrets and release status

The latest recorded Apex regression is **35/35 results, 99% coverage**; component checks recorded **22 passing Jest tests**. See the [evidence index](strategic-deal-assurance/docs/project-index.md) for dates and scope. The ten-case manual browser suite is prepared, **not marked executed**. A repeatable external API/UI harness, full tagged release reset and dedicated agent OAuth setup are still pending.

Only synthetic plans and sanitized reports belong in Git. Credentials, `.sf`, `.sfdx`, `.env`, browser profiles and raw artifacts are ignored. Supply org URLs, usernames and secret-store references locally; never publish tokens, passwords, activation links or session URLs. A source snapshot or push does not certify a live org or authorize writes to it.
