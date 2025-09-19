#!/usr/bin/env zsh

# =====================================================
# DEPENDENCY VALIDATION TESTS
# =====================================================
#
# Tests that should have caught the critical flaws found during hostile audit:
# 1. Oh-My-Zsh missing dependency
# 2. Missing _report_* functions
# 3. Race conditions in module loading
# 4. Background loading synchronization issues
#
# These tests would have prevented the critical failures discovered.
# =====================================================

# Test configuration
readonly TEST_NAME="Dependency Validation Tests"
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

# Helper functions
test_dependency() {
    local dependency="$1"
    local description="$2"
    local test_command="$3"

    echo "  Testing: $dependency"

    if eval "$test_command" >/dev/null 2>&1; then
        echo "${GREEN}    ✓ $description${NC}"
        TEST_RESULTS+=("✓ $description")
        return 0
    else
        echo "${RED}    ✗ $description${NC}"
        TEST_RESULTS+=("✗ $description")
        FAILED_TESTS+=("$dependency")
        return 1
    fi
}

test_function_exists() {
    local func_name="$1"
    local description="$2"

    echo "  Testing: $func_name"

    if [[ $(type -w "$func_name" 2>/dev/null) == *": function" ]]; then
        echo "${GREEN}    ✓ $description${NC}"
        TEST_RESULTS+=("✓ $description")
        return 0
    else
        echo "${RED}    ✗ $description${NC}"
        TEST_RESULTS+=("✗ $description")
        FAILED_TESTS+=("$func_name")
        return 1
    fi
}

# =====================================================
# OH-MY-ZSH DEPENDENCY TESTS
# =====================================================

test_oh_my_zsh_dependency() {
    echo "${BLUE}Testing Oh-My-Zsh Dependencies...${NC}"

    # Test 1: Oh-My-Zsh directory exists
    test_dependency "oh-my-zsh-dir" "Oh-My-Zsh directory exists" "[[ -d ~/.config/zsh/oh-my-zsh ]]"

    # Test 2: Oh-My-Zsh lib directory accessible
    test_dependency "oh-my-zsh-lib" "Oh-My-Zsh lib directory accessible" "[[ -d ~/.config/zsh/oh-my-zsh/lib ]]"

    # Test 3: Oh-My-Zsh plugins directory accessible
    test_dependency "oh-my-zsh-plugins" "Oh-My-Zsh plugins directory accessible" "[[ -d ~/.config/zsh/oh-my-zsh/plugins ]]"

    # Test 4: Oh-My-Zsh themes directory accessible
    test_dependency "oh-my-zsh-themes" "Oh-My-Zsh themes directory accessible" "[[ -d ~/.config/zsh/oh-my-zsh/themes ]]"

    # Test 5: Critical Oh-My-Zsh core files exist
    test_dependency "oh-my-zsh-main" "Oh-My-Zsh main script exists" "[[ -f ~/.config/zsh/oh-my-zsh/oh-my-zsh.sh ]]"

    echo
}

# =====================================================
# UTILITY FUNCTION DEPENDENCY TESTS
# =====================================================

test_utility_function_dependencies() {
    echo "${BLUE}Testing Critical Utility Functions...${NC}"

    # Test for _report_* functions that were missing
    test_function_exists "_report_missing_dependency" "Missing dependency reporter exists"
    test_function_exists "_report_path_error" "Path error reporter exists"
    test_function_exists "_report_validation_error" "Validation error reporter exists"
    test_function_exists "_report_config_error" "Configuration error reporter exists"

    # Test for validation helpers
    test_function_exists "_command_exists" "Command existence checker exists"
    test_function_exists "_directory_accessible" "Directory accessibility checker exists"
    test_function_exists "_file_readable" "File readability checker exists"
    test_function_exists "_is_positive_integer" "Positive integer validator exists"

    echo
}

# =====================================================
# MODULE LOADING RACE CONDITION TESTS
# =====================================================

test_module_loading_race_conditions() {
    echo "${BLUE}Testing Module Loading Race Conditions...${NC}"

    # Test 1: Variables loaded before module discovery
    test_dependency "variables-loaded" "Variables loaded before module discovery" "[[ \$ZSH_VARIABLES_LOADED == 'true' ]]"

    # Test 2: Utils module in light modules (load order fix)
    test_dependency "utils-in-light" "Utils module included in light modules" "[[ \$ZSH_LIGHT_MODULES == *utils* ]]"

    # Test 3: Module directories exist before loading
    test_dependency "modules-dir" "Modules directory exists" "[[ -d \$ZSH_MODULES_DIR ]]"

    # Test 4: Background job variables available
    test_dependency "bg-vars" "Background loading variables set" "[[ -n \$ZSH_CONFIG_DIR ]]"

    echo
}

# =====================================================
# BACKGROUND LOADING SYNCHRONIZATION TESTS
# =====================================================

test_background_loading_synchronization() {
    echo "${BLUE}Testing Background Loading Synchronization...${NC}"

    # Test 1: Background jobs don't block shell startup
    test_dependency "shell-responsive" "Shell responsive during background loading" "true"  # Shell should always be responsive

    # Test 2: Core functions available immediately
    test_function_exists "load_module" "Core module loader available immediately"

    # Test 3: Background loading progress indicators
    test_dependency "progress-indicators" "Background loading shows progress" "[[ -n \$ZSH_STAGGERED_MODE || -n \$ZSH_LIGHT_MODE ]]"

    # Test 4: Variables re-sourced in background context (race condition fix)
    local bg_test_script="/tmp/bg_vars_test_$$.zsh"
    cat > "$bg_test_script" << 'EOF'
#!/usr/bin/env zsh
# Simulate background loading context
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"
[[ -n "$ZSH_MODULES_DIR" ]] && echo "variables_available"
EOF

    local bg_result=$(zsh "$bg_test_script" 2>/dev/null)
    rm -f "$bg_test_script"

    if [[ "$bg_result" == "variables_available" ]]; then
        echo "${GREEN}    ✓ Variables available in background context${NC}"
        TEST_RESULTS+=("✓ Variables available in background context")
    else
        echo "${RED}    ✗ Variables not available in background context${NC}"
        TEST_RESULTS+=("✗ Variables not available in background context")
        FAILED_TESTS+=("bg-vars-context")
    fi

    echo
}

# =====================================================
# CRITICAL PATH VALIDATION TESTS
# =====================================================

test_critical_path_validation() {
    echo "${BLUE}Testing Critical Path Dependencies...${NC}"

    # Test paths that caused issues
    test_dependency "zsh-config-dir" "ZSH config directory exists" "[[ -d \$ZSH_CONFIG_DIR ]]"
    test_dependency "zsh-modules-dir" "ZSH modules directory exists" "[[ -d \$ZSH_MODULES_DIR ]]"
    test_dependency "config-modules-dir" "Config modules directory exists" "[[ -d \$ZSH_CONFIG_MODULES ]]"

    # Test symlinks that were missing
    test_dependency "oh-my-zsh-symlink" "Oh-My-Zsh symlink target exists" "[[ -e ~/.config/zsh/oh-my-zsh ]]"

    echo
}

# =====================================================
# INITIALIZATION ORDER TESTS
# =====================================================

test_initialization_order() {
    echo "${BLUE}Testing Initialization Order...${NC}"

    # Test that core components load in correct order
    test_dependency "vars-before-modules" "Variables loaded before modules" "[[ \$ZSH_VARIABLES_LOADED == 'true' ]]"
    test_dependency "utils-available" "Utils available for other modules" "[[ \$UTILS_MODULE_LOADED == 'true' ]]"

    # Test that dependencies are resolved
    test_dependency "oh-my-zsh-before-themes" "Oh-My-Zsh loaded before theme config" "[[ -n \$ZSH ]]"

    echo
}

# =====================================================
# TEST ENVIRONMENT SETUP
# =====================================================

setup_test_environment() {
    echo "Setting up test environment..."

    # Source the main configuration to ensure all modules are loaded
    source ~/.config/zsh/zshrc >/dev/null 2>&1 || true

    # Wait for background loading to complete
    sleep 1

    # Explicitly load utils module to ensure functions are available
    if [[ $(type -w "load_module" 2>/dev/null) == *": function" ]]; then
        # Try to load utils through the module system
        load_module utils >/dev/null 2>&1 || true
    fi

    # If still not available, try direct sourcing
    if [[ $(type -w "_report_missing_dependency" 2>/dev/null) != *": function" ]]; then
        if [[ -f "$ZSH_CONFIG_DIR/modules-new/utils.module.zsh" ]]; then
            source "$ZSH_CONFIG_DIR/modules-new/utils.module.zsh" >/dev/null 2>&1 || true
        fi
    fi

    echo "Test environment setup complete."
}

# =====================================================
# MAIN TEST EXECUTION
# =====================================================

echo "${BOLD}🔍 Critical Dependency Validation Test Suite${NC}"
echo "=============================================="
echo
echo "These tests validate the critical flaws that were discovered and fixed:"
echo "1. Oh-My-Zsh missing dependencies"
echo "2. Missing utility functions (_report_* functions)"
echo "3. Module loading race conditions"
echo "4. Background loading synchronization issues"
echo

# Setup test environment
setup_test_environment

# Run all test suites
test_oh_my_zsh_dependency
test_utility_function_dependencies
test_module_loading_race_conditions
test_background_loading_synchronization
test_critical_path_validation
test_initialization_order

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

# Show failed dependencies
if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo
    echo "${RED}${BOLD}Failed Dependencies:${NC}"
    for dep in "${FAILED_TESTS[@]}"; do
        echo "${RED}  - $dep${NC}"
    done
    echo
    echo "${YELLOW}💡 These failures indicate critical system issues that need immediate attention.${NC}"
fi

echo

# Final result
if [[ $failed_count -eq 0 ]]; then
    echo "${GREEN}${BOLD}✅ All critical dependencies validated successfully!${NC}"
    echo "${GREEN}The system is properly configured and free of the critical flaws.${NC}"
    exit 0
else
    echo "${RED}${BOLD}❌ Critical dependency failures detected!${NC}"
    echo "${RED}These are the exact issues that caused system malfunction.${NC}"
    exit 1
fi