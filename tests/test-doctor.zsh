#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/doctor.zsh"

test_doctor_function_defined() {
    assert_command_success "typeset -f zsh_doctor >/dev/null" "zsh_doctor should be defined"
}

test_doctor_runs_and_returns_quickly() {
    # Smoke test: zsh_doctor should run without erroring and produce
    # output containing the summary line.
    local out
    out="$(zsh_doctor 2>&1)"
    assert_contains "$out" "zsh_doctor" "should print the header"
    assert_contains "$out" "ok" "should report at least one ok check"
    assert_contains "$out" "Summary" "should print a Summary section"
}

test_doctor_flags_leaked_zcompdump() {
    # Synthetic check: with a stale ~/.zcompdump* present, the FAIL
    # counter should be nonzero.
    local tmp_home
    tmp_home="$(mktemp -d)"
    touch "$tmp_home/.zcompdump"
    local out
    out="$(HOME="$tmp_home" zsh_doctor 2>&1)"
    rm -rf "$tmp_home"
    assert_contains "$out" "stale ~/.zcompdump*" "should flag stale compdump in HOME"
}

register_test "doctor_function_defined" test_doctor_function_defined
register_test "doctor_runs_and_returns_quickly" test_doctor_runs_and_returns_quickly
register_test "doctor_flags_leaked_zcompdump" test_doctor_flags_leaked_zcompdump
