#!/bin/bash
# Log session discoveries and key insights
# Usage: ./log-discovery.sh <category> <discovery>
# Categories: pattern, insight, decision, architecture, bug, optimization

set -euo pipefail

DISCOVERY_LOG=".claude/session_discoveries.log"
TIMESTAMP=$(date +%s)

if [ $# -lt 2 ]; then
  echo "Usage: $0 <category> <discovery>" >&2
  exit 1
fi

CATEGORY="$1"
shift
DISCOVERY="$*"

# Create log directory if needed
mkdir -p .claude

# Append to log (format: timestamp,category,discovery)
echo "$TIMESTAMP,$CATEGORY,$DISCOVERY" >> "$DISCOVERY_LOG"

echo "✓ Discovery logged: $CATEGORY" >&2
