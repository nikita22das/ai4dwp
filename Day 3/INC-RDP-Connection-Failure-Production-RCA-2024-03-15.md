# Production Root Cause Analysis (RCA)

## Executive Summary

On 2024-03-15, user account FINBRIDGE\\bwalker experienced repeated Remote Desktop Protocol (RDP) connection failures from client IP 10.10.5.44. Security and System logs show multiple failed RemoteInteractive logons (Event ID 4625), followed by account lockout (Event ID 4740), then eventual successful RemoteInteractive logon (Event ID 4624) from the same source.

The most likely root cause is repeated invalid credential submission (or stale cached credentials) triggering account lockout policy enforcement. A protocol stream/security-layer disconnect event (TermDD Event ID 56) was observed, but available evidence indicates it was a concurrent symptom during failed authentication rather than the primary incident driver.

## Incident Description

A user attempted to establish an RDP session to a Windows endpoint. Initial attempts failed with bad-credential indicators and associated security logging. Repeated failed attempts reached the lockout threshold, causing temporary account lockout. After a delay, the account successfully authenticated via RDP from the same client, confirming endpoint reachability and eventual credential/account-state correction.

## Scope

- Incident type: Endpoint access/authentication incident (RDP)
- Incident date: 2024-03-15
- Affected identity: FINBRIDGE\\bwalker
- Source endpoint/IP: 10.10.5.44
- Evidence sources: Windows System log and Security log entries provided in incident dataset
- Confirmed impact scope: single user/session path in provided logs
- Out of scope: enterprise-wide prevalence assessment (not inferable from provided endpoint-only event subset)

## Timeline of Events

1. 2024-03-15 14:01:02 - Event ID 56 (System, TermDD, Error): Terminal Services security layer detected protocol stream error and disconnected client 10.10.5.44.
2. 2024-03-15 14:01:02 - Event ID 140 (System, RdpCoreTS, Warning): Connection from 10.10.5.44 failed due to incorrect username/password.
3. 2024-03-15 14:01:04 - Event ID 4625 (Security, Audit Failure): Failed RemoteInteractive logon (Type 10) for FINBRIDGE\\bwalker from 10.10.5.44, reason: unknown username or bad password.
4. 2024-03-15 14:03:18 - Event ID 4625 (Security, Audit Failure): Second failed Type 10 logon for same account/source/reason.
5. 2024-03-15 14:05:33 - Event ID 4625 (Security, Audit Failure): Third failed Type 10 logon for same account/source/reason.
6. 2024-03-15 14:05:34 - Event ID 4740 (Security, listed as Audit Failure in provided data): Account FINBRIDGE\\bwalker locked out; caller computer 10.10.5.44.
7. 2024-03-15 14:22:07 - Event ID 131 (System, RdpCoreTS, Info): Server accepted new TCP connection from 10.10.5.44:52341.
8. 2024-03-15 14:22:09 - Event ID 4624 (Security, Audit Success): Successful RemoteInteractive logon (Type 10) for FINBRIDGE\\bwalker from 10.10.5.44.

## Event ID Analysis

### Event ID 56 (System, TermDD)
- Records RDP security/protocol stream anomaly resulting in client disconnect.
- Indicates protocol/security-layer termination occurred during connection attempt.
- Does not independently prove persistent network failure.

### Event ID 140 (System, RemoteDesktopServices-RdpCoreTS)
- Records RDP connection failure attributed to incorrect username/password.
- Strongly aligns with authentication failure in this incident.

### Event ID 4625 (Security)
- Records failed logon attempts.
- In this case, all are Logon Type 10 (RemoteInteractive) for the same account/source, reason unknown username or bad password.
- Primary authentication-failure evidence.

### Event ID 4740 (Security)
- Records account lockout event.
- Here it follows immediately after repeated 4625 failures from same source context.
- Note: dataset labels this row as Audit Failure; exact audit-category labeling should be validated in full event metadata.

### Event ID 131 (System, RemoteDesktopServices-RdpCoreTS)
- Records accepted inbound TCP connection for RDP.
- Confirms network path and listener availability at that time.

### Event ID 4624 (Security)
- Records successful logon.
- Type 10 success confirms eventual successful RDP authentication/session establishment path.

## Authentication Failure Analysis

- Authentication failures are explicit and repeated:
1. Event ID 140 directly states username/password incorrect.
2. Event ID 4625 appears three times with Type 10 and bad-credential reason.
- Failure pattern is consistent with either:
1. Manual credential entry errors.
2. Stale saved credentials replayed by client tools/processes.
3. Username format mismatch (for example, DOMAIN\\username vs UPN) during attempts.
- Evidence does not indicate a persistent authentication service outage because later Type 10 success is recorded.

## Account Lockout Analysis

- Lockout event timing (4740 at 14:05:34) directly follows third failed 4625 at 14:05:33.
- This sequence is consistent with policy-based lockout threshold enforcement.
- Caller computer correlation to 10.10.5.44 ties lockout to the observed RDP attempt origin.
- Later successful 4624 indicates lockout condition was resolved (unlock/reset/expiry) before recovery attempt.

## Technical Findings

1. The RDP service path was reachable and functional during recovery window (Event 131 + Event 4624).
2. Authentication failures, not transport reachability, were the dominant blocker during initial attempts.
3. Account lockout was a direct downstream effect of repeated failed credentials.
4. Protocol/security-layer disconnect (Event 56) occurred but lacks evidence of persistence or independent recurrence after credential state was corrected.
5. Incident behavior supports a user/account-specific access issue rather than generalized platform outage in provided scope.

## Most Likely Root Cause

Repeated invalid credential submissions (or stale credential replay) during RDP RemoteInteractive logon attempts triggered account lockout policy, causing temporary access denial until account/credential state was corrected.

## Alternative Root Cause Theories

1. Primary RDP protocol issue
- Less likely: later successful Type 10 logon from same client/source context indicates no sustained protocol failure.

2. Network issue
- Less likely: accepted TCP RDP connection (Event 131) and successful 4624 contradict sustained network-path failure.

3. Endpoint RDP service instability
- Less likely: service accepted connection and authenticated successfully later within same incident window.

4. Nonexistent account/identity mismatch only
- Possible but less likely: eventual successful logon for same account suggests account exists and password/state changed or corrected.

## Evidence Supporting Root Cause

- Three Security Event ID 4625 failures for Type 10 with bad-credential reason.
- Security Event ID 4740 lockout immediately after repeated failures.
- System Event ID 140 explicitly states incorrect username/password.
- Later Security Event ID 4624 Type 10 success for same account/source.
- System Event ID 131 accepted TCP connection from same source.

## Impact Assessment

### Business Impact

- Temporary loss of remote endpoint access for affected user.
- Work interruption for tasks dependent on RDP-hosted resources.
- Service Desk and engineering effort required for lockout and credential-path triage.

### User Impact

- User unable to log on via RDP during failure/lockout period.
- Potential repeated retry loop and delayed productivity until unlock or credential correction.

### Severity Assessment

- Recommended severity: SEV3.
- Justification: localized single-user impact in provided evidence, no indication of widespread service outage, and eventual same-session-path recovery.
- Escalation criteria:
1. Move to SEV2 if multiple users/endpoints show similar concurrent lockout/auth patterns.
2. Move to SEV1 if broad critical access disruption occurs without workable alternatives.

## 5 Why Analysis

1. Why did RDP access fail initially?
Because authentication attempts were rejected for bad username/password.

2. Why were credentials rejected repeatedly?
Because incorrect or stale credentials were submitted multiple times.

3. Why did access remain blocked after repeated attempts?
Because account lockout policy threshold was reached and enforced.

4. Why was recovery not immediate?
Because lockout required unlock/reset or waiting for lockout duration before successful authentication could occur.

5. Why did retries continue to lockout threshold?
Because credential-validation and stale-credential checks were not completed before repeated attempts.

Root cause from 5 Why: credential handling failure path (manual entry or cached credentials) causing policy-driven lockout.

## Corrective Actions

1. Validate user identity and reset/unlock account per operational policy.
2. Remove cached RDP credentials and recreate clean connection profile.
3. Confirm correct credential format with user (DOMAIN\\username or UPN).
4. Correlate endpoint events with Domain Controller authentication logs for full path confirmation.
5. Verify no hidden credential replay sources (scheduled tasks, mapped resources, legacy clients).
6. Retest with controlled sign-in sequence and capture confirmation evidence.

## Preventive Actions

1. Implement proactive alerting for pattern: repeated 4625 Type 10 followed by 4740 from same source.
2. Publish Service Desk runbook for RDP auth-failure triage and lockout-safe handling.
3. Introduce user guidance to avoid repeated retries when first authentication failures occur.
4. Standardize credential cache hygiene for managed RDP clients.
5. Review lockout policy settings periodically to balance security and operational resilience.

## Ownership and Follow Up Items

- Service Desk Lead
1. Ensure first-line lockout triage checklist is used on all RDP auth incidents.
2. Confirm evidence capture minimum set (56/140/4625/4740/131/4624 + source IP/account).
- DWP Endpoint Engineering
1. Build detection/reporting for repeated Type 10 failures and lockout chains.
2. Validate endpoint RDP security baseline consistency.
- Active Directory Operations
1. Review lockout policy thresholds and replication behavior for affected OU/domain scope.
2. Provide DC-side event correlation procedure to incident responders.
- Security Operations
1. Track recurring lockout patterns for potential credential abuse vs user error differentiation.

Target follow-up milestones:
1. Runbook update: within 5 business days.
2. Monitoring rule implementation: within 10 business days.
3. Policy review and sign-off: within 15 business days.

## Lessons Learned

1. Early differentiation between authentication failure and network/protocol failure materially reduces time to resolution.
2. Rapid lockout can be avoided by stopping repeated retries and validating credential state immediately.
3. Event correlation across System and Security logs provides clear causal chain for RDP failures.
4. Protocol-layer error events should be interpreted with context; they are not always the primary fault domain.

## References That Should Be Verified Against Microsoft Documentation

1. TermDD Event ID 56 interpretation and known causes for current Windows build.
2. RemoteDesktopServices-RdpCoreTS Event IDs 131 and 140 semantics.
3. Security Event ID 4625 field/substatus interpretation for unknown username or bad password.
4. Security Event ID 4740 auditing behavior and lockout diagnostics guidance.
5. Logon Type 10 (RemoteInteractive) correlation guidance for RDP troubleshooting.
6. Microsoft-recommended lockout troubleshooting workflow, including stale credential-source identification.
