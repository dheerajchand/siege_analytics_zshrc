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
    export CODEX_SESSION_AUTO_EXEC_NONINTERACTIVE=1
    printf "demo=abc123|Test\n" > "$CODEX_SESSIONS_FILE"
    : > "$log"
    PATH="$bin:/usr/bin:/bin" ZSH_TEST_MODE=1 zsh -fc \
        "source $ROOT_DIR/modules/agents.zsh; codex_session demo >/dev/null"
    assert_contains "$(cat "$log")" "resume abc123" "should execute codex resume in non-interactive mode"
    unset CODEX_SESSION_AUTO_EXEC_NONINTERACTIVE
    rm -rf "$tmp"
}

test_codex_session_non_interactive_show_only_by_default() {
    local tmp bin log out
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
    out="$(PATH="$bin:/usr/bin:/bin" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/agents.zsh; codex_session demo")"
    assert_contains "$out" "codex resume abc123" "should print resume command"
    assert_equal "" "$(cat "$log")" "should not auto-execute in non-interactive mode by default"
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
    export CLAUDE_SESSION_AUTO_EXEC_NONINTERACTIVE=1
    printf "demo=abc123|Test\n" > "$CLAUDE_SESSIONS_FILE"
    : > "$log"
    PATH="$bin:/usr/bin:/bin" ZSH_TEST_MODE=1 zsh -fc \
        "source $ROOT_DIR/modules/agents.zsh; claude_session demo >/dev/null"
    assert_contains "$(cat "$log")" "resume abc123" "should execute claude resume in non-interactive mode"
    unset CLAUDE_SESSION_AUTO_EXEC_NONINTERACTIVE
    rm -rf "$tmp"
}

test_codex_init_creates_config_files() {
    local tmp
    tmp="$(mktemp -d)"
    (
        cd "$tmp" || exit 1
        ZSH_TEST_MODE=1 source "$ROOT_DIR/modules/agents.zsh"
        codex_init --project demo --org siege --git-root "$tmp" --role "Senior DE" --approval on-request --sandbox workspace-write --yes >/dev/null
    )
    assert_true "[[ -f \"$tmp/AGENTS.md\" ]]" "codex_init should create AGENTS.md"
    assert_true "[[ -f \"$tmp/.codex/settings.local.json\" ]]" "codex_init should create settings file"
    assert_true "[[ -f \"$tmp/.codex/init.env\" ]]" "codex_init should create init state file"
    assert_contains "$(cat "$tmp/AGENTS.md")" "Senior DE" "AGENTS.md should include configured role"
    assert_contains "$(cat "$tmp/AGENTS.md")" "created with" "AGENTS.md should explicitly forbid created-with attribution phrasing"
    assert_contains "$(cat "$tmp/.codex/settings.local.json")" "\"approval_mode\": \"on-request\"" "settings should include approval mode"
    assert_contains "$(cat "$tmp/.codex/settings.local.json")" "\"forbid_created_with_phrasing\": true" "settings should enforce no created-with phrasing"
    rm -rf "$tmp"
}

test_ai_init_codex_only() {
    local tmp
    tmp="$(mktemp -d)"
    (
        cd "$tmp" || exit 1
        ZSH_TEST_MODE=1 source "$ROOT_DIR/modules/agents.zsh"
        ai_init --codex-only --project demo --org siege --git-root "$tmp" --yes >/dev/null
    )
    assert_true "[[ -f \"$tmp/AGENTS.md\" ]]" "ai_init --codex-only should create Codex config"
    assert_false "[[ -d \"$tmp/.claude\" ]]" "ai_init --codex-only should not run Claude init"
    rm -rf "$tmp"
}

test_codex_init_add_session() {
    local tmp
    tmp="$(mktemp -d)"
    (
        cd "$tmp" || exit 1
        export CODEX_SESSIONS_FILE="$tmp/codex-sessions.env"
        ZSH_TEST_MODE=1 source "$ROOT_DIR/modules/agents.zsh"
        codex_init --project demo --org siege --git-root "$tmp" --yes \
          --add-session --session-name demo_dev --session-desc "Demo workspace" >/dev/null
    )
    assert_true "[[ -f \"$tmp/codex-sessions.env\" ]]" "codex_init --add-session should create sessions file"
    assert_contains "$(cat "$tmp/codex-sessions.env")" "demo_dev=" "codex_init should add requested session key"
    assert_contains "$(cat "$tmp/codex-sessions.env")" "Demo workspace" "codex_init should include session description"
    rm -rf "$tmp"
}

test_codex_init_update_merges_rules_without_overwrite() {
    local tmp
    tmp="$(mktemp -d)"
    (
        cd "$tmp" || exit 1
        mkdir -p .codex
        cat > AGENTS.md <<'EOF'
# AGENTS.md

## Team Rules
- Keep custom team language unchanged.
EOF
        cat > .codex/settings.local.json <<'EOF'
{
  "defaults": {
    "role": "Custom Role"
  },
  "rules": {
    "custom_rule": true
  }
}
EOF
        ZSH_TEST_MODE=1 source "$ROOT_DIR/modules/agents.zsh"
        codex_init --project demo --org siege --git-root "$tmp" --update >/dev/null
    )
    assert_contains "$(cat "$tmp/AGENTS.md")" "Keep custom team language unchanged." "update should preserve custom AGENTS content"
    assert_contains "$(cat "$tmp/AGENTS.md")" "Never use phrases like \"created with\"" "update should add required no-attribution phrase rule"
    assert_contains "$(cat "$tmp/.codex/settings.local.json")" "\"custom_rule\": true" "update should preserve custom settings rules"
    assert_contains "$(cat "$tmp/.codex/settings.local.json")" "\"forbid_created_with_phrasing\": true" "update should enforce created-with prohibition"
    rm -rf "$tmp"
}

register_test "test_codex_session_crud" "test_codex_session_crud"
register_test "test_codex_session_auto_exec_non_interactive" "test_codex_session_auto_exec_non_interactive"
register_test "test_codex_session_non_interactive_show_only_by_default" "test_codex_session_non_interactive_show_only_by_default"
register_test "test_claude_session_crud" "test_claude_session_crud"
register_test "test_claude_session_auto_exec_non_interactive" "test_claude_session_auto_exec_non_interactive"
register_test "test_codex_init_creates_config_files" "test_codex_init_creates_config_files"
register_test "test_ai_init_codex_only" "test_ai_init_codex_only"
register_test "test_codex_init_add_session" "test_codex_init_add_session"
register_test "test_codex_init_update_merges_rules_without_overwrite" "test_codex_init_update_merges_rules_without_overwrite"
