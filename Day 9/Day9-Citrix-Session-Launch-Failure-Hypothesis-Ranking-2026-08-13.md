# Day 9 - Citrix Session Launch Failure Hypothesis Ranking (FinBridge)

## Document Control

- Date: 2026-08-13
- Incident scenario: Citrix VDI session launch failure
- Affected pool: FinBridge-VDI-Pool-02
- Unaffected comparison pool: FinBridge-VDI-Pool-01

---

## Scope Facts Used (No New Assumptions)

- Affected users: 22 of 30 users in FinBridge-VDI-Pool-02.
- Unaffected pool: FinBridge-VDI-Pool-01.
- Broker sequence for failed launch:
  - Timeout waiting for machine registration response (30000ms exceeded)
  - Session launch failed with error 1030
  - Error text: 'No machines available in the desktop group'
- Pool-02 catalog:
  - 25 provisioned, 3 registered, 22 unregistered, maintenance mode 0.
- Pool-01 catalog:
  - 20 provisioned, 19 registered, 1 unregistered.
- Unregistered machine sample from Pool-02:
  - Registration failed with 'Unable to contact Delivery Controller'
  - dc-vdi-02.finbridge.local:80 - connection refused
- Delivery Controller health:
  - dc-vdi-02: Citrix Broker Service STOPPED; last running yesterday 23:40; Windows Update installed at 00:15; reboot required flag set.
  - dc-vdi-01 (serves Pool-01): Citrix Broker Service RUNNING; uptime 14 days.

Note on error code interpretation:
- The exact broker error is confirmed from provided logs: error 1030 with text 'No machines available in the desktop group'.
- I am not asserting any broader vendor-wide meaning for code 1030 beyond the message shown in this data.

---

## Ranked Hypotheses (Most Probable First)

### 1) Primary likely cause: Citrix Broker Service outage on dc-vdi-02 (controller serving Pool-02)

Why it fits the evidence:
- Pool-02 is heavily unregistered (22/25 unregistered), while Pool-01 remains healthy (19/20 registered).
- Affected VDA registration attempts show dc-vdi-02:80 connection refused, which is consistent with a service not listening.
- Direct controller health confirms Citrix Broker Service is STOPPED on dc-vdi-02.
- Broker timeout and 'No machines available' align with insufficient registered machines at launch time.

Fastest check to confirm/eliminate:
- On dc-vdi-02, check service state and listener:
  - Get-Service BrokerService
  - netstat -ano | findstr :80
- Recheck Pool-02 registration count after service recovery attempt.

Specific remediation if confirmed:
- Start and set Citrix Broker Service to automatic start.
- Reboot dc-vdi-02 if required state from patching is blocking stable service operation.
- Verify VDA registration recovery in Pool-02 and retest user launch.

### 2) Secondary likely cause: Pool-02 VDA registration configured to rely only on dc-vdi-02 (insufficient controller redundancy)

Why it fits the evidence:
- Pool-01 remains healthy via dc-vdi-01 while Pool-02 fails against dc-vdi-02.
- If Pool-02 VDAs were pinned to dc-vdi-02 only, controller outage would produce broad unregistration and launch failure.

Fastest check to confirm/eliminate:
- On sample Pool-02 VDA hosts, inspect ListOfDDCs (policy/registry) and confirm whether dc-vdi-01 is included.
- Validate failover registration behavior after stopping/starting one controller in maintenance window.

Specific remediation if confirmed:
- Update VDA DDC list/policy to include both dc-vdi-01 and dc-vdi-02.
- Force policy refresh and restart Citrix Desktop Service on Pool-02 VDAs.
- Validate balanced registration and failover behavior.

### 3) Tertiary likely cause: Post-Windows Update state on dc-vdi-02 left broker components unavailable until reboot/service recovery

Why it fits the evidence:
- Controller shows update installed at 00:15 and reboot-required flag set.
- Broker Service last known running before this maintenance window (23:40 previous day), then stopped.
- Timing aligns with next-morning user impact.

Fastest check to confirm/eliminate:
- Review update history and system event logs around service stop time.
- Reboot dc-vdi-02 and verify Broker Service healthy post-boot.

Specific remediation if confirmed:
- Execute controlled reboot for dc-vdi-02.
- Validate dependent Citrix services auto-start and health checks pass.
- Add post-patch service validation gate before business hours.

---

## Finalized Hypothesis

Final hypothesis selected:
- Citrix Broker Service outage on dc-vdi-02 caused mass Pool-02 machine unregistration, resulting in broker timeout and session launch failure (error 1030 text: 'No machines available in the desktop group').

Rationale for finalization:
- This is directly evidenced by service state STOPPED on the relevant controller plus connection refused from affected VDAs to that controller endpoint.
- It explains impact isolation (Pool-02 affected, Pool-01 healthy) and registration split without requiring additional assumptions.

---

## Exact Remediation Steps

1. Contain user impact immediately
- Temporarily stop new session placement to Pool-02 if operationally required.
- Communicate active incident status to affected user group.

2. Recover controller service path
- On dc-vdi-02:
  - Start Citrix Broker Service.
  - Ensure startup type is Automatic.
  - If service does not remain healthy, perform controlled reboot (reboot-required flag is present).

3. Restore VDA registrations
- Confirm Pool-02 VDA machines begin re-registering.
- On lagging VDAs, restart Citrix Desktop Service and force machine policy refresh as needed.

4. Re-enable normal brokering
- Return pool to normal placement after registration threshold is recovered.

5. Stabilize and harden
- Confirm DDC redundancy in Pool-02 VDA configuration includes both controllers.
- Schedule/implement post-patching health checks and alerting.

---

## Correct Order of Operations

1. Incident communication + containment.
2. Recover dc-vdi-02 Broker Service.
3. Reboot dc-vdi-02 only if service is unstable or blocked by pending reboot.
4. Validate Pool-02 registration recovery.
5. Test pilot user launches.
6. Resume full user access.
7. Implement preventive controls.

---

## Verification Checks After Remediation

- Controller checks:
  - dc-vdi-02 Broker Service is RUNNING and stable.
  - Controller event logs show no repeated broker startup failures.
- Catalog checks:
  - Pool-02 Registered count returns to expected healthy range.
  - Unregistered count decreases from 22 to normal baseline.
- User checks:
  - Multiple test users can launch sessions from Pool-02 without timeout.
  - No new broker timeout/1030 incidents in monitoring window.

---

## Preventive Action (To Prevent Recurrence)

- Implement a post-patching runbook gate for each Delivery Controller:
  - Mandatory reboot completion if required.
  - Broker Service health check and port-listener validation before production start-of-day.
  - Automated alarm if Broker Service is stopped or if pool registration falls below threshold.
- Enforce dual-controller registration targets (DDC redundancy) for all production VDA catalogs.
