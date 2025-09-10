#!/bin/bash

# =============================================================================
# COMPREHENSIVE BASH COMPATIBILITY TEST
# =============================================================================
# Tests the modular ZSH configuration system running in pure Bash
# Validates cross-shell compatibility and function loading
# =============================================================================

set -e

echo "🧪 Comprehensive Bash Compatibility Test Suite"
echo "=============================================="
echo ""

# Test environment
echo "📋 Test Environment:"
echo "   Shell: $0 ($(bash --version | head -1))"
echo "   Platform: $(uname -s)"
echo "   Date: $(date)"
echo ""

# Function to run test and report results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    
    echo "🔍 Testing: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        local result=$?
        if [[ $result -eq $expected_result ]]; then
            echo "   ✅ PASSED"
            return 0
        else
            echo "   ❌ FAILED (exit code: $result, expected: $expected_result)"
            return 1
        fi
    else
        echo "   ❌ FAILED (command failed to execute)"
        return 1
    fi
}

# Function to test if a function exists
test_function_exists() {
    local func_name="$1"
    run_test "Function exists: $func_name" "type $func_name"
}

# Function to test if a variable is set
test_variable_set() {
    local var_name="$1" 
    run_test "Variable set: $var_name" "[[ -n \"\${$var_name}\" ]]"
}

# =============================================================================
# PHASE 1: BASIC BASH SETUP
# =============================================================================

echo "🔧 Phase 1: Basic Bash Setup"
echo "-----------------------------"

# Test basic bash features (compatible with Bash 3.2+)
run_test "Command substitution" "[[ \$(echo 'test') == 'test' ]]"
run_test "Array support" "test_array=('one' 'two') && [[ \${test_array[1]} == 'two' ]]"
run_test "Parameter expansion" "[[ \${HOME:-/default} == \"$HOME\" ]]"

echo ""

# =============================================================================
# PHASE 2: LOAD MODULAR CONFIGURATION
# =============================================================================

echo "🚀 Phase 2: Loading Modular Configuration"
echo "----------------------------------------"

# Load centralized paths (or fallback to defaults)
source "$HOME/.config/zsh/zshrc" 2>/dev/null || {
    # Fallback if config not available
    export ZSH_CONFIG_DIR="$HOME/.config/zsh"
    export ZSH_CONFIG_MODULES="$ZSH_CONFIG_DIR/config"
    export ZSH_ACTIVE_REPO="$HOME/.config/zsh"
    export ZSH_ARCHIVE_REPO="$HOME/.zshrc_backups"
}

# Test configuration files exist
run_test "Config directory exists" "[[ -d '$ZSH_CONFIG_DIR' ]]"
run_test "Modules directory exists" "[[ -d '$ZSH_CONFIG_MODULES' ]]"
run_test "Main zshrc file exists" "[[ -f '$ZSH_CONFIG_DIR/zshrc' ]]"

# Load the configuration (suppress verbose output for testing)
echo "📦 Loading configuration..."
# Test loading in a separate bash process
load_result=$(MODULAR_ZSHRC_VERBOSE=false bash -c "source '$ZSH_CONFIG_DIR/zshrc' 2>/dev/null && echo 'SUCCESS'" 2>/dev/null || echo 'FAILED')
if [[ "$load_result" == "SUCCESS" ]]; then
    echo "   ✅ Configuration loaded successfully"
else
    echo "   ⚠️  Configuration load had issues, continuing with fallback testing..."
fi

echo ""

# =============================================================================
# PHASE 3: TEST MODULE LOADING SYSTEM
# =============================================================================

echo "🔧 Phase 3: Module Loading System"
echo "--------------------------------"

# Create a new bash session that loads the config
BASH_TEST_SESSION=$(cat << 'EOF'
#!/bin/bash
export ZSH_CONFIG_DIR="$HOME/.config/zsh"
source "$ZSH_CONFIG_DIR/zshrc" 2>/dev/null

# Test module loading variables
echo "LOADED_MODULES_TEST:${#LOADED_MODULES[@]}"

# Test if core functions are available
for func in modular_zsh_status environment_info platform_open; do
    if type "$func" >/dev/null 2>&1; then
        echo "FUNCTION_AVAILABLE:$func"
    else
        echo "FUNCTION_MISSING:$func"
    fi
done

# Test spark functions specifically
for func in spark_test_simple spark_status spark_start; do
    if type "$func" >/dev/null 2>&1; then
        echo "SPARK_FUNCTION_AVAILABLE:$func"
    else
        echo "SPARK_FUNCTION_MISSING:$func"
    fi
done

# Test platform detection
if type detect_platform >/dev/null 2>&1; then
    echo "PLATFORM_DETECTED:$(detect_platform)"
fi
EOF
)

# Run the test session
echo "🧪 Running bash test session..."
bash_output=$(echo "$BASH_TEST_SESSION" | bash 2>/dev/null)

# Analyze results
echo "📊 Results Analysis:"
if echo "$bash_output" | grep -q "LOADED_MODULES_TEST:"; then
    module_count=$(echo "$bash_output" | grep "LOADED_MODULES_TEST:" | cut -d: -f2)
    echo "   📦 Modules loaded: $module_count"
fi

# Check function availability
available_funcs=$(echo "$bash_output" | grep "FUNCTION_AVAILABLE:" | wc -l)
missing_funcs=$(echo "$bash_output" | grep "FUNCTION_MISSING:" | wc -l)
echo "   ✅ Core functions available: $available_funcs"
echo "   ❌ Core functions missing: $missing_funcs"

# Check Spark functions
spark_available=$(echo "$bash_output" | grep "SPARK_FUNCTION_AVAILABLE:" | wc -l)
spark_missing=$(echo "$bash_output" | grep "SPARK_FUNCTION_MISSING:" | wc -l)
echo "   ⚡ Spark functions available: $spark_available"
echo "   ❌ Spark functions missing: $spark_missing"

# Check platform detection
if echo "$bash_output" | grep -q "PLATFORM_DETECTED:"; then
    platform=$(echo "$bash_output" | grep "PLATFORM_DETECTED:" | cut -d: -f2)
    echo "   🌍 Platform detected: $platform"
fi

echo ""

# =============================================================================
# PHASE 4: FUNCTIONAL TESTING
# =============================================================================

echo "⚡ Phase 4: Functional Testing"
echo "-----------------------------"

# Test specific functions in bash
FUNCTIONAL_TEST=$(cat << 'EOF'
#!/bin/bash
export ZSH_CONFIG_DIR="$HOME/.config/zsh"
source "$ZSH_CONFIG_DIR/zshrc" >/dev/null 2>&1

echo "TESTING_STARTED"

# Test modular_zsh_status
if type modular_zsh_status >/dev/null 2>&1; then
    echo "TEST_STATUS:$(modular_zsh_status 2>/dev/null | grep -c "✅ Loaded" || echo "0")"
else
    echo "TEST_STATUS:MISSING"
fi

# Test environment_info
if type environment_info >/dev/null 2>&1; then
    echo "TEST_ENV_INFO:$(environment_info 2>/dev/null | grep -q "Platform:" && echo "OK" || echo "FAIL")"
else
    echo "TEST_ENV_INFO:MISSING"
fi

# Test platform detection functions
if type detect_platform >/dev/null 2>&1; then
    platform=$(detect_platform 2>/dev/null)
    echo "TEST_PLATFORM:$platform"
else
    echo "TEST_PLATFORM:MISSING"
fi

# Test spark_test_simple (if available)
if type spark_test_simple >/dev/null 2>&1; then
    # Run a basic check (not full test to avoid dependencies)
    echo "TEST_SPARK_SIMPLE:AVAILABLE"
else
    echo "TEST_SPARK_SIMPLE:MISSING"
fi

echo "TESTING_COMPLETED"
EOF
)

echo "🔬 Running functional tests..."
func_output=$(echo "$FUNCTIONAL_TEST" | bash 2>/dev/null)

# Parse functional test results
if echo "$func_output" | grep -q "TESTING_STARTED"; then
    echo "   ✅ Functional test session started successfully"
    
    # Check individual test results
    if echo "$func_output" | grep -q "TEST_STATUS:"; then
        status_result=$(echo "$func_output" | grep "TEST_STATUS:" | cut -d: -f2)
        echo "   📊 Status function: $status_result modules detected"
    fi
    
    if echo "$func_output" | grep -q "TEST_ENV_INFO:"; then
        env_result=$(echo "$func_output" | grep "TEST_ENV_INFO:" | cut -d: -f2)
        echo "   🌍 Environment info: $env_result"
    fi
    
    if echo "$func_output" | grep -q "TEST_PLATFORM:"; then
        platform_result=$(echo "$func_output" | grep "TEST_PLATFORM:" | cut -d: -f2)
        echo "   🔍 Platform detection: $platform_result"
    fi
    
    if echo "$func_output" | grep -q "TEST_SPARK_SIMPLE:"; then
        spark_result=$(echo "$func_output" | grep "TEST_SPARK_SIMPLE:" | cut -d: -f2)
        echo "   ⚡ Spark test function: $spark_result"
    fi
    
    if echo "$func_output" | grep -q "TESTING_COMPLETED"; then
        echo "   ✅ All functional tests completed"
    fi
else
    echo "   ❌ Functional test session failed to start"
fi

echo ""

# =============================================================================
# PHASE 5: COMPATIBILITY SUMMARY
# =============================================================================

echo "📋 Phase 5: Compatibility Summary"
echo "--------------------------------"

# Calculate overall compatibility score
total_tests=0
passed_tests=0

# Count basic setup tests (3 tests)
total_tests=$((total_tests + 3))
passed_tests=$((passed_tests + 3))  # Assume they passed if we got this far

# Count module loading tests
total_tests=$((total_tests + 1))
if [[ $module_count -gt 0 ]]; then
    passed_tests=$((passed_tests + 1))
fi

# Count function availability tests
total_tests=$((total_tests + available_funcs + missing_funcs))
passed_tests=$((passed_tests + available_funcs))

# Count Spark function tests
total_tests=$((total_tests + spark_available + spark_missing))
passed_tests=$((passed_tests + spark_available))

# Calculate percentage
if [[ $total_tests -gt 0 ]]; then
    compatibility_percent=$(( (passed_tests * 100) / total_tests ))
else
    compatibility_percent=0
fi

echo "🎯 Overall Bash Compatibility: $compatibility_percent% ($passed_tests/$total_tests tests passed)"

if [[ $compatibility_percent -ge 90 ]]; then
    echo "   🎉 EXCELLENT: Bash compatibility is excellent!"
    exit_code=0
elif [[ $compatibility_percent -ge 75 ]]; then
    echo "   ✅ GOOD: Bash compatibility is good with minor issues"
    exit_code=0
elif [[ $compatibility_percent -ge 50 ]]; then
    echo "   ⚠️  FAIR: Bash compatibility has some issues that need attention"
    exit_code=1
else
    echo "   ❌ POOR: Bash compatibility has significant issues"
    exit_code=1
fi

echo ""
echo "💡 Testing Recommendations:"
echo "   • Run this test regularly during development"
echo "   • Test on different platforms (Linux, macOS, WSL)"
echo "   • Verify after making changes to module loading system"
echo "   • Use 'bash -l' to test login shell behavior"

echo ""
echo "🔚 Bash compatibility testing completed!"

exit $exit_code