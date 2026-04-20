#!/usr/bin/env zsh
# =================================================================
# SECRETS — 1Password CLI layer
# =================================================================
# All _op_* helpers and op_* public commands. Depends on core.zsh
# for _secrets_warn / _secrets_info / _secrets_normalize_value.

_op_account_alias() {
    local alias_name="$1"
    [[ -f "$OP_ACCOUNTS_FILE" ]] || return 1
    local line key val
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue
        if [[ "$line" == *"="* ]]; then
            key="${line%%=*}"
            val="${line#*=}"
            key="${key## }"; key="${key%% }"
            if [[ "$key" == "$alias_name" ]]; then
                echo "$(_secrets_normalize_value "$val")"
                return 0
            fi
        fi
    done < "$OP_ACCOUNTS_FILE"
    return 1
}

_op_account_alias_for_uuid() {
    local uuid="$1"
    [[ -f "$OP_ACCOUNTS_FILE" ]] || return 1
    local line key val
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        [[ "$line" == \#* ]] && continue
        if [[ "$line" == *"="* ]]; then
            key="${line%%=*}"
            val="${line#*=}"
            key="${key## }"; key="${key%% }"
            val="$(_secrets_normalize_value "$val")"
            if [[ "$val" == "$uuid" ]]; then
                echo "$key"
                return 0
            fi
        fi
    done < "$OP_ACCOUNTS_FILE"
    return 1
}

op_accounts_edit() {
    local editor="${EDITOR:-vi}"
    if [[ ! -f "$OP_ACCOUNTS_FILE" ]]; then
        umask 077
        if [[ -f "$OP_ACCOUNTS_FILE_EXAMPLE" ]]; then
            cp "$OP_ACCOUNTS_FILE_EXAMPLE" "$OP_ACCOUNTS_FILE"
        else
            touch "$OP_ACCOUNTS_FILE"
        fi
    fi
    "$editor" "$OP_ACCOUNTS_FILE"
}

op_accounts_sanitize() {
    local mode="check"
    local file="${OP_ACCOUNTS_FILE:-}"
    if [[ "${1:-}" == "--fix" ]]; then
        mode="fix"
        shift
    fi
    [[ -z "$file" || ! -f "$file" ]] && { _secrets_warn "alias file not found: $file"; return 1; }

    local tmp
    tmp="$(mktemp)"
    local issues=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        local original="$line"
        line="$(_secrets_normalize_value "$line")"
        if [[ "$line" != "$original" ]]; then
            issues=1
        fi
        printf "%s\n" "$line" >> "$tmp"
    done < "$file"

    if [[ "$issues" -eq 0 ]]; then
        rm -f "$tmp"
        _secrets_info "aliases file looks clean"
        return 0
    fi

    if [[ "$mode" == "fix" ]]; then
        mv "$tmp" "$file"
        _secrets_info "aliases file cleaned: $file"
        return 0
    fi

    rm -f "$tmp"
    _secrets_warn "aliases file has formatting issues (run: op_accounts_sanitize --fix)"
    return 1
}

_op_accounts_write_kv() {
    local alias_name="$1"
    local uuid="$2"
    local file="$OP_ACCOUNTS_FILE"
    [[ -z "$alias_name" || -z "$uuid" ]] && return 1
    umask 077
    [[ -f "$file" ]] || : > "$file"
    local tmp updated
    tmp="$(mktemp "${file}.XXXXXX")" || return 1
    updated=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "${alias_name}="* ]]; then
            echo "${alias_name}=${uuid}" >> "$tmp"
            updated=1
        else
            echo "$line" >> "$tmp"
        fi
    done < "$file"
    if [[ "$updated" -eq 0 ]]; then
        echo "${alias_name}=${uuid}" >> "$tmp"
    fi
    mv "$tmp" "$file"
}

_op_account_uuid_configured() {
    local uuid="${1:-}"
    local json="${2:-}"
    [[ -z "$uuid" || -z "$json" ]] && return 1
    if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
        printf '%s' "$json" | jq -e --arg u "$uuid" 'any(.[]; .account_uuid == $u)' >/dev/null 2>&1
    elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
        printf '%s' "$json" | "$_SECRETS_JSON_CMD" -c 'import json,sys; data=json.load(sys.stdin); u=sys.argv[1];
sys.exit(0 if any((a.get("account_uuid") or "")==u for a in data) else 1)' "$uuid" 2>/dev/null
    else
        return 1
    fi
}

_op_account_shorthand_configured() {
    local shorthand="${1:-}"
    local json="${2:-}"
    [[ -z "$shorthand" || -z "$json" ]] && return 1
    if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
        printf '%s' "$json" | jq -e --arg s "$shorthand" 'any(.[]; .shorthand == $s)' >/dev/null 2>&1
    elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
        printf '%s' "$json" | "$_SECRETS_JSON_CMD" -c 'import json,sys; data=json.load(sys.stdin); s=sys.argv[1];
sys.exit(0 if any((a.get("shorthand") or "")==s for a in data) else 1)' "$shorthand" 2>/dev/null
    else
        return 1
    fi
}

_op_cmd() {
    local bin="${OP_BIN:-op}"
    command "$bin" "$@"
}

_op_source_account() {
    local account="${ZSH_OP_SOURCE_ACCOUNT:-}"
    [[ -z "$account" ]] && { echo ""; return 0; }
    echo "$(_op_resolve_account_uuid "$account")"
}

_op_source_vault() {
    echo "${ZSH_OP_SOURCE_VAULT:-}"
}

_op_resolve_account_uuid() {
    local account="$1"
    [[ -z "$account" ]] && { echo ""; return 0; }
    if [[ "$account" =~ ^[A-Z0-9]{26}$ ]]; then
        echo "$account"
        return 0
    fi
    local resolved
    resolved="$(_op_account_alias "$account" 2>/dev/null || true)"
    if [[ -n "$resolved" ]]; then
        echo "$resolved"
        return 0
    fi
    local accounts_json=""
    if command -v op >/dev/null 2>&1; then
        accounts_json="$(_op_cmd account list --format=json 2>/dev/null || true)"
    fi
    if [[ -n "$accounts_json" ]]; then
        if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
            local jq_result
            jq_result="$(printf '%s' "$accounts_json" | jq -r --arg n "$account" '.[] | select(.shorthand == $n) | .account_uuid // empty' 2>/dev/null)"
            if [[ -n "$jq_result" ]]; then
                echo "$jq_result"
                return 0
            fi
        elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
            "$_SECRETS_JSON_CMD" - <<'PY' "$accounts_json" "$account" 2>/dev/null && return 0
import json,sys
data=json.loads(sys.argv[1])
name=sys.argv[2]
for a in data:
    if (a.get("shorthand") or "") == name:
        print(a.get("account_uuid",""))
        sys.exit(0)
sys.exit(1)
PY
        fi
    fi
    echo "$account"
}

_op_resolve_account_arg() {
    local account="$1"
    [[ -z "$account" ]] && { echo ""; return 0; }
    local accounts_json=""
    if command -v op >/dev/null 2>&1; then
        accounts_json="$(command op account list --format=json 2>/dev/null || true)"
    fi
    if [[ -n "$accounts_json" ]]; then
        if _op_account_shorthand_configured "$account" "$accounts_json"; then
            echo "$account"
            return 0
        fi
    fi
    local resolved
    resolved="$(_op_account_alias "$account" 2>/dev/null || true)"
    if [[ -n "$resolved" ]]; then
        if [[ -n "$accounts_json" ]] && _op_account_uuid_configured "$resolved" "$accounts_json"; then
            echo "$resolved"
            return 0
        fi
    fi
    echo "$account"
}

op_accounts_set_alias() {
    local alias_name="${1:-}"
    local uuid="${2:-}"
    if [[ -z "$alias_name" || -z "$uuid" ]]; then
        echo "Usage: op_accounts_set_alias <alias> <account-uuid>" >&2
        return 1
    fi
    if [[ ! "$alias_name" =~ ^[A-Za-z0-9_]+$ ]]; then
        _secrets_warn "Alias must be alphanumeric/underscore: $alias_name"
        return 1
    fi
    _op_accounts_write_kv "$alias_name" "$uuid" || return 1
    _secrets_info "Set alias: $alias_name"
}

op_accounts_seed() {
    _secrets_require_op "cannot seed aliases" || return 1
    if [[ -z "${ZSH_TEST_MODE:-}" && ! -o interactive ]]; then
        _secrets_warn "Interactive shell required to seed aliases"
        return 1
    fi
    local json
    json="$(OP_CLI_NO_COLOR=1 op account list --format=json 2>/dev/null || true)"
    if [[ -z "$json" ]]; then
        _secrets_warn "No accounts returned by op account list"
        return 1
    fi
    local line account_uuid email url alias_name
    while IFS=$'\t' read -r account_uuid email url; do
        [[ -z "$account_uuid" ]] && continue
        alias_name="$(_op_account_alias_for_uuid "$account_uuid" 2>/dev/null || true)"
        if [[ -n "$alias_name" ]]; then
            continue
        fi
        read -r "alias_name?Alias for ${email:-unknown} @ ${url:-unknown} (${account_uuid}) [skip]: "
        [[ -z "$alias_name" ]] && continue
        if [[ ! "$alias_name" =~ ^[A-Za-z0-9_]+$ ]]; then
            _secrets_warn "Skipping invalid alias: $alias_name"
            continue
        fi
        _op_accounts_write_kv "$alias_name" "$account_uuid"
    done < <(
        if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
            printf '%s' "$json" | jq -r '.[] | "\(.account_uuid)\t\(.email)\t\(.url)"'
        elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
            "$_SECRETS_JSON_CMD" - <<'PY' "$json"
import json,sys
data=json.loads(sys.argv[1])
for a in data:
    print(f"{a.get('account_uuid','')}\t{a.get('email','')}\t{a.get('url','')}")
PY
        fi
    )
    _secrets_info "Alias seeding complete"
}

op_verify_accounts() {
    local rc=0
    (
        emulate -L zsh -o no_xtrace -o no_verbose
        if ! command -v op >/dev/null 2>&1; then
            _secrets_warn "op not found; cannot verify accounts"
            exit 1
        fi
        if ! op account list >/dev/null 2>&1; then
            _secrets_warn "1Password auth required (run: eval \"\$(op signin)\")"
            exit 1
        fi
        if [[ ! -f "$OP_ACCOUNTS_FILE" ]]; then
            _secrets_warn "No account aliases file: $OP_ACCOUNTS_FILE"
            exit 1
        fi
        echo "🔐 1Password Account Verification"
        echo "================================"
        printf "%-22s | %-32s | %-40s | %s\n" "Alias" "UUID" "Item" "Result"
        local py_cmd="${_SECRETS_JSON_CMD}"
        if [[ "$py_cmd" == "jq" ]]; then
            # verify needs python for complex item inspection; find it
            if command -v python3 >/dev/null 2>&1; then py_cmd="python3"
            elif command -v python >/dev/null 2>&1; then py_cmd="python"
            else _secrets_warn "python not found; cannot verify items"; exit 1; fi
        fi
        [[ -z "$py_cmd" ]] && { _secrets_warn "No JSON tool found; cannot verify items"; exit 1; }
        local line alias_name uuid
        local accounts_json
        accounts_json="$(OP_CLI_NO_COLOR=1 op account list --format=json 2>/dev/null || true)"
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" || "$line" == \#* ]] && continue
            alias_name="${line%%=*}"
            uuid="${line#*=}"
            alias_name="${alias_name## }"; alias_name="${alias_name%% }"
            uuid="${uuid## }"; uuid="${uuid%% }"
            [[ -z "$alias_name" || -z "$uuid" ]] && continue
            local account_arg=""
            if _op_account_shorthand_configured "$alias_name" "$accounts_json"; then
                account_arg="$alias_name"
            elif _op_account_uuid_configured "$uuid" "$accounts_json"; then
                account_arg="$uuid"
            else
                printf "%-22s | %-32s | %-40s | %s\n" "$alias_name" "$uuid" "(account)" "FAIL"
                continue
            fi
            local item_id rc_code
            item_id="$(OP_CLI_NO_COLOR=1 op item list --account "$account_arg" --format json 2>/dev/null | OP_VERIFY_RAND="$RANDOM" "$py_cmd" -c 'import json,os,sys; data=json.load(sys.stdin);
if not data: sys.exit(2)
r=int(os.environ.get("OP_VERIFY_RAND","0") or "0")
item=data[r % len(data)]
print(item.get("id",""))' 2>/dev/null)"
            rc_code=$?
            if [[ "$rc_code" -eq 2 ]]; then
                printf "%-22s | %-32s | %-40s | %s\n" "$alias_name" "$uuid" "(none)" "FAIL"
                continue
            fi
            if [[ "$rc_code" -ne 0 || -z "$item_id" ]]; then
                printf "%-22s | %-32s | %-40s | %s\n" "$alias_name" "$uuid" "(list)" "FAIL"
                continue
            fi
            local title_out
            title_out="$(_secrets_truncate "item:${item_id}" 40)"
            local value_ok
            value_ok="$(OP_CLI_NO_COLOR=1 op item get "$item_id" --account "$account_arg" --format json 2>/dev/null | "$py_cmd" -c 'import json,sys; data=json.load(sys.stdin); 
ok=False
for f in data.get("fields",[]) or []:
    v=f.get("value")
    if isinstance(v,str) and v.strip():
        ok=True; break
if not ok:
    np=data.get("notesPlain")
    if isinstance(np,str) and np.strip():
        ok=True
print("1" if ok else "0")' 2>/dev/null || true)"
            if [[ "$value_ok" == "1" ]]; then
                printf "%-22s | %-32s | %-40s | %s\n" "$alias_name" "$uuid" "$title_out" "PASS"
            else
                printf "%-22s | %-32s | %-40s | %s\n" "$alias_name" "$uuid" "$title_out" "FAIL"
            fi
        done < "$OP_ACCOUNTS_FILE"
    )
    rc=$?
    return $rc
}

_op_latest_item_id_by_title() {
    local title="$1"
    local account_arg="${2:-${OP_ACCOUNT-}}"
    local vault_arg="${3:-${OP_VAULT-}}"
    local resolved_account="$account_arg"
    if [[ -n "$account_arg" ]]; then
        resolved_account="$(_op_resolve_account_uuid "$account_arg")"
    fi
    local items_json
    items_json="$(OP_CLI_NO_COLOR=1 _op_cmd item list \
        ${resolved_account:+--account="$resolved_account"} \
        ${resolved_account:+${vault_arg:+--vault="$vault_arg"}} \
        --format=json 2>/dev/null || true)"
    if [[ ( -z "$items_json" || "$items_json" == "[]" ) && -n "$vault_arg" ]]; then
        items_json="$(OP_CLI_NO_COLOR=1 _op_cmd item list \
            ${resolved_account:+--account="$resolved_account"} \
            --format=json 2>/dev/null || true)"
    fi
    if [[ -z "$items_json" ]]; then
        return 1
    fi
    if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
        local id
        id="$(printf '%s' "$items_json" | jq -r --arg t "$title" '
            [ .[] | select(.title == $t) ] | sort_by(.updatedAt // .updated_at // .createdAt // .created_at) | last | .id // empty
        ' 2>/dev/null || true)"
        [[ -n "$id" ]] && { echo "$id"; return 0; }
    elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
        "$_SECRETS_JSON_CMD" - <<'PY' "$items_json" "$title" 2>/dev/null && return 0
import json,sys
data=json.loads(sys.argv[1])
title=sys.argv[2]
matches=[i for i in data if i.get("title")==title]
def ts(i):
    return i.get("updatedAt") or i.get("updated_at") or i.get("createdAt") or i.get("created_at") or ""
matches.sort(key=ts)
if matches:
    print(matches[-1].get("id",""))
PY
    fi
    return 1
}

_op_group_item_ids_by_title() {
    local title="$1"
    local account_arg="${2:-${OP_ACCOUNT-}}"
    local vault_arg="${3:-${OP_VAULT-}}"
    local resolved_account="$account_arg"
    if [[ -n "$account_arg" ]]; then
        resolved_account="$(_op_resolve_account_uuid "$account_arg")"
    fi
    local items_json
    items_json="$(OP_CLI_NO_COLOR=1 _op_cmd item list \
        ${resolved_account:+--account="$resolved_account"} \
        ${resolved_account:+${vault_arg:+--vault="$vault_arg"}} \
        --format=json 2>/dev/null || true)"
    if [[ ( -z "$items_json" || "$items_json" == "[]" ) && -n "$vault_arg" ]]; then
        items_json="$(OP_CLI_NO_COLOR=1 _op_cmd item list \
            ${resolved_account:+--account="$resolved_account"} \
            --format=json 2>/dev/null || true)"
    fi
    [[ -z "$items_json" ]] && return 1
    if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
        echo "$items_json" | jq -r --arg t "$title" '
            [ .[] | select(.title == $t) ] | sort_by(.updatedAt // .updated_at // .createdAt // .created_at) | .[].id // empty
        ' 2>/dev/null
        return 0
    elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
        "$_SECRETS_JSON_CMD" - <<'PY' "$items_json" "$title" 2>/dev/null
import json,sys
data=json.loads(sys.argv[1])
title=sys.argv[2]
matches=[i for i in data if i.get("title")==title]
def ts(i):
    return i.get("updatedAt") or i.get("updated_at") or i.get("createdAt") or i.get("created_at") or ""
matches.sort(key=ts)
for item in matches:
    print(item.get("id",""))
PY
    else
        return 1
    fi
}

op_set_default() {
    local account="${1:-}"
    local vault="${2:-}"
    if [[ -n "$vault" && -z "$account" ]]; then
        _secrets_warn "Vault specified without account; refusing to set vault"
        return 1
    fi
    if [[ -n "$account" ]]; then
        local account_arg
        account_arg="$(_op_resolve_account_arg "$account")"
        if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
            local accounts_json
            accounts_json="$(op account list --format=json 2>/dev/null || true)"
            if ! _op_account_shorthand_configured "$account_arg" "$accounts_json" && \
               ! _op_account_uuid_configured "$account_arg" "$accounts_json"; then
                local resolved
                resolved="$(_op_account_alias "$account" 2>/dev/null || true)"
                _secrets_warn "Account not configured on this device: $account${resolved:+ ($resolved)}"
                _secrets_info "Run: op account add --shorthand $account"
            fi
        fi
        export OP_ACCOUNT="$account_arg"
        if [[ -z "$vault" ]]; then
            unset OP_VAULT
        fi
    fi
    if [[ -n "$vault" ]]; then
        export OP_VAULT="$vault"
    fi
    _secrets_info "1Password defaults: account=${OP_ACCOUNT:-default} vault=${OP_VAULT:-default}"
}

op_list_accounts_vaults() {
    _secrets_require_op "cannot list accounts/vaults" || return 1
    local accounts_json
    accounts_json="$(op account list --format=json 2>/dev/null)"
    if [[ -z "$accounts_json" ]]; then
        _secrets_warn "No 1Password accounts found"
        return 1
    fi
    echo "🔐 1Password Accounts & Vaults"
    echo "=============================="
    local acct_list
    if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
        acct_list="$(echo "$accounts_json" | jq -r '.[] | "\(.account_uuid)\t\(.email)\t\(.url)"')"
    elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
        acct_list="$("$_SECRETS_JSON_CMD" - <<'PY' <<<"$accounts_json"
import json,sys
data=json.load(sys.stdin)
for item in data:
    print(f"{item.get('account_uuid','')}\t{item.get('email','')}\t{item.get('url','')}")
PY
)"
    else
        _secrets_warn "No JSON tool (jq/python) available"
        return 1
    fi
    local line account_uuid email url alias
    while IFS=$'\t' read -r account_uuid email url; do
        [[ -z "$account_uuid" ]] && continue
        alias="$(_op_account_alias_for_uuid "$account_uuid" 2>/dev/null || true)"
        if [[ -n "$alias" ]]; then
            echo "Account: $alias ($account_uuid) @ $url"
        else
            echo "Account: $account_uuid @ $url"
        fi
        local vaults
        if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
            vaults="$(op vault list --account="$account_uuid" --format=json 2>/dev/null | jq -r '.[]?.name' || true)"
        elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
            vaults="$(op vault list --account="$account_uuid" --format=json 2>/dev/null | \
                "$_SECRETS_JSON_CMD" - <<'PY'
import json,sys
data=json.load(sys.stdin)
for item in data:
    name=item.get("name")
    if name:
        print(f"{name}")
PY
)"
        fi
        if [[ -z "$vaults" ]]; then
            echo "  - (none found or access denied)"
        else
            echo "$vaults" | awk '{print "  - " $0}'
        fi
    done <<<"$acct_list"
}

op_list_items() {
    local account_arg="${1:-${OP_ACCOUNT-}}"
    local vault_arg="${2:-${OP_VAULT-}}"
    local filter="${3:-}"
    if [[ -n "$vault_arg" && -z "$account_arg" ]]; then
        _secrets_warn "Vault specified without account; refusing to list items"
        return 1
    fi
    _secrets_require_op "cannot list items" || return 1
    local items_json
    items_json="$(op item list \
        ${account_arg:+--account="$account_arg"} \
        ${account_arg:+${vault_arg:+--vault="$vault_arg"}} \
        --format=json 2>/dev/null || true)"
    if [[ -z "$items_json" ]]; then
        _secrets_warn "No items found"
        return 1
    fi
    local titles
    if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
        if [[ -n "$filter" ]]; then
            titles="$(echo "$items_json" | jq -r --arg f "$filter" '.[] | select(.title | test($f;"i")) | .title')"
        else
            titles="$(echo "$items_json" | jq -r '.[].title')"
        fi
    elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
        titles="$("$_SECRETS_JSON_CMD" - <<'PY' "$filter" <<<"$items_json"
import json,sys,re
flt=sys.argv[1] if len(sys.argv)>1 else ""
data=json.load(sys.stdin)
out=[]
for item in data:
    title=item.get("title","")
    if not title:
        continue
    if flt:
        if re.search(flt, title, re.I):
            out.append(title)
    else:
        out.append(title)
print("\n".join(out))
PY
)"
    else
        _secrets_warn "No JSON tool (jq/python) available"
        return 1
    fi
    if [[ -z "$titles" ]]; then
        _secrets_warn "No items found"
        return 1
    fi
    echo "$titles"
}

op_find_item_across_accounts() {
    local title="${1:-}"
    if [[ -z "$title" ]]; then
        _secrets_warn "Usage: op_find_item_across_accounts <title>"
        return 1
    fi
    _secrets_require_op "cannot search items" || return 1
    local accounts_json
    accounts_json="$(op account list --format=json 2>/dev/null || true)"
    if [[ -z "$accounts_json" ]]; then
        _secrets_warn "No accounts configured on this device"
        return 1
    fi
    local uuids
    if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
        uuids="$(printf '%s' "$accounts_json" | jq -r '[.[].account_uuid // empty] | join(" ")' 2>/dev/null || true)"
    elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
        uuids="$(printf '%s' "$accounts_json" | "$_SECRETS_JSON_CMD" -c 'import json,sys; data=json.load(sys.stdin); print(" ".join([a.get("account_uuid","") for a in data if a.get("account_uuid")]))' 2>/dev/null || true)"
    else
        _secrets_warn "No JSON tool (jq/python) available"
        return 1
    fi
    for uuid in $uuids; do
        local items_json
        items_json="$(op item list --account "$uuid" --format=json 2>/dev/null || true)"
        if [[ -z "$items_json" ]]; then
            continue
        fi
        local matches
        if [[ "$_SECRETS_JSON_CMD" == "jq" ]]; then
            matches="$(printf '%s' "$items_json" | jq -r --arg t "$title" '.[] | select(.title == $t) | "\(.id)\t\(.title)\t\(.vault.name // "?")"' 2>/dev/null || true)"
        elif [[ -n "$_SECRETS_JSON_CMD" ]]; then
            matches="$("$_SECRETS_JSON_CMD" - <<'PY' "$items_json" "$title" 2>/dev/null || true
import json,sys
data=json.loads(sys.argv[1])
title=sys.argv[2]
for i in data:
    if i.get("title") == title:
        vault=i.get("vault",{}).get("name","?")
        print(f"{i.get('id','')}\t{i.get('title','')}\t{vault}")
PY
)"
        else
            _secrets_warn "No JSON tool (jq/python) available"
            return 1
        fi
        if [[ -n "$matches" ]]; then
            printf "Account %s:\n" "$uuid"
            printf "%s\n" "$matches"
        fi
    done
}

op_signin_account() {
    local account_alias="${1:-}"
    if [[ -z "$account_alias" ]]; then
        echo "Usage: op_signin_account <account-alias>" >&2
        return 1
    fi
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot sign in"
        return 1
    fi
    local resolved
    resolved="$(_op_account_alias "$account_alias" 2>/dev/null || true)"
    if [[ -z "$resolved" ]]; then
        _secrets_warn "Account alias not found: $account_alias"
        _secrets_info "Edit: op_accounts_edit"
        return 1
    fi
    if [[ "$account_alias" =~ ^[A-Za-z0-9_]+$ ]]; then
        local token
        token="$(op signin --account "$resolved" --raw 2>/dev/null || true)"
        if [[ -z "$token" ]]; then
            _secrets_warn "Failed to sign in: $account_alias"
            return 1
        fi
        export "OP_SESSION_${account_alias}=${token}"
    else
        _secrets_warn "Alias '$account_alias' not safe for OP_SESSION variable name"
        return 1
    fi
}

op_signin_all() {
    setopt local_options
    unsetopt xtrace verbose
    if ! command -v op >/dev/null 2>&1; then
        _secrets_warn "op not found; cannot sign in"
        return 1
    fi
    if [[ ! -f "$OP_ACCOUNTS_FILE" ]]; then
        _secrets_warn "No account aliases file: $OP_ACCOUNTS_FILE"
        _secrets_info "Create: op_accounts_edit"
        return 1
    fi
    local accounts_json
    accounts_json="$(OP_CLI_NO_COLOR=1 op account list --format=json 2>/dev/null || true)"
    if [[ -z "$accounts_json" ]]; then
        _secrets_warn "No accounts configured on this device (run: op account add)"
        return 1
    fi
    local line alias_name resolved token reply ok=0 fail=0
    local _sessions_tmp
    _sessions_tmp="$(mktemp)"
    umask 077
    chmod 600 "$_sessions_tmp" 2>/dev/null || true
    printf '# op session state — written by op_signin_all at %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" > "$_sessions_tmp"
    while IFS= read -r -u3 line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        alias_name="${line%%=*}"
        alias_name="${alias_name## }"; alias_name="${alias_name%% }"
        [[ -z "$alias_name" ]] && continue
        echo "🔐 Signing in: $alias_name"
        resolved="$(_op_account_alias "$alias_name" 2>/dev/null || true)"
        if [[ -z "$resolved" ]]; then
            _secrets_warn "Account alias not found: $alias_name"
            ((fail++))
            continue
        fi
        if ! _op_account_shorthand_configured "$alias_name" "$accounts_json" && \
           ! _op_account_uuid_configured "$resolved" "$accounts_json"; then
            _secrets_warn "Account not configured: $alias_name ($resolved)"
            if [[ -o interactive ]]; then
                reply=""
                read -r "reply?Add now with 'op account add --shorthand $alias_name'? [y/N]: "
                if [[ "$reply" =~ ^[Yy]$ ]]; then
                    op account add --shorthand "$alias_name" || {
                        ((fail++))
                        continue
                    }
                    accounts_json="$(OP_CLI_NO_COLOR=1 op account list --format=json 2>/dev/null || true)"
                else
                    ((fail++))
                    continue
                fi
            else
                ((fail++))
                continue
            fi
        fi
        if [[ ! "$alias_name" =~ ^[A-Za-z0-9_]+$ ]]; then
            _secrets_warn "Invalid alias for OP_SESSION var: $alias_name"
            ((fail++))
            continue
        fi
        # Determine which identifier op knows: prefer shorthand, fall back to UUID
        local signin_id="$resolved"
        if _op_account_shorthand_configured "$alias_name" "$accounts_json"; then
            signin_id="$alias_name"
        fi
        unset "OP_SESSION_${alias_name}" 2>/dev/null || true
        local signin_err="" signin_rc
        local _stderr_file="$(mktemp)"
        if [[ -e /dev/tty ]]; then
            token="$(OP_CLI_NO_COLOR=1 op signin --account "$signin_id" --raw </dev/tty 2>"$_stderr_file")"
        else
            token="$(OP_CLI_NO_COLOR=1 op signin --account "$signin_id" --raw 2>"$_stderr_file")"
        fi
        signin_rc=$?
        signin_err="$(<"$_stderr_file")"
        rm -f "$_stderr_file"
        if [[ "$signin_rc" -ne 0 ]]; then
            _secrets_warn "Failed to sign in: $alias_name (account: $signin_id)"
            [[ -n "$signin_err" ]] && _secrets_warn "  op error: $signin_err"
            _secrets_info "Try: op signin --account $signin_id"
            ((fail++))
            continue
        fi
        # With app integration (biometric), token is empty but signin succeeds
        if [[ -n "$token" ]]; then
            export "OP_SESSION_${alias_name}=${token}"
        fi
        # Record successful signin for agent access
        # Human-legible label, resolved UUID, and op identifier
        printf '# %s\n' "$alias_name" >> "$_sessions_tmp"
        printf 'OP_SIGNED_IN_%s=%q\n' "$alias_name" "$signin_id" >> "$_sessions_tmp"
        printf 'OP_UUID_%s=%q\n' "$alias_name" "$resolved" >> "$_sessions_tmp"
        # Include email/URL for human identification
        local _acct_email _acct_url
        _acct_email="$(printf '%s' "$accounts_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(next((a.get('email','') for a in d if a.get('account_uuid')==sys.argv[1]),''))" "$resolved" 2>/dev/null || true)"
        _acct_url="$(printf '%s' "$accounts_json" | python3 -c "import json,sys; d=json.load(sys.stdin); print(next((a.get('url','') for a in d if a.get('account_uuid')==sys.argv[1]),''))" "$resolved" 2>/dev/null || true)"
        [[ -n "$_acct_email" ]] && printf 'OP_EMAIL_%s=%q\n' "$alias_name" "$_acct_email" >> "$_sessions_tmp"
        [[ -n "$_acct_url" ]] && printf 'OP_URL_%s=%q\n' "$alias_name" "$_acct_url" >> "$_sessions_tmp"
        if [[ -n "$token" ]]; then
            printf 'OP_SESSION_%s=%q\n' "$alias_name" "$token" >> "$_sessions_tmp"
        fi
        echo "✅ Signed in: $alias_name"
        ((ok++))
    done 3< "$OP_ACCOUNTS_FILE"
    echo "Done: ${ok} ok, ${fail} failed"

    # Finalize session file with defaults and move into place
    _op_sessions_save --tmp-file "$_sessions_tmp" --count "$ok"

    [[ "$fail" -eq 0 ]] || return 1
}

_op_sessions_save() {
    local tmp_file="" count=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tmp-file) tmp_file="${2:-}"; shift 2 ;;
            --count)    count="${2:-0}"; shift 2 ;;
            *)          shift ;;
        esac
    done
    [[ -z "$tmp_file" ]] && return 1
    local sessions_file="${OP_SESSIONS_FILE:-$HOME/.config/zsh/.op-sessions.env}"

    # Append current default account/vault
    [[ -n "${OP_ACCOUNT:-}" ]] && printf 'OP_ACCOUNT=%q\n' "$OP_ACCOUNT" >> "$tmp_file"
    [[ -n "${OP_VAULT:-}" ]] && printf 'OP_VAULT=%q\n' "$OP_VAULT" >> "$tmp_file"

    mkdir -p "$(dirname "$sessions_file")" 2>/dev/null || true
    mv "$tmp_file" "$sessions_file"
    chmod 600 "$sessions_file" 2>/dev/null || true
    _secrets_info "Session state saved to $sessions_file ($count accounts)"
}

op_sessions_source() {
    local sessions_file="${OP_SESSIONS_FILE:-$HOME/.config/zsh/.op-sessions.env}"
    if [[ ! -f "$sessions_file" ]]; then
        _secrets_warn "No sessions file: $sessions_file (run op_signin_all first)"
        return 1
    fi
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        local key="${line%%=*}"
        local val="${line#*=}"
        export "$key=$val"
    done < "$sessions_file"
    _secrets_info "Loaded OP sessions from $sessions_file"
}

op_set_default_alias() {
    local account_alias="${1:-}"
    local vault="${2:-}"
    if [[ -z "$account_alias" ]]; then
        echo "Usage: op_set_default_alias <account-alias> [vault]" >&2
        return 1
    fi
    local resolved
    resolved="$(_op_account_alias "$account_alias" 2>/dev/null || true)"
    if [[ -z "$resolved" ]]; then
        _secrets_warn "Account alias not found: $account_alias"
        _secrets_info "Edit: op_accounts_edit"
        return 1
    fi
    op_set_default "$resolved" "$vault"
}

