# Joiner-Mover-Leaver Process

## Purpose

Make sure every employee has the access their job needs, no more and no less, from their first day until the day they leave.

## Roles

| Role | Responsibility |
|------|----------------|
| HR | Keeps the HR feed accurate (hires, transfers, terminations) |
| IAM team | Owns the role matrix and the sync script; reviews errors in the audit log |
| Managers | Certify their team's access during access reviews |
| Application / group owners | Approve changes to what each group grants |

## Source of truth

The HR feed is authoritative. Users are matched on **employeeId**, never on name, because names change and can be duplicated.

## Lifecycle events

### Joiner
1. A new row appears in the HR feed with Status = Active.
2. The script creates the account with the UPN format `first.last@domain`.
3. The user must change the temporary password at first sign-in.
4. The script adds the groups the role matrix defines for the user's department and job title (birthright access).
5. The script sets the manager.

### Mover
1. The user's department or job title changes in the HR feed.
2. The script updates those attributes in Entra ID.
3. The script **removes** groups the new role doesn't include and **adds** groups it does.
4. Anything beyond the new role must go through a normal access request.

### Leaver
1. HR sets Status = Terminated.
2. The script disables the account (it doesn't delete it, so the account stays available for audit and data retention).
3. The script revokes all sign-in sessions and refresh tokens.
4. The script removes every role group.
5. Account deletion is a separate step after the retention period.

## Drift control

When nothing has changed for a user, the script still re-applies their role groups. If someone added a user to a managed group by hand, the next run removes it.

## Audit

Every action is logged with a timestamp, action, employee ID, UPN, detail and result. Failures are logged as `Failure` and reviewed by the IAM team.

## Controls summary

| Control | How it's met |
|---------|--------------|
| Least privilege | Role-based birthright access; movers lose old access |
| Timely de-provisioning | Leavers are disabled and their sessions revoked on the next sync |
| Separation of duties | Finance approver rights only for the Finance Manager role |
| Accountability | CSV audit log for every change |
| Periodic certification | Quarterly manager access reviews (see `access-review.md`) |
