# Strategic Deal Assurance

Salesforce system-under-test for a separately developed assurance agent. The current milestone adds **10 native cross-module scenarios and 368 linked synthetic business records** to the Lightning workbench, USD 15% policy and separate-persona Regional VP approval. This is not yet a full showcase release.

## Agent handoff and project discovery

Start with the [agent integration guide](docs/agent-integration-guide.md) and [machine-readable interface contract](contracts/agent-interface.json). Use the [project map](docs/project-index.md), [knowledge graph overview](docs/application-knowledge-graph.md), [generated graph](knowledge/application-graph.json) and [hashed file index](knowledge/project-index.json) to locate implementation and test evidence. [.env.example](.env.example) defines optional local connection settings without credentials.

The guide covers authentication lanes, exact field names, record relationships, policy/approval lifecycle, browser controls, standard REST request shapes, current permission limits, data/reset safety and known gaps. There is no custom Apex REST facade or authenticated external-agent client provisioned by this repo. Internal AuraEnabled methods must not be treated as HTTP endpoints. Existing integration permissions do not grant every CRM module or direct private-evidence access.

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

Four permission sets are deployed; Strategic_Deal_User is assigned to the authorized demo identity with user approval. Evaluation history remains private without direct normal-user CRUD; the controller checks parent access before returning five narrow history summaries. Seven managed synthetic deals have a repeatable, non-destructive data reset. Native approval supports submission, assigned-actor approval/rejection, owner recall and record locking. A separate minimum-access demo VP is provisioned. Reset refuses pending approval requests. External API correlation, a repeatable UI/API harness and full tagged release reset remain future milestones. A custom external REST facade is deferred; the approval controller is an internal Lightning adapter.

Run commands from this directory and explicitly target `caip-dev`. Do not deploy the template's broad package manifest; use the appropriate scoped milestone manifest. Repeat current Apex tests with `powershell -NoProfile -File scripts/test-milestone-4.ps1`, component tests with `npm run test:unit -- -- --runInBand`, and lint with `npm run lint`. VS Code is optional. Open App Launcher > Strategic Deal Assurance for the demo UI.

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
