#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/fileprovider.zsh"

test_fileprovider_status_runs() {
    local out
    out="$(fileprovider_status 2>&1)"
    # Either daemon is running (and we see fileproviderd line) or it's not
    # (and we see "not running"). Either is a healthy run.
    if [[ "$out" != *"fileproviderd"* ]]; then
        _print_fail "expected output to mention fileproviderd; got: $out"
        return 1
    fi
    return 0
}

test_fp_human_size_thresholds() {
    assert_equal "0B" "$(_fp_human_size 0)" "0 → 0B"
    assert_equal "512B" "$(_fp_human_size 512)" "512 → 512B"
    assert_equal "1.0K" "$(_fp_human_size 1024)" "1KiB → 1.0K"
    assert_equal "1.0M" "$(_fp_human_size 1048576)" "1MiB → 1.0M"
    assert_equal "1.0G" "$(_fp_human_size 1073741824)" "1GiB → 1.0G"
}

test_fp_size_of_handles_missing_file() {
    local out
    out="$(_fp_size_of "/no/such/path")"
    assert_equal "0" "$out" "missing file should return 0"
}

test_fp_size_of_real_file() {
    local tmp
    tmp="$(mktemp)"
    print -- "12345" > "$tmp"
    local out
    out="$(_fp_size_of "$tmp")"
    rm -f "$tmp"
    assert_equal "6" "$out" "6 bytes (5 chars + newline)"
}

test_fileprovider_check_handles_missing_ctl() {
    # If /usr/bin/fileproviderctl is not on PATH, the function should
    # warn and return nonzero rather than blow up.
    local saved_path="$PATH"
    PATH="/tmp/empty-bin"
    local out rc
    out="$(fileprovider_check 2>&1 || true)"
    rc=$?
    PATH="$saved_path"
    if [[ "$out" != *"fileproviderctl not found"* ]]; then
        _print_fail "expected 'fileproviderctl not found' message; got: $out"
        return 1
    fi
    return 0
}

register_test "fileprovider_status_runs" test_fileprovider_status_runs
register_test "fp_human_size_thresholds" test_fp_human_size_thresholds
register_test "fp_size_of_handles_missing_file" test_fp_size_of_handles_missing_file
register_test "fp_size_of_real_file" test_fp_size_of_real_file
register_test "fileprovider_check_handles_missing_ctl" test_fileprovider_check_handles_missing_ctl
