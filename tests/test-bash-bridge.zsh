#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

test_bash_bridge_defines_functions() {
    local out
    out="$(bash -c "source \"$ROOT_DIR/bash-bridge.sh\"; type zrun; type zhelp; type zstatus; type zspark; type zhadoop; type zzeppelin; type zsecrets; type zbackup; type ztest")"
    assert_contains "$out" "zrun is a function" "zrun should be defined"
    assert_contains "$out" "ztest is a function" "ztest should be defined"
}

test_bash_bridge_zrun_usage() {
    local out
    out="$(bash -c "source \"$ROOT_DIR/bash-bridge.sh\"; zrun" 2>&1 || true)"
    assert_contains "$out" "Usage: zrun <function> [args...]" "zrun should print usage without args"
}

test_bash_bridge_zrun_invokes_zsh() {
    local tmp bin log out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    log="$tmp/zsh.log"
    mkdir -p "$bin"

    cat > "$bin/zsh" <<'ZSH'
#!/usr/bin/env bash
echo "$*" > "$ZSH_STUB_LOG"
exit 0
ZSH
    chmod +x "$bin/zsh"

    out="$(PATH="$bin:/usr/bin:/bin" ZSH_STUB_LOG="$log" bash -c "export ZSH_BRIDGE_DIR=/tmp/zcfg; source \"$ROOT_DIR/bash-bridge.sh\"; zrun spark_status --summary; cat \"$log\"")"
    assert_contains "$out" "-lc" "zrun should invoke zsh -lc"
    assert_contains "$out" "source \"/tmp/zcfg/zshrc\"" "zrun should source configured zshrc"
    assert_contains "$out" "spark_status --summary" "zrun should forward function args"

    rm -rf "$tmp"
}

test_bash_bridge_ztest_runs_runner() {
    local tmp bin log out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    log="$tmp/zsh.log"
    mkdir -p "$bin"

    cat > "$bin/zsh" <<'ZSH'
#!/usr/bin/env bash
echo "$*" > "$ZSH_STUB_LOG"
exit 0
ZSH
    chmod +x "$bin/zsh"

    out="$(PATH="$bin:/usr/bin:/bin" ZSH_STUB_LOG="$log" bash -c "export ZSH_BRIDGE_DIR=\"$ROOT_DIR\"; source \"$ROOT_DIR/bash-bridge.sh\"; ztest --test test_settings_load_order; cat \"$log\"")"
    assert_contains "$out" "run-tests.zsh --test test_settings_load_order" "ztest should call run-tests.zsh"

    rm -rf "$tmp"
}

register_test "test_bash_bridge_defines_functions" "test_bash_bridge_defines_functions"
register_test "test_bash_bridge_zrun_usage" "test_bash_bridge_zrun_usage"
register_test "test_bash_bridge_zrun_invokes_zsh" "test_bash_bridge_zrun_invokes_zsh"
register_test "test_bash_bridge_ztest_runs_runner" "test_bash_bridge_ztest_runs_runner"
