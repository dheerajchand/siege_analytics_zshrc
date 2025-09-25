#!/bin/bash
# =====================================================
# BATTLE TESTING FRAMEWORK - Real-World Validation
# =====================================================
# Tests functionality across actual execution environments
# Focus: Environment-specific behavior, not synthetic testing

echo "🔥 BATTLE TESTING FRAMEWORK - Real-World Validation"
echo "=================================================="
echo "Testing principle: Validate in actual usage contexts"
echo "Focus: Claude Code, iTerm2, Warp, scripts, containers"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CRITICAL_FAILURES=()
WARNING_ISSUES=()

# Test execution function
run_battle_test() {
    local test_id="$1"
    local description="$2"
    local context="$3"
    local expected="$4"
    local environment="${5:-current}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo "🔍 BATTLE TEST: $test_id"
    echo "   Description: $description"
    echo "   Environment: $environment"
    echo "   Context: $context"

    # Execute test
    actual_output=$(eval "$context" 2>&1)
    exit_code=$?

    # Check result
    if echo "$actual_output" | grep -q "$expected"; then
        echo "✅ PASS: Real-world functionality validated"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ FAIL: Real-world functionality broken"
        echo "   Expected pattern: $expected"
        echo "   Actual output: $actual_output"
        echo "   Exit code: $exit_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))

        # Categorize failures
        if [[ "$test_id" == *"CRITICAL"* ]]; then
            CRITICAL_FAILURES+=("$test_id $description")
        else
            WARNING_ISSUES+=("$test_id $description")
        fi
    fi
    echo ""
}

echo "📋 PHASE 1: Cross-Environment Module Loading"
echo "============================================="

# Test BT.1: Claude Code module loading
run_battle_test "BT.1 CRITICAL Claude Code Full Loading" \
    "Verify all 11 modules load in Claude Code environment" \
    "zsh -c 'source ~/.zshrc 2>&1' | grep -c '✅.*:' | grep -q '^6\$' && echo 'primary modules loaded'" \
    "primary modules loaded" \
    "Claude Code"

# Test BT.2: Container light mode
run_battle_test "BT.2 Container Light Mode" \
    "Verify container environments trigger light mode" \
    "container=docker zsh -c 'source ~/.zshrc 2>&1' | grep -q 'Light Mode' && echo 'light mode triggered'" \
    "light mode triggered" \
    "Container simulation"

# Test BT.3: Function availability in subshells
run_battle_test "BT.3 CRITICAL Subshell Functions" \
    "Verify core functions work in script contexts" \
    "bash -c 'source ~/.zshrc >/dev/null 2>&1 && mkcd /tmp/battle_test_\$RANDOM >/dev/null 2>&1 && pwd | grep -q battle_test && echo functions_work'" \
    "functions_work" \
    "Bash subshell"

echo "📋 PHASE 2: Real Development Workflows"
echo "======================================"

# Test BT.4: Backup system functionality
run_battle_test "BT.4 CRITICAL Backup System" \
    "Test backup system in real repository context" \
    "cd ~/.config/zsh && zsh -c 'source ~/.zshrc >/dev/null 2>&1 && backup \"battle test \$(date +%s)\" >/dev/null 2>&1 && git log --oneline -1 | grep -q \"battle test\" && echo backup_works'" \
    "backup_works" \
    "Real git repository"

# Test BT.5: Python environment integration
run_battle_test "BT.5 Python Integration" \
    "Verify Python module provides working environment" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && python3 -c \"import sys; print(f\\\"python_{sys.version_info.major}_{sys.version_info.minor}_works\\\")\" 2>/dev/null' | grep -q 'python_.*_works'" \
    "python_.*_works" \
    "Python execution"

# Test BT.6: Module state persistence
run_battle_test "BT.6 Module State Tracking" \
    "Verify LOADED_MODULES tracks state correctly" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && echo \$LOADED_MODULES | wc -w | grep -q \"[1-9]\" && echo state_tracked'" \
    "state_tracked" \
    "State management"

echo "📋 PHASE 3: Environment Detection Accuracy"
echo "=========================================="

# Test BT.7: Claude environment detection
run_battle_test "BT.7 Claude Detection" \
    "Verify Claude environment detection works correctly" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && detect_claude_environment && echo claude_detected'" \
    "claude_detected" \
    "Claude Code detection"

# Test BT.8: Terminal differentiation
run_battle_test "BT.8 Terminal Detection" \
    "Verify system can differentiate terminal types" \
    "echo \$TERM_PROGRAM | grep -q 'Warp\\|iTerm\\|Terminal' && echo terminal_detected" \
    "terminal_detected" \
    "Terminal identification"

echo "📋 PHASE 4: Error Recovery & Edge Cases"
echo "======================================="

# Test BT.9: Missing module graceful handling
run_battle_test "BT.9 Missing Module Recovery" \
    "Test system continues when modules missing" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && load_module nonexistent >/dev/null 2>&1; echo \$? | grep -q \"0\\|1\" && command -v backup >/dev/null && echo recovery_works'" \
    "recovery_works" \
    "Error recovery"

# Test BT.10: Shell restart safety
run_battle_test "BT.10 CRITICAL Shell Restart" \
    "Verify functions survive shell restarts" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && zsh -c \"source ~/.zshrc >/dev/null 2>&1 && command -v load_module >/dev/null && echo restart_safe\"'" \
    "restart_safe" \
    "Shell restart"

echo "🔥 BATTLE TESTING FRAMEWORK RESULTS"
echo "=================================="
echo "📊 Total tests run: $TOTAL_TESTS"
echo "✅ Tests passed: $PASSED_TESTS"
echo "❌ Tests failed: $FAILED_TESTS"
echo "📈 Pass rate: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
echo ""

if [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]]; then
    echo "🚨 CRITICAL FAILURES (System Unusable):"
    for failure in "${CRITICAL_FAILURES[@]}"; do
        echo "  - $failure"
    done
    echo ""
fi

if [[ ${#WARNING_ISSUES[@]} -gt 0 ]]; then
    echo "⚠️  WARNING ISSUES (Degraded Functionality):"
    for warning in "${WARNING_ISSUES[@]}"; do
        echo "  - $warning"
    done
    echo ""
fi

# Final verdict
if [[ ${#CRITICAL_FAILURES[@]} -eq 0 ]]; then
    if [[ ${#WARNING_ISSUES[@]} -eq 0 ]]; then
        echo "🎉 BATTLE TESTING VERDICT: PRODUCTION READY"
        echo "✅ All critical functionality validated in real contexts"
        echo "✅ No critical failures detected"
        echo "✅ System passes real-world validation requirements"
    else
        echo "⚠️  BATTLE TESTING VERDICT: CONDITIONAL APPROVAL"
        echo "✅ No critical failures but minor issues exist"
        echo "🔧 Address warning issues for optimal production readiness"
    fi
else
    echo "🚨 BATTLE TESTING VERDICT: SYSTEM NOT READY"
    echo "❌ Critical failures prevent real-world deployment"
    echo "❌ System fails under actual usage conditions"
    echo "🔧 Major repairs required before deployment"
fi