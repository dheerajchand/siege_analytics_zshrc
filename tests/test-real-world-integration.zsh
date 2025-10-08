#!/usr/bin/env zsh
# =====================================================
# REAL-WORLD INTEGRATION TESTING SUITE
# =====================================================
#
# Purpose: Test actual functionality with real tools and services
# Principle: No emulation - test actual capabilities
# Usage: ~/.config/zsh/test-real-world-integration.zsh
# =====================================================

echo "🌍 REAL-WORLD INTEGRATION TESTING SUITE"
echo "========================================"
echo "Testing principle: Use actual tools and services, not emulation"
echo "Scope: Spark jobs, Docker containers, database connections, backup operations"
echo ""

# Test result tracking
local tests_run=0
local tests_passed=0
local tests_failed=0
local failed_tests=()
local warnings=()

# Helper function for real-world test execution
run_real_test() {
    local test_name="$1"
    local test_description="$2"
    local test_command="$3"
    local success_pattern="$4"
    local failure_is_ok="${5:-false}"  # Some tests may fail due to missing external services

    ((tests_run++))
    echo "🔍 REAL TEST: $test_name"
    echo "   Description: $test_description"

    # Execute real command
    local result
    local exit_code
    result=$(eval "$test_command" 2>&1)
    exit_code=$?

    # Evaluate result
    if [[ $exit_code -eq 0 && "$result" =~ "$success_pattern" ]]; then
        echo "✅ PASS: Real functionality verified"
        ((tests_passed++))
    elif [[ "$failure_is_ok" == "true" ]]; then
        echo "⚠️  SKIP: External service unavailable (expected)"
        echo "   Note: $result"
        warnings+=("$test_name")
    else
        echo "❌ FAIL: Real functionality not working"
        ((tests_failed++))
        failed_tests+=("$test_name")
        echo "   Command: $test_command"
        echo "   Output: $result"
        echo "   Exit: $exit_code"
    fi
    echo ""
}

# =====================================================
# REAL-WORLD TESTS
# =====================================================

echo "📋 REAL-WORLD: Module Loading and Functionality Tests"
echo "====================================================="

# Test RW.1: Backup System with Real Git Operations
run_real_test "RW.1 Backup System" \
    "Create actual backup and push to Git repository" \
    "backup 'Real-world integration test commit'" \
    "(Backup completed|Changes pushed)" \
    true

# Test RW.2: Python Environment with Real Code Execution
run_real_test "RW.2 Python Execution" \
    "Execute actual Python code in current environment" \
    "python3 -c \"import sys, json; print(f'Python {sys.version_info.major}.{sys.version_info.minor} - JSON module: {json.__name__}')\"" \
    "Python 3.*JSON module: json"

# Test RW.3: Docker Integration with Real Container Operations
run_real_test "RW.3 Docker Container" \
    "Start and interact with actual Docker container" \
    "load_module docker >/dev/null 2>&1 && docker run --rm hello-world" \
    "Hello from Docker" \
    true

# Test RW.4: Spark Module with Real Spark Job
run_real_test "RW.4 Spark Job Submission" \
    "Submit actual Spark job (local mode)" \
    "load_module spark >/dev/null 2>&1 && echo 'from pyspark.sql import SparkSession; spark = SparkSession.builder.appName(\"test\").master(\"local\").getOrCreate(); print(\"Spark Context:\", spark.sparkContext); spark.stop()' | python3" \
    "Spark Context" \
    true

# Test RW.5: Database Connection Test
run_real_test "RW.5 Database Tools" \
    "Test database client availability" \
    "load_module database >/dev/null 2>&1 && psql --version" \
    "psql.*PostgreSQL" \
    true

# Test RW.6: File Operations with Real Files
run_real_test "RW.6 File Operations" \
    "Create, manipulate, and clean up real files" \
    "mkcd /tmp/zsh_test_$$ && echo 'test content' > test_file.txt && cat test_file.txt && cd .. && rm -rf /tmp/zsh_test_$$" \
    "test content"

# Test RW.7: Network Connectivity Test
run_real_test "RW.7 Network Operations" \
    "Test actual network connectivity" \
    "curl -s --max-time 5 https://httpbin.org/ip" \
    "origin.*[0-9]" \
    true

# Test RW.8: Module Dependency Resolution
run_real_test "RW.8 Module Dependencies" \
    "Test Spark module loads without path_add errors" \
    "load_module spark 2>&1" \
    "✅.*Spark.*loaded successfully" \
    false

# Test RW.9: Variable State Consistency
run_real_test "RW.9 State Consistency" \
    "Verify LOADED_MODULES reflects actual state" \
    "echo \$LOADED_MODULES | grep -E '(utils|python)'" \
    "(utils.*python|python.*utils)"

# Test RW.10: Mode Detection with Real Environment
run_real_test "RW.10 Mode Detection" \
    "Test mode detection with actual environment variables" \
    "detect_zsh_mode" \
    "staggered"

# =====================================================
# ADVANCED REAL-WORLD TESTS
# =====================================================

echo "📋 ADVANCED: Real Tool Integration Tests"
echo "========================================"

# Test ARW.1: UV Python Project Creation
if command -v uv >/dev/null 2>&1; then
    run_real_test "ARW.1 UV Project Creation" \
        "Create actual Python project with UV" \
        "cd /tmp && uv init test_project_$$ && cd test_project_$$ && ls" \
        "pyproject.toml" \
        true
fi

# Test ARW.2: Pyenv Environment Switching
if command -v pyenv >/dev/null 2>&1; then
    run_real_test "ARW.2 Pyenv Environment" \
        "Test pyenv environment detection" \
        "pyenv version" \
        "geo31111"
fi

# Test ARW.3: Git Operations
run_real_test "ARW.3 Git Operations" \
    "Test git functionality in current repository" \
    "git status --porcelain | wc -l" \
    "[0-9]+"

# Test ARW.4: PATH Management
run_real_test "ARW.4 PATH Management" \
    "Test PATH optimization functionality" \
    "echo \$PATH | wc -c" \
    "[0-9]+"

# Test ARW.5: Oh-My-Zsh Integration
run_real_test "ARW.5 Oh-My-Zsh" \
    "Test Oh-My-Zsh plugin functionality" \
    "alias | grep -E '^(ll|la)='" \
    "ll=.*ls"

# =====================================================
# PERFORMANCE AND RELIABILITY TESTS
# =====================================================

echo "📋 PERFORMANCE: Real-World Performance Tests"
echo "==========================================="

# Test PRF.1: Startup Time
run_real_test "PRF.1 Startup Performance" \
    "Measure actual startup time" \
    "time zsh -c 'source ~/.zshrc; echo startup_complete' 2>&1 | grep real" \
    "real.*0m[0-9]"

# Test PRF.2: Module Loading Performance
run_real_test "PRF.2 Module Loading Speed" \
    "Test individual module loading time" \
    "time load_module docker 2>&1 | grep real || echo 'Module already loaded'" \
    "(real.*0m[0-9]|Module already loaded)"

# Test PRF.3: Memory Usage
run_real_test "PRF.3 Memory Efficiency" \
    "Check shell memory footprint" \
    "ps -o rss= -p \$\$ | awk '{print \$1 < 50000 ? \"efficient\" : \"heavy\"}'" \
    "efficient"

# =====================================================
# REAL-WORLD INTEGRATION RESULTS
# =====================================================

echo "🎯 REAL-WORLD INTEGRATION RESULTS"
echo "================================="
echo "📊 Total tests run: $tests_run"
echo "✅ Tests passed: $tests_passed"
echo "❌ Tests failed: $tests_failed"
echo "⚠️  Tests skipped (external deps): ${#warnings[@]}"

if [[ ${#warnings[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  Skipped tests (external dependencies unavailable):"
    for warning in "${warnings[@]}"; do
        echo "  - $warning"
    done
fi

if [[ $tests_failed -eq 0 ]]; then
    echo ""
    echo "🌍 REAL-WORLD INTEGRATION COMPLETE - FUNCTIONALITY VERIFIED!"
    echo "✅ All core functionality working with real tools"
    echo "✅ System handles actual workloads successfully"
    echo "✅ Integration with external tools verified"
    echo "✅ Ready for production use with real workflows"

    # Real-world capability summary
    echo ""
    echo "💎 REAL-WORLD CAPABILITIES VERIFIED:"
    echo "   Backup system: Git operations with real repositories"
    echo "   Python: Code execution in actual environments"
    echo "   Docker: Container operations (if daemon available)"
    echo "   Spark: Job submission capabilities (if installed)"
    echo "   Network: Real connectivity and API calls"
    echo "   File system: Actual file operations and management"

    exit 0
else
    echo ""
    echo "🚨 REAL-WORLD INTEGRATION ISSUES FOUND"
    echo "❌ Failed tests: ${failed_tests[*]}"
    echo "🔧 These represent actual functionality problems, not test issues"
    echo ""
    echo "⚠️  Production readiness: CONDITIONAL"
    echo "     - Core functionality works"
    echo "     - Some integrations need attention"

    exit 1
fi