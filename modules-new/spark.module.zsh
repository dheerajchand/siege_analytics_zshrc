#!/usr/bin/env zsh
# =====================================================
# SPARK MODULE - Apache Spark and big data tools
# =====================================================
#
# Purpose: Apache Spark, Hadoop, and big data ecosystem management
# Provides: Spark operations, cluster management, job submission
# Dependencies: centralized variables, SDKMAN
# =====================================================

echo "⚡ Loading Spark module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# SPARK ENVIRONMENT SETUP
# =====================================================

# Setup SDKMAN if available (uses centralized paths)
if [[ -f "$SDKMAN_INIT_SCRIPT" ]]; then
    source "$SDKMAN_INIT_SCRIPT"

    # Setup Spark (uses centralized SPARK_*_PATH variables)
    if [[ -d "$SPARK_HOME_PATH" ]]; then
        export SPARK_HOME="$SPARK_HOME_PATH"
        export PATH="$SPARK_BIN_PATH:$SPARK_SBIN_PATH:$PATH"
    fi

    # Setup Hadoop (uses centralized HADOOP_*_PATH variables)
    if [[ -d "$HADOOP_HOME_PATH" ]]; then
        export HADOOP_HOME="$HADOOP_HOME_PATH"
        export PATH="$HADOOP_BIN_PATH:$HADOOP_SBIN_PATH:$PATH"
    fi
fi

# =====================================================
# SPARK FUNCTIONS
# =====================================================

# Purpose: Show comprehensive Spark and Hadoop status
# Arguments: None
# Returns: 0 always
# Usage: spark_status
spark_status() {
    echo "⚡ Apache Spark Status"
    echo "====================="

    # Spark installation
    if command -v spark-submit >/dev/null 2>&1; then
        echo "✅ Spark: $(spark-submit --version 2>&1 | head -1)"
        echo "📍 SPARK_HOME: $SPARK_HOME"
    else
        echo "❌ Spark: Not available"
    fi

    # Hadoop installation
    if command -v hadoop >/dev/null 2>&1; then
        echo "✅ Hadoop: $(hadoop version | head -1)"
        echo "📍 HADOOP_HOME: $HADOOP_HOME"
    else
        echo "❌ Hadoop: Not available"
    fi

    # SDKMAN status
    if command -v sdk >/dev/null 2>&1; then
        echo "✅ SDKMAN: Available"
    else
        echo "❌ SDKMAN: Not available"
    fi

    # Configuration
    echo "🔧 Configuration:"
    echo "  Driver Memory: $SPARK_DRIVER_MEMORY"
    echo "  Executor Memory: $SPARK_EXECUTOR_MEMORY"
    echo "  Driver Cores: $SPARK_DRIVER_CORES"
    echo "  Executor Cores: $SPARK_EXECUTOR_CORES"
}

# Purpose: Start Spark services (master and worker)
# Arguments: None
# Returns: 0 on success, 1 on error
# Usage: spark_start
spark_start() {
    if [[ -z "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not set"
        return 1
    fi

    echo "🚀 Starting Spark services..."
    $SPARK_HOME/sbin/start-master.sh
    $SPARK_HOME/sbin/start-worker.sh spark://localhost:7077
    echo "✅ Spark services started"
    echo "🌐 Web UI: http://localhost:8080"
}

# Purpose: Stop Spark services
# Arguments: None
# Returns: 0 always
# Usage: spark_stop
spark_stop() {
    if [[ -z "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not set"
        return 1
    fi

    echo "🛑 Stopping Spark services..."
    $SPARK_HOME/sbin/stop-worker.sh
    $SPARK_HOME/sbin/stop-master.sh
    echo "✅ Spark services stopped"
}

# Purpose: Intelligent Spark job submission with optimized settings
# Arguments: $@ - all arguments passed to spark-submit
# Returns: spark-submit exit code
# Usage: smart_spark_submit --class MyClass myapp.jar
smart_spark_submit() {
    if ! command -v spark-submit >/dev/null 2>&1; then
        echo "❌ spark-submit not available"
        return 1
    fi

    echo "⚡ Submitting Spark job with optimized settings..."

    spark-submit \
        --driver-memory "$SPARK_DRIVER_MEMORY" \
        --executor-memory "$SPARK_EXECUTOR_MEMORY" \
        --driver-cores "$SPARK_DRIVER_CORES" \
        --executor-cores "$SPARK_EXECUTOR_CORES" \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.sql.adaptive.coalescePartitions.enabled=true \
        "$@"
}

# =====================================================
# ALIASES
# =====================================================

alias spark-status='spark_status'
alias spark-start='spark_start'
alias spark-stop='spark_stop'
alias spark-submit='smart_spark_submit'

echo "✅ Spark module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export SPARK_MODULE_LOADED=true