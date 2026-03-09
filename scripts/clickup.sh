#!/usr/bin/env bash
set -euo pipefail

CLICKUP_API_BASE="https://api.clickup.com/api/v2"
MAX_RETRIES=3
RETRY_DELAY=2

# --- helpers ---

usage() {
  cat <<'EOF'
Usage: clickup.sh <command> [args...]

Commands:
  workspaces                   List all workspaces (teams)
  spaces <team_id>             List spaces in a workspace
  folders <space_id>           List folders in a space
  lists <folder_id>            List lists in a folder
  folderless-lists <space_id>  List lists not in any folder
  tasks <list_id> [page]       List tasks in a list (page starts at 0)
  task <task_id>               Get a single task detail
  comments <task_id>           Get comments on a task
  members <task_id>            Get members assigned to a task
  help                         Show this help message
EOF
}

die() {
  echo "Error: $1" >&2
  exit 1
}

require_arg() {
  if [[ -z "${2:-}" ]]; then
    die "Command '$1' requires an argument. Run with 'help' for usage."
  fi
}

api_get() {
  local endpoint="$1"
  local url="${CLICKUP_API_BASE}${endpoint}"
  local attempt=0
  local http_code body tmp

  tmp=$(mktemp)
  trap "rm -f '$tmp'" RETURN

  while (( attempt < MAX_RETRIES )); do
    http_code=$(curl -s -o "$tmp" -w '%{http_code}' \
      -H "Authorization: ${CLICKUP_API_KEY}" \
      -H "Content-Type: application/json" \
      "$url")

    if [[ "$http_code" == "429" ]]; then
      attempt=$((attempt + 1))
      if (( attempt < MAX_RETRIES )); then
        sleep "$RETRY_DELAY"
        RETRY_DELAY=$((RETRY_DELAY * 2))
        continue
      fi
    fi
    break
  done

  body=$(<"$tmp")

  if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
    echo "$body"
  else
    echo "{\"error\": true, \"http_status\": $http_code, \"body\": $body}" >&2
    exit 1
  fi
}

# --- main ---

command="${1:-help}"
shift || true

if [[ "$command" == "help" || "$command" == "--help" || "$command" == "-h" ]]; then
  usage
  exit 0
fi

if [[ -z "${CLICKUP_API_KEY:-}" ]]; then
  die "CLICKUP_API_KEY environment variable is not set."
fi

case "$command" in
  workspaces)
    api_get "/team"
    ;;
  spaces)
    require_arg "spaces" "${1:-}"
    api_get "/team/$1/space?archived=false"
    ;;
  folders)
    require_arg "folders" "${1:-}"
    api_get "/space/$1/folder?archived=false"
    ;;
  lists)
    require_arg "lists" "${1:-}"
    api_get "/folder/$1/list?archived=false"
    ;;
  folderless-lists)
    require_arg "folderless-lists" "${1:-}"
    api_get "/space/$1/list?archived=false"
    ;;
  tasks)
    require_arg "tasks" "${1:-}"
    local_page="${2:-0}"
    api_get "/list/$1/task?page=${local_page}&subtasks=true&include_closed=true"
    ;;
  task)
    require_arg "task" "${1:-}"
    api_get "/task/$1?include_subtasks=true"
    ;;
  comments)
    require_arg "comments" "${1:-}"
    api_get "/task/$1/comment"
    ;;
  members)
    require_arg "members" "${1:-}"
    api_get "/task/$1/member"
    ;;
  *)
    die "Unknown command: $command. Run with 'help' for usage."
    ;;
esac
