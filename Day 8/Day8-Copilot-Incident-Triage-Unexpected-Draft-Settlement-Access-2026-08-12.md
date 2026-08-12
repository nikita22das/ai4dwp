Title: Copilot Incident Triage - Unexpected Draft Settlement Access  
Version: 1.0  
Date: 12/08/2026  
Status: Draft

## Ticket (Observed Facts)
- User role: Partner.
- User says Copilot surfaced and summarised a draft settlement from a matter they are not assigned to.
- User stated: "I didn't even know I could see that folder."

## Likely Cause Ranking (Most Probable First)

### 1) Permissions / Access Boundary
Why it fits the ticket evidence:
- Copilot can only work with content the user can already access.
- The user's statement suggests they may have existing folder access they did not know about.
- This is the best fit for a case where Copilot exposed content from a matter the user did not expect to reach.

Fastest check:
- Verify the user's effective permissions on the folder and the draft settlement file in SharePoint or the source system.

Evidence that would support it:
- The user has direct, inherited, or group-based access to the folder or file.
- The folder is visible to the user in the file system or SharePoint UI when checked directly.

Evidence that would contradict it:
- The user has no effective access path to the folder or file, and direct access checks fail.

### 2) Sensitivity Label Restriction
Why it fits the ticket evidence:
- A draft settlement is likely to be sensitive, so protection controls may apply.
- Label-driven controls can create cases where content exists in a user's access scope but should be restricted or treated carefully.

Fastest check:
- Check whether the draft settlement or its parent library has a sensitivity label or protection policy applied.

Evidence that would support it:
- The file or library is protected by a restrictive label or policy.
- The label policy is meant to control how sensitive legal content is surfaced or handled.

Evidence that would contradict it:
- No restrictive label or policy is present on the file, folder, or library.

### 3) Data Indexing Lag
Why it fits the ticket evidence:
- Copilot may surface content after indexing changes propagate.
- However, the issue here is unexpected visibility of content, not a newly created file or recently changed document, so this is less likely than an access issue.

Fastest check:
- Confirm when the file was created, modified, or moved relative to when Copilot surfaced it.

Evidence that would support it:
- The settlement file or permissions changed very recently and are still within a propagation window.

Evidence that would contradict it:
- The content and permissions have been stable for some time.

### 4) License / Client Prerequisite Issue
Why it fits the ticket evidence:
- If the user lacks a valid Copilot setup, results can be inconsistent.
- That said, the ticket shows Copilot did surface a result, so this is not the strongest explanation.

Fastest check:
- Confirm the user's Copilot license assignment and supported client state.

Evidence that would support it:
- Missing or inactive Copilot entitlement, or an unsupported client build/session state.

Evidence that would contradict it:
- License and client prerequisites are confirmed healthy.

### 5) Guest / External Sharing Limitation
Why it fits the ticket evidence:
- If the folder or matter content is exposed through external sharing constructs, Copilot behavior can differ from standard internal access.
- The ticket does not mention guests or external users, so this remains lower probability.

Fastest check:
- Confirm whether the content is internal only or shared through guest/external access paths.

Evidence that would support it:
- The content depends on guest or cross-tenant sharing rather than normal internal permissions.

Evidence that would contradict it:
- The content is fully internal and accessible through standard tenant permissions.

### 6) Genuine Copilot Fault
Why it fits the ticket evidence:
- This would only be considered if permissions, labels, indexing, licensing, and sharing boundaries are all confirmed healthy and the issue is still reproducible.
- Based on the ticket, a control-plane explanation is more likely than a product defect.

Fastest check:
- Reproduce after validating effective access and policy state on the exact folder and file.

Evidence that would support it:
- The same incorrect surfacing occurs after all access and policy checks are cleared.

Evidence that would contradict it:
- Any access boundary, inherited permission, or policy control explains the surfacing.

## Most Likely Cause
Permissions / Access Boundary.

## Fastest Validation Step
Check the partner's effective permissions on the folder and draft settlement file, including inherited and group-based access.

## Is this actually a Copilot bug?
No.

## Justification
Observation:
- The user believes they should not be able to see the folder.
- Copilot surfaced content from that folder anyway.

Conclusion:
- Copilot is most likely reflecting an existing access path rather than breaking access control.
- The stronger concern is that the user may have broader inherited or group-based permissions than expected.
- A Copilot bug should not be assumed until the access boundary is verified directly.

## Additional Risk Assessment
- Is this a potential oversharing issue? Yes. The user's surprise strongly suggests content may be more visible than intended.
- Does this indicate excessive inherited permissions? Possibly. That is the first control to check because it matches the evidence best.
- Is there a data governance concern? Yes. Draft settlement material is sensitive legal content and should be tightly controlled.
- What business risk exists if similar access is widespread? Confidential matter details could be exposed to users outside the assigned matter team, creating legal, compliance, and client-confidentiality risk.