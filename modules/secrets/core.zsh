#!/usr/bin/env zsh
# =================================================================
# SECRETS — core utility helpers
# =================================================================
# Pure string/value helpers and logging used throughout the secrets
# subsystem. No dependencies on `op`, filesystem state, or other
# secrets modules. Sourced first by the secrets umbrella.

# Warn to stderr with a visible prefix.
_secrets_warn() {
    emulate -L zsh
    echo "⚠️  $*" >&2
}

# Informational message; silenced in test mode. `emulate -L` insulates
# us from caller-imposed options (errexit/nounset/pipefail) so a
# false-first conditional (`[[ -n "" ]] && return 0`) doesn't trip
# under a strict-mode caller like run-tests.zsh (#137 investigation).
_secrets_info() {
    emulate -L zsh
    [[ -n "${ZSH_TEST_MODE:-}" ]] && return 0
    echo "🔐 $*"
}

# Debug trace; requires ZSH_SECRETS_DEBUG to be set.
_secrets_debug() {
    [[ -n "${ZSH_SECRETS_DEBUG:-}" ]] || return 0
    echo "[secrets:debug] $*" >&2
}

# Strip a trailing carriage return (handles CRLF line endings).
_secrets_strip_crlf() {
    local val="$1"
    val="${val%%$'\r'}"
    echo "$val"
}

# Trim leading and trailing whitespace.
_secrets_trim_ws() {
    local val="$1"
    while [[ "$val" == *[[:space:]] ]]; do
        val="${val%[[:space:]]}"
    done
    while [[ "$val" == [[:space:]]* ]]; do
        val="${val#[[:space:]]}"
    done
    echo "$val"
}

# Strip surrounding double or single quotes. POLICY: also strip an
# unmatched trailing quote, defensive against copy-paste artifacts
# in env files (e.g. KEY=UUID"). Set ZSH_STRIP_UNMATCHED_QUOTES=0 to
# disable.
_secrets_strip_quotes() {
    local val="$1"
    if [[ "$val" == \"*\" ]]; then
        val="${val#\"}"
        val="${val%\"}"
    elif [[ "$val" == \'*\' ]]; then
        val="${val#\'}"
        val="${val%\'}"
    fi
    if [[ "${ZSH_STRIP_UNMATCHED_QUOTES:-1}" != "0" ]]; then
        val="${val%\"}"
        val="${val%\'}"
    fi
    echo "$val"
}

# Canonicalize a raw value: strip CRLF, trim whitespace, strip quotes.
_secrets_normalize_value() {
    local val="$1"
    val="$(_secrets_strip_crlf "$val")"
    val="$(_secrets_trim_ws "$val")"
    val="$(_secrets_strip_quotes "$val")"
    echo "$val"
}

# Normalize ZSH_SECRETS_MODE in place.
_secrets_normalize_mode() {
    if [[ -n "${ZSH_SECRETS_MODE:-}" ]]; then
        export ZSH_SECRETS_MODE="$(_secrets_normalize_value "$ZSH_SECRETS_MODE")"
    fi
}

# Decide whether the current shell should prefer the agent env cache
# over a live 1Password session. Returns 0 if cache should be preferred.
_secrets_startup_prefers_agent_cache() {
    local mode="${ZSH_SECRETS_STARTUP_SOURCE:-auto}"
    mode="${mode:l}"
    case "$mode" in
        cache) return 0 ;;
        live) return 1 ;;
        auto)
            [[ "${ZSH_IS_IDE_TERMINAL:-0}" == "1" ]] && [[ -f "${SECRETS_AGENT_ENV_FILE:-$HOME/.config/zsh/.agent-secrets.env}" ]]
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}
