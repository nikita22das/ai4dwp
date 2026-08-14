Title: Floor 6 Login and Performance Investigation - Ranked Differential Analysis
Version: 1.0
Date: 14/08/2026
Author: Nikita
Status: Draft

Scope Facts

Known facts:
- Floor 6 contains Legal users (45 users).
- Floor 6 was recently migrated to Windows 11.
- Floor 6 devices were recently enrolled into Intune.
- At least a dozen users report login failures or very slow logins.
- Reports are occurring Monday morning.
- A new Document Management application was deployed to Floor 6 on Friday afternoon.
- No logs, telemetry, DEX exports, SCCM reports, Intune reports, or Event Viewer logs are available yet.

Unknown facts:
- Exact number of affected users and exact failure rate across all 45 users.
- Whether affected users are clustered by device model, network segment, office zone, role, or manager.
- Whether failures are credential errors, MFA/Conditional Access failures, profile load failures, script timeout, or shell/startup hangs.
- Whether symptoms occur before credential acceptance, during profile load, or after desktop appears.
- Whether unaffected users exist on Floor 6 and what differs between affected and unaffected groups.
- Whether the issue also exists on other floors or only Floor 6.
- Whether the Friday app installed successfully on all, some, or none of affected devices.
- Whether any identity, policy, security baseline, or network changes occurred in the same time window.

Assumptions that must not be made:
- Do not assume the Friday deployment caused the issue.
- Do not assume the Friday deployment is unrelated.
- Do not assume all login failures and slow-logins are the same root cause.
- Do not assume Windows 11 migration itself is the cause without comparison evidence.
- Do not assume Intune enrollment itself is the cause without policy/application timing correlation.
- Do not assume user reports describe technically identical symptoms.

Ranked Differential Diagnosis

Ranking method used:
- Timing relevance (Friday change versus Monday onset).
- Breadth of impact (at least ~12/45 users reported, potentially more).
- Environment transition risk (recent Win11 migration and Intune enrollment).
- Symptom fit for both login failures and slow logins.
- Ability to explain floor-specific concentration.

1) Cause: Identity/Conditional Access or authentication path degradation affecting Floor 6 user cohort.
- Why it fits available evidence: Login failures plus severe delays are classic identity-plane symptoms and can affect many users quickly on Monday start-of-day peaks.
- Supporting evidence currently available: Multi-user login impact is explicitly reported; no evidence yet of device-only failure mode.
- Contradicting evidence if found: Affected users authenticate successfully in cloud logs with normal latency while endpoint logs show local profile/app bottleneck.
- Fastest check: Entra ID sign-in logs for affected users in the Monday morning window, including CA decisions and failure reasons.
- Expected result if true: Elevated sign-in failures, CA blocks/challenges/timeouts, or materially increased token/sign-in latency versus baseline.
- Expected result if false: Sign-ins mostly successful and timely, with delays occurring after authentication during profile/shell/app startup.

2) Cause: Intune policy/configuration convergence issue after recent enrollment (security baseline, scripts, compliance, or profile settings).
- Why it fits available evidence: Newly enrolled endpoints often apply many policies over time; Monday startup can surface policy conflicts or heavy post-enrollment processing.
- Supporting evidence currently available: Recent Intune enrollment plus mixed symptoms (failures and slow logins) across a sizable subset.
- Contradicting evidence if found: Identical policy state on unaffected floors/devices with no symptom difference and no timing alignment to policy assignments.
- Fastest check: Intune device configuration/compliance timelines and policy assignment history for affected versus unaffected Floor 6 devices.
- Expected result if true: Affected devices share one or more recent policy/script/app assignment events preceding symptom onset.
- Expected result if false: No common policy delta between affected and unaffected users/devices.

3) Cause: Friday Document Management app deployment causing startup/login overhead or failure on subset of endpoints.
- Why it fits available evidence: Timing is plausible (Friday rollout, Monday complaints), and startup-integrated apps can delay shell load or fail sign-in hooks.
- Supporting evidence currently available: Known targeted deployment to Floor 6 in immediate pre-incident window.
- Contradicting evidence if found: Affected users did not receive the app, or unaffected users all received same version/config with no performance impact.
- Fastest check: Intune/SCCM deployment status and install outcomes correlated with affected user/device list.
- Expected result if true: Strong overlap between impacted users and installation/failure state, plus startup or crash records tied to the app.
- Expected result if false: Weak or no overlap; issue appears in devices with no deployment or normal app behavior.

4) Cause: User profile, FSLogix/roaming profile, or logon script processing bottleneck after Win11 migration.
- Why it fits available evidence: Slow logins and intermittent login failures commonly arise from profile load issues, large profile redirection, or script timeouts after OS transition.
- Supporting evidence currently available: Recent Win11 migration, performance symptoms, Monday peak load scenario.
- Contradicting evidence if found: Profile services healthy with normal load times while identity and app startup events show primary delays.
- Fastest check: Event Viewer (User Profile Service, GroupPolicy/Winlogon), logon duration telemetry (DEX), and profile container health where applicable.
- Expected result if true: Repeating profile load errors/timeouts and elevated logon phase durations on affected devices.
- Expected result if false: Profile load durations normal and no recurrent profile-related error signatures.

5) Cause: Floor 6 network path degradation (DNS, proxy, Wi-Fi/VLAN congestion, auth endpoint reachability) causing both auth and post-login slowness.
- Why it fits available evidence: Floor-concentrated Monday-morning issues can be network-segment specific and produce both sign-in delays and perceived performance degradation.
- Supporting evidence currently available: Geographic concentration on one floor and timing at business-day start.
- Contradicting evidence if found: Normal Floor 6 network telemetry and unaffected reachability/latency to identity and management endpoints.
- Fastest check: Floor 6 network telemetry and endpoint connectivity tests to Entra, Intune, and line-of-business services; compare with unaffected floors.
- Expected result if true: Higher packet loss/latency/DNS failures on affected segment and correlated login delays.
- Expected result if false: Network KPIs normal and no segment-specific degradation.

Why this ranking order:
- Rank 1 prioritized because it best explains simultaneous login failures plus delays across many users and is highest operational risk if ongoing.
- Rank 2 prioritized next due to recent Intune enrollment and high probability of policy convergence issues in newly managed Win11 estates.
- Rank 3 kept high but not first because timing is suggestive, not proof; deployment remains a correlation clue pending overlap evidence.
- Rank 4 remains plausible due to migration context and symptom shape, but currently has less direct timing evidence than ranks 1-3.
- Rank 5 remains credible for floor concentration, but there is not yet direct network evidence.

Deployment Correlation Analysis

What would increase confidence the Friday deployment is responsible:
- High affected-user overlap with successful or failed installation state of the new app.
- Symptom onset clustering soon after install or first boot after install.
- Startup traces showing the app/service materially extending login or shell-ready time.
- App crash/hang signatures recurring on affected devices only.
- Unaffected floors/users without deployment do not show similar symptoms.

What would decrease confidence the Friday deployment is responsible:
- Weak or no overlap between impacted users and deployed devices.
- Affected users who never received the deployment.
- Comparable symptoms on non-deployed floors.
- Identity or policy evidence that independently explains the failures/latency.
- Normal app startup/crash metrics with no time correlation to symptom windows.

Evidence sources to check first (ordered):
1. Intune deployment status and assignment scope for the new app.
2. SCCM deployment records (if co-management/workload overlap exists).
3. DEX startup and logon-phase performance by affected versus unaffected devices.
4. Event Viewer startup/profile/application logs on representative affected endpoints.
5. CPU, RAM, disk utilization during login window.
6. Cross-floor comparison for same time window.

Reasoning for this order:
- Start with fastest high-signal overlap checks (deployment state versus impact list).
- Then validate runtime impact and failure signatures (DEX/Event Viewer/resource data).
- Finish with control-group comparison (other floors) to test specificity.

Evidence Collection Plan

1) Data Source: Intune app deployment and device policy reports
- Why it matters: Validates who received what, when, and with what result.
- Specific evidence to collect: App assignment scope, install success/failure codes, install timestamps, remediation retries, policy assignment change history.
- How it proves/disproves deployment theory: Strong impact-overlap with install state supports; weak overlap or no install on affected users weakens.

2) Data Source: SCCM deployment records (if applicable)
- Why it matters: Confirms whether another management channel also pushed software/configuration.
- Specific evidence to collect: Advertisements, deployment collections, content distribution status, endpoint execution/failure codes.
- How it proves/disproves deployment theory: Confirms/denies hidden parallel rollout influence.

3) Data Source: Entra ID sign-in logs and Conditional Access outcomes
- Why it matters: Distinguishes authentication-plane problems from post-auth startup problems.
- Specific evidence to collect: Failure reasons, CA policy results, token issuance latency, client app and device join/compliance context.
- How it proves/disproves deployment theory: If identity failures dominate independent of deployment status, deployment theory weakens.

4) Data Source: DEX (Nexthink or equivalent) startup/logon performance telemetry
- Why it matters: Quantifies where delay occurs in the login journey.
- Specific evidence to collect: Pre-credential, auth, profile load, shell ready, and first-app launch durations; affected versus unaffected comparison.
- How it proves/disproves deployment theory: Delay concentrated after app service start or on deployed cohort supports correlation.

5) Data Source: Event Viewer on representative affected and unaffected endpoints
- Why it matters: Gives concrete local error signatures.
- Specific evidence to collect: User Profile Service, Winlogon, GroupPolicy, AppModel, application crash/hang events in incident window.
- How it proves/disproves deployment theory: Repeated deployment-app errors on affected endpoints supports; absence with alternative errors weakens.

6) Data Source: Endpoint resource telemetry (CPU/RAM/disk at login)
- Why it matters: Detects startup contention causing slow logins.
- Specific evidence to collect: Peak resource usage per process during login and 5-10 minutes post-login.
- How it proves/disproves deployment theory: New app/process resource spikes on affected devices support deployment impact.

7) Data Source: Network telemetry and endpoint connectivity tests
- Why it matters: Floor-specific network issues can mimic deployment issues.
- Specific evidence to collect: DNS resolution failures, latency/packet loss, auth endpoint reachability, proxy failures by floor segment.
- How it proves/disproves deployment theory: Segment-level network degradation independent of deployment lowers deployment confidence.

8) Data Source: Service desk ticket corpus and affected-user roster
- Why it matters: Clarifies blast radius and symptom taxonomy.
- Specific evidence to collect: Timestamped incidents, exact error messages, device IDs, location, and symptom classification.
- How it proves/disproves deployment theory: Precise symptom clustering by deployment state increases or decreases correlation confidence.

9) Data Source: Comparison set from unaffected floors/users
- Why it matters: Provides control group for differential diagnosis.
- Specific evidence to collect: Same metrics/logs for matched users/devices not reporting issues.
- How it proves/disproves deployment theory: If only Floor 6 deployed cohort deviates, deployment theory strengthens.

Most Likely Working Theory

Leading hypothesis:
- A combined identity/policy convergence issue (authentication path plus recent Intune/Win11 state convergence) is currently the leading theory, with Friday deployment as a significant but unproven co-factor.

Why it is leading:
- The symptom pair (login failures plus very slow logins) across many users is strongly compatible with identity and policy-path disruptions.
- Recent Win11 migration and Intune enrollment materially increase probability of convergence friction during Monday peak usage.
- Deployment timing is suggestive and remains in-scope, but there is no direct overlap evidence yet tying it to all affected users.

Confidence level:
- Low to Medium.

Why confidence is not yet higher:
- No direct logs, telemetry, deployment outcome data, or control-group comparisons are available yet.
- User-reported symptom wording may combine multiple technical failure modes.
- Current evidence is temporal and descriptive, not diagnostic.

Evidence that would rule out the leading theory:
- Entra sign-in logs show normal authentication success/latency for affected users while delays are isolated to a specific post-login app process.
- Intune policy timelines show no shared changes among affected users compared with unaffected controls.
- Strong alternative evidence shows single-cause network degradation or clear deployment-only failure signature explaining nearly all cases.

Investigation posture note:
- This is a ranked differential analysis for triage and investigation direction only, not a root-cause declaration or resolution plan.