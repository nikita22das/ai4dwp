# Root Cause Analysis — Autopilot Enrolment Failure
## Error: 0x80180014 / 0x80070005

| Field | Detail |
|---|---|
| **RCA Reference** | RCA-2026-08-11-AUTOPILOT-001 |
| **Incident Reference** | INC-Autopilot-EnrolmentFailure-0x80180014 |
| **Date of Incident** | 2026-08-11 |
| **Date of RCA** | 2026-08-11 |
| **Author** | DWP Endpoint Engineer |
| **Review Status** | Draft — pending technical sign-off |
| **Severity** | Medium |
| **Service Affected** | Microsoft Autopilot / Intune MDM Enrolment |
| **Device Scope** | Single device (stale legacy MDM enrolment from 2023-11-04) |

---

## 1. Executive Summary

A Windows 11 device submitted for Autopilot enrolment failed with error `0x80180014` (MENROLL_E_DEVICE_ALREADY_ENROLLED). Investigation confirmed the device carried a legacy manual MDM enrolment registered on 2023-11-04 that had never been removed prior to Autopilot deployment. The Autopilot flow was unable to proceed past the enrolment phase, leaving 0 of 4 Intune configuration profiles applied. A secondary error `0x80070005` (Access Denied) was recorded against all profile-write attempts — confirmed as a downstream consequence of the blocked enrolment, not an independent fault.

Network connectivity was healthy, and all required licences (Intune P1, Autopilot) were present. The failure was entirely attributable to a process gap: no device wipe or MDM de-registration was performed before the device was reassigned to the Autopilot deployment group.

**Resolution:** Remove stale enrolment artefacts, delete orphaned Intune and AAD device objects, perform a full device reset to OOBE, and allow the Autopilot flow to complete from a clean state.

---

## 2. Supporting Evidence

### 2.1 MDM Diagnostic Export (raw)

```
EnrollmentState  : Failed
ErrorCode        : 0x80180014
ErrorDescription : The device is already enrolled in MDM.
MDMEnrolled      : Yes (previous enrolment from 2023-11-04)
EnrolmentSource  : Legacy manual MDM enrolment
ProfilesApplied  : 0 of 4
LastError        : 0x80070005 (Access denied)
AzureADJoined    : Yes
IntuneP1License  : Yes
AutopilotLicense : Yes
Network          : All endpoints reachable, no proxy
```

### 2.2 Error Code Verification

| Error Code | Hex | Official Name | Confirmed Meaning |
|---|---|---|---|
| `0x80180014` | MENROLL_E_DEVICE_ALREADY_ENROLLED | Device already enrolled | Confirmed — standard Intune MDM enrolment error returned when an active MDM enrolment is detected during a new enrolment attempt |
| `0x80070005` | ERROR_ACCESS_DENIED | Access denied | Confirmed — standard Windows system error; in MDM context indicates the new enrolment context was denied write access to the CSP/registry policy store, blocked by the existing enrolment's artefacts |

### 2.3 Factors Ruled Out

| Factor | Evidence | Conclusion |
|---|---|---|
| Licensing gap | IntuneP1License: Yes / AutopilotLicense: Yes | Eliminated |
| Network / proxy failure | All endpoints reachable, no proxy | Eliminated |
| Azure AD join state | AzureADJoined: Yes | Not a contributing factor |
| Conditional Access block | No CA block evidence; device never reached compliance evaluation | Not applicable at failure point |
| Hardware incompatibility | Not indicated in export | No evidence |

### 2.4 Related Compliance Policy Context

The device was being enrolled under the DWP Windows 11 Intune Compliance Policy (ref: [Day 6/DWP-Win11-Intune-Compliance-Policy.md](DWP-Win11-Intune-Compliance-Policy.md)), which mandates:
- BitLocker, Secure Boot, OS build minimum, Defender RTP, Firewall, PIN, and Device Integrity.
- All settings carry a 7-day grace period.

Because enrolment failed before any profiles were applied, compliance evaluation was never reached. Had enrolment succeeded, the 7-day grace period would have covered HAS sync latency (BitLocker, Secure Boot) and Windows Hello for Business provisioning (PIN).

---

## 3. Incident Timeline

| Time | Event | Source |
|---|---|---|
| **2023-11-04** | Device manually enrolled into MDM via legacy enrolment process. No Autopilot profile assigned at this time. | MDM diagnostic export — EnrolmentSource field |
| **2023-11-04 → 2026-08-10** | Device remained under legacy MDM management. No wipe, Autopilot reset, or de-registration performed during this period. | Inferred from diagnostic export — stale enrolment still active |
| **2026-08-10 (approx.)** | Device reassigned and added to Autopilot deployment group. No pre-reassignment wipe checklist completed. | Process gap identified during analysis |
| **2026-08-11 (T+0)** | Autopilot enrolment initiated at OOBE. Device was not in a clean reset state. | MDM diagnostic export — EnrollmentState: Failed |
| **2026-08-11 (T+0)** | Autopilot returns `0x80180014` — enrolment blocked by existing MDM registration. | MDM diagnostic export — ErrorCode |
| **2026-08-11 (T+0)** | MDM client attempts to apply 4 Intune configuration profiles; all fail with `0x80070005`. | MDM diagnostic export — ProfilesApplied: 0 of 4 / LastError |
| **2026-08-11 (T+0)** | Autopilot flow terminates. Device remains in OOBE failure state. | MDM diagnostic export — EnrollmentState: Failed |
| **2026-08-11 (T+1)** | MDM diagnostic export collected and submitted for analysis. | This RCA |
| **2026-08-11 (T+2)** | Root cause confirmed. Remediation plan approved. | This RCA |
| **Pending** | Stale enrolment removed, device wiped, Autopilot re-triggered. | Resolution — see Section 6 |

---

## 4. Five Why Analysis

### Problem Statement
*A Windows 11 device failed Autopilot enrolment with error 0x80180014 and no Intune configuration profiles were applied.*

---

**Why 1 — Why did Autopilot enrolment fail?**

> Because the device already had an active MDM enrolment (`MDMEnrolled: Yes`, dated 2023-11-04).  
> Autopilot requires the device to have no prior MDM registration. The presence of the legacy enrolment caused the service to return `MENROLL_E_DEVICE_ALREADY_ENROLLED` (`0x80180014`) and halt the flow.

---

**Why 2 — Why did the device still have an active MDM enrolment?**

> Because the device was not wiped or MDM de-registered before being reassigned and added to the Autopilot deployment group.  
> The legacy manual enrolment from 2023-11-04 had been live for approximately 2 years and 9 months without intervention.

---

**Why 3 — Why was the device not wiped or de-registered before reassignment?**

> Because there was no enforced checklist or automated gate in the device repurposing process that required confirmation of a clean MDM state before a device could be added to the Autopilot deployment group.  
> The reassignment was performed manually without following a formal offboarding-then-onboarding procedure.

---

**Why 4 — Why was there no enforced gate in the repurposing process?**

> Because the device repurposing Standard Operating Procedure (SOP) was written before Autopilot was introduced and does not include Autopilot-specific prerequisites (clean OOBE state, MDM de-registration, Intune/AAD object deletion).  
> The SOP has not been reviewed or updated to reflect the current Intune/Autopilot deployment model.

---

**Why 5 — Why has the SOP not been updated to reflect Autopilot requirements?**

> Because there is no scheduled review cadence for endpoint SOPs tied to platform changes.  
> When Autopilot was adopted, the operational change was communicated informally. No formal SOP update was commissioned, no owner was assigned to maintain the document, and no training was delivered to the team performing device repurposing.

---

### Root Cause Statement

**The root cause is the absence of a maintained, Autopilot-aware device repurposing SOP with an enforced clean-state prerequisite.** The immediate cause (stale enrolment) and the triggering event (device reassigned without wipe) are both direct consequences of this process gap. The technical errors (`0x80180014`, `0x80070005`) are symptoms, not causes.

---

## 5. Impact Assessment

| Category | Impact | Detail |
|---|---|---|
| **User productivity** | Low–Medium | Device unavailable for use until remediation completes. No data loss. |
| **Security posture** | Low | Device never reached compliance evaluation; no CA-protected resources were accessed from this device in its failed state. |
| **Service availability** | None | No shared service disrupted; single-device failure. |
| **Compliance risk** | Low | Device is not compliant and not yet subject to Conditional Access enforcement (enrolment not completed). 7-day grace period will apply once enrolment succeeds. |
| **Repeat risk** | Medium–High | If the SOP gap is not closed, any other repurposed legacy-MDM device will reproduce this failure identically. |

---

## 6. Resolution Plan

### Immediate Actions (this device)

| Step | Action | Owner | Completion Criteria |
|---|---|---|---|
| 1 | Confirm stale enrolment via `Settings → Accounts → Access work or school` | Technician | Legacy MDM entry visible and confirmed |
| 2 | Disconnect stale MDM enrolment from device settings | Technician | Entry removed from Access work or school |
| 3 | Delete orphaned Intune device record (2023-11-04 entry) | Intune Admin | Device record absent from Intune → Devices → All devices |
| 4 | Delete duplicate AAD device object if present | Intune Admin | Single clean device object in AAD → Devices |
| 5 | Confirm Autopilot hardware hash is registered | Intune Admin | Hash visible in Devices → Enrol devices → Windows enrolment → Devices |
| 6 | Perform full Autopilot Reset or wipe (Remove everything) | Technician / Intune Admin | Device presents OOBE screen cleanly |
| 7 | Allow Autopilot enrolment flow to complete | Unattended | Enrolment Status Page shows success; all 4 profiles applied |
| 8 | Validate compliance state in Intune (allow up to 24 h for HAS sync) | Intune Admin | Device shows Compliant or In grace period — no Failed profiles |

### Contingency — If `0x80070005` persists after clean re-enrolment

Remove residual DMCLIENT artefacts manually (run as SYSTEM):

```powershell
# Identify and remove stale MDM enrolment registry keys
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" | Where-Object {
    (Get-ItemProperty $_.PSPath).EnrollmentType -ne $null
} | Select-Object Name

# Remove the stale GUID key — replace <STALE-GUID> with value found above
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Enrollments\<STALE-GUID>" -Recurse -Force

# Restart MDM services
Restart-Service -Name dmwappushsvc -Force
Restart-Service -Name DeviceManagementService -Force
```

Remove stale MDM certificate via `certlm.msc → Personal → Certificates` — remove any certificate whose subject or friendly name references the old enrolment GUID.

---

## 7. Preventive Actions

### PA-01 — Update Device Repurposing SOP to include Autopilot prerequisites

| Field | Detail |
|---|---|
| **Action** | Revise the device repurposing SOP to add a mandatory pre-reassignment checklist: (1) disconnect MDM enrolment on device, (2) delete Intune device object, (3) delete AAD device object, (4) confirm hardware hash in Autopilot device list, (5) perform Autopilot Reset or full wipe before reassignment is marked complete. |
| **Owner** | DWP Endpoint Engineering — SOP Owner |
| **Target Date** | Within 14 days of RCA sign-off |
| **Success Metric** | Updated SOP published and distributed to all staff performing device repurposing |

---

### PA-02 — Implement an automated stale-enrolment detection alert

| Field | Detail |
|---|---|
| **Action** | Create an Intune Device Filter or Azure AD dynamic device group that identifies devices with an enrolment date older than 18 months that are members of an Autopilot deployment group. Generate a weekly report to the endpoint team for manual review and pre-emptive clean-up. |
| **Owner** | DWP Intune Administrator |
| **Target Date** | Within 21 days of RCA sign-off |
| **Success Metric** | Weekly report active; zero devices in Autopilot group with stale enrolment date > 18 months |

---

### PA-03 — Adopt Autopilot Reset as the standard device repurposing method

| Field | Detail |
|---|---|
| **Action** | For all currently Intune-managed devices being repurposed, mandate the use of **Intune → device → Autopilot Reset** rather than manual wipes. This ensures DMCLIENT state, MDM certificates, and registry artefacts are fully cleared by the platform. Document this as the preferred method in the updated SOP (PA-01). |
| **Owner** | DWP Endpoint Engineering |
| **Target Date** | Incorporated into PA-01 SOP revision |
| **Success Metric** | Autopilot Reset used as default method; manual wipes reserved only for devices not reachable via Intune |

---

### PA-04 — Deliver targeted briefing to device repurposing staff

| Field | Detail |
|---|---|
| **Action** | Deliver a short (30-minute) briefing to all staff who perform device repurposing, covering: Autopilot clean-state requirements, the updated SOP checklist (PA-01), the correct use of Autopilot Reset (PA-03), and the consequences of skipping MDM de-registration. Document attendance. |
| **Owner** | DWP Endpoint Engineering Lead |
| **Target Date** | Within 21 days of RCA sign-off |
| **Success Metric** | 100% of repurposing staff briefed and attendance recorded |

---

### PA-05 — Establish a platform-change SOP review trigger

| Field | Detail |
|---|---|
| **Action** | Add a standing agenda item to the DWP Endpoint Engineering change review process: any adoption of a new device management platform or deployment method (e.g. Autopilot, co-management changes, new enrolment profile types) must trigger a formal review of all related operational SOPs within 30 days of go-live. Assign a named SOP owner for each document. |
| **Owner** | DWP Endpoint Engineering Lead / Change Manager |
| **Target Date** | Within 30 days of RCA sign-off |
| **Success Metric** | Process documented; SOP owners assigned; review trigger included in change management template |

---

## 8. Lessons Learned

| # | Lesson |
|---|---|
| 1 | Technical errors in Autopilot failures are frequently symptoms of upstream process gaps, not platform bugs. Always trace the error code to a process step before assuming a configuration fault. |
| 2 | `0x80180014` in an Autopilot context is an unambiguous signal that the device repurposing process was not followed. It does not require deep technical investigation — it requires a process correction. |
| 3 | Secondary errors (`0x80070005`) co-occurring with `0x80180014` should be treated as downstream consequences, not independent faults, until the primary block is resolved. |
| 4 | MDM diagnostic exports contain sufficient scope data to identify the root cause of common Autopilot failures without requiring hands-on device access. Exporting diagnostics early reduces resolution time significantly. |
| 5 | SOPs that predate a platform change become a liability. The cost of an informal adoption (no SOP update, no training) is realised as incidents like this one. |

---

## 9. Sign-Off

| Role | Name | Date | Status |
|---|---|---|---|
| Author | DWP Endpoint Engineer | 2026-08-11 | Draft submitted |
| Technical Reviewer | *(pending)* | | |
| Service Owner | *(pending)* | | |

---

*This RCA was produced by DWP Endpoint Engineering following the incident on 2026-08-11. Preventive actions are subject to team lead approval before implementation.*
