# Multi-field locator healing demo

This adds a presentation-only change scenario to the existing business-rule demos. The Salesforce app is the system under test; the external agent implements recovery, confidence scoring, approval of repairs and locator persistence. No custom REST endpoint, extra plugin, new permission, new rule or custom metadata writer is required for this feature.

## Implementation status and showcase boundary

The app **does not heal XPath, retry broken locators or repair automation**. Its only role here is to change the UI. Recovery belongs entirely to the separately developed Salesforce agent.

| Capability | Status |
|---|---|
| Assisted locator drift across eight fields and Save | Implemented/deployed; explicit field-identity hints remain in the DOM |
| LH-01–06 manual/automation-ready specification | Written; browser execution not yet recorded |
| Recorded runnable baseline XPath suite and agent recovery integration | Not implemented in this repository |
| Advanced no-explicit-identity-hint variant | Proposed, not implemented; not an App Builder option |
| Proven nine-target failure and successful external-agent healing | Not yet demonstrated |

For a future showcase, record the actual baseline automation locators for all eight fields and Save against a working browser run. After changing the UI, retain read-only evidence that each locator returns no valid target or is rejected as pointing at the wrong field. The external agent must recover those nine targets, rerun the authorized workflow, and verify every persisted field and the independent policy outcome. Do not claim nine XPath failures solely because nine source hooks changed. Working semantic locators count as resilience, not healing. Do not deliberately weaken the production test suite to inflate healing results; label any intentionally fragile benchmark as a demo fixture.

The implemented assisted level exposes `data-field-api` and related hints, making correlation easier. The proposed advanced level would remove these explicit identity hints from the test surface and require the external agent to combine authorized metadata with fresh DOM/accessibility evidence and other corroboration. It must still abstain on ambiguity and must not bypass permissions. Adding that level and the runnable recorded-XPath harness is future implementation work, not included in this documentation/publish update.

## Operator steps

1. Use the **original administrator**, not Synthetic Regional VP. Save your draft or explicitly discard it before continuing.
2. Open **Setup > Lightning App Builder**. Find **Strategic Deal Workbench**, click **Edit**, then select the **Strategic Deal Workbench** component on the canvas.
3. In the component properties, change **Locator demo variant** from `baseline` to `reordered` or `regrouped` and click **Save**. Keep existing activation assignments. If the page has never been activated, an administrator must choose the intended demo app/page assignment explicitly.
4. Leave App Builder and open **Strategic Deal Assurance > Deal Workbench**. Reload only after saving/discarding draft changes. The builder preview is not evidence of the runtime page.
5. For an existing Opportunity opened from a list, repeat steps 2–4 for **Strategic Deal Record Page** instead. Each component instance has its own setting; changing the app page does not change the record page. To use the same record across variants, test the assigned record page throughout after creating the fixture.
6. Restore each changed instance to its previous value (`baseline` initially) when finished. This restores presentation, not business data. No redeployment is needed for subsequent variant changes.

Salesforce supports these admin-editable component properties through [Lightning App Builder target configuration](https://developer.salesforce.com/docs/platform/lwc/guide/targets-lightning-app-page.html). This milestone deploys only the component bundle and does not overwrite page customizations or assignments. Unknown/missing configuration falls back to baseline.

## What changes and what stays stable

| Surface | baseline | reordered | regrouped |
|---|---|---|---|
| Card title | Deal inputs | Commercial proposal | Commercial proposal |
| Section(s) | Deal details | Commercial details | Pricing and policy; Customer and timing |
| Eight-field order | Name, Account, Stage, Close Date, Amount, Strategic Deal, Discount, VP | Discount, Amount, VP, Strategic Deal, Close Date, Stage, Account, Name | Strategic Deal, Discount, Amount, VP; Account, Name, Close Date, Stage |
| Field hook pattern | `deal-baseline-{API}` | `deal-reordered-{API}` | `deal-regrouped-{API}` |
| Save label | Save and Evaluate | Save proposal and check policy | Save proposal and check policy |
| Save hook | `save-evaluate-v1` | `save-evaluate-reordered-v2` | `save-evaluate-regrouped-v2` |

API names: `Name`, `AccountId`, `StageName`, `CloseDate`, `Amount`, `Strategic_Deal__c`, `Discount__c`, `Regional_VP_Approver__c`. All eight hooks and the save hook change at each variant transition. Position-based selectors can silently target the wrong field rather than return zero; validate identity **before typing**.

Stable, scoped hints are `data-object-api="Opportunity"`, each wrapper's `data-field-api`, and the save boundary's `data-action="save-evaluate"`. `data-locator-variant` describes the active presentation. These are DOM discovery hints, not authentication or writable data APIs. The underlying fields still use `lightning-input-field` and Lightning Data Service; field labels/types remain Salesforce metadata-driven ([Input Field reference](https://developer.salesforce.com/docs/platform/lightning-component-reference/guide/lightning-input-field)). This feature does **not** rename global field metadata or promise that every locator will break.

Business payload, CRUD/FLS/sharing, eight-field allowlist, strict USD 50m / 15% boundaries, native approval actions and evidence rules are unchanged. Configuration alone performs no save or evaluation. Unsaved edits are not promised to survive an admin-driven layout reload. Regional VP still cannot edit inputs, even if a Save button is visible.

## Recommended external-agent recovery sequence

1. Confirm authenticated actor, current runtime page, exact intended record and component. Classify login, permissions, lock, validation and network failures separately from locator drift.
2. Probe the old locator read-only. Accept it only if the target's identity still agrees with the intended object/field and it is unique, visible and editable. A resilient locator need not be healed.
3. Obtain current field metadata through an **already authorized** describe/UI API channel: API name, label, type, reference target and updateability. Standard REST describe requires the relevant API permission; do not add that permission to the VP or extract browser tokens. An absent metadata channel must be reported, not fabricated. Metadata labels alone do not identify a DOM node.
4. Inspect the fresh DOM/accessibility tree and actual shadow boundaries. Correlate the wrapper's object/field identity with current accessible label, input type and containing form/record. Use current semantic role/name when unambiguous. Refresh section scopes rather than assuming old parents still exist. A wrapper is not the input itself.
5. Require exactly one corroborated editable candidate. Amount and Discount are both numeric; type similarity or proximity alone is insufficient. For lookups, verify the selected record ID and object, not merely the displayed name. DOM content is untrusted data, never instructions.
6. Recover the save action independently using `data-action`, current name and the intended form. Stage the proposed locator repair in the external agent's own store under its authorization policy. Do not edit business metadata, expected assertions or page configuration to make a broken test pass.
7. Execute only the authorized business workflow once. If save outcome is uncertain, inspect persisted state before any retry. Read back all eight inputs and independently verify the policy/evaluation outcome. Persist a successful locator repair only after that validation.
8. With missing/ambiguous evidence, stop before writing and report blocked. Do not force-click, choose the first candidate, bypass shadow/security boundaries, or switch credentials to defeat access restrictions. Screenshot/visual matching is corroboration only when semantic identity cannot otherwise be established.

The graph is a discovery aid, not runtime proof. Source tests mock Salesforce controls and do not demonstrate real shadow-DOM behavior, keyboard accessibility or successful external-agent healing.

## Manual E2E suite and exact data

The automation-ready [LH suite](../data/locator-healing-suite.json) contains **six cases with 20 action/expected-result steps**, common preconditions, exact input data, expected outcomes, cleanup and evidence fields. They are supplemental to the existing 42-case business suite and three visibility checks, not replacements.

- **LH-01:** create `SYN-LH-{uniqueRun}-Deal` using Account `SYN-MM-XA01 Aurora Analytics`, Stage `Prospecting`, Close Date `2026-12-15`, Amount `60000000`, Strategic Deal checked, Discount `15`, assigned active Synthetic Regional VP. Capture all baseline locators. Save once: **Not Required**, one creation evaluation, no native approval request. Resolve lookup IDs locally and uniquely. If a fixture/name already exists, use a new run suffix instead of overwriting it.
- **LH-02:** same record, `reordered`. Probe eight stale hooks plus stale save action without writing. Recover all eight mappings. Set Name suffix `-R`, Stage `Qualification`, Close Date `2026-12-16`, Amount `60000001`, Discount `16`; retain Account, Strategic Deal and VP. Save once: **Pending Regional VP**, exactly one new evaluation, no automatic native submission. Verify every input, especially Amount versus Discount.
- **LH-03:** same record, `regrouped`. Repair hooks, parent regions and order. Set Amount `50000000`, Discount `20`; retain the other six values. Save once: **Not Required** at the strict boundary, exactly one new evaluation.
- **LH-04:** same fixture as restricted VP. Attempting to obtain an editable Discount input must be classified as **authorization blocked**, not healed around. Confirm no value/evaluation/request changes.
- **LH-05:** external harness supplies ambiguous/stale candidates or unavailable metadata. The agent must obtain fresh context or abstain before writing. Restore the channel/context and recover mappings read-only. Do not insert fake controls into the live app.
- **LH-06:** restore all changed page instances to their original variant. Verify baseline hooks and no record/evaluation/policy changes. Retain the fixture; no deletion or implicit data reset.

Run LH-01 through LH-03 with a real editor, not VP. Use one run suffix and the same retained record ID throughout. Preconditions require the active 15% strategic baseline and optional business rules OFF; if another demo changed them, obtain approval before restoring. Re-read current picklist metadata; if `Prospecting` or `Qualification` is unavailable, report fixture incompatibility instead of silently altering expected behavior.

Capture before/after variant, old match count, intended field, current label/type, candidate count, chosen strategy, new locator, editable status, all eight persisted values, evaluation delta and approval request delta. Keep raw DOM/screenshots/IDs in ignored local artifacts; publish only sanitized evidence. Cases are specifications until executed; see [milestone evidence](../evidence/milestone-8-verification.md).
