<#
.SYNOPSIS
    Creates the security groups listed in the role matrix (one-time setup).

.DESCRIPTION
    Reads role_matrix.csv, collects every unique group name and creates any
    security group that doesn't already exist in Entra ID.

.EXAMPLE
    .\New-LabGroups.ps1 -RoleMatrixPath ..\data\role_matrix.csv
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$RoleMatrixPath
)

Connect-MgGraph -Scopes "Group.ReadWrite.All" -NoWelcome

$groupNames = Import-Csv $RoleMatrixPath |
    ForEach-Object { $_.Groups -split ';' } |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ } |
    Sort-Object -Unique

foreach ($name in $groupNames) {
    $existing = Get-MgGroup -Filter "displayName eq '$name'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Exists:  $name" -ForegroundColor DarkGray
        continue
    }

    if ($PSCmdlet.ShouldProcess($name, "Create security group")) {
        New-MgGroup -DisplayName $name `
                    -Description "IAM lab - managed by role matrix" `
                    -MailEnabled:$false `
                    -MailNickname ($name -replace '[^a-zA-Z0-9]', '') `
                    -SecurityEnabled | Out-Null
        Write-Host "Created: $name" -ForegroundColor Green
    }
}
