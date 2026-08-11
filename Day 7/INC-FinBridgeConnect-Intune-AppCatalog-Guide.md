# Adding FinBridge Connect v3.1 to the Intune App Catalog

**Document type:** Step-by-step engineer guide  
**Application:** FinBridge Connect v3.1 (.intunewin package)  
**Author:** DWP Engineer  
**Date:** 2026-08-11  
**Audience:** DWP engineers with no prior Intune app-deployment experience

---

## Overview

Before any phased rollout of FinBridge Connect v3.1 can begin, the application must be added to the Microsoft Intune app catalog. This guide walks through every step from uploading the package to verifying it is ready for assignment.

> **Tenant version note:** Microsoft regularly updates the Intune admin centre UI. Label names and navigation paths in this document reflect the current portal at time of writing. Where labels are known to vary, this is flagged explicitly. Always verify each step against your own tenant before proceeding.

---

## 1. Where to Add an App in Intune

### 1.1 Navigation path

1. Open a browser and go to [https://intune.microsoft.com](https://intune.microsoft.com).
2. Sign in with an account that has the **Intune Administrator** or **Application Manager** role.
3. In the left-hand navigation pane, select **Apps**.
4. Select **All apps** (or **Windows** under the platform sub-menu — exact sub-menu label may vary; verify in your tenant).
5. Select **+ Add** (top-left of the app list).

> **Tenant variation flag:** The top-level navigation label may appear as **Apps** or **Client apps** depending on your tenant version. Verify the label in your live portal.

### 1.2 Choosing the correct app type

A dialogue (or fly-out panel) will prompt you to select an app type. Use the table below to select the correct type for your scenario:

| Scenario | App type to select |
|---|---|
| Windows LOB app packaged as a `.intunewin` file | **Line-of-business app** |
| App published in the Microsoft Store | **Microsoft Store app (new)** or **Microsoft Store app** (label varies by tenant) |
| Shortcut to a website | **Web link** |

**For FinBridge Connect v3.1:** Select **Line-of-business app**, then click **Select**.

> **Tenant variation flag:** This option may appear as **Line-of-business app** or **LOB app**. Verify in your tenant.

---

## 2. Required Fields When Creating a Windows LOB App

Work through each tab in the app creation wizard in order.

### 2.1 App information

| Field | Value for FinBridge Connect v3.1 | Notes |
|---|---|---|
| App package file | `FinBridgeConnect_v3.1.intunewin` | Upload the `.intunewin` file here |
| Name | `FinBridge Connect` | Displayed to users in Company Portal |
| Description | `FinBridge Connect is the finance integration platform used across DWP. Version 3.1.` | Shown in Company Portal — keep user-facing |
| Publisher | `FinBridge Ltd` | Must match the vendor name used in other catalog entries |
| App version | `3.1` | Used for tracking; does not drive detection (detection rule does) |
| Category | `Business` (or appropriate category) | Optional but improves discoverability |
| Show this as a featured app | Set as appropriate | Optional |
| Information URL | Leave blank unless vendor URL is known | Optional |
| Privacy URL | Leave blank unless vendor URL is known | Optional |
| Logo | Upload vendor logo if available | Optional |

Click **Next** when complete.

> **Tenant variation flag:** The **App version** field may be pre-populated from the `.intunewin` package metadata. Verify the value is correct before continuing.

---

### 2.2 Program

| Field | Value for FinBridge Connect v3.1 | Notes |
|---|---|---|
| Install command | `FinBridgeConnect_Setup.exe /silent` | Exact command — do not modify spacing |
| Uninstall command | `FinBridgeConnect_Setup.exe /uninstall /silent` | Used when assignment type is set to Uninstall |
| Install behavior | **System** | Installs for all users on the device; use **User** only if the app is per-user |
| Device restart behavior | **Determine behavior based on return codes** | Adjust if the vendor specifies a required restart |
| Return codes | See Section 2.5 | Configured on this same tab |

**Install behavior guidance:**
- **System context** — The app is installed by the Intune Management Extension running as SYSTEM. Use this for most corporate LOB apps, including FinBridge Connect v3.1.
- **User context** — The app is installed under the logged-in user's account. Use only when the app explicitly requires a per-user installation.

Click **Next** when complete.

---

### 2.3 Requirements

| Field | Value for FinBridge Connect v3.1 |
|---|---|
| Operating system architecture | **64-bit** (select also **32-bit** if the app must support 32-bit devices) |
| Minimum operating system | **Windows 10 1909** or higher (verify against FinBridge v3.1 release notes) |
| Disk space required (MB) | Enter value from vendor documentation if known; otherwise leave blank |
| Physical memory required (MB) | `4096` — note that 5% of the fleet has only 4 GB RAM; this device group will require separate consideration before deployment |
| Minimum number of logical processors | Leave blank unless vendor specifies |
| Minimum CPU speed (MHz) | Leave blank unless vendor specifies |

> **4 GB RAM constraint:** Devices with only 4 GB RAM meet the minimum listed above but may experience degraded performance with FinBridge Connect v3.1. Flag these devices to the project team and consider a separate pilot group for lower-spec hardware before full rollout.

Click **Next** when complete.

> **Tenant variation flag:** Additional requirement fields (custom scripts, registry checks) may appear depending on tenant configuration. These are optional and not required for this deployment.

---

### 2.4 Detection rules

Detection rules tell Intune how to confirm the app has installed successfully. Select **Manually configure detection rules**, then click **+ Add** and configure as follows:

| Field | Value |
|---|---|
| Rule type | **Registry** |
| Key path | `HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect` |
| Value name | `Version` |
| Detection method | **String comparison** |
| Operator | **Equals** |
| Value | `3.1` |
| Associated with a 32-bit app on 64-bit clients | **No** (unless the app is a 32-bit installer) |

> **What this does:** After each install attempt, the Intune Management Extension reads `HKLM\SOFTWARE\FinBridge\Connect\Version`. If it equals `3.1`, the app is marked **Installed**. If the key is absent or the value does not match, the app is marked **Not installed** and Intune may retry.

**Alternative detection methods (for reference):**

| Method | When to use |
|---|---|
| MSI product code | When the app is an MSI and you have the GUID |
| File path | When the app writes a specific file with a known version |
| Registry | When the app writes a registry key (used here for FinBridge Connect v3.1) |

Click **OK**, then **Next**.

---

### 2.5 Return codes

Return codes tell Intune how to interpret the exit code from the install process.

The following defaults are pre-populated and should be retained unless vendor documentation specifies otherwise:

| Return code | Type | Meaning |
|---|---|---|
| `0` | Success | Installation completed successfully |
| `1707` | Success | Installation completed successfully |
| `3010` | Soft reboot | Installation succeeded; a restart is required |
| `1641` | Hard reboot | Installation succeeded; a restart is being initiated |
| `1618` | Retry | Another install is in progress; Intune will retry |

If the FinBridge Connect installer uses non-standard exit codes, add them here using **+ Add**. Consult the vendor release notes for FinBridge Connect v3.1 to confirm.

Click **Next**.

---

### 2.6 Scope tags (optional)

Assign scope tags if your organisation uses role-based access control (RBAC) with Intune scope tags (e.g., a `Finance` tag for Finance-team apps). If unsure, leave as default and consult your Intune administrator.

Click **Next**.

---

### 2.7 Assignments

**Do not assign to the full fleet here.** See Section 3 for assignment guidance.

Leave assignments blank at this stage and click **Next**, then **Create** to save the app to the catalog.

The portal will upload the `.intunewin` package and process it. This may take several minutes depending on file size.

---

## 3. Assignment Basics

### 3.1 Assignment types

| Assignment type | What it does |
|---|---|
| **Required** | Intune installs the app on the device automatically, without user interaction. The app is enforced. |
| **Available (enrolled devices)** | The app appears in Company Portal. Users can choose to install it themselves. It is not enforced. |
| **Uninstall** | Intune removes the app from the device. |

**For FinBridge Connect v3.1 rollout:** Use **Required** for all assignment groups, since this is a corporate LOB app that must be present on target devices.

### 3.2 Why assign to a pilot group first

Assigning directly to all 10,000 devices creates significant risk:
- A packaging error or incorrect detection rule would trigger 10,000 failed installs simultaneously.
- Rollback requires pushing v3.0 as a **Required** assignment to 10,000 devices, creating a large remediation effort.
- A pilot group of 20–50 devices surfaces installation, compatibility, and detection issues at low cost before broader deployment.

**Recommended assignment sequence for FinBridge Connect v3.1:**

| Phase | Group | Device count | Timeline |
|---|---|---|---|
| Phase 0 — Pilot | IT/DWP engineer test devices | 10–20 devices | Day 1–2 |
| Phase 1 — Finance priority | Finance team devices | 500 devices | End of week 1 (deadline) |
| Phase 2 — Remaining fleet | All remaining devices (excluding 4 GB RAM group) | ~9,000 devices | Weeks 2–3 |
| Phase 3 — Low-spec review | 4 GB RAM devices | ~500 devices | After Phase 2 validation |

### 3.3 How to add an assignment after catalog creation

1. Navigate to **Apps** > **All apps** > select **FinBridge Connect**.
2. Select **Properties** > scroll to **Assignments** > click **Edit**.
3. Under **Required**, click **+ Add group**.
4. Search for and select the pilot Azure AD / Entra ID group.
5. Click **Select**, then **Review + save**, then **Save**.

> **Tenant variation flag:** The group search panel may appear as a fly-out or a separate dialogue depending on tenant version. Verify in your live portal.

---

## 4. Verification Steps

### 4.1 Confirm the app appears in the catalog

1. Navigate to **Apps** > **All apps**.
2. Search for `FinBridge Connect` using the search bar.
3. Verify the following:
   - **Name:** FinBridge Connect
   - **Platform:** Windows
   - **Type:** Line-of-business app
   - **Version:** 3.1

If the app does not appear within 5 minutes of creation, refresh the page. If it still does not appear, check for upload errors under the app's **Overview** tab.

### 4.2 Check install status on an assigned test device

1. Navigate to **Apps** > **All apps** > select **FinBridge Connect**.
2. Select the **Device install status** tab.
3. Locate the test device by name.
4. Review the **Install status** column.

Allow up to 30 minutes after policy sync for the status to update. To force a faster sync on the test device, run the following on the device:

```powershell
# Trigger an Intune policy sync
Start-Process "ms-settings:workplace" 
# Or from an elevated prompt:
Get-ScheduledTask -TaskName "PushLaunch" | Start-ScheduledTask
```

Alternatively, on the device go to **Settings** > **Accounts** > **Access work or school** > select the account > **Info** > **Sync**.

### 4.3 Install status meanings

| Status | Meaning | Action |
|---|---|---|
| **Installed** | The detection rule returned a match. The app is confirmed present. | No action required. |
| **Failed** | The installer returned an unrecognised exit code, or the detection rule did not match after install. | Review the Intune Management Extension log: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`. Check install and uninstall commands, detection rule, and return codes. |
| **Not applicable** | The device does not meet the requirements configured in Section 2.3, or the device is excluded from the assignment group. | Verify device membership in the assignment group and check OS/architecture requirements. |
| **Pending** | The device has received the policy but has not yet attempted install (common in first 30 minutes). | Wait and re-check. Force a sync if needed (see Section 4.2). |
| **Not installed** | The device is in scope but the detection rule has not returned a match (install not yet attempted or silently failed). | Wait for next Intune check-in cycle or force a sync. If persistent, check the IME log. |

### 4.4 Confirming detection rule correctness on a test device

After a successful install, validate the registry key manually on the test device:

```powershell
# Verify detection registry key
Get-ItemProperty -Path "HKLM:\SOFTWARE\FinBridge\Connect" -Name "Version"
```

Expected output:

```
Version : 3.1
PSPath  : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\FinBridge\Connect
...
```

If the key is absent or the value differs from `3.1`, the detection rule will not match and Intune will report **Not installed** regardless of whether the application binary is present.

---

## 5. Rollback Procedure

If FinBridge Connect v3.1 must be removed from a device or group:

1. Navigate to **Apps** > **All apps** > select **FinBridge Connect** (v3.1).
2. Edit the assignment for the affected group and change the assignment type to **Uninstall**.
3. Separately, locate **FinBridge Connect v3.0** in the Intune app catalog (confirmed still available).
4. Assign v3.0 as **Required** to the same group.
5. Monitor install status for v3.0 using the steps in Section 4.2.

> The uninstall command `FinBridgeConnect_Setup.exe /uninstall /silent` configured in Section 2.2 will be used by Intune to remove v3.1.

---

## Summary Checklist

- [ ] App package (`.intunewin`) uploaded and catalog entry created
- [ ] App information fields completed (name, description, publisher, version)
- [ ] Install and uninstall commands verified
- [ ] Install behavior set to **System**
- [ ] Requirements configured (OS, architecture, RAM minimum)
- [ ] Detection rule configured — registry key `HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1`
- [ ] Return codes reviewed against vendor documentation
- [ ] App visible in **All apps** catalog
- [ ] Pilot group (10–20 test devices) assigned as **Required**
- [ ] Install status confirmed **Installed** on at least one pilot device
- [ ] Registry key verified manually on pilot device
- [ ] Finance team group assignment scheduled for end of week 1
- [ ] Low-spec (4 GB RAM) device group flagged for separate phase
