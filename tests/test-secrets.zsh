#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/secrets.zsh"

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

test_secrets_normalize_mode_strips_quote() {
    local old_mode="${ZSH_SECRETS_MODE-}"
    export ZSH_SECRETS_MODE='both"'
    _secrets_normalize_mode
    assert_equal "both" "$ZSH_SECRETS_MODE" "should strip trailing quote"
    export ZSH_SECRETS_MODE="$old_mode"
}

test_secrets_trim_value_strips_space_quote() {
    local out
    out="$(_secrets_trim_value 'both"   ')"
    assert_equal "both" "$out" "should trim whitespace and trailing quote"
}

test_secrets_normalize_value_trims_and_strips_quotes() {
    local out
    out="$(_secrets_normalize_value '  "abc"  ')"
    assert_equal "abc" "$out" "normalize should trim and strip surrounding quotes"
}

test_secrets_extract_item_value_notes_plain() {
    local json='{"notesPlain":"hello","fields":[]}'
    local value="$(_secrets_extract_item_value_from_json "$json")"
    assert_equal "hello" "$value" "should read notesPlain when secrets_file field missing"
}

test_secrets_extract_item_value_field() {
    local json='{"fields":[{"id":"secrets_file","value":"from_field"}]}'
    local value="$(_secrets_extract_item_value_from_json "$json")"
    assert_equal "from_field" "$value" "should read secrets_file field value"
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

test_machine_profile_default() {
    local profile
    local old_profile="${ZSH_ENV_PROFILE-}"
    unset ZSH_ENV_PROFILE
    profile="$(machine_profile)"
    assert_true "[[ -n \"$profile\" ]]" "machine_profile should return a value"
    if [[ -n "$old_profile" ]]; then
        export ZSH_ENV_PROFILE="$old_profile"
    fi
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

test_op_accounts_set_alias_updates_file() {
    local tmp file old_file
    tmp="$(mktemp -d)"
    file="$tmp/op-accounts.env"
    echo "ElectInfo=OLDUUID" > "$file"
    old_file="$OP_ACCOUNTS_FILE"
    export OP_ACCOUNTS_FILE="$file"
    op_accounts_set_alias ElectInfo NEWUUID
    assert_contains "$(cat "$file")" "ElectInfo=NEWUUID" "should update existing alias"
    op_accounts_set_alias NewAlias UUID2
    assert_contains "$(cat "$file")" "NewAlias=UUID2" "should append new alias"
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

test_secrets_rsync_requires_rsync() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    PATH="$bin"
    out="$(secrets_rsync_to_host user@host 2>&1 || true)"
    assert_contains "$out" "rsync not found" "rsync should be required"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_secrets_rsync_named_args_usage() {
    local out
    out="$(secrets_rsync_to_host --user testuser 2>&1 || true)"
    assert_contains "$out" "Usage: secrets_rsync_to_host" "should require host when using named args"
}

test_secrets_rsync_cyberpower_defaults() {
    local out old_path tmp bin
    old_path="$PATH"
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    PATH="$bin"
    out="$(secrets_rsync_to_cyberpower 2>&1 || true)"
    PATH="$old_path"
    rm -rf "$tmp"
    assert_contains "$out" "rsync not found" "cyberpower wrapper should use rsync"
}

test_secrets_rsync_verify_requires_ssh() {
    local out old_path tmp bin
    old_path="$PATH"
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    PATH="$bin"
    out="$(secrets_rsync_verify user@host 2>&1 || true)"
    PATH="$old_path"
    rm -rf "$tmp"
    assert_contains "$out" "ssh not found" "verify should require ssh"
}

test_op_verify_accounts_requires_op() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    PATH="$bin"
    out="$(op_verify_accounts 2>&1 || true)"
    assert_contains "$out" "op not found" "verify should require op"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_op_login_headless_requires_op() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    PATH="$bin"
    out="$(op_login_headless 2>&1 || true)"
    assert_contains "$out" "op not found" "headless login should require op"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_secrets_safe_title() {
    assert_equal "hello" "$(_secrets_safe_title "hello")" "should keep normal title"
    assert_equal "(redacted)" "$(_secrets_safe_title "API_KEY=secret")" "should redact suspicious title"
    assert_equal "(redacted)" "$(_secrets_safe_title "$(printf 'x%.0s' {1..81})")" "should redact long title"
    assert_equal "(unnamed)" "$(_secrets_safe_title "")" "should handle empty title"
}

test_secrets_truncate() {
    assert_equal "short" "$(_secrets_truncate "short" 10)" "should keep short text"
    assert_equal "abcd..." "$(_secrets_truncate "abcdefghijk" 7)" "should truncate long text"
    assert_equal "ab" "$(_secrets_truncate "abcdef" 2)" "should handle tiny max"
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

test_secrets_require_source_blocks_mismatch() {
    local old_source_account old_source_vault
    old_source_account="${ZSH_OP_SOURCE_ACCOUNT-}"
    old_source_vault="${ZSH_OP_SOURCE_VAULT-}"
    export ZSH_OP_SOURCE_ACCOUNT="acct-source"
    export ZSH_OP_SOURCE_VAULT="Private"
    assert_false "_secrets_require_source acct-other Private" "should block non-source account"
    assert_false "_secrets_require_source acct-source Other" "should block non-source vault"
    assert_true "_secrets_require_source acct-source Private" "should allow source"
    export ZSH_OP_SOURCE_ACCOUNT="$old_source_account"
    export ZSH_OP_SOURCE_VAULT="$old_source_vault"
}

test_op_set_default_prefers_shorthand() {
    local tmp bin file old_path old_file
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
    PATH="$bin:/usr/bin:/bin"
    export OP_ACCOUNTS_FILE="$file"
    op_set_default Dheeraj_Chand_Family Private
    assert_equal "Dheeraj_Chand_Family" "$OP_ACCOUNT" "should prefer shorthand when configured"
    PATH="$old_path"
    export OP_ACCOUNTS_FILE="$old_file"
    rm -rf "$tmp"
}

test_op_set_default_uses_uuid_when_no_shorthand() {
    local tmp bin file old_path old_file
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
    PATH="$bin:/usr/bin:/bin"
    export OP_ACCOUNTS_FILE="$file"
    op_set_default Dheeraj_Chand_Family Private
    assert_equal "UUID1" "$OP_ACCOUNT" "should use uuid when shorthand missing"
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
    out="$(BIN="$bin" zsh -lc 'export ZSH_TEST_MODE=1; export OP_ACCOUNT=acct-1; export OP_VAULT=; source /Users/dheerajchand/.config/zsh/modules/secrets.zsh; PATH="$BIN:/usr/bin:/bin"; unalias op 2>/dev/null || true; unfunction op 2>/dev/null || true; op(){ "$BIN/op" "$@"; }; op_list_items' 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "op_list_items should fail on empty list"
    assert_contains "$out" "No items found" "op_list_items should warn on empty list"
    rm -rf "$tmp"
}

test_secrets_pull_requires_op() {
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
    out="$(BIN="$bin" zsh -lc 'export ZSH_TEST_MODE=1; export OP_ACCOUNT=acct-1; export OP_VAULT=; source /Users/dheerajchand/.config/zsh/modules/secrets.zsh; PATH="$BIN:/usr/bin:/bin"; unalias op 2>/dev/null || true; unfunction op 2>/dev/null || true; op(){ "$BIN/op" "$@"; }; secrets_pull_from_1p' 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "secrets_pull_from_1p should fail on empty field"
    assert_contains "$out" "No secrets_file field" "secrets_pull_from_1p should warn on empty field"
    rm -rf "$tmp"
}

test_secrets_pull_fallback_notes_plain() {
    local tmp bin out rc old_file
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
    if [[ "${OP_CLI_NO_COLOR:-}" == "1" ]]; then
      echo '[{"id":"old","title":"zsh-secrets"},{"id":"new","title":"zsh-secrets","updatedAt":"2026-01-01T00:00:00Z"}]'
      exit 0
    fi
    ;;
  "item get")
    if [[ "$3" == "new" ]]; then
      echo '{"notesPlain":"HELLO=world"}'
      exit 0
    fi
    echo '{"notesPlain":"HELLO=world"}'
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
OP
    chmod +x "$bin/op"
    old_file="$ZSH_SECRETS_FILE"
    export ZSH_SECRETS_FILE="$tmp/secrets.env"
    out="$(BIN="$bin" zsh -lc 'export ZSH_TEST_MODE=1; source /Users/dheerajchand/.config/zsh/modules/secrets.zsh; PATH="$BIN:/usr/bin:/bin"; unalias op 2>/dev/null || true; unfunction op 2>/dev/null || true; op(){ "$BIN/op" "$@"; }; secrets_pull_from_1p' 2>&1)"
    rc=$?
    assert_equal "0" "$rc" "should pull from notesPlain"
    assert_contains "$(cat "$tmp/secrets.env")" "HELLO=world" "should write notesPlain content"
    export ZSH_SECRETS_FILE="$old_file"
    rm -rf "$tmp"
}

test_secrets_profile_switch_usage() {
    local out
    out="$(secrets_profile_switch 2>&1 || true)"
    assert_contains "$out" "Usage: secrets_profile_switch" "should show usage on missing args"
}

test_secrets_profile_switch_invalid_profile() {
    local out
    out="$(secrets_profile_switch nonsense 2>&1 || true)"
    assert_contains "$out" "Invalid profile: nonsense" "should reject invalid profile"
    assert_contains "$out" "expected one of:" "should show expected profiles"
    assert_contains "$out" "Available profiles:" "should list available profiles"
}

test_secrets_profile_list_from_config() {
    local old_list
    old_list="${ZSH_PROFILE_LIST-}"
    unset ZSH_PROFILE_LIST
    typeset -A ZSH_PROFILE_CONFIGS
    typeset -A ZSH_PROFILE_COLORS
    typeset -a ZSH_PROFILE_ORDER
    ZSH_PROFILE_CONFIGS=(dev "Dev config" prod "Prod config")
    ZSH_PROFILE_COLORS=(dev "32;1 32" prod "31;1 31")
    ZSH_PROFILE_ORDER=(dev prod)
    local out
    out="$(_secrets_profile_list)"
    assert_contains "$out" "dev" "should include dev from config"
    assert_contains "$out" "prod" "should include prod from config"
    unset ZSH_PROFILE_CONFIGS ZSH_PROFILE_COLORS ZSH_PROFILE_ORDER
    if [[ -n "${old_list-}" ]]; then
        export ZSH_PROFILE_LIST="$old_list"
    fi
}

test_secrets_profiles_output() {
    typeset -A ZSH_PROFILE_CONFIGS
    typeset -A ZSH_PROFILE_COLORS
    typeset -a ZSH_PROFILE_ORDER
    ZSH_PROFILE_CONFIGS=(dev "Dev config")
    ZSH_PROFILE_COLORS=(dev "32;1 32")
    ZSH_PROFILE_ORDER=(dev)
    local out
    out="$(secrets_profiles)"
    assert_contains "$out" "dev - Dev config" "should include description"
    assert_contains "$out" "colors: 32;1 32" "should include colors"
    unset ZSH_PROFILE_CONFIGS ZSH_PROFILE_COLORS ZSH_PROFILE_ORDER
}

test_secrets_bootstrap_requires_op() {
    local old_path out rc
    old_path="$PATH"
    PATH="/usr/bin:/bin"
    unalias op 2>/dev/null || true
    unfunction op 2>/dev/null || true
    out="$(secrets_bootstrap_from_1p 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "bootstrap should fail without op"
    assert_contains "$out" "op not found" "should warn without op"
    PATH="$old_path"
}

test_secrets_profile_switch_sets_profile() {
    local old_profile="${ZSH_ENV_PROFILE-}"
    ZSH_SECRETS_MODE=off
    secrets_profile_switch dev >/dev/null 2>&1
    assert_equal "dev" "$ZSH_ENV_PROFILE" "should set ZSH_ENV_PROFILE"
    if [[ -n "$old_profile" ]]; then
        export ZSH_ENV_PROFILE="$old_profile"
    fi
}

test_secrets_profile_switch_persists() {
    local tmp file old_file old_mode
    tmp="$(mktemp -d)"
    file="$tmp/secrets.env"
    old_file="$ZSH_SECRETS_FILE"
    old_mode="$ZSH_SECRETS_MODE"
    export ZSH_SECRETS_FILE="$file"
    export ZSH_SECRETS_MODE="off"
    secrets_profile_switch staging >/dev/null 2>&1
    assert_contains "$(cat "$file")" "ZSH_ENV_PROFILE=staging" "should persist profile to secrets file"
    export ZSH_SECRETS_FILE="$old_file"
    export ZSH_SECRETS_MODE="$old_mode"
    rm -rf "$tmp"
}

test_secrets_update_env_file_error_handling() {
    local old_file
    old_file="$ZSH_SECRETS_FILE"
    export ZSH_SECRETS_FILE="/root/forbidden_secrets.env"
    out="$(_secrets_update_env_file FOO bar 2>&1 || true)"
    assert_contains "$out" "Failed to create secrets file" "should warn on write failure"
    export ZSH_SECRETS_FILE="$old_file"
}

test_secrets_profile_switch_ignores_vault_without_account() {
    local old_account old_vault out tmp
    old_account="${OP_ACCOUNT-}"
    old_vault="${OP_VAULT-}"
    unset OP_ACCOUNT
    export OP_VAULT="VaultOnly"
    tmp="$(mktemp)"
    secrets_profile_switch dev >"$tmp" 2>&1 || true
    out="$(cat "$tmp")"
    assert_contains "$out" "clearing vault" "should clear vault without account"
    assert_equal "" "${OP_VAULT-}" "should unset OP_VAULT"
    rm -f "$tmp"
    export OP_ACCOUNT="$old_account"
    export OP_VAULT="$old_vault"
}

test_secrets_validate_setup_success() {
    local tmp map old_mode old_map old_path old_test_mode
    tmp="$(mktemp -d)"
    map="$tmp/secrets.1p"
    echo "ENV VAR user field" > "$map"
    old_mode="$ZSH_SECRETS_MODE"
    old_map="$ZSH_SECRETS_MAP"
    old_path="$PATH"
    old_test_mode="${ZSH_TEST_MODE-}"
    unset ZSH_TEST_MODE
    export ZSH_SECRETS_MODE="op"
    export ZSH_SECRETS_MAP="$map"
    PATH="$tmp/bin:/usr/bin:/bin"
    mkdir -p "$tmp/bin"
    cat > "$tmp/bin/op" <<'OP'
#!/usr/bin/env zsh
if [[ "$1 $2" == "account list" ]]; then
  exit 0
fi
exit 0
OP
    chmod +x "$tmp/bin/op"
    out="$(secrets_validate_setup 2>&1)"
    assert_contains "$out" "Secrets setup looks good" "should print success message"
    export ZSH_SECRETS_MODE="$old_mode"
    export ZSH_SECRETS_MAP="$old_map"
    PATH="$old_path"
    if [[ -n "${old_test_mode-}" ]]; then
        export ZSH_TEST_MODE="$old_test_mode"
    fi
    rm -rf "$tmp"
}

test_op_signin_account_usage() {
    local out
    out="$(op_signin_account 2>&1 || true)"
    assert_contains "$out" "Usage: op_signin_account" "should show usage"
}

test_op_signin_account_uuid_usage() {
    local out
    out="$(op_signin_account_uuid 2>&1 || true)"
    assert_contains "$out" "Usage: op_signin_account_uuid" "should show usage"
}

test_op_signin_all_missing_accounts_file() {
    local old_file
    old_file="$OP_ACCOUNTS_FILE"
    export OP_ACCOUNTS_FILE="/tmp/does-not-exist"
    out="$(op_signin_all 2>&1 || true)"
    assert_contains "$out" "No account aliases file" "should warn on missing aliases file"
    export OP_ACCOUNTS_FILE="$old_file"
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

test_vault_without_account_warns() {
    local out old_account
    old_account="${OP_ACCOUNT-}"
    unset OP_ACCOUNT
    out="$(secrets_sync_to_1p "zsh-secrets-env" "" "VaultA" 2>&1 || true)"
    assert_contains "$out" "Vault specified without account; refusing to sync" "should reject vault without account"
    if [[ -n "${old_account-}" ]]; then
        export OP_ACCOUNT="$old_account"
    fi
}

register_test "test_secrets_load_file" "test_secrets_load_file"
register_test "test_secrets_load_op" "test_secrets_load_op"
register_test "test_secrets_load_op_supports_op_url_mapping" "test_secrets_load_op_supports_op_url_mapping"
register_test "test_secrets_push_uses_1password_when_available" "test_secrets_push_uses_1password_when_available"
register_test "test_secrets_pull_prefers_rsync_when_host_provided" "test_secrets_pull_prefers_rsync_when_host_provided"
register_test "test_secrets_normalize_mode_strips_quote" "test_secrets_normalize_mode_strips_quote"
register_test "test_secrets_trim_value_strips_space_quote" "test_secrets_trim_value_strips_space_quote"
register_test "test_secrets_normalize_value_trims_and_strips_quotes" "test_secrets_normalize_value_trims_and_strips_quotes"
register_test "test_op_group_item_ids_by_title_orders" "test_op_group_item_ids_by_title_orders"
register_test "test_secrets_pull_prefers_item_with_content" "test_secrets_pull_prefers_item_with_content"
register_test "test_secrets_missing_from_1p_reports_missing" "test_secrets_missing_from_1p_reports_missing"
register_test "test_secrets_missing_from_1p_json_and_fix" "test_secrets_missing_from_1p_json_and_fix"
register_test "test_op_resolve_account_uuid_from_alias" "test_op_resolve_account_uuid_from_alias"
register_test "test_op_account_alias_trims_quote" "test_op_account_alias_trims_quote"
register_test "test_op_latest_item_id_uses_op_bin" "test_op_latest_item_id_uses_op_bin"
register_test "test_op_latest_item_id_resolves_alias_to_uuid" "test_op_latest_item_id_resolves_alias_to_uuid"
register_test "test_op_latest_item_id_fallbacks_without_vault" "test_op_latest_item_id_fallbacks_without_vault"
register_test "test_secrets_pull_defaults_to_source_account" "test_secrets_pull_defaults_to_source_account"
register_test "test_secrets_extract_item_value_notes_plain" "test_secrets_extract_item_value_notes_plain"
register_test "test_secrets_extract_item_value_field" "test_secrets_extract_item_value_field"
register_test "test_secrets_find_account_for_item" "test_secrets_find_account_for_item"
register_test "test_machine_profile_default" "test_machine_profile_default"
register_test "test_secrets_edit_creates_file" "test_secrets_edit_creates_file"
register_test "test_secrets_sync_to_1p_requires_op" "test_secrets_sync_to_1p_requires_op"
register_test "test_secrets_sync_to_1p_with_account_vault" "test_secrets_sync_to_1p_with_account_vault"
register_test "test_secrets_init_from_example" "test_secrets_init_from_example"
register_test "test_secrets_init_map_from_example" "test_secrets_init_map_from_example"
register_test "test_secrets_map_sanitize_fixes_trailing_quote" "test_secrets_map_sanitize_fixes_trailing_quote"
register_test "test_op_accounts_sanitize_fixes_trailing_quote" "test_op_accounts_sanitize_fixes_trailing_quote"
register_test "test_op_list_accounts_vaults_requires_op" "test_op_list_accounts_vaults_requires_op"
register_test "test_op_account_alias_lookup" "test_op_account_alias_lookup"
register_test "test_op_account_uuid_configured" "test_op_account_uuid_configured"
register_test "test_op_set_default_clears_vault" "test_op_set_default_clears_vault"
register_test "test_op_set_default_prefers_shorthand" "test_op_set_default_prefers_shorthand"
register_test "test_op_set_default_uses_uuid_when_no_shorthand" "test_op_set_default_uses_uuid_when_no_shorthand"
register_test "test_secrets_require_source_blocks_mismatch" "test_secrets_require_source_blocks_mismatch"
register_test "test_op_alias_shim_resolves_account" "test_op_alias_shim_resolves_account"
register_test "test_op_list_accounts_vaults_empty" "test_op_list_accounts_vaults_empty"
register_test "test_op_list_items_requires_op" "test_op_list_items_requires_op"
register_test "test_secrets_pull_requires_op" "test_secrets_pull_requires_op"
register_test "test_secrets_pull_fallback_notes_plain" "test_secrets_pull_fallback_notes_plain"
register_test "test_op_login_headless_requires_op" "test_op_login_headless_requires_op"
register_test "test_secrets_profile_switch_usage" "test_secrets_profile_switch_usage"
register_test "test_secrets_profile_switch_sets_profile" "test_secrets_profile_switch_sets_profile"
register_test "test_secrets_profile_switch_persists" "test_secrets_profile_switch_persists"
register_test "test_secrets_profile_switch_invalid_profile" "test_secrets_profile_switch_invalid_profile"
register_test "test_secrets_profile_switch_ignores_vault_without_account" "test_secrets_profile_switch_ignores_vault_without_account"
register_test "test_secrets_profile_list_from_config" "test_secrets_profile_list_from_config"
register_test "test_secrets_profiles_output" "test_secrets_profiles_output"
register_test "test_secrets_bootstrap_requires_op" "test_secrets_bootstrap_requires_op"
register_test "test_secrets_update_env_file_error_handling" "test_secrets_update_env_file_error_handling"
register_test "test_secrets_validate_setup_success" "test_secrets_validate_setup_success"
register_test "test_vault_without_account_warns" "test_vault_without_account_warns"
register_test "test_op_signin_account_usage" "test_op_signin_account_usage"
register_test "test_op_signin_account_uuid_usage" "test_op_signin_account_uuid_usage"
register_test "test_op_signin_all_missing_accounts_file" "test_op_signin_all_missing_accounts_file"
