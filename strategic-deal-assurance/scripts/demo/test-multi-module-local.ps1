$ErrorActionPreference='Stop'
$root=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$plan=Get-Content (Join-Path $root 'data/multi-module-plan.json') -Raw | ConvertFrom-Json
$expected=@{Account=24;Contact=60;Opportunity=40;Lead=30;Case=30;Task=60;Campaign=4;CampaignMember=40;OpportunityContactRole=80}
$keys=@{operator=$true;vp=$true}
$total=0
foreach ($object in $expected.Keys) {
    $rows=@($plan.objects.$object)
    if ($rows.Count -ne $expected[$object]) {throw "Unexpected count: $object"}
    $total+=$rows.Count
    foreach ($row in $rows) {
        if ($keys.ContainsKey($row.key)) {throw 'Duplicate logical key'}
        $keys[$row.key]=$true
        foreach ($field in $row.fields.PSObject.Properties) {
            if ($field.Name -eq 'Email' -and $field.Value -notlike '*@example.invalid') {throw 'Only reserved synthetic email addresses allowed'}
            if ($field.Name -in @('Approval_Status__c','Policy_Rule_Version__c','Policy_Evaluated_At__c','Approval_Reason__c')) {throw 'Seeder must not forge derived fields'}
        }
    }
}
foreach ($object in $expected.Keys) {
    foreach ($row in $plan.objects.$object) {
        foreach ($field in $row.fields.PSObject.Properties) {
            if ($field.Value -is [string] -and $field.Value.StartsWith('@') -and !$keys.ContainsKey($field.Value.Substring(1))) {throw 'Dangling logical relationship'}
        }
    }
}
if ($total -ne 368 -or $plan.currency -ne 'USD') {throw 'Plan totals/currency differ'}
$byKey=@{}
foreach ($object in $expected.Keys) {foreach ($row in $plan.objects.$object) {$byKey[$row.key]=$row.fields}}
foreach ($row in $plan.objects.OpportunityContactRole) {
    $opportunity=$byKey[$row.fields.OpportunityId.Substring(1)]
    $contact=$byKey[$row.fields.ContactId.Substring(1)]
    if ($opportunity.AccountId -ne $contact.AccountId) {throw 'Buying-team contact belongs to the wrong Account'}
}
foreach ($deal in $plan.objects.Opportunity) {
    $roles=@($plan.objects.OpportunityContactRole | Where-Object {$_.fields.OpportunityId -eq ('@'+$deal.key)})
    if ($roles.Count -ne 2 -or @($roles | Where-Object {$_.fields.IsPrimary}).Count -ne 1) {throw 'Expected two roles and exactly one primary per deal'}
}
foreach ($case in $plan.objects.Case) {
    if ($case.fields.AccountId -ne $byKey[$case.fields.ContactId.Substring(1)].AccountId) {throw 'Case and Contact customer mismatch'}
}
$scenarios=Get-Content (Join-Path $root 'data/multi-module-use-cases.json') -Raw | ConvertFrom-Json
if ($scenarios.cases.Count -ne 10 -or @($scenarios.cases.id | Sort-Object -Unique).Count -ne 10) {throw 'Exactly ten unique use cases required'}
foreach ($scenario in $scenarios.cases) {
    if (!$scenario.objective -or !$scenario.actor -or !$scenario.cleanup -or $scenario.steps.Count -lt 5) {throw 'Incomplete manual use case'}
    foreach ($step in $scenario.steps) {if ($step.Count -ne 2 -or !$step[0] -or !$step[1]) {throw 'Each step requires action and expected result'}}
}
$outcomes=@{'Not Required'=0;'Pending Regional VP'=0;'Configuration Error'=0}
foreach ($row in $plan.objects.Opportunity) {
    $f=$row.fields
    $requires=$f.Strategic_Deal__c -and $f.Amount -gt 50000000 -and $f.Discount__c -gt 15
    $status=if (!$requires) {'Not Required'} elseif ($null -eq $f.Regional_VP_Approver__c) {'Configuration Error'} else {'Pending Regional VP'}
    $outcomes[$status]++
}
if ($outcomes['Not Required'] -ne 24 -or $outcomes['Pending Regional VP'] -ne 8 -or $outcomes['Configuration Error'] -ne 8) {throw 'Independent policy oracle differs'}
$tokens=$null; $errors=$null
[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'seed-multi-module.ps1'),[ref]$tokens,[ref]$errors) | Out-Null
if ($errors.Count -ne 0) {throw 'Runner parse errors'}
foreach ($mode in @('Apply','Rehearse')) {
    $blocked=$false
    try {& (Join-Path $PSScriptRoot 'seed-multi-module.ps1') -Mode $mode | Out-Null} catch {$blocked=$_.Exception.Message -match 'require -ConfirmDataInsert'}
    if (!$blocked) {throw 'Write confirmation guard failed'}
}
[pscustomobject]@{outcome='Passed';businessRows=$total;objects=$expected.Count;policyOracle=$outcomes;writeGuards=2;liveOrgCalls=0} | ConvertTo-Json
