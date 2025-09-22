#!/usr/bin/env zsh
# =====================================================
# OVERNIGHT COMPREHENSIVE TEST RUNNER
# =====================================================
# Runs ALL integration tests automatically
# Perfect for overnight execution
# =====================================================

echo "🌙 OVERNIGHT COMPREHENSIVE TEST SUITE"
echo "====================================="
echo "Started: $(date)"
echo ""

# Create results directory
RESULTS_DIR="/Users/dheerajchand/.config/zsh/integration-tests/results-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Test execution function
run_test_suite() {
    local test_name="$1"
    local test_script="$2"
    
    echo "🔍 Running: $test_name"
    echo "======================================="
    
    if [[ -f "$test_script" ]]; then
        # Run test and capture output
        if "$test_script" > "$RESULTS_DIR/${test_name}.log" 2>&1; then
            echo "✅ $test_name: COMPLETED"
            # Show summary
            tail -5 "$RESULTS_DIR/${test_name}.log" | grep -E "(✅|❌|COMPLETE|SUCCESS|FAIL)"
        else
            echo "❌ $test_name: FAILED"
        fi
    else
        echo "❌ $test_name: Test script not found"
    fi
    echo ""
}

# Run all test suites
run_test_suite "backup-system" "./test-backup-system-real.zsh"
run_test_suite "python-environments" "./test-python-environments-real.zsh" 
run_test_suite "spark-hdfs" "./test-spark-hdfs-real.zsh"
run_test_suite "docker-integration" "./test-docker-real.zsh"
run_test_suite "database-integration" "./test-database-real.zsh"
run_test_suite "jetbrains-integration" "./test-jetbrains-real.zsh"
run_test_suite "comprehensive-functionality" "./comprehensive-functionality-test.zsh"

# Additional module-specific tests
echo "🔧 TESTING INDIVIDUAL CONFIG MODULES"
echo "===================================="

# Test each config module individually
config_modules=(
    "credentials"
    "environment" 
    "hadoop"
    "help"
    "notebooks"
    "shell-compat"
    "status"
)

for module in "${config_modules[@]}"; do
    echo "Testing config/$module.zsh..."
    if [[ -f "../config/$module.zsh" ]]; then
        if source "../config/$module.zsh" >/dev/null 2>&1; then
            echo "✅ config/$module.zsh: Sources successfully"
        else
            echo "❌ config/$module.zsh: Source failed"
        fi
    else
        echo "❌ config/$module.zsh: File not found"
    fi
done

echo ""
echo "🧪 TESTING UTILITY SCRIPTS"
echo "=========================="

# Test utility scripts
if [[ -d "../scripts" ]]; then
    find "../scripts" -name "*.zsh" -o -name "*.sh" | while read script; do
        script_name=$(basename "$script")
        echo "Testing script: $script_name..."
        if [[ -x "$script" ]]; then
            echo "✅ $script_name: Executable"
        else
            echo "❌ $script_name: Not executable"
        fi
    done
fi

echo ""
echo "🎯 OVERNIGHT TEST SUITE COMPLETE"
echo "================================"
echo "Completed: $(date)"
echo ""
echo "📊 Results Summary:"
echo "   Results saved to: $RESULTS_DIR"
echo "   Individual test logs available"
echo "   Check each .log file for detailed results"
echo ""
echo "📋 Quick Results Check:"
for log_file in "$RESULTS_DIR"/*.log; do
    if [[ -f "$log_file" ]]; then
        test_name=$(basename "$log_file" .log)
        success_count=$(grep -c "✅" "$log_file" 2>/dev/null || echo "0")
        fail_count=$(grep -c "❌" "$log_file" 2>/dev/null || echo "0")
        echo "   $test_name: $success_count ✅ / $fail_count ❌"
    fi
done

echo ""
echo "🌅 OVERNIGHT TESTING COMPLETE - CHECK RESULTS WHEN YOU WAKE UP!"
