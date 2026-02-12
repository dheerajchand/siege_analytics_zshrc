#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/agents.zsh"

test_codex_session_crud() {
    local tmp
    tmp="$(mktemp)"
    CODEX_SESSIONS_FILE="$tmp"
    codex_session_add "demo" "abc123|Test session"
    local out
    out="$(codex_session_list)"
    assert_contains "$out" "demo" "list should include key"
    codex_session_update "demo" "xyz999|Updated"
    out="$(codex_session demo)"
    assert_contains "$out" "codex resume xyz999" "resume should use updated id"
    codex_session_remove "demo"
    out="$(codex_session_list)"
    assert_not_contains "$out" "demo" "key should be removed"
    rm -f "$tmp"
}

test_codex_session_auto_exec_non_interactive() {
    local tmp bin out log
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    log="$tmp/log"
    mkdir -p "$bin"
    cat > "$bin/codex" <<'CODEX'
#!/usr/bin/env zsh
echo "$*" >> "$CODEX_LOG"
CODEX
    chmod +x "$bin/codex"
    export CODEX_SESSIONS_FILE="$tmp/sessions.env"
    export CODEX_LOG="$log"
    printf "demo=abc123|Test\n" > "$CODEX_SESSIONS_FILE"
    : > "$log"
    PATH="$bin:/usr/bin:/bin" ZSH_TEST_MODE=1 zsh -fc \
        "source $ROOT_DIR/modules/agents.zsh; codex_session demo >/dev/null"
    assert_contains "$(cat "$log")" "resume abc123" "should execute codex resume in non-interactive mode"
    rm -rf "$tmp"
}

test_claude_session_crud() {
    local tmp
    tmp="$(mktemp)"
    CLAUDE_SESSIONS_FILE="$tmp"
    claude_session_add "demo" "abc123|Test session"
    local out
    out="$(claude_session_list)"
    assert_contains "$out" "demo" "list should include key"
    claude_session_update "demo" "xyz999|Updated"
    out="$(claude_session demo)"
    assert_contains "$out" "claude resume xyz999" "resume should use updated id"
    claude_session_remove "demo"
    out="$(claude_session_list)"
    assert_not_contains "$out" "demo" "key should be removed"
    rm -f "$tmp"
}

test_claude_session_auto_exec_non_interactive() {
    local tmp bin out log
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    log="$tmp/log"
    mkdir -p "$bin"
    cat > "$bin/claude" <<'CLAUDE'
#!/usr/bin/env zsh
echo "$*" >> "$CLAUDE_LOG"
CLAUDE
    chmod +x "$bin/claude"
    export CLAUDE_SESSIONS_FILE="$tmp/sessions.env"
    export CLAUDE_LOG="$log"
    printf "demo=abc123|Test\n" > "$CLAUDE_SESSIONS_FILE"
    : > "$log"
    PATH="$bin:/usr/bin:/bin" ZSH_TEST_MODE=1 zsh -fc \
        "source $ROOT_DIR/modules/agents.zsh; claude_session demo >/dev/null"
    assert_contains "$(cat "$log")" "resume abc123" "should execute claude resume in non-interactive mode"
    rm -rf "$tmp"
}

register_test "test_codex_session_crud" "test_codex_session_crud"
register_test "test_codex_session_auto_exec_non_interactive" "test_codex_session_auto_exec_non_interactive"
register_test "test_claude_session_crud" "test_claude_session_crud"
register_test "test_claude_session_auto_exec_non_interactive" "test_claude_session_auto_exec_non_interactive"
