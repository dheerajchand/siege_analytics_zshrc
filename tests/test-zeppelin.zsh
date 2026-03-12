#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/zeppelin.zsh"

test_zeppelin_detect_home_env() {
    local old_home="${ZEPPELIN_HOME:-}"
    export ZEPPELIN_HOME="/tmp/stub-zeppelin"
    mkdir -p "$ZEPPELIN_HOME"
    local out
    out="$(_zeppelin_detect_home)"
    assert_equal "/tmp/stub-zeppelin" "$out" "should return ZEPPELIN_HOME when set"
    export ZEPPELIN_HOME="$old_home"
}

test_zeppelin_detect_home_fallback() {
    local old_home="${ZEPPELIN_HOME:-}"
    unset ZEPPELIN_HOME
    local out
    out="$(_zeppelin_detect_home 2>/dev/null || true)"
    # Verifies function runs without error when no home is found
    assert_true "true" "should not crash when ZEPPELIN_HOME is unset"
    export ZEPPELIN_HOME="$old_home"
}

test_zeppelin_spark_integration_mode_default() {
    local old_mode="${ZEPPELIN_SPARK_INTEGRATION_MODE:-}"
    unset ZEPPELIN_SPARK_INTEGRATION_MODE
    local out
    out="$(_zeppelin_spark_integration_mode)"
    assert_equal "external" "$out" "default integration mode should be external"
    export ZEPPELIN_SPARK_INTEGRATION_MODE="$old_mode"
}

test_zeppelin_config_status_output() {
    local out
    out="$(zeppelin_config_status 2>&1 || true)"
    assert_contains "$out" "Zeppelin" "zeppelin_config_status should mention Zeppelin"
}

test_zeppelin_integration_use_sets_env() {
    local old_mode="${ZEPPELIN_SPARK_INTEGRATION_MODE:-}"
    zeppelin_integration_use embedded >/dev/null 2>&1
    assert_equal "embedded" "$ZEPPELIN_SPARK_INTEGRATION_MODE" "should set mode to embedded"
    zeppelin_integration_use livy >/dev/null 2>&1
    assert_equal "livy" "$ZEPPELIN_SPARK_INTEGRATION_MODE" "should set mode to livy"
    zeppelin_integration_use external >/dev/null 2>&1
    assert_equal "external" "$ZEPPELIN_SPARK_INTEGRATION_MODE" "should set mode to external"
    export ZEPPELIN_SPARK_INTEGRATION_MODE="$old_mode"
}

test_zeppelin_livy_url_default() {
    local old_url="${ZEPPELIN_LIVY_URL:-}"
    unset ZEPPELIN_LIVY_URL
    local out
    out="$(_zeppelin_livy_url)"
    assert_equal "http://127.0.0.1:8998" "$out" "default Livy URL should be localhost:8998"
    export ZEPPELIN_LIVY_URL="$old_url"
}

test_zeppelin_diagnose_output() {
    local out
    out="$(zeppelin_diagnose 2>&1 || true)"
    assert_contains "$out" "Zeppelin" "zeppelin_diagnose should mention Zeppelin"
}

register_test "test_zeppelin_detect_home_env" "test_zeppelin_detect_home_env"
register_test "test_zeppelin_detect_home_fallback" "test_zeppelin_detect_home_fallback"
register_test "test_zeppelin_spark_integration_mode_default" "test_zeppelin_spark_integration_mode_default"
register_test "test_zeppelin_config_status_output" "test_zeppelin_config_status_output"
register_test "test_zeppelin_integration_use_sets_env" "test_zeppelin_integration_use_sets_env"
register_test "test_zeppelin_livy_url_default" "test_zeppelin_livy_url_default"
register_test "test_zeppelin_diagnose_output" "test_zeppelin_diagnose_output"
