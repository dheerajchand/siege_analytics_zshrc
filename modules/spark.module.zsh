#!/usr/bin/env zsh
# =====================================================
# SPARK MODULE - Apache Spark and big data processing
# =====================================================
#
# Purpose: Apache Spark cluster management and big data processing
# Provides: Spark cluster management, job submission, Hadoop integration
# Dependencies: Apache Spark, Java, Hadoop (optional)
# =====================================================

echo "⚡ Loading Spark module..."

# Load Spark configuration and functions
if [[ -f "$ZSH_CONFIG_DIR/config/spark.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/config/spark.zsh"
    echo "✅ Spark functions loaded"
else
    echo "❌ Spark config not found: $ZSH_CONFIG_DIR/config/spark.zsh"
    return 1
fi

# Load Hadoop configuration if available
if [[ -f "$ZSH_CONFIG_DIR/config/hadoop.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/config/hadoop.zsh"
    echo "✅ Hadoop functions loaded"
fi

echo "✅ Spark module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export SPARK_MODULE_LOADED=true
