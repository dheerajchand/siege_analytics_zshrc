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
    local port="${ZEPPELIN_PORT:-8081}"
    local notebook_dir="$(_zeppelin_notebook_dir)"

    mkdir -p "$conf_dir" "$(_zeppelin_log_dir)" "$notebook_dir"

    cat > "$conf_dir/zeppelin-env.sh" <<EOF
export ZEPPELIN_PORT="${port}"
export ZEPPELIN_LOG_DIR="$(_zeppelin_log_dir)"
export ZEPPELIN_NOTEBOOK_DIR="${notebook_dir}"
${spark_home:+export SPARK_HOME="${spark_home}"}
${submit_opts:+export SPARK_SUBMIT_OPTIONS="${submit_opts}"}
${spark_master:+export SPARK_MASTER="${spark_master}"}
EOF

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

    local spark_home="${SPARK_HOME:-}"
    local spark_master="local[*]"
    if pgrep -f "spark.deploy.master.Master" >/dev/null 2>&1; then
        spark_master="${SPARK_MASTER_URL:-spark://localhost:7077}"
    fi

    local submit_opts
    submit_opts="$(_zeppelin_resolve_spark_submit_options)"
    [[ -n "$spark_master" ]] && submit_opts="--master ${spark_master} ${submit_opts}"

    local conf_dir
    conf_dir="$(_zeppelin_conf_dir)"
    _zeppelin_write_config "$conf_dir" "$spark_home" "$spark_master" "$submit_opts"

    export ZEPPELIN_HOME="$home"
    export ZEPPELIN_CONF_DIR="$conf_dir"
    export ZEPPELIN_LOG_DIR="$(_zeppelin_log_dir)"

    local jh
    jh="$(_zeppelin_resolve_java_home 2>/dev/null || true)"
    [[ -n "$jh" ]] && export JAVA_HOME="$jh"

    if [[ -x "$home/bin/zeppelin-daemon.sh" ]]; then
        "$home/bin/zeppelin-daemon.sh" start
    else
        "$home/bin/zeppelin.sh" start
    fi
    echo "✅ Zeppelin started: http://localhost:${ZEPPELIN_PORT:-8081}"
}

zeppelin_stop() {
    local home
    home="$(_zeppelin_detect_home 2>/dev/null || true)"
    if [[ -z "$home" ]]; then
        echo "❌ Zeppelin not installed"
        return 1
    fi
    if [[ -x "$home/bin/zeppelin-daemon.sh" ]]; then
        "$home/bin/zeppelin-daemon.sh" stop
    else
        "$home/bin/zeppelin.sh" stop
    fi
    echo "✅ Zeppelin stopped"
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
    echo "SPARK_SUBMIT_OPTIONS: ${submit_opts:-unset}"
    echo "Sedona: ${SPARK_SEDONA_ENABLE:-1} (v${SPARK_SEDONA_VERSION:-unknown})"
    echo "GeoTools: ${SPARK_GEOTOOLS_VERSION:-unknown}"
}

zeppelin_diagnose() {
    local ok=0
    echo "🩺 Zeppelin Diagnostics"
    echo "======================="
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

alias zeppelin-ui='zeppelin_ui'

echo "✅ zeppelin loaded"
