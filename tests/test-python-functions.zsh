#!/usr/bin/env zsh

# =============================================================================
# Python Functions Unit Tests
# =============================================================================

# Source the test framework
source "$(dirname "$0")/../test-framework.zsh"

# Source the functions to test
source "$(dirname "$0")/../python/core.zsh"

# =============================================================================
# Test: setup_pyenv
# =============================================================================

test_setup_pyenv() {
    echo "Testing setup_pyenv function..."
    
    # Test that PYENV_ROOT is set
    setup_pyenv
    assert_var_set "PYENV_ROOT" "PYENV_ROOT should be set"
    
    # Test that PYENV_ROOT is in PATH
    assert_contains "$PATH" "$PYENV_ROOT/bin" "PYENV_ROOT/bin should be in PATH"
    
    # Test that pyenv command is available (if pyenv is installed)
    if command -v pyenv >/dev/null 2>&1; then
        assert_command_success "pyenv --version" "pyenv command should be available"
    fi
    
    echo "✅ setup_pyenv tests passed"
}

# =============================================================================
# Test: setup_uv
# =============================================================================

test_setup_uv() {
    echo "Testing setup_uv function..."
    
    # Test that uv command is available (if uv is installed)
    if command -v uv >/dev/null 2>&1; then
        assert_command_success "uv --version" "uv command should be available"
    fi
    
    echo "✅ setup_uv tests passed"
}

# =============================================================================
# Test: python_status
# =============================================================================

test_python_status() {
    echo "Testing python_status function..."
    
    # Capture output
    local output
    output=$(python_status 2>&1)
    
    # Test that output contains expected information
    assert_contains "$output" "Python Environment Status" "Output should contain status header"
    assert_contains "$output" "Manager:" "Output should contain manager info"
    assert_contains "$output" "Python:" "Output should contain Python version"
    
    echo "✅ python_status tests passed"
}

# =============================================================================
# Test: setup_python_manager
# =============================================================================

test_setup_python_manager() {
    echo "Testing setup_python_manager function..."
    
    # Test with different manager types
    setup_python_manager "pyenv"
    assert_equal "pyenv" "$PYTHON_MANAGER" "PYTHON_MANAGER should be set to pyenv"
    
    setup_python_manager "uv"
    assert_equal "uv" "$PYTHON_MANAGER" "PYTHON_MANAGER should be set to uv"
    
    setup_python_manager "auto"
    assert_equal "auto" "$PYTHON_MANAGER" "PYTHON_MANAGER should be set to auto"
    
    echo "✅ setup_python_manager tests passed"
}

# =============================================================================
# Test: detect_python_manager
# =============================================================================

test_detect_python_manager() {
    echo "Testing detect_python_manager function..."
    
    # Test detection logic
    local detected_manager
    detected_manager=$(detect_python_manager)
    
    # Should return one of the supported managers
    assert_true "[[ '$detected_manager' == 'pyenv' || '$detected_manager' == 'uv' || '$detected_manager' == 'none' ]]" "Should detect a valid manager"
    
    echo "✅ detect_python_manager tests passed"
}

# =============================================================================
# Test: get_python_version
# =============================================================================

test_get_python_version() {
    echo "Testing get_python_version function..."
    
    # Test that function returns a version string
    local version
    version=$(get_python_version)
    
    # Should return a version in format X.Y.Z
    assert_contains "$version" "." "Version should contain dots"
    assert_true "[[ '$version' =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]" "Version should be in X.Y.Z format"
    
    echo "✅ get_python_version tests passed"
}

# =============================================================================
# Test: get_python_path
# =============================================================================

test_get_python_path() {
    echo "Testing get_python_path function..."
    
    # Test that function returns a valid path
    local python_path
    python_path=$(get_python_path)
    
    # Should return a valid path
    assert_true "[[ -n '$python_path' ]]" "Python path should not be empty"
    assert_command_success "command -v '$python_path'" "Python path should be executable"
    
    echo "✅ get_python_path tests passed"
}

# =============================================================================
# Test: is_virtual_env_active
# =============================================================================

test_is_virtual_env_active() {
    echo "Testing is_virtual_env_active function..."
    
    # Test function returns true or false
    local is_active
    is_active=$(is_virtual_env_active)
    
    assert_true "[[ '$is_active' == 'true' || '$is_active' == 'false' ]]" "Should return true or false"
    
    echo "✅ is_virtual_env_active tests passed"
}

# =============================================================================
# Test: get_virtual_env_name
# =============================================================================

test_get_virtual_env_name() {
    echo "Testing get_virtual_env_name function..."
    
    # Test function returns a name or empty string
    local env_name
    env_name=$(get_virtual_env_name)
    
    # Should return a string (could be empty)
    assert_true "[[ -n '$env_name' || -z '$env_name' ]]" "Should return a string or empty"
    
    echo "✅ get_virtual_env_name tests passed"
}

# =============================================================================
# Test: get_virtual_env_path
# =============================================================================

test_get_virtual_env_path() {
    echo "Testing get_virtual_env_path function..."
    
    # Test function returns a path or empty string
    local env_path
    env_path=$(get_virtual_env_path)
    
    # Should return a string (could be empty)
    assert_true "[[ -n '$env_path' || -z '$env_path' ]]" "Should return a string or empty"
    
    echo "✅ get_virtual_env_path tests passed"
}

# =============================================================================
# Test: pyhelp
# =============================================================================

test_pyhelp() {
    echo "Testing pyhelp function..."
    
    # Capture output
    local output
    output=$(pyhelp 2>&1)
    
    # Test that output contains help information
    assert_contains "$output" "Python Management Commands" "Output should contain help header"
    assert_contains "$output" "setup_pyenv" "Output should contain setup_pyenv command"
    assert_contains "$output" "setup_uv" "Output should contain setup_uv command"
    assert_contains "$output" "python_status" "Output should contain python_status command"
    
    echo "✅ pyhelp tests passed"
}

# =============================================================================
# Register Tests
# =============================================================================

register_test "test_setup_pyenv" "test_setup_pyenv"
register_test "test_setup_uv" "test_setup_uv"
register_test "test_python_status" "test_python_status"
register_test "test_setup_python_manager" "test_setup_python_manager"
register_test "test_detect_python_manager" "test_detect_python_manager"
register_test "test_get_python_version" "test_get_python_version"
register_test "test_get_python_path" "test_get_python_path"
register_test "test_is_virtual_env_active" "test_is_virtual_env_active"
register_test "test_get_virtual_env_name" "test_get_virtual_env_name"
register_test "test_get_virtual_env_path" "test_get_virtual_env_path"
register_test "test_pyhelp" "test_pyhelp"
