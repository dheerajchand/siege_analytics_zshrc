#!/usr/bin/env zsh
# =================================================================
# SECRETS — 1Password bidirectional sync
# =================================================================
# Push local env values to 1Password, pull them back, prune duplicate
# items, surface items that are missing either side, and bootstrap a
# fresh machine from a source vault.

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

