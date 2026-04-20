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

_secrets_update_env_file() {
    local key="" value="" file="$ZSH_SECRETS_FILE"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --key)   key="${2:-}"; shift 2 ;;
            --value) value="${2:-}"; shift 2 ;;
            --file)  file="${2:-$ZSH_SECRETS_FILE}"; shift 2 ;;
            *)       shift ;;
        esac
    done
    local tmp
    umask 077
    if [[ ! -f "$file" ]]; then
        if ! printf '%s=%s\n' "$key" "$value" > "$file" 2>/dev/null; then
            _secrets_warn "Failed to create secrets file: $file"
            return 1
        fi
        chmod 600 "$file" 2>/dev/null || true
        return 0
    fi
    tmp="$(mktemp 2>/dev/null || mktemp -t zsh-secrets 2>/dev/null)"
    if [[ -z "$tmp" || ! -f "$tmp" ]]; then
        _secrets_warn "Failed to create temp file for secrets update"
        return 1
    fi
    local _py_cmd=""
    if [[ "$_SECRETS_JSON_CMD" == "python3" || "$_SECRETS_JSON_CMD" == "python" ]]; then
        _py_cmd="$_SECRETS_JSON_CMD"
    elif command -v python3 >/dev/null 2>&1; then
        _py_cmd="python3"
    elif command -v python >/dev/null 2>&1; then
        _py_cmd="python"
    else
        _secrets_warn "python not found; cannot update secrets file"
        return 1
    fi
    if ! "$_py_cmd" - "$file" "$tmp" "$key" "$value" <<'PY'
import sys
src, dst, key, val = sys.argv[1:5]
found = False
with open(src, "r") as fh:
    lines = fh.read().splitlines()
out = []
for line in lines:
    if line.startswith(f"{key}="):
        out.append(f"{key}={val}")
        found = True
    else:
        out.append(line)
if not found:
    out.append(f"{key}={val}")
with open(dst, "w") as fh:
    fh.write("\n".join(out))
    fh.write("\n")
PY
    then
        _secrets_warn "Failed to update secrets file"
        rm -f "$tmp"
        return 1
    fi
    if ! mv "$tmp" "$file" 2>/dev/null; then
        _secrets_warn "Failed to update secrets file"
        rm -f "$tmp"
        return 1
    fi
    chmod 600 "$file" 2>/dev/null || true
}

_secrets_export_kv() {
    local line="$1"
    [[ -z "$line" ]] && return 0
    [[ "$line" == \#* ]] && return 0
    if [[ "$line" == export\ * ]]; then
        line="${line#export }"
    fi
    if [[ "$line" == *"="* ]]; then
        local key="${line%%=*}"
        local val="${line#*=}"
        key="${key## }"; key="${key%% }"
        val="$(_secrets_normalize_value "$val")"
        export "$key=$val"
    fi
}

_secrets_require_op() {
    local context="${1:-cannot proceed}"
    local op_bin="${OP_BIN:-op}"
    if ! command -v "$op_bin" >/dev/null 2>&1; then
        _secrets_warn "op not found; $context"
        return 1
    fi
    if ! _op_cmd account list >/dev/null 2>&1; then
        _secrets_warn "1Password auth required (run: op signin)"
        return 1
    fi
    return 0
}

secrets_find_account_for_item() {
    local title="${1:-}"
    local vault="${2:-${ZSH_OP_SOURCE_VAULT:-}}"
    local op_bin="${OP_BIN:-op}"
    if [[ -z "$title" ]]; then
        _secrets_warn "Usage: secrets_find_account_for_item <title> [vault]"
        return 1
    fi
    _secrets_require_op "cannot search accounts" || return 1
    local accounts_json
    accounts_json="$(_op_cmd account list --format=json 2>/dev/null || true)"
    if [[ -z "$accounts_json" ]]; then
        _secrets_warn "No accounts configured on this device"
        return 1
    fi
    local uuids="${OP_ACCOUNT_UUIDS:-}"
    if [[ -z "$uuids" ]]; then
        if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
            uuids="$(printf '%s' "$accounts_json" | jq -r '[.[].account_uuid // empty] | join(" ")' 2>/dev/null || true)"
        elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
            uuids="$(printf '%s' "$accounts_json" | "$_SECRETS_JSON_CMD" -c 'import json,sys; data=json.load(sys.stdin); print(" ".join([a.get("account_uuid","") for a in data if a.get("account_uuid")]))' 2>/dev/null || true)"
        else
            _secrets_warn "No JSON tool (jq/python) available"
            return 1
        fi
    fi
    local matches=()
    for uuid in $uuids; do
        local items_list
        if [[ -n "$vault" ]]; then
            items_list="$(_op_cmd item list --account "$uuid" --vault "$vault" 2>/dev/null || true)"
        else
            items_list="$(_op_cmd item list --account "$uuid" 2>/dev/null || true)"
        fi
        if [[ -z "$items_list" ]]; then
            continue
        fi
        if printf '%s\n' "$items_list" | grep -Fq "$title"; then
            matches+=("$uuid")
        fi
    done
    if (( ${#matches[@]} == 0 )); then
        return 1
    fi
    printf "%s\n" "${matches[@]}"
}

_secrets_accounts_equivalent() {
    local left="${1:-}"
    local right="${2:-}"
    [[ -z "$left" || -z "$right" ]] && return 1
    local left_uuid right_uuid
    left_uuid="$(_op_resolve_account_uuid "$left")"
    right_uuid="$(_op_resolve_account_uuid "$right")"
    if [[ -n "$left_uuid" && -n "$right_uuid" && "$left_uuid" == "$right_uuid" ]]; then
        return 0
    fi
    if [[ "$left" == "$right" ]]; then
        return 0
    fi
    return 1
}

secrets_source_set() {
    local account="" vault=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --account) account="${2:-}"; shift 2 ;;
            --vault)   vault="${2:-}"; shift 2 ;;
            --help|-h) echo "Usage: secrets_source_set --account <acct> [--vault <vault>]" >&2; return 0 ;;
            *)         if [[ -z "$account" ]]; then account="$1"; else vault="$1"; fi; shift ;;
        esac
    done
    if [[ -z "$account" ]]; then
        _secrets_warn "Usage: secrets_source_set --account <acct> [--vault <vault>]"
        return 1
    fi
    local resolved
    resolved="$(_op_resolve_account_uuid "$account")"
    export ZSH_OP_SOURCE_ACCOUNT="$(_secrets_normalize_value "${resolved:-$account}")"
    if [[ -n "$vault" ]]; then
        export ZSH_OP_SOURCE_VAULT="$vault"
    fi
    _secrets_update_env_file --key "ZSH_OP_SOURCE_ACCOUNT" --value "$ZSH_OP_SOURCE_ACCOUNT" || true
    _secrets_update_env_file --key "ZSH_OP_SOURCE_VAULT" --value "$ZSH_OP_SOURCE_VAULT" || true
    _secrets_info "1Password source set: account=$ZSH_OP_SOURCE_ACCOUNT vault=$ZSH_OP_SOURCE_VAULT"
}

secrets_source_status() {
    echo "🔐 1Password Source"
    echo "==================="
    echo "Account: ${ZSH_OP_SOURCE_ACCOUNT:-unset}"
    echo "Vault: ${ZSH_OP_SOURCE_VAULT:-unset}"
}

_secrets_require_source() {
    local account="${1:-${OP_ACCOUNT-}}"
    local vault="${2:-${OP_VAULT-}}"
    local source_account
    local source_vault
    source_account="$(_op_source_account)"
    source_vault="$(_op_source_vault)"
    if [[ -z "$source_account" || -z "$source_vault" ]]; then
        _secrets_warn "Source of truth not configured (set ZSH_OP_SOURCE_ACCOUNT/Vault)"
        return 1
    fi
    local resolved_account="$account"
    if [[ -n "$account" ]]; then
        resolved_account="$(_op_resolve_account_uuid "$account")"
    fi
    if [[ -n "$resolved_account" ]] && ! _secrets_accounts_equivalent "$resolved_account" "$source_account"; then
        _secrets_warn "Refusing to use non-source account: $resolved_account (source: $source_account)"
        return 1
    fi
    if [[ -n "$vault" && "$vault" != "$source_vault" ]]; then
        _secrets_warn "Refusing to use non-source vault: $vault (source: $source_vault)"
        return 1
    fi
    return 0
}

_secrets_safe_title() {
    local title="${1:-}"
    if [[ -z "$title" ]]; then
        echo "(unnamed)"
        return 0
    fi
    if [[ "$title" == *$'\n'* || "$title" == *"="* ]]; then
        echo "(redacted)"
        return 0
    fi
    if [[ ${#title} -gt 80 ]]; then
        echo "(redacted)"
        return 0
    fi
    echo "$title"
}

_secrets_truncate() {
    local value="${1:-}"
    local max="${2:-40}"
    if (( max < 4 )); then
        echo "${value:0:$max}"
        return 0
    fi
    if (( ${#value} > max )); then
        local cut=$(( max - 3 ))
        echo "${value:0:$cut}..."
        return 0
    fi
    echo "$value"
}

_secrets_local_path_default() {
    if [[ -n "${ZSH_CONFIG_DIR:-}" ]]; then
        echo "$ZSH_CONFIG_DIR"
    else
        echo "$HOME/.config/zsh"
    fi
}

_secrets_remote_path_default() {
    echo "~/.config/zsh"
}

_secrets_rsync_parse_args() {
    local user="" host="" path="" remote=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                user="$2"
                shift 2
                ;;
            --host)
                host="$2"
                shift 2
                ;;
            --path)
                path="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
                return 2
                ;;
            *)
                if [[ -z "$remote" ]]; then
                    remote="$1"
                elif [[ -z "$path" ]]; then
                    path="$1"
                else
                    echo "Usage: $0 [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
                    return 2
                fi
                shift
                ;;
        esac
    done
    if [[ -n "$user" || -n "$host" ]]; then
        [[ -z "$host" ]] && return 1
        if [[ -n "$user" ]]; then
            remote="${user}@${host}"
        else
            remote="$host"
        fi
    fi
    if [[ -z "$path" ]]; then
        path="$(_secrets_remote_path_default)"
    fi
    echo "$remote" "$path"
    return 0
}

secrets_rsync_to_host() {
    local parsed remote remote_path
    parsed="$(_secrets_rsync_parse_args "$@")" || {
        echo "Usage: secrets_rsync_to_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    }
    remote="${parsed%% *}"
    remote_path="${parsed#* }"
    if [[ -z "$remote" ]]; then
        echo "Usage: secrets_rsync_to_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    fi
    if ! command -v rsync >/dev/null 2>&1; then
        _secrets_warn "rsync not found; cannot sync secrets"
        return 1
    fi
    local src_base
    src_base="$(_secrets_local_path_default)"
    local -a src_files=()
    local _f
    for _f in "${_SECRETS_SYNC_FILES[@]}"; do src_files+=("$src_base/$_f"); done
    rsync -av --chmod=Fu=rw,Fgo=,Du=rwx,Dgo= \
        --rsync-path="mkdir -p ${remote_path} && rsync" \
        "${src_files[@]}" \
        "${remote}:${remote_path}/"
}

secrets_rsync_from_host() {
    local parsed remote remote_path
    parsed="$(_secrets_rsync_parse_args "$@")" || {
        echo "Usage: secrets_rsync_from_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    }
    remote="${parsed%% *}"
    remote_path="${parsed#* }"
    if [[ -z "$remote" ]]; then
        echo "Usage: secrets_rsync_from_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    fi
    if ! command -v rsync >/dev/null 2>&1; then
        _secrets_warn "rsync not found; cannot sync secrets"
        return 1
    fi
    local dest_base
    dest_base="$(_secrets_local_path_default)"
    umask 077
    mkdir -p "$dest_base"
    local -a remote_files=()
    local _f
    for _f in "${_SECRETS_SYNC_FILES[@]}"; do remote_files+=("${remote}:${remote_path}/$_f"); done
    rsync -av --chmod=Fu=rw,Fgo=,Du=rwx,Dgo= \
        "${remote_files[@]}" \
        "$dest_base/"
}

secrets_rsync_to_cyberpower() {
    local user="${1:-${USER}}"
    secrets_rsync_to_host --user "$user" --host "cyberpower"
}

secrets_rsync_from_cyberpower() {
    local user="${1:-${USER}}"
    secrets_rsync_from_host --user "$user" --host "cyberpower"
}

secrets_rsync_verify() {
    local parsed remote remote_path
    parsed="$(_secrets_rsync_parse_args "$@")" || {
        echo "Usage: secrets_rsync_verify [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    }
    remote="${parsed%% *}"
    remote_path="${parsed#* }"
    if [[ -z "$remote" ]]; then
        echo "Usage: secrets_rsync_verify [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    fi
    if ! command -v ssh >/dev/null 2>&1; then
        _secrets_warn "ssh not found; cannot verify remote"
        return 1
    fi
    local base
    base="$(_secrets_local_path_default)"
    local missing=0
    for f in "${_SECRETS_SYNC_FILES[@]}"; do
        if [[ ! -f "$base/$f" ]]; then
            _secrets_warn "Missing local file: $base/$f"
            missing=1
        fi
    done
    local _test_cmd="true"
    for f in "${_SECRETS_SYNC_FILES[@]}"; do _test_cmd="$_test_cmd && test -f ${remote_path}/$f"; done
    ssh "$remote" "$_test_cmd" >/dev/null 2>&1 || {
        _secrets_warn "Missing one or more remote files in ${remote_path}"
        missing=1
    }
    if [[ "$missing" -eq 0 ]]; then
        _secrets_info "Secrets files present locally and on ${remote}:${remote_path}"
        return 0
    fi
    return 1
}

secrets_load_file() {
    [[ -f "$ZSH_SECRETS_FILE" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        _secrets_export_kv "$line"
    done < "$ZSH_SECRETS_FILE"
    _secrets_info "Loaded secrets from file"
}

secrets_load_op() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_debug "No global account set; entries must specify @account"
    fi
    [[ -f "$ZSH_SECRETS_MAP" ]] || return 1
    _secrets_require_op "cannot load 1Password secrets" || return 1
    secrets_map_sanitize --fix >/dev/null 2>&1 || true
    if [[ -n "$account_arg" ]]; then
        account_arg="$(_op_resolve_account_arg "$account_arg")"
    fi

    local _loaded=0 _failed=0 _failed_vars=()
    local line envvar service user field vault_override
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue
        vault_override=""
        local entry_account=""

        # Support op:// mapping: KEY=op://vault/item/field [@account]
        if [[ "$line" == *"="* ]]; then
            envvar="${line%%=*}"
            local rhs="${line#*=}"
            envvar="${envvar## }"
            envvar="${envvar%% }"
            rhs="${rhs## }"
            rhs="${rhs%% }"
            if [[ -n "$envvar" && "$rhs" == op://* ]]; then
                # Support per-entry account: op://vault/item/field @account
                local op_uri="$rhs"
                if [[ "$rhs" == *" @"* ]]; then
                    entry_account="${rhs##* @}"
                    op_uri="${rhs% @*}"
                    entry_account="$(_op_resolve_account_arg "$entry_account")"
                fi
                local effective_account="${entry_account:-$account_arg}"

                local value=""
                value="$(_op_cmd read "$op_uri" \
                    ${effective_account:+--account="$effective_account"} \
                    2>/dev/null || true)"
                if [[ -z "$value" ]]; then
                    value="$(_op_cmd read "$op_uri" 2>/dev/null || true)"
                fi
                if [[ -n "$value" ]]; then
                    export "$envvar=$value"
                    (( _loaded++ ))
                    continue
                fi

                # Fallback: parse op://vault/item/field and use item get.
                local parts
                parts="$(_secrets_extract_op_url_parts "$op_uri")"
                local fld_vault="${parts%%	*}"
                local fld_rest="${parts#*	}"
                local fld_item="${fld_rest%%	*}"
                local fld_field="${fld_rest#*	}"
                if [[ -n "$fld_item" && -n "$fld_field" ]]; then
                    service="$fld_item"
                    user="-"
                    field="$fld_field"
                    vault_override="$fld_vault"
                else
                    continue
                fi
            else
                read -r envvar service user field <<<"$line"
            fi
        else
            read -r envvar service user field <<<"$line"
        fi
        [[ -z "$envvar" ]] && continue
        [[ -z "$service" || -z "$field" ]] && continue
        local value=""
        local vault_to_use="${vault_override:-$vault_arg}"
        local effective_account="${entry_account:-$account_arg}"
        if [[ "$user" == "-" || -z "$user" ]]; then
            value="$(_op_cmd item get "$service" \
                ${effective_account:+--account="$effective_account"} \
                ${effective_account:+${vault_to_use:+--vault="$vault_to_use"}} \
                --field="$field" --reveal 2>/dev/null || true)"
        else
            value="$(_op_cmd item get "$service-$user" \
                ${effective_account:+--account="$effective_account"} \
                ${effective_account:+${vault_to_use:+--vault="$vault_to_use"}} \
                --field="$field" --reveal 2>/dev/null || true)"
        fi
        if [[ -n "$value" ]]; then
            export "$envvar=$value"
            (( _loaded++ ))
        else
            (( _failed++ ))
            _failed_vars+=("$envvar")
        fi
    done < "$ZSH_SECRETS_MAP"
    if (( _failed > 0 )); then
        _secrets_warn "1Password: loaded $_loaded, failed $_failed (${_failed_vars[*]})"
        # Return failure when nothing loaded — triggers agent-cache fallback
        (( _loaded == 0 )) && return 1
    else
        _secrets_info "Loaded $_loaded secrets from 1Password"
    fi
}

_secrets_extract_op_url_parts() {
    local rhs="$1"
    local op_path="${rhs#op://}"
    local vault="${op_path%%/*}"
    local rest="${op_path#*/}"
    local item="${rest%%/*}"
    local field="${rest#*/}"
    printf '%s\t%s\t%s' "$vault" "$item" "$field"
}

_secrets_map_envvar_from_line() {
    local line="$1"
    [[ -z "$line" || "$line" == \#* ]] && return 1
    local envvar=""
    if [[ "$line" == *"="* ]]; then
        envvar="${line%%=*}"
    else
        read -r envvar _ <<< "$line"
    fi
    envvar="${envvar## }"
    envvar="${envvar%% }"
    [[ -z "$envvar" ]] && return 1
    printf '%s\n' "$envvar"
}

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

_secrets_missing_from_1p_usage() {
    echo "Usage: secrets_missing_from_1p [--json] [--fix] [account] [vault]" >&2
}

secrets_missing_from_1p() {
    local mode="text"
    local fix="0"
    local account_arg=""
    local vault_arg=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json) mode="json"; shift ;;
            --fix) fix="1"; shift ;;
            -h|--help) _secrets_missing_from_1p_usage; return 0 ;;
            *) if [[ -z "$account_arg" ]]; then account_arg="$1"; else vault_arg="$1"; fi; shift ;;
        esac
    done
    account_arg="${account_arg:-${OP_ACCOUNT-}}"
    vault_arg="${vault_arg:-${OP_VAULT-}}"
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_debug "No global account set; entries must specify @account"
    fi
    [[ -f "$ZSH_SECRETS_MAP" ]] || return 1
    _secrets_require_op "cannot check 1Password" || return 1
    local missing=0
    local line envvar service user field vault_override
    local -a missing_json=()
    local -a updated_lines=()
    local line_num=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line_num=$((line_num + 1))
        if [[ -z "$line" || "$line" == \#* ]]; then
            updated_lines+=("$line")
            continue
        fi
        vault_override=""
        local entry_account=""

        if [[ "$line" == *"="* ]]; then
            envvar="${line%%=*}"
            local rhs="${line#*=}"
            envvar="${envvar## }"; envvar="${envvar%% }"
            rhs="${rhs## }"; rhs="${rhs%% }"
            if [[ -n "$envvar" && "$rhs" == op://* ]]; then
                # Support per-entry account: op://vault/item/field @account
                local op_uri="$rhs"
                if [[ "$rhs" == *" @"* ]]; then
                    entry_account="${rhs##* @}"
                    op_uri="${rhs% @*}"
                    entry_account="$(_op_resolve_account_arg "$entry_account")"
                fi
                local effective_account="${entry_account:-$account_arg}"

                local vault item fld
                local parts
                parts="$(_secrets_extract_op_url_parts "$op_uri")"
                vault="${parts%%$'\t'*}"
                item="${parts#*$'\t'}"; item="${item%%$'\t'*}"
                fld="${parts##*$'\t'}"
                if ! _op_cmd read "$op_uri" ${effective_account:+--account="$effective_account"} >/dev/null 2>&1; then
                    if [[ "$mode" == "json" ]]; then
                        missing_json+=("{\"line\":$line_num,\"env\":\"$envvar\",\"type\":\"op_url\",\"ref\":\"op://$vault/$item/$fld\"}")
                    else
                        _secrets_warn "Missing: $envvar (op://$vault/$item/$fld)"
                    fi
                    missing=1
                    if [[ "$fix" == "1" ]]; then
                        updated_lines+=("# MISSING: $line")
                    fi
                else
                    updated_lines+=("$line")
                fi
                continue
            else
                read -r envvar service user field <<<"$line"
            fi
        else
            read -r envvar service user field <<<"$line"
        fi
        [[ -z "$envvar" ]] && continue
        [[ -z "$service" || -z "$field" ]] && continue
        local vault_to_use="${vault_override:-$vault_arg}"
        local effective_account="${entry_account:-$account_arg}"
        local ok=""
        if [[ "$user" == "-" || -z "$user" ]]; then
            ok="$(_op_cmd item get "$service" ${effective_account:+--account="$effective_account"} ${effective_account:+${vault_to_use:+--vault="$vault_to_use"}} --field="$field" --reveal 2>/dev/null || true)"
        else
            ok="$(_op_cmd item get "$service" ${effective_account:+--account="$effective_account"} ${effective_account:+${vault_to_use:+--vault="$vault_to_use"}} --fields label=="$field" --reveal 2>/dev/null || true)"
        fi
        if [[ -z "$ok" ]]; then
            if [[ "$mode" == "json" ]]; then
                missing_json+=("{\"line\":$line_num,\"env\":\"$envvar\",\"type\":\"item\",\"ref\":\"item=$service field=$field\"}")
            else
                _secrets_warn "Missing: $envvar (item=$service field=$field)"
            fi
            missing=1
            if [[ "$fix" == "1" ]]; then
                updated_lines+=("# MISSING: $line")
            fi
        else
            updated_lines+=("$line")
        fi
    done < "$ZSH_SECRETS_MAP"
    if [[ "$mode" == "json" ]]; then
        printf '[%s]\n' "$(IFS=,; echo "${missing_json[*]}")"
    fi
    if [[ "$fix" == "1" && "$missing" -ne 0 ]]; then
        local bak="${ZSH_SECRETS_MAP}.bak"
        cp "$ZSH_SECRETS_MAP" "$bak"
        local tmp
        tmp="$(mktemp)"
        printf '%s\n' "${updated_lines[@]}" > "$tmp"
        mv "$tmp" "$ZSH_SECRETS_MAP"
        _secrets_info "Updated $ZSH_SECRETS_MAP (commented missing entries; backup: $bak)"
    fi
    return $missing
}

load_secrets() {
    _secrets_normalize_mode
    local _agent_cache="${SECRETS_AGENT_ENV_FILE:-$HOME/.config/zsh/.agent-secrets.env}"
    case "$ZSH_SECRETS_MODE" in
        off) return 0 ;;
        file) secrets_load_file ;;
        op)
            if _secrets_startup_prefers_agent_cache; then
                _secrets_info "startup using agent cache"
                secrets_agent_source && return 0
            fi
            secrets_load_op || {
                if [[ -f "$_agent_cache" ]]; then
                    _secrets_info "op auth unavailable, loading from agent cache"
                    secrets_agent_source
                fi
            }
            ;;
        both)
            secrets_load_file
            if _secrets_startup_prefers_agent_cache; then
                _secrets_info "startup using agent cache"
                secrets_agent_source && return 0
            fi
            secrets_load_op || {
                if [[ -f "$_agent_cache" ]]; then
                    _secrets_info "op auth unavailable, loading from agent cache"
                    secrets_agent_source
                fi
            }
            ;;
        *)
            _secrets_warn "Unknown ZSH_SECRETS_MODE: $ZSH_SECRETS_MODE"
            return 1
            ;;
    esac
}

_secrets_check_profile() {
    if [[ -n "${ZSH_ENV_PROFILE:-}" ]]; then
        return 0
    fi
    if [[ -n "${_SECRETS_PROFILE_WARNED:-}" ]]; then
        return 0
    fi
    if [[ -n "${ZSH_TEST_MODE:-}" ]]; then
        return 0
    fi
    if [[ ! -o interactive ]]; then
        return 0
    fi
    _SECRETS_PROFILE_WARNED=1
    _secrets_warn "ZSH_ENV_PROFILE not set. Run: secrets_init_profile"
    _secrets_info "Available profiles: dev, staging, prod, laptop"
    _secrets_info "Run 'secrets_init_profile' for setup wizard"
}

_secrets_validate_profile() {
    local profile="${1:-}"
    local list
    list="$(_secrets_profile_list)"
    if [[ " $list " == *" $profile "* ]]; then
        return 0
    fi
    _secrets_warn "Invalid profile: $profile (expected one of: $(_secrets_default_profiles))"
    return 1
}

_secrets_profile_list() {
    if typeset -p ZSH_PROFILE_ORDER >/dev/null 2>&1; then
        local -a ordered
        ordered=("${ZSH_PROFILE_ORDER[@]}")
        if typeset -p ZSH_PROFILE_CONFIGS >/dev/null 2>&1; then
            local -a filtered
            local name
            for name in "${ordered[@]}"; do
                [[ -n "${ZSH_PROFILE_CONFIGS[$name]-}" ]] && filtered+=("$name")
            done
            [[ "${#filtered[@]}" -gt 0 ]] && echo "${filtered[*]}" && return 0
        fi
        echo "${ordered[*]}"
        return 0
    fi
    if typeset -p ZSH_PROFILE_CONFIGS >/dev/null 2>&1; then
        local -a keys
        keys=("${(@k)ZSH_PROFILE_CONFIGS}")
        echo "${keys[*]}"
        return 0
    fi
    if [[ -n "${ZSH_PROFILE_LIST:-}" ]]; then
        echo "$ZSH_PROFILE_LIST"
        return 0
    fi
    _secrets_default_profiles
}

_secrets_default_profiles() {
    echo "dev staging prod laptop cyberpower"
}

secrets_prune_duplicates_1p() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    local resolved_account="$account_arg"
    if [[ -n "$account_arg" ]]; then
        resolved_account="$(_op_resolve_account_uuid "$account_arg")"
    fi
    shift 2 || true
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_warn "Vault specified without account; refusing to prune"
        return 1
    fi
    _secrets_require_op "cannot prune duplicates" || return 1
    local -a titles
    if [[ "$#" -gt 0 ]]; then
        titles=("$@")
    else
        titles=(op-accounts-env zsh-secrets-env zsh-secrets-map codex-sessions-env)
    fi
    local title ids keep_id id
    for title in "${titles[@]}"; do
        ids=($(_op_group_item_ids_by_title "$title" "$resolved_account" "$vault_arg" 2>/dev/null))
        if [[ "${#ids[@]}" -le 1 ]]; then
            continue
        fi
        keep_id="${ids[-1]}"
        for id in "${ids[@]}"; do
            [[ "$id" == "$keep_id" ]] && continue
            _op_cmd item delete "$id" \
                ${resolved_account:+--account="$resolved_account"} \
                ${resolved_account:+${vault_arg:+--vault="$vault_arg"}} >/dev/null 2>&1 || true
        done
        _secrets_info "Pruned duplicates for $title (kept: $keep_id)"
    done
}

secrets_validate_setup() {
    local errors=0
    if [[ "$ZSH_SECRETS_MODE" == "op" || "$ZSH_SECRETS_MODE" == "both" ]]; then
        if ! command -v op >/dev/null 2>&1; then
            _secrets_warn "op CLI not found. Install: brew install --cask 1password-cli"
            ((errors++))
        elif ! op account list >/dev/null 2>&1; then
            _secrets_warn "1Password not authenticated. Run: op signin"
            ((errors++))
        fi
        if [[ ! -f "$ZSH_SECRETS_MAP" ]]; then
            _secrets_warn "1Password mapping file not found: $ZSH_SECRETS_MAP"
            _secrets_info "Create from example: cp $ZSH_SECRETS_MAP.example $ZSH_SECRETS_MAP"
            ((errors++))
        fi
    fi
    if [[ "$errors" -eq 0 ]]; then
        _secrets_info "Secrets setup looks good"
    fi
    return "$errors"
}

_secrets_policy_titles() {
    echo "op-accounts-env zsh-secrets-env zsh-secrets-map codex-sessions-env"
}

_secrets_count_duplicate_titles() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    local resolved_account="$account_arg"
    [[ -n "$account_arg" ]] && resolved_account="$(_op_resolve_account_uuid "$account_arg")"
    _secrets_require_op "cannot check duplicates" >/dev/null 2>&1 || { echo 0; return 0; }
    local title ids dup_count=0
    for title in $(_secrets_policy_titles); do
        ids=($(_op_group_item_ids_by_title "$title" "$resolved_account" "$vault_arg" 2>/dev/null))
        if [[ "${#ids[@]}" -gt 1 ]]; then
            dup_count=$((dup_count + 1))
        fi
    done
    echo "$dup_count"
}

secrets_policy_preflight() {
    local mode="text"
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    if [[ "$account_arg" == "--json" ]]; then
        mode="json"
        account_arg="${OP_ACCOUNT-}"
        vault_arg="${OP_VAULT-}"
    elif [[ "$1" == "--json" ]]; then
        mode="json"
        shift
        account_arg="${1:-${OP_ACCOUNT-}}"
        vault_arg="${2:-${OP_VAULT-}}"
    fi

    local source_ok=true map_ok=true duplicates_ok=true missing_ok=true
    local duplicates=0 missing=0
    local source_account source_vault
    source_account="$(_op_source_account)"
    source_vault="$(_op_source_vault)"
    account_arg="$(_op_resolve_account_uuid "$account_arg")"
    if ! _secrets_require_source "$account_arg" "$vault_arg" >/dev/null 2>&1; then
        source_ok=false
    fi
    if ! secrets_map_sanitize >/dev/null 2>&1; then
        map_ok=false
    fi
    duplicates="$(_secrets_count_duplicate_titles "$account_arg" "$vault_arg")"
    if [[ "${duplicates:-0}" -gt 0 ]]; then
        duplicates_ok=false
    fi
    local missing_file
    missing_file="$(mktemp 2>/dev/null || mktemp -t secrets-missing 2>/dev/null)"
    if ! secrets_missing_from_1p --json "$account_arg" "$vault_arg" >"$missing_file" 2>/dev/null; then
        missing_ok=false
    fi
    if [[ -f "$missing_file" ]]; then
        if command -v jq >/dev/null 2>&1; then
            missing="$(jq 'length' "$missing_file" 2>/dev/null || echo 0)"
        else
            local py="python3"
            command -v python3 >/dev/null 2>&1 || py="python"
            missing="$("$py" - <<'PY' "$missing_file" 2>/dev/null || echo 0
import json,sys
try:
    print(len(json.load(open(sys.argv[1]))))
except Exception:
    print(0)
PY
)"
        fi
        rm -f "$missing_file"
    fi
    [[ "${missing:-0}" -gt 0 ]] && missing_ok=false

    local ok=true
    [[ "$source_ok" == true && "$map_ok" == true && "$duplicates_ok" == true && "$missing_ok" == true ]] || ok=false
    if [[ "$mode" == "json" ]]; then
        printf '{"ok":%s,"checks":{"source":{"ok":%s,"account":"%s","vault":"%s"},"map":{"ok":%s},"duplicates":{"ok":%s,"count":%s},"missing":{"ok":%s,"count":%s}}}\n' \
            "$ok" "$source_ok" "$(_secrets_safe_title "$source_account")" "$(_secrets_safe_title "$source_vault")" "$map_ok" "$duplicates_ok" "$duplicates" "$missing_ok" "$missing"
        [[ "$ok" == true ]]
        return $?
    fi

    echo "🔐 Secrets Policy Preflight"
    echo "==========================="
    [[ "$source_ok" == true ]] && echo "✅ source-of-truth guard: ok" || { _secrets_warn "source-of-truth guard failed"; echo "   fix: secrets_source_set <account> <vault>"; }
    [[ "$map_ok" == true ]] && echo "✅ mapping format: clean" || { _secrets_warn "mapping format invalid"; echo "   fix: secrets_map_sanitize --fix"; }
    [[ "$duplicates_ok" == true ]] && echo "✅ duplicates: none" || { _secrets_warn "duplicate secure notes detected ($duplicates titles)"; echo "   fix: secrets_prune_duplicates_1p"; }
    [[ "$missing_ok" == true ]] && echo "✅ map references: resolvable" || { _secrets_warn "missing map references detected ($missing)"; echo "   fix: secrets_missing_from_1p --fix"; }
    [[ "$ok" == true ]]
}

secrets_policy_status() {
    if [[ "${1:-}" == "--json" ]]; then
        secrets_policy_preflight --json
        return $?
    fi
    secrets_policy_preflight
}

secrets_policy_recover_headless() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    op_accounts_sanitize --fix >/dev/null 2>&1 || true
    secrets_map_sanitize --fix >/dev/null 2>&1 || true
    secrets_prune_duplicates_1p "$account_arg" "$vault_arg" >/dev/null 2>&1 || true
    secrets_missing_from_1p --fix "$account_arg" "$vault_arg" >/dev/null 2>&1 || true
    secrets_policy_preflight "$account_arg" "$vault_arg"
}

secrets_init_profile() {
    if [[ -f "$ZSH_SECRETS_FILE" ]]; then
        _secrets_warn "secrets file already exists: $ZSH_SECRETS_FILE"
        return 1
    fi
    echo "🔐 ZSH Secrets Profile Setup"
    echo "============================"
    echo ""
    echo "Select environment profile:"
    echo "  1) dev      - Development environment"
    echo "  2) staging  - Staging environment"
    echo "  3) prod     - Production environment"
    echo "  4) laptop   - Personal laptop"
    echo ""
    local choice profile
    read -r "choice?Profile [1-4]: "
    case "$choice" in
        1) profile="dev" ;;
        2) profile="staging" ;;
        3) profile="prod" ;;
        4) profile="laptop" ;;
        *) _secrets_warn "Invalid choice"; return 1 ;;
    esac

    local mode="file"
    if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
        local use_op
        read -r "use_op?Use 1Password for secrets? [y/N]: "
        if [[ "$use_op" == [Yy]* ]]; then
            mode="both"
        fi
    else
        if command -v op >/dev/null 2>&1; then
            _secrets_warn "1Password not authenticated. Using file-only mode."
        else
            _secrets_warn "1Password CLI not installed. Using file-only mode."
        fi
    fi

    umask 077
    cat > "$ZSH_SECRETS_FILE" <<EOF
# ZSH Environment Profile
ZSH_ENV_PROFILE=$profile

# Secrets Mode: file, op, both, off
ZSH_SECRETS_MODE=$mode

# 1Password Configuration (optional)
# OP_ACCOUNT=your-account-alias
# OP_VAULT=Private
EOF
    if [[ ! -f "$ZSH_SECRETS_FILE" ]]; then
        _secrets_warn "Failed to create secrets file"
        return 1
    fi
    chmod 600 "$ZSH_SECRETS_FILE" 2>/dev/null || true
    local perms
    perms="$(stat -f "%OLp" "$ZSH_SECRETS_FILE" 2>/dev/null || stat -c "%a" "$ZSH_SECRETS_FILE" 2>/dev/null || true)"
    if [[ -n "$perms" && "$perms" != "600" && "$perms" != "400" ]]; then
        _secrets_warn "Secrets file has insecure permissions: $perms"
    fi

    if [[ "$mode" == "op" || "$mode" == "both" ]]; then
        if [[ ! -f "$ZSH_SECRETS_MAP" && -f "$ZSH_SECRETS_MAP.example" ]]; then
            cp "$ZSH_SECRETS_MAP.example" "$ZSH_SECRETS_MAP"
            _secrets_info "Created $ZSH_SECRETS_MAP from example"
        fi
    fi
    if [[ ! -f "$CODEX_SESSIONS_FILE" ]]; then
        umask 077
        cat > "$CODEX_SESSIONS_FILE" <<'EOF'
# name=id|description
EOF
        _secrets_info "Created $CODEX_SESSIONS_FILE"
    fi

    export ZSH_ENV_PROFILE="$profile"
    export ZSH_SECRETS_MODE="$mode"
    load_secrets
    _secrets_info "Profile setup complete: $profile"
}

secrets_status() {
    echo "🔐 Secrets"
    echo "=========="
    echo "Mode: $ZSH_SECRETS_MODE"
    echo "File: $ZSH_SECRETS_FILE"
    echo "1Password map: $ZSH_SECRETS_MAP"
    if [[ -n "${SECRETS_MAP_STATUS:-}" ]]; then
        echo "1Password map status: $SECRETS_MAP_STATUS"
    fi
    echo "1Password source: ${ZSH_OP_SOURCE_ACCOUNT:-unset} / ${ZSH_OP_SOURCE_VAULT:-unset}"
    echo "1Password account: ${OP_ACCOUNT:-default}"
    echo "1Password vault: ${OP_VAULT:-default}"
    if command -v op >/dev/null 2>&1; then
        if op account list >/dev/null 2>&1; then
            echo "1Password: Ready"
        else
            echo "1Password: Auth required (run: op signin)"
        fi
    else
        echo "1Password: Not installed"
    fi
}

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

secrets_edit() {
    local editor="${EDITOR:-vi}"
    if [[ ! -f "$ZSH_SECRETS_FILE" ]]; then
        umask 077
        touch "$ZSH_SECRETS_FILE"
    else
        local perms=""
        perms="$(stat -f "%OLp" "$ZSH_SECRETS_FILE" 2>/dev/null || stat -c "%a" "$ZSH_SECRETS_FILE" 2>/dev/null || true)"
        if [[ -n "$perms" && "$perms" != "600" && "$perms" != "400" ]]; then
            _secrets_warn "secrets file has insecure permissions ($perms). Fixing..."
            chmod 600 "$ZSH_SECRETS_FILE" 2>/dev/null || true
        fi
    fi
    "$editor" "$ZSH_SECRETS_FILE"
}

secrets_init() {
    local src="$ZSH_SECRETS_FILE_EXAMPLE"
    if [[ -f "$ZSH_SECRETS_FILE" ]]; then
        _secrets_warn "secrets file already exists: $ZSH_SECRETS_FILE"
        return 1
    fi
    if [[ -f "$src" ]]; then
        umask 077
        cp "$src" "$ZSH_SECRETS_FILE"
        _secrets_info "Created secrets file from example"
        return 0
    fi
    umask 077
    touch "$ZSH_SECRETS_FILE"
    _secrets_info "Created empty secrets file"
}

secrets_init_map() {
    local src="$ZSH_SECRETS_MAP.example"
    if [[ -f "$ZSH_SECRETS_MAP" ]]; then
        _secrets_warn "secrets map already exists: $ZSH_SECRETS_MAP"
        return 1
    fi
    if [[ -f "$src" ]]; then
        umask 077
        cp "$src" "$ZSH_SECRETS_MAP"
        _secrets_info "Created secrets map from example"
        return 0
    fi
    umask 077
    touch "$ZSH_SECRETS_MAP"
    _secrets_info "Created empty secrets map"
}

secrets_map_sanitize() {
    local mode="check"
    local file="${ZSH_SECRETS_MAP:-}"
    if [[ "${1:-}" == "--fix" ]]; then
        mode="fix"
        shift
    fi
    [[ -z "$file" || ! -f "$file" ]] && { _secrets_warn "secrets map not found: $file"; return 1; }

    local tmp
    tmp="$(mktemp)"
    local issues=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        local original="$line"
        # Normalize only the value part (after =), preserve key and structure
        if [[ "$line" != \#* && "$line" == *"="* ]]; then
            local key="${line%%=*}"
            local val="${line#*=}"
            val="$(_secrets_normalize_value "$val")"
            line="${key}=${val}"
        elif [[ "$line" != \#* && -n "$line" ]]; then
            # Legacy space-delimited line: just strip CRLF and trailing whitespace
            line="$(_secrets_strip_crlf "$line")"
            line="$(_secrets_trim_ws "$line")"
        fi
        if [[ "$line" != "$original" ]]; then
            issues=1
        fi
        printf "%s\n" "$line" >> "$tmp"
    done < "$file"

    if [[ "$issues" -eq 0 ]]; then
        rm -f "$tmp"
        export SECRETS_MAP_STATUS="clean"
        _secrets_info "secrets map looks clean"
        return 0
    fi

    if [[ "$mode" == "fix" ]]; then
        mv "$tmp" "$file"
        export SECRETS_MAP_STATUS="fixed"
        _secrets_info "secrets map cleaned: $file"
        return 0
    fi

    rm -f "$tmp"
    export SECRETS_MAP_STATUS="dirty"
    _secrets_warn "secrets map has formatting issues (run: secrets_map_sanitize --fix)"
    return 1
}

_secrets_extract_item_value_from_json() {
    local item_json="$1"
    [[ -z "$item_json" ]] && return 1
    if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
        echo "$item_json" | jq -r '
            (.fields[]? | select((.id=="secrets_file") or (.label=="secrets_file") or (.title=="secrets_file") or (.name=="secrets_file")) | .value)
            // .notesPlain
            // .notes
            // empty
        ' 2>/dev/null
        return 0
    elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
        "$_SECRETS_JSON_CMD" - <<'PY' "$item_json"
import json,sys
data=json.loads(sys.argv[1])
value=""
for field in data.get("fields", []) or []:
    if field.get("id") == "secrets_file" or field.get("label") == "secrets_file" or field.get("title") == "secrets_file" or field.get("name") == "secrets_file":
        value = field.get("value","")
        break
if not value:
    value = data.get("notesPlain","") or data.get("notes","") or ""
print(value)
PY
        return 0
    else
        return 1
    fi
}

secrets_sync_to_1p() {
    local title="${1:-zsh-secrets}"
    local account_arg="${2:-${OP_ACCOUNT-}}"
    local vault_arg="${3:-${OP_VAULT-}}"
    local resolved_account="$account_arg"
    if [[ -n "$account_arg" ]]; then
        resolved_account="$(_op_resolve_account_uuid "$account_arg")"
    fi
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_warn "Vault specified without account; refusing to sync"
        return 1
    fi
    _secrets_require_op "cannot sync secrets to 1Password" || return 1
    if [[ ! -f "$ZSH_SECRETS_FILE" ]]; then
        _secrets_warn "secrets file not found: $ZSH_SECRETS_FILE"
        return 1
    fi
    local content
    content="$(cat "$ZSH_SECRETS_FILE")"
    local err_file
    err_file="$(mktemp)"
    local item_id
    item_id="$(_op_latest_item_id_by_title "$title" "$resolved_account" "$vault_arg")"
    if [[ -n "$item_id" ]]; then
        if _op_cmd item edit "$item_id" \
            ${resolved_account:+--account="$resolved_account"} \
            ${resolved_account:+${vault_arg:+--vault="$vault_arg"}} \
            "secrets_file[text]=$content" \
            "notesPlain=$content" >/dev/null 2>"$err_file"; then
            rm -f "$err_file"
            _secrets_info "Synced secrets file to 1Password item: $title"
            return 0
        fi
        if _op_cmd item edit "$item_id" \
            ${resolved_account:+--account="$resolved_account"} \
            ${resolved_account:+${vault_arg:+--vault="$vault_arg"}} \
            --notes "$content" >/dev/null 2>"$err_file"; then
            rm -f "$err_file"
            _secrets_info "Synced secrets file to 1Password item: $title"
            return 0
        fi
    fi
    if _op_cmd item create \
        --category="Secure Note" \
        --title="$title" \
        ${resolved_account:+--account="$resolved_account"} \
        ${resolved_account:+${vault_arg:+--vault="$vault_arg"}} \
        "secrets_file[text]=$content" \
        "notesPlain=$content" \
        "notes=$content" >/dev/null 2>"$err_file"; then
        rm -f "$err_file"
        _secrets_info "Synced secrets file to 1Password item: $title"
        return 0
    fi
    _secrets_warn "Failed to sync secrets file to 1Password"
    if [[ -s "$err_file" ]]; then
        sed -n '1,3p' "$err_file" >&2
    fi
    rm -f "$err_file"
    return 1
}

secrets_pull_from_1p() {
    local title="${1:-zsh-secrets}"
    local account_arg="${2:-${OP_ACCOUNT-}}"
    local vault_arg="${3:-${OP_VAULT-}}"
    if [[ -z "$account_arg" ]]; then
        account_arg="$(_op_source_account)"
    fi
    if [[ -z "$vault_arg" ]]; then
        vault_arg="$(_op_source_vault)"
    fi
    local resolved_account="$account_arg"
    if [[ -n "$account_arg" ]]; then
        resolved_account="$(_op_resolve_account_uuid "$account_arg")"
    fi
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_warn "Vault specified without account; refusing to pull"
        return 1
    fi
    _secrets_require_op "cannot pull secrets from 1Password" || return 1
    local -a item_ids
    item_ids=($(_op_group_item_ids_by_title "$title" "$resolved_account" "$vault_arg" 2>/dev/null))
    if [[ "${#item_ids[@]}" -eq 0 ]]; then
        local source_candidate=""
        source_candidate="$(secrets_find_account_for_item "$title" "$vault_arg" 2>/dev/null | head -n 1 || true)"
        if [[ -n "$source_candidate" && -n "$resolved_account" && "$source_candidate" != "$resolved_account" ]]; then
            _secrets_warn "Item '$title' exists in account $source_candidate, but current source/account is $resolved_account"
        fi
        _secrets_warn "Item not found: $title"
        return 1
    fi
    local value="" item_id item_json
    local -a tried_ids
    for item_id in "${item_ids[@]}"; do
        tried_ids+=("$item_id")
        value="$(_op_cmd item get "$item_id" \
            ${resolved_account:+--account="$resolved_account"} \
            ${resolved_account:+${vault_arg:+--vault="$vault_arg"}} \
            --field="secrets_file" --reveal 2>/dev/null || true)"
        if [[ -z "$value" ]]; then
            item_json="$(_op_cmd item get "$item_id" \
                ${resolved_account:+--account="$resolved_account"} \
                ${resolved_account:+${vault_arg:+--vault="$vault_arg"}} \
                --format=json 2>/dev/null || true)"
            if [[ -n "$item_json" ]]; then
                value="$(_secrets_extract_item_value_from_json "$item_json")"
            fi
        fi
        if [[ -n "$value" ]]; then
            umask 077
            printf '%s\n' "$value" > "$ZSH_SECRETS_FILE"
            _secrets_info "Pulled secrets into $ZSH_SECRETS_FILE"
            return 0
        fi
    done
    _secrets_warn "No secrets_file/notes found for item: $title (ids tried: ${tried_ids[*]})"
    return 1
}

secrets_sync_all_to_1p() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    local source_account source_vault
    source_account="$(_op_source_account)"
    source_vault="$(_op_source_vault)"
    if [[ -z "$account_arg" ]]; then
        account_arg="$source_account"
    fi
    if [[ -z "$vault_arg" ]]; then
        vault_arg="$source_vault"
    fi
    account_arg="$(_op_resolve_account_uuid "$account_arg")"
    if ! _secrets_require_source "$account_arg" "$vault_arg"; then
        _secrets_info "Run: secrets_source_set <account> <vault> to set source of truth"
        return 1
    fi
    if ! secrets_policy_preflight "$account_arg" "$vault_arg"; then
        _secrets_warn "Policy preflight failed; run: secrets_policy_recover_headless"
        return 1
    fi
    op_accounts_sanitize --fix >/dev/null 2>&1 || true
    local -a _failed_syncs=()
    local old_file="$ZSH_SECRETS_FILE"
    ZSH_SECRETS_FILE="$OP_ACCOUNTS_FILE" \
        secrets_sync_to_1p "op-accounts-env" "$account_arg" "$vault_arg" || _failed_syncs+=("op-accounts-env")
    ZSH_SECRETS_FILE="$old_file" \
        secrets_sync_to_1p "zsh-secrets-env" "$account_arg" "$vault_arg" || _failed_syncs+=("zsh-secrets-env")
    ZSH_SECRETS_FILE="$ZSH_SECRETS_MAP" \
        secrets_sync_to_1p "zsh-secrets-map" "$account_arg" "$vault_arg" || _failed_syncs+=("zsh-secrets-map")
    ZSH_SECRETS_FILE="$CODEX_SESSIONS_FILE" \
        secrets_sync_to_1p "codex-sessions-env" "$account_arg" "$vault_arg" || _failed_syncs+=("codex-sessions-env")
    ZSH_SECRETS_FILE="$old_file"
    if (( ${#_failed_syncs[@]} > 0 )); then
        _secrets_warn "Failed to sync: ${_failed_syncs[*]}"
        return 1
    fi
    return 0
}

secrets_pull_all_from_1p() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    local source_account source_vault
    source_account="$(_op_source_account)"
    source_vault="$(_op_source_vault)"
    if [[ -z "$account_arg" ]]; then
        account_arg="$source_account"
    fi
    if [[ -z "$vault_arg" ]]; then
        vault_arg="$source_vault"
    fi
    account_arg="$(_op_resolve_account_uuid "$account_arg")"
    if ! _secrets_require_source "$account_arg" "$vault_arg"; then
        _secrets_info "Run: secrets_source_set <account> <vault> to set source of truth"
        return 1
    fi
    if ! secrets_policy_preflight "$account_arg" "$vault_arg"; then
        _secrets_warn "Policy preflight failed; run: secrets_policy_recover_headless"
        return 1
    fi
    local -a _failed_pulls=()
    local old_file="$ZSH_SECRETS_FILE"
    ZSH_SECRETS_FILE="$OP_ACCOUNTS_FILE" \
        secrets_pull_from_1p "op-accounts-env" "$account_arg" "$vault_arg" || _failed_pulls+=("op-accounts-env")
    ZSH_SECRETS_FILE="$old_file" \
        secrets_pull_from_1p "zsh-secrets-env" "$account_arg" "$vault_arg" || _failed_pulls+=("zsh-secrets-env")
    ZSH_SECRETS_FILE="$ZSH_SECRETS_MAP" \
        secrets_pull_from_1p "zsh-secrets-map" "$account_arg" "$vault_arg" || _failed_pulls+=("zsh-secrets-map")
    ZSH_SECRETS_FILE="$CODEX_SESSIONS_FILE" \
        secrets_pull_from_1p "codex-sessions-env" "$account_arg" "$vault_arg" || _failed_pulls+=("codex-sessions-env")
    ZSH_SECRETS_FILE="$old_file"
    if (( ${#_failed_pulls[@]} > 0 )); then
        _secrets_warn "Failed to pull: ${_failed_pulls[*]}"
        return 1
    fi
    return 0
}

secrets_profile_switch() {
    local profile="" account="${OP_ACCOUNT-}" vault="${OP_VAULT-}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)  profile="${2:-}"; shift 2 ;;
            --account)  account="${2:-}"; shift 2 ;;
            --vault)    vault="${2:-}"; shift 2 ;;
            --help|-h)  echo "Usage: secrets_profile_switch --profile <name> [--account <acct>] [--vault <vault>]" >&2; return 0 ;;
            *)          profile="$1"; shift ;;  # accept bare arg for convenience
        esac
    done
    if [[ -z "$profile" ]]; then
        echo "Usage: secrets_profile_switch --profile <name> [--account <acct>] [--vault <vault>]" >&2
        return 1
    fi
    if ! _secrets_validate_profile "$profile"; then
        echo "Available profiles: $(_secrets_profile_list)" >&2
        return 1
    fi
    _secrets_update_env_file --key "ZSH_ENV_PROFILE" --value "$profile"
    export ZSH_ENV_PROFILE="$profile"
    if [[ -n "$account" ]]; then
        if ! op_set_default "$account" "$vault"; then
            return 1
        fi
    elif [[ -n "$vault" ]]; then
        _secrets_warn "Vault specified without account; clearing vault"
        OP_VAULT=""
        unset OP_VAULT
    fi
    load_secrets
    _secrets_info "Switched profile to $profile"
}

secrets_profiles() {
    local list
    local -a profiles
    list="$(_secrets_profile_list)"
    if [[ -z "$list" ]]; then
        echo "No profiles configured." >&2
        return 1
    fi
    profiles=("${(@s: :)list}")
    local profile desc colors
    for profile in "${profiles[@]}"; do
        desc=""
        colors=""
        if typeset -p ZSH_PROFILE_CONFIGS >/dev/null 2>&1; then
            desc="${ZSH_PROFILE_CONFIGS[$profile]-}"
        fi
        if typeset -p ZSH_PROFILE_COLORS >/dev/null 2>&1; then
            colors="${ZSH_PROFILE_COLORS[$profile]-}"
        fi
        if [[ -n "$colors" && -n "$desc" ]]; then
            echo "$profile - $desc (colors: $colors)"
        elif [[ -n "$desc" ]]; then
            echo "$profile - $desc"
        elif [[ -n "$colors" ]]; then
            echo "$profile (colors: $colors)"
        else
            echo "$profile"
        fi
    done
}

secrets_bootstrap_from_1p() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    _secrets_require_op "cannot bootstrap secrets" || return 1
    if [[ -z "$account_arg" ]]; then
        local shorthand
        if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
            shorthand="$(op account list --format=json 2>/dev/null | jq -r '.[0].shorthand // empty' 2>/dev/null)"
        elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
            shorthand="$(op account list --format=json 2>/dev/null | "$_SECRETS_JSON_CMD" - <<'PY'
import json,sys
data=json.load(sys.stdin)
print(data[0].get("shorthand","") if data else "")
PY
)"
        fi
        if [[ -n "$shorthand" ]]; then
            account_arg="$shorthand"
        fi
    fi
    if [[ -n "$account_arg" ]]; then
        op_set_default "$account_arg" "$vault_arg" >/dev/null 2>&1 || true
    fi
    local old_file
    old_file="$ZSH_SECRETS_FILE"

    ZSH_SECRETS_FILE="$OP_ACCOUNTS_FILE" \
        secrets_pull_from_1p "op-accounts-env" "$OP_ACCOUNT" "$OP_VAULT" || true
    if [[ -f "$OP_ACCOUNTS_FILE" ]]; then
        _secrets_info "Pulled op-accounts.env"
    else
        _secrets_warn "op-accounts.env not found in 1Password"
    fi

    ZSH_SECRETS_FILE="$old_file" \
        secrets_pull_from_1p "zsh-secrets-env" "$OP_ACCOUNT" "$OP_VAULT" || true

    ZSH_SECRETS_FILE="$ZSH_SECRETS_MAP" \
        secrets_pull_from_1p "zsh-secrets-map" "$OP_ACCOUNT" "$OP_VAULT" || true

    ZSH_SECRETS_FILE="$CODEX_SESSIONS_FILE" \
        secrets_pull_from_1p "codex-sessions-env" "$OP_ACCOUNT" "$OP_VAULT" || true

    export ZSH_SECRETS_FILE="$old_file"
    load_secrets
    _secrets_info "Bootstrap complete"
}

machine_profile() {
    if [[ -n "${ZSH_ENV_PROFILE:-}" ]]; then
        echo "$ZSH_ENV_PROFILE"
        return 0
    fi
    if command -v hostname >/dev/null 2>&1; then
        hostname -s 2>/dev/null || hostname
        return 0
    fi
    echo "unknown-host"
}

secrets_push() {
    local host="${1:-}"
    echo "🔐 Pushing secrets..."

    # Always sync to 1Password if available and authenticated
    if command -v op >/dev/null 2>&1 && _op_cmd account list >/dev/null 2>&1; then
        secrets_sync_all_to_1p && echo "  ✅ 1Password: synced" || echo "  ❌ 1Password: failed"
    else
        echo "  ⏭️  1Password: skipped (not authenticated)"
    fi

    # If host specified, rsync to it
    if [[ -n "$host" ]]; then
        secrets_rsync_to_host "$host" && echo "  ✅ rsync → $host: synced" || echo "  ❌ rsync → $host: failed"
    fi

    echo "Done."
}

secrets_pull() {
    local host="${1:-}"
    echo "🔐 Pulling secrets..."

    if [[ -n "$host" ]]; then
        # Pull from remote host via rsync
        secrets_rsync_from_host "$host" && echo "  ✅ rsync ← $host: synced" || echo "  ❌ rsync ← $host: failed"
    elif command -v op >/dev/null 2>&1 && _op_cmd account list >/dev/null 2>&1; then
        secrets_pull_all_from_1p && echo "  ✅ 1Password: pulled" || echo "  ❌ 1Password: failed"
    else
        _secrets_warn "No source specified and 1Password not authenticated"
        echo "Usage: secrets_pull [user@host]  OR  authenticate 1Password first"
        return 1
    fi

    # Reload
    load_secrets
    echo "Done. Secrets reloaded."
}

secrets_sync_status() {
    echo "🔐 Secrets Sync Status"
    echo "======================"
    echo ""

    # Local files
    echo "Local files:"
    local f
    for f in "${_SECRETS_SYNC_FILES[@]}"; do
        local path="$(_secrets_local_path_default)/$f"
        if [[ -f "$path" ]]; then
            local age_s=$(( $(date +%s) - $(stat -c %Y "$path" 2>/dev/null || stat -f %m "$path" 2>/dev/null || echo 0) ))
            local age_h=$(( age_s / 3600 ))
            echo "  ✅ $f (modified ${age_h}h ago)"
        else
            echo "  ❌ $f (missing)"
        fi
    done
    echo ""

    # 1Password
    echo "1Password:"
    if command -v op >/dev/null 2>&1; then
        if _op_cmd account list >/dev/null 2>&1; then
            if op whoami >/dev/null 2>&1; then
                echo "  ✅ Authenticated (session active)"
            else
                echo "  ⚠️  Accounts configured but session expired (run: eval \"\$(op signin)\")"
            fi
        else
            echo "  ❌ Not configured (run: op account add)"
        fi
    else
        echo "  ❌ CLI not installed"
    fi
    echo "  Source: ${ZSH_OP_SOURCE_ACCOUNT:-unset} / ${ZSH_OP_SOURCE_VAULT:-unset}"
    echo ""

    # Quick workflow guide
    echo "Quick workflow:"
    echo "  secrets_push              → sync to 1Password"
    echo "  secrets_push user@host    → sync to 1Password + rsync to host"
    echo "  secrets_pull              → pull from 1Password"
    echo "  secrets_pull user@host    → pull from host via rsync"
    echo ""
}

_secrets_auto_signin_all_on_load() {
    [[ -n "${ZSH_TEST_MODE:-}" ]] && return 0
    [[ "${ZSH_OP_AUTO_SIGNIN_ALL:-1}" == "1" ]] || return 0
    [[ -o interactive ]] || return 0
    if [[ "${ZSH_IS_IDE_TERMINAL:-0}" == "1" && "${ZSH_OP_AUTO_SIGNIN_IN_IDE:-0}" != "1" ]]; then
        return 0
    fi
    [[ "$ZSH_SECRETS_MODE" == "op" || "$ZSH_SECRETS_MODE" == "both" ]] || return 0
    command -v op >/dev/null 2>&1 || return 0
    [[ -f "$OP_ACCOUNTS_FILE" ]] || return 0
    typeset -f op_signin_all >/dev/null 2>&1 || return 0

    local stamp_file="${ZSH_OP_AUTO_SIGNIN_STAMP:-$HOME/.config/zsh/.op_signin_all.stamp}"
    local now last age max_age
    now="$(date +%s)"
    max_age="${ZSH_OP_AUTO_SIGNIN_MAX_AGE_SEC:-300}"
    last="0"
    if [[ -f "$stamp_file" ]]; then
        last="$(stat -f %m "$stamp_file" 2>/dev/null || stat -c %Y "$stamp_file" 2>/dev/null || echo 0)"
    fi
    if [[ "$last" =~ '^[0-9]+$' ]]; then
        age=$(( now - last ))
        if (( age >= 0 && age < max_age )); then
            return 0
        fi
    fi
    umask 077
    : > "$stamp_file" 2>/dev/null || true

    if ! op_signin_all >/dev/null 2>&1; then
        _secrets_warn "Auto 1Password sign-in for all accounts failed (run: op_signin_all)"
        return 1
    fi
    [[ "${ZSH_SECRETS_VERBOSE:-}" == "1" ]] && _secrets_info "Auto-signed in all configured 1Password accounts"

    # After successful auto-signin, refresh agent cache for non-interactive shells
    if typeset -f secrets_agent_refresh >/dev/null 2>&1; then
        secrets_agent_refresh >/dev/null 2>&1 || true
    fi
    return 0
}

# Auto-load secrets unless disabled or in test mode
if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    load_secrets
    _secrets_auto_signin_all_on_load || true
    _secrets_check_profile
    [[ "${ZSH_SECRETS_VERBOSE:-}" == "1" ]] && echo "✅ secrets loaded"
fi

