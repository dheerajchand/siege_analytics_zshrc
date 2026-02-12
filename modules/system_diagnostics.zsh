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
    if typeset -f zeppelin_config_status >/dev/null 2>&1; then
        ran=1
        echo ""
        zeppelin_config_status || rc=1
    else
        echo "⚠️  zeppelin_config_status not available (zeppelin module not loaded)"
        rc=1
    fi
    if [[ "$ran" -eq 0 ]]; then
        echo "⚠️  No configuration checks available"
        return 1
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
