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

test_secrets_load_file() {
    local tmp file old_file old_mode
    tmp="$(mktemp -d)"
    file="$tmp/secrets.env"
    cat > "$file" <<'EOF'
FOO=bar
# comment
BAZ=qux
export ZSH_ENV_PROFILE=dev
EOF
    old_file="$ZSH_SECRETS_FILE"
    old_mode="$ZSH_SECRETS_MODE"
    export ZSH_SECRETS_FILE="$file"
    export ZSH_SECRETS_MODE="file"
    secrets_load_file
    assert_equal "bar" "$FOO" "should load FOO from file"
    assert_equal "qux" "$BAZ" "should load BAZ from file"
    assert_equal "dev" "$ZSH_ENV_PROFILE" "should support export syntax"
    export ZSH_SECRETS_FILE="$old_file"
    export ZSH_SECRETS_MODE="$old_mode"
    rm -rf "$tmp"
}

test_secrets_load_op() {
    local tmp bin map old_path old_map old_mode
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_op_secrets "$bin"
    map="$tmp/secrets.1p"
    cat > "$map" <<'EOF'
FEC_API_KEY svc user password
SERVICE_TOKEN svc - token
EOF
    old_path="$PATH"
    old_map="$ZSH_SECRETS_MAP"
    old_mode="$ZSH_SECRETS_MODE"
    PATH="$bin:/usr/bin:/bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    op() { "$bin/op" "$@"; }
    hash -r
    export ZSH_SECRETS_MAP="$map"
    export ZSH_SECRETS_MODE="op"
    export OP_ACCOUNT="test-account"
    export OP_VAULT="TestVault"
    unset FEC_API_KEY SERVICE_TOKEN
    secrets_load_op
    assert_equal "op-secret" "${FEC_API_KEY-}" "should load secret from op item get"
    assert_equal "op-token" "${SERVICE_TOKEN-}" "should load token from op item get without user"
    PATH="$old_path"
    export ZSH_SECRETS_MAP="$old_map"
    export ZSH_SECRETS_MODE="$old_mode"
    unset OP_ACCOUNT OP_VAULT
    unset -f op 2>/dev/null || true
    rm -rf "$tmp"
}

test_secrets_load_op_supports_op_url_mapping() {
    skip_if_missing "op"
    local tmp map old_map old_mode old_account old_vault orig_op_cmd
    tmp="$(mktemp -d)"
    map="$tmp/secrets.1p"
    cat > "$map" <<'EOF'
GITLAB_TOKEN=op://Private/gitlab-access-token/password
EOF
    old_map="$ZSH_SECRETS_MAP"
    old_mode="$ZSH_SECRETS_MODE"
    old_account="${OP_ACCOUNT-}"
    old_vault="${OP_VAULT-}"
    orig_op_cmd="$(typeset -f _op_cmd 2>/dev/null || true)"
    _op_cmd() { echo "token-value"; }
    export ZSH_SECRETS_MAP="$map"
    export ZSH_SECRETS_MODE="op"
    export OP_ACCOUNT="uuid1"
    export OP_VAULT="Private"
    GITLAB_TOKEN=""
    secrets_load_op
    assert_equal "token-value" "${GITLAB_TOKEN-}" "op:// mapping should set env var"
    if [[ -n "$orig_op_cmd" ]]; then
        eval "$orig_op_cmd"
    else
        unset -f _op_cmd 2>/dev/null || true
    fi
    export ZSH_SECRETS_MAP="$old_map"
    export ZSH_SECRETS_MODE="$old_mode"
    export OP_ACCOUNT="$old_account"
    export OP_VAULT="$old_vault"
    rm -rf "$tmp"
}

test_secrets_push_uses_1password_when_available() {
    local tmp bin old_path old_bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "account list" ]]; then
  exit 0
fi
exit 1
OP
    chmod +x "$bin/op"
    old_bin="${OP_BIN-}"
    old_path="$PATH"
    OP_BIN="$bin/op"
    PATH="$bin:/usr/bin:/bin"
    secrets_sync_all_to_1p() { echo "SYNCED"; }
    out="$(secrets_push 2>&1)"
    assert_contains "$out" "1Password: synced" "secrets_push should attempt 1Password sync"
    unset -f secrets_sync_all_to_1p 2>/dev/null || true
    OP_BIN="$old_bin"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_secrets_pull_prefers_rsync_when_host_provided() {
    local out
    secrets_rsync_from_host() { echo "RSYNCED"; return 0; }
    out="$(secrets_pull host 2>&1)"
    assert_contains "$out" "rsync" "secrets_pull should prefer rsync when host provided"
    unset -f secrets_rsync_from_host 2>/dev/null || true
}

test_secrets_pull_prefers_item_with_content() {
    local tmp bin map old_path old_map old_mode old_account old_vault
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
    echo '[{"id":"old","title":"zsh-secrets-env","updatedAt":"2020-01-01"},{"id":"new","title":"zsh-secrets-env","updatedAt":"2025-01-01"}]'
    exit 0
    ;;
  "item get")
    item="$3"
    if [[ "$*" == *"--field=secrets_file"* || "$*" == *"--field secrets_file"* ]]; then
      if [[ "$item" == "new" ]]; then
        echo "FOO=bar"
      fi
      exit 0
    fi
    if [[ "$item" == "old" ]]; then
      echo '{"id":"old","fields":[],"notesPlain":""}'
      exit 0
    fi
    if [[ "$item" == "new" ]]; then
      echo '{"id":"new","fields":[{"id":"secrets_file","value":"FOO=bar"}]}'
      exit 0
    fi
    ;;
esac
exit 1
OP
    chmod +x "$bin/op"
    map="$tmp/secrets.1p"
    old_path="$PATH"
    old_map="$ZSH_SECRETS_MAP"
    old_mode="$ZSH_SECRETS_MODE"
    old_account="${OP_ACCOUNT-}"
    old_vault="${OP_VAULT-}"
    PATH="$bin:/usr/bin:/bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    op() { "$bin/op" "$@"; }
    hash -r
    export ZSH_SECRETS_MAP="$map"
    export ZSH_SECRETS_MODE="op"
    export OP_ACCOUNT="acct"
    export OP_VAULT="Private"
    export ZSH_SECRETS_FILE="$tmp/secrets.env"
    secrets_pull_from_1p "zsh-secrets-env" "$OP_ACCOUNT" "$OP_VAULT"
    assert_contains "$(cat "$ZSH_SECRETS_FILE")" "FOO=bar" "should pull from newest item with content"
    PATH="$old_path"
    export ZSH_SECRETS_MAP="$old_map"
    export ZSH_SECRETS_MODE="$old_mode"
    export OP_ACCOUNT="$old_account"
    export OP_VAULT="$old_vault"
    rm -rf "$tmp"
}

test_secrets_pull_defaults_to_source_account() {
    local tmp bin old_bin old_path old_source
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
    for arg in "$@"; do
      if [[ "$arg" == "--account=SRC" ]]; then
        echo '[{"id":"ok","title":"zsh-secrets-env","updatedAt":"2025-01-01"}]'
        exit 0
      fi
    done
    echo '[]'
    exit 0
    ;;
  "item get")
    if [[ "$3" == "ok" ]]; then
      if [[ "$*" == *"--field=secrets_file"* || "$*" == *"--field secrets_file"* ]]; then
        echo "FOO=bar"
        exit 0
      fi
      echo '{"id":"ok","fields":[{"id":"secrets_file","value":"FOO=bar"}]}'
      exit 0
    fi
    ;;
esac
exit 1
OP
    chmod +x "$bin/op"
    old_bin="${OP_BIN-}"
    old_path="$PATH"
    old_source="${ZSH_OP_SOURCE_ACCOUNT-}"
    OP_BIN="$bin/op"
    PATH="$bin:/usr/bin:/bin"
    export ZSH_OP_SOURCE_ACCOUNT="SRC"
    export ZSH_OP_SOURCE_VAULT="Private"
    export ZSH_SECRETS_FILE="$tmp/secrets.env"
    secrets_pull_from_1p "zsh-secrets-env" "" "Private"
    assert_contains "$(cat "$ZSH_SECRETS_FILE")" "FOO=bar" "should default to source account when OP_ACCOUNT empty"
    OP_BIN="$old_bin"
    PATH="$old_path"
    export ZSH_OP_SOURCE_ACCOUNT="$old_source"
    rm -rf "$tmp"
}

test_secrets_edit_creates_file() {
    local tmp file old_file
    tmp="$(mktemp -d)"
    file="$tmp/secrets.env"
    old_file="$ZSH_SECRETS_FILE"
    export ZSH_SECRETS_FILE="$file"
    export EDITOR="/usr/bin/true"
    secrets_edit
    assert_true "[[ -f \"$file\" ]]" "secrets_edit should create secrets file"
    export ZSH_SECRETS_FILE="$old_file"
    rm -rf "$tmp"
}

test_secrets_init_from_example() {
    local tmp file example old_file old_example
    tmp="$(mktemp -d)"
    file="$tmp/secrets.env"
    example="$tmp/secrets.env.example"
    cat > "$example" <<'EOF'
FOO=bar
EOF
    old_file="$ZSH_SECRETS_FILE"
    old_example="$HOME/.config/zsh/secrets.env.example"
    export ZSH_SECRETS_FILE="$file"
    export ZSH_SECRETS_FILE_EXAMPLE="$example"
    secrets_init
    assert_true "[[ -f \"$file\" ]]" "secrets_init should create file"
    assert_contains "$(cat "$file")" "FOO=bar" "secrets_init should copy example"
    export ZSH_SECRETS_FILE="$old_file"
    export ZSH_SECRETS_FILE_EXAMPLE="$old_example"
    rm -rf "$tmp"
}

test_secrets_init_map_from_example() {
    local tmp map old_map
    tmp="$(mktemp -d)"
    map="$tmp/secrets.1p"
    cat > "$tmp/secrets.1p.example" <<'EOF'
FOO bar - baz
EOF
    old_map="$ZSH_SECRETS_MAP"
    export ZSH_SECRETS_MAP="$map"
    secrets_init_map
    assert_true "[[ -f \"$map\" ]]" "should create secrets.1p"
    assert_contains "$(cat "$map")" "FOO bar - baz" "should copy example"
    export ZSH_SECRETS_MAP="$old_map"
    rm -rf "$tmp"
}

test_secrets_map_sanitize_fixes_trailing_quote() {
    local tmp map old_map
    tmp="$(mktemp -d)"
    map="$tmp/secrets.1p"
    cat > "$map" <<'EOF'
GITLAB_TOKEN=op://Private/gitlab-access-token/password"   
EOF
    old_map="$ZSH_SECRETS_MAP"
    export ZSH_SECRETS_MAP="$map"
    secrets_map_sanitize --fix
    assert_contains "$(cat "$map")" "GITLAB_TOKEN=op://Private/gitlab-access-token/password" "should strip trailing quote"
    assert_equal "fixed" "${SECRETS_MAP_STATUS-}" "should set map status to fixed"
    export ZSH_SECRETS_MAP="$old_map"
    rm -rf "$tmp"
}

test_secrets_require_source_blocks_mismatch() {
    # Save prior state — track whether each var was set vs unset so we
    # can fully restore (exporting "" is not the same as unset and was
    # leaking ZSH_OP_SOURCE_VAULT="" into later tests after the
    # test-secrets split).
    local had_account had_vault old_source_account old_source_vault
    [[ -v ZSH_OP_SOURCE_ACCOUNT ]] && had_account=1 || had_account=0
    [[ -v ZSH_OP_SOURCE_VAULT ]] && had_vault=1 || had_vault=0
    old_source_account="${ZSH_OP_SOURCE_ACCOUNT-}"
    old_source_vault="${ZSH_OP_SOURCE_VAULT-}"
    export ZSH_OP_SOURCE_ACCOUNT="acct-source"
    export ZSH_OP_SOURCE_VAULT="Private"
    assert_false "_secrets_require_source acct-other Private" "should block non-source account"
    assert_false "_secrets_require_source acct-source Other" "should block non-source vault"
    assert_true "_secrets_require_source acct-source Private" "should allow source"
    if (( had_account )); then
        export ZSH_OP_SOURCE_ACCOUNT="$old_source_account"
    else
        unset ZSH_OP_SOURCE_ACCOUNT
    fi
    if (( had_vault )); then
        export ZSH_OP_SOURCE_VAULT="$old_source_vault"
    else
        unset ZSH_OP_SOURCE_VAULT
    fi
}

test_secrets_pull_requires_op() {
    skip_if_missing "op"
    (( TEST_SKIP )) && return 0
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
    echo '[{"id":"item-1","title":"zsh-secrets"}]'
    exit 0
    ;;
  "item get")
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
OP
    chmod +x "$bin/op"
    out="$(BIN="$bin" zsh -lc 'export ZSH_TEST_MODE=1; export OP_ACCOUNT=acct-1; export OP_VAULT=; source $HOME/.config/zsh/modules/secrets.zsh; PATH="$BIN:/usr/bin:/bin"; unalias op 2>/dev/null || true; unfunction op 2>/dev/null || true; op(){ "$BIN/op" "$@"; }; secrets_pull_from_1p' 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "secrets_pull_from_1p should fail on empty field"
    assert_contains "$out" "No secrets_file/notes found" "secrets_pull_from_1p should warn on empty field"
    rm -rf "$tmp"
}

register_test "test_secrets_load_file" "test_secrets_load_file"
register_test "test_secrets_load_op" "test_secrets_load_op"
register_test "test_secrets_load_op_supports_op_url_mapping" "test_secrets_load_op_supports_op_url_mapping"
register_test "test_secrets_push_uses_1password_when_available" "test_secrets_push_uses_1password_when_available"
register_test "test_secrets_pull_prefers_rsync_when_host_provided" "test_secrets_pull_prefers_rsync_when_host_provided"
register_test "test_secrets_pull_prefers_item_with_content" "test_secrets_pull_prefers_item_with_content"
register_test "test_secrets_pull_defaults_to_source_account" "test_secrets_pull_defaults_to_source_account"
register_test "test_secrets_edit_creates_file" "test_secrets_edit_creates_file"
register_test "test_secrets_init_from_example" "test_secrets_init_from_example"
register_test "test_secrets_init_map_from_example" "test_secrets_init_map_from_example"
register_test "test_secrets_map_sanitize_fixes_trailing_quote" "test_secrets_map_sanitize_fixes_trailing_quote"
register_test "test_secrets_require_source_blocks_mismatch" "test_secrets_require_source_blocks_mismatch"
register_test "test_secrets_pull_requires_op" "test_secrets_pull_requires_op"
