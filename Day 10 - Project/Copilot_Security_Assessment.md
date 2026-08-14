Title: Floor 6 Copilot Security Assessment
Version: 1.0
Date: 14/08/2026
Author: Nikita
Status: Draft

Scope Facts

What is known:
- A single report has been received from IT Ops lead relaying a user statement.
- The statement is: one paralegal says Copilot surfaced a client matter she believes she has never had access to.
- The report concerns potentially inappropriate visibility of client-related information.

What is unknown:
- The exact prompt used, full Copilot response text, timestamp, and workload context.
- Whether the surfaced content was an actual document, a summary, a title reference, or a misunderstanding of matter naming.
- Whether the user had direct, inherited, historic, group-based, or temporary access at any prior point.
- Whether this is a one-off report or part of a wider pattern affecting other users.
- The current and historical permission state for the matter, folders, and related sites.
- Whether audit data exists, is retained, or is immediately accessible.

Assumptions that must NOT be made:
- Do not assume Copilot created new access rights.
- Do not assume the user definitely never had access.
- Do not assume this is a Copilot product defect.
- Do not assume this is hallucination or AI noise without evidence.
- Do not assume intent, data exfiltration, or misuse by the reporting user.

What Kind Of Incident Is This?

This should not initially be treated as a Copilot bug because the observed behavior can result from existing underlying permissions, inherited access paths, or content oversharing that Copilot is merely revealing. The first handling classification should therefore be a potential information access governance incident rather than an application defect.

This should not be closed as AI weirdness because doing so skips verification of real permission boundaries and could leave a genuine confidentiality gap unaddressed. A single credible report involving client-matter visibility is enough to trigger formal security and governance triage until disproven.

Why this represents a potential security, permissions, governance, or oversharing signal:
- Access inheritance: SharePoint and M365 content often inherits permissions from parent sites, libraries, or groups; users can gain visibility via nested or indirect inheritance that is not obvious to business users.
- Oversharing risks: Broad groups, stale memberships, link-based sharing, or permissive defaults can expose sensitive matter context without explicit item-by-item grants.
- Permission review requirements: Effective access must be validated at user, group, site, library, folder, and item levels, including historical and inherited paths.
- Data governance implications: If sensitivity labels, least-privilege controls, and matter segregation are misaligned, AI-assisted retrieval may surface governance debt faster, which is a control concern independent of Copilot troubleshooting.

Conclusion for handling type:
- Treat as a potential security and data governance incident signal.
- Run evidence-led access validation and governance escalation.
- Defer any product-defect conclusion until permission and audit evidence is reviewed.

Immediate Actions

1. Action: Preserve the initial report details and capture user statement verbatim.
- Why it is needed: Prevents loss of context and anchors timeline/evidence integrity.
- Who should perform it: Incident manager or service desk lead.

2. Action: Request exact prompt/response evidence from the reporting paralegal (screenshots/text and timestamp).
- Why it is needed: Establishes what was actually surfaced and where.
- Who should perform it: DWP engineer with service desk support.

3. Action: Open parallel escalation to Security/Compliance/Data Governance.
- Why it is needed: Potential confidentiality exposure requires governance oversight from the start.
- Who should perform it: Incident commander or duty security liaison.

4. Action: Initiate effective-permissions review for the referenced client matter content path.
- Why it is needed: Determines whether access was legitimately inherited, directly granted, or misconfigured.
- Who should perform it: M365/SharePoint admin and identity team.

5. Action: Start audit evidence request (Copilot activity, content access, sign-in context) with retention awareness.
- Why it is needed: Time-sensitive logs may roll; early collection protects forensic completeness.
- Who should perform it: Security operations or compliance analyst.

6. Action: Classify current state as unconfirmed potential oversharing until evidence resolves.
- Why it is needed: Ensures consistent communications without premature closure or blame.
- Who should perform it: Incident manager.

What I Would NOT Do

1. Incorrect action: Close the ticket as a Copilot issue.
- Why inappropriate: It bypasses access-governance validation and may miss a real confidentiality exposure.

2. Incorrect action: Assume the user never had access.
- Why inappropriate: Users may be unaware of inherited, historic, or group-derived permissions; assumption can distort triage.

3. Incorrect action: Treat it as hallucination without evidence.
- Why inappropriate: The report references client matter visibility and must be verified through audit and permission checks first.

4. Incorrect action: Disable Copilot tenant-wide as a first reflex.
- Why inappropriate: This is a broad disruptive action without confirmed root cause and may not address the underlying permission issue.

5. Incorrect action: Communicate a root cause before evidence review.
- Why inappropriate: Premature conclusions can create legal/compliance risk and damage trust in incident handling.

Escalation

A user-reported event indicates Copilot surfaced a client matter to a paralegal who states she should not have access, and we have not yet validated effective permissions or audit history for that content path. Please initiate urgent Security/Compliance/Data Governance investigation for potential oversharing or permission inheritance exposure, preserve relevant audit records, and coordinate evidence-led access validation without assuming product defect or user error.

Evidence Collection Plan

1. Effective permissions review:
- What to collect: Current effective access for the reporting user and comparison users at site, library, folder, and item levels.
- Why: Confirms whether visibility is authorized, inherited, or misconfigured.

2. Access inheritance mapping:
- What to collect: Parent-to-child permission inheritance chain, broken inheritance points, and unique permission nodes.
- Why: Identifies hidden or indirect paths that can explain unexpected visibility.

3. SharePoint and OneDrive access history:
- What to collect: Recent access events for the referenced matter artifacts, including actor, timestamp, operation, and source.
- Why: Establishes whether and when access occurred, and whether behavior is isolated.

4. Group membership and entitlement history:
- What to collect: Entra ID and M365 group memberships (current and recent changes), nested groups, dynamic rule impacts.
- Why: Determines if entitlement drift or stale group assignment enabled access.

5. Copilot-related audit activity:
- What to collect: Available Copilot/M365 audit events linked to user/session/time window and referenced content.
- Why: Correlates user prompt/response behavior with underlying data access events.

6. Sharing configuration and link audit:
- What to collect: External/internal sharing links, anonymous/company links, link scope, expiration, and recipients.
- Why: Oversharing frequently occurs through broad links outside intended matter boundaries.

7. Data governance control state:
- What to collect: Sensitivity labels, DLP policies, retention settings, and matter-segregation policy applicability.
- Why: Tests whether governance controls match the confidentiality expectations of client matter data.

8. User validation package:
- What to collect: User confirmation of matter identity, screenshot artifacts, and sequence of actions before the observation.
- Why: Reduces ambiguity and prevents misclassification based on partial narrative.

9. Correlation with other reports:
- What to collect: Similar incidents/tickets from same floor, team, or matter workspace.
- Why: Distinguishes isolated event from systemic permissions/governance issue.

Evidence status note:
- None of the above evidence is assumed to already exist in-hand; each item requires explicit collection and validation before any root-cause conclusion.