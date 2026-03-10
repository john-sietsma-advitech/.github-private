---
name: dev-flow.task
description: Create a feature branch and specification from a task description, or from structured input handed off by @dev-flow.jira-task.
argument-hint: "<TICKET-ID> <summary>  or  plain task description"
target: vscode
tools:
  [
    "execute/runInTerminal",
    "read/readFile",
    "edit/editFiles",
    "search/fileSearch",
  ]
handoffs:
  - label: Clarify Feature Requirements
    agent: dev-flow.clarify
    prompt: Clarify feature requirements
    send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

This agent creates a feature branch and specification file. It accepts input in two forms:

- **Structured** (handed off from `@dev-flow.jira-task`):
  ```
  TICKET_ID: VAC-123
  SUMMARY: Add user authentication
  DESCRIPTION: <full task description>
  ```
- **Plain description** (direct use): a free-text description from which a `TASK-YYYYMMDD-<slug>` ID is auto-generated.

Read `README.md` and `.github/instructions/copilot-instructions.md` to understand the project structure, coding standards, and best practices.

## Execution Flow

1. **Parse input**:
   - If `$ARGUMENTS` begins with `TICKET_ID:`, parse the structured format:
     - Extract `TICKET_ID`, `SUMMARY`, and `DESCRIPTION` fields.
   - Otherwise, treat `$ARGUMENTS` as a plain description:
     - Extract a brief `SUMMARY` (first sentence or ~5-7 words).
     - Generate a unique `TICKET_ID`:
       - Format: `TASK-YYYYMMDD-<slug>` where slug is derived from the first 4–5 words of the SUMMARY.
       - Example: `TASK-20260223-add-user-authentication`
       - Slug: lowercase, alphanumeric + hyphens only.
   - If input is empty: ERROR - "No task description provided. Usage: `@dev-flow.task <description>` or hand off from `@dev-flow.jira-task`."

2. **Generate branch name and check for conflicts**:

   a. Determine the branch prefix from the nature of the work (refer to `.github/instructions/general.instructions.md` for the authoritative list):
   - `feature/` — new features or capabilities (default if unclear)
   - `bugfix/` — bug fixes
   - `hotfix/` — urgent production fixes
   - `refactor/` — code restructuring without behaviour change
   - `chore/` — maintenance tasks (dependencies, configs, cleanup)
   - `docs/` — documentation-only changes
   - `test/` — adding or updating tests
   - `ci/` — CI/CD pipeline changes
   - `release/` — release preparation

   Infer the prefix from SUMMARY/DESCRIPTION keywords (e.g. "fix", "bug" → `bugfix/`; "update deps" → `chore/`; "document" → `docs/`). Default to `feature/` when ambiguous.

   b. Create branch name from the inferred prefix, TICKET_ID, and SUMMARY:
   - Format: `<prefix>/<TICKET_ID>-<slug>`
   - Slug: lowercase, alphanumeric + hyphens, no spaces or special chars.
   - Examples: `feature/VAC-123-add-user-authentication`, `bugfix/VAC-456-fix-login-redirect`, `chore/TASK-20260223-update-dependencies`

   b. **Capture the current (base) branch BEFORE any git network operations**:

   ```bash
   git rev-parse --abbrev-ref HEAD
   ```

   Store the result as `BASE_BRANCH`. This is the branch the new branch will be created from. Do this first so that subsequent `git fetch` activity cannot affect which commit is used as the base.

   c. Fetch remote branches:

   ```bash
   git fetch --all --prune
   ```

   d. If the target branch already exists, offer to switch to it instead of creating a new one.

   e. **Spec template structure**: Use the following template when creating the spec file, substituting all placeholders with actual values:

   ```markdown
   # Feature Specification: <SUMMARY>

   **Feature Branch**: `<BRANCH_NAME>`
   **Created**: <YYYY-MM-DD>
   **Base Branch**: `<BASE_BRANCH>`
   **Fork Point**: `<FORK_POINT_SHA>`
   **Status**: Draft
   **Input**: User description: "<DESCRIPTION>"

   ## User Story - <Brief Title>

   <Describe this user journey in plain language>

   ## Functional Requirements

   <List testable requirements derived from the user story. Each item must be unambiguous and verifiable.>

   - [ ] Requirement 1
   - [ ] Requirement 2

   ## Assumptions

   <Document any defaults or inferred decisions made during spec generation.>

   - Assumption 1

   ## Tasks

   - Include exact file paths in descriptions

   - [ ] Task 1 - <Title>: <Brief description>
   - [ ] Task 2 - <Title>: <Brief description>

   ## Documentation

   <Describe the documentation changes required.>

   ## Testing

   > **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

   - [ ] Unit test in tests/test_<name>.py

   ## Notes

   - Verify tests fail before implementing
   - Commit using conventional commits after each task or logical group
   ```

   f. Present confirmation to user, including the base branch so the user can verify it is correct:

   ```
   Ready to create branch?
   Branch:    feature/VAC-123-add-user-authentication
   Based on:  feature/my-current-branch
   Spec file: docs/specs/VAC-123-add-user-authentication.md

   Reply 'yes' to proceed, or 'no' to cancel.
   ```

   _(The `Branch:` line MUST reflect the inferred prefix, e.g. `bugfix/` or `chore/` as appropriate.)_

   g. After confirmation, run the following steps:

   1. **Create the branch** from `BASE_BRANCH`:
      ```bash
      git checkout -b <branch-name> <BASE_BRANCH>
      ```
   2. **Record the fork point** (current tip of `BASE_BRANCH`):
      ```bash
      git rev-parse <BASE_BRANCH>
      ```
      Store as `FORK_POINT`.
   3. **Create the spec directory** if it doesn't exist:
      ```powershell
      New-Item -ItemType Directory -Path docs/specs -Force | Out-Null
      ```
   4. **Write the spec file** to `docs/specs/<feature-name>.md` using the template from step 2.e, substituting all placeholders. Populate `**Base Branch**` with `BASE_BRANCH`, `**Fork Point**` with `FORK_POINT`, and `**Created**` with today's date.

3. **Generate spec content**:
   1. Parse description - if empty, use SUMMARY as a minimal description.
   2. Extract key concepts: actors, actions, data, constraints.
   3. For unclear aspects:
      - Make informed guesses based on context and industry standards.
      - Only mark `[NEEDS CLARIFICATION: <question>]` when:
        - The choice materially impacts feature scope or user experience.
        - Multiple reasonable interpretations exist with different implications.
        - No reasonable default exists.
      - Prioritise clarifications by impact: scope > security/privacy > user experience > technical details.
   4. Fill User Story and Documentation sections.
      - If no clear user flow can be determined: ERROR - "Cannot determine user scenarios."
   5. Generate Functional Requirements - each requirement MUST be testable.
   6. Document assumptions for any unspecified details.

4. **Write spec file**: Write the completed specification to `SPEC_FILE` using the template structure, preserving section order and headings. The `**Base Branch**` and `**Fork Point**` header fields are populated during branch creation (step 2.g) — MUST NOT overwrite or blank them.

5. **MUST NOT** immediately start implementing code.

## Spec Generation Guidelines

1. **Make informed guesses**: Use context, industry standards, and common patterns to fill gaps.
2. **Document assumptions**: Record reasonable defaults in the Assumptions section.
3. **Prioritise clarifications**: scope > security/privacy > user experience > technical details.
4. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item.
5. **Common areas needing clarification** (only if no reasonable default exists):
   - Feature scope and boundaries (include/exclude specific use cases)
   - User types and permissions (if multiple conflicting interpretations are possible)
   - Security/compliance requirements (when legally or financially significant)

**Examples of reasonable defaults** (do not ask about these):

- Error handling: user-friendly messages with appropriate fallbacks.
- Integration patterns: RESTful APIs unless specified otherwise.
