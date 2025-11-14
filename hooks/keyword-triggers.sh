#!/usr/bin/env bash
# Super Claude Kit v2.0.0 - Keyword-based Tool Triggering
# Auto-suggests relevant tools based on user prompt keywords

set -euo pipefail

# Source tool runner
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOL_RUNNER_PATH="$HOME/.claude/lib/tool-runner.sh"

if [ ! -f "$TOOL_RUNNER_PATH" ]; then
    exit 0  # Silent fail if tool-runner not available
fi

source "$TOOL_RUNNER_PATH"

# Get user prompt from environment (passed by Claude Code)
USER_PROMPT="${1:-}"

if [ -z "$USER_PROMPT" ]; then
    exit 0
fi

# Convert to lowercase for case-insensitive matching
PROMPT_LOWER=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')

# Track if any suggestions made
SUGGESTIONS_MADE=false

# Function to suggest tool
suggest_tool() {
    local tool_name="$1"
    local reason="$2"

    if ! $SUGGESTIONS_MADE; then
        echo ""
        echo "💡 Super Claude Kit - Available Tools:"
        SUGGESTIONS_MADE=true
    fi

    echo "   • $tool_name - $reason"
}

# Dependency-related keywords
if echo "$PROMPT_LOWER" | grep -qE '(depend|import|require|reference)'; then
    suggest_tool "query-deps" "Query dependency relationships"
fi

# Circular dependency keywords
if echo "$PROMPT_LOWER" | grep -qE '(circular|cycle|loop)'; then
    suggest_tool "find-circular" "Find circular dependency cycles"
fi

# Dead code keywords
if echo "$PROMPT_LOWER" | grep -qE '(unused|dead code|orphan|unreferenced)'; then
    suggest_tool "find-dead-code" "Find potentially unused files"
fi

# Impact analysis keywords
if echo "$PROMPT_LOWER" | grep -qE '(impact|affect|break|change.*will)'; then
    suggest_tool "impact-analysis" "Analyze impact of file changes"
fi

# Refactoring keywords
if echo "$PROMPT_LOWER" | grep -qE '(refactor|restructure|reorganize)'; then
    suggest_tool "query-deps" "Check dependencies before refactoring"
    suggest_tool "impact-analysis" "Analyze refactoring impact"
fi

# If suggestions were made, show how to use them
if $SUGGESTIONS_MADE; then
    echo ""
    echo "   Usage: run_tool <tool-name> [args...]"
    echo ""
fi

exit 0
