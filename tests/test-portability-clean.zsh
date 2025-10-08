#!/usr/bin/env zsh

# =====================================================
# CLEAN CROSS-USER PORTABILITY TEST
# =====================================================
#
# Test script that simulates a clean user environment
# without any user-specific configuration files.
#
# Usage: ./test-portability-clean.zsh
# =====================================================

echo "🔍 Testing Clean Cross-User Portability"
echo "======================================="
echo ""

# Test users to simulate
test_users=("alice" "bob" "charlie" "newuser")
current_user="$USER"

echo "📊 Original user: $current_user"
echo ""

# Function to test a simulated user environment
test_user_environment() {
    local test_user="$1"
    echo "🧪 Testing as user: $test_user"
    echo "-----------------------------"

    # Backup original environment
    local USER_BACKUP="$USER"
    local HOME_BACKUP="$HOME"

    # Simulate new user environment
    export USER="$test_user"
    export HOME="/Users/$test_user"

    # Backup any user-specific config that might interfere
    local user_config_exists=false
    if [[ -f "$HOME/.zsh_user_config" ]]; then
        user_config_exists=true
        mv "$HOME/.zsh_user_config" "$HOME/.zsh_user_config.backup" 2>/dev/null || true
    fi

    # Clear environment variables that might be set
    unset PGUSER MYSQL_USER SNOWFLAKE_USER ZSH_REPO_OWNER ZSH_MAIN_REPO ZSH_BACKUP_REPO

    # Source variables in clean environment
    source "$(dirname "$0")/config/variables.zsh" >/dev/null 2>&1

    # Test results
    local failed_tests=0

    # Test 1: Database users should use system username
    if [[ "$PGUSER" == "$test_user" ]]; then
        echo "  ✅ PGUSER correctly uses system user: $PGUSER"
    else
        echo "  ❌ PGUSER should be $test_user but is: $PGUSER"
        ((failed_tests++))
    fi

    if [[ "$MYSQL_USER" == "$test_user" ]]; then
        echo "  ✅ MYSQL_USER correctly uses system user: $MYSQL_USER"
    else
        echo "  ❌ MYSQL_USER should be $test_user but is: $MYSQL_USER"
        ((failed_tests++))
    fi

    # Test 2: Repository URLs should use system username
    expected_main_repo="https://github.com/$test_user/siege_analytics_zshrc"
    if [[ "$ZSH_MAIN_REPO" == "$expected_main_repo" ]]; then
        echo "  ✅ ZSH_MAIN_REPO correctly uses system user: $ZSH_MAIN_REPO"
    else
        echo "  ❌ ZSH_MAIN_REPO should be $expected_main_repo but is: $ZSH_MAIN_REPO"
        ((failed_tests++))
    fi

    # Test 3: Home directory paths should adapt
    expected_config_dir="$HOME/.config/zsh"
    if [[ "$ZSH_CONFIG_DIR" == "$expected_config_dir" ]]; then
        echo "  ✅ ZSH_CONFIG_DIR correctly adapts: $ZSH_CONFIG_DIR"
    else
        echo "  ❌ ZSH_CONFIG_DIR should be $expected_config_dir but is: $ZSH_CONFIG_DIR"
        ((failed_tests++))
    fi

    # Test 4: Platform detection should still work
    if [[ -n "$HOMEBREW_PREFIX" ]]; then
        echo "  ✅ Platform detection works: HOMEBREW_PREFIX=$HOMEBREW_PREFIX"
    else
        echo "  ❌ Platform detection failed: HOMEBREW_PREFIX not set"
        ((failed_tests++))
    fi

    # Restore environment
    export USER="$USER_BACKUP"
    export HOME="$HOME_BACKUP"

    # Restore user config if it existed
    if [[ "$user_config_exists" == "true" ]]; then
        mv "$HOME_BACKUP/.zsh_user_config.backup" "$HOME_BACKUP/.zsh_user_config" 2>/dev/null || true
    fi

    echo "  📊 Result: $failed_tests test(s) failed for user $test_user"
    echo ""

    return $failed_tests
}

# Run tests for each simulated user
total_failures=0
for user in "${test_users[@]}"; do
    test_user_environment "$user"
    total_failures=$((total_failures + $?))
done

# Final summary
echo "🎯 Clean Portability Test Summary"
echo "================================="

if [[ $total_failures -eq 0 ]]; then
    echo "✅ ALL TESTS PASSED - Configuration is truly portable!"
    echo "🌍 New users can use this configuration without modification"
    echo ""
    echo "💡 Current user ($current_user) has custom settings in ~/.zsh_user_config"
    echo "   which is the correct way to override defaults while maintaining portability"
    exit 0
else
    echo "❌ $total_failures test(s) failed - Configuration needs fixes"
    echo "🔧 The configuration may not work correctly for new users"
    exit 1
fi