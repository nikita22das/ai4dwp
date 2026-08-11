# DWP Guide: Create an Intune App Catalog Entry for a Windows App (Worked Example: FinBridge Connect v3.1)

## Purpose and Scope
This guide explains how a DWP engineer adds a Windows application to the Intune app catalog before phased rollout begins.

Worked example used throughout this guide:
- Application: FinBridge Connect v3.1
- Package type: .intunewin (Windows LOB/Win32 app package)
- Install command: FinBridgeConnect_Setup.exe /silent
- Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
- Detection method: Registry key
- Detection value: HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1

Operational context for this release:
- Target fleet: 10,000 Windows 11 endpoints
- Deadline: 3 weeks from 2026-08-11
- Priority: Finance team needs first wave by end of week 1 (500 users)
- Constraint: ~5% of devices are older hardware (4 GB RAM) and may struggle with v3.1
- Rollback option: FinBridge Connect v3.0 remains available in Intune app catalog

---

## 1) Open Intune and navigate to app creation

1. Sign in to the Microsoft Intune admin center.
2. Navigate to Apps > All apps > Add.
3. UI varies by tenant version:
   - Label names, panel layout, and tab order can differ.
   - Verify each label in your live tenant before clicking Next.
4. In Select app type, choose the correct type based on what you are publishing:
   - Windows LOB/Win32 app (.intunewin package): choose the Win32 app option used for .intunewin uploads.
   - Microsoft Store app: choose the Microsoft Store app type.
   - Web link shortcut: choose the Web link app type.
5. For this worked example, select the Win32 app option for FinBridge Connect v3.1.

Note:
- In many tenants, .intunewin uploads are under the Win32 app path, while LOB wording may appear differently in older/newer UI. Always validate against your tenant screens.

---

## 2) Enter required fields for a Windows LOB/Win32 app

### 2.1 App information

1. In App information, provide:
   - Name: FinBridge Connect
   - Description: Finance application client for secure bridge connectivity.
   - Publisher: FinBridge
   - Version: 3.1
2. Optional but recommended:
   - Category: Finance or Line-of-Business
   - Logo/icon: upload official application icon for easier catalog recognition
3. UI varies by tenant version:
   - Some tenants show these fields in one page; others split metadata across tabs.
   - Confirm field meaning from hints/tooltips if labels differ.

### 2.2 Program

1. In Program, configure command lines:
   - Install command: FinBridgeConnect_Setup.exe /silent
   - Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent
2. Set Install behavior/context:
   - Choose System context for device-wide installs requiring elevated rights.
   - Choose User context only if the app must install per-user and does not require machine-level permissions.
3. For FinBridge Connect v3.1, use System context unless vendor documentation explicitly requires user context.
4. UI varies by tenant version:
   - This section may be called Program, Installation, or Commands.
   - Verify your tenant wording before saving.

### 2.3 Requirements

1. In Requirements, set supported platform details:
   - Operating system architecture: choose x64 for standard Win11 enterprise fleet.
   - Minimum operating system: Windows 11 minimum build per your corporate standard.
2. For low-RAM devices (~4 GB), plan carefully:
   - Keep requirement gates focused on hard compatibility criteria (OS/build/architecture).
   - Handle performance risk through pilot assignments and monitoring, not by over-broadly blocking if the app is technically compatible.
3. UI varies by tenant version:
   - Architecture and OS build selectors may be shown as checkboxes, dropdowns, or profile constraints.
   - Verify your choices map to Windows 11 target devices.

### 2.4 Detection rules

1. Detection rules tell Intune how to decide if install succeeded.
2. Common detection methods:
   - Registry key/value
   - MSI product code
   - File/folder path or file version
3. For FinBridge Connect v3.1, configure registry detection:
   - Hive/path: HKLM\SOFTWARE\FinBridge\Connect
   - Value name: Version
   - Detection operator: equals
   - Expected value: 3.1
4. Confirm the detection value type (string/version) matches how the installer writes the registry.
5. UI varies by tenant version:
   - Detection wizard sequence and wording can differ.
   - Validate each field against your tenant help text.

### 2.5 Return codes

1. Return codes classify installer exit results.
2. Ensure at least these categories exist and are mapped correctly:
   - Success (for example, 0)
   - Soft reboot required (commonly 3010)
   - Hard reboot initiated (if used)
   - Retry (for transient conditions, if your packaging standard uses this)
   - Failure (non-success error codes)
3. Confirm vendor/package-specific exit codes for FinBridge installer and map them accurately.
4. UI varies by tenant version:
   - Some tenants expose a default return-code table; others require explicit entries.
   - Verify the final mapping before creation.

---

## 3) Configure assignments (do not deploy to all 10,000 first)

1. Understand assignment types:
   - Required: Intune pushes install automatically to targeted users/devices.
   - Available: App is offered in Company Portal; user installs on demand.
   - Uninstall: Intune removes app from targeted users/devices.
2. Start with a pilot-first strategy:
   - Do not target the full 10,000-device fleet initially.
   - First wave should be a controlled pilot with Finance priority users.
3. Recommended phased approach for this release:
   - Phase 0: IT validation group (small internal test set)
   - Phase 1 (end of week 1 target): Finance pilot group of 500 users
   - Phase 2: Broader staged expansion after success metrics are met
4. Include higher-risk hardware in pilot composition:
   - Deliberately include a representative subset of 4 GB RAM devices.
5. Keep rollback ready:
   - Maintain FinBridge Connect v3.0 assignment plan in parallel.
   - Predefine trigger conditions for rollback (for example, sustained failure rate or critical performance degradation).
6. UI varies by tenant version:
   - Assignment panes may use labels like Included groups/Excluded groups/Assignments.
   - Verify group targeting in your live tenant before saving.

---

## 4) Verify catalog entry and installation behavior

### 4.1 Verify app appears correctly in catalog

1. Open Apps > All apps and search for FinBridge Connect.
2. Confirm key metadata:
   - Name and publisher
   - Version 3.1
   - App type (Win32)
   - Assignment presence (pilot groups only at this stage)
3. Open Properties and re-check:
   - Install/uninstall commands
   - Requirement rules
   - Detection rule path/value
   - Return code mappings
4. UI varies by tenant version:
   - Properties may appear as tabs or expandable sections.
   - Validate values section by section.

### 4.2 Verify install status on an assigned test device

1. Use a device in the pilot assignment group.
2. Force policy sync from Intune portal and/or device side.
3. On the endpoint, trigger Company Portal sync if needed.
4. In Intune, open the app and review device install status.
5. Confirm endpoint evidence:
   - Application installed successfully
   - Registry key exists: HKLM\SOFTWARE\FinBridge\Connect\Version = 3.1
   - App launches normally and core workflow works

### 4.3 Interpret common status values

1. Installed:
   - Intune detection rule matched expected installed state.
2. Failed:
   - Install or detection failed.
   - Check installer logs, command syntax, execution context, and return codes.
3. Not applicable:
   - Device did not meet requirements or assignment scope.
   - Common causes: architecture mismatch, OS requirement mismatch, or exclusion targeting.

---

## 5) Completion checklist before phased rollout approval

1. App created in Intune as Win32 app with .intunewin package.
2. App information complete and accurate for FinBridge Connect v3.1.
3. Program commands validated:
   - Install: FinBridgeConnect_Setup.exe /silent
   - Uninstall: FinBridgeConnect_Setup.exe /uninstall /silent
4. Install behavior confirmed (System context unless explicitly documented otherwise).
5. Requirements aligned to Windows 11 fleet.
6. Detection rule validated:
   - HKLM\SOFTWARE\FinBridge\Connect\Version equals 3.1
7. Return codes reviewed and mapped.
8. Pilot assignments configured (not full fleet).
9. Finance week-1 pilot group (500 users) confirmed.
10. Monitoring and rollback readiness confirmed (v3.0 available).

If all items are complete, the app catalog entry is ready for phased deployment execution.
