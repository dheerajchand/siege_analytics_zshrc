#!/usr/bin/env zsh
# =================================================================
# PESSIMISTIC TESTING - Assume Failure, Prove Success
# =================================================================
# Tests clean zsh build by trying to break it
# Not "security theater" - just thorough failure testing
# =================================================================

echo "🧪 Testing Clean ZSH Build"
echo "=========================="
echo "Approach: Assume everything will fail, prove it works"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

# Test helper
test_function() {
    local name="$1"
    local description="$2"
    shift 2
    
    echo -n "Testing $name: $description... "
    
    if "$@" >/dev/null 2>&1; then
        echo "✅ PASS"
        ((TESTS_PASSED++))
        return 0
    else
        echo "❌ FAIL"
        ((TESTS_FAILED++))
        return 1
    fi
}

# =================================================================
# TEST 1: Core Functions Exist
# =================================================================
echo "1️⃣  Testing Core Functions"
echo "─────────────────────────"

test_function "command_exists" "function exists" command -v command_exists
test_function "is_online" "function exists" command -v is_online
test_function "mkcd" "function exists" command -v mkcd
test_function "extract" "function exists" command -v extract
test_function "path_add" "function exists" command -v path_add
test_function "path_clean" "function exists" command -v path_clean

echo ""

# =================================================================
# TEST 2: Core Functions Work
# =================================================================
echo "2️⃣  Testing Core Function Behavior"
echo "─────────────────────────────────"

# Test command_exists
test_function "command_exists" "detects existing command" command_exists ls
test_function "command_exists" "rejects non-existent" bash -c "! command_exists fake_command_xyz"

# Test is_online (may fail if offline - that's OK)
if is_online >/dev/null 2>&1; then
    echo -n "Testing is_online: returns true when online... "
    if [[ "$(is_online_status)" == "online" ]]; then
        echo "✅ PASS"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL"
        ((TESTS_FAILED++))
    fi
else
    echo "⚠️  Skipping is_online test (offline)"
fi

# Test mkcd
test_function "mkcd" "creates and enters directory" bash -c "cd /tmp && mkcd test_zsh_$$ && [[ \$(pwd) == /tmp/test_zsh_$$ ]] && cd /tmp && rm -rf test_zsh_$$"

# Test path_add
test_function "path_add" "adds to PATH" bash -c "export PATH=/usr/bin && path_add /tmp && [[ \$PATH == /tmp:/usr/bin ]]"

echo ""

# =================================================================
# TEST 3: Python Environment
# =================================================================
echo "3️⃣  Testing Python Environment"
echo "────────────────────────────"

test_function "pyenv" "command available" command -v pyenv
test_function "python" "python available" command -v python
test_function "py_env_switch" "function exists" command -v py_env_switch
test_function "python_status" "function exists" command -v python_status

# Test Python actually works
echo -n "Testing python: executes code... "
if python -c "print('test')" 2>/dev/null | grep -q "test"; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL"
    ((TESTS_FAILED++))
fi

echo ""

# =================================================================
# TEST 4: Spark Functions
# =================================================================
echo "4️⃣  Testing Spark Functions"
echo "─────────────────────────"

test_function "SPARK_HOME" "environment variable set" test -n "$SPARK_HOME"
test_function "spark_start" "function exists" command -v spark_start
test_function "spark_stop" "function exists" command -v spark_stop
test_function "spark_status" "function exists" command -v spark_status
test_function "smart_spark_submit" "function exists" command -v smart_spark_submit
test_function "get_spark_dependencies" "function exists" command -v get_spark_dependencies
test_function "spark_yarn_submit" "function exists" command -v spark_yarn_submit

# Test get_spark_dependencies logic
echo -n "Testing get_spark_dependencies: returns value... "
if [[ -n "$(get_spark_dependencies 2>/dev/null)" ]]; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL (may be OK if no JARs and offline)"
    ((TESTS_FAILED++))
fi

echo ""

# =================================================================
# TEST 5: Hadoop/YARN Functions
# =================================================================
echo "5️⃣  Testing Hadoop/YARN Functions"
echo "───────────────────────────────"

test_function "HADOOP_HOME" "environment variable set" test -n "$HADOOP_HOME"
test_function "start_hadoop" "function exists" command -v start_hadoop
test_function "stop_hadoop" "function exists" command -v stop_hadoop
test_function "hadoop_status" "function exists" command -v hadoop_status
test_function "yarn_application_list" "function exists" command -v yarn_application_list
test_function "hdfs_ls" "function exists" command -v hdfs_ls

echo ""

# =================================================================
# TEST 6: Docker Functions
# =================================================================
echo "6️⃣  Testing Docker Functions"
echo "──────────────────────────"

test_function "docker_status" "function exists" command -v docker_status
test_function "docker_cleanup" "function exists" command -v docker_cleanup
test_function "docker_shell" "function exists" command -v docker_shell
test_function "docker_logs" "function exists" command -v docker_logs

if command -v docker >/dev/null 2>&1; then
    echo -n "Testing docker: command works... "
    if docker --version >/dev/null 2>&1; then
        echo "✅ PASS"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL"
        ((TESTS_FAILED++))
    fi
fi

echo ""

# =================================================================
# TEST 7: Database Functions
# =================================================================
echo "7️⃣  Testing Database Functions"
echo "────────────────────────────"

test_function "PGHOST" "environment variable set" test -n "$PGHOST"
test_function "PGUSER" "environment variable set" test -n "$PGUSER"
test_function "pg_connect" "function exists" command -v pg_connect
test_function "pg_test_connection" "function exists" command -v pg_test_connection
test_function "setup_postgres_credentials" "function exists" command -v setup_postgres_credentials
test_function "database_status" "function exists" command -v database_status

echo ""

# =================================================================
# TEST 8: Credential Functions
# =================================================================
echo "8️⃣  Testing Credential Functions"
echo "──────────────────────────────"

test_function "get_credential" "function exists" command -v get_credential
test_function "store_credential" "function exists" command -v store_credential
test_function "credential_backend_status" "function exists" command -v credential_backend_status
test_function "ga_store_service_account" "function exists" command -v ga_store_service_account

# Test 1Password is available
if command -v op >/dev/null 2>&1; then
    echo -n "Testing 1Password: CLI available... "
    echo "✅ PASS"
    ((TESTS_PASSED++))
fi

echo ""

# =================================================================
# TEST 9: Backup Functions
# =================================================================
echo "9️⃣  Testing Backup Functions"
echo "──────────────────────────"

test_function "backup" "function exists" command -v backup
test_function "pushmain" "function exists" command -v pushmain
test_function "sync" "function exists" command -v sync
test_function "repo_status" "function exists" command -v repo_status

echo ""

# =================================================================
# TEST 10: No Duplicate Functions
# =================================================================
echo "🔟 Testing for Duplicates"
echo "───────────────────────"

echo -n "Testing command_exists: only one definition... "
if [[ $(type -a command_exists 2>/dev/null | grep -c "is a shell function") -eq 1 ]]; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL (multiple definitions found)"
    type -a command_exists
    ((TESTS_FAILED++))
fi

echo -n "Testing is_online: only one definition... "
if [[ $(type -a is_online 2>/dev/null | grep -c "is a shell function") -eq 1 ]]; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL (multiple definitions found)"
    type -a is_online
    ((TESTS_FAILED++))
fi

echo ""

# =================================================================
# TEST 11: Critical Workflow Tests
# =================================================================
echo "1️⃣1️⃣  Testing Critical Workflows"
echo "─────────────────────────────"

# Test Spark dependency decision based on connectivity
echo -n "Testing Spark dependency logic: uses is_online()... "
if get_spark_dependencies 2>&1 | grep -qE "(local JARs|Maven packages|Offline)"; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
else
    echo "❌ FAIL"
    ((TESTS_FAILED++))
fi

# Test Python environment is active
echo -n "Testing Python: geo31111 environment active... "
if pyenv version-name 2>/dev/null | grep -q "geo31111"; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
else
    echo "⚠️  WARN (geo31111 not active)"
    echo "  Current: $(pyenv version-name 2>/dev/null || echo 'unknown')"
fi

echo ""

# =================================================================
# FINAL RESULTS
# =================================================================
echo "═══════════════════════════════════════════════════"
echo "  TEST RESULTS"
echo "═══════════════════════════════════════════════════"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "🎉 ALL TESTS PASSED"
    echo "✅ Clean build is ready for use"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    echo "⚠️  Review failures above"
    exit 1
fi



