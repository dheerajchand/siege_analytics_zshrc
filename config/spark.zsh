#!/usr/bin/env zsh

# =====================================================
# APACHE SPARK MODULE
# =====================================================
# 
# Cross-platform Apache Spark configuration and utilities
# Supports local, distributed, and YARN execution modes
# Optimized for different workload types (ML, API-heavy, etc.)
# =====================================================

# Module identification
export SPARK_MODULE_LOADED="true"

# =====================================================
# SPARK HELPER FUNCTIONS
# =====================================================

spark_master_running() {
    # Check if Spark master is running
    if command -v nc >/dev/null 2>&1; then
        nc -z localhost 7077 2>/dev/null
    else
        pgrep -f "spark.deploy.master.Master" >/dev/null 2>&1
    fi
}

spark_worker_running() {
    # Check if Spark worker is running
    pgrep -f "spark.deploy.worker.Worker" >/dev/null 2>&1
}

# =====================================================
# SMART SPARK DEPENDENCY MANAGEMENT
# =====================================================

ensure_spark_available() {
    # Smart function to ensure Spark is available
    # Default: Use SDKMAN for installation (preferred method)
    
    # Check if Spark is available via SDKMAN
    if [[ -n "$SDKMAN_DIR" ]] && [[ -f "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        if ! sdk list spark 2>/dev/null | grep -q "installed"; then
            echo "🔄 Installing Spark via SDKMAN (default method)..."
            sdk install spark
            if [[ $? -eq 0 ]]; then
                echo "✅ Spark installed via SDKMAN"
                # Reinitialize SDKMAN to pick up new installation
                source "$SDKMAN_DIR/bin/sdkman-init.sh"
                return 0
            else
                echo "❌ Spark installation via SDKMAN failed"
                return 1
            fi
        else
            echo "✅ Spark already available via SDKMAN"
            return 0
        fi
    else
        echo "⚠️  SDKMAN not available - manual Spark installation required"
        echo "💡 Install SDKMAN: curl -s \"https://get.sdkman.io\" | bash"
        return 1
    fi
}

start_spark_cluster() {
    # Start local Spark cluster
    ensure_spark_available || return 1
    
    if [[ -z "$SPARK_HOME" ]]; then
        echo "❌ SPARK_HOME not set"
        return 1
    fi
    
    echo "🚀 Starting Spark cluster..."
    
    # Start master
    if ! spark_master_running; then
        echo "▶️  Starting Spark master..."
        "$SPARK_HOME/sbin/start-master.sh"
        sleep 2
    else
        echo "✅ Master already running"
    fi
    
    # Start worker
    if ! spark_worker_running; then
        echo "▶️  Starting Spark worker..."
        "$SPARK_HOME/sbin/start-worker.sh" spark://localhost:7077
    else
        echo "✅ Worker already running"
    fi
    
    echo "✅ Spark cluster started"
}

# =====================================================
# SPARK ENVIRONMENT SETUP
# =====================================================

setup_spark_environment() {
    # Auto-detect and configure Spark
    local spark_candidates=()
    
    # Platform-specific Spark locations
    case "$ZSH_PLATFORM" in
        "macos")
            spark_candidates=(
                "/opt/homebrew/opt/apache-spark/libexec"
                "/usr/local/opt/apache-spark/libexec"
                "$HOME/spark"
                "$HOME/apache-spark"
            )
            ;;
        "linux")
            spark_candidates=(
                "/opt/spark"
                "/usr/local/spark"
                "/opt/apache-spark"
                "/usr/local/apache-spark"
                "$HOME/spark"
                "$HOME/apache-spark"
            )
            ;;
    esac
    
    # Check SDKMAN installations
    if [[ -n "$SDKMAN_DIR" ]]; then
        local sdkman_spark="$SDKMAN_DIR/candidates/spark/current"
        [[ -d "$sdkman_spark" ]] && spark_candidates=("$sdkman_spark" "${spark_candidates[@]}")
    fi
    
    # Find Spark installation
    for candidate in "${spark_candidates[@]}"; do
        if [[ -d "$candidate" && -f "$candidate/bin/spark-submit" ]]; then
            export SPARK_HOME="$candidate"
            break
        fi
    done
    
    if [[ -z "$SPARK_HOME" ]]; then
        [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "⚠️  Apache Spark not found - functions will be limited"
        return 1
    fi
    
    # Configure Spark environment
    export SPARK_CONF_DIR="$SPARK_HOME/conf"
    export PYSPARK_PYTHON=python3
    export PYSPARK_DRIVER_PYTHON=python3
    
    # Add Spark to PATH (with fallback if path_add not available)
    if command -v path_add >/dev/null 2>&1; then
        path_add "$SPARK_HOME/bin"
        path_add "$SPARK_HOME/sbin"
    else
        # Fallback PATH addition
        [[ ":$PATH:" != *":$SPARK_HOME/bin:"* ]] && export PATH="$SPARK_HOME/bin:$PATH"
        [[ ":$PATH:" != *":$SPARK_HOME/sbin:"* ]] && export PATH="$SPARK_HOME/sbin:$PATH"
    fi
    
    # Default configurations
    # Note: Spark configuration variables are defined in main zshrc centralized section:
    # - SPARK_DRIVER_MEMORY, SPARK_EXECUTOR_MEMORY, SPARK_MASTER_URL
    # - SPARK_NUM_EXECUTORS, SPARK_EXECUTOR_CORES, SPARK_DRIVER_MAX_RESULT_SIZE
    
    # Container-specific adjustments
    if [[ "$ZSH_IS_DOCKER" == "true" ]]; then
        # Reduce memory requirements for containers
        export SPARK_DRIVER_MEMORY="1g"
        export SPARK_EXECUTOR_MEMORY="512m"
    fi
}

# =====================================================
# MAIN SPARK FUNCTIONS
# =====================================================

spark_start() {
    #
    # Start local Spark cluster with intelligent dependency management
    #
    # Description:
    #   Starts a complete Apache Spark cluster (master + worker) with automatic
    #   dependency resolution. Will auto-install Spark via SDKMAN if not available,
    #   configure environment variables, and start both master and worker processes.
    #
    # Usage:
    #   spark_start
    #
    # Returns:
    #   0 if successful, 1 if failed
    #
    # Examples:
    #   spark_start                    # Start cluster with defaults
    #   SPARK_DRIVER_MEMORY=4g spark_start  # Start with custom memory
    #
    echo "🚀 Starting Apache Spark cluster..."
    
    # Ensure Spark is available
    if ! command -v spark-submit >/dev/null 2>&1; then
        echo "🔍 Spark not found, attempting to install..."
        ensure_spark_available || {
            echo "❌ Could not install Spark automatically"
            echo "💡 Please install Spark manually or via SDKMAN"
            return 1
        }
    fi
    
    # Setup environment if needed
    setup_spark_environment 2>/dev/null || true
    
    # Start cluster
    start_spark_cluster
}

spark_stop() {
    # Stop Spark cluster
    echo "🛑 Stopping Spark cluster..."
    
    if [[ -n "$SPARK_HOME" ]]; then
        "$SPARK_HOME/sbin/stop-worker.sh" 2>/dev/null || true
        "$SPARK_HOME/sbin/stop-master.sh" 2>/dev/null || true
    fi
    
    echo "✅ Spark cluster stopped"
}

spark_status() {
    # Show comprehensive Spark status
    echo "⚡ Apache Spark Status"
    echo "===================="
    echo ""
    
    # Configuration
    echo "Configuration:"
    echo "  SPARK_HOME: ${SPARK_HOME:-Not set}"
    echo "  Driver Memory: ${SPARK_DRIVER_MEMORY:-2g}"
    echo "  Executor Memory: ${SPARK_EXECUTOR_MEMORY:-1g}"
    echo "  Master URL: ${SPARK_MASTER_URL:-spark://localhost:7077}"
    echo ""
    
    # Cluster status
    echo "Cluster Status:"
    if spark_master_running; then
        local master_pid=$(pgrep -f "spark.deploy.master.Master" | head -1)
        echo "  ✅ Master: Running (PID: $master_pid)"
        echo "     Web UI: http://localhost:8080"
    else
        echo "  ❌ Master: Not running"
    fi
    
    if spark_worker_running; then
        local worker_pids=$(pgrep -f "spark.deploy.worker.Worker" | tr '\n' '\n')
        echo "  ✅ Worker: Running (PID: $worker_pids)"
        echo "     Web UI: http://localhost:8081"
    else
        echo "  ❌ Worker: Not running"
    fi
    
    echo ""
    
    # Check connectivity
    echo "Connectivity:"
    if nc -z localhost 7077 2>/dev/null; then
        echo "  ✅ Master port (7077): Accessible"
    else
        echo "  ❌ Master port (7077): Not accessible"
    fi
    
    if nc -z localhost 8080 2>/dev/null; then
        echo "  ✅ Master Web UI (8080): Accessible"
    else
        echo "  ❌ Master Web UI (8080): Not accessible"
    fi
    
    # System status
    echo ""
    echo "System:"
    if command -v spark-submit >/dev/null 2>&1; then
        echo "  ✅ spark-submit: Available"
    else
        echo "  ❌ spark-submit: Not found"
    fi
    
    if command -v pyspark >/dev/null 2>&1; then
        echo "  ✅ pyspark: Available"  
    else
        echo "  ❌ pyspark: Not found"
    fi
}

# =====================================================
# SPARK TESTING FUNCTIONS
# =====================================================

spark_test_simple() {
    #
    # Quick Spark functionality test using PySpark
    #
    # Description:
    #   Performs a simple Spark functionality test by creating a SparkSession,
    #   running basic operations, and verifying the cluster is working.
    #   This is a lightweight test suitable for development validation.
    #
    # Usage:
    #   spark_test_simple
    #
    # Returns:
    #   0 if test passes, 1 if test fails
    #
    echo "🧪 Quick Spark functionality test..."
    
    # Check if Spark is available
    if ! command -v spark-submit >/dev/null 2>&1; then
        echo "❌ Spark not found. Run spark_start or ensure_spark_available first."
        return 1
    fi
    
    # Check if Python is available
    if ! command -v python3 >/dev/null 2>&1; then
        echo "❌ Python3 not found. Install Python to run Spark tests."
        return 1
    fi
    
    # Run simple PySpark test
    python3 -c "
import sys
try:
    from pyspark.sql import SparkSession
    
    # Create SparkSession
    spark = SparkSession.builder \
        .appName('QuickSparkTest') \
        .master('local[2]') \
        .config('spark.sql.execution.arrow.pyspark.enabled', 'false') \
        .getOrCreate()
    
    # Simple test operations
    data = [1, 2, 3, 4, 5]
    rdd = spark.sparkContext.parallelize(data)
    result = rdd.map(lambda x: x * 2).collect()
    
    # Verify results
    expected = [2, 4, 6, 8, 10]
    if result == expected:
        print('✅ Basic RDD operations: PASSED')
    else:
        print(f'❌ Basic RDD operations: FAILED (got {result}, expected {expected})')
        sys.exit(1)
    
    # Test DataFrame operations  
    df = spark.createDataFrame([(1, 'Alice'), (2, 'Bob')], ['id', 'name'])
    count = df.count()
    
    if count == 2:
        print('✅ DataFrame operations: PASSED')
    else:
        print(f'❌ DataFrame operations: FAILED (got count {count}, expected 2)')
        sys.exit(1)
    
    # Cleanup
    spark.stop()
    print('🎉 Quick Spark test completed successfully!')
    
except ImportError as e:
    print(f'❌ PySpark not available: {e}')
    print('💡 Install with: pip install pyspark')
    sys.exit(1)
except Exception as e:
    print(f'❌ Test failed: {e}')
    sys.exit(1)
" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Spark functionality test PASSED"
        return 0
    else
        echo "❌ Spark functionality test FAILED"
        echo "💡 Try running: spark_start && spark_test_simple"
        return 1
    fi
}

# =====================================================
# ALIASES
# =====================================================

alias spark-start='spark_start'
alias spark-stop='spark_stop'
alias spark-status='spark_status'

# =====================================================
# INITIALIZATION
# =====================================================

# Setup Spark environment (with error handling)
setup_spark_environment 2>/dev/null || true

# Show setup status if verbose
if [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && [[ -n "$SPARK_HOME" ]]; then
    echo "⚡ Spark: $(spark-submit --version 2>&1 | head -n1 | cut -d' ' -f5) at $SPARK_HOME"
fi