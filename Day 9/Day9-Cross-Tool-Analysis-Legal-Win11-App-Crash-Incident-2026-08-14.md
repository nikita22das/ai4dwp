# Version Header

Title: Cross-Tool Analysis - Legal Win11 App Crash Incident  
Version: 1.0  
Date: 14/08/2026  
Author: Nikita  
Status: Draft

---

# Incident Summary

## Fact
On 2024-03-25 morning, Legal (Floor 6) reported a wave of application crashes. Cross-tool data was reviewed from Nexthink DEX telemetry and SCCM deployment logs as a single investigative dataset.

## Fact
The incident scope is the Legal-Win11 device group, and telemetry degradation begins in the first hour after a completed SCCM deployment.

## Conclusion
The incident is time-correlated to a completed application upgrade event affecting the same device population and the same application family, requiring validation of post-upgrade runtime behavior before final root cause confirmation.

Evidence references: E1, E2, E3, E4, E5, E6, E7

---

# Scope Facts

## Fact
Affected device group: Legal-Win11.

## Fact
Device count: 45 devices.

## Fact
Issue start window: first major degradation visible at 10:00 on 2024-03-25.

## Fact
User and business impact: Legal users experienced a wave of app crashes during business hours.

## Fact
DEX score change:
- 09:00: 90
- 10:00: 58
- 11:00: 55

## Fact
Application affected: DocManager.exe is top crashing process (74% of all crashes between 10:00 and 11:00).

## Fact
Crash rate change:
- 09:00: 0.2%
- 10:00: 6.2%
- 11:00: 6.8%

## Fact
Disk I/O change:
- 08:00 and 09:00: Normal
- 10:00 and 11:00: High

## Fact
Hardware characteristics (Legal-Win11):
- 60% have 8GB RAM
- 40% have 4GB RAM

## Fact
Deployment activity:
- SCCM deployment started 09:38:20
- SCCM deployment completed 09:44:07
- Success: 45/45 devices, 0 failures

Evidence references: E1, E2, E3, E4, E5, E6, E7

---

# Cross-Tool Correlation

## Fact
Both sources reference the same target scope: Legal-Win11 with 45 devices.

## Fact
Deployment completion (09:44:07) precedes the first observed telemetry break (10:00).

## Fact
The deployed software identity aligns with the crashing process identity:
- SCCM: Legal Document Manager v2.1
- Nexthink: DocManager.exe dominates crash share

## Fact
The onset window contains three aligned shifts after deployment:
- Crash rate increases sharply
- DEX score collapses
- Disk I/O changes from Normal to High

## Conclusion
The strongest cross-tool relationship is a tight post-deployment temporal and behavioral coupling in the same app and device population.

Evidence references: E1, E2, E3, E4, E5, E6

---

# Evidence Collected

E1. Nexthink scope: Legal-Win11 (45 devices).  
E2. Nexthink timeline: DEX 91 at 08:00, 90 at 09:00, 58 at 10:00, 55 at 11:00.  
E3. Nexthink timeline: crash rate 0.1% at 08:00, 0.2% at 09:00, 6.2% at 10:00, 6.8% at 11:00.  
E4. Nexthink timeline: Disk I/O Normal at 08:00-09:00, High at 10:00-11:00.  
E5. Nexthink process evidence: DocManager.exe = 74% of all crashes (10:00-11:00).  
E6. SCCM deployment: started 09:38:20, completed 09:44:07, success 45/45, 0 failures.  
E7. SCCM package context: v2.0 previously stable for 6 weeks; v2.1 release note warns of early-hours high disk I/O and intermittent crashes during initial indexing, especially on devices with under 8GB RAM. Fleet RAM mix includes 40% with 4GB.

---

# Timeline

- 08:00: DEX 91, crash rate 0.1%, Disk I/O Normal.
- 09:00: DEX 90, crash rate 0.2%, Disk I/O Normal.
- 09:38:20: SCCM deployment of Legal Document Manager v2.1 starts for Legal-Win11.
- 09:44:07: SCCM deployment completes successfully on 45/45 devices.
- 10:00: DEX score drops to 58, crash rate rises to 6.2%, Disk I/O shifts to High.
- 11:00: DEX score 55, crash rate 6.8%, Disk I/O remains High, DocManager.exe dominates crashes.

## Conclusion
The degradation onset follows deployment completion by approximately 16 minutes.

Evidence references: E2, E3, E4, E5, E6

---

# Ranked Hypotheses

## 1) Most likely: v2.1 post-install indexing behavior is driving early-hours instability, with stronger effect on low-RAM endpoints

Why it fits:
- Directly matches the timing boundary (post 09:44 completion to 10:00 impact).
- Directly matches observed pattern (crash surge plus high Disk I/O).
- Directly matches app identity (DocManager.exe).
- Directly matches vendor known limitation and hardware mix relevance.

Supports:
- E2, E3, E4, E5, E6, E7

Could be contradicted by:
- Pre-deployment crash and I/O spike in same scope.
- Equal or higher crash rates in non-upgraded or unrelated app populations.
- No crash concentration on under-8GB subset.

Fastest validation:
- Segment 09:45-12:00 crash and I/O metrics by RAM tier and app version; verify whether under-8GB v2.1 endpoints show materially higher crash and I/O pressure.

## 2) Likely: v2.1 functional regression not strictly RAM-dependent

Why it fits:
- Strong deployment-to-impact timing and app identity match.
- Prior version baseline is stated as stable.

Supports:
- E3, E5, E6, E7

Could be contradicted by:
- Failures concentrated only in low-RAM endpoints with resource stress pattern.
- Rapid stabilization once indexing window ends.

Fastest validation:
- Compare crash persistence on 8GB devices after initial index window and test a controlled rollback on impacted endpoints.

## 3) Possible: transient post-install resource contention event in Legal-Win11 amplified application instability

Why it fits:
- High Disk I/O appears exactly when crash rate rises.
- Same-time shift in experience and reliability metrics after change event.

Supports:
- E2, E3, E4, E6, E7

Could be contradicted by:
- Normal disk queue and latency during crash periods.
- Continued high crash rate long after transient load should clear.

Fastest validation:
- Correlate per-device disk queue and memory pressure with DocManager.exe crash timestamps during first 3 hours post-install.

---

# Hypothesis Elimination

## Eliminated as primary hypothesis: broad SCCM deployment failure

Reason:
- SCCM records successful install on 45/45 with 0 failures, which contradicts a deployment execution failure model.

Evidence:
- E6

Note:
- This elimination applies only to deployment transport/execution failure, not runtime application health.

## De-prioritized: unrelated environmental incident with no app linkage

Reason:
- Crash dominance is inside DocManager.exe (74%), and onset follows app upgrade in same scope.

Evidence:
- E5, E6

## Remaining candidates after elimination

- Hypothesis 1 and Hypothesis 2 remain strongest.
- Hypothesis 3 remains a secondary amplifier model.

Evidence references: E3, E4, E5, E6, E7

---

# Surviving Hypothesis

## Working surviving hypothesis (not final root cause)
The most probable current hypothesis is that Document Manager v2.1 introduces an early post-install instability pattern (indexing phase) that correlates with high disk I/O and elevated DocManager.exe crashes, with likely higher impact on under-8GB devices.

Why this survives:
- Best full alignment across timing, app identity, metric behavior, vendor note pattern, and fleet RAM composition.

Evidence references: E3, E4, E5, E6, E7

---

# Recommended Resolution

## Immediate containment
- Pause further v2.1 rollout to other collections until validation completes.
- Preserve current telemetry and SCCM execution logs for evidence integrity.

## Targeted mitigation
- Create a pilot rollback cohort from highest-impact Legal endpoints and compare crash and DEX deltas against a hold cohort that remains on v2.1.
- Prioritize under-8GB endpoints for mitigation actions due to documented sensitivity.

## Communication
- Inform Legal stakeholders that issue is under active cross-tool validation, with deployment timing and app telemetry strongly correlated but root cause not yet confirmed.

Conclusion basis:
- Containment and mitigation actions are justified by evidence-backed temporal and behavioral correlation, while preserving root cause neutrality.

Evidence references: E2, E3, E4, E5, E6, E7

---

# Validation Plan

1. Data segmentation (30 minutes)
- Split Legal-Win11 by RAM tier (4GB vs 8GB) and app version state.
- Output: crash rate, Disk I/O status, DEX trend per segment.

2. Cohort experiment (60 to 120 minutes)
- Cohort A: controlled rollback to v2.0 on impacted subset.
- Cohort B: remain on v2.1 (matched impact baseline).
- Measure: DocManager.exe crash rate, DEX score recovery, Disk I/O normalization.

3. Pass and fail criteria
- Pass for Hypothesis 1:
  - Under-8GB v2.1 cohort shows higher crash and I/O during early window, and rollback cohort improves materially.
- Fail for Hypothesis 1:
  - No meaningful difference by RAM tier or version/cohort state.

4. Decision gate
- If pass: proceed with broader rollback or vendor-advised workaround plan.
- If fail: elevate Hypothesis 2 and re-open broader regression analysis.

Evidence references: E2, E3, E4, E5, E6, E7

---

# Lessons Learned

## Fact-based lessons
- Cross-tool correlation is stronger than single-tool interpretation when timeline alignment exists.
- Deployment success telemetry cannot be used as proof of runtime health.
- Vendor release notes must be treated as weighted evidence when they match observed telemetry signatures.

## Process lessons
- Preserve hourly telemetry granularity around deployment windows.
- Always stratify by hardware profile when release notes indicate hardware-dependent behavior.
- Use control cohorts early to separate deployment coincidence from deployment-linked behavior.

Evidence references: E2, E3, E4, E5, E6, E7
