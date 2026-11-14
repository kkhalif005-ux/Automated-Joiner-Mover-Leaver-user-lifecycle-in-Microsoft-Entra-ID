# Access Review (Certification) Setup

Access reviews make managers confirm, on a schedule, that their people still need the access they have. Requires Entra ID P2 (or Entra ID Governance).

## Set up the review

1. Go to **Entra admin center → Identity governance → Access reviews → New access review**.
2. **Review type:** Teams + Groups → select `GRP-Finance-Approvers` (a sensitive group).
3. **Scope:** All users.
4. **Reviewers:** Manager of users. Fallback reviewer: your admin account.
5. **Recurrence:** Quarterly, 14-day duration.
6. **Upon completion settings:**
   - Auto-apply results to the resource: **On**
   - If reviewers don't respond: **Remove access**
   - Require a reason on approval: **On**
7. Create the review.

## Run the review

1. Sign in as the manager (for example, Ava Johnson) at `https://myaccess.microsoft.com`.
2. Open the review and **approve** one user with a reason, then **deny** another.
3. When the review ends, check that the denied user was removed from the group.

## Why it matters

Automated provisioning handles predictable changes. Reviews catch the rest: access granted by exception, people who changed roles informally, and access nobody remembers asking for.

## Evidence to capture

- The review configuration page
- The reviewer's approve/deny screen
- The review results showing the applied removal
