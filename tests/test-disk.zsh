#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/disk.zsh"

# ---- _disk_is_icloud_path ----

test_icloud_path_documents() {
    _disk_is_icloud_path "$HOME/Documents/foo"
    assert_equal "0" "$?" "Documents subpath should be flagged iCloud"
}

test_icloud_path_documents_root() {
    _disk_is_icloud_path "$HOME/Documents"
    assert_equal "0" "$?" "Documents root should be flagged iCloud"
}

test_icloud_path_desktop() {
    _disk_is_icloud_path "$HOME/Desktop/foo"
    assert_equal "0" "$?" "Desktop subpath should be flagged iCloud"
}

test_icloud_path_safe() {
    _disk_is_icloud_path "$HOME/.cache"
    assert_equal "1" "$?" "~/.cache should NOT be flagged iCloud"
}

test_icloud_path_library() {
    _disk_is_icloud_path "$HOME/Library/Caches/foo"
    assert_equal "1" "$?" "~/Library should NOT be flagged iCloud"
}

# ---- _disk_size ----

test_size_missing() {
    local out
    out=$(_disk_size "/nonexistent/path/$$")
    assert_equal "MISSING" "$out" "_disk_size returns MISSING for absent path"
}

test_size_present() {
    local tmp
    tmp=$(mktemp -d)
    local out
    out=$(_disk_size "$tmp")
    rmdir "$tmp"
    assert_true "[[ -n '$out' && '$out' != 'MISSING' ]]" "_disk_size returns human size for real dir"
}

# ---- disk_clean_caches dry-run safety ----

test_clean_caches_dry_run_is_default() {
    local tmp
    tmp=$(mktemp -d)
    touch "$tmp/canary"
    # Override the targets list to point at our temp file
    local saved=("${_DISK_SAFE_CACHE_TARGETS[@]}")
    _DISK_SAFE_CACHE_TARGETS=("$tmp")
    disk_clean_caches >/dev/null 2>&1
    _DISK_SAFE_CACHE_TARGETS=("${saved[@]}")
    assert_true "[[ -f '$tmp/canary' ]]" "dry-run must NOT delete files"
    rm -rf "$tmp"
}

test_clean_caches_execute_deletes() {
    local tmp
    tmp=$(mktemp -d)
    touch "$tmp/canary"
    local saved=("${_DISK_SAFE_CACHE_TARGETS[@]}")
    _DISK_SAFE_CACHE_TARGETS=("$tmp")
    disk_clean_caches --execute >/dev/null 2>&1
    _DISK_SAFE_CACHE_TARGETS=("${saved[@]}")
    assert_false "[[ -e '$tmp' ]]" "--execute must actually delete"
}

test_clean_caches_refuses_icloud() {
    # Inject a fake iCloud path into the targets list and verify it is refused
    local fake_icloud="$HOME/Documents/.disk_module_test_$$"
    mkdir -p "$fake_icloud"
    touch "$fake_icloud/canary"
    local saved=("${_DISK_SAFE_CACHE_TARGETS[@]}")
    _DISK_SAFE_CACHE_TARGETS=("$fake_icloud")
    disk_clean_caches --execute >/dev/null 2>&1
    _DISK_SAFE_CACHE_TARGETS=("${saved[@]}")
    assert_true "[[ -f '$fake_icloud/canary' ]]" "must refuse to delete inside iCloud-synced path"
    rm -rf "$fake_icloud"
}

# ---- disk_prune_snapshots dry-run safety ----

test_prune_snapshots_dry_run() {
    local tmp
    tmp=$(mktemp -d)
    mkdir -p "$tmp/config_2025-01" "$tmp/config_2025-02" "$tmp/config_2025-03" \
             "$tmp/config_2025-04" "$tmp/config_2025-05" "$tmp/config_2025-06"
    disk_prune_snapshots --root "$tmp" --keep 3 >/dev/null 2>&1
    local count
    count=$(find "$tmp" -maxdepth 1 -type d -name 'config_*' 2>/dev/null | wc -l | tr -d ' ')
    rm -rf "$tmp"
    assert_equal "6" "$count" "dry-run must NOT remove snapshots"
}

test_prune_snapshots_execute_keeps_n_newest() {
    local tmp
    tmp=$(mktemp -d)
    mkdir -p "$tmp/config_2025-01" "$tmp/config_2025-02" "$tmp/config_2025-03" \
             "$tmp/config_2025-04" "$tmp/config_2025-05" "$tmp/config_2025-06"
    disk_prune_snapshots --root "$tmp" --keep 3 --execute >/dev/null 2>&1
    local count
    count=$(find "$tmp" -maxdepth 1 -type d -name 'config_*' 2>/dev/null | wc -l | tr -d ' ')
    rm -rf "$tmp"
    assert_equal "3" "$count" "--execute keeps exactly N=3 snapshots"
}

test_prune_snapshots_handles_spaces_in_names() {
    local tmp
    tmp=$(mktemp -d)
    # iCloud-style duplicate naming with spaces — exact pattern this module exists to handle.
    # Pattern 'config*' matches both underscore and space variants.
    mkdir -p "$tmp/config_2025-01" "$tmp/config_2025-02" \
             "$tmp/config 2025-05" "$tmp/config 2 2025-06"
    disk_prune_snapshots --root "$tmp" --pattern 'config*' --keep 2 --execute >/dev/null 2>&1
    local count
    count=$(find "$tmp" -maxdepth 1 -type d -name 'config*' 2>/dev/null | wc -l | tr -d ' ')
    # The space-containing dirs must remain whole — if word-splitting bug, count would be > 2 (partial dirs orphaned) or rm would fail entirely
    rm -rf "$tmp"
    assert_equal "2" "$count" "snapshot names with spaces must be handled atomically (keep 2, prune 2)"
}

test_prune_snapshots_rejects_negative_keep() {
    local tmp
    tmp=$(mktemp -d)
    mkdir -p "$tmp/config_2025-01"
    local out rc
    out=$(disk_prune_snapshots --root "$tmp" --keep -3 --execute 2>&1)
    rc=$?
    rm -rf "$tmp"
    assert_equal "1" "$rc" "--keep -3 must be rejected"
    assert_contains "$out" "non-negative integer" "rejection message names the constraint"
}

# ---- disk_prune_jetbrains_stale (with --base-dir for testability) ----

test_prune_jetbrains_dry_run_preserves() {
    local tmp
    tmp=$(mktemp -d)
    mkdir -p "$tmp/PyCharm2026.1" "$tmp/PyCharm2025.3" "$tmp/Daemon"
    disk_prune_jetbrains_stale --base-dir "$tmp" >/dev/null 2>&1
    local count
    count=$(find "$tmp" -maxdepth 1 -type d -not -path "$tmp" 2>/dev/null | wc -l | tr -d ' ')
    rm -rf "$tmp"
    assert_equal "3" "$count" "dry-run preserves all dirs"
}

test_prune_jetbrains_execute_drops_non_keep_year() {
    local tmp
    tmp=$(mktemp -d)
    mkdir -p "$tmp/PyCharm2026.1" "$tmp/PyCharm2025.3" "$tmp/DataSpell2025.3" "$tmp/Daemon"
    disk_prune_jetbrains_stale --base-dir "$tmp" --keep-prefix 2026 --execute >/dev/null 2>&1
    # 2025.3 dirs gone, 2026.1 kept, Daemon (carve-out) kept
    assert_true "[[ -d '$tmp/PyCharm2026.1' ]]"   "2026.1 preserved"
    assert_false "[[ -d '$tmp/PyCharm2025.3' ]]"  "2025.3 PyCharm dropped"
    assert_false "[[ -d '$tmp/DataSpell2025.3' ]]" "2025.3 DataSpell dropped"
    assert_true "[[ -d '$tmp/Daemon' ]]"          "Daemon carve-out preserved"
    rm -rf "$tmp"
}

# ---- disk_check_icloud_corruption ----

test_corruption_check_clean() {
    local tmp
    tmp=$(mktemp -d)
    touch "$tmp/regular_file.txt"
    disk_check_icloud_corruption "$tmp" >/dev/null 2>&1
    local rc=$?
    rm -rf "$tmp"
    assert_equal "0" "$rc" "clean dir should exit 0 (no corruption)"
}

test_corruption_check_dirty() {
    local tmp
    tmp=$(mktemp -d)
    touch "$tmp/file.txt"
    touch "$tmp/file 2.txt"
    disk_check_icloud_corruption "$tmp" >/dev/null 2>&1
    local rc=$?
    rm -rf "$tmp"
    assert_equal "1" "$rc" "dir with ' 2.*' files should exit nonzero"
}

# Register tests
register_test "icloud_path_documents"      test_icloud_path_documents
register_test "icloud_path_documents_root" test_icloud_path_documents_root
register_test "icloud_path_desktop"        test_icloud_path_desktop
register_test "icloud_path_safe"           test_icloud_path_safe
register_test "icloud_path_library"        test_icloud_path_library
register_test "size_missing"               test_size_missing
register_test "size_present"               test_size_present
register_test "clean_caches_dry_run"       test_clean_caches_dry_run_is_default
register_test "clean_caches_execute"       test_clean_caches_execute_deletes
register_test "clean_caches_refuses_icloud" test_clean_caches_refuses_icloud
register_test "prune_snapshots_dry_run"    test_prune_snapshots_dry_run
register_test "prune_snapshots_execute"    test_prune_snapshots_execute_keeps_n_newest
register_test "prune_snapshots_spaces"     test_prune_snapshots_handles_spaces_in_names
register_test "prune_snapshots_neg_keep"   test_prune_snapshots_rejects_negative_keep
register_test "prune_jetbrains_dry_run"    test_prune_jetbrains_dry_run_preserves
register_test "prune_jetbrains_execute"    test_prune_jetbrains_execute_drops_non_keep_year
register_test "corruption_check_clean"     test_corruption_check_clean
register_test "corruption_check_dirty"     test_corruption_check_dirty
