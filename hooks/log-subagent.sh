#!/bin/bash
# Log sub-agent completion and results
# Usage: ./log-subagent.sh <type> <summary>
# Types: Explore, Plan, general-purpose, architecture-explorer, database-navigator, agent-developer, github-issue-tracker, etc.

set -euo pipefail

SUBAGENT_LOG=".claude/subagent_results.log"
TIMESTAMP=$(date +%s)

if [ $# -lt 2 ]; then
  echo "Usage: $0 <type> <summary>" >&2
  exit 1
fi

AGENT_TYPE="$1"
shift
SUMMARY="$*"

# Create log directory if needed
mkdir -p .claude

# Append to log (format: timestamp,type,summary)
echo "$TIMESTAMP,$AGENT_TYPE,$SUMMARY" >> "$SUBAGENT_LOG"

echo "✓ Sub-agent logged: $AGENT_TYPE" >&2
