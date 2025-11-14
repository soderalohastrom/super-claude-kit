#!/bin/bash
# Find potentially dead code (files not imported by anyone)
# Usage: find-dead-code.sh

set -euo pipefail

GRAPH=".claude/dep-graph.json"

if [ ! -f "$GRAPH" ]; then
  echo "❌ Dependency graph not built"
  exit 1
fi

# Get dead code files
DEAD_FILES=$(cat "$GRAPH" | jq -r '.DeadCode[]?' 2>/dev/null || echo "")
DEAD_COUNT=0

if [ -n "$DEAD_FILES" ]; then
  DEAD_COUNT=$(echo "$DEAD_FILES" | wc -l | tr -d ' ')
fi

if [ "$DEAD_COUNT" -eq 0 ]; then
  echo "✅ No dead code detected"
  echo ""
  echo "All files are imported by at least one other file or are entry points."
  exit 0
fi

echo "🗑️  Found $DEAD_COUNT potentially unused files"
echo ""

# List all dead files (simple approach without grouping)
echo "$DEAD_FILES" | while read -r file; do
  echo "  • $file"
done
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  Before deleting, verify these are NOT:"
echo ""
echo "  • Entry points (main.ts, index.ts, etc.)"
echo "  • Test files that are run separately"
echo "  • Configuration files"
echo "  • Files used by build tools"
echo "  • Recently added files"
echo ""
echo "💡 To verify a file is safe to delete:"
echo "   1. Check git history: git log <file>"
echo "   2. Search for dynamic imports: grep -r \"<filename>\""
echo "   3. Check if it's referenced in configs"
