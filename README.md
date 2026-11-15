# IAM Home Lab: Identity Lifecycle, SSO and Privileged Access

Two hands-on Identity and Access Management (IAM) projects built in a Microsoft Entra ID test tenant. They cover the day-to-day work of an IAM Analyst or Engineer: provisioning, de-provisioning, RBAC, access reviews, SAML SSO, MFA, Conditional Access and Privileged Identity Management (PIM).

> **Lab only.** Everything here runs in a free test tenant with fake users. Never run these scripts against a production tenant.

## Projects

| # | Project | What it shows |
|---|---------|---------------|
| 1 | [Joiner-Mover-Leaver automation](01-joiner-mover-leaver/) | An HR CSV drives user provisioning, role-based group assignment, department moves and terminations in Entra ID with PowerShell and Microsoft Graph. Includes audit logging and access reviews. |
| 2 | [SSO, Conditional Access and PIM](02-sso-conditional-access-pim/) | SAML SSO to an enterprise app, Conditional Access policies (MFA, block legacy auth), just-in-time admin access with PIM, and a troubleshooting runbook for common sign-in errors. |

## Demo results (live run, Nov 14, 2026)

I ran Project 1 end to end in Azure Cloud Shell against my own Entra ID test tenant. All 35 logged actions succeeded, with zero errors.

| Run | Joiners | Movers | Leavers | Group adds | Group removes |
|-----|:-------:|:------:|:-------:|:----------:|:-------------:|
| Setup | | | | 7 groups created | |
| Day 1 | 6 | 0 | 0 | 18 | 0 |
| Day 2 | 1 (Olivia Martinez) | 1 (Marcus Lee) | 1 (Daniel Garcia) | 4 | 4 |

- **Mover:** Marcus Lee went from Finance Accountant to IT Helpdesk Technician. He gained `GRP-IT-Users` and `GRP-IT-Helpdesk` and lost `GRP-Finance-Users`, with no manual steps.
- **Leaver:** Daniel Garcia's account was disabled, his sessions were revoked and he was removed from 3 groups.
- **Preview first:** every run started with `-WhatIf`, which listed the planned changes before anything was applied.

Cloud Shell needed two small fixes: installing the Microsoft Graph user modules, and reusing the Cloud Shell sign-in token because interactive sign-in times out there.

Project 2 is documented and scripted but has not been run in the tenant yet.

## Skills covered

| Skill | Project 1 | Project 2 |
|-------|:---------:|:---------:|
| Identity lifecycle (provisioning / de-provisioning) | ✅ | |
| RBAC and least privilege | ✅ | ✅ |
| Access reviews / certifications | ✅ | |
| Microsoft Entra ID | ✅ | ✅ |
| SSO and SAML federation | | ✅ |
| MFA and Conditional Access | | ✅ |
| PAM / PIM (just-in-time privileged access) | | ✅ |
| Troubleshooting authentication and access issues | ✅ | ✅ |
| PowerShell and Microsoft Graph | ✅ | ✅ |
| Documentation (process docs, runbooks) | ✅ | ✅ |

## Lab setup

1. Create a free Azure account. It comes with a Microsoft Entra ID tenant.
2. Start the free 30-day **Microsoft Entra ID P2** trial (Entra admin center → Billing → Licenses → Try/Buy). P2 is needed for Access Reviews, Conditional Access and PIM. Assign the trial licenses to your test users.
3. Create a **break-glass admin account** that is excluded from Conditional Access, so you can't lock yourself out.
4. Install the Microsoft Graph PowerShell SDK:

   ```powershell
   Install-Module Microsoft.Graph -Scope CurrentUser
   ```

## Run Project 1

Run everything from `01-joiner-mover-leaver/scripts`. Replace `yourtenant.onmicrosoft.com` with your tenant's domain. Each script opens a sign-in prompt and asks for the Graph permissions it needs.

```powershell
cd 01-joiner-mover-leaver\scripts

# 1. One-time setup: create the security groups from the role matrix
.\New-LabGroups.ps1 -RoleMatrixPath ..\data\role_matrix.csv

# 2. Day 1: preview, then apply
.\Invoke-JMLSync.ps1 -HRFeedPath ..\data\hr_feed_day1.csv -RoleMatrixPath ..\data\role_matrix.csv -Domain yourtenant.onmicrosoft.com -WhatIf
.\Invoke-JMLSync.ps1 -HRFeedPath ..\data\hr_feed_day1.csv -RoleMatrixPath ..\data\role_matrix.csv -Domain yourtenant.onmicrosoft.com

# 3. Day 2: the HR feed changes
.\Invoke-JMLSync.ps1 -HRFeedPath ..\data\hr_feed_day2.csv -RoleMatrixPath ..\data\role_matrix.csv -Domain yourtenant.onmicrosoft.com
```

What to expect:

| Run | Result |
|-----|--------|
| Day 1 | Six users are created, added to their role groups and linked to their managers. |
| Day 2 | **Mover:** Marcus Lee goes from Finance Accountant to IT Helpdesk Technician, loses `GRP-Finance-Users` and gains `GRP-IT-Users` and `GRP-IT-Helpdesk`. **Leaver:** Daniel Garcia is disabled, his sessions are revoked and his groups removed. **Joiner:** Olivia Martinez is created as a Finance Accountant. |

Each run writes an audit log to `scripts\logs\audit_<timestamp>.csv`. To use your own HR feed, keep the same column headers as the sample feeds and make sure every Department and JobTitle pair has a row in `role_matrix.csv`; rows without a matching role are skipped and logged.

Then follow [process.md](01-joiner-mover-leaver/docs/process.md) for the process behind the script and [access-review.md](01-joiner-mover-leaver/docs/access-review.md) to set up the quarterly review.

## Run Project 2

1. Set up SAML SSO with [saml-sso-setup.md](02-sso-conditional-access-pim/docs/saml-sso-setup.md).
2. Deploy the Conditional Access policies in report-only mode, with your break-glass account excluded:

   ```powershell
   cd 02-sso-conditional-access-pim\scripts
   .\Deploy-ConditionalAccess.ps1 -PolicyPath ..\policies -BreakGlassUpn breakglass@yourtenant.onmicrosoft.com
   ```

   Review the report-only results in the sign-in logs, then switch the policies on in the portal.
3. Set up just-in-time admin access with [pim-setup.md](02-sso-conditional-access-pim/docs/pim-setup.md).
4. Use [troubleshooting-runbook.md](02-sso-conditional-access-pim/docs/troubleshooting-runbook.md) to diagnose failed sign-ins.

## Repo structure

```
.
├── 01-joiner-mover-leaver/
│   ├── data/          # Fake HR feeds and the role matrix
│   ├── scripts/       # Group setup and lifecycle sync scripts
│   └── docs/          # Process documentation and access review guide
├── 02-sso-conditional-access-pim/
│   ├── policies/      # Conditional Access policies as JSON
│   ├── scripts/       # Policy deployment and PIM scripts
│   └── docs/          # SAML setup, PIM setup and troubleshooting runbook
└── screenshots/       # Evidence from the lab
```

## What I learned

- The **mover** step is where most organizations leak access. Removing old access matters as much as granting new access.
- Testing Conditional Access in **report-only mode** first prevents lockouts.
- **Standing admin access is a risk.** PIM makes admins request a role for a limited time, with MFA and a justification.
- **Sign-in logs** and the AADSTS error codes are the fastest way to troubleshoot SSO.

## License

[MIT](LICENSE)
