# Triage Note: T-1008

Summary (one line): VPN establishes connection after Windows 11 upgrade but internal resources remain unreachable, suggesting post-connect routing, DNS, or policy path issue.

Impact (who/how many/business urgency):
- Affected user count: 1 confirmed user/device to-verify for other upgraded users.
- User impact: Remote user cannot access internal business services despite VPN connected state.
- Business urgency: High to-verify (remote work blocked for internal systems).

Known facts:
- Ticket ID: T-1008.
- Symptom: VPN status shows connected.
- Functional outcome: No internal resources reachable.
- Context: Occurs after Windows 11 upgrade.
- Indicates split between tunnel establishment and resource access path.

Missing information to gather:
- Which internal resources fail: file shares, intranet, internal apps, RDP, all or subset.
- Whether issue affects hostname access only, IP access only, or both.
- Whether internet access remains normal while VPN is connected.
- VPN client version/profile and whether profile changed during/after upgrade.
- Network environment: home/office hotspot, wired/wireless.
- Whether other users on same VPN profile are affected.
- Any recent policy/certificate/compliance changes impacting VPN authorization (to-verify).
- Timestamp of successful last internal access prior to issue.

Likely catagory:
- Network Access / VPN / Post-Upgrade Connectivity (to-verify against local service taxonomy).

First diagnostic step:
- Run a quick reachability split test while VPN is connected (internal hostname and internal IP target) to determine whether failure is DNS resolution vs route/access path, then correlate with VPN client session details in approved tooling.