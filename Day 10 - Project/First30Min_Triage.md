Title: Floor 6 Monday Incident - First 30 Minute Triage
Version: 1.0
Date: 14/08/2026
Author: Nikita
Status: Draft

Scope Note:
- This triage is based only on the 09:14 Slack message from IT Ops lead.
- No logs, exports, telemetry, or endpoint snapshots are yet available.
- Facts and assumptions are separated explicitly below.

Incident Separation

Track 1: Potential Unauthorized Copilot Data Exposure
- Incident Name: Copilot returned a client matter a user reports never having access to.
- User Impact: At least one paralegal may have seen potentially unauthorized client content.
- Business Impact: Possible confidentiality breach, legal/regulatory exposure, and partner trust impact.
- Why separate investigation: This is a security/confidentiality signal with different urgency, stakeholders, and evidence chain than performance or endpoint hygiene issues.
- Fact: One paralegal reported Copilot surfaced a client matter she says she never had access to.
- Assumption (unverified): The surfaced content may represent unauthorized access rather than misunderstanding, stale permissions, or prompt/context mix-up.
- Missing evidence: Prompt used, response shown, exact matter ID, user identity, permission state at time of event, and audit trail.

Track 2: Floor 6 Authentication Failure and Severe Login Latency
- Incident Name: Multi-user login failures and very slow sign-in on Floor 6.
- User Impact: At least a dozen users cannot log in or experience excessive delay.
- Business Impact: Immediate productivity loss and inability to access core systems for a full floor/team area.
- Why separate investigation: Broad availability/access issue likely involving identity, profile, network, or endpoint state and not necessarily tied to Copilot or shortcuts.
- Fact: IT Ops lead reported at least a dozen affected users with failed or very slow login.
- Assumption (unverified): Scope could be floor-specific but may extend beyond Floor 6.
- Missing evidence: Exact error codes, affected identity providers, device list, time-to-login metrics, and blast radius outside Floor 6.

Track 3: Desktop Shortcuts Missing
- Incident Name: User desktop shortcuts disappeared.
- User Impact: At least one user lost expected shortcuts, affecting navigation to applications/files.
- Business Impact: Lower immediate operational efficiency and increased service desk load; typically lower criticality than access/security issues unless widespread.
- Why separate investigation: Endpoint configuration/profile symptom can occur independently and may require different tooling (policy/profile/script/deployment checks).
- Fact: Someone else says their desktop shortcuts vanished.
- Assumption (unverified): Could be isolated to one user or represent broader profile/GPO/deployment behavior.
- Missing evidence: Which shortcuts, how many users, persistence after sign-out/reboot, and whether profile redirection/policy changed.

Track 4: Friday Floor 6 Document Management App Rollout - Change Correlation Track
- Incident Name: Recent change window correlation assessment (not causation).
- User Impact: Unknown direct impact; this track validates whether rollout intersects affected users/devices.
- Business Impact: High decision value because it influences containment/rollback decisions and partner comms, but is not proof of cause.
- Why separate investigation: Change analysis is a cross-cutting track that can support or exclude links to Tracks 1-3 without assuming the deployment caused anything.
- Fact: New document management app was rolled out Friday afternoon to Floor 6.
- Assumption (unverified): Temporal proximity may be coincidental.
- Missing evidence: Change ticket scope, deployment success/failure rates, detection/install states, policy payloads, and post-deploy incident timing.

First 30 Minute Triage Plan (Ranked by Urgency)

Priority 1 - Track 1: Potential Unauthorized Copilot Data Exposure
- Why highest priority: Potential confidentiality/security incident. Even one valid exposure can have disproportionate legal and reputational impact.
- Evidence to collect first: Reporter identity, exact prompt/response text (screenshots if available), timestamp, tenant/workload, client matter identifier, and whether content is still reproducible.
- First tool/system check: Microsoft Purview Audit (Copilot/M365 audit events) plus SharePoint/OneDrive item permission snapshot for the matter referenced.
- Why highest-value first check: Confirms whether accessed content events and effective permissions align with claim; quickly distinguishes possible exposure from perception/error.
- Immediate escalation trigger: Any evidence of access to content outside authorized ACLs, multi-user similar reports, or inability to preserve forensic audit trail.

Priority 2 - Track 2: Multi-user Login Failure/Latency
- Why second: Broad operational outage risk with many users currently blocked, directly reducing business continuity.
- Evidence to collect first: Affected user list, device names, exact login errors, timestamps, authentication path (Entra ID/AD/AVD/VDI), and known-good comparison users on same floor.
- First tool/system check: Entra ID Sign-in Logs (failure reason, conditional access outcomes, token issuance latency) and service health dashboard for identity/auth services.
- Why highest-value first check: Rapidly separates identity-plane failures from endpoint-only issues and establishes scope/blast radius.
- Immediate escalation trigger: Failure rate rising, spread to additional floors/business units, or identity platform degradation/service advisory indicators.

Priority 3 - Track 4: Friday Rollout Correlation Assessment
- Why third: High leverage for decision-making but not inherently a live impact symptom; supports triage of Tracks 2 and 3 without assuming causation.
- Evidence to collect first: Deployment ring/scope, install success/failure counts, affected endpoint overlap with login/shortcut complaints, and exact rollout timeline.
- First tool/system check: Intune/SCCM deployment reports and change record (CAB/change ticket, release notes, rollout approvals).
- Why highest-value first check: Fastest way to confirm or exclude overlap between change scope and incidents, informing containment messaging.
- Immediate escalation trigger: Clear overlap with high failure rates after rollout or evidence of harmful configuration pushed to many Floor 6 endpoints.

Priority 4 - Track 3: Missing Desktop Shortcuts
- Why fourth: User-impacting but currently lower risk than potential data exposure and floor-wide access outage, unless prevalence increases.
- Evidence to collect first: User/device IDs, specific missing shortcuts, timing, profile redirection state, and whether issue persists after policy refresh/sign-out.
- First tool/system check: Endpoint management policy baseline (Intune/SCCM), GPO result set, and user profile shell folder path validation.
- Why highest-value first check: Quickly identifies whether this is policy/deployment-driven versus isolated profile corruption.
- Immediate escalation trigger: Widespread reproducibility across Floor 6 after policy/deployment change or linkage to privileged app access paths.

Prioritization Reasoning Summary (Fact vs Assumption):
- Fact-driven: Security signal (Track 1) and multi-user login impairment (Track 2) are explicitly reported in Slack and carry highest immediate risk.
- Assumption-controlled: Change rollout (Track 4) is investigated as correlation only; no causation assumed.
- Dynamic rule: Track 3 can move up if new evidence shows widespread impact or linkage to critical workflows.

Evidence Collection Plan by Track

Track 1 - Potential Unauthorized Copilot Data Exposure
- Data Sources: User statement capture, matter metadata, document library ownership records, service desk ticket timeline.
- Logs: Microsoft Purview Audit, Unified Audit Log, Copilot interaction/audit events, SharePoint/OneDrive access logs, Entra ID sign-in and token events.
- Telemetry: M365 service health incidents/advisories, Copilot request telemetry available to tenant admins, sensitivity label access events.
- Deployment Records: Any recent permission model changes, SharePoint group membership updates, DLP/policy modifications, Copilot policy changes.
- User Validation Required: Interview reporting paralegal; confirm exact matter name/ID, whether content excerpt was truly unknown, and whether recurrence occurs.

Track 2 - Login Failure/Latency
- Data Sources: Service desk incidents, floor captain reports, affected user roster, endpoint inventory mapping to Floor 6.
- Logs: Entra ID Sign-in Logs, AD domain controller auth logs (if hybrid), AVD/VDI connection logs, endpoint Event Viewer (User Profile Service, Winlogon, Netlogon).
- Telemetry: Nexthink endpoint performance/auth journey, VPN/Network telemetry for Floor 6 segment, identity service health metrics.
- Deployment Records: Recent identity/conditional access policy changes, endpoint security baseline changes, authentication agent updates.
- User Validation Required: Validate exact symptom per user (cannot login vs slow login), elapsed times, first-seen timestamp, and unaffected control users nearby.

Track 4 - Friday Rollout Correlation
- Data Sources: CAB/change ticket, release notes, rollout plan, deployment scoping lists, exception approvals.
- Logs: Intune app install status logs, SCCM deployment status/failure codes, installer logs on sample affected endpoints.
- Telemetry: App crash/startup metrics (if instrumented), endpoint health drift after rollout, post-deploy failure trend line.
- Deployment Records: Package/version hashes, detection rules, supersedence/uninstall behavior, rollback readiness evidence.
- User Validation Required: Confirm whether affected users/devices received the rollout and whether symptom onset followed installation timing.

Track 3 - Desktop Shortcuts Missing
- Data Sources: User desktop snapshots, profile path configuration, known baseline shortcut set for role/team.
- Logs: Event Viewer shell/profile logs, Intune policy application logs, GPO processing logs, script execution logs for desktop provisioning.
- Telemetry: Nexthink file/path presence checks, endpoint configuration drift telemetry.
- Deployment Records: Recent script/package/policy that modifies public desktop, user desktop, or shell folder redirection.
- User Validation Required: Identify missing shortcuts by name/path, validate whether shortcuts exist in expected directories, and confirm if issue is single-user or clustered.

Evidence Gaps (All Tracks):
- No validated user list yet.
- No timestamps beyond initial Slack message time.
- No raw logs or screenshots preserved yet.
- No confirmed blast radius outside Floor 6.

First-Hour Manager Update

We have separated the morning report into four parallel triage tracks: (1) potential Copilot confidentiality exposure, (2) multi-user login failure/slow login, (3) missing desktop shortcuts, and (4) a neutral assessment of Friday's document-management rollout as a possible correlation only.

Highest risk right now is the Copilot-related access claim because it could indicate unauthorized visibility of client matter information; this is being treated as a security signal until disproven.

Highest immediate business impact is the login issue affecting at least a dozen users, as it directly blocks staff from starting work.

Current evidence collection is focused on: preserving user-reported Copilot prompt/output details and audit trails; extracting identity sign-in failure/latency patterns and affected-user scope; validating rollout scope and endpoint overlap from Intune/SCCM/change records; and confirming whether missing shortcuts are isolated or widespread. We are intentionally not asserting root cause at this stage.
