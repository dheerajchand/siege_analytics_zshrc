# =====================================================
# CONFIGURATION SCRIPT TESTS
# =====================================================

# Test the configure-shell.sh script functionality
# This test suite validates all aspects of the configuration script

# Test configuration
TEST_SCRIPT_PATH="$ZSHRC_CONFIG_DIR/configure-shell.sh"
TEST_TEMP_DIR="/tmp/shell-config-test-$$"
TEST_ENV_FILE="$TEST_TEMP_DIR/.shell-config-env"

# Setup test environment
function setup_config_test {
    echo "🧪 Setting up configuration script tests..."
    
    # Create temporary directory
    mkdir -p "$TEST_TEMP_DIR"
    
    # Check if script exists
    if [[ ! -f "$TEST_SCRIPT_PATH" ]]; then
        echo "❌ Configuration script not found: $TEST_SCRIPT_PATH"
        return 1
    fi
    
    # Make script executable
    chmod +x "$TEST_SCRIPT_PATH"
    
    echo "✅ Test environment setup complete"
    return 0
}

# Test help functionality
function test_config_help {
    echo "🧪 Testing help functionality..."
    
    if "$TEST_SCRIPT_PATH" --help > /dev/null 2>&1; then
        echo "✅ Help functionality works"
        return 0
    else
        echo "❌ Help functionality failed"
        return 1
    fi
}

# Test validation
function test_config_validation {
    echo "🧪 Testing validation..."
    
    # Test invalid mode
    if "$TEST_SCRIPT_PATH" --mode invalid 2>&1 | grep -q "Invalid mode"; then
        echo "✅ Invalid mode validation works"
    else
        echo "❌ Invalid mode validation failed"
        return 1
    fi
    
    # Test invalid shell
    if "$TEST_SCRIPT_PATH" --shell invalid 2>&1 | grep -q "Invalid shell"; then
        echo "✅ Invalid shell validation works"
    else
        echo "❌ Invalid shell validation failed"
        return 1
    fi
    
    return 0
}

# Test environment setup
function test_config_env_setup {
    echo "🧪 Testing environment setup..."
    
    # Test environment setup (non-interactive)
    if "$TEST_SCRIPT_PATH" --mode standalone --setup-env 2>&1 | grep -q "Environment setup complete"; then
        echo "✅ Environment setup works"
    else
        echo "❌ Environment setup failed"
        return 1
    fi
    
    # Check if environment file was created
    if [[ -f "$HOME/.shell-config-env" ]]; then
        echo "✅ Environment file created"
    else
        echo "❌ Environment file not created"
        return 1
    fi
    
    # Check if environment variables are set
    source "$HOME/.shell-config-env"
    if [[ -n "$SHELL_CONFIG_MODE" ]]; then
        echo "✅ Environment variables set"
    else
        echo "❌ Environment variables not set"
        return 1
    fi
    
    return 0
}

# Test personal defaults
function test_config_personal_defaults {
    echo "🧪 Testing personal defaults..."
    
    # Test personal mode (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --personal --force 2>&1 | grep -q "Mode: symlink"; then
        echo "✅ Personal defaults work"
    else
        echo "❌ Personal defaults failed"
        return 1
    fi
    
    return 0
}

# Test different modes
function test_config_modes {
    echo "🧪 Testing different modes..."
    
    # Test standalone mode (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --mode standalone --force 2>&1 | grep -q "Mode: standalone"; then
        echo "✅ Standalone mode works"
    else
        echo "❌ Standalone mode failed"
        return 1
    fi
    
    # Test copy mode (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --mode copy --force 2>&1 | grep -q "Mode: copy"; then
        echo "✅ Copy mode works"
    else
        echo "❌ Copy mode failed"
        return 1
    fi
    
    # Test symlink mode (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --mode symlink --target "$TEST_TEMP_DIR" --force 2>&1 | grep -q "Mode: symlink"; then
        echo "✅ Symlink mode works"
    else
        echo "❌ Symlink mode failed"
        return 1
    fi
    
    return 0
}

# Test shell options
function test_config_shell_options {
    echo "🧪 Testing shell options..."
    
    # Test zsh only (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --shell zsh --force 2>&1 | grep -q "Shell: zsh"; then
        echo "✅ Zsh-only option works"
    else
        echo "❌ Zsh-only option failed"
        return 1
    fi
    
    # Test bash only (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --shell bash --force 2>&1 | grep -q "Shell: bash"; then
        echo "✅ Bash-only option works"
    else
        echo "❌ Bash-only option failed"
        return 1
    fi
    
    # Test both shells (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --shell both --force 2>&1 | grep -q "Shell: both"; then
        echo "✅ Both shells option works"
    else
        echo "❌ Both shells option failed"
        return 1
    fi
    
    return 0
}

# Test backup functionality
function test_config_backup {
    echo "🧪 Testing backup functionality..."
    
    # Test backup creation (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --mode standalone --backup --force 2>&1 | grep -q "Created backup"; then
        echo "✅ Backup functionality works"
    else
        echo "❌ Backup functionality failed"
        return 1
    fi
    
    return 0
}

# Test force option
function test_config_force {
    echo "🧪 Testing force option..."
    
    # Test force mode (non-interactive)
    if "$TEST_SCRIPT_PATH" --mode standalone --force 2>&1 | grep -q "Force: true"; then
        echo "✅ Force option works"
    else
        echo "❌ Force option failed"
        return 1
    fi
    
    return 0
}

# Test environment variable integration
function test_config_env_integration {
    echo "🧪 Testing environment variable integration..."
    
    # Test with environment variables (non-interactive with --force)
    if SHELL_CONFIG_MODE=copy "$TEST_SCRIPT_PATH" --force 2>&1 | grep -q "Mode: copy"; then
        echo "✅ Environment variable integration works"
    else
        echo "❌ Environment variable integration failed"
        return 1
    fi
    
    return 0
}

# Test error handling
function test_config_error_handling {
    echo "🧪 Testing error handling..."
    
    # Test missing script
    if [[ ! -f "$TEST_SCRIPT_PATH" ]]; then
        echo "❌ Script not found - cannot test error handling"
        return 1
    fi
    
    # Test invalid arguments
    if "$TEST_SCRIPT_PATH" --invalid-option 2>&1 | grep -q "Unknown option"; then
        echo "✅ Error handling works"
    else
        echo "❌ Error handling failed"
        return 1
    fi
    
    return 0
}

# Test file operations
function test_config_file_operations {
    echo "🧪 Testing file operations..."
    
    # Test symlink creation (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --mode symlink --target "$TEST_TEMP_DIR" --force 2>&1 | grep -q "Created symlink"; then
        echo "✅ Symlink creation works"
    else
        echo "❌ Symlink creation failed"
        return 1
    fi
    
    # Test file copying (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --mode copy --force 2>&1 | grep -q "Copied"; then
        echo "✅ File copying works"
    else
        echo "❌ File copying failed"
        return 1
    fi
    
    return 0
}

# Test configuration summary
function test_config_summary {
    echo "🧪 Testing configuration summary..."
    
    # Test summary display (non-interactive with --force)
    if "$TEST_SCRIPT_PATH" --mode standalone --force 2>&1 | grep -q "Configuration Summary"; then
        echo "✅ Configuration summary works"
    else
        echo "❌ Configuration summary failed"
        return 1
    fi
    
    return 0
}

# Test confirmation logic
function test_config_confirmation {
    echo "🧪 Testing confirmation logic..."
    
    # Test that --force bypasses confirmation
    if "$TEST_SCRIPT_PATH" --mode standalone --force 2>&1 | grep -q "Force: true"; then
        echo "✅ Force option bypasses confirmation"
    else
        echo "❌ Force option failed"
        return 1
    fi
    
    # Test that cancellation works (the prompt might not be captured in output)
    local test_output
    test_output=$(echo -e "n" | "$TEST_SCRIPT_PATH" --mode standalone 2>&1)
    if echo "$test_output" | grep -q "Configuration cancelled"; then
        echo "✅ Confirmation cancellation works"
    else
        echo "❌ Confirmation cancellation failed"
        return 1
    fi
    
    return 0
}

# Test edge cases and error conditions
function test_config_edge_cases {
    echo "🧪 Testing edge cases..."
    
    # Test with empty target path (should auto-detect, non-interactive)
    local test_output
    test_output=$(echo -e "n\nn" | "$TEST_SCRIPT_PATH" --mode symlink --target "" 2>&1)
    if echo "$test_output" | grep -q "Target Path:"; then
        echo "✅ Empty target path auto-detection works"
    else
        echo "❌ Empty target path auto-detection failed"
        return 1
    fi
    
    # Test with non-existent target (should prompt to create, then cancel)
    test_output=$(echo -e "n\nn" | "$TEST_SCRIPT_PATH" --mode symlink --target "/nonexistent/path" 2>&1)
    if echo "$test_output" | grep -q "Target path does not exist"; then
        echo "✅ Non-existent target validation works"
    else
        echo "❌ Non-existent target validation failed"
        return 1
    fi
    
    # Test invalid mode (non-interactive)
    test_output=$("$TEST_SCRIPT_PATH" --mode invalid 2>&1)
    if echo "$test_output" | grep -q "Invalid mode"; then
        echo "✅ Invalid mode validation works"
    else
        echo "❌ Invalid mode validation failed"
        return 1
    fi
    
    # Test invalid shell (non-interactive)
    test_output=$("$TEST_SCRIPT_PATH" --shell invalid 2>&1)
    if echo "$test_output" | grep -q "Invalid shell"; then
        echo "✅ Invalid shell validation works"
    else
        echo "❌ Invalid shell validation failed"
        return 1
    fi
    
    return 0
}

# Cleanup test environment
function cleanup_config_test {
    echo "🧹 Cleaning up test environment..."
    
    # Remove temporary directory
    rm -rf "$TEST_TEMP_DIR"
    
    # Remove test environment file if it exists
    if [[ -f "$TEST_ENV_FILE" ]]; then
        rm -f "$TEST_ENV_FILE"
    fi
    
    echo "✅ Test cleanup complete"
}

# Main test function
function test_configuration_script {
    echo "🧪 Testing Configuration Script"
    echo "==============================="
    
    local test_results=()
    local total_tests=0
    local passed_tests=0
    
    # Setup
    if ! setup_config_test; then
        echo "❌ Test setup failed"
        return 1
    fi
    
    # Run tests
    local tests=(
        "test_config_help"
        "test_config_validation"
        "test_config_env_setup"
        "test_config_personal_defaults"
        "test_config_modes"
        "test_config_shell_options"
        "test_config_backup"
        "test_config_force"
        "test_config_env_integration"
        "test_config_error_handling"
        "test_config_file_operations"
        "test_config_summary"
        "test_config_confirmation"
        "test_config_edge_cases"
    )
    
    for test in "${tests[@]}"; do
        echo ""
        total_tests=$((total_tests + 1))
        if $test; then
            test_results+=("✅ $test")
            passed_tests=$((passed_tests + 1))
        else
            test_results+=("❌ $test")
        fi
    done
    
    # Cleanup
    cleanup_config_test
    
    # Show results
    echo ""
    echo "📊 Test Results"
    echo "==============="
    for result in "${test_results[@]}"; do
        echo "$result"
    done
    
    echo ""
    echo "📈 Summary: $passed_tests/$total_tests tests passed"
    
    if [[ $passed_tests -eq $total_tests ]]; then
        echo "🎉 All configuration script tests passed!"
        return 0
    else
        echo "⚠️  Some tests failed"
        return 1
    fi
}

# Test function is ready to use
# Usage: source tests/test-configuration-script.zsh && test_configuration_script
