#Requires -Version 5.1
<#
.SYNOPSIS
Read-only assignment counts using an existing authorized Graph session.
.DESCRIPTION
Does not sign in, grant consent, enumerate OAuth scopes or change assignments.
Requires an existing delegated Application.Read.All session for the expected
tenant. Output omits display names and IDs. Keep results private.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][ValidateCount(1,30)][guid[]]$ApplicationIds,
    [Parameter(Mandatory=$true)][guid]$ExpectedTenantId
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
if ($ExpectedTenantId -eq [guid]::Empty -or $ApplicationIds -contains [guid]::Empty) {
    throw 'Replace placeholder IDs with approved identifiers kept outside Git.'
}
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
$context=Get-MgContext
if (-not $context -or $context.AuthType -ne 'Delegated' -or
    [string]$context.TenantId -ne [string]$ExpectedTenantId -or
    @($context.Scopes) -notcontains 'Application.Read.All') {
    throw 'An existing delegated Application.Read.All session for the expected tenant is required.'
}
$index=0
foreach ($appId in $ApplicationIds) {
    $index++
    $filter=[uri]::EscapeDataString("appId eq '$appId'")
    $url='https://graph.microsoft.com/v1.0/servicePrincipals?$filter='+$filter+'&$select=id,appRoleAssignmentRequired'
    $response=Invoke-MgGraphRequest -Method GET -Uri $url -ErrorAction Stop
    $apps=@($response['value'])
    if ($apps.Count -ne 1 -or $null -eq $apps[0]) { throw 'Expected exactly one service principal for an input application.' }
    $app=$apps[0]
    $objectId=[guid]$app['id']
    $next='https://graph.microsoft.com/v1.0/servicePrincipals/'+$objectId+'/appRoleAssignedTo'
    $seen=@{}
    $count=0
    while ($next) {
        $uri=[uri]$next
        $expectedPath='/v1.0/servicePrincipals/'+$objectId+'/appRoleAssignedTo'
        if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'graph.microsoft.com' -or
            $uri.Port -ne 443 -or $uri.UserInfo -or $uri.AbsolutePath -ne $expectedPath) {
            throw 'Unexpected Graph pagination destination.'
        }
        if ($seen.ContainsKey($next) -or $seen.Count -ge 100) { throw 'Pagination repeated or exceeded 100 pages.' }
        $seen[$next]=$true
        $page=Invoke-MgGraphRequest -Method GET -Uri $next -ErrorAction Stop
        $count+=@($page['value']).Count
        $next=$page['@odata.nextLink']
    }
    [pscustomobject]@{
        InputIndex=$index
        AssignmentRequired=[bool]$app['appRoleAssignmentRequired']
        AssignedPrincipalCount=$count
    }
}
