#!/usr/bin/env zsh

# =============================================================================
# Bash Compatibility Functions Unit Tests
# =============================================================================

# Source the test framework
source "$(dirname "$0")/../test-framework.zsh"

# Source the functions to test
source "$(dirname "$0")/../bash-compatibility.zsh"

# =============================================================================
# Test: detect_shell
# =============================================================================

test_detect_shell() {
    echo "Testing detect_shell function..."
    
    # Test shell detection
    local detected_shell
    detected_shell=$(detect_shell)
    
    # Should detect zsh (since we're running in zsh)
    assert_equal "zsh" "$detected_shell" "Should detect zsh shell"
    
    echo "✅ detect_shell tests passed"
}

# =============================================================================
# Test: detect_platform
# =============================================================================

test_detect_platform() {
    echo "Testing detect_platform function..."
    
    # Test platform detection
    local detected_platform
    detected_platform=$(detect_platform)
    
    # Should detect macOS (since we're on macOS)
    assert_equal "macos" "$detected_platform" "Should detect macOS platform"
    
    echo "✅ detect_platform tests passed"
}

# =============================================================================
# Test: init_compatibility
# =============================================================================

test_init_compatibility() {
    echo "Testing init_compatibility function..."
    
    # Test compatibility initialization
    local init_output
    init_output=$(init_compatibility 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$init_output" "error:" "Init should not have errors"
    
    # Test that environment variables are set
    assert_var_set "CURRENT_SHELL" "CURRENT_SHELL should be set"
    assert_var_set "PLATFORM" "PLATFORM should be set"
    assert_var_set "IS_ZSH" "IS_ZSH should be set"
    assert_var_set "IS_BASH" "IS_BASH should be set"
    
    # Test that values are correct for zsh
    assert_equal "zsh" "$CURRENT_SHELL" "CURRENT_SHELL should be zsh"
    assert_equal "macos" "$PLATFORM" "PLATFORM should be macos"
    assert_equal "true" "$IS_ZSH" "IS_ZSH should be true"
    assert_equal "false" "$IS_BASH" "IS_BASH should be false"
    
    echo "✅ init_compatibility tests passed"
}

# =============================================================================
# Test: setup_python_manager (bash compatibility version)
# =============================================================================

test_setup_python_manager_compatibility() {
    echo "Testing setup_python_manager compatibility function..."
    
    # Test Python manager setup
    setup_python_manager "pyenv"
    
    # Test that PYTHON_MANAGER is set
    assert_var_set "PYTHON_MANAGER" "PYTHON_MANAGER should be set"
    assert_equal "pyenv" "$PYTHON_MANAGER" "PYTHON_MANAGER should be pyenv"
    
    echo "✅ setup_python_manager compatibility tests passed"
}

# =============================================================================
# Test: setup_pyenv (bash compatibility version)
# =============================================================================

test_setup_pyenv_compatibility() {
    echo "Testing setup_pyenv compatibility function..."
    
    # Test pyenv setup
    setup_pyenv
    
    # Test that PYENV_ROOT is set
    assert_var_set "PYENV_ROOT" "PYENV_ROOT should be set"
    assert_equal "$HOME/.pyenv" "$PYENV_ROOT" "PYENV_ROOT should be ~/.pyenv"
    
    # Test that PYENV_ROOT is in PATH
    assert_contains "$PATH" "$PYENV_ROOT/bin" "PYENV_ROOT/bin should be in PATH"
    
    echo "✅ setup_pyenv compatibility tests passed"
}

# =============================================================================
# Test: setup_uv (bash compatibility version)
# =============================================================================

test_setup_uv_compatibility() {
    echo "Testing setup_uv compatibility function..."
    
    # Test uv setup
    setup_uv
    
    # Test that function runs without errors
    local setup_output
    setup_output=$(setup_uv 2>&1)
    assert_not_contains "$setup_output" "error:" "UV setup should not have errors"
    
    echo "✅ setup_uv compatibility tests passed"
}

# =============================================================================
# Test: python_status (bash compatibility version)
# =============================================================================

test_python_status_compatibility() {
    echo "Testing python_status compatibility function..."
    
    # Test Python status function
    local status_output
    status_output=$(python_status 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$status_output" "error:" "Python status should not have errors"
    
    # Test that output contains expected information
    assert_contains "$status_output" "Python Environment Status" "Status should contain header"
    
    echo "✅ python_status compatibility tests passed"
}

# =============================================================================
# Test: backup (bash compatibility version)
# =============================================================================

test_backup_compatibility() {
    echo "Testing backup compatibility function..."
    
    # Test backup function
    local backup_output
    backup_output=$(backup "test compatibility backup" 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$backup_output" "error:" "Backup should not have errors"
    
    # Test that backup was created
    assert_contains "$backup_output" "Backup created:" "Backup should indicate creation"
    
    echo "✅ backup compatibility tests passed"
}

# =============================================================================
# Test: setup_spark (bash compatibility version)
# =============================================================================

test_setup_spark_compatibility() {
    echo "Testing setup_spark compatibility function..."
    
    # Test Spark setup
    setup_spark
    
    # Test that SPARK_HOME is set
    assert_var_set "SPARK_HOME" "SPARK_HOME should be set"
    
    # Test that SPARK_HOME is in PATH
    assert_contains "$PATH" "$SPARK_HOME/bin" "SPARK_HOME/bin should be in PATH"
    
    echo "✅ setup_spark compatibility tests passed"
}

# =============================================================================
# Test: show_spark_config (bash compatibility version)
# =============================================================================

test_show_spark_config_compatibility() {
    echo "Testing show_spark_config compatibility function..."
    
    # Test Spark config display
    local config_output
    config_output=$(show_spark_config 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$config_output" "error:" "Spark config should not have errors"
    
    # Test that output contains expected information
    assert_contains "$config_output" "Spark Configuration" "Config should contain header"
    
    echo "✅ show_spark_config compatibility tests passed"
}

# =============================================================================
# Test: deduplicate_path (bash compatibility version)
# =============================================================================

test_deduplicate_path_compatibility() {
    echo "Testing deduplicate_path compatibility function..."
    
    # Test PATH deduplication
    local original_path="$PATH"
    local test_path="/usr/bin:/usr/local/bin:/usr/bin:/opt/homebrew/bin:/usr/bin"
    
    # Set test PATH
    PATH="$test_path"
    
    # Run deduplication
    deduplicate_path
    
    # Test that duplicates are removed
    local path_count=$(echo "$PATH" | tr ':' '\n' | sort | uniq -d | wc -l)
    assert_equal "0" "$path_count" "PATH should not contain duplicates"
    
    # Restore original PATH
    PATH="$original_path"
    
    echo "✅ deduplicate_path compatibility tests passed"
}

# =============================================================================
# Test: optimize_shell
# =============================================================================

test_optimize_shell() {
    echo "Testing optimize_shell function..."
    
    # Test shell optimization
    local optimize_output
    optimize_output=$(optimize_shell 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$optimize_output" "error:" "Shell optimization should not have errors"
    
    echo "✅ optimize_shell tests passed"
}

# =============================================================================
# Test: zsh_help (bash compatibility version)
# =============================================================================

test_zsh_help_compatibility() {
    echo "Testing zsh_help compatibility function..."
    
    # Test help function
    local help_output
    help_output=$(zsh_help 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$help_output" "error:" "Help should not have errors"
    
    # Test that output contains expected information
    assert_contains "$help_output" "Siege Analytics Configuration" "Help should contain header"
    
    echo "✅ zsh_help compatibility tests passed"
}

# =============================================================================
# Test: validate_environment
# =============================================================================

test_validate_environment() {
    echo "Testing validate_environment function..."
    
    # Test environment validation
    local validation_output
    validation_output=$(validate_environment 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$validation_output" "error:" "Environment validation should not have errors"
    
    echo "✅ validate_environment tests passed"
}

# =============================================================================
# Test: test_compatibility
# =============================================================================

test_test_compatibility() {
    echo "Testing test_compatibility function..."
    
    # Test compatibility testing function
    local test_output
    test_output=$(test_compatibility 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$test_output" "error:" "Compatibility test should not have errors"
    
    # Test that output contains expected information
    assert_contains "$test_output" "Testing shell compatibility" "Test should contain header"
    
    echo "✅ test_compatibility tests passed"
}

# =============================================================================
# Test: Environment Variables
# =============================================================================

test_compatibility_environment_variables() {
    echo "Testing compatibility environment variables..."
    
    # Test that required environment variables are set after initialization
    init_compatibility
    
    assert_var_set "CURRENT_SHELL" "CURRENT_SHELL should be set"
    assert_var_set "PLATFORM" "PLATFORM should be set"
    assert_var_set "IS_ZSH" "IS_ZSH should be set"
    assert_var_set "IS_BASH" "IS_BASH should be set"
    assert_var_set "ZSHRC_CONFIG_DIR" "ZSHRC_CONFIG_DIR should be set"
    assert_var_set "ZSHRC_BACKUPS" "ZSHRC_BACKUPS should be set"
    
    echo "✅ compatibility environment variables tests passed"
}

# =============================================================================
# Register Tests
# =============================================================================

register_test "test_detect_shell" "test_detect_shell"
register_test "test_detect_platform" "test_detect_platform"
register_test "test_init_compatibility" "test_init_compatibility"
register_test "test_setup_python_manager_compatibility" "test_setup_python_manager_compatibility"
register_test "test_setup_pyenv_compatibility" "test_setup_pyenv_compatibility"
register_test "test_setup_uv_compatibility" "test_setup_uv_compatibility"
register_test "test_python_status_compatibility" "test_python_status_compatibility"
register_test "test_backup_compatibility" "test_backup_compatibility"
register_test "test_setup_spark_compatibility" "test_setup_spark_compatibility"
register_test "test_show_spark_config_compatibility" "test_show_spark_config_compatibility"
register_test "test_deduplicate_path_compatibility" "test_deduplicate_path_compatibility"
register_test "test_optimize_shell" "test_optimize_shell"
register_test "test_zsh_help_compatibility" "test_zsh_help_compatibility"
register_test "test_validate_environment" "test_validate_environment"
register_test "test_test_compatibility" "test_test_compatibility"
register_test "test_compatibility_environment_variables" "test_compatibility_environment_variables"
