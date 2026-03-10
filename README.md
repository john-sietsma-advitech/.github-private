# Dev Flow

Development workflow automation for GitHub Copilot — spec-driven task management, code review, and Bitbucket PR integration.

## Overview

Dev Flow provides a set of GitHub Copilot agents that automate the development workflow:

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
