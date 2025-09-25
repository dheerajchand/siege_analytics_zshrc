#!/bin/bash
# =====================================================
# BIG DATA REALITY TEST - Actual Functionality Testing
# =====================================================
# Tests if big data stack actually works, not just loads

echo "🔥 BIG DATA REALITY TEST - No More Lies"
echo "======================================="
echo "Testing principle: Prove functionality, not just availability"
echo ""

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test execution function
run_reality_test() {
    local test_name="$1"
    local test_command="$2"
    local success_pattern="$3"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo "🔍 REALITY TEST: $test_name"

    result=$(eval "$test_command" 2>&1)
    if echo "$result" | grep -q "$success_pattern"; then
        echo "✅ REAL FUNCTIONALITY: $test_name works"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo "❌ BROKEN FUNCTIONALITY: $test_name failed"
        echo "   Output: $result"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    echo ""
}

echo "📋 PHASE 1: Apache Spark Functionality"
echo "====================================="

# Load big data modules first
zsh -c 'source ~/.zshrc >/dev/null 2>&1 && load_module spark >/dev/null 2>&1'

echo "🚀 Attempting to start Spark services..."
spark_startup_result=$(zsh -c 'source ~/.zshrc >/dev/null 2>&1 && spark_start 2>&1')
if echo "$spark_startup_result" | grep -q "❌"; then
    echo "⚠️  Spark startup failed - testing with services down"
    echo "   Reason: $spark_startup_result"
else
    echo "✅ Spark startup successful"
fi
echo ""

# Test Spark Master
run_reality_test "Spark Master Running" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && spark_status 2>&1' | grep 'Master:'" \
    "✅ Master: Running"

# Test Spark Worker
run_reality_test "Spark Worker Running" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && spark_status 2>&1' | grep 'Worker:'" \
    "✅ Worker: Running"

# Test Spark Connectivity
run_reality_test "Spark Master Port Accessible" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && spark_status 2>&1' | grep 'Master port'" \
    "✅ Master port.*: Accessible"

# Test Spark Job Submission
run_reality_test "Spark Job Execution" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && spark_test_simple 2>&1'" \
    "✅.*test.*success"

echo "📋 PHASE 2: Apache Hadoop Functionality"
echo "====================================="

echo "🚀 Attempting to start Hadoop services..."
hadoop_startup_result=$(zsh -c 'source ~/.zshrc >/dev/null 2>&1 && init_hadoop_dirs >/dev/null 2>&1 && start_hadoop 2>&1')
if echo "$hadoop_startup_result" | grep -q "❌"; then
    echo "⚠️  Hadoop startup failed - testing with services down"
    echo "   Reason: $hadoop_startup_result"
else
    echo "✅ Hadoop startup successful"
fi
echo ""

# Test Hadoop NameNode
run_reality_test "Hadoop NameNode Running" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && hadoop_status 2>&1' | grep 'NameNode:'" \
    "✅ Running"

# Test Hadoop DataNode
run_reality_test "Hadoop DataNode Running" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && hadoop_status 2>&1' | grep 'DataNode:'" \
    "✅ Running"

# Test HDFS Connectivity
run_reality_test "HDFS Accessible" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && hadoop_status 2>&1' | grep 'HDFS.*:'" \
    "✅ Accessible"

# Test HDFS Operations
run_reality_test "HDFS File Operations" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && echo \"test content\" | hdfs dfs -put - /tmp/reality_test.txt 2>&1 && hdfs dfs -cat /tmp/reality_test.txt 2>&1 && hdfs dfs -rm /tmp/reality_test.txt 2>&1'" \
    "test content"

echo "📋 PHASE 3: Apache YARN Functionality"
echo "===================================="

# Test YARN ResourceManager
run_reality_test "YARN ResourceManager Running" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && hadoop_status 2>&1' | grep 'ResourceManager:'" \
    "✅ Running"

# Test YARN NodeManager
run_reality_test "YARN NodeManager Running" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && hadoop_status 2>&1' | grep 'NodeManager:'" \
    "✅ Running"

# Test YARN Application Listing
run_reality_test "YARN Application Management" \
    "zsh -c 'source ~/.zshrc >/dev/null 2>&1 && yarn_application_list 2>&1'" \
    "applications found\\|No applications"

echo "🔥 BIG DATA REALITY TEST RESULTS"
echo "================================"
echo "📊 Total functionality tests: $TOTAL_TESTS"
echo "✅ Actually working: $PASSED_TESTS"
echo "❌ Completely broken: $FAILED_TESTS"
echo "📈 Real functionality rate: $((PASSED_TESTS * 100 / TOTAL_TESTS))%"
echo ""

if [[ $PASSED_TESTS -eq 0 ]]; then
    echo "🚨 REALITY VERDICT: COMPLETE BIG DATA FAILURE"
    echo "❌ 0% big data functionality - nothing works"
    echo "❌ All Spark/Hadoop/YARN services down"
    echo "❌ Previous 'success' metrics were lies"
    echo "🔧 Entire big data stack needs repair/setup"
elif [[ $FAILED_TESTS -eq 0 ]]; then
    echo "🎉 REALITY VERDICT: BIG DATA FULLY FUNCTIONAL"
    echo "✅ All big data services operational"
    echo "✅ Spark/Hadoop/YARN cluster working"
    echo "✅ Real-world big data processing ready"
else
    echo "⚠️  REALITY VERDICT: PARTIAL BIG DATA FUNCTIONALITY"
    echo "⚡ Some services working, others broken"
    echo "🔧 Requires targeted repairs for full functionality"
fi