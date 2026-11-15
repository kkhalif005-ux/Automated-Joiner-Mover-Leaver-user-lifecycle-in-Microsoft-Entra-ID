# SAML SSO Setup

Sets up SAML single sign-on from Entra ID (the identity provider) to a test application (the service provider). The lab uses the **Microsoft Entra SAML Toolkit**, a free test app in the Entra gallery, so no paid SaaS subscription is needed.

## Add the application

1. Go to **Entra admin center → Identity → Applications → Enterprise applications → New application**.
2. Search for **Microsoft Entra SAML Toolkit**, select it and choose **Create**.

## Configure SAML in Entra ID

1. In the app, open **Single sign-on → SAML**.
2. Edit **Basic SAML Configuration** and set:

   | Field | Value |
   |-------|-------|
   | Identifier (Entity ID) | `https://samltoolkit.azurewebsites.net` |
   | Reply URL (ACS URL) | `https://samltoolkit.azurewebsites.net/SAML/Consume` |
   | Sign on URL | `https://samltoolkit.azurewebsites.net/` |

3. Under **SAML Certificates**, download **Certificate (Raw)**.
4. Under **Set up Microsoft Entra SAML Toolkit**, copy the **Login URL**, **Microsoft Entra Identifier** and **Logout URL**.

If the portal shows different values for the toolkit, follow Microsoft's current tutorial for the app.

## Configure the service provider

1. Open `https://samltoolkit.azurewebsites.net/` and register a test account. Use the same email address as the UPN of one of the lab users.
2. Open **SAML Configuration → Create**.
3. Paste the Login URL, Microsoft Entra Identifier and Logout URL, upload the Raw certificate and save.
4. Copy the SP-initiated login URL and ACS URL the toolkit shows. If they differ from the values above, update **Basic SAML Configuration** in Entra ID to match.

## Assign access with a group

1. In the enterprise app, open **Users and groups → Add user/group**.
2. Assign `GRP-Finance-Users`, not individual users. Access to the app then follows the role matrix from Project 1: a mover who leaves Finance loses the app on the next sync.

## Test

1. In **Single sign-on**, choose **Test** and sign in as a Finance user. The sign-in should succeed.
2. Sign in as a user outside the group. Expect error `AADSTS50105`, which proves the assignment is enforced.
3. Check **Sign-in logs** for both attempts.

## Evidence to capture

- The Basic SAML Configuration page
- The group assignment
- A successful sign-in and the `AADSTS50105` failure in the sign-in logs
