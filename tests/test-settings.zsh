#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

test_settings_load_order() {
    local tmp
    tmp="$(mktemp -d)"
    mkdir -p "$tmp"
    ZSH_SETTINGS_DIR="$tmp"
    ZSH_VARS_FILE="$tmp/vars.env"
    ZSH_ALIASES_FILE="$tmp/aliases.zsh"
    ZSH_PATHS_FILE="$tmp/paths.env"
    printf 'export JARS_DIR="/tmp/jars"\n' > "$ZSH_VARS_FILE"
    printf 'alias foo="bar"\n' > "$ZSH_ALIASES_FILE"
    printf 'export WRITING_STUFF="/tmp/writing"\n' > "$ZSH_PATHS_FILE"
    local out
    out="$(ZSH_SETTINGS_DIR="$tmp" ZSH_VARS_FILE="$ZSH_VARS_FILE" ZSH_ALIASES_FILE="$ZSH_ALIASES_FILE" ZSH_PATHS_FILE="$ZSH_PATHS_FILE" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/settings.zsh; echo \"\$JARS_DIR|\$WRITING_STUFF\"; alias foo")"
    assert_contains "$out" "/tmp/jars" "vars.env should load"
    assert_contains "$out" "/tmp/writing" "paths.env should load"
    assert_contains "$out" "foo=" "aliases should load"
    rm -rf "$tmp"
}

test_settings_machine_override() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp"
    printf 'export PYENV_DEFAULT_VENV="shared_default"\n' > "$tmp/vars.env"
    printf 'export PYENV_DEFAULT_VENV="machine_override"\n' > "$tmp/vars.cyberpower.env"
    printf 'export WRITING_STUFF="/tmp/writing"\n' > "$tmp/paths.env"
    printf 'alias foo="bar"\n' > "$tmp/aliases.zsh"
    out="$(ZSH_SETTINGS_DIR="$tmp" ZSH_VARS_FILE="$tmp/vars.env" ZSH_MACHINE_PROFILE="cyberpower" ZSH_VARS_MACHINE_FILE="$tmp/vars.cyberpower.env" ZSH_ALIASES_FILE="$tmp/aliases.zsh" ZSH_PATHS_FILE="$tmp/paths.env" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/settings.zsh; echo \"\$PYENV_DEFAULT_VENV|\$WRITING_STUFF\"")"
    assert_contains "$out" "machine_override|/tmp/writing" "machine vars should override shared vars and keep other files loading"
    rm -rf "$tmp"
}

register_test "test_settings_load_order" "test_settings_load_order"
register_test "test_settings_machine_override" "test_settings_machine_override"
