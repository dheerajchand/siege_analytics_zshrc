#!/usr/bin/env zsh
# =================================================================
# SECRETS — policy checks
# =================================================================
# Preflight + recovery for the secrets policy (required items,
# headless recovery paths, status reporting).

_secrets_policy_titles() {
    echo "op-accounts-env zsh-secrets-env zsh-secrets-map codex-sessions-env"
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

secrets_policy_recover_headless() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    op_accounts_sanitize --fix >/dev/null 2>&1 || true
    secrets_map_sanitize --fix >/dev/null 2>&1 || true
    secrets_prune_duplicates_1p "$account_arg" "$vault_arg" >/dev/null 2>&1 || true
    secrets_missing_from_1p --fix "$account_arg" "$vault_arg" >/dev/null 2>&1 || true
    secrets_policy_preflight "$account_arg" "$vault_arg"
}

secrets_policy_status() {
    if [[ "${1:-}" == "--json" ]]; then
        secrets_policy_preflight --json
        return $?
    fi
    secrets_policy_preflight
}

