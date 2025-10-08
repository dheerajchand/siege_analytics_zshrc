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

# Load critical function guard (silently)
if [[ -f "$ZSH_CONFIG_DIR/docs/security/CRITICAL_FUNCTION_GUARD.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/docs/security/CRITICAL_FUNCTION_GUARD.zsh" >/dev/null 2>&1
fi

# Load Spark configuration and functions
if [[ -f "$ZSH_CONFIG_DIR/config/spark.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/config/spark.zsh"

    # CRITICAL: Verify functions actually loaded
    if command -v verify_critical_functions &> /dev/null && verify_critical_functions "spark"; then
        echo "✅ Spark functions loaded and verified"
    else
        echo "❌ CRITICAL: Spark functions failed to load properly"
        echo "🔧 Check: config/spark.zsh for missing function definitions"
        return 1
    fi
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
