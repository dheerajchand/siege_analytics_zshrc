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

test_secrets_profile_switch_usage() {
    local out
    out="$(secrets_profile_switch 2>&1 || true)"
    assert_contains "$out" "Usage: secrets_profile_switch" "should show usage on missing args"
}

test_secrets_profile_switch_sets_profile() {
    local old_profile="${ZSH_ENV_PROFILE-}"
    ZSH_SECRETS_MODE=off
    secrets_profile_switch --profile dev >/dev/null 2>&1
    assert_equal "dev" "$ZSH_ENV_PROFILE" "should set ZSH_ENV_PROFILE"
    if [[ -n "$old_profile" ]]; then
        export ZSH_ENV_PROFILE="$old_profile"
    fi
}

test_secrets_profile_switch_persists() {
    local tmp file old_file old_mode old_account old_vault old_path old_profile_list
    tmp="$(mktemp -d)"
    file="$tmp/secrets.env"
    old_file="$ZSH_SECRETS_FILE"
    old_mode="$ZSH_SECRETS_MODE"
    old_account="${OP_ACCOUNT-}"
    old_vault="${OP_VAULT-}"
    old_path="$PATH"
    old_profile_list="${ZSH_PROFILE_LIST-}"
    export ZSH_SECRETS_FILE="$file"
    export ZSH_SECRETS_MODE="off"
    export PATH="/usr/bin:/bin"
    unset OP_ACCOUNT OP_VAULT
    export ZSH_PROFILE_LIST="dev staging prod laptop cyberpower"
    : > "$file"
    secrets_profile_switch --profile staging >/dev/null 2>&1 || true
    assert_contains "$(cat "$file")" "ZSH_ENV_PROFILE=staging" "should persist profile to secrets file"
    export ZSH_SECRETS_FILE="$old_file"
    export ZSH_SECRETS_MODE="$old_mode"
    PATH="$old_path"
    if [[ -n "${old_account-}" ]]; then export OP_ACCOUNT="$old_account"; else unset OP_ACCOUNT; fi
    if [[ -n "${old_vault-}" ]]; then export OP_VAULT="$old_vault"; else unset OP_VAULT; fi
    if [[ -n "${old_profile_list-}" ]]; then export ZSH_PROFILE_LIST="$old_profile_list"; else unset ZSH_PROFILE_LIST; fi
    rm -rf "$tmp"
}

test_secrets_profile_switch_invalid_profile() {
    local out
    out="$(secrets_profile_switch --profile nonsense 2>&1 || true)"
    assert_contains "$out" "Invalid profile: nonsense" "should reject invalid profile"
    assert_contains "$out" "expected one of:" "should show expected profiles"
    assert_contains "$out" "Available profiles:" "should list available profiles"
}

test_secrets_profile_switch_ignores_vault_without_account() {
    local old_account old_vault out tmp
    old_account="${OP_ACCOUNT-}"
    old_vault="${OP_VAULT-}"
    unset OP_ACCOUNT
    export OP_VAULT="VaultOnly"
    tmp="$(mktemp)"
    secrets_profile_switch --profile dev >"$tmp" 2>&1 || true
    out="$(cat "$tmp")"
    assert_contains "$out" "clearing vault" "should clear vault without account"
    assert_equal "" "${OP_VAULT-}" "should unset OP_VAULT"
    rm -f "$tmp"
    export OP_ACCOUNT="$old_account"
    export OP_VAULT="$old_vault"
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

register_test "test_machine_profile_default" "test_machine_profile_default"
register_test "test_secrets_profile_switch_usage" "test_secrets_profile_switch_usage"
register_test "test_secrets_profile_switch_sets_profile" "test_secrets_profile_switch_sets_profile"
register_test "test_secrets_profile_switch_persists" "test_secrets_profile_switch_persists"
register_test "test_secrets_profile_switch_invalid_profile" "test_secrets_profile_switch_invalid_profile"
register_test "test_secrets_profile_switch_ignores_vault_without_account" "test_secrets_profile_switch_ignores_vault_without_account"
register_test "test_secrets_profile_list_from_config" "test_secrets_profile_list_from_config"
register_test "test_secrets_profiles_output" "test_secrets_profiles_output"
