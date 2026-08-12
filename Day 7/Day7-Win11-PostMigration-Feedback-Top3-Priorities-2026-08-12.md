# FinBridge Win11 Post-Migration Feedback: Top 3 Priorities for Today
Date: 2026-08-12
Scope: Prioritized from 50 end-user comments using combined weighting of impact (Blocker/Friction/Minor/Positive) and volume.

## Ranking Logic
- Primary weight: impact to business continuity (Blocker > Friction > Minor > Positive).
- Secondary weight: business criticality when severity is equal (tenant-wide access > critical business process > workload/data segment).
- Tertiary weight: volume within each impact band.
- Final tie-breaker: urgency language in comments.

## 1) AVD Sign-In and Account Lockout Failures (Count: 7)
Why this ranks #1:
- This is a direct work-stoppage issue (Blocker): users cannot sign in at all or are repeatedly locked out.
- It has both high severity and meaningful volume (7 comments), indicating this is not isolated.
- It blocks users before they can do any work, making it the highest immediate operational risk.

One sentence to manager:
- "AVD sign-in and lockout failures are our highest priority today because they fully prevent work and are affecting multiple users, so restoring access must be treated as an immediate service recovery action."

## 2) Shared Drive Access Denied (S:/Finance) (Count: 3)
Why this ranks #2:
- This is a Blocker affecting core finance workflows (including month-end reporting).
- It outranks OneDrive despite lower volume because it directly halts a named critical business process.
- This is severity-first prioritization: a process-stopping finance dependency is treated as higher operational urgency than broader friction themes.

One sentence to manager:
- "Shared drive access denial is second priority because it is a hard blocker on finance month-end execution and needs immediate restoration to protect critical business timelines."

## 3) OneDrive Missing Files and Sync Errors (Count: 4)
Why this ranks #3:
- This remains a Blocker because users report missing files needed for meetings and end-of-day deadlines.
- It is ranked below shared-drive denial because impact is severe but appears concentrated to specific file sets/users rather than a known core process dependency.
- It still outranks all Friction themes regardless of volume due to potential delivery and data-trust risk.

One sentence to manager:
- "OneDrive missing-file reports are third priority because they represent blocker-level delivery risk and require urgent containment, even though they are not the most business-process-wide outage."

---
Prepared by: DWP Analyst
