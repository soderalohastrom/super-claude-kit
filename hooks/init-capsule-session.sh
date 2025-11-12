#!/bin/bash
# Initialize capsule session tracking
# Called from SessionStart hook

set -euo pipefail

SESSION_START_FILE=".claude/session_start.txt"
MESSAGE_COUNT_FILE=".claude/message_count.txt"
FILE_LOG=".claude/session_files.log"
TASK_FILE=".claude/current_tasks.log"
SUBAGENT_LOG=".claude/subagent_results.log"
DISCOVERY_LOG=".claude/session_discoveries.log"
SNAPSHOT_FILE=".claude/last_snapshot.txt"

# Create .claude directory
mkdir -p .claude

# Set session start time
date +%s > "$SESSION_START_FILE"

# Reset message count
echo "0" > "$MESSAGE_COUNT_FILE"

# Clear file log (start fresh each session)
> "$FILE_LOG"

# Clear task log (start fresh each session)
> "$TASK_FILE"

# Clear sub-agent log (start fresh each session)
> "$SUBAGENT_LOG"

# Clear discovery log (start fresh each session)
> "$DISCOVERY_LOG"

# Initialize git snapshot for change detection
git status --porcelain 2>/dev/null > "$SNAPSHOT_FILE" || touch "$SNAPSHOT_FILE"

echo "✓ Capsule session initialized" >&2
