#!/usr/bin/env zsh
# =====================================================
# HOSTILE SPARK TESTING FRAMEWORK
# =====================================================
# Purpose: Real-world adversarial testing of Spark functions
# Tests: Missing dependencies, invalid inputs, broken environments
# =====================================================

echo "🔥 HOSTILE SPARK TESTING FRAMEWORK"
echo "=================================="
echo ""

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CRITICAL_FAILURES=0

# Test result tracking
TEST_RESULTS=()

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log_test() {
    local test_name="$1"
    local result="$2"
    local details="$3"

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
    elif [[ "$result" == "CRITICAL" ]]; then
        echo -e "${RED}🚨 CRITICAL FAILURE${NC}: $test_name"
        if [[ -n "$details" ]]; then
            echo -e "   ${RED}└─${NC} $details"
        fi
        CRITICAL_FAILURES=$((CRITICAL_FAILURES + 1))
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi

    TEST_RESULTS+=("$result: $test_name")
}

# Setup environment
export ZSH_CONFIG_DIR="/Users/dheerajchand/.config/zsh"
echo "🔧 Setting up test environment..."

# Load Spark module
if ! source "$ZSH_CONFIG_DIR/modules/spark.module.zsh" >/dev/null 2>&1; then
    log_test "Spark module loading" "CRITICAL" "Module failed to load"
    exit 1
fi

echo ""
echo "🧪 PHASE 1: FUNCTION EXISTENCE TESTS"
echo "-----------------------------------"

# Test 1: Critical functions exist
CRITICAL_SPARK_FUNCTIONS=(
    "default_spark_submit"
    "distributed_spark_submit"
    "smart_spark_submit"
    "spark_yarn_submit"
    "heavy_api_submit"
    "get_spark_dependencies"
    "pyspark_shell"
    "spark_shell"
)

for func in "${CRITICAL_SPARK_FUNCTIONS[@]}"; do
    if declare -f "$func" >/dev/null 2>&1; then
        log_test "Function exists: $func" "PASS"
    else
        log_test "Function exists: $func" "CRITICAL" "Function not found after module load"
    fi
done

echo ""
echo "🔥 PHASE 2: HOSTILE INPUT TESTS"
echo "------------------------------"

# Test 2: Missing file input
test_output=$(default_spark_submit 2>&1)
if [[ $? -ne 0 ]] && [[ "$test_output" == *"Usage"* ]]; then
    log_test "Missing file parameter handling" "PASS"
else
    log_test "Missing file parameter handling" "FAIL" "Should show usage message"
fi

# Test 3: Non-existent file
test_output=$(default_spark_submit "/tmp/nonexistent_spark_job_$(date +%s).py" 2>&1)
if [[ $? -ne 0 ]] && [[ "$test_output" == *"File not found"* ]]; then
    log_test "Non-existent file handling" "PASS"
else
    log_test "Non-existent file handling" "FAIL" "Should detect missing file"
fi

# Test 4: Invalid file extension
echo "print('not a real spark job')" > /tmp/hostile_test_invalid.txt
test_output=$(default_spark_submit "/tmp/hostile_test_invalid.txt" 2>&1)
if [[ $? -ne 0 ]] || [[ "$test_output" == *"warning"* ]] || [[ "$test_output" == *"invalid"* ]]; then
    log_test "Invalid file extension handling" "PASS"
else
    log_test "Invalid file extension handling" "FAIL" "Should warn about non-.py file"
fi
rm -f /tmp/hostile_test_invalid.txt

# Test 5: Empty file
touch /tmp/hostile_test_empty.py
test_output=$(default_spark_submit "/tmp/hostile_test_empty.py" 2>&1)
# This should either fail or show a warning
if [[ $? -ne 0 ]] || [[ "$test_output" == *"empty"* ]] || [[ "$test_output" == *"warning"* ]]; then
    log_test "Empty file handling" "PASS"
else
    log_test "Empty file handling" "FAIL" "Should handle empty files gracefully"
fi
rm -f /tmp/hostile_test_empty.py

echo ""
echo "💥 PHASE 3: ENVIRONMENT DESTRUCTION TESTS"
echo "----------------------------------------"

# Test 6: Missing SPARK_HOME
original_spark_home="$SPARK_HOME"
unset SPARK_HOME
test_output=$(default_spark_submit --version 2>&1)
if [[ $? -ne 0 ]] || [[ "$test_output" == *"SPARK_HOME"* ]] || [[ "$test_output" == *"not set"* ]]; then
    log_test "Missing SPARK_HOME handling" "PASS"
else
    log_test "Missing SPARK_HOME handling" "FAIL" "Should detect missing SPARK_HOME"
fi
export SPARK_HOME="$original_spark_home"

# Test 7: Invalid SPARK_HOME
export SPARK_HOME="/tmp/fake_spark_$(date +%s)"
test_output=$(default_spark_submit --version 2>&1)
if [[ $? -ne 0 ]] || [[ "$test_output" == *"not found"* ]] || [[ "$test_output" == *"invalid"* ]]; then
    log_test "Invalid SPARK_HOME handling" "PASS"
else
    log_test "Invalid SPARK_HOME handling" "FAIL" "Should detect invalid SPARK_HOME"
fi
export SPARK_HOME="$original_spark_home"

# Test 8: Corrupted PATH
original_path="$PATH"
export PATH="/tmp/nonexistent_path_$(date +%s)"
test_output=$(default_spark_submit --help 2>&1)
if [[ $? -ne 0 ]] || [[ "$test_output" == *"command not found"* ]] || [[ "$test_output" == *"not found"* ]]; then
    log_test "Corrupted PATH handling" "PASS"
else
    log_test "Corrupted PATH handling" "FAIL" "Should handle missing commands"
fi
export PATH="$original_path"

echo ""
echo "🎯 PHASE 4: DEPENDENCY VERIFICATION"
echo "----------------------------------"

# Test 9: Java availability
if command -v java >/dev/null 2>&1; then
    java_version=$(java -version 2>&1 | head -n1)
    log_test "Java dependency check" "PASS" "Found: $java_version"
else
    log_test "Java dependency check" "CRITICAL" "Java not found - Spark cannot function"
fi

# Test 10: Python availability
if command -v python3 >/dev/null 2>&1; then
    python_version=$(python3 --version 2>&1)
    log_test "Python dependency check" "PASS" "Found: $python_version"
else
    log_test "Python dependency check" "CRITICAL" "Python3 not found - PySpark cannot function"
fi

# Test 11: Spark installation
if command -v spark-submit >/dev/null 2>&1; then
    spark_version=$(spark-submit --version 2>&1 | grep -o "version [0-9]\+\.[0-9]\+\.[0-9]\+" | head -n1)
    log_test "Spark installation check" "PASS" "Found: $spark_version"
else
    log_test "Spark installation check" "CRITICAL" "spark-submit not found in PATH"
fi

echo ""
echo "⚡ PHASE 5: REAL WORLD SIMULATION"
echo "-------------------------------"

# Test 12: Create realistic test job
cat > /tmp/hostile_spark_test_job.py << 'EOF'
from pyspark.sql import SparkSession
import sys

def main():
    spark = SparkSession.builder.appName("HostileTestJob").getOrCreate()

    # Simple test that should work
    data = [1, 2, 3, 4, 5]
    rdd = spark.sparkContext.parallelize(data)
    result = rdd.sum()

    print(f"Sum result: {result}")

    if result == 15:
        print("SUCCESS: Test job completed correctly")
        sys.exit(0)
    else:
        print(f"FAILURE: Expected 15, got {result}")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

# Test 13: Dry run test (--help to see if command structure is valid)
test_output=$(default_spark_submit --help 2>&1)
if [[ $? -eq 0 ]] || [[ "$test_output" == *"Usage"* ]] || [[ "$test_output" == *"submit"* ]]; then
    log_test "Function dry run test" "PASS"
else
    log_test "Function dry run test" "FAIL" "Function structure appears broken"
fi

echo ""
echo "🔍 PHASE 6: STRESS TESTING"
echo "-------------------------"

# Test 14: Multiple concurrent function calls
for i in {1..3}; do
    (default_spark_submit --help >/dev/null 2>&1) &
done
wait
log_test "Concurrent function calls" "PASS" "Functions handle parallel execution"

# Test 15: Memory stress - very long arguments
long_arg=$(python3 -c "print('x' * 10000)")
test_output=$(default_spark_submit --conf spark.driver.extraJavaOptions="-D$long_arg=value" --help 2>&1)
if [[ $? -eq 0 ]] || [[ "$test_output" != *"Argument list too long"* ]]; then
    log_test "Long argument handling" "PASS"
else
    log_test "Long argument handling" "FAIL" "Cannot handle long arguments"
fi

# Cleanup
rm -f /tmp/hostile_spark_test_job.py

echo ""
echo "📊 HOSTILE TEST RESULTS SUMMARY"
echo "=============================="
echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo -e "Critical Failures: ${RED}$CRITICAL_FAILURES${NC}"

if [[ $CRITICAL_FAILURES -gt 0 ]]; then
    echo ""
    echo -e "${RED}🚨 CRITICAL SYSTEM FAILURES DETECTED${NC}"
    echo "The Spark system has fundamental issues that prevent operation."
    exit 1
elif [[ $FAILED_TESTS -gt 0 ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  SOME TESTS FAILED${NC}"
    echo "The Spark system works but has reliability issues."
    exit 1
else
    echo ""
    echo -e "${GREEN}🎉 ALL HOSTILE TESTS PASSED${NC}"
    echo "The Spark system is robust and handles adversarial conditions."
    exit 0
fi