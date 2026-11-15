# IAM Home Lab: Identity Lifecycle, SSO and Privileged Access

Two hands-on Identity and Access Management (IAM) projects built in a Microsoft Entra ID test tenant. They cover the day-to-day work of an IAM Analyst or Engineer: provisioning, de-provisioning, RBAC, access reviews, SAML SSO, MFA, Conditional Access and Privileged Identity Management (PIM).

> **Lab only.** Everything here runs in a free test tenant with fake users. Never run these scripts against a production tenant.

## Projects

| # | Project | What it shows |
|---|---------|---------------|
| 1 | [Joiner-Mover-Leaver automation](01-joiner-mover-leaver/) | An HR CSV drives user provisioning, role-based group assignment, department moves and terminations in Entra ID with PowerShell and Microsoft Graph. Includes audit logging and access reviews. |
| 2 | [SSO, Conditional Access and PIM](02-sso-conditional-access-pim/) | SAML SSO to an enterprise app, Conditional Access policies (MFA, block legacy auth), just-in-time admin access with PIM, and a troubleshooting runbook for common sign-in errors. |

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

## Repo structure

```
iam-home-lab/
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
