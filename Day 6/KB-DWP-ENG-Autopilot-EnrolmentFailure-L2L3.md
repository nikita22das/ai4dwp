# L2/L3 Knowledge Base Article — Autopilot Enrolment Failure: Stale Legacy MDM Enrolment

| Field | Detail |
|---|---|
| **Version** | 1.0 |
| **Date** | 07/08/2026 |
| **Status** | Draft |
| **Audience** | DWP L2/L3 Endpoint Engineers |
| **Article Reference** | KB-DWP-ENG-AUTOPILOT-001 |
| **Author** | Nikita, DWP Endpoint Engineering |
| **Source RCA** | RCA-2026-08-11-AUTOPILOT-001 |
| **Related KER** | KER-2026-08-001 |

---

## 1. Version Header

| Version | Date | Author | Change |
|---|---|---|---|
| 1.0 | 07/08/2026 | Nikita | Initial draft from verified RCA |

---

## 2. Background

Microsoft Autopilot is a cloud-driven Windows 11 deployment method that provisions a device from OOBE (Out of Box Experience) without manual imaging. When a device is powered on for the first time or after a reset, it contacts the Microsoft Autopilot service using its pre-registered hardware hash. Autopilot delivers the assigned deployment profile, joins the device to Azure AD, and triggers Intune to push configuration profiles and compliance policies — all without engineer intervention on the device.

**Prerequisite for Autopilot enrolment:** The device must arrive at OOBE with no active MDM enrolment. The Microsoft Enrolment Service checks for an existing MDM registration before proceeding. If a registration is found, enrolment is blocked.

Devices that have previously been managed via legacy manual MDM enrolment carry an active enrolment record, an Intune device object, an AAD device object, DMCLIENT registry artefacts under `HKLM\SOFTWARE\Microsoft\Enrollments\<GUID>`, and MDM certificates in the device certificate store. None of these are removed automatically when a device is repurposed — they must be explicitly cleared before an Autopilot flow is initiated.

---

## 3. Scope

| Field | Detail |
|---|---|
| **Platform** | Windows 11 |
| **Management method** | Microsoft Autopilot (user-driven or pre-provisioning) |
| **Affected device state** | Devices previously enrolled via legacy manual MDM enrolment that have not been wiped or de-registered before Autopilot deployment |
| **Not in scope** | Autopilot failures caused by network issues, missing hardware hash registration, licensing gaps, Conditional Access blocks, or AAD join failures — each presents different error codes |

---

## 4. Symptoms

### User-Reported Symptoms

- Device is stuck on OOBE setup or welcome screen and does not progress.
- User receives a message that setup could not be completed.
- Device was previously assigned to another user and has never successfully completed setup for the current user.

### Engineer-Observed Symptoms

- Autopilot deployment report in Intune shows status: **Failed**.
- `EnrollmentState: Failed` in MDM diagnostic export.
- `ErrorCode: 0x80180014` in MDM diagnostic export or Intune device enrolment view.
- `ProfilesApplied: 0 of N` — no configuration profiles applied.
- `LastError: 0x80070005` against all profile-write attempts.
- Duplicate device record visible in Intune with an enrolment date predating the current Autopilot attempt.

---

## 5. Technical Indicators

| Indicator | Location | Expected (Healthy) | Observed (Fault) |
|---|---|---|---|
| Enrolment state | MDM diagnostic export / Intune → device → Device enrolment | `Enrolled` | `Failed` |
| Primary error code | MDM diagnostic export — `ErrorCode` field | Absent | `0x80180014` (MENROLL_E_DEVICE_ALREADY_ENROLLED) |
| Active MDM enrolment | MDM diagnostic export — `MDMEnrolled` field | `No` or current date | `Yes` — date predates current Autopilot attempt |
| Enrolment source | MDM diagnostic export — `EnrolmentSource` field | `Autopilot` | `Legacy manual MDM enrolment` |
| Profiles applied | MDM diagnostic export — `ProfilesApplied` field | `N of N` | `0 of N` |
| Secondary error | MDM diagnostic export — `LastError` field | Absent | `0x80070005` (Access Denied) |
| Stale Intune device record | Intune → Devices → All devices | Single record, current date | Duplicate record with legacy enrolment date |
| Stale AAD device object | Azure AD → Devices | Single object, current date | Duplicate object with legacy enrolment date |
| DMCLIENT registry key | `HKLM\SOFTWARE\Microsoft\Enrollments\` | Single GUID key, current enrolment | Stale GUID key from previous enrolment |
| MDM certificate | `certlm.msc → Personal → Certificates` | Certificate for current enrolment only | Certificate referencing old enrolment GUID |

---

## 6. Root Cause

The device held an active legacy manual MDM enrolment predating the current Autopilot deployment. When Autopilot initiated enrolment, the Microsoft Enrolment Service detected the existing MDM registration and returned `MENROLL_E_DEVICE_ALREADY_ENROLLED` (`0x80180014`), halting the flow at the enrolment phase.

The `0x80070005` (Access Denied) errors on profile-write attempts are a **downstream consequence**: the stale enrolment's registry artefacts and MDM certificates block the new enrolment context from writing to the CSP policy store. They are not an independent fault and will resolve when the stale enrolment is removed.

**Process root cause:** The device repurposing procedure did not include a mandatory MDM de-registration and device wipe step. The device was added to the Autopilot deployment group without clearing the prior enrolment state.

---

## 7. Detection

### Step 1 — Collect MDM Diagnostic Export

**On the device (if accessible):**
```
MdmDiagnosticsTool.exe -out C:\MDMLogs
```
Review `MDMDiagReport.xml` for `EnrollmentState`, `ErrorCode`, `MDMEnrolled`, `EnrolmentSource`, `ProfilesApplied`, and `LastError` fields.

**Via Intune (remote):**
Intune admin center → Devices → All devices → [device] → **Collect diagnostics**

---

### Step 2 — Check Event Viewer on the Device

| Log Name | Path | Event IDs to Look For |
|---|---|---|
| DeviceManagement-Enterprise-Diagnostics-Provider | `Event Viewer → Applications and Services Logs → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostics-Provider → Admin` | **72** — enrolment failure; **404**, **406** — policy write access denied |
| Microsoft-Windows-AAD | `Event Viewer → Applications and Services Logs → Microsoft → Windows → AAD → Operational` | Events indicating device registration conflict |

**Expected healthy baseline:** No events 72, 404, or 406. Enrolment events show success with a current timestamp.

---

### Step 3 — Confirm Stale Enrolment State

| Check | Location | Unhealthy Indicator |
|---|---|---|
| Live MDM account on device | `Settings → Accounts → Access work or school` | Entry present with legacy account name or old date |
| Stale Intune device record | Intune → Devices → All devices → filter by device name/serial | Duplicate record with enrolment date predating current attempt |
| Stale AAD device object | Azure AD → Devices → search by device name | Duplicate object; `Join type: Workplace joined` or stale registered date |
| DMCLIENT registry keys | `HKLM\SOFTWARE\Microsoft\Enrollments\` | Multiple GUID subkeys, or a single key with a stale enrolment timestamp |
| MDM certificate | `certlm.msc → Personal → Certificates` | Certificate issued to old enrolment GUID |

---

### Step 4 — Confirm This Known Error Pattern

All three conditions must be present to confirm this known error:

1. `ErrorCode: 0x80180014`
2. `MDMEnrolled: Yes` with date predating the current Autopilot attempt
3. `ProfilesApplied: 0 of N` with `LastError: 0x80070005`

If only `0x80070005` is present without `0x80180014`, investigate independently — this indicates a different root cause.

---

## 8. Resolution

> Complete all steps in order. Do not attempt re-enrolment before Step 6.

**Step 1 — Disconnect the stale MDM enrolment on the device**

Location: `Settings → Accounts → Access work or school → [legacy account entry] → Disconnect`

*Expected result:* The legacy account entry is removed from the Access work or school list.

---

**Step 2 — Delete the orphaned Intune device record**

Location: `Intune admin center → Devices → All devices → [stale device record] → Delete`

*Expected result:* The stale device record is absent from Intune → Devices → All devices. Only the current Autopilot-registered device record remains.

---

**Step 3 — Delete the duplicate AAD device object**

Location: `Azure Active Directory → Devices → [device with legacy enrolment date] → Delete`

*Expected result:* Only one AAD device object exists for this device. The object with the legacy registration date is absent.

---

**Step 4 — Confirm Autopilot hardware hash registration**

Location: `Intune → Devices → Enrol devices → Windows enrolment → Devices (Autopilot)`

*Expected result:* Device hardware hash is listed with the correct Autopilot deployment profile assigned. If hash is absent, re-capture using `Get-WindowsAutoPilotInfo` and upload before proceeding.

---

**Step 5 — Remove residual DMCLIENT artefacts (perform if Step 1 did not fully clear state)**

Run as SYSTEM or local administrator on the device:

```powershell
# Identify stale enrolment GUID
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" |
    Where-Object { (Get-ItemProperty $_.PSPath).EnrollmentType -ne $null } |
    Select-Object Name

# Remove stale key — replace <STALE-GUID> with value found above
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Enrollments\<STALE-GUID>" -Recurse -Force

# Restart MDM services
Restart-Service -Name dmwappushsvc -Force
Restart-Service -Name DeviceManagementService -Force
```

Remove stale MDM certificate: `certlm.msc → Personal → Certificates` → delete certificate referencing the old enrolment GUID.

*Expected result:* No stale GUID subkeys under `HKLM\SOFTWARE\Microsoft\Enrollments`. No legacy MDM certificate in the Personal store.

---

**Step 6 — Perform a full Autopilot Reset or device wipe**

| Method | When to use | Steps |
|---|---|---|
| **Autopilot Reset (preferred)** | Device is Intune-reachable | Intune → device → **Autopilot Reset** |
| **Local wipe** | Device not reachable via Intune | `Settings → System → Recovery → Reset this PC → Remove everything` |

*Expected result:* Device presents the OOBE welcome screen with no pre-populated account. The Autopilot deployment profile is applied automatically at OOBE start.

---

**Step 7 — Allow Autopilot enrolment to complete**

Allow the Autopilot Enrolment Status Page (ESP) to run to completion. Do not interrupt. Monitor progress via:

`Intune → Devices → Monitor → Autopilot deployments → [device]`

*Expected result:* ESP shows all phases (Device preparation, Device setup, Account setup) completed successfully. Enrolment status transitions to **Enrolled**.

---

## 9. Verification

Confirm all of the following before closing the incident:

| Check | Location | Success Criteria |
|---|---|---|
| Enrolment state | Intune → device → Device enrolment | **Enrolled** |
| Configuration profiles | Intune → device → Device configuration | All expected profiles: **Succeeded** |
| Compliance state | Intune → device → Device compliance | **Compliant** or **In grace period** |
| No duplicate Intune record | Intune → Devices → All devices | Single record for this serial/hardware hash |
| No duplicate AAD object | Azure AD → Devices | Single object, current registration date |
| No legacy MDM entry on device | `Settings → Accounts → Access work or school` | Current Intune account only — no legacy entry |
| No stale DMCLIENT key | `HKLM\SOFTWARE\Microsoft\Enrollments\` | Single GUID key with current enrolment timestamp |
| HAS sync — BitLocker / Secure Boot | Intune → device → Hardware tab → HAS report timestamp | Current timestamp; not absent or stale |
| Event log clear | DeviceManagement-Enterprise-Diagnostics-Provider → Admin | No Event ID 72, 404, or 406 post-enrolment |

> **Note:** HAS report sync can take up to 24 hours on newly enrolled devices. BitLocker and Secure Boot compliance settings may show *In grace period* during this window. This is expected under the DWP 7-day grace period policy — do not treat as a fault.

**Healthy baseline after successful enrolment:**
- `EnrollmentState: Enrolled`
- `ProfilesApplied: N of N`
- No `0x80180014` or `0x80070005` in diagnostic export or Event Viewer
- Compliance state: Compliant (or In grace period with HAS sync pending)

---

## 10. Rollback

> Use rollback only if the Autopilot Reset or wipe (Resolution Step 6) must be reversed — for example, if the wrong device was selected or the reset was initiated in error.

**Rollback is only possible before Step 6 is executed.** Once a full reset or Autopilot Reset has been performed, the device is wiped and rollback is not applicable. In that case, allow the Autopilot flow to complete and raise a separate incident if the device does not provision correctly.

**If Steps 1–5 were completed but Step 6 has not yet been initiated:**

| Rollback Action | Steps |
|---|---|
| Restore Intune device record | Re-enrol the device via the original legacy MDM method, or restore from a recent Intune device export if available. Note: restoring the old record re-introduces the stale enrolment and does not resolve the underlying issue. |
| Restore AAD device object | If deleted within the AAD soft-delete retention window (30 days): `Azure AD → Devices → Deleted devices → [device] → Restore` |
| Re-register Autopilot hash | If hash was removed in error: re-capture using `Get-WindowsAutoPilotInfo` and upload via Intune → Devices → Enrol devices → Windows enrolment → Devices → Import |

**Rollback Validation:**

| Check | Expected State After Rollback |
|---|---|
| Intune device record | Device visible in Intune → Devices → All devices with previous enrolment date |
| AAD device object | Device object visible in Azure AD → Devices with previous registration date |
| Device account | `Settings → Accounts → Access work or school` shows original MDM entry |

> **Important:** A successful rollback returns the device to the pre-resolution state — the original stale enrolment problem will still be present. Rollback is a recovery action only; the full resolution must be rescheduled.

---

## 11. Preventive Actions

| Ref | Action | Detail |
|---|---|---|
| PA-01 | Update device repurposing SOP | Mandate a pre-reassignment checklist before any device is added to an Autopilot group: (1) disconnect MDM on device, (2) delete Intune object, (3) delete AAD object, (4) confirm Autopilot hash, (5) perform Autopilot Reset or wipe. Task must not be marked complete without documented confirmation of all five steps. |
| PA-02 | Automated stale-enrolment detection | Create an Intune Device Filter or AAD dynamic group identifying devices in an Autopilot deployment group with an enrolment date older than 18 months. Generate a weekly report to the endpoint team for pre-emptive clean-up. |
| PA-03 | Mandate Autopilot Reset as standard repurposing method | For all Intune-reachable devices, use Intune → device → **Autopilot Reset** rather than manual wipes. Ensures DMCLIENT state, certificates, and registry artefacts are platform-cleared. Reserve manual wipes for unreachable devices only. |
| PA-04 | Staff briefing on Autopilot prerequisites | Deliver a documented briefing to all device repurposing staff covering clean-state requirements, updated SOP checklist, and correct use of Autopilot Reset. Record attendance. |
| PA-05 | Platform-change SOP review trigger | Any adoption of a new device management method must trigger a formal review of all related SOPs within 30 days. Assign a named SOP owner per document and include the review trigger in the change management template. |

---

## 12. Related Incidents

| Reference | Description |
|---|---|
| INC-Autopilot-EnrolmentFailure-0x80180014 | Source incident for this article |
| RCA-2026-08-11-AUTOPILOT-001 | Verified root cause analysis |
| KER-2026-08-001 | Known Error Record for this failure pattern |

---

## 13. References

| Resource | Location |
|---|---|
| Incident Analysis | Day 6/INC-Autopilot-EnrolmentFailure-0x80180014-Analysis.md |
| Root Cause Analysis | Day 6/INC-Autopilot-EnrolmentFailure-0x80180014-RCA.md |
| Known Error Record | Day 6/KER-Autopilot-EnrolmentFailure-0x80180014.md |
| DWP Compliance Policy | Day 6/DWP-Win11-Intune-Compliance-Policy.md |
| Microsoft — Autopilot Troubleshooting | https://learn.microsoft.com/en-us/autopilot/troubleshooting |
| Microsoft — Windows Enrolment Error Reference | https://learn.microsoft.com/en-us/intune/enrollment/troubleshoot-windows-enrollment-errors |
| Microsoft — MDM Diagnostic Tool | https://learn.microsoft.com/en-us/windows/client-management/mdm-diagnostics |
| Microsoft — Autopilot Reset | https://learn.microsoft.com/en-us/autopilot/windows-autopilot-reset |

---

*Article prepared by Nikita, DWP Endpoint Engineering — 07/08/2026. Review due 07/09/2026.*
