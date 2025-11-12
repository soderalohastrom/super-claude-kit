#!/bin/bash
# Restore Capsule from Previous Session
# Loads persisted state if session was recent (<24 hours)

set -euo pipefail

PERSIST_FILE=".claude/capsule_persist.json"
CURRENT_TIME=$(date +%s)
TWENTY_FOUR_HOURS=$((24 * 60 * 60))

# Check if persistence file exists
if [ ! -f "$PERSIST_FILE" ]; then
  exit 0  # No previous session to restore
fi

# Check if previous session was recent
LAST_SESSION_TIME=$(python3 -c "import json; data = json.load(open('$PERSIST_FILE')); print(data['last_session']['ended_at'])" 2>/dev/null || echo "0")
TIME_SINCE_SESSION=$((CURRENT_TIME - LAST_SESSION_TIME))

if [ $TIME_SINCE_SESSION -gt $TWENTY_FOUR_HOURS ]; then
  # Session too old - skip restore
  exit 0
fi

# Display restoration banner
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔄 RESTORING FROM PREVIOUS SESSION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Convert time since to human readable
if [ $TIME_SINCE_SESSION -lt 3600 ]; then
  TIME_STR="$((TIME_SINCE_SESSION / 60))m ago"
elif [ $TIME_SINCE_SESSION -lt 86400 ]; then
  TIME_STR="$((TIME_SINCE_SESSION / 3600))h ago"
else
  TIME_STR="$((TIME_SINCE_SESSION / 86400))d ago"
fi

echo "Last session ended: $TIME_STR"

# Show previous session info
PREV_DURATION=$(python3 -c "import json; data = json.load(open('$PERSIST_FILE')); print(data['last_session']['duration_seconds'])" 2>/dev/null || echo "0")
PREV_BRANCH=$(python3 -c "import json; data = json.load(open('$PERSIST_FILE')); print(data['last_session']['branch'])" 2>/dev/null || echo "unknown")

if [ $PREV_DURATION -lt 60 ]; then
  DUR_STR="${PREV_DURATION}s"
elif [ $PREV_DURATION -lt 3600 ]; then
  DUR_STR="$((PREV_DURATION / 60))m"
else
  DUR_STR="$((PREV_DURATION / 3600))h $((PREV_DURATION % 3600 / 60))m"
fi

echo "Previous session: $DUR_STR on branch $PREV_BRANCH"
echo ""

# Show key discoveries from last session
echo "💡 Key Discoveries from Last Session:"
python3 << 'PYTHON_SCRIPT'
import json
import sys

try:
    with open('.claude/capsule_persist.json', 'r') as f:
        data = json.load(f)

    discoveries = data.get('discoveries', [])
    if discoveries:
        for disc in discoveries[:5]:  # Show top 5
            category = disc.get('category', 'unknown')
            content = disc.get('content', '')

            # Category icons
            icons = {
                'pattern': '🔍',
                'insight': '💭',
                'decision': '🎯',
                'architecture': '🏗️',
                'bug': '🐛',
                'optimization': '⚡'
            }
            icon = icons.get(category, '📝')

            print(f"   {icon} [{category}] {content}")
    else:
        print("   (No discoveries from last session)")
except:
    print("   (Could not load discoveries)")
PYTHON_SCRIPT

echo ""

# Show key files from last session
echo "📁 Files from Last Session:"
python3 << 'PYTHON_SCRIPT'
import json

try:
    with open('.claude/capsule_persist.json', 'r') as f:
        data = json.load(f)

    files = data.get('key_files', [])
    if files:
        for file in files[:10]:  # Show top 10
            print(f"   • {file}")
    else:
        print("   (No files from last session)")
except:
    print("   (Could not load files)")
PYTHON_SCRIPT

echo ""

# Show sub-agent results
echo "🤖 Sub-Agent Results from Last Session:"
python3 << 'PYTHON_SCRIPT'
import json

try:
    with open('.claude/capsule_persist.json', 'r') as f:
        data = json.load(f)

    agents = data.get('sub_agents', [])
    if agents:
        for agent in agents:
            agent_type = agent.get('type', 'unknown')
            summary = agent.get('summary', '')
            print(f"   • [{agent_type}] {summary}")
    else:
        print("   (No sub-agent results from last session)")
except:
    print("   (Could not load sub-agent results)")
PYTHON_SCRIPT

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Previous session context restored"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
