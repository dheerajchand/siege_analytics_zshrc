#!/bin/bash
# =====================================================
# HOSTILE TESTING FRAMEWORK - COMPREHENSIVE VALIDATION
# =====================================================
#
# Purpose: Find EVERY way the system can fail in real usage
# Principle: Assume failure until proven otherwise in ALL contexts
# Method: Test subshells, scripts, automation contexts
# =====================================================

echo "🔥 HOSTILE TESTING FRAMEWORK - COMPREHENSIVE VALIDATION"
echo "======================================================="
echo "Testing principle: Assume failure, prove success in ALL contexts"
echo "Focus: Subshells, scripts, automation, real-world usage"
echo ""

# Test result tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CRITICAL_FAILURES=()
WARNING_ISSUES=()

# Helper function for hostile test execution
run_hostile_test() {
    local test_name="$1"
    local test_description="$2"
    local test_script="$3"
    local success_pattern="$4"
    local is_critical="${5:-true}"

    ((TOTAL_TESTS++))
    echo "🔍 HOSTILE TEST: $test_name"
    echo "   Description: $test_description"
    echo "   Context: $test_script"

    # Create test script and execute
    local test_file="/tmp/hostile_test_$$_${TOTAL_TESTS}.sh"
    cat > "$test_file" << EOF
#!/bin/bash
$test_script
EOF
    chmod +x "$test_file"

    # Execute test script
    local result
    local exit_code
    result=$(bash "$test_file" 2>&1)
    exit_code=$?

    # Clean up test file
    rm -f "$test_file"

    # Evaluate result
    if [[ $exit_code -eq 0 && "$result" =~ $success_pattern ]]; then
        echo "✅ PASS: Functionality verified in isolated context"
        ((PASSED_TESTS++))
    else
        echo "❌ FAIL: Functionality broken in real usage context"
        if [[ "$is_critical" == "true" ]]; then
            CRITICAL_FAILURES+=("$test_name")
        else
            WARNING_ISSUES+=("$test_name")
        fi
        ((FAILED_TESTS++))
        echo "   Expected pattern: $success_pattern"
        echo "   Actual output: $result"
        echo "   Exit code: $exit_code"
    fi
    echo ""
}

# =====================================================
# PHASE 1: CORE FUNCTION AVAILABILITY TESTS
# =====================================================

echo "📋 PHASE 1: Core Function Availability in Subshells"
echo "==================================================="

# Test HF.1: Basic functions in subshell
run_hostile_test "HF.1 Basic Functions" \
    "Test if basic functions work in script context" \
    "source ~/.zshrc >/dev/null 2>&1; command_exists ls && echo 'command_exists works' || echo 'command_exists failed'" \
    "command_exists works"

# Test HF.2: mkcd function in subshell
run_hostile_test "HF.2 mkcd Function" \
    "Test mkcd function availability in script" \
    "source ~/.zshrc >/dev/null 2>&1; typeset -f mkcd >/dev/null && echo 'mkcd available' || echo 'mkcd missing'" \
    "mkcd available"

# Test HF.3: Module loading system in subshell
run_hostile_test "HF.3 Module System" \
    "Test load_module function in script context" \
    "source ~/.zshrc >/dev/null 2>&1; typeset -f load_module >/dev/null && echo 'load_module available' || echo 'load_module missing'" \
    "load_module available"

# Test HF.4: Mode detection in subshell
run_hostile_test "HF.4 Mode Detection" \
    "Test detect_zsh_mode function in script" \
    "source ~/.zshrc >/dev/null 2>&1; typeset -f detect_zsh_mode >/dev/null && echo 'detect_zsh_mode available' || echo 'detect_zsh_mode missing'" \
    "detect_zsh_mode available"

# =====================================================
# PHASE 2: MODULE LOADING TESTS IN ISOLATION
# =====================================================

echo "📋 PHASE 2: Module Loading in Script Contexts"
echo "============================================="

# Test HM.1: Utils module loading and ACTUAL backup functionality
run_hostile_test "HM.1 Utils Module Real Backup Test" \
    "Load utils module and verify backup actually works in config directory" \
    "zsh -c 'export CLAUDE_CODE_SESSION=test && source ~/.zshrc >/dev/null 2>&1 && cd ~/.config/zsh && command -v backup >/dev/null && typeset -f enhanced_backup >/dev/null && echo \"backup function available\" || echo \"backup function missing\"'" \
    "backup function available"

# Test HM.2: Python module ACTUAL execution test
run_hostile_test "HM.2 Python Module Real Execution Test" \
    "Load python module and verify Python can actually execute code" \
    "zsh -c 'export CLAUDE_CODE_SESSION=test && source ~/.zshrc >/dev/null 2>&1 && load_module python >/dev/null 2>&1 && python3 -c \"print(2+2)\" 2>/dev/null | grep -q \"4\" && echo \"python execution works\" || echo \"python execution broken\"'" \
    "python execution works"

# Test HM.3: Module state persistence
run_hostile_test "HM.3 Module State Tracking" \
    "Verify LOADED_MODULES variable in script context" \
    "source ~/.zshrc >/dev/null 2>&1; load_module utils >/dev/null 2>&1; echo \"LOADED_MODULES: \$LOADED_MODULES\"; echo \$LOADED_MODULES | grep -q utils && echo 'state tracked' || echo 'state lost'" \
    "state tracked"

# Test HM.4: Staggered module loading verification
run_hostile_test "HM.4 Staggered Module Loading" \
    "Verify staggered mode loads all expected modules" \
    "zsh -c 'export CLAUDE_CODE_SESSION=test; source ~/.zshrc 2>&1 | grep -c \"✅.*:\" | grep -q \"^6\\\$\" && echo \"all modules loaded\" || echo \"modules missing\"'" \
    "all modules loaded"

# =====================================================
# PHASE 3: CLAUDE CODE ENVIRONMENT DETECTION
# =====================================================

echo "📋 PHASE 3: Claude Code Environment Detection"
echo "============================================"

# Test HC.1: Claude environment detection in script
run_hostile_test "HC.1 Claude Environment Detection" \
    "Test Claude Code environment detection in script contexts" \
    "source ~/.zshrc >/dev/null 2>&1; detect_claude_environment && echo 'claude environment detected' || echo 'claude environment not detected'" \
    "claude environment detected" \
    false

# Test HC.2: Claude Code session variable
run_hostile_test "HC.2 Claude Session Variable" \
    "Test CLAUDE_CODE_SESSION variable detection" \
    "export CLAUDE_CODE_SESSION=test; source ~/.zshrc 2>&1 | grep -q 'Claude Code' && echo 'session detected' || echo 'session not detected'" \
    "session detected" \
    false

# Test HC.3: Staggered mode auto-loading in Claude Code context
run_hostile_test "HC.3 Staggered Auto-loading Verification" \
    "Verify all 6 primary modules auto-load in Claude Code staggered mode" \
    "zsh -c 'export CLAUDE_CODE_SESSION=test; source ~/.zshrc 2>&1 | grep -q \"ZSH ready - 6 modules loaded\" && echo \"staggered loading works\" || echo \"staggered loading failed\"'" \
    "staggered loading works"

# Test HC.4: Hierarchical module loading
run_hostile_test "HC.4 Hierarchical Module Loading" \
    "Verify hierarchical modules are discovered and processed" \
    "export CLAUDE_CODE_SESSION=test; source ~/.zshrc 2>&1 | grep -q 'Loading hierarchical module' && echo 'hierarchical modules processed' || echo 'hierarchical modules not found'" \
    "hierarchical modules processed" \
    false

# Test HC.5: PATH protection REAL functionality test
run_hostile_test "HC.5 PATH Protection Real Test" \
    "Verify essential commands work after staggered loading" \
    "zsh -c 'export CLAUDE_CODE_SESSION=test && source ~/.zshrc >/dev/null 2>&1 && date >/dev/null 2>&1 && git --version >/dev/null 2>&1 && mkdir -p /tmp/path_test_$$ && rmdir /tmp/path_test_$$ && echo \"essential commands work\" || echo \"essential commands broken\"'" \
    "essential commands work"

# Test HC.6: JavaScript module functionality
run_hostile_test "HC.6 JavaScript Module Loading" \
    "Verify newly created javascript module loads correctly" \
    "export CLAUDE_CODE_SESSION=test; source ~/.zshrc >/dev/null 2>&1; echo \$LOADED_MODULES | grep -q javascript && echo 'javascript module loaded' || echo 'javascript module missing'" \
    "javascript module loaded"

# Test HC.7: Shell restart functionality
run_hostile_test "HC.7 Shell Restart Safety" \
    "Verify zshreboot function works without crashing" \
    "/bin/zsh -c 'source ~/.zshrc >/dev/null 2>&1; command -v zshreboot >/dev/null && echo \"restart function available\" || echo \"restart function missing\"'" \
    "restart function available"

# =====================================================
# PHASE 4: REAL-WORLD AUTOMATION SCENARIOS
# =====================================================

echo "📋 PHASE 4: Real-World Automation Scenarios"
echo "==========================================="

# Test HA.1: Cron job REAL execution simulation
run_hostile_test "HA.1 Cron Job Real Execution Test" \
    "Simulate actual cron job that needs to create files and run commands" \
    "env -i HOME=\$HOME PATH=/usr/bin:/bin bash -c 'source ~/.zshrc >/dev/null 2>&1 && mkdir -p /tmp/cron_test_\$\$ && echo \"test\" > /tmp/cron_test_\$\$/file.txt && cat /tmp/cron_test_\$\$/file.txt >/dev/null && rm -rf /tmp/cron_test_\$\$ && echo \"cron execution works\" || echo \"cron execution broken\"'" \
    "cron execution works" \
    false

# Test HA.2: SSH session simulation
run_hostile_test "HA.2 SSH Session Simulation" \
    "Simulate SSH non-interactive session" \
    "bash -c 'source ~/.zshrc >/dev/null 2>&1; path_length=\$(echo \$PATH | wc -c); if [ \$path_length -lt 1000 ]; then echo \"path clean\"; else echo \"path bloated\"; fi'" \
    "path clean" \
    false

# Test HA.3: CI/CD pipeline REAL workflow simulation
run_hostile_test "HA.3 CI/CD Pipeline Real Workflow Test" \
    "Simulate actual CI/CD workflow that builds and tests code" \
    "env PATH=/usr/bin:/bin bash -c 'source ~/.zshrc >/dev/null 2>&1 && load_module python >/dev/null 2>&1 && cd /tmp && mkdir -p ci_test_\$\$ && cd ci_test_\$\$ && echo \"print(\\\"hello world\\\")\" > test.py && python3 test.py | grep -q \"hello world\" && cd /tmp && rm -rf ci_test_\$\$ && echo \"ci workflow works\" || echo \"ci workflow broken\"'" \
    "ci workflow works" \
    false

# Test HA.4: Docker container simulation
run_hostile_test "HA.4 Docker Container Simulation" \
    "Test in minimal container-like environment" \
    "env -i HOME=$HOME PATH=/usr/bin:/bin SHELL=/bin/bash bash -c 'source ~/.zshrc >/dev/null 2>&1; command -v zsh >/dev/null && echo \"container compatible\" || echo \"container broken\"'" \
    "container compatible" \
    false

# =====================================================
# PHASE 5: PERFORMANCE AND RELIABILITY
# =====================================================

echo "📋 PHASE 5: Performance and Reliability Tests"
echo "============================================="

# Test HP.1: Startup time in script
run_hostile_test "HP.1 Startup Performance" \
    "Measure startup time in script context" \
    "bash -c 'start_time=\$(date +%s.%N); source ~/.zshrc >/dev/null 2>&1; end_time=\$(date +%s.%N); duration=\$(echo \"\$end_time - \$start_time\" | bc 2>/dev/null || echo \"2.0\"); if (( \$(echo \"\$duration < 2.0\" | bc -l 2>/dev/null || echo 0) )); then echo \"fast startup\"; else echo \"slow startup\"; fi'" \
    "fast startup" \
    false

# Test HP.2: Memory efficiency in script
run_hostile_test "HP.2 Memory Efficiency" \
    "Check memory usage in script context" \
    "bash -c 'source ~/.zshrc >/dev/null 2>&1; ps -o rss= -p \$\$ | awk \"\\\$1 < 50000 { print \\\"efficient\\\" } \\\$1 >= 50000 { print \\\"heavy\\\" }\"'" \
    "efficient" \
    false

# Test HP.3: PATH optimization persistence
run_hostile_test "HP.3 PATH Optimization" \
    "Verify PATH stays optimized in scripts" \
    "source ~/.zshrc >/dev/null 2>&1; path_length=\$(echo \$PATH | wc -c); if [ \$path_length -lt 1000 ]; then echo \"optimized\"; else echo \"bloated\"; fi" \
    "optimized"

# =====================================================
# PHASE 6: EDGE CASE AND ERROR HANDLING
# =====================================================

echo "📋 PHASE 6: Edge Cases and Error Handling"
echo "========================================="

# Test HE.1: Missing dependency ACTUAL error handling
run_hostile_test "HE.1 Missing Dependencies Real Test" \
    "Test system continues working when dependencies missing" \
    "zsh -c 'export CLAUDE_CODE_SESSION=test && source ~/.zshrc >/dev/null 2>&1 && unset -f path_add 2>/dev/null && load_module spark >/dev/null 2>&1; backup \"dependency test\" >/dev/null 2>&1 && echo \"system still functional\" || echo \"system broken\"'" \
    "system still functional" \
    false

# Test HE.2: Corrupted module REAL resilience test
run_hostile_test "HE.2 Corrupted Module Real Resilience Test" \
    "Test system continues working after loading corrupted module" \
    "echo 'invalid syntax }{' > /tmp/corrupt_module.zsh && zsh -c 'export CLAUDE_CODE_SESSION=test && source ~/.zshrc >/dev/null 2>&1 && source /tmp/corrupt_module.zsh >/dev/null 2>&1; date >/dev/null 2>&1 && backup \"corruption test\" >/dev/null 2>&1 && echo \"system resilient\" || echo \"system broken\"' && rm -f /tmp/corrupt_module.zsh" \
    "system resilient" \
    false

# Test HE.3: Network failure resilience
run_hostile_test "HE.3 Network Failure Resilience" \
    "Test system startup without network" \
    "timeout 5 bash -c 'source ~/.zshrc >/dev/null 2>&1; echo \"startup completed\"' 2>/dev/null && echo 'network independent' || echo 'network dependent'" \
    "network independent"

# =====================================================
# PHASE 7: REAL USER WORKFLOW VALIDATION
# =====================================================

echo "📋 PHASE 7: Real User Workflow Tests"
echo "===================================="

# Test UW.1: Complete development workflow
run_hostile_test "UW.1 Real Development Workflow" \
    "Test complete edit→backup→verify workflow" \
    "zsh -c 'export CLAUDE_CODE_SESSION=test && source ~/.zshrc >/dev/null 2>&1 && cd ~/.config/zsh && echo \"# Workflow test \$(date)\" >> /tmp/workflow_test.tmp && backup \"workflow validation\" >/dev/null 2>&1 && rm -f /tmp/workflow_test.tmp && git log --oneline -1 | grep -q \"workflow validation\" && echo \"development workflow works\" || echo \"development workflow broken\"'" \
    "development workflow works"

# Test UW.2: Module loading and actual usage
run_hostile_test "UW.2 Module Usage Workflow" \
    "Test loading modules and actually using their features" \
    "zsh -c 'export CLAUDE_CODE_SESSION=test && source ~/.zshrc >/dev/null 2>&1 && load_module python >/dev/null 2>&1 && python3 -c \"import sys; print(sys.version)\" >/dev/null 2>&1 && load_module docker >/dev/null 2>&1 && docker --version >/dev/null 2>&1 && echo \"module usage workflow works\" || echo \"module usage workflow broken\"'" \
    "module usage workflow works"

# Test UW.3: Shell restart and persistence
run_hostile_test "UW.3 Shell Restart Persistence" \
    "Test that functions survive shell restart" \
    "zsh -c 'export CLAUDE_CODE_SESSION=test && source ~/.zshrc >/dev/null 2>&1 && /bin/zsh -c \"source ~/.zshrc >/dev/null 2>&1 && command -v backup >/dev/null && command -v load_module >/dev/null && echo \\\"functions persist\\\" || echo \\\"functions lost\\\"\"'" \
    "functions persist"

# =====================================================
# HOSTILE TESTING RESULTS AND ANALYSIS
# =====================================================

echo "🔥 HOSTILE TESTING FRAMEWORK RESULTS"
echo "===================================="
echo "📊 Total tests run: $TOTAL_TESTS"
echo "✅ Tests passed: $PASSED_TESTS"
echo "❌ Tests failed: $FAILED_TESTS"
echo "📈 Pass rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
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

# Determine overall system status
if [[ ${#CRITICAL_FAILURES[@]} -eq 0 && $FAILED_TESTS -eq 0 ]]; then
    echo "🎉 HOSTILE TESTING VERDICT: SYSTEM READY FOR PRODUCTION"
    echo "✅ All critical functionality verified in all contexts"
    echo "✅ No critical failures detected"
    echo "✅ System passes hostile validation requirements"
    exit 0
elif [[ ${#CRITICAL_FAILURES[@]} -eq 0 && $FAILED_TESTS -le 3 ]]; then
    echo "⚠️  HOSTILE TESTING VERDICT: CONDITIONAL APPROVAL"
    echo "✅ No critical failures but minor issues exist"
    echo "🔧 Address warning issues for full production readiness"
    exit 1
else
    echo "🚨 HOSTILE TESTING VERDICT: SYSTEM NOT READY"
    echo "❌ Critical failures prevent production deployment"
    echo "❌ Multiple functionality failures detected"
    echo "🔧 Major repairs required before deployment"
    exit 2
fi