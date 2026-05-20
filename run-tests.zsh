#!/usr/bin/env zsh
# `pipefail` is deliberately NOT set globally: test assertions frequently
# look like `cmd | grep -q "something"`, and `grep -q` exits as soon as
# it finds a match. Under pipefail the upstream producer may then be
# killed by SIGPIPE, turning a successful assertion into a flake. Tests
# that need strict mode should opt in scoped inside `emulate -L`.
set -eu

ROOT_DIR="$(cd "$(dirname "${0:A}")" && pwd)"
TESTS_DIR="$ROOT_DIR/tests"

TEST_VERBOSE=0
TEST_NAME=""

usage() {
    cat <<'USAGE'
Usage: zsh run-tests.zsh [--verbose] [--list] [--test NAME]
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose) TEST_VERBOSE=1; shift ;;
        --list) TEST_NAME="__list__"; shift ;;
        --test) TEST_NAME="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown arg: $1"; usage; exit 1 ;;
    esac
done

export TEST_VERBOSE
export ZSH_TEST_MODE=1

for test_file in "$TESTS_DIR"/test-*.zsh; do
    [[ -f "$test_file" ]] || continue
    [[ "$test_file" == *"/test-framework.zsh" ]] && continue
    source "$test_file"
done

if [[ "$TEST_NAME" == "__list__" ]]; then
    for name in "${TEST_NAMES[@]}"; do
        echo "$name"
    done
    exit 0
fi

if [[ -n "$TEST_NAME" ]]; then
    set +e
    run_test "$TEST_NAME"
    rc=$?
    set -e
    exit $rc
fi

set +e
run_all_tests
rc=$?
set -e
exit $rc
