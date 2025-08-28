# =====================================================
# SPARK CONFIGURATION MODULE
# =====================================================
# Only loaded when SPARK_HOME exists

# Spark environment
export SPARK_HOME="${SPARK_HOME:-/opt/homebrew/opt/sdkman-cli/libexec/candidates/spark/current}"
export SPARK_LOCAL_IP="127.0.0.1"
export SPARK_MASTER_HOST="127.0.0.1"
export SPARK_MASTER_PORT="7077"
export SPARK_WORKER_INSTANCES="4"
export SPARK_DRIVER_MEMORY="2g"
export SPARK_EXECUTOR_MEMORY="1g"
export SPARK_WORKER_MEMORY="2g"
export SPARK_CONF_DIR="$SPARK_HOME/conf"

# Python paths
export PYSPARK_PYTHON="/Users/dheerajchand/.pyenv/shims/python3"
export PYSPARK_DRIVER_PYTHON="/Users/dheerajchand/.pyenv/shims/python3"

# Add Spark to PATH
export PATH="$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH"

# Additional environment variables for distributed mode
export SPARK_NUM_EXECUTORS="${SPARK_NUM_EXECUTORS:-4}"
export SPARK_EXECUTOR_CORES="${SPARK_EXECUTOR_CORES:-1}"
export SPARK_DRIVER_MAX_RESULT_SIZE="${SPARK_DRIVER_MAX_RESULT_SIZE:-2g}"

# Dependency management
export DEFAULT_SPARK_JARS="org.apache.sedona:sedona-spark-shaded-3.5_2.12:1.7.1,org.datasyslab:geotools-wrapper:1.7.1-28.5,graphframes:graphframes:0.8.3-spark3.5-s_2.12"
export LOCAL_SPARK_JAR_PATH="$HOME/local_jars"
mkdir -p "$LOCAL_SPARK_JAR_PATH"

# Enhanced dependency resolution
function get_spark_dependencies {
    local online_status=$(is_online)
    if [[ "$online_status" == "online" ]]; then
        echo "--packages $DEFAULT_SPARK_JARS"
    else
        local local_jars=$(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
        if [[ -n "$local_jars" ]]; then
            echo "--jars $local_jars"
        else
            download_spark_jars_if_needed
            local_jars=$(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
            [[ -n "$local_jars" ]] && echo "--jars $local_jars" || echo ""
        fi
    fi
}

# Download essential JARs when offline
function download_spark_jars_if_needed {
    echo "📦 Downloading essential Spark JARs for offline use..."
    local jar_urls=(
        "https://repo1.maven.org/maven2/org/apache/sedona/sedona-spark-shaded-3.5_2.12/1.7.1/sedona-spark-shaded-3.5_2.12-1.7.1.jar"
        "https://repo1.maven.org/maven2/org/datasyslab/geotools-wrapper/1.7.1-28.5/geotools-wrapper-1.7.1-28.5.jar"
        "https://repo1.maven.org/maven2/graphframes/graphframes/0.8.3-spark3.5-s_2.12/graphframes-0.8.3-spark3.5-s_2.12.jar"
    )
    for url in "${jar_urls[@]}"; do
        local jar_name=$(basename "$url")
        local jar_path="$LOCAL_SPARK_JAR_PATH/$jar_name"
        if [[ ! -f "$jar_path" ]]; then
            echo "  Downloading: $jar_name"
            curl -sL "$url" -o "$jar_path" && echo "  ✅ Downloaded: $jar_name" || { echo "  ❌ Failed: $jar_name"; rm -f "$jar_path"; }
        fi
    done
}

# =====================================================
# SPARK CLUSTER MANAGEMENT
# =====================================================

function spark_start {
    echo "🚀 Starting Spark cluster..."
    pkill -f 'org.apache.spark.deploy.master.Master' 2>/dev/null
    pkill -f 'org.apache.spark.deploy.worker.Worker' 2>/dev/null
    sleep 3
    
    $SPARK_HOME/sbin/start-master.sh
    sleep 5
    
    for i in {1..4}; do
        $SPARK_HOME/sbin/start-worker.sh spark://127.0.0.1:7077
        sleep 1
    done
    
    export SPARK_MASTER_URL="spark://127.0.0.1:7077"
    echo "✅ Cluster started! UI: http://127.0.0.1:8080"
}

function spark_stop {
    echo "🛑 Stopping Spark cluster..."
    [[ -f "$SPARK_HOME/sbin/stop-all.sh" ]] && $SPARK_HOME/sbin/stop-all.sh
    pkill -f 'org.apache.spark.deploy.master.Master' 2>/dev/null
    pkill -f 'org.apache.spark.deploy.worker.Worker' 2>/dev/null
    unset SPARK_MASTER_URL
    echo "✅ Cluster stopped"
}

function spark_restart {
    spark_stop && sleep 3 && spark_start
}

function spark_status {
    echo "📊 Spark Cluster Status:"
    echo "   Master processes: $(ps aux | grep 'spark.deploy.master.Master' | grep -v grep | wc -l)"
    echo "   Worker processes: $(ps aux | grep 'spark.deploy.worker.Worker' | grep -v grep | wc -l)"
    echo "   Master URL: ${SPARK_MASTER_URL:-'Not set'}"
    echo "   Master UI: http://127.0.0.1:8080"
}

# =====================================================
# SPARK SUBMIT FUNCTIONS
# =====================================================

function default_spark_submit() {
    local py_file="$1"
    [[ -z "$py_file" || ! -f "$py_file" ]] && { echo "Usage: default_spark_submit <python_file>"; return 1; }
    
    echo "🚀 Local Spark submit with enhanced dependencies..."
    local dependencies=$(get_spark_dependencies)
    eval "spark-submit \
        --master 'local[*]' \
        --driver-memory $SPARK_DRIVER_MEMORY \
        --executor-memory $SPARK_EXECUTOR_MEMORY \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
        $dependencies \
        '$py_file'"
}

function distributed_spark_submit() {
    local py_file="$1"
    local master_url="${2:-$SPARK_MASTER_URL}"
    [[ -z "$py_file" || ! -f "$py_file" ]] && { echo "Usage: distributed_spark_submit <python_file> [master_url]"; return 1; }
    [[ -z "$master_url" ]] && { echo "❌ No master URL. Run: spark_start"; return 1; }
    
    echo "🌐 Distributed Spark submit..."
    local dependencies=$(get_spark_dependencies)
    eval "spark-submit \
        --master '$master_url' \
        --deploy-mode client \
        --driver-memory $SPARK_DRIVER_MEMORY \
        --executor-memory $SPARK_EXECUTOR_MEMORY \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
        $dependencies \
        '$py_file'"
}

function heavy_api_submit {
    local py_file="$1"
    local mode="${2:-auto}"
    [[ -z "$py_file" || ! -f "$py_file" ]] && { echo "Usage: heavy_api_submit <python_file> [mode]"; return 1; }
    
    echo "🚀 Heavy API Workload Submit..."
    
    local heavy_configs=(
        "--conf spark.sql.adaptive.enabled=true"
        "--conf spark.network.timeout=600s"
        "--conf spark.python.worker.reuse=true"
        "--conf spark.log.level=ERROR"
        "--conf spark.ui.showConsoleProgress=false"
    )
    
    local dependencies=$(get_spark_dependencies)
    local config_string="${heavy_configs[*]}"
    
    case "$mode" in
        auto|local)
            eval "spark-submit --master 'local[*]' --driver-memory 4g $config_string $dependencies '$py_file'"
            ;;
        distributed)
            [[ -z "$SPARK_MASTER_URL" ]] && { echo "❌ No cluster. Run: spark_start"; return 1; }
            eval "spark-submit --master '$SPARK_MASTER_URL' --driver-memory 4g $config_string $dependencies '$py_file'"
            ;;
        *)
            echo "❌ Invalid mode: $mode. Use: auto, local, distributed"
            return 1
            ;;
    esac
}

# =====================================================
# TESTING FUNCTIONS
# =====================================================

function test_spark_comprehensive {
    echo "🧪 Comprehensive Spark functionality test..."
    local test_script="/tmp/spark_comprehensive_test.py"
    cat > "$test_script" << 'PYTHON_EOF'
from pyspark.sql import SparkSession
print("🚀 Starting comprehensive Spark test...")

spark = SparkSession.builder \
    .appName("ComprehensiveSparkTest") \
    .config("spark.sql.extensions", "org.apache.sedona.sql.SedonaSqlExtensions") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .getOrCreate()

print("✅ Spark Context created successfully")
print(f"   Master: {spark.sparkContext.master}")

# Test basic operations
rdd = spark.sparkContext.parallelize(range(100), 4)
result = rdd.map(lambda x: x * x).sum()
print(f"✅ RDD computation result: {result}")

# Test Sedona if available
try:
    from sedona.spark import SedonaContext
    sedona = SedonaContext.create(spark)
    print("✅ Sedona context created")
    
    distance_result = sedona.sql("""
        SELECT ST_Distance(
            ST_Point(-0.1275, 51.5072),
            ST_Point(-74.0060, 40.7128)
        ) as distance_degrees
    """).collect()[0]["distance_degrees"]
    print(f"✅ Sedona distance calculation: {distance_result:.4f} degrees")
except Exception as e:
    print(f"⚠️  Sedona failed: {e}")

spark.stop()
print("🛑 Test completed")
PYTHON_EOF
    
    if [[ -n "$SPARK_MASTER_URL" ]]; then
        distributed_spark_submit "$test_script"
    else
        default_spark_submit "$test_script"
    fi
    rm -f "$test_script"
}

# =====================================================
# CONVENIENCE ALIASES
# =====================================================

alias sstart='spark_start'
alias sstop='spark_stop'
alias srestart='spark_restart'
alias sstatus='spark_status'
alias ssubmit='default_spark_submit'
alias dsubmit='distributed_spark_submit'
alias hsubmit='heavy_api_submit'
alias stest='test_spark_comprehensive'

echo "⚡ Spark module loaded - $(spark-submit --version 2>&1 | head -1 || echo 'Spark ready')"
