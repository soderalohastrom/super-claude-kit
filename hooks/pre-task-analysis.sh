#!/bin/bash

# Pre-Task Analysis Hook
# Analyzes user prompt and suggests optimal approach using AVAILABLE sub-agents
# Runs BEFORE Claude responds to encourage best practices

# Read user prompt from stdin with timeout to prevent hanging
USER_PROMPT=$(timeout 0.1 cat 2>/dev/null || echo "$1")

# ============================================
# CONTEXT CAPSULE: Smart refresh with heuristics
# ============================================

# Increment message counter
MESSAGE_COUNT_FILE=".claude/message_count.txt"
if [ -f "$MESSAGE_COUNT_FILE" ]; then
  COUNT=$(cat "$MESSAGE_COUNT_FILE")
  echo $((COUNT + 1)) > "$MESSAGE_COUNT_FILE"
else
  echo "1" > "$MESSAGE_COUNT_FILE"
fi

# Smart refresh: Check if update is needed
if ./.claude/hooks/check-refresh-needed.sh 2>/dev/null; then
  # Refresh needed - proceed with update

  # Detect changes since last run (automatic file tracking)
  ./.claude/hooks/detect-changes.sh 2>/dev/null

  # Update capsule with current state
  ./.claude/hooks/update-capsule.sh 2>/dev/null

  # Inject capsule if changed (hash-based detection)
  ./.claude/hooks/inject-capsule.sh 2>/dev/null
else
  # No meaningful changes - skip refresh (save cycles)
  :  # No-op
fi

# ============================================
# END CONTEXT CAPSULE
# ============================================

# Track if any suggestions were made
SUGGESTIONS_MADE=false

# Exploration tasks → Explore sub-agent
if echo "$USER_PROMPT" | grep -qiE "explore|find.*file|search.*code|where.*is|how does.*work|understand.*architecture|locate|discover|investigate|show.*me"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 DELEGATION SUGGESTION: Explore sub-agent"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Task Type: Codebase exploration/discovery"
    echo "   Best Approach: Use 'Explore' sub-agent"
    echo "   Why: Fast multi-round investigation, pattern matching"
    echo ""
    echo "   Usage: Task tool with subagent_type='Explore'"
    echo "   Thoroughness: 'quick', 'medium', or 'very thorough'"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    SUGGESTIONS_MADE=true
fi

# Planning/Implementation tasks → Plan sub-agent
if echo "$USER_PROMPT" | grep -qiE "plan|implement|build|create|develop|design|architect|add.*feature|new.*system"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 DELEGATION SUGGESTION: Plan sub-agent"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Task Type: Planning/Implementation"
    echo "   Best Approach: Use 'Plan' sub-agent"
    echo "   Why: Creates systematic implementation strategy"
    echo ""
    echo "   Usage: Task tool with subagent_type='Plan'"
    echo "   Returns: Detailed implementation plan with steps"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    SUGGESTIONS_MADE=true
fi

# Complex multi-step tasks → general-purpose sub-agent
if echo "$USER_PROMPT" | grep -qiE "fix.*and.*test|migrate.*and.*verify|update.*across|refactor.*entire"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🤖 DELEGATION SUGGESTION: general-purpose sub-agent"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Task Type: Complex multi-step task"
    echo "   Best Approach: Use 'general-purpose' sub-agent"
    echo "   Why: Handles complex workflows with multiple operations"
    echo ""
    echo "   Usage: Task tool with subagent_type='general-purpose'"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    SUGGESTIONS_MADE=true
fi

# Check for parallel work opportunity
if echo "$USER_PROMPT" | grep -qiE "and|also|both|multiple|all three|check.*check|verify.*verify"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚡ PERFORMANCE TIP: Parallel Tool Calls"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   Detected: Multiple independent operations"
    echo "   Best Practice: Execute tool calls in parallel"
    echo "   Why: Faster execution (single message, multiple tools)"
    echo ""
    echo "   Example: Read 3 files → Use 3 Read calls in one message"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    SUGGESTIONS_MADE=true
fi

# Check for continuation work (should read exploration journal)
if echo "$USER_PROMPT" | grep -qiE "continue|resume|pick.*up|where.*left|last.*time|previous|what.*next"; then
    if [ -f "docs/exploration/CURRENT_SESSION.md" ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📚 MEMORY AVAILABLE: Exploration Journal Found"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "   Action Required: Read exploration journal FIRST"
        echo "   Location: docs/exploration/CURRENT_SESSION.md"
        echo "   Why: Avoid repeating work, maintain continuity"
        echo ""
        echo "   Next: Summarize previous session for user"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        SUGGESTIONS_MADE=true
    fi
fi

# TodoWrite reminder for complex tasks
if echo "$USER_PROMPT" | grep -qiE "implement|build|create|fix.*bug|add.*feature"; then
    echo ""
    echo "📝 REMINDER: Use TodoWrite for task tracking"
    echo "   Break complex work into trackable steps"
    echo ""
    SUGGESTIONS_MADE=true
fi

# General reminder if no specific suggestions
if [ "$SUGGESTIONS_MADE" = false ]; then
    # Check complexity heuristic (long prompt = potentially complex task)
    PROMPT_LENGTH=${#USER_PROMPT}
    if [ $PROMPT_LENGTH -gt 200 ]; then
        echo ""
        echo "💡 REMINDER: Complex task detected (long prompt)"
        echo "   Available sub-agents: Plan, Explore, general-purpose"
        echo "   Consider: Breaking into smaller tasks with TodoWrite"
        echo ""
    fi
fi

# Always continue processing (don't block)
exit 0
