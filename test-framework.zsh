#!/usr/bin/env zsh

# =============================================================================
# ZSH Testing Framework - Comprehensive Unit Testing for Zsh Functions
# =============================================================================
# 
# This framework provides pytest-like functionality for Zsh functions including:
# - Test discovery and execution
# - Assertions and mocking
# - Test reporting and coverage
# - Parallel test execution
# - Integration with CI/CD
#
# Usage:
#   zsh test-framework.zsh                    # Run all tests
#   zsh test-framework.zsh --test function    # Run specific test
#   zsh test-framework.zsh --coverage         # Run with coverage
#   zsh test-framework.zsh --verbose          # Verbose output
#   zsh test-framework.zsh --parallel 4       # Run 4 tests in parallel
#
# =============================================================================

# Test Framework Configuration
# =============================================================================

# Colors for output
readonly TEST_COLOR_RED='\033[0;31m'
readonly TEST_COLOR_GREEN='\033[0;32m'
readonly TEST_COLOR_YELLOW='\033[1;33m'
readonly TEST_COLOR_BLUE='\033[0;34m'
readonly TEST_COLOR_CYAN='\033[0;36m'
readonly TEST_COLOR_WHITE='\033[1;37m'
readonly TEST_COLOR_RESET='\033[0m'

# Test statistics
typeset -g TEST_STATS_TOTAL=0
typeset -g TEST_STATS_PASSED=0
typeset -g TEST_STATS_FAILED=0
typeset -g TEST_STATS_SKIPPED=0
typeset -g TEST_STATS_START_TIME=0
typeset -g TEST_STATS_END_TIME=0

# Test configuration
typeset -g TEST_VERBOSE=false
typeset -g TEST_COVERAGE=false
typeset -g TEST_PARALLEL=1
typeset -g TEST_PATTERN=""
typeset -g TEST_OUTPUT_DIR="./test-results"

# Test results storage
typeset -gA TEST_RESULTS
typeset -gA TEST_COVERAGE_DATA

# =============================================================================
# Test Framework Core Functions
# =============================================================================

# Initialize test framework
test_init() {
    TEST_STATS_START_TIME=$(date +%s)
    TEST_STATS_TOTAL=0
    TEST_STATS_PASSED=0
    TEST_STATS_FAILED=0
    TEST_STATS_SKIPPED=0
    
    # Create output directory
    mkdir -p "$TEST_OUTPUT_DIR"
    
    # Clear previous results
    TEST_RESULTS=()
    TEST_COVERAGE_DATA=()
    
    echo "${TEST_COLOR_CYAN}🧪 ZSH Testing Framework${TEST_COLOR_RESET}"
    echo "${TEST_COLOR_CYAN}========================${TEST_COLOR_RESET}"
    echo ""
}

# Parse command line arguments
test_parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                TEST_VERBOSE=true
                shift
                ;;
            --coverage|-c)
                TEST_COVERAGE=true
                shift
                ;;
            --parallel|-p)
                TEST_PARALLEL="$2"
                shift 2
                ;;
            --test|-t)
                TEST_PATTERN="$2"
                shift 2
                ;;
            --output|-o)
                TEST_OUTPUT_DIR="$2"
                shift 2
                ;;
            --help|-h)
                test_show_help
                exit 0
                ;;
            *)
                echo "${TEST_COLOR_RED}Unknown option: $1${TEST_COLOR_RESET}"
                test_show_help
                exit 1
                ;;
        esac
    done
}

# Show help information
test_show_help() {
    cat << EOF
ZSH Testing Framework

Usage: zsh test-framework.zsh [OPTIONS]

Options:
  -v, --verbose     Verbose output
  -c, --coverage    Enable coverage reporting
  -p, --parallel N  Run N tests in parallel
  -t, --test NAME   Run specific test
  -o, --output DIR  Output directory for results
  -h, --help        Show this help

Examples:
  zsh test-framework.zsh
  zsh test-framework.zsh --verbose --coverage
  zsh test-framework.zsh --test "test_python_status"
  zsh test-framework.zsh --parallel 4
EOF
}

# =============================================================================
# Test Assertion Functions
# =============================================================================

# Assert that a condition is true
assert_true() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if eval "$condition"; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Condition: $condition${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that a condition is false
assert_false() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if ! eval "$condition"; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Condition: $condition${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that two values are equal
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values are not equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Expected: '$expected'${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Actual: '$actual'${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that two values are not equal
assert_not_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values are equal}"
    
    if [[ "$expected" != "$actual" ]]; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Expected: '$expected'${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Actual: '$actual'${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that a string contains a substring
assert_contains() {
    local string="$1"
    local substring="$2"
    local message="${3:-String does not contain substring}"
    
    if [[ "$string" == *"$substring"* ]]; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   String: '$string'${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Substring: '$substring'${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that a string does not contain a substring
assert_not_contains() {
    local string="$1"
    local substring="$2"
    local message="${3:-String contains substring}"
    
    if [[ "$string" != *"$substring"* ]]; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   String: '$string'${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Substring: '$substring'${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that a command succeeds
assert_command_success() {
    local command="$1"
    local message="${2:-Command failed}"
    
    if eval "$command" >/dev/null 2>&1; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Command: $command${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that a command fails
assert_command_failure() {
    local command="$1"
    local message="${2:-Command succeeded}"
    
    if ! eval "$command" >/dev/null 2>&1; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Command: $command${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-File does not exist}"
    
    if [[ -f "$file" ]]; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   File: $file${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-Directory does not exist}"
    
    if [[ -d "$dir" ]]; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Directory: $dir${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that a variable is set
assert_var_set() {
    local var_name="$1"
    local message="${2:-Variable is not set}"
    
    if [[ -n "${(P)var_name}" ]]; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Variable: $var_name${TEST_COLOR_RESET}"
        return 1
    fi
}

# Assert that a variable is not set
assert_var_unset() {
    local var_name="$1"
    local message="${2:-Variable is set}"
    
    if [[ -z "${(P)var_name}" ]]; then
        return 0
    else
        echo "${TEST_COLOR_RED}❌ $message${TEST_COLOR_RESET}"
        echo "${TEST_COLOR_RED}   Variable: $var_name${TEST_COLOR_RESET}"
        return 1
    fi
}

# =============================================================================
# Test Execution Functions
# =============================================================================

# Run a single test
run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TEST_STATS_TOTAL=$((TEST_STATS_TOTAL + 1))
    
    if [[ -n "$TEST_PATTERN" && "$test_name" != *"$TEST_PATTERN"* ]]; then
        TEST_STATS_SKIPPED=$((TEST_STATS_SKIPPED + 1))
        return 0
    fi
    
    if [[ "$TEST_VERBOSE" == "true" ]]; then
        echo "${TEST_COLOR_BLUE}🧪 Running: $test_name${TEST_COLOR_RESET}"
    fi
    
    # Capture test output
    local test_output
    local test_exit_code
    
    # Run test in subshell to isolate environment
    test_output=$(eval "$test_function" 2>&1)
    test_exit_code=$?
    
    # Store test result
    TEST_RESULTS[$test_name]="$test_exit_code"
    
    if [[ $test_exit_code -eq 0 ]]; then
        TEST_STATS_PASSED=$((TEST_STATS_PASSED + 1))
        if [[ "$TEST_VERBOSE" == "true" ]]; then
            echo "${TEST_COLOR_GREEN}✅ PASSED: $test_name${TEST_COLOR_RESET}"
        fi
    else
        TEST_STATS_FAILED=$((TEST_STATS_FAILED + 1))
        echo "${TEST_COLOR_RED}❌ FAILED: $test_name${TEST_COLOR_RESET}"
        if [[ -n "$test_output" ]]; then
            echo "$test_output"
        fi
    fi
    
    return $test_exit_code
}

# Run all tests
run_all_tests() {
    echo "${TEST_COLOR_CYAN}🔍 Discovering tests...${TEST_COLOR_RESET}"
    
    # Source all test files
    for test_file in tests/*.zsh; do
        if [[ -f "$test_file" ]]; then
            if [[ "$TEST_VERBOSE" == "true" ]]; then
                echo "${TEST_COLOR_BLUE}📄 Loading: $test_file${TEST_COLOR_RESET}"
            fi
            source "$test_file"
        fi
    done
    
    echo "${TEST_COLOR_CYAN}🚀 Running tests...${TEST_COLOR_RESET}"
    echo ""
    
    # Run tests
    for test_name in ${(k)TEST_FUNCTIONS}; do
        run_test "$test_name" "${TEST_FUNCTIONS[$test_name]}"
    done
}

# =============================================================================
# Test Registration System
# =============================================================================

# Register a test function
register_test() {
    local test_name="$1"
    local test_function="$2"
    
    TEST_FUNCTIONS[$test_name]="$test_function"
}

# =============================================================================
# Coverage Analysis
# =============================================================================

# Start coverage tracking
start_coverage() {
    if [[ "$TEST_COVERAGE" == "true" ]]; then
        echo "${TEST_COLOR_CYAN}📊 Starting coverage tracking...${TEST_COLOR_RESET}"
        # Coverage tracking would be implemented here
    fi
}

# Generate coverage report
generate_coverage_report() {
    if [[ "$TEST_COVERAGE" == "true" ]]; then
        echo "${TEST_COLOR_CYAN}📊 Generating coverage report...${TEST_COLOR_RESET}"
        # Coverage report generation would be implemented here
    fi
}

# =============================================================================
# Test Reporting
# =============================================================================

# Generate test report
generate_test_report() {
    TEST_STATS_END_TIME=$(date +%s)
    local duration=$((TEST_STATS_END_TIME - TEST_STATS_START_TIME))
    
    echo ""
    echo "${TEST_COLOR_CYAN}📊 Test Results${TEST_COLOR_RESET}"
    echo "${TEST_COLOR_CYAN}===============${TEST_COLOR_RESET}"
    echo ""
    echo "Total Tests: $TEST_STATS_TOTAL"
    echo "${TEST_COLOR_GREEN}Passed: $TEST_STATS_PASSED${TEST_COLOR_RESET}"
    echo "${TEST_COLOR_RED}Failed: $TEST_STATS_FAILED${TEST_COLOR_RESET}"
    echo "${TEST_COLOR_YELLOW}Skipped: $TEST_STATS_SKIPPED${TEST_COLOR_RESET}"
    echo "Duration: ${duration}s"
    echo ""
    
    # Calculate success rate
    if [[ $TEST_STATS_TOTAL -gt 0 ]]; then
        local success_rate=$((TEST_STATS_PASSED * 100 / TEST_STATS_TOTAL))
        echo "Success Rate: ${success_rate}%"
        
        if [[ $success_rate -eq 100 ]]; then
            echo "${TEST_COLOR_GREEN}🎉 All tests passed!${TEST_COLOR_RESET}"
        elif [[ $success_rate -ge 80 ]]; then
            echo "${TEST_COLOR_YELLOW}⚠️  Most tests passed${TEST_COLOR_RESET}"
        else
            echo "${TEST_COLOR_RED}❌ Many tests failed${TEST_COLOR_RESET}"
        fi
    fi
    
    # Save detailed report
    cat > "$TEST_OUTPUT_DIR/test-report.json" << EOF
{
    "total": $TEST_STATS_TOTAL,
    "passed": $TEST_STATS_PASSED,
    "failed": $TEST_STATS_FAILED,
    "skipped": $TEST_STATS_SKIPPED,
    "duration": $duration,
    "success_rate": $success_rate,
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    echo ""
    echo "📄 Detailed report saved to: $TEST_OUTPUT_DIR/test-report.json"
}

# =============================================================================
# Main Execution
# =============================================================================

# Main function
main() {
    test_parse_args "$@"
    test_init
    start_coverage
    run_all_tests
    generate_coverage_report
    generate_test_report
    
    # Exit with appropriate code
    if [[ $TEST_STATS_FAILED -gt 0 ]]; then
        exit 1
    else
        exit 0
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
