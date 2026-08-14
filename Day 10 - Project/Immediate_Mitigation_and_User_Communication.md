Title: Floor 6 Immediate Mitigation and User Communication
Version: 1.0
Date: 14/08/2026
Author: Nikita
Status: Draft

Situation Summary

What was reported:
- Floor 6 users (Legal, 45 devices) reported login failures, slow logins, and degraded device performance on Monday morning.
- A new Document Management application was deployed to Floor 6 on Friday afternoon.

What evidence was reviewed:
- Differential analysis outputs and triage reasoning from the completed investigation document.
- Correlation factors used: timing (Friday deployment versus Monday impact), symptom pattern (login plus performance), and affected user count (at least a dozen).
- Constraint: no definitive telemetry bundle (DEX exports, full Intune/SCCM evidence pack, Event Viewer exports) has yet been attached as final proof.

Leading hypothesis:
- The deployed Document Management application is sufficiently likely to be contributing to startup contention, login delay, or instability on a subset of Floor 6 devices.

Why action is being taken now:
- Judgement: impact is active and material to business continuity (multiple users blocked or significantly delayed).
- Evidence: temporal and symptom correlation is strong enough to justify reversible mitigation while investigation continues.
- This is a risk-reduction action, not a root-cause declaration.

Immediate Technical Action

Assumptions for command examples:
- Intune environment is accessible through Microsoft Graph PowerShell.
- SCCM site is available through ConfigurationManager PowerShell module.
- Affected device list is available in a CSV file with DeviceName and serial/managed identifiers.
- Existing pilot/deployment ring model is in use.
- Commands are realistic examples and must be aligned to tenant naming, IDs, and change-control policy before execution.

Intune option (example operational sequence):

1) Command:
```powershell
Connect-MgGraph -Scopes "DeviceManagementApps.ReadWrite.All","DeviceManagementManagedDevices.ReadWrite.All","Group.ReadWrite.All"
$affected = Import-Csv "C:\Temp\Floor6_AffectedDevices.csv"
$group = New-MgGroup -DisplayName "GRP-Floor6-Affected-Mitigation" -MailEnabled:$false -MailNickname "grp_floor6_affected_mitigation" -SecurityEnabled
```
Purpose:
- Establish admin session and create a dedicated mitigation target group for affected devices.
Expected Result:
- Graph session established and group created.
Validation Check:
```powershell
Get-MgGroup -Filter "displayName eq 'GRP-Floor6-Affected-Mitigation'" | Select-Object Id,DisplayName
```

2) Command:
```powershell
foreach ($d in $affected) {
    $md = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$($d.DeviceName)'"
    if ($md) {
        $aad = Get-MgDevice -Filter "deviceId eq '$($md.AzureAdDeviceId)'"
        if ($aad) { New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $aad.Id }
    }
}
```
Purpose:
- Target only impacted endpoints for mitigation to minimize collateral impact.
Expected Result:
- Affected devices are members of mitigation group.
Validation Check:
```powershell
Get-MgGroupMember -GroupId $group.Id -All | Measure-Object
```

3) Command:
```powershell
# Assumption: app object and assignment IDs are known for the Friday rollout.
$appId = "<IntuneWinAppId>"
$assignmentId = "<Floor6RingAssignmentId>"
Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $appId -MobileAppAssignmentId $assignmentId
```
Purpose:
- Remove affected devices or Floor 6 ring from active rollout assignment.
Expected Result:
- Devices stop receiving new install/enforcement from that assignment.
Validation Check:
```powershell
Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $appId | Select-Object Id,Intent,Target
```

4) Command:
```powershell
# Assumption: supersedence/rollback package exists (previous known-good version)
$rollbackAppId = "<PreviousVersionAppId>"
# Create required assignment to mitigation group (example payload omitted for brevity)
Write-Host "Assign rollback app $rollbackAppId to mitigation group $($group.Id)"
```
Purpose:
- Roll back impacted endpoints to known-good version quickly.
Expected Result:
- Affected devices begin uninstall/reinstall path to previous stable app version.
Validation Check:
```powershell
# Validate install state trend for rollback package
Get-MgDeviceAppManagementMobileApp -MobileAppId $rollbackAppId | Select-Object Id,DisplayName
```

5) Command:
```powershell
# Tenant-wide stop-gap: pause further rollout by removing include assignment to remaining pilot ring
$remainingAssignmentId = "<RemainingRolloutAssignmentId>"
Remove-MgDeviceAppManagementMobileAppAssignment -MobileAppId $appId -MobileAppAssignmentId $remainingAssignmentId
```
Purpose:
- Stop additional exposure while evidence is collected.
Expected Result:
- No further devices are newly targeted by this rollout.
Validation Check:
```powershell
Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $appId
```

SCCM option (example operational sequence):

1) Command:
```powershell
Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
Set-Location "ABC:"   # Assumption: site code is ABC
$affected = Import-Csv "C:\Temp\Floor6_AffectedDevices.csv"
New-CMDeviceCollection -Name "COLL-Floor6-Affected-Mitigation" -LimitingCollectionName "All Systems"
```
Purpose:
- Prepare SCCM scope for targeted mitigation.
Expected Result:
- Collection exists for affected devices.
Validation Check:
```powershell
Get-CMDeviceCollection -Name "COLL-Floor6-Affected-Mitigation"
```

2) Command:
```powershell
foreach ($d in $affected) {
    $dev = Get-CMDevice -Name $d.DeviceName
    if ($dev) {
        Add-CMDeviceCollectionDirectMembershipRule -CollectionName "COLL-Floor6-Affected-Mitigation" -ResourceId $dev.ResourceId
    }
}
```
Purpose:
- Add only impacted devices to mitigation collection.
Expected Result:
- Membership reflects affected set.
Validation Check:
```powershell
Get-CMDeviceCollectionDirectMembershipRule -CollectionName "COLL-Floor6-Affected-Mitigation" | Measure-Object
```

3) Command:
```powershell
# Stop further rollout to Floor 6 ring
Disable-CMApplicationDeployment -ApplicationName "Document Management App" -CollectionName "COLL-Floor6-Ring"
```
Purpose:
- Halt continued deployment pressure while investigating.
Expected Result:
- New enforcement to ring is stopped.
Validation Check:
```powershell
Get-CMDeployment -SoftwareName "Document Management App" | Select-Object CollectionName,Enabled
```

4) Command:
```powershell
# Roll back by deploying previous version to affected collection and enabling uninstall of problematic version
Start-CMApplicationDeployment -Name "Document Management App - Previous Stable" -CollectionName "COLL-Floor6-Affected-Mitigation" -DeployAction Install -DeployPurpose Required
Start-CMApplicationDeployment -Name "Document Management App - Current" -CollectionName "COLL-Floor6-Affected-Mitigation" -DeployAction Uninstall -DeployPurpose Required
```
Purpose:
- Revert impacted endpoints to known-good baseline.
Expected Result:
- Current version removed and prior version installed on affected devices.
Validation Check:
```powershell
Get-CMDeploymentStatusDetails -CollectionName "COLL-Floor6-Affected-Mitigation" -SoftwareName "Document Management App - Previous Stable"
```

5) Command:
```powershell
# Force policy refresh for faster convergence
Invoke-CMClientAction -CollectionName "COLL-Floor6-Affected-Mitigation" -ActionType MachinePolicyRetrievalEvalCycle
```
Purpose:
- Accelerate mitigation policy/application updates.
Expected Result:
- Faster receipt and execution of rollback actions.
Validation Check:
```powershell
Get-CMClientStatusSetting
```

Verification Plan

1) Login performance
- What to measure: Average sign-in duration, failed sign-in count, and P95 time-to-desktop for affected users.
- Success criteria: Sustained reduction in failed logins and measurable improvement in sign-in duration versus incident window.
- Failure criteria: No material improvement or continued upward failure trend after mitigation propagation window.

2) User experience
- What to measure: Number of new tickets from Floor 6, user-reported ability to start work within normal time.
- Success criteria: Significant drop in fresh incident tickets and positive user validation from affected cohort.
- Failure criteria: Continued complaints at similar or higher volume.

3) Application behavior
- What to measure: Crash/hang rates and startup events for current versus rolled-back app versions.
- Success criteria: Reduced crash/hang telemetry and stable launch behavior post-rollback.
- Failure criteria: App instability persists despite rollback, suggesting alternate cause.

4) Device performance
- What to measure: CPU, memory, and disk saturation during login and first 10 minutes after login.
- Success criteria: Resource contention decreases toward pre-incident baseline.
- Failure criteria: Persistent contention with no version-linked improvement.

5) Comparison against pre-change behavior
- What to measure: Delta between post-mitigation metrics and baseline from pre-Friday deployment period or unaffected control devices.
- Success criteria: Post-mitigation trend converges toward baseline/control profile.
- Failure criteria: Metrics remain materially worse than baseline/control.

Floor 6 Communication

Team, we know this morning has been disruptive, and we are sorry for the impact this has had on your start to the day. We have identified a likely connection between the recent Floor 6 software rollout and the login/performance issues being reported, and we are now applying a targeted rollback on affected devices while the investigation continues.

This does not mean we have confirmed a final cause yet, but it is the fastest low-risk step to reduce disruption while we keep validating evidence. If you are affected, please keep your device on, connected to the network, and restart once when prompted by IT; if problems continue after restart, log a ticket and include your device name and time of issue so we can prioritize you quickly.

Thank you for your patience while we work this through carefully.

Reasoning

Why this mitigation was chosen:
- Evidence: timing and symptom pattern create credible deployment correlation, and rollback is reversible and targeted.
- Judgement: targeted containment provides near-term relief without waiting for perfect certainty.

Why chosen action has lower risk than waiting:
- Waiting allows continued user disruption and potential expansion of impact.
- Targeted rollback limits blast radius and preserves investigation integrity by changing one major variable under change control.

What evidence would reverse this decision:
- Strong evidence that unaffected non-deployed devices show identical symptoms at same rate.
- Identity or network telemetry conclusively shows a separate dominant cause unrelated to application version.
- Post-mitigation data shows no improvement and no app-behavior signal difference between versions.

Ongoing investigation posture:
- This remains an active investigation; mitigation does not equal root-cause confirmation.