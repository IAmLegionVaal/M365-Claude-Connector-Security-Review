$ErrorActionPreference='Stop'
$scriptFile=Join-Path $PSScriptRoot '../scripts/Get-EntraAppAssignmentPosture.ps1'
$tokens=$null; $errors=$null
[void][System.Management.Automation.Language.Parser]::ParseFile($scriptFile,[ref]$tokens,[ref]$errors)
if ($errors.Count) { throw 'Syntax errors' }
function Assert-Throws([scriptblock]$Action,[string]$Expected) {
    $caught=$false
    try { & $Action } catch { $caught=$true; if ($_.Exception.Message -notlike "*$Expected*") { throw } }
    if (-not $caught) { throw "Expected failure: $Expected" }
}
# Synthetic GUIDs only; all SDK commands are mocked before script invocation.
$tenant='11111111-1111-4111-8111-111111111111'
$app='22222222-2222-4222-8222-222222222222'
$testState=@{objectId='33333333-3333-4333-8333-333333333333';mode='normal';requests=0;wrongTenant=$false}
function Import-Module { param($Name,$ErrorAction) if ($Name -ne 'Microsoft.Graph.Authentication') { throw 'Unexpected module' } }
function Get-MgContext {
    @{AuthType='Delegated';TenantId=$(if ($testState.wrongTenant) {'44444444-4444-4444-8444-444444444444'} else {$tenant});Scopes=@('Application.Read.All')}
}
function Invoke-MgGraphRequest {
    param($Method,$Uri,$ErrorAction)
    $testState.requests++
    if ($Method -ne 'GET' -or $Uri -notlike 'https://graph.microsoft.com/*') { throw 'Unsafe request' }
    if ($Uri -like '*?$filter=*') {
        if ($testState.mode -eq 'absent') { return @{value=@()} }
        return @{value=@(@{id=$testState.objectId;appRoleAssignmentRequired=$true})}
    }
    if ($testState.mode -eq 'error') { throw 'synthetic API error' }
    $next='https://graph.microsoft.com/v1.0/servicePrincipals/'+$testState.objectId+'/appRoleAssignedTo?synthetic=2'
    if ($testState.mode -eq 'hostile') { $next='https://example.com/collect' }
    if ($Uri -like '*synthetic=2' -and $testState.mode -ne 'cycle') { return @{value=@(@{id='synthetic3'})} }
    return @{value=@(@{id='synthetic1'},@{id='synthetic2'});'@odata.nextLink'=$next}
}
Assert-Throws { & $scriptFile -ApplicationIds @([guid]::Empty) -ExpectedTenantId $tenant } 'placeholder'
$testState.wrongTenant=$true
Assert-Throws { & $scriptFile -ApplicationIds @($app) -ExpectedTenantId $tenant } 'expected tenant'
if ($testState.requests -ne 0) { throw 'Invalid context reached Graph' }
$testState.wrongTenant=$false
$result=& $scriptFile -ApplicationIds @($app) -ExpectedTenantId $tenant
if ($result.AssignedPrincipalCount -ne 3 -or -not $result.AssignmentRequired -or $result.InputIndex -ne 1) { throw 'Pagination count incorrect' }
if ($result.PSObject.Properties.Name -contains 'ApplicationId') { throw 'Identifier leak' }
$testState.mode='hostile'
Assert-Throws { & $scriptFile -ApplicationIds @($app) -ExpectedTenantId $tenant } 'pagination destination'
$testState.mode='cycle'
Assert-Throws { & $scriptFile -ApplicationIds @($app) -ExpectedTenantId $tenant } 'Pagination repeated'
$testState.mode='absent'
Assert-Throws { & $scriptFile -ApplicationIds @($app) -ExpectedTenantId $tenant } 'exactly one'
$testState.mode='error'
Assert-Throws { & $scriptFile -ApplicationIds @($app) -ExpectedTenantId $tenant } 'synthetic API error'
Write-Host '7 behavioral checks and PowerShell syntax passed; no tenant requests made.'
