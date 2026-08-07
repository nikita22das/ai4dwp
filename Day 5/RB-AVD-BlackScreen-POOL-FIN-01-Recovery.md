# Runbook - AVD POOL-FIN-01 Black Screen Recovery

## Version Header

- Title: AVD POOL-FIN-01 Black Screen Recovery
- Version: 1.0
- Date: 07/08/2026
- Author: Nikita
- reviewed: self
- status: draft
- change: initial version from RCA

## Purpose

Use this runbook when users in POOL-FIN-01 report black screen behavior or repeated session disconnects immediately after successful sign-in, and event evidence points to `dwm.exe` crashing in `igdumd64.dll` after a recent image or display driver change.

## Prerequisites

- Access to the Azure portal tenant that contains the AVD host pools. `[Elevated permissions required]`
- Rights to manage AVD host pool session hosts, including drain mode changes and host restarts. `[Elevated permissions required]`
- Rights to inspect or manage the gold image or image assignment used by POOL-FIN-01. `[Elevated permissions required]`
- Local administrator rights on affected session hosts if direct event log review or driver validation on the host is required. `[Elevated permissions required]`
- Access to Event Viewer or centralized log tooling for Application, System, and TerminalServices logs.
- The approved known-good image version or snapshot ID for POOL-FIN-01 from the change record or image release record.
- The approved known-good Intel display driver version recorded for the last stable POOL-FIN-01 release.
- A named validation account or a business-approved test user who can sign in to POOL-FIN-01.
- The list of affected session hosts in POOL-FIN-01.
- An active incident or change record to document actions and timestamps.

## Procedure

1. In Azure portal, go to `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`.  
   Expected result: The `Session hosts` grid for `POOL-FIN-01` is open and shows host names, status, drain mode, and active sessions.

2. Copy the names of the session hosts that show user impact or were part of the latest image rollout into the incident ticket or change record.  
   Expected result: You have a saved host list such as `SHFIN-01-A`, `SHFIN-01-B`, and any other impacted hosts.

3. In Azure portal, select the first affected host in `POOL-FIN-01` > choose `Drain mode` > set it to `On`. `[Elevated permissions required]`  
   Expected result: The selected host shows `Drain mode: On` in the `Session hosts` grid.

4. Repeat the `Drain mode: On` action for each remaining affected host in the same `Session hosts` grid. `[Elevated permissions required]`  
   Expected result: Every affected host shows `Drain mode: On` and no new sessions are assigned to those hosts.

5. Connect to the first affected host with an administrative session using your approved management path such as Bastion, RDP, or your remote support console. `[Elevated permissions required]`  
   Expected result: You are signed in to the affected host desktop with administrative access.

6. Open `Event Viewer` on the host and browse to `Windows Logs` > `Application`.  
   Expected result: The `Application` log is visible in the center pane.

7. In the `Application` log, choose `Filter Current Log...` and enter Event ID `1000`.  
   Expected result: The results list shows only Application Error events with Event ID `1000`.

8. Open the Event ID `1000` entries from the incident window and find one where `Faulting application name` is `dwm.exe` and `Faulting module name` is `igdumd64.dll`.  
   Expected result: You have at least one event entry that explicitly lists `dwm.exe` and `igdumd64.dll` in the event details.

9. In `Event Viewer`, browse to `Applications and Services Logs` > `Microsoft` > `Windows` > `TerminalServices-LocalSessionManager` > `Operational`.  
   Expected result: The `TerminalServices-LocalSessionManager/Operational` log is visible.

10. In the `TerminalServices-LocalSessionManager/Operational` log, choose `Filter Current Log...` and enter Event IDs `21,40`.  
   Expected result: The results list shows only session logon success and disconnect events.

11. Match one Event ID `21` logon success entry to a later Event ID `40` disconnect entry for the same user and same host within five minutes.  
   Expected result: You can point to a specific user session that logged on successfully and then disconnected shortly after.

12. In `Event Viewer`, browse to `Applications and Services Logs` > `Microsoft` > `Windows` > `Desktop Window Manager` > `Operational`.  
   Expected result: The `Desktop Window Manager/Operational` log is visible.

13. In the `Desktop Window Manager/Operational` log, choose `Filter Current Log...` and enter Event IDs `9009,9011`.  
   Expected result: The results list shows only DWM exit and DWM startup events.

14. Find an Event ID `9009` that occurs immediately after the `dwm.exe` Application Error event on the same host.  
   Expected result: The timestamps show the `dwm.exe` crash first and the DWM exit event immediately after it.

15. Open the change record, image release note, or image management console entry for the most recent `POOL-FIN-01` deployment.  
   Expected result: The current image version and the last known-good image version are both visible in the same record.

16. Compare the current deployed image version and Intel display driver version against the last known-good release record for `POOL-FIN-01`.  
   Expected result: You can name the exact version difference between the current state and the stable baseline.

17. In the image management console or deployment workflow used by your team, assign the affected host back to the approved known-good image version or snapshot ID recorded in the release history. `[Elevated permissions required]`  
   Expected result: The deployment record for that host shows the known-good image version or snapshot ID as the target state.

18. Install the approved known-good Intel display driver version on the affected host if your team’s recovery process requires a host-level driver correction before reboot. `[Elevated permissions required]`  
   Expected result: `Device Manager` > `Display adapters` > the Intel adapter > `Driver` tab shows the approved known-good driver version.

19. Restart the affected host from Azure portal or from the guest operating system after the image or driver correction is in place. `[Elevated permissions required]`  
   Expected result: The host restarts and later returns to `Available` or your platform’s healthy equivalent state.

20. In Azure portal, refresh `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts` until the restarted host shows `Status: Available`.  
   Expected result: The host is online, registered, and visible as available in the session host list.

21. Sign in to the `Remote Desktop` client or the approved AVD web client with the validation account and launch the desktop or app path mapped to `POOL-FIN-01`.  
   Expected result: The user reaches the Windows desktop without a black screen and remains connected.

22. Keep the validation session open for 10 minutes without reconnecting or refreshing the client.  
   Expected result: The session stays connected for the full 10 minutes and no black screen appears.

23. On the remediated host, reopen `Event Viewer` > `Windows Logs` > `Application` and review Event ID `1000` entries created after the validation sign-in time.  
   Expected result: No new Event ID `1000` entry after the validation sign-in lists `dwm.exe` as the faulting application and `igdumd64.dll` as the faulting module.

24. On the remediated host, reopen `Event Viewer` > `Applications and Services Logs` > `Microsoft` > `Windows` > `Desktop Window Manager` > `Operational` and review Event ID `9009` entries created after the validation sign-in time.  
   Expected result: No new Event ID `9009` entries are present after the validation sign-in time.

25. In Azure portal, select the remediated host in `POOL-FIN-01` > choose `Drain mode` > set it to `Off`. `[Elevated permissions required]`  
   Expected result: The selected host shows `Drain mode: Off` and is eligible to accept user sessions.

26. Repeat steps 5 through 25 for each remaining affected host on your saved host list.  
   Expected result: Every affected host is remediated, validated, and returned to service.

27. Update the incident or change record with the affected host names, the restored image version, the restored driver version, the restart times, and the validation outcome for each host.  
   Expected result: The ticket contains enough detail for another engineer to see exactly what was changed and which hosts passed validation.

## Verification

1. In the AVD client session launched through `POOL-FIN-01`, verify that the user reaches a usable Windows desktop within two minutes of entering credentials.  
   Success looks like: The Start menu, taskbar, and desktop background render normally and the screen never remains black.

2. Leave the validation session connected and idle for 10 minutes.  
   Success looks like: The session remains connected for the full 10 minutes with no forced disconnect, reconnect loop, or frozen black display.

3. On each remediated host, open `Event Viewer` > `Windows Logs` > `Application` and filter for Event ID `1000` with a time range starting at the validation sign-in.  
   Success looks like: There are zero new events where `Faulting application name` is `dwm.exe` and `Faulting module name` is `igdumd64.dll`.

4. On each remediated host, open `Event Viewer` > `Applications and Services Logs` > `Microsoft` > `Windows` > `Desktop Window Manager` > `Operational` and filter for Event ID `9009` with a time range starting at the validation sign-in.  
   Success looks like: There are zero new Event ID `9009` entries after remediation.

5. In Azure portal, go to `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts` after drain mode is removed.  
   Success looks like: Each remediated host shows `Status: Available`, `Drain mode: Off`, and begins accepting new sessions without fresh user complaints.

6. Review the helpdesk queue, incident bridge, or monitoring channel for 30 minutes after the last host is returned to service.  
   Success looks like: No new ticket, alert, or user report mentions black screen after sign-in or repeated disconnects for `POOL-FIN-01`.

## Rollback

Use this rollback only if the remediation makes the host worse, breaks host registration, or increases black screen or disconnect impact. Execute steps 1 through 5 immediately and in order. The target is to get back to the exact pre-change state, not to troubleshoot further.

1. In Azure portal, go to `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, select the worsened host, and set `Drain mode` to `On`. `[Elevated permissions required]`  
   Expected result: The host shows `Drain mode: On` and stops accepting new sessions.

2. In Azure portal, while still on the same `Session hosts` page, select the worsened host and choose `Sign out` for the active session only if one is connected. `[Elevated permissions required]`  
   Expected result: The active session is removed and no new production user is on the host.

3. Open the image release record or deployment history for `POOL-FIN-01` and copy the exact pre-change image version or snapshot ID.  
   Expected result: You have the last known-good version string or snapshot ID in front of you.

4. In the image management console or deployment workflow used by your team, set the host target back to that copied pre-change image version or snapshot ID. `[Elevated permissions required]`  
   Expected result: The host deployment target matches the pre-change state exactly.

5. On the host, open `Device Manager` > `Display adapters` > `Intel` adapter > `Driver` tab and roll back to the copied pre-change Intel display driver version, then restart the host from Azure portal `Session hosts` or from the host OS. `[Elevated permissions required]`  
   Expected result: The host restarts into the pre-change image and driver state.

6. In Azure portal, refresh `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts` until the host shows `Status: Available` and `Drain mode: Off` only after it is stable.  
   Expected result: The host is back online in the pool at the pre-change baseline.

7. If the host still blacks out, disconnects, or fails to register after step 5, leave it in `Drain mode: On` and escalate to the image engineering or endpoint engineering owner immediately.  
   Expected result: The host stays contained and the rollback problem is handed off without user exposure.

## Notes

- This runbook applies when authentication succeeds first and the failure occurs during desktop composition or session initialization.
- The key signature is Event ID `1000` for `dwm.exe` with faulting module `igdumd64.dll`, followed by Event ID `40` and Event ID `9009`.
- A host that shows successful Event ID `9011` startup without matching crash events is less likely to be affected by this specific issue.
- Do not remove drain mode from a host until a controlled sign-in completes successfully and post-login logs stay clean.
- If all hosts in `POOL-FIN-01` are affected, keep the entire pool in controlled recovery and direct urgent business users to the approved alternate pool or business continuity path.
- Related document: `Day 4/INC-AVD-BlackScreen-POOL-FIN-01-RCA-2024-03-15.md`.
- Related document: `Day 4/KE-AVD-BlackScreen-POOL-FIN-01.md`.
- Related incident pattern: partial impact after an image wave can indicate staggered host rollout rather than user-specific failure.
