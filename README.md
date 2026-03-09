# ClickUp Skill for Claude Code

A read-only ClickUp integration that works as both:

1. **A standalone CLI wrapper** around the [ClickUp API v2](https://clickup.com/api/) — a shell script you can call directly from your terminal
2. **A Claude Code slash command** (`/clickup`) — lets Claude browse your ClickUp workspaces, tasks, and comments conversationally

No MCP server needed. Authentication uses a ClickUp Personal API Token via environment variable. All API calls are **read-only** (GET requests only).

## How It Works

```
You ──► /clickup tasks 12345 ──► Claude Code ──► clickup.sh ──► ClickUp API v2
                                      │                              │
                                      │◄── formatted markdown ◄──── JSON
```

The shell script (`scripts/clickup.sh`) handles authentication, HTTP requests, error handling, and rate-limit retries. Claude reads the raw JSON and presents it as formatted tables, task details, and comment threads.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- A ClickUp account with a [Personal API Token](https://app.clickup.com/settings/apps)
- `curl` available in your shell

## Quick Setup

```bash
git clone https://github.com/Teapot-Agency/clickup-skill.git
cd clickup-skill
bash setup.sh
```

The setup script will:
1. Prompt for your ClickUp Personal API Token (if not already set)
2. Add `CLICKUP_API_KEY` to `~/.zshrc`
3. Symlink the command to `~/.claude/commands/clickup.md`
4. Test API connectivity

## Manual Setup

1. Set your API key:
   ```bash
   export CLICKUP_API_KEY="pk_YOUR_TOKEN_HERE"
   # Add to ~/.zshrc for persistence
   ```

2. Make the script executable:
   ```bash
   chmod +x scripts/clickup.sh
   ```

3. Symlink the command (for Claude Code integration):
   ```bash
   mkdir -p ~/.claude/commands
   ln -sf "$(pwd)/clickup.md" ~/.claude/commands/clickup.md
   ```

## Usage

### As a Claude Code Skill

In any Claude Code session:

```
/clickup                          # Interactive browse mode (drill down)
/clickup workspaces               # List all workspaces
/clickup spaces <team_id>         # List spaces in a workspace
/clickup folders <space_id>       # List folders in a space
/clickup lists <folder_id>        # List lists in a folder
/clickup folderless-lists <sid>   # Lists not inside a folder
/clickup tasks <list_id>          # List tasks (paginated, 100/page)
/clickup tasks <list_id> 1        # Page 2 of tasks
/clickup task <task_id>           # View task detail with subtasks
/clickup comments <task_id>       # View task comments
/clickup members <task_id>        # View task members
/clickup https://app.clickup.com/t/TASK_ID  # Open task from URL
```

Claude formats the JSON output as markdown tables, structured task details, and quoted comments.

### As a Standalone CLI Tool

```bash
# List workspaces
bash scripts/clickup.sh workspaces

# Get task detail
bash scripts/clickup.sh task 869bv8r0t

# Get comments
bash scripts/clickup.sh comments 869bv8r0t

# Show help
bash scripts/clickup.sh help
```

Returns raw JSON — pipe to `jq` for formatting:

```bash
bash scripts/clickup.sh workspaces | jq '.teams[].name'
```

## Pre-Approve Permissions

To avoid permission prompts on every `/clickup` call in Claude Code, add to `~/.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "Bash(bash *clickup.sh *)"
    ]
  }
}
```

## ClickUp API v2 Endpoints

All requests are **read-only** (GET). No data is created, modified, or deleted.

| Command | API Endpoint | Description |
|---------|-------------|-------------|
| `workspaces` | `GET /team` | List all workspaces (teams) |
| `spaces` | `GET /team/{id}/space` | List spaces in a workspace |
| `folders` | `GET /space/{id}/folder` | List folders in a space |
| `lists` | `GET /folder/{id}/list` | List lists in a folder |
| `folderless-lists` | `GET /space/{id}/list` | Lists not in any folder |
| `tasks` | `GET /list/{id}/task` | List tasks (100/page, includes subtasks) |
| `task` | `GET /task/{id}` | Single task with subtasks and attachments |
| `comments` | `GET /task/{id}/comment` | Task comments |
| `members` | `GET /task/{id}/member` | Task members |

### Rate Limiting

The script automatically retries on HTTP 429 (rate limited) with exponential backoff, up to 3 attempts.

### Error Handling

- Missing `CLICKUP_API_KEY` — exits with error message
- Missing required arguments — shows usage for the command
- HTTP errors — returns status code and response body as JSON on stderr

## Architecture

```
clickup-skill/
├── scripts/
│   └── clickup.sh      # Shell wrapper for ClickUp API v2 (curl + auth)
├── clickup.md           # Claude Code command definition (symlinked to ~/.claude/commands/)
├── setup.sh             # Installation script
└── README.md
```

### Authentication

Uses a ClickUp [Personal API Token](https://app.clickup.com/settings/apps) passed via the `CLICKUP_API_KEY` environment variable. The token is sent as an `Authorization` header on every request.

## License

MIT
