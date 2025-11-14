#!/usr/bin/env bash
# Super Claude Kit v2.0.0 - Tool Auto-Suggestion System
# Intelligently suggests tools based on context and prompt analysis

set -euo pipefail

# This script is designed to be sourced/called from user-prompt-submit hook
# It analyzes the user's prompt and suggests relevant tools

USER_PROMPT="${1:-}"

# Only run if we have a prompt
if [ -z "$USER_PROMPT" ]; then
    exit 0
fi

# Convert prompt to lowercase for matching
PROMPT_LOWER=$(echo "$USER_PROMPT" | tr '[:upper:]' '[:lower:]')

# Initialize suggestion array
declare -a SUGGESTIONS=()

# Dependency analysis patterns
if echo "$PROMPT_LOWER" | grep -qE '(depend|import|require|reference|use)'; then
    SUGGESTIONS+=("query-deps:Query file dependencies and relationships")
fi

# Circular dependency patterns
if echo "$PROMPT_LOWER" | grep -qE '(circular|cycle|loop|recursive depend)'; then
    SUGGESTIONS+=("find-circular:Detect circular dependency cycles")
fi

# Dead code patterns
if echo "$PROMPT_LOWER" | grep -qE '(unused|dead code|orphan|unreferenced|not used)'; then
    SUGGESTIONS+=("find-dead-code:Find potentially unused files")
fi

# Impact analysis patterns
if echo "$PROMPT_LOWER" | grep -qE '(impact|affect|break|change.*will|what if|consequence)'; then
    SUGGESTIONS+=("impact-analysis:Analyze change impact on codebase")
fi

# Refactoring patterns
if echo "$PROMPT_LOWER" | grep -qE '(refactor|restructure|reorganize|move.*file|rename)'; then
    # Suggest multiple tools for refactoring
    if ! echo "${SUGGESTIONS[*]}" | grep -q "query-deps"; then
        SUGGESTIONS+=("query-deps:Check dependencies before refactoring")
    fi
    if ! echo "${SUGGESTIONS[*]}" | grep -q "impact-analysis"; then
        SUGGESTIONS+=("impact-analysis:Understand refactoring impact")
    fi
fi

# Architecture/structure analysis patterns
if echo "$PROMPT_LOWER" | grep -qE '(architecture|structure|organization|how.*organized)'; then
    SUGGESTIONS+=("dependency-scanner:Analyze codebase structure")
fi

# Only output if we have suggestions
if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
    echo ""
    echo "💡 Super Claude Kit - Suggested Tools:"
    echo ""

    # Remove duplicates while preserving order (bash 3.2 compatible)
    SEEN_TOOLS=""
    for suggestion in "${SUGGESTIONS[@]}"; do
        TOOL_NAME="${suggestion%%:*}"
        TOOL_DESC="${suggestion#*:}"

        # Check if we've seen this tool before
        if ! echo "$SEEN_TOOLS" | grep -q "^${TOOL_NAME}$"; then
            SEEN_TOOLS="${SEEN_TOOLS}${TOOL_NAME}"$'\n'
            echo "   📦 $TOOL_NAME"
            echo "      → $TOOL_DESC"
            echo ""
        fi
    done

    echo "   Usage: bash ./.claude/lib/tool-runner.sh <tool-name> [args]"
    echo "   Or call: run_tool <tool-name> [args]"
    echo ""
fi

exit 0
