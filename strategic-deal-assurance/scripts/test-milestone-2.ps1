$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    $raw = & sf apex run test --class-names StrategicDiscountPolicyTest StrategicDiscountFlowTest --target-org caip-dev --code-coverage --wait 20 --json
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
        throw 'Milestone 2 tests failed or timed out. Inspect details locally without publishing private org identifiers.'
    }
} finally {
    Pop-Location
}
