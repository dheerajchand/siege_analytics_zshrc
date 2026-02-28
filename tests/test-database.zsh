#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/database.zsh"

_make_stub_psql() {
    local bin_dir="$1"
    cat > "$bin_dir/psql" <<'PSQL'
#!/usr/bin/env zsh
if [[ "$1" == "--version" ]]; then
    echo "psql (PostgreSQL) 15.0"
    exit 0
fi
if [[ "$1" == "-c" ]]; then
    echo "PostgreSQL 15.0 on stub"
    exit 0
fi
exit 0
PSQL
    chmod +x "$bin_dir/psql"
}

test_pg_test_connection_success() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_psql "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    out="$(pg_test_connection 2>&1)"
    assert_contains "$out" "Connection successful" "pg_test_connection should pass with stub"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_database_status_with_stub() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_psql "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    out="$(database_status 2>&1)"
    assert_contains "$out" "psql: 15.0" "database_status should show psql version"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_database_default_pg_user_from_default_var() {
    local out
    out="$(DEFAULT_PG_USER='pg_owner' PGUSER='' ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/database.zsh >/dev/null; echo \$PGUSER")"
    assert_equal "pg_owner" "$out" "PGUSER should default to DEFAULT_PG_USER when PGUSER is unset"
}

test_database_default_pg_user_falls_back_to_shell_user() {
    local out
    out="$(DEFAULT_PG_USER='' PGUSER='' ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/database.zsh >/dev/null; echo \$PGUSER")"
    assert_equal "$USER" "$out" "PGUSER should fallback to current shell user when DEFAULT_PG_USER is unset"
}

register_test "database_pg_test" test_pg_test_connection_success
register_test "database_status" test_database_status_with_stub
register_test "database_default_pg_user_from_default_var" test_database_default_pg_user_from_default_var
register_test "database_default_pg_user_falls_back_to_shell_user" test_database_default_pg_user_falls_back_to_shell_user
