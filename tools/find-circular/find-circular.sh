#!/bin/bash
# Find circular dependencies in the codebase
# Usage: find-circular.sh

set -euo pipefail

GRAPH=".claude/dep-graph.json"

if [ ! -f "$GRAPH" ]; then
  echo "❌ Dependency graph not built"
  exit 1
fi

# Check for circular dependencies
CIRCULAR_COUNT=$(cat "$GRAPH" | jq '.Circular | length' 2>/dev/null || echo "0")

if [ "$CIRCULAR_COUNT" -eq 0 ]; then
  echo "✅ No circular dependencies found"
  echo ""
  echo "Your dependency graph is clean!"
  exit 0
fi

echo "⚠️  Found $CIRCULAR_COUNT circular dependency cycles"
echo ""

# Display each cycle
CYCLE_NUM=1
cat "$GRAPH" | jq -r '.Circular[] | @json' 2>/dev/null | while read -r cycle; do
  echo "Cycle #$CYCLE_NUM:"
  CYCLE_ARRAY=$(echo "$cycle" | jq -r '.[]')

  # Print cycle with arrows
  FIRST_FILE=""
  PREV_FILE=""
  while IFS= read -r file; do
    if [ -z "$FIRST_FILE" ]; then
      FIRST_FILE="$file"
      PREV_FILE="$file"
      echo "  $file"
    else
      echo "    ↓"
      echo "  $file"
      PREV_FILE="$file"
    fi
  done <<< "$CYCLE_ARRAY"

  # Close the cycle
  echo "    ↓"
  echo "  $FIRST_FILE (cycle back)"

  echo ""
  CYCLE_NUM=$((CYCLE_NUM + 1))
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 How to fix circular dependencies:"
echo ""
echo "1. Extract shared code into a new module"
echo "2. Use dependency injection"
echo "3. Refactor to use interfaces/abstractions"
echo "4. Consider architectural boundaries"
echo ""
echo "Circular dependencies can cause:"
echo "  • Difficult testing"
echo "  • Build/import issues"
echo "  • Hard to understand code flow"
