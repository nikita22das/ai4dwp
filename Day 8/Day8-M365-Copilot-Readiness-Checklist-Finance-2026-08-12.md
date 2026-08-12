# Microsoft 365 Copilot Readiness Checklist - Finance (DWP)

Date: 2026-08-12  
Department: Finance (~200 users)

## Deployment Context
- Department: Finance (~200 users)
- Data sensitivity: High - payroll, board packs, M&A documents, client financial data on shared drives
- Current state: SharePoint permissions inherited from a 2019 migration, never fully audited since
- Licensing: M365 E5 confirmed for all 200 users, Copilot add-on not yet assigned

## How to use this checklist
- Tick each item only when evidence exists (report, screenshot, export, or signed approval).
- Complete all Priority 0 (P0) items before assigning any Copilot licenses.
- For this department, permissions and oversharing controls are the highest-risk gate and must be treated as a hard stop.

---

## Priority 0 (P0) - Permissions and Oversharing Hard Gate (Highest Priority)

### A. Tenant-level content exposure baseline
- [ ] Run Microsoft 365 data access and sharing posture review across SharePoint Online and OneDrive.
- [ ] Export a current inventory of:
  - [ ] Sites with Everyone/Everyone except external users access
  - [ ] Sites with broad Visitors/Members groups
  - [ ] Files/folders with anonymous or company-wide sharing links
  - [ ] OneDrive content shared externally or broadly internally
- [ ] Identify high-risk repositories likely containing payroll, board packs, M&A, and client financial data.
- [ ] Produce a risk-ranked list of top exposure locations and owners.

### B. Legacy permission inheritance remediation (2019 migration debt)
- [ ] Identify sites/libraries/folders with broken inheritance and unclear ownership.
- [ ] Validate that site owners are current and accountable (no stale users, no orphaned groups).
- [ ] Remove or remediate excessive direct user permissions.
- [ ] Replace ad hoc access with role-based access groups where possible.
- [ ] Review and clean nested group memberships that create unintended broad access.
- [ ] Confirm least-privilege model for payroll, board, M&A, and client-data areas.

### C. Oversharing controls and validation tests
- [ ] Disable or tightly restrict Anyone links for Finance-owned sites unless explicitly approved.
- [ ] Set default link type to People in your organization for Finance content.
- [ ] Restrict external sharing on highly sensitive Finance sites/libraries.
- [ ] Run a representative user access test (at least 15-20 users across roles) to verify:
  - [ ] Users can access only what their role requires
  - [ ] No cross-team access to confidential payroll/board/M&A/client files
  - [ ] No broad search visibility of sensitive documents beyond intended audiences
- [ ] Document all exceptions with business owner sign-off and expiry date.

### D. Copilot go/no-go security gate
- [ ] Security + Finance data owner sign-off that high-risk oversharing findings are remediated or formally accepted.
- [ ] Written go/no-go decision recorded before any Copilot license assignment.

---

## Priority 1 (P1) - Licensing and Service Prerequisites

### A. Licensing prerequisites
- [ ] Confirm all target users have eligible base licenses (M365 E5 already confirmed for department).
- [ ] Procure Microsoft 365 Copilot add-on licenses for pilot and rollout waves.
- [ ] Assign Copilot licenses to pilot users only after P0 gate is complete.
- [ ] Validate license assignment in Entra ID/M365 admin center.
- [ ] Confirm required services are enabled for scoped users:
  - [ ] Exchange Online
  - [ ] SharePoint Online
  - [ ] OneDrive for Business
  - [ ] Microsoft Teams

### B. Pilot scope and rollout controls
- [ ] Define pilot cohort (recommended 20-30 users across Finance leadership, payroll, FP&A, and operations).
- [ ] Exclude users handling ultra-sensitive active M&A/board materials until extra controls are validated.
- [ ] Define rollback process (license removal, comms template, support path).

---

## Priority 1 (P1) - Microsoft 365 Apps Client Readiness

### A. Client version/channel readiness
- [ ] Verify Microsoft 365 Apps for enterprise installed on all target endpoints.
- [ ] Confirm update channel is supported and managed (Current Channel or approved enterprise channel strategy).
- [ ] Confirm build versions meet Microsoft 365 Copilot minimum supported requirements at rollout time.
- [ ] Patch non-compliant devices before user enablement.

### B. App health and sign-in posture
- [ ] Validate users are signed in with corporate Entra ID accounts in desktop apps.
- [ ] Confirm Office activation health and token refresh reliability.
- [ ] Confirm Teams desktop client is in supported state for Copilot experiences.

---

## Priority 1 (P1) - Identity and MFA Readiness

### A. Identity hygiene
- [ ] Confirm all 200 users are cloud-synced/Entra-ready with no duplicate or stale identities.
- [ ] Remove inactive accounts and stale privileged memberships.
- [ ] Validate manager and department attributes for targeting and reporting.

### B. MFA and access controls
- [ ] Enforce MFA for all target users (no permanent bypass accounts for end users).
- [ ] Review Conditional Access policies for modern auth and compliant access paths.
- [ ] Validate sign-in risk policies and session controls for Finance access patterns.
- [ ] Test at least 10 pilot users for MFA prompts, token persistence, and Conditional Access success.

---

## Priority 1 (P1) - Sensitivity Labels and Information Protection

### A. Label taxonomy and policy coverage
- [ ] Confirm sensitivity label taxonomy includes Finance-appropriate classes (for example: Public, Internal, Confidential, Highly Confidential Finance).
- [ ] Map labels to Finance data classes:
  - [ ] Payroll
  - [ ] Board packs
  - [ ] M&A
  - [ ] Client financial data
- [ ] Ensure encryption and access restrictions are applied to highest sensitivity labels.
- [ ] Confirm label publishing policies target all Finance users and relevant groups.

### B. Label application and DLP alignment
- [ ] Enable or tune mandatory labeling for Office documents where policy requires it.
- [ ] Configure auto-labeling (where feasible) for high-risk content patterns.
- [ ] Validate DLP policies align with labels and block risky sharing/exfiltration paths.
- [ ] Run sample document tests to confirm expected label behavior across Word, Excel, PowerPoint, SharePoint, and OneDrive.

---

## Priority 2 (P2) - End-User Communications and Enablement

### A. Communications plan
- [ ] Send pre-enable communication to Finance users covering:
  - [ ] What Copilot can and cannot access (based on existing permissions)
  - [ ] Data handling expectations for sensitive financial information
  - [ ] How to report suspected oversharing or incorrect responses
- [ ] Publish an internal FAQ and support route (Service Desk + Security escalation).

### B. Training and adoption
- [ ] Deliver role-based quick-start sessions (leadership, payroll, analysts, operations).
- [ ] Include mandatory guidance on prompt hygiene and sensitive-data handling.
- [ ] Provide approved prompt examples for Finance-safe use cases.
- [ ] Schedule 2-week and 6-week adoption reviews with incident/risk feedback loop.

---

## Final Go-Live Checklist (Must be all checked)
- [ ] P0 permissions/oversharing hard gate complete and signed off.
- [ ] Copilot licenses procured and assigned to approved wave.
- [ ] Client version and app readiness validated.
- [ ] MFA/Conditional Access readiness validated.
- [ ] Sensitivity labeling and DLP controls validated.
- [ ] End-user comms and enablement completed.
- [ ] Named owners assigned for post-go-live monitoring and rapid remediation.

## Owners and Sign-off
- Security Owner: [ ]
- Finance Data Owner: [ ]
- M365 Platform Owner: [ ]
- Service Desk Lead: [ ]
- Final Approval Date: [ ]
