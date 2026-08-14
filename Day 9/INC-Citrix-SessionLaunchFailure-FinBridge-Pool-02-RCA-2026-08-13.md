# Incident RCA - Citrix Session Launch Failure (FinBridge-VDI-Pool-02)

## Document Control

- Incident ID: INC-CITRIX-POOL02-LAUNCHFAIL-20260813
- Date of incident evidence: 2026-08-13 (from provided logs)
- RCA prepared: 2026-08-13
- Impacted service: Citrix VDI session launch
- Impacted pool: FinBridge-VDI-Pool-02
- Comparison pool: FinBridge-VDI-Pool-01
- Status: Resolved (remediation plan finalized from evidence set)

---

## Executive Summary

Users in FinBridge-VDI-Pool-02 experienced session launch failures due to insufficient registered machines available to the broker. The evidence chain shows broad machine unregistration in Pool-02, failed VDA registration attempts to dc-vdi-02 on port 80 with connection refused, and Citrix Broker Service confirmed STOPPED on dc-vdi-02. In the same period, Pool-01 remained healthy and was served by dc-vdi-01 where Broker Service was RUNNING.

The finalized root cause hypothesis is a Broker Service outage on dc-vdi-02, likely associated with post-update host state (reboot required), causing Pool-02 registration collapse and broker launch failures.

---

## Scope and Business Impact

- Affected population: 22 of 30 users in FinBridge-VDI-Pool-02.
- User-facing symptom: Session launch failure from broker.
- Unaffected cohort: FinBridge-VDI-Pool-01 users.
- Business effect: Material access disruption for majority of Pool-02 user population.

---

## Supporting Evidence

### 1) Session Broker log evidence

- [08:58:04] Broker querying available machines in Pool-02.
- [08:58:34] Broker timeout waiting for machine registration response (30000ms exceeded).
- [08:58:34] Session launch FAILED: error 1030.
- Error text: 'No machines available in the desktop group'.

Interpretation supported by evidence:
- Launch failed due to lack of available/registered machines at brokering moment.

### 2) Machine catalog registration evidence

- Pool-02 catalog:
  - 25 provisioned
  - 3 registered
  - 22 unregistered
  - 0 maintenance mode
- Pool-01 catalog:
  - 20 provisioned
  - 19 registered
  - 1 unregistered

Interpretation supported by evidence:
- Pool-02 experienced severe registration deficit while Pool-01 remained near healthy baseline.

### 3) Unregistered VDA detail (Pool-02 sample)

- VDI-P02-014 and VDI-P02-017 last registration attempts failed.
- Error on both: Unable to contact Delivery Controller.
- Endpoint: dc-vdi-02.finbridge.local:80 - connection refused.

Interpretation supported by evidence:
- Affected VDAs attempted to reach dc-vdi-02 but controller endpoint rejected connection.

### 4) Delivery Controller health evidence

- dc-vdi-02:
  - Citrix Broker Service: STOPPED
  - Last known running: yesterday 23:40
  - Windows Update installed: today 00:15
  - Reboot required flag set; host not rebooted
- dc-vdi-01 (serves Pool-01):
  - Citrix Broker Service: RUNNING
  - Uptime: 14 days

Interpretation supported by evidence:
- Controller state divergence aligns with pool impact divergence.

### 5) Error code handling note

- Confirmed exact log data: error 1030 with text 'No machines available in the desktop group'.
- No additional vendor-wide semantic claim for 1030 is asserted beyond provided message text.

---

## Detailed Timeline (From Provided Data)

- Yesterday 23:40
  - dc-vdi-02 last known Broker Service running.
- Today 00:15
  - Windows Update installed on dc-vdi-02; reboot required flag set.
- 06:15:22
  - VDI-P02-014 registration attempt failed to dc-vdi-02:80 (connection refused).
- 06:16:01
  - VDI-P02-017 registration attempt failed to dc-vdi-02:80 (connection refused).
- 08:58:03
  - User jsmith session launch requested to Pool-02.
- 08:58:04
  - Broker queried available machines in Pool-02.
- 08:58:34
  - Broker timeout (30000ms exceeded).
- 08:58:34
  - Session launch failed, error 1030, message 'No machines available in the desktop group'.

---

## Hypothesis Ranking Considered

1. Broker Service outage on dc-vdi-02 causing Pool-02 mass unregistration. (Most probable)
2. Pool-02 VDA registration configuration lacking controller redundancy (dc-vdi-01 not effective fallback).
3. Post-update pending reboot state on dc-vdi-02 causing service non-availability.

Finalized hypothesis:
- Hypothesis 1 selected as primary root cause based on direct evidence.

---

## Root Cause Statement

The Citrix Broker Service on dc-vdi-02 was unavailable (stopped), causing Pool-02 VDA machines to remain unregistered and resulting in broker inability to allocate desktops for users in FinBridge-VDI-Pool-02.

Contributing condition:
- dc-vdi-02 had recent update activity with reboot-required state, increasing likelihood of service non-recovery/stability issue.

---

## 5 Whys Analysis

1. Why did users fail to launch sessions in Pool-02?
Because the broker had insufficient registered machines and timed out.

2. Why were machines unavailable to the broker?
Because most Pool-02 machines were unregistered (22 unregistered, 3 registered).

3. Why were those machines unregistered?
Because VDAs failed registration attempts to dc-vdi-02 with connection refused on port 80.

4. Why was dc-vdi-02 refusing those registration connections?
Because Citrix Broker Service on dc-vdi-02 was stopped.

5. Why was Broker Service stopped at incident time?
Most likely due to post-update/pending-reboot operational state and missing start-of-day controller health validation gate.

---

## Exact Remediation Steps

1. Notify and contain
- Notify stakeholders of active Pool-02 impact.
- Temporarily restrict new launches to known healthy capacity if required.

2. Recover dc-vdi-02 broker function
- Start Citrix Broker Service on dc-vdi-02.
- Set startup type to Automatic.
- If unstable or blocked by pending reboot conditions, perform controlled reboot.

3. Recover machine registrations
- Monitor Pool-02 registration counts until recovering toward baseline.
- On remaining stale hosts, restart Citrix Desktop Service and refresh policy.

4. Validate end-to-end launch
- Execute pilot user launches in Pool-02.
- Confirm no broker timeout and no recurrence of launch-failed events.

5. Return to standard operations
- Remove temporary restrictions.
- Close incident after stability window passes.

---

## Correct Order of Operations

1. Communication and containment.
2. dc-vdi-02 service recovery.
3. dc-vdi-02 reboot only if needed for stable broker operation.
4. VDA registration recovery checks.
5. Pilot launch validation.
6. Full service restoration.
7. Preventive hardening actions.

---

## Verification Checks (Post-Remediation)

Controller verification:
- dc-vdi-02 Broker Service is RUNNING and remains stable.
- No immediate service stop/crash recurrence in system/application logs.

Catalog verification:
- Pool-02 registered machines increase materially from 3 toward healthy baseline.
- Unregistered machines decrease from 22 toward baseline.

User verification:
- Representative Pool-02 users can launch sessions successfully.
- No new launch failures with 30000ms registration timeout pattern.

Comparison verification:
- Pool-01 remains healthy and unchanged.

---

## Preventive Actions

1. Controller patching runbook hardening
- Enforce reboot completion for patch cycles with reboot-required flags.
- Include mandatory Broker Service start/health verification before business hours.

2. Redundancy and configuration controls
- Ensure Pool-02 VDAs are configured with redundant DDC targets.
- Periodically validate failover registration behavior.

3. Monitoring and alerting
- Alert when Broker Service is stopped on any Delivery Controller.
- Alert when pool registration ratio drops below defined threshold.
- Alert on repeated broker timeout pattern leading to launch failures.

4. Operational readiness checks
- Add start-of-day controller and catalog health checklist.
- Gate incident closure on both technical and user-experience verification.

---

## Closure Criteria

- Broker Service healthy on dc-vdi-02.
- Pool-02 registration recovered to agreed baseline.
- User launch success validated across sample set.
- Preventive controls assigned and tracked.
