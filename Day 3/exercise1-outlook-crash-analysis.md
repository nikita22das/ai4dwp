# Exercise 1 - Outlook Crash Analysis

## Incident Summary

- Endpoint: Windows 11 (build family indicated by `10.0.22621.x` in `KERNELBASE.dll`)
- Application affected: `OUTLOOK.EXE` (Office 16, version `16.0.17126.20132`)
- Symptom: Repeated Outlook crashes within minutes of launch
- Primary crash signature observed:
  - `Application Error` Event ID `1000`
  - Faulting module: `KERNELBASE.dll`
  - Exception code: `0xc0000005`

## 1) Distinct Event IDs, Exception Codes, Faulting Modules, and Error Conditions

### Distinct Event IDs observed

1. `1000` (`Application Error`)
2. `1001` (`Windows Error Reporting`)
3. `1026` (`.NET Runtime`)

### Distinct exception codes observed

1. `0xc0000005` (seen in Event ID `1000`)

### Distinct faulting modules observed

1. `KERNELBASE.dll` (`C:\Windows\System32\KERNELBASE.dll`)

### Distinct error conditions observed

1. Repeated `APPCRASH` for `OUTLOOK.EXE`
2. Unhandled exception path in managed runtime (`.NET Runtime` Event ID `1026`)
3. `System.AccessViolationException` (memory access violation in .NET context)
4. Multiple crashes in a short interval (approximately 3-4 minutes)

## 2) What Each Event ID Records

### Event ID 1000 (Source: Application Error)

Records that a process crashed and captures low-level crash fields such as:
- Faulting application name/version/path
- Faulting module name/version/path
- Exception code
- Fault offset
- Process ID and app start time

In this case it records `OUTLOOK.EXE` crashing in `KERNELBASE.dll` with `0xc0000005`.

### Event ID 1001 (Source: Windows Error Reporting)

Records Windows Error Reporting (WER) processing metadata for the crash, including:
- Fault bucket ID
- Event name (for example `APPCRASH`)
- CAB/report packaging state

In this case it confirms WER classified the incident as `APPCRASH` and assigned bucket `1847362910`.

### Event ID 1026 (Source: .NET Runtime)

Records a managed runtime termination due to an unhandled .NET exception. It typically indicates that a .NET component loaded in the process (application code, add-in, plugin, or interop layer) raised an exception that was not handled.

In this case it states process termination due to unhandled `System.AccessViolationException`.

## 3) Exception Code Interpretation

### `0xc0000005`

- Meaning: Access violation.
- Practical interpretation: The process attempted to read from or write to memory it was not allowed to access.
- Common causes: Defective add-ins, bad interop calls, corrupted process memory state, incompatible binaries, or bugs in application/runtime interactions.

Confidence: High for the definition of the code itself.

## 4) Chronological Reconstruction (Plain English)

1. At `09:13:44`, Outlook starts.
2. At `09:14:22`, Outlook crashes (`Event ID 1000`) with access violation `0xc0000005`, faulting in `KERNELBASE.dll`.
3. Outlook is launched again (implied by second crash; start time for second instance is not included in the excerpt).
4. At `09:17:45`, Outlook crashes again with the same signature (`Event ID 1000`, same module and exception code, same fault offset).
5. At `09:18:01`, Windows Error Reporting logs `Event ID 1001` (`APPCRASH`) and assigns a fault bucket.
6. At `09:18:05`, `.NET Runtime` logs `Event ID 1026`, showing the process terminated because of an unhandled `System.AccessViolationException`.

Interpretation of sequence: the repeated identical crash pattern plus .NET unhandled exception indicates deterministic failure during Outlook runtime, not an isolated random one-off.

## 5) Most Likely Root Cause and Supporting Evidence

## Most likely root cause

A failing or incompatible component loaded into Outlook (most likely a COM/VSTO add-in or another integration module) causing memory access violation, which surfaces as:
- native crash signature in `KERNELBASE.dll` (`1000`), and
- managed unhandled exception (`1026`, `System.AccessViolationException`).

## Supporting evidence from logs

1. Repeated crashes with same signature:
   - same app (`OUTLOOK.EXE`)
   - same module (`KERNELBASE.dll`)
   - same code (`0xc0000005`)
   - same fault offset (`0x000000000003a4b2`)
2. `.NET Runtime` unhandled `System.AccessViolationException` strongly suggests managed/native boundary issue in a loaded component, not just a generic UI freeze.
3. WER `APPCRASH` bucketing indicates a recognized repeated crash pattern.

## 6) Component Attribution (What This Is Most Likely Related To)

### Primary attribution: Office add-ins or another Outlook-loaded integration component

Reasoning:
1. `System.AccessViolationException` in `.NET Runtime` often appears when managed code/add-ins interact unsafely with native components.
2. Outlook commonly hosts third-party and line-of-business add-ins that can trigger deterministic crashes during startup/profile/mailbox initialization.
3. `KERNELBASE.dll` is frequently the faulting module in user-mode crashes even when it is not the original buggy code path.

### Secondary possibilities

1. Outlook client build issue (`OUTLOOK.EXE` version-specific defect)
2. Corrupted Outlook profile or OST causing code path that crashes
3. Corrupted Office binaries
4. Windows system file issue involving `KERNELBASE.dll` (less likely given repeated app-specific pattern)

### Relative likelihood by requested categories

1. Office Add-ins: High
2. Outlook core/client state: Medium
3. User profile corruption (Outlook profile/OST): Medium
4. .NET Runtime itself as root cause: Low to Medium (runtime reports crash, but may not be the original defect source)
5. Windows system files: Low (not excluded)

## 7) Ranked Remediation Plan (Most Likely Fix First)

## Step 1 - Isolate add-ins first (highest probability)

Action:
- Start Outlook in safe mode (`outlook.exe /safe`) and confirm crash behavior.
- Disable all COM add-ins, then re-enable one by one.

Specific checks:
1. In safe mode, Outlook remains stable for at least 15-30 minutes.
2. Crash returns only when a specific add-in is re-enabled.
3. Event signature (`1000` + `0xc0000005`) disappears when suspect add-in is disabled.

Success criteria:
- Stable Outlook with add-in disabled and no new matching `1000`/`1026` entries.

## Step 2 - Update or remove the suspect add-in

Action:
- Upgrade add-in to vendor-supported build for current Office version, or remove it.

Specific checks:
1. Add-in version is confirmed compatible with Office `16.0.17126.20132` (or current tenant channel after updates).
2. Vendor release notes include crash/access violation fixes if available.
3. Post-change monitoring shows no recurrence for at least one business day.

Success criteria:
- No recurring APPCRASH/WER bucket for same signature.

## Step 3 - Validate/repair Office installation

Action:
- Run Office Quick Repair, then Online Repair if needed.
- Apply latest Office updates for the assigned update channel.

Specific checks:
1. Office update channel and build are documented before/after.
2. `OUTLOOK.EXE` version changes (or file integrity repaired) after remediation.
3. Crash no longer reproduces in normal mode.

Success criteria:
- Stable Outlook and no new `1000` with same offset/module.

## Step 4 - Test new Outlook profile / OST rebuild path

Action:
- Create a clean Outlook mail profile.
- Regenerate OST (if Exchange cached mode scenario).

Specific checks:
1. New profile can send/receive and remains stable.
2. Old profile reproduces while new does not (or both stable after OST rebuild).
3. No matching error pattern in Application log after profile switch.

Success criteria:
- Stability restored with new profile path.

## Step 5 - System integrity checks for lower-probability OS corruption

Action:
- Run `sfc /scannow` and `DISM /Online /Cleanup-Image /RestoreHealth`.

Specific checks:
1. SFC/DISM output for corruption findings and repair status.
2. Reboot and retest Outlook.
3. Confirm whether `1000`/`1026` pattern persists.

Success criteria:
- Either corruption repaired and issue resolved, or ruled out as root cause.

## Step 6 - Deep crash triage if still unresolved

Action:
- Capture crash dump(s) for `OUTLOOK.EXE` and analyze stack/module involvement.
- Correlate with Microsoft known issues and vendor advisories.

Specific checks:
1. Dump points to repeatable offending module or add-in DLL.
2. Symbolized stack supports remediation decision.
3. Incident evidence package is complete for escalation (M365 support or add-in vendor).

Success criteria:
- Offending component identified with high confidence.

## 8) Assumptions

1. The provided event excerpts are representative and not missing contradictory events around the same timestamps.
2. The endpoint has Outlook add-ins installed or policy-assignable (common enterprise baseline).
3. No concurrent hardware memory fault is present (not indicated in provided logs).
4. Timestamp ordering is from same host and same timezone with synchronized clock.
5. No other security tool injected module is omitted from the excerpt.

## 9) Items to Verify Against Microsoft Documentation

1. Exact semantic definition and troubleshooting guidance for Event ID `1000` (`Application Error`) in current Windows 11 documentation.
2. WER fault bucket interpretation limits for Event ID `1001` and whether bucket `1847362910` maps to an existing known issue.
3. Official Microsoft guidance for handling `System.AccessViolationException` in Outlook-hosted managed add-ins.
4. Office channel/build known issues for Outlook `16.0.17126.20132` around crash signatures involving `KERNELBASE.dll`.
5. Recommended enterprise sequence for Outlook crash triage (safe mode, add-ins, repair, profile, SaRA/Microsoft Support escalation).

## 10) Final Assessment

The issue is most likely tied to a component loaded into Outlook (especially add-ins/integrations) rather than `KERNELBASE.dll` itself. The repeated identical `0xc0000005` crash signature plus `.NET Runtime` unhandled `System.AccessViolationException` strongly supports a deterministic code-path failure during Outlook runtime. Start with add-in isolation and compatibility validation first, then Office/profile repair paths, and keep OS file repair as a lower-probability branch.

## 11) Business Impact

1. Email workflow disruption for the affected user(s), including delayed response to internal and external communications.
2. Potential interruption to calendar-dependent activities (meeting acceptance, scheduling changes, reminders) during crash periods.
3. Increased Service Desk load due to repeat incident contacts and re-opened tickets if the crash recurs after temporary workarounds.
4. Risk of downstream operational delay in teams where Outlook is a primary workflow tool (approvals, escalations, customer coordination).

## 12) User Impact

1. Outlook launches and then crashes within minutes, preventing stable mailbox usage.
2. User may be unable to send/receive mail reliably, access calendar items, or manage tasks/contacts.
3. Repeated restart attempts can create productivity loss and user confidence impact.
4. If only one endpoint/user is impacted, scope is localized; if multiple users share same build/add-in baseline, broader user impact is possible.

## 13) Severity Assessment

Proposed severity based on available evidence:

1. Current observed severity: `SEV3` (single-user or limited-scope productivity degradation, no confirmed tenant-wide outage in provided logs).
2. Raise to `SEV2` if either condition is confirmed:
  - Multiple users/endpoints show identical crash signature (`1000` + `0xc0000005` + same bucket/same module pattern).
  - A business-critical role or time-sensitive operation cannot continue without Outlook.
3. Raise to `SEV1` only if widespread organizational communication capability is materially unavailable and no workaround exists.

Rationale:
- Logs show repeated hard failure, but only from one endpoint dataset and without explicit estate-wide impact evidence.

## 14) Outage Duration Estimation (From Available Logs)

Known timeline points:

1. Outlook start: `2024-03-15 09:13:44`
2. First recorded crash: `2024-03-15 09:14:22`
3. Second recorded crash: `2024-03-15 09:17:45`
4. WER/.NET follow-on logging: `2024-03-15 09:18:01` to `09:18:05`

Estimated disruption window from this excerpt:

1. Minimum confirmed instability window: approximately `3 minutes 43 seconds` (`09:14:22` to `09:18:05`) with repeated failure evidence.
2. Practical user-impact window is likely longer, because:
  - The second crash implies relaunch/retry activity between crashes.
  - No recovery-success event is present in provided logs.

Operational estimate to use in ticket (until verified):

1. Confirmed: at least 4 minutes of repeated crash behavior.
2. Working estimate: 10-30 minutes effective user productivity loss per affected incident cycle, pending user interview and additional telemetry.

## 15) Recommended Service Desk Actions

1. Confirm scope immediately:
  - Ask whether issue is single user, single device, or multiple users/devices.
  - Check for similar tickets in same time window and Office build.
2. Capture structured evidence in first response:
  - Exact crash time(s), screenshot/error prompt text, Outlook launch method, safe mode behavior.
  - Installed add-in list (if visible) and recent software/patch changes.
3. Perform approved first-line isolation:
  - Test `outlook.exe /safe`.
  - If stable, disable COM add-ins and retest in normal mode.
4. Apply standard user-safe mitigations:
  - Create temporary new Outlook profile if policy allows.
  - Guide user through quick Office repair if within SD remit.
5. Escalate to DWP Engineering with complete handoff package:
  - Event IDs `1000/1001/1026`, exception `0xc0000005`, module `KERNELBASE.dll`, Office version, reproduction steps, and outcome of safe-mode/add-in test.
6. User communication actions:
  - Provide interim workaround (OWA/new Outlook web access) while desktop Outlook is unstable.
  - Set expectation on next update time and escalation status.

## 16) Recommended DWP Engineering Actions

1. Pattern and blast-radius analysis:
  - Query endpoint/log platform for matching signature across estate (same Outlook build, exception code, and bucket pattern).
2. Add-in governance checks:
  - Identify recently updated or newly deployed Outlook add-ins via policy/configuration management.
  - Compare impacted vs non-impacted cohorts.
3. Controlled validation ring:
  - Reproduce in test VM with same Office build and add-in set.
  - Validate add-in disable/rollback and document deterministic pass/fail.
4. Build/channel verification:
  - Confirm Office update channel alignment and check recent release known issues.
  - Consider controlled rollback or forward-update if Microsoft issue confirmed.
5. Advanced triage:
  - Collect crash dumps for symbolized stack analysis.
  - Correlate with EDR/injection hooks/security extensions that may interact with Outlook process memory.
6. Permanent fix and prevention:
  - Remove/upgrade offending add-in or adjust deployment targeting.
  - Publish a KEDB/KB entry with signature-based detection and resolution workflow.

## 17) Recommended Microsoft Office Troubleshooting Actions

1. Run Outlook in safe mode and compare stability.
2. Disable all COM add-ins and re-enable one at a time to isolate offender.
3. Run Office Quick Repair, then Online Repair if issue persists.
4. Verify Office update channel and move to a known-good or latest supported build per enterprise policy.
5. Create a new Outlook profile and retest; rebuild OST if applicable.
6. Run Microsoft Support and Recovery Assistant (SaRA) for Outlook diagnostics where permitted.
7. If unresolved, collect and analyze Outlook crash dumps and escalate to Microsoft with WER bucket, build details, and repro steps.

## 18) Additional Assumptions for New Sections

1. Severity model (`SEV1` to `SEV3`) reflects a common enterprise incident framework and should be mapped to your organization's exact matrix.
2. No confirmed broad outage evidence is present in the supplied logs; scope statements are therefore conditional.
3. Outage duration estimate is constrained by available timestamps and may understate full user impact.

## 19) Additional Items to Verify Against Microsoft Documentation

1. Current Microsoft guidance on Outlook crash triage precedence (safe mode/add-ins vs repair/profile order).
2. Microsoft-documented known issues around Office build `16.0.17126.20132` and access violations.
3. SaRA recommendation boundaries and data collection requirements for enterprise support escalation.
4. Official interpretation boundaries for fault buckets when determining root-cause confidence.
