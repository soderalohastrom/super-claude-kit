#!/bin/bash
# Helper script to log current tasks
# Usage: ./log-task.sh <status> <content>
# Status: in_progress, pending, completed

set -euo pipefail

TASK_FILE=".claude/current_tasks.log"

if [ $# -lt 2 ]; then
  echo "Usage: $0 <status> <content>" >&2
  exit 1
fi

STATUS="$1"
shift
CONTENT="$*"

# Create log directory if needed
mkdir -p .claude

# Append to log (format: status|content)
echo "$STATUS|$CONTENT" >> "$TASK_FILE"
