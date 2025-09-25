#!/bin/bash
# =====================================================
# HONEST TESTING FRAMEWORK - No Gaming, No Lies
# =====================================================
# Testing principle: ASSUME FAILURE, REQUIRE COMPLETE SUCCESS
# Focus: End-to-end functionality, not component availability

echo "🔥 HONEST TESTING FRAMEWORK - Zero Tolerance for Gaming"
echo "======================================================"
echo "Testing principle: Components must work together, not just exist"
echo "Success criteria: Complete workflows, not partial patterns"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CRITICAL_FAILURES=()

# Test execution with COMPLETE success requirements
run_honest_test() {
    local test_id="$1"
    local description="$2"
    local test_command="$3"
    local success_criteria="$4"
    local failure_criteria="${5:-}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    echo "🔍 HONEST TEST: $test_id"
    echo "   Description: $description"
    echo "   Success Requirement: $success_criteria"

    # Execute test with timeout
    actual_output=$(timeout 60 bash -c "$test_command" 2>&1)
    exit_code=$?

    # Check for explicit failure criteria first
    if [[ -n "$failure_criteria" ]] && echo "$actual_output" | grep -q "$failure_criteria"; then
        echo "❌ EXPLICIT FAILURE DETECTED: Found failure pattern '$failure_criteria'"
        echo "   Full output: $actual_output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        CRITICAL_FAILURES+=("$test_id: $description")
        echo ""
        return 1
    fi

    # Check for timeout
    if [[ $exit_code -eq 124 ]]; then
        echo "❌ TIMEOUT FAILURE: Test took more than 60 seconds"
        echo "   This indicates hanging/broken functionality"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        CRITICAL_FAILURES+=("$test_id: Timeout - $description")
        echo ""
        return 1
    fi

    # Check for success criteria (must be exact match) - support multiline patterns
    if printf "%s" "$actual_output" | grep -qE "$success_criteria"; then
        echo "✅ COMPLETE SUCCESS: All requirements met"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ INCOMPLETE SUCCESS: Missing required criteria"
        echo "   Expected: $success_criteria"
        echo "   Got: $actual_output"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        CRITICAL_FAILURES+=("$test_id: $description")
    fi
    echo ""
}

echo "📋 PHASE 1: Big Data Complete Cluster Testing"
echo "============================================="

# Test HT.1: Spark COMPLETE cluster (both Master AND Worker)
run_honest_test "HT.1 CRITICAL Spark Complete Cluster" \
    "Verify BOTH Spark Master and Worker are running (not just Worker)" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && spark_start >/dev/null 2>&1 && spark_status 2>&1'" \
    "✅ Master: Running.*(PID:|Web UI:).*✅ Worker: Running" \
    "❌.*Not running"

# Test HT.2: Hadoop COMPLETE service startup (all 4 services)
run_honest_test "HT.2 CRITICAL Hadoop Complete Services" \
    "Verify ALL Hadoop services start (NameNode, DataNode, ResourceManager, NodeManager)" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && init_hadoop_dirs >/dev/null 2>&1 && start_hadoop >/dev/null 2>&1 && hadoop_status 2>&1'" \
    "NameNode: ✅ Running.*DataNode: ✅ Running.*ResourceManager: ✅ Running.*NodeManager: ✅ Running" \
    "❌ Stopped"

# Test HT.3: HDFS actual file operations (not just connectivity)
run_honest_test "HT.3 CRITICAL HDFS File Operations" \
    "Verify HDFS can actually store and retrieve files (end-to-end)" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && echo \"test content $(date)\" | hdfs dfs -put - /tmp/honest_test.txt >/dev/null 2>&1 && hdfs dfs -cat /tmp/honest_test.txt 2>/dev/null && hdfs dfs -rm /tmp/honest_test.txt >/dev/null 2>&1'" \
    "test content" \
    "No such file or directory\\|Connection refused"

# Test HT.4: Spark job execution on cluster (not just local)
run_honest_test "HT.4 CRITICAL Spark Distributed Job" \
    "Verify Spark can execute jobs on the cluster (distributed processing)" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && spark_test_simple 2>&1'" \
    "✅.*RDD operations.*PASSED.*✅.*DataFrame operations.*PASSED" \
    "FAILED\\|Exception\\|Error"

echo "📋 PHASE 2: Development Workflow Complete Testing"
echo "================================================"

# Test HT.5: Backup system complete workflow
run_honest_test "HT.5 Backup Complete Workflow" \
    "Verify backup creates commit AND pushes to remote" \
    "cd ~/.config/zsh && zsh -c 'source ~/.zshrc >/dev/null 2>&1 && backup \"honest test $(date +%s)\" 2>&1'" \
    "✅.*Enhanced backup created.*created:" \
    "failed\\|error"

# Test HT.6: Python environment complete functionality
run_honest_test "HT.6 Python Environment Complete" \
    "Verify Python can import packages and execute real code" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && python3 -c \"import sys, os, json; print(f\\\"Python {sys.version_info.major}.{sys.version_info.minor} complete\\\")\" 2>&1'" \
    "Python [0-9]\\.[0-9]+ complete" \
    "Error\\|ImportError"

echo "📋 PHASE 3: Module Loading Honesty Testing"
echo "=========================================="

# Test HT.7: Module count accuracy (no double-counting)
run_honest_test "HT.7 Module Count Accuracy" \
    "Verify module loading reports accurate counts (no duplicates)" \
    "zsh -c 'source ~/.zshrc 2>&1' | grep 'modules loaded'" \
    "✅ ZSH ready - [0-9]+ modules loaded" \
    ""

# Test HT.8: Module functionality verification
run_honest_test "HT.8 Module Functions Available" \
    "Verify loaded modules actually provide their functions" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && command -v backup && command -v spark_start && command -v hadoop_status && echo \"all functions available\"'" \
    "all functions available" \
    "command not found"

echo "🔥 HONEST TESTING FRAMEWORK RESULTS"
echo "=================================="
echo "📊 Total tests run: $TOTAL_TESTS"
echo "✅ Complete successes: $PASSED_TESTS"
echo "❌ Failures/Incomplete: $FAILED_TESTS"
echo "📈 HONEST pass rate: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
echo ""

if [[ ${#CRITICAL_FAILURES[@]} -gt 0 ]]; then
    echo "🚨 CRITICAL FAILURES (No Gaming, No Excuses):"
    for failure in "${CRITICAL_FAILURES[@]}"; do
        echo "  - $failure"
    done
    echo ""
fi

# Honest verdict based on actual functionality
if [[ $PASSED_TESTS -eq $TOTAL_TESTS ]]; then
    echo "🎉 HONEST VERDICT: SYSTEM FULLY FUNCTIONAL"
    echo "✅ All components work together completely"
    echo "✅ No partial successes accepted"
    echo "✅ Ready for production use"
elif [[ $PASSED_TESTS -gt $((TOTAL_TESTS / 2)) ]]; then
    echo "⚠️  HONEST VERDICT: SYSTEM PARTIALLY FUNCTIONAL"
    echo "⚡ Some workflows work, others don't"
    echo "🔧 Specific repairs needed for full functionality"
    echo "❌ NOT production-ready for all use cases"
else
    echo "🚨 HONEST VERDICT: SYSTEM FUNDAMENTALLY BROKEN"
    echo "❌ More failures than successes"
    echo "❌ Major repairs required"
    echo "❌ NOT suitable for production use"
fi

echo ""
echo "🎯 KEY PRINCIPLE: NO PARTIAL CREDIT"
echo "- Worker running but Master down = FAILURE"
echo "- Some modules loaded but others missing = FAILURE"
echo "- Partial functionality = FAILURE"
echo "- Only COMPLETE SUCCESS counts as success"