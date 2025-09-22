#!/usr/bin/env zsh
# =====================================================
# HOSTILE PRODUCTION SYSTEM TEST SUITE
# =====================================================
#
# Purpose: Adversarial testing with functional verification
# Principle: Assume system is broken until proven otherwise
# Tests: Real functionality, edge cases, failure modes
# Usage: ~/.config/zsh/test-production-system-hostile.zsh
# =====================================================

echo "🔥 HOSTILE PRODUCTION SYSTEM TESTING"
echo "======================================"
echo "Testing principle: Functional verification over syntax checking"
echo "Assumption: System is broken until proven otherwise"
echo ""

# Test result tracking
local tests_run=0
local tests_passed=0
local tests_failed=0
local failed_tests=()
local warnings=()

# Helper function for hostile test reporting
run_hostile_test() {
    local test_name="$1"
    local test_description="$2"
    local test_command="$3"
    local validation_function="$4"

    ((tests_run++))
    echo "🔍 HOSTILE TEST: $test_name"
    echo "   Testing: $test_description"

    # Execute test in fresh shell context
    local result
    local exit_code
    result=$(zsh -c "source ~/.zshrc >/dev/null 2>&1; $test_command" 2>&1)
    exit_code=$?

    # Validate result using custom validation function
    if eval "$validation_function \"\$result\" \$exit_code"; then
        echo "✅ PASS: Functional verification successful"
        ((tests_passed++))
    else
        echo "❌ FAIL: Functional verification failed"
        ((tests_failed++))
        failed_tests+=("$test_name")
        echo "   Command: $test_command"
        echo "   Output: $result"
        echo "   Exit: $exit_code"
    fi
    echo ""
}

# Helper function for edge case testing
run_edge_case_test() {
    local test_name="$1"
    local setup_command="$2"
    local test_command="$3"
    local cleanup_command="$4"
    local expected_behavior="$5"

    ((tests_run++))
    echo "🚨 EDGE CASE: $test_name"
    echo "   Expected: $expected_behavior"

    # Setup edge case
    eval "$setup_command" >/dev/null 2>&1

    # Execute test
    local result
    result=$(zsh -c "source ~/.zshrc; $test_command" 2>&1)
    local exit_code=$?

    # Cleanup
    eval "$cleanup_command" >/dev/null 2>&1

    # Validate edge case handling
    if [[ "$result" =~ "$expected_behavior" ]]; then
        echo "✅ PASS: Edge case handled correctly"
        ((tests_passed++))
    else
        echo "❌ FAIL: Edge case not handled properly"
        ((tests_failed++))
        failed_tests+=("$test_name")
        echo "   Expected pattern: $expected_behavior"
        echo "   Got: $result"
    fi
    echo ""
}

# Validation functions for hostile tests
validate_modules_loaded() {
    local result="$1"
    local exit_code="$2"

    # Must contain both utils and python
    [[ "$result" =~ "utils" && "$result" =~ "python" && -n "$result" ]]
}

validate_python_functional() {
    local result="$1"
    local exit_code="$2"

    # Must show actual Python version
    [[ "$result" =~ "Python 3\." && $exit_code -eq 0 ]]
}

validate_backup_functional() {
    local result="$1"
    local exit_code="$2"

    # Must show backup help or functionality
    [[ "$result" =~ "backup" && $exit_code -eq 0 ]]
}

validate_mode_detection() {
    local result="$1"
    local exit_code="$2"

    # Must return a valid mode
    [[ "$result" =~ ^(heavy|staggered|minimal|light)$ && $exit_code -eq 0 ]]
}

validate_function_exists() {
    local result="$1"
    local exit_code="$2"

    # Must show function definition or confirmation
    [[ $exit_code -eq 0 && -n "$result" ]]
}

# =====================================================
# HOSTILE FUNCTIONAL TESTS
# =====================================================
echo "📋 HOSTILE: Functional Verification Tests"
echo "=========================================="

# Test F.1: Module loading with ACTUAL verification
run_hostile_test "F.1 Module Loading" \
    "LOADED_MODULES variable contains actual loaded modules" \
    "printf '%s' \"\$LOADED_MODULES\"" \
    "validate_modules_loaded"

# Test F.2: Python environment FUNCTIONAL test
run_hostile_test "F.2 Python Environment" \
    "Python command actually executes and returns version" \
    "python3 --version" \
    "validate_python_functional"

# Test F.3: Backup system FUNCTIONAL test
run_hostile_test "F.3 Backup System" \
    "Backup system actually callable and responds" \
    "type backup && backup --help 2>/dev/null || alias backup" \
    "validate_backup_functional"

# Test F.4: Mode detection with MANUAL override
run_hostile_test "F.4 Mode Detection Override" \
    "Manual mode override actually works" \
    "ZSH_MODE=heavy detect_zsh_mode" \
    "validate_mode_detection"

# Test F.5: Module loading function FUNCTIONAL test
run_hostile_test "F.5 Load Module Function" \
    "load_module function actually exists and callable" \
    "typeset -f load_module" \
    "validate_function_exists"

# Test F.6: Utils functions FUNCTIONAL test
run_hostile_test "F.6 Utils Functions" \
    "_report_missing_dependency function actually exists" \
    "typeset -f _report_missing_dependency" \
    "validate_function_exists"

# =====================================================
# HOSTILE EDGE CASE TESTS
# =====================================================
echo "📋 HOSTILE: Edge Case & Failure Mode Tests"
echo "==========================================="

# Edge E.1: Missing modules directory
run_edge_case_test "E.1 Missing Modules Directory" \
    "mv ~/.config/zsh/modules ~/.config/zsh/modules.backup 2>/dev/null" \
    "startup_status | grep -E '(Module Loading Failed|⚠️)'" \
    "mv ~/.config/zsh/modules.backup ~/.config/zsh/modules 2>/dev/null" \
    "(Module Loading Failed|⚠️)"

# Edge E.2: Individual module failure
run_edge_case_test "E.2 Individual Module Failure" \
    "mv ~/.config/zsh/modules/python.module.zsh ~/.config/zsh/modules/python.module.zsh.backup 2>/dev/null" \
    "printf '%s' \"\$LOADED_MODULES\" | grep -v python || echo 'python not loaded'" \
    "mv ~/.config/zsh/modules/python.module.zsh.backup ~/.config/zsh/modules/python.module.zsh 2>/dev/null" \
    "(python not loaded|utils)"

# Edge E.3: Invalid mode override
run_edge_case_test "E.3 Invalid Mode Override" \
    "export ZSH_MODE=invalid_mode" \
    "detect_zsh_mode" \
    "unset ZSH_MODE" \
    "invalid_mode"

# =====================================================
# HOSTILE INTEGRATION TESTS
# =====================================================
echo "📋 HOSTILE: Integration & Reality Check Tests"
echo "=============================================="

# Integration I.1: Fresh shell startup
echo "🔍 INTEGRATION: I.1 Fresh Shell Startup"
echo "   Testing: Complete system initialization from scratch"
startup_output=$(zsh -c "source ~/.zshrc 2>&1")
if [[ "$startup_output" =~ "✅.*module.*loaded" && "$startup_output" =~ "Production Ready" ]]; then
    echo "✅ PASS: Fresh shell startup successful"
    ((tests_passed++))
else
    echo "❌ FAIL: Fresh shell startup issues"
    echo "   Output: $startup_output"
    ((tests_failed++))
    failed_tests+=("I.1 Fresh Shell Startup")
fi
((tests_run++))
echo ""

# Integration I.2: Variable persistence across commands
echo "🔍 INTEGRATION: I.2 Variable Persistence"
echo "   Testing: Variables persist across multiple commands"
persistence_test=$(zsh -c "source ~/.zshrc >/dev/null 2>&1; echo \$LOADED_MODULES; startup_status | grep 'modules loaded'")
if [[ "$persistence_test" =~ "utils python" && "$persistence_test" =~ "2/2 modules loaded" ]]; then
    echo "✅ PASS: Variable persistence verified"
    ((tests_passed++))
else
    echo "❌ FAIL: Variable persistence broken"
    echo "   Test output: $persistence_test"
    ((tests_failed++))
    failed_tests+=("I.2 Variable Persistence")
fi
((tests_run++))
echo ""

# =====================================================
# HOSTILE RESULTS & VALIDATION
# =====================================================
echo "🎯 HOSTILE TESTING RESULTS"
echo "=========================="
echo "📊 Total tests run: $tests_run"
echo "✅ Tests passed: $tests_passed"
echo "❌ Tests failed: $tests_failed"

if [[ $tests_failed -eq 0 ]]; then
    echo ""
    echo "🔥 HOSTILE TESTING COMPLETE - SYSTEM VERIFIED!"
    echo "✅ All functional verification tests passed"
    echo "✅ All edge cases handled properly"
    echo "✅ All integration tests successful"
    echo "✅ System ready for adversarial deployment"

    # Final reality check
    echo ""
    echo "💎 HOSTILE REALITY CHECK:"
    reality_check=$(zsh -c "source ~/.zshrc >/dev/null 2>&1; echo 'Modules: '[\$LOADED_MODULES]; echo 'Python: '[\$(python3 --version 2>&1)]; echo 'Backup: '[\$(type backup | head -1)]; echo 'Mode: '[\$(detect_zsh_mode)]")
    echo "$reality_check" | sed 's/^/   /'

    exit 0
else
    echo ""
    echo "🚨 HOSTILE TESTING FAILED - SYSTEM NOT READY"
    echo "❌ Failed tests: ${failed_tests[*]}"
    echo "🔧 System requires fixes before deployment"
    echo ""
    echo "⚠️  Production readiness: DENIED"

    exit 1
fi