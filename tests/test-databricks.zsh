#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/databricks.zsh"

# Tests use stubs and do not require real Databricks auth profiles.
_dbx_require_auth() {
    _dbx_require || return 1
    return 0
}

_make_databricks_stub() {
    local bin="$1"
    cat > "$bin/databricks" <<'SH'
#!/usr/bin/env zsh
set -e
if [[ -n "${DBX_ARGS_LOG:-}" ]]; then
  mkdir -p "$(dirname "$DBX_ARGS_LOG")" >/dev/null 2>&1 || true
  echo "$*" >> "$DBX_ARGS_LOG" 2>/dev/null || true
fi

cmd1="${1:-}"; cmd2="${2:-}"
if [[ "$cmd1" == "auth" && "$cmd2" == "profiles" ]]; then
  if [[ -n "${DBX_AUTH_PROFILES_JSON:-}" ]]; then
    printf '%s' "$DBX_AUTH_PROFILES_JSON"
  else
    printf '%s' '[{"name":"DEFAULT"}]'
  fi
  exit 0
fi

if [[ "$cmd1" == "clusters" && "$cmd2" == "list" ]]; then
  echo "clusters"
  exit 0
fi
if [[ "$cmd1" == "clusters" && "$cmd2" == "start" ]]; then
  echo "started ${3:-}"
  exit 0
fi
if [[ "$cmd1" == "clusters" && "$cmd2" == "stop" ]]; then
  echo "stopped ${3:-}"
  exit 0
fi

if [[ "$cmd1" == "jobs" && "$cmd2" == "list" ]]; then
  echo "jobs"
  exit 0
fi
if [[ "$cmd1" == "jobs" && "$cmd2" == "run-now" ]]; then
  echo "run ${3:-}"
  exit 0
fi

if [[ "$cmd1" == "workspace" && "$cmd2" == "list" ]]; then
  echo "workspace ${3:-/}"
  exit 0
fi

if [[ "$cmd1" == "repos" && "$cmd2" == "list" ]]; then
  if [[ -n "${DBX_REPOS_LIST_JSON:-}" ]]; then
    printf '%s' "$DBX_REPOS_LIST_JSON"
  else
    printf '%s' '[{"id":"7","path":"testrepo"}]'
  fi
  exit 0
fi
if [[ "$cmd1" == "repos" && "$cmd2" == "update" ]]; then
  echo "repo updated"
  exit 0
fi

if [[ "$cmd1" == "api" ]]; then
  method="$2"
  path="$3"
  if [[ "$method" == "get" && "$path" == "/api/2.0/lakebase/instances" ]]; then
    if [[ -n "${DBX_LAKEBASE_INSTANCES_JSON:-}" ]]; then
      printf '%s' "$DBX_LAKEBASE_INSTANCES_JSON"
    else
      printf '%s' '[{"id":"inst-1","name":"family","hostname":"lake.local"}]'
    fi
    exit 0
  fi
  if [[ "$method" == "get" && "$path" == "/api/2.0/lakebase/instances/inst-1" ]]; then
    printf '%s' '{"id":"inst-1","name":"family","hostname":"lake.local"}'
    exit 0
  fi
  if [[ "$method" == "get" && "$path" == "/api/2.0/lakebase/instances/inst-1/databases" ]]; then
    printf '%s' '{"databases":[{"name":"analytics"}]}'
    exit 0
  fi
  if [[ "$method" == "get" && "$path" == "/api/2.0/sql/warehouses" ]]; then
    printf '%s' '{"warehouses":[]}'
    exit 0
  fi
  if [[ "$method" == "post" && "$path" == "/api/2.0/lakebase/instances/inst-1/databases" ]]; then
    echo "created"
    exit 0
  fi
  if [[ "$method" == "delete" && "$path" == "/api/2.0/lakebase/instances/inst-1/databases/analytics" ]]; then
    echo "deleted"
    exit 0
  fi
fi

exit 1
SH
    chmod +x "$bin/databricks"
}

_make_psql_stub() {
    local bin="$1"
    cat > "$bin/psql" <<'SH'
#!/usr/bin/env zsh
[[ -n "${DBX_PSQL_LOG:-}" ]] && echo "$*" >> "$DBX_PSQL_LOG"
exit 0
SH
    chmod +x "$bin/psql"
}

test_dbx_profile_use_sets_env() {
    local old_profile="${DATABRICKS_CONFIG_PROFILE:-}"
    dbx_profile_use default >/dev/null
    assert_equal "default" "${DATABRICKS_CONFIG_PROFILE:-}" "dbx_profile_use should set DATABRICKS_CONFIG_PROFILE"
    export DATABRICKS_CONFIG_PROFILE="$old_profile"
}

test_dbx_clusters_list_invokes_cli() {
    local old_path="$PATH"
    local tmp="$(mktemp -d)"
    local bin="$tmp/bin"
    mkdir -p "$bin"
    _make_databricks_stub "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    export DATABRICKS_BIN="$bin/databricks"
    export DBX_AUTH_PROFILES_JSON='[{"name":"DEFAULT"}]'

    local out
    out="$(dbx_clusters_list 2>&1)"
    assert_contains "$out" "clusters" "dbx_clusters_list should call databricks clusters list"

    PATH="$old_path"
    rm -rf "$tmp"
}

test_dbx_lakebase_dbs_list_resolves_instance_name() {
    local old_path="$PATH"
    local tmp="$(mktemp -d)"
    local bin="$tmp/bin"
    local log="$tmp/args.log"
    mkdir -p "$bin"
    _make_databricks_stub "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    export DATABRICKS_BIN="$bin/databricks"
    export DBX_AUTH_PROFILES_JSON='[{"name":"DEFAULT"}]'
    export DBX_ARGS_LOG="$log"

    dbx_lakebase_dbs_list --instance family >/dev/null
    assert_contains "$(cat "$log")" "api get /api/2.0/lakebase/instances/inst-1/databases" "should resolve instance name to id"

    PATH="$old_path"
    rm -rf "$tmp"
}

test_dbx_lakebase_db_create_calls_api() {
    local old_path="$PATH"
    local tmp="$(mktemp -d)"
    local bin="$tmp/bin"
    local log="$tmp/args.log"
    mkdir -p "$bin"
    _make_databricks_stub "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    export DATABRICKS_BIN="$bin/databricks"
    export DBX_AUTH_PROFILES_JSON='[{"name":"DEFAULT"}]'
    export DBX_ARGS_LOG="$log"

    dbx_lakebase_db_create --instance family --db analytics >/dev/null
    assert_contains "$(cat "$log")" "api post /api/2.0/lakebase/instances/inst-1/databases --json {\"name\":\"analytics\"}" "should call create database endpoint"

    PATH="$old_path"
    rm -rf "$tmp"
}

test_dbx_lakebase_db_drop_requires_force() {
    assert_command_failure "dbx_lakebase_db_drop --instance family --db analytics >/dev/null 2>&1" "drop should require --force"
}

test_dbx_lakebase_db_drop_calls_api_with_force() {
    local old_path="$PATH"
    local tmp="$(mktemp -d)"
    local bin="$tmp/bin"
    local log="$tmp/args.log"
    mkdir -p "$bin"
    _make_databricks_stub "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    export DATABRICKS_BIN="$bin/databricks"
    export DBX_AUTH_PROFILES_JSON='[{"name":"DEFAULT"}]'
    export DBX_ARGS_LOG="$log"

    dbx_lakebase_db_drop --instance family --db analytics --force >/dev/null
    assert_contains "$(cat "$log")" "api delete /api/2.0/lakebase/instances/inst-1/databases/analytics" "drop should call delete endpoint"

    PATH="$old_path"
    rm -rf "$tmp"
}

test_dbx_lakebase_psql_uses_instance_host() {
    local old_path="$PATH"
    local tmp="$(mktemp -d)"
    local bin="$tmp/bin"
    local psql_log="$tmp/psql.log"
    mkdir -p "$bin"
    _make_databricks_stub "$bin"
    _make_psql_stub "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    export DATABRICKS_BIN="$bin/databricks"
    export DBX_AUTH_PROFILES_JSON='[{"name":"DEFAULT"}]'
    export DBX_PSQL_LOG="$psql_log"

    dbx_lakebase_psql --instance family --db analytics --user analyst >/dev/null
    assert_contains "$(cat "$psql_log")" "host=lake.local" "psql should target lakebase host"
    assert_contains "$(cat "$psql_log")" "dbname=analytics" "psql should target requested db"
    assert_contains "$(cat "$psql_log")" "user=analyst" "psql should use requested user"

    PATH="$old_path"
    rm -rf "$tmp"
}

register_test "dbx_profile_use_sets_env" test_dbx_profile_use_sets_env
register_test "dbx_clusters_list_invokes_cli" test_dbx_clusters_list_invokes_cli
register_test "dbx_lakebase_dbs_list_resolves_instance_name" test_dbx_lakebase_dbs_list_resolves_instance_name
register_test "dbx_lakebase_db_create_calls_api" test_dbx_lakebase_db_create_calls_api
register_test "dbx_lakebase_db_drop_requires_force" test_dbx_lakebase_db_drop_requires_force
register_test "dbx_lakebase_db_drop_calls_api_with_force" test_dbx_lakebase_db_drop_calls_api_with_force
register_test "dbx_lakebase_psql_uses_instance_host" test_dbx_lakebase_psql_uses_instance_host
