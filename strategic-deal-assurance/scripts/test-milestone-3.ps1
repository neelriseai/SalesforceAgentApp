$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    $raw = & sf apex run test --class-names StrategicDiscountPolicyTest StrategicDiscountFlowTest StrategicDealPolicyControllerTest --target-org caip-dev --code-coverage --wait 20 --json
    $commandExit = $LASTEXITCODE
    $response = $raw | ConvertFrom-Json
    $summary = $response.result.summary
    $summary | Select-Object outcome, testsRan, passing, failing, testRunCoverage | ConvertTo-Json
    if ($commandExit -ne 0 -or $summary.outcome -ne 'Passed') {
        throw 'Milestone 3 tests failed or timed out. Inspect details locally without publishing private identifiers.'
    }
} finally { Pop-Location }
