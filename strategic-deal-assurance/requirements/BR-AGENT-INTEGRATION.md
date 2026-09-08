# BR-AGENT-INTEGRATION: governed external agent lane

Status: deployed and live-smoke-validated through the user-approved `caip-dev` hackathon-administrator lane; dedicated least-privilege identity validation remains optional/pending.

The Salesforce app supplies standard CRM data and one narrow read-only policy-evidence facade. Authentication, CLI process execution, browser session handling, locator healing, repair approval and orchestration remain in the separate agent module.

## Required app behavior

- `GET /services/apexrest/sda/v1/policy/{OpportunityId}?limit=1..50` returns current derived policy state, active policy configuration and newest private evaluation summaries.
- The caller must first be able to read the parent Opportunity and every returned parent field in user mode. A nonexistent or inaccessible parent returns the same safe 404. Malformed IDs/limits return 400. The response is `no-store`.
- The evidence object remains private and has no direct integration CRUD. A tightly scoped system-mode helper can read only rows for the already-authorized parent, newest first, maximum 50.
- No REST write, delete, approval bypass, arbitrary SOQL, arbitrary object proxy, metadata mutation, credential exchange or user administration is exposed by the facade.
- Standard Salesforce REST remains the create/patch/query/describe lane and native Salesforce approval REST remains the approval lane. Their caller permissions and explicit task authorization remain mandatory.

## Personas and permissions

- `Change_Assurance_Integration`: API enabled; synthetic test create/read/update (no Delete/View All/Modify All) for Account, Contact, Lead, Opportunity, OpportunityContactRole, Case, Task, Campaign and CampaignMember; Convert Leads plus its required Edit Tasks prerequisite; facade access. No direct evidence CRUD, user admin, approval authority or metadata administration.
- `Strategic_Deal_UI_Runner`: existing UI grants plus API/facade transport for an explicitly assigned automation identity.
- `Strategic_Deal_API_Access`: transport-only additive set. It grants API/facade access but no object CRUD or approval authority on its own. For the approved hackathon lane it is paired with the existing Synthetic Regional VP, whose `Regional_VP_Approver` set supplies the business authority.
- `caip-vp` must resolve to the existing Synthetic Regional VP, never the administrator. It may query/describe permitted Opportunity data, act only on work items genuinely assigned to that VP, and mint an ephemeral browser session. It has no metadata administration or deal-input editing.

## User-approved hackathon administrator mode

For this dedicated Developer Edition hackathon org, the external agent may use the locally authorized `caip-dev` System Administrator CLI alias as its single authentication/session broker. This mode is intentionally capability-complete for the MVP:

- standard REST and Apex REST through `sf api request rest`;
- metadata validate/deploy/retrieve through scoped `sf project` commands;
- Apex execution and named test runs;
- a short-lived Lightning frontdoor URL from `sf org open --url-only --json`, passed directly to the browser process in memory.

This approval does not require a custom JWT module, certificate upload, a second integration user, broader permission sets, disabled IP protections or a stored Salesforce password. A one-time private `sf org login web` is required whenever Salesforce expires/revokes the CLI authorization. The agent must never print, persist or place the CLI auth file, access/refresh token, SFDX auth URL or frontdoor URL in prompts, logs, artifacts or Git.

Hackathon administrator mode is restricted to the verified `caip-dev` non-production org, synthetic demo records and scoped manifests. It is not least-privilege or production security evidence. Destructive operations, arbitrary metadata deployments, user/permission changes and approval decisions still require the authority of the calling task. The separate `caip-vp` alias preserves administrator-versus-approver separation. Because the same VP user supports both human and automated demonstrations, strict human-versus-bot attribution would still require a new automation user in a production-grade design.

## Production hardening decisions intentionally deferred

- External Client App/JWT certificate, consumer key and dedicated integration username are environment settings, never source credentials.
- A dedicated least-privilege metadata identity remains a production-hardening item. Do not add metadata administration to the general data integration permission set; the approved hackathon path uses the already-authorized administrator alias and scoped manifests.
- Do not disable IP-bound-session protection or relax IP policies merely to make a frontdoor URL work. Decide from the actual network model and compensate narrowly at client policy if needed.
- JWT bearer does not require implementing a token store in this Salesforce repository. The agent may let Salesforce CLI manage its local authorization, but must never emit verbose token or frontdoor results into logs/prompts.
