#!/usr/bin/env zsh
# =================================================================
# SECRETS — load + init + edit + validate + status
# =================================================================
# Everything that's not 1Password CLI, policy, profile, agent-cache,
# or sync: the top-level load_secrets entry point, secrets_init*,
# file/op loading, edit/status/validate, and remaining helpers.

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

_secrets_default_profiles() {
    echo "dev staging prod laptop cyberpower"
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

