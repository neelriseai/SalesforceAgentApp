$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    $raw = & sf apex run test --class-names StrategicDiscountPolicyTest StrategicDiscountFlowTest StrategicDealPolicyControllerTest StrategicDealApprovalControllerTest --target-org caip-dev --code-coverage --wait 20 --json
    $code = $LASTEXITCODE
    $response = $raw | ConvertFrom-Json
    $summary = $response.result.summary
    $summary | Select-Object outcome,testsRan,passing,failing,testRunCoverage | ConvertTo-Json
    if ($code -ne 0 -or $summary.outcome -ne 'Passed') { throw 'Approval regression tests failed or timed out. Inspect sanitized failures locally.' }
} finally { Pop-Location }
