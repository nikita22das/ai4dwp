# Incident RCA - User Login Failure (cthompson)
**Incident date:** 2024-03-15  
**RCA authored:** 2026-08-06  
**User:** FINBRIDGE\cthompson  
**Primary endpoint observed:** DESKTOP-FB022  
**Status:** Resolved  
**Service restoration time:** 09:09 AM

---

## 1. Executive Summary

At approximately 08:44, user FINBRIDGE\cthompson could not complete login due to repeated bad-password authentication attempts that triggered account lockout. Evidence confirms interactive failures from DESKTOP-FB022 and additional Kerberos pre-authentication failures from a second source (10.10.8.112), indicating stale credentials were still being replayed after lockout. 

Resolution actions were applied to stop repeated bad credential attempts, restore account state, and clean up stale credential paths. Account was re-enabled at 09:08:14 and successful interactive login was confirmed at 09:09:01. Post-recovery verification indicated users were logging into hosts without further issues reported.

---

## 2. Incident Scope and Impact

- **Impacted user(s):** FINBRIDGE\cthompson only
- **Symptom:** Unable to login
- **Onset window:** ~08:40 onward
- **Reported change:** None
- **Business impact:** Individual productivity interruption for affected user; no broader pool-wide outage observed

---

## 3. Supporting Evidence

### 3.1 Failure Evidence (Security Log)

- **08:44:01 - Event 4776 (Audit Failure)**  
  DC credential validation failed for FINBRIDGE\cthompson.  
  Error 0xC000006A = wrong password.  
  Source workstation: DESKTOP-FB022.

- **08:44:03 - Event 4625 (Audit Failure)**  
  Failed interactive logon for FINBRIDGE\cthompson.  
  Reason: unknown user name or bad password.  
  Logon type: 2.  
  Source: DESKTOP-FB022.

- **08:44:28 - Event 4625 (Audit Failure)**  
  Failed interactive logon (same reason/type/source as above).

- **08:44:55 - Event 4625 (Audit Failure)**  
  Failed interactive logon (same reason/type/source as above).

- **08:44:56 - Event 4740 (Audit Failure)**  
  Account FINBRIDGE\cthompson locked out.  
  Caller computer: DESKTOP-FB022.

- **08:45:10 - Event 4625 (Audit Failure)**  
  Failed unlock attempt.  
  Reason: account locked out.  
  Logon type: 7.  
  Source: DESKTOP-FB022.

- **08:45:44 - Event 4771 (Audit Failure)**  
  Kerberos pre-authentication failed for FINBRIDGE\cthompson.  
  Failure code 0x18 = wrong password.  
  Source IP: 10.10.8.112.

- **08:46:01 - Event 4771 (Audit Failure)**  
  Kerberos pre-authentication failed (same account/code/source IP).

- **08:46:33 - Event 4771 (Audit Failure)**  
  Kerberos pre-authentication failed (same account/code/source IP).

### 3.2 Recovery Evidence (Security Log)

- **09:08:14 - Event 4722 (Audit Success)**  
  User account enabled.  
  Account: FINBRIDGE\cthompson.  
  Action by: FINBRIDGE\helpdesk-admin.

- **09:09:01 - Event 4624 (Audit Success)**  
  Successful interactive logon.  
  Account: FINBRIDGE\cthompson.  
  Logon type: 2.  
  Source: DESKTOP-FB022.

### 3.3 Verification Statement

- Service desk verification confirms issue resolved at **09:09 AM**.
- User login to host(s) confirmed successful.
- No additional related issues reported after recovery.

---

## 4. Consolidated Timeline (All Key Milestones)

- **~08:40** - User-reported inability to login begins.
- **08:44:01** - First confirmed wrong-password validation failure (4776).
- **08:44:03 to 08:44:55** - Repeated interactive failed logons (4625 x3).
- **08:44:56** - Account lockout triggered (4740).
- **08:45:10** - Post-lockout failure on unlock attempt (4625, type 7).
- **08:45:44 to 08:46:33** - Additional Kerberos wrong-password attempts from secondary source IP 10.10.8.112 (4771 x3).
- **09:08:14** - Account enabled by helpdesk-admin (4722).
- **09:09:01** - Successful interactive login (4624).
- **09:09** - Incident declared resolved; user login flow validated.

---

## 5. Root Cause Statement

**Primary root cause:** Account lockout caused by repeated invalid credential submissions for FINBRIDGE\cthompson.

**Contributing factor:** At least one additional source (10.10.8.112) continued to submit stale/incorrect credentials, increasing lockout persistence risk.

**Non-causal factors ruled out during elimination:**
- Conditional Access/MFA-specific failure pattern
- User profile/container initialization failure pattern
- Session host entitlement mismatch pattern

---

## 6. 5-Why Analysis

1. **Why was the user unable to login?**  
   Because the account was locked and authentication attempts were failing.

2. **Why was the account locked?**  
   Because multiple bad-password attempts were recorded in a short period.

3. **Why were there multiple bad-password attempts?**  
   Because incorrect/stale credentials were entered or replayed repeatedly from the user endpoint and another source.

4. **Why were stale credentials still being replayed after failures?**  
   Because at least one additional device/service context (source IP 10.10.8.112) retained incorrect credentials and continued background authentication attempts.

5. **Why was this not prevented before lockout occurred?**  
   Because credential hygiene controls and operational detection around stale saved credentials were not fast enough to interrupt repeated retries before lockout threshold was reached.

**5-Why conclusion:** The incident was driven by stale/incorrect credential replay causing lockout, with inadequate early interruption of repeated failed attempts across all credential sources.

---

## 7. Resolution Actions Applied

- Identified lockout/failure pattern from security events.
- Contained repeated bad credential attempts (including secondary source path).
- Restored account access state (account enabled/unlocked by helpdesk-admin).
- Validated successful interactive logon for FINBRIDGE\cthompson.
- Confirmed post-fix stability with no immediate recurrence reports.

---

## 8. Preventive Actions

### 8.1 Immediate Preventive Controls (Operational)

1. Add a lockout-response checklist to triage SOP:
   - Check 4625/4776/4771/4740 sequence first.
   - Identify all active credential sources (endpoint, mobile, services, scheduled tasks, mapped resources).

2. During lockout incidents, perform credential source containment before repeated unlock operations.

3. Require stale credential cleanup on user endpoint after password issues:
   - Credential Manager entries
   - Office/Teams/OneDrive/VPN sessions
   - Mapped resources and legacy app auth caches

### 8.2 Medium-Term Controls (Engineering)

1. Implement alerting for repeated failed auth bursts per user across multiple source IPs within short windows.
2. Add automated enrichment to lockout tickets with source host/IP correlation.
3. Run periodic hygiene reviews for service/task contexts using user credentials where avoidable.
4. Publish user guidance for post-password-change sign-in refresh across all devices/apps.

### 8.3 Success Criteria for Prevention

- Reduced repeat lockout incidents for same user population.
- Faster mean time to identify credential source during lockout events.
- Decrease in failed-auth bursts that progress to lockout.

---

## 9. Lessons Learned

- Early interpretation of event ID chain is high-value for rapid diagnosis.
- Secondary auth sources can sustain lockout conditions even after local user attempts stop.
- Recovery verification should include both successful logon evidence and short-window recurrence monitoring.

---

## 10. Closure

Incident resolved at **09:09 AM** with confirmed successful login and no immediate follow-on issues reported.
