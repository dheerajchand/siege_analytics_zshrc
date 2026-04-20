#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

# Extract the load_module function from zshrc and run it in a subshell
# so we don't have to source the whole config.
_extract_load_module() {
    awk '/^load_module\(\)/,/^\}/' "$ROOT_DIR/zshrc"
}

test_load_module_honors_disable_flag() {
    # With ZSH_DISABLE_<NAME>=1, the module should NOT be sourced.
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/modules"
    echo 'echo LOADED_FROM_FAKE_MODULE' > "$tmp/modules/fake.zsh"
    local loader="$(_extract_load_module)"
    out="$(ZSH_CONFIG_DIR="$tmp" ZSH_DISABLE_FAKE=1 zsh -c "$loader; load_module fake")"
    rm -rf "$tmp"
    assert_equal "" "$out" "ZSH_DISABLE_FAKE=1 should skip the module source"
}

test_load_module_loads_when_flag_unset() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/modules"
    echo 'echo LOADED_FROM_FAKE_MODULE' > "$tmp/modules/fake.zsh"
    local loader="$(_extract_load_module)"
    out="$(ZSH_CONFIG_DIR="$tmp" zsh -c "$loader; load_module fake")"
    rm -rf "$tmp"
    assert_equal "LOADED_FROM_FAKE_MODULE" "$out" "load_module should source by default"
}

test_load_module_flag_maps_hyphen_to_underscore() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/modules"
    echo 'echo LOADED_HYPHEN' > "$tmp/modules/my-module.zsh"
    local loader="$(_extract_load_module)"
    out="$(ZSH_CONFIG_DIR="$tmp" ZSH_DISABLE_MY_MODULE=1 zsh -c "$loader; load_module my-module")"
    rm -rf "$tmp"
    assert_equal "" "$out" "hyphens should map to underscores in the flag name"
}

register_test "load_module_honors_disable_flag" test_load_module_honors_disable_flag
register_test "load_module_loads_when_flag_unset" test_load_module_loads_when_flag_unset
register_test "load_module_flag_maps_hyphen_to_underscore" test_load_module_flag_maps_hyphen_to_underscore
