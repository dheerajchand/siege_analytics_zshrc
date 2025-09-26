#!/usr/bin/env zsh
# =====================================================
# SPARK FUNCTION VERIFICATION TEST
# =====================================================

echo "🧪 Testing Spark function loading..."
echo ""

# Set up environment
export ZSH_CONFIG_DIR="/Users/dheerajchand/.config/zsh"

echo "1️⃣ Testing module loading..."
source "$ZSH_CONFIG_DIR/modules/spark.module.zsh"
echo ""

echo "2️⃣ Testing critical functions exist..."
CRITICAL_SPARK_FUNCTIONS=(
    "default_spark_submit"
    "distributed_spark_submit"
    "smart_spark_submit"
    "spark_yarn_submit"
    "heavy_api_submit"
    "get_spark_dependencies"
)

all_functions_exist=true
for func in "${CRITICAL_SPARK_FUNCTIONS[@]}"; do
    if declare -f "$func" >/dev/null 2>&1; then
        echo "✅ $func - FOUND"
    else
        echo "❌ $func - MISSING"
        all_functions_exist=false
    fi
done

echo ""
if [[ "$all_functions_exist" == "true" ]]; then
    echo "🎉 ALL SPARK FUNCTIONS VERIFIED SUCCESSFULLY"
    echo ""
    echo "3️⃣ Testing function execution..."
    echo "Available commands:"
    echo "  default_spark_submit my_job.py"
    echo "  distributed_spark_submit my_job.py"
    echo "  smart_spark_submit my_job.py"
else
    echo "🚨 CRITICAL: Some Spark functions are missing!"
    echo "💡 Check: config/spark.zsh for function definitions"
fi

echo ""
echo "Test completed. Run this script in your terminal: ./test_spark_functions.zsh"