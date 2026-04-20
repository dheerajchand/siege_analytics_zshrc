#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/secrets.zsh"

_make_stub_op_accounts_json() {
    local bin_dir="$1"
    local json="$2"
    cat > "$bin_dir/op" <<OP
#!/usr/bin/env zsh
if [[ "\$1 \$2" == "account list" ]]; then
  if [[ "\$3" == "--format=json" ]]; then
    cat <<'JSON'
$json
JSON
    exit 0
  fi
  exit 0
fi
exit 1
OP
    chmod +x "$bin_dir/op"
}

_make_stub_op_secrets() {
    local bin_dir="$1"
    cat > "$bin_dir/op" <<'OP'
#!/usr/bin/env zsh
field=""
item=""
args=("$@")
for ((i=1; i<=${#args[@]}; i++)); do
  case "${args[$i]}" in
    --field=*)
      field="${args[$i]#--field=}"
      ;;
    --field)
      field="${args[$((i+1))]}"
      ;;
  esac
done
item="$3"
case "$1 $2" in
  "account list")
    exit 0
    ;;
  "item get")
    if [[ "$item" == "svc-user" && "$field" == "password" ]]; then
      echo "op-secret"
      exit 0
    fi
    if [[ "$item" == "svc" && "$field" == "token" ]]; then
      echo "op-token"
      exit 0
    fi
    exit 1
    ;;
  *)
    exit 1
    ;;
esac
OP
    chmod +x "$bin_dir/op"
}

test_op_group_item_ids_by_title_orders() {
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "item list" && "$3" == "--format=json" ]]; then
  echo '[{"id":"a","title":"t","updatedAt":"2024-01-01"},{"id":"b","title":"t","updatedAt":"2025-01-01"}]'
  exit 0
fi
if [[ "$1 $2" == "account list" ]]; then
  exit 0
fi
exit 1
OP
    chmod +x "$bin/op"
    local old_path="$PATH"
    PATH="$bin:/usr/bin:/bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    out="$(_op_group_item_ids_by_title "t")"
    assert_equal $'a\nb' "$out" "should return ids in ascending updatedAt order"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_op_resolve_account_uuid_from_alias() {
    local tmp file old_file out
    tmp="$(mktemp -d)"
    file="$tmp/op-accounts.env"
    cat > "$file" <<'EOF'
Dheeraj_Chand_Family=UUIDX
EOF
    old_file="$OP_ACCOUNTS_FILE"
    export OP_ACCOUNTS_FILE="$file"
    out="$(_op_resolve_account_uuid "Dheeraj_Chand_Family")"
    assert_equal "UUIDX" "$out" "should resolve alias to uuid"
    export OP_ACCOUNTS_FILE="$old_file"
    rm -rf "$tmp"
}

test_op_account_alias_trims_quote() {
    local tmp file old_file out
    tmp="$(mktemp -d)"
    file="$tmp/op-accounts.env"
    cat > "$file" <<'EOF'
Dheeraj_Chand_Family=UUIDQ"
EOF
    old_file="$OP_ACCOUNTS_FILE"
    export OP_ACCOUNTS_FILE="$file"
    out="$(_op_account_alias "Dheeraj_Chand_Family")"
    assert_equal "UUIDQ" "$out" "alias lookup should trim trailing quote"
    export OP_ACCOUNTS_FILE="$old_file"
    rm -rf "$tmp"
}

test_op_latest_item_id_uses_op_bin() {
    local tmp bin old_bin old_path out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "item list" ]]; then
  echo '[{"id":"idx","title":"t","updatedAt":"2025-01-01"}]'
  exit 0
fi
exit 1
OP
    chmod +x "$bin/op"
    old_bin="${OP_BIN-}"
    old_path="$PATH"
    OP_BIN="$bin/op"
    PATH="$bin:/usr/bin:/bin"
    op() { echo "wrapper-called" >&2; return 1; }
    out="$(_op_latest_item_id_by_title "t")"
    assert_equal "idx" "$out" "should use OP_BIN command not wrapper"
    unset -f op 2>/dev/null || true
    OP_BIN="$old_bin"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_op_latest_item_id_resolves_alias_to_uuid() {
    local tmp bin file old_file old_bin old_path out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    file="$tmp/op-accounts.env"
    cat > "$file" <<'EOF'
AliasA=UUIDA
EOF
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "item list" ]]; then
  for arg in "$@"; do
    if [[ "$arg" == "--account=UUIDA" ]]; then
      echo '[{"id":"ok","title":"t","updatedAt":"2025-01-01"}]'
      exit 0
    fi
  done
  echo '[]'
  exit 0
fi
exit 1
OP
    chmod +x "$bin/op"
    old_file="$OP_ACCOUNTS_FILE"
    old_bin="${OP_BIN-}"
    old_path="$PATH"
    export OP_ACCOUNTS_FILE="$file"
    OP_BIN="$bin/op"
    PATH="$bin:/usr/bin:/bin"
    out="$(_op_latest_item_id_by_title "t" "AliasA")"
    assert_equal "ok" "$out" "should resolve alias to uuid for item list"
    export OP_ACCOUNTS_FILE="$old_file"
    OP_BIN="$old_bin"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_op_latest_item_id_fallbacks_without_vault() {
    local tmp bin old_bin old_path out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "item list" ]]; then
  for arg in "$@"; do
    if [[ "$arg" == "--vault=Private" ]]; then
      echo '[]'
      exit 0
    fi
  done
  echo '[{"id":"ok","title":"t","updatedAt":"2025-01-01"}]'
  exit 0
fi
exit 1
OP
    chmod +x "$bin/op"
    old_bin="${OP_BIN-}"
    old_path="$PATH"
    OP_BIN="$bin/op"
    PATH="$bin:/usr/bin:/bin"
    out="$(_op_latest_item_id_by_title "t" "UUID" "Private")"
    assert_equal "ok" "$out" "should retry without vault when vault filter returns empty"
    OP_BIN="$old_bin"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_op_accounts_sanitize_fixes_trailing_quote() {
    local tmp file old_file
    tmp="$(mktemp -d)"
    file="$tmp/op-accounts.env"
    cat > "$file" <<'EOF'
Dheeraj_Chand_Family=I3C75JBKZJGSLMVQDGRKCVNHIM"   
EOF
    old_file="$OP_ACCOUNTS_FILE"
    export OP_ACCOUNTS_FILE="$file"
    op_accounts_sanitize --fix
    assert_contains "$(cat "$file")" "Dheeraj_Chand_Family=I3C75JBKZJGSLMVQDGRKCVNHIM" "should strip trailing quote"
    export OP_ACCOUNTS_FILE="$old_file"
    rm -rf "$tmp"
}

test_op_list_accounts_vaults_requires_op() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    PATH="$bin"
    out="$(op_list_accounts_vaults 2>&1 || true)"
    assert_contains "$out" "op not found" "list should require op"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_op_account_alias_lookup() {
    local tmp file old_file
    tmp="$(mktemp -d)"
    file="$tmp/op-accounts.env"
    cat > "$file" <<'EOF'
ElectInfo=ABC123
EOF
    old_file="$OP_ACCOUNTS_FILE"
    export OP_ACCOUNTS_FILE="$file"
    assert_equal "ABC123" "$(_op_account_alias ElectInfo)" "alias should resolve to uuid"
    assert_equal "ElectInfo" "$(_op_account_alias_for_uuid ABC123)" "uuid should resolve to alias"
    export OP_ACCOUNTS_FILE="$old_file"
    rm -rf "$tmp"
}

test_op_account_uuid_configured() {
    local json
    json='[{"account_uuid":"UUID1"},{"account_uuid":"UUID2"}]'
    local rc
    _op_account_uuid_configured UUID1 "$json"
    rc=$?
    assert_equal "0" "$rc" "should detect configured uuid"
    _op_account_uuid_configured UUID3 "$json"
    rc=$?
    assert_not_equal "0" "$rc" "should reject missing uuid"
}

test_op_set_default_clears_vault() {
    local old_account="${OP_ACCOUNT-}"
    local old_vault="${OP_VAULT-}"
    export OP_ACCOUNT="old-account"
    export OP_VAULT="OldVault"
    op_set_default "acct-alias"
    assert_equal "" "${OP_VAULT-}" "should clear vault when not provided"
    export OP_ACCOUNT="$old_account"
    export OP_VAULT="$old_vault"
}

test_op_set_default_prefers_shorthand() {
    local tmp bin file old_path old_file old_account old_vault
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    file="$tmp/op-accounts.env"
    cat > "$file" <<'EOF'
Dheeraj_Chand_Family=UUID1
EOF
    _make_stub_op_accounts_json "$bin" '[{"account_uuid":"UUID1","shorthand":"Dheeraj_Chand_Family"}]'
    old_path="$PATH"
    old_file="$OP_ACCOUNTS_FILE"
    old_account="${OP_ACCOUNT-}"
    old_vault="${OP_VAULT-}"
    PATH="$bin:/usr/bin:/bin"
    export OP_ACCOUNTS_FILE="$file"
    op_set_default Dheeraj_Chand_Family Private
    assert_equal "Dheeraj_Chand_Family" "$OP_ACCOUNT" "should prefer shorthand when configured"
    PATH="$old_path"
    export OP_ACCOUNTS_FILE="$old_file"
    if [[ -n "${old_account-}" ]]; then export OP_ACCOUNT="$old_account"; else unset OP_ACCOUNT; fi
    if [[ -n "${old_vault-}" ]]; then export OP_VAULT="$old_vault"; else unset OP_VAULT; fi
    rm -rf "$tmp"
}

test_op_set_default_uses_uuid_when_no_shorthand() {
    local tmp bin file old_path old_file old_account old_vault
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    file="$tmp/op-accounts.env"
    cat > "$file" <<'EOF'
Dheeraj_Chand_Family=UUID1
EOF
    _make_stub_op_accounts_json "$bin" '[{"account_uuid":"UUID1","shorthand":""}]'
    old_path="$PATH"
    old_file="$OP_ACCOUNTS_FILE"
    old_account="${OP_ACCOUNT-}"
    old_vault="${OP_VAULT-}"
    PATH="$bin:/usr/bin:/bin"
    export OP_ACCOUNTS_FILE="$file"
    op_set_default Dheeraj_Chand_Family Private
    assert_equal "UUID1" "$OP_ACCOUNT" "should use uuid when shorthand missing"
    PATH="$old_path"
    export OP_ACCOUNTS_FILE="$old_file"
    if [[ -n "${old_account-}" ]]; then export OP_ACCOUNT="$old_account"; else unset OP_ACCOUNT; fi
    if [[ -n "${old_vault-}" ]]; then export OP_VAULT="$old_vault"; else unset OP_VAULT; fi
    rm -rf "$tmp"
}

test_op_alias_shim_resolves_account() {
    local tmp bin file old_path old_file out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    file="$tmp/op-accounts.env"
    cat > "$file" <<'EOF'
Dheeraj_Chand_Family=UUID1
EOF
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "account list" ]]; then
  if [[ "$3" == "--format=json" ]]; then
    echo '[{"account_uuid":"UUID1","shorthand":""}]'
    exit 0
  fi
  exit 0
fi
if [[ "$1" == "item" && "$2" == "create" ]]; then
  echo "$@"
  exit 0
fi
exit 0
OP
    chmod +x "$bin/op"
    old_path="$PATH"
    old_file="$OP_ACCOUNTS_FILE"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    export OP_ACCOUNTS_FILE="$file"
    out="$(zsh -fc "source $ROOT_DIR/modules/secrets.zsh; op item create --account Dheeraj_Chand_Family test")"
    assert_contains "$out" "--account UUID1" "alias shim should replace account with uuid"
    PATH="$old_path"
    export OP_ACCOUNTS_FILE="$old_file"
    rm -rf "$tmp"
}

test_op_list_accounts_vaults_empty() {
    local tmp bin old_path out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "account list" ]]; then
  echo '[{"account_uuid":"UUID1","email":"u@example.com","url":"example.com"}]'
  exit 0
fi
if [[ "$1 $2" == "vault list" ]]; then
  echo '[]'
  exit 0
fi
exit 0
OP
    cat > "$bin/jq" <<'JQ'
#!/usr/bin/env zsh
if [[ "$1" == "-r" && "$2" == ".[] | \"\\(.account_uuid)\\t\\(.email)\\t\\(.url)\"" ]]; then
  echo -e "UUID1\tu@example.com\texample.com"
  exit 0
fi
if [[ "$1" == "-r" && "$2" == ".[]?.name" ]]; then
  exit 0
fi
exit 0
JQ
    chmod +x "$bin/op" "$bin/jq"
    old_path="$PATH"
    PATH="$bin:/usr/bin:/bin"
    out="$(op_list_accounts_vaults)"
    assert_contains "$out" "(none found or access denied)" "empty vault list should show placeholder"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_op_list_items_requires_op() {
    skip_if_missing "op"
    local tmp bin out rc
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
case "$1 $2" in
  "account list")
    exit 0
    ;;
  "item list")
    echo '[]'
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
OP
    chmod +x "$bin/op"
    out="$(BIN="$bin" zsh -lc 'export ZSH_TEST_MODE=1; export OP_ACCOUNT=acct-1; export OP_VAULT=; source $HOME/.config/zsh/modules/secrets.zsh; PATH="$BIN:/usr/bin:/bin"; unalias op 2>/dev/null || true; unfunction op 2>/dev/null || true; op(){ "$BIN/op" "$@"; }; op_list_items' 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "op_list_items should fail on empty list"
    assert_contains "$out" "No items found" "op_list_items should warn on empty list"
    rm -rf "$tmp"
}

register_test "test_op_group_item_ids_by_title_orders" "test_op_group_item_ids_by_title_orders"
register_test "test_op_resolve_account_uuid_from_alias" "test_op_resolve_account_uuid_from_alias"
register_test "test_op_account_alias_trims_quote" "test_op_account_alias_trims_quote"
register_test "test_op_latest_item_id_uses_op_bin" "test_op_latest_item_id_uses_op_bin"
register_test "test_op_latest_item_id_resolves_alias_to_uuid" "test_op_latest_item_id_resolves_alias_to_uuid"
register_test "test_op_latest_item_id_fallbacks_without_vault" "test_op_latest_item_id_fallbacks_without_vault"
register_test "test_op_accounts_sanitize_fixes_trailing_quote" "test_op_accounts_sanitize_fixes_trailing_quote"
register_test "test_op_list_accounts_vaults_requires_op" "test_op_list_accounts_vaults_requires_op"
register_test "test_op_account_alias_lookup" "test_op_account_alias_lookup"
register_test "test_op_account_uuid_configured" "test_op_account_uuid_configured"
register_test "test_op_set_default_clears_vault" "test_op_set_default_clears_vault"
register_test "test_op_set_default_prefers_shorthand" "test_op_set_default_prefers_shorthand"
register_test "test_op_set_default_uses_uuid_when_no_shorthand" "test_op_set_default_uses_uuid_when_no_shorthand"
register_test "test_op_alias_shim_resolves_account" "test_op_alias_shim_resolves_account"
register_test "test_op_list_accounts_vaults_empty" "test_op_list_accounts_vaults_empty"
register_test "test_op_list_items_requires_op" "test_op_list_items_requires_op"
