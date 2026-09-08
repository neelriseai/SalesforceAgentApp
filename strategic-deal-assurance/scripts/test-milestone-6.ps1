$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    $orgResult = (& sf data query --query 'SELECT Id, OrganizationType FROM Organization' --target-org caip-dev --json) | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0) { throw 'Cannot verify org.' }
    $org = $orgResult.result.records[0]
    $binding = Get-Content '.sf/demo-data-binding.json' -Raw | ConvertFrom-Json
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $fingerprint = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes([string]$org.Id)))).Replace('-','').ToLowerInvariant() } finally { $sha.Dispose() }
    if ($org.OrganizationType -ne 'Developer Edition' -or $binding.alias -ne 'caip-dev' -or $binding.fingerprint -ne $fingerprint) { throw 'Dedicated demo org binding mismatch.' }
    $raw = & sf apex run test --class-names DemoBusinessRulesTest StrategicDiscountPolicyTest StrategicDiscountFlowTest StrategicDealPolicyControllerTest StrategicDealApprovalControllerTest StrategicDealAgentApiTest --target-org caip-dev --code-coverage --wait 20 --json
    $code = $LASTEXITCODE
    $response = $raw | ConvertFrom-Json
    $summary = $response.result.summary
    $summary | Select-Object outcome,testsRan,passing,failing,testRunCoverage | ConvertTo-Json
    if ($code -ne 0 -or $summary.outcome -ne 'Passed') {
        $response.result.tests | Where-Object {$_.Outcome -ne 'Pass'} | Select-Object MethodName,Message,StackTrace | ConvertTo-Json
        throw 'Rule regression failed or timed out; do not claim completion.'
    }
} finally { Pop-Location }
