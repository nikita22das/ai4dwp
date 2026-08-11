# FinBridge Connect v3.1 Intune Phased Deployment Plan

Date: 2026-08-11  
Deployment deadline: 2026-09-01 (3 weeks)

Scope baseline:
- App: FinBridge Connect v3.1 (.intunewin), already uploaded to Intune app catalog
- Target fleet: 10,000 Windows 11 endpoints
- At-risk hardware segment: 5% of fleet (~500 devices) with 4 GB RAM
- Rollback baseline: FinBridge Connect v3.0 remains available in app catalog
- Detection method: Registry version string check

1. RING STRUCTURE

Ring 1 (Pilot)
- Size: 500 devices (5% of fleet)
- Duration: 4 calendar days
- Included users/devices:
  - 100 IT + service desk power users (high signal, fast feedback)
  - 300 cross-functional business users on standard hardware
  - 100 devices from the 4 GB RAM at-risk segment (explicit stress sample)
- Purpose:
  - Validate install workflow, detection rule accuracy, and baseline app stability
  - Surface hardware-related failures early (especially low-memory behavior)
  - Confirm known line-of-business workflows before scale-out
- Intune assignment group type:
  - Required assignment to a static Entra ID device security group: FB-v3_1-Ring1-Pilot-Devices

Ring 2 (Early)
- Size: 2,500 devices (25% of fleet)
- Duration: 7 calendar days
- Included users/devices:
  - Remaining Finance users not already deployed via priority path (up to 500 total Finance users by end of week 1)
  - Business-critical non-Finance departments (Operations, HR, Service Delivery)
  - Additional 150 devices from 4 GB RAM segment (cumulative 250 at-risk devices covered before broad)
- Purpose:
  - Validate scaled deployment behavior across business-critical workloads
  - Confirm support load remains manageable at mid-scale
  - Confirm no latent issues appear after 72-96 hours real usage
- Intune assignment group type:
  - Required assignment to a dynamic Entra ID device group (rule-based by department tags and Windows 11 compliance), with explicit exclusion groups for blocked devices

Ring 3 (Broad)
- Size: 7,000 devices (70% of fleet)
- Duration: 10 calendar days (deployment starts once Ring 2 criteria pass, with remaining days used for stragglers and cleanup before deadline)
- Included users/devices:
  - All remaining eligible Windows 11 endpoints
  - Remaining 250 devices from 4 GB RAM segment only if ring-isolation trigger is not active
- Purpose:
  - Complete enterprise rollout to all remaining endpoints inside the 3-week window
  - Manage long-tail install retries and offline devices
- Intune assignment group type:
  - Required assignment to dynamic all-Win11 device group: FB-v3_1-Ring3-Broad-Win11
  - Exclude groups: FB-v3_1-Blocked, FB-v3_1-4GB-Isolation (if active), FB-v3_1-Rollback-v3_0

2. ADVANCE CRITERIA

Measurement standard for all criteria
- Measurement source: Intune app install status report (Success, Failed, Pending) filtered by assignment group
- Evaluation windows are counted from the time each ring reaches 90% install attempt visibility in Intune reporting
- Ticket rate is measured as validated FinBridge v3.1 incidents per 100 installed devices using ITSM feed joined with Intune installed-device denominator in the deployment workbook

Ring 1 to Ring 2 advance gate
- Install success rate: >= 97.0% within 72 hours
- Error rate threshold: <= 2.5% failed state in Intune within same 72-hour window
- User-reported issue threshold: <= 1.5 validated tickets per 100 installed devices in 72 hours
- Monitoring period: minimum 72 continuous hours after first full pilot assignment

Ring 2 to Ring 3 advance gate
- Install success rate: >= 98.0% within 96 hours
- Error rate threshold: <= 2.0% failed state in Intune within same 96-hour window
- User-reported issue threshold: <= 1.0 validated tickets per 100 installed devices in 96 hours
- Monitoring period: minimum 96 continuous hours after first Ring 2 full assignment

Hold condition (pause without full rollback)
- Trigger: A single Intune failure code (for example 0x87D1041C) exceeds 1.0% of targeted devices in the active ring during any rolling 6-hour period
- Action: Pause progression to the next ring immediately, keep current ring installed base unchanged, open remediation workstream, and retest for 24 hours before resuming
- Specific example:
  - If Ring 2 shows 32 devices failing with 0x87D1041C out of 2,500 targeted devices (1.28%) in 6 hours, freeze Ring 3 assignment while troubleshooting package dependency or detection mismatch

3. ROLLBACK TRIGGERS

Trigger 1: Install failure rate automatic halt
- Condition: Failed install state > 8.0% in an active ring for 4 consecutive hours
- Decision owner: Incident Commander (EUC Platform Lead) with Intune Service Owner
- Decision window: 60 minutes from trigger confirmation
- Exact Intune rollback action:
  - Remove Required assignment of FinBridge v3.1 from active ring group(s)
  - Add affected ring group(s) to exclusion list for FinBridge v3.1
  - Assign FinBridge v3.0 as Required to rollback group FB-v3_1-Rollback-v3_0-[RingName]

Trigger 2: Application crash rate rollback consideration
- Condition: App crash rate >= 3.0 crashes per 100 active devices over a rolling 24-hour window, confirmed in endpoint telemetry
- Decision owner: Major Incident Manager + Application Owner + Finance IT representative
- Decision window: 2 hours from threshold breach
- Exact Intune rollback action:
  - Halt all not-yet-started ring assignments for v3.1
  - Convert currently assigned v3.1 groups to Uninstall assignment where business-approved
  - Assign v3.0 Required to same device groups until crash rate normalizes

Trigger 3: Business-critical immediate rollback
- Condition: Any verified inability in Finance to complete payment-file export/submit workflow (for example ACH/SWIFT batch submit fails in production) affecting payroll or treasury cutoff
- Decision owner: CAB emergency triad (Finance Director, Application Owner, EUC Platform Lead)
- Decision window: Immediate (<= 30 minutes)
- Exact Intune rollback action:
  - Emergency exclude Finance groups from v3.1 Required assignment
  - Assign v3.0 Required to Finance rollback group FB-v3_0-Finance-Immediate
  - Keep non-Finance rings paused until root cause decision

Trigger 4: 4 GB RAM segment isolation
- Condition: 4 GB cohort failure rate >= 12.0% over rolling 24 hours (measured only on FB-v3_1-4GB-Cohort)
- Decision owner: Endpoint Engineering Lead
- Decision window: 90 minutes from threshold breach
- Exact Intune action (ring isolation, not fleetwide rollback by default):
  - Move all remaining 4 GB devices into FB-v3_1-4GB-Isolation exclusion group for v3.1
  - Keep standard-hardware rollout moving only if other global triggers are not breached
  - Assign v3.0 Required to isolated 4 GB group until compatibility fix is validated

4. FINANCE DEADLINE RESOLUTION

Option A - Compress pilot timeline to place Finance in Ring 2 by end of week 1
- Minimum safe pilot duration: 72 hours with at least one full business cycle observed
- Introduced risk: Reduced time to catch latent defects that appear after day 3-4, especially under finance-period processing peaks
- Compensating control:
  - Hourly monitoring during first 48 hours of Ring 2
  - Pre-staged rollback groups and scripted assignment switch for Finance
  - Dedicated war room for Finance app support through end of week 1

Option B - Create Finance priority Ring 0 before the main pilot
- Ring 0 structure:
  - Size: 500 Finance users
  - Sequence: 100 users on day 1, 150 users on day 2, 250 users on day 3-4
  - Group type: Static Entra ID user/device groups owned by Finance IT coordinator
- Ring 0 advance conditions:
  - Success >= 98.0% within 48 hours per wave
  - Failure <= 1.5% per wave
  - Ticket rate <= 1.0 per 100 users per wave over 48 hours
- Ring 0 rollback plan:
  - If any wave breaches thresholds, stop next wave immediately
  - Remove v3.1 Required from remaining Finance wave groups
  - Assign v3.0 Required to impacted Finance wave group
  - Resume only after 24-hour stability revalidation

Recommendation (single path): Option B
- Choose Option B (Finance Ring 0) as the primary plan.
- Justification:
  - Meets Finance deadline by end of week 1 without compressing the technical confidence window for the enterprise pilot
  - Preserves Ring 1 quality signal for the broader 9,500 non-Finance endpoints
  - Contains business risk through a controlled, high-priority cohort with explicit per-wave rollback controls
  - Best balance of deadline certainty and operational safety across the full 3-week objective
