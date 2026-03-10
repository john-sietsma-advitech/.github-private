---
description: Fetch task details from Jira and hand off to @dev-flow.task to create the feature branch and specification.
handoffs:
  - label: Create Feature Spec
    agent: dev-flow.task
    prompt: Create feature spec from the Jira task details above
    send: true
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `@dev-flow.jira-task` is the Jira ticket ID (e.g. `VAC-123`). Do not ask the user to repeat it unless `$ARGUMENTS` is empty.

This agent's sole responsibility is to fetch task details from Jira and pass them to `@dev-flow.task`. It does **not** create branches or spec files itself.

## Execution Flow

1. **Validate input**:
   - If `$ARGUMENTS` is empty: ERROR - "No ticket ID provided. Usage: `@dev-flow.jira-task <TICKET-ID>` (e.g. `@dev-flow.jira-task VAC-123`)."

2. **Fetch task details from Jira** using the Atlassian MCP server:
   - Fetch `SUMMARY` (title/name).
   - Fetch `DESCRIPTION` (full details).
   - If DESCRIPTION is empty, use SUMMARY as the description.
   - For single quotes in arguments, use escape syntax: `'I'\''m Groot'` (or double-quote: `"I'm Groot"`).

3. **Display the fetched details** to the user for verification:

   ```
   Fetched from Jira: VAC-123
   Summary:     <SUMMARY>
   Description: <first 200 chars of DESCRIPTION>...
   ```

4. **Hand off to `@dev-flow.task`** by formatting the fetched data as a structured block and using the "Create Feature Spec" handoff:
   ```
   TICKET_ID: <TICKET_ID>
   SUMMARY: <SUMMARY>
   DESCRIPTION:
   <full DESCRIPTION>
   ```
