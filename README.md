# Dev Flow

Development workflow automation for GitHub Copilot — spec-driven task management, code review, and Bitbucket PR integration.

## Overview

Dev Flow provides a set of GitHub Copilot agents and supporting scripts that automate the development workflow:

- Create feature branches and spec files from Jira tickets or plain descriptions
- Clarify and refine specs before implementation
- Review code changes against engineering standards
- Create Bitbucket pull requests with conventional commit titles

These agents are defined in this `.github-private` repository and are automatically available to all members of the organisation in GitHub Copilot Chat — no installation required.

## Agents

Invoke agents in GitHub Copilot Chat using `@dev-flow.<name>`.

| Agent         | Command                        | Purpose                                                                                    |
| ------------- | ------------------------------ | ------------------------------------------------------------------------------------------ |
| **Jira Task** | `@dev-flow.jira-task VAC-123`  | Fetch a Jira ticket and hand off to `@dev-flow.task`                                       |
| **Task**      | `@dev-flow.task <description>` | Create feature branch and specification from a task description or Jira handoff            |
| **Clarify**   | `@dev-flow.clarify`            | Ask targeted clarification questions about underspecified areas in your spec               |
| **Review**    | `@dev-flow.review`             | Review code changes against best practices, engineering principles, and language standards |
| **PR**        | `@dev-flow.pr`                 | Create or update a Bitbucket pull request with conventional commit format and summary      |

## Workflow

**With Jira:**

```
1. @dev-flow.jira-task VAC-123   — fetch ticket, hand off to task agent
2. @dev-flow.task                — create branch + spec
3. @dev-flow.clarify             — refine spec
4. Implement feature
5. @dev-flow.review              — review changes
6. @dev-flow.pr                  — create or update PR
```

**Without Jira:**

```
1. @dev-flow.task Implement OAuth2 login   — create branch + spec from description
2. @dev-flow.clarify                       — refine spec
3. Implement feature
4. @dev-flow.review                        — review changes
5. @dev-flow.pr                            — create or update PR
```

## Setup

### Prerequisites

- GitHub Copilot with organisation-level custom agents enabled (`github.copilot.chat.organizationCustomAgents.enabled: true` in VS Code settings)
- PowerShell 7+ installed on each developer machine
- A `docs/specs/` directory in each project repo (created automatically by `@dev-flow.task` on first use)

### Jira / Bitbucket

1. Install the [Atlassian MCP server](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/) for Jira integration (`@dev-flow.jira-task`).
2. [Generate an Atlassian API token](https://id.atlassian.com/manage-profile/security/api-tokens) with `pullrequest:read` and `pullrequest:write` permissions for Bitbucket PR creation.

Credentials are resolved in order: environment variables → `~/.atlassian`:

```
ATLASSIAN_API_KEY=<API_KEY>
ATLASSIAN_EMAIL=<EMAIL>   # optional — defaults to git config user.email
```

## Scripts

The scripts in this repo are standalone command-line utilities. The agents no longer depend on them — all workflow logic is embedded directly in the agent instructions. Copy scripts into a project repo only if you want them as manual tools.

| Script                    | Description                                                           |
| ------------------------- | --------------------------------------------------------------------- |
| `create-task-spec.ps1`    | Create a task branch and spec file from a ticket ID and summary       |
| `create-pr.ps1`           | Create a Bitbucket pull request via API                               |
| `check-prerequisites.ps1` | Verify the current branch has a spec file; output paths               |
| `rebase-onto.ps1`         | Rebase the current branch onto a target using the recorded fork point |
| `common.ps1`              | Shared utility functions (sourced by other scripts)                   |

## create-pr.ps1

Standalone script for creating a Bitbucket pull request. Can be used directly from the command line.

### Usage

```powershell
.\scripts\create-pr.ps1 `
  -Title        "feat: add login page" `
  -Description  "## Summary..." `
  -TargetBranch main
```

### Credential resolution (in order)

1. Environment variables: `ATLASSIAN_API_KEY`, `ATLASSIAN_EMAIL`
2. File: `~/.atlassian`

File format:

```
ATLASSIAN_API_KEY=<api_key>
ATLASSIAN_EMAIL=<email>        # optional — defaults to git config user.email
```

### Exit codes

| Code | Meaning                                                            |
| ---- | ------------------------------------------------------------------ |
| 0    | Success — PR created                                               |
| 1    | Fatal error (missing required parameter, bad branch, push failure) |
| 2    | Non-fatal — credentials missing or API error; fallback URL printed |

## rebase-onto.ps1

Use this script after the base branch of your feature has been squash-merged into `main`
(or another target). Because squash-merge rewrites history, a plain `git rebase origin/main`
will try to replay every commit including those from the base branch. `rebase-onto.ps1` reads
the fork point SHA recorded in the spec file at branch-creation time and runs:

```
git rebase --onto origin/<target> <fork-point>
```

This replays only the commits unique to your branch, correctly landing them on the new target.

### Usage

```powershell
# Rebase onto main (default)
.\scripts\rebase-onto.ps1

# Rebase onto a different target
.\scripts\rebase-onto.ps1 -TargetBranch develop
```

### Requirements

The current branch's spec file (`docs/specs/<branch-name>.md`) MUST contain a `**Fork Point**`
header field. This is recorded automatically by `create-task-spec.ps1` when the branch is
created. If missing, add it manually:

```markdown
**Fork Point**: `<SHA>`
```

where `<SHA>` is the output of `git rev-parse <base-branch>` at the time the feature branch
was created.

### Conflict resolution

`rebase-onto.ps1` automatically resolves `UD` conflicts — files deleted in `HEAD` but modified
in the rebased commit. These are typically spec files that exist on the feature branch but not
on `main`. Only `UD`-status entries are auto-resolved; any other conflict type requires manual
resolution.

## Templates

| Template                     | Description                                       |
| ---------------------------- | ------------------------------------------------- |
| `templates/spec-template.md` | Spec file template used by `create-task-spec.ps1` |
