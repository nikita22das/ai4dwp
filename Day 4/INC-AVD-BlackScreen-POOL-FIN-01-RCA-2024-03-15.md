# AVD Incident RCA - Black Screen and Session Disconnects (POOL-FIN-01)

## Document Control

- Incident ID: INC-AVD-BLACKSCREEN-POOL-FIN-01-20240315
- Date of incident: 2024-03-15
- RCA prepared: 2026-08-06
- Impacted pool: POOL-FIN-01
- Comparison pool: POOL-FIN-02
- Incident status: Resolved
- Resolution confirmed: 10:00 AM (local)

---

## Executive Summary

Between approximately 07:00 and 10:00 AM, users connecting to POOL-FIN-01 experienced black screen behavior and repeated session disconnects after successful logon. Evidence from affected session host SHFIN-01-A shows repeated Desktop Window Manager (dwm.exe) crashes in Intel graphics module igdumd64.dll, immediately followed by DWM termination and session disconnect. Comparison host SHFIN-02-A (pre-update image) showed normal DWM startup with no corresponding application crashes.

The root cause was a GPU/display driver regression introduced with the overnight image update to POOL-FIN-01. The remediation (driver/image rollback to known-good state and controlled host recovery) was applied, and by 10:00 AM users were successfully logging in across POOL-FIN-01 with no additional issue reports.

---

## Scope and Business Impact

- User-visible symptom: Black screen post-login; for some users temporary recovery, for others persistent failure.
- Service impact: Login productivity interruption for affected POOL-FIN-01 users.
- Affected population: Approximately 40 percent of users landing on updated hosts in POOL-FIN-01.
- Unaffected control group: POOL-FIN-02 users and hosts remained stable during the same window.

---

## Supporting Evidence

### 1) Affected host event chain (SHFIN-01-A)

Window reviewed: 07:00-07:30 (Application + System)

- 07:02:10 - TerminalServices-LocalSessionManager Event 21
  Session logon succeeded (FINBRIDGE\\mlopez, Session 3).
- 07:02:14 - Kernel-General Event 1
  Boot time indicates host restart following overnight update cycle.
- 07:02:16 - Application Error Event 1000
  Faulting application dwm.exe; faulting module igdumd64.dll; exception 0xc0000005.
- 07:02:17 - TerminalServices-LocalSessionManager Event 40
  Session disconnected (Session 3).
- 07:02:18 - Desktop Window Manager Event 9009
  DWM exited with code 0x40010004.
- 07:02:44 - TerminalServices-LocalSessionManager Event 21
  Reconnect succeeded.
- 07:02:46 - Application Error Event 1000
  Repeat dwm.exe crash in igdumd64.dll.
- 07:02:47 - TerminalServices-LocalSessionManager Event 40
  Session disconnected again.
- 07:03:01 - Desktop Window Manager Event 9009
  Repeat DWM exit.
- 07:03:10 - TerminalServices-LocalSessionManager Event 21
  Second reconnect succeeded (new session ID).
- 07:08:24 - Application Error Event 1000
  Same crash signature repeated for another user logon flow.

Interpretation: Authentication succeeds first, then display compositor crashes, then disconnect occurs. This sequence strongly indicates graphics stack instability rather than credential, policy, or broker failure.

### 2) Control host evidence (SHFIN-02-A, unaffected)

- 07:01:44 - TerminalServices-LocalSessionManager Event 21
  Session logon succeeded.
- 07:01:46 - Desktop Window Manager Event 9011
  DWM started successfully.
- No Application Error Event 1000 entries in the same observation window.

Interpretation: Shared AVD platform components remained healthy. Differential behavior aligns with image-content difference, not platform-wide external dependency failure.

### 3) Hypothesis elimination summary

- FSLogix regression: Contradicted by direct, repeated graphics module crash signature.
- Logon script/startup blocker: Contradicted by immediate post-logon DWM crash chain.
- Shell/Winlogon misconfiguration: Contradicted because logon succeeds before failure occurs.
- GPU/display driver regression: Supported by repeated Event 1000 (dwm.exe + igdumd64.dll) plus Event 9009 exits.
- Partial rollout: Supported as spread mechanism (why only subset was affected), not defect source.

---

## Detailed Timeline

- 02:00 - Overnight image update wave applied to POOL-FIN-01.
- 02:03:11 - SHFIN-01-A boot time recorded (observed later via Event 1 at 07:02:14).
- ~07:00 - User reports begin: black screen after login in POOL-FIN-01.
- 07:02:10 - User logon succeeds on SHFIN-01-A (Event 21).
- 07:02:16 - First observed dwm.exe crash in igdumd64.dll (Event 1000).
- 07:02:17 to 07:03:01 - Repeated disconnect and DWM exit cycle (Events 40 and 9009), with reconnect attempts.
- 07:08:24 - Same crash pattern recurs for additional logon flow (Event 1000).
- 07:18 - Incident formally logged for investigation.
- 07:20 to 09:30 - Containment and remediation actions executed on affected hosts (drain, rollback/known-good alignment, controlled validation).
- 10:00 - Resolution verified: users logging in to POOL-FIN-01 successfully; no active issue reports.

---

## Root Cause Statement

A GPU/display driver regression introduced in the updated POOL-FIN-01 image caused dwm.exe to crash in Intel graphics module igdumd64.dll during session initialization. The resulting Desktop Window Manager termination triggered user-facing black screen behavior and repeated session disconnects.

---

## 5 Whys Analysis

1. Why did users see black screens and disconnects after login?
Because user sessions lost desktop compositor stability immediately after authentication due to DWM process failure.

2. Why did DWM fail?
Because dwm.exe repeatedly crashed with access violation in igdumd64.dll (Application Error Event 1000).

3. Why was igdumd64.dll failing on affected hosts?
Because the updated image introduced a regressed or incompatible display driver state on POOL-FIN-01 hosts.

4. Why did only part of the population fail?
Because only hosts in the updated wave carried the regressed driver state, creating partial pool impact based on host assignment.

5. Why was this not prevented before production exposure?
Because pre-release image validation did not include sufficient AVD-specific graphics stability checks under representative multi-user logon conditions, and rollout gating did not halt early on crash telemetry.

---

## Resolution Actions Performed

1. Containment
- Restricted new session placement to confirmed healthy hosts.
- Drained active sessions from symptomatic hosts during maintenance activity.

2. Technical remediation
- Reverted affected hosts to a known-good driver/image state.
- Rebooted remediated hosts and validated login behavior.

3. Validation
- Performed canary login verification on remediated hosts.
- Confirmed no new Event 1000 dwm.exe/igdumd64.dll crashes during validation window.
- Confirmed no recurring Event 9009 DWM exit and disconnect loop.

4. Service confirmation
- At 10:00 AM, users were verified logging in to POOL-FIN-01 without incident.
- No additional helpdesk reports consistent with the prior symptom pattern.

---

## Preventive and Corrective Actions (CAPA)

### Immediate corrective controls

- Pin validated display driver version in production image baseline.
- Block automatic graphics driver drift in image build and post-deploy stages.
- Keep previous known-good image available for rapid rollback.

### Preventive controls for future releases

- Add pre-production AVD graphics validation suite:
  - repeated sign-in/sign-out cycles,
  - concurrent user session load,
  - DWM stability checks,
  - session reconnect testing.
- Introduce staged rollout gates with automatic stop conditions on:
  - Event 1000 burst for dwm.exe + igdumd64.dll,
  - correlated Event 21 to Event 40/9009 patterns.
- Require change advisory sign-off for display driver version changes.
- Maintain host-to-image and host-to-driver inventory for rapid blast-radius identification.

### Monitoring and observability improvements

- Create alert rule for repeated Application Error Event 1000 where:
  - Faulting application is dwm.exe,
  - Faulting module is igdumd64.dll.
- Create correlation alert for per-host sequence:
  - Event 21 (logon success) followed by Event 9009 and/or Event 40 within short interval.
- Add incident dashboard slice by host image version and driver version.

---

## Closure Criteria and Evidence of Stability

- User access restored: Yes (verified by 10:00 AM).
- Symptom recurrence during post-fix observation: None reported.
- Affected pool operational status: Stable.
- RCA completed with identified root cause, evidence chain, and preventive controls: Yes.

---

## Residual Risk and Follow-up

- Residual risk: Future image updates may reintroduce display instability if driver governance is bypassed.
- Follow-up review: Conduct post-implementation review after next scheduled image wave to confirm CAPA effectiveness.
