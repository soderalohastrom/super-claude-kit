#!/bin/bash
# Helper script to log file access operations
# Usage: ./log-file-access.sh <path> <action>
# Actions: read, edit, write

set -euo pipefail

FILE_LOG=".claude/session_files.log"
TIMESTAMP=$(date +%s)

if [ $# -lt 2 ]; then
  echo "Usage: $0 <path> <action>" >&2
  exit 1
fi

PATH_ARG="$1"
ACTION="$2"

# Create log directory if needed
mkdir -p .claude

# Append to log (format: path,action,timestamp)
echo "$PATH_ARG,$ACTION,$TIMESTAMP" >> "$FILE_LOG"
