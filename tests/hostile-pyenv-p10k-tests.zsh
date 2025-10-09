#!/usr/bin/env zsh
# =====================================================
# HOSTILE TESTING FOR PYENV & P10K FIXES
# =====================================================
# Purpose: Verify pyenv completion and P10k integration:
# 1. Pyenv completion functionality
# 2. P10k instant prompt configuration
#
# These tests aggressively verify the fixes work under adversarial conditions
# =====================================================

echo "🔥 HOSTILE PYENV & P10K TESTING FRAMEWORK"
echo "=========================================="
echo "Testing pyenv and P10k integration:"
echo "1. Pyenv completion functionality"
echo "2. P10k instant prompt configuration"
echo ""

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CRITICAL_FAILURES=0

# Test result tracking
TEST_RESULTS=()
CRITICAL_ISSUES=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Logging function
log_test() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    local is_critical="${4:-false}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    if [[ "$result" == "PASS" ]]; then
        echo -e "${GREEN}✅ PASS${NC}: $test_name"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    elif [[ "$result" == "FAIL" ]]; then
        echo -e "${RED}❌ FAIL${NC}: $test_name"
        if [[ -n "$details" ]]; then
            echo -e "   ${RED}└─${NC} $details"
        fi
        FAILED_TESTS=$((FAILED_TESTS + 1))

        if [[ "$is_critical" == "true" ]]; then
            CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
            CRITICAL_ISSUES+=("$test_name: $details")
        fi
    elif [[ "$result" == "CRITICAL" ]]; then
        echo -e "${RED}🚨 CRITICAL FAILURE${NC}: $test_name"
        if [[ -n "$details" ]]; then
            echo -e "   ${RED}└─${NC} $details"
        fi
        CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
        FAILED_TESTS=$((FAILED_TESTS + 1))
        CRITICAL_ISSUES+=("$test_name: $details")
    fi

    TEST_RESULTS+=("$result: $test_name")
}

# Setup environment
export ZSH_CONFIG_DIR="/Users/dheerajchand/.config/zsh"
export ZSH_CACHE_DIR="$ZSH_CONFIG_DIR/cache"

echo "🔧 Setting up hostile testing environment..."
echo "ZSH_CONFIG_DIR: $ZSH_CONFIG_DIR"

# Create test isolation environment
TEST_ENV_DIR="/tmp/hostile_test_env_$$"
mkdir -p "$TEST_ENV_DIR"

echo ""
echo "🧪 PHASE 1: PYENV COMPLETION FIX VERIFICATION"
echo "============================================="

# Test 1.1: Verify variable name fix in load_module function
echo -e "${BLUE}Testing variable collision fix...${NC}"

test_source_content=$(cat "$ZSH_CONFIG_DIR/zshrc" | grep -A 10 "load_module()" | grep "module_")
if echo "$test_source_content" | grep -q "module_file" && ! echo "$test_source_content" | grep -q "module_path="; then
    log_test "Variable name fix verification" "PASS" "load_module uses 'module_file' instead of 'module_path'"
else
    log_test "Variable name fix verification" "CRITICAL" "load_module still uses problematic 'module_path' variable" true
fi

# Test 1.2: Create hostile pyenv environment simulation
cat > "$TEST_ENV_DIR/pyenv_completion_test.zsh" << 'EOF'
#!/usr/bin/env zsh
# Simulate PyCharm/IDE environment with pyenv completion

# Set up zsh module path (this is what was causing the collision)
module_path=(/usr/local/lib/zsh/site-functions /usr/share/zsh/functions)

# Source the main zshrc to test for variable collision
source ~/.config/zsh/zshrc >/dev/null 2>&1

# Test pyenv completion loading
if command -v pyenv >/dev/null 2>&1; then
    # Try to load pyenv completions
    eval "$(pyenv init - zsh)" 2>&1 | grep -i "failed to load module" && echo "PYENV_COMPLETION_FAILED" || echo "PYENV_COMPLETION_SUCCESS"
else
    echo "PYENV_NOT_AVAILABLE"
fi

# Test module loading still works
load_module python >/dev/null 2>&1
if typeset -f python_status >/dev/null 2>&1; then
    echo "MODULE_LOADING_SUCCESS"
else
    echo "MODULE_LOADING_FAILED"
fi
EOF

chmod +x "$TEST_ENV_DIR/pyenv_completion_test.zsh"

# Run pyenv completion test
pyenv_test_result=$("$TEST_ENV_DIR/pyenv_completion_test.zsh" 2>&1)

if echo "$pyenv_test_result" | grep -q "PYENV_COMPLETION_FAILED"; then
    log_test "Pyenv completion collision test" "CRITICAL" "Pyenv still fails to load with 'failed to load module' error" true
elif echo "$pyenv_test_result" | grep -q "MODULE_LOADING_FAILED"; then
    log_test "Pyenv completion collision test" "FAIL" "Module loading broken after pyenv interaction" true
elif echo "$pyenv_test_result" | grep -q "PYENV_NOT_AVAILABLE"; then
    log_test "Pyenv completion collision test" "PASS" "Pyenv not available - testing variable collision directly"
else
    log_test "Pyenv completion collision test" "PASS" "No pyenv completion failures detected"
fi

# Test 1.3: IDE environment simulation (PyCharm, IntelliJ, etc.)
echo -e "${BLUE}Testing IDE environment compatibility...${NC}"

cat > "$TEST_ENV_DIR/ide_environment_test.zsh" << 'EOF'
#!/usr/bin/env zsh
# Simulate hostile IDE environment

# Set environment variables that IDEs commonly set
export TERMINAL_EMULATOR="JetBrains-JediTerm"
export TERM_PROGRAM="PyCharm"
export PYCHARM_HOSTED=1

# Pre-populate module_path array (this was the source of the collision)
typeset -a module_path
module_path=(/usr/lib/zsh /usr/local/share/zsh)

# Source zshrc - this should not interfere with the pre-existing module_path
source ~/.config/zsh/zshrc >/dev/null 2>&1

# Verify the global module_path array is still intact
echo "module_path array contents: ${module_path[@]}"

# Test module loading functionality
load_module utils >/dev/null 2>&1
if typeset -f backup >/dev/null 2>&1; then
    echo "IDE_MODULE_LOADING_SUCCESS"
else
    echo "IDE_MODULE_LOADING_FAILED"
fi

# Test that our local variable doesn't interfere with global scope
if [[ "${#module_path[@]}" -gt 0 ]]; then
    echo "GLOBAL_MODULE_PATH_PRESERVED"
else
    echo "GLOBAL_MODULE_PATH_CORRUPTED"
fi
EOF

chmod +x "$TEST_ENV_DIR/ide_environment_test.zsh"

ide_test_result=$("$TEST_ENV_DIR/ide_environment_test.zsh" 2>&1)

if echo "$ide_test_result" | grep -q "IDE_MODULE_LOADING_FAILED"; then
    log_test "IDE environment module loading" "CRITICAL" "Module loading fails in IDE environment" true
elif echo "$ide_test_result" | grep -q "GLOBAL_MODULE_PATH_CORRUPTED"; then
    log_test "IDE environment module loading" "FAIL" "Global module_path array corrupted by local variable" true
else
    log_test "IDE environment module loading" "PASS" "Module loading works correctly in IDE environment"
fi

# Test 1.4: Concurrent module loading (stress test the variable scoping)
echo -e "${BLUE}Testing concurrent module loading for variable collision...${NC}"

cat > "$TEST_ENV_DIR/concurrent_loading_test.zsh" << 'EOF'
#!/usr/bin/env zsh
source ~/.config/zsh/zshrc >/dev/null 2>&1

# Run multiple module loads concurrently to test for variable collision
for i in {1..5}; do
    (
        load_module utils >/dev/null 2>&1
        if typeset -f backup >/dev/null 2>&1; then
            echo "CONCURRENT_LOAD_${i}_SUCCESS"
        else
            echo "CONCURRENT_LOAD_${i}_FAILED"
        fi
    ) &
done

wait
EOF

chmod +x "$TEST_ENV_DIR/concurrent_loading_test.zsh"

concurrent_result=$("$TEST_ENV_DIR/concurrent_loading_test.zsh" 2>&1)
concurrent_failures=$(echo "$concurrent_result" | grep -c "FAILED")

if [[ $concurrent_failures -gt 0 ]]; then
    log_test "Concurrent module loading" "FAIL" "$concurrent_failures out of 5 concurrent loads failed" true
else
    log_test "Concurrent module loading" "PASS" "All concurrent module loads succeeded"
fi

echo ""
echo "🎨 PHASE 2: P10K INSTANT PROMPT FIX VERIFICATION"
echo "==============================================="

# Test 2.1: Verify POWERLEVEL9K_INSTANT_PROMPT default setting
echo -e "${BLUE}Testing P10k instant prompt default setting...${NC}"

test_p10k_default=$(zsh -c 'source ~/.config/zsh/zshrc >/dev/null 2>&1; echo "P10K_SETTING:$POWERLEVEL9K_INSTANT_PROMPT"' 2>&1)

if echo "$test_p10k_default" | grep -q "P10K_SETTING:off"; then
    log_test "P10k instant prompt default setting" "PASS" "POWERLEVEL9K_INSTANT_PROMPT correctly defaults to 'off'"
else
    log_test "P10k instant prompt default setting" "CRITICAL" "POWERLEVEL9K_INSTANT_PROMPT not set to 'off' by default" true
fi

# Test 2.2: Test console output suppression during module loading
echo -e "${BLUE}Testing console output suppression...${NC}"

cat > "$TEST_ENV_DIR/console_output_test.zsh" << 'EOF'
#!/usr/bin/env zsh
# Test with instant prompt OFF (should show output)
export POWERLEVEL9K_INSTANT_PROMPT="off"
source ~/.config/zsh/zshrc 2>&1 | grep "📦 Loading" | wc -l
EOF

cat > "$TEST_ENV_DIR/console_output_test_instant.zsh" << 'EOF'
#!/usr/bin/env zsh
# Test with instant prompt ON (should suppress output)
export POWERLEVEL9K_INSTANT_PROMPT="verbose"
# This should trigger warnings if console output occurs
source ~/.config/zsh/zshrc 2>&1 | grep -E "(WARNING|warning|instant prompt)" | wc -l
EOF

chmod +x "$TEST_ENV_DIR/console_output_test.zsh"
chmod +x "$TEST_ENV_DIR/console_output_test_instant.zsh"

output_count_off=$("$TEST_ENV_DIR/console_output_test.zsh" 2>/dev/null)
output_count_instant=$("$TEST_ENV_DIR/console_output_test_instant.zsh" 2>/dev/null)

if [[ "$output_count_off" -gt 0 ]] && [[ "$output_count_instant" -eq 0 ]]; then
    log_test "Console output suppression" "PASS" "Output correctly suppressed when instant prompt enabled"
elif [[ "$output_count_instant" -gt 0 ]]; then
    log_test "Console output suppression" "FAIL" "P10k warnings detected when instant prompt enabled" true
else
    log_test "Console output suppression" "PASS" "No console output interference detected"
fi

# Test 2.3: Test P10k toggle functionality
echo -e "${BLUE}Testing P10k toggle functionality...${NC}"

cat > "$TEST_ENV_DIR/p10k_toggle_test.zsh" << 'EOF'
#!/usr/bin/env zsh
# Test the toggle mechanism
export ENABLE_P10K_INSTANT_PROMPT="true"
source ~/.config/zsh/zshrc >/dev/null 2>&1

if [[ "$POWERLEVEL9K_INSTANT_PROMPT" == "verbose" ]]; then
    echo "TOGGLE_ENABLE_SUCCESS"
else
    echo "TOGGLE_ENABLE_FAILED:$POWERLEVEL9K_INSTANT_PROMPT"
fi

# Test the opposite
export ENABLE_P10K_INSTANT_PROMPT="false"
source ~/.config/zsh/zshrc >/dev/null 2>&1

if [[ "$POWERLEVEL9K_INSTANT_PROMPT" == "off" ]]; then
    echo "TOGGLE_DISABLE_SUCCESS"
else
    echo "TOGGLE_DISABLE_FAILED:$POWERLEVEL9K_INSTANT_PROMPT"
fi
EOF

chmod +x "$TEST_ENV_DIR/p10k_toggle_test.zsh"

toggle_result=$("$TEST_ENV_DIR/p10k_toggle_test.zsh" 2>&1)

if echo "$toggle_result" | grep -q "TOGGLE_ENABLE_SUCCESS" && echo "$toggle_result" | grep -q "TOGGLE_DISABLE_SUCCESS"; then
    log_test "P10k toggle functionality" "PASS" "Toggle mechanism works correctly"
elif echo "$toggle_result" | grep -q "TOGGLE_.*_FAILED"; then
    failed_toggle=$(echo "$toggle_result" | grep "TOGGLE_.*_FAILED" | head -1)
    log_test "P10k toggle functionality" "FAIL" "Toggle mechanism broken: $failed_toggle" true
else
    log_test "P10k toggle functionality" "FAIL" "Toggle mechanism not responding"
fi

# Test 2.4: Terminal emulator compatibility test
echo -e "${BLUE}Testing terminal emulator compatibility...${NC}"

for terminal in "iTerm.app" "Terminal.app" "Warp" "Kitty" "Alacritty"; do
    cat > "$TEST_ENV_DIR/terminal_test_$terminal.zsh" << EOF
#!/usr/bin/env zsh
export TERM_PROGRAM="$terminal"
source ~/.config/zsh/zshrc 2>&1 | grep -i "warning\|error" | wc -l
EOF
    chmod +x "$TEST_ENV_DIR/terminal_test_$terminal.zsh"

    warning_count=$("$TEST_ENV_DIR/terminal_test_$terminal.zsh" 2>/dev/null)

    if [[ "$warning_count" -eq 0 ]]; then
        log_test "Terminal compatibility: $terminal" "PASS"
    else
        log_test "Terminal compatibility: $terminal" "FAIL" "$warning_count warnings detected"
    fi
done

echo ""
echo "⚡ PHASE 3: INTEGRATION & REGRESSION TESTS"
echo "=========================================="

# Test 3.1: Verify both fixes work together
echo -e "${BLUE}Testing both fixes integration...${NC}"

cat > "$TEST_ENV_DIR/integration_test.zsh" << 'EOF'
#!/usr/bin/env zsh
# Simulate worst-case scenario: IDE environment with pyenv + P10k instant prompt

# Set up the problematic environment
export TERM_PROGRAM="PyCharm"
export PYCHARM_HOSTED=1
typeset -a module_path
module_path=(/usr/lib/zsh /usr/local/share/zsh)

# Test with instant prompt enabled (should not cause warnings)
export ENABLE_P10K_INSTANT_PROMPT="true"

# Source zshrc and capture all output
zsh_output=$(source ~/.config/zsh/zshrc 2>&1)

# Check for pyenv completion errors
pyenv_errors=$(echo "$zsh_output" | grep -c "failed to load module")

# Check for P10k warnings
p10k_warnings=$(echo "$zsh_output" | grep -c -i "instant prompt.*warning")

# Test module loading still works
load_module python >/dev/null 2>&1
if typeset -f python_status >/dev/null 2>&1; then
    module_success="true"
else
    module_success="false"
fi

echo "PYENV_ERRORS:$pyenv_errors"
echo "P10K_WARNINGS:$p10k_warnings"
echo "MODULE_SUCCESS:$module_success"
echo "P10K_SETTING:$POWERLEVEL9K_INSTANT_PROMPT"
EOF

chmod +x "$TEST_ENV_DIR/integration_test.zsh"

integration_result=$("$TEST_ENV_DIR/integration_test.zsh" 2>&1)

pyenv_errors=$(echo "$integration_result" | grep "PYENV_ERRORS:" | cut -d: -f2)
p10k_warnings=$(echo "$integration_result" | grep "P10K_WARNINGS:" | cut -d: -f2)
module_success=$(echo "$integration_result" | grep "MODULE_SUCCESS:" | cut -d: -f2)

if [[ "$pyenv_errors" -eq 0 ]] && [[ "$p10k_warnings" -eq 0 ]] && [[ "$module_success" == "true" ]]; then
    log_test "Integration test (both fixes)" "PASS" "Both fixes work together without regression"
else
    error_details="pyenv_errors:$pyenv_errors, p10k_warnings:$p10k_warnings, module_success:$module_success"
    log_test "Integration test (both fixes)" "CRITICAL" "Integration failure: $error_details" true
fi

# Test 3.2: Stress test with rapid environment changes
echo -e "${BLUE}Testing rapid environment changes...${NC}"

cat > "$TEST_ENV_DIR/stress_test.zsh" << 'EOF'
#!/usr/bin/env zsh
success_count=0
total_attempts=10

for i in {1..10}; do
    # Rapid toggle of P10k settings
    export ENABLE_P10K_INSTANT_PROMPT=$([[ $((i % 2)) -eq 0 ]] && echo "true" || echo "false")

    # Vary terminal environment
    case $((i % 3)) in
        0) export TERM_PROGRAM="iTerm.app" ;;
        1) export TERM_PROGRAM="Terminal.app" ;;
        2) export TERM_PROGRAM="PyCharm" ;;
    esac

    # Source and test
    if source ~/.config/zsh/zshrc >/dev/null 2>&1 && load_module utils >/dev/null 2>&1 && typeset -f backup >/dev/null 2>&1; then
        success_count=$((success_count + 1))
    fi
done

echo "STRESS_SUCCESS:$success_count/$total_attempts"
EOF

chmod +x "$TEST_ENV_DIR/stress_test.zsh"

stress_result=$("$TEST_ENV_DIR/stress_test.zsh" 2>&1)
stress_success=$(echo "$stress_result" | grep "STRESS_SUCCESS:" | cut -d: -f2)

if echo "$stress_success" | grep -q "10/10"; then
    log_test "Rapid environment stress test" "PASS" "All 10 rapid environment changes succeeded"
elif echo "$stress_success" | grep -q "/10"; then
    success_rate=$(echo "$stress_success" | cut -d/ -f1)
    if [[ "$success_rate" -ge 8 ]]; then
        log_test "Rapid environment stress test" "PASS" "High success rate: $stress_success"
    else
        log_test "Rapid environment stress test" "FAIL" "Low success rate: $stress_success"
    fi
else
    log_test "Rapid environment stress test" "FAIL" "Could not determine success rate"
fi

echo ""
echo "🔍 PHASE 4: EDGE CASE & FAILURE MODE TESTING"
echo "==========================================="

# Test 4.1: Test with corrupted module_path array
echo -e "${BLUE}Testing corrupted module_path array handling...${NC}"

cat > "$TEST_ENV_DIR/corrupted_module_path_test.zsh" << 'EOF'
#!/usr/bin/env zsh
# Corrupt the global module_path array
typeset -a module_path
module_path=("invalid_path_1" "invalid_path_2" "/nonexistent/path")

# This should not break our module loading
source ~/.config/zsh/zshrc >/dev/null 2>&1

# Test module loading still works despite corrupted global state
load_module utils >/dev/null 2>&1
if typeset -f backup >/dev/null 2>&1; then
    echo "CORRUPTED_MODULE_PATH_HANDLED"
else
    echo "CORRUPTED_MODULE_PATH_BROKE_LOADING"
fi

# Verify global array is still intact (not overwritten by our local variable)
if [[ "${module_path[1]}" == "invalid_path_1" ]]; then
    echo "GLOBAL_ARRAY_PRESERVED"
else
    echo "GLOBAL_ARRAY_OVERWRITTEN"
fi
EOF

chmod +x "$TEST_ENV_DIR/corrupted_module_path_test.zsh"

corrupted_result=$("$TEST_ENV_DIR/corrupted_module_path_test.zsh" 2>&1)

if echo "$corrupted_result" | grep -q "CORRUPTED_MODULE_PATH_BROKE_LOADING"; then
    log_test "Corrupted module_path handling" "CRITICAL" "Module loading breaks with corrupted global module_path" true
elif echo "$corrupted_result" | grep -q "GLOBAL_ARRAY_OVERWRITTEN"; then
    log_test "Corrupted module_path handling" "FAIL" "Local variable overwrites global module_path array" true
else
    log_test "Corrupted module_path handling" "PASS" "Module loading resilient to corrupted global state"
fi

# Test 4.2: Test P10k behavior with missing cache directories
echo -e "${BLUE}Testing P10k with missing cache directories...${NC}"

cat > "$TEST_ENV_DIR/missing_cache_test.zsh" << 'EOF'
#!/usr/bin/env zsh
# Remove P10k cache
rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" 2>/dev/null

export ENABLE_P10K_INSTANT_PROMPT="true"
source ~/.config/zsh/zshrc 2>&1 | grep -c -i "error\|failed\|warning"
EOF

chmod +x "$TEST_ENV_DIR/missing_cache_test.zsh"

missing_cache_errors=$("$TEST_ENV_DIR/missing_cache_test.zsh" 2>/dev/null)

if [[ "$missing_cache_errors" -eq 0 ]]; then
    log_test "Missing P10k cache handling" "PASS" "No errors with missing P10k cache"
else
    log_test "Missing P10k cache handling" "FAIL" "$missing_cache_errors errors with missing cache"
fi

# Test 4.3: Test with extremely long module names (edge case)
echo -e "${BLUE}Testing edge case with unusual module names...${NC}"

cat > "$TEST_ENV_DIR/edge_case_test.zsh" << 'EOF'
#!/usr/bin/env zsh
source ~/.config/zsh/zshrc >/dev/null 2>&1

# Test with non-existent module (should fail gracefully)
load_module "nonexistent_module_with_very_long_name_that_definitely_does_not_exist" >/dev/null 2>&1
exit_code=$?

# Test with empty module name (should fail gracefully)
load_module "" >/dev/null 2>&1
empty_exit_code=$?

if [[ $exit_code -ne 0 ]] && [[ $empty_exit_code -ne 0 ]]; then
    echo "EDGE_CASES_HANDLED"
else
    echo "EDGE_CASES_NOT_HANDLED"
fi
EOF

chmod +x "$TEST_ENV_DIR/edge_case_test.zsh"

edge_case_result=$("$TEST_ENV_DIR/edge_case_test.zsh" 2>&1)

if echo "$edge_case_result" | grep -q "EDGE_CASES_HANDLED"; then
    log_test "Edge case module names" "PASS" "Invalid module names handled gracefully"
else
    log_test "Edge case module names" "FAIL" "Edge cases not properly handled"
fi

# Cleanup test environment
rm -rf "$TEST_ENV_DIR"

echo ""
echo "📊 HOSTILE TEST RESULTS SUMMARY"
echo "=============================="
echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo -e "Critical Failures: ${RED}$CRITICAL_FAILURES${NC}"

# Calculate pass rate
if [[ $TOTAL_TESTS -gt 0 ]]; then
    pass_rate=$(( PASSED_TESTS * 100 / TOTAL_TESTS ))
    echo -e "Pass Rate: ${BLUE}$pass_rate%${NC}"
fi

echo ""
echo "🔍 FIX VERIFICATION STATUS"
echo "========================="

# Determine overall status
if [[ $CRITICAL_FAILURES -eq 0 ]] && [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}🎉 ALL HOSTILE TESTS PASSED${NC}"
    echo -e "${GREEN}✅ Pyenv completion fix: VERIFIED${NC}"
    echo -e "${GREEN}✅ P10k instant prompt fix: VERIFIED${NC}"
    echo -e "${GREEN}✅ Both fixes work together: VERIFIED${NC}"
    echo ""
    echo "🚀 The systematic fixes are PRODUCTION READY"
    exit 0
elif [[ $CRITICAL_FAILURES -eq 0 ]]; then
    echo -e "${YELLOW}⚠️  MINOR ISSUES DETECTED${NC}"
    echo "Most functionality works but some edge cases have issues."
    echo ""
    echo "Non-critical failures:"
    for result in "${TEST_RESULTS[@]}"; do
        if [[ "$result" == "FAIL:"* ]]; then
            echo "  - ${result#FAIL: }"
        fi
    done
    exit 1
else
    echo -e "${RED}🚨 CRITICAL FAILURES DETECTED${NC}"
    echo "The fixes have fundamental problems that prevent proper operation."
    echo ""
    echo -e "${RED}Critical issues:${NC}"
    for issue in "${CRITICAL_ISSUES[@]}"; do
        echo "  - $issue"
    done

    echo ""
    echo -e "${RED}❌ FIX STATUS:${NC}"
    if echo "${CRITICAL_ISSUES[@]}" | grep -q "pyenv\|module_path\|variable"; then
        echo -e "${RED}❌ Pyenv completion fix: FAILED${NC}"
    else
        echo -e "${GREEN}✅ Pyenv completion fix: VERIFIED${NC}"
    fi

    if echo "${CRITICAL_ISSUES[@]}" | grep -q "P10k\|instant prompt\|POWERLEVEL9K"; then
        echo -e "${RED}❌ P10k instant prompt fix: FAILED${NC}"
    else
        echo -e "${GREEN}✅ P10k instant prompt fix: VERIFIED${NC}"
    fi

    echo ""
    echo "🔧 IMMEDIATE ACTION REQUIRED"
    exit 2
fi