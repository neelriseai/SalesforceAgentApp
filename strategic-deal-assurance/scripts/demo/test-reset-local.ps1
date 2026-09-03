$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'reset-baseline.ps1'
$plan = Get-Content (Join-Path $PSScriptRoot '../../data/baseline-15-plan.json') -Raw | ConvertFrom-Json
$tokens = $null; $parseErrors = $null
[Management.Automation.Language.Parser]::ParseFile($runner, [ref]$tokens, [ref]$parseErrors) | Out-Null
if ($parseErrors.Count -ne 0) { throw 'PowerShell parse failed' }
if ($plan.cases.Count -ne 7 -or $plan.currency -ne 'USD' -or $plan.discountThreshold -ne 15 -or $plan.amountThreshold -ne 50000000) { throw 'Unexpected baseline plan' }
$expected = @{
    'non-strategic'='Not Required'; 'amount-exact'='Not Required'; 'discount-exact'='Not Required'
    'discount-above'='Pending Regional VP'; 'missing-approver'='Configuration Error'
    'null-discount'='Not Required'; 'null-amount'='Not Required'
}
foreach ($case in $plan.cases) {
    if ($case.expectedStatus -ne $expected[$case.key]) { throw 'Independent status oracle mismatch' }
}
$above = $plan.cases | Where-Object key -eq 'discount-above'
if ($above.amount -ne 50000000.01 -or $above.discount -ne 15.01 -or !$above.approverPresent) { throw 'Above-boundary case differs' }
if (($plan.cases | Where-Object key -eq 'amount-exact').amount -ne 50000000) { throw 'Exact amount differs' }
if (($plan.cases | Where-Object key -eq 'discount-exact').discount -ne 15) { throw 'Exact discount differs' }
if ($null -ne ($plan.cases | Where-Object key -eq 'null-amount').amount -or $null -ne ($plan.cases | Where-Object key -eq 'null-discount').discount) { throw 'Null cases differ' }
# These checks stop before any CLI call and require no org authorization.
foreach ($mode in @('Apply','Rehearse')) {
    $blocked = $false
    try { & $runner -Mode $mode | Out-Null } catch { $blocked = $_.Exception.Message -match 'require -ConfirmDataReset' }
    if (!$blocked) { throw 'Write confirmation guard did not block' }
}
[pscustomobject]@{outcome='Passed';planCases=7;parseErrors=0;writeGuards=2;liveOrgCalls=0} | ConvertTo-Json
