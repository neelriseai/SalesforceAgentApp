param(
    [string]$OperationId,
    [switch]$KeepCurrentMarker
)

$ErrorActionPreference = "Stop"

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$archiveRoot = Join-Path $projectRoot "artifacts\demo-candidate-archives"
$currentMarker = Join-Path $archiveRoot "current-operation-id.txt"

if ([string]::IsNullOrWhiteSpace($OperationId)) {
    if (-not (Test-Path -LiteralPath $currentMarker)) {
        throw "No -OperationId provided and no current-operation-id.txt marker exists."
    }
    $OperationId = (Get-Content -LiteralPath $currentMarker -Raw).Trim()
}

if ($OperationId -notmatch '^local-candidate-\d{8}T\d{6}Z-[0-9a-f]{8}$') {
    throw "Invalid operation id shape: $OperationId"
}

$archiveDir = Join-Path $archiveRoot $OperationId
$manifestPath = Join-Path $archiveDir "manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath)) {
    throw "Manifest not found for operation: $OperationId"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$repoRoot = (Resolve-Path (Join-Path $projectRoot "..")).Path
$targetPath = Join-Path $repoRoot ($manifest.target -replace "/", [System.IO.Path]::DirectorySeparatorChar)
$archiveFile = Join-Path $projectRoot ($manifest.before.archivePath -replace "/", [System.IO.Path]::DirectorySeparatorChar)

if (-not (Test-Path -LiteralPath $archiveFile)) {
    throw "Archived preimage missing: $($manifest.before.archivePath)"
}

Copy-Item -LiteralPath $archiveFile -Destination $targetPath -Force
$restoredSha = Get-Sha256 $targetPath
if ($restoredSha -ne $manifest.before.sha256) {
    throw "Restore verification failed for $($manifest.target): expected $($manifest.before.sha256), got $restoredSha"
}

if (-not $KeepCurrentMarker -and (Test-Path -LiteralPath $currentMarker)) {
    Remove-Item -LiteralPath $currentMarker
}

Write-Host "Restored local demo candidate: $OperationId"
Write-Host "Restored $($manifest.target)"
Write-Host "Verified SHA-256: $restoredSha"
