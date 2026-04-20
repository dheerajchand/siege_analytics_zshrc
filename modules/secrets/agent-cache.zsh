#!/usr/bin/env zsh
# =================================================================
# SECRETS — agent env cache
# =================================================================
# Warm a background env-file cache so interactive-IDE shells don't
# must hit 1Password live on every startup.

secrets_agent_refresh() {
    local out_file="${SECRETS_AGENT_ENV_FILE:-$HOME/.config/zsh/.agent-secrets.env}"
    local account_arg="${OP_ACCOUNT-}"
    local vault_arg="${OP_VAULT-}"
    local strict=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output) out_file="${2:-}"; shift 2 ;;
            --account) account_arg="${2:-}"; shift 2 ;;
            --vault) vault_arg="${2:-}"; shift 2 ;;
            --strict) strict=1; shift ;;
            -h|--help)
                cat <<'HELP'
Usage: secrets_agent_refresh [--output <file>] [--account <account>] [--vault <vault>] [--strict]

Loads mapped 1Password secrets and writes only mapped ENV vars to an agent-readable local env file.
The output file permissions are restricted to 600.
HELP
                return 0
                ;;
            *)
                _secrets_warn "Unknown option: $1"
                return 1
                ;;
        esac
    done

    [[ -f "$ZSH_SECRETS_MAP" ]] || { _secrets_warn "1Password mapping file not found: $ZSH_SECRETS_MAP"; return 1; }
    _secrets_require_op "cannot refresh agent secrets" || return 1

    local -a mapped_envvars=()
    local line envvar
    while IFS= read -r line || [[ -n "$line" ]]; do
        envvar="$(_secrets_map_envvar_from_line "$line" 2>/dev/null || true)"
        [[ -n "$envvar" ]] && mapped_envvars+=("$envvar")
    done < "$ZSH_SECRETS_MAP"

    local var
    for var in "${mapped_envvars[@]}"; do
        unset "$var" 2>/dev/null || true
    done

    secrets_load_op "$account_arg" "$vault_arg" >/dev/null 2>&1 || true

    local tmp
    tmp="$(mktemp)"
    umask 077
    : > "$tmp"
    chmod 600 "$tmp" 2>/dev/null || true

    local loaded=0
    local missing=0
    local -a missing_vars=()
    for var in "${mapped_envvars[@]}"; do
        if typeset -p "$var" >/dev/null 2>&1; then
            local value="${(P)var}"
            printf '%s=%q\n' "$var" "$value" >> "$tmp"
            loaded=$((loaded + 1))
        else
            missing=$((missing + 1))
            missing_vars+=("$var")
        fi
    done

    mkdir -p "$(dirname "$out_file")" 2>/dev/null || true
    mv "$tmp" "$out_file"
    chmod 600 "$out_file" 2>/dev/null || true

    if (( missing > 0 )); then
        _secrets_warn "agent env: loaded $loaded, missing $missing (${missing_vars[*]})"
        (( strict == 1 )) && return 1
    else
        _secrets_info "agent env refreshed: $out_file ($loaded vars)"
    fi
}

secrets_agent_source() {
    local refresh=0
    local out_file="${SECRETS_AGENT_ENV_FILE:-$HOME/.config/zsh/.agent-secrets.env}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --refresh) refresh=1; shift ;;
            --output) out_file="${2:-}"; shift 2 ;;
            -h|--help)
                echo "Usage: secrets_agent_source [--refresh] [--output <file>]" >&2
                return 0
                ;;
            *)
                _secrets_warn "Unknown option: $1"
                return 1
                ;;
        esac
    done
    (( refresh == 1 )) && secrets_agent_refresh --output "$out_file" || true
    [[ -f "$out_file" ]] || { _secrets_warn "agent env file not found: $out_file"; return 1; }
    while IFS= read -r line || [[ -n "$line" ]]; do
        _secrets_export_kv "$line"
    done < "$out_file"
    _secrets_info "Loaded agent env from $out_file"
}

secrets_agent_status() {
    local out_file="${SECRETS_AGENT_ENV_FILE:-$HOME/.config/zsh/.agent-secrets.env}"
    echo "🔐 Agent Secrets"
    echo "================"
    echo "Map file: $ZSH_SECRETS_MAP"
    echo "Agent env file: $out_file"
    if [[ -f "$out_file" ]]; then
        local vars_count
        vars_count="$(grep -Ec '^[A-Za-z_][A-Za-z0-9_]*=' "$out_file" 2>/dev/null || echo 0)"
        echo "Agent env vars: $vars_count"
    else
        echo "Agent env vars: 0 (file missing)"
    fi
    if _secrets_require_op "cannot query 1Password status" >/dev/null 2>&1; then
        echo "1Password: Ready"
    else
        echo "1Password: Not ready"
    fi
}

