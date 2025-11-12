# SUPER CLAUDE

**Transform Claude Code from a stateless tourist into a stateful resident.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0+-green.svg)](https://www.gnu.org/software/bash/)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Compatible-blue.svg)](https://claude.ai)

---

## The Problem

Claude Code is brilliant, but it's **stateless**. Every session starts from scratch:

- ❌ Forgets what files you read 2 minutes ago
- ❌ Loses task context between messages
- ❌ No memory across sessions
- ❌ Repeats the same questions

You're the tour guide, and Claude is the tourist who keeps asking for directions to the same place.

## The Solution

**SUPER CLAUDE** adds persistent memory to Claude Code using:

- ✅ **Session state tracking** - Remembers files, tasks, discoveries
- ✅ **Cross-session persistence** - 24-hour memory window
- ✅ **Token-efficient storage** - 52% reduction with TOON format
- ✅ **Smart refresh** - 60-70% fewer context updates
- ✅ **Exploration journal** - Permanent knowledge base

**No external dependencies. No databases. Pure bash + hooks.**

---

## Features

### 🧠 Persistent Memory

Claude remembers:
- Files accessed (with timestamps)
- Current tasks (in progress, pending, completed)
- Sub-agent results (Explore, Plan, etc.)
- Session discoveries (patterns, insights, decisions)
- Git state (branch, dirty files, commits)

### 📊 Context Capsule

Before every prompt, Claude sees a compact summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 CONTEXT CAPSULE (Updated)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🌿 Git State:
   Branch: main (HEAD: a1b2c3d)
   ⚠️  5 dirty file(s)

📁 Files in Context:
   • server/auth.ts (read, 2m ago)
   • api/gateway.go (edit, 5m ago)

✅ Current Tasks:
   🔄 [IN PROGRESS] Implementing auth system
   ✅ [DONE] Design database schema

💡 Session Discoveries:
   🔍 [pattern] Auth uses JWT + Redis sessions
   🏗️ [architecture] Gateway proxies to microservices

⏱️  Session Info:
   Messages: 8 | Session: 12m

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 🔄 Cross-Session Restoration

Start a new session within 24 hours, and Claude restores:
- Last 10 discoveries
- Last 15 files accessed
- Last 5 sub-agent results
- Previous session metadata

```
🔄 RESTORING FROM PREVIOUS SESSION
Last session ended: 30m ago
Previous session: 15m on branch main

💡 Key Discoveries from Last Session:
   🔍 [pattern] Redis stores session tokens with 24h TTL
   🏗️ [architecture] Auth service uses middleware pattern
```

### ⚡ Performance

| Metric | Improvement |
|--------|-------------|
| Token usage | **52% reduction** (TOON vs JSON) |
| Context refreshes | **60-70% fewer** (smart heuristics) |
| File re-reads | **87% reduction** |
| Cross-session context | **24-hour persistence** |

### 🤖 Specialized Sub-Agents

SUPER CLAUDE includes 4 built-in sub-agents for common development tasks:

1. **architecture-explorer** - Understand codebases, service boundaries, data flows
2. **database-navigator** - Explore database schemas, migrations, relationships
3. **agent-developer** - Build and debug AI agents with MCP integration
4. **github-issue-tracker** - Create well-formatted GitHub issues from discoveries

**Use them by launching the Task tool with `subagent_type`:**
```
Task tool with subagent_type="architecture-explorer"
```

---

## Installation

### Requirements

- **Claude Code** (any version with hooks)
- **Git** (recommended, but not required)

### Quick Install (Recommended)

```bash
cd your-project
curl -sL https://raw.githubusercontent.com/arpitnath/super-claude/main/install | bash
```

**That's it.** Next time you start Claude Code:

```
🚀 SUPER CLAUDE ACTIVATED - Context Loaded
```

### What Gets Installed

- ✅ 20 hooks (automatic automation)
- ✅ 2 utility scripts (manual testing & stats)
- ✅ 3 skills (context-saver, exploration-continue, task-router)
- ✅ 4 sub-agents (architecture-explorer, database-navigator, agent-developer, github-issue-tracker)
- ✅ Documentation & usage guides
- ✅ Updated `.gitignore` with session files
- ✅ Updated `CLAUDE.md` with integration instructions

### Test Installation

```bash
# Verify everything works
bash .claude/scripts/test-super-claude.sh

# View usage statistics
bash .claude/scripts/show-stats.sh
```

---

## Usage

### Automatic Features

These work without any manual intervention:

- ✅ Git state tracking (every prompt)
- ✅ Smart refresh (hash-based change detection)
- ✅ Capsule injection (only when state changes)
- ✅ Cross-session persistence (automatic save/restore)
- ✅ Journal sync (discoveries → Markdown)

### Manual Logging (For Claude)

Claude should explicitly log operations:

```bash
# After reading a file
./.claude/hooks/log-file-access.sh "path/to/file" "read"

# After editing a file
./.claude/hooks/log-file-access.sh "path/to/file" "edit"

# After a discovery
./.claude/hooks/log-discovery.sh "pattern" "Auth uses JWT tokens"

# After task update
./.claude/hooks/log-task.sh "in_progress" "Implementing auth"

# After sub-agent completes
./.claude/hooks/log-subagent.sh "Explore" "Found auth in server/auth/"
```

### Utilities

```bash
# Get discovery suggestions
./.claude/hooks/suggest-discoveries.sh

# View session summary
./.claude/hooks/summarize-session.sh

# Force capsule refresh
rm .claude/last_refresh_state.txt
./.claude/hooks/update-capsule.sh
```

---

## Architecture

### System Overview

```
┌─────────────────────────────────────────┐
│  Hook Orchestration Layer              │
│  - session-start.sh                     │
│  - pre-task-analysis.sh                 │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  Context Capsule System                 │
│  - Smart refresh (check-refresh-needed) │
│  - State aggregation (update-capsule)   │
│  - Change detection (detect-changes)    │
│  - Display logic (inject-capsule)       │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│  Storage Layer                          │
│  - TOON files (.toon)                   │
│  - Session logs (.log)                  │
│  - Persistence (JSON)                   │
│  - Exploration journal (Markdown)       │
└─────────────────────────────────────────┘
```

### TOON Format

**TOON (Token-Oriented Object Notation)** achieves 52% fewer tokens than JSON:

**JSON (95 tokens):**
```json
{
  "git": {"branch": "main", "head": "a1b2c3d", "dirty": 5},
  "files": [{"path": "auth.ts", "action": "read", "age": 120}],
  "tasks": [{"status": "in_progress", "content": "Auth"}]
}
```

**TOON (45 tokens):**
```toon
GIT{branch,head,dirty}:
 main,a1b2c3d,5
FILES{path,action,age}:
 auth.ts,read,120
TASK{status,content}:
 in_progress,Auth
```

### Hook System

| Hook | Trigger | Purpose |
|------|---------|---------|
| `session-start.sh` | Session init | Load context, restore state |
| `pre-task-analysis.sh` | Before each prompt | Update capsule, inject context |

---

## Documentation

- **[Usage Guide](docs/CAPSULE_USAGE_GUIDE.md)** - Best practices for using SUPER CLAUDE
- **[System Architecture](docs/SUPER_CLAUDE_SYSTEM_ARCHITECTURE.md)** - Complete technical deep dive (46 pages)

---

## File Structure

```
.claude/
├── hooks/                      # 20 automation hooks
│   ├── session-start.sh       # Session initialization
│   ├── pre-task-analysis.sh   # Pre-prompt orchestration
│   ├── update-capsule.sh      # TOON generation
│   ├── inject-capsule.sh      # Context display
│   ├── check-refresh-needed.sh # Smart refresh
│   ├── detect-changes.sh      # Git diff detection
│   ├── persist-capsule.sh     # Cross-session save
│   ├── restore-capsule.sh     # Cross-session restore
│   ├── sync-to-journal.sh     # Journal sync
│   ├── load-from-journal.sh   # Journal load
│   ├── summarize-session.sh   # Session summary
│   ├── suggest-discoveries.sh # Discovery hints
│   ├── log-file-access.sh     # File logging
│   ├── log-task.sh            # Task logging
│   ├── log-subagent.sh        # Sub-agent logging
│   ├── log-discovery.sh       # Discovery logging
│   ├── validate-capsule-usage.sh # Validation warnings
│   └── init-capsule-session.sh # Session init
├── scripts/                    # 2 utility scripts
│   ├── show-stats.sh          # Usage statistics
│   └── test-super-claude.sh   # Installation tests
├── skills/                     # 3 universal skills
│   ├── context-saver/         # Save important context
│   ├── exploration-continue/  # Continue exploration
│   └── task-router/           # Route complex tasks
├── agents/                     # 4 specialized sub-agents
│   ├── architecture-explorer.md    # Codebase architecture
│   ├── database-navigator.md       # Database schemas
│   ├── agent-developer.md          # Agent development
│   └── github-issue-tracker.md     # Issue management
├── docs/                       # Documentation
│   ├── CAPSULE_USAGE_GUIDE.md        # Usage patterns
│   └── SUPER_CLAUDE_SYSTEM_ARCHITECTURE.md  # Technical details
├── capsule.toon               # Current state (TOON)
├── capsule_persist.json       # 24h persistence
├── session_files.log          # File access log
├── current_tasks.log          # Task tracking
├── subagent_results.log       # Sub-agent results
├── session_discoveries.log    # Session insights
└── [other session files]
```

---

## Performance Benchmarks

**Token Efficiency:**
- JSON: 95 tokens
- TOON: 45 tokens
- **Reduction: 52%**

**Refresh Rate:**
- Baseline: 12/12 prompts (100%)
- Smart refresh: 4/12 prompts (33%)
- **Reduction: 67%**

**Storage:**
- Per-session: 10-30KB
- Persistence: 2-5KB
- **Total: <50KB**

**Latency:**
- Hook execution: <50ms
- Capsule generation: ~20ms
- Capsule injection: ~10ms
- **Total overhead: <80ms**

---

## How It Works

### Session Initialization Flow

```
Claude Code Starts
    ↓
session-start.sh
    ├─> persist-capsule.sh (save previous session)
    ├─> init-capsule-session.sh (start new session)
    ├─> restore-capsule.sh (restore if <24h)
    ├─> load-from-journal.sh (show recent discoveries)
    └─> update-capsule.sh (generate initial capsule)
    ↓
SUPER CLAUDE Activated
```

### Pre-Prompt Flow

```
User Submits Prompt
    ↓
pre-task-analysis.sh
    ├─> Increment message counter
    ├─> check-refresh-needed.sh (hash-based)
    │   └─> Skip if unchanged + <5 min
    ├─> detect-changes.sh (git diff)
    ├─> update-capsule.sh (aggregate state)
    └─> inject-capsule.sh (display if changed)
    ↓
Claude Processes with Full Context
```

---

## Troubleshooting

### Hooks not running?

Check Claude Code configuration:
```bash
cat .claude/config.json
```

Should have:
```json
{
  "hooks": {
    "sessionStart": ".claude/hooks/session-start.sh",
    "userPromptSubmit": ".claude/hooks/pre-task-analysis.sh"
  }
}
```

### Capsule not updating?

Check refresh state:
```bash
cat .claude/last_refresh_state.txt
rm .claude/last_refresh_state.txt  # Force refresh
```

### Session not persisting?

Check persistence file:
```bash
cat .claude/capsule_persist.json | python3 -m json.tool
```

### Logs growing too large?

Session logs clear on new session start. If needed:
```bash
> .claude/session_files.log
> .claude/session_discoveries.log
```

---

## Contributing

Contributions welcome! Areas for improvement:

1. **Phase 4 Features:**
   - Automatic discovery extraction
   - Journal archival system
   - Cross-session analytics
   - Capsule visualizations

2. **Platform Support:**
   - Windows support (WSL2 tested)
   - Alternative shells (zsh, fish)

3. **Integration:**
   - VS Code extension
   - Cursor IDE support
   - Other AI coding assistants

**To contribute:**
1. Fork the repo
2. Create a feature branch
3. Submit a pull request

---

## License

MIT License - See [LICENSE](LICENSE) file

---

## Acknowledgments

- **Anthropic** - For Claude and Claude Code
- **The developer community** - For inspiration and feedback
- **Early testers** - For bug reports and suggestions

---

## Author

**Arpit Nath**

Builder of AI-powered developer tools. Created SUPER CLAUDE to solve the persistent context problem in AI coding assistants.

- GitHub: [@arpitnath](https://github.com/arpitnath)
- Twitter/X: [@arpitsharma](https://x.com/arpitsharma)

---

**⭐ If SUPER CLAUDE helps you, please star the repo!**

---

*"The best AI tools aren't the ones with the biggest models. They're the ones with the best architecture."*
