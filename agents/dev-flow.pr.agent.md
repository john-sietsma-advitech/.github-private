---
name: dev-flow.pr
description: Create a Bitbucket pull request with conventional commit title and concise change summary
argument-hint: "(optional) target branch or extra notes — runs on current feature branch"
target: vscode
tools: ["execute/runInTerminal", "read/readFile", "search/changes"]
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

Goal: Create a well-formatted pull request on Bitbucket with a conventional commit title and clear summary of changes.

Execution steps:

1. **Get current branch information**:
   - Run `git rev-parse --abbrev-ref HEAD` to get current branch name
   - Abort if on `main`, `master`, or `develop` — PRs must originate from a working branch
   - Warn (but do not abort) if the branch does not match a conventional prefix (`feature/`, `bugfix/`, `hotfix/`, `chore/`, `release/`, `docs/`, `test/`, `ci/`, `refactor/`) — ask the user to confirm they want to proceed
   - **Determine target (parent) branch** using the following strategy in order:
     1. Check the upstream tracking branch: `git rev-parse --abbrev-ref "HEAD@{upstream}"` — strip the `origin/` prefix to get the local branch name. **If the result equals the current branch name, treat this as no upstream and move to step 2.**
     2. If no upstream, check the spec file in `docs/specs/` matching the branch ticket ID for a recorded `Base Branch` field
     3. If no spec file, check `git branch -r` for known remote branches and identify the most likely parent (prefer `develop`, `main`, then `master`)
     4. As a last resort, fall back to `develop`, then `main`, then `master`
   - Store the result as `TARGET_BRANCH`

2. **Derive Bitbucket workspace and repository**:
   - Run `git remote get-url origin` to get the remote URL
   - Parse `workspace` and `repo` from the URL. Supported formats:
     - HTTPS: `https://bitbucket.org/<workspace>/<repo>.git` → strip `.git` suffix
     - SSH: `git@bitbucket.org:<workspace>/<repo>.git` → strip `.git` suffix
   - If parsing fails or remote is not a Bitbucket URL: ERROR — "Cannot determine Bitbucket workspace/repo from remote URL. Verify `git remote get-url origin` returns a valid Bitbucket URL."
   - Use the derived `$workspace` and `$repo` values in all subsequent API calls — never hardcode or guess these values

3. **Check if PR already exists**:
   - Run `scripts/find-pr.ps1 -SourceBranch <current_branch> -Json` to query for an existing open PR
   - Exit code 0 means a PR was found; parse the JSON output for `id`, `title`, and `url`
   - Exit code 1 means no PR exists — continue with creation flow (proceed to step 5)
   - If PR found: abort with the message "A PR already exists for this branch: <url>" and exit

4. **Suggest code review** (if not already run):
   - Before analysing changes, suggest running `@dev-flow.review` first to catch issues early
   - Display: "💡 Tip: Run `@dev-flow.review` before creating a PR to catch potential issues"
   - This is optional; continue with PR creation if user prefers

5. **Analyse changes**:
   - First verify the remote branch exists: `git ls-remote --exit-code origin $TARGET_BRANCH` — if this fails, warn and use `git log --oneline HEAD` with no diff stat
   - Run `git diff --stat origin/$TARGET_BRANCH...HEAD` to see changed files
   - Run `git log --oneline origin/$TARGET_BRANCH..HEAD` to see commits on this branch
   - Run `git diff --name-status origin/$TARGET_BRANCH...HEAD` to categorise changes (Added, Modified, Deleted)
   - Identify primary change areas (frontend, backend, infrastructure, documentation, etc.)

6. **Determine conventional commit type**:
   Based on the changes, select the most appropriate type:
   - **feat**: New feature or capability
   - **fix**: Bug fix
   - **chore**: Maintenance tasks (dependencies, configs, cleanup)
   - **refactor**: Code restructuring without behavior change
   - **docs**: Documentation only changes
   - **test**: Adding or updating tests
   - **ci**: CI/CD pipeline changes
   - **perf**: Performance improvements
   - **style**: Formatting, whitespace, linting

   If multiple types apply, choose the most significant user-facing change (feat > fix > refactor > chore).

7. **Generate PR title**:
   Format: `<type>: <short description>`

   Rules:
   - Use imperative mood ("Add feature" not "Adds feature" or "Added feature")
   - Keep under 72 characters
   - No period at the end
   - Be specific but concise
   - Extract from feature branch name or spec file if available

   Examples:
   - `feat: add user authentication with OAuth2`
   - `fix: resolve memory leak in audio processing`
   - `chore: consolidate Docker configuration files`
   - `refactor: migrate to composition API in Vue components`

8. **Generate PR description**:
   Structure:

   ```markdown
   ## Summary

   [2-3 sentence overview of what this PR does and why]

   ## Changes

   - [Key change 1 with file/component reference]
   - [Key change 2 with file/component reference]
   - [Key change 3 with file/component reference]

   ## Testing

   [How this was tested - reference spec acceptance criteria if available]

   ## Related

   - Jira: [VAC-XXX] (if applicable)
   - Spec: docs/specs/VAC-XXX-description.md (if applicable)
   ```

   Guidelines:
   - Focus on WHAT changed and WHY, not HOW (code review shows HOW)
   - Highlight user-facing changes first
   - Group related changes together with category headers
   - **IMPORTANT**: Add blank lines between category headers and bullet lists for proper markdown rendering
   - Keep total description under 500 words
   - Use bullet points for scannability
   - Reference specific files/components for context
   - If spec file exists in docs/specs/, reference completed tasks

9. **Present PR preview**:
   Show the user:

   ```
   Title: <generated title>

   Target Branch: <target branch>
   Source Branch: <current branch>

   Description:
   <generated description>

   Files Changed: <count> files (+<additions> -<deletions>)
   Commits: <count>
   ```

   Ask: "Ready to create this PR? Reply 'yes' to proceed, or provide feedback to adjust."

10. **Create PR** (after user confirmation):

    Call `scripts/create-pr.ps1` — it handles push, credential loading, API call, and manual fallback:

    ```powershell
    .\scripts\create-pr.ps1 `
      -Title         "<pr title>" `
      -Description   "<pr description>" `
      -TargetBranch  "<target branch>" `
      -SourceBranch  "<current branch>"
    ```

    The script:
    - Pushes the branch to origin (skip with `-NoPush`)
    - Loads credentials from `ATLASSIAN_API_KEY` / `ATLASSIAN_EMAIL` env vars, then `~/.atlassian`
    - Creates the PR via the Bitbucket API (POST)
    - On API failure: prints a manual creation link and exits with code 2 (non-fatal)

    Credential file format (`~/.atlassian`):

    ```
    ATLASSIAN_API_KEY=<api_key>
    ATLASSIAN_EMAIL=<email>        # optional — defaults to git config user.email
    ```

11. **Report completion** from script output:

- **On success** (exit code 0): Display the PR URL and suggest next steps (add reviewers, link to Jira)
- **On credential failure** (exit code 2, no API key): Show the fallback URL and instruct the user to set `ATLASSIAN_API_KEY`
- **On API failure** (exit code 2, API error): Show the fallback URL and the error detail printed by the script

## Behaviour Rules

- If on `main`, `master`, or `develop`, abort with a clear error
- If branch does not match a conventional prefix, warn and ask the user to confirm before proceeding
- If no changes detected, abort with helpful message
- If spec file exists in docs/specs/ (e.g., docs/specs/VAC-XXX-description.md), read it to understand feature context
- Tasks are embedded in the spec file, reference them in description
- Target branch is determined from the upstream tracking branch, spec file, or git history — `develop` is only used as a last resort fallback (see step 1). If `$ARGUMENTS` specifies a target branch, it overrides the detected value
- If user provides custom title in $ARGUMENTS, use it instead of generating
- If user provides custom description in $ARGUMENTS, append it to generated description
- **Always show preview before creating PR** (never auto-create without confirmation)
- **API errors are non-fatal**: Provide manual creation link instead of aborting
- Validate all credentials before attempting API call
- Handle auth failures with clear guidance on credential setup
- If git push fails, provide clear error and resolution steps
- Provide both automatic and manual creation paths for robustness
- Check for existing PR before creating to avoid duplicates

## Optional Enhancements

- Detect Jira ticket from branch name (e.g., `feature/VAC-123-description` → VAC-123)
- Auto-link to related PRs if branch references them in commits
- Suggest reviewers based on file ownership (CODEOWNERS if exists)
- Check if branch is up-to-date with target, warn if behind

Context for PR creation/update: $ARGUMENTS

```

```
