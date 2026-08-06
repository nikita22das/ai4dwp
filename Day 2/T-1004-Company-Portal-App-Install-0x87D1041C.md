# Triage Note: T-1004

Summary (one line): Company app installation from Company Portal fails with error 0x87D1041C, indicating an app deployment state, requirement, or detection mismatch to be validated.

Impact (who/how many/business urgency):
- Affected user count: 1 confirmed user/device to-verify if wider.
- User impact: Required business application unavailable on endpoint.
- Business urgency: Medium-High to-verify (depends on app criticality for role).

Known facts:
- Ticket ID: T-1004.
- Channel: Company Portal.
- Symptom: App fails to install.
- Observed error: 0x87D1041C (as provided in ticket).
- Device context: Endpoint enrollment/deployment workflow issue implied.

Missing information to gather:
- Exact app name/version and assignment intent (required vs available).
- Affected scope: single device/user vs multiple.
- Device compliance/enrollment state at failure time.
- Whether other Company Portal apps install successfully on same device.
- Whether install was retried after sync and reboot.
- Disk space, connectivity, and user context during install attempt.
- Deployment metadata in approved admin console: requirement rules, dependencies, supersedence, detection logic (to-verify).
- Timestamp of failure for log correlation.

Likely catagory:
- Endpoint Management / Intune / App Deployment (to-verify against local service taxonomy).

First diagnostic step:
- Validate scope and assignment by confirming the app’s assignment and device/user targeting in approved endpoint management tooling, then correlate the reported timestamp with deployment status details for requirement/detection failure indicators.