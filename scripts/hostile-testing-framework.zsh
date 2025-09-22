#!/usr/bin/env zsh
# =====================================================
# HOSTILE TESTING FRAMEWORK
# =====================================================
#
# Purpose: Adversarial testing framework for all ZSH changes
# Principle: Functional verification over task completion
# Usage: Source this file to get hostile testing functions
# =====================================================

# Global testing state
HOSTILE_TESTS_RUN=0
HOSTILE_TESTS_PASSED=0
HOSTILE_TESTS_FAILED=0
HOSTILE_FAILED_TESTS=()

# =====================================================
# CORE HOSTILE TESTING FUNCTIONS
# =====================================================

# Initialize hostile testing session
hostile_test_init() {
    echo "🔥 HOSTILE TESTING FRAMEWORK ACTIVATED"
    echo "======================================="
    echo "Principle: Assume broken until proven functional"
    echo "Standard: Evidence-based verification required"
    echo ""

    HOSTILE_TESTS_RUN=0
    HOSTILE_TESTS_PASSED=0
    HOSTILE_TESTS_FAILED=0
    HOSTILE_FAILED_TESTS=()
}

# Execute hostile test with functional verification
# Usage: hostile_test "Test Name" "Description" "command" "validation_function"
hostile_test() {
    local test_name="$1"
    local test_description="$2"
    local test_command="$3"
    local validation_function="$4"

    ((HOSTILE_TESTS_RUN++))
    echo "🔍 HOSTILE TEST: $test_name"
    echo "   Testing: $test_description"

    # Execute in fresh shell context
    local result
    local exit_code
    result=$(zsh -c "source ~/.zshrc >/dev/null 2>&1; $test_command" 2>&1)
    exit_code=$?

    # Apply functional validation
    if eval "$validation_function \"\$result\" \$exit_code"; then
        echo "✅ PASS: Functional verification successful"
        ((HOSTILE_TESTS_PASSED++))
    else
        echo "❌ FAIL: Functional verification failed"
        ((HOSTILE_TESTS_FAILED++))
        HOSTILE_FAILED_TESTS+=("$test_name")
        echo "   Command: $test_command"
        echo "   Output: $result"
        echo "   Exit: $exit_code"
    fi
    echo ""
}

# Execute edge case test
# Usage: hostile_edge_test "Test Name" "setup_cmd" "test_cmd" "cleanup_cmd" "expected_pattern"
hostile_edge_test() {
    local test_name="$1"
    local setup_command="$2"
    local test_command="$3"
    local cleanup_command="$4"
    local expected_pattern="$5"

    ((HOSTILE_TESTS_RUN++))
    echo "🚨 EDGE CASE: $test_name"

    # Setup edge case
    eval "$setup_command" >/dev/null 2>&1

    # Execute test
    local result
    result=$(zsh -c "source ~/.zshrc; $test_command" 2>&1)

    # Cleanup
    eval "$cleanup_command" >/dev/null 2>&1

    # Validate edge case handling
    if [[ "$result" =~ "$expected_pattern" ]]; then
        echo "✅ PASS: Edge case handled correctly"
        ((HOSTILE_TESTS_PASSED++))
    else
        echo "❌ FAIL: Edge case not handled properly"
        ((HOSTILE_TESTS_FAILED++))
        HOSTILE_FAILED_TESTS+=("$test_name")
        echo "   Expected pattern: $expected_pattern"
        echo "   Got: $result"
    fi
    echo ""
}

# Execute integration test
# Usage: hostile_integration_test "Test Name" "Description" "test_commands"
hostile_integration_test() {
    local test_name="$1"
    local test_description="$2"
    local test_commands="$3"

    ((HOSTILE_TESTS_RUN++))
    echo "🔗 INTEGRATION: $test_name"
    echo "   Testing: $test_description"

    # Execute integration test
    local result
    result=$(eval "$test_commands" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo "✅ PASS: Integration test successful"
        ((HOSTILE_TESTS_PASSED++))
    else
        echo "❌ FAIL: Integration test failed"
        ((HOSTILE_TESTS_FAILED++))
        HOSTILE_FAILED_TESTS+=("$test_name")
        echo "   Commands: $test_commands"
        echo "   Output: $result"
    fi
    echo ""
}

# Generate hostile test results
hostile_test_results() {
    echo "🎯 HOSTILE TESTING RESULTS"
    echo "=========================="
    echo "📊 Total tests run: $HOSTILE_TESTS_RUN"
    echo "✅ Tests passed: $HOSTILE_TESTS_PASSED"
    echo "❌ Tests failed: $HOSTILE_TESTS_FAILED"

    if [[ $HOSTILE_TESTS_FAILED -eq 0 ]]; then
        echo ""
        echo "🔥 HOSTILE TESTING COMPLETE - FUNCTIONALITY VERIFIED!"
        echo "✅ All functional verification tests passed"
        echo "✅ Ready for deployment"
        return 0
    else
        echo ""
        echo "🚨 HOSTILE TESTING FAILED - FUNCTIONALITY NOT VERIFIED"
        echo "❌ Failed tests: ${HOSTILE_FAILED_TESTS[*]}"
        echo "🔧 Fixes required before deployment"
        return 1
    fi
}

# =====================================================
# STANDARD VALIDATION FUNCTIONS
# =====================================================

# Validate that a variable contains expected content
validate_variable_contains() {
    local result="$1"
    local exit_code="$2"
    local expected="$3"

    [[ "$result" =~ "$expected" && -n "$result" ]]
}

# Validate that a command executes successfully
validate_command_success() {
    local result="$1"
    local exit_code="$2"

    [[ $exit_code -eq 0 ]]
}

# Validate that a function exists and is callable
validate_function_exists() {
    local result="$1"
    local exit_code="$2"

    [[ $exit_code -eq 0 && -n "$result" ]]
}

# Validate that output matches pattern
validate_output_pattern() {
    local result="$1"
    local exit_code="$2"
    local pattern="$3"

    [[ "$result" =~ "$pattern" ]]
}

# =====================================================
# HOSTILE TESTING TEMPLATES
# =====================================================

# Template: Test module loading
hostile_test_module_loading() {
    local module_name="$1"

    hostile_test "Module Loading: $module_name" \
        "Module $module_name loads successfully" \
        "load_module $module_name && echo 'success'" \
        "validate_output_pattern \"\$1\" \$2 'success'"
}

# Template: Test function availability
hostile_test_function_available() {
    local function_name="$1"

    hostile_test "Function: $function_name" \
        "Function $function_name is available and callable" \
        "typeset -f $function_name" \
        "validate_function_exists"
}

# Template: Test variable persistence
hostile_test_variable_persistence() {
    local variable_name="$1"
    local expected_content="$2"

    hostile_test "Variable: $variable_name" \
        "Variable $variable_name persists with expected content" \
        "printf '%s' \"\$$variable_name\"" \
        "validate_variable_contains \"\$1\" \$2 '$expected_content'"
}

# Template: Test command functionality
hostile_test_command_works() {
    local command_name="$1"
    local test_args="$2"

    hostile_test "Command: $command_name" \
        "Command $command_name executes successfully" \
        "$command_name $test_args" \
        "validate_command_success"
}

# =====================================================
# HOSTILE TESTING SUITES
# =====================================================

# Run full hostile test suite
hostile_test_full_suite() {
    hostile_test_init

    # Core functionality tests
    hostile_test_variable_persistence "LOADED_MODULES" "utils python"
    hostile_test_function_available "load_module"
    hostile_test_function_available "detect_zsh_mode"
    hostile_test_function_available "_report_missing_dependency"
    hostile_test_command_works "python3" "--version"

    # Edge case tests
    hostile_edge_test "Missing Module Directory" \
        "mv ~/.config/zsh/modules ~/.config/zsh/modules.backup 2>/dev/null" \
        "startup_status | grep -E '(Module Loading Failed|⚠️)'" \
        "mv ~/.config/zsh/modules.backup ~/.config/zsh/modules 2>/dev/null" \
        "(Module Loading Failed|⚠️)"

    # Integration tests
    hostile_integration_test "Fresh Shell Startup" \
        "Complete system loads without errors" \
        "zsh -c 'source ~/.zshrc 2>&1 | grep -q \"Production Ready\"'"

    hostile_test_results
}

# Quick hostile test for development
hostile_test_quick() {
    hostile_test_init

    # Essential functionality only
    hostile_test_variable_persistence "LOADED_MODULES" "utils"
    hostile_test_function_available "load_module"
    hostile_test_command_works "startup_status" ""

    hostile_test_results
}

# =====================================================
# USAGE EXAMPLES & DOCUMENTATION
# =====================================================

# Show usage examples
hostile_test_help() {
    echo "🔥 HOSTILE TESTING FRAMEWORK USAGE"
    echo "=================================="
    echo ""
    echo "Core Functions:"
    echo "  hostile_test_init                 # Initialize testing session"
    echo "  hostile_test_results              # Show results and determine pass/fail"
    echo ""
    echo "Test Types:"
    echo "  hostile_test                      # Basic functional test"
    echo "  hostile_edge_test                 # Edge case test"
    echo "  hostile_integration_test          # Integration test"
    echo ""
    echo "Templates:"
    echo "  hostile_test_module_loading 'python'         # Test module loading"
    echo "  hostile_test_function_available 'my_func'    # Test function exists"
    echo "  hostile_test_variable_persistence 'VAR' 'val' # Test variable content"
    echo "  hostile_test_command_works 'cmd' 'args'      # Test command works"
    echo ""
    echo "Test Suites:"
    echo "  hostile_test_full_suite           # Complete system verification"
    echo "  hostile_test_quick                # Quick development verification"
    echo ""
    echo "Example Usage:"
    echo "  source ~/.config/zsh/scripts/hostile-testing-framework.zsh"
    echo "  hostile_test_init"
    echo "  hostile_test 'My Test' 'Description' 'command' 'validator'"
    echo "  hostile_test_results"
}

echo "🔥 Hostile Testing Framework Loaded"
echo "Run 'hostile_test_help' for usage examples"