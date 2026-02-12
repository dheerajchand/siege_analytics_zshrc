#!/usr/bin/env zsh
# =================================================================
# SPARK - Apache Spark Cluster Management
# =================================================================
# Start/stop Spark cluster, intelligent job submission
# Uses is_online() to decide: local JARs vs Maven downloads
# =================================================================

# Spark environment setup
if [[ -z "$SPARK_HOME" ]]; then
    if [[ -d "$HOME/.sdkman/candidates/spark/current" ]]; then
        export SPARK_HOME="$HOME/.sdkman/candidates/spark/current"
    elif [[ -d "/opt/homebrew/opt/apache-spark/libexec" ]]; then
        export SPARK_HOME="/opt/homebrew/opt/apache-spark/libexec"
    elif [[ -d "/usr/lib/spark" ]]; then
        export SPARK_HOME="/usr/lib/spark"
    elif [[ -d "/usr/local/spark" ]]; then
        export SPARK_HOME="/usr/local/spark"
    fi
fi
export SPARK_MASTER_HOST="${SPARK_MASTER_HOST:-localhost}"
export SPARK_MASTER_PORT="${SPARK_MASTER_PORT:-7077}"
export SPARK_MASTER_URL="spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}"
export SPARK_LOCAL_MASTER="${SPARK_LOCAL_MASTER:-local[*]}"
export SPARK_EXECUTION_MODE="${SPARK_EXECUTION_MODE:-auto}"
export SPARK_DRIVER_MEMORY="${SPARK_DRIVER_MEMORY:-2g}"
export SPARK_EXECUTOR_MEMORY="${SPARK_EXECUTOR_MEMORY:-2g}"
: "${SPARK_JARS_AUTO_DOWNLOAD:=1}"
: "${SPARK_SEDONA_ENABLE:=1}"
: "${SPARK_SEDONA_VERSION:=1.8.1}"
: "${SPARK_GEOTOOLS_VERSION:=1.8.1-33.1}"
: "${SPARK_GRAPHFRAMES_ENABLE:=1}"
: "${SPARK_GRAPHFRAMES_VERSION:=}"
: "${SPARK_KAFKA_ENABLE:=1}"
: "${SPARK_KAFKA_VERSION:=}"
: "${HADOOP_VERSION:=}"

_spark_cluster_running() {
    if command -v jps >/dev/null 2>&1; then
        jps | grep -q "Master"
        return $?
    fi
    pgrep -f "spark.deploy.master.Master" >/dev/null 2>&1
}

_spark_normalize_mode() {
    local mode="${1:-${SPARK_EXECUTION_MODE:-auto}}"
    mode="${mode:l}"
    case "$mode" in
        auto|local|cluster) echo "$mode" ;;
        *) echo "auto" ;;
    esac
}

_spark_resolve_master() {
    local mode
    mode="$(_spark_normalize_mode "$1")"
    case "$mode" in
        local)
            echo "$SPARK_LOCAL_MASTER"
            ;;
        cluster)
            echo "$SPARK_MASTER_URL"
            ;;
        auto)
            if _spark_cluster_running; then
                echo "$SPARK_MASTER_URL"
            else
                echo "$SPARK_LOCAL_MASTER"
            fi
            ;;
    esac
}

_spark_persist_var() {
    local key="$1"
    local value="$2"
    local file="${ZSH_CONFIG_DIR:-$HOME/.config/zsh}/vars.env"
    [[ -z "$key" ]] && return 1
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

spark_mode_status() {
    local mode
    mode="$(_spark_normalize_mode)"
    local effective_master
    effective_master="$(_spark_resolve_master "$mode")"
    echo "⚙️  Spark Execution Mode"
    echo "======================="
    echo "Configured mode: ${mode}"
    echo "Local master: ${SPARK_LOCAL_MASTER}"
    echo "Cluster master: ${SPARK_MASTER_URL}"
    if _spark_cluster_running; then
        echo "Cluster state: running"
    else
        echo "Cluster state: stopped"
    fi
    echo "Effective master: ${effective_master}"
}

spark_mode_use() {
    local mode=""
    local persist=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            auto|local|cluster)
                mode="$1"
                shift
                ;;
            --persist)
                persist=1
                shift
                ;;
            --help|-h)
                echo "Usage: spark_mode_use <auto|local|cluster> [--persist]" >&2
                return 0
                ;;
            *)
                echo "Usage: spark_mode_use <auto|local|cluster> [--persist]" >&2
                return 1
                ;;
        esac
    done
    if [[ -z "$mode" ]]; then
        echo "Usage: spark_mode_use <auto|local|cluster> [--persist]" >&2
        return 1
    fi
    export SPARK_EXECUTION_MODE="$mode"
    if (( persist )); then
        _spark_persist_var "SPARK_EXECUTION_MODE" "$mode"
        echo "✅ Persisted Spark execution mode: ${mode}"
    else
        echo "✅ Active Spark execution mode: ${mode}"
    fi
    if [[ "$mode" == "cluster" ]] && ! _spark_cluster_running; then
        echo "⚠️  Spark cluster mode selected but master is not running at ${SPARK_MASTER_URL}"
    fi
    spark_mode_status
}

# Detect Spark and Scala versions from spark-submit output
_spark_detect_versions() {
    local spark_version scala_version output
    spark_version=""
    scala_version=""
    if command -v spark-submit >/dev/null 2>&1; then
        output="$(spark-submit --version 2>&1 || true)"
        spark_version="$(printf '%s' "$output" | awk '/version/{print $NF; exit}')"
        scala_version="$(printf '%s' "$output" | awk -F'version ' '/Scala/{print $2; exit}')"
        scala_version="${scala_version%%,*}"
        scala_version="${scala_version%% *}"
    fi
    if [[ -n "$spark_version" ]]; then
        echo "$spark_version" "${scala_version:-}"
        return 0
    fi
    return 1
}

_spark_detect_scala_version() {
    if command -v scala >/dev/null 2>&1; then
        scala -version 2>&1 | awk '/version/{print $NF; exit}'
    fi
}

_spark_detect_hadoop_version() {
    local hv=""
    if [[ -n "${HADOOP_VERSION:-}" ]]; then
        echo "$HADOOP_VERSION"
        return 0
    fi
    if command -v hadoop >/dev/null 2>&1; then
        hv="$(hadoop version 2>/dev/null | awk '/Hadoop/{print $2; exit}')"
        [[ -n "$hv" ]] && echo "$hv"
    fi
}

_spark_default_scala_for_spark() {
    local spark_version="$1"
    case "$spark_version" in
        2.0*|2.1*|2.2*|2.3*) echo "2.11" ;;
        2.4*) echo "2.12" ;;
        3.*) echo "2.12" ;;
        4.*) echo "2.13" ;;
        *) echo "" ;;
    esac
}

_spark_scala_binary() {
    local v="$1"
    v="${v%%,*}"
    v="${v%% *}"
    if [[ -z "$v" ]]; then
        echo ""
        return 0
    fi
    if [[ "$v" == *.*.* ]]; then
        echo "${v%.*}"
        return 0
    fi
    echo "$v"
}

jar_matrix_resolve() {
    local spark_version="${SPARK_VERSION:-}"
    local scala_version="${SPARK_SCALA_VERSION:-}"
    if [[ -z "$spark_version" || -z "$scala_version" ]]; then
        local detected
        detected="$(_spark_detect_versions 2>/dev/null || true)"
        spark_version="${spark_version:-${detected%% *}}"
        scala_version="${scala_version:-${detected#* }}"
    fi
    if [[ -z "$scala_version" ]]; then
        scala_version="$(_spark_detect_scala_version 2>/dev/null || true)"
    fi
    if [[ -z "$scala_version" && -n "$spark_version" ]]; then
        scala_version="$(_spark_default_scala_for_spark "$spark_version")"
    fi
    local scala_binary=""
    scala_binary="$(_spark_scala_binary "$scala_version")"
    local spark_mm=""
    local spark_major=""
    if [[ -n "$spark_version" ]]; then
        spark_mm="${spark_version%.*}"
        spark_major="${spark_version%%.*}"
    fi
    local sedona_spark_mm="${SPARK_SEDONA_SPARK_VERSION:-}"
    if [[ -z "$sedona_spark_mm" && -n "$spark_version" ]]; then
        if [[ "$spark_version" == 4.* ]]; then
            sedona_spark_mm="4.0"
        else
            sedona_spark_mm="$spark_mm"
        fi
    fi
    local coords=()
    if [[ "$SPARK_SEDONA_ENABLE" == "1" && -n "$sedona_spark_mm" && -n "$scala_binary" ]]; then
        coords+=("org.apache.sedona:sedona-spark-shaded-${sedona_spark_mm}_${scala_binary}:${SPARK_SEDONA_VERSION}")
        coords+=("org.datasyslab:geotools-wrapper:${SPARK_GEOTOOLS_VERSION}")
    fi
    local graphframes_version="${SPARK_GRAPHFRAMES_VERSION:-}"
    if [[ -z "$graphframes_version" ]]; then
        if [[ "$spark_major" == "4" ]]; then
            graphframes_version="0.10.0"
        elif [[ "$spark_major" == "3" ]]; then
            graphframes_version="0.9.3"
        fi
    fi
    if [[ "$SPARK_GRAPHFRAMES_ENABLE" == "1" && -n "$spark_major" && -n "$scala_binary" && -n "$graphframes_version" ]]; then
        coords+=("io.graphframes:graphframes-spark${spark_major}_${scala_binary}:${graphframes_version}")
    fi
    if [[ "$SPARK_KAFKA_ENABLE" == "1" && -n "$scala_binary" ]]; then
        local kafka_version="${SPARK_KAFKA_VERSION:-$spark_version}"
        if [[ -n "$kafka_version" ]]; then
            coords+=("org.apache.spark:spark-sql-kafka-0-10_${scala_binary}:${kafka_version}")
        fi
    fi
    if [[ -n "${SPARK_JARS_COORDS:-}" ]]; then
        coords+=("${(s:,:)SPARK_JARS_COORDS}")
    fi
    if [[ ${#coords[@]} -eq 0 ]]; then
        return 1
    fi
    local joined="${(j:,:)coords}"
    echo "$joined"
}

jar_matrix_status() {
    local spark_version="${SPARK_VERSION:-}"
    local scala_version="${SPARK_SCALA_VERSION:-}"
    if [[ -z "$spark_version" || -z "$scala_version" ]]; then
        local detected
        detected="$(_spark_detect_versions 2>/dev/null || true)"
        spark_version="${spark_version:-${detected%% *}}"
        scala_version="${scala_version:-${detected#* }}"
    fi
    if [[ -z "$scala_version" ]]; then
        scala_version="$(_spark_detect_scala_version 2>/dev/null || true)"
    fi
    if [[ -z "$scala_version" && -n "$spark_version" ]]; then
        scala_version="$(_spark_default_scala_for_spark "$spark_version")"
    fi
    local hadoop_version
    hadoop_version="$(_spark_detect_hadoop_version 2>/dev/null || true)"
    local coords
    coords="$(jar_matrix_resolve 2>/dev/null || true)"
    local jars_root="${JARS_DIR:-$HOME/.jars}"
    local jar_dir="${jars_root}/spark"
    [[ -n "$spark_version" ]] && jar_dir="${jars_root}/spark/${spark_version}"
    echo "🧩 Jar Matrix Status"
    echo "===================="
    echo "Spark: ${spark_version:-unknown}"
    echo "Scala: ${scala_version:-unknown}"
    echo "Hadoop: ${hadoop_version:-unknown}"
    echo "JARS_DIR: ${jars_root}"
    echo "Jar dir: ${jar_dir}"
    if [[ -n "$coords" ]]; then
        echo "Coords: $coords"
    else
        echo "Coords: (none)"
    fi
}

spark_validate_versions() {
    local spark_version="${SPARK_VERSION:-}"
    local scala_version="${SPARK_SCALA_VERSION:-}"
    if [[ -z "$spark_version" || -z "$scala_version" ]]; then
        local detected
        detected="$(_spark_detect_versions 2>/dev/null || true)"
        spark_version="${spark_version:-${detected%% *}}"
        scala_version="${scala_version:-${detected#* }}"
    fi
    if [[ -z "$scala_version" ]]; then
        scala_version="$(_spark_detect_scala_version 2>/dev/null || true)"
    fi
    local expected_scala=""
    if [[ -n "$spark_version" ]]; then
        expected_scala="$(_spark_default_scala_for_spark "$spark_version")"
    fi
    local scala_binary=""
    scala_binary="$(_spark_scala_binary "$scala_version")"
    local expected_binary=""
    expected_binary="$(_spark_scala_binary "$expected_scala")"
    local hadoop_version
    hadoop_version="$(_spark_detect_hadoop_version 2>/dev/null || true)"
    local hadoop_mm=""
    [[ -n "$hadoop_version" ]] && hadoop_mm="${hadoop_version%%.*}"
    local ok=0
    if [[ -n "$spark_version" && -n "$expected_binary" && -n "$scala_binary" && "$expected_binary" != "$scala_binary" ]]; then
        echo "⚠️  Spark $spark_version expects Scala $expected_binary but found $scala_binary" >&2
        ok=1
    fi
    if [[ -n "$hadoop_mm" && "$hadoop_mm" != "2" && "$hadoop_mm" != "3" ]]; then
        echo "⚠️  Unsupported Hadoop major version: $hadoop_mm (expected 2.x or 3.x)" >&2
        ok=1
    fi
    if [[ -z "$spark_version" ]]; then
        echo "⚠️  Spark version unknown; set SPARK_VERSION or install Spark" >&2
        ok=1
    fi
    if [[ -z "$scala_binary" ]]; then
        echo "⚠️  Scala version unknown; set SPARK_SCALA_VERSION or install Scala" >&2
        ok=1
    fi
    return "$ok"
}

spark_config_status() {
    local spark_version="${SPARK_VERSION:-}"
    local scala_version="${SPARK_SCALA_VERSION:-}"
    if [[ -z "$spark_version" || -z "$scala_version" ]]; then
        local detected
        detected="$(_spark_detect_versions 2>/dev/null || true)"
        spark_version="${spark_version:-${detected%% *}}"
        scala_version="${scala_version:-${detected#* }}"
    fi
    if [[ -z "$scala_version" ]]; then
        scala_version="$(_spark_detect_scala_version 2>/dev/null || true)"
    fi
    if [[ -z "$scala_version" && -n "$spark_version" ]]; then
        scala_version="$(_spark_default_scala_for_spark "$spark_version")"
    fi
    local hadoop_version
    hadoop_version="$(_spark_detect_hadoop_version 2>/dev/null || true)"
    echo "⚙️  Spark Configuration"
    echo "======================"
    echo "SPARK_HOME: ${SPARK_HOME:-unset}"
    echo "Spark: ${spark_version:-unknown}"
    echo "Scala: ${scala_version:-unknown}"
    echo "Hadoop: ${hadoop_version:-unknown}"
    echo "JARS_DIR: ${JARS_DIR:-$HOME/.jars}"
    echo "Auto-download: ${SPARK_JARS_AUTO_DOWNLOAD}"
    echo "Legacy jar dirs: ${SPARK_LEGACY_JAR_DIR_ENABLE}"
    echo "Sedona: ${SPARK_SEDONA_ENABLE} (v${SPARK_SEDONA_VERSION})"
    echo "GeoTools: ${SPARK_GEOTOOLS_VERSION}"
    local graphframes_version="${SPARK_GRAPHFRAMES_VERSION:-auto}"
    echo "GraphFrames: ${SPARK_GRAPHFRAMES_ENABLE} (v${graphframes_version})"
}

spark_versions() {
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found (install SDKMAN)" >&2
        return 1
    fi
    sdk list spark
}

spark_use_version() {
    local version="$1"
    if [[ -z "$version" ]]; then
        echo "Usage: spark_use_version <version>" >&2
        return 1
    fi
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found (install SDKMAN)" >&2
        return 1
    fi
    sdk use spark "$version"
    if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
        _secrets_update_env_file "SPARK_VERSION" "$version" >/dev/null 2>&1 || true
    fi
    export SPARK_VERSION="$version"
}

spark_default_version() {
    local version="$1"
    if [[ -z "$version" ]]; then
        echo "Usage: spark_default_version <version>" >&2
        return 1
    fi
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found (install SDKMAN)" >&2
        return 1
    fi
    sdk default spark "$version"
    if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
        _secrets_update_env_file "SPARK_VERSION" "$version" >/dev/null 2>&1 || true
    fi
    export SPARK_VERSION="$version"
}

scala_versions() {
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found (install SDKMAN)" >&2
        return 1
    fi
    sdk list scala
}

scala_use_version() {
    local version="$1"
    if [[ -z "$version" ]]; then
        echo "Usage: scala_use_version <version>" >&2
        return 1
    fi
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found (install SDKMAN)" >&2
        return 1
    fi
    sdk use scala "$version"
    if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
        _secrets_update_env_file "SPARK_SCALA_VERSION" "$version" >/dev/null 2>&1 || true
    fi
    export SPARK_SCALA_VERSION="$version"
}

scala_default_version() {
    local version="$1"
    if [[ -z "$version" ]]; then
        echo "Usage: scala_default_version <version>" >&2
        return 1
    fi
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found (install SDKMAN)" >&2
        return 1
    fi
    sdk default scala "$version"
    if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
        _secrets_update_env_file "SPARK_SCALA_VERSION" "$version" >/dev/null 2>&1 || true
    fi
    export SPARK_SCALA_VERSION="$version"
}

java_versions() {
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found (install SDKMAN)" >&2
        return 1
    fi
    sdk list java
}

java_use_version() {
    local version="$1"
    if [[ -z "$version" ]]; then
        echo "Usage: java_use_version <version>" >&2
        return 1
    fi
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found (install SDKMAN)" >&2
        return 1
    fi
    sdk use java "$version"
    if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
        _secrets_update_env_file "JAVA_VERSION" "$version" >/dev/null 2>&1 || true
    fi
    export JAVA_VERSION="$version"
}

java_default_version() {
    local version="$1"
    if [[ -z "$version" ]]; then
        echo "Usage: java_default_version <version>" >&2
        return 1
    fi
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found (install SDKMAN)" >&2
        return 1
    fi
    sdk default java "$version"
    if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
        _secrets_update_env_file "JAVA_VERSION" "$version" >/dev/null 2>&1 || true
    fi
    export JAVA_VERSION="$version"
}

# Check if Spark is available
if [[ ! -d "$SPARK_HOME" ]] && command -v spark-submit >/dev/null 2>&1; then
    SPARK_HOME="$(dirname $(dirname $(which spark-submit)))"
    export SPARK_HOME
fi

# Start Spark cluster
spark_start() {
    if [[ ! -d "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not found: $SPARK_HOME"
        echo "Install via SDKMAN or set SPARK_HOME"
        return 1
    fi
    
    # Configure Python for Spark (ensures driver and worker use same Python)
    # CRITICAL: Prevents Python version mismatch between driver and workers
    local python_path
    if command -v pyenv >/dev/null 2>&1; then
        python_path="$(pyenv which python 2>/dev/null || which python)"
    else
        python_path="$(which python3 || which python)"
    fi
    
    # Maintain Python config without overwriting existing spark-env.sh
    mkdir -p "$SPARK_HOME/conf"
    local env_main="$SPARK_HOME/conf/spark-env.sh"
    local env_fragment="$SPARK_HOME/conf/spark-env-zsh.sh"
    cat > "$env_fragment" << SPARKENV
# Python configuration - auto-generated by zsh config
# Ensures driver and worker use same Python version
export PYSPARK_PYTHON="$python_path"
export PYSPARK_DRIVER_PYTHON="$python_path"
SPARKENV
    if [[ ! -f "$env_main" ]]; then
        cat > "$env_main" <<'SPARKMAIN'
#!/usr/bin/env bash
# spark-env.sh
if [ -f "$SPARK_HOME/conf/spark-env-zsh.sh" ]; then
  . "$SPARK_HOME/conf/spark-env-zsh.sh"
fi
SPARKMAIN
    elif ! grep -q "spark-env-zsh.sh" "$env_main" 2>/dev/null; then
        echo "" >> "$env_main"
        echo 'if [ -f "$SPARK_HOME/conf/spark-env-zsh.sh" ]; then' >> "$env_main"
        echo '  . "$SPARK_HOME/conf/spark-env-zsh.sh"' >> "$env_main"
        echo "fi" >> "$env_main"
    fi
    
    echo "🚀 Starting Spark cluster..."
    
    # Start master (use jps - more reliable for Java processes)
    if ! jps | grep -q "Master"; then
        "$SPARK_HOME/sbin/start-master.sh"
        sleep 3
        if jps | grep -q "Master"; then
            echo "✅ Spark Master started"
        else
            echo "❌ Spark Master failed to start"
            return 1
        fi
    else
        echo "✅ Spark Master already running"
    fi
    
    # Start worker
    if ! jps | grep -q "Worker"; then
        "$SPARK_HOME/sbin/start-worker.sh" "$SPARK_MASTER_URL"
        sleep 3
        if jps | grep -q "Worker"; then
            echo "✅ Spark Worker started"
        else
            echo "❌ Spark Worker failed to start"
            return 1
        fi
    else
        echo "✅ Spark Worker already running"
    fi
    
    echo ""
    echo "Spark Web UI: http://localhost:8080"
    echo "Master URL: $SPARK_MASTER_URL"
}

# Stop Spark cluster
spark_stop() {
    if [[ ! -d "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not found"
        return 1
    fi
    
    echo "⏹️  Stopping Spark cluster..."
    
    "$SPARK_HOME/sbin/stop-worker.sh" 2>/dev/null
    "$SPARK_HOME/sbin/stop-master.sh" 2>/dev/null
    
    echo "✅ Spark cluster stopped"
}

# Show Spark status
spark_status() {
    echo "⚡ Spark Status"
    echo "=============="
    
    if [[ -d "$SPARK_HOME" ]]; then
        echo "SPARK_HOME: $SPARK_HOME"
        echo "Master URL: $SPARK_MASTER_URL"
        echo "Execution mode: $(_spark_normalize_mode)"
        echo "Effective master: $(_spark_resolve_master)"
    else
        echo "❌ SPARK_HOME not found"
        return 1
    fi
    
    echo ""
    
    if pgrep -f "spark.deploy.master.Master" >/dev/null; then
        echo "✅ Master: Running (http://localhost:8080)"
    else
        echo "❌ Master: Not running"
    fi
    
    if pgrep -f "spark.deploy.worker.Worker" >/dev/null; then
        echo "✅ Worker: Running"
    else
        echo "❌ Worker: Not running"
    fi
}

spark_health() {
    local ok=0
    echo "⚡ Spark Health"
    echo "============="
    if [[ -z "${SPARK_HOME:-}" && -z "$(command -v spark-submit 2>/dev/null)" ]]; then
        echo "❌ Spark not found (set SPARK_HOME or install Spark)"
        return 1
    fi
    if [[ -n "${SPARK_HOME:-}" && ! -d "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not found: $SPARK_HOME"
        ok=1
    fi
    if pgrep -f "spark.deploy.master.Master" >/dev/null; then
        echo "✅ Master: running"
    else
        echo "⚠️  Master: not running"
        ok=1
    fi
    if pgrep -f "spark.deploy.worker.Worker" >/dev/null; then
        echo "✅ Worker: running"
    else
        echo "⚠️  Worker: not running"
        ok=1
    fi
    if [[ -n "${ZSH_TEST_MODE:-}" ]]; then
        return "$ok"
    fi
    if command -v spark-submit >/dev/null 2>&1; then
        local version
        version="$(spark-submit --version 2>&1 | head -n 1)"
        [[ -n "$version" ]] && echo "📦 $version"
    fi
    return "$ok"
}

# Get Spark dependencies based on connectivity
# CRITICAL: Uses is_online() to decide local JARs vs Maven
get_spark_dependencies() {
    local deps=""
    local jars_root="${JARS_DIR:-$HOME/.jars}"
    local spark_version="${SPARK_VERSION:-}"
    if [[ -z "$spark_version" ]]; then
        spark_version="$(_spark_detect_versions 2>/dev/null | awk '{print $1}' || true)"
    fi
    local scala_version="${SPARK_SCALA_VERSION:-}"
    if [[ -z "$scala_version" ]]; then
        scala_version="$(_spark_detect_versions 2>/dev/null | awk '{print $2}' || true)"
    fi
    if [[ -z "$scala_version" ]]; then
        scala_version="$(_spark_detect_scala_version 2>/dev/null || true)"
    fi
    if [[ -z "$scala_version" && -n "$spark_version" ]]; then
        scala_version="$(_spark_default_scala_for_spark "$spark_version")"
    fi
    local scala_binary=""
    scala_binary="$(_spark_scala_binary "$scala_version")"
    local hadoop_version
    hadoop_version="$(_spark_detect_hadoop_version 2>/dev/null || true)"
    local hadoop_mm=""
    [[ -n "$hadoop_version" ]] && hadoop_mm="${hadoop_version%.*}"
    local spark_jars_coords=""
    spark_jars_coords="$(jar_matrix_resolve 2>/dev/null || true)"
    
    # Check for local JARs first (for offline use)
    local jar_dirs=()
    if [[ -n "$spark_version" ]]; then
        jar_dirs+=("${jars_root}/spark/${spark_version}")
        [[ -n "$scala_binary" ]] && jar_dirs+=("${jars_root}/spark/${spark_version}/scala-${scala_binary}")
        [[ -n "$hadoop_mm" ]] && jar_dirs+=("${jars_root}/spark/${spark_version}/hadoop-${hadoop_mm}")
    fi
    jar_dirs+=("${jars_root}/spark" "${jars_root}")
    if [[ "${SPARK_LEGACY_JAR_DIR_ENABLE:-0}" == "1" ]]; then
        jar_dirs+=("$HOME/spark-jars" "$HOME/.spark/jars")
    fi
    
    for jar_dir in "${jar_dirs[@]}"; do
        if [[ -d "$jar_dir" ]]; then
            # Use zsh globbing instead of ls
            local jars=("$jar_dir"/*.jar(N))
            if [[ ${#jars[@]} -gt 0 ]]; then
                # Convert array to comma-separated list
                local jar_list="${(j:,:)jars}"
                deps="--jars $jar_list"
                echo "📦 Using local JARs from $jar_dir (${#jars[@]} files)" >&2
                echo "$deps"
                return 0
            fi
        fi
    done
    
    # No local JARs - check if online for Maven
    if is_online; then
        if [[ -n "$spark_jars_coords" && "$SPARK_JARS_AUTO_DOWNLOAD" == "1" && "$(command -v download_jars 2>/dev/null)" != "" ]]; then
            local download_dir="${jars_root}/spark"
            if [[ -n "$spark_version" ]]; then
                download_dir="${jars_root}/spark/${spark_version}"
                [[ -n "$scala_binary" ]] && download_dir="${download_dir}/scala-${scala_binary}"
            fi
            download_jars --dest "$download_dir" "$spark_jars_coords" || true
            if [[ -d "$download_dir" ]]; then
                local jars=("$download_dir"/*.jar(N))
                if [[ ${#jars[@]} -gt 0 ]]; then
                    local jar_list="${(j:,:)jars}"
                    deps="--jars $jar_list"
                    echo "📦 Using downloaded JARs from $download_dir (${#jars[@]} files)" >&2
                    echo "$deps"
                    return 0
                fi
            fi
        fi
        local kafka_spark_version="${SPARK_VERSION:-}"
        local kafka_scala_version="${SPARK_SCALA_VERSION:-}"
        if [[ -z "$kafka_spark_version" || -z "$kafka_scala_version" ]]; then
            local detected
            detected="$(_spark_detect_versions 2>/dev/null || true)"
            kafka_spark_version="${kafka_spark_version:-${detected%% *}}"
            kafka_scala_version="${kafka_scala_version:-${detected#* }}"
        fi
        local kafka_scala_binary=""
        if [[ -n "$kafka_scala_version" ]]; then
            kafka_scala_binary="${kafka_scala_version%.*}"
        fi
        if [[ -n "$spark_jars_coords" ]]; then
            deps="--packages $spark_jars_coords"
        elif [[ -n "$kafka_spark_version" && -n "$kafka_scala_binary" ]]; then
            deps="--packages org.apache.spark:spark-sql-kafka-0-10_${kafka_scala_binary}:${kafka_spark_version}"
        else
            deps="--packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0"
            echo "⚠️  Could not detect Spark/Scala versions; using default deps" >&2
        fi
        echo "🌐 Online: Will download Maven packages" >&2
    else
        # Offline and no local JARs - use basic Spark (will work for most jobs)
        echo "⚠️  Offline and no local JARs - using basic Spark" >&2
        deps=""
    fi
    
    echo "$deps"
}

# Smart Spark job submission
smart_spark_submit() {
    local py_file="$1"
    
    if [[ -z "$py_file" || ! -f "$py_file" ]]; then
        echo "Usage: smart_spark_submit <python_file>"
        return 1
    fi
    
    local dependencies=$(get_spark_dependencies)
    
    local mode
    mode="$(_spark_normalize_mode)"
    local master
    master="$(_spark_resolve_master "$mode")"
    if [[ "$master" == "$SPARK_MASTER_URL" ]]; then
        echo "🌐 Using cluster mode: $master"
        spark-submit \
            --master "$master" \
            --driver-memory "$SPARK_DRIVER_MEMORY" \
            --executor-memory "$SPARK_EXECUTOR_MEMORY" \
            $dependencies \
            "$py_file"
    else
        echo "💻 Using local mode: $master"
        spark-submit \
            --master "$master" \
            --driver-memory "$SPARK_DRIVER_MEMORY" \
            $dependencies \
            "$py_file"
    fi
}

# Interactive PySpark shell
pyspark_shell() {
    local dependencies=$(get_spark_dependencies)
    local master
    master="$(_spark_resolve_master)"
    pyspark --master "$master" $dependencies
}

# Spark history server
spark_history_server() {
    if [[ ! -d "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not found"
        return 1
    fi
    
    "$SPARK_HOME/sbin/start-history-server.sh"
    echo "✅ History server started: http://localhost:18080"
}

spark_install_from_tar() {
    local set_default=0
    local dry_run=0
    local version=""
    local tarball=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --default)
                set_default=1
                shift
                ;;
            --dry-run)
                dry_run=1
                shift
                ;;
            --help|-h)
                echo "Usage: spark_install_from_tar [--default] [--dry-run] <version> <tarball>" >&2
                return 0
                ;;
            *)
                if [[ -z "$version" ]]; then
                    version="$1"
                elif [[ -z "$tarball" ]]; then
                    tarball="$1"
                else
                    echo "Usage: spark_install_from_tar [--default] [--dry-run] <version> <tarball>" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done
    if [[ -z "$version" || -z "$tarball" ]]; then
        echo "Usage: spark_install_from_tar [--default] [--dry-run] <version> <tarball>" >&2
        return 1
    fi
    if [[ ! -f "$tarball" ]]; then
        echo "Tarball not found: $tarball" >&2
        return 1
    fi
    local target="$HOME/.sdkman/candidates/spark/$version"
    if (( dry_run )); then
        echo "DRY RUN: mkdir -p \"$target\""
        echo "DRY RUN: tar -xf \"$tarball\" --strip-components=1 -C \"$target\""
        echo "DRY RUN: sdk use spark \"$version\""
        if (( set_default )); then
            echo "DRY RUN: sdk default spark \"$version\""
        fi
        return 0
    fi
    if ! command -v sdk >/dev/null 2>&1; then
        echo "sdk not found; install SDKMAN first" >&2
        return 1
    fi
    mkdir -p "$target" || return 1
    tar -xf "$tarball" --strip-components=1 -C "$target" || return 1
    sdk use spark "$version"
    if (( set_default )); then
        sdk default spark "$version"
    fi
    echo "Installed Spark $version from $tarball"
}

# Submit to YARN cluster
spark_yarn_submit() {
    local script_file="$1"
    local deploy_mode="${2:-client}"
    
    if [[ -z "$script_file" || ! -f "$script_file" ]]; then
        echo "Usage: spark_yarn_submit <script_file> [client|cluster]"
        return 1
    fi
    
    if ! command -v yarn >/dev/null 2>&1; then
        echo "❌ YARN not available"
        echo "💡 Start Hadoop first: start_hadoop"
        return 1
    fi
    
    echo "🚀 Submitting to YARN..."
    local dependencies=$(get_spark_dependencies)
    
    spark-submit \
        --master yarn \
        --deploy-mode "$deploy_mode" \
        --driver-memory "$SPARK_DRIVER_MEMORY" \
        --executor-memory "$SPARK_EXECUTOR_MEMORY" \
        $dependencies \
        "$script_file"
}

# Interactive Spark shell
spark_shell() {
    local dependencies=$(get_spark_dependencies)
    local master
    master="$(_spark_resolve_master)"
    spark-shell --master "$master" $dependencies
}

# Restart Spark cluster
spark_restart() {
    spark_stop
    sleep 2
    spark_start
}

# Aliases
alias spark-ui='open http://localhost:8080'
alias spark-history='open http://localhost:18080'
alias ss='spark_status'
alias pyspark='pyspark_shell'

echo "✅ spark loaded"
