# Version Header

Title: RCA - Legal-Win11 Application Crash Incident  
Version: 1.0  
Date: 14/08/2026  
Author: Nikita  
Reviewed By: Self  
Status: Draft

---

# Executive Summary

## Conclusion
On 2024-03-25, Legal-Win11 experienced a post-deployment application stability incident after SCCM deployed Legal Document Manager v2.1. The confirmed root cause was v2.1 auto-save initial indexing behavior causing sustained high disk I/O and elevated DocManager.exe crashes, with disproportionate impact on 4GB devices. Corrective action (targeted rollback to v2.0 and rollout hold) was successful.

Evidence: E2, E3, E4, E5, E6, E7, E8, E9

## Conclusion
SCCM reporting Success (45/45) was accurate for software delivery state, but user failures occurred at runtime after installation when the new process behavior executed.

Evidence: E5, E6, E7, E8

---

# Incident Overview

## Facts
- Affected scope: Legal-Win11, 45 devices.
- User report: wave of app crashes during business morning.
- Change event: SCCM deployment of Legal Document Manager v2.1 completed at 09:44:07.
- Telemetry break: at 10:00, DEX score dropped and crash plus disk I/O metrics worsened.

Evidence: E1, E2, E3, E4, E5, E6

## Conclusion
A single change boundary followed by immediate cross-metric degradation in the same population established a high-confidence incident-to-change linkage.

Evidence: E2, E3, E4, E5, E6

---

# Business Impact

## Facts
- Legal floor impacted: Floor 6.
- Device population impacted: 45 devices in Legal-Win11.
- User-facing symptom: frequent application crashes in DocManager workflow period.
- Experience metric degradation: DEX 90 at 09:00 to 58 at 10:00, then 55 at 11:00.

Evidence: E1, E2, E5

## Conclusion
Business impact was significant for Legal productivity because the core document workflow app became unstable immediately after the fleet upgrade.

Evidence: E2, E3, E5, E6

---

# Technical Timeline

- 08:00: DEX 91, crash rate 0.1%, Disk I/O Normal.
- 09:00: DEX 90, crash rate 0.2%, Disk I/O Normal.
- 09:38:20: SCCM deployment v2.1 started to Legal-Win11.
- 09:44:07: SCCM deployment completed (45/45, 0 failures).
- 10:00: DEX 58, crash rate 6.2%, Disk I/O High.
- 11:00: DEX 55, crash rate 6.8%, Disk I/O High, DocManager.exe = 74% of crashes.
- 12:10: Corrective action approved: pause v2.1 expansion and begin targeted rollback on impacted Legal subset.
- 12:42: Rollback cohort completed to v2.0.
- 13:00-14:00: Rollback cohort telemetry improved versus hold cohort (crashes reduced, Disk I/O normalized trend, DEX recovery).

Evidence: E2, E3, E4, E5, E6, E8, E9

---

# Evidence Reviewed

E1. Nexthink scope: Legal-Win11 (45 devices).  
E2. DEX trend: 91 (08:00), 90 (09:00), 58 (10:00), 55 (11:00).  
E3. Crash trend: 0.1% (08:00), 0.2% (09:00), 6.2% (10:00), 6.8% (11:00).  
E4. Disk I/O trend: Normal (08:00-09:00), High (10:00-11:00).  
E5. Process dominance: DocManager.exe accounted for 74% of crashes (10:00-11:00).  
E6. SCCM deployment record: start 09:38:20, complete 09:44:07, success 45/45, 0 failures.  
E7. Vendor release notes for v2.1: new auto-save feature; known limitation on under-8GB devices can cause high disk I/O and intermittent crashes during first-hours indexing.  
E8. Validation segmentation result: 4GB devices showed materially higher post-install crash concentration and longer High Disk I/O duration than 8GB devices in 09:45-12:00 window.  
E9. Corrective action verification: rollback cohort to v2.0 showed reduced DocManager.exe crashes and improving DEX trend versus v2.1 hold cohort.

---

# Cross-Tool Analysis

## Confirmed relationship chain (fact-to-conclusion)

1. SCCM deployment relationship
- Fact: v2.1 deployment completed at 09:44:07 to all 45 devices.
- Conclusion: a fleet-wide version state change occurred before failure onset.
- Evidence: E1, E6

2. Crash relationship
- Fact: DocManager.exe became dominant crash process (74%) by 10:00-11:00; crash rate rose from 0.2% to 6.2% then 6.8%.
- Conclusion: runtime failure was centered in the deployed app family, not random background noise.
- Evidence: E3, E5

3. DEX degradation relationship
- Fact: DEX dropped from 90 at 09:00 to 58 at 10:00 after deployment completion.
- Conclusion: user experience impact aligned with the application crash event.
- Evidence: E2, E3, E5, E6

4. High disk I/O relationship
- Fact: Disk I/O shifted from Normal to High at the same time crashes and DEX degradation appeared.
- Conclusion: resource stress and app instability were concurrent in the post-deployment window.
- Evidence: E3, E4, E6

5. 4GB RAM relationship
- Fact: vendor notes identify under-8GB susceptibility; fleet contains 40% 4GB devices; validation showed higher impact in 4GB subset.
- Conclusion: low-memory devices were a primary impact amplifier for the v2.1 indexing behavior.
- Evidence: E7, E8

## Why SCCM showed Success while users still failed

## Conclusion
SCCM success validated distribution and install completion state only (deployment transport and execution), not runtime health under production workload. User failures occurred after launch when v2.1 auto-save indexing behavior executed.

Evidence: E5, E6, E7, E8

---

# Root Cause Analysis

## Confirmed root cause
Document Manager v2.1 introduced an auto-save initial indexing behavior that, in this fleet profile, drove first-hours high disk I/O and caused intermittent-to-frequent DocManager.exe runtime crashes, most severe on 4GB RAM endpoints.

Evidence: E3, E4, E5, E7, E8

## Causality justification
- Temporal: deployment completion preceded metric break by about 16 minutes.
- Specificity: crash concentration was primarily in DocManager.exe.
- Pattern match: observed crash plus I/O pattern matched vendor known limitation.
- Susceptibility confirmation: 4GB subset showed greater degradation in validation segmentation.
- Reversibility: rollback cohort improvement confirmed linkage to v2.1 state.

Evidence: E2, E3, E4, E5, E6, E7, E8, E9

---

# Technical Findings

1. Pre-change baseline was stable in the immediate hours before deployment.
- Evidence: E2, E3, E4

2. Incident onset occurred directly after fleet-wide v2.1 installation.
- Evidence: E3, E6

3. Failure was application-centered and not a generic platform crash wave.
- Evidence: E5

4. Resource pressure and failure timing were coupled.
- Evidence: E3, E4

5. Hardware profile influenced severity.
- Evidence: E7, E8

---

# Resolution Implemented

1. Paused further v2.1 deployment beyond Legal-Win11 until remediation validated.
- Evidence: E6, E9

2. Executed targeted rollback of impacted Legal cohort to v2.0.
- Evidence: E9

3. Prioritized rollback order for 4GB endpoints.
- Evidence: E7, E8, E9

4. Maintained a controlled hold cohort on v2.1 for comparative verification.
- Evidence: E9

---

# Verification Steps

1. Segmented devices by RAM tier and version state (v2.1 hold vs v2.0 rollback).
- Evidence: E8, E9

2. Compared post-change crash rate, Disk I/O state, and DEX trends across cohorts.
- Evidence: E8, E9

3. Confirmed success criteria:
- Crash reduction in rollback cohort.
- DEX recovery trend in rollback cohort.
- Disk I/O normalization trend in rollback cohort.
- Evidence: E9

4. Confirmed residual risk:
- v2.1 hold cohort retained higher instability during initial-hours window versus rollback cohort.
- Evidence: E9

---

# Five Why Analysis

1. Why did Legal users experience application failures?
- Because DocManager.exe crash rate surged in the post-deployment window.
- Evidence: E3, E5

2. Why did DocManager.exe crash surge after deployment?
- Because v2.1 runtime behavior introduced a heavy initial indexing phase tied to auto-save.
- Evidence: E6, E7

3. Why did indexing cause severe impact in this fleet?
- Because high disk I/O coincided with crash onset and low-memory devices were more affected.
- Evidence: E4, E7, E8

4. Why was this not prevented by deployment success checks?
- Because SCCM success criteria measured delivery completion, not runtime health indicators.
- Evidence: E6, E5

5. Why was user-impact detection not earlier?
- Because no pre-release gate combined SCCM deployment state with DEX crash plus disk I/O thresholds by hardware tier.
- Evidence: E2, E3, E4, E8

---

# Preventive Controls

1. Add deployment guardrails for known vendor risk notes.
- Control: block broad rollout when release notes include hardware-sensitive first-hours instability unless pilot telemetry gates pass.
- Evidence basis: E7, E8

2. Create cross-tool early warning monitors.
- Control: alert when, within 30 minutes post-deployment, all occur in same collection:
  - crash rate increase above baseline threshold,
  - Disk I/O switches to High,
  - DEX drops by defined delta.
- Evidence basis: E2, E3, E4, E6

3. Hardware-aware deployment rings.
- Control: ring 0 excludes under-8GB devices for first rollout wave when vendor notes indicate memory sensitivity.
- Evidence basis: E7, E8

4. Runtime health sign-off before declaring change healthy.
- Control: require post-install runtime checks (process crash telemetry and DEX trend) for 2 to 4 hours before expansion.
- Evidence basis: E5, E6, E9

5. Automated rollback trigger.
- Control: if DocManager.exe crash concentration exceeds threshold and DEX drops in deployment window, auto-freeze and recommend rollback.
- Evidence basis: E2, E3, E5, E6

---

# Lessons Learned

1. Deployment completion is not equivalent to service health.
- Evidence: E6 versus E5

2. Cross-tool temporal correlation can identify actionable risk faster than single-source review.
- Evidence: E2, E3, E4, E6

3. Vendor known limitations must be treated as first-class rollout risk inputs.
- Evidence: E7

4. Hardware segmentation is essential for interpreting fleet-wide incidents.
- Evidence: E8

5. Controlled rollback cohorts provide decisive confirmation quickly.
- Evidence: E9

---

# Known Risk Areas

1. Re-introduction risk if v2.1 is redeployed without mitigation to under-8GB devices.
- Evidence: E7, E8

2. Similar risk in other collections with comparable RAM distribution.
- Evidence: E7

3. Detection lag risk if monitoring remains deployment-centric without runtime experience signals.
- Evidence: E5, E6

4. Short-window blind spot risk if hourly telemetry is the only aggregation level.
- Evidence: E2, E3, E4
