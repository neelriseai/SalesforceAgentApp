[CmdletBinding()]
param(
    [ValidateSet('Preview','Apply','Verify','Rehearse')][string]$Mode='Preview',
    [switch]$ConfirmDataInsert
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if ($Mode -in @('Apply','Rehearse') -and !$ConfirmDataInsert) { throw 'Write modes require -ConfirmDataInsert.' }
$projectRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Push-Location $projectRoot
$mutex=[Threading.Mutex]::new($false,'Local\SDA_DemoData_caip_dev')
$held=$false
try {
    try {$held=$mutex.WaitOne(0)} catch [Threading.AbandonedMutexException] {$held=$true}
    if (!$held) {throw 'Another local demo-data run is active.'}
    function Invoke-Sf([string[]]$Arguments) {
        $raw=& sf @Arguments --target-org caip-dev --json
        $exitCode=$LASTEXITCODE
        $result=($raw -join "`n") | ConvertFrom-Json
        if ($exitCode -ne 0 -or $result.status -ne 0) {
            $detail=[string]$result.message
            if ($null -ne $result.PSObject.Properties['result']) {
                foreach ($field in @('compileProblem','exceptionMessage')) {
                    if ($null -ne $result.result.PSObject.Properties[$field]) {$detail+=' '+[string]$result.result.$field}
                }
            }
            $detail=$detail -replace '\b[a-zA-Z0-9]{15,18}\b','[identifier]' -replace '[\w.+-]+@[\w.-]+','[email]'
            throw ('Salesforce command failed. '+$detail)
        }
        return $result
    }
    $org=(Invoke-Sf @('data','query','--query','SELECT Id, OrganizationType FROM Organization')).result.records[0]
    if ($org.OrganizationType -ne 'Developer Edition') {throw 'Dedicated Developer Edition only.'}
    $hasher=[Security.Cryptography.SHA256]::Create()
    try {$fingerprint=([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes([string]$org.Id)))).Replace('-','').ToLowerInvariant()} finally {$hasher.Dispose()}
    $binding=Get-Content '.sf/demo-data-binding.json' -Raw | ConvertFrom-Json
    if ($binding.alias -ne 'caip-dev' -or $binding.fingerprint -ne $fingerprint) {throw 'Existing demo org binding does not match.'}
    $planPath='data/visibility-expansion-plan.json'
    $plan=Get-Content $planPath -Raw | ConvertFrom-Json
    if ($plan.dataset -ne 'SDA-VISIBILITY-EXPANSION-v1' -or $plan.expectedBusinessRows -ne 186 -or $plan.currency -ne 'USD') {throw 'Unexpected synthetic data plan.'}
    # Compress only the checked-in synthetic plan to fit anonymous Apex's source-size limit.
    Add-Type -AssemblyName System.IO.Compression
    $stream=[IO.MemoryStream]::new()
    $zip=[IO.Compression.ZipArchive]::new($stream,[IO.Compression.ZipArchiveMode]::Create,$true)
    try {
        $entry=$zip.CreateEntry('plan.json')
        $writer=[IO.StreamWriter]::new($entry.Open(),[Text.UTF8Encoding]::new($false))
        try {$writer.Write(($plan | ConvertTo-Json -Depth 12 -Compress))} finally {$writer.Dispose()}
    } finally {$zip.Dispose()}
    try {$payload=[Convert]::ToBase64String($stream.ToArray())} finally {$stream.Dispose()}
    $templatePath=Join-Path $PSScriptRoot 'visibility-expansion.apex.template'
    $sharedSource=Get-Content (Join-Path $PSScriptRoot 'multi-module.apex.template') -Raw
    $boundary=$sharedSource.IndexOf("String mode='")
    if ($boundary -lt 1) {throw 'Shared helper boundary missing.'}
    $shared=$sharedSource.Substring(0,$boundary)
    if (!$shared.Contains('public with sharing class CrossModuleFixtures')) {throw 'Shared create-only helper missing.'}
    $request=($shared+(Get-Content $templatePath -Raw)).Replace('__PLAN_BASE64__',$payload).Replace('__MODE__',$Mode).Replace('__ORG_FINGERPRINT__',$fingerprint)
    if ($request.Length -gt 32000) {throw 'Generated anonymous Apex exceeds the conservative source-size budget.'}
    $runId=(Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,8)
    $folder=Join-Path $projectRoot ('artifacts/visibility-expansion/'+$runId)
    [IO.Directory]::CreateDirectory($folder) | Out-Null
    $requestPath=Join-Path $folder 'request.apex'
    [IO.File]::WriteAllText($requestPath,$request)
    $response=Invoke-Sf @('apex','run','--file',$requestPath)
    if (!$response.result.success) {throw 'Anonymous Apex did not succeed; no success claimed.'}
    $logs=[Net.WebUtility]::HtmlDecode($response.result.logs)
    $match=[regex]::Match($logs,'\|USER_DEBUG\|[^\r\n]*\|EXPANSION_RESULT\|(\{[^\r\n]+\})')
    if (!$match.Success) {throw 'No verification receipt. Run Verify before retrying any write.'}
    $result=$match.Groups[1].Value | ConvertFrom-Json
    $report=[ordered]@{runId=$runId;endedAtUtc=(Get-Date).ToUniversalTime().ToString('o');planSha256=(Get-FileHash $planPath -Algorithm SHA256).Hash.ToLowerInvariant();runnerSha256=(Get-FileHash $templatePath -Algorithm SHA256).Hash.ToLowerInvariant();sharedHelperSha256=(Get-FileHash (Join-Path $PSScriptRoot 'multi-module.apex.template') -Algorithm SHA256).Hash.ToLowerInvariant();result=$result}
    $json=$report | ConvertTo-Json -Depth 12
    [IO.File]::WriteAllText((Join-Path $folder 'result.json'),$json)
    $json
} finally {
    if ($held) {$mutex.ReleaseMutex()}
    $mutex.Dispose()
    Pop-Location
}
