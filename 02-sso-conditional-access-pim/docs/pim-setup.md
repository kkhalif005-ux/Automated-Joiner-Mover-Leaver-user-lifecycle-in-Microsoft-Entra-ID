# Privileged Identity Management (PIM) Setup

PIM replaces standing admin access with just-in-time access. A user is *eligible* for a role and has to activate it, with MFA and a justification, for a limited time. Requires Entra ID P2.

## Configure the role settings

1. Go to **Entra admin center → Identity governance → Privileged Identity Management → Microsoft Entra roles → Roles**.
2. Open **User Administrator → Role settings → Edit**.
3. On the **Activation** tab set:
   - Activation maximum duration: **2 hours**
   - On activation, require: **Microsoft Entra MFA**
   - Require justification on activation: **On**
   - Require approval to activate: **On**, with your admin account as approver (optional, but it shows the approval flow)
4. On the **Assignment** tab, turn off **Allow permanent eligible assignment** and set eligibility to expire after 3 months.
5. Save.

## Make a user eligible

Use the script:

```powershell
cd 02-sso-conditional-access-pim\scripts
.\New-PimEligibleAssignment.ps1 -UserUpn priya.patel@yourtenant.onmicrosoft.com -RoleName 'User Administrator'
```

Or in the portal: **Roles → User Administrator → Add assignments**, select the user and choose **Eligible**.

The lab assigns eligibility to the IT Manager directly. `GRP-IT-Admins-Eligible` from Project 1 is an ordinary security group; a group has to be created as role-assignable before it can hold an Entra role.

## Activate the role

1. Sign in as the eligible user and open **PIM → My roles**.
2. Choose **Activate** on User Administrator, complete MFA and enter a justification.
3. If approval is on, approve the request from the admin account.
4. Check that the user can now manage users, and that the role disappears when the activation window ends.

## Review the trail

**PIM → Microsoft Entra roles → Resource audit** shows who activated which role, when and why.

## Evidence to capture

- The role settings page
- The eligible assignment
- The activation request with its justification
- The audit history entry
