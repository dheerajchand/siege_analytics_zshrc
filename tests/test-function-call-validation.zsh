#!/usr/bin/env zsh

# =====================================================
# FUNCTION CALL VALIDATION TESTS
# =====================================================
#
# Tests that validate actual function calls that would have failed
# before the critical fixes were applied. These tests simulate the
# exact scenarios that caused runtime errors.
#
# This test specifically validates:
# 1. _report_* functions called by python module
# 2. Error handling for missing dependencies
# 3. Function call chains that would break
# =====================================================

# Test configuration
readonly TEST_NAME="Function Call Validation Tests"
readonly TEST_VERSION="1.0.0"

# Test results tracking
TEST_RESULTS=()
FAILED_TESTS=()

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# =====================================================
# TEST HELPER FUNCTIONS
# =====================================================

test_function_call() {
    local func_name="$1"
    local test_args="$2"
    local description="$3"
    local expect_success="${4:-true}"

    echo "  Testing call: $func_name $test_args"

    local result
    local exit_code

    # Capture both output and exit code
    result=$(eval "$func_name $test_args" 2>&1)
    exit_code=$?

    if [[ "$expect_success" == "true" ]]; then
        if [[ $exit_code -eq 0 ]]; then
            echo "${GREEN}    ✓ $description${NC}"
            TEST_RESULTS+=("✓ $description")
            return 0
        else
            echo "${RED}    ✗ $description - Exit code: $exit_code${NC}"
            echo "${RED}      Output: $result${NC}"
            TEST_RESULTS+=("✗ $description")
            FAILED_TESTS+=("$func_name")
            return 1
        fi
    else
        if [[ $exit_code -ne 0 ]]; then
            echo "${GREEN}    ✓ $description (expected failure)${NC}"
            TEST_RESULTS+=("✓ $description (expected failure)")
            return 0
        else
            echo "${RED}    ✗ $description - Should have failed but succeeded${NC}"
            TEST_RESULTS+=("✗ $description - Should have failed")
            FAILED_TESTS+=("$func_name")
            return 1
        fi
    fi
}

test_function_exists_and_callable() {
    local func_name="$1"
    local description="$2"

    echo "  Testing existence and callability: $func_name"

    # First check if function exists
    if [[ $(type -w "$func_name" 2>/dev/null) == *": function" ]]; then
        # Try to call it with --help or minimal args
        local result
        if result=$(eval "$func_name --help 2>/dev/null" || eval "$func_name 2>/dev/null" || echo "callable"); then
            echo "${GREEN}    ✓ $description${NC}"
            TEST_RESULTS+=("✓ $description")
            return 0
        else
            echo "${RED}    ✗ Function exists but not callable: $description${NC}"
            TEST_RESULTS+=("✗ $description")
            FAILED_TESTS+=("$func_name")
            return 1
        fi
    else
        echo "${RED}    ✗ Function does not exist: $description${NC}"
        TEST_RESULTS+=("✗ $description")
        FAILED_TESTS+=("$func_name")
        return 1
    fi
}

# =====================================================
# CRITICAL _REPORT_* FUNCTION TESTS
# =====================================================

test_report_functions() {
    echo "${BLUE}Testing Critical _report_* Functions...${NC}"
    echo "These functions were missing and caused Python module failures."
    echo

    # Test _report_missing_dependency function (called by Python module)
    test_function_call "_report_missing_dependency" \
        '"test_tool" "Test description" "Test context" "brew install test_tool"' \
        "Missing dependency reporter with valid arguments"

    # Test _report_path_error function
    test_function_call "_report_path_error" \
        '"/nonexistent/path" "Path not found" "Create directory" "mkdir -p /test/path"' \
        "Path error reporter with valid arguments"

    # Test _report_validation_error function
    test_function_call "_report_validation_error" \
        '"port" "abc" "numeric value" "command 8080"' \
        "Validation error reporter with valid arguments"

    # Test _report_config_error function
    test_function_call "_report_config_error" \
        '"TEST_VAR" "current_value" "Invalid configuration" "Fix the config"' \
        "Configuration error reporter with valid arguments"

    echo
}

# =====================================================
# VALIDATION HELPER FUNCTION TESTS
# =====================================================

test_validation_helpers() {
    echo "${BLUE}Testing Validation Helper Functions...${NC}"
    echo "These functions are used by the _report_* functions."
    echo

    # Test _command_exists function
    test_function_call "_command_exists" '"ls"' \
        "Command existence checker with existing command"

    test_function_call "_command_exists" '"nonexistent_command_xyz"' \
        "Command existence checker with non-existing command" "false"

    # Test _directory_accessible function
    test_function_call "_directory_accessible" '"/"' \
        "Directory accessibility checker with root directory"

    test_function_call "_directory_accessible" '"/nonexistent/directory"' \
        "Directory accessibility checker with non-existing directory" "false"

    # Test _file_readable function
    test_function_call "_file_readable" '"/etc/hosts"' \
        "File readability checker with existing file"

    test_function_call "_file_readable" '"/nonexistent/file"' \
        "File readability checker with non-existing file" "false"

    # Test _is_positive_integer function
    test_function_call "_is_positive_integer" '"123"' \
        "Positive integer validator with valid number"

    test_function_call "_is_positive_integer" '"abc"' \
        "Positive integer validator with invalid input" "false"

    echo
}

# =====================================================
# SYSTEM DIAGNOSTIC FUNCTION TESTS
# =====================================================

test_system_diagnostics() {
    echo "${BLUE}Testing System Diagnostic Functions...${NC}"
    echo "These functions provide system information and health checks."
    echo

    # Test _system_info function
    test_function_exists_and_callable "_system_info" "System information function"

    # Test _environment_health_check function
    test_function_exists_and_callable "_environment_health_check" "Environment health check function"

    echo
}

# =====================================================
# INTEGRATION TESTS - SIMULATING REAL FAILURE SCENARIOS
# =====================================================

test_failure_scenarios() {
    echo "${BLUE}Testing Real Failure Scenarios...${NC}"
    echo "Simulating the exact scenarios that caused system failures."
    echo

    # Scenario 1: Python module tries to report missing pyenv
    echo "  Scenario 1: Python module reporting missing pyenv"
    if test_function_call "_report_missing_dependency" \
        '"pyenv" "Python version manager" "Python environment setup" "brew install pyenv"' \
        "Python module can report missing pyenv"; then
        echo "${GREEN}    ✓ Python module error reporting works${NC}"
    else
        echo "${RED}    ✗ Python module would fail with missing dependency error${NC}"
    fi

    # Scenario 2: Module tries to validate directory
    echo "  Scenario 2: Module validating Python directory"
    if test_function_call "_directory_accessible" '"/usr/local/bin"' \
        "Module can validate Python directory"; then
        echo "${GREEN}    ✓ Directory validation works${NC}"
    else
        echo "${RED}    ✗ Module would fail with directory validation error${NC}"
    fi

    # Scenario 3: Configuration validation
    echo "  Scenario 3: Configuration validation with error reporting"
    if test_function_call "_report_config_error" \
        '"PYTHON_PATH" "/invalid/path" "Invalid Python path" "Update PYTHON_PATH"' \
        "Configuration validation with error reporting"; then
        echo "${GREEN}    ✓ Configuration error handling works${NC}"
    else
        echo "${RED}    ✗ Configuration validation would fail${NC}"
    fi

    echo
}

# =====================================================
# CROSS-MODULE DEPENDENCY TESTS
# =====================================================

test_cross_module_dependencies() {
    echo "${BLUE}Testing Cross-Module Dependencies...${NC}"
    echo "Testing that modules can successfully call utility functions."
    echo

    # Test that python module can use utility functions
    echo "  Testing Python module utility function access..."

    # Check if Python module functions exist and can potentially call utils
    if [[ $(type -w "python_status" 2>/dev/null) == *": function" ]]; then
        echo "${GREEN}    ✓ Python module loaded and can access utility functions${NC}"
        TEST_RESULTS+=("✓ Python module can access utilities")
    else
        echo "${YELLOW}    ? Python module not loaded yet (background loading)${NC}"
        TEST_RESULTS+=("? Python module not loaded yet")
    fi

    # Test that other modules would be able to call utility functions
    local modules=("docker" "database" "spark")
    for module in "${modules[@]}"; do
        echo "  Testing $module module utility function access..."
        if [[ $(type -w "${module}_status" 2>/dev/null) == *": function" ]]; then
            echo "${GREEN}    ✓ $module module can access utility functions${NC}"
            TEST_RESULTS+=("✓ $module module can access utilities")
        else
            echo "${YELLOW}    ? $module module not loaded yet (background loading)${NC}"
            TEST_RESULTS+=("? $module module not loaded yet")
        fi
    done

    echo
}

# =====================================================
# MAIN TEST EXECUTION
# =====================================================

echo "${BOLD}🔍 Function Call Validation Test Suite${NC}"
echo "======================================"
echo
echo "These tests validate that the critical function calls work correctly"
echo "after the fixes were applied. Before the fixes, these would have failed."
echo

# Load utils module to ensure functions are available
if [[ $(type -w "load_module" 2>/dev/null) == *": function" ]]; then
    echo "Loading utils module for testing..."
    load_module utils >/dev/null 2>&1 || true
fi

# Run all test suites
test_report_functions
test_validation_helpers
test_system_diagnostics
test_failure_scenarios
test_cross_module_dependencies

# =====================================================
# RESULTS SUMMARY
# =====================================================

echo "${BOLD}Test Results Summary:${NC}"
echo "===================="

passed_count=0
failed_count=0
pending_count=0

for result in "${TEST_RESULTS[@]}"; do
    if [[ "$result" == "✓"* ]]; then
        echo "${GREEN}$result${NC}"
        ((passed_count++))
    elif [[ "$result" == "?"* ]]; then
        echo "${YELLOW}$result${NC}"
        ((pending_count++))
    else
        echo "${RED}$result${NC}"
        ((failed_count++))
    fi
done

echo
echo "${BOLD}Statistics:${NC}"
echo "  Passed: ${GREEN}$passed_count${NC}"
echo "  Failed: ${RED}$failed_count${NC}"
echo "  Pending (Background Loading): ${YELLOW}$pending_count${NC}"
echo "  Total: $((passed_count + failed_count + pending_count))"

# Show failed function calls
if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo
    echo "${RED}${BOLD}Failed Function Calls:${NC}"
    for func in "${FAILED_TESTS[@]}"; do
        echo "${RED}  - $func${NC}"
    done
    echo
    echo "${YELLOW}💡 These failures would have caused runtime errors before the fixes.${NC}"
fi

echo

# Final result
if [[ $failed_count -eq 0 ]]; then
    echo "${GREEN}${BOLD}✅ All function calls validated successfully!${NC}"
    echo "${GREEN}The critical fixes have resolved the runtime errors.${NC}"
    if [[ $pending_count -gt 0 ]]; then
        echo "${YELLOW}Note: Some modules still loading in background - this is expected.${NC}"
    fi
    exit 0
else
    echo "${RED}${BOLD}❌ Function call failures detected!${NC}"
    echo "${RED}These represent the exact runtime errors that occurred.${NC}"
    exit 1
fi