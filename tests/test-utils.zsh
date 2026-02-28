#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/utils.zsh"

test_command_exists_basic() {
    assert_true "command_exists echo" "echo should exist"
}

test_path_add_and_clean() {
    local old_path="$PATH"
    PATH="/bin:/bin:/usr/bin"
    path_add "/tmp" "append"
    assert_contains "$PATH" "/tmp" "path_add should append new dir"
    path_clean >/dev/null
    local count
    count="$(printf '%s' "$PATH" | tr ':' '\n' | grep -c "^/bin$")"
    assert_equal "1" "$count" "path_clean should dedupe entries"
    PATH="$old_path"
}

test_download_jars_stub() {
    local old_path="$PATH"
    local tmp bin dest jar
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    dest="$tmp/jars"
    mkdir -p "$bin"
    cat > "$bin/curl" <<'CURL'
#!/usr/bin/env zsh
out=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o)
            out="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done
[[ -n "$out" ]] || exit 1
mkdir -p "$(dirname "$out")"
echo "stub" > "$out"
CURL
    chmod +x "$bin/curl"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    download_jars --dest "$dest" "org.example:demo:1.0.0"
    jar="$dest/demo-1.0.0.jar"
    assert_true "[[ -f \"$jar\" ]]" "download_jars should create jar file"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_legacy_quick_commands_defined() {
    assert_true "typeset -f setup_pyenv >/dev/null 2>&1" "setup_pyenv should be defined"
    assert_true "typeset -f setup_uv >/dev/null 2>&1" "setup_uv should be defined"
    assert_true "typeset -f toggle_hidden_files >/dev/null 2>&1" "toggle_hidden_files should be defined"
    assert_true "typeset -f toggle_key_repeat >/dev/null 2>&1" "toggle_key_repeat should be defined"
    assert_true "typeset -f test_system >/dev/null 2>&1" "test_system should be defined"
    assert_true "typeset -f test_backup >/dev/null 2>&1" "test_backup should be defined"
    assert_true "typeset -f test_python >/dev/null 2>&1" "test_python should be defined"
    assert_true "typeset -f test_spark >/dev/null 2>&1" "test_spark should be defined"
    assert_true "typeset -f test_jvm >/dev/null 2>&1" "test_jvm should be defined"
    assert_true "typeset -f test_jupyter >/dev/null 2>&1" "test_jupyter should be defined"
    assert_true "typeset -f test_compatibility >/dev/null 2>&1" "test_compatibility should be defined"
    assert_true "typeset -f test_bash_install >/dev/null 2>&1" "test_bash_install should be defined"
}

register_test "utils_command_exists" test_command_exists_basic
register_test "utils_path_add_clean" test_path_add_and_clean
register_test "utils_download_jars" test_download_jars_stub
register_test "utils_legacy_quick_commands_defined" test_legacy_quick_commands_defined
