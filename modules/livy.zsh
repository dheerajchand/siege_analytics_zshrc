#!/usr/bin/env zsh
# =================================================================
# LIVY - Apache Livy helpers
# =================================================================

_livy_detect_home() {
    if [[ -n "${LIVY_HOME:-}" && -d "$LIVY_HOME" ]]; then
        echo "$LIVY_HOME"
        return 0
    fi
    if [[ -d "$HOME/opt/livy/current" ]]; then
        echo "$HOME/opt/livy/current"
        return 0
    fi
    return 1
}

_livy_conf_dir() {
    echo "${LIVY_CONF_DIR:-$HOME/.config/livy}"
}

_livy_log_dir() {
    echo "${LIVY_LOG_DIR:-$HOME/.config/livy/logs}"
}

_livy_url() {
    echo "${ZEPPELIN_LIVY_URL:-http://127.0.0.1:8998}"
}

_livy_api_ready() {
    local url="$(_livy_url)"
    curl -fsS "${url%/}/sessions" >/dev/null 2>&1
}

_livy_write_config() {
    local conf_dir="$(_livy_conf_dir)"
    local log_dir="$(_livy_log_dir)"
    mkdir -p "$conf_dir" "$log_dir"
    local java17_opens="--add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/java.lang.invoke=ALL-UNNAMED"
    local spark_master="local[*]"
    if pgrep -f "spark.deploy.master.Master" >/dev/null 2>&1; then
        spark_master="${SPARK_MASTER_URL:-spark://localhost:7077}"
    fi
    local coords=""
    if typeset -f jar_matrix_resolve >/dev/null 2>&1; then
        coords="$(jar_matrix_resolve 2>/dev/null || true)"
    fi
    cat > "${conf_dir}/livy.conf" <<EOF
livy.server.host = 127.0.0.1
livy.server.port = ${ZEPPELIN_LIVY_URL##*:}
livy.spark.master = ${spark_master}
livy.spark.deploy-mode = client
livy.file.local-dir-whitelist = ${HOME}
livy.repl.enable-hive-context = false
livy.spark.driver.extraJavaOptions = ${java17_opens}
livy.spark.executor.extraJavaOptions = ${java17_opens}
EOF
    if [[ -n "$coords" ]]; then
        {
            echo "livy.spark.jars.packages = ${coords}"
            echo "livy.spark.serializer = org.apache.spark.serializer.KryoSerializer"
            echo "livy.spark.kryo.registrator = org.apache.sedona.core.serde.SedonaKryoRegistrator"
            echo "livy.spark.sql.extensions = org.apache.sedona.sql.SedonaSqlExtensions"
        } >> "${conf_dir}/livy.conf"
    fi
}

livy_status() {
    local home
    home="$(_livy_detect_home 2>/dev/null || true)"
    if [[ -z "$home" ]]; then
        echo "❌ Livy not installed"
        return 1
    fi
    echo "LIVY_HOME: ${home}"
    echo "LIVY_CONF_DIR: $(_livy_conf_dir)"
    echo "LIVY_LOG_DIR: $(_livy_log_dir)"
    echo "LIVY_URL: $(_livy_url)"
    if _livy_api_ready; then
        echo "✅ Livy API reachable"
        return 0
    fi
    echo "⚠️  Livy API unreachable"
    return 1
}

livy_start() {
    local home
    home="$(_livy_detect_home 2>/dev/null || true)"
    if [[ -z "$home" ]]; then
        echo "❌ Livy not installed (run setup-software.sh)"
        return 1
    fi
    if _livy_api_ready; then
        echo "✅ Livy already running: $(_livy_url)"
        return 0
    fi
    _livy_write_config
    export LIVY_HOME="$home"
    export LIVY_CONF_DIR="$(_livy_conf_dir)"
    export LIVY_LOG_DIR="$(_livy_log_dir)"
    if [[ -n "${SPARK_HOME:-}" ]]; then
        export SPARK_HOME
    fi
    if [[ -x "$home/bin/livy-server" ]]; then
        "$home/bin/livy-server" start
    else
        echo "❌ livy-server not found in $home/bin"
        return 1
    fi
    local attempts=20
    local i=1
    while [[ $i -le $attempts ]]; do
        if _livy_api_ready; then
            echo "✅ Livy started: $(_livy_url)"
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    echo "❌ Livy failed to start"
    return 1
}

livy_stop() {
    local home
    home="$(_livy_detect_home 2>/dev/null || true)"
    if [[ -z "$home" ]]; then
        echo "❌ Livy not installed"
        return 1
    fi
    if [[ -x "$home/bin/livy-server" ]]; then
        "$home/bin/livy-server" stop || true
    fi
    pkill -f "org.apache.livy.server.LivyServer" >/dev/null 2>&1 || true
    local attempts=10
    local i=1
    while [[ $i -le $attempts ]]; do
        if ! _livy_api_ready; then
            echo "✅ Livy stopped"
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done
    echo "⚠️  Livy stop timed out"
    return 1
}

livy_logs() {
    local log_dir="$(_livy_log_dir)"
    local file=""
    if [[ -d "$log_dir" ]]; then
        file="$(ls -t "$log_dir"/* 2>/dev/null | head -n 1)"
    fi
    if [[ -n "$file" ]]; then
        tail -n 200 -f "$file"
        return 0
    fi
    echo "No Livy logs found in $log_dir"
    return 1
}

echo "✅ livy loaded"
