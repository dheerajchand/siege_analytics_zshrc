#!/usr/bin/env zsh
# =================================================================
# SYSTEM DIAGNOSTICS & REPAIR
# =================================================================

_run_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "$seconds" "$@"
        return $?
    fi
    if command -v gtimeout >/dev/null 2>&1; then
        gtimeout "$seconds" "$@"
        return $?
    fi
    if command -v perl >/dev/null 2>&1; then
        perl -e 'alarm shift; exec @ARGV' "$seconds" "$@"
        return $?
    fi
    "$@"
}

_is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

_icloud_js_is_suspect_name() {
    local name="$1"
    [[ -z "$name" ]] && return 1
    case "$name" in
        .*) return 1 ;;
        Desktop|Documents|Downloads|Library|Movies|Music|Pictures|Public|Applications|__pycache__|Kung\ Fu|Oddities)
            return 1
            ;;
    esac
    if [[ "$name" == @* ]]; then
        return 0
    fi
    # Heuristic: npm-style package names
    if [[ "$name" =~ '^[a-z0-9._-]+$' && "$name" == *[a-z]* ]]; then
        return 0
    fi
    return 1
}

_icloud_js_collect_suspects() {
    local root="$1"
    [[ -d "$root" ]] || return 1
    local d base
    for d in "$root"/*(N/); do
        base="${d:t}"
        if _icloud_js_is_suspect_name "$base"; then
            printf '%s\n' "$d"
        fi
    done
}

data_platform_health() {
    local rc=0
    local ran=0
    echo "🧪 Data Platform Health"
    echo "======================"
    if typeset -f spark_health >/dev/null 2>&1; then
        ran=1
        spark_health || rc=1
        echo ""
    else
        echo "⚠️  spark_health not available (spark module not loaded)"
        rc=1
    fi
    if typeset -f hadoop_health >/dev/null 2>&1; then
        ran=1
        hadoop_health || rc=1
        echo ""
    else
        echo "⚠️  hadoop_health not available (hadoop module not loaded)"
        rc=1
    fi
    if typeset -f yarn_health >/dev/null 2>&1; then
        ran=1
        yarn_health || rc=1
        echo ""
    fi
    if [[ "$ran" -eq 0 ]]; then
        echo "⚠️  No health checks available"
        return 1
    fi
    return "$rc"
}

data_platform_config_status() {
    local rc=0
    local ran=0
    echo "⚙️  Data Platform Configuration"
    echo "=============================="
    if typeset -f spark_config_status >/dev/null 2>&1; then
        ran=1
        spark_config_status || rc=1
        if typeset -f spark_validate_versions >/dev/null 2>&1; then
            spark_validate_versions || rc=1
        fi
        echo ""
    else
        echo "⚠️  spark_config_status not available (spark module not loaded)"
        rc=1
    fi
    if typeset -f hadoop_config_status >/dev/null 2>&1; then
        ran=1
        hadoop_config_status || rc=1
        echo ""
    else
        echo "⚠️  hadoop_config_status not available (hadoop module not loaded)"
        rc=1
    fi
    if typeset -f python_config_status >/dev/null 2>&1; then
        ran=1
        python_config_status || rc=1
    else
        echo "⚠️  python_config_status not available (python module not loaded)"
        rc=1
    fi
    if typeset -f stack_profile_status >/dev/null 2>&1; then
        ran=1
        echo ""
        stack_profile_status || rc=1
    fi
    if typeset -f stack_validate_versions >/dev/null 2>&1; then
        ran=1
        stack_validate_versions || rc=1
    fi
    if typeset -f zeppelin_config_status >/dev/null 2>&1; then
        ran=1
        echo ""
        zeppelin_config_status || rc=1
    else
        echo "⚠️  zeppelin_config_status not available (zeppelin module not loaded)"
        rc=1
    fi
    if typeset -f livy_status >/dev/null 2>&1; then
        ran=1
        echo ""
        livy_status || rc=1
    fi
    if [[ "$ran" -eq 0 ]]; then
        echo "⚠️  No configuration checks available"
        return 1
    fi
    return "$rc"
}

spark41_route_health() {
    local run_spark_smoke=0
    local spark_master_override=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --spark-smoke)
                run_spark_smoke=1
                shift
                ;;
            --master)
                spark_master_override="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: spark41_route_health [--spark-smoke] [--master <spark-master>]" >&2
                return 0
                ;;
            *)
                echo "Usage: spark41_route_health [--spark-smoke] [--master <spark-master>]" >&2
                return 1
                ;;
        esac
    done

    local rc=0
    echo "🧪 Spark 4.1 Route Health"
    echo "========================="

    if typeset -f stack_validate_versions >/dev/null 2>&1; then
        stack_validate_versions --component zeppelin || rc=1
    else
        echo "⚠️  stack_validate_versions not available"
        rc=1
    fi
    echo ""

    if typeset -f spark_mode_status >/dev/null 2>&1; then
        spark_mode_status || rc=1
    else
        echo "⚠️  spark_mode_status not available"
        rc=1
    fi
    if typeset -f spark_workers_health >/dev/null 2>&1; then
        echo ""
        spark_workers_health || rc=1
    else
        echo "⚠️  spark_workers_health not available"
        rc=1
    fi
    echo ""

    if typeset -f zeppelin_integration_status >/dev/null 2>&1; then
        zeppelin_integration_status || rc=1
        if [[ "${ZEPPELIN_SPARK_INTEGRATION_MODE:-external}" != "external" ]]; then
            echo "⚠️  For Spark 4.1, preferred Zeppelin mode is external."
            rc=1
        fi
    else
        echo "⚠️  zeppelin_integration_status not available"
        rc=1
    fi
    echo ""

    if typeset -f zeppelin_status >/dev/null 2>&1; then
        zeppelin_status || rc=1
    else
        echo "⚠️  zeppelin_status not available"
        rc=1
    fi

    if (( run_spark_smoke )); then
        echo ""
        echo "🚀 Running Spark local smoke test..."
        if ! command -v spark-submit >/dev/null 2>&1; then
            echo "❌ spark-submit not found"
            rc=1
        else
            local smoke_file
            smoke_file="$(mktemp /tmp/spark41-route-health.XXXXXX.py)"
            cat > "$smoke_file" <<'PY'
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("spark41-route-health").getOrCreate()
print("SPARK_VERSION=" + spark.version)
print("ROW_COUNT=" + str(spark.range(1, 6).count()))
spark.stop()
PY
            local smoke_master="${spark_master_override:-${SPARK_LOCAL_MASTER:-local[*]}}"
            if spark-submit --master "$smoke_master" "$smoke_file"; then
                echo "✅ Spark smoke test passed using master=$smoke_master"
            else
                echo "❌ Spark smoke test failed using master=$smoke_master"
                rc=1
            fi
            rm -f "$smoke_file"
        fi

        if typeset -f spark_workers_health >/dev/null 2>&1; then
            echo ""
            echo "🚀 Running Spark worker probe with Sedona/GraphFrames checks..."
            if [[ -n "$spark_master_override" ]]; then
                spark_workers_health --probe --with-packages --master "$spark_master_override" || rc=1
            else
                spark_workers_health --probe --with-packages || rc=1
            fi
        fi
    fi

    return "$rc"
}

data_platform_use_versions() {
    local spark="" hadoop="" scala="" java="" pyenv=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --spark) spark="$2"; shift 2 ;;
            --hadoop) hadoop="$2"; shift 2 ;;
            --scala) scala="$2"; shift 2 ;;
            --java) java="$2"; shift 2 ;;
            --pyenv) pyenv="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: data_platform_use_versions [--spark v] [--hadoop v] [--scala v] [--java v] [--pyenv v]" >&2
                return 0
                ;;
            *)
                echo "Usage: data_platform_use_versions [--spark v] [--hadoop v] [--scala v] [--java v] [--pyenv v]" >&2
                return 1
                ;;
        esac
    done
    local rc=0
    [[ -n "$spark" ]] && typeset -f spark_use_version >/dev/null 2>&1 && spark_use_version "$spark" || true
    [[ -n "$hadoop" ]] && typeset -f hadoop_use_version >/dev/null 2>&1 && hadoop_use_version "$hadoop" || true
    [[ -n "$scala" ]] && typeset -f scala_use_version >/dev/null 2>&1 && scala_use_version "$scala" || true
    [[ -n "$java" ]] && typeset -f java_use_version >/dev/null 2>&1 && java_use_version "$java" || true
    [[ -n "$pyenv" ]] && typeset -f pyenv_use_version >/dev/null 2>&1 && pyenv_use_version "$pyenv" || true
    return "$rc"
}

data_platform_default_versions() {
    local spark="" hadoop="" scala="" java="" pyenv=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --spark) spark="$2"; shift 2 ;;
            --hadoop) hadoop="$2"; shift 2 ;;
            --scala) scala="$2"; shift 2 ;;
            --java) java="$2"; shift 2 ;;
            --pyenv) pyenv="$2"; shift 2 ;;
            --help|-h)
                echo "Usage: data_platform_default_versions [--spark v] [--hadoop v] [--scala v] [--java v] [--pyenv v]" >&2
                return 0
                ;;
            *)
                echo "Usage: data_platform_default_versions [--spark v] [--hadoop v] [--scala v] [--java v] [--pyenv v]" >&2
                return 1
                ;;
        esac
    done
    local rc=0
    [[ -n "$spark" ]] && typeset -f spark_default_version >/dev/null 2>&1 && spark_default_version "$spark" || true
    [[ -n "$hadoop" ]] && typeset -f hadoop_default_version >/dev/null 2>&1 && hadoop_default_version "$hadoop" || true
    [[ -n "$scala" ]] && typeset -f scala_default_version >/dev/null 2>&1 && scala_default_version "$scala" || true
    [[ -n "$java" ]] && typeset -f java_default_version >/dev/null 2>&1 && java_default_version "$java" || true
    [[ -n "$pyenv" ]] && typeset -f pyenv_default_version >/dev/null 2>&1 && pyenv_default_version "$pyenv" || true
    return "$rc"
}

icloud_status() {
    if ! _is_macos; then
        echo "iCloud diagnostics are macOS-only."
        return 1
    fi
    echo "==== brctl status com.apple.CloudDocs ===="
    if command -v brctl >/dev/null 2>&1; then
        _run_with_timeout 8 brctl status com.apple.CloudDocs || true
    else
        echo "brctl not found"
    fi
    echo ""
    echo "==== fileproviderctl dump -l ===="
    if command -v fileproviderctl >/dev/null 2>&1; then
        _run_with_timeout 8 fileproviderctl dump -l || true
    else
        echo "fileproviderctl not found"
    fi
}

icloud_logs() {
    if ! _is_macos; then
        echo "iCloud diagnostics are macOS-only."
        return 1
    fi
    echo "==== CloudDocs/FileProvider logs (last 2m) ===="
    if [[ -x /usr/bin/log ]]; then
        /usr/bin/log show --last 2m --style compact \
            --predicate '(subsystem CONTAINS "com.apple.CloudDocs") || (subsystem CONTAINS "com.apple.FileProvider")' \
            | tail -n 200
    else
        echo "/usr/bin/log not found"
    fi
}

icloud_snapshot() {
    if ! _is_macos; then
        echo "iCloud diagnostics are macOS-only."
        return 1
    fi
    local ts out
    ts="$(date +%Y%m%d-%H%M%S)"
    out="${1:-$HOME/Library/Logs/icloud_snapshot_${ts}.txt}"
    {
        echo "Snapshot: $ts"
        icloud_status
    } > "$out"
    echo "Wrote $out"
}

icloud_preflight() {
    if ! _is_macos; then
        echo "iCloud diagnostics are macOS-only."
        return 1
    fi
    local status
    if ! command -v brctl >/dev/null 2>&1; then
        echo "Preflight: brctl not found; cannot detect active iCloud sync."
        return 0
    fi
    status="$(_run_with_timeout 6 brctl status com.apple.CloudDocs 2>/dev/null || true)"
    if [[ -z "$status" ]]; then
        echo "Preflight: no brctl status output; assuming idle."
        return 0
    fi
    if command -v rg >/dev/null 2>&1; then
        echo "$status" | rg -q "needs-sync|in-sync-down|upload progress|download progress" && {
            echo "Preflight: iCloud activity detected."
            return 1
        }
    else
        echo "$status" | grep -Eq "needs-sync|in-sync-down|upload progress|download progress" && {
            echo "Preflight: iCloud activity detected."
            return 1
        }
    fi
    echo "Preflight: no active sync indicators detected."
    return 0
}

icloud_js_guard() {
    local fix=0
    local assume_yes=0
    local root="${ICLOUD_CLOUDDOCS_ROOT:-$HOME/Library/Mobile Documents/com~apple~CloudDocs}"
    local quarantine_base="${ICLOUD_JS_QUARANTINE_BASE:-$HOME/Documents/iCloud_js_quarantine}"
    local -a suspects
    local p

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix) fix=1; shift ;;
            --yes|-y) assume_yes=1; shift ;;
            --root) root="${2:-}"; shift 2 ;;
            --quarantine) quarantine_base="${2:-}"; shift 2 ;;
            --help|-h)
                cat <<'HELP'
Usage: icloud_js_guard [--fix] [--yes] [--root <clouddocs_root>] [--quarantine <dir>]

Scans iCloud Drive root for npm-like package directories accidentally created there.
Default mode is report-only. Use --fix to move suspects into a quarantine folder.
HELP
                return 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    if [[ ! -d "$root" ]]; then
        echo "❌ iCloud root not found: $root"
        return 1
    fi

    while IFS= read -r p; do
        [[ -n "$p" ]] && suspects+=("$p")
    done < <(_icloud_js_collect_suspects "$root")

    local count="${#suspects[@]}"
    if [[ "$count" -eq 0 ]]; then
        echo "✅ iCloud JS guard: no suspicious package directories found."
        return 0
    fi

    echo "⚠️  iCloud JS guard: found $count suspicious directories in:"
    echo "   $root"
    local shown=0
    for p in "${suspects[@]}"; do
        echo "   - ${p:t}"
        shown=$((shown + 1))
        [[ "$shown" -ge 20 ]] && break
    done
    if [[ "$count" -gt 20 ]]; then
        echo "   ... and $((count - 20)) more"
    fi

    if [[ "$fix" -ne 1 ]]; then
        echo "Run with --fix to quarantine them."
        return 1
    fi

    if [[ "$assume_yes" -ne 1 ]]; then
        read -r "REPLY?Move these directories to quarantine? [y/N] "
        [[ "$REPLY" =~ ^[Yy]$ ]] || {
            echo "Cancelled."
            return 1
        }
    fi

    local ts qdir log
    ts="$(date +%Y%m%d_%H%M%S)"
    qdir="$quarantine_base/$ts"
    log="$qdir/move_log.tsv"
    mkdir -p "$qdir"
    : > "$log"

    local moved=0
    local src base dst i
    for src in "${suspects[@]}"; do
        base="${src:t}"
        dst="$qdir/$base"
        i=1
        while [[ -e "$dst" ]]; do
            dst="$qdir/${base}__${i}"
            i=$((i + 1))
        done
        if mv "$src" "$dst"; then
            printf '%s\t%s\n' "$src" "$dst" >> "$log"
            moved=$((moved + 1))
        fi
    done

    echo "✅ Quarantined $moved directories"
    echo "   Quarantine: $qdir"
    echo "   Move log:   $log"
}

icloud_js_restore() {
    local log_file="${1:-}"
    if [[ -z "$log_file" ]]; then
        echo "Usage: icloud_js_restore <move_log.tsv>" >&2
        return 1
    fi
    if [[ ! -f "$log_file" ]]; then
        echo "❌ Move log not found: $log_file" >&2
        return 1
    fi

    local src dst restored=0
    while IFS=$'\t' read -r src dst || [[ -n "${src:-}" ]]; do
        [[ -z "${src:-}" || -z "${dst:-}" ]] && continue
        if [[ -e "$dst" ]]; then
            mv "$dst" "$src"
            restored=$((restored + 1))
        fi
    done < "$log_file"
    echo "✅ Restored $restored directories from quarantine"
}

icloud_reset_state() {
    if ! _is_macos; then
        echo "iCloud diagnostics are macOS-only."
        return 1
    fi
    local ts
    local force="false"
    if [[ "${1:-}" == "--force" ]]; then
        force="true"
        shift
    fi
    ts="$(date +%Y%m%d-%H%M%S)"
    if [[ -z "${PS1:-}" ]]; then
        echo "Refusing to run in non-interactive shell."
        return 1
    fi
    if [[ ! -d "$HOME/Library/Application Support/FileProvider" ]] && \
       [[ ! -d "$HOME/Library/Application Support/CloudDocs" ]]; then
        echo "No FileProvider/CloudDocs state found to move."
        return 1
    fi
    echo "This will move FileProvider/CloudDocs state to .bak.$ts and restart daemons."
    echo "Any active iCloud sync will be interrupted and require re-sync."
    if [[ "$force" != "true" ]]; then
        if ! icloud_preflight; then
            echo "Preflight failed. Re-run with --force to proceed anyway."
            return 1
        fi
    fi
    read -r "REPLY?Proceed? [y/N] "
    [[ "$REPLY" =~ ^[Yy]$ ]] || { echo "Cancelled"; return 1; }
    if [[ -d "$HOME/Library/Application Support/FileProvider" ]]; then
        mv "$HOME/Library/Application Support/FileProvider" \
            "$HOME/Library/Application Support/FileProvider.bak.$ts"
    fi
    if [[ -d "$HOME/Library/Application Support/CloudDocs" ]]; then
        mv "$HOME/Library/Application Support/CloudDocs" \
            "$HOME/Library/Application Support/CloudDocs.bak.$ts"
    fi
    killall bird cloudd fileproviderd Finder >/dev/null 2>&1 || true
    echo "Reset complete. Backups created with suffix .bak.$ts"
}

dropbox_status() {
    if ! _is_macos; then
        echo "Dropbox diagnostics are macOS-only."
        return 1
    fi
    local db_path
    db_path="$HOME/Library/CloudStorage/Dropbox"
    echo "==== Dropbox folder ===="
    if [[ -d "$db_path" ]]; then
        ls -ld "$db_path"
    else
        echo "Missing: $db_path"
    fi
    echo ""
    echo "==== Dropbox info.json ===="
    if [[ -f "$HOME/.dropbox/info.json" ]]; then
        cat "$HOME/.dropbox/info.json"
    else
        echo "Missing: $HOME/.dropbox/info.json"
    fi
    echo ""
    echo "==== Dropbox app ===="
    if [[ -d "/Applications/Dropbox.app" ]]; then
        ls -ld /Applications/Dropbox.app
    else
        echo "Missing: /Applications/Dropbox.app"
    fi
}

dropbox_restart() {
    if ! _is_macos; then
        echo "Dropbox diagnostics are macOS-only."
        return 1
    fi
    if [[ -n "${ZSH_TEST_MODE:-}" ]]; then
        echo "Test mode: would restart Dropbox."
        return 0
    fi
    if [[ ! -d "/Applications/Dropbox.app" ]]; then
        echo "Dropbox.app not found in /Applications"
        return 1
    fi
    echo "Restarting Dropbox..."
    pkill -x Dropbox >/dev/null 2>&1 || true
    open -a Dropbox
}

dropbox_relink_helper() {
    if ! _is_macos; then
        echo "Dropbox diagnostics are macOS-only."
        return 1
    fi
    local db_path
    db_path="$HOME/Library/CloudStorage/Dropbox"
    echo "Dropbox relink helper"
    echo "Expected path: $db_path"
    if [[ -d "$db_path" ]]; then
        echo "Folder exists. Use this path if Dropbox asks."
        [[ -n "${ZSH_TEST_MODE:-}" ]] || open -a Finder "$db_path"
    else
        echo "Folder missing. Dropbox will need to recreate it."
    fi
    echo "If you see the 'Dropbox Folder Missing' dialog, click Relink and choose the path above."
    echo "Launching Dropbox..."
    [[ -n "${ZSH_TEST_MODE:-}" ]] || open -a Dropbox
}

linux_system_status() {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo "Linux diagnostics are Linux-only."
        return 1
    fi
    echo "==== System Information ===="
    uname -a
    echo ""
    echo "==== Disk Usage ===="
    df -h
    echo ""
    echo "==== Memory Usage ===="
    if command -v free >/dev/null 2>&1; then
        free -h
    else
        vmstat -s 2>/dev/null || true
    fi
    echo ""
    echo "==== Running Services ===="
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-units --type=service --state=running | head -n 20
    else
        ps -eo pid,comm,etime | head -n 20
    fi
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ system_diagnostics loaded"
fi
