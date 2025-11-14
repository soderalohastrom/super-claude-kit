#!/usr/bin/env bash
# Super Claude Kit v2.0.0 - Pre-Edit Analysis Hook
# Auto-runs impact analysis before significant file modifications

set -euo pipefail

# This hook is designed to be called before Edit operations
# Usage: pre-edit-analysis.sh <file-path>

FILE_PATH="${1:-}"

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Check if dependency graph exists
DEP_GRAPH="$HOME/.claude/dep-graph.json"

if [ ! -f "$DEP_GRAPH" ]; then
    # Try to generate it first using tool-runner if available
    TOOL_RUNNER_PATH="$HOME/.claude/lib/tool-runner.sh"

    if [ -f "$TOOL_RUNNER_PATH" ]; then
        source "$TOOL_RUNNER_PATH"
        if command -v run_tool &> /dev/null; then
            run_tool dependency-scanner --path "$(pwd)" --output "$DEP_GRAPH" &> /dev/null || true
        fi
    fi
fi

# If still no graph, skip analysis
if [ ! -f "$DEP_GRAPH" ]; then
    exit 0
fi

# Check if file exists in dependency graph
FILE_IN_GRAPH=$(jq -r --arg path "$FILE_PATH" '.Files[$path] // empty' "$DEP_GRAPH" 2>/dev/null || true)

if [ -z "$FILE_IN_GRAPH" ]; then
    exit 0  # File not in graph
fi

# Count importers
IMPORTER_COUNT=$(jq -r --arg path "$FILE_PATH" '.Files[$path].ImportedBy | length' "$DEP_GRAPH" 2>/dev/null || echo "0")

# Only show analysis if file has importers (changes might have impact)
if [ "$IMPORTER_COUNT" -gt 0 ]; then
    echo ""
    echo "⚠️  Impact Analysis for: $(basename "$FILE_PATH")"
    echo "   Files that import this: $IMPORTER_COUNT"

    # Show top 5 importers
    IMPORTERS=$(jq -r --arg path "$FILE_PATH" '.Files[$path].ImportedBy[:5][]' "$DEP_GRAPH" 2>/dev/null || true)

    if [ -n "$IMPORTERS" ]; then
        echo "   Affected files:"
        echo "$IMPORTERS" | while read -r importer; do
            echo "     • $(basename "$importer")"
        done
    fi

    if [ "$IMPORTER_COUNT" -gt 5 ]; then
        echo "     ... and $((IMPORTER_COUNT - 5)) more"
    fi

    echo ""
    echo "   💡 Run 'run_tool impact-analysis $FILE_PATH' for full analysis"
    echo ""
fi

exit 0
