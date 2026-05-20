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

test_secrets_missing_from_1p_reports_missing() {
    local tmp bin map old_path old_map old_mode old_account old_vault out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
case "$1 $2" in
  "account list")
    exit 0
    ;;
  "read")
    exit 1
    ;;
  "item get")
    exit 1
    ;;
esac
exit 1
OP
    chmod +x "$bin/op"
    map="$tmp/secrets.1p"
    cat > "$map" <<'EOF'
GITLAB_TOKEN=op://Private/gitlab personal access token/password
EOF
    old_path="$PATH"
    old_map="$ZSH_SECRETS_MAP"
    old_mode="$ZSH_SECRETS_MODE"
    old_account="${OP_ACCOUNT-}"
    old_vault="${OP_VAULT-}"
    PATH="$bin:/usr/bin:/bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    op() { "$bin/op" "$@"; }
    export ZSH_SECRETS_MAP="$map"
    export OP_ACCOUNT="acct"
    export OP_VAULT="Private"
    out="$(secrets_missing_from_1p 2>&1 || true)"
    assert_contains "$out" "Missing: GITLAB_TOKEN" "should report missing op:// entry"
    PATH="$old_path"
    export ZSH_SECRETS_MAP="$old_map"
    export ZSH_SECRETS_MODE="$old_mode"
    export OP_ACCOUNT="$old_account"
    export OP_VAULT="$old_vault"
    unset -f op 2>/dev/null || true
    rm -rf "$tmp"
}

test_secrets_missing_from_1p_json_and_fix() {
    local tmp bin map old_path old_map old_account old_vault out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
case "$1 $2" in
  "account list")
    exit 0
    ;;
  "read")
    exit 1
    ;;
  "item get")
    exit 1
    ;;
esac
exit 1
OP
    chmod +x "$bin/op"
    map="$tmp/secrets.1p"
    cat > "$map" <<'EOF'
GITLAB_TOKEN=op://Private/gitlab personal access token/password
EOF
    old_path="$PATH"
    old_map="$ZSH_SECRETS_MAP"
    old_account="${OP_ACCOUNT-}"
    old_vault="${OP_VAULT-}"
    PATH="$bin:/usr/bin:/bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    op() { "$bin/op" "$@"; }
    export ZSH_SECRETS_MAP="$map"
    export OP_ACCOUNT="acct"
    export OP_VAULT="Private"
    out="$(secrets_missing_from_1p --json --fix 2>/dev/null || true)"
    assert_contains "$out" "\"env\":\"GITLAB_TOKEN\"" "json output should include env name"
    assert_contains "$(cat "$map")" "# MISSING:" "fix should comment missing entry"
    PATH="$old_path"
    export ZSH_SECRETS_MAP="$old_map"
    export OP_ACCOUNT="$old_account"
    export OP_VAULT="$old_vault"
    unset -f op 2>/dev/null || true
    rm -rf "$tmp"
}

test_secrets_find_account_for_item() {
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
case "$1 $2" in
  "account list")
    if [[ "$3" == "--format=json" ]]; then
      echo '[{"account_uuid":"A1"},{"account_uuid":"A2"}]'
      exit 0
    fi
    exit 0
    ;;
  "item list")
    echo 'id title vault'
    echo 'x1 gitlab-token Private'
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
OP
    chmod +x "$bin/op"
    local old_bin="${OP_BIN-}"
    local old_path="$PATH"
    PATH="$bin:$PATH"
    unset OP_BIN
    hash -r
    export OP_ACCOUNT_UUIDS="A2"
    out="$(secrets_find_account_for_item "gitlab-token" "Private" 2>/dev/null || true)"
    assert_contains "$out" "A2" "should return account containing item"
    PATH="$old_path"
    OP_BIN="$old_bin"
    unset OP_ACCOUNT_UUIDS
    rm -rf "$tmp"
}

test_secrets_sync_to_1p_requires_op() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    PATH="$bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    hash -r
    out="$(secrets_sync_to_1p 2>&1 || true)"
    assert_true "[[ -n \"$out\" ]]" "sync should produce an error message"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_secrets_sync_to_1p_with_account_vault() {
    local tmp bin file old_file old_path out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    file="$tmp/secrets.env"
    echo "FOO=bar" > "$file"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "account list" ]]; then
  exit 0
fi
if [[ "$1 $2" == "item create" ]]; then
  printf '%s\n' "$@" > "${OP_ARGS_FILE}"
  exit 0
fi
exit 1
OP
    chmod +x "$bin/op"
    old_file="$ZSH_SECRETS_FILE"
    old_path="$PATH"
    export ZSH_SECRETS_FILE="$file"
    PATH="$bin:/usr/bin:/bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    export OP_ARGS_FILE="$tmp/op.args"
    out="$(secrets_sync_to_1p "zsh-secrets-env" "acct-1" "VaultA" 2>&1)"
    assert_true "[[ -f \"$tmp/op.args\" ]]" "sync should call op item create"
    assert_contains "$(cat "$tmp/op.args")" "--account=acct-1" "should pass account arg"
    assert_contains "$(cat "$tmp/op.args")" "--vault=VaultA" "should pass vault arg"
    export ZSH_SECRETS_FILE="$old_file"
    PATH="$old_path"
    unset OP_ARGS_FILE
    rm -rf "$tmp"
}

test_secrets_bootstrap_requires_op() {
    local old_path old_bin out rc
    old_path="$PATH"
    old_bin="${OP_BIN:-}"
    PATH="/usr/bin:/bin"
    export OP_BIN="/nonexistent/op"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    out="$(secrets_bootstrap_from_1p 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "bootstrap should fail without op"
    assert_contains "$out" "op not found" "should warn without op"
    PATH="$old_path"
    if [[ -n "$old_bin" ]]; then export OP_BIN="$old_bin"; else unset OP_BIN; fi
}

register_test "test_secrets_missing_from_1p_reports_missing" "test_secrets_missing_from_1p_reports_missing"
register_test "test_secrets_missing_from_1p_json_and_fix" "test_secrets_missing_from_1p_json_and_fix"
register_test "test_secrets_find_account_for_item" "test_secrets_find_account_for_item"
register_test "test_secrets_sync_to_1p_requires_op" "test_secrets_sync_to_1p_requires_op"
register_test "test_secrets_sync_to_1p_with_account_vault" "test_secrets_sync_to_1p_with_account_vault"
register_test "test_secrets_bootstrap_requires_op" "test_secrets_bootstrap_requires_op"
