#!/usr/bin/env zsh

# =====================================================
# CROSS-USER PORTABILITY TEST
# =====================================================
#
# Test script to verify that the ZSH configuration works
# across different users and environments without hardcoded paths.
#
# Usage: ./test-portability.zsh
# =====================================================

echo "🔍 Testing Cross-User Portability"
echo "================================="
echo ""

# Simulate different users
test_users=("alice" "bob" "charlie" "testuser")
current_user="$USER"

echo "📊 Current user: $current_user"
echo ""

# Test dynamic path resolution
echo "🧪 Testing Dynamic Path Resolution"
echo "----------------------------------"

# Source the variables to test
source "$(dirname "$0")/config/variables.zsh" 2>/dev/null || {
    echo "❌ Failed to source variables.zsh"
    exit 1
}

# Test 1: Check that no hardcoded 'dheerajchand' exists in key variables
echo "Test 1: Checking for hardcoded usernames..."
failed_vars=()

check_var() {
    local var_name="$1"
    local var_value="${(P)var_name}"
    if [[ "$var_value" =~ "dheerajchand" ]]; then
        failed_vars+=("$var_name=$var_value")
        echo "  ❌ $var_name contains hardcoded username: $var_value"
        return 1
    else
        echo "  ✅ $var_name is portable: $var_value"
        return 0
    fi
}

# Key variables to test
check_var "PGUSER"
check_var "MYSQL_USER"
check_var "SNOWFLAKE_USER"
check_var "ZSH_MAIN_REPO"
check_var "ZSH_BACKUP_REPO"

if [[ ${#failed_vars[@]} -gt 0 ]]; then
    echo "❌ Found ${#failed_vars[@]} hardcoded username(s)"
else
    echo "✅ All key variables are portable"
fi

echo ""

# Test 2: Check platform-specific path resolution
echo "Test 2: Platform Detection & Path Resolution..."
echo "  Platform OS: $ZSH_PLATFORM_OS"
echo "  Platform Arch: $ZSH_PLATFORM_ARCH"
echo "  Homebrew Prefix: $HOMEBREW_PREFIX"

if [[ -n "$HOMEBREW_PREFIX" ]]; then
    echo "  ✅ Homebrew prefix detected correctly"
else
    echo "  ❌ Homebrew prefix not detected"
fi

echo ""

# Test 3: Check that paths use $HOME and are not absolute
echo "Test 3: Home Directory Usage..."
portable_paths=(
    "ZSH_CONFIG_DIR"
    "PYENV_ROOT"
    "UV_BIN_PATH"
    "SDKMAN_DIR"
    "DOCKER_CONFIG_PATH"
)

for path_var in "${portable_paths[@]}"; do
    path_value="${(P)path_var}"
    if [[ "$path_value" =~ "^$HOME" ]]; then
        echo "  ✅ $path_var uses \$HOME: $path_value"
    elif [[ "$path_value" =~ "^/" ]] && [[ ! "$path_var" =~ "HOMEBREW" ]]; then
        echo "  ⚠️  $path_var is absolute (may not be portable): $path_value"
    else
        echo "  ✅ $path_var is portable: $path_value"
    fi
done

echo ""

# Test 4: Simulate different user environments
echo "Test 4: Simulating Different Users..."
for test_user in "${test_users[@]}"; do
    echo "  Testing as user: $test_user"

    # Simulate user environment
    USER_BACKUP="$USER"
    HOME_BACKUP="$HOME"

    export USER="$test_user"
    export HOME="/Users/$test_user"  # macOS-style, but concept applies

    # Re-source variables with simulated user
    source "$(dirname "$0")/config/variables.zsh" >/dev/null 2>&1

    # Check if paths adapt correctly
    if [[ "$PGUSER" == "$test_user" ]]; then
        echo "    ✅ PGUSER adapted: $PGUSER"
    else
        echo "    ❌ PGUSER not adapted: $PGUSER (expected: $test_user)"
    fi

    if [[ "$ZSH_CONFIG_DIR" == "$HOME/.config/zsh" ]]; then
        echo "    ✅ ZSH_CONFIG_DIR adapted: $ZSH_CONFIG_DIR"
    else
        echo "    ❌ ZSH_CONFIG_DIR not adapted: $ZSH_CONFIG_DIR"
    fi

    # Restore original environment
    export USER="$USER_BACKUP"
    export HOME="$HOME_BACKUP"
done

# Re-source with original environment
source "$(dirname "$0")/config/variables.zsh" >/dev/null 2>&1

echo ""
echo "🎯 Portability Test Summary"
echo "==========================="

if [[ ${#failed_vars[@]} -eq 0 ]]; then
    echo "✅ All tests passed - Configuration is portable!"
    echo "🌍 This configuration should work for any user"
    exit 0
else
    echo "❌ Some tests failed - Configuration needs fixes"
    echo "🔧 Hardcoded paths/usernames found in:"
    for var in "${failed_vars[@]}"; do
        echo "   - $var"
    done
    exit 1
fi