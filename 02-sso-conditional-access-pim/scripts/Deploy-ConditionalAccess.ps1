<#
.SYNOPSIS
    Creates the Conditional Access policies stored as JSON in the policies folder.

.DESCRIPTION
    Reads every *.json file in -PolicyPath and creates it in Entra ID.
      - The break-glass account is added to each policy's exclusions, so you
        can't lock yourself out.
      - Policies are created in report-only mode unless you pass -Enforce.
      - A policy whose display name already exists is skipped.

    Supports -WhatIf so you can preview changes before making them.

.EXAMPLE
    # Create the policies in report-only mode
    .\Deploy-ConditionalAccess.ps1 -PolicyPath ..\policies -BreakGlassUpn breakglass@contoso.onmicrosoft.com

    # Create them switched on (only after checking the report-only results)
    .\Deploy-ConditionalAccess.ps1 -PolicyPath ..\policies -BreakGlassUpn breakglass@contoso.onmicrosoft.com -Enforce
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$PolicyPath,
    [Parameter(Mandatory)] [string]$BreakGlassUpn,
    [switch]$Enforce
)

$ErrorActionPreference = 'Stop'

Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "Policy.Read.All", "Application.Read.All", "User.Read.All" -NoWelcome

$breakGlass = Get-MgUser -UserId $BreakGlassUpn
$existingNames = @(Get-MgIdentityConditionalAccessPolicy -All | ForEach-Object { $_.DisplayName })
$state = if ($Enforce) { 'enabled' } else { 'enabledForReportingButNotEnforced' }

foreach ($file in Get-ChildItem -Path $PolicyPath -Filter *.json | Sort-Object Name) {
    $policy = Get-Content $file.FullName -Raw | ConvertFrom-Json

    if ($existingNames -contains $policy.displayName) {
        Write-Host "Exists:  $($policy.displayName)" -ForegroundColor DarkGray
        continue
    }

    $policy.state = $state
    $policy.conditions.users.excludeUsers = @($breakGlass.Id)

    if ($PSCmdlet.ShouldProcess($policy.displayName, "Create Conditional Access policy ($state)")) {
        Invoke-MgGraphRequest -Method POST `
            -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies' `
            -Body ($policy | ConvertTo-Json -Depth 10) `
            -ContentType 'application/json' | Out-Null
        Write-Host "Created: $($policy.displayName) [$state]" -ForegroundColor Green
    }
}
