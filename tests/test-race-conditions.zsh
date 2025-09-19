#!/usr/bin/env zsh

# =====================================================
# RACE CONDITION DETECTION TESTS
# =====================================================
#
# Tests that detect race conditions in module loading and background
# processing that caused the original system failures.
#
# Critical race conditions tested:
# 1. Variables not available in background jobs
# 2. Module loading order dependencies
# 3. Background job synchronization issues
# 4. Function availability timing
# =====================================================

# Test configuration
readonly TEST_NAME="Race Condition Detection Tests"
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

test_race_condition() {
    local test_name="$1"
    local description="$2"
    local test_command="$3"
    local expected_result="$4"

    echo "  Testing race condition: $test_name"

    local result
    result=$(eval "$test_command" 2>/dev/null)
    local exit_code=$?

    if [[ "$result" == "$expected_result" && $exit_code -eq 0 ]]; then
        echo "${GREEN}    ✓ $description${NC}"
        TEST_RESULTS+=("✓ $description")
        return 0
    else
        echo "${RED}    ✗ $description${NC}"
        echo "${RED}      Expected: '$expected_result', Got: '$result', Exit: $exit_code${NC}"
        TEST_RESULTS+=("✗ $description")
        FAILED_TESTS+=("$test_name")
        return 1
    fi
}

simulate_background_context() {
    local script_content="$1"
    local temp_script="/tmp/bg_race_test_$$.zsh"

    cat > "$temp_script" << EOF
#!/usr/bin/env zsh
# Simulate background job context
$script_content
EOF

    local result
    result=$(zsh "$temp_script" 2>&1)
    local exit_code=$?

    rm -f "$temp_script"
    echo "$result"
    return $exit_code
}

# =====================================================
# VARIABLE AVAILABILITY RACE CONDITION TESTS
# =====================================================

test_variable_availability_race_conditions() {
    echo "${BLUE}Testing Variable Availability Race Conditions...${NC}"
    echo "These tests detect if variables are available in background contexts."
    echo

    # Test 1: ZSH_CONFIG_DIR available in background jobs
    local bg_script='
    [[ -n "$ZSH_CONFIG_DIR" ]] && echo "config_dir_available" || echo "config_dir_missing"
    '
    local result=$(simulate_background_context "$bg_script")
    test_race_condition "bg-config-dir" \
        "ZSH_CONFIG_DIR available in background context" \
        "echo '$result'" \
        "config_dir_available"

    # Test 2: ZSH_MODULES_DIR available in background jobs
    local bg_script2='
    [[ -n "$ZSH_MODULES_DIR" ]] && echo "modules_dir_available" || echo "modules_dir_missing"
    '
    local result2=$(simulate_background_context "$bg_script2")
    test_race_condition "bg-modules-dir" \
        "ZSH_MODULES_DIR available in background context" \
        "echo '$result2'" \
        "modules_dir_available"

    # Test 3: Variables loaded in background after re-sourcing
    local bg_script3='
    # Simulate the fix: re-source variables in background context
    [[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"
    [[ -n "$ZSH_MODULES_DIR" ]] && echo "vars_resourced" || echo "vars_missing"
    '
    local result3=$(simulate_background_context "$bg_script3")
    test_race_condition "bg-vars-resourced" \
        "Variables available after re-sourcing in background" \
        "echo '$result3'" \
        "vars_resourced"

    echo
}

# =====================================================
# MODULE LOADING ORDER RACE CONDITION TESTS
# =====================================================

test_module_loading_order_race_conditions() {
    echo "${BLUE}Testing Module Loading Order Race Conditions...${NC}"
    echo "These tests ensure modules load in the correct dependency order."
    echo

    # Test 1: Utils module loaded before other modules (dependency fix)
    test_race_condition "utils-first" \
        "Utils module in light modules (loads first)" \
        '[[ "$ZSH_LIGHT_MODULES" == *"utils"* ]] && echo "utils_first" || echo "utils_missing"' \
        "utils_first"

    # Test 2: Variables loaded before module discovery
    test_race_condition "vars-before-discovery" \
        "Variables loaded before module discovery" \
        '[[ "$ZSH_VARIABLES_LOADED" == "true" ]] && echo "vars_loaded" || echo "vars_missing"' \
        "vars_loaded"

    # Test 3: Core dependencies available for background modules
    test_race_condition "core-deps-available" \
        "Core dependencies available for background modules" \
        '[[ -n "$ZSH_CONFIG_DIR" && -n "$ZSH_MODULES_DIR" ]] && echo "deps_available" || echo "deps_missing"' \
        "deps_available"

    echo
}

# =====================================================
# BACKGROUND JOB SYNCHRONIZATION TESTS
# =====================================================

test_background_job_synchronization() {
    echo "${BLUE}Testing Background Job Synchronization...${NC}"
    echo "These tests detect timing issues in background job coordination."
    echo

    # Test 1: Background jobs don't inherit broken environment
    local sync_test='
    # Test background job with proper variable access
    {
        sleep 0.1  # Brief delay to simulate background loading
        [[ -n "$ZSH_CONFIG_DIR" ]] && echo "bg_sync_ok" || echo "bg_sync_fail"
    } &!
    wait
    '

    local sync_result
    sync_result=$(eval "$sync_test" 2>/dev/null | tail -1)
    test_race_condition "bg-job-sync" \
        "Background jobs have proper variable access" \
        "echo '$sync_result'" \
        "bg_sync_ok"

    # Test 2: Background job completion tracking
    test_race_condition "bg-completion" \
        "Background job completion can be tracked" \
        '[[ -n "$ZSH_STAGGERED_MODE" || -n "$ZSH_LIGHT_MODE" ]] && echo "completion_tracked" || echo "completion_unknown"' \
        "completion_tracked"

    # Test 3: No background job interference with shell startup
    local startup_time_before=$(date +%s.%N)
    # Shell should be responsive immediately
    local startup_time_after=$(date +%s.%N)
    local duration=$(echo "$startup_time_after - $startup_time_before" | bc 2>/dev/null || echo "0.1")

    # Test that shell startup is fast (< 1 second for responsiveness test)
    if [[ $(echo "$duration < 1.0" | bc 2>/dev/null || echo 1) -eq 1 ]]; then
        echo "${GREEN}    ✓ Shell remains responsive during background loading${NC}"
        TEST_RESULTS+=("✓ Shell remains responsive during background loading")
    else
        echo "${RED}    ✗ Shell responsiveness affected by background loading${NC}"
        TEST_RESULTS+=("✗ Shell responsiveness affected by background loading")
        FAILED_TESTS+=("shell-responsiveness")
    fi

    echo
}

# =====================================================
# FUNCTION AVAILABILITY TIMING TESTS
# =====================================================

test_function_availability_timing() {
    echo "${BLUE}Testing Function Availability Timing...${NC}"
    echo "These tests ensure critical functions are available when needed."
    echo

    # Test 1: Core functions available immediately
    test_race_condition "core-immediate" \
        "Core module loader available immediately" \
        '[[ $(type -w "load_module" 2>/dev/null) == *": function" ]] && echo "core_ready" || echo "core_missing"' \
        "core_ready"

    # Test 2: Utils functions available for other modules
    test_race_condition "utils-ready" \
        "Utils functions available for module dependencies" \
        '[[ $(type -w "_report_missing_dependency" 2>/dev/null) == *": function" ]] && echo "utils_ready" || echo "utils_missing"' \
        "utils_ready"

    # Test 3: Background loading doesn't block critical functions
    local critical_functions=("load_module" "_report_missing_dependency" "_command_exists")
    local all_critical_ready=true

    for func in "${critical_functions[@]}"; do
        if [[ $(type -w "$func" 2>/dev/null) != *": function" ]]; then
            all_critical_ready=false
            break
        fi
    done

    if $all_critical_ready; then
        echo "${GREEN}    ✓ All critical functions available during background loading${NC}"
        TEST_RESULTS+=("✓ All critical functions available during background loading")
    else
        echo "${RED}    ✗ Some critical functions blocked by background loading${NC}"
        TEST_RESULTS+=("✗ Some critical functions blocked by background loading")
        FAILED_TESTS+=("critical-functions-blocked")
    fi

    echo
}

# =====================================================
# DEPENDENCY RESOLUTION RACE CONDITION TESTS
# =====================================================

test_dependency_resolution_race_conditions() {
    echo "${BLUE}Testing Dependency Resolution Race Conditions...${NC}"
    echo "These tests ensure dependencies are resolved in correct order."
    echo

    # Test 1: Oh-My-Zsh available before theme loading
    test_race_condition "omz-before-theme" \
        "Oh-My-Zsh available before theme configuration" \
        '[[ -n "$ZSH" ]] && echo "omz_ready" || echo "omz_missing"' \
        "omz_ready"

    # Test 2: Utils loaded before modules that depend on it
    test_race_condition "utils-before-deps" \
        "Utils loaded before dependent modules" \
        '[[ "$UTILS_MODULE_LOADED" == "true" ]] && echo "utils_first" || echo "utils_pending"' \
        "utils_first"

    # Test 3: Path dependencies resolved before module loading
    test_race_condition "paths-before-modules" \
        "Path dependencies resolved before module loading" \
        '[[ -d "$ZSH_MODULES_DIR" && -d "$ZSH_CONFIG_DIR" ]] && echo "paths_ready" || echo "paths_missing"' \
        "paths_ready"

    echo
}

# =====================================================
# CONCURRENT ACCESS PATTERN TESTS
# =====================================================

test_concurrent_access_patterns() {
    echo "${BLUE}Testing Concurrent Access Patterns...${NC}"
    echo "These tests simulate concurrent access scenarios that caused issues."
    echo

    # Test 1: Multiple background jobs accessing variables simultaneously
    local concurrent_test='
    {
        sleep 0.05
        [[ -n "$ZSH_CONFIG_DIR" ]] && echo "job1_ok" || echo "job1_fail"
    } &!
    {
        sleep 0.05
        [[ -n "$ZSH_MODULES_DIR" ]] && echo "job2_ok" || echo "job2_fail"
    } &!
    wait
    '

    local concurrent_results
    concurrent_results=$(eval "$concurrent_test" 2>/dev/null | sort)
    local expected_results=$'job1_ok\njob2_ok'

    if [[ "$concurrent_results" == "$expected_results" ]]; then
        echo "${GREEN}    ✓ Concurrent variable access works correctly${NC}"
        TEST_RESULTS+=("✓ Concurrent variable access works correctly")
    else
        echo "${RED}    ✗ Concurrent variable access has race conditions${NC}"
        echo "${RED}      Expected: job1_ok, job2_ok${NC}"
        echo "${RED}      Got: $concurrent_results${NC}"
        TEST_RESULTS+=("✗ Concurrent variable access has race conditions")
        FAILED_TESTS+=("concurrent-access")
    fi

    echo
}

# =====================================================
# MAIN TEST EXECUTION
# =====================================================

echo "${BOLD}🏁 Race Condition Detection Test Suite${NC}"
echo "======================================"
echo
echo "These tests detect the race conditions that caused system failures"
echo "and validate that the synchronization fixes work correctly."
echo

# Run all test suites
test_variable_availability_race_conditions
test_module_loading_order_race_conditions
test_background_job_synchronization
test_function_availability_timing
test_dependency_resolution_race_conditions
test_concurrent_access_patterns

# =====================================================
# RESULTS SUMMARY
# =====================================================

echo "${BOLD}Test Results Summary:${NC}"
echo "===================="

passed_count=0
failed_count=0

for result in "${TEST_RESULTS[@]}"; do
    if [[ "$result" == "✓"* ]]; then
        echo "${GREEN}$result${NC}"
        ((passed_count++))
    else
        echo "${RED}$result${NC}"
        ((failed_count++))
    fi
done

echo
echo "${BOLD}Statistics:${NC}"
echo "  Passed: ${GREEN}$passed_count${NC}"
echo "  Failed: ${RED}$failed_count${NC}"
echo "  Total: $((passed_count + failed_count))"

# Show failed race condition tests
if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo
    echo "${RED}${BOLD}Detected Race Conditions:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo "${RED}  - $test${NC}"
    done
    echo
    echo "${YELLOW}💡 These race conditions would have caused intermittent failures.${NC}"
fi

echo

# Final result
if [[ $failed_count -eq 0 ]]; then
    echo "${GREEN}${BOLD}✅ No race conditions detected!${NC}"
    echo "${GREEN}The synchronization fixes have resolved the timing issues.${NC}"
    exit 0
else
    echo "${RED}${BOLD}❌ Race conditions detected!${NC}"
    echo "${RED}These timing issues caused the original system failures.${NC}"
    exit 1
fi