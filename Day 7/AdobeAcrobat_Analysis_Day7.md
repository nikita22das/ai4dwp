Version Header
Title: Adobe Acrobat Pro v23.6 Deployment Failure Analysis
Version: 1.0
Date: 11/08/2026
Author: Nikita
Status: Draft

Incident Summary
Observation:
- Intune attempted to deploy Adobe Acrobat Pro v23.6 using an .intunewin package and SYSTEM-context MSI install command.
- The initial install attempt and retry attempt 1 both returned MSI code 1603.
- Detection logic executed after failure and reported the target registry value as not found.
- Intune marked the deployment as failed and scheduled recurring 60-minute retries.

Conclusion:
- The deployment did not complete successfully in either observed attempt window.

Scope Facts
- Application Name: Adobe Acrobat Pro v23.6
- Deployment Method: Intune Win32 app deployment via package AdobeAcrobatPro.intunewin
- Install Context: SYSTEM
- Install Command: msiexec /i AcrobatPro.msi /quiet
- Detection Method: Registry detection check against HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0
- Retry Behaviour: Retry scheduled every 60 minutes; retry attempt 1 executed and failed; next retry scheduled for another 60 minutes

Timeline of Events
- 2024-03-15 10:01:00: AgentExecutor started app install for Adobe Acrobat Pro v23.6.
- 2024-03-15 10:01:01: AppInstaller reported SYSTEM install context.
- 2024-03-15 10:01:02: AppInstaller identified package AdobeAcrobatPro.intunewin.
- 2024-03-15 10:01:03: AppInstaller invoked msiexec /i AcrobatPro.msi /quiet.
- 2024-03-15 10:01:44: AppInstaller returned code 1603 and logged install failed.
- 2024-03-15 10:01:45: DetectionRule ran registry detection; key HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 value not found.
- 2024-03-15 10:01:46: Detection result reported Not detected.
- 2024-03-15 10:01:47: AgentExecutor recorded app install result Failed and scheduled retry in 60 minutes.
- 2024-03-15 11:01:47: AgentExecutor started retry attempt 1.
- 2024-03-15 11:01:48: AppInstaller invoked the same install command.
- 2024-03-15 11:02:31: AppInstaller returned code 1603 again.
- 2024-03-15 11:02:32: AgentExecutor logged retry 1 failed; next retry scheduled in 60 minutes.

Evidence Collected
1) [2024-03-15 10:01:00] AgentExecutor Starting app install: Adobe Acrobat Pro v23.6
- Proves deployment target application and start time of initial attempt.

2) [2024-03-15 10:01:01] AppInstaller Install context: SYSTEM
- Proves installer execution context.

3) [2024-03-15 10:01:02] AppInstaller Package: AdobeAcrobatPro.intunewin
- Proves Win32 package artifact used by Intune.

4) [2024-03-15 10:01:03] AppInstaller Install command: msiexec /i AcrobatPro.msi /quiet
- Proves exact install command used during initial attempt.

5) [2024-03-15 10:01:44] AppInstaller Return code: 1603
- Proves MSI engine returned fatal-install class error code for initial attempt.

6) [2024-03-15 10:01:44] AppInstaller Install failed. Return code 1603.
- Proves Intune interpreted the return code as install failure.

7) [2024-03-15 10:01:45] DetectionRule Running detection: registry check
- Proves detection workflow executed after failure.

8) [2024-03-15 10:01:45] DetectionRule Key: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0
- Proves the exact registry path used for detection.

9) [2024-03-15 10:01:45] DetectionRule Value: not found
- Proves detector did not locate expected value at configured key.

10) [2024-03-15 10:01:46] DetectionRule Detection result: Not detected
- Proves detection state remained negative after initial install attempt.

11) [2024-03-15 10:01:47] AgentExecutor App install result: Failed
- Proves overall initial attempt outcome recorded as failed.

12) [2024-03-15 10:01:47] AgentExecutor Retry scheduled: 60 minutes
- Proves retry interval policy in effect.

13) [2024-03-15 11:01:47] AgentExecutor Retry attempt 1: Adobe Acrobat Pro v23.6
- Proves retry execution occurred at scheduled cadence.

14) [2024-03-15 11:01:48] AppInstaller Install command: msiexec /i AcrobatPro.msi /quiet
- Proves retry used the same install command.

15) [2024-03-15 11:02:31] AppInstaller Return code: 1603
- Proves repeat MSI failure code in retry attempt 1.

16) [2024-03-15 11:02:32] AgentExecutor Retry 1 failed. Next retry: 60 minutes
- Proves persistent failure pattern and continued retry scheduling.

Differential Diagnosis
Rank 1: MSI installation failure condition inside the executed install path (generic MSI-level blocker)
- Why it fits the evidence:
  - Both attempts returned identical MSI code 1603 under same command and context, indicating repeatable failure at installer execution stage.
- Evidence supporting it:
  - 10:01:44 return code 1603; 11:02:31 return code 1603; both with msiexec /i AcrobatPro.msi /quiet.
- Fastest validation check:
  - Collect and review verbose MSI log for the same command to identify first failing custom action/error line.
- Evidence that would contradict it:
  - A successful install attempt with the same package, context, and command on the same endpoint during same configuration state.

Rank 2: Detection configuration does not align with installed product footprint (registry target mismatch)
- Why it fits the evidence:
  - Detection targets HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 while deployed app is named Adobe Acrobat Pro v23.6; naming/path alignment is not proven by logs.
- Evidence supporting it:
  - Detector explicitly checks Adobe\Acrobat Reader\23.0 and returns value not found at 10:01:45.
- Fastest validation check:
  - On a known-good Acrobat Pro v23.6 device, verify whether the configured registry key/value exists exactly as specified.
- Evidence that would contradict it:
  - Verified presence of the exact configured key/value on successful v23.6 installs.

Rank 3: Packaged content or command target mismatch (command references file not properly available in execution context)
- Why it fits the evidence:
  - Command references AcrobatPro.msi; logs do not show content validation or file resolution success before MSI failure.
- Evidence supporting it:
  - Only command invocation and 1603 outcomes are logged; no confirmation entry that package extraction contained expected MSI path.
- Fastest validation check:
  - Validate intunewin extracted content and confirm AcrobatPro.msi exists at expected relative location used by command.
- Evidence that would contradict it:
  - Verified extracted package contains correct MSI and command path mapping is correct on failed device.

Rank 4: SYSTEM-context specific install constraint
- Why it fits the evidence:
  - Both failures occurred in SYSTEM context; no evidence from alternate context in provided logs.
- Evidence supporting it:
  - Explicit SYSTEM context at 10:01:01 and repeated failure behavior.
- Fastest validation check:
  - Reproduce install with equivalent SYSTEM token and compare outcome against interactive admin context on same endpoint.
- Evidence that would contradict it:
  - Successful install under SYSTEM with same package/command on affected device baseline.

Rank 5: Retry mechanism correctly re-attempts but cannot progress due to unchanged failure precondition
- Why it fits the evidence:
  - Retry used same command and reproduced same return code exactly one hour later.
- Evidence supporting it:
  - Retry scheduled at 10:01:47; retry attempt at 11:01:47; same command at 11:01:48; same code 1603 at 11:02:31.
- Fastest validation check:
  - Confirm whether any deployment variable changes between attempt 0 and attempt 1 (command, content hash, assignment policy, detection rule) were absent.
- Evidence that would contradict it:
  - Logs showing changed package, changed command, or changed policy before retry.

Hypothesis Elimination
Hypothesis 1: Generic MSI-level install blocker in current package/command execution path
- Supports:
  - [10:01:44] Return code 1603.
  - [11:02:31] Return code 1603.
  - [10:01:03] and [11:01:48] same install command.
- Contradicts:
  - No direct contradictory log in provided dataset.
- Neutral:
  - DetectionRule entries show post-install state but do not isolate internal MSI failing step.

Hypothesis 2: Detection registry target mismatch for Acrobat Pro v23.6
- Supports:
  - [10:01:45] Detection key under Adobe\Acrobat Reader\23.0.
  - [10:01:45] value not found; [10:01:46] Not detected.
- Contradicts:
  - [10:01:44] explicit install failure 1603 means detection mismatch alone cannot explain installer failure event.
- Neutral:
  - Retry logs do not include additional detection run evidence after retry attempt 1.

Hypothesis 3: Package content/command target mismatch
- Supports:
  - Command references specific MSI filename; logs do not prove file presence.
  - Repeated 1603 under unchanged command suggests persistent execution-path issue.
- Contradicts:
  - No explicit "file not found" or path error entry in provided logs.
- Neutral:
  - Detection entries neither confirm nor deny package extraction integrity.

Hypothesis 4: SYSTEM-context constraint
- Supports:
  - [10:01:01] SYSTEM context recorded.
  - Failures observed only in SYSTEM runs in provided logs.
- Contradicts:
  - No alternate-context test data provided.
- Neutral:
  - Detection failure is expected after install failure and does not isolate context as sole cause.

Hypothesis 5: Retry cannot self-heal unchanged precondition
- Supports:
  - [10:01:47] retry scheduled 60 minutes; [11:01:47] retry attempt 1; [11:02:31] same 1603; [11:02:32] retry failed again.
- Contradicts:
  - None in provided logs.
- Neutral:
  - Does not identify underlying failure source, only behavior of repeated attempts.

Surviving Hypothesis
Observation-based survivor:
- The strongest surviving hypothesis is a persistent MSI-level installation blocker in the current deployment execution path (same package, same command, same context) causing repeat 1603 outcomes.

Why it survives:
- It directly matches all repeated hard-failure observations across both attempts.
- It requires no unsupported assumption beyond what logs explicitly show.

Why others are eliminated or downgraded:
- Detection mismatch hypothesis is plausible for Not detected state, but it cannot by itself explain explicit installer failure events already logged.
- Package-path mismatch and SYSTEM-context constraints remain plausible but are not proven by explicit error lines in the provided log sample.
- Retry behavior hypothesis explains repetition mechanics, not root failing mechanism.

How it explains all observed behaviour:
- Initial install executes then fails with 1603.
- Detection runs and finds no expected marker, so status remains Not detected.
- AgentExecutor marks failure and schedules retry.
- Retry repeats unchanged conditions and reproduces 1603, resulting in continued failure cycle.

Proposed Resolution
Conclusion from current evidence:
- The most likely fix path is to correct the deployment so MSI installation can complete under SYSTEM with the current Intune package and command, then ensure detection criteria match the actual installed footprint.

Action statement (without assuming success):
- Rebuild or revalidate the Win32 package and install invocation for AcrobatPro.msi, execute with verbose MSI logging, and align detection rule to a verified post-install marker for Acrobat Pro v23.6 before redeployment.

Next Investigation Actions
Additional data needed for root-cause certainty:
1. Verbose MSI log from a failed run of msiexec /i AcrobatPro.msi /quiet under SYSTEM.
2. Intune Management Extension detailed log segment covering package extraction path and command execution context for both attempts.
3. Extracted package file inventory proving presence and location of AcrobatPro.msi at runtime.
4. Registry snapshot from a known-good Acrobat Pro v23.6 endpoint to validate correct detection key/value.
5. Comparative test results on the same endpoint for SYSTEM vs interactive admin context using identical installer media.
6. Any associated Windows Installer event log entries around 10:01:44 and 11:02:31 for correlated MSI error detail.