# DWP Incident RCA - User Lockout (jsmith)

## Incident Summary

- **Incident type:** User account lockout / access interruption
- **User:** `jsmith`
- **Affected endpoint:** `DESKTOP-FB001`
- **Observation window:** 08:02:14 to 08:23:44 (local time)
- **Business impact:** User was unable to access workstation until support intervention.

## Event ID Reference (What Each Event Records)

- **4625 (An account failed to log on)**
  Records a failed sign-in attempt. It includes failure reason, account name, source machine, and logon type.

- **4740 (A user account was locked out)**
  Records that the account lockout threshold was reached and the account was locked by policy. Includes the calling/source computer.

- **4722 (A user account was enabled)**
  Records that an account was enabled by an administrator or delegated operator. Includes who performed the action.

- **4624 (An account was successfully logged on)**
  Records a successful sign-in, including account and logon type.

## Observed Event Timeline

1. **08:02:14 - Event 4625 (Failure)**
   Failed interactive logon for `jsmith` on `DESKTOP-FB001`.
   Failure reason: Unknown username or bad password.

2. **08:04:22 - Event 4625 (Failure)**
   Second failed interactive logon for `jsmith` on `DESKTOP-FB001`.
   Failure reason: Unknown username or bad password.

3. **08:06:01 - Event 4740 (Lockout)**
   Account `jsmith` locked out. Calling computer: `DESKTOP-FB001`.

4. **08:07:45 - Event 4625 (Failure, locked state)**
   Failed unlock attempt (logon type 7) for `jsmith` from `DESKTOP-FB001`.
   Failure reason: Account locked out.

5. **08:22:10 - Event 4722 (Admin action)**
   Account `jsmith` enabled by `FINBRIDGE\helpdesk-admin`.

6. **08:23:44 - Event 4624 (Success)**
   Successful interactive logon (type 2) for `jsmith`.

## Sequence of Events (Plain English)

The user attempted to sign in at the local workstation and entered invalid credentials at least twice. Shortly after, the account hit lockout policy and was locked. The user then tried to unlock the session, but authentication failed because the account was already locked. Helpdesk intervened, enabled the account, and the user successfully logged on one minute later.

## Most Likely Cause of Lockout

**Primary cause:** Repeated bad-password interactive sign-in attempts on `DESKTOP-FB001`, resulting in policy-based account lockout.

### Evidence

- Two explicit pre-lockout `4625` events (08:02:14 and 08:04:22) with bad password reason.
- `4740` confirms formal account lockout from the same source endpoint (`DESKTOP-FB001`).
- Post-lockout `4625` at 08:07:45 (logon type 7) confirms user attempts continued while account was locked.
- Administrative recovery (`4722`) was immediately followed by successful sign-in (`4624`), validating that access failure condition was account state/credential related rather than endpoint/network failure.

### Technical interpretation note

Only two bad-password `4625` events are shown before `4740`, while many environments lock at three attempts. This suggests either:

- one additional failed attempt occurred outside the provided excerpt/window granularity, or
- one failure was logged in a different security log source not included in this dataset.

This does not change the root-cause conclusion because `4740` is authoritative evidence that lockout threshold was met.

## 5 Whys Analysis

1. **Why was the user locked out?**
   Because the account exceeded the failed authentication threshold and triggered account lockout policy (`4740`).

2. **Why did failed authentications occur?**
   The user entered incorrect credentials during local interactive logon (`4625`, bad password reason).

3. **Why were incorrect credentials repeatedly entered?**
   Most likely user-side credential mismatch (mistyped password, stale remembered password, keyboard state such as Caps Lock) during login/unlock attempts.

4. **Why did this immediately cause service disruption?**
   Lockout policy prevents further authentication attempts until administrative action or timeout, and a subsequent unlock attempt failed with account-locked state (`4625`, type 7).

5. **Why was manual support required to restore service quickly?**
   The account state required administrator intervention (`4722` by helpdesk-admin) before successful user logon resumed (`4624`).

## Root Cause Statement

User account `jsmith` was locked due to repeated invalid local interactive authentication attempts on `DESKTOP-FB001`, which triggered account lockout policy. Access was restored after helpdesk account-state remediation.

## Corrective and Preventive Actions (CAPA)

- Confirm lockout threshold and observation settings in account lockout policy documentation.
- Validate user credential hygiene steps in runbooks (caps lock check, keyboard layout check, recent password change confirmation).
- Add helpdesk triage step to check for cached/stored stale credentials on endpoint if lockouts recur.
- Correlate with directory-side events (`4767` unlock, if available) for fuller post-incident evidence chain.
- Consider user advisory/training on sign-in retry limits to reduce repeat lockout incidents.

## Closure Criteria

- User access restored: **Yes** (`4624` at 08:23:44).
- Immediate incident resolved: **Yes**.
- Follow-up recommended: **Yes** (policy confirmation and user guidance).
