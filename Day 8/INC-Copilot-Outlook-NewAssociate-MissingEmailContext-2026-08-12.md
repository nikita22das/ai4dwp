# Copilot Incident Triage – New Associate Missing Email Context

**Version:** 1.0
**Date:** 12/08/2026
**Status:** Draft

---

## Ticket Summary

A new associate who joined this week is unable to use Copilot in Outlook to find any case emails needed for context. The user is attempting to use Copilot to understand ongoing case activity and historical email discussions.

---

## Likely Causes (Most Probable First)

---

### 1. Data Indexing Lag

**Why it fits the ticket evidence**
The user joined this week. Their mailbox and any shared mailboxes or folders they have recently been granted access to will not be fully indexed by Microsoft 365 Search yet. Copilot in Outlook relies on the Microsoft Search index; content that has not been indexed cannot be surfaced. A brand-new account has zero indexed history at the point of joining.

**Fastest check**
Ask the user to perform a native Outlook Search (not Copilot) for a known email subject or sender. If standard search also returns no results or very limited results, indexing lag is confirmed.

**Evidence that would support it**
- Standard Outlook Search also fails to return expected emails.
- The mailbox was provisioned within the last 1–7 days.
- Other new-joiner accounts in the same cohort report the same experience.
- Microsoft 365 Admin Center shows mailbox provisioned date aligns with this week.

**Evidence that would contradict it**
- Standard Outlook Search successfully finds the emails but Copilot cannot.
- The emails were migrated into the mailbox well before this week and indexing should be complete.

---

### 2. Permissions / Access Boundary

**Why it fits the ticket evidence**
The associate is described as needing "case emails" — these may reside in shared mailboxes, team mailboxes, or delegated folders to which the new user has not yet been granted access. Copilot cannot retrieve content the user's identity does not have permission to access, regardless of business need.

**Fastest check**
Confirm whether the case emails are in the user's own mailbox or in a shared/team mailbox. Verify in Exchange Admin Center or Outlook that the user has been granted the necessary delegate or member permissions on those mailboxes/folders.

**Evidence that would support it**
- Case emails live in a shared mailbox or team folder, not the user's personal inbox.
- The user's account has not been added as a delegate or member of the relevant mailbox.
- Other users with explicit permissions can retrieve the same emails via Copilot.

**Evidence that would contradict it**
- The emails are confirmed to be in the user's own mailbox.
- The user can open and read the emails manually in Outlook but Copilot still cannot find them.

---

### 3. License / Client Prerequisite Issue

**Why it fits the ticket evidence**
New-joiner provisioning workflows sometimes apply a base M365 licence first and assign the Microsoft 365 Copilot add-on licence as a secondary step, which can be delayed. If the Copilot licence was not assigned at account creation, the feature will appear present (if the client was pre-installed) but will silently fail to retrieve content or surface an error.

**Fastest check**
Check the user's assigned licences in Microsoft Entra ID (Azure AD) or the M365 Admin Center. Confirm a Microsoft 365 Copilot licence is assigned and shows as active (not pending).

**Evidence that would support it**
- The Copilot licence is absent or shows as "Pending" in the admin portal.
- The user was onboarded via a standard new-joiner flow that assigns licences in batches.
- Other Copilot features (e.g., Copilot in Teams, Word) are also non-functional for this user.

**Evidence that would contradict it**
- Licence assignment is confirmed as active for this user.
- Copilot works in other M365 applications for the same user.

---

### 4. Sensitivity Label Restriction

**Why it fits the ticket evidence**
If case emails carry sensitivity labels (e.g., OFFICIAL-SENSITIVE, PROTECTED) that restrict access to specific security groups, a new associate who has not yet been added to those groups will be blocked from Copilot retrieving that content. This is a common DWP pattern where case-related correspondence is labelled.

**Fastest check**
Open one of the target emails directly in Outlook and check whether a sensitivity label is displayed in the ribbon or message header. If labelled, verify the user's Entra ID group memberships against the label's access policy.

**Evidence that would support it**
- Target emails display a sensitivity label.
- The user is not a member of the security group referenced in the label's access policy.
- Other users in the correct security group can retrieve the same emails via Copilot.

**Evidence that would contradict it**
- Emails carry no sensitivity label or carry a label with no access restriction.
- The user can open and read the labelled emails manually (indicating they are in scope of the label policy).

---

### 5. Guest / External Sharing Limitation

**Why it fits the ticket evidence**
If any of the case emails were shared from or with external parties, or if the user's account was inadvertently provisioned as a guest-type identity rather than a full member, Copilot's retrieval scope may be constrained.

**Fastest check**
Confirm in Entra ID that the account type is "Member" not "Guest". Check the UserType attribute.

**Evidence that would support it**
- The account shows as UserType = Guest in Entra ID.
- The user was provisioned via an external collaboration flow rather than the standard HR onboarding pipeline.

**Evidence that would contradict it**
- The account is confirmed as a full Member in Entra ID.
- The user can access internal SharePoint sites and Teams without guest restrictions.

---

### 6. Genuine Copilot Fault

**Why it fits the ticket evidence**
There is minimal evidence to support a Copilot-specific defect. The scenario is fully explained by new-joiner conditions. This category is included for completeness only.

**Fastest check**
After ruling out all causes above, test the same Copilot query on a tenured user account with confirmed access to the same emails. If that user succeeds, the fault is environmental, not a Copilot defect.

**Evidence that would support it**
- All environmental causes (indexing, permissions, licence, labels) have been confirmed as correct and healthy.
- Tenured users with identical permissions also fail to retrieve the emails via Copilot.
- A Microsoft service health advisory is active for Copilot in Outlook.

**Evidence that would contradict it**
- Any of the above environmental causes is found to be misconfigured (which is the expected finding in a new-joiner scenario).

---

## Most Likely Cause

**Data Indexing Lag**, closely followed by **Permissions / Access Boundary**.

A user who joined this week will have a mailbox that is either not yet indexed or only partially indexed by Microsoft 365 Search. If the case emails also reside in shared or team mailboxes that the user has not yet been explicitly granted access to, a permissions gap compounds the indexing issue. Both conditions are standard new-joiner states and fully account for the reported behaviour without requiring any Copilot defect.

---

## Fastest Validation Step

Ask the user to run a native Outlook Search (keyboard shortcut: Ctrl+E) for a specific email subject or sender known to be in scope. If native search also returns no results, indexing lag is the primary cause and the user should be advised to allow 24–72 hours for full indexing to complete. If native search succeeds but Copilot does not, escalate to licence verification and permissions review.

---

## Is This Actually a Copilot Bug?

**No**

---

## Justification

The entire reported behaviour is consistent with standard Microsoft 365 new-joiner conditions. Mailbox indexing for a newly provisioned account is incomplete by design for the first 24–72 hours. Access to case-related shared mailboxes or sensitivity-labelled content requires explicit provisioning steps that may not yet have been completed. There is no evidence in the ticket that points to a defect in the Copilot service itself. All causes are environmental and resolvable through standard IT onboarding checks.

> **Observation vs. Conclusion separation:**
> *Observation:* User joined this week; Copilot cannot find case emails.
> *Conclusion:* This is consistent with indexing lag and/or missing permissions — not a Copilot fault — until environmental factors are ruled out.

---

*Document prepared by DWP Engineering – M365 Copilot Triage*
