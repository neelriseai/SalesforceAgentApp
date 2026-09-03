# Rerun only the already-deployed first milestone tests; no deployment or record writes.
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    $raw = & sf apex run test --class-names StrategicDiscountPolicyTest --target-org caip-dev --code-coverage --wait 20 --json
    $commandExit = $LASTEXITCODE
    $response = $raw | ConvertFrom-Json
    $summary = $response.result.summary
    [pscustomobject]@{
        outcome = $summary.outcome
        testsRan = $summary.testsRan
        passing = $summary.passing
        failing = $summary.failing
        coverage = $summary.testRunCoverage
    } | ConvertTo-Json
    if ($commandExit -ne 0 -or $summary.outcome -ne 'Passed') {
        throw 'Milestone 1 tests failed or did not complete. Inspect the CLI result locally; do not publish identifiers or credentials.'
    }
} finally {
    Pop-Location
}
