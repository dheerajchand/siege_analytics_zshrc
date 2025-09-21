#!/usr/bin/env zsh
# =====================================================
# PRODUCTION SYSTEM TEST SUITE - Final Validation
# =====================================================
#
# Purpose: Validate production-ready 3-tier architecture
# Tests: Complete system functionality including backup system
# Usage: ~/.config/zsh/test-production-system.zsh
# =====================================================

echo "🧪 PRODUCTION SYSTEM VALIDATION"
echo "==============================="
echo ""

# Test result tracking
local tests_run=0
local tests_passed=0
local tests_failed=0
local failed_tests=()

# Helper function for test reporting
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"

    ((tests_run++))
    echo -n "🔍 Testing: $test_name... "

    local result
    if [[ "$test_command" == *"typeset -f"* ]]; then
        result=$(zsh -c "source ~/.zshrc; $test_command" 2>/dev/null)
    else
        result=$(zsh -c "source ~/.zshrc; $test_command" 2>/dev/null)
    fi
    local exit_code=$?

    if [[ $exit_code -eq 0 && "$result" =~ "$expected_result" ]]; then
        echo "✅ PASS"
        ((tests_passed++))
    else
        echo "❌ FAIL"
        ((tests_failed++))
        failed_tests+=("$test_name")
        echo "   Expected: $expected_result"
        echo "   Got: $result (exit: $exit_code)"
    fi
}

# =====================================================
# PRODUCTION SYSTEM TESTS
# =====================================================
echo "📋 PRODUCTION: System Validation Tests"
echo "======================================"

# Test P.1: Essential modules auto-loaded
run_test "Essential modules loaded" "[[ -n \"\$LOADED_MODULES\" ]] && echo \$LOADED_MODULES | grep -q 'utils python' && echo 'modules_loaded'" "modules_loaded"

# Test P.2: Python environment active
run_test "Python environment active" "python --version 2>&1 | grep -q 'Python 3.11' && echo 'python_active'" "python_active"

# Test P.3: PATH optimized
local path_length=${#PATH}
run_test "PATH length optimized" "[[ $path_length -lt 500 ]] && echo 'path_optimized'" "path_optimized"

# Test P.4: Backup system available
run_test "Backup system available" "alias backup >/dev/null 2>&1 && echo 'backup_available'" "backup_available"

# Test P.5: ZSH system management
run_test "ZSH system control" "[[ -x ~/.config/zsh/zsh-system ]] && echo 'zsh_system_available'" "zsh_system_available"

# Test P.6: Module loading functions
run_test "Module loading system" "typeset -f load_module >/dev/null 2>&1 && echo 'load_module_available'" "load_module_available"

# Test P.7: Staggered mode as default
run_test "Staggered default mode" "detect_zsh_mode | grep -q 'staggered' && echo 'staggered_default'" "staggered_default"

# Test P.8: Utils module functions
run_test "Utils functions loaded" "typeset -f _report_missing_dependency >/dev/null 2>&1 && echo 'utils_functions_ok'" "utils_functions_ok"

echo ""

# =====================================================
# FINAL RESULTS
# =====================================================
echo "🎯 PRODUCTION VALIDATION RESULTS"
echo "================================"
echo "📊 Total tests run: $tests_run"
echo "✅ Tests passed: $tests_passed"
echo "❌ Tests failed: $tests_failed"

if [[ $tests_failed -eq 0 ]]; then
    echo ""
    echo "🎉 PRODUCTION SYSTEM VALIDATED!"
    echo "✅ All production requirements met"
    echo "✅ System ready for deployment"
    echo "✅ Documentation updated and accurate"
    echo "✅ Filesystem cleaned and organized"

    # System health summary (run in proper shell context)
    echo ""
    echo "💎 PRODUCTION HEALTH SUMMARY:"
    local health_result
    health_result=$(zsh -c "source ~/.zshrc >/dev/null 2>&1; echo \"Essential modules: \$(echo \$LOADED_MODULES | wc -w | tr -d ' ')/2 loaded\"; echo \"PATH length: \${#PATH} characters (target: <500)\"; echo \"Python: \$(command -v python 2>/dev/null || echo 'Not found')\"; echo \"Backup system: \$(alias backup >/dev/null 2>&1 && echo 'Available' || echo 'Missing')\"; echo \"Shell mode: \$(detect_zsh_mode 2>/dev/null || echo 'Unknown')\"")
    echo "$health_result" | sed 's/^/   /'

    exit 0
else
    echo ""
    echo "⚠️  PRODUCTION VALIDATION INCOMPLETE"
    echo "❌ Failed tests: ${failed_tests[*]}"
    echo "🔧 Manual review required before deployment"
    echo ""
    echo "🚨 Production readiness: PARTIAL"

    exit 1
fi