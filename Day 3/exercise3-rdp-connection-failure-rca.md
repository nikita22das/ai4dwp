# Exercise 3 - RDP Connection Failure RCA

**Analyst:** DWP Endpoint Support  
**Date:** 2026-08-07  
**Incident Window (from logs):** 2024-03-15 14:01:02 to 14:22:09  
**Affected Account:** FINBRIDGE\\bwalker  
**Source Client IP:** 10.10.5.44

---

## 1. Incident Summary

A user attempted to connect over RDP (RemoteInteractive logon type 10) from 10.10.5.44 to a Windows endpoint. The session experienced repeated authentication failures (Security Event ID 4625 with "Unknown username or bad password"), followed by account lockout (Security Event ID 4740). A later connection attempt from the same source IP succeeded (Security Event ID 4624), and the system logged acceptance of a new TCP RDP connection (System Event ID 131).

Most likely primary cause: repeated invalid credentials leading to account lockout, with at least one associated RDP protocol/security-layer disconnect event during failed attempts.

---

## 2. Timeline (Chronological, Plain English)

1. **14:01:02** - System Event ID 56 (TermDD, Error): RDP security layer reports a protocol stream error and disconnects the client at 10.10.5.44.
2. **14:01:02** - System Event ID 140 (RdpCoreTS, Warning): Connection from 10.10.5.44 fails because username or password is not correct.
3. **14:01:04** - Security Event ID 4625 (Audit Failure): RemoteInteractive logon failure for FINBRIDGE\\bwalker from 10.10.5.44, reason "Unknown username or bad password."
4. **14:03:18** - Security Event ID 4625 (Audit Failure): Second failed RemoteInteractive logon for FINBRIDGE\\bwalker from 10.10.5.44, same bad credential reason.
5. **14:05:33** - Security Event ID 4625 (Audit Failure): Third failed RemoteInteractive logon for FINBRIDGE\\bwalker from 10.10.5.44, same bad credential reason.
6. **14:05:34** - Security Event ID 4740 (listed as Audit Failure in provided data): Account FINBRIDGE\\bwalker is locked out; caller computer is 10.10.5.44.
7. **14:22:07** - System Event ID 131 (RdpCoreTS, Info): Server accepts a new TCP connection from 10.10.5.44:52341.
8. **14:22:09** - Security Event ID 4624 (Audit Success): Successful RemoteInteractive logon for FINBRIDGE\\bwalker from 10.10.5.44.

Plain-English sequence: the user had multiple bad-password RDP attempts, the account then locked, and after a gap (likely unlock/reset/wait for lockout duration) a new RDP attempt succeeded.

---

## 3. Event ID Analysis (What Each Event Records)

## Event ID 56 (System, Source: TermDD)
- Records that the Terminal Services security layer detected a protocol stream/security-layer error and disconnected the client.
- In this incident, it occurred at the same second as Event ID 140. By itself it does not prove a persistent transport network issue.

## Event ID 140 (System, Source: RemoteDesktopServices-RdpCoreTS)
- Records an RDP connection failure tied to incorrect username/password.
- In this incident, it directly points to credential validation failure from 10.10.5.44.

## Event ID 4625 (Security)
- Records a failed logon attempt.
- Here, all 4625 entries are Logon Type 10 (RemoteInteractive), account FINBRIDGE\\bwalker, source 10.10.5.44, reason "Unknown username or bad password."
- This is direct evidence of authentication failure caused by invalid credentials (or username mismatch/format issue).

## Event ID 4740 (Security)
- Records that an account was locked out.
- In this incident, FINBRIDGE\\bwalker was locked out with caller computer 10.10.5.44 immediately after repeated 4625 failures.
- Note of uncertainty to validate: the provided row labels this as "Audit Failure." In many environments, 4740 is typically logged as an account-management success audit event. The event meaning (account locked out) is still clear.

## Event ID 131 (System, Source: RemoteDesktopServices-RdpCoreTS)
- Records that the server accepted a new TCP connection for RDP from a client endpoint/port.
- This indicates network path and TCP reachability were working at that time.

## Event ID 4624 (Security)
- Records a successful logon.
- In this incident, Logon Type 10 for FINBRIDGE\\bwalker from 10.10.5.44 confirms successful RDP authentication and session establishment path after earlier failures.

---

## 4. Required Classification of Observed Events

### Authentication failures present
- Yes: Event ID 4625 at 14:01:04, 14:03:18, 14:05:33.
- Yes: Event ID 140 at 14:01:02 explicitly says username/password not correct.

### Protocol failures present
- Yes: Event ID 56 at 14:01:02 (protocol stream/security-layer disconnect).

### Account lockout events present
- Yes: Event ID 4740 at 14:05:34.

### Successful logon events present
- Yes: Event ID 4624 at 14:22:09.

---

## 5. Technical Analysis

### Primary causal chain supported by logs
1. Repeated bad credentials were submitted for RemoteInteractive logon (three 4625 events).
2. Lockout threshold was reached and the account was locked (4740 one second after third 4625).
3. Later, from same client IP and same account, a successful logon occurred (4624), indicating credentials/account state was corrected.

### Interpretation of the protocol error (Event 56)
- Event 56 shows an RDP security/protocol-layer disconnect, but it appears at the same time as explicit bad-credential signaling (140, then 4625).
- This makes it more likely a symptom observed during failed authentication/handshake flow rather than the dominant root cause.
- Certainty note: with only the listed events and no Schannel/CAPI/RDP extended traces, we cannot fully exclude a transient protocol negotiation anomaly. However, subsequent successful 4624 and accepted TCP connection argue strongly against a persistent protocol stack failure.

### Network assessment
- Later accepted TCP connection (131) and successful 4624 from same source IP are strong evidence that basic network path was functional.
- A persistent network outage is unlikely.

---

## 6. Evidence Table

| Evidence | Why It Matters |
|---|---|
| Event 4625 x3 with reason "Unknown username or bad password" | Direct proof of repeated authentication failures using invalid credentials. |
| Event 4740 immediately after third 4625 | Indicates lockout was consequence of repeated failed auth attempts. |
| Event 140 says username/password not correct | Corroborates credential problem at RDP service layer. |
| Event 4624 later for same account/IP | Confirms eventual successful authentication; problem was not permanently infrastructural. |
| Event 131 accepted TCP connection | Shows reachability to RDP endpoint at transport level. |
| Event 56 protocol stream/security-layer disconnect | Shows protocol-level disconnect occurred, but timing suggests secondary effect in failed auth flow. |

---

## 7. Most Likely Cause of the RDP Connection Failure

Most likely cause: **invalid credentials causing repeated authentication failures, which then triggered account lockout**. 

Why this is most likely:
1. Multiple explicit bad-password failures (4625) for RemoteInteractive logon.
2. Immediate lockout event (4740) after the repeated failures.
3. Later successful logon (4624) indicates no persistent network or server-side RDP service failure.
4. Event 140 explicitly attributes failure to incorrect username/password.

---

## 8. Alternate Theories and Why They Are Less Likely

1. **Primary RDP protocol defect**
- Less likely because successful RDP authentication occurred later from same source IP/account.
- Protocol error (56) is present but not persistent in the provided sequence.

2. **Network issue**
- Less likely because TCP connection was accepted later (131) and authentication eventually succeeded (4624).
- No events provided indicating packet loss, name resolution failure, or host unreachable.

3. **Server-side RDP service outage**
- Less likely due to successful session establishment later in same incident window.

4. **Unknown account rather than bad password**
- Possible in theory because 4625 reason combines both conditions, but repeated attempts on a valid domain account followed by eventual success strongly supports bad password entry (or stale cached password) rather than nonexistent account.

---

## 9. Issue Type Determination

This incident is primarily a **combination of multiple issues**, with one dominant factor:

- Dominant: **Invalid credentials / authentication failure**.
- Secondary consequence: **Account lockout**.
- Additional but likely non-primary symptom: **RDP protocol/security-layer disconnect event**.
- Not primary: **Network issue**.

Reasoning: The sequence, event semantics, and eventual successful logon align with credential/authentication problems that escalated into lockout, not a persistent network or protocol outage.

---

## 10. Impact

- User impact: user could not establish RDP session during failed-attempt and lockout period.
- Service impact: endpoint RDP service appears available overall, but access was blocked by authentication state.
- Security impact: lockout policy worked as designed to protect account after repeated failures.

---

## 11. Containment Actions

1. Confirm lockout state and unlock account per policy (or wait lockout duration if policy requires).
2. Verify user identity and reset password if compromise or repeated mistype is suspected.
3. Instruct user to test sign-in with confirmed account format (DOMAIN\\username or UPN) before retrying RDP.
4. Review for concurrent stale credential sources (saved RDP credentials, mapped drives, scheduled tasks, mobile mail clients) that may continue bad attempts.

---

## 12. Corrective Actions

1. Clear and recreate saved credentials in Windows Credential Manager and .rdp profile for this target.
2. Verify AD account status, lockout policy thresholds, and whether password changed recently.
3. Confirm client and server time synchronization (Kerberos tolerance) even though this log set does not show clock-skew errors.
4. Capture and review related logs (Security 4771/4776/4648 if present, TerminalServices operational logs) for fuller auth path visibility.

---

## 13. Preventive Actions

1. User guidance on correct domain credential format for RDP.
2. Enable alerting on repeated 4625 Type 10 failures followed by 4740 from same source IP.
3. Encourage password manager or approved process to avoid repeated manual entry errors.
4. Periodic review of lockout threshold policy to balance security and usability.
5. Train support to check for hidden credential replay sources after lockout incidents.

---

## 14. 5 Why Analysis

1. **Why did the RDP connection fail initially?**  
Because authentication attempts were rejected as bad username/password.

2. **Why were authentication attempts rejected?**  
Because incorrect credentials (or incorrect username format) were submitted repeatedly from 10.10.5.44.

3. **Why did this escalate to a prolonged access issue?**  
Because repeated failures reached lockout threshold, generating Event 4740.

4. **Why could the user not connect until later?**  
Because account lockout prevented successful authentication until unlock/reset/lockout window expiration occurred.

5. **Why was this not prevented earlier?**  
Because stale/saved credentials or repeated manual entry errors were likely not detected and corrected before lockout threshold was reached.

Root cause from 5 Why: credential handling failure (entry/storage/format) leading to lockout; protocol event appears contributory or symptomatic, not principal.

---

## 15. Items to Verify Against Microsoft Documentation

1. Exact semantics and typical causes of TermDD Event ID 56 in modern Windows builds.
2. RdpCoreTS Event ID 140 and 131 field interpretations for the OS/server version in use.
3. Security Event ID 4625 failure reason mapping for "Unknown username or bad password" and relevant substatus codes (if available in full event XML).
4. Security Event ID 4740 audit category behavior (noting discrepancy between provided "Audit Failure" label and commonly expected logging patterns).
5. Logon Type 10 (RemoteInteractive) interpretation and correlation best practice with RDP events.
6. Recommended Microsoft workflow for diagnosing repeated 4625 + 4740 lockout patterns (including stale credential sources).

---

## 16. Analyst Confidence and Uncertainty

- **High confidence:** repeated invalid credential attempts and resulting lockout are the primary incident mechanism.
- **Medium confidence:** Event 56 is secondary/symptomatic rather than root cause.
- **Uncertain without extra logs:** whether bad credentials came from user typo, cached credentials, or automated background process.

---

## 17. Business Impact

- Temporary interruption of remote access to a business endpoint for the affected user.
- Potential delay to time-sensitive work that depends on RDP-only access (line-of-business tools, shared desktop apps, and controlled environment resources).
- Increased Service Desk handling time due to lockout recovery and credential validation tasks.
- Minor security operations overhead due to lockout event triage and verification.

---

## 18. User Impact

- User was unable to establish RDP access during the failed-attempt and lockout period.
- User likely experienced repeated sign-in prompts/failures before successful access was restored.
- Productivity degradation was time-bounded and localized to the affected identity/session.

---

## 19. Severity Assessment

- **Recommended severity:** SEV3 (localized user impact, no evidence of widespread endpoint/network/platform outage).
- **Why SEV3 fits:**
1. Single account and single observed source endpoint behavior.
2. Core endpoint/service path later recovered (Event 131 and Event 4624).
3. No evidence in provided logs of multi-user service degradation.
- **Escalate to SEV2 if:** multiple users/accounts/hosts show concurrent 4625/4740 RDP failures.
- **Escalate to SEV1 if:** broad inability to access critical remote services with no viable workaround.

---

## 20. Authentication Flow Analysis

1. Client 10.10.5.44 initiated RDP to the target endpoint.
2. RDP stack reported credential rejection at service layer (Event 140).
3. Security subsystem recorded failed RemoteInteractive logons (Event 4625, type 10).
4. Repeated failed authentication attempts crossed policy threshold.
5. Account lockout was enforced (Event 4740).
6. A later RDP attempt from same source proceeded with accepted TCP connection (Event 131).
7. Authentication then succeeded (Event 4624, type 10), confirming restored credential/account state.

Interpretation: the control point that blocked access was authentication and lockout policy enforcement, not persistent transport failure.

---

## 21. Account Lockout Analysis

- Lockout event occurred immediately after the third observed failed RemoteInteractive logon.
- Caller computer in Event 4740 matches the RDP source IP context (10.10.5.44), linking lockout to that client activity.
- Most probable lockout path is repeated invalid password submission (manual entry error or stale cached credential replay).
- Less certain but possible contributors include hidden background credential retries (saved RDP creds, scheduled tasks, mapped resources, mobile/legacy clients).
- Recovery evidence (later 4624 success) indicates lockout was temporary/resolved through unlock, password correction, reset, or lockout-duration expiry.

---

## 22. Recommended Service Desk Actions

1. Verify user identity and confirm exact sign-in format to use (DOMAIN\\username or UPN).
2. Check whether account is currently locked and unlock per policy/workflow.
3. If needed, initiate password reset and confirm first successful sign-in on a known-good path.
4. Remove stale entries from Credential Manager and cached `.rdp` credentials on the client.
5. Capture incident artifacts: timestamps, source IP, account, and event IDs (56/140/4625/4740/131/4624).
6. Advise user to stop repeated retries until credential state is validated to prevent re-lockout.
7. If immediate reconnect still fails, escalate to DWP Engineering with collected evidence bundle.

---

## 23. Recommended DWP Engineering Actions

1. Correlate target endpoint logs with Domain Controller security logs for the same timeline.
2. Review TerminalServices operational logs for handshake/authentication detail around Event 56.
3. Validate endpoint RDP security settings (NLA requirement, security layer mode, TLS policy) against baseline.
4. Confirm no policy drift on lockout threshold, lockout duration, and reset counters.
5. Implement detection logic for repeated `4625 (Type 10)` followed by `4740` from same source.
6. Produce a known-issues note for stale credential replay patterns and standard triage steps.
7. Where possible, automate first-response lockout diagnostics to reduce MTTR.

---

## 24. Recommended Active Directory Checks

1. Confirm account status: enabled/disabled, locked/unlocked, password last set, bad password count.
2. Check lockout policy values applied to the user scope:
	- lockout threshold
	- lockout duration
	- reset account lockout counter after
3. Validate recent password changes and replication status across domain controllers.
4. Identify authenticating DC for failed attempts and compare with PDC emulator records.
5. Review Security events relevant to auth path (for example 4740, 4771, 4776, 4625) on DCs.
6. Confirm no account restrictions blocking logon (logon hours, workstation restrictions, smart card requirements where applicable).

---

## 25. Recommended RDP Troubleshooting Actions

1. Test connectivity basics from client to target (`Test-NetConnection <host> -Port 3389`).
2. Verify DNS resolution and host targeting are correct (avoid connecting to stale/wrong endpoint aliases).
3. Validate client credential entry and clear saved credentials before reattempt.
4. Confirm target host accepts RDP and has healthy listener/service state.
5. Check NLA/TLS compatibility between client and target after updates or hardening changes.
6. Review for local client-side replay sources (Credential Manager, mapped drives, background apps using old password).
7. Re-test with a controlled known-good account (if policy permits) to isolate user-specific vs host-specific issues.
8. If protocol errors persist without auth failures, collect deeper traces (Schannel, TerminalServices logs, packet capture) for protocol-level investigation.
