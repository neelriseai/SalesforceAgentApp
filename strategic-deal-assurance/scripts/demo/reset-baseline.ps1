[CmdletBinding()]
param(
    [ValidateSet('Preview', 'Apply', 'Verify', 'Rehearse')][string]$Mode = 'Preview',
    [switch]$ConfirmDataReset,
    [switch]$BindDemoOrg
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Push-Location $projectRoot
$runLock = [Threading.Mutex]::new($false, 'Local\SDA_DemoData_caip_dev')
$lockHeld = $false
try {
    try { $lockHeld = $runLock.WaitOne(0) } catch [Threading.AbandonedMutexException] { $lockHeld = $true }
    if (!$lockHeld) { throw 'Another local demo-data run is active. Wait for it to finish.' }
    function Invoke-SfJson([string[]]$Arguments) {
        $raw = & sf @Arguments --target-org caip-dev --json
        $code = $LASTEXITCODE
        try { $response = ($raw -join "`n") | ConvertFrom-Json } catch { throw 'Salesforce returned no usable JSON. Check the CLI connection locally.' }
        if ($code -ne 0 -or $response.status -ne 0) { throw 'Salesforce command failed. No success claimed; inspect the CLI locally without sharing credentials or raw logs.' }
        return $response
    }
    function Get-Sha256([string]$Value) {
        $hasher = [Security.Cryptography.SHA256]::Create()
        try { return ([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($Value)))).Replace('-', '').ToLowerInvariant() }
        finally { $hasher.Dispose() }
    }
    if ($Mode -in @('Apply', 'Rehearse') -and !$ConfirmDataReset) {
        throw 'Write modes require -ConfirmDataReset. Preview and Verify make no record changes.'
    }
    $org = (Invoke-SfJson @('data','query','--query','SELECT Id, OrganizationType, IsSandbox FROM Organization')).result.records[0]
    if ($org.OrganizationType -ne 'Developer Edition') { throw 'This script is restricted to the dedicated Developer Edition, not production or other org types.' }
    $fingerprint = Get-Sha256 ([string]$org.Id)
    $bindingPath = Join-Path $projectRoot '.sf/demo-data-binding.json'
    if (!(Test-Path -LiteralPath $bindingPath)) {
        if (!$BindDemoOrg -or $Mode -ne 'Preview') { throw 'First run Preview -BindDemoOrg after verifying caip-dev is the intended demo org.' }
        [IO.Directory]::CreateDirectory((Split-Path $bindingPath)) | Out-Null
        [IO.File]::WriteAllText($bindingPath, (@{alias='caip-dev';fingerprint=$fingerprint} | ConvertTo-Json))
    }
    $binding = Get-Content -LiteralPath $bindingPath -Raw | ConvertFrom-Json
    if ($binding.alias -ne 'caip-dev' -or $binding.fingerprint -ne $fingerprint) { throw 'Org binding mismatch. Do not reset: caip-dev no longer matches the locally bound demo org.' }
    $planPath = Join-Path $projectRoot 'data/baseline-15-plan.json'
    $plan = Get-Content -LiteralPath $planPath -Raw | ConvertFrom-Json
    if ($plan.dataset -ne 'SDA-DEMO-BASELINE-15-v1' -or $plan.currency -ne 'USD' -or $plan.cases.Count -ne 7) { throw 'Unexpected data plan. Review before use.' }
    if (@($plan.cases.name | Sort-Object -Unique).Count -ne 7 -or @($plan.cases.key | Sort-Object -Unique).Count -ne 7) { throw 'Duplicate fixture keys or names.' }
    $planJson = $plan | ConvertTo-Json -Depth 10 -Compress
    $planBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($planJson))
    $templatePath = Join-Path $PSScriptRoot 'reset-baseline.apex.template'
    $apex = (Get-Content -LiteralPath $templatePath -Raw).Replace('__PLAN_BASE64__', $planBase64).Replace('__MODE__', $Mode).Replace('__ORG_FINGERPRINT__', $fingerprint)
    $runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8)
    $runDirectory = Join-Path $projectRoot ('artifacts/demo-data/' + $runId)
    [IO.Directory]::CreateDirectory($runDirectory) | Out-Null
    $apexPath = Join-Path $runDirectory 'request.apex'
    # Generated request contains only the synthetic plan and a non-secret org fingerprint.
    [IO.File]::WriteAllText($apexPath, $apex)
    $started = (Get-Date).ToUniversalTime().ToString('o')
    $response = Invoke-SfJson @('apex','run','--file',$apexPath)
    if (!$response.result.success) { throw 'Demo-data transaction failed and was rolled back. No successful reset is claimed.' }
    $decodedLogs = [Net.WebUtility]::HtmlDecode($response.result.logs)
    $match = [regex]::Match($decodedLogs, '\|USER_DEBUG\|[^\r\n]*\|DEMO_DATA_RESULT\|(\{[^\r\n]+\})')
    if (!$match.Success) { throw 'Transaction returned no verification receipt. Inspect current state with Verify before retrying.' }
    $result = $match.Groups[1].Value | ConvertFrom-Json
    $report = [ordered]@{
        runId=$runId; mode=$Mode; requirement='BR-STRATEGIC-DISCOUNT'; profile='DATA_CHECKPOINT'; simulation=($Mode -eq 'Rehearse')
        orgFingerprint=('sha256:'+$fingerprint); startedAtUtc=$started; endedAtUtc=(Get-Date).ToUniversalTime().ToString('o')
        planSha256=(Get-FileHash -LiteralPath $planPath -Algorithm SHA256).Hash.ToLowerInvariant()
        runnerSha256=(Get-FileHash -LiteralPath $templatePath -Algorithm SHA256).Hash.ToLowerInvariant()
        sourceCommit=$null; baselineTag=$null; cleanTaggedReleaseVerified=$false; result=$result
    }
    $reportJson = $report | ConvertTo-Json -Depth 10
    [IO.File]::WriteAllText((Join-Path $runDirectory 'result.json'), $reportJson)
    $reportJson
} finally {
    if ($lockHeld) { $runLock.ReleaseMutex() }
    $runLock.Dispose()
    Pop-Location
}
