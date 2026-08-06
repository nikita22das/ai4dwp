# Triage Note: T-1003

Summary (one line): AVD session disconnects after approximately 10 minutes and then reconnects, indicating a likely session transport, policy timeout, or network stability issue.

Impact (who/how many/business urgency):
- Affected user count: 1 confirmed user to-verify for broader pattern.
- User impact: Repeated session interruption impacts productivity and workflow continuity.
- Business urgency: Medium to-verify (higher if impacting multiple users or critical shifts).

Known facts:
- Ticket ID: T-1003.
- Platform: Azure Virtual Desktop (AVD).
- Symptom: Session disconnects after about 10 minutes.
- Follow-on behavior: Session reconnects.
- Pattern: Time-based recurrence implied (~10 minutes).

Missing information to gather:
- Whether issue affects one user, one host pool, or multiple users.
- Client used: Windows app, web client, thin client, or other.
- Network context: office, home, VPN, wired/wireless.
- Whether disconnect happens during idle only or also during active use.
- Exact timestamps for last 3 disconnect events for correlation.
- Whether user sees any specific disconnect notification text/code (to-verify).
- Recent changes to AVD host pool policies, session timeout settings, or networking path (to-verify).
- Whether other applications drop network at the same time.

Likely catagory:
- EUC / AVD / Session Stability (to-verify against local service taxonomy).

First diagnostic step:
- Establish reproducibility and scope by collecting exact disconnect timestamps and usage state (idle vs active), then correlate with AVD session diagnostics and host/network event timelines in approved monitoring tools.