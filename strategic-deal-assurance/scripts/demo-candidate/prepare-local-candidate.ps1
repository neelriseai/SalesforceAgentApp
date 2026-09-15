param(
    [decimal]$CandidateDiscountThreshold = 18,
    [string]$CandidateRuleVersion = "demo-18-candidate",
    [switch]$AllowExistingTargetDiff
)

$ErrorActionPreference = "Stop"

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function New-OperationId {
    $bytes = [byte[]]::new(4)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
    $suffix = -join ($bytes | ForEach-Object { $_.ToString("x2") })
    return "local-candidate-{0}-{1}" -f (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ"), $suffix
}

function Replace-Single([string]$Text, [string]$Pattern, [string]$Replacement, [string]$Label) {
    $matches = [regex]::Matches($Text, $Pattern)
    if ($matches.Count -ne 1) {
        throw "Expected exactly one $Label entry but found $($matches.Count)."
    }
    return [regex]::Replace($Text, $Pattern, $Replacement, 1)
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$repoRoot = (Resolve-Path (Join-Path $projectRoot "..")).Path
$relativeTarget = "strategic-deal-assurance/force-app/main/default/customMetadata/Strategic_Discount_Rule.Default.md-meta.xml"
$targetPath = Join-Path $repoRoot ($relativeTarget -replace "/", [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $targetPath)) {
    throw "Candidate target not found: $relativeTarget"
}

if (-not $AllowExistingTargetDiff) {
    & git -C $repoRoot diff --quiet -- $relativeTarget
    if ($LASTEXITCODE -ne 0) {
        throw "Refusing to prepare candidate because $relativeTarget already has unstaged changes. Restore or commit those first, or pass -AllowExistingTargetDiff intentionally."
    }
    & git -C $repoRoot diff --cached --quiet -- $relativeTarget
    if ($LASTEXITCODE -ne 0) {
        throw "Refusing to prepare candidate because $relativeTarget already has staged changes. Restore or commit those first, or pass -AllowExistingTargetDiff intentionally."
    }
}

$beforeText = Get-Content -LiteralPath $targetPath -Raw
$beforeSha = Get-Sha256 $targetPath
$discountPattern = '(<values><field>Discount_Threshold_Percent__c</field><value xsi:type="xsd:double">)([^<]+)(</value></values>)'
$versionPattern = '(<values><field>Rule_Version__c</field><value xsi:type="xsd:string">)([^<]+)(</value></values>)'
$discountMatch = [regex]::Match($beforeText, $discountPattern)
$versionMatch = [regex]::Match($beforeText, $versionPattern)
if (-not $discountMatch.Success -or -not $versionMatch.Success) {
    throw "Target does not contain the expected Strategic_Discount_Rule fields."
}

$operationId = New-OperationId
$archiveRoot = Join-Path $projectRoot "artifacts\demo-candidate-archives"
$archiveDir = Join-Path $archiveRoot $operationId
$archiveFile = Join-Path $archiveDir ($relativeTarget -replace "/", [System.IO.Path]::DirectorySeparatorChar)
New-Item -ItemType Directory -Force -Path (Split-Path $archiveFile -Parent) | Out-Null
Copy-Item -LiteralPath $targetPath -Destination $archiveFile

$candidateText = Replace-Single $beforeText $discountPattern "`${1}$CandidateDiscountThreshold`${3}" "discount threshold"
$candidateText = Replace-Single $candidateText $versionPattern "`${1}$CandidateRuleVersion`${3}" "rule version"
Set-Content -LiteralPath $targetPath -Value $candidateText -NoNewline -Encoding utf8
$afterSha = Get-Sha256 $targetPath

$head = (& git -C $repoRoot rev-parse HEAD 2>$null)
$manifest = [ordered]@{
    operationId = $operationId
    createdAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    purpose = "repeatable-local-demo-candidate"
    repoHead = $head
    target = $relativeTarget
    before = [ordered]@{
        sha256 = $beforeSha
        discountThreshold = [decimal]$discountMatch.Groups[2].Value
        ruleVersion = $versionMatch.Groups[2].Value
        archivePath = ($archiveFile.Substring($projectRoot.Length + 1) -replace "\\", "/")
    }
    candidate = [ordered]@{
        sha256 = $afterSha
        discountThreshold = $CandidateDiscountThreshold
        ruleVersion = $CandidateRuleVersion
    }
    restoreCommand = ".\scripts\demo-candidate\restore-local-candidate.ps1 -OperationId $operationId"
}
$manifestPath = Join-Path $archiveDir "manifest.json"
$manifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $manifestPath -Encoding utf8
Set-Content -LiteralPath (Join-Path $archiveRoot "current-operation-id.txt") -Value $operationId -Encoding ascii

Write-Host "Prepared local demo candidate: $operationId"
Write-Host "Changed $relativeTarget"
Write-Host "Discount threshold: $($discountMatch.Groups[2].Value) -> $CandidateDiscountThreshold"
Write-Host "Rule version: $($versionMatch.Groups[2].Value) -> $CandidateRuleVersion"
Write-Host "Restore with: .\scripts\demo-candidate\restore-local-candidate.ps1 -OperationId $operationId"
