# Milestone 9: governed external-agent API source

Date: 2026-09-08. Status: **deployed; hackathon-administrator API/metadata/browser transport validated; dedicated identity pending**.

## Implemented source

- Read-only `StrategicDealAgentApi` at `GET /services/apexrest/sda/v1/policy/{OpportunityId}?limit=1..50`.
- Parent Opportunity query explicitly uses user mode. Only after it succeeds, a private helper reads at most 50 evidence rows for that exact parent in system mode. Uniform inaccessible/missing response; invalid input response; no-store header; no write/approval/metadata methods.
- `StrategicDealAgentApiTest` covers authorized history, bound limit/newest state, direct-evidence denial, parent denial and malformed requests.
- `Change_Assurance_Integration` source covers nine CRM object/relationship types without Delete/View All/Modify All, adds facade and lead-conversion permissions, and retains no direct evidence or metadata administration.
- `Strategic_Deal_UI_Runner` source adds API/facade transport. New `Strategic_Deal_API_Access` is transport-only for a separately approved future automation persona.
- Existing 554 SYN-MM records are reused. Six external API cases specify the live fixture/read/negative checks; no new record insert is needed to begin.

The first live check-only validation found Salesforce's declared `ConvertLeads` dependency on `EditTask`; no metadata was applied. Source was corrected with that narrow prerequisite before the validation was repeated.

## Local verification

- Agent API specification/security/graph checks: 4/4 passed.
- Locator checks: 3/3 passed. Existing manual suite: 42 cases / 232 steps fresh and 3/3 tests passed. Visibility checks: 3/3 passed.
- Catalog/security/link checks: 7/7 passed. Generated discovery snapshot: 1,012 nodes and 3,700 edges. The exact current source snapshot is recorded in the generated graph/index; this historical evidence does not duplicate a self-referential generated hash.
- `git diff --check` passed. Screenshot source material is ignored because it includes private chat/account context; its sanitized decisions are in the requirement/provisioning guide.

These static checks do not replace Apex compilation, Salesforce permission validation or a real OAuth identity E2E.

## Live validation

- The owner privately completed `sf org login web`; `caip-dev` then reported Connected against the bound Developer Edition org.
- All three affected permission sets had zero assignees before deployment, so changing them broadened no existing user's effective permission assignment.
- First check-only validation found the documented `ConvertLeads` -> `EditTask` prerequisite. After adding it and aligning the existing permission-contract test with the five-persona design, the final check-only validation passed 50/50 tests.
- The exact scoped milestone manifest deployed successfully: three Apex classes (including the updated contract test) and three permission sets. Deployment again passed 50/50 tests with zero failures; `StrategicDealAgentApi` coverage was 100% (74/74 locations).
- A read-only CLI REST call to the deployed custom endpoint for exact fixture `SYN-MM-O02 Deal` returned HTTP 200, `Pending Regional VP`, one bounded history row and rule version `baseline-15`.
- `sf org open` successfully resolved the Lightning-enabled custom domain and launched the workbench. A second `--url-only --json` check parsed an HTTPS session URL entirely in memory, printed no credential and persisted nothing. This proves CLI-backed browser session creation; it is not a full locator-healing browser-suite run.
- Check-only and real deployments prove scoped Metadata API access through the approved administrator alias. No IP/session protection was relaxed and no JWT certificate, password store, second automation user or External Client App was required.
- The existing Synthetic Regional VP was assigned transport-only `Strategic_Deal_API_Access` and privately authorized as `caip-vp` through Chrome Incognito. Sanitized verification proved exact VP identity, the `Regional_VP_Approver` + transport pairing, HTTP-200 Opportunity describe/query and an HTTPS browser credential created and discarded in memory. No approval decision was submitted during transport verification.

## Live blocker and explicit omissions

The original CLI authorization was expired, and the first reauthorization attempt timed out at Salesforce login. The owner then completed a second private login successfully. Automation did not enter or record credentials.

Remaining work is optional production hardening and full suite execution: provision a dedicated data-integration identity, execute API-01–06 as that persona, and add a separate VP automation user only if strict human-versus-bot attribution is required. Administrator and VP identities are already separate (`caip-dev` versus `caip-vp`).
