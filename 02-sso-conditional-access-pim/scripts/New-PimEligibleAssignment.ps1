<#
.SYNOPSIS
    Makes a user eligible for an Entra ID admin role through PIM.

.DESCRIPTION
    Creates a time-limited eligible assignment. The user holds no admin rights
    until they activate the role in PIM, which is what "just-in-time" means.
    Requires Entra ID P2 and a caller who is a Privileged Role Administrator
    or Global Administrator.

    Supports -WhatIf so you can preview the change before making it.

.EXAMPLE
    .\New-PimEligibleAssignment.ps1 -UserUpn priya.patel@contoso.onmicrosoft.com -RoleName 'User Administrator'
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$UserUpn,
    [Parameter(Mandatory)] [string]$RoleName,
    [int]$Days = 90,
    [string]$Justification = 'IAM lab - eligible assignment for just-in-time access'
)

$ErrorActionPreference = 'Stop'

Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory", "User.Read.All" -NoWelcome

$user = Get-MgUser -UserId $UserUpn
$role = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq '$RoleName'"
if (-not $role) { throw "Role '$RoleName' not found." }

$request = @{
    action           = 'adminAssign'
    justification    = $Justification
    roleDefinitionId = $role.Id
    directoryScopeId = '/'
    principalId      = $user.Id
    scheduleInfo     = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString('o')
        expiration    = @{
            type     = 'afterDuration'
            duration = "P$($Days)D"
        }
    }
}

if ($PSCmdlet.ShouldProcess($UserUpn, "Make eligible for '$RoleName' for $Days days")) {
    New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $request | Out-Null
    Write-Host "Eligible: $UserUpn -> $RoleName ($Days days)" -ForegroundColor Green
}
