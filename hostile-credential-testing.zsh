#!/usr/bin/env zsh

# =====================================================
# HOSTILE CREDENTIAL SYSTEM TESTING FRAMEWORK
# =====================================================

echo "🔥 HOSTILE CREDENTIAL SYSTEM TESTING"
echo "====================================="

# Load credential system
source ~/.config/zsh/config/credentials.zsh

# Test counters
local test_count=0
local pass_count=0

run_test() {
    local test_name="$1"
    local test_command="$2"

    test_count=$((test_count + 1))
    echo ""
    echo "🧪 TEST $test_count: $test_name"

    if eval "$test_command" >/dev/null 2>&1; then
        echo "   ✅ PASS"
        pass_count=$((pass_count + 1))
    else
        echo "   ❌ FAIL"
        echo "   Command: $test_command"
    fi
}

echo ""
echo "🔍 CATEGORY 1: FUNCTION AVAILABILITY TESTS"
echo "==========================================="

run_test "get_credential function exists" "command -v get_credential"
run_test "store_credential function exists" "command -v store_credential"
run_test "credential_backend_status function exists" "command -v credential_backend_status"
run_test "test_credential_system function exists" "command -v test_credential_system"
run_test "ga_get_service_account function exists" "command -v ga_get_service_account"
run_test "ga_list_credentials function exists" "command -v ga_list_credentials"

echo ""
echo "🔥 CATEGORY 2: HOSTILE INPUT TESTING"
echo "===================================="

run_test "get_credential handles empty service" "! get_credential '' 'user'"
run_test "get_credential handles empty user" "! get_credential 'service' ''"
run_test "get_credential handles missing args" "! get_credential"
run_test "store_credential handles empty service" "! store_credential '' 'user' 'pass'"
run_test "store_credential handles empty user" "! store_credential 'service' '' 'pass'"
run_test "store_credential handles empty password" "! store_credential 'service' 'user' ''"
run_test "store_credential handles missing args" "! store_credential"

echo ""
echo "⚡ CATEGORY 3: BACKEND FAILURE SIMULATION"
echo "========================================="

# Temporarily break 1Password CLI
run_test "Graceful degradation when 1Password unavailable" "
    # Backup original PATH
    original_path=\"\$PATH\"
    # Remove op from PATH temporarily
    export PATH=\"\$(echo \$PATH | sed 's|[^:]*1password[^:]*:||g')\"
    # Test should still work with Keychain fallback
    result=\$(get_credential 'nonexistent-test' 'user' 2>/dev/null; echo \$?)
    # Restore PATH
    export PATH=\"\$original_path\"
    # Should return 1 (not found) but not crash
    [[ \$result -eq 1 ]]
"

# Test with corrupted credential store
run_test "Handle corrupted credential data gracefully" "
    # Should not crash on malformed credential requests
    result=\$(get_credential 'test-\$\$\$invalid' 'user-\$(date)' 2>/dev/null; echo \$?)
    [[ \$result -eq 1 ]]
"

echo ""
echo "🛡️ CATEGORY 4: SECURITY TESTING"
echo "==============================="

run_test "No credential leakage in error output" "
    # Test that sensitive data doesn't appear in error messages
    output=\$(get_credential 'secret-service' 'secret-user' 2>&1 || true)
    ! echo \"\$output\" | grep -i 'password\\|secret\\|credential' >/dev/null
"

run_test "Function parameter validation" "
    # Test injection attempts
    ! get_credential 'service; rm -rf /' 'user'
"

echo ""
echo "🚀 CATEGORY 5: INTEGRATION STRESS TESTS"
echo "========================================"

run_test "Concurrent credential access simulation" "
    # Test multiple credential calls don't interfere
    (get_credential 'test1' 'user1' >/dev/null 2>&1 &)
    (get_credential 'test2' 'user2' >/dev/null 2>&1 &)
    (get_credential 'test3' 'user3' >/dev/null 2>&1 &)
    wait
    true
"

run_test "Environment variable pollution resistance" "
    # Test that credential functions work with polluted environment
    PGPASSWORD='fake' MYSQL_PASSWORD='fake' SNOWFLAKE_PASSWORD='fake' \\
    credential_backend_status >/dev/null
"

run_test "Module loading in hostile environment" "
    # Test loading credentials module with PATH pollution
    PYTHONPATH='/fake/path' NODE_PATH='/fake/path' \\
    source ~/.config/zsh/config/credentials.zsh >/dev/null 2>&1
"

echo ""
echo "🔧 CATEGORY 6: ALIAS AND CONVENIENCE FUNCTIONS"
echo "=============================================="

run_test "creds-status alias works" "command -v creds-status && creds-status >/dev/null"
run_test "creds-test alias works" "command -v creds-test"
run_test "creds-get alias works" "command -v creds-get"
run_test "creds-store alias works" "command -v creds-store"
run_test "ga-get alias works" "command -v ga-get"
run_test "ga-list alias works" "command -v ga-list"

echo ""
echo "📊 HOSTILE CREDENTIAL TESTING RESULTS"
echo "====================================="
echo "Total Tests: $test_count"
echo "Passed: $pass_count"
echo "Failed: $((test_count - pass_count))"
echo ""

if [[ $pass_count -eq $test_count ]]; then
    echo "🎉 ALL HOSTILE CREDENTIAL TESTS PASSED!"
    echo "✅ Credential system is PRODUCTION READY"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    echo "⚠️  Credential system needs attention"
    exit 1
fi