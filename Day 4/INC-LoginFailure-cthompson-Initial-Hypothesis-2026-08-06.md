# Login Failure Incident - Initial Hypothesis
**User:** cthompson  
**Date:** 2026-08-06  
**Assessment type:** Scope-facts-only triage hypothesis (no single cause committed)

---

## Scope Facts Used

- **Symptom:** user cthompson not able to login
- **Who:** cthompson only (single-user impact)
- **Since:** ~08:40 this morning
- **Change:** Nil reported

---

## Ranked Top 5 Most Likely Causes

### #1 - Account lockout or credential state issue (bad password retries, stale cached credential, or lockout threshold hit)
**Why this fits the scope facts:**
A single-user failure with no broader impact is most commonly identity-state specific. Sudden onset at a specific time with no known platform change aligns with lockout threshold crossing or repeated old credential use from a mobile device/app.

**Single fastest check:**
In AD/Azure identity logs, check whether cthompson shows a current lockout state or repeated failed sign-ins around 08:40.

---

### #2 - Recent password change not synchronized across sign-in paths (cloud vs. on-prem or cached session mismatch)
**Why this fits the scope facts:**
No environment-wide change and only one affected user strongly suggests a user-specific auth mismatch. This often presents as "cannot log in" immediately after password updates, especially when one auth path has updated and another has not.

**Single fastest check:**
Ask cthompson to authenticate to a known-good web identity endpoint (for example Microsoft 365 portal) and compare result with Windows/VDI sign-in outcome.

---

### #3 - Conditional Access/MFA challenge failure specific to cthompson (device compliance, MFA method issue, sign-in risk flag)
**Why this fits the scope facts:**
CA/MFA failures can affect exactly one user with no infra change. The time-based onset around 08:40 is consistent with a policy evaluation event, token expiry, or a newly triggered risk/compliance requirement for that identity.

**Single fastest check:**
Review Entra sign-in log result for cthompson at first failure after 08:40 and inspect the exact failure reason and CA status.

---

### #4 - User profile/container issue for cthompson (corrupt local profile or profile mount failure)
**Why this fits the scope facts:**
Profile problems are often single-user and can begin abruptly without any announced change. A broken user profile path, stale profile lock, or failed profile container attach can block interactive logon while other users remain unaffected.

**Single fastest check:**
Check the target host's profile-related event logs at cthompson login time (User Profile Service and, if used, FSLogix operational events).

---

### #5 - Session host assignment or entitlement mismatch affecting only cthompson (group membership drift, app/desktop assignment issue)
**Why this fits the scope facts:**
Single-user impact with no reported change fits access scoping issues where only one user's entitlement path changed (for example membership removal or stale token against updated group claims).

**Single fastest check:**
Validate current group/app assignment for cthompson and force token refresh/sign-out-sign-in to confirm entitlement is still effective.

---

## Notes

- Ranking is probability-based from scope facts only.
- No single root cause is concluded yet.
- Next step should be to run the five fast checks in rank order and then re-rank based on evidence.

---

## Evidence Addendum - 2026-08-06

### Security Event Details Reviewed

**Source host:** DESKTOP-FB022  
**Incident window:** 2024-03-15 08:44-09:12

- 08:44:01 - Security Event 4776 (Audit Failure)  
	Domain controller credential validation failed for FINBRIDGE\cthompson.  
	Error code: 0xC000006A (wrong password).  
	Source workstation: DESKTOP-FB022.

- 08:44:03 - Security Event 4625 (Audit Failure)  
	FINBRIDGE\cthompson sign-in failed.  
	Failure reason: unknown user name or bad password.  
	Logon type: 2 (interactive).

- 08:44:28 - Security Event 4625 (Audit Failure)  
	FINBRIDGE\cthompson sign-in failed.  
	Failure reason: unknown user name or bad password.  
	Logon type: 2 (interactive).

- 08:44:55 - Security Event 4625 (Audit Failure)  
	FINBRIDGE\cthompson sign-in failed.  
	Failure reason: unknown user name or bad password.  
	Logon type: 2 (interactive).

- 08:44:56 - Security Event 4740 (Audit Failure)  
	User account FINBRIDGE\cthompson locked out.  
	Caller computer: DESKTOP-FB022.

- 08:45:10 - Security Event 4625 (Audit Failure)  
	FINBRIDGE\cthompson sign-in failed.  
	Failure reason: account locked out.  
	Logon type: 7 (unlock attempt).

- 08:45:44 - Security Event 4771 (Audit Failure)  
	Kerberos pre-authentication failed for FINBRIDGE\cthompson.  
	Failure code: 0x18 (wrong password).  
	Source IP: 10.10.8.112.

- 08:46:01 - Security Event 4771 (Audit Failure)  
	Kerberos pre-authentication failed for FINBRIDGE\cthompson.  
	Failure code: 0x18 (wrong password).  
	Source IP: 10.10.8.112.

- 08:46:33 - Security Event 4771 (Audit Failure)  
	Kerberos pre-authentication failed for FINBRIDGE\cthompson.  
	Failure code: 0x18 (wrong password).  
	Source IP: 10.10.8.112.

### Hypothesis Elimination Outcome (No Early Winner Selection During Elimination Step)

- **Supports:**
	- #1 Account lockout or credential state issue.

- **Neutral:**
	- #2 Recent password change not synchronized across sign-in paths.

- **Contradicts:**
	- #3 Conditional Access/MFA challenge failure.
	- #4 User profile/container issue.
	- #5 Session host assignment or entitlement mismatch.

### Surviving Hypothesis

**#1 - Account lockout or credential state issue (bad password retries, stale cached credential, or lockout threshold hit)**

This survives because the event sequence shows wrong-password attempts, lockout, post-lockout failure, and continued bad-password attempts from an additional source.

### Resolution Runbook

1. **Contain repeated bad-credential attempts first**
	 - Identify what endpoint/service is using source IP 10.10.8.112.
	 - Temporarily isolate that source from authentication attempts (disconnect network session, stop task/service, or sign out app session).
	 - Keep DESKTOP-FB022 in triage scope as the interactive source.

2. **Restore account access state**
	 - Confirm lockout status for FINBRIDGE\cthompson in AD.
	 - Unlock the account.
	 - If needed for certainty, reset password to a temporary known-good value and force change at next sign-in.

3. **Remove stale credentials on known sources**
	 - On DESKTOP-FB022, clear stored credentials in Credential Manager for corporate resources.
	 - Re-authenticate Office/Teams/OneDrive/VPN/mapped resources with the current password.
	 - On 10.10.8.112, update credentials in any saved context (services, scheduled tasks, mail profile, mobile app, legacy client).

4. **Validate successful authentication path**
	 - Perform one controlled sign-in test for cthompson.
	 - Confirm no new 4625, 4776, 4771, or 4740 events occur during/after test window.
	 - Confirm user can complete normal interactive sign-in and unlock.

5. **Monitor for recurrence**
	 - Observe security events for 30-60 minutes.
	 - If failures recur, trace the remaining source of stale credentials before repeating unlock operations.

6. **Close with prevention notes**
	 - Record the exact origin of repeated failures (device/service/IP).
	 - Add prevention guidance: after any password update, re-authenticate all apps/devices promptly to avoid lockout loops.
