#!/usr/bin/env zsh
set -u

if [[ -n "${TEST_FRAMEWORK_LOADED:-}" ]]; then
    return 0
fi
export TEST_FRAMEWORK_LOADED=1

typeset -ga TEST_NAMES=()
typeset -gA TEST_FUNCS=()
TEST_ASSERT_FAIL=0

TEST_VERBOSE="${TEST_VERBOSE:-0}"

register_test() {
    local name="$1"
    local func="${2:-$1}"
    TEST_NAMES+=("$name")
    TEST_FUNCS[$name]="$func"
}

_print_fail() {
    local msg="$1"
    echo "FAIL: $msg"
    TEST_ASSERT_FAIL=1
}

assert_true() {
    local condition="$1"
    local msg="${2:-expected condition to be true}"
    if ! eval "$condition"; then
        _print_fail "$msg"
        return 1
    fi
}

assert_false() {
    local condition="$1"
    local msg="${2:-expected condition to be false}"
    if eval "$condition"; then
        _print_fail "$msg"
        return 1
    fi
}

assert_equal() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-values are not equal}"
    if [[ "$expected" != "$actual" ]]; then
        _print_fail "$msg (expected: '$expected' got: '$actual')"
        return 1
    fi
}

assert_not_equal() {
    local expected="$1"
    local actual="$2"
    local msg="${3:-values are equal}"
    if [[ "$expected" == "$actual" ]]; then
        _print_fail "$msg (value: '$actual')"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-expected string to contain substring}"
    if [[ "$haystack" != *"$needle"* ]]; then
        _print_fail "$msg (missing: '$needle')"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local msg="${3:-expected string to not contain substring}"
    if [[ "$haystack" == *"$needle"* ]]; then
        _print_fail "$msg (found: '$needle')"
        return 1
    fi
}

assert_command_success() {
    local cmd="$1"
    local msg="${2:-expected command to succeed}"
    if ! eval "$cmd"; then
        _print_fail "$msg (cmd: $cmd)"
        return 1
    fi
}

assert_command_failure() {
    local cmd="$1"
    local msg="${2:-expected command to fail}"
    if eval "$cmd"; then
        _print_fail "$msg (cmd: $cmd)"
        return 1
    fi
}

TEST_SKIP=0
TEST_SKIPPED_COUNT=0

skip_if_missing() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        TEST_SKIP=1
        return 0
    fi
}

skip_in_ci() {
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        TEST_SKIP=1
        return 0
    fi
}

run_test() {
    local name="$1"
    local func="${TEST_FUNCS[$name]-$name}"
    if ! typeset -f "$func" >/dev/null 2>&1; then
        _print_fail "unknown test: $name"
        return 1
    fi
    [[ "$TEST_VERBOSE" == "1" ]] && echo "RUN: $name"
    TEST_ASSERT_FAIL=0
    TEST_SKIP=0
    "$func"
    local rc=$?
    if [[ "$TEST_SKIP" -eq 1 ]]; then
        [[ "$TEST_VERBOSE" == "1" ]] && echo "SKIP: $name"
        ((TEST_SKIPPED_COUNT++))
        return 0
    fi
    if [[ "$TEST_ASSERT_FAIL" -ne 0 || "$rc" -ne 0 ]]; then
        return 1
    fi
    return 0
}

run_all_tests() {
    local total=0
    local failed=0
    local name
    for name in "${TEST_NAMES[@]}"; do
        ((total++))
        if run_test "$name"; then
            [[ "$TEST_VERBOSE" == "1" ]] && echo "PASS: $name"
        else
            ((failed++))
        fi
    done
    if [[ "$TEST_SKIPPED_COUNT" -gt 0 ]]; then
        echo "TOTAL: $total  FAILED: $failed  SKIPPED: $TEST_SKIPPED_COUNT"
    else
        echo "TOTAL: $total  FAILED: $failed"
    fi
    [[ "$failed" -eq 0 ]]
}
