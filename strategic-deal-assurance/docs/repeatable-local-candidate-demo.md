# Repeatable local candidate demo

This demo path gives the assurance agent a real local Git candidate to analyze without deploying Salesforce metadata and without leaving the AUT repository dirty after the presentation.

## What the candidate changes

The prepared candidate edits one source file:

`force-app/main/default/customMetadata/Strategic_Discount_Rule.Default.md-meta.xml`

It changes only the strategic discount rule threshold and rule version. The current live org is not changed by these scripts. Neo can then analyze the local Git diff as a release candidate and combine that diff with live Salesforce baseline evidence, coverage, impact and assurance-report evidence.

## Prepare before the demo

From `strategic-deal-assurance`:

```powershell
.\scripts\demo-candidate\prepare-local-candidate.ps1
```

Default candidate:

- discount threshold: current source value -> `18`
- rule version: current source value -> `demo-18-candidate`

The script creates an ignored preimage archive under:

`artifacts/demo-candidate-archives/<operation-id>/`

It also writes:

`artifacts/demo-candidate-archives/current-operation-id.txt`

## Demo narration

After preparation, the AUT repo has a controlled local diff. In Neo, use **Analyze current Git candidate** and describe it as:

> Neo is analyzing the current local Salesforce candidate change, not a GitHub remote. The candidate proposes a strategic discount policy threshold change. Neo links the diff to affected policy logic, fields, tests, browser evidence, governance constraints and live Salesforce baseline receipts.

## Restore after the demo

From `strategic-deal-assurance`:

```powershell
.\scripts\demo-candidate\restore-local-candidate.ps1
```

or with an explicit operation id:

```powershell
.\scripts\demo-candidate\restore-local-candidate.ps1 -OperationId local-candidate-YYYYMMDDTHHMMSSZ-xxxxxxxx
```

The restore command copies the archived preimage back and verifies its SHA-256 hash. After restore, `git diff -- force-app/main/default/customMetadata/Strategic_Discount_Rule.Default.md-meta.xml` should be empty.

## Safety boundaries

- These scripts do not call `sf`.
- These scripts do not deploy metadata.
- These scripts do not read or write Salesforce auth state.
- The archive is local and ignored by Git.
- The candidate is intentionally a local Git working-tree change so it can be repeated for every demo.
