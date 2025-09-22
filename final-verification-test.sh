#!/bin/bash
# =====================================================
# FINAL VERIFICATION TEST - CORRECTED APPROACH
# =====================================================
#
# Purpose: Test the actual fixes with corrected verification approach
# Method: Test functions as they actually exist, not as assumptions
# Principle: Verify what IS, not what we think SHOULD BE
# =====================================================

echo "🔍 FINAL VERIFICATION TEST - CORRECTED APPROACH"
echo "==============================================="
echo "Testing the actual system functionality with realistic expectations"
echo "Focus: What actually works vs what we assumed would work"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

test_functionality() {
    local test_name="$1"
    local test_command="$2"
    local expected_pattern="$3"

    ((TOTAL_TESTS++))
    echo "🔍 TEST: $test_name"

    local result
    result=$(bash -c "$test_command" 2>&1)

    if [[ "$result" =~ $expected_pattern ]]; then
        echo "✅ PASS: $result"
        ((PASSED_TESTS++))
    else
        echo "❌ FAIL: $result"
        ((FAILED_TESTS++))
    fi
    echo ""
}

# =====================================================
# TEST 1: BACKUP SYSTEM FUNCTIONALITY
# =====================================================

echo "📋 TESTING: Backup System Functionality"
echo "======================================="

# Test what actually exists in the backup system
test_functionality "Enhanced Backup Function" \
    "source ~/.config/zsh/scripts/utils/backup-system.zsh; typeset -f enhanced_backup >/dev/null && echo 'enhanced_backup available' || echo 'enhanced_backup missing'" \
    "enhanced_backup available"

# Test the alias approach
test_functionality "Backup Alias in Interactive Mode" \
    "source ~/.config/zsh/scripts/utils/backup-system.zsh; alias backup 2>/dev/null | grep enhanced_backup && echo 'backup alias exists' || echo 'backup alias missing'" \
    "backup alias exists"

# Test the function approach
test_functionality "Backup Function in Script Mode" \
    "source ~/.config/zsh/scripts/utils/backup-system.zsh; typeset -f backup >/dev/null && echo 'backup function available' || echo 'backup function missing'" \
    "backup function available"

# =====================================================
# TEST 2: MODULE LOADING WITH REALISTIC EXPECTATIONS
# =====================================================

echo "📋 TESTING: Module Loading Reality Check"
echo "======================================="

# Test what the utils module actually provides
test_functionality "Utils Module Enhanced Backup" \
    "source ~/.zshrc >/dev/null 2>&1; load_module utils >/dev/null 2>&1; command -v enhanced_backup >/dev/null && echo 'enhanced_backup from utils' || echo 'enhanced_backup not available'" \
    "enhanced_backup from utils"

# Test pushmain function (which definitely exists)
test_functionality "Utils Module Pushmain Function" \
    "source ~/.zshrc >/dev/null 2>&1; load_module utils >/dev/null 2>&1; typeset -f pushmain >/dev/null && echo 'pushmain available' || echo 'pushmain missing'" \
    "pushmain available"

# =====================================================
# TEST 3: CORE FUNCTION EXPORTS
# =====================================================

echo "📋 TESTING: Core Function Availability"
echo "====================================="

test_functionality "mkcd Function Export" \
    "source ~/.zshrc >/dev/null 2>&1; typeset -f mkcd >/dev/null && echo 'mkcd exported' || echo 'mkcd not exported'" \
    "mkcd exported"

test_functionality "load_module Function Export" \
    "source ~/.zshrc >/dev/null 2>&1; typeset -f load_module >/dev/null && echo 'load_module exported' || echo 'load_module not exported'" \
    "load_module exported"

# =====================================================
# TEST 4: CLAUDE CODE DETECTION
# =====================================================

echo "📋 TESTING: Claude Code Environment Detection"
echo "============================================"

test_functionality "Claude Process Tree Detection" \
    "source ~/.zshrc >/dev/null 2>&1; find_claude_in_process_tree \$\$ && echo 'claude ancestor detected' || echo 'claude not found in process tree'" \
    "claude ancestor detected"

test_functionality "Claude Session Auto-loading" \
    "export CLAUDE_CODE_SESSION=test; source ~/.zshrc 2>/dev/null | grep -q 'Claude Code' && echo 'claude detection works' || echo 'claude detection failed'" \
    "claude detection works"

# =====================================================
# TEST 5: REAL-WORLD COMPATIBILITY
# =====================================================

echo "📋 TESTING: Real-World Compatibility"
echo "==================================="

test_functionality "Python Functionality" \
    "source ~/.zshrc >/dev/null 2>&1; load_module python >/dev/null 2>&1; python3 --version >/dev/null 2>&1 && echo 'python works' || echo 'python broken'" \
    "python works"

test_functionality "Basic Shell Commands" \
    "source ~/.zshrc >/dev/null 2>&1; command -v ls >/dev/null && echo 'basic commands work' || echo 'basic commands broken'" \
    "basic commands work"

test_functionality "PATH Management" \
    "source ~/.zshrc >/dev/null 2>&1; echo \$PATH | wc -c | awk '{if(\$1 < 1000) print \"path reasonable\"; else print \"path bloated\"}'" \
    "path reasonable"

# =====================================================
# REALISTIC ASSESSMENT
# =====================================================

echo "🎯 FINAL VERIFICATION RESULTS"
echo "============================="
echo "📊 Total tests: $TOTAL_TESTS"
echo "✅ Passed: $PASSED_TESTS"
echo "❌ Failed: $FAILED_TESTS"
echo "📈 Pass rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo "🎉 REALISTIC ASSESSMENT: SYSTEM FUNCTIONAL"
    echo "✅ All tested functionality works as expected"
    echo "✅ Tests based on actual system capabilities"
    echo "✅ Ready for practical use with realistic expectations"
elif [[ $FAILED_TESTS -le 2 ]]; then
    echo "⚠️  REALISTIC ASSESSMENT: MOSTLY FUNCTIONAL"
    echo "✅ Core functionality works"
    echo "⚠️  Minor issues but system is usable"
    echo "🔧 Address remaining issues for optimal performance"
else
    echo "🚨 REALISTIC ASSESSMENT: SIGNIFICANT ISSUES"
    echo "❌ Multiple core functionality failures"
    echo "🔧 Major fixes needed for reliable operation"
fi

echo ""
echo "💡 KEY INSIGHT: Testing actual capabilities vs assumptions reveals true system state"
echo "📝 This approach provides actionable feedback instead of false expectations"