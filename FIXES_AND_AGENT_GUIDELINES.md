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


### TASK: TASK-0008 - Fix Server Details 404s (metrics & containers)

- ID: TASK-0008
- Status: not-started
- Priority: P0
- Owner: unassigned
- Created: 2026-01-17
- Files: app/lib/features/servers/**, service-node/internal/api/server_handlers.go, service-node/cmd/serviced/main.go, tests/integration_test.py
- Description: |
  The Test Server details page shows DioException 404 errors for Current Metrics and Containers (see screenshot). Investigate the frontend request paths and backend routes/handlers, register missing routes, or fix response shapes.
- Acceptance Criteria: |
  - Metrics and Containers panels return 200 with JSON or an empty list rather than 404.
  - The UI displays metrics and container data or empty state instead of an error card.
- Tests/Commands: |
  - Reproduce with curl: `curl -i http://localhost:8080/api/v1/servers/<id>/metrics`
  - `curl -i http://localhost:8080/api/v1/servers/<id>/containers`
  - Run integration tests that assert 200/JSON responses for these endpoints.
- Notes: |
  - If DB schema or migrations are required, include migrations and update repository queries.


### TASK: TASK-0009 - Make Edit Server form persist and configure all options

- ID: TASK-0009
- Status: not-started
- Priority: P0
- Owner: unassigned
- Created: 2026-01-17
- Files: app/lib/features/servers/**, service-node/internal/api/servers_handler.go, service-node/internal/models/servers.go, service-node/internal/repository/servers_repository.go
- Description: |
  The Edit Server action currently does nothing. Implement full edit flow on frontend and backend so users can modify all server properties (name, hostname, port, folder, tags, description, auth settings).
- Acceptance Criteria: |
  - Edit Server UI saves changes and the backend persists them.
  - After editing, the server detail page reflects updated fields immediately.
- Tests/Commands: |
  - Use the UI to edit a server and verify via `curl GET /api/v1/servers/{id}` the fields updated.
  - Add integration test for server update (PATCH/PUT returns 200 and persisted fields).
- Notes: |
  - Ensure validation and clear error messaging for invalid inputs.


### TASK: TASK-0010 - Add per-server auth configuration (password or SSH key)

- ID: TASK-0010
- Status: not-started
- Priority: P0
- Owner: unassigned
- Created: 2026-01-17
- Files: service-node/internal/models/servers.go, service-node/internal/api/servers_handler.go, migrations/*.sql, app/lib/features/servers/**, tests/integration_test.py
- Description: |
  Extend server model/API/UI to support selecting an authentication method per server (PASSWORD or SSH_KEY) and storing credentials accordingly (password or reference to stored key credential).
- Acceptance Criteria: |
  - API and DB store `auth_method` and `auth_reference` (or similar) for servers.
  - UI allows selecting method and entering password or selecting a key from stored credentials.
  - Integration tests cover creating/updating servers with both auth methods.
- Tests/Commands: |
  - `curl -X POST /api/v1/servers -d '{... "auth_method":"PASSWORD","password":"..."}'`
  - `curl -X POST /api/v1/servers -d '{... "auth_method":"SSH_KEY","key_id":"..."}'`
- Notes: |
  - Private key storage must be secure; treat secrets carefully and mark required encryption/ACLs for production.


### TASK: TASK-0011 - Implement key management (generate, store, associate, deploy)

- ID: TASK-0011
- Status: not-started
- Priority: P0
- Owner: unassigned
- Created: 2026-01-17
- Files: service-node/internal/api/keys_handler.go, service-node/internal/repository/keys_repository.go, app/lib/features/settings/keys/**, tests/integration_test.py
- Description: |
  Provide key-pair generation (RSA/ED25519), secure private key storage, a UI to view/manage keys, associate keys with servers, and a server-side endpoint to deploy public keys to a server via SSH.
- Acceptance Criteria: |
  - Create/list/delete keys via API/UI.
  - Generate key pairs server-side and return public key for download; private key stored encrypted or downloadable once (document security tradeoffs).
  - Associate keys with servers and trigger a deploy action which attempts to add the public key to the server's `authorized_keys` (returns success/failure and logs).
- Tests/Commands: |
  - `curl -X POST /api/v1/keys/generate` to create a keypair.
  - `curl -X POST /api/v1/servers/{id}/keys/{key_id}/deploy` to deploy.
- Notes: |
  - Consider using a background job for deploy operations and provide operation status endpoints.


### TASK: TASK-0012 - Tagging, folders, quick filtering, and Unknown category

- ID: TASK-0012
- Status: not-started
- Priority: P0
- Owner: unassigned
- Created: 2026-01-17
- Files: service-node/internal/models/servers.go, service-node/internal/api/servers_handler.go, app/lib/features/servers/**, app/lib/features/servers/list.dart, tests/integration_test.py
- Description: |
  Add server tags and folder categorization, implement text-based quick filtering (search across tags/name/description/folder), and introduce an "Unknown" status for servers never connected. The Unknown status should only appear in the status selector if at least one server qualifies.
- Acceptance Criteria: |
  - Servers can be assigned tags and folders via UI/API.
  - Server list supports typing a quick filter that matches tags, name, description, or folder.
  - An "Unknown" status group is shown only when one or more servers have never connected.
- Tests/Commands: |
  - Create servers with tags and folders, then use UI filter and verify results.
  - `curl GET /api/v1/servers?filter=text` returns filtered list.
- Notes: |
  - Consider indexing/tag storage format (simple comma-separated tags or normalized tags table) depending on expected scale.

