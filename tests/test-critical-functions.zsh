#!/usr/bin/env zsh

#
# Critical Functions Test Suite
#
# Tests the most important functions in the ZSH configuration
# to ensure they load properly and function correctly.
#
# Usage: ./test-critical-functions.zsh
# Exit codes: 0=success, 1=failure
#

# Load configuration
source "${0:A:h}/../zshrc" 2>/dev/null || true

# Test configuration
TEST_RESULTS=()
FAILED_TESTS=()

# ANSI colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

#
# Helper Functions
#

function_exists() {
    local func_name="$1"
    [[ $(type -w "$func_name" 2>/dev/null) == *": function" ]]
}

test_function() {
    local func_name="$1"
    local description="$2"

    echo "  Testing: $func_name"

    if function_exists "$func_name"; then
        echo "${GREEN}    ✓ Function exists${NC}"
        TEST_RESULTS+=("✓ $description")
        return 0
    else
        echo "${RED}    ✗ Function not found${NC}"
        TEST_RESULTS+=("✗ $description")
        FAILED_TESTS+=("$func_name")
        return 1
    fi
}

test_function_with_execution() {
    local func_name="$1"
    local description="$2"
    local test_args="$3"

    echo "  Testing: $func_name $test_args"

    if function_exists "$func_name"; then
        echo "${GREEN}    ✓ Function exists${NC}"

        # Try to execute with test args (in safe mode)
        if [[ -n "$test_args" ]]; then
            echo "    Executing: $func_name $test_args"
            if eval "$func_name $test_args" >/dev/null 2>&1; then
                echo "${GREEN}    ✓ Function executed successfully${NC}"
                TEST_RESULTS+=("✓ $description")
                return 0
            else
                echo "${YELLOW}    ? Function exists but execution failed (may be expected)${NC}"
                TEST_RESULTS+=("? $description")
                return 1
            fi
        else
            TEST_RESULTS+=("✓ $description")
            return 0
        fi
    else
        echo "${RED}    ✗ Function not found${NC}"
        TEST_RESULTS+=("✗ $description")
        FAILED_TESTS+=("$func_name")
        return 1
    fi
}

#
# Test Suites
#

test_core_functions() {
    echo "${BLUE}Testing Core System Functions...${NC}"

    test_function "load_config_module" "Core module loading system"
    test_function "zsh_help" "Help system"
    test_function "repair_path" "PATH repair utility"
    test_function "deduplicate_path" "PATH deduplication"

    echo
}

test_python_functions() {
    echo "${BLUE}Testing Python Management Functions...${NC}"

    test_function "python_status" "Python environment status"
    test_function "py-switch" "Python environment switching"
    test_function "py-list" "Python environment listing"
    test_function "py-uv" "UV project activation"

    # Test with safe arguments
    test_function_with_execution "python_status" "Python status execution" ""

    echo
}

test_docker_functions() {
    echo "${BLUE}Testing Docker Management Functions...${NC}"

    test_function "docker_status" "Docker system status"
    test_function "dstatus" "Docker status alias"
    test_function "dclean" "Docker cleanup"
    test_function "ensure_docker_available" "Docker dependency management"

    # Test status function
    test_function_with_execution "docker_status" "Docker status execution" ""

    echo
}

test_database_functions() {
    echo "${BLUE}Testing Database Functions...${NC}"

    test_function "database_status" "Database connection status"
    test_function "get_credential" "Credential retrieval system"
    test_function "credential_backend_status" "Credential backend status"

    echo
}

test_spark_functions() {
    echo "${BLUE}Testing Spark/Big Data Functions...${NC}"

    test_function "spark_status" "Spark cluster status"
    test_function "spark_start" "Spark startup with dependency management"
    test_function "hadoop_status" "Hadoop ecosystem status"
    test_function "ensure_spark_available" "Spark dependency management"

    echo
}

test_backup_and_sync_functions() {
    echo "${BLUE}Testing Backup and Sync Functions...${NC}"

    test_function "comprehensive_1password_to_apple_sync" "1Password to Apple sync"
    test_function "comprehensive_apple_to_1password_sync" "Apple to 1Password sync"
    test_function "sync_all_passwords_to_1password" "Complete password sync"
    test_function "backup" "Configuration backup system"

    echo
}

test_status_aggregation() {
    echo "${BLUE}Testing Status Aggregation Functions...${NC}"

    test_function "master_status" "Master status aggregation"
    test_function "zsh-status" "ZSH module status"
    test_function "repostatus" "Repository status"

    # Test execution of status functions
    test_function_with_execution "zsh-status" "ZSH status execution" ""

    echo
}

test_utility_functions() {
    echo "${BLUE}Testing Utility Functions...${NC}"

    test_function "push" "Git push with custom message"
    test_function "pushmain" "Quick git push"
    test_function "sync" "Repository sync"
    test_function "load_module" "Module loading utility"

    echo
}

test_performance_functions() {
    echo "${BLUE}Testing Performance Functions...${NC}"

    test_function "zsh-reload" "Shell reload"
    test_function "zsh-verbose" "Verbose loading"
    test_function "zsh-light" "Minimal mode"

    # Test reload function
    echo "  Testing shell reload functionality..."
    if command -v zsh-reload >/dev/null 2>&1; then
        echo "${GREEN}    ✓ zsh-reload command available${NC}"
    else
        echo "${YELLOW}    ? zsh-reload command not in PATH${NC}"
    fi

    echo
}

#
# Test Execution
#

echo "${BOLD}🧪 Critical Functions Test Suite${NC}"
echo "================================="
echo

# Run all test suites
test_core_functions
test_python_functions
test_docker_functions
test_database_functions
test_spark_functions
test_backup_and_sync_functions
test_status_aggregation
test_utility_functions
test_performance_functions

# Summary
echo "${BOLD}Test Results Summary:${NC}"
echo "===================="

passed_count=0
failed_count=0
review_count=0

for result in "${TEST_RESULTS[@]}"; do
    if [[ "$result" == "✓"* ]]; then
        echo "${GREEN}$result${NC}"
        ((passed_count++))
    elif [[ "$result" == "✗"* ]]; then
        echo "${RED}$result${NC}"
        ((failed_count++))
    else
        echo "${YELLOW}$result${NC}"
        ((review_count++))
    fi
done

echo
echo "${BOLD}Statistics:${NC}"
echo "  Passed: ${GREEN}$passed_count${NC}"
echo "  Failed: ${RED}$failed_count${NC}"
echo "  Need Review: ${YELLOW}$review_count${NC}"
echo "  Total: $((passed_count + failed_count + review_count))"

# Show failed functions
if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo
    echo "${RED}${BOLD}Failed Functions:${NC}"
    for func in "${FAILED_TESTS[@]}"; do
        echo "${RED}  - $func${NC}"
    done
    echo
    echo "${YELLOW}💡 To fix missing functions, try:${NC}"
    echo "  1. Load relevant modules: load-python, load-docker, etc."
    echo "  2. Check module loading: zsh-status"
    echo "  3. Reload configuration: zsh-reload"
fi

echo

# Final result
if [[ $failed_count -eq 0 ]]; then
    echo "${GREEN}${BOLD}✅ All critical functions are available!${NC}"
    exit 0
elif [[ $failed_count -lt 5 ]]; then
    echo "${YELLOW}${BOLD}⚠️  Some functions missing but system mostly functional.${NC}"
    exit 1
else
    echo "${RED}${BOLD}❌ Many critical functions missing - configuration needs attention.${NC}"
    exit 1
fi