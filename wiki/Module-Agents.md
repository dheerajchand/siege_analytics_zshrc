# Module: Agents

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Codex and Claude session management, plus Claude project initialization with configuration templates.

## Environment
- `CODEX_SESSIONS_FILE` (default `~/.config/zsh/codex-sessions.env`)
- `CLAUDE_SESSIONS_FILE` (default `~/.config/zsh/claude-sessions.env`)

## Functions

### Codex Sessions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `codex_session` | Print `codex resume` for saved session | `fzf` (optional) | Sessions file exists |
| `codex_session_list` | List saved sessions | `awk` | None |
| `codex_session_add` | Add session entry | `awk`, `mktemp` | `name=id|desc` |
| `codex_session_update` | Update entry | `awk`, `mktemp` | Existing key |
| `codex_session_remove` | Remove entry | `awk`, `mktemp` | Existing key |
| `codex_session_edit` | Edit sessions file | `$EDITOR` | File writable |

### Claude Sessions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `claude_session` | Print `claude resume` for saved session | `fzf` (optional) | Sessions file exists |
| `claude_session_list` | List saved sessions | `awk` | None |
| `claude_session_add` | Add session entry | `awk`, `mktemp` | `name=id|desc` |
| `claude_session_update` | Update entry | `awk`, `mktemp` | Existing key |
| `claude_session_remove` | Remove entry | `awk`, `mktemp` | Existing key |
| `claude_session_edit` | Edit sessions file | `$EDITOR` | File writable |

### Claude Project Initialization

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `claude_init` | Initialize Claude Code config in current directory | `git`, `curl` | None |

**Usage:**
```bash
claude_init                           # Auto-detect project settings
claude_init --project myapp --org myorg
claude_init --add-session             # Also add to session list
claude_init --help                    # Show help
```

**What it does:**
1. Auto-detects project name, organization, and git root from context
2. Clones `siege-analytics/claude-configs` repo
3. Copies categorized skills to `.claude/skills/`
4. Generates `CLAUDE.md` from template with variable substitution
5. Copies baseline `settings.local.json` with safe permissions
6. Optionally adds project to Claude session list

**Template Variables:**
- `{{PROJECT_NAME}}` - Auto-detected from git remote or directory name
- `{{ORG_NAME}}` - Auto-detected from git remote
- `{{GIT_ROOT}}` - Parent directory
- `{{CURRENT_DATE}}` - Current date

**Skills Taxonomy:**
- `session/` - Session lifecycle (wrap-up)
- `planning/` - Work prioritization (im-feeling-lucky)
- `maintenance/` - Code/doc health (consolidate)
- `development/` - Coding helpers (empty)
- `operations/` - Runtime tasks (empty)

## Notes
- Format: `name=id|description`
- If `fzf` is installed, both `codex_session` and `claude_session` use it for selection.
- In interactive shells, session commands prompt to execute the resume command (default **Y**).
- In non‑interactive shells, they auto‑execute the resume command.
