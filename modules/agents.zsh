#!/usr/bin/env zsh
# =================================================================
# AGENTS - Codex & Claude session helpers
# =================================================================

: "${CODEX_SESSIONS_FILE:=$HOME/.config/zsh/codex-sessions.env}"
: "${CLAUDE_SESSIONS_FILE:=$HOME/.config/zsh/claude-sessions.env}"

_codex_sessions_ensure_file() {
    local file="$CODEX_SESSIONS_FILE"
    if [[ ! -f "$file" ]]; then
        umask 077
        touch "$file" 2>/dev/null || return 1
    fi
    return 0
}

_codex_sessions_list_keys() {
    local file="$CODEX_SESSIONS_FILE"
    [[ -f "$file" ]] || return 0
    awk -F'=' '
        /^[[:space:]]*#/ {next}
        /^[[:space:]]*$/ {next}
        {print $1}
    ' "$file"
}

_codex_sessions_get() {
    local key="$1"
    local file="$CODEX_SESSIONS_FILE"
    [[ -f "$file" ]] || return 1
    awk -F'=' -v k="$key" '
        $1==k {print $2; found=1}
        END {exit found?0:1}
    ' "$file"
}

codex_session_add() {
    local key="$1"
    shift || true
    local value="$*"
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: codex_session_add <name> <id>|<description>" >&2
        echo "Example: codex_session_add zsh_work \"019b...|ZSH refactor work\"" >&2
        return 1
    fi
    _codex_sessions_ensure_file || { echo "Cannot write $CODEX_SESSIONS_FILE" >&2; return 1; }
    if _codex_sessions_get "$key" >/dev/null 2>&1; then
        echo "Key exists: $key (use codex_session_update)" >&2
        return 1
    fi
    printf '%s=%s\n' "$key" "$value" >> "$CODEX_SESSIONS_FILE"
}

codex_session_update() {
    local key="$1"
    shift || true
    local value="$*"
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: codex_session_update <name> <id>|<description>" >&2
        return 1
    fi
    _codex_sessions_ensure_file || { echo "Cannot write $CODEX_SESSIONS_FILE" >&2; return 1; }
    local tmp
    tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" -v v="$value" '
        BEGIN {updated=0}
        $1==k {print k "=" v; updated=1; next}
        {print}
        END {if (!updated) exit 2}
    ' "$CODEX_SESSIONS_FILE" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then
        rm -f "$tmp"
        echo "Key not found: $key" >&2
        return 1
    fi
    mv "$tmp" "$CODEX_SESSIONS_FILE"
}

codex_session_remove() {
    local key="$1"
    if [[ -z "$key" ]]; then
        echo "Usage: codex_session_remove <name>" >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" '
        $1==k {removed=1; next}
        {print}
        END {if (!removed) exit 2}
    ' "$CODEX_SESSIONS_FILE" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then
        rm -f "$tmp"
        echo "Key not found: $key" >&2
        return 1
    fi
    mv "$tmp" "$CODEX_SESSIONS_FILE"
}

codex_session_list() {
    _codex_sessions_ensure_file || return 1
    echo "Codex sessions: $CODEX_SESSIONS_FILE"
    awk -F'=' '
        /^[[:space:]]*#/ {next}
        /^[[:space:]]*$/ {next}
        {
            printf "%-20s | %s\n", $1, $2
        }
    ' "$CODEX_SESSIONS_FILE"
}

codex_session_edit() {
    _codex_sessions_ensure_file || return 1
    "${EDITOR:-vi}" "$CODEX_SESSIONS_FILE"
}

codex_session() {
    local key="$1"
    _codex_sessions_ensure_file || return 1
    if [[ -z "$key" ]]; then
        local choice=""
        if command -v fzf >/dev/null 2>&1; then
            choice="$(_codex_sessions_list_keys | fzf --prompt='codex session> ')"
        else
            local keys
            keys=($(_codex_sessions_list_keys))
            if [[ ${#keys[@]} -eq 0 ]]; then
                echo "No sessions saved." >&2
                return 1
            fi
            echo "Select session:"
            select key in "${keys[@]}"; do
                choice="$key"
                break
            done
        fi
        key="$choice"
    fi
    if [[ -z "$key" ]]; then
        return 1
    fi
    local entry
    entry="$(_codex_sessions_get "$key" 2>/dev/null || true)"
    if [[ -z "$entry" ]]; then
        echo "Key not found: $key" >&2
        return 1
    fi
    local id desc
    id="${entry%%|*}"
    desc="${entry#*|}"
    if [[ "$id" == "$desc" ]]; then
        desc=""
    fi
    local cmd="codex resume $id"
    if [[ -n "$desc" ]]; then
        echo "$cmd  # $desc"
    else
        echo "$cmd"
    fi
    local reply="y"
    local should_exec=0
    if [[ -o interactive ]]; then
        read -r "reply?Execute command? [Y/n]: "
        reply="${reply:-y}"
        [[ "$reply" =~ ^[Yy]$ ]] && should_exec=1
    else
        # Non-interactive mode defaults to "show only" unless explicitly enabled.
        [[ "${CODEX_SESSION_AUTO_EXEC_NONINTERACTIVE:-0}" == "1" ]] && should_exec=1
    fi
    if (( should_exec )); then
        if [[ ! "$id" =~ ^[A-Za-z0-9._:-]+$ ]]; then
            echo "Unsafe session id; refusing execution: $id" >&2
            return 1
        fi
        command codex resume "$id"
    fi
}

codex_start_net() {
    if ! command -v codex >/dev/null 2>&1; then
        echo "codex not found on PATH" >&2
        return 1
    fi
    codex --sandbox workspace-write -a on-request -c network_access="enabled" "$@"
}

codex_start_danger() {
    if ! command -v codex >/dev/null 2>&1; then
        echo "codex not found on PATH" >&2
        return 1
    fi
    codex --dangerously-bypass-approvals-and-sandbox "$@"
}

# =================================================================
# Claude session helpers
# =================================================================

_claude_sessions_ensure_file() {
    local file="$CLAUDE_SESSIONS_FILE"
    if [[ ! -f "$file" ]]; then
        umask 077
        touch "$file" 2>/dev/null || return 1
    fi
    return 0
}

_claude_sessions_list_keys() {
    local file="$CLAUDE_SESSIONS_FILE"
    [[ -f "$file" ]] || return 0
    awk -F'=' '
        /^[[:space:]]*#/ {next}
        /^[[:space:]]*$/ {next}
        {print $1}
    ' "$file"
}

_claude_sessions_get() {
    local key="$1"
    local file="$CLAUDE_SESSIONS_FILE"
    [[ -f "$file" ]] || return 1
    awk -F'=' -v k="$key" '
        $1==k {print $2; found=1}
        END {exit found?0:1}
    ' "$file"
}

claude_session_add() {
    local key="$1"
    shift || true
    local value="$*"
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: claude_session_add <name> <id>|<description>" >&2
        echo "Example: claude_session_add zsh_work \"019b...|ZSH refactor work\"" >&2
        return 1
    fi
    _claude_sessions_ensure_file || { echo "Cannot write $CLAUDE_SESSIONS_FILE" >&2; return 1; }
    if _claude_sessions_get "$key" >/dev/null 2>&1; then
        echo "Key exists: $key (use claude_session_update)" >&2
        return 1
    fi
    printf '%s=%s\n' "$key" "$value" >> "$CLAUDE_SESSIONS_FILE"
}

claude_session_update() {
    local key="$1"
    shift || true
    local value="$*"
    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: claude_session_update <name> <id>|<description>" >&2
        return 1
    fi
    _claude_sessions_ensure_file || { echo "Cannot write $CLAUDE_SESSIONS_FILE" >&2; return 1; }
    local tmp
    tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" -v v="$value" '
        BEGIN {updated=0}
        $1==k {print k "=" v; updated=1; next}
        {print}
        END {if (!updated) exit 2}
    ' "$CLAUDE_SESSIONS_FILE" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then
        rm -f "$tmp"
        echo "Key not found: $key" >&2
        return 1
    fi
    mv "$tmp" "$CLAUDE_SESSIONS_FILE"
}

claude_session_remove() {
    local key="$1"
    if [[ -z "$key" ]]; then
        echo "Usage: claude_session_remove <name>" >&2
        return 1
    fi
    local tmp
    tmp="$(mktemp)" || return 1
    awk -F'=' -v k="$key" '
        $1==k {removed=1; next}
        {print}
        END {if (!removed) exit 2}
    ' "$CLAUDE_SESSIONS_FILE" > "$tmp"
    local rc=$?
    if [[ $rc -eq 2 ]]; then
        rm -f "$tmp"
        echo "Key not found: $key" >&2
        return 1
    fi
    mv "$tmp" "$CLAUDE_SESSIONS_FILE"
}

claude_session_list() {
    _claude_sessions_ensure_file || return 1
    echo "Claude sessions: $CLAUDE_SESSIONS_FILE"
    awk -F'=' '
        /^[[:space:]]*#/ {next}
        /^[[:space:]]*$/ {next}
        {
            printf "%-20s | %s\n", $1, $2
        }
    ' "$CLAUDE_SESSIONS_FILE"
}

claude_session_edit() {
    _claude_sessions_ensure_file || return 1
    "${EDITOR:-vi}" "$CLAUDE_SESSIONS_FILE"
}

claude_session() {
    local key="$1"
    _claude_sessions_ensure_file || return 1
    if [[ -z "$key" ]]; then
        local choice=""
        if command -v fzf >/dev/null 2>&1; then
            choice="$(_claude_sessions_list_keys | fzf --prompt='claude session> ')"
        else
            local keys
            keys=($(_claude_sessions_list_keys))
            if [[ ${#keys[@]} -eq 0 ]]; then
                echo "No sessions saved." >&2
                return 1
            fi
            echo "Select session:"
            select key in "${keys[@]}"; do
                choice="$key"
                break
            done
        fi
        key="$choice"
    fi
    if [[ -z "$key" ]]; then
        return 1
    fi
    local entry
    entry="$(_claude_sessions_get "$key" 2>/dev/null || true)"
    if [[ -z "$entry" ]]; then
        echo "Key not found: $key" >&2
        return 1
    fi
    local id desc
    id="${entry%%|*}"
    desc="${entry#*|}"
    if [[ "$id" == "$desc" ]]; then
        desc=""
    fi
    local cmd="claude resume $id"
    if [[ -n "$desc" ]]; then
        echo "$cmd  # $desc"
    else
        echo "$cmd"
    fi
    local reply="y"
    local should_exec=0
    if [[ -o interactive ]]; then
        read -r "reply?Execute command? [Y/n]: "
        reply="${reply:-y}"
        [[ "$reply" =~ ^[Yy]$ ]] && should_exec=1
    else
        [[ "${CLAUDE_SESSION_AUTO_EXEC_NONINTERACTIVE:-0}" == "1" ]] && should_exec=1
    fi
    if (( should_exec )); then
        if [[ ! "$id" =~ ^[A-Za-z0-9._:-]+$ ]]; then
            echo "Unsafe session id; refusing execution: $id" >&2
            return 1
        fi
        command claude resume "$id"
    fi
}

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
            claude_session_add "$session_name" "$session_value"
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
    "require_tests_for_behavior_changes": true
  }
}
EOF
}

codex_init() {
    local project_name=""
    local org_name=""
    local git_root=""
    local role="${CODEX_DEFAULT_ROLE:-Senior pragmatic software engineer}"
    local approval="${CODEX_DEFAULT_APPROVAL:-on-request}"
    local sandbox="${CODEX_DEFAULT_SANDBOX:-workspace-write}"
    local yes=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project_name="${2:-}"; shift 2 ;;
            --org) org_name="${2:-}"; shift 2 ;;
            --git-root) git_root="${2:-}"; shift 2 ;;
            --role) role="${2:-}"; shift 2 ;;
            --approval) approval="${2:-}"; shift 2 ;;
            --sandbox) sandbox="${2:-}"; shift 2 ;;
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

    if [[ -f "$agents_file" && "$yes" -ne 1 ]]; then
        read -r "reply?AGENTS.md exists. Overwrite? [y/N]: "
        [[ "$reply" =~ ^[Yy]$ ]] || return 1
    fi
    if [[ -f "$settings_file" && "$yes" -ne 1 ]]; then
        read -r "reply?.codex/settings.local.json exists. Overwrite? [y/N]: "
        [[ "$reply" =~ ^[Yy]$ ]] || return 1
    fi

    _agents_write_codex_agents_md "$agents_file" "$project_name" "$org_name" "$git_root" "$role" "$approval" "$sandbox"
    _agents_write_codex_settings "$settings_file" "$role" "$approval" "$sandbox"

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

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ agents loaded"
fi
