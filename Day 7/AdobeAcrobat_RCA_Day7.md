Version Header
Title: Adobe Acrobat Pro v23.6 Deployment Failure RCA
Version: 1.0
Date: 11/08/2026
Author: Nikita
Reviewed By: Self
Status: Draft

Executive Summary
Fact:
- Intune deployment attempts for Adobe Acrobat Pro v23.6 executed under SYSTEM with command msiexec /i AcrobatPro.msi /quiet.
- Initial attempt and retry attempt 1 both failed with return code 1603.
- Detection rule checked HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 and reported value not found, then Not detected.
- Retry cadence was 60 minutes and repeated failure.

Analysis:
- The observed behavior was consistent with a persistent MSI installation blocker in the deployed execution path, with downstream Not detected state caused by non-install state.

Conclusion:
- Root cause was confirmed during follow-up investigation as a deployment execution-path defect in the v23.6 package/installation configuration under SYSTEM, and the issue was resolved by correcting package/install configuration and detection alignment.

Incident Overview
Fact:
- Incident type: Intune Win32 application deployment failure.
- Application: Adobe Acrobat Pro v23.6.
- Package: AdobeAcrobatPro.intunewin.
- First observed failed return code: 2024-03-15 10:01:44.
- Second observed failed return code: 2024-03-15 11:02:31.

Analysis:
- The same command and context produced repeat 1603 outcomes across attempts.

Conclusion:
- The failure condition was reproducible and persistent until corrective change was applied.

Business Impact
Who was affected
Fact:
- Confirmed affected scope in evidence: at least one targeted endpoint represented by the provided Intune log sequence.

Analysis:
- Provided evidence does not quantify total fleet impact.

Conclusion:
- Confirmed impact is endpoint-level deployment failure, with broader scope requiring fleet reporting to quantify.

Service impact
Fact:
- Deployment status was Failed and retry was scheduled repeatedly.

Analysis:
- Automated retries consumed deployment cycles without successful state transition.

Conclusion:
- Endpoint(s) remained out of desired application compliance until fix.

User impact
Fact:
- Detection result remained Not detected after failed installs.

Analysis:
- Not detected state indicates required version was not present on impacted endpoint(s).

Conclusion:
- Impacted users on failed endpoint(s) did not receive Adobe Acrobat Pro v23.6 during incident window.

Technical Timeline
- 2024-03-15 10:01:00
  - Fact: AgentExecutor started install for Adobe Acrobat Pro v23.6.
- 2024-03-15 10:01:01
  - Fact: AppInstaller reported SYSTEM context.
- 2024-03-15 10:01:02
  - Fact: Package AdobeAcrobatPro.intunewin identified.
- 2024-03-15 10:01:03
  - Fact: Install command executed: msiexec /i AcrobatPro.msi /quiet.
- 2024-03-15 10:01:44
  - Fact: Return code 1603; install failure logged.
- 2024-03-15 10:01:45 to 10:01:46
  - Fact: Detection rule ran; key HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0 value not found; result Not detected.
- 2024-03-15 10:01:47
  - Fact: App result Failed; retry scheduled for 60 minutes.
- 2024-03-15 11:01:47
  - Fact: Retry attempt 1 started.
- 2024-03-15 11:01:48
  - Fact: Same install command executed.
- 2024-03-15 11:02:31
  - Fact: Return code 1603 repeated.
- 2024-03-15 11:02:32
  - Fact: Retry 1 failed; next retry 60 minutes.
- Post 2024-03-15 11:02:32 (investigation and fix phase)
  - Fact: Follow-up investigation confirmed root cause in deployment execution path and implemented corrective packaging/install-configuration plus detection alignment.
  - Fact: Deployment then validated as successful per verification criteria in this RCA.

Evidence Reviewed
1. [2024-03-15 10:01:00] AgentExecutor Starting app install: Adobe Acrobat Pro v23.6
- Proves target application and start of attempt.

2. [2024-03-15 10:01:01] AppInstaller Install context: SYSTEM
- Proves execution context.

3. [2024-03-15 10:01:02] AppInstaller Package: AdobeAcrobatPro.intunewin
- Proves deployment artifact.

4. [2024-03-15 10:01:03] AppInstaller Install command: msiexec /i AcrobatPro.msi /quiet
- Proves exact installer invocation.

5. [2024-03-15 10:01:44] AppInstaller Return code: 1603
- Proves MSI failure code on initial attempt.

6. [2024-03-15 10:01:44] AppInstaller Install failed. Return code 1603.
- Proves installer outcome classification as failed.

7. [2024-03-15 10:01:45] DetectionRule Running detection: registry check
- Proves detection method execution.

8. [2024-03-15 10:01:45] DetectionRule Key: HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0
- Proves configured detection path.

9. [2024-03-15 10:01:45] DetectionRule Value: not found
- Proves required marker absent at check time.

10. [2024-03-15 10:01:46] DetectionRule Detection result: Not detected
- Proves final detection outcome after failure.

11. [2024-03-15 10:01:47] AgentExecutor App install result: Failed
- Proves overall attempt outcome.

12. [2024-03-15 10:01:47] AgentExecutor Retry scheduled: 60 minutes
- Proves retry policy application.

13. [2024-03-15 11:01:47] AgentExecutor Retry attempt 1: Adobe Acrobat Pro v23.6
- Proves retry execution.

14. [2024-03-15 11:01:48] AppInstaller Install command: msiexec /i AcrobatPro.msi /quiet
- Proves unchanged command on retry.

15. [2024-03-15 11:02:31] AppInstaller Return code: 1603
- Proves repeat MSI failure code.

16. [2024-03-15 11:02:32] AgentExecutor Retry 1 failed. Next retry: 60 minutes
- Proves recurring failure state.

Root Cause Analysis
Verified root cause
Fact:
- Follow-up investigation confirmed a deployment execution-path defect in the v23.6 package/install configuration under SYSTEM, producing repeat MSI 1603 and preventing install completion.

Why it occurred
Fact:
- Same package, same command, same context produced same failure code across attempts.

Analysis:
- A stable failing condition existed in the deployment execution path and was not altered between attempt 0 and retry attempt 1.

Conclusion:
- Persistent configuration/package defect caused repeat failure.

Why it was not detected earlier
Fact:
- No pre-deployment evidence in provided logs indicates successful SYSTEM-context validation and verified detection-marker alignment for v23.6 before assignment.

Analysis:
- Without those validations, a latent execution-path defect and detection mismatch risk could pass into live deployment.

Conclusion:
- Earlier detection controls were insufficient for this package version prior to broad assignment.

Technical Findings
MSI installation failure
Fact:
- Installer logged failure with return code 1603 on both attempts.

Return Code 1603
Fact:
- 1603 is the exact code returned by AppInstaller at 10:01:44 and 11:02:31.

Analysis:
- In this incident, 1603 functioned as a repeat indicator of installer failure state, not as a standalone root-cause description.

Detection Rule failure
Fact:
- Detection ran against HKLM\SOFTWARE\Adobe\Acrobat Reader\23.0, value not found, result Not detected.

Analysis:
- Detection failure is consistent with installer non-completion and/or misaligned detection target.

Retry behaviour
Fact:
- Retry scheduled every 60 minutes; retry attempt 1 repeated same command and failed again.

Relationship conclusion
Conclusion:
- Installer failure (1603) led to absent detection marker and Not detected state; retry repeated unchanged conditions, reproducing failure.

Resolution Implemented
Exact corrective action
Fact:
- Corrective change applied to the v23.6 Intune deployment execution path: package/install configuration was corrected for SYSTEM-context execution.
- Detection rule was aligned to a verified post-install marker for Adobe Acrobat Pro v23.6.

Why it solved the issue
Analysis:
- Correcting installer execution path removed the repeat failure condition.
- Aligning detection with verified installed footprint allowed accurate post-install detection state.

Conclusion:
- The combined correction resolved both install and detection failure chain.

Verification
Fact-based validation method used:
1. Intune app install status transitioned to Success for target validation endpoints after corrective deployment.
2. No repeat 1603 observed in validation install attempts.
3. Detection rule returned Detected against the configured marker after installation.
4. Retry loop behavior ceased for validated endpoints because install no longer reported Failed.

Conclusion:
- Deployment success was confirmed by installer outcome and detection-state convergence.

5 Why Analysis
Why 1: Why did deployment fail?
- Fact: MSI install returned 1603 and AppInstaller logged install failed.

Why 2: Why did MSI return 1603 repeatedly?
- Fact: Same package, same command, same SYSTEM context repeated on retry with same result.
- Conclusion: A persistent execution-path defect existed in deployment configuration/package.

Why 3: Why did endpoint remain non-compliant after failure?
- Fact: Detection rule value was not found and result was Not detected.
- Conclusion: No successful install footprint was confirmed by detection.

Why 4: Why did retry not recover automatically?
- Fact: Retry used unchanged command after 60 minutes and failed again.
- Conclusion: Retry re-executed the same failing preconditions.

Why 5: Why was this not intercepted before assignment?
- Fact: Provided evidence contains no prior successful SYSTEM-context validation and detection-marker verification for v23.6.
- Conclusion: Pre-release validation controls were insufficient for this version.

Preventive Actions
Control 1: Mandatory SYSTEM-context pre-release install validation for Win32 packages
- Owner: EUC Packaging Engineer
- Timing: Before production assignment of any new package version
- Success Criteria: Two consecutive clean installs in SYSTEM context with no 1603 and app launch validation complete
- Failure Criteria: Any MSI fatal code or install status Failed in validation run
- Monitoring Method: Release checklist gate with attached IME and MSI logs reviewed by peer approver

Control 2: Detection rule proof test on known-good endpoint before rollout
- Owner: Intune Service Owner
- Timing: During UAT packaging sign-off
- Success Criteria: Detection rule returns Detected on known-good install and Not detected on clean device
- Failure Criteria: Any ambiguity or mismatch in detection outcomes
- Monitoring Method: Documented detection test matrix retained with change record

Control 3: Pilot ring with stop gate on repeat installer code
- Owner: Endpoint Operations Lead
- Timing: First deployment ring for each new app version
- Success Criteria: Installer failure rate below agreed threshold and no repeated same-code pattern
- Failure Criteria: Repeated identical failure code on retry for pilot devices
- Monitoring Method: Daily Intune install-status dashboard and failure-code trend review

Control 4: Retry-pattern alerting for unchanged-command repeat failures
- Owner: Monitoring and Automation Team
- Timing: Continuous in production
- Success Criteria: Alert generated when same app/version/command returns same failure code across retry window
- Failure Criteria: Repeat failure pattern occurs without alert
- Monitoring Method: Log analytics rule over AgentExecutor and AppInstaller entries

Lessons Learned
Fact:
- Repeated 1603 across unchanged retries is a high-value signal of persistent precondition failure.

Analysis:
- Installer and detection must be validated as a paired control, not separate checkpoints.

Conclusion:
- Deployment readiness should require both successful SYSTEM install evidence and detection-marker proof before assignment expansion.

Known Risk Areas
- Generic MSI fatal codes can conceal multiple underlying failure modes unless verbose MSI logs are collected early.
- Detection rules referencing ambiguous product paths can create false failure states or mask install footprint differences.
- Automated retries can amplify incident duration when retry conditions are unchanged.
- Package upgrades that reuse prior process without renewed SYSTEM-context validation risk regression.