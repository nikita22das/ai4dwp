# Production Incident Report - Repeated Outlook Crash on Windows 11 Endpoint

## Executive Summary

On 2024-03-15, a Windows 11 endpoint experienced repeated Microsoft Outlook crashes shortly after launch. The crash signature was consistent across multiple events: Application Error Event ID 1000 with exception code 0xc0000005 and faulting module KERNELBASE.dll, followed by Windows Error Reporting Event ID 1001 (APPCRASH) and .NET Runtime Event ID 1026 (System.AccessViolationException). 

The most likely cause is an unstable or incompatible component loaded into Outlook, most likely an add-in or managed/native integration path, rather than KERNELBASE.dll being the origin of the defect. Immediate containment should prioritize add-in isolation, then Office repair and profile validation.

Current severity is assessed as SEV3 (localized productivity degradation) based on available evidence, with clear criteria to escalate if broader scope is confirmed.

## Timeline of Events

All timestamps below are from provided Application log entries.

1. 09:13:44 - Outlook process starts (from Event ID 1000 metadata: faulting app start time).
2. 09:14:22 - Event ID 1000 (Application Error): OUTLOOK.EXE crashes in KERNELBASE.dll with exception 0xc0000005.
3. 09:17:45 - Event ID 1000 (Application Error): second Outlook crash with identical signature (same module and exception code; same fault offset).
4. 09:18:01 - Event ID 1001 (Windows Error Reporting): APPCRASH event recorded with fault bucket 1847362910.
5. 09:18:05 - Event ID 1026 (.NET Runtime): unhandled System.AccessViolationException terminates OUTLOOK.EXE.

Interpretation: repeatable crash behavior occurs within minutes and is not a one-time random failure.

## Event ID Analysis

### Event ID 1000 - Application Error

What it records:
- Process crash details including application, module, exception code, and offset.

What it shows in this incident:
- OUTLOOK.EXE version 16.0.17126.20132 crashed.
- Faulting module: KERNELBASE.dll version 10.0.22621.3155.
- Exception code: 0xc0000005.
- Fault offset: 0x000000000003a4b2.

### Event ID 1001 - Windows Error Reporting

What it records:
- WER crash classification and bucket metadata used for grouping similar crashes.

What it shows in this incident:
- Event Name APPCRASH.
- Fault bucket 1847362910.
- Confirms WER classified and processed the crash pattern.

### Event ID 1026 - .NET Runtime

What it records:
- Managed runtime termination due to an unhandled exception.

What it shows in this incident:
- OUTLOOK.EXE terminated due to unhandled System.AccessViolationException.
- Indicates managed code involvement (application component, add-in, plugin, or interop layer).

## Exception Code Analysis

### Exception Code 0xc0000005

Meaning:
- Access violation.

Technical interpretation:
- The process attempted to read/write memory outside allowed boundaries.

Confidence level:
- High for the meaning of the code itself.

Caution:
- The faulting module (KERNELBASE.dll) may be where failure surfaces, not necessarily where the original defect is introduced.

## Technical Findings

1. Crash pattern is deterministic:
- Two Event ID 1000 crashes with same exception code and same fault offset.

2. Managed exception evidence is present:
- Event ID 1026 reports unhandled System.AccessViolationException in OUTLOOK.EXE.

3. WER corroborates repeated APPCRASH behavior:
- Event ID 1001 with fault bucket indicates crash signature grouping.

4. Reproduction frequency is high:
- Multiple crashes occur within approximately four minutes of observed event window.

5. Scope from supplied evidence is endpoint-local:
- No direct multi-host or tenant-wide indicators in the provided logs.

## Most Likely Root Cause

Most likely root cause:
- A faulty, incompatible, or unstable Outlook-loaded component (most likely COM/VSTO add-in or integration module) causing memory access violation during Outlook runtime.

Why this is most likely:
1. Repeated identical signature points to a stable failing code path.
2. System.AccessViolationException strongly aligns with managed/native interop failures common in add-in ecosystems.
3. KERNELBASE.dll is commonly the observed faulting module for downstream process exceptions, even when another loaded component is causal.

## Alternative Root Cause Theories

1. Outlook client build-specific defect in version 16.0.17126.20132.
2. Corrupted Outlook user profile or OST causing deterministic failure during mailbox initialization.
3. Corrupted Office binaries or partial update state.
4. Security/EDR injection or integration conflict within Outlook process space.
5. Windows system file corruption affecting KERNELBASE.dll behavior (lower probability without broader OS symptoms).

## Evidence Supporting Root Cause

1. Identical repeated Event ID 1000 signature:
- Same application, module, exception code, and fault offset.

2. Event ID 1026 with System.AccessViolationException:
- Direct evidence of unhandled managed exception path in the same process.

3. Event ID 1001 APPCRASH/WER bucketing:
- Confirms consistent crash classification and repeatability profile.

4. Tight event sequencing:
- Crash, re-crash, WER, and .NET runtime failure logging occur within minutes.

## Impact Assessment

### Business Impact

1. Reduced responsiveness in email-dependent operations.
2. Possible delays to approvals, customer communications, and meeting workflows.
3. Increased operational load on Service Desk and engineering teams.

### User Impact

1. User cannot maintain stable Outlook session.
2. Repeated relaunch attempts reduce productivity and confidence.
3. Reliance on workaround channels (for example OWA) may be required.

### Severity Assessment

1. Current level: SEV3 based on available evidence (localized endpoint/user impact).
2. Upgrade to SEV2 if multiple users/endpoints show same signature.
3. Upgrade to SEV1 only if communication capability is broadly impaired and no workaround is available.

### Outage Duration Estimation

From available logs:
1. Confirmed unstable period from first crash at 09:14:22 to runtime follow-on at 09:18:05 is about 3 minutes 43 seconds.
2. Practical user-impact duration is likely longer due to relaunch attempts and no logged success event.
3. Working estimate for operational reporting: at least 4 minutes confirmed, likely 10-30 minutes effective productivity disruption per incident cycle.

## Ranked Remediation Plan

1. Isolate add-ins immediately.
- Action: Launch Outlook in safe mode, disable all COM add-ins, re-enable one at a time.
- Checks: Safe mode stability; crash returns only with specific add-in; no new matching 1000/1026 events.

2. Update or remove offending add-in.
- Action: Move to vendor-supported version or remove component.
- Checks: Version compatibility with Office build; no recurrence across monitored period.

3. Repair Office installation and align update channel.
- Action: Quick Repair, then Online Repair if needed; apply approved Office updates.
- Checks: Build/channel recorded; post-repair stability in normal mode.

4. Rebuild Outlook profile path.
- Action: Create new mail profile; rebuild OST where applicable.
- Checks: New profile stable; crash does not reproduce.

5. Validate system integrity.
- Action: Run SFC and DISM; reboot and retest.
- Checks: Repair results documented; no recurring signature.

6. Perform advanced crash triage if unresolved.
- Action: Capture crash dumps and analyze stack/module chain; escalate with evidence pack.
- Checks: Offending module identified with high confidence.

## Preventive Actions

1. Establish add-in certification and compatibility gates before broad deployment.
2. Use phased/ring-based rollout for Outlook and add-in updates.
3. Implement monitoring query for early detection of repeating Event ID 1000 + 0xc0000005 Outlook signatures.
4. Maintain known-good Office/add-in baseline matrix by update channel.
5. Document a standard Outlook crash playbook for Service Desk first-line triage and evidence capture.

## Lessons Learned

1. Repeatable crash signatures with identical offset and exception codes should trigger rapid pattern-based triage, not isolated user troubleshooting.
2. KERNELBASE.dll appearing as the faulting module does not alone prove Windows core file fault.
3. Capturing Event ID 1000, 1001, and 1026 together improves root-cause confidence and speeds escalation quality.
4. Safe mode and add-in isolation are high-value early tests that can sharply reduce time to mitigation.

## References That Should Be Verified Against Microsoft Documentation

1. Official Microsoft/Windows documentation for Application Error Event ID 1000 field interpretation.
2. Official Windows Error Reporting guidance for Event ID 1001 fault bucket behavior and supportability interpretation.
3. Microsoft .NET guidance for System.AccessViolationException and unhandled exception handling in Office-hosted managed components.
4. Microsoft 365 Apps release notes and known issues for Outlook build 16.0.17126.20132.
5. Microsoft-recommended enterprise Outlook crash workflow ordering (safe mode, add-ins, repair, profile, SaRA, support escalation).
6. Microsoft Support and Recovery Assistant (SaRA) usage boundaries and required diagnostics for enterprise cases.

## Assumptions

1. All provided log entries are from the same endpoint and same incident window.
2. No omitted logs contradict the stated sequence.
3. No hardware-level memory fault evidence was provided.
4. Organization severity model supports SEV3/SEV2/SEV1 mapping as used above.
5. Scope is presumed local until broader telemetry confirms otherwise.
