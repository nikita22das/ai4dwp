# Microsoft 365 Copilot Readiness Tiered Ranking - Finance (DWP)

Date: 2026-08-12  
Source checklist: Day8-M365-Copilot-Readiness-Checklist-Finance-2026-08-12.md

## Deployment Context
- Department: Finance (~200 users)
- Data sensitivity: High - payroll, board packs, M&A documents, client financial data on shared drives
- Current state: SharePoint permissions inherited from a 2019 migration, never fully audited since
- Licensing: M365 E5 confirmed for all 200 users, Copilot add-on not yet assigned

---

## MUST Complete Before Rollout (Blocking)
- [ ] Complete the full P0 permissions and oversharing hard gate across SharePoint and OneDrive.
- [ ] Produce and remediate the exposure inventory (Everyone access, broad groups, anonymous/org-wide links, over-shared OneDrive).
- [ ] Validate and fix inherited 2019 permission issues (broken inheritance, stale owners, direct grants, nested groups, least privilege for payroll/board/M&A/client data).
- [ ] Enforce restrictive sharing defaults for Finance-sensitive locations (no broad Anyone links unless approved, org-only defaults, external sharing restrictions for high-sensitivity sites).
- [ ] Run representative access validation tests proving no unauthorized visibility in file access or search.
- [ ] Obtain Security plus Finance data owner go/no-go sign-off.
- [ ] Confirm Copilot licensing prerequisites are met for pilot users (eligible base licensing, add-on procured, service prerequisites enabled).
- [ ] Confirm endpoint/client readiness for scoped pilot users (supported Microsoft 365 Apps versions/channels and healthy sign-in/activation).
- [ ] Enforce MFA for all scoped users and validate Conditional Access success for pilot accounts.

## SHOULD Complete Before Rollout (High Risk If Skipped)
- [ ] Finalize pilot cohort segmentation to defer ultra-sensitive active deal/board users until controls are proven.
- [ ] Complete sensitivity label policy validation for Finance classes (especially Highly Confidential Finance mappings).
- [ ] Validate DLP and label behavior with representative test documents across apps and SharePoint/OneDrive.
- [ ] Complete identity hygiene cleanup beyond minimum access controls (stale accounts/memberships and attribute quality improvements).
- [ ] Finalize rollback runbook and operational support escalation paths.

## CAN Complete During/After Rollout (Lower Risk)
- [ ] Broad role-based enablement sessions after pilot start (beyond mandatory baseline guidance).
- [ ] Expanded prompt playbooks and department-specific use-case libraries.
- [ ] 2-week and 6-week adoption optimization cycles.
- [ ] Continuous tuning of auto-labeling coverage and false-positive reduction.
- [ ] Post-rollout optimization of reporting dashboards and long-tail permission cleanups not tied to high-risk repositories.

---

## Why Permissions/Oversharing Is In MUST Tier
1. Copilot respects existing Microsoft 365 permissions, so any legacy over-permission becomes AI-amplified exposure rather than a static access issue.
2. Finance data in scope (payroll, board packs, M&A, client financial data) carries high regulatory, fiduciary, and reputational impact if exposed.
3. The inherited 2019 permission model with no full audit is a known high-risk condition; rollout before remediation increases likelihood of confidential data discovery by unintended users.
4. Licensing and client version checks are necessary availability gates, but they do not reduce data exposure risk by themselves.
5. Missing a version prerequisite usually causes user experience issues; missing permissions remediation can cause real confidentiality breaches. That risk severity makes permissions and oversharing a blocking control.
