#!/usr/bin/env zsh
# =================================================================
# ZEPPELIN - Apache Zeppelin Helpers
# =================================================================

_zeppelin_detect_home() {
    if [[ -n "${ZEPPELIN_HOME:-}" && -d "$ZEPPELIN_HOME" ]]; then
        echo "$ZEPPELIN_HOME"
        return 0
    fi
    if [[ -d "/opt/homebrew/opt/apache-zeppelin/libexec" ]]; then
        echo "/opt/homebrew/opt/apache-zeppelin/libexec"
        return 0
    fi
    if command -v brew >/dev/null 2>&1; then
        local prefix
        prefix="$(brew --prefix apache-zeppelin 2>/dev/null || true)"
        if [[ -n "$prefix" && -d "$prefix/libexec" ]]; then
            echo "$prefix/libexec"
            return 0
        fi
    fi
    if [[ -d "$HOME/opt/zeppelin/current" ]]; then
        echo "$HOME/opt/zeppelin/current"
        return 0
    fi
    if [[ -d "$HOME/.sdkman/candidates/zeppelin/current" ]]; then
        echo "$HOME/.sdkman/candidates/zeppelin/current"
        return 0
    fi
    if [[ -d "/usr/local/opt/apache-zeppelin/libexec" ]]; then
        echo "/usr/local/opt/apache-zeppelin/libexec"
        return 0
    fi
    return 1
}

_zeppelin_conf_dir() {
    echo "${ZEPPELIN_CONF_DIR:-$HOME/.config/zeppelin}"
}

_zeppelin_log_dir() {
    echo "${ZEPPELIN_LOG_DIR:-$HOME/.config/zeppelin/logs}"
}

_zeppelin_notebook_dir() {
    echo "${ZEPPELIN_NOTEBOOK_DIR:-$(_zeppelin_conf_dir)/notebook}"
}

_zeppelin_resolve_java_home() {
    if [[ -n "${JAVA_HOME:-}" && -d "$JAVA_HOME" ]]; then
        echo "$JAVA_HOME"
        return 0
    fi
    if [[ -x "/usr/libexec/java_home" ]]; then
        local jh=""
        jh="$(/usr/libexec/java_home -v 21 2>/dev/null || true)"
        if [[ -n "$jh" ]]; then
            echo "$jh"
            return 0
        fi
        jh="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
        if [[ -n "$jh" ]]; then
            echo "$jh"
            return 0
        fi
    fi
    return 1
}

_zeppelin_is_running() {
    pgrep -f "org.apache.zeppelin.server.ZeppelinServer" >/dev/null 2>&1
}

_zeppelin_api_ready() {
    local port="${ZEPPELIN_PORT:-8081}"
    curl -fsS "http://127.0.0.1:${port}/api/version" >/dev/null 2>&1
}

_zeppelin_spark_integration_mode() {
    local mode="${ZEPPELIN_SPARK_INTEGRATION_MODE:-external}"
    mode="${mode:l}"
    case "$mode" in
        embedded|livy|external) echo "$mode" ;;
        *) echo "external" ;;
    esac
}

_zeppelin_livy_url() {
    echo "${ZEPPELIN_LIVY_URL:-http://127.0.0.1:8998}"
}

_zeppelin_livy_ready() {
    local url="$(_zeppelin_livy_url)"
    curl -fsS "${url%/}/sessions" >/dev/null 2>&1
}

_zeppelin_persist_var() {
    local key="$1"
    local value="$2"
    local file="${ZSH_CONFIG_DIR:-$HOME/.config/zsh}/vars.env"
    [[ -z "$key" || -z "$value" ]] && return 1
    if typeset -f _compat_persist_var >/dev/null 2>&1; then
        _compat_persist_var "$key" "$value"
        return $?
    fi
    [[ -f "$file" ]] || touch "$file"
    python3 - "$file" "$key" "$value" <<'PY'
import sys
path, key, value = sys.argv[1:4]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()
needle = f'export {key}="'
new_line = f'export {key}="${{{key}:-{value}}}"'
updated = False
out = []
for line in lines:
    if line.startswith(needle):
        out.append(new_line)
        updated = True
    else:
        out.append(line)
if not updated:
    out.append(new_line)
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
}

_zeppelin_sedona_confs() {
    if [[ "${SPARK_SEDONA_ENABLE:-1}" == "1" ]]; then
        echo "--conf spark.serializer=org.apache.spark.serializer.KryoSerializer --conf spark.kryo.registrator=org.apache.sedona.core.serde.SedonaKryoRegistrator --conf spark.sql.extensions=org.apache.sedona.sql.SedonaSqlExtensions"
    fi
}

_zeppelin_resolve_spark_submit_options() {
    local base_opts="${SPARK_SUBMIT_OPTIONS:-}"
    local deps=""
    if typeset -f get_spark_dependencies >/dev/null 2>&1; then
        deps="$(get_spark_dependencies 2>/dev/null || true)"
    fi
    local sedona=""
    sedona="$(_zeppelin_sedona_confs 2>/dev/null || true)"
    echo "${base_opts} ${deps} ${sedona}" | sed -e 's/^ *//' -e 's/ *$//'
}

_zeppelin_write_config() {
    local conf_dir="$1"
    local spark_home="$2"
    local spark_master="$3"
    local submit_opts="$4"
    local zeppelin_home="$5"
    local port="${ZEPPELIN_PORT:-8081}"
    local notebook_dir="$(_zeppelin_notebook_dir)"
    local mode="$(_zeppelin_spark_integration_mode)"
    local use_spark="true"
    [[ "$mode" != "embedded" ]] && use_spark="false"

    mkdir -p "$conf_dir" "$(_zeppelin_log_dir)" "$notebook_dir"

    {
        printf 'export ZEPPELIN_PORT=%q\n' "${port}"
        printf 'export ZEPPELIN_LOG_DIR=%q\n' "$(_zeppelin_log_dir)"
        printf 'export ZEPPELIN_NOTEBOOK_DIR=%q\n' "${notebook_dir}"
        printf 'export ZEPPELIN_SPARK_INTEGRATION_MODE=%q\n' "${mode}"
        printf 'export ZEPPELIN_LIVY_URL=%q\n' "$(_zeppelin_livy_url)"
        printf 'export USE_ZEPPELIN_SPARK=%q\n' "${use_spark}"
        if [[ -n "$spark_home" ]]; then
            printf 'export SPARK_HOME=%q\n' "${spark_home}"
        fi
        if [[ "$mode" == "embedded" && -n "$submit_opts" ]]; then
            printf 'export SPARK_SUBMIT_OPTIONS=%q\n' "${submit_opts}"
        fi
        if [[ "$mode" == "embedded" && -n "$spark_master" ]]; then
            printf 'export SPARK_MASTER=%q\n' "${spark_master}"
        fi
    } > "$conf_dir/zeppelin-env.sh"

    # Seed required Zeppelin config files when using a custom conf directory.
    # Without log4j.properties, Zeppelin may fail very early with no useful logs.
    if [[ -n "$zeppelin_home" && -d "$zeppelin_home/conf" ]]; then
        if [[ ! -f "$conf_dir/log4j.properties" ]]; then
            if [[ -f "$zeppelin_home/conf/log4j.properties" ]]; then
                cp "$zeppelin_home/conf/log4j.properties" "$conf_dir/log4j.properties" 2>/dev/null || true
            elif [[ -f "$zeppelin_home/conf/log4j.properties.template" ]]; then
                cp "$zeppelin_home/conf/log4j.properties.template" "$conf_dir/log4j.properties" 2>/dev/null || true
            fi
        fi
        if [[ "${ZEPPELIN_ENABLE_AUTH:-0}" != "1" && -f "$conf_dir/shiro.ini" ]]; then
            rm -f "$conf_dir/shiro.ini" 2>/dev/null || true
        fi
    fi

    cat > "$conf_dir/zeppelin-site.xml" <<EOF
<?xml version="1.0"?>
<configuration>
  <property>
    <name>zeppelin.server.addr</name>
    <value>127.0.0.1</value>
  </property>
  <property>
    <name>zeppelin.server.port</name>
    <value>${port}</value>
  </property>
  <property>
    <name>zeppelin.notebook.dir</name>
    <value>${notebook_dir}</value>
  </property>
</configuration>
EOF
}

zeppelin_start() {
    local home
    home="$(_zeppelin_detect_home 2>/dev/null || true)"
    if [[ -z "$home" ]]; then
        echo "❌ Zeppelin not installed (run setup-software.sh or install to ~/opt/zeppelin/current)"
        return 1
    fi
    local mode
    mode="$(_zeppelin_spark_integration_mode)"
    if typeset -f stack_validate_versions >/dev/null 2>&1; then
        if ! stack_validate_versions --component zeppelin >/dev/null; then
            stack_validate_versions --component zeppelin
            return 1
        fi
    fi

    local spark_home="${ZEPPELIN_SPARK_HOME:-${SPARK_HOME:-}}"
    local spark_master="local[*]"
    if pgrep -f "spark.deploy.master.Master" >/dev/null 2>&1; then
        spark_master="${SPARK_MASTER_URL:-spark://localhost:7077}"
    fi

    local submit_opts
    if [[ "$mode" == "embedded" ]]; then
        local old_path="$PATH"
        local old_runtime_spark_home="${SPARK_HOME-}"
        local had_runtime_spark_home=0
        local old_spark_version="${SPARK_VERSION-}"
        local old_scala_version="${SPARK_SCALA_VERSION-}"
        local old_kafka_version="${SPARK_KAFKA_VERSION-}"
        local had_spark_version=0
        local had_scala_version=0
        local had_kafka_version=0
        [[ "${SPARK_VERSION+x}" == "x" ]] && had_spark_version=1
        [[ "${SPARK_SCALA_VERSION+x}" == "x" ]] && had_scala_version=1
        [[ "${SPARK_KAFKA_VERSION+x}" == "x" ]] && had_kafka_version=1
        [[ "${SPARK_HOME+x}" == "x" ]] && had_runtime_spark_home=1
        if [[ -n "$spark_home" && -d "$spark_home/bin" ]]; then
            export PATH="$spark_home/bin:$PATH"
            export SPARK_HOME="$spark_home"
            rehash 2>/dev/null || true
            unset SPARK_VERSION
            unset SPARK_SCALA_VERSION
            unset SPARK_KAFKA_VERSION
        fi
        submit_opts="$(_zeppelin_resolve_spark_submit_options)"
        export PATH="$old_path"
        if [[ "$had_runtime_spark_home" -eq 1 ]]; then export SPARK_HOME="$old_runtime_spark_home"; else unset SPARK_HOME; fi
        if [[ "$had_spark_version" -eq 1 ]]; then export SPARK_VERSION="$old_spark_version"; else unset SPARK_VERSION; fi
        if [[ "$had_scala_version" -eq 1 ]]; then export SPARK_SCALA_VERSION="$old_scala_version"; else unset SPARK_SCALA_VERSION; fi
        if [[ "$had_kafka_version" -eq 1 ]]; then export SPARK_KAFKA_VERSION="$old_kafka_version"; else unset SPARK_KAFKA_VERSION; fi
        [[ -n "$spark_master" ]] && submit_opts="--master ${spark_master} ${submit_opts}"
    fi

    if [[ "$mode" == "livy" ]]; then
        if ! _zeppelin_livy_ready; then
            if typeset -f livy_status >/dev/null 2>&1; then
                livy_status >/dev/null 2>&1 || true
            fi
            if [[ "${ZEPPELIN_LIVY_STRICT:-0}" == "1" ]]; then
                echo "❌ Livy not reachable at $(_zeppelin_livy_url)"
                echo "Run: livy_start"
                return 1
            fi
            echo "⚠️  Livy not reachable at $(_zeppelin_livy_url); Zeppelin will start, but Livy paragraphs may fail."
        fi
    fi

    local conf_dir
    conf_dir="$(_zeppelin_conf_dir)"
    _zeppelin_write_config "$conf_dir" "$spark_home" "$spark_master" "$submit_opts" "$home"

    export ZEPPELIN_HOME="$home"
    export ZEPPELIN_CONF_DIR="$conf_dir"
    export ZEPPELIN_LOG_DIR="$(_zeppelin_log_dir)"

    local jh
    jh="$(_zeppelin_resolve_java_home 2>/dev/null || true)"
    [[ -n "$jh" ]] && export JAVA_HOME="$jh"

    if _zeppelin_is_running; then
        echo "✅ Zeppelin already running: http://localhost:${ZEPPELIN_PORT:-8081}"
        return 0
    fi

    local launcher_log="$(_zeppelin_log_dir)/zeppelin-launch.out"
    if [[ "${ZEPPELIN_USE_DAEMON:-1}" == "1" && -x "$home/bin/zeppelin-daemon.sh" ]]; then
        "$home/bin/zeppelin-daemon.sh" start
    else
        nohup "$home/bin/zeppelin.sh" >> "$launcher_log" 2>&1 < /dev/null &
    fi

    local attempts=20
    local i=1
    while [[ $i -le $attempts ]]; do
        if _zeppelin_is_running && _zeppelin_api_ready; then
            echo "✅ Zeppelin started: http://localhost:${ZEPPELIN_PORT:-8081}"
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    echo "❌ Zeppelin failed to start (see $launcher_log)"
    return 1
}

zeppelin_stop() {
    local home
    home="$(_zeppelin_detect_home 2>/dev/null || true)"
    if [[ -z "$home" ]]; then
        echo "❌ Zeppelin not installed"
        return 1
    fi
    if _zeppelin_is_running; then
        pkill -f "org.apache.zeppelin.server.ZeppelinServer" >/dev/null 2>&1 || true
    elif [[ -x "$home/bin/zeppelin-daemon.sh" ]]; then
        "$home/bin/zeppelin-daemon.sh" stop || true
    fi
    local attempts=15
    local i=1
    while [[ $i -le $attempts ]]; do
        if ! _zeppelin_is_running; then
            echo "✅ Zeppelin stopped"
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    echo "⚠️  Zeppelin stop timed out"
    return 1
}

zeppelin_status() {
    local home
    home="$(_zeppelin_detect_home 2>/dev/null || true)"
    if [[ -z "$home" ]]; then
        echo "❌ Zeppelin not installed"
        return 1
    fi
    if _zeppelin_is_running; then
        echo "✅ Zeppelin running (port ${ZEPPELIN_PORT:-8081})"
    else
        echo "⚠️  Zeppelin not running"
    fi
}

zeppelin_restart() {
    zeppelin_stop || true
    sleep 2
    zeppelin_start
}

zeppelin_ui() {
    local port="${ZEPPELIN_PORT:-8081}"
    if command -v open >/dev/null 2>&1; then
        open "http://localhost:${port}"
    else
        echo "http://localhost:${port}"
    fi
}

zeppelin_config_status() {
    local home
    home="$(_zeppelin_detect_home 2>/dev/null || true)"
    local conf_dir="$(_zeppelin_conf_dir)"
    local log_dir="$(_zeppelin_log_dir)"
    local notebook_dir="$(_zeppelin_notebook_dir)"
    local port="${ZEPPELIN_PORT:-8081}"
    local spark_home="${SPARK_HOME:-}"
    local mode
    mode="$(_zeppelin_spark_integration_mode)"
    local livy_url
    livy_url="$(_zeppelin_livy_url)"
    local submit_opts
    submit_opts="$(_zeppelin_resolve_spark_submit_options 2>/dev/null || true)"

    echo "⚙️  Zeppelin Configuration"
    echo "=========================="
    echo "ZEPPELIN_HOME: ${home:-unset}"
    echo "ZEPPELIN_CONF_DIR: ${conf_dir}"
    echo "ZEPPELIN_LOG_DIR: ${log_dir}"
    echo "ZEPPELIN_NOTEBOOK_DIR: ${notebook_dir}"
    echo "ZEPPELIN_PORT: ${port}"
    echo "SPARK_HOME: ${spark_home:-unset}"
    echo "ZEPPELIN_SPARK_HOME: ${ZEPPELIN_SPARK_HOME:-unset}"
    echo "Integration mode: ${mode}"
    echo "Livy URL: ${livy_url}"
    if [[ "$mode" == "embedded" ]]; then
        echo "SPARK_SUBMIT_OPTIONS: ${submit_opts:-unset}"
    else
        echo "SPARK_SUBMIT_OPTIONS: (unused in ${mode} mode)"
    fi
    echo "Sedona: ${SPARK_SEDONA_ENABLE:-1} (v${SPARK_SEDONA_VERSION:-unknown})"
    echo "GeoTools: ${SPARK_GEOTOOLS_VERSION:-unknown}"
    echo "GraphFrames: ${SPARK_GRAPHFRAMES_ENABLE:-1} (v${SPARK_GRAPHFRAMES_VERSION:-unknown})"
    if [[ "$mode" == "livy" ]]; then
        if _zeppelin_livy_ready; then
            echo "Livy health: reachable"
        else
            echo "Livy health: unreachable"
        fi
    fi
}

zeppelin_diagnose() {
    local ok=0
    local mode
    mode="$(_zeppelin_spark_integration_mode)"
    echo "🩺 Zeppelin Diagnostics"
    echo "======================="
    echo "Integration mode: ${mode}"
    zeppelin_status || ok=1

    local home
    home="$(_zeppelin_detect_home 2>/dev/null || true)"
    if [[ -z "$home" ]]; then
        echo "❌ ZEPPELIN_HOME not found"
        return 1
    fi

    if [[ -x "$home/bin/zeppelin.sh" ]]; then
        echo "✅ zeppelin.sh found"
    else
        echo "❌ zeppelin.sh not found"
        ok=1
    fi

    local conf_dir="$(_zeppelin_conf_dir)"
    local env_file="$conf_dir/zeppelin-env.sh"
    local site_file="$conf_dir/zeppelin-site.xml"
    [[ -f "$env_file" ]] && echo "✅ zeppelin-env.sh present" || { echo "⚠️  zeppelin-env.sh missing"; ok=1; }
    [[ -f "$site_file" ]] && echo "✅ zeppelin-site.xml present" || { echo "⚠️  zeppelin-site.xml missing"; ok=1; }

    if command -v java >/dev/null 2>&1; then
        echo "✅ Java: $(java -version 2>&1 | head -n 1)"
    else
        echo "❌ Java not found"
        ok=1
    fi

    if command -v spark-submit >/dev/null 2>&1; then
        local spark_ver
        spark_ver="$(spark-submit --version 2>&1 | awk '/version/{print $NF; exit}')"
        echo "✅ Spark: ${spark_ver:-unknown}"
    else
        echo "⚠️  spark-submit not found"
        ok=1
    fi
    if [[ "$mode" == "livy" ]]; then
        if _zeppelin_livy_ready; then
            echo "✅ Livy reachable: $(_zeppelin_livy_url)"
        else
            echo "⚠️  Livy unreachable: $(_zeppelin_livy_url)"
            ok=1
        fi
    fi

    local log_dir="$(_zeppelin_log_dir)"
    if [[ -d "$log_dir" ]]; then
        local latest_log
        latest_log="$(ls -t "$log_dir"/* 2>/dev/null | head -n 1)"
        if [[ -n "$latest_log" ]]; then
            echo "📝 Latest log: $latest_log"
        else
            echo "⚠️  No logs found in $log_dir"
        fi
    else
        echo "⚠️  Log dir missing: $log_dir"
    fi

    return "$ok"
}

zeppelin_logs() {
    local log_dir="$(_zeppelin_log_dir)"
    local log_file=""
    if [[ -d "$log_dir" ]]; then
        log_file="$(ls -t "$log_dir"/* 2>/dev/null | head -n 1)"
    fi
    if [[ -n "$log_file" ]]; then
        tail -n 200 -f "$log_file"
    else
        echo "No Zeppelin logs found in $log_dir"
        return 1
    fi
}

zeppelin_seed_smoke_notebook() {
    local script="${ZSH_CONFIG_DIR:-$HOME/.config/zsh}/scripts/zeppelin_seed_smoke_notebook.py"
    local base_url="http://127.0.0.1:${ZEPPELIN_PORT:-8081}"
    if [[ ! -f "$script" ]]; then
        echo "❌ Notebook seed script not found: $script"
        return 1
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        echo "❌ python3 not found"
        return 1
    fi
    if ! _zeppelin_is_running; then
        zeppelin_start || return 1
    fi
    local mode
    mode="$(_zeppelin_spark_integration_mode)"
    python3 "$script" --base-url "$base_url" --integration-mode "$mode" --run "$@"
}

zeppelin_integration_status() {
    local mode
    mode="$(_zeppelin_spark_integration_mode)"
    echo "Zeppelin Spark integration mode: ${mode}"
    if [[ "$mode" == "livy" ]]; then
        local livy_url
        livy_url="$(_zeppelin_livy_url)"
        echo "Livy URL: ${livy_url}"
        if _zeppelin_livy_ready; then
            echo "Livy: reachable"
        else
            echo "Livy: unreachable"
        fi
    fi
}

zeppelin_integration_use() {
    local mode=""
    local persist=0
    local livy_url=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            embedded|livy|external)
                mode="$1"
                shift
                ;;
            --persist)
                persist=1
                shift
                ;;
            --livy-url)
                livy_url="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: zeppelin_integration_use <embedded|livy|external> [--livy-url URL] [--persist]" >&2
                return 0
                ;;
            *)
                echo "Usage: zeppelin_integration_use <embedded|livy|external> [--livy-url URL] [--persist]" >&2
                return 1
                ;;
        esac
    done
    if [[ -z "$mode" ]]; then
        echo "Usage: zeppelin_integration_use <embedded|livy|external> [--livy-url URL] [--persist]" >&2
        return 1
    fi
    export ZEPPELIN_SPARK_INTEGRATION_MODE="$mode"
    if [[ -n "$livy_url" ]]; then
        export ZEPPELIN_LIVY_URL="$livy_url"
    fi
    if (( persist )); then
        _zeppelin_persist_var "ZEPPELIN_SPARK_INTEGRATION_MODE" "$mode"
        if [[ -n "$livy_url" ]]; then
            _zeppelin_persist_var "ZEPPELIN_LIVY_URL" "$livy_url"
        fi
        echo "✅ Persisted Zeppelin integration mode: ${mode}"
    else
        echo "✅ Active Zeppelin integration mode: ${mode}"
    fi
    zeppelin_integration_status
}

alias zeppelin-ui='zeppelin_ui'

echo "✅ zeppelin loaded"
