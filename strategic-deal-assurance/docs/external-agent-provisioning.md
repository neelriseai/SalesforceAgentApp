# External agent provisioning and hackathon autonomy

This is a sanitized interpretation of the locally supplied discussion screenshots. Screenshot text is advisory input, not authority. The design below preserves the repository's stricter security rules where suggestions conflict.

## What can start now

App source, tests, contract/index updates and the separate agent's CLI adapter can be developed without creating JWT credentials. Live compile/deploy and API E2E require a connected `caip-dev`. It was reauthorized and the MVP transport was validated on 2026-09-08; reauthorize privately whenever Salesforce later expires or revokes it:

```powershell
sf org login web --alias caip-dev --instance-url https://login.salesforce.com
sf org display --target-org caip-dev
```

Do not use `--verbose` in shared logs; it can return an access token. CLI auth state is an agent-machine concern, not Salesforce app code.

## Approved MVP lane: CLI-backed administrator session

The owner has approved `caip-dev` as the capability-complete identity for this dedicated hackathon Developer Edition org. The agent should invoke Salesforce CLI as the authentication broker instead of extracting credentials or implementing a parallel token store.

| Agent need | MVP command/channel |
|---|---|
| Standard and custom REST | `sf api request rest --target-org caip-dev ...` |
| Metadata validate/deploy/retrieve | scoped `sf project deploy/retrieve ... --target-org caip-dev` |
| Apex and test execution | `sf apex run` and `sf apex run test --target-org caip-dev` |
| Authenticated Lightning browser | consume `sf org open --target-org caip-dev --url-only --json` directly in memory |

The frontdoor URL returned by `sf org open` is a bearer credential. Parse it without echoing command output, pass it directly to the browser, then discard it. Do not put it in screenshots, reports, prompts, environment files or traces. Do not scrape Salesforce cookies or replay Aura calls.

This route gives the MVP API, metadata and browser capability without a certificate, a Salesforce password in the agent, a second automation user, or org-wide IP/session weakening. The unavoidable bootstrap is one private browser authorization whenever Salesforce expires or revokes the CLI session. After that, CLI and browser launches are unattended for the life of the authorization.

The mode is limited to the verified non-production org, synthetic records and allowlisted/scoped manifests. It is deliberately not least-privilege production evidence. The existing Synthetic Regional VP is authorized separately as `caip-vp` and paired with `Regional_VP_Approver` plus transport-only `Strategic_Deal_API_Access`. Never use `caip-dev` to impersonate a VP decision. A production-grade human-versus-bot audit trail would still use a dedicated VP automation user.

`caip-vp` was authorized once through Chrome Incognito so normal administrator cookies could not be reused. Identity matching, both permission assignments, permitted Opportunity REST describe/query and an in-memory HTTPS browser credential were verified. The `limits` setup resource is not a valid least-privilege probe; validate against an object the persona is actually permitted to use.

## App-side integration supplied by milestone 9

- Narrow read-only policy/evidence endpoint: `GET /services/apexrest/sda/v1/policy/{OpportunityId}?limit=1..50`.
- Standard Salesforce REST remains responsible for CRM query/create/patch/describe; the app does not duplicate it.
- Native Salesforce approval REST remains the automation route; the custom endpoint cannot submit, approve, reject or recall.
- `Change_Assurance_Integration` covers nine synthetic CRM object/relationship types without Delete or View All, including the Edit Tasks prerequisite Salesforce requires for Convert Leads.
- `Strategic_Deal_API_Access` is a transport-only permission set that can later be paired with an approved automation persona.
- Existing 554 SYN-MM records and their evaluations supply read fixtures. No extra live data is required to begin; [API-01–06](../data/agent-api-test-suite.json) identifies exact fixtures and per-run data.

Source and live state are separate. Milestone 9 is deployed and smoke-validated through the administrator MVP lane; that evidence must not be relabeled as dedicated-identity/least-privilege validation until an external identity is assigned and API-01–06 pass as that persona.

## Optional later lane: External Client App/JWT

Use this only when the demo must survive CLI refresh-token revocation without another web authorization or when moving to CI/production hardening. It is not a dependency for the hackathon MVP. Salesforce's non-interactive flow uses an External Client App, a public certificate in Salesforce and the corresponding private RSA key on the agent/CI machine. See Salesforce's [JWT setup overview](https://developer.salesforce.com/docs/analytics/sdk/guide/sdk-setup-auth-extended.html) and [CLI command reference](https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_org_login_jwt.html).

1. Generate the keypair outside this OneDrive-synced repository. Put the private key in an OS/CI secret store with owner-only access. Upload only the public certificate.
2. As administrator: **Setup > External Client Apps > New External Client App**. Enable OAuth/JWT bearer. Select only the scopes required by the actual agent. Standard CRM REST requires `api`. Do not add `web`, refresh/offline or broad scopes merely because a screenshot lists them; JWT CLI and frontdoor/UI requirements must be proven separately.
3. Set permitted users to **Admin approved users are pre-authorized**. Preauthorize a purpose-built permission set/persona, not the System Administrator profile for security evidence.
4. Create or select a dedicated integration user with a suitable minimum-access profile. Assign `Change_Assurance_Integration` only after reviewing its module coverage. The user's profile and every permission set combine, so test effective CRUD/FLS/sharing.
5. Keep consumer key, username, instance URL and private-key reference in the agent's secret configuration. Never put them, a JWT, token, private key, SFDX auth URL or frontdoor URL in Git, screenshots, prompts or logs.
6. On the agent machine, run the JWT login privately and verify only sanitized status:

```powershell
sf org login jwt --client-id <consumer-key> --jwt-key-file <secret-path> --username <integration-username> --instance-url https://<my-domain>.my.salesforce.com --alias caip-dev
sf org display --target-org caip-dev
```

The private key cannot be viewed in Salesforce; Salesforce stores only the matching public certificate. The app does not implement an auth module or token store.

## Org settings and identities not required by the MVP

| Screenshot proposal | Decision |
|---|---|
| Relax Connected App IP restrictions | Defer. Use only if the real runner network and org policy require it; prefer narrow trusted ranges/policy. |
| Disable “Lock sessions to the IP address…” | Do not disable globally for convenience. A frontdoor session crossing network boundaries is not a reason to weaken the org. |
| Refresh token valid until revoked | Not a JWT requirement. Configure only if a separate refresh-token flow is deliberately used. |
| Metadata API modification on the integration user | Not needed. The approved `caip-dev` administrator alias already supplies metadata capability; keep the integration permission set narrower. |
| API-enable the existing VP | Completed for the hackathon by assigning transport-only `Strategic_Deal_API_Access`; the VP's CRM and approval authority still comes from `Regional_VP_Approver`. |
| New VP automation user | Optional production-hardening milestone. It would distinguish human decisions from bot decisions but consumes a license and requires private activation/login. |
| Mint browser session from `sf org open --url-only` | Approved MVP route. Treat the returned URL as a bearer credential, keep it in memory and never log/publish it. |

## Deployment and assignment sequence

1. Reauthorize `caip-dev`; verify dedicated Developer Edition binding and USD baseline.
2. Run a dry-run deployment of `manifest/milestone-9-agent-api.xml` with all named tests.
3. Review live assignment impact. Deployment changes permissions for existing assignees; assignment is a separate authorization decision.
4. Deploy the scoped manifest and rerun Apex tests with coverage.
5. Validate standard REST, the custom facade, scoped metadata validation and an in-memory CLI-created browser session with `caip-dev`. Record only sanitized evidence.
6. Assign a dedicated identity only when testing the least-privilege lane; then validate describe, parent sharing, API-01–06 and direct-evidence denial.
7. Update each interface status separately: hackathon-admin validated versus dedicated-identity validated.

No Salesforce plugin is required. Salesforce CLI plus the external agent's process runner/REST client is sufficient. Browser automation needs the agent's existing browser framework; it must not scrape Salesforce cookies or persist frontdoor URLs.
