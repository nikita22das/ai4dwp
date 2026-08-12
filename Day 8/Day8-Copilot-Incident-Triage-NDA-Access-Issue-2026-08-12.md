Title: Copilot Incident Triage - NDA Access Issue  
Version: 1.0  
Date: 12/08/2026  
Status: Draft

## Ticket (Observed Facts)
- User role: Paralegal.
- User asked Copilot to summarize a client NDA in SharePoint.
- Copilot response: "I don't have access to that content."
- File location context: The NDA is in a folder the user has never opened before.
- User awareness context: User only heard about the folder in a meeting.

## Likely Cause Ranking (Most Probable First)

### 1) Permissions / Access Boundary
Why it fits the ticket evidence:
- The returned message explicitly states lack of access.
- User has never opened the folder before, which is consistent with possible lack of granted permissions.

Fastest check:
- Ask the user to open the exact NDA file directly in SharePoint using the same account.

Evidence that would support it:
- User cannot open the folder/file directly.
- SharePoint permissions show the user is not in an allowed group or has no direct access.

Evidence that would contradict it:
- User can directly open and read the exact NDA file with the same account and same tenant context.

### 2) Sensitivity Label Restriction
Why it fits the ticket evidence:
- Client NDA content is likely sensitive in many legal/finance environments.
- A protection policy could allow some access patterns while restricting Copilot usage context.

Fastest check:
- Check whether the NDA has a sensitivity label or protection policy that restricts usage.

Evidence that would support it:
- File has a restrictive sensitivity label/policy aligned to legal/confidential data controls.
- Policy documentation indicates Copilot-related limitations for that protected content path.

Evidence that would contradict it:
- No restrictive label/policy is applied, or policy allows this user and usage mode without restriction.

### 3) License / Client Prerequisite Issue
Why it fits the ticket evidence:
- If Copilot entitlement/client prerequisites fail, user can see inconsistent Copilot behavior.
- Less likely here because the response is access-specific, not a general service unavailable message.

Fastest check:
- Verify Copilot license assignment and supported client/session state for this user.

Evidence that would support it:
- Missing Copilot add-on assignment or inactive service plan for the user.
- Unsupported client state correlating with failed Copilot operations.

Evidence that would contradict it:
- User license and client prerequisites are confirmed healthy and compliant.

### 4) Data Indexing Lag
Why it fits the ticket evidence:
- Newly discovered content may not be immediately reflected in all Copilot retrieval contexts.
- However, the explicit "don't have access" phrasing points more to access control than indexing latency.

Fastest check:
- Confirm when the file/folder permissions and content were last changed relative to the user test.

Evidence that would support it:
- Very recent permission/content updates with expected indexing propagation window still in progress.

Evidence that would contradict it:
- File and permissions have been stable for a long period with no recent change window.

### 5) Guest / External Sharing Limitation
Why it fits the ticket evidence:
- If the NDA is accessed through external/guest sharing patterns, Copilot may not retrieve it as expected.
- Ticket does not mention external sharing, so this remains lower probability.

Fastest check:
- Confirm whether the NDA is internal SharePoint content or relies on guest/external sharing constructs.

Evidence that would support it:
- File access path is through guest/external sharing model rather than standard internal permissioning.

Evidence that would contradict it:
- File is fully internal to tenant with normal internal access controls.

### 6) Genuine Copilot Fault
Why it fits the ticket evidence:
- Could only fit if all access, policy, licensing, client, and content-state checks are valid and reproducible issue persists.
- By rule and evidence, this is last resort.

Fastest check:
- Reproduce after all higher-probability causes are ruled out, then compare behavior across another user with identical permissions.

Evidence that would support it:
- Multiple controlled reproductions fail despite confirmed access, compliant policy state, and valid prerequisites.

Evidence that would contradict it:
- Any upstream control issue (permissions, policy, prerequisites, sharing model) explains the behavior.

## Most Likely Cause
Permissions / Access Boundary.

## Fastest Validation Step
Ask the paralegal to open the exact NDA directly in SharePoint with the same account used in Copilot.

## Is this actually a Copilot bug?
No.

## Justification
Observation:
- Copilot explicitly returned an access denial message.
- User has never opened the target folder before.

Conclusion:
- The strongest evidence points to a permission/access boundary issue rather than a Copilot product defect.
- A bug classification is not justified unless higher-probability control causes are disproven with direct validation.
