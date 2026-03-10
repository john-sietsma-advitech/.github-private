---
name: copilot
description: GitHub Copilot instructions index with links to language and topic guidelines
---

# GitHub Copilot Instructions

This document is the index of GitHub Copilot instructions. Specific technology and topic areas are organised into separate files:

## Core Instructions

- **[Language & Documentation Standards](language.instructions.md)** - Australian English spelling, documentation style, and RFC2119 keywords
- **[General Infrastructure Standards](general.instructions.md)** - Version control, CI/CD, containerisation, and general practices
- **[Software Engineering Principles](swe.instructions.md)** - SOLID, DRY, and other high-level software engineering principles

## Technology-Specific Instructions

- **[Python Development](python.instructions.md)** - FastAPI, pytest, ruff, UV package management, and type hints
- **[TypeScript & React Development](typescript-react.instructions.md)** - React 18, Hooks, PrimeReact, Vite, and ESLint configuration
- **[PowerShell Scripting](powershell.instructions.md)** - PSScriptAnalyzer linting, approved verbs, and best practices
- **[CSS Layout & Styling](css-styling.instructions.md)** - Flexbox best practices, relative units, and responsive design

## Agents

Reusable chat agents that automate the dev workflow. Located in `.github/agents/`:

- **[dev-flow.task](../agents/dev-flow.task.agent.md)** - Create a feature branch and specification from a task description or Jira handoff
- **[dev-flow.jira-task](../agents/dev-flow.jira-task.agent.md)** - Fetch a Jira ticket and hand off to `@dev-flow.task`
- **[dev-flow.clarify](../agents/dev-flow.clarify.agent.md)** - Identify ambiguities in the current feature spec and encode answers back into it
- **[dev-flow.review](../agents/dev-flow.review.agent.md)** - Review code changes against engineering principles and language-specific standards
- **[dev-flow.pr](../agents/dev-flow.pr.agent.md)** - Create or update a Bitbucket pull request with a conventional commit title and change summary

Typical workflow: `@dev-flow.jira-task` → `@dev-flow.task` → `@dev-flow.clarify` → _(implement)_ → `@dev-flow.review` → `@dev-flow.pr`

## Code Quality & Linting

**MUST** lint and type-check all code changes before considering them complete. Linting and type checking are non-negotiable quality gates.

See the language-specific instruction files for the exact tools and commands required for each language.

## PowerShell & Terminal Output

When executing PowerShell scripts in agents or tools:

- **Avoid complex multi-line scripts with arrays** - Scripts with array operations (`$result += ...`) and try/catch blocks may not display output reliably
- **Use simple `Write-Host` statements** - For user-facing output, prefer simple individual `Write-Host` calls over building result arrays
- **Write to files for debugging** - When complex operations need output, write to a file and read it back instead of relying on terminal buffer
- **Test output patterns** - Verify that output displays correctly before using in production agents

**Example Pattern:**

```powershell
# ❌ Avoid - Output may not display
$result = @()
$result += "Line 1"
$result += "Line 2"
$result | ConvertTo-Json

# ✅ Prefer - Output displays reliably
Write-Host "Line 1"
Write-Host "Line 2"
```
