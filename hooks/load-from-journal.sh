#!/bin/bash
# Load Recent Discoveries from Exploration Journal
# Displays recent journal entries relevant to current work

set -euo pipefail

JOURNAL_DIR="docs/exploration"
CURRENT_SESSION="$JOURNAL_DIR/CURRENT_SESSION.md"

# Check if journal exists
if [ ! -f "$CURRENT_SESSION" ]; then
  exit 0  # No journal to load
fi

# Check if journal was updated recently (last 7 days)
if [ -f "$CURRENT_SESSION" ]; then
  LAST_MODIFIED=$(stat -f %m "$CURRENT_SESSION" 2>/dev/null || stat -c %Y "$CURRENT_SESSION" 2>/dev/null || echo "0")
  CURRENT_TIME=$(date +%s)
  DAYS_SINCE=$((( CURRENT_TIME - LAST_MODIFIED ) / 86400))

  if [ $DAYS_SINCE -gt 7 ]; then
    exit 0  # Journal too old
  fi

  # Display journal excerpt
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "📚 EXPLORATION JOURNAL (Updated $DAYS_SINCE day(s) ago)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Recent discoveries from journal:"
  echo ""

  # Show last 10 discovery lines
  grep -E "^- (🔍|💭|🎯|🏗️|🐛|⚡)" "$CURRENT_SESSION" 2>/dev/null | tail -n 10 || echo "   (No recent discoveries)"

  echo ""
  echo "💡 Full journal: $CURRENT_SESSION"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi
