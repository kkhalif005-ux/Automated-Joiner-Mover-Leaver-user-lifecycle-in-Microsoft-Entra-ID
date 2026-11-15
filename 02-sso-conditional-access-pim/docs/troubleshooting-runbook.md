# Sign-in Troubleshooting Runbook

## First steps for any failed sign-in

1. Get the user's UPN, the application, the time of the attempt and the error code or correlation ID from the error page.
2. Open **Entra admin center → Identity → Monitoring & health → Sign-in logs** and filter by user and time.
3. Open the failed entry and read these tabs:
   - **Basic info:** the error code and failure reason
   - **Authentication details:** which method was tried and whether MFA was satisfied
   - **Conditional Access:** which policies applied and which one failed
4. Match the error code below.

## Common errors

| Code | Meaning | Usual cause | Fix |
|------|---------|-------------|-----|
| AADSTS50034 | User account doesn't exist in the tenant | Wrong UPN or wrong tenant | Confirm the UPN; check the joiner ran for this user |
| AADSTS50126 | Invalid username or password | Wrong or expired password | Reset the password or issue a Temporary Access Pass |
| AADSTS50053 | Account is locked | Smart lockout after repeated failed attempts | Wait for the lockout to clear; check for a stale saved password on a device |
| AADSTS50057 | Account is disabled | Leaver processed, or disabled by hand | Check the HR feed and audit log before re-enabling anything |
| AADSTS50076 | MFA required | A Conditional Access policy requires MFA | Expected behaviour; the user completes MFA |
| AADSTS50079 | User must register for MFA | No MFA method registered | Have the user register at `https://aka.ms/mfasetup` |
| AADSTS53003 | Blocked by Conditional Access | A block policy matched, for example legacy authentication | Read the Conditional Access tab to find the policy; move the client to modern authentication |
| AADSTS50105 | User isn't assigned to the application | User isn't in a group assigned to the enterprise app | Fix the role matrix or raise an access request; don't assign users directly |
| AADSTS50011 | Reply URL mismatch | The ACS URL the app sent isn't in Basic SAML Configuration | Correct the Reply URL in the enterprise app |
| AADSTS700016 | Application not found in the tenant | Wrong Identifier (Entity ID) in the app or in Entra ID | Make the Identifier match on both sides |
| AADSTS75011 | Authentication method mismatch | The app requested a method different from the one the user's session used | Remove the RequestedAuthnContext from the app's SAML request, or sign in again |

## Conditional Access checks

- Use the **What If** tool under **Conditional Access → Policies** to see which policies would apply to a user, app and client.
- A report-only policy never blocks. Its result appears on the **Report-only** tab of the sign-in log entry.
- If an admin is locked out, sign in with the break-glass account, switch the policy to report-only and investigate.

## Escalate when

- Many users fail at the same time (check **Service health** first).
- The sign-in log shows a risky sign-in or an unfamiliar location.
- A disabled account shows sign-in attempts after the leaver date.
