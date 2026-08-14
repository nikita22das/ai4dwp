Title: Floor 6 Prevention and Reflection
Version: 1.0
Date: 14/08/2026
Author: Nikita
Status: Draft

Prevention Note

Control Name:
- Monday 07:00 Targeted Ring Exit Check

Problem It Addresses:
- This control is designed to catch high-impact endpoint changes that were deployed late in the week and are likely to surface only when users begin work on Monday morning.
- In the Floor 6 incident, the strongest operational concern was that a newly deployed Document Management application may have been causing login delay, startup contention, or instability across a defined user cohort.
- The issue was not that a change existed; the issue was that affected-device behavior was not checked at the final decision point before full business use resumed.

When It Runs:
- Every Monday at 07:00, and on the first business morning following any Friday after-hours or late-afternoon deployment to a pilot or floor-specific ring.

Who Owns It:
- DWP Endpoint Operations, with execution by the on-call endpoint engineer and approval by the incident or change owner.

Inputs Required:
- Current deployment target list for the changed application.
- Affected ring or pilot device list.
- Previous known-good application version.
- Sign-in failure count and sign-in duration trend for target devices.
- Device performance snapshot for the first 10 minutes after sign-in.
- Application crash or error trend for the changed application on target devices.

Pass Criteria:
- No abnormal increase in sign-in failures across the target ring.
- No material increase in sign-in duration compared with pre-change or matched control devices.
- No sustained device resource contention pattern linked to the changed application.
- No meaningful crash or error clustering for the changed application in the target ring.

Fail Criteria:
- Sign-in failures increase above normal for the target ring.
- Sign-in duration is materially worse than pre-change or control trend.
- Device performance degradation appears repeatedly in the changed cohort.
- Application error or crash patterns cluster on changed devices.

Required Action If Failed:
- Stop further rollout immediately.
- Remove the affected ring from active assignment.
- Roll back the target cohort to the previous known-good version under emergency change control.
- Open or update the incident and begin focused user-impact validation before business start.

How this control would have detected the Floor 6 issue before Monday morning:
- The project evidence consistently pointed to a floor-specific change cohort, a Friday deployment window, and Monday morning login and performance symptoms.
- A mandatory 07:00 ring exit check would have forced a decision using measurable criteria before the full Legal population began work.
- If the changed Floor 6 cohort showed worse sign-in outcomes, abnormal startup performance, or clustered application instability compared with pre-change behavior or unaffected controls, the ring would have failed the check.
- That failure would have triggered the same mitigation path used later in the incident, but before users arrived in volume.
- This is specific, measurable, repeatable, and auditable because it has a named owner, fixed trigger time, defined inputs, explicit pass or fail thresholds, and a mandatory action on failure.

Reflection

Initial Assumption:
- My initial instinct was that the first AI-generated evidence collection script was good enough to use as-is because it captured system information, processes, application errors, and a login-related event log.

Why It Seemed Reasonable:
- The script looked broad, structured, and safe because it was read-only, had a dry-run mode, and produced output another engineer could review.
- In a time-pressured incident, that kind of first-pass script can appear sufficient because it seems to cover the main evidence categories quickly.

Evidence Reviewed:
- The script review showed that Version 1 relied too heavily on a single login-related log source, did not distinguish missing data from collector failure, did not sort event data consistently, and did not isolate evidence relevant to the newly changed application.
- It also lacked stronger operator logging and did not make it easy to tell whether a blank section meant no issue was present or the collection had failed.

What The Evidence Showed:
- The first answer was not wrong because it was unsafe; it was wrong because it was incomplete in ways that could distort the investigation.
- A script that appears comprehensive can still mislead engineers if it collects broad data without reliable status reporting, targeted correlation, and clear evidence quality signals.
- In this case, relying on the first version could have weakened the differential analysis by underrepresenting policy, profile, or application-linked evidence and by masking collection gaps.

How It Changed The Investigation:
- Instead of treating the first script as the answer, the investigation shifted to treating it as a draft requiring engineering review.
- That led to a corrected version with collector-level status tracking, stronger error handling, deterministic event ordering, broader login evidence sources, and targeted application-match output.
- This improved the quality of evidence that would be gathered to prove or disprove the leading hypothesis, rather than simply producing more data.

Lesson Learned:
- In AI-assisted DWP work, the first useful-looking output should be treated as a candidate artifact, not an approved operational artifact.
- Evidence collection must be reviewed with the same discipline as a remediation script because weak evidence changes the direction of the investigation just as much as a bad fix would.
- The broader investigation lesson is that evidence-based troubleshooting depends not only on collecting data, but on knowing whether the collection method itself is trustworthy.

FINAL LESSON

This incident reinforced that AI can accelerate DWP troubleshooting, but it does not remove the engineer's responsibility to validate scope, evidence quality, and operational fit. The strongest use of AI in this project was not accepting its first answer quickly; it was using AI to draft, then applying engineering judgement to challenge assumptions, tighten controls, and improve evidence collection before acting. In practice, AI was most valuable as a force multiplier for structured thinking and first-pass outputs, while the quality of the investigation still depended on disciplined review, measurable decision points, and clear separation between correlation, evidence, and conclusion.