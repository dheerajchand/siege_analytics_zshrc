#!/usr/bin/env zsh
# Test script to verify systematic fixes work correctly
# This script tests the fixes in clean environments to avoid context contamination

echo "🧪 Testing Systematic Fixes"
echo "=========================="

# Test 1: Normal module loading
echo ""
echo "📋 Test 1: Normal module loading"
echo "--------------------------------"
result1=$(env -i zsh -c "
    export HOME=$HOME
    export PATH=/usr/local/bin:/usr/bin:/bin
    export ZSH_CONFIG_DIR=/Users/dheerajchand/.config/zsh
    source ~/.zshrc 2>/dev/null
    echo \$LOADED_MODULES
")
echo "Result: [$result1]"
if [[ "$result1" == "utils python" ]]; then
    echo "✅ PASS: Modules loaded correctly"
else
    echo "❌ FAIL: Expected 'utils python', got '$result1'"
fi

# Test 2: Missing modules directory
echo ""
echo "📋 Test 2: Missing modules directory"
echo "-----------------------------------"
# Create temporary backup
cp -r modules modules.test.backup 2>/dev/null
mv modules modules.disabled 2>/dev/null

result2=$(env -i zsh -c "
    export HOME=$HOME
    export PATH=/usr/local/bin:/usr/bin:/bin
    export ZSH_CONFIG_DIR=/Users/dheerajchand/.config/zsh
    source ~/.zshrc 2>/dev/null
    echo \$LOADED_MODULES
")
echo "Result: [$result2]"
if [[ -z "$result2" ]]; then
    echo "✅ PASS: LOADED_MODULES empty when modules fail to load"
else
    echo "❌ FAIL: Expected empty, got '$result2'"
fi

# Restore modules
mv modules.disabled modules 2>/dev/null

# Test 3: Status display with failed modules
echo ""
echo "📋 Test 3: Status display with failed modules"
echo "--------------------------------------------"
mv modules modules.disabled 2>/dev/null

status_output=$(env -i zsh -c "
    export HOME=$HOME
    export PATH=/usr/local/bin:/usr/bin:/bin
    export ZSH_CONFIG_DIR=/Users/dheerajchand/.config/zsh
    source ~/.zshrc 2>/dev/null
" | grep -E "(Module Loading Failed|Production Ready)")

echo "Status output: $status_output"
if [[ "$status_output" == *"Module Loading Failed"* ]]; then
    echo "✅ PASS: Status correctly shows failure state"
else
    echo "❌ FAIL: Status should show 'Module Loading Failed'"
fi

# Restore modules
mv modules.disabled modules 2>/dev/null

echo ""
echo "🎯 Test Summary"
echo "==============="
echo "These tests verify the systematic fixes work correctly"
echo "in clean environments without context contamination."
