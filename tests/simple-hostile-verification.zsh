#!/usr/bin/env zsh
# =====================================================
# SIMPLE HOSTILE VERIFICATION FOR SYSTEMATIC FIXES
# =====================================================
# Purpose: Verify pyenv completion and P10k integration work correctly
# 1. Pyenv completion functionality
# 2. P10k instant prompt configuration
# =====================================================

echo "🔥 HOSTILE VERIFICATION - SYSTEMATIC FIXES"
echo "=========================================="
echo ""

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Helper function
run_test() {
    local test_name="$1"
    local test_script="$2"
    local expected_result="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo "🧪 TEST: $test_name"

    # Create isolated test script
    local test_file="/tmp/test_$$_$TESTS_TOTAL.zsh"
    cat > "$test_file" << EOF
#!/usr/bin/env zsh
$test_script
EOF
    chmod +x "$test_file"

    # Run test and capture result
    local result
    result=$("$test_file" 2>&1)
    local exit_code=$?

    # Clean up
    rm -f "$test_file"

    # Check result
    if [[ "$result" == *"$expected_result"* ]]; then
        echo "✅ PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "❌ FAIL"
        echo "   Expected: $expected_result"
        echo "   Got: $result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

echo "📋 PHASE 1: PYENV COMPLETION FIX"
echo "==============================="

# Test 1: Variable name verification
run_test "Variable name fix in source code" \
'
if grep -q "local module_file=" /Users/dheerajchand/.config/zsh/zshrc; then
    echo "VARIABLE_FIX_VERIFIED"
else
    echo "VARIABLE_FIX_MISSING"
fi
' \
"VARIABLE_FIX_VERIFIED"

# Test 2: Variable collision simulation
run_test "Variable collision resistance" \
'
# Set up global module_path array
typeset -a module_path
module_path=(/usr/lib/zsh /usr/local/share/zsh)

# Clear P10k variables for clean test
unset POWERLEVEL9K_INSTANT_PROMPT ENABLE_P10K_INSTANT_PROMPT

# Source zshrc and test module loading
source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1
load_module utils >/dev/null 2>&1

if typeset -f backup >/dev/null 2>&1; then
    if [[ "${module_path[1]}" == "/usr/lib/zsh" ]]; then
        echo "COLLISION_RESISTANCE_VERIFIED"
    else
        echo "GLOBAL_ARRAY_CORRUPTED"
    fi
else
    echo "MODULE_LOADING_FAILED"
fi
' \
"COLLISION_RESISTANCE_VERIFIED"

# Test 3: IDE environment test
run_test "IDE environment compatibility" \
'
export TERM_PROGRAM="PyCharm"
export PYCHARM_HOSTED=1
typeset -a module_path
module_path=(/usr/lib/zsh)

unset POWERLEVEL9K_INSTANT_PROMPT ENABLE_P10K_INSTANT_PROMPT
source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1
load_module python >/dev/null 2>&1

if command -v python3 >/dev/null 2>&1; then
    echo "IDE_COMPATIBILITY_VERIFIED"
else
    echo "IDE_COMPATIBILITY_FAILED"
fi
' \
"IDE_COMPATIBILITY_VERIFIED"

echo "📋 PHASE 2: P10K INSTANT PROMPT FIX"
echo "==================================="

# Test 4: Default P10k setting
run_test "P10k instant prompt default setting" \
'
unset POWERLEVEL9K_INSTANT_PROMPT ENABLE_P10K_INSTANT_PROMPT
source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1

if [[ "$POWERLEVEL9K_INSTANT_PROMPT" == "off" ]]; then
    echo "P10K_DEFAULT_VERIFIED"
else
    echo "P10K_DEFAULT_INCORRECT:$POWERLEVEL9K_INSTANT_PROMPT"
fi
' \
"P10K_DEFAULT_VERIFIED"

# Test 5: P10k toggle enable
run_test "P10k toggle enable functionality" \
'
unset POWERLEVEL9K_INSTANT_PROMPT ENABLE_P10K_INSTANT_PROMPT
export ENABLE_P10K_INSTANT_PROMPT="true"
source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1

if [[ "$POWERLEVEL9K_INSTANT_PROMPT" == "verbose" ]]; then
    echo "P10K_TOGGLE_ENABLE_VERIFIED"
else
    echo "P10K_TOGGLE_ENABLE_FAILED:$POWERLEVEL9K_INSTANT_PROMPT"
fi
' \
"P10K_TOGGLE_ENABLE_VERIFIED"

# Test 6: P10k toggle disable
run_test "P10k toggle disable functionality" \
'
unset POWERLEVEL9K_INSTANT_PROMPT ENABLE_P10K_INSTANT_PROMPT
export ENABLE_P10K_INSTANT_PROMPT="false"
source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1

if [[ "$POWERLEVEL9K_INSTANT_PROMPT" == "off" ]]; then
    echo "P10K_TOGGLE_DISABLE_VERIFIED"
else
    echo "P10K_TOGGLE_DISABLE_FAILED:$POWERLEVEL9K_INSTANT_PROMPT"
fi
' \
"P10K_TOGGLE_DISABLE_VERIFIED"

echo "📋 PHASE 3: INTEGRATION TEST"
echo "============================"

# Test 7: Both fixes working together
run_test "Integration test (both fixes)" \
'
# Hostile environment: IDE + variable collision + P10k disabled by default
export TERM_PROGRAM="PyCharm"
typeset -a module_path
module_path=(/usr/lib/zsh)

unset POWERLEVEL9K_INSTANT_PROMPT ENABLE_P10K_INSTANT_PROMPT
# Test with default behavior (P10k should be off)

source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1
load_module utils >/dev/null 2>&1

# Check all conditions
p10k_ok=false
module_ok=false
array_ok=false

# P10k should default to off
if [[ "$POWERLEVEL9K_INSTANT_PROMPT" == "off" ]]; then
    p10k_ok=true
fi

if typeset -f backup >/dev/null 2>&1; then
    module_ok=true
fi

if [[ "${module_path[1]}" == "/usr/lib/zsh" ]]; then
    array_ok=true
fi

if $p10k_ok && $module_ok && $array_ok; then
    echo "INTEGRATION_VERIFIED"
else
    echo "INTEGRATION_FAILED:p10k=$p10k_ok,module=$module_ok,array=$array_ok,P10K=$POWERLEVEL9K_INSTANT_PROMPT"
fi
' \
"INTEGRATION_VERIFIED"

# Test 8: Error recovery
run_test "Error recovery test" \
'
unset POWERLEVEL9K_INSTANT_PROMPT ENABLE_P10K_INSTANT_PROMPT
source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1

# Try to load non-existent module
load_module "nonexistent_module" >/dev/null 2>&1

# System should still work
load_module utils >/dev/null 2>&1
if typeset -f backup >/dev/null 2>&1; then
    echo "ERROR_RECOVERY_VERIFIED"
else
    echo "ERROR_RECOVERY_FAILED"
fi
' \
"ERROR_RECOVERY_VERIFIED"

echo "📊 FINAL RESULTS"
echo "================"
echo "Total tests: $TESTS_TOTAL"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo "🎉 ALL HOSTILE TESTS PASSED!"
    echo "✅ Pyenv completion fix: VERIFIED"
    echo "✅ P10k instant prompt fix: VERIFIED"
    echo "✅ Integration: VERIFIED"
    echo ""
    echo "🚀 SYSTEMATIC FIXES ARE PRODUCTION READY"
    exit 0
else
    echo ""
    echo "🚨 SOME TESTS FAILED"
    echo "🔧 Fixes need attention before production deployment"
    exit 1
fi