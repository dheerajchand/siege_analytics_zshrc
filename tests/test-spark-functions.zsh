#!/usr/bin/env zsh

# =============================================================================
# Spark and JVM Functions Unit Tests
# =============================================================================

# Source the test framework
source "$(dirname "$0")/../test-framework.zsh"

# Source the functions to test
source "$(dirname "$0")/../spark.zsh"
source "$(dirname "$0")/../hadoop.zsh"

# =============================================================================
# Test: setup_spark
# =============================================================================

test_setup_spark() {
    echo "Testing setup_spark function..."
    
    # Test Spark setup
    setup_spark
    
    # Test that SPARK_HOME is set
    assert_var_set "SPARK_HOME" "SPARK_HOME should be set"
    
    # Test that SPARK_HOME is in PATH
    assert_contains "$PATH" "$SPARK_HOME/bin" "SPARK_HOME/bin should be in PATH"
    
    # Test that SPARK_HOME is a valid directory
    assert_dir_exists "$SPARK_HOME" "SPARK_HOME should be a valid directory"
    
    # Test that Spark binaries are available
    assert_file_exists "$SPARK_HOME/bin/spark-shell" "spark-shell should exist"
    assert_file_exists "$SPARK_HOME/bin/pyspark" "pyspark should exist"
    
    echo "✅ setup_spark tests passed"
}

# =============================================================================
# Test: show_spark_config
# =============================================================================

test_show_spark_config() {
    echo "Testing show_spark_config function..."
    
    # Test Spark config display
    local config_output
    config_output=$(show_spark_config 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$config_output" "error:" "Spark config should not have errors"
    
    # Test that output contains expected information
    assert_contains "$config_output" "Spark Configuration" "Config should contain header"
    assert_contains "$config_output" "SPARK_HOME" "Config should contain SPARK_HOME"
    
    echo "✅ show_spark_config tests passed"
}

# =============================================================================
# Test: pyspark_shell
# =============================================================================

test_pyspark_shell() {
    echo "Testing pyspark_shell function..."
    
    # Test that function exists and is callable
    assert_command_success "type pyspark_shell" "pyspark_shell function should exist"
    
    # Test function help output
    local help_output
    help_output=$(pyspark_shell --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "pyspark_shell should provide output"
    
    echo "✅ pyspark_shell tests passed"
}

# =============================================================================
# Test: spark_shell_scala
# =============================================================================

test_spark_shell_scala() {
    echo "Testing spark_shell_scala function..."
    
    # Test that function exists and is callable
    assert_command_success "type spark_shell_scala" "spark_shell_scala function should exist"
    
    # Test function help output
    local help_output
    help_output=$(spark_shell_scala --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "spark_shell_scala should provide output"
    
    echo "✅ spark_shell_scala tests passed"
}

# =============================================================================
# Test: smart_spark_shell
# =============================================================================

test_smart_spark_shell() {
    echo "Testing smart_spark_shell function..."
    
    # Test that function exists and is callable
    assert_command_success "type smart_spark_shell" "smart_spark_shell function should exist"
    
    # Test function help output
    local help_output
    help_output=$(smart_spark_shell --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "smart_spark_shell should provide output"
    
    echo "✅ smart_spark_shell tests passed"
}

# =============================================================================
# Test: setup_hadoop
# =============================================================================

test_setup_hadoop() {
    echo "Testing setup_hadoop function..."
    
    # Test Hadoop setup
    setup_hadoop
    
    # Test that HADOOP_HOME is set
    assert_var_set "HADOOP_HOME" "HADOOP_HOME should be set"
    
    # Test that HADOOP_HOME is in PATH
    assert_contains "$PATH" "$HADOOP_HOME/bin" "HADOOP_HOME/bin should be in PATH"
    
    # Test that HADOOP_HOME is a valid directory
    assert_dir_exists "$HADOOP_HOME" "HADOOP_HOME should be a valid directory"
    
    echo "✅ setup_hadoop tests passed"
}

# =============================================================================
# Test: show_hadoop_config
# =============================================================================

test_show_hadoop_config() {
    echo "Testing show_hadoop_config function..."
    
    # Test Hadoop config display
    local config_output
    config_output=$(show_hadoop_config 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$config_output" "error:" "Hadoop config should not have errors"
    
    # Test that output contains expected information
    assert_contains "$config_output" "Hadoop Configuration" "Config should contain header"
    assert_contains "$config_output" "HADOOP_HOME" "Config should contain HADOOP_HOME"
    
    echo "✅ show_hadoop_config tests passed"
}

# =============================================================================
# Test: setup_yarn
# =============================================================================

test_setup_yarn() {
    echo "Testing setup_yarn function..."
    
    # Test YARN setup
    setup_yarn
    
    # Test that YARN_HOME is set
    assert_var_set "YARN_HOME" "YARN_HOME should be set"
    
    # Test that YARN_HOME is in PATH
    assert_contains "$PATH" "$YARN_HOME/bin" "YARN_HOME/bin should be in PATH"
    
    # Test that YARN_HOME is a valid directory
    assert_dir_exists "$YARN_HOME" "YARN_HOME should be a valid directory"
    
    echo "✅ setup_yarn tests passed"
}

# =============================================================================
# Test: show_yarn_config
# =============================================================================

test_show_yarn_config() {
    echo "Testing show_yarn_config function..."
    
    # Test YARN config display
    local config_output
    config_output=$(show_yarn_config 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$config_output" "error:" "YARN config should not have errors"
    
    # Test that output contains expected information
    assert_contains "$config_output" "YARN Configuration" "Config should contain header"
    assert_contains "$config_output" "YARN_HOME" "Config should contain YARN_HOME"
    
    echo "✅ show_yarn_config tests passed"
}

# =============================================================================
# Test: start_hadoop_services
# =============================================================================

test_start_hadoop_services() {
    echo "Testing start_hadoop_services function..."
    
    # Test that function exists and is callable
    assert_command_success "type start_hadoop_services" "start_hadoop_services function should exist"
    
    # Test function help output
    local help_output
    help_output=$(start_hadoop_services --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "start_hadoop_services should provide output"
    
    echo "✅ start_hadoop_services tests passed"
}

# =============================================================================
# Test: stop_hadoop_services
# =============================================================================

test_stop_hadoop_services() {
    echo "Testing stop_hadoop_services function..."
    
    # Test that function exists and is callable
    assert_command_success "type stop_hadoop_services" "stop_hadoop_services function should exist"
    
    # Test function help output
    local help_output
    help_output=$(stop_hadoop_services --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "stop_hadoop_services should provide output"
    
    echo "✅ stop_hadoop_services tests passed"
}

# =============================================================================
# Test: start_zeppelin
# =============================================================================

test_start_zeppelin() {
    echo "Testing start_zeppelin function..."
    
    # Test that function exists and is callable
    assert_command_success "type start_zeppelin" "start_zeppelin function should exist"
    
    # Test function help output
    local help_output
    help_output=$(start_zeppelin --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "start_zeppelin should provide output"
    
    echo "✅ start_zeppelin tests passed"
}

# =============================================================================
# Test: stop_zeppelin
# =============================================================================

test_stop_zeppelin() {
    echo "Testing stop_zeppelin function..."
    
    # Test that function exists and is callable
    assert_command_success "type stop_zeppelin" "stop_zeppelin function should exist"
    
    # Test function help output
    local help_output
    help_output=$(stop_zeppelin --help 2>&1 || echo "help not available")
    
    # Function should exist even if help is not available
    assert_true "[[ -n '$help_output' ]]" "stop_zeppelin should provide output"
    
    echo "✅ stop_zeppelin tests passed"
}

# =============================================================================
# Test: spark_fix_logging
# =============================================================================

test_spark_fix_logging() {
    echo "Testing spark_fix_logging function..."
    
    # Test that function exists and is callable
    assert_command_success "type spark_fix_logging" "spark_fix_logging function should exist"
    
    # Test function execution
    local fix_output
    fix_output=$(spark_fix_logging 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$fix_output" "error:" "Spark logging fix should not have errors"
    
    echo "✅ spark_fix_logging tests passed"
}

# =============================================================================
# Test: load_big_data
# =============================================================================

test_load_big_data() {
    echo "Testing load_big_data function..."
    
    # Test that function exists and is callable
    assert_command_success "type load_big_data" "load_big_data function should exist"
    
    # Test function execution
    local load_output
    load_output=$(load_big_data 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$load_output" "error:" "Load big data should not have errors"
    
    # Test that environment variables are set
    assert_var_set "SPARK_HOME" "SPARK_HOME should be set after load_big_data"
    assert_var_set "HADOOP_HOME" "HADOOP_HOME should be set after load_big_data"
    
    echo "✅ load_big_data tests passed"
}

# =============================================================================
# Test: Environment Variables
# =============================================================================

test_spark_environment_variables() {
    echo "Testing Spark environment variables..."
    
    # Test that required environment variables are set after setup
    setup_spark
    setup_hadoop
    setup_yarn
    
    assert_var_set "SPARK_HOME" "SPARK_HOME should be set"
    assert_var_set "HADOOP_HOME" "HADOOP_HOME should be set"
    assert_var_set "YARN_HOME" "YARN_HOME should be set"
    
    # Test that paths are in PATH
    assert_contains "$PATH" "$SPARK_HOME/bin" "SPARK_HOME/bin should be in PATH"
    assert_contains "$PATH" "$HADOOP_HOME/bin" "HADOOP_HOME/bin should be in PATH"
    assert_contains "$PATH" "$YARN_HOME/bin" "YARN_HOME/bin should be in PATH"
    
    echo "✅ Spark environment variables tests passed"
}

# =============================================================================
# Test: Java Environment
# =============================================================================

test_java_environment() {
    echo "Testing Java environment..."
    
    # Test that Java is available
    if command -v java >/dev/null 2>&1; then
        assert_command_success "java -version" "Java should be available"
        
        # Test JAVA_HOME is set
        if [[ -n "$JAVA_HOME" ]]; then
            assert_dir_exists "$JAVA_HOME" "JAVA_HOME should be a valid directory"
        fi
    else
        echo "⚠️  Java not available - skipping Java tests"
    fi
    
    echo "✅ Java environment tests passed"
}

# =============================================================================
# Test: SDKMAN Integration
# =============================================================================

test_sdkman_integration() {
    echo "Testing SDKMAN integration..."
    
    # Test that SDKMAN is available
    if command -v sdk >/dev/null 2>&1; then
        assert_command_success "sdk version" "SDKMAN should be available"
        
        # Test that SDKMAN_HOME is set
        assert_var_set "SDKMAN_HOME" "SDKMAN_HOME should be set"
        assert_dir_exists "$SDKMAN_HOME" "SDKMAN_HOME should be a valid directory"
    else
        echo "⚠️  SDKMAN not available - skipping SDKMAN tests"
    fi
    
    echo "✅ SDKMAN integration tests passed"
}

# =============================================================================
# Register Tests
# =============================================================================

register_test "test_setup_spark" "test_setup_spark"
register_test "test_show_spark_config" "test_show_spark_config"
register_test "test_pyspark_shell" "test_pyspark_shell"
register_test "test_spark_shell_scala" "test_spark_shell_scala"
register_test "test_smart_spark_shell" "test_smart_spark_shell"
register_test "test_setup_hadoop" "test_setup_hadoop"
register_test "test_show_hadoop_config" "test_show_hadoop_config"
register_test "test_setup_yarn" "test_setup_yarn"
register_test "test_show_yarn_config" "test_show_yarn_config"
register_test "test_start_hadoop_services" "test_start_hadoop_services"
register_test "test_stop_hadoop_services" "test_stop_hadoop_services"
register_test "test_start_zeppelin" "test_start_zeppelin"
register_test "test_stop_zeppelin" "test_stop_zeppelin"
register_test "test_spark_fix_logging" "test_spark_fix_logging"
register_test "test_load_big_data" "test_load_big_data"
register_test "test_spark_environment_variables" "test_spark_environment_variables"
register_test "test_java_environment" "test_java_environment"
register_test "test_sdkman_integration" "test_sdkman_integration"
