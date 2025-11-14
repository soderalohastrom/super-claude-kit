#!/bin/bash
# Query dependencies for a specific file
# Usage: query-deps.sh <file-path>

set -euo pipefail

FILE_PATH="$1"
GRAPH=".claude/dep-graph.json"

if [ ! -f "$GRAPH" ]; then
  echo "❌ Dependency graph not built"
  echo "   Run: ./.claude/hooks/session-start.sh to build it"
  exit 1
fi

# Check if file exists in graph
FILE_COUNT=$(cat "$GRAPH" | jq -r ".Files | has(\"$FILE_PATH\")" 2>/dev/null || echo "false")
if [ "$FILE_COUNT" == "false" ]; then
  echo "❌ File not found in dependency graph: $FILE_PATH"
  exit 1
fi

echo "📊 Dependencies for: $FILE_PATH"
echo ""

# Who imports this file?
IMPORTERS=$(cat "$GRAPH" | jq -r ".Files[\"$FILE_PATH\"].ImportedBy[]?" 2>/dev/null || echo "")
if [ -n "$IMPORTERS" ]; then
  IMPORTER_COUNT=$(echo "$IMPORTERS" | wc -l | tr -d ' ')
  echo "Imported by ($IMPORTER_COUNT files):"
  echo "$IMPORTERS" | while read -r file; do
    echo "  • $file"
  done
else
  echo "⚠️  Not imported by any files (potential dead code)"
fi

echo ""

# What does this file import?
IMPORTS=$(cat "$GRAPH" | jq -r ".Files[\"$FILE_PATH\"].Imports[]?.Path" 2>/dev/null || echo "")
if [ -n "$IMPORTS" ]; then
  IMPORT_COUNT=$(echo "$IMPORTS" | wc -l | tr -d ' ')
  echo "Imports ($IMPORT_COUNT files/packages):"
  echo "$IMPORTS" | while read -r file; do
    echo "  • $file"
  done
else
  echo "No imports"
fi

echo ""

# Exports
EXPORTS=$(cat "$GRAPH" | jq -r ".Files[\"$FILE_PATH\"].Exports[]? | \"\\(.Name) (\\(.Type))\"" 2>/dev/null || echo "")
if [ -n "$EXPORTS" ]; then
  EXPORT_COUNT=$(echo "$EXPORTS" | wc -l | tr -d ' ')
  echo "Exports ($EXPORT_COUNT symbols):"
  echo "$EXPORTS" | while read -r export; do
    echo "  • $export"
  done
else
  echo "No exports"
fi
