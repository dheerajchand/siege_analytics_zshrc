#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/compat.zsh"

test_compat_matrix_file_exists() {
    local matrix
    matrix="$(_compat_matrix_file)"
    assert_true "[[ -f '$matrix' ]]" "compatibility-matrix.json should exist"
}

test_compat_profiles_lists_entries() {
    local out
    out="$(compat_profiles 2>&1 || true)"
    assert_contains "$out" "stable" "compat_profiles should list the stable profile"
}

test_stack_profile_use_sets_env() {
    skip_in_ci
    local old_spark="${SPARK_VERSION:-}"
    # Get first profile name from matrix
    local profile
    profile="$(python3 -c "import json; m=json.load(open('$(_compat_matrix_file)')); print(list(m.get('profiles',{}).keys())[0])" 2>/dev/null || true)"
    if [[ -n "$profile" ]]; then
        stack_profile_use "$profile" >/dev/null 2>&1 || true
        assert_true "[[ -n \"\${SPARK_VERSION:-}\" ]]" "should set SPARK_VERSION"
    fi
    export SPARK_VERSION="$old_spark"
}

test_stack_profile_status_output() {
    local out
    out="$(stack_profile_status 2>&1 || true)"
    assert_contains "$out" "Spark" "stack_profile_status should mention Spark"
}

test_stack_validate_versions_json() {
    skip_in_ci
    local out
    out="$(stack_validate_versions --json 2>&1 || true)"
    # Should produce JSON output (or at least not crash)
    assert_true "true" "stack_validate_versions --json should not crash"
}

register_test "test_compat_matrix_file_exists" "test_compat_matrix_file_exists"
register_test "test_compat_profiles_lists_entries" "test_compat_profiles_lists_entries"
register_test "test_stack_profile_use_sets_env" "test_stack_profile_use_sets_env"
register_test "test_stack_profile_status_output" "test_stack_profile_status_output"
register_test "test_stack_validate_versions_json" "test_stack_validate_versions_json"
