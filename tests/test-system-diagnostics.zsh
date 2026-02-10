#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/system_diagnostics.zsh"

test_icloud_status_missing_tools() {
    if [[ "$OSTYPE" != darwin* ]]; then
        # icloud_status guards with _is_macos; skip on non-macOS
        return 0
    fi
    local old_path="$PATH"
    local tmp
    tmp="$(mktemp -d)"
    PATH="$tmp"
    local out
    out="$(icloud_status 2>/dev/null || true)"
    assert_contains "$out" "brctl not found" "brctl missing should be reported"
    assert_contains "$out" "fileproviderctl not found" "fileproviderctl missing should be reported"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_icloud_preflight_no_brctl() {
    if [[ "$OSTYPE" != darwin* ]]; then
        return 0
    fi
    local old_path="$PATH"
    local tmp
    tmp="$(mktemp -d)"
    PATH="$tmp"
    local out
    out="$(icloud_preflight 2>/dev/null || true)"
    local rc=$?
    assert_equal "0" "$rc" "preflight should return success without brctl"
    assert_contains "$out" "brctl not found" "preflight should mention missing brctl"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_icloud_reset_state_non_interactive() {
    if [[ "$OSTYPE" != darwin* ]]; then
        return 0
    fi
    local old_ps1="${PS1-}"
    unset PS1
    local out
    out="$(icloud_reset_state 2>/dev/null)"
    local rc=$?
    assert_equal "1" "$rc" "reset should refuse in non-interactive shell"
    assert_contains "$out" "Refusing to run in non-interactive shell" "should refuse non-interactive run"
    PS1="$old_ps1"
}

test_dropbox_restart_test_mode() {
    if [[ "$OSTYPE" != darwin* ]]; then
        return 0
    fi
    ZSH_TEST_MODE=1
    local out
    out="$(dropbox_restart 2>/dev/null || true)"
    local rc=$?
    assert_equal "0" "$rc" "dropbox_restart should succeed in test mode"
    assert_contains "$out" "Test mode: would restart Dropbox." "test mode should skip action"
    unset ZSH_TEST_MODE
}

test_linux_system_status_non_linux() {
    if [[ "$OSTYPE" == linux-gnu* ]]; then
        # On Linux, the function runs real diagnostics; skip non-Linux test
        return 0
    fi
    local out
    out="$(linux_system_status 2>/dev/null || true)"
    assert_contains "$out" "Linux diagnostics are Linux-only." "should warn on non-linux"
}

test_data_platform_health_without_modules() {
    local out rc
    out="$(ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/system_diagnostics.zsh; data_platform_health" 2>/dev/null)"
    rc=$?
    assert_not_equal "0" "$rc" "health suite should fail without modules"
    assert_contains "$out" "spark_health not available" "should warn for missing spark module"
    assert_contains "$out" "hadoop_health not available" "should warn for missing hadoop module"
}

test_data_platform_config_status_defined() {
    source "$ROOT_DIR/modules/system_diagnostics.zsh"
    assert_true "typeset -f data_platform_config_status >/dev/null 2>&1" "data_platform_config_status should be defined"
}

_make_stub_sdk() {
    local bin_dir="$1"
    cat > "$bin_dir/sdk" <<'SDK'
#!/usr/bin/env zsh
exit 0
SDK
    chmod +x "$bin_dir/sdk"
}

test_data_platform_use_versions_defined() {
    source "$ROOT_DIR/modules/system_diagnostics.zsh"
    assert_true "typeset -f data_platform_use_versions >/dev/null 2>&1" "data_platform_use_versions should be defined"
    assert_true "typeset -f data_platform_default_versions >/dev/null 2>&1" "data_platform_default_versions should be defined"
}

register_test "test_icloud_status_missing_tools" "test_icloud_status_missing_tools"
register_test "test_icloud_preflight_no_brctl" "test_icloud_preflight_no_brctl"
register_test "test_icloud_reset_state_non_interactive" "test_icloud_reset_state_non_interactive"
register_test "test_dropbox_restart_test_mode" "test_dropbox_restart_test_mode"
register_test "test_linux_system_status_non_linux" "test_linux_system_status_non_linux"
register_test "test_data_platform_health_without_modules" "test_data_platform_health_without_modules"
register_test "test_data_platform_config_status_defined" "test_data_platform_config_status_defined"
register_test "test_data_platform_use_versions_defined" "test_data_platform_use_versions_defined"
