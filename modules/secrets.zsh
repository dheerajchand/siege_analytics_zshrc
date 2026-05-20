#!/usr/bin/env zsh
# =================================================================
# SECRETS - Local + 1Password environment loader
# =================================================================

: "${ZSH_SECRETS_MODE:=file}" # file|op|both|off
: "${ZSH_SECRETS_FILE:=$HOME/.config/zsh/secrets.env}"
: "${ZSH_SECRETS_FILE_EXAMPLE:=$HOME/.config/zsh/secrets.env.example}"
: "${ZSH_SECRETS_MAP:=$HOME/.config/zsh/secrets.1p}"
: "${OP_ACCOUNTS_FILE:=$HOME/.config/zsh/op-accounts.env}"
: "${OP_ACCOUNTS_FILE_EXAMPLE:=$HOME/.config/zsh/op-accounts.env.example}"
: "${OP_VAULT:=}"
: "${OP_ACCOUNT:=}"
: "${CODEX_SESSIONS_FILE:=$HOME/.config/zsh/codex-sessions.env}"
: "${SECRETS_AGENT_ENV_FILE:=$HOME/.config/zsh/.agent-secrets.env}"
: "${OP_SESSIONS_FILE:=$HOME/.config/zsh/.op-sessions.env}"
: "${ZSH_OP_SOURCE_ACCOUNT:=Dheeraj_Chand_Family}"
: "${ZSH_OP_SOURCE_VAULT:=Private}"
: "${ZSH_SECRETS_STARTUP_SOURCE:=auto}" # auto|live|cache
_SECRETS_SYNC_FILES=(op-accounts.env secrets.env secrets.1p codex-sessions.env)

# Resolve JSON tool once: prefer jq, fall back to python3, then python
_SECRETS_JSON_CMD=""
if command -v jq >/dev/null 2>&1; then
    _SECRETS_JSON_CMD="jq"
elif command -v python3 >/dev/null 2>&1; then
    _SECRETS_JSON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    _SECRETS_JSON_CMD="python"
fi

# Core utility helpers (_secrets_warn/info/debug, value normalization,
# agent-cache preference) moved to modules/secrets/core.zsh.
source "${0:A:h}/secrets/core.zsh"

# 1Password CLI layer — _op_* helpers and op_* public commands.
source "${0:A:h}/secrets/1password-cli.zsh"

# Agent env cache — secrets_agent_{refresh,source,status}.
source "${0:A:h}/secrets/agent-cache.zsh"

# Policy preflight + recovery + status.
source "${0:A:h}/secrets/policy.zsh"

# Machine profile management.
source "${0:A:h}/secrets/profile.zsh"

# 1Password bidirectional sync.
source "${0:A:h}/secrets/sync-1p.zsh"

# rsync-based host sync + verification.
source "${0:A:h}/secrets/sync-rsync.zsh"

# Loaders + init/edit/validate/status.
source "${0:A:h}/secrets/load.zsh"

if [[ -z "${OP_ALIAS_SHIM_DISABLE:-}" ]]; then
    if command -v op >/dev/null 2>&1 && ! typeset -f op >/dev/null 2>&1; then
        op() {
            local -a args=("$@")
            local -a out=()
            local account=""
            local i=1
            while [[ $i -le ${#args[@]} ]]; do
                case "${args[$i]}" in
                    --account)
                        account="${args[$((i+1))]}"
                        out+=("--account")
                        local resolved
                        resolved="$(_op_resolve_account_arg "$account")"
                        out+=("$resolved")
                        i=$((i+2))
                        continue
                        ;;
                    --account=*)
                        account="${args[$i]#--account=}"
                        local resolved2
                        resolved2="$(_op_resolve_account_arg "$account")"
                        out+=("--account=${resolved2}")
                        i=$((i+1))
                        continue
                        ;;
                esac
                out+=("${args[$i]}")
                i=$((i+1))
            done
            command op "${out[@]}"
        }
    fi
fi

# Auto-load secrets unless disabled or in test mode
if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    load_secrets
    _secrets_auto_signin_all_on_load || true
    _secrets_check_profile
    [[ "${ZSH_SECRETS_VERBOSE:-}" == "1" ]] && echo "✅ secrets loaded"
fi

