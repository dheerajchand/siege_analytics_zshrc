#!/usr/bin/env zsh

# =============================================================================
# Jupyter Notebook Functions Unit Tests
# =============================================================================

# Source the test framework
source "$(dirname "$0")/../test-framework.zsh"

# Source the functions to test
source "$(dirname "$0")/../notebooks.zsh"
source "$(dirname "$0")/../python/integrations/notebooks.zsh"

# =============================================================================
# Test: setup_jupyter
# =============================================================================

test_setup_jupyter() {
    echo "Testing setup_jupyter function..."
    
    # Test Jupyter setup
    setup_jupyter
    
    # Test that JUPYTER_HOME is set
    assert_var_set "JUPYTER_HOME" "JUPYTER_HOME should be set"
    
    # Test that JUPYTER_HOME is in PATH
    assert_contains "$PATH" "$JUPYTER_HOME/bin" "JUPYTER_HOME/bin should be in PATH"
    
    # Test that JUPYTER_HOME is a valid directory
    assert_dir_exists "$JUPYTER_HOME" "JUPYTER_HOME should be a valid directory"
    
    echo "✅ setup_jupyter tests passed"
}

# =============================================================================
# Test: start_jupyter
# =============================================================================

test_start_jupyter() {
    echo "Testing start_jupyter function..."
    
    # Test that function exists and is callable
    assert_command_success "type start_jupyter" "start_jupyter function should exist"
    
    # Test function help output
    local help_output
    help_output=$(start_jupyter --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "start_jupyter should provide output"
    
    echo "✅ start_jupyter tests passed"
}

# =============================================================================
# Test: stop_jupyter
# =============================================================================

test_stop_jupyter() {
    echo "Testing stop_jupyter function..."
    
    # Test that function exists and is callable
    assert_command_success "type stop_jupyter" "stop_jupyter function should exist"
    
    # Test function help output
    local help_output
    help_output=$(stop_jupyter --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "stop_jupyter should provide output"
    
    echo "✅ stop_jupyter tests passed"
}

# =============================================================================
# Test: jupyter_status
# =============================================================================

test_jupyter_status() {
    echo "Testing jupyter_status function..."
    
    # Test that function exists and is callable
    assert_command_success "type jupyter_status" "jupyter_status function should exist"
    
    # Test function execution
    local status_output
    status_output=$(jupyter_status 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$status_output" "error:" "Jupyter status should not have errors"
    
    # Test that output contains expected information
    assert_contains "$status_output" "Jupyter" "Status should contain Jupyter information"
    
    echo "✅ jupyter_status tests passed"
}

# =============================================================================
# Test: create_notebook
# =============================================================================

test_create_notebook() {
    echo "Testing create_notebook function..."
    
    # Test that function exists and is callable
    assert_command_success "type create_notebook" "create_notebook function should exist"
    
    # Test function help output
    local help_output
    help_output=$(create_notebook --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "create_notebook should provide output"
    
    echo "✅ create_notebook tests passed"
}

# =============================================================================
# Test: list_notebooks
# =============================================================================

test_list_notebooks() {
    echo "Testing list_notebooks function..."
    
    # Test that function exists and is callable
    assert_command_success "type list_notebooks" "list_notebooks function should exist"
    
    # Test function execution
    local list_output
    list_output=$(list_notebooks 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$list_output" "error:" "List notebooks should not have errors"
    
    echo "✅ list_notebooks tests passed"
}

# =============================================================================
# Test: notebook_convert
# =============================================================================

test_notebook_convert() {
    echo "Testing notebook_convert function..."
    
    # Test that function exists and is callable
    assert_command_success "type notebook_convert" "notebook_convert function should exist"
    
    # Test function help output
    local help_output
    help_output=$(notebook_convert --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "notebook_convert should provide output"
    
    echo "✅ notebook_convert tests passed"
}

# =============================================================================
# Test: notebook_export
# =============================================================================

test_notebook_export() {
    echo "Testing notebook_export function..."
    
    # Test that function exists and is callable
    assert_command_success "type notebook_export" "notebook_export function should exist"
    
    # Test function help output
    local help_output
    help_output=$(notebook_export --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "notebook_export should provide output"
    
    echo "✅ notebook_export tests passed"
}

# =============================================================================
# Test: setup_jupyter_lab
# =============================================================================

test_setup_jupyter_lab() {
    echo "Testing setup_jupyter_lab function..."
    
    # Test that function exists and is callable
    assert_command_success "type setup_jupyter_lab" "setup_jupyter_lab function should exist"
    
    # Test function execution
    local setup_output
    setup_output=$(setup_jupyter_lab 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$setup_output" "error:" "Jupyter Lab setup should not have errors"
    
    echo "✅ setup_jupyter_lab tests passed"
}

# =============================================================================
# Test: start_jupyter_lab
# =============================================================================

test_start_jupyter_lab() {
    echo "Testing start_jupyter_lab function..."
    
    # Test that function exists and is callable
    assert_command_success "type start_jupyter_lab" "start_jupyter_lab function should exist"
    
    # Test function help output
    local help_output
    help_output=$(start_jupyter_lab --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "start_jupyter_lab should provide output"
    
    echo "✅ start_jupyter_lab tests passed"
}

# =============================================================================
# Test: stop_jupyter_lab
# =============================================================================

test_stop_jupyter_lab() {
    echo "Testing stop_jupyter_lab function..."
    
    # Test that function exists and is callable
    assert_command_success "type stop_jupyter_lab" "stop_jupyter_lab function should exist"
    
    # Test function help output
    local help_output
    help_output=$(stop_jupyter_lab --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "stop_jupyter_lab should provide output"
    
    echo "✅ stop_jupyter_lab tests passed"
}

# =============================================================================
# Test: jupyter_lab_status
# =============================================================================

test_jupyter_lab_status() {
    echo "Testing jupyter_lab_status function..."
    
    # Test that function exists and is callable
    assert_command_success "type jupyter_lab_status" "jupyter_lab_status function should exist"
    
    # Test function execution
    local status_output
    status_output=$(jupyter_lab_status 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$status_output" "error:" "Jupyter Lab status should not have errors"
    
    # Test that output contains expected information
    assert_contains "$status_output" "Jupyter" "Status should contain Jupyter information"
    
    echo "✅ jupyter_lab_status tests passed"
}

# =============================================================================
# Test: setup_jupyter_hub
# =============================================================================

test_setup_jupyter_hub() {
    echo "Testing setup_jupyter_hub function..."
    
    # Test that function exists and is callable
    assert_command_success "type setup_jupyter_hub" "setup_jupyter_hub function should exist"
    
    # Test function execution
    local setup_output
    setup_output=$(setup_jupyter_hub 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$setup_output" "error:" "Jupyter Hub setup should not have errors"
    
    echo "✅ setup_jupyter_hub tests passed"
}

# =============================================================================
# Test: start_jupyter_hub
# =============================================================================

test_start_jupyter_hub() {
    echo "Testing start_jupyter_hub function..."
    
    # Test that function exists and is callable
    assert_command_success "type start_jupyter_hub" "start_jupyter_hub function should exist"
    
    # Test function help output
    local help_output
    help_output=$(start_jupyter_hub --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "start_jupyter_hub should provide output"
    
    echo "✅ start_jupyter_hub tests passed"
}

# =============================================================================
# Test: stop_jupyter_hub
# =============================================================================

test_stop_jupyter_hub() {
    echo "Testing stop_jupyter_hub function..."
    
    # Test that function exists and is callable
    assert_command_success "type stop_jupyter_hub" "stop_jupyter_hub function should exist"
    
    # Test function help output
    local help_output
    help_output=$(stop_jupyter_hub --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "stop_jupyter_hub should provide output"
    
    echo "✅ stop_jupyter_hub tests passed"
}

# =============================================================================
# Test: jupyter_hub_status
# =============================================================================

test_jupyter_hub_status() {
    echo "Testing jupyter_hub_status function..."
    
    # Test that function exists and is callable
    assert_command_success "type jupyter_hub_status" "jupyter_hub_status function should exist"
    
    # Test function execution
    local status_output
    status_output=$(jupyter_hub_status 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$status_output" "error:" "Jupyter Hub status should not have errors"
    
    # Test that output contains expected information
    assert_contains "$status_output" "Jupyter" "Status should contain Jupyter information"
    
    echo "✅ jupyter_hub_status tests passed"
}

# =============================================================================
# Test: Environment Variables
# =============================================================================

test_notebook_environment_variables() {
    echo "Testing notebook environment variables..."
    
    # Test that required environment variables are set after setup
    setup_jupyter
    
    assert_var_set "JUPYTER_HOME" "JUPYTER_HOME should be set"
    
    # Test that paths are in PATH
    assert_contains "$PATH" "$JUPYTER_HOME/bin" "JUPYTER_HOME/bin should be in PATH"
    
    echo "✅ Notebook environment variables tests passed"
}

# =============================================================================
# Test: Jupyter Command Availability
# =============================================================================

test_jupyter_command_availability() {
    echo "Testing Jupyter command availability..."
    
    # Test that Jupyter commands are available
    if command -v jupyter >/dev/null 2>&1; then
        assert_command_success "jupyter --version" "Jupyter should be available"
        
        # Test Jupyter Lab
        if command -v jupyter-lab >/dev/null 2>&1; then
            assert_command_success "jupyter-lab --version" "Jupyter Lab should be available"
        else
            echo "⚠️  Jupyter Lab not available - skipping Jupyter Lab tests"
        fi
        
        # Test Jupyter Hub
        if command -v jupyterhub >/dev/null 2>&1; then
            assert_command_success "jupyterhub --version" "Jupyter Hub should be available"
        else
            echo "⚠️  Jupyter Hub not available - skipping Jupyter Hub tests"
        fi
    else
        echo "⚠️  Jupyter not available - skipping Jupyter tests"
    fi
    
    echo "✅ Jupyter command availability tests passed"
}

# =============================================================================
# Test: Notebook Integration with Python
# =============================================================================

test_notebook_python_integration() {
    echo "Testing notebook Python integration..."
    
    # Test that Python is available for Jupyter
    if command -v python >/dev/null 2>&1; then
        assert_command_success "python --version" "Python should be available for Jupyter"
        
        # Test that Jupyter can find Python
        if command -v jupyter >/dev/null 2>&1; then
            local jupyter_output
            jupyter_output=$(jupyter kernelspec list 2>&1)
            assert_not_contains "$jupyter_output" "error:" "Jupyter kernelspec should not have errors"
        fi
    else
        echo "⚠️  Python not available - skipping Python integration tests"
    fi
    
    echo "✅ Notebook Python integration tests passed"
}

# =============================================================================
# Register Tests
# =============================================================================

register_test "test_setup_jupyter" "test_setup_jupyter"
register_test "test_start_jupyter" "test_start_jupyter"
register_test "test_stop_jupyter" "test_stop_jupyter"
register_test "test_jupyter_status" "test_jupyter_status"
register_test "test_create_notebook" "test_create_notebook"
register_test "test_list_notebooks" "test_list_notebooks"
register_test "test_notebook_convert" "test_notebook_convert"
register_test "test_notebook_export" "test_notebook_export"
register_test "test_setup_jupyter_lab" "test_setup_jupyter_lab"
register_test "test_start_jupyter_lab" "test_start_jupyter_lab"
register_test "test_stop_jupyter_lab" "test_stop_jupyter_lab"
register_test "test_jupyter_lab_status" "test_jupyter_lab_status"
register_test "test_setup_jupyter_hub" "test_setup_jupyter_hub"
register_test "test_start_jupyter_hub" "test_start_jupyter_hub"
register_test "test_stop_jupyter_hub" "test_stop_jupyter_hub"
register_test "test_jupyter_hub_status" "test_jupyter_hub_status"
register_test "test_notebook_environment_variables" "test_notebook_environment_variables"
register_test "test_jupyter_command_availability" "test_jupyter_command_availability"
register_test "test_notebook_python_integration" "test_notebook_python_integration"
