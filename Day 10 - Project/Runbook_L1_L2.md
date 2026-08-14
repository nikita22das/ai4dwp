DOCUMENT 1 - RUNBOOK

Title: Floor 6 Document Management App Mitigation Runbook
Version: 1.0
Date: 14/08/2026
Author: Nikita
Status: Draft

Purpose:
- Provide the immediate, controlled mitigation procedure for Floor 6 login and performance degradation while investigation remains active.

Scope:
- Floor 6 Legal cohort (45 devices), with priority targeting of currently affected devices.
- Covers deployment halt, affected-device targeting, rollback to previous app version, validation, rollback-of-rollback, and escalation.

Prerequisites:
- Approved incident/change record for emergency mitigation.
- Current affected-device list (device name plus managed identifier where available).
- Confirmed current app package ID/version and previous known-good package ID/version.
- Named incident owner and communications owner.

Required Access:
- Intune admin permissions for app assignments and managed device scope.
- SCCM application deployment and collection management permissions.
- Read access to sign-in and endpoint telemetry used for verification.

Required Tools:
- Microsoft Graph PowerShell module (for Intune actions).
- Configuration Manager PowerShell module (for SCCM actions).
- CSV containing affected devices.
- Standard incident ticketing and communication channels.

Procedure:

1. Step 1
Action:
- Confirm incident scope and import the affected-device list.
- Create a dedicated mitigation target group/collection for affected devices only.
Expected Result:
- A validated mitigation target exists and contains only affected endpoints.

2. Step 2
Action:
- Pause further rollout of the current Document Management app deployment to Floor 6 ring.
- Remove or disable active include assignment/deployment for the affected ring.
Expected Result:
- No additional Floor 6 devices receive the current rollout during mitigation.

3. Step 3
Action:
- Remove affected devices from the active rollout ring assignment/collection.
- Keep unaffected floors/rings unchanged unless incident commander expands scope.
Expected Result:
- Affected devices are isolated from continued enforcement of current version.

4. Step 4
Action:
- Deploy previous known-good app version to affected devices as required install.
- Deploy uninstall (or supersedence rollback) for current problematic version on affected devices.
Expected Result:
- Affected devices converge to known-good version; current version is removed from targeted cohort.

5. Step 5
Action:
- Trigger policy refresh/evaluation cycle for affected devices.
- Monitor deployment state transitions (required, in progress, success, failed).
Expected Result:
- Mitigation actions execute promptly and status becomes observable in management console.

6. Step 6
Action:
- Execute post-mitigation verification checks (login, user experience, app behavior, device performance, baseline comparison).
Expected Result:
- Evidence shows improvement trend or confirms need to escalate/adjust response.

Verification:

1. Check: Login performance trend for affected users
Expected Healthy Result:
- Failed logins decrease and sign-in duration improves versus incident window.
Failure Indicator:
- Failures persist or sign-in latency remains materially elevated.

2. Check: Floor 6 user experience signal
Expected Healthy Result:
- New incident tickets decline and users report normal startup experience.
Failure Indicator:
- Ticket volume remains flat/increases and users continue reporting severe delays.

3. Check: Document Management app behavior after rollback
Expected Healthy Result:
- Reduced crash/hang/error signals on affected devices.
Failure Indicator:
- App instability persists despite version rollback.

4. Check: Device resource profile during login and first 10 minutes
Expected Healthy Result:
- CPU, memory, and disk contention returns toward baseline/control behavior.
Failure Indicator:
- Sustained contention remains without improvement.

5. Check: Comparison to pre-change or unaffected controls
Expected Healthy Result:
- Post-mitigation metrics trend toward baseline/control profile.
Failure Indicator:
- Metrics remain significantly worse than baseline/control.

Rollback:

1. Rollback Step 1
Action:
- If mitigation causes broader disruption, stop rollback deployment and re-enable prior stable assignment state under change control.
Expected Result:
- Environment returns to pre-mitigation assignment posture.
Validation:
- Assignment/deployment states match documented pre-mitigation configuration.

2. Rollback Step 2
Action:
- Restore affected devices to last known stable app state using approved package/version path.
Expected Result:
- Devices return to stable application baseline.
Validation:
- App inventory and deployment status confirm expected stable version on target devices.

3. Rollback Step 3
Action:
- Re-run verification checks and incident impact sampling.
Expected Result:
- Clear evidence whether rollback-of-rollback improved or worsened user outcomes.
Validation:
- Verification metrics captured and attached to incident record.

Known Risks:
- Temporary feature regression for users who require current app-version functionality.
- Partial convergence where some devices complete rollback slower than others.
- Mis-targeting risk if affected-device list quality is poor.
- Investigation bias risk if mitigation outcome is interpreted as proof of root cause.

Escalation Path:
- Service Desk -> DWP Incident Commander -> Endpoint Engineering (Intune/SCCM owners).
- If user impact does not improve after mitigation window, escalate to Identity and Network teams for parallel fault domain investigation.
- If evidence suggests data exposure or access anomalies during investigation, escalate to Security/Compliance immediately.


DOCUMENT 2 - L1 SELF-SERVICE ARTICLE

Title: Floor 6 Login and Speed Issues - What To Do Now
Version: 1.0
Date: 14/08/2026
Author: Nikita
Status: Draft
Audience: Floor 6 business users

This article is derived from Runbook Version 1.0

We are responding to reports of login failures and slow device startup on Floor 6. A targeted software rollback is being applied to affected devices to reduce disruption while investigation continues.

What you may notice:
- Trouble signing in.
- Long wait before desktop is ready.
- Slow performance shortly after login.

What you should do:
- Keep your device powered on and connected to the office network.
- Restart once if prompted by IT.
- After restart, try signing in again and wait for desktop load.

When to contact Service Desk:
- You still cannot sign in.
- Login is still very slow after restart.
- Your device remains unusually slow after you reach desktop.

When you contact Service Desk, include:
- Your device name.
- Time the issue happened.
- What you observed (for example sign-in failed, long wait, slow desktop).

This helps us prioritize affected users and verify whether mitigation is improving outcomes.


DOCUMENT 3 - L2 TECHNICAL ARTICLE

Title: Floor 6 Mitigation Procedure - DWP Engineer Guide
Version: 1.0
Date: 14/08/2026
Author: Nikita
Status: Draft
Audience: DWP Engineers

This article is derived from Runbook Version 1.0

Purpose:
- Execute controlled mitigation for Floor 6 login/performance incident using targeted deployment pause and rollback.

Scope:
- Floor 6 Legal devices, priority on affected-device cohort.

Prerequisites, Required Access, Required Tools:
- Use exactly the Runbook prerequisites, access model, and tools.

Procedure (same as Runbook):
1. Build validated affected-device target group/collection from incident list.
Action:
- Confirm scope and import affected-device list; create dedicated mitigation target.
Expected Result:
- Correctly scoped mitigation target.

2. Stop further rollout to Floor 6 ring.
Action:
- Remove/disable active deployment assignment for current app rollout.
Expected Result:
- No new rollout exposure during mitigation.

3. Remove affected devices from active ring.
Action:
- Isolate affected devices from current version enforcement.
Expected Result:
- Affected cohort no longer receives current rollout.

4. Roll back affected devices to previous known-good version.
Action:
- Deploy previous version and uninstall/supersede current version on affected cohort.
Expected Result:
- Version convergence to stable baseline.

5. Trigger policy refresh and monitor execution.
Action:
- Force policy/evaluation cycle and track deployment states.
Expected Result:
- Faster and observable mitigation convergence.

6. Run verification set.
Action:
- Apply all Runbook verification checks.
Expected Result:
- Measurable improvement or clear escalation trigger.

Verification (same as Runbook):
1. Login performance trend
Check:
- Failed logins and sign-in duration trend.
Expected Healthy Result:
- Improved trend versus incident window.
Failure Indicator:
- Persistent failures/high latency.

2. User experience signal
Check:
- New Floor 6 ticket volume and user feedback.
Expected Healthy Result:
- Ticket decline and improved startup reports.
Failure Indicator:
- No improvement or worsening reports.

3. App behavior
Check:
- Post-rollback app crash/hang/error trend.
Expected Healthy Result:
- Reduced instability.
Failure Indicator:
- Ongoing instability.

4. Device performance
Check:
- CPU/memory/disk during login and first 10 minutes.
Expected Healthy Result:
- Contention trends toward baseline.
Failure Indicator:
- Sustained contention.

5. Baseline/control comparison
Check:
- Post-mitigation versus pre-change or unaffected controls.
Expected Healthy Result:
- Convergence toward baseline/control.
Failure Indicator:
- Continued material deviation.

Rollback (same as Runbook):
1. Stop mitigation changes and restore pre-mitigation assignment state if mitigation worsens impact.
Action:
- Revert assignment/deployment posture under change control.
Expected Result:
- Assignment posture restored.
Validation:
- Console state matches pre-mitigation record.

2. Restore last known stable app state for affected devices.
Action:
- Re-apply approved stable version path.
Expected Result:
- Stable version present on target devices.
Validation:
- Inventory and deployment status confirm stable state.

3. Re-run verification and capture incident impact sample.
Action:
- Repeat verification checks after rollback-of-rollback.
Expected Result:
- Clear outcome trend for decision-making.
Validation:
- Metrics attached to incident record.

Known Risks and Escalation Path:
- Use exactly the Runbook risk and escalation definitions.


L1/L2 Traceability Matrix

| Runbook Section | Corresponding L1 Section | Corresponding L2 Section |
|---|---|---|
| Purpose | Opening paragraph (why action is being taken) | Purpose |
| Scope | User-facing scope language (Floor 6 users) | Scope |
| Prerequisites | Implied in user instruction to keep device on network and restart when prompted | Prerequisites |
| Required Access | Not user-facing; represented by "IT is applying targeted rollback" | Prerequisites, Required Access, Required Tools |
| Required Tools | Not user-facing; omitted by design for plain-language audience | Prerequisites, Required Access, Required Tools |
| Procedure Step 1 (target affected devices) | Service Desk contact details requested from user (device name/time/symptom) supporting target validation | Procedure Step 1 |
| Procedure Step 2 (stop rollout) | "targeted software rollback is being applied" | Procedure Step 2 |
| Procedure Step 3 (remove from ring) | "targeted" wording (affected devices only) | Procedure Step 3 |
| Procedure Step 4 (rollback version) | "software rollback" statement | Procedure Step 4 |
| Procedure Step 5 (policy refresh and monitor) | "restart once if prompted by IT" | Procedure Step 5 |
| Procedure Step 6 (verification execution) | "This helps us verify whether mitigation is improving outcomes" | Procedure Step 6 |
| Verification checks | Symptoms and when to contact Service Desk | Verification section items 1-5 |
| Rollback | Not user-facing; covered by IT-controlled mitigation language | Rollback section items 1-3 |
| Known Risks | No technical detail presented to users; reflected by cautious non-final wording | Known Risks |
| Escalation Path | "contact Service Desk" route for end users | Escalation Path |

Traceability statement:
- L1 and L2 content above are re-expressions of the Runbook sections only; no independent troubleshooting path or new research content has been introduced.