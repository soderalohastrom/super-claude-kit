#!/bin/bash
# Analyze impact of changing a file
# Usage: impact-analysis.sh <file-path>

set -euo pipefail

FILE_PATH="$1"
GRAPH=".claude/dep-graph.json"

if [ ! -f "$GRAPH" ]; then
  echo "❌ Dependency graph not built"
  exit 1
fi

# Check if file exists
FILE_EXISTS=$(cat "$GRAPH" | jq -r ".Files | has(\"$FILE_PATH\")" 2>/dev/null || echo "false")
if [ "$FILE_EXISTS" == "false" ]; then
  echo "❌ File not found in dependency graph: $FILE_PATH"
  exit 1
fi

echo "⚠️  Impact Analysis: $FILE_PATH"
echo ""

# Direct dependents (files that import this file)
DIRECT=$(cat "$GRAPH" | jq -r ".Files[\"$FILE_PATH\"].ImportedBy[]?" 2>/dev/null || echo "")
DIRECT_COUNT=0
if [ -n "$DIRECT" ]; then
  DIRECT_COUNT=$(echo "$DIRECT" | wc -l | tr -d ' ')
fi

echo "Direct dependents: $DIRECT_COUNT files"
if [ "$DIRECT_COUNT" -gt 0 ]; then
  echo "$DIRECT" | head -10 | while read -r file; do
    echo "  • $file"
  done
  if [ "$DIRECT_COUNT" -gt 10 ]; then
    echo "  ... and $((DIRECT_COUNT - 10)) more"
  fi
fi

echo ""

# Calculate transitive dependents (simplified - would need BFS for full analysis)
# For now, just show that direct dependents also have dependents
TRANSITIVE_COUNT=0
if [ "$DIRECT_COUNT" -gt 0 ]; then
  for dep in $DIRECT; do
    DEP_IMPORTERS=$(cat "$GRAPH" | jq -r ".Files[\"$dep\"].ImportedBy | length" 2>/dev/null || echo "0")
    TRANSITIVE_COUNT=$((TRANSITIVE_COUNT + DEP_IMPORTERS))
  done
fi

if [ "$TRANSITIVE_COUNT" -gt 0 ]; then
  echo "Transitive dependents: ~$TRANSITIVE_COUNT files (approximate)"
  echo ""
fi

# Total impact
TOTAL_IMPACT=$((DIRECT_COUNT + TRANSITIVE_COUNT))
echo "Total potential impact: ~$TOTAL_IMPACT files"
echo ""

# Risk assessment
if [ "$DIRECT_COUNT" -eq 0 ]; then
  echo "🟢 RISK: NONE - File is not used (dead code)"
elif [ "$DIRECT_COUNT" -gt 10 ]; then
  echo "🔴 RISK: HIGH - Many files depend on this"
  echo "   ⚠️  Changes here will affect $DIRECT_COUNT files"
  echo "   💡 Consider:"
  echo "      • Write comprehensive tests"
  echo "      • Review all dependent files"
  echo "      • Consider breaking changes carefully"
elif [ "$DIRECT_COUNT" -gt 3 ]; then
  echo "🟡 RISK: MEDIUM - Several files depend on this"
  echo "   ⚠️  Changes here will affect $DIRECT_COUNT files"
  echo "   💡 Review dependent files before making breaking changes"
else
  echo "🟢 RISK: LOW - Few dependencies"
  echo "   ✅ Safe to modify with standard testing"
fi
