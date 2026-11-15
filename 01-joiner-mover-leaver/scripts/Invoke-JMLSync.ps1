<#
.SYNOPSIS
    Joiner-Mover-Leaver sync: makes Entra ID match the HR feed.

.DESCRIPTION
    The HR CSV is the authoritative source. For each employee:
      - Joiner : not in Entra ID yet          -> create user, assign role groups
      - Mover  : department or title changed  -> update user, swap role groups
      - Leaver : Status = Terminated          -> disable, revoke sessions, remove groups
    Users are matched on the employeeId attribute, not on name.
    Every action is written to a CSV audit log.

    Supports -WhatIf so you can preview changes before making them.

.EXAMPLE
    # Preview what would change
    .\Invoke-JMLSync.ps1 -HRFeedPath ..\data\hr_feed_day1.csv -RoleMatrixPath ..\data\role_matrix.csv -Domain contoso.onmicrosoft.com -WhatIf

    # Apply the changes
    .\Invoke-JMLSync.ps1 -HRFeedPath ..\data\hr_feed_day1.csv -RoleMatrixPath ..\data\role_matrix.csv -Domain contoso.onmicrosoft.com
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string]$HRFeedPath,
    [Parameter(Mandatory)] [string]$RoleMatrixPath,
    [Parameter(Mandatory)] [string]$Domain,          # e.g. yourtenant.onmicrosoft.com
    [string]$LogPath = ".\logs\audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

$ErrorActionPreference = 'Stop'

# --- Least privilege: request only the Graph permissions this script needs ---
Connect-MgGraph -Scopes "User.ReadWrite.All", "GroupMember.ReadWrite.All", "Group.Read.All" -NoWelcome

New-Item -ItemType Directory -Path (Split-Path $LogPath) -Force | Out-Null

function Write-AuditLog {
    param($Action, $EmployeeID, $UPN, $Detail, $Result = 'Success')
    [pscustomobject]@{
        Timestamp  = (Get-Date).ToString('s')
        Action     = $Action
        EmployeeID = $EmployeeID
        UPN        = $UPN
        Detail     = $Detail
        Result     = $Result
    } | Export-Csv -Path $LogPath -Append -NoTypeInformation
    $color = if ($Result -eq 'Success') { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1} {2} - {3}" -f $Action, $EmployeeID, $UPN, $Detail) -ForegroundColor $color
}

function New-TempPassword {
    # Random temporary password. It is never logged or printed;
    # reset it in the portal (or issue a Temporary Access Pass) to sign in as the user.
    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$%'
    -join (1..20 | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# --- Load role matrix: "Department|JobTitle" -> list of groups ---
$roleMap = @{}
Import-Csv $RoleMatrixPath | ForEach-Object {
    $roleMap["$($_.Department)|$($_.JobTitle)"] = @($_.Groups -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

# Groups this script is allowed to manage (anything in the role matrix)
$managedGroupNames = $roleMap.Values | ForEach-Object { $_ } | Sort-Object -Unique
$groupIds = @{}
foreach ($name in $managedGroupNames) {
    $g = Get-MgGroup -Filter "displayName eq '$name'"
    if (-not $g) { throw "Group '$name' not found. Run New-LabGroups.ps1 first." }
    $groupIds[$name] = $g.Id
}

function Get-UserByEmployeeId([string]$EmployeeId) {
    # Filtering on employeeId is an advanced query: needs ConsistencyLevel + count
    Get-MgUser -Filter "employeeId eq '$EmployeeId'" -ConsistencyLevel eventual -CountVariable c `
               -Property Id, DisplayName, UserPrincipalName, Department, JobTitle, AccountEnabled, EmployeeId
}

function Get-ManagedGroupMemberships([string]$UserId) {
    Get-MgUserMemberOf -UserId $UserId -All |
        Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group' } |
        Where-Object { $groupIds.Values -contains $_.Id } |
        ForEach-Object { $_.AdditionalProperties['displayName'] }
}

function Set-RoleGroups($User, [string[]]$DesiredGroups, $EmployeeId) {
    $current = @(Get-ManagedGroupMemberships -UserId $User.Id)

    foreach ($g in $DesiredGroups | Where-Object { $current -notcontains $_ }) {
        if ($PSCmdlet.ShouldProcess($User.UserPrincipalName, "Add to $g")) {
            New-MgGroupMember -GroupId $groupIds[$g] -DirectoryObjectId $User.Id
            Write-AuditLog 'GroupAdd' $EmployeeId $User.UserPrincipalName $g
        }
    }
    foreach ($g in $current | Where-Object { $DesiredGroups -notcontains $_ }) {
        if ($PSCmdlet.ShouldProcess($User.UserPrincipalName, "Remove from $g")) {
            Remove-MgGroupMemberByRef -GroupId $groupIds[$g] -DirectoryObjectId $User.Id
            Write-AuditLog 'GroupRemove' $EmployeeId $User.UserPrincipalName $g
        }
    }
}

# --- Main loop ---
$hrRecords = Import-Csv $HRFeedPath

foreach ($rec in $hrRecords) {
    try {
        $user = Get-UserByEmployeeId $rec.EmployeeID

        # ---------- LEAVER ----------
        if ($rec.Status -eq 'Terminated') {
            if (-not $user -or -not $user.AccountEnabled) { continue }   # already handled

            if ($PSCmdlet.ShouldProcess($user.UserPrincipalName, "Disable account, revoke sessions, remove groups")) {
                Update-MgUser -UserId $user.Id -AccountEnabled:$false
                Revoke-MgUserSignInSession -UserId $user.Id | Out-Null
                foreach ($g in Get-ManagedGroupMemberships -UserId $user.Id) {
                    Remove-MgGroupMemberByRef -GroupId $groupIds[$g] -DirectoryObjectId $user.Id
                    Write-AuditLog 'GroupRemove' $rec.EmployeeID $user.UserPrincipalName $g
                }
                Write-AuditLog 'Leaver' $rec.EmployeeID $user.UserPrincipalName 'Account disabled and sessions revoked'
            }
            continue
        }

        $roleKey = "$($rec.Department)|$($rec.JobTitle)"
        if (-not $roleMap.ContainsKey($roleKey)) {
            Write-AuditLog 'Skipped' $rec.EmployeeID '' "No role defined for '$roleKey'" 'Warning'
            continue
        }
        $desiredGroups = $roleMap[$roleKey]

        # ---------- JOINER ----------
        if (-not $user) {
            $upn = ("{0}.{1}@{2}" -f $rec.FirstName, $rec.LastName, $Domain).ToLower()
            if ($PSCmdlet.ShouldProcess($upn, "Create user")) {
                $user = New-MgUser -AccountEnabled `
                    -DisplayName "$($rec.FirstName) $($rec.LastName)" `
                    -GivenName $rec.FirstName -Surname $rec.LastName `
                    -MailNickname ("{0}.{1}" -f $rec.FirstName, $rec.LastName).ToLower() `
                    -UserPrincipalName $upn `
                    -Department $rec.Department -JobTitle $rec.JobTitle `
                    -EmployeeId $rec.EmployeeID `
                    -UsageLocation 'US' `
                    -PasswordProfile @{ Password = (New-TempPassword); ForceChangePasswordNextSignIn = $true }
                Write-AuditLog 'Joiner' $rec.EmployeeID $upn "Created as $($rec.JobTitle), $($rec.Department)"
                Set-RoleGroups $user $desiredGroups $rec.EmployeeID
            }
        }
        # ---------- MOVER ----------
        elseif ($user.Department -ne $rec.Department -or $user.JobTitle -ne $rec.JobTitle) {
            if ($PSCmdlet.ShouldProcess($user.UserPrincipalName, "Move to $roleKey")) {
                Update-MgUser -UserId $user.Id -Department $rec.Department -JobTitle $rec.JobTitle
                Write-AuditLog 'Mover' $rec.EmployeeID $user.UserPrincipalName "$($user.Department)/$($user.JobTitle) -> $($rec.Department)/$($rec.JobTitle)"
                Set-RoleGroups $user $desiredGroups $rec.EmployeeID
            }
        }
        # ---------- NO CHANGE: still enforce the role (catches manual drift) ----------
        else {
            Set-RoleGroups $user $desiredGroups $rec.EmployeeID
        }

        # ---------- MANAGER ----------
        if ($user -and $rec.ManagerEmployeeID) {
            $mgr = Get-UserByEmployeeId $rec.ManagerEmployeeID
            if ($mgr -and $PSCmdlet.ShouldProcess($user.UserPrincipalName, "Set manager $($mgr.UserPrincipalName)")) {
                Set-MgUserManagerByRef -UserId $user.Id -BodyParameter @{
                    '@odata.id' = "https://graph.microsoft.com/v1.0/users/$($mgr.Id)"
                }
            }
        }
    }
    catch {
        Write-AuditLog 'Error' $rec.EmployeeID '' $_.Exception.Message 'Failure'
    }
}

Write-Host "`nDone. Audit log: $LogPath" -ForegroundColor Cyan
