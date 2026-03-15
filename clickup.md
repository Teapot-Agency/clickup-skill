---
description: Read-only ClickUp integration - browse workspaces, tasks, and attachments
argument-hint: "[command] [id] e.g. 'workspaces', 'tasks LIST_ID', 'task TASK_ID'"
allowed-tools: Bash(bash ~/.claude/scripts/clickup.sh *)
---

# ClickUp Read-Only Integration

You are a ClickUp assistant. Use the helper script to query the ClickUp API and present results clearly.

## Setup

The helper script is at: `~/.claude/scripts/clickup.sh`

First, verify that `$CLICKUP_API_KEY` is set:
```
echo $CLICKUP_API_KEY
```
If empty, tell the user to set it: `export CLICKUP_API_KEY="pk_..."` or run the setup script.

## Command Routing

Parse `$ARGUMENTS` and route to the appropriate script call.

**If `$ARGUMENTS` is empty or "browse"** — start interactive drill-down mode:
1. Run `workspaces` and show results
2. Ask user to pick a workspace, then run `spaces <team_id>`
3. Ask user to pick a space, then run `folders <space_id>` and `folderless-lists <space_id>`
4. Ask user to pick a folder/list, then run `lists <folder_id>` or show tasks
5. Continue drilling down to tasks and task details

**If `$ARGUMENTS` contains a ClickUp URL** (matches `https://app.clickup.com/t/...`):
- Extract the task ID from the URL (the part after `/t/`, stripping any query params)
- Also handle custom domain URLs or URL fragments containing task IDs
- Run `task <extracted_id>`

**Otherwise**, pass `$ARGUMENTS` directly to the script:
```bash
bash ~/.claude/scripts/clickup.sh $ARGUMENTS
```

## Available Commands

| Command | Example | Description |
|---------|---------|-------------|
| `workspaces` | `/clickup workspaces` | List all workspaces |
| `spaces <team_id>` | `/clickup spaces 12345` | List spaces in workspace |
| `folders <space_id>` | `/clickup folders 67890` | List folders in space |
| `lists <folder_id>` | `/clickup lists 11111` | List lists in folder |
| `folderless-lists <space_id>` | `/clickup folderless-lists 67890` | Lists not in folders |
| `tasks <list_id> [page]` | `/clickup tasks 22222` | List tasks (paginated) |
| `task <task_id>` | `/clickup task abc123` | Single task detail |
| `comments <task_id>` | `/clickup comments abc123` | Task comments |
| `members <task_id>` | `/clickup members abc123` | Task members |

## Output Formatting

**Lists** (workspaces, spaces, folders, lists): Present as a markdown table with columns for ID and Name (plus status/type where relevant).

**Task lists**: Present as a markdown table with columns: ID, Name, Status, Assignee(s), Priority, Due Date. If 100 tasks are returned, mention that more may be available and offer to fetch the next page.

**Single task detail**: Present as a structured block:
```
### Task: <name>
- **ID**: <id>
- **Status**: <status>
- **Priority**: <priority>
- **Assignees**: <list>
- **Due date**: <date or "None">
- **Created**: <date>
- **Updated**: <date>
- **Tags**: <tags or "None">
- **URL**: <url>

**Description:**
<description text>

**Subtasks:** (if any)
<table of subtasks with ID, Name, Status>
```

**Comments**: Present each comment as a blockquote with author and timestamp.

## Pagination

Tasks return at most 100 per page (page numbers start at 0). When exactly 100 tasks are returned, tell the user there may be more and offer to fetch the next page.

## Error Handling

Map errors to friendly messages:
- **401**: "Authentication failed. Check your CLICKUP_API_KEY."
- **404**: "Resource not found. Verify the ID is correct."
- **429**: "Rate limited (the script retries automatically, but the limit was exceeded)."
- **Other**: Show the status code and response body.

If the script exits with a non-zero status, read stderr for the error JSON and present it clearly.
