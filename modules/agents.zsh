#!/usr/bin/env zsh
# =================================================================
# AGENTS - Codex & Claude session helpers
# =================================================================

: "${CODEX_SESSIONS_FILE:=$HOME/.config/zsh/codex-sessions.env}"
: "${CLAUDE_SESSIONS_FILE:=$HOME/.config/zsh/claude-sessions.env}"

# =================================================================
# Generic session manager — parameterized by tool name & file
# =================================================================

_agent_sessions_ensure_file() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        umask 077
        touch "$file" 2>/dev/null || return 1
    fi
    return 0
}

_agent_sessions_list_keys() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    awk -F'=' '/^[[:space:]]*#/{next} /^[[:space:]]*$/{next} {print $1}' "$file"
}

_agent_sessions_get() {
    local key="$1" file="$2"
    [[ -f "$file" ]] || return 1
    awk -F'=' -v k="$key" '$1==k {print $2; found=1} END {exit found?0:1}' "$file"
}

_agent_session_add() {
    local tool="$1" file="$2"; shift 2
    local key="" value=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)  key="${2:-}"; shift 2 ;;
            --value) value="${2:-}"; shift 2 ;;
            --help|-h) echo "Usage: ${tool}_session_add --name <name> --value <id>|<description>" >&2; return 0 ;;
            *) if [[ -z "$key" ]]; then key="$1"; else value="${value:+$value }$1"; fi; shift ;;
        esac
    done
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: ${tool}_session_add --name <name> --value <id>|<description>" >&2
        return 1
    fi
    _agent_sessions_ensure_file "$file" || { echo "Cannot write $file" >&2; return 1; }
    if _agent_sessions_get "$key" "$file" >/dev/null 2>&1; then
        echo "Key exists: $key (use ${tool}_session_update)" >&2; return 1
    fi
    printf '%s=%s\n' "$key" "$value" >> "$file"
}

_agent_session_update() {
    local tool="$1" file="$2"; shift 2
    local key="" value=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)  key="${2:-}"; shift 2 ;;
            --value) value="${2:-}"; shift 2 ;;
            --help|-h) echo "Usage: ${tool}_session_update --name <name> --value <id>|<description>" >&2; return 0 ;;
            *) if [[ -z "$key" ]]; then key="$1"; else value="${value:+$value }$1"; fi; shift ;;
        esac
    done
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: ${tool}_session_update --name <name> --value <id>|<description>" >&2; return 1
    fi
    _agent_sessions_ensure_file "$file" || { echo "Cannot write $file" >&2; return 1; }
    local tmp; tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" -v v="$value" 'BEGIN{u=0} $1==k{print k"="v;u=1;next} {print} END{if(!u)exit 2}' "$file" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then rm -f "$tmp"; echo "Key not found: $key" >&2; return 1; fi
    mv "$tmp" "$file"
}

_agent_session_remove() {
    local tool="$1" file="$2" key="$3"
    if [[ -z "$key" ]]; then echo "Usage: ${tool}_session_remove <name>" >&2; return 1; fi
    local tmp; tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" '$1==k{r=1;next}{print}END{if(!r)exit 2}' "$file" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then rm -f "$tmp"; echo "Key not found: $key" >&2; return 1; fi
    mv "$tmp" "$file"
}

_agent_session_list() {
    local tool="$1" file="$2"
    _agent_sessions_ensure_file "$file" || return 1
    echo "${tool} sessions: $file"
    awk -F'=' '/^[[:space:]]*#/{next}/^[[:space:]]*$/{next}{printf "%-20s | %s\n",$1,$2}' "$file"
}

_agent_session_edit() {
    local file="$1"
    _agent_sessions_ensure_file "$file" || return 1
    "${EDITOR:-vi}" "$file"
}

_agent_session_resume() {
    local tool="$1" file="$2"; shift 2
    local key="" auto_exec_var="${(U)tool}_SESSION_AUTO_EXEC_NONINTERACTIVE"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)  key="${2:-}"; shift 2 ;;
            --help|-h) echo "Usage: ${tool}_session [--name <key>]" >&2; return 0 ;;
            *) key="$1"; shift ;;
        esac
    done
    _agent_sessions_ensure_file "$file" || return 1
    if [[ -z "$key" ]]; then
        if command -v fzf >/dev/null 2>&1; then
            key="$(_agent_sessions_list_keys "$file" | fzf --prompt="${tool} session> ")"
        else
            local keys; keys=($(_agent_sessions_list_keys "$file"))
            if [[ ${#keys[@]} -eq 0 ]]; then echo "No sessions saved." >&2; return 1; fi
            echo "Select session:"
            select key in "${keys[@]}"; do break; done
        fi
    fi
    [[ -z "$key" ]] && return 1
    local entry; entry="$(_agent_sessions_get "$key" "$file" 2>/dev/null || true)"
    if [[ -z "$entry" ]]; then echo "Key not found: $key" >&2; return 1; fi
    local id="${entry%%|*}" desc="${entry#*|}"
    [[ "$id" == "$desc" ]] && desc=""
    # Resume invocation differs per CLI (verified against `claude --help` and
    # `codex resume --help`):
    #   claude : the flag form `claude --resume <id>` -- there is NO `resume`
    #            subcommand; `claude resume <id>` is parsed as a prompt, not a
    #            session resume.
    #   codex  : the subcommand `codex resume <id>`.
    # _agent_session_resume_args emits the correct argv per tool so the generic
    # helper does not assume both CLIs share a syntax.
    local -a resume_args
    resume_args=("${(@f)$(_agent_session_resume_args "$tool" "$id")}")
    local cmd="${tool} ${resume_args[*]}"
    [[ -n "$desc" ]] && echo "$cmd  # $desc" || echo "$cmd"
    local should_exec=0
    if [[ -o interactive ]]; then
        local reply; read -r "reply?Execute command? [Y/n]: "; reply="${reply:-y}"
        [[ "$reply" =~ ^[Yy]$ ]] && should_exec=1
    else
        [[ "${(P)auto_exec_var:-0}" == "1" ]] && should_exec=1
    fi
    if (( should_exec )); then
        [[ ! "$id" =~ ^[A-Za-z0-9._:-]+$ ]] && { echo "Unsafe session id: $id" >&2; return 1; }
        command "$tool" "${resume_args[@]}"
    fi
}

# Echo the resume argv (one arg per line) for a given tool + session id.
# claude uses the --resume flag; every other tool (codex) uses a `resume`
# subcommand. Centralized so the invocation is defined in exactly one place.
_agent_session_resume_args() {
    local tool="$1" id="$2"
    case "$tool" in
        claude) printf '%s\n' "--resume" "$id" ;;
        *)      printf '%s\n' "resume" "$id" ;;
    esac
}

# =================================================================
# Codex wrappers (thin delegates to generic session manager)
# =================================================================
codex_session_add()    { _agent_session_add    codex "$CODEX_SESSIONS_FILE" "$@"; }
codex_session_update() { _agent_session_update codex "$CODEX_SESSIONS_FILE" "$@"; }
codex_session_remove() { _agent_session_remove codex "$CODEX_SESSIONS_FILE" "$1"; }
codex_session_list()   { _agent_session_list   codex "$CODEX_SESSIONS_FILE"; }
codex_session_edit()   { _agent_session_edit   "$CODEX_SESSIONS_FILE"; }
codex_session()        { _agent_session_resume codex "$CODEX_SESSIONS_FILE" "$@"; }

codex_start_net() {
    command -v codex >/dev/null 2>&1 || { echo "codex not found on PATH" >&2; return 1; }
    codex --sandbox workspace-write -a on-request -c network_access="enabled" "$@"
}
codex_start_danger() {
    command -v codex >/dev/null 2>&1 || { echo "codex not found on PATH" >&2; return 1; }
    codex --dangerously-bypass-approvals-and-sandbox "$@"
}

# =================================================================
# Claude wrappers (thin delegates to generic session manager)
# =================================================================
claude_session_add()    { _agent_session_add    claude "$CLAUDE_SESSIONS_FILE" "$@"; }
claude_session_update() { _agent_session_update claude "$CLAUDE_SESSIONS_FILE" "$@"; }
claude_session_remove() { _agent_session_remove claude "$CLAUDE_SESSIONS_FILE" "$1"; }
claude_session_list()   { _agent_session_list   claude "$CLAUDE_SESSIONS_FILE"; }
claude_session_edit()   { _agent_session_edit   "$CLAUDE_SESSIONS_FILE"; }
claude_session()        { _agent_session_resume claude "$CLAUDE_SESSIONS_FILE" "$@"; }

# =================================================================
# Claude project initialization
# =================================================================

claude_init() {
    local project_name org_name git_root current_date
    local add_to_sessions=false
    local claude_configs_repo="${CLAUDE_CONFIGS_REPO:-https://github.com/siege-analytics/claude-configs.git}"

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project)
                project_name="$2"
                shift 2
                ;;
            --org)
                org_name="$2"
                shift 2
                ;;
            --git-root)
                git_root="$2"
                shift 2
                ;;
            --add-session)
                add_to_sessions=true
                shift
                ;;
            --help)
                cat <<'HELP'
Usage: claude_init [OPTIONS]

Initialize Claude Code configuration in the current directory.

Options:
  --project NAME      Project name (default: auto-detect from directory/git)
  --org NAME          Organization name (default: auto-detect from git remote)
  --git-root PATH     Git root path (default: parent directory)
  --add-session       Add project to claude_session list
  --help              Show this help message

Examples:
  claude_init                           # Auto-detect everything
  claude_init --project myapp --org myorg
  claude_init --add-session             # Also add to session list
HELP
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                echo "Use --help for usage information" >&2
                return 1
                ;;
        esac
    done

    # Auto-detect project name
    if [[ -z "$project_name" ]]; then
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            # Try to get from git remote
            local remote_url
            remote_url="$(git remote get-url origin 2>/dev/null || true)"
            if [[ -n "$remote_url" ]]; then
                # Extract repo name from git@github.com:org/repo.git or https://github.com/org/repo.git
                project_name="${remote_url##*/}"
                project_name="${project_name%.git}"
            fi
        fi
        # Fallback to directory name
        if [[ -z "$project_name" ]]; then
            project_name="${PWD:t}"
        fi
    fi

    # Auto-detect organization name
    if [[ -z "$org_name" ]]; then
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local remote_url
            remote_url="$(git remote get-url origin 2>/dev/null || true)"
            if [[ -n "$remote_url" ]]; then
                # Extract org from git@github.com:org/repo.git or https://github.com/org/repo.git
                org_name="${remote_url#*[:/]}"
                org_name="${org_name%%/*}"
            fi
        fi
        # Fallback to project name
        if [[ -z "$org_name" ]]; then
            org_name="$project_name"
        fi
    fi

    # Auto-detect git root
    if [[ -z "$git_root" ]]; then
        git_root="${PWD:h}"
    fi

    # Current date
    current_date="$(date +%Y-%m-%d)"

    echo "Initializing Claude Code configuration..."
    echo "  Project: $project_name"
    echo "  Organization: $org_name"
    echo "  Git root: $git_root"
    echo ""

    # Check if already initialized
    if [[ -d .claude ]]; then
        echo "⚠️  .claude/ directory already exists"
        read -r "reply?Reinitialize? This will preserve existing files but may update skills. [y/N]: "
        if [[ ! "$reply" =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            return 1
        fi
    fi

    # Create .claude directory
    mkdir -p .claude

    # Clone and copy skills and templates (works for both git and non-git repos)
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    echo "Fetching skills and templates from $claude_configs_repo..."
    if command -v gh >/dev/null 2>&1; then
        gh repo clone siege-analytics/claude-configs "$tmp_dir" -- --depth 1 >/dev/null 2>&1 || \
            git clone --depth 1 "$claude_configs_repo" "$tmp_dir" >/dev/null 2>&1
    else
        git clone --depth 1 "$claude_configs_repo" "$tmp_dir" >/dev/null 2>&1
    fi
    if [[ -d "$tmp_dir/.git" || -d "$tmp_dir/templates" ]]; then
        cp -r "$tmp_dir/skills" .claude/

        # Store templates for later use
        local templates_dir="$tmp_dir/templates"

        echo "✅ Skills copied to .claude/skills/"

        # If in a git repo, set up subtree tracking for future updates
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            git add .claude/skills
            echo ""
            echo "💡 To update skills in the future, run:"
            echo "   git subtree pull --prefix .claude/skills $claude_configs_repo main --squash"
        fi

        # Generate CLAUDE.md from template
        if [[ ! -f CLAUDE.md ]] || { echo "CLAUDE.md exists."; read -q "?Overwrite? [y/N]: " }; then
            echo ""
            echo "Generating CLAUDE.md from template..."
            if [[ -f "$templates_dir/CLAUDE.md.template" ]]; then
                local template_content
                template_content="$(<"$templates_dir/CLAUDE.md.template")"
                # Substitute variables
                template_content="${template_content//\{\{PROJECT_NAME\}\}/$project_name}"
                template_content="${template_content//\{\{ORG_NAME\}\}/$org_name}"
                template_content="${template_content//\{\{GIT_ROOT\}\}/$git_root}"
                template_content="${template_content//\{\{CURRENT_DATE\}\}/$current_date}"

                echo "$template_content" > CLAUDE.md
                echo "✅ CLAUDE.md created"
                echo "   Edit CLAUDE.md to add project-specific content"
            else
                echo "⚠️  Template not found, using fallback"
                cat > CLAUDE.md <<EOF
# $project_name

> **SESSION START**: Always read all markdown files in $project_name repositories at session start:
> \`\`\`
> $git_root/$project_name/CLAUDE.md
> $git_root/$project_name/*/CLAUDE.md
> $git_root/$project_name/docs/*.md
> \`\`\`

## Attribution Policy

**NEVER** include AI assistant attribution in commits, PRs, issues, comments, or any public-facing content.

## Project Overview

[Add project description here]

---

*Last updated: $current_date*
EOF
            echo "✅ CLAUDE.md created from fallback template"
        fi
    fi

        # Copy settings.local.json
        if [[ ! -f .claude/settings.local.json ]] || { echo "settings.local.json exists."; read -q "?Overwrite? [y/N]: " }; then
            echo ""
            echo "Copying settings.local.json..."
            if [[ -f "$templates_dir/settings.local.json" ]]; then
                cp "$templates_dir/settings.local.json" .claude/settings.local.json
                echo "✅ .claude/settings.local.json created"
                echo "   Edit to add project-specific permissions"
            else
                echo "⚠️  Settings template not found" >&2
            fi
        fi

        # Clean up temp directory
        rm -rf "$tmp_dir"
    else
        echo "❌ Failed to clone claude-configs repository" >&2
        rm -rf "$tmp_dir"
        return 1
    fi

    echo ""
    echo "✅ Claude Code initialization complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Edit CLAUDE.md to add project-specific context"
    echo "  2. Edit .claude/settings.local.json to add necessary permissions"
    echo "  3. Customize skills in .claude/skills/ as needed"
    echo "  4. Start a Claude session: claude"

    # Optionally add to session list
    if [[ "$add_to_sessions" == true ]]; then
        echo ""
        read -r "session_name?Enter session name (e.g., ${project_name}_dev): "
        if [[ -n "$session_name" ]]; then
            read -r "session_desc?Enter session description (optional): "
            local session_value="${PWD}"
            if [[ -n "$session_desc" ]]; then
                session_value="${PWD}|${session_desc}"
            fi
            claude_session_add --name "$session_name" --value "$session_value"
            echo "✅ Added to Claude session list: $session_name"
        fi
    fi
}

# =================================================================
# Codex + Combined project initialization
# =================================================================

_agents_detect_project_name() {
    local remote_url
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        remote_url="$(git remote get-url origin 2>/dev/null || true)"
        if [[ -n "$remote_url" ]]; then
            local p="${remote_url##*/}"
            echo "${p%.git}"
            return 0
        fi
    fi
    echo "${PWD:t}"
}

_agents_detect_org_name() {
    local remote_url
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        remote_url="$(git remote get-url origin 2>/dev/null || true)"
        if [[ -n "$remote_url" ]]; then
            local o="${remote_url#*[:/]}"
            echo "${o%%/*}"
            return 0
        fi
    fi
    echo "$(_agents_detect_project_name)"
}

_agents_detect_git_root() {
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        git rev-parse --show-toplevel 2>/dev/null || echo "$PWD"
        return 0
    fi
    echo "$PWD"
}

_agents_write_codex_agents_md() {
    local out="$1"
    local project_name="$2"
    local org_name="$3"
    local git_root="$4"
    local role="$5"
    local approval="$6"
    local sandbox="$7"
    cat > "$out" <<EOF
# AGENTS.md

## Role
\`$role\`

## Execution Defaults
- Approval mode: \`$approval\`
- Sandbox mode: \`$sandbox\`
- Destructive operations: require explicit confirmation.

## Project Context
- Project: \`$project_name\`
- Organization: \`$org_name\`
- Workspace root: \`$git_root\`

## Working Rules
- Plan first, then execute.
- Prefer targeted edits over broad changes.
- Run tests for changed behavior before presenting results.
- Keep commits focused and reversible.
- No AI attribution in commits, comments, docs, or PRs.
- Never use phrases like "created with", "generated by", or "co-authored-by AI".

## Escalation Rules
- Ask before destructive operations (\`rm -rf\`, reset, force push).
- Ask before changing external infrastructure or production data.
- Ask before introducing long-running background processes.

## Initialization Notes
- Update this file with domain-specific constraints and architecture.
- Keep secrets out of the repository.
EOF
}

_agents_write_codex_settings() {
    local out="$1"
    local role="$2"
    local approval="$3"
    local sandbox="$4"
    cat > "$out" <<EOF
{
  "defaults": {
    "role": "$role",
    "approval_mode": "$approval",
    "sandbox_mode": "$sandbox"
  },
  "rules": {
    "ask_before_destructive": true,
    "no_ai_attribution": true,
    "forbid_created_with_phrasing": true,
    "require_tests_for_behavior_changes": true
  }
}
EOF
}

_agents_merge_codex_agents_md() {
    local file="$1"
    local -a required_rules
    required_rules=(
        "- Plan first, then execute."
        "- Run tests for changed behavior before presenting results."
        "- No AI attribution in commits, comments, docs, or PRs."
        "- Never use phrases like \"created with\", \"generated by\", or \"co-authored-by AI\"."
    )

    local -a missing_rules
    local line
    for line in "${required_rules[@]}"; do
        if ! grep -Fqx -- "$line" "$file" 2>/dev/null; then
            missing_rules+=("$line")
        fi
    done

    [[ ${#missing_rules[@]} -eq 0 ]] && return 0

    {
        echo
        echo "## Codex Managed Rules"
        for line in "${missing_rules[@]}"; do
            echo "$line"
        done
    } >> "$file"
}

_agents_merge_codex_settings() {
    local out="$1"
    local role="$2"
    local approval="$3"
    local sandbox="$4"

    python3 - "$out" "$role" "$approval" "$sandbox" <<'PY'
import json
import os
import sys

path, role, approval, sandbox = sys.argv[1:5]
data = {}

if os.path.exists(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if not isinstance(data, dict):
            data = {}
    except Exception:
        data = {}

defaults = data.setdefault("defaults", {})
if not isinstance(defaults, dict):
    defaults = {}
    data["defaults"] = defaults
defaults.setdefault("role", role)
defaults.setdefault("approval_mode", approval)
defaults.setdefault("sandbox_mode", sandbox)

rules = data.setdefault("rules", {})
if not isinstance(rules, dict):
    rules = {}
    data["rules"] = rules
rules["ask_before_destructive"] = True
rules["no_ai_attribution"] = True
rules["forbid_created_with_phrasing"] = True
rules["require_tests_for_behavior_changes"] = True

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, sort_keys=False)
    f.write("\n")
PY
}

codex_init() {
    local project_name=""
    local org_name=""
    local git_root=""
    local role="${CODEX_DEFAULT_ROLE:-Senior pragmatic software engineer}"
    local approval="${CODEX_DEFAULT_APPROVAL:-on-request}"
    local sandbox="${CODEX_DEFAULT_SANDBOX:-workspace-write}"
    local add_to_sessions=false
    local session_name=""
    local session_desc=""
    local update=0
    local yes=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project_name="${2:-}"; shift 2 ;;
            --org) org_name="${2:-}"; shift 2 ;;
            --git-root) git_root="${2:-}"; shift 2 ;;
            --role) role="${2:-}"; shift 2 ;;
            --approval) approval="${2:-}"; shift 2 ;;
            --sandbox) sandbox="${2:-}"; shift 2 ;;
            --add-session) add_to_sessions=true; shift ;;
            --session-name) session_name="${2:-}"; shift 2 ;;
            --session-desc) session_desc="${2:-}"; shift 2 ;;
            --update) update=1; shift ;;
            --yes|-y) yes=1; shift ;;
            --help)
                cat <<'HELP'
Usage: codex_init [OPTIONS]

Initialize Codex-oriented project config in the current directory.

Options:
  --project NAME         Project name (auto-detected if omitted)
  --org NAME             Organization name (auto-detected if omitted)
  --git-root PATH        Workspace root (auto-detected if omitted)
  --role TEXT            Default role/persona
  --approval MODE        Default approval mode (default: on-request)
  --sandbox MODE         Default sandbox mode (default: workspace-write)
  --add-session          Add this project to codex_session list
  --session-name NAME    Session key to use with --add-session
  --session-desc TEXT    Session description with --add-session
  --update               Merge required rules into existing files
  --yes, -y              Overwrite existing files without prompt
HELP
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    [[ -n "$project_name" ]] || project_name="$(_agents_detect_project_name)"
    [[ -n "$org_name" ]] || org_name="$(_agents_detect_org_name)"
    [[ -n "$git_root" ]] || git_root="$(_agents_detect_git_root)"

    mkdir -p .codex

    local agents_file="AGENTS.md"
    local settings_file=".codex/settings.local.json"
    local state_file=".codex/init.env"

    if [[ "$update" -ne 1 && -f "$agents_file" && "$yes" -ne 1 ]]; then
        read -r "reply?AGENTS.md exists. Overwrite? [y/N]: "
        [[ "$reply" =~ ^[Yy]$ ]] || return 1
    fi
    if [[ "$update" -ne 1 && -f "$settings_file" && "$yes" -ne 1 ]]; then
        read -r "reply?.codex/settings.local.json exists. Overwrite? [y/N]: "
        [[ "$reply" =~ ^[Yy]$ ]] || return 1
    fi

    if [[ "$update" -eq 1 ]]; then
        if [[ -f "$agents_file" ]]; then
            _agents_merge_codex_agents_md "$agents_file"
        else
            _agents_write_codex_agents_md "$agents_file" "$project_name" "$org_name" "$git_root" "$role" "$approval" "$sandbox"
        fi
        _agents_merge_codex_settings "$settings_file" "$role" "$approval" "$sandbox"
    else
        _agents_write_codex_agents_md "$agents_file" "$project_name" "$org_name" "$git_root" "$role" "$approval" "$sandbox"
        _agents_write_codex_settings "$settings_file" "$role" "$approval" "$sandbox"
    fi

    cat > "$state_file" <<EOF
PROJECT_NAME=$project_name
ORG_NAME=$org_name
GIT_ROOT=$git_root
ROLE=$role
APPROVAL=$approval
SANDBOX=$sandbox
EOF

    echo "✅ Codex config initialized"
    echo "   - $agents_file"
    echo "   - $settings_file"
    echo "   - $state_file"

    if [[ "$add_to_sessions" == true ]]; then
        if [[ -z "$session_name" ]]; then
            if [[ -o interactive ]]; then
                read -r "session_name?Enter Codex session name (e.g., ${project_name}_dev): "
            else
                session_name="${project_name}_dev"
            fi
        fi
        if [[ -n "$session_name" && -z "$session_desc" && -o interactive ]]; then
            read -r "session_desc?Enter session description (optional): "
        fi
        if [[ -n "$session_name" ]]; then
            local session_value="${PWD}"
            if [[ -n "$session_desc" ]]; then
                session_value="${PWD}|${session_desc}"
            fi
            if _codex_sessions_get "$session_name" >/dev/null 2>&1; then
                codex_session_update --name "$session_name" --value "$session_value"
                echo "✅ Updated Codex session: $session_name"
            else
                codex_session_add --name "$session_name" --value "$session_value"
                echo "✅ Added Codex session: $session_name"
            fi
        fi
    fi
}

ai_init() {
    local claude_only=0
    local codex_only=0
    local pass=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --claude-only) claude_only=1; shift ;;
            --codex-only) codex_only=1; shift ;;
            *) pass+=("$1"); shift ;;
        esac
    done

    if [[ "$claude_only" -eq 1 && "$codex_only" -eq 1 ]]; then
        echo "Cannot set both --claude-only and --codex-only" >&2
        return 1
    fi

    if [[ "$codex_only" -eq 0 ]]; then
        claude_init "${pass[@]}" || return 1
    fi
    if [[ "$claude_only" -eq 0 ]]; then
        codex_init "${pass[@]}" || return 1
    fi
}

# =================================================================
# Electron app window repair
# =================================================================
# Electron apps sometimes launch with no visible window due to corrupt
# or empty window state data. This generic function handles the fix for
# any Electron app.
#
# Two window-state storage patterns exist in the wild:
#   "standalone"  — a dedicated window-state.json (Craft Agents, Claude)
#   "embedded"    — a key inside a larger JSON file like Preferences or
#                   storage.json (VS Code, Cursor, Slack)
#
# Per-app wrappers below configure the right paths and call the generic
# engine.  To add a new app, define a wrapper that calls
# _electron_fix_window with the appropriate arguments.

# --- generic engine ------------------------------------------------

_electron_fix_window() {
    local app_name=""           # display name, e.g. "Craft Agents"
    local process_name=""       # killall target (defaults to app_name)
    local app_path=""           # /Applications/Foo.app
    local state_file=""         # path to window-state file
    local state_format=""       # "standalone" | "embedded"
    local state_key=""          # JSON key when format=embedded
    local lock_files=()         # extra files to remove before relaunch
    local state_builder=""      # optional function that prints the JSON value to write

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --app-name)      app_name="$2";      shift 2 ;;
            --process-name)  process_name="$2";  shift 2 ;;
            --app-path)      app_path="$2";      shift 2 ;;
            --state-file)    state_file="$2";    shift 2 ;;
            --state-format)  state_format="$2";  shift 2 ;;
            --state-key)     state_key="$2";     shift 2 ;;
            --lock-file)     lock_files+=("$2"); shift 2 ;;
            --state-builder) state_builder="$2"; shift 2 ;;
            *) echo "Unknown option: $1" >&2; return 1 ;;
        esac
    done

    : "${process_name:=$app_name}"
    local default_bounds='{ "x": 100, "y": 100, "width": 1200, "height": 800 }'

    if [[ -z "$app_name" || -z "$state_file" || -z "$state_format" ]]; then
        echo "Usage: _electron_fix_window --app-name NAME --state-file PATH --state-format standalone|embedded [options]" >&2
        return 1
    fi

    echo "Repairing ${app_name}..."

    # 1. Kill the app
    killall "$process_name" 2>/dev/null
    sleep "${ELECTRON_FIX_KILL_DELAY:-1}"

    # 2. Remove stale lock files
    local lf
    for lf in "${lock_files[@]}"; do
        [[ -f "$lf" ]] && rm -f "$lf" && echo "  Removed lock: $lf"
    done

    # 3. Build the replacement state value
    local new_state
    if [[ -n "$state_builder" ]]; then
        new_state="$($state_builder)" || { echo "  State builder failed" >&2; return 1; }
    else
        new_state="$default_bounds"
    fi

    # 4. Write it
    mkdir -p "${state_file:h}" 2>/dev/null
    case "$state_format" in
        standalone)
            echo "$new_state" > "$state_file"
            echo "  Wrote $state_file"
            ;;
        embedded)
            if [[ -z "$state_key" ]]; then
                echo "  --state-key required for embedded format" >&2; return 1
            fi
            if [[ ! -f "$state_file" ]]; then
                echo "  State file not found: $state_file" >&2; return 1
            fi
            python3 -c "
import json, sys
path, key = sys.argv[1], sys.argv[2]
new_val = json.loads(sys.argv[3])
with open(path, 'r') as f:
    data = json.load(f)
data[key] = new_val
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" "$state_file" "$state_key" "$new_state" || { echo "  Failed to patch $state_file" >&2; return 1; }
            echo "  Patched key '$state_key' in $state_file"
            ;;
        *)
            echo "  Unknown format: $state_format" >&2; return 1
            ;;
    esac

    # 5. Relaunch
    if [[ -n "$app_path" && -d "$app_path" ]]; then
        open "$app_path"
    else
        open -a "$app_name"
    fi
    sleep "${ELECTRON_FIX_LAUNCH_DELAY:-3}"

    # 6. Verify a window appeared
    local wcount
    wcount="$(osascript -e "
        tell application \"System Events\"
            tell process \"$process_name\"
                return count of windows
            end tell
        end tell
    " 2>/dev/null)"

    if [[ "$wcount" -gt 0 ]]; then
        echo "  Window visible ($wcount window(s))"
    else
        echo "  Warning: no window detected after repair." >&2
        return 1
    fi
}

# --- per-app wrappers ----------------------------------------------

# Craft Agents: standalone window-state.json with workspace ID
_craft_agents_state_builder() {
    local config_file="$HOME/.craft-agent/config.json"
    python3 -c "
import json
c = json.load(open('$config_file'))
wid = c.get('activeWorkspaceId') or c.get('workspaces', [{}])[0].get('id', '')
if not wid:
    raise SystemExit('no workspace')
print(json.dumps({
    'windows': [{
        'workspaceId': wid,
        'bounds': {'x': 100, 'y': 100, 'width': 1200, 'height': 800},
        'focused': True
    }]
}, indent=2))
" 2>/dev/null
}

craft_agents_fix() {
    _electron_fix_window \
        --app-name      "Craft Agents" \
        --app-path      "/Applications/Craft Agents.app" \
        --state-file    "$HOME/.craft-agent/window-state.json" \
        --state-format  standalone \
        --lock-file     "$HOME/.craft-agent/.server.lock" \
        --state-builder _craft_agents_state_builder
}

# Claude desktop: standalone window-state.json, flat bounds object
claude_desktop_fix() {
    _electron_fix_window \
        --app-name      "Claude" \
        --app-path      "/Applications/Claude.app" \
        --state-file    "$HOME/Library/Application Support/Claude/window-state.json" \
        --state-format  standalone
}

# VS Code: embedded in storage.json under "windowsState"
vscode_fix() {
    local storage="$HOME/Library/Application Support/Code/User/globalStorage/storage.json"
    _electron_fix_window \
        --app-name      "Code" \
        --process-name  "Electron" \
        --app-path      "/Applications/Visual Studio Code.app" \
        --state-file    "$storage" \
        --state-format  embedded \
        --state-key     "windowsState"
}

# Cursor: same layout as VS Code
cursor_fix() {
    local storage="$HOME/Library/Application Support/Cursor/User/globalStorage/storage.json"
    _electron_fix_window \
        --app-name      "Cursor" \
        --app-path      "/Applications/Cursor.app" \
        --state-file    "$storage" \
        --state-format  embedded \
        --state-key     "windowsState"
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ agents loaded"
fi
