#!/usr/bin/env zsh
# =====================================================
# PYTHON HELP FUNCTION TEST
# =====================================================

echo "🐍 Testing Python help functions..."
echo ""

# Set up environment
export ZSH_CONFIG_DIR="/Users/dheerajchand/.config/zsh"

echo "1️⃣ Loading Python module..."
source "$ZSH_CONFIG_DIR/modules/python.module.zsh"
echo ""

echo "2️⃣ Testing Python help functions..."
PYTHON_HELP_FUNCTIONS=(
    "python_help"
    "pyhelp"
    "python_status"
)

all_functions_exist=true
for func in "${PYTHON_HELP_FUNCTIONS[@]}"; do
    if declare -f "$func" >/dev/null 2>&1; then
        echo "✅ $func - FOUND"
    else
        echo "❌ $func - MISSING"
        all_functions_exist=false
    fi
done

echo ""
if [[ "$all_functions_exist" == "true" ]]; then
    echo "🎉 ALL PYTHON HELP FUNCTIONS VERIFIED"
    echo ""
    echo "3️⃣ Testing function execution..."
    echo "Running python_help..."
    python_help | head -10
    echo ""
    echo "Running pyhelp..."
    pyhelp | head -10
else
    echo "🚨 CRITICAL: Some Python help functions are missing!"
fi

echo ""
echo "Test completed."