#!/usr/bin/env zsh

# =============================================================================
# Detailed Bash Compatibility Tests
# =============================================================================

# Source the test framework
source "$(dirname "$0")/../test-framework.zsh"

# =============================================================================
# Test: Bash Compatibility Layer Core Functions
# =============================================================================

test_bash_compatibility_core() {
    echo "Testing bash compatibility layer core functions..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    
    # Test shell detection
    local detected_shell
    detected_shell=$(detect_shell)
    assert_equal "zsh" "$detected_shell" "Should detect zsh shell"
    
    # Test platform detection
    local detected_platform
    detected_platform=$(detect_platform)
    assert_equal "macos" "$detected_platform" "Should detect macOS platform"
    
    # Test compatibility initialization
    init_compatibility
    assert_equal "zsh" "$CURRENT_SHELL" "CURRENT_SHELL should be zsh"
    assert_equal "macos" "$PLATFORM" "PLATFORM should be macos"
    assert_equal "true" "$IS_ZSH" "IS_ZSH should be true"
    assert_equal "false" "$IS_BASH" "IS_BASH should be false"
    
    echo "✅ bash compatibility layer core tests passed"
}

# =============================================================================
# Test: Python Manager Functions in Bash Mode
# =============================================================================

test_python_manager_bash_compatibility() {
    echo "Testing Python manager functions in bash compatibility mode..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test setup_python_manager
    setup_python_manager "pyenv"
    assert_equal "pyenv" "$PYTHON_MANAGER" "PYTHON_MANAGER should be set to pyenv"
    
    setup_python_manager "uv"
    assert_equal "uv" "$PYTHON_MANAGER" "PYTHON_MANAGER should be set to uv"
    
    setup_python_manager "auto"
    assert_equal "auto" "$PYTHON_MANAGER" "PYTHON_MANAGER should be set to auto"
    
    # Test setup_pyenv
    setup_pyenv
    assert_var_set "PYENV_ROOT" "PYENV_ROOT should be set"
    assert_equal "$HOME/.pyenv" "$PYENV_ROOT" "PYENV_ROOT should be ~/.pyenv"
    assert_contains "$PATH" "$PYENV_ROOT/bin" "PYENV_ROOT/bin should be in PATH"
    
    # Test setup_uv
    setup_uv
    # Function should run without errors
    local setup_output
    setup_output=$(setup_uv 2>&1)
    assert_not_contains "$setup_output" "error:" "UV setup should not have errors"
    
    # Test python_status
    local status_output
    status_output=$(python_status 2>&1)
    assert_not_contains "$status_output" "error:" "Python status should not have errors"
    assert_contains "$status_output" "Python Environment Status" "Status should contain header"
    
    echo "✅ Python manager bash compatibility tests passed"
}

# =============================================================================
# Test: Backup Functions in Bash Mode
# =============================================================================

test_backup_functions_bash_compatibility() {
    echo "Testing backup functions in bash compatibility mode..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test backup function
    local backup_output
    backup_output=$(backup "test bash compatibility backup" 2>&1)
    assert_not_contains "$backup_output" "error:" "Backup should not have errors"
    assert_contains "$backup_output" "Backup created:" "Backup should indicate creation"
    
    # Test deduplicate_path
    local original_path="$PATH"
    local test_path="/usr/bin:/usr/local/bin:/usr/bin:/opt/homebrew/bin:/usr/bin"
    PATH="$test_path"
    deduplicate_path
    local path_count=$(echo "$PATH" | tr ':' '\n' | sort | uniq -d | wc -l)
    assert_equal "0" "$path_count" "PATH should not contain duplicates"
    PATH="$original_path"
    
    echo "✅ backup functions bash compatibility tests passed"
}

# =============================================================================
# Test: Spark Functions in Bash Mode
# =============================================================================

test_spark_functions_bash_compatibility() {
    echo "Testing Spark functions in bash compatibility mode..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test setup_spark
    setup_spark
    assert_var_set "SPARK_HOME" "SPARK_HOME should be set"
    assert_contains "$PATH" "$SPARK_HOME/bin" "SPARK_HOME/bin should be in PATH"
    
    # Test show_spark_config
    local config_output
    config_output=$(show_spark_config 2>&1)
    assert_not_contains "$config_output" "error:" "Spark config should not have errors"
    assert_contains "$config_output" "Spark Configuration" "Config should contain header"
    
    echo "✅ Spark functions bash compatibility tests passed"
}

# =============================================================================
# Test: Environment Variable Consistency
# =============================================================================

test_environment_variable_consistency() {
    echo "Testing environment variable consistency..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test that all required environment variables are set
    assert_var_set "CURRENT_SHELL" "CURRENT_SHELL should be set"
    assert_var_set "PLATFORM" "PLATFORM should be set"
    assert_var_set "IS_ZSH" "IS_ZSH should be set"
    assert_var_set "IS_BASH" "IS_BASH should be set"
    assert_var_set "ZSHRC_CONFIG_DIR" "ZSHRC_CONFIG_DIR should be set"
    assert_var_set "ZSHRC_BACKUPS" "ZSHRC_BACKUPS should be set"
    
    # Test that values are consistent
    assert_equal "zsh" "$CURRENT_SHELL" "CURRENT_SHELL should be zsh"
    assert_equal "macos" "$PLATFORM" "PLATFORM should be macos"
    assert_equal "true" "$IS_ZSH" "IS_ZSH should be true"
    assert_equal "false" "$IS_BASH" "IS_BASH should be false"
    
    # Test that paths are set correctly
    assert_dir_exists "$ZSHRC_CONFIG_DIR" "ZSHRC_CONFIG_DIR should be a valid directory"
    assert_dir_exists "$ZSHRC_BACKUPS" "ZSHRC_BACKUPS should be a valid directory"
    
    echo "✅ environment variable consistency tests passed"
}

# =============================================================================
# Test: Function Availability
# =============================================================================

test_function_availability() {
    echo "Testing function availability..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test that all core functions are available
    local functions=(
        "setup_python_manager"
        "setup_pyenv"
        "setup_uv"
        "python_status"
        "setup_spark"
        "show_spark_config"
        "setup_hadoop"
        "show_hadoop_config"
        "setup_yarn"
        "show_yarn_config"
        "setup_jupyter"
        "jupyter_status"
        "backup"
        "deduplicate_path"
        "optimize_shell"
        "zsh_help"
        "validate_environment"
        "test_compatibility"
    )
    
    for func in "${functions[@]}"; do
        assert_command_success "type $func" "Function $func should be available"
    done
    
    echo "✅ function availability tests passed"
}

# =============================================================================
# Test: Cross-Shell Syntax Translation
# =============================================================================

test_cross_shell_syntax_translation() {
    echo "Testing cross-shell syntax translation..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test array handling (bash compatibility)
    local test_array=("item1" "item2" "item3")
    assert_equal "3" "${#test_array[@]}" "Array should have 3 items"
    assert_equal "item1" "${test_array[0]}" "First array item should be item1"
    
    # Test parameter expansion
    local test_var="test_value"
    assert_equal "test_value" "$test_var" "Variable should be accessible"
    
    # Test function execution
    local test_output
    test_output=$(test_compatibility 2>&1)
    assert_not_contains "$test_output" "error:" "Test compatibility should not have errors"
    
    echo "✅ cross-shell syntax translation tests passed"
}

# =============================================================================
# Test: Error Handling
# =============================================================================

test_bash_compatibility_error_handling() {
    echo "Testing bash compatibility error handling..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test that functions handle errors gracefully
    local error_output
    error_output=$(setup_python_manager "invalid_manager" 2>&1)
    assert_not_contains "$error_output" "fatal:" "Should handle invalid manager gracefully"
    
    # Test that functions don't crash on invalid input
    local backup_output
    backup_output=$(backup "" 2>&1)
    assert_not_contains "$backup_output" "fatal:" "Should handle empty backup message"
    
    echo "✅ bash compatibility error handling tests passed"
}

# =============================================================================
# Test: Performance
# =============================================================================

test_bash_compatibility_performance() {
    echo "Testing bash compatibility performance..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    
    # Test initialization performance
    local start_time=$(date +%s%N)
    init_compatibility
    local end_time=$(date +%s%N)
    local duration=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds
    
    # Should initialize in less than 100ms
    assert_true "[[ $duration -lt 100 ]]" "Compatibility initialization should be fast (< 100ms)"
    
    # Test function execution performance
    start_time=$(date +%s%N)
    setup_python_manager "auto"
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 ))
    
    # Should execute in less than 50ms
    assert_true "[[ $duration -lt 50 ]]" "Function execution should be fast (< 50ms)"
    
    echo "✅ bash compatibility performance tests passed"
}

# =============================================================================
# Test: Memory Usage
# =============================================================================

test_bash_compatibility_memory_usage() {
    echo "Testing bash compatibility memory usage..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test that environment variables don't consume excessive memory
    local env_count
    env_count=$(env | grep -c "ZSHRC\|PYTHON\|SPARK\|HADOOP\|JUPYTER" || echo "0")
    assert_true "[[ $env_count -gt 0 ]]" "Should have environment variables set"
    assert_true "[[ $env_count -lt 100 ]]" "Should not have excessive environment variables"
    
    echo "✅ bash compatibility memory usage tests passed"
}

# =============================================================================
# Test: Compatibility Validation
# =============================================================================

test_compatibility_validation() {
    echo "Testing compatibility validation..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test validate_environment function
    local validation_output
    validation_output=$(validate_environment 2>&1)
    assert_not_contains "$validation_output" "error:" "Environment validation should not have errors"
    
    # Test test_compatibility function
    local test_output
    test_output=$(test_compatibility 2>&1)
    assert_not_contains "$test_output" "error:" "Compatibility test should not have errors"
    assert_contains "$test_output" "Testing shell compatibility" "Test should contain header"
    
    echo "✅ compatibility validation tests passed"
}

# =============================================================================
# Register Tests
# =============================================================================

register_test "test_bash_compatibility_core" "test_bash_compatibility_core"
register_test "test_python_manager_bash_compatibility" "test_python_manager_bash_compatibility"
register_test "test_backup_functions_bash_compatibility" "test_backup_functions_bash_compatibility"
register_test "test_spark_functions_bash_compatibility" "test_spark_functions_bash_compatibility"
register_test "test_environment_variable_consistency" "test_environment_variable_consistency"
register_test "test_function_availability" "test_function_availability"
register_test "test_cross_shell_syntax_translation" "test_cross_shell_syntax_translation"
register_test "test_bash_compatibility_error_handling" "test_bash_compatibility_error_handling"
register_test "test_bash_compatibility_performance" "test_bash_compatibility_performance"
register_test "test_bash_compatibility_memory_usage" "test_bash_compatibility_memory_usage"
register_test "test_compatibility_validation" "test_compatibility_validation"
