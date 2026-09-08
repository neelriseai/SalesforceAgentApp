# Strategic Deal Assurance

Salesforce system-under-test for a separately developed assurance agent. Current additions include a deployed narrow read-only agent policy/evidence REST endpoint and integration permission design, plus the **186-record expansion (554 combined SYN-MM business records)**, populated reports/views, assisted locator-change demo, configurable CRM guards, 42-case business suite, USD 15% policy and separate-persona Regional VP approval. Milestone 9 is live-smoke-validated through the approved hackathon administrator lane; dedicated-identity validation remains optional/pending.

## External agent API and authentication

Read the [integration requirement](requirements/BR-AGENT-INTEGRATION.md), [provisioning/settings guide](docs/external-agent-provisioning.md), [agent guide](docs/agent-integration-guide.md) and [six-case API specification](data/agent-api-test-suite.json). The app supplies a read-only parent-authorized policy/evidence facade. Standard CRM REST, native approval REST, CLI/JWT authentication, browser session handling and locator healing remain outside that facade.

No JWT private key, consumer key, username, token or frontdoor URL belongs in this repository. For this dedicated hackathon org, the owner approved `caip-dev` administrator-backed REST, scoped Metadata API and ephemeral browser sessions as the MVP lane. Separate `caip-vp` is verified as Synthetic Regional VP with only its existing approver authority plus transport-only API access. Neither alias needs a certificate or stored Salesforce password; reauthorize privately after future expiry. External Client App/JWT and dedicated bot identities are optional production-hardening work, not blockers.

## More data and named demo views/reports

The original 368-row dataset is preserved. A separate **186-record expansion** brings the combined SYN-MM population to **554 business records**: 60 Cases, 120 Tasks, 10 Campaigns, 34 Accounts, 80 Contacts, plus the existing Opportunities, Leads and relationships. New cases/tasks have varied statuses and task due dates around 2026-09-04.

Use the **SDA Demo Cases/Tasks/Campaigns** list views and **Reports > All Folders > SDA Demo Reports**, which contains five populated saved reports. Read the [visibility guide and supplemental manual checks](docs/demo-data-visibility.md). Loader: [seed-visibility-expansion.ps1](scripts/demo/seed-visibility-expansion.ps1); plan: [visibility-expansion-plan.json](data/visibility-expansion-plan.json); scope: [milestone-7-demo-visibility.xml](manifest/milestone-7-demo-visibility.xml).

## Configure and demo without code changes

Salesforce contains no locator healer: only UI change controls. Recorded baseline XPath automation, external-agent healing integration and an advanced no-explicit-identity-hint mode are **not yet implemented here**. The current assisted hints support recovery but do not prove every existing locator fails. Nine-target failure/recovery must be demonstrated against an actual baseline browser run; see the [status boundary](docs/locator-healing-demo.md#implementation-status-and-showcase-boundary).

For UI locator changes, use **Setup > Lightning App Builder > Strategic Deal Workbench (or Strategic Deal Record Page) > Edit > select Workbench component > Locator demo variant**. Choose `baseline`, `reordered` or `regrouped`, Save and reopen the runtime page. This changes presentation across eight fields plus the save action, not policy or permissions. Read the [locator demo guide](docs/locator-healing-demo.md), [six-case / 20-step automation specification](data/locator-healing-suite.json) and [verification limits](evidence/milestone-8-verification.md). The external agent's healer is not implemented in Salesforce.

As administrator, open **Setup > Custom Metadata Types > Demo Business Rule > Manage Records**. All eight new restrictions start OFF. Enable the desired rule, adjust its supported parameter/version, then save the target record to observe the changed behavior. The existing strategic discount remains under **Strategic Discount Rule > Default**, unchanged at 15%.

Read the [configuration guide](docs/demo-rules-guide.md), [approved rule specification](requirements/BR-DEMO-CONFIGURABLE-RULES.md), [test plan](docs/test-plan.md), [42 step-by-step manual cases](docs/manual-test-cases.md) and [JSON suite for future automation](data/manual-test-suite.json). Each case supplies exact data, actor, preconditions, action/expected-result steps, negative checks, evidence and cleanup. Configuration changes do not automatically re-evaluate old records; successful Lead conversion cannot be undone by the seed loader.

Implementation: DemoBusinessRules, seven thin triggers, eight Demo_Business_Rule__mdt records, Case Demo Resolution field/layout and field-only Demo_Rule_Operator permission set. Existing approval security and 15% policy are not weakened. New guards target only SYN-MM-/SYN-RULE- synthetic names; this is not a production-wide validation framework.

Run `npm run manual:build`, `npm run manual:check` and `npm run manual:test` after changing scenarios; then rebuild/check the knowledge catalog. Current live runner: [test-milestone-6.ps1](scripts/test-milestone-6.ps1), all six Apex suites with coverage. Scoped deployment: [milestone-6-demo-rules.xml](manifest/milestone-6-demo-rules.xml). Read [verification and limitations](evidence/milestone-6-verification.md) before claiming execution.

## Agent handoff and project discovery

Start with the [agent integration guide](docs/agent-integration-guide.md) and [machine-readable interface contract](contracts/agent-interface.json). Use the [project map](docs/project-index.md), [knowledge graph overview](docs/application-knowledge-graph.md), [generated graph](knowledge/application-graph.json) and [hashed file index](knowledge/project-index.json) to locate implementation and test evidence. [.env.example](.env.example) defines optional local connection settings without credentials.

The guide covers authentication lanes, exact field names, relationships, lifecycle, browser controls, REST shapes, current permission limits and reset safety. `StrategicDealAgentApi` is the only custom external endpoint and is read-only; internal AuraEnabled methods remain non-HTTP. The endpoint is deployed and administrator-smoke-tested. No dedicated identity is provisioned or live-validated, and direct private-evidence CRUD remains denied.

Regenerate discovery artifacts with `npm run catalog:build`, validate freshness with `npm run catalog:check`, and run local catalog/security checks with `npm run catalog:test`. Historical milestone reports remain historical; current graph/index source fingerprints do not certify the live org.

## Implementation and demo references

- [Baseline requirement](requirements/BR-STRATEGIC-DISCOUNT-baseline.md)
- [Design and scope boundaries](docs/milestone-1-design.md)
- [Exact deployment manifest](manifest/milestone-1.xml)
- [Live milestone verification](evidence/milestone-1-verification.md)
- [Flow and permission design](docs/milestone-2-design.md)
- [Milestone 2 verification](evidence/milestone-2-verification.md)
- [Lightning app design](docs/milestone-3-design.md)
- [Milestone 3 verification](evidence/milestone-3-verification.md)
- [Demo data and reset commands](docs/demo-data-reset.md)
- [Demo data/reset verification](evidence/demo-data-reset-verification.md)
- [Native approval design and limitations](docs/milestone-4-design.md)
- [Milestone 4 verification](evidence/milestone-4-verification.md)
- [Two-login approval walkthrough](docs/approval-demo-walkthrough.md)
- [10 cross-module manual end-to-end tests](docs/multi-module-manual-e2e.md)
- [Manual test result sheet](docs/multi-module-test-results.md)
- [Cross-module data loader and verification](docs/multi-module-data.md)
- [Cross-module milestone verification](evidence/milestone-5-verification.md)

The first slice provides seven Opportunity fields, the evaluation evidence object, central policy custom metadata, and tested invocable Apex. Milestone 2 activates the after-save Flow: creating an Opportunity or changing policy inputs updates its outcome and creates one evaluation row. Irrelevant/output-only changes create none. The rule is strategic=true AND Amount > USD 50,000,000 AND Discount > 15%. No currency conversion occurs.

Six permission sets are defined. The new transport-only API set grants no business access itself; deployed updates expand the integration/UI automation lanes without Delete, View All, direct evidence CRUD, approval or metadata administration. Evaluation history remains private and is exposed only after a parent user-mode gate. A separate human VP remains browser-only. External JWT identity/assignment, a complete API/UI harness and full tagged reset remain optional future milestones.

Run commands from this directory and explicitly target `caip-dev`. Do not deploy the template's broad package manifest; use the appropriate scoped milestone manifest. Repeat current Apex tests with `powershell -NoProfile -File scripts/test-milestone-6.ps1`, component tests with `npm run test:unit -- -- --runInBand`, and lint with `npm run lint`. VS Code is optional. Open App Launcher > Strategic Deal Assurance for the demo UI.

The expanded navigation exposes Accounts, Contacts, Leads, Opportunities, Cases, Tasks and Campaigns as permitted by the current user's access. Search `SYN-MM-` in an all-records list to find the new fixtures. Forty new Opportunities produce forty initial evaluation rows in addition to the 368 business records. The loader is create-only and leaves the original `SYN-SDA-` approval demo unchanged. Manual test results remain Not run until the stated browser steps are executed; successful seeding is not a manual E2E pass.

## Original Salesforce DX scaffold reference

Salesforce DX is a development approach that brings source-driven development, team collaboration, and continuous integration to the Salesforce Platform. Instead of working directly in an org through a web browser, you work with metadata as source files in a local DX project, track changes in version control, and deploy through automated processes.

This project template gets you started with the tools and structure you need to build Salesforce applications using source control, scratch orgs, and the Salesforce CLI.

## Prerequisites

Before you start, make sure you have:

- **Salesforce CLI** - Download from [developer.salesforce.com/tools/salesforcecli](https://developer.salesforce.com/tools/salesforcecli). See [Install Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm) for details.
- **VS Code with Salesforce Extension Pack** - See [Installation Instructions](https://developer.salesforce.com/docs/platform/sfvscode-extensions/guide/install.html) for details. Includes the Agentforce Vibes extension.
- **A development org** - Sign up for a free Developer Edition org [here](https://developer.salesforce.com/signup).
- **Dev Hub enabled** (optional, required to create scratch orgs) - You can enable Dev Hub in your development org under Setup > Dev Hub.  See [Provide Developers Access to Salesforce DX Tools](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_setup_dx_tools.htm).

## Project Structure

Your DX project follows this structure:

- **`force-app/main/default/`** - Your metadata source files live in this default package directory. You can configure additional package directories in the `sfdx-project.json` file.
- **`config/`** - Scratch org definitions and project settings
- **`scripts/`** - Automation scripts for common tasks
- **`sfdx-project.json`** - Project manifest that defines package directories, namespace, API version, and other project-level settings

See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm).

## Get Started

Ready to start developing? The [Get Started with Salesforce DX](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_get_started_dx.htm) guide walks you through your first project, from creating a scratch org to creating a simple Apex class or LWC to deploying your code to a sandbox.

## Common Salesforce CLI Commands

Here are common CLI commands that you'll use the most:

- `sf org login web`: Authorize an org
- `sf org open`: Open your org in a browser
- `sf org create scratch`: Create a scratch org
- `sf project deploy start`: Deploy metadata to your org
- `sf project retrieve start`: Retrieve metadata from your org
- `sf template generate <artifact>`: Scaffold new components, such as Apex classes and triggers, LWC components, Lightning apps, and more
- `sf apex <command>`: Run Apex tests, run anonymous Apex blocks, and view logs
- `sf data <command>`: Work with test data
- `sf alias <command>`: Manage org aliases
- `sf config <command>`: Configure CLI settings

## Use Agentforce Vibes to Build Lightning Apps

Transform your ideas into custom Lightning apps that extend CRM workflows directly in Lightning Experience. Through natural conversations with Agentforce Vibes, implement custom objects and fields, complex business logic, and dynamic UI components. See [Build a Lightning App Using Agentforce Vibes](https://developer.salesforce.com/docs/platform/einstein-for-devs/guide/lexapp-overview.html).

## Additional Resources

- [Agentforce Vibes Developer Guide](https://developer.salesforce.com/docs/platform/einstein-for-devs/guide/einstein-overview.html)
- [Salesforce CLI Installation Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
- [Salesforce CLI Plugin Development Guide](https://developer.salesforce.com/docs/platform/salesforce-cli-plugin/guide/conceptual-overview.html)
- [Salesforce VS Code Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
