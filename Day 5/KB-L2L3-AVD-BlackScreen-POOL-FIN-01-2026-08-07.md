# L2/L3 Knowledge Base - AVD Black Screen and Disconnect Loop (POOL-FIN-01)

## Version Header

- v 1.0
- Date: 07/08/2026
- status: Draft

## Background

The AVD service provides virtual Windows desktops and apps for business users. During sign-in, the desktop display layer must start correctly for the user to see and interact with the desktop. If this startup fails, users can authenticate but still cannot work, causing immediate productivity impact and high service desk volume.

## Symptom

What users report:
- Black screen after sign-in.
- Repeated disconnect after sign-in.
- Sometimes temporary recovery after reconnect, then failure again.

What the engineer observes:
- Successful sign-in events followed shortly by disconnect events.
- Repeated application crashes tied to desktop rendering process.
- Impact concentrated in POOL-FIN-01, while POOL-FIN-02 remains stable.

## Root Cause

Specific technical cause:
- A regressed Intel display stack introduced by the updated POOL-FIN-01 release caused `dwm.exe` to crash in `igdumd64.dll` during session initialization.

Evidence that confirms it:
- Application Event ID 1000 on affected hosts shows:
  - Faulting application name: `dwm.exe`
  - Faulting module name: `igdumd64.dll`
  - Exception code: `0xc0000005`
- Desktop Window Manager Event ID 9009 appears immediately after the crash.
- TerminalServices log sequence shows successful logon (Event ID 21) followed by disconnect (Event ID 40).
- Comparison host in POOL-FIN-02 shows normal DWM startup (Event ID 9011) and no matching Event ID 1000 crash pattern in the same window.

## Detection

Goal: confirm this incident pattern in under 3 minutes before remediation.

1. In Azure portal, open `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts` and pick one impacted host (example: `SHFIN-01-A`).
   Expected result: You have the exact impacted host name to test.

2. Open PowerShell as Administrator on that impacted host and run:
   ```powershell
   $since = (Get-Date).AddHours(-4)
   Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$since } |
     Where-Object { $_.Message -match 'Faulting application name:\s*dwm\.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64\.dll' } |
     Select-Object -First 5 TimeCreated, Id, MachineName, Message
   ```
   Expected result: At least one `Application` log Event ID `1000` contains `Faulting application name: dwm.exe` and `Faulting module name: igdumd64.dll`.

3. If command output is empty, open Event Viewer and verify manually at exact path `Event Viewer` > `Windows Logs` > `Application` (Application log), filter `Event ID: 1000`, then open event details.
   Expected result: In the event `General` details, fields show:
   - `Faulting application name: dwm.exe`
   - `Faulting module name: igdumd64.dll`
   - `Exception code: 0xc0000005`

4. On the same impacted host, run this command for DWM exits:
   ```powershell
   Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9009; StartTime=$since } |
     Select-Object -First 10 TimeCreated, Id, MachineName
   ```
   Expected result: One or more Event ID `9009` entries exist in the same incident window.

5. Compare timestamps between Step 2 Event ID `1000` and Step 4 Event ID `9009`.
   Expected result: Event ID `9009` appears immediately after the Event ID `1000` crash timeline.

6. Run control comparison on POOL-FIN-02: in Azure portal open `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-02` > `Session hosts`, connect to one healthy host (example: `SHFIN-02-A`), then run:
   ```powershell
   $since = (Get-Date).AddHours(-4)
   Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-Desktop Window Manager/Operational'; Id=9011; StartTime=$since } |
     Select-Object -First 5 TimeCreated, Id, MachineName

   Get-WinEvent -FilterHashtable @{ LogName='Application'; Id=1000; StartTime=$since } |
     Where-Object { $_.Message -match 'Faulting application name:\s*dwm\.exe' -and $_.Message -match 'Faulting module name:\s*igdumd64\.dll' } |
     Select-Object -First 5 TimeCreated, Id, MachineName, Message
   ```
   Expected result: Control host shows Event ID `9011` (healthy DWM start) and does not show matching `Application` Event ID `1000` for `dwm.exe` + `igdumd64.dll` in same window.

7. Confirm incident signature.
   Expected result: Treat as this issue only when all are true:
   - Impacted POOL-FIN-01 host has `Application` Event ID `1000` with `igdumd64.dll` and `dwm.exe`.
   - Same impacted host has DWM Event ID `9009` around same time.
   - POOL-FIN-02 control host shows Event ID `9011` baseline and no equivalent `1000` crash signature.

## Resolution

Perform on each affected host in POOL-FIN-01.

Quick CLI setup (run once in Azure Cloud Shell or local Azure CLI):
```bash
SUBSCRIPTION_ID="<subscription-id>"
RG="<host-resource-group>"
HP="POOL-FIN-01"
SH="SHFIN-01-A"
VM="<affected-vm-name>"
WS="<avd-workspace-name>"

az account set --subscription "$SUBSCRIPTION_ID"
```

1. In Azure portal, open `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`.
   Expected result: The session host list shows `Status`, `Drain mode`, and active sessions.

2. In the same path, select the affected host and set `Drain mode` to `On`.
   Expected result: `Drain mode` changes to `On` and new sessions stop landing on the host.

3. CLI equivalent for step 2:
   ```bash
   az desktopvirtualization session-host update \
     --resource-group "$RG" \
     --host-pool-name "$HP" \
     --name "$SH" \
     --allow-new-session false
   ```
   Expected result: Command completes and host is in drain mode.

4. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts` > `<affected-host>` > `User sessions`, sign out only validation or non-critical sessions.
   Expected result: Host is clear for remediation activity.

5. CLI equivalent for step 4:
   ```bash
   az desktopvirtualization user-session list \
     --resource-group "$RG" \
     --host-pool-name "$HP" \
     --session-host-name "$SH" \
     --query "[].name" -o tsv
   ```
   Then sign out required sessions:
   ```bash
   az desktopvirtualization user-session delete \
     --resource-group "$RG" \
     --host-pool-name "$HP" \
     --session-host-name "$SH" \
     --name "<session-id>"
   ```
   Expected result: Selected sessions are removed from the host.

6. In Azure portal, open `Resource groups` > `<host-resource-group>` > `Deployments` and identify the last known-good deployment entry for POOL-FIN-01 (image/snapshot baseline).
   Expected result: Known-good baseline identifier is confirmed from deployment history.

7. In Azure portal, open `Resource groups` > `<host-resource-group>` > `Virtual machines` > `<affected-vm-name>` > `Operations` > `Run command` > `RunPowerShellScript`, and run the approved restore script for the known-good display baseline.
   Expected result: Run command returns `Succeeded`.

8. CLI equivalent for step 7:
   ```bash
   az vm run-command invoke \
     --resource-group "$RG" \
     --name "$VM" \
     --command-id RunPowerShellScript \
     --scripts "<approved-restore-script-content>"
   ```
   Expected result: CLI output returns provisioning state `Succeeded`.

9. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, select the affected host and choose `Restart`.
   Expected result: Host restarts and returns to service state.

10. CLI equivalent for step 9:
   ```bash
   az vm restart --resource-group "$RG" --name "$VM"
   ```
   Expected result: Restart command completes without error.

11. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, refresh until host shows `Status: Available`.
    Expected result: Host is registered and healthy.

12. CLI equivalent for step 11:
    ```bash
    az desktopvirtualization session-host show \
      --resource-group "$RG" \
      --host-pool-name "$HP" \
      --name "$SH" \
      --query "{status:status,allowNewSession:allowNewSession}" -o table
    ```
    Expected result: `status` is `Available` and `allowNewSession` is `false` during validation.

13. In Azure portal, open `Azure Virtual Desktop` > `Workspaces` > `<avd-workspace-name>` > `Application groups`, confirm validation account assignment, then sign in with the validation account and launch desktop.
    Expected result: Desktop opens without black screen and stays connected.

14. Keep validation session connected for 10 minutes.
    Expected result: No disconnect loop occurs.

15. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, set `Drain mode` to `Off` after successful validation.
    Expected result: Host resumes production placement.

16. CLI equivalent for step 15:
    ```bash
    az desktopvirtualization session-host update \
      --resource-group "$RG" \
      --host-pool-name "$HP" \
      --name "$SH" \
      --allow-new-session true
    ```
    Expected result: Host accepts new sessions again.

17. Repeat steps 2 through 16 for each remaining impacted host.
    Expected result: All affected hosts are remediated and returned to normal service.

## Verification

1. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, confirm each remediated host shows `Status: Available` and `Drain mode: Off`.
   Expected result: All remediated hosts are online and accepting sessions.

2. CLI equivalent for step 1:
   ```bash
   az desktopvirtualization session-host list \
     --resource-group "$RG" \
     --host-pool-name "$HP" \
     --query "[].{name:name,status:status,allowNewSession:allowNewSession}" -o table
   ```
   Expected result: Target hosts show `status=Available` and `allowNewSession=true`.

3. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts` > `<host>` > `Virtual machine`, open the VM and run quick event verification using `Run command` > `RunPowerShellScript`.
   Expected result: No new matching crash events after remediation timestamp.

4. CLI equivalent for step 3 (Event 1000 and Event 9009 verification):
   ```bash
   az vm run-command invoke \
     --resource-group "$RG" \
     --name "$VM" \
     --command-id RunPowerShellScript \
     --scripts '$since=(Get-Date).AddMinutes(-30); Get-WinEvent -FilterHashtable @{LogName="Application";Id=1000;StartTime=$since} | ? {$_.Message -match "dwm.exe" -and $_.Message -match "igdumd64.dll"} | select TimeCreated,Id,Message; Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Desktop Window Manager/Operational";Id=9009;StartTime=$since} | select TimeCreated,Id'
   ```
   Expected result: No post-fix Event 1000 (`dwm.exe` + `igdumd64.dll`) and no post-fix Event 9009.

5. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-02` > `Session hosts`, validate control host remains healthy.
   Expected result: Control host behavior remains normal.

6. CLI control check for healthy baseline (Event 9011):
   ```bash
   az vm run-command invoke \
     --resource-group "$RG" \
     --name "<pool-fin-02-vm-name>" \
     --command-id RunPowerShellScript \
     --scripts '$since=(Get-Date).AddMinutes(-30); Get-WinEvent -FilterHashtable @{LogName="Microsoft-Windows-Desktop Window Manager/Operational";Id=9011;StartTime=$since} | select -First 5 TimeCreated,Id'
   ```
   Expected result: Event 9011 is present on control host in verification window.

7. Confirm service stability for 30 minutes from completion time.
   Expected result: No new black-screen/disconnect tickets for POOL-FIN-01.

## Rollback

Use rollback immediately if remediation causes broader failure, failed registration, or worse user impact.

1. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, select affected host and set `Drain mode` to `On`.
   Expected result: New sessions are blocked from the unstable host.

2. CLI equivalent for step 1:
   ```bash
   az desktopvirtualization session-host update \
     --resource-group "$RG" \
     --host-pool-name "$HP" \
     --name "$SH" \
     --allow-new-session false
   ```
   Expected result: Host is drained.

3. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts` > `<affected-host>` > `User sessions`, sign out active validation sessions.
   Expected result: Host is isolated from active workload.

4. In Azure portal path `Resource groups` > `<host-resource-group>` > `Deployments`, open the pre-change deployment entry and copy the baseline image/snapshot version.
   Expected result: Exact rollback baseline is identified.

5. In Azure portal path `Resource groups` > `<host-resource-group>` > `Virtual machines` > `<affected-vm-name>` > `Settings` > `Extensions + applications`, confirm rollback extension/script target, then run `Operations` > `Run command` > `RunPowerShellScript` with approved rollback script.
   Expected result: Rollback command completes with `Succeeded`.

6. CLI equivalent for step 5:
   ```bash
   az vm run-command invoke \
     --resource-group "$RG" \
     --name "$VM" \
     --command-id RunPowerShellScript \
     --scripts "<approved-rollback-script-content>"
   ```
   Expected result: CLI reports successful rollback execution.

7. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, restart the host.
   Expected result: Host reboots to the pre-change baseline.

8. CLI equivalent for step 7:
   ```bash
   az vm restart --resource-group "$RG" --name "$VM"
   ```
   Expected result: Restart completes.

9. In Azure portal path `Azure Virtual Desktop` > `Host pools` > `POOL-FIN-01` > `Session hosts`, refresh until host is `Status: Available`.
   Expected result: Host is registered and online.

10. CLI equivalent for step 9:
    ```bash
    az desktopvirtualization session-host show \
      --resource-group "$RG" \
      --host-pool-name "$HP" \
      --name "$SH" \
      --query "{status:status,allowNewSession:allowNewSession}" -o table
    ```
    Expected result: Host returns to `Available` with controlled session state.

11. If issue persists, keep `Drain mode` on and escalate to image engineering or endpoint engineering with host name, timestamps, Deployment ID, and Event ID 1000 or 9009 evidence.
    Expected result: User impact remains contained while deeper remediation proceeds.

## Preventive

Implement these specific controls to prevent recurrence:

1. Owner: `Image owner`; Timing: `before deployment`; Type: `automated`.
   Control: pin approved Intel display version in baseline and block drift in pipeline; pass = build artifact version exactly matches approved version and drift checks return 0 mismatches; fail = any mismatch blocks release and opens a change task to image owner.

2. Owner: `Release engineer`; Timing: `before deployment`; Type: `automated` [REQUIRES: CI/CD release gate].
   Control: canary gate fails promotion if any `Application` Event ID `1000` with `dwm.exe` + `igdumd64.dll` appears in test run; pass = count is `0`; fail = pipeline hard-stop, auto-notify release engineer and image owner.

3. Owner: `Release engineer`; Timing: `during deployment`; Type: `automated` [REQUIRES: staged rollout orchestrator].
   Control: enforce rollout 10% -> 30% -> 100%; pass = in each hold window, Event ID `1000` (`dwm.exe`+`igdumd64.dll`) count = `0` and Event ID `9009` rate <= `1` per host per 30 min; fail = freeze progression at current wave.

4. Owner: `DWP engineer`; Timing: `during deployment`; Type: `automated` [REQUIRES: central event monitoring].
   Control: alert on `Application` log signature Event ID `1000` where faulting app is `dwm.exe` and module is `igdumd64.dll`; pass = no alert in rollout window; fail = Sev2 incident created and on-call paged within 5 minutes.

5. Owner: `DWP engineer`; Timing: `during deployment`; Type: `automated` [REQUIRES: correlation rule engine].
   Control: correlation alert when Event `21` then `40` plus DWM `9009` occur on same host within 5 minutes; pass = correlation count `0`; fail = host auto-marked for drain and escalation task generated.

6. Owner: `Image owner`; Timing: `after deployment`; Type: `automated` [REQUIRES: CMDB or inventory job].
   Control: update host-to-image and host-to-driver inventory after each deployment; pass = 100% of session hosts reported with current image/driver within 15 minutes; fail = change cannot be closed until inventory completeness reaches 100%.

7. Owner: `Change manager`; Timing: `before deployment`; Type: `manual`.
   Control: CAB checkpoint must include display stack change summary plus rollback artifact; pass = CAB record has rollback script, trigger threshold, and owner approvals; fail = CAB rejects release and returns to release engineer.
   Automation note: validate CAB template fields with mandatory form rules [REQUIRES: CAB workflow enforcement].

8. Owner: `Release engineer`; Timing: `before deployment`; Type: `automated` [REQUIRES: pre-deployment smoke test pack].
   Control (added layer: pre-deployment test gate): run smoke test with 5 sign-in/sign-out cycles and 3 reconnect cycles on canary; pass = Event ID `1000` count `0`, Event ID `9009` count `0`, and successful DWM start Event ID `9011` >= `5`; fail = block release and open defect.

9. Owner: `DWP engineer`; Timing: `during deployment`; Type: `automated` [REQUIRES: rollout watch dashboard + alerting].
   Control (added layer: in-flight monitoring): monitor per-host counters every 5 minutes for Event IDs `1000`, `9009`, and `40`; pass = no host exceeds threshold (`1000` >=1 or `9009` >=2 or `40` >=3 in 15 min); fail = alert and drain affected host.

10. Owner: `DWP engineer`; Timing: `after deployment`; Type: `manual`.
    Control (added layer: post-deployment validation): validate one user sign-in per remediated host and run 30-minute log check for Event IDs `1000`/`9009`; pass = zero matching errors and users reach desktop in <=2 minutes; fail = reopen incident and keep host drained.
    Automation note: run validation script via `az vm run-command` for all hosts and aggregate results.

11. Owner: `Change manager`; Timing: `during deployment`; Type: `automated` [REQUIRES: release guardrail policy].
    Control (added layer: rollback trigger): trigger rollback automatically if any wave has >=2 hosts with Event ID `1000` (`dwm.exe` + `igdumd64.dll`) within 15 minutes; pass = threshold not hit; fail = auto-stop rollout and execute rollback playbook for current wave.

12. Owner: `Service desk lead`; Timing: `after deployment`; Type: `manual`.
    Control (added layer: knowledge update): update L1, L2/L3 KB, and runbook checklist within 1 business day after incident closure; pass = document version updated and change log entry present; fail = problem record remains open until updates are published.
    Automation note: create ticket workflow step that blocks problem closure until KB update task is completed [REQUIRES: ITSM workflow rule].

## Related

- Day 4 incident RCA: `Day 4/INC-AVD-BlackScreen-POOL-FIN-01-RCA-2024-03-15.md`
- Day 4 known error: `Day 4/KE-AVD-BlackScreen-POOL-FIN-01.md`
- Day 5 recovery runbook: `Day 5/RB-AVD-BlackScreen-POOL-FIN-01-Recovery.md`
- Day 5 end-user KB: `Day 5/KB-AVD-BlackScreen-EndUser-2026-08-07.md`
- Day 5 first-line desk KB: `Day 5/KB-L1-AVD-BlackScreen-Triage-2026-08-07.md`
