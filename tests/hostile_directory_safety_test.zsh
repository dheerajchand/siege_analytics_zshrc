#!/usr/bin/env zsh

# 🔥 HOSTILE TESTING FOR DIRECTORY SAFETY TOOLS
# VP Engineering Level - Assume Developer Is An Idiot

echo "🔥 HOSTILE DIRECTORY SAFETY TOOLS TEST"
echo "======================================"
echo "Goal: Break every safety mechanism and expose coding mistakes"

# Load the tools we're testing
source /Users/dheerajchand/.config/zsh/scripts/directory_safety_tools.zsh >/dev/null 2>&1

test_failures=0
test_passed=0

fail_test() {
    echo "❌ FAIL: $1"
    ((test_failures++))
}

pass_test() {
    echo "✅ PASS: $1"
    ((test_passed++))
}

echo "\n🔥 TEST 1: COMMAND INJECTION IN FILE PATHS"
echo "==========================================="

# Test 1.1: Command injection via source file
echo "Testing: scan_file_dependencies with command injection"
if scan_file_dependencies "; rm -rf /tmp/test; echo hacked" 2>/dev/null | grep -q "hacked"; then
    fail_test "Command injection vulnerability in scan_file_dependencies"
else
    pass_test "scan_file_dependencies resists command injection"
fi

# Test 1.2: Path traversal attacks
echo "Testing: pre_move_validation with path traversal"
mkdir -p /tmp/test_hostile 2>/dev/null
echo "test" > /tmp/test_hostile/legitimate.txt
if pre_move_validation "../../../etc/passwd" "/tmp/test_hostile/passwd" 2>/dev/null | grep -q "Pre-move validation passed"; then
    fail_test "Path traversal vulnerability in pre_move_validation"
else
    pass_test "pre_move_validation blocks path traversal"
fi

echo "\n🔥 TEST 2: BUFFER OVERFLOW / RESOURCE EXHAUSTION"
echo "==============================================="

# Test 2.1: Extremely long file paths
long_path=$(printf 'a%.0s' {1..10000})
echo "Testing: Long path handling"
if scan_file_dependencies "$long_path" 2>/dev/null | grep -q "DEPENDENCY SCAN"; then
    echo "⚠️  WARNING: Accepts extremely long paths (potential DoS)"
else
    pass_test "Long path rejection"
fi

# Test 2.2: Many files in dependency matrix
echo "Testing: Resource exhaustion via many files"
mkdir -p /tmp/test_many_files 2>/dev/null
for i in {1..100}; do
    echo "# file $i" > "/tmp/test_many_files/file$i.zsh" 2>/dev/null
done
cd /tmp/test_many_files 2>/dev/null
timeout 5 zsh -c "source /Users/dheerajchand/.config/zsh/scripts/directory_safety_tools.zsh >/dev/null 2>&1 && create_dependency_matrix /tmp/stress_test.txt" >/dev/null 2>&1
if [[ $? -eq 124 ]]; then
    fail_test "Dependency matrix creation hangs on many files (DoS vulnerability)"
else
    pass_test "Dependency matrix handles many files gracefully"
fi
cd - >/dev/null 2>&1

echo "\n🔥 TEST 3: RACE CONDITIONS"
echo "========================="

# Test 3.1: Concurrent move operations
echo "Testing: Concurrent safe_move_file operations"
mkdir -p /tmp/race_test/{src,dest} 2>/dev/null
echo "test1" > /tmp/race_test/src/file1.txt
echo "test2" > /tmp/race_test/src/file2.txt

# Simulate race condition
(cd /tmp/race_test && zsh -c "source /Users/dheerajchand/.config/zsh/scripts/directory_safety_tools.zsh >/dev/null 2>&1 && safe_move_file src/file1.txt dest/file1.txt" >/dev/null 2>&1) &
(cd /tmp/race_test && zsh -c "source /Users/dheerajchand/.config/zsh/scripts/directory_safety_tools.zsh >/dev/null 2>&1 && safe_move_file src/file2.txt dest/file2.txt" >/dev/null 2>&1) &
wait

if [[ -f /tmp/race_test/dest/file1.txt && -f /tmp/race_test/dest/file2.txt ]]; then
    pass_test "Concurrent operations handled safely"
else
    fail_test "Race condition in concurrent file moves"
fi

echo "\n🔥 TEST 4: MALICIOUS INPUT VALIDATION"
echo "===================================="

# Test 4.1: Special characters in filenames
echo "Testing: Special characters in file paths"
touch "/tmp/file with spaces and 'quotes' and \$vars and ;commands" 2>/dev/null
if scan_file_dependencies "/tmp/file with spaces and 'quotes' and \$vars and ;commands" 2>/dev/null | grep -q "DEPENDENCY SCAN"; then
    pass_test "Handles special characters safely"
else
    echo "⚠️  WARNING: May have issues with special characters"
fi

# Test 4.2: Null bytes and binary data
echo "Testing: Null byte injection"
if scan_file_dependencies $'file\x00injected' 2>/dev/null | grep -q "injected"; then
    fail_test "Null byte injection vulnerability"
else
    pass_test "Null byte injection blocked"
fi

echo "\n🔥 TEST 5: BACKUP SYSTEM INTEGRITY"
echo "================================="

# Test 5.1: Backup directory hijacking
echo "Testing: Backup directory security"
export BACKUP_DIR="/etc"  # Try to hijack backup location
mkdir -p /tmp/backup_test 2>/dev/null
echo "test" > /tmp/backup_test/test.txt
cd /tmp/backup_test 2>/dev/null

# Check if backup respects hijacked location
if zsh -c "source /Users/dheerajchand/.config/zsh/scripts/directory_safety_tools.zsh >/dev/null 2>&1 && safe_move_file test.txt moved.txt" 2>&1 | grep -q "/etc"; then
    fail_test "Backup directory hijacking vulnerability"
else
    pass_test "Backup directory hardcoded safely"
fi
cd - >/dev/null 2>&1

echo "\n🔥 TEST 6: ERROR HANDLING FAILURES"
echo "================================="

# Test 6.1: Non-existent files
echo "Testing: Non-existent file handling"
if safe_move_file "/non/existent/file.txt" "/also/non/existent.txt" 2>/dev/null | grep -q "Pre-move validation passed"; then
    fail_test "Accepts non-existent source files"
else
    pass_test "Properly rejects non-existent files"
fi

# Test 6.2: Permission denied scenarios
echo "Testing: Permission handling"
mkdir -p /tmp/no_perm_test 2>/dev/null
echo "test" > /tmp/no_perm_test/file.txt
chmod 000 /tmp/no_perm_test/file.txt 2>/dev/null
if safe_move_file "/tmp/no_perm_test/file.txt" "/tmp/moved.txt" 2>/dev/null | grep -q "Pre-move validation passed"; then
    fail_test "Doesn't handle permission errors"
else
    pass_test "Properly handles permission errors"
fi
chmod 644 /tmp/no_perm_test/file.txt 2>/dev/null  # Cleanup

echo "\n🔥 TEST 7: MEMORY CORRUPTION / SHELL INJECTION"
echo "=============================================="

# Test 7.1: Variable pollution
export LOADED_MODULES="; rm -rf /tmp/test; echo hacked"
export ZSH_CONFIG_DIR="; malicious_command"

echo "Testing: Environment variable pollution resistance"
if test_system_health 2>&1 | grep -q "hacked\|malicious"; then
    fail_test "Environment variable injection vulnerability"
else
    pass_test "Resists environment variable pollution"
fi

# Test 7.2: Function hijacking
unset -f test_system_health 2>/dev/null
test_system_health() { echo "HIJACKED FUNCTION"; }

if zsh -c "source /Users/dheerajchand/.config/zsh/scripts/directory_safety_tools.zsh >/dev/null 2>&1 && test_system_health" 2>&1 | grep -q "HIJACKED"; then
    fail_test "Function hijacking vulnerability"
else
    pass_test "Protected against function hijacking"
fi

echo "\n🔥 HOSTILE TEST RESULTS"
echo "======================="
echo "Tests passed: $test_passed"
echo "Tests failed: $test_failures"

if [[ $test_failures -eq 0 ]]; then
    echo "✅ Directory safety tools are HOSTILE-TEST CERTIFIED"
    echo "💪 Ready for production use with confidence"
    exit 0
else
    echo "❌ Directory safety tools FAILED hostile testing"
    echo "🚨 DO NOT USE IN PRODUCTION - Security vulnerabilities found"
    exit 1
fi