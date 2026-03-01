#!/usr/bin/env zsh
# =================================================================
# DATABRICKS - Databricks + Lakebase workflows
# =================================================================

_dbx_usage() {
    echo "Usage:"
    echo "  dbx_preflight [--json]"
    echo "  dbx_ops <status|run|logs|diag> [options]"
    echo "  dbx_auth_status"
    echo "  dbx_profiles_list"
    echo "  dbx_profile_use <profile> [--persist]"
    echo "  dbx_clusters_list"
    echo "  dbx_cluster_start <cluster_id>"
    echo "  dbx_cluster_stop <cluster_id>"
    echo "  dbx_jobs_list"
    echo "  dbx_job_run_now <job_id>"
    echo "  dbx_workspace_ls [path]"
    echo "  dbx_repos_sync [repo_path]"
    echo "  dbx_sql_warehouses_list"
    echo "  dbx_lakebase_instances_list"
    echo "  dbx_lakebase_dbs_list --instance <id_or_name>"
    echo "  dbx_lakebase_db_create --instance <id_or_name> --db <name>"
    echo "  dbx_lakebase_db_drop --instance <id_or_name> --db <name> [--force]"
    echo "  dbx_lakebase_psql --instance <id_or_name> --db <name> [--user <u>]"
    echo "  dbx_lakebase_health --instance <id_or_name>"
}

_dbx_fail() {
    local failure_class="$1"
    local message="$2"
    local hint="${3:-}"
    echo "❌ [$failure_class] $message" >&2
    [[ -n "$hint" ]] && echo "   hint: $hint" >&2
    return 1
}

_dbx_require() {
    local bin="${DATABRICKS_BIN:-databricks}"
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo "❌ databricks CLI not found" >&2
        return 1
    fi
    return 0
}

_dbx_profiles_json() {
    _dbx_exec auth profiles --output json 2>/dev/null || true
}

_dbx_exec() {
    local bin="${DATABRICKS_BIN:-databricks}"
    "$bin" "$@"
}

_dbx_require_auth() {
    _dbx_require || return 1
    local profiles
    profiles="$(_dbx_profiles_json)"
    [[ -n "$profiles" && "$profiles" != "[]" ]] || {
        echo "❌ Databricks auth required (run: databricks auth login --host <workspace-url>)" >&2
        return 1
    }
    return 0
}

_dbx_json_extract() {
    local expr="$1"
    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    "$py" -c "import json,sys; data=json.load(sys.stdin); print($expr)"
}

_dbx_lakebase_resolve_instance_id() {
    local key="$1"
    local instances_json
    instances_json="$(dbx_lakebase_instances_list --json 2>/dev/null || true)"
    [[ -n "$instances_json" ]] || return 1

    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    printf '%s' "$instances_json" | "$py" -c 'import json,sys
needle=sys.argv[1].strip().lower()
obj=json.load(sys.stdin)
items=obj if isinstance(obj,list) else obj.get("instances",[])
for it in items:
    iid=str(it.get("id") or it.get("instance_id") or "")
    name=str(it.get("name") or "")
    if needle and (needle==iid.lower() or needle==name.lower()):
        print(iid)
        raise SystemExit(0)
if needle:
    print(needle)
' "$key"
}

_dbx_profile_persist() {
    local profile="$1"
    if typeset -f settings_persist_var >/dev/null 2>&1; then
        settings_persist_var "DATABRICKS_CONFIG_PROFILE" "$profile"
        return $?
    fi
    return 1
}

dbx_auth_status() {
    _dbx_require || return 1
    _dbx_exec auth profiles
}

dbx_preflight() {
    local mode="text"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json) mode="json"; shift ;;
            --help|-h)
                echo "Usage: dbx_preflight [--json]" >&2
                return 0
                ;;
            *)
                echo "Usage: dbx_preflight [--json]" >&2
                return 1
                ;;
        esac
    done

    local cli_ok=1 auth_ok=1 api_ok=1 rc=0
    local cli_msg="ok" auth_msg="ok" api_msg="ok"

    if ! _dbx_require >/dev/null 2>&1; then
        cli_ok=0
        auth_ok=0
        api_ok=0
        rc=1
        cli_msg="databricks CLI not found"
        auth_msg="skipped (cli unavailable)"
        api_msg="skipped (cli unavailable)"
    else
        local profiles
        profiles="$(_dbx_profiles_json)"
        if [[ -z "$profiles" || "$profiles" == "[]" ]]; then
            auth_ok=0
            api_ok=0
            rc=1
            auth_msg="no authenticated profiles"
            api_msg="skipped (auth unavailable)"
        else
            if ! _dbx_exec api get /api/2.0/sql/warehouses >/dev/null 2>&1; then
                api_ok=0
                rc=1
                api_msg="workspace/API reachability failed"
            fi
        fi
    fi

    if [[ "$mode" == "json" ]]; then
        printf '{"ok":%s,"checks":{"cli":{"ok":%s,"message":"%s"},"auth":{"ok":%s,"message":"%s"},"api":{"ok":%s,"message":"%s"}}}\n' \
            "$([[ "$rc" -eq 0 ]] && echo true || echo false)" \
            "$([[ "$cli_ok" -eq 1 ]] && echo true || echo false)" "$cli_msg" \
            "$([[ "$auth_ok" -eq 1 ]] && echo true || echo false)" "$auth_msg" \
            "$([[ "$api_ok" -eq 1 ]] && echo true || echo false)" "$api_msg"
        return "$rc"
    fi

    echo "🔎 Databricks Preflight"
    echo "======================="
    [[ "$cli_ok" -eq 1 ]] && echo "✅ cli: $cli_msg" || _dbx_fail "DBX_CLI_MISSING" "$cli_msg" "install Databricks CLI and ensure it is on PATH"
    [[ "$auth_ok" -eq 1 ]] && echo "✅ auth: $auth_msg" || _dbx_fail "DBX_AUTH_REQUIRED" "$auth_msg" "run: databricks auth login --host <workspace-url>"
    [[ "$api_ok" -eq 1 ]] && echo "✅ api: $api_msg" || _dbx_fail "DBX_API_UNREACHABLE" "$api_msg" "verify host/profile and network reachability"
    return "$rc"
}

dbx_profiles_list() {
    _dbx_require || return 1
    _dbx_exec auth profiles
}

dbx_profile_use() {
    local profile="${1:-}"
    local persist=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --persist) persist=1; shift ;;
            *)
                if [[ -z "$profile" || "$profile" == "$1" ]]; then
                    profile="$1"
                fi
                shift
                ;;
        esac
    done
    [[ -n "$profile" ]] || { echo "Usage: dbx_profile_use <profile> [--persist]" >&2; return 1; }

    export DATABRICKS_CONFIG_PROFILE="$profile"
    echo "✅ Databricks profile active in shell: $profile"

    if [[ "$persist" -eq 1 ]]; then
        if _dbx_profile_persist "$profile"; then
            echo "✅ Persisted DATABRICKS_CONFIG_PROFILE in vars.env"
        else
            echo "⚠️  Could not persist profile automatically; set in vars.env manually" >&2
        fi
    fi
}

dbx_clusters_list() {
    _dbx_require_auth || return 1
    _dbx_exec clusters list
}

dbx_cluster_start() {
    local cluster_id="${1:-}"
    [[ -n "$cluster_id" ]] || { echo "Usage: dbx_cluster_start <cluster_id>" >&2; return 1; }
    _dbx_require_auth || return 1
    _dbx_exec clusters start "$cluster_id"
}

dbx_cluster_stop() {
    local cluster_id="${1:-}"
    [[ -n "$cluster_id" ]] || { echo "Usage: dbx_cluster_stop <cluster_id>" >&2; return 1; }
    _dbx_require_auth || return 1
    _dbx_exec clusters stop "$cluster_id"
}

dbx_jobs_list() {
    _dbx_require_auth || return 1
    _dbx_exec jobs list
}

dbx_job_run_now() {
    local job_id="${1:-}"
    [[ -n "$job_id" ]] || { echo "Usage: dbx_job_run_now <job_id>" >&2; return 1; }
    _dbx_require_auth || return 1
    _dbx_exec jobs run-now "$job_id"
}

dbx_workspace_ls() {
    local path="${1:-/}"
    _dbx_require_auth || return 1
    _dbx_exec workspace list "$path"
}

dbx_repos_sync() {
    local repo_path="${1:-$PWD}"
    _dbx_require_auth || return 1

    local branch
    branch="$(git -C "$repo_path" branch --show-current 2>/dev/null || true)"
    [[ -n "$branch" ]] || branch="main"

    local repos_json py repo_id
    repos_json="$(_dbx_exec repos list --output json 2>/dev/null || true)"
    [[ -n "$repos_json" ]] || { echo "❌ Unable to list Databricks repos" >&2; return 1; }

    py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    repo_id="$(printf '%s' "$repos_json" | "$py" -c 'import json,sys,os
needle=os.path.abspath(sys.argv[1])
obj=json.load(sys.stdin)
items=obj if isinstance(obj,list) else obj.get("repos",[])
for it in items:
    p=it.get("path") or ""
    if p and (p==needle or p.endswith(os.path.basename(needle))):
        print(it.get("id") or it.get("repo_id") or "")
        raise SystemExit(0)
' "$repo_path")"

    [[ -n "$repo_id" ]] || { echo "❌ No Databricks repo found matching path: $repo_path" >&2; return 1; }
    _dbx_exec repos update "$repo_id" --branch "$branch"
}

dbx_sql_warehouses_list() {
    _dbx_require_auth || return 1
    _dbx_exec api get /api/2.0/sql/warehouses
}

dbx_lakebase_instances_list() {
    _dbx_require_auth || return 1
    if [[ "${1:-}" == "--json" ]]; then
        _dbx_exec api get /api/2.0/lakebase/instances
    else
        _dbx_exec api get /api/2.0/lakebase/instances | _dbx_json_extract 'json.dumps(data, indent=2)'
    fi
}

dbx_lakebase_dbs_list() {
    local instance=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --instance) instance="${2:-}"; shift 2 ;;
            --help|-h) _dbx_usage; return 0 ;;
            *) _dbx_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$instance" ]] || { echo "Usage: dbx_lakebase_dbs_list --instance <id_or_name>" >&2; return 1; }

    _dbx_require_auth || return 1
    local instance_id
    instance_id="$(_dbx_lakebase_resolve_instance_id "$instance")"
    _dbx_exec api get "/api/2.0/lakebase/instances/${instance_id}/databases"
}

dbx_lakebase_db_create() {
    local instance=""
    local db=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --instance) instance="${2:-}"; shift 2 ;;
            --db) db="${2:-}"; shift 2 ;;
            --help|-h) _dbx_usage; return 0 ;;
            *) _dbx_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$instance" && -n "$db" ]] || { echo "Usage: dbx_lakebase_db_create --instance <id_or_name> --db <name>" >&2; return 1; }

    _dbx_require_auth || return 1
    local instance_id
    instance_id="$(_dbx_lakebase_resolve_instance_id "$instance")"
    _dbx_exec api post "/api/2.0/lakebase/instances/${instance_id}/databases" --json "{\"name\":\"${db}\"}"
}

dbx_lakebase_db_drop() {
    local instance=""
    local db=""
    local force=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --instance) instance="${2:-}"; shift 2 ;;
            --db) db="${2:-}"; shift 2 ;;
            --force) force=1; shift ;;
            --help|-h) _dbx_usage; return 0 ;;
            *) _dbx_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$instance" && -n "$db" ]] || { echo "Usage: dbx_lakebase_db_drop --instance <id_or_name> --db <name> [--force]" >&2; return 1; }

    if [[ "$force" -ne 1 ]]; then
        echo "Refusing destructive drop without --force" >&2
        return 1
    fi

    _dbx_require_auth || return 1
    local instance_id
    instance_id="$(_dbx_lakebase_resolve_instance_id "$instance")"
    _dbx_exec api delete "/api/2.0/lakebase/instances/${instance_id}/databases/${db}"
}

dbx_lakebase_psql() {
    local instance=""
    local db=""
    local user="${USER:-databricks}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --instance) instance="${2:-}"; shift 2 ;;
            --db) db="${2:-}"; shift 2 ;;
            --user) user="${2:-}"; shift 2 ;;
            --help|-h) _dbx_usage; return 0 ;;
            *) _dbx_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$instance" && -n "$db" ]] || { echo "Usage: dbx_lakebase_psql --instance <id_or_name> --db <name> [--user <u>]" >&2; return 1; }

    if ! command -v psql >/dev/null 2>&1; then
        echo "❌ psql not found" >&2
        return 1
    fi

    _dbx_require_auth || return 1
    local instance_id host
    instance_id="$(_dbx_lakebase_resolve_instance_id "$instance")"

    host="$(_dbx_exec api get "/api/2.0/lakebase/instances/${instance_id}" | _dbx_json_extract 'data.get("hostname") or data.get("host") or ""')"
    [[ -n "$host" ]] || { echo "❌ Could not resolve Lakebase host for instance: $instance" >&2; return 1; }

    psql "host=${host} dbname=${db} user=${user}"
}

dbx_lakebase_health() {
    local instance=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --instance) instance="${2:-}"; shift 2 ;;
            --help|-h) _dbx_usage; return 0 ;;
            *) _dbx_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$instance" ]] || { echo "Usage: dbx_lakebase_health --instance <id_or_name>" >&2; return 1; }

    _dbx_require_auth || return 1
    local instance_id
    instance_id="$(_dbx_lakebase_resolve_instance_id "$instance")"

    echo "🔎 Lakebase health"
    echo "=================="
    _dbx_exec api get "/api/2.0/lakebase/instances/${instance_id}"
    echo
    _dbx_exec api get "/api/2.0/lakebase/instances/${instance_id}/databases"
}

dbx_ops() {
    local op="${1:-}"
    shift || true
    case "$op" in
        status)
            dbx_preflight || return 1
            echo ""
            dbx_auth_status
            ;;
        run)
            local job_id=""
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --job) job_id="${2:-}"; shift 2 ;;
                    *) echo "Usage: dbx_ops run --job <job_id>" >&2; return 1 ;;
                esac
            done
            [[ -n "$job_id" ]] || { echo "Usage: dbx_ops run --job <job_id>" >&2; return 1; }
            dbx_preflight || return 1
            dbx_job_run_now "$job_id"
            ;;
        logs)
            local run_id=""
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --run-id) run_id="${2:-}"; shift 2 ;;
                    *) echo "Usage: dbx_ops logs --run-id <run_id>" >&2; return 1 ;;
                esac
            done
            [[ -n "$run_id" ]] || { echo "Usage: dbx_ops logs --run-id <run_id>" >&2; return 1; }
            dbx_preflight || return 1
            _dbx_exec jobs get-run "$run_id"
            ;;
        diag)
            local instance=""
            while [[ $# -gt 0 ]]; do
                case "$1" in
                    --instance) instance="${2:-}"; shift 2 ;;
                    *) echo "Usage: dbx_ops diag [--instance <id_or_name>]" >&2; return 1 ;;
                esac
            done
            dbx_preflight || return 1
            echo ""
            dbx_sql_warehouses_list || true
            if [[ -n "$instance" ]]; then
                echo ""
                dbx_lakebase_health --instance "$instance"
            fi
            ;;
        --help|-h|"")
            _dbx_usage
            return 0
            ;;
        *)
            echo "Unknown dbx_ops command: $op" >&2
            _dbx_usage >&2
            return 1
            ;;
    esac
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ databricks loaded"
fi
