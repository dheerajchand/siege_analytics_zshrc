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

test_secrets_normalize_mode_strips_quote() {
    local old_mode="${ZSH_SECRETS_MODE-}"
    export ZSH_SECRETS_MODE='both"'
    _secrets_normalize_mode
    assert_equal "both" "$ZSH_SECRETS_MODE" "should strip trailing quote"
    export ZSH_SECRETS_MODE="$old_mode"
}

test_secrets_trim_value_strips_space_quote() {
    local out
    out="$(_secrets_normalize_value 'both"   ')"
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

register_test "test_secrets_normalize_mode_strips_quote" "test_secrets_normalize_mode_strips_quote"
register_test "test_secrets_trim_value_strips_space_quote" "test_secrets_trim_value_strips_space_quote"
register_test "test_secrets_normalize_value_trims_and_strips_quotes" "test_secrets_normalize_value_trims_and_strips_quotes"
register_test "test_secrets_extract_item_value_notes_plain" "test_secrets_extract_item_value_notes_plain"
register_test "test_secrets_extract_item_value_field" "test_secrets_extract_item_value_field"
