# Microsoft 365 connector security review

**Status: final activation and end-user acceptance remain unverified.**
This anonymized case concerns review of a third-party AI connector's access to
Microsoft 365. Publication of this runbook does not certify the integration as
secure, functional, or approved for a particular organization.

## Scope and evidence limits

The source narrative describes an initial rollout with outstanding provider-side
activation and pilot testing. This public derivative intentionally omits actual
assignment counts, deployment configuration, and granted permission inventories.
It contains no tenant identifiers, app identifiers, user lists, or source logs.
The diagnostic script is a reusable review aid, not the original deployment tool.

## Review procedure

1. Obtain an approved inventory of connector-related enterprise applications in
   private storage. Distinguish application identifiers from service-principal
   object identifiers.
2. Confirm the intended tenant and operator authorization before any audit.
3. Check whether assignment is required and review assignments privately.
   An assignment count is not a count of effective users: groups can contain
   members and permissions may impose additional access conditions.
4. Review delegated consent and application permissions as separate inventories.
   Match each requested permission to an approved data flow and provider policy.
   The included script does not perform this consent review.
5. Verify existing authentication and access policies using approved private
   audit evidence. Do not weaken them to make a connector test pass.
6. Have an authorized owner confirm provider activation and conduct controlled
   assigned-user and unassigned-user tests with synthetic content.
7. Record retention, revocation, rollback and support ownership. Change consent
   or assignments only through separate approved change control.

## Read-only diagnostic

Install Microsoft.Graph.Authentication through your organization's approved
process and establish an authorized delegated session separately. The script
requires the SDK's read-only Application.Read.All scope; this is a prerequisite
for this generic audit, not a disclosure of permissions granted in the incident.

```powershell
# Populate these variables privately; never commit actual IDs.
.\scripts\Get-EntraAppAssignmentPosture.ps1 -ApplicationIds $ApprovedApplicationIds -ExpectedTenantId $ApprovedTenantId
```

The script does not sign in, request consent, install modules, or change the
tenant. It rejects placeholders and a mismatched session, checks pagination
destinations and limits, and fails on missing applications or API errors.
Output contains only input position, assignment requirement and count. Keep even
these results private. It does not enumerate consent scopes, expand groups,
verify authentication policies, or prove connector access.

## Acceptance criteria

- An authorized reviewer approves the private permission and data-flow inventory.
- A pilot user completes the intended workflow with synthetic content.
- An unassigned test identity is rejected where the approved access design
  requires this; any discrepancy is investigated.
- Authentication-policy, retention, revocation and rollback checks are recorded.
- A service owner confirms provider-side activation and support ownership.

These criteria remain outstanding in the source case. CI cannot establish them.

## Repository scope and operating boundaries

This standalone project separates the historical incident outcome from the
diagnostic tooling. The script collects a narrow set of checks; it does not
automatically perform the manual recovery steps described above. Start with a
nonproduction test and capture a baseline before proposing a configuration
change. Use the least-privileged approved identity and preserve rollback values
in private change records. Stop when required inputs or authorization are missing.

## Evidence and acceptance record

For any new investigation, record the product/runtime versions, UTC observation
time, expected behavior, actual result, exact approved change, rollback owner,
and follow-up observation window in private storage. Publish only a redacted
summary. Mark hypotheses as hypotheses. A successful diagnostic command or green
CI run does not prove the business workflow works. Keep unresolved acceptance
items open until an authorized tester verifies the end-user result.

## Quality, security and licensing

- [Tests and limitations](TESTING.md): syntax, hygiene and isolated regressions.
- [Security guidance](SECURITY.md): safe execution and evidence handling.
- [Source and rights](PROVENANCE.md) and [MIT license](LICENSE).
- [CI runs](https://github.com/IAmLegionVaal/M365-Claude-Connector-Security-Review/actions/workflows/validate.yml).
- [Central incident index](https://github.com/IAmLegionVaal/IT-Support-Toolkit-Launcher/blob/main/incident-projects/README.md).
- [Publication and follow-up tracker](https://github.com/IAmLegionVaal/IT-Support-Toolkit-Launcher/issues/1).

Contributions should include synthetic regression coverage and an explicit
statement of what was actually tested. Do not attach raw client evidence to
issues or pull requests. Preserve the historical status unless new evidence
supports a change.
