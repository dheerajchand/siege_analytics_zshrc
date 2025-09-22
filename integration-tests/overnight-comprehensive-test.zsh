#!/usr/bin/env zsh
# =====================================================
# OVERNIGHT COMPREHENSIVE ZSH SYSTEM TEST
# =====================================================
# This is the master test that runs everything
# Perfect for overnight automation
# =====================================================

echo "🌙 OVERNIGHT COMPREHENSIVE ZSH SYSTEM TEST"
echo "=========================================="
echo "Started: $(date)"
echo "This will test EVERY aspect of the zsh configuration system"
echo ""

# Create timestamped results directory
RESULTS_DIR="$HOME/.config/zsh/test-results-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$RESULTS_DIR"

# Redirect all output to log file and console
exec > >(tee "$RESULTS_DIR/master-test-log.txt")
exec 2>&1

echo "📁 Results will be saved to: $RESULTS_DIR"
echo ""

# Load zsh configuration
echo "🔧 Loading ZSH configuration..."
source ~/.zshrc >/dev/null 2>&1
echo "✅ ZSH configuration loaded"
echo ""

# Test Phase 1: Production System Validation
echo "🧪 PHASE 1: PRODUCTION SYSTEM VALIDATION"
echo "========================================"
cd /Users/dheerajchand/.config/zsh
./test-production-system.zsh > "$RESULTS_DIR/production-test.log" 2>&1
echo "✅ Production test completed - see production-test.log"
echo ""

# Test Phase 2: Individual Integration Tests
echo "🔬 PHASE 2: INDIVIDUAL INTEGRATION TESTS"
echo "========================================"

cd integration-tests

# Run each integration test
integration_tests=(
    "test-backup-system-real.zsh"
    "test-python-environments-real.zsh"
    "test-spark-hdfs-real.zsh" 
    "test-docker-real.zsh"
    "test-database-real.zsh"
    "test-jetbrains-real.zsh"
)

for test in "${integration_tests[@]}"; do
    if [[ -f "$test" ]]; then
        test_name=$(basename "$test" .zsh)
        echo "Running $test_name..."
        ./"$test" > "$RESULTS_DIR/$test_name.log" 2>&1
        echo "✅ $test_name completed"
    else
        echo "❌ $test not found"
    fi
done

echo ""

# Test Phase 3: Comprehensive Function Testing
echo "🔍 PHASE 3: COMPREHENSIVE FUNCTION TESTING"
echo "=========================================="

./comprehensive-functionality-test.zsh > "$RESULTS_DIR/comprehensive-functions.log" 2>&1
echo "✅ Comprehensive function test completed"
echo ""

# Test Phase 4: All Modules Testing
echo "📦 PHASE 4: ALL MODULES TESTING"
echo "==============================="

./test-all-modules-real.zsh > "$RESULTS_DIR/all-modules.log" 2>&1
echo "✅ All modules test completed"
echo ""

# Test Phase 5: Edge Cases and Stress Testing
echo "⚡ PHASE 5: EDGE CASES AND STRESS TESTING"
echo "========================================"

# Test with missing directories
echo "Testing resilience with missing directories..."
cd /Users/dheerajchand/.config/zsh

# Backup and test missing modules
if [[ -d "modules" ]]; then
    mv modules modules.test.backup
    echo "Testing with missing modules directory..."
    zsh -c "source ~/.zshrc 2>&1" > "$RESULTS_DIR/missing-modules-test.log"
    mv modules.test.backup modules
    echo "✅ Missing modules test completed"
fi

# Test with missing config
if [[ -d "config" ]]; then
    mv config config.test.backup
    echo "Testing with missing config directory..."
    zsh -c "source ~/.zshrc 2>&1" > "$RESULTS_DIR/missing-config-test.log"
    mv config.test.backup config
    echo "✅ Missing config test completed"
fi

echo ""

# Test Phase 6: Performance Testing
echo "🏃 PHASE 6: PERFORMANCE TESTING"
echo "==============================="

echo "Testing startup performance..."
time zsh -c "source ~/.zshrc >/dev/null 2>&1" > "$RESULTS_DIR/startup-performance.log" 2>&1
echo "✅ Startup performance test completed"

echo "Testing PATH length..."
zsh -c "source ~/.zshrc >/dev/null 2>&1; echo 'PATH length: \${#PATH} characters'" > "$RESULTS_DIR/path-length.log" 2>&1
echo "✅ PATH length test completed"

echo ""

# Final Results Summary
echo "🎯 OVERNIGHT TEST SUITE COMPLETE"
echo "================================"
echo "Completed: $(date)"
echo ""
echo "📊 All test results saved to: $RESULTS_DIR"
echo ""
echo "📋 Quick Summary:"
echo "   production-test.log          - Production system validation"
echo "   backup-system-real.log       - Backup functionality"
echo "   python-environments-real.log - Python environment management"
echo "   spark-hdfs-real.log         - Spark and HDFS integration"
echo "   docker-real.log             - Docker functionality"
echo "   database-real.log           - Database connections"
echo "   jetbrains-real.log          - IDE integration"
echo "   comprehensive-functions.log  - All function availability"
echo "   all-modules.log             - Module loading tests"
echo "   missing-modules-test.log    - Edge case: missing modules"
echo "   missing-config-test.log     - Edge case: missing config"
echo "   startup-performance.log     - Performance metrics"
echo "   path-length.log             - PATH optimization"
echo ""
echo "🌅 CHECK RESULTS WHEN YOU WAKE UP!"
echo ""

# Create summary report
echo "📄 Creating summary report..."
cat > "$RESULTS_DIR/SUMMARY.md" << EOF
# Overnight ZSH System Test Results

**Test Date:** $(date)
**System:** $(uname -a)
**ZSH Version:** $ZSH_VERSION

## Test Results Summary

### Production System Test
$(grep -E "(tests passed|tests failed|PASS|FAIL)" "$RESULTS_DIR/production-test.log" 2>/dev/null | tail -5)

### Integration Tests
$(for log in "$RESULTS_DIR"/*-real.log; do
    if [[ -f "$log" ]]; then
        test_name=$(basename "$log" -real.log)
        success=$(grep -c "✅" "$log" 2>/dev/null || echo "0")
        failures=$(grep -c "❌" "$log" 2>/dev/null || echo "0")
        echo "- $test_name: $success ✅ / $failures ❌"
    fi
done)

### Performance Metrics
$(cat "$RESULTS_DIR/startup-performance.log" 2>/dev/null)
$(cat "$RESULTS_DIR/path-length.log" 2>/dev/null)

### Edge Case Testing
- Missing modules test: $(grep -c "❌" "$RESULTS_DIR/missing-modules-test.log" 2>/dev/null || echo "0") errors
- Missing config test: $(grep -c "❌" "$RESULTS_DIR/missing-config-test.log" 2>/dev/null || echo "0") errors

## Overall Assessment

**System Status:** $(if [[ $(grep -c "✅" "$RESULTS_DIR"/*.log 2>/dev/null) -gt $(grep -c "❌" "$RESULTS_DIR"/*.log 2>/dev/null) ]]; then echo "FUNCTIONAL"; else echo "NEEDS REPAIR"; fi)

**Next Steps:** Review individual log files for detailed analysis.
EOF

echo "✅ Summary report created: $RESULTS_DIR/SUMMARY.md"
echo ""
echo "🎯 OVERNIGHT TESTING SETUP COMPLETE!"
echo "===================================="
echo "All tests will run automatically."
echo "Check $RESULTS_DIR when you wake up for complete results."
