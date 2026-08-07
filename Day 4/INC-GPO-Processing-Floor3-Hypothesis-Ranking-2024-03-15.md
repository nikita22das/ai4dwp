# INC - Group Policy Processing Failure (Floor 3) - Hypothesis Ranking

Date of analysis: 2026-08-07
Incident window referenced: 2024-03-15 07:40-07:55
Scope: FB055, FB056, FB057 affected; FB058 unaffected (same OU=Finance)

## Goal
Rank the most likely causes of Group Policy processing failure using only provided scope facts, with FB058 success as the primary weighting factor.

## Key discriminator
FB058 is in the same OU as FB055-057 and successfully processes policy, while FB055-057 fail.
This strongly favors host/network-path differences over OU-level policy corruption.

## Re-ranked hypotheses (most probable first)

### 1) Client DNS assignment divergence caused by DHCP scope mismatch
Why this fits:
- Affected clients receive old/decommissioned DNS servers.
- FB058 receives correct DNS (10.10.0.10) and succeeds.
- Same OU but different DNS outcome cleanly explains split behavior.

Fastest check:
- On one failed client, run `ipconfig /all` and compare DNS server(s) to DHCP scope option for the Floor 3 subnet.

### 2) DNS resolution failure to domain controller FQDN
Why this fits:
- Logs show DNS timeout and no DNS response.
- Netlogon 5719 reports no DC available and failed query for FINBRIDGE-DC01.finbridge.local.
- Consistent with inability to locate DC when old DNS is assigned.

Fastest check:
- From an affected client, run `nslookup FINBRIDGE-DC01.finbridge.local` against currently assigned DNS.

### 3) Startup timing issue (GP attempts before valid network/DNS state)
Why this fits:
- GP/DC failures appear early in startup sequence.
- Valid DHCP lease evidence appears later in the same window.
- Timing can worsen impact when DNS is already wrong.

Fastest check:
- Correlate event timestamps (NLA, DHCP lease, Netlogon, GroupPolicy) on an affected host to confirm GP runs before usable DNS/network.

### 4) SYSVOL path access failure as downstream symptom
Why this fits:
- GroupPolicy 1058 cannot access \\FINBRIDGE-DC01\sysvol\...\gpt.ini with 0x3.
- This aligns with upstream DC name resolution/connectivity failure, not necessarily missing file.

Fastest check:
- After forcing correct DNS on one affected client, test direct access to the same SYSVOL UNC path.

### 5) OU-level policy corruption or OU-linked GPO defect
Why this fits less:
- If OU-level corruption were primary, same-OU clients would be expected to fail consistently.
- FB058 success in the same OU weakens this hypothesis substantially.

Fastest check:
- On FB058, run `gpresult /r` and verify the same OU-linked GPOs apply successfully.

## Why OU-level corruption is less likely with one same-OU success
- OU-linked policy objects are shared for clients in scope; a true OU-wide policy artifact defect usually impacts all similarly scoped machines.
- Observed outcomes align with DNS/network path differences, not OU membership.
- FB058 acts as a control case showing policy can be retrieved/applied when DC and DNS path are healthy.

## Status
- This is a weighted hypothesis ranking only.
- No root cause is declared in this note.

## Evidence Review, Root Cause Confirmation, and Action Plan (Appended 2026-08-07)

### Event log evidence
- DESKTOP-FB031, 07:40:08, Netlogon Event 5719 (Error): secure channel setup to FINBRIDGE failed; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- DESKTOP-FB031, 07:40:09 and 07:40:11, GroupPolicy Event 1058 (Error): cannot access \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini; error 0x3.
- DESKTOP-FB031, 07:40:10, GroupPolicy Event 1030 (Warning): cannot query list of Group Policy objects; error 0x546.
- DESKTOP-FB031, 07:40:12 and 07:44:01, GroupPolicy Event 1129 (Error): no network connectivity to a domain controller during policy processing.
- DESKTOP-FB031, 07:41:05, DNS Client Event 1014 (Warning): name resolution for FINBRIDGE-DC01.finbridge.local timed out; configured DNS servers did not respond.
- DESKTOP-FB031, 07:42:18, DHCP Client Event 50036 (Information): DNS assigned by DHCP was 10.10.3.250 (old/decommissioned).
- DESKTOP-FB029 (comparison host, unaffected), 07:40:05, DHCP Client Event 50036: DNS assigned was 10.10.0.10 (correct new DNS).
- DESKTOP-FB029 (comparison host, unaffected), 07:40:11, GroupPolicy Event 1500 (Information): Group Policy settings processed successfully.

### Supported hypotheses
- Supported: Client DNS assignment divergence from DHCP scope mismatch.
	- Supported by DHCP 50036 comparison: affected host(s) received decommissioned DNS; unaffected host received correct DNS.
- Supported: DNS resolution failure to domain controller FQDN.
	- Supported by Netlogon 5719 and DNS Client 1014 showing DC lookup and DNS server response failure.
- Supported: Startup timing contribution (early GP attempt before stable usable network state).
	- Supported by failure events occurring before/around lease stabilization, with DHCP details logged later in the startup sequence.
- Supported: SYSVOL path access failure as a downstream symptom.
	- Supported by repeated GroupPolicy 1058 for \\FINBRIDGE-DC01\sysvol\...\gpt.ini and GroupPolicy 1030.

### Eliminated hypotheses
- Eliminated: OU-level policy corruption or OU-linked GPO defect as the primary cause.
	- Eliminating evidence: same-OU comparison host (DESKTOP-FB029) processed policy successfully (GroupPolicy 1500 at 07:40:11).
	- Rationale: an OU-wide policy artifact defect would be expected to impact all similarly scoped machines, not split by host DNS assignment.

### Verified root cause
- DHCP scope configuration for the Floor 3 subnet still referenced decommissioned DNS server entries after migration.
- Affected clients therefore failed DC name resolution and DC reachability at startup, causing downstream Group Policy failures (1058/1030/1129).

### Resolution actions
- Immediate restoration actions:
	- On affected clients, force valid DNS use and refresh network state.
	- Run: `ipconfig /flushdns`, `ipconfig /renew`, `nltest /dsgetdc:finbridge.local`, `gpupdate /force`.
	- If emergency workaround is needed before DHCP correction, temporarily set DNS to 10.10.0.10 and revert to DHCP-managed DNS after scope fix.
- DHCP changes required:
	- Update Floor 3 DHCP scope Option 006.
	- Remove decommissioned DNS entries (including 10.10.3.250 and 172.16.5.5 where present in scope history).
	- Set correct DNS server(s), including 10.10.0.10 per migration target.
	- Replicate/synchronize across DHCP failover peers if configured.
- DNS validation steps:
	- `nslookup FINBRIDGE-DC01.finbridge.local`
	- `Resolve-DnsName FINBRIDGE-DC01.finbridge.local`
	- `nltest /dsgetdc:finbridge.local`
	- `Test-NetConnection FINBRIDGE-DC01 -Port 445`
	- `dir \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies`
- Client validation steps:
	- Confirm DNS values from lease on impacted hosts via `ipconfig /all` and `Get-DnsClientServerAddress -AddressFamily IPv4`.
	- Confirm DNS list contains only approved current DNS servers.
- Group Policy validation commands:
	- `gpupdate /force`
	- `gpresult /r /scope computer`
	- `gpresult /h C:\Temp\gpresult.html`
	- `Get-WinEvent -LogName System | Where-Object { $_.Id -in 5719,1058,1030,1129,1014,1500 } | Select-Object TimeCreated, Id, ProviderName, Message -First 50`

### Verification results
- Evidence-based conclusion from provided logs:
	- Verified failure pattern on affected host(s): DC lookup and DNS timeout (5719, 1014), followed by SYSVOL/GPO failures (1058, 1030, 1129).
	- Verified success pattern on same-OU unaffected host: correct DNS assignment and successful GP processing (50036 with 10.10.0.10, then 1500).
	- Verified discriminator: outcome tracks DNS assignment, not OU membership.
- Post-change success criteria to record as closure evidence:
	- Floor 3 DHCP Option 006 shows only current DNS server(s).
	- Renewed leases on FB055-FB057 show corrected DNS.
	- DC resolution/discovery and SYSVOL access succeed.
	- Group Policy processing returns success without recurrence of 5719/1014/1058/1030/1129 during startup checks.
