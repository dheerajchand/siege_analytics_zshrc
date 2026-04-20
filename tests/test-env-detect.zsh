#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/env_detect.zsh"

test_env_snapshot_has_expected_keys() {
    local out
    out="$(zsh_env_snapshot)"
    for k in os shell term_program is_warp is_vscode is_cursor is_ide is_ci is_staggered full_init test_mode profile; do
        assert_contains "$out" "${k}=" "snapshot should include ${k}="
    done
}

test_env_query_returns_single_value() {
    local out
    out="$(zsh_env os)"
    assert_not_equal "" "$out" "os fact should be non-empty"
}

test_env_query_missing_key_returns_nonzero() {
    zsh_env nonexistent_key >/dev/null 2>&1
    assert_not_equal "0" "$?" "unknown key should return nonzero"
}

register_test "env_snapshot_has_expected_keys" test_env_snapshot_has_expected_keys
register_test "env_query_returns_single_value" test_env_query_returns_single_value
register_test "env_query_missing_key_returns_nonzero" test_env_query_missing_key_returns_nonzero
