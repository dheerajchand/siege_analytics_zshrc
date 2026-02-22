#!/usr/bin/env zsh
# =================================================================
# SETTINGS - Centralized user config (vars/paths/aliases)
# =================================================================

: "${ZSH_SETTINGS_DIR:=$HOME/.config/zsh}"
: "${ZSH_VARS_FILE:=$ZSH_SETTINGS_DIR/vars.env}"
: "${ZSH_ALIASES_FILE:=$ZSH_SETTINGS_DIR/aliases.zsh}"
: "${ZSH_PATHS_FILE:=$ZSH_SETTINGS_DIR/paths.env}"

_settings_detect_machine_profile() {
    if [[ -n "${ZSH_MACHINE_PROFILE:-}" ]]; then
        printf '%s\n' "${ZSH_MACHINE_PROFILE:l}"
        return 0
    fi
    if [[ -n "${ZSH_ENV_PROFILE:-}" ]]; then
        printf '%s\n' "${ZSH_ENV_PROFILE:l}"
        return 0
    fi
    local hn
    hn="$(hostname 2>/dev/null || echo "")"
    hn="${hn:l}"
    if [[ "$hn" == *cyberpower* ]]; then
        echo "cyberpower"
        return 0
    fi
    if [[ "$OSTYPE" == darwin* ]]; then
        echo "mac"
    else
        echo "linux"
    fi
}

: "${ZSH_MACHINE_PROFILE:=$(_settings_detect_machine_profile)}"
: "${ZSH_VARS_MACHINE_FILE:=$ZSH_SETTINGS_DIR/vars.${ZSH_MACHINE_PROFILE}.env}"

settings_persist_var() {
    local key="$1"
    local value="$2"
    local file="${3:-$ZSH_VARS_FILE}"
    [[ -z "$key" || -z "$file" ]] && return 1
    [[ -f "$file" ]] || touch "$file"
    python3 - "$file" "$key" "$value" <<'PY'
import sys
path, key, value = sys.argv[1:4]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()
needle = f'export {key}="'
new_line = f'export {key}="${{{key}:-{value}}}"'
updated = False
out = []
for line in lines:
    if line.startswith(needle):
        out.append(new_line)
        updated = True
    else:
        out.append(line)
if not updated:
    out.append(new_line)
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
}

settings_init() {
    local created=0
    umask 077
    if [[ ! -f "$ZSH_VARS_FILE" ]]; then
        cat > "$ZSH_VARS_FILE" <<'EOF'
# Custom variables (export VAR="value")
# Example:
# export JARS_DIR="$HOME/.jars"
# export PYENV_DEFAULT_VENV="default_31111"
EOF
        created=1
        echo "Created $ZSH_VARS_FILE"
    fi
    if [[ ! -f "$ZSH_ALIASES_FILE" ]]; then
        cat > "$ZSH_ALIASES_FILE" <<'EOF'
# Custom aliases
# Example:
# alias proj='cd ~/Projects'
EOF
        created=1
        echo "Created $ZSH_ALIASES_FILE"
    fi
    if [[ ! -f "$ZSH_PATHS_FILE" ]]; then
        cat > "$ZSH_PATHS_FILE" <<'EOF'
# Custom convenience paths
# Example:
# export WRITING_STUFF="$HOME/Documents/Writing_Projects/Current"
EOF
        created=1
        echo "Created $ZSH_PATHS_FILE"
    fi
    if [[ ! -f "$ZSH_VARS_MACHINE_FILE" ]]; then
        cat > "$ZSH_VARS_MACHINE_FILE" <<EOF
# Machine-specific variable overrides for profile: ${ZSH_MACHINE_PROFILE}
# Loaded after vars.env; values here override shared defaults.
# Example:
# export PYENV_DEFAULT_VENV="\${PYENV_DEFAULT_VENV:-default_31111}"
EOF
        created=1
        echo "Created $ZSH_VARS_MACHINE_FILE"
    fi
    [[ "$created" -eq 1 ]] || echo "All settings files already exist"
}

settings_edit_vars() {
    [[ -f "$ZSH_VARS_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_VARS_FILE"
}

settings_edit_vars_machine() {
    [[ -f "$ZSH_VARS_MACHINE_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_VARS_MACHINE_FILE"
}

settings_edit_aliases() {
    [[ -f "$ZSH_ALIASES_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_ALIASES_FILE"
}

settings_edit_paths() {
    [[ -f "$ZSH_PATHS_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_PATHS_FILE"
}

settings_status() {
    echo "⚙️  Settings"
    echo "============"
    echo "Profile: $ZSH_MACHINE_PROFILE"
    echo "Vars:    $ZSH_VARS_FILE"
    echo "Vars(M): $ZSH_VARS_MACHINE_FILE"
    echo "Aliases: $ZSH_ALIASES_FILE"
    echo "Paths:   $ZSH_PATHS_FILE"
}

# Load order: shared vars -> machine vars -> aliases -> paths
if [[ -f "$ZSH_VARS_FILE" ]]; then
    source "$ZSH_VARS_FILE"
fi
if [[ -f "$ZSH_VARS_MACHINE_FILE" ]]; then
    source "$ZSH_VARS_MACHINE_FILE"
fi
if [[ -f "$ZSH_ALIASES_FILE" ]]; then
    source "$ZSH_ALIASES_FILE"
fi
if [[ -f "$ZSH_PATHS_FILE" ]]; then
    export PATHS_LOADED=1
    source "$ZSH_PATHS_FILE"
fi

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ settings loaded"
fi
