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
New Tasks
-------------------------

(No pending tasks)

### TASK: TASK-0013 - Global credential pool

- ID: TASK-0013
- Status: not-started
- Priority: P0
- Owner: unassigned
- Created: 2026-01-18
- Files: app/lib/features/servers/pages/server_list_page.dart, app/lib/features/servers/providers/server_provider.dart, app/lib/features/settings/pages/settings_page.dart, service-node/internal/api/credential_handlers.go, service-node/internal/repository/credential_repository.go
- Description: |
  Implement a global credential pool so SSH keys and saved credentials are managed centrally. When adding or editing a server the UI should allow selecting an existing credential from the global pool. Adding a credential from a server flow should register it in the global pool. The pool must be encrypted/stored using existing vault mechanisms.
- Acceptance Criteria: |
  - Global Credentials page lists stored credentials (name, type, created_at)
  - Add credential flow stores credential in the global pool and returns an ID
  - Add/Edit Server dialogs allow selecting an existing credential from the global pool
  - Adding a credential from a server detail view registers it in the global pool
  - Stored credentials remain encrypted at rest (use vault)
  - Integration tests cover create/list/select flows
- Tests/Commands: |
  - cd /home/codex/server-monitoring && python3 tests/integration_test.py
  - Manual: Add credential in Settings > SSH Keys, then assign it to a server and verify connection/test succeeds
- Notes: |
  - Reuse existing key storage + vault encryption patterns
  - Update API to return credential IDs for selection

### TASK: TASK-0014 - Connect button on server page

- ID: TASK-0014
- Status: not-started
- Priority: P1
- Owner: unassigned
- Created: 2026-01-18
- Files: app/lib/features/servers/pages/server_list_page.dart, app/lib/features/servers/pages/server_detail_page.dart, app/lib/features/servers/providers/server_provider.dart, service-node/internal/api/server_handlers.go
- Description: |
  Add a prominent Connect button on server list cards and on each server's detail page when the server is not currently connected or has never connected. The button should trigger a connection test and provide immediate feedback (connecting, success, failure).
- Acceptance Criteria: |
  - Connect button visible on server cards for offline/never-connected servers
  - Connect button visible on server detail page when not connected
  - Clicking Connect runs the existing server connection/test API and shows status toast or inline indicator
  - Successful connection updates server status in the UI
  - Integration test for connection attempt and status update
- Tests/Commands: |
  - cd /home/codex/server-monitoring && python3 tests/integration_test.py
  - Manual: Click Connect on an offline server and observe status change or failure message
- Notes: |
  - Use existing server test connection API (service-node)

### TASK: TASK-0015 - Terminal interface using saved credential

- ID: TASK-0015
- Status: not-started
- Priority: P0
- Owner: unassigned
- Created: 2026-01-18
- Files: app/lib/features/servers/pages/server_detail_page.dart, app/lib/features/servers/widgets/terminal_widget.dart, app/lib/features/servers/providers/server_provider.dart, service-node/internal/api/ssh_handlers.go, service-node/internal/collector/docker.go
- Description: |
  Implement an in-browser terminal interface that leverages the server's selected saved credential to establish an SSH session. The terminal should be accessible from the server detail page via a Connect/Terminal button and reuse stored credentials from the global pool. The backend must proxy and broker the SSH session securely.
- Acceptance Criteria: |
  - Terminal button available on server detail pages for servers with an assigned credential
  - Terminal UI opens in a modal or dedicated route and shows an interactive shell
  - SSH session initiated using the saved credential (private key or password) and proxied via backend
  - Session logs/errors are visible to the user; private keys are never exposed in logs or responses
  - Integration test to open terminal, run a simple command (e.g., echo hello), and verify output
- Tests/Commands: |
  - cd /home/codex/server-monitoring && python3 tests/integration_test.py
  - Manual: Open Terminal on a server and run `echo hello` to verify a working shell
- Notes: |
  - Consider leveraging websocket-based pty proxy on the backend
  - Ensure vault encryption and careful handling of private keys; only the brokered backend process should access keys

