# AVD Black Screen Incident — Cause Analysis
**Pool:** POOL-FIN-01 | **Logged:** 2024-03-15 07:18 | **Reported by:** Maria Lopez, Finance (ext 4421)

---

## Incident Summary

- **Symptom:** Black screen post-login; clears after ~30 s for some users, persists indefinitely for others
- **Affected:** ~40% of users on POOL-FIN-01
- **Unaffected:** POOL-FIN-02 (IT team pool) — completely clean
- **Onset:** ~07:00 2024-03-15
- **Change:** Overnight image update to POOL-FIN-01 at 02:00 — POOL-FIN-02 was NOT included in this update wave

---

## Control Group Logic

POOL-FIN-02 shares the same infrastructure, network, storage, and AVD broker as POOL-FIN-01.
The **only variable** separating them is the image update.
POOL-FIN-02 being completely unaffected **eliminates every external cause** (network, storage, broker, GPO, DNS) and locks causation inside the image content itself.

---

## Ranked Hypotheses

### #1 — FSLogix agent regression baked into the new image
**Why it fits the control group:**
FSLogix is installed inside the image. POOL-FIN-02 retained the previous image version and previous FSLogix build — no regression. A storage or SMB path issue would have hit POOL-FIN-02 Finance users equally; the clean POOL-FIN-02 line rules that out. FSLogix mount failure is the most common producer of the black-screen-with-variable-recovery pattern in AVD.
The 40% scope is explained by partial host rollout within POOL-FIN-01 — only hosts that received the new image carry the broken FSLogix build.

**Fastest check:** FSLogix Operational event log on an affected host — event IDs 26/51 at login time (event ID 25 = clean attach).

---

### #2 — Logon script or startup entry introduced by the new image
**Why it fits the control group:**
If the script were a GPO applied to the Finance OU, POOL-FIN-02 IT users on Finance machines would also be affected. They are not. The script must therefore live inside the image (RunOnce, scheduled task, baked startup entry). Variable duration fits a script that times out for some users but blocks on a missing dependency for others.

**Fastest check:** Diff `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` and `RunOnce` between a new-image host and an old-image host.

---

### #3 — Shell (explorer.exe) or Winlogon misconfiguration in the new image
**Why it fits the control group:**
A Winlogon shell misconfiguration is a pure image-content artefact. POOL-FIN-02 never received the image so never received the bad registry key. Nothing external could cause this on one pool and not the other.

**Fastest check:**
```powershell
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" | Select-Object Shell, Userinit
```
Expected: `Shell = explorer.exe`, `Userinit = C:\Windows\system32\userinit.exe,`
Compare a new-image host vs. an old-image host.

---

### #4 — GPU/display driver regression in the new image
**Why it fits the control group:**
Driver is baked into the image; POOL-FIN-02 retained the previous driver. Drops to #4 because a driver issue would more likely affect 100% of updated hosts — the 40% partial scope is harder to explain unless POOL-FIN-01 has mixed VM SKUs.

**Fastest check:** Device Manager on an affected host for display adapter warnings; System event log for GPU driver errors at login time.

---

### #5 — Partial host rollout (deployment mechanism, not a root cause)
**Why it drops to #5:**
Partial rollout explains why 40% of POOL-FIN-01 is affected, but it is a *deployment mechanism*, not a root cause. It does not explain what is broken inside the image. POOL-FIN-02 being excluded from the wave entirely is already accounted for by all causes above. Listed here as a scope-shaping factor only.

---

## Summary Table

| Rank | Root cause | Lives inside the image? | Explains POOL-FIN-02 clean? |
|------|-----------|------------------------|------------------------------|
| 1 | FSLogix regression | Yes | Perfectly |
| 2 | Logon script / startup entry | Yes | Perfectly — rules out GPO-level cause |
| 3 | Shell / Winlogon misconfiguration | Yes | Perfectly |
| 4 | GPU/display driver regression | Yes | Perfectly — but 40% scope is weak fit |
| 5 | Partial rollout | Deployment mechanic | Already assumed by all above |

---

## Recommended First Action

In the AVD blade, compare the OS image version / last-reimaged timestamp on each session host in POOL-FIN-01. Cross-reference which hosts the affected users landed on. If affected users cluster on newly-imaged hosts, proceed to check FSLogix Operational logs on those hosts (event IDs 26/51).

Do not commit to a single root cause until at least two checks have been completed.

---

## Evidence Addendum - 2026-08-06

### Incident Window Event Details Reviewed

**Affected host:** SHFIN-01-A (Application + System logs, 07:00-07:30)

- 07:02:10 - TerminalServices-LocalSessionManager Event 21
	Session logon succeeded for FINBRIDGE\mlopez (Session ID 3).
- 07:02:14 - Kernel-General Event 1
	Host boot time recorded as 02:03:11 (restart after overnight update).
- 07:02:16 - Application Error Event 1000 (Error)
	dwm.exe crashed; faulting module igdumd64.dll; exception 0xc0000005.
- 07:02:17 - TerminalServices-LocalSessionManager Event 40
	Session disconnected for FINBRIDGE\mlopez (Session ID 3), reason code 0.
- 07:02:18 - Desktop Window Manager Event 9009 (Error)
	DWM exited with code 0x40010004.
- 07:02:44 - TerminalServices-LocalSessionManager Event 21
	Reconnect logon succeeded for FINBRIDGE\mlopez (Session ID 3).
- 07:02:46 - Application Error Event 1000 (Error)
	Repeat dwm.exe crash in igdumd64.dll; exception 0xc0000005.
- 07:02:47 - TerminalServices-LocalSessionManager Event 40
	Session disconnected again for FINBRIDGE\mlopez.
- 07:03:01 - Desktop Window Manager Event 9009 (Error)
	Repeat DWM exit with code 0x40010004.
- 07:03:10 - TerminalServices-LocalSessionManager Event 21
	Second reconnect succeeded (Session ID 4).
- 07:08:22 - TerminalServices-LocalSessionManager Event 21
	Session logon succeeded for FINBRIDGE\akapoor (Session ID 5).
- 07:08:24 - Application Error Event 1000 (Error)
	Repeat dwm.exe crash in igdumd64.dll; exception 0xc0000005.

**Comparison host (unaffected):** SHFIN-02-A (pre-update image)

- 07:01:44 - TerminalServices-LocalSessionManager Event 21
	Session logon succeeded for FINBRIDGE\bwalker (Session ID 2).
- 07:01:46 - Desktop Window Manager Event 9011 (Information)
	DWM started successfully.
- No Application Error Event 1000 entries observed in this comparison window.

### Hypothesis-by-Hypothesis Elimination Outcome

1. FSLogix agent regression - **Contradicted** by repeated graphics-stack crash signature (Event 1000 at 07:02:16, 07:02:46, 07:08:24).
2. Logon script/startup entry in image - **Contradicted** by immediate DWM and igdumd64.dll fault chain (Event 1000 at 07:02:16 and 07:02:46; Event 9009 at 07:02:18 and 07:03:01).
3. Shell/Winlogon misconfiguration - **Contradicted** because logon succeeds (Event 21 at 07:02:10, 07:02:44, 07:03:10) before compositor failure (Event 1000/9009).
4. GPU/display driver regression - **Supported** by repeated dwm.exe crashes against igdumd64.dll (Event 1000) and subsequent DWM termination (Event 9009), plus clean comparison host behavior (Event 9011, no Event 1000).
5. Partial rollout (scope mechanism) - **Supported as spread factor** by updated host restart signal (Event 1 at 07:02:14) and unaffected pre-update comparison host baseline.

### Surviving Hypothesis

**GPU/display driver regression in the updated POOL-FIN-01 image** (Intel igdumd64.dll faulting dwm.exe during user logon session establishment).

### Detailed Resolution Steps

1. Contain impact
	 - Temporarily stop new session placement on known-affected POOL-FIN-01 hosts.
	 - Drain active user sessions from affected hosts in a maintenance window.

2. Validate affected host set
	 - Build host matrix: hostname, image version, last reimage time, Event 1000 count, Event 9009 count.
	 - Confirm affected hosts show the recurring sequence: Event 21 -> Event 1000 (dwm/igdumd64) -> Event 40/9009.

3. Apply technical fix path
	 - Preferred: redeploy affected hosts from last known-good pre-update image.
	 - Alternate rapid fix: roll back or replace Intel display driver with previously validated stable version.
	 - Reboot host after driver remediation.

4. Canary validation
	 - Use 1-2 remediated hosts for controlled test logons.
	 - Success criteria:
		 - no new Event 1000 dwm.exe/igdumd64.dll crashes,
		 - no Event 9009 crash exits,
		 - no immediate reconnect/disconnect loop,
		 - no black screen symptom.

5. Image hardening and redeploy
	 - Build new gold image with validated driver pinned.
	 - Disable/guard unvalidated driver drift during image maintenance.
	 - Roll out in rings (pilot -> wave 2 -> full) with hold points.

6. Monitoring and closure
	 - Alert on burst pattern of Event 1000 (dwm.exe + igdumd64.dll).
	 - Correlate Event 21 with near-term Event 40/9009 for early detection.
	 - Close incident after two peak login windows with no recurrence.
