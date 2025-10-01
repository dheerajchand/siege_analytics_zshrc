#!/usr/bin/env zsh

# Simple credential testing
source ~/.config/zsh/config/credentials.zsh

echo "=== TESTING BACKEND FAILURE ==="
# Back up PATH
original_path="$PATH"
# Remove 1Password from PATH
export PATH="$(echo $PATH | sed 's|[^:]*1password[^:]*:||g')"
echo "1Password removed from PATH"

# Test function
echo "Testing get_credential..."
get_credential 'nonexistent-test' 'user' 2>/dev/null
exit_code=$?
echo "Exit code: $exit_code"

# Restore PATH
export PATH="$original_path"

echo ""
echo "=== TESTING CREDENTIAL LEAKAGE ==="
output=$(get_credential 'secret-service' 'secret-user' 2>&1)
echo "Output: '$output'"
echo "Checking for leaks..."
if echo "$output" | grep -i 'password\|secret\|credential' >/dev/null; then
    echo "❌ LEAK DETECTED"
else
    echo "✅ NO LEAKS"
fi

echo ""
echo "=== TESTING INJECTION PROTECTION ==="
get_credential 'test-$$$invalid' 'user-$(date)' 2>/dev/null
injection_exit=$?
echo "Injection test exit code: $injection_exit"

if [[ $exit_code -eq 1 && $injection_exit -eq 1 ]]; then
    echo "✅ Backend and injection tests passed"
else
    echo "❌ Tests failed: backend=$exit_code, injection=$injection_exit"
fi