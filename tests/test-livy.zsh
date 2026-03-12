#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/livy.zsh"

test_livy_detect_home_returns_env() {
    local old_home="${LIVY_HOME:-}"
    export LIVY_HOME="/tmp/stub-livy"
    mkdir -p "$LIVY_HOME"
    local out
    out="$(_livy_detect_home)"
    assert_equal "/tmp/stub-livy" "$out" "should return LIVY_HOME when set"
    export LIVY_HOME="$old_home"
}

test_livy_detect_home_fallback() {
    local old_home="${LIVY_HOME:-}"
    unset LIVY_HOME
    local out
    out="$(_livy_detect_home 2>/dev/null || true)"
    # Should return fallback or empty if not found
    if [[ -d "$HOME/opt/livy/current" ]]; then
        assert_equal "$HOME/opt/livy/current" "$out" "should fall back to ~/opt/livy/current"
    fi
    export LIVY_HOME="$old_home"
}

test_livy_status_output() {
    local out
    out="$(livy_status 2>&1 || true)"
    assert_contains "$out" "Livy" "livy_status should mention Livy"
}

test_livy_url_default() {
    local old_url="${ZEPPELIN_LIVY_URL:-}"
    unset ZEPPELIN_LIVY_URL
    local out
    out="$(_livy_url)"
    assert_equal "http://127.0.0.1:8998" "$out" "default Livy URL should be localhost:8998"
    export ZEPPELIN_LIVY_URL="$old_url"
}

test_livy_url_env_override() {
    local old_url="${ZEPPELIN_LIVY_URL:-}"
    export ZEPPELIN_LIVY_URL="http://livy.example.com:9999"
    local out
    out="$(_livy_url)"
    assert_equal "http://livy.example.com:9999" "$out" "should use ZEPPELIN_LIVY_URL override"
    export ZEPPELIN_LIVY_URL="$old_url"
}

register_test "test_livy_detect_home_returns_env" "test_livy_detect_home_returns_env"
register_test "test_livy_detect_home_fallback" "test_livy_detect_home_fallback"
register_test "test_livy_status_output" "test_livy_status_output"
register_test "test_livy_url_default" "test_livy_url_default"
register_test "test_livy_url_env_override" "test_livy_url_env_override"
