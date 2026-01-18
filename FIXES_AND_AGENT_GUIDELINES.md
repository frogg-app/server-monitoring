# FIXES AND AGENT GUIDELINES

Purpose
-------
This document centralizes small-to-medium fixes that need to be implemented in the repository and defines strict conventions for how AI agents and humans add, track, and mark tasks complete.

Why this exists
----------------
- Provide a single, unambiguous place for required fixes and their acceptance criteria.
- Enforce a strict, machine-parseable task format so automated agents can add/read tasks reliably.
- Prevent accidental or conflicting edits to the rules or task descriptions.

Document rules (MUST NOT be changed)
-----------------------------------
1. This header, the rules, and the task-format template MUST NOT be modified by agents completing tasks. They are the immutable contract for how tasks are added and removed.
2. Agents ADDING tasks must append a new task block that exactly matches the "Task Block Template" below, and MUST NOT change any other section of this file.
3. Agents COMPLETING tasks must only remove the entire task block corresponding to the task they completed. They MUST NOT edit or reformat the template, other tasks, or the rules.
4. Do not change task IDs that are already present. If you add a task, choose the next available sequential TASK-XXXX ID.
5. Each task block must contain the exact fields in the exact order specified by the template. Missing fields make the task invalid and may be rejected by automation.
6. Tasks marked as `Status: completed` must be removed from this document by the agent that completed it. Other agents or humans must not remove tasks they did not complete.

Task Block Template (strict format)
-----------------------------------
When adding a new task, copy the block below and replace the example values. Do not alter field names, order, or the header marker.

### TASK: TASK-0001 - Short Title Here

- ID: TASK-0001
- Status: not-started | in-progress | completed
- Priority: P0 | P1 | P2
- Owner: @agent-or-username (or unassigned)
- Created: 2026-01-17 (YYYY-MM-DD)
- Files: file/path1, file/path2  (comma-separated relative paths)
- Description: |
  Short explanation of the problem, why it matters, and a concise plan of action.
- Acceptance Criteria: |
  - Clear pass/fail criteria, e.g. HTTP 200 for endpoint, UI no longer 404, tests pass.
- Tests/Commands: |
  - Commands to run to validate the fix (unit tests, integration tests, manual curl commands).
- Notes: |
  - Any extra context or links to issues/PRs. Optional.

Example (do not edit this example when adding new tasks)
------------------------------------------------------
### TASK: TASK-0000 - Example Task (template)

- ID: TASK-0000
- Status: not-started
- Priority: P2
- Owner: unassigned
- Created: 2026-01-17
- Files: README.md
- Description: |
  This is an example task to demonstrate the required block format. Replace fields with real values.
- Acceptance Criteria: |
  - Example criteria met.
- Tests/Commands: |
  - echo "run example"
- Notes: |
  - None


-------------------------
How to add new tasks (summary)
-------------------------
1. Copy the Task Block Template exactly and fill values.
2. Append the full task block to the end of this file.
3. Choose the next sequential `TASK-XXXX` ID.
4. Do not edit rules, the template, or other tasks.

How to mark a task complete (summary)
------------------------------------
1. The agent that implemented and validated the fix must remove the completed `### TASK: ...` block from this file entirely (delete from the file).
2. The agent must not modify any other content in this file.
3. When removing the task block, commit the change with a message referencing the task ID (e.g., `fix: TASK-0002 - implement alerts API and remove task from FIXES_AND_AGENT_GUIDELINES.md`).

Audit and automation
--------------------
- Automation can parse this file by scanning for `### TASK: TASK-` headers and reading the fields that follow. Keep field names and order stable.
- Any agent that fails to follow the template may have their addition rejected by automation or by a human reviewer.

Contact / Questions
-------------------
If you're unsure about adding or removing a task, open a PR and request review from the repository maintainers.

-------------------------
New Tasks (added 2026-01-17)
-------------------------

### TASK: TASK-0006 - Remove "Source code" link from UI

- ID: TASK-0006
- Status: not-started
- Priority: P1
- Owner: unassigned
- Created: 2026-01-17
- Files: app/web/**, app/lib/widgets/header.dart, README.md
- Description: |
  The web UI currently exposes a "Source code" link which points directly at the repository. Remove or replace this link with a pointer to internal documentation to avoid exposing the repo link publicly.
- Acceptance Criteria: |
  - The web UI no longer shows a clickable "Source code" link that points to the repo.
  - A documentation link is present and navigates to the local docs or README.
- Tests/Commands: |
  - Open the web UI and verify the header/menu no longer contains the source link.
  - `grep -R "Source code" -n app || true`
- Notes: |
  - This is primarily a UI/navigation change; no DB work required.


### TASK: TASK-0007 - Build basic documentation and connect the link

- ID: TASK-0007
- Status: not-started
- Priority: P1
- Owner: unassigned
- Created: 2026-01-17
- Files: docs/README.md, README.md, app/web/**, app/lib/widgets/header.dart
- Description: |
  Create a minimal documentation landing page (docs/README.md) with installation, running, and basic usage instructions. Wire the web UI documentation link to this local docs page.
- Acceptance Criteria: |
  - `docs/README.md` exists with Getting Started and API endpoints overview.
  - Web UI documentation link opens the local docs (or an in-app docs view).
- Tests/Commands: |
  - `ls docs && sed -n '1,40p' docs/README.md`
  - Open the web UI and click the docs link to confirm navigation.
- Notes: |
  - Keep docs small and iterative; expand later.

