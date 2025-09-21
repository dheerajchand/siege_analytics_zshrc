#!/usr/bin/env zsh
# =====================================================
# SPARK MODULE - On-demand Apache Spark management
# =====================================================

echo "⚡ Loading Spark module..."

# =====================================================
# SPARK CONFIGURATION
# =====================================================

export SPARK_DRIVER_MEMORY="${SPARK_DRIVER_MEMORY:-2g}"
export SPARK_EXECUTOR_MEMORY="${SPARK_EXECUTOR_MEMORY:-2g}"

# SDKMAN integration for Spark
if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    source "$HOME/.sdkman/bin/sdkman-init.sh"

    # Add Spark paths if available
    if [[ -d "$HOME/.sdkman/candidates/spark/current" ]]; then
        export SPARK_HOME="$HOME/.sdkman/candidates/spark/current"
        export PATH="$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH"
    fi

    # Add Hadoop paths if available
    if [[ -d "$HOME/.sdkman/candidates/hadoop/current" ]]; then
        export HADOOP_HOME="$HOME/.sdkman/candidates/hadoop/current"
        export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"
    fi
fi

# =====================================================
# SPARK FUNCTIONS
# =====================================================

spark_status() {
    echo "⚡ Apache Spark Status"
    echo "====================="

    if command -v spark-submit >/dev/null 2>&1; then
        echo "✅ Spark available"
        echo "Version: $(spark-submit --version 2>&1 | grep -E 'version|Spark' | head -1)"
        echo "Home: ${SPARK_HOME:-'Not set'}"
        echo "Driver Memory: $SPARK_DRIVER_MEMORY"
        echo "Executor Memory: $SPARK_EXECUTOR_MEMORY"
    else
        echo "❌ Spark not found"
        echo "💡 Install with SDKMAN: sdk install spark"
    fi

    echo ""

    if command -v hadoop >/dev/null 2>&1; then
        echo "✅ Hadoop available"
        echo "Version: $(hadoop version | head -1)"
    else
        echo "❌ Hadoop not found"
    fi
}

spark_start() {
    if [[ -n "$SPARK_HOME" && -f "$SPARK_HOME/sbin/start-all.sh" ]]; then
        echo "🚀 Starting Spark cluster..."
        "$SPARK_HOME/sbin/start-all.sh"
    else
        echo "❌ Spark not properly configured"
    fi
}

spark_stop() {
    if [[ -n "$SPARK_HOME" && -f "$SPARK_HOME/sbin/stop-all.sh" ]]; then
        echo "🛑 Stopping Spark cluster..."
        "$SPARK_HOME/sbin/stop-all.sh"
    else
        echo "❌ Spark not properly configured"
    fi
}

smart_spark_submit() {
    local script="$1"
    shift

    if [[ -z "$script" ]]; then
        echo "Usage: smart_spark_submit <script.py> [args...]"
        return 1
    fi

    echo "⚡ Submitting Spark job: $script"
    spark-submit \
        --driver-memory "$SPARK_DRIVER_MEMORY" \
        --executor-memory "$SPARK_EXECUTOR_MEMORY" \
        "$script" "$@"
}

# =====================================================
# ALIASES
# =====================================================

alias spark-status='spark_status'
alias spark-start='spark_start'
alias spark-stop='spark_stop'
alias spark-submit='smart_spark_submit'

echo "✅ Spark module loaded successfully"