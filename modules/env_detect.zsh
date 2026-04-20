#!/usr/bin/env zsh
# =================================================================
# ENV_DETECT — environment detection registry
# =================================================================
# Consolidated inspection helpers. Modules that want to answer "what
# terminal / mode are we in?" should ask the registry instead of
# reimplementing the check.
#
# The registry does NOT replace the existing zshrc-level helpers
# (_zsh_is_warp_terminal, detect_ide, _zsh_startup_use_staggered);
# it wraps them plus a couple of new checks into a single
# introspectable surface.

# Print a line-per-fact snapshot of the shell's detected environment.
# Stable key=value format, safe for scripting and for zsh_doctor use.
zsh_env_snapshot() {
    emulate -L zsh
    local is_ide=0 is_warp=0 is_vscode=0 is_cursor=0 is_ci=0 is_staggered=0

    if (( ${+functions[detect_ide]} )) && detect_ide 2>/dev/null; then
        is_ide=1
    fi
    if (( ${+functions[_zsh_is_warp_terminal]} )) && _zsh_is_warp_terminal; then
        is_warp=1
    fi
    [[ "${TERM_PROGRAM:-}" == "vscode" ]] && is_vscode=1
    [[ "${TERM_PROGRAM:-}" == "Cursor" ]] && is_cursor=1
    [[ -n "${GITHUB_ACTIONS:-}${CI:-}" ]] && is_ci=1
    if (( ${+functions[_zsh_startup_use_staggered]} )) && _zsh_startup_use_staggered; then
        is_staggered=1
    fi

    printf 'os=%s\n' "$OSTYPE"
    printf 'shell=%s\n' "zsh $ZSH_VERSION"
    printf 'term_program=%s\n' "${TERM_PROGRAM:-unknown}"
    printf 'is_warp=%d\n' "$is_warp"
    printf 'is_vscode=%d\n' "$is_vscode"
    printf 'is_cursor=%d\n' "$is_cursor"
    printf 'is_ide=%d\n' "$is_ide"
    printf 'is_ci=%d\n' "$is_ci"
    printf 'is_staggered=%d\n' "$is_staggered"
    printf 'full_init=%s\n' "${ZSH_FORCE_FULL_INIT:-0}"
    printf 'test_mode=%s\n' "${ZSH_TEST_MODE:-0}"
    printf 'profile=%s\n' "${ZSH_PROFILE:-0}"
}

# Query a single fact by name. Useful in conditionals:
#   if [[ "$(zsh_env is_warp)" == "1" ]]; then ...
zsh_env() {
    local key="${1:-}"
    [[ -z "$key" ]] && { zsh_env_snapshot; return 0; }
    zsh_env_snapshot | awk -F= -v k="$key" '$1==k {print $2; found=1} END {exit !found}'
}
