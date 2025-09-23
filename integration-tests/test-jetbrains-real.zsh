#!/usr/bin/env zsh
# =====================================================
# REAL JETBRAINS INTEGRATION TEST
# =====================================================
# Tests actual JetBrains IDE functionality:
# 1. Test JetBrains module loading
# 2. Test IDE detection
# 3. Test project setup functions
# 4. Test IDE integration features
# =====================================================

echo "🧠 REAL JETBRAINS INTEGRATION TEST"
echo "=================================="

# Load zsh config
source ~/.zshrc >/dev/null 2>&1

echo ""
echo "📋 Test 1: JetBrains module loading"
echo "----------------------------------"

if load_module jetbrains 2>&1; then
    echo "✅ JetBrains module loaded"
else
    echo "❌ JetBrains module loading failed"
fi

echo ""
echo "📋 Test 2: JetBrains functions availability"
echo "------------------------------------------"

jetbrains_functions=("jetbrains_status" "pycharm_project" "dataspell_project" "intellij_project" "jetbrains_detect")

for func in "${jetbrains_functions[@]}"; do
    if command -v "$func" >/dev/null 2>&1; then
        echo "✅ $func available"
    else
        echo "❌ $func not found"
    fi
done

echo ""
echo "📋 Test 3: IDE detection"
echo "-----------------------"

echo "Current environment variables:"
echo "  JETBRAINS_IDE: ${JETBRAINS_IDE:-'Not set'}"
echo "  PYCHARM_HOSTED: ${PYCHARM_HOSTED:-'Not set'}"
echo "  DATASPELL_IDE: ${DATASPELL_IDE:-'Not set'}"
echo "  TERM_PROGRAM: ${TERM_PROGRAM:-'Not set'}"

echo ""
echo "📋 Test 4: JetBrains installation detection"
echo "------------------------------------------"

# Check for JetBrains installations
jetbrains_apps=("PyCharm" "DataSpell" "IntelliJ IDEA" "WebStorm" "PhpStorm")

for app in "${jetbrains_apps[@]}"; do
    if [[ -d "/Applications/$app.app" ]]; then
        echo "✅ $app installed"
    else
        echo "❌ $app not found"
    fi
done

echo ""
echo "📋 Test 5: JetBrains status reporting"
echo "------------------------------------"

if command -v jetbrains_status >/dev/null 2>&1; then
    echo "Testing JetBrains status..."
    jetbrains_status 2>&1
else
    echo "❌ jetbrains_status not available"
fi

echo ""
echo "🎯 JETBRAINS INTEGRATION TEST COMPLETE"
echo "======================================"
