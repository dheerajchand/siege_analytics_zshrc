#!/usr/bin/env zsh
# =================================================================
# DATABRICKS - Databricks + Lakebase workflows
# =================================================================

_dbx_usage() {
    echo "Usage:"
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

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ databricks loaded"
fi
