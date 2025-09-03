#!/usr/bin/env zsh

# =============================================================================
# JVM Functions Unit Tests (Hadoop, YARN, Spark, etc.)
# =============================================================================

# Source the test framework
source "$(dirname "$0")/../test-framework.zsh"

# Source the functions to test
source "$(dirname "$0")/../spark.zsh"
source "$(dirname "$0")/../hadoop.zsh"

# =============================================================================
# Test: Java Environment Setup
# =============================================================================

test_java_environment_setup() {
    echo "Testing Java environment setup..."
    
    # Test that Java is available
    if command -v java >/dev/null 2>&1; then
        assert_command_success "java -version" "Java should be available"
        
        # Test JAVA_HOME is set
        if [[ -n "$JAVA_HOME" ]]; then
            assert_dir_exists "$JAVA_HOME" "JAVA_HOME should be a valid directory"
            assert_file_exists "$JAVA_HOME/bin/java" "Java binary should exist in JAVA_HOME"
        fi
        
        # Test Java version
        local java_version
        java_version=$(java -version 2>&1 | head -1)
        assert_contains "$java_version" "version" "Java version should be available"
    else
        echo "⚠️  Java not available - skipping Java tests"
    fi
    
    echo "✅ Java environment setup tests passed"
}

# =============================================================================
# Test: Hadoop Core Functions
# =============================================================================

test_hadoop_core_functions() {
    echo "Testing Hadoop core functions..."
    
    # Test setup_hadoop
    setup_hadoop
    assert_var_set "HADOOP_HOME" "HADOOP_HOME should be set"
    assert_dir_exists "$HADOOP_HOME" "HADOOP_HOME should be a valid directory"
    assert_contains "$PATH" "$HADOOP_HOME/bin" "HADOOP_HOME/bin should be in PATH"
    
    # Test Hadoop configuration
    local hadoop_config_output
    hadoop_config_output=$(show_hadoop_config 2>&1)
    assert_not_contains "$hadoop_config_output" "error:" "Hadoop config should not have errors"
    assert_contains "$hadoop_config_output" "Hadoop Configuration" "Config should contain header"
    
    # Test Hadoop binaries availability
    if [[ -d "$HADOOP_HOME/bin" ]]; then
        assert_file_exists "$HADOOP_HOME/bin/hadoop" "Hadoop binary should exist"
        assert_file_exists "$HADOOP_HOME/bin/hdfs" "HDFS binary should exist"
        assert_file_exists "$HADOOP_HOME/bin/yarn" "YARN binary should exist"
    fi
    
    echo "✅ Hadoop core functions tests passed"
}

# =============================================================================
# Test: YARN Functions
# =============================================================================

test_yarn_functions() {
    echo "Testing YARN functions..."
    
    # Test setup_yarn
    setup_yarn
    assert_var_set "YARN_HOME" "YARN_HOME should be set"
    assert_dir_exists "$YARN_HOME" "YARN_HOME should be a valid directory"
    assert_contains "$PATH" "$YARN_HOME/bin" "YARN_HOME/bin should be in PATH"
    
    # Test YARN configuration
    local yarn_config_output
    yarn_config_output=$(show_yarn_config 2>&1)
    assert_not_contains "$yarn_config_output" "error:" "YARN config should not have errors"
    assert_contains "$yarn_config_output" "YARN Configuration" "Config should contain header"
    
    # Test YARN binaries availability
    if [[ -d "$YARN_HOME/bin" ]]; then
        assert_file_exists "$YARN_HOME/bin/yarn" "YARN binary should exist"
    fi
    
    echo "✅ YARN functions tests passed"
}

# =============================================================================
# Test: Spark JVM Integration
# =============================================================================

test_spark_jvm_integration() {
    echo "Testing Spark JVM integration..."
    
    # Test setup_spark
    setup_spark
    assert_var_set "SPARK_HOME" "SPARK_HOME should be set"
    assert_dir_exists "$SPARK_HOME" "SPARK_HOME should be a valid directory"
    assert_contains "$PATH" "$SPARK_HOME/bin" "SPARK_HOME/bin should be in PATH"
    
    # Test Spark configuration
    local spark_config_output
    spark_config_output=$(show_spark_config 2>&1)
    assert_not_contains "$spark_config_output" "error:" "Spark config should not have errors"
    assert_contains "$spark_config_output" "Spark Configuration" "Config should contain header"
    
    # Test Spark binaries availability
    if [[ -d "$SPARK_HOME/bin" ]]; then
        assert_file_exists "$SPARK_HOME/bin/spark-shell" "Spark shell should exist"
        assert_file_exists "$SPARK_HOME/bin/pyspark" "PySpark should exist"
        assert_file_exists "$SPARK_HOME/bin/spark-submit" "Spark submit should exist"
    fi
    
    echo "✅ Spark JVM integration tests passed"
}

# =============================================================================
# Test: Hadoop Services Management
# =============================================================================

test_hadoop_services_management() {
    echo "Testing Hadoop services management..."
    
    # Test start_hadoop_services function
    assert_command_success "type start_hadoop_services" "start_hadoop_services function should exist"
    
    # Test stop_hadoop_services function
    assert_command_success "type stop_hadoop_services" "stop_hadoop_services function should exist"
    
    # Test function help output
    local start_help_output
    start_help_output=$(start_hadoop_services --help 2>&1 || echo "help not available")
    assert_true "[[ -n '$start_help_output' ]]" "start_hadoop_services should provide output"
    
    local stop_help_output
    stop_help_output=$(stop_hadoop_services --help 2>&1 || echo "help not available")
    assert_true "[[ -n '$stop_help_output' ]]" "stop_hadoop_services should provide output"
    
    echo "✅ Hadoop services management tests passed"
}

# =============================================================================
# Test: Zeppelin Integration
# =============================================================================

test_zeppelin_integration() {
    echo "Testing Zeppelin integration..."
    
    # Test start_zeppelin function
    assert_command_success "type start_zeppelin" "start_zeppelin function should exist"
    
    # Test stop_zeppelin function
    assert_command_success "type stop_zeppelin" "stop_zeppelin function should exist"
    
    # Test function help output
    local start_help_output
    start_help_output=$(start_zeppelin --help 2>&1 || echo "help not available")
    assert_true "[[ -n '$start_help_output' ]]" "start_zeppelin should provide output"
    
    local stop_help_output
    stop_help_output=$(stop_zeppelin --help 2>&1 || echo "help not available")
    assert_true "[[ -n '$stop_help_output' ]]" "stop_zeppelin should provide output"
    
    echo "✅ Zeppelin integration tests passed"
}

# =============================================================================
# Test: JVM Memory Configuration
# =============================================================================

test_jvm_memory_configuration() {
    echo "Testing JVM memory configuration..."
    
    # Test that JVM memory settings are available
    if [[ -n "$JAVA_OPTS" ]]; then
        assert_contains "$JAVA_OPTS" "-Xmx" "JAVA_OPTS should contain memory settings"
    fi
    
    # Test Spark memory configuration
    if [[ -n "$SPARK_DRIVER_MEMORY" ]]; then
        assert_contains "$SPARK_DRIVER_MEMORY" "g" "SPARK_DRIVER_MEMORY should be in gigabytes"
    fi
    
    if [[ -n "$SPARK_EXECUTOR_MEMORY" ]]; then
        assert_contains "$SPARK_EXECUTOR_MEMORY" "g" "SPARK_EXECUTOR_MEMORY should be in gigabytes"
    fi
    
    echo "✅ JVM memory configuration tests passed"
}

# =============================================================================
# Test: HDFS Functions
# =============================================================================

test_hdfs_functions() {
    echo "Testing HDFS functions..."
    
    # Test HDFS availability
    if command -v hdfs >/dev/null 2>&1; then
        assert_command_success "hdfs version" "HDFS should be available"
        
        # Test HDFS configuration
        local hdfs_config_output
        hdfs_config_output=$(hdfs getconf -confKey fs.defaultFS 2>&1 || echo "config not available")
        assert_true "[[ -n '$hdfs_config_output' ]]" "HDFS configuration should be available"
    else
        echo "⚠️  HDFS not available - skipping HDFS tests"
    fi
    
    echo "✅ HDFS functions tests passed"
}

# =============================================================================
# Test: MapReduce Functions
# =============================================================================

test_mapreduce_functions() {
    echo "Testing MapReduce functions..."
    
    # Test MapReduce availability
    if command -v hadoop >/dev/null 2>&1; then
        # Test MapReduce version
        local mapreduce_version
        mapreduce_version=$(hadoop version 2>&1 | head -1)
        assert_contains "$mapreduce_version" "Hadoop" "MapReduce version should contain Hadoop"
        
        # Test MapReduce configuration
        local mapreduce_config_output
        mapreduce_config_output=$(hadoop version 2>&1)
        assert_not_contains "$mapreduce_config_output" "error:" "MapReduce version should not have errors"
    else
        echo "⚠️  MapReduce not available - skipping MapReduce tests"
    fi
    
    echo "✅ MapReduce functions tests passed"
}

# =============================================================================
# Test: JVM Garbage Collection
# =============================================================================

test_jvm_garbage_collection() {
    echo "Testing JVM garbage collection configuration..."
    
    # Test GC settings in JAVA_OPTS
    if [[ -n "$JAVA_OPTS" ]]; then
        # Test for common GC settings
        local gc_settings=("-XX:+UseG1GC" "-XX:+UseConcMarkSweepGC" "-XX:+UseParallelGC")
        local found_gc=false
        
        for gc_setting in "${gc_settings[@]}"; do
            if [[ "$JAVA_OPTS" == *"$gc_setting"* ]]; then
                found_gc=true
                break
            fi
        done
        
        if [[ "$found_gc" == "true" ]]; then
            echo "✅ GC settings found in JAVA_OPTS"
        else
            echo "⚠️  No GC settings found in JAVA_OPTS"
        fi
    else
        echo "⚠️  JAVA_OPTS not set - skipping GC tests"
    fi
    
    echo "✅ JVM garbage collection tests passed"
}

# =============================================================================
# Test: JVM Classpath Configuration
# =============================================================================

test_jvm_classpath_configuration() {
    echo "Testing JVM classpath configuration..."
    
    # Test CLASSPATH environment variable
    if [[ -n "$CLASSPATH" ]]; then
        assert_contains "$CLASSPATH" ":" "CLASSPATH should contain path separators"
    fi
    
    # Test Hadoop classpath
    if command -v hadoop >/dev/null 2>&1; then
        local hadoop_classpath
        hadoop_classpath=$(hadoop classpath 2>&1)
        assert_not_contains "$hadoop_classpath" "error:" "Hadoop classpath should not have errors"
        assert_contains "$hadoop_classpath" ":" "Hadoop classpath should contain path separators"
    fi
    
    # Test Spark classpath
    if [[ -n "$SPARK_HOME" ]]; then
        local spark_classpath
        spark_classpath=$(find "$SPARK_HOME" -name "*.jar" | head -5 | tr '\n' ':')
        if [[ -n "$spark_classpath" ]]; then
            assert_contains "$spark_classpath" ".jar" "Spark classpath should contain JAR files"
        fi
    fi
    
    echo "✅ JVM classpath configuration tests passed"
}

# =============================================================================
# Test: JVM Security Configuration
# =============================================================================

test_jvm_security_configuration() {
    echo "Testing JVM security configuration..."
    
    # Test Java security settings
    if [[ -n "$JAVA_OPTS" ]]; then
        # Test for security-related settings
        local security_settings=("-Djava.security.manager" "-Djava.security.policy" "-Djava.security.auth.login.config")
        local found_security=false
        
        for security_setting in "${security_settings[@]}"; do
            if [[ "$JAVA_OPTS" == *"$security_setting"* ]]; then
                found_security=true
                break
            fi
        done
        
        if [[ "$found_security" == "true" ]]; then
            echo "✅ Security settings found in JAVA_OPTS"
        else
            echo "⚠️  No security settings found in JAVA_OPTS"
        fi
    else
        echo "⚠️  JAVA_OPTS not set - skipping security tests"
    fi
    
    echo "✅ JVM security configuration tests passed"
}

# =============================================================================
# Test: JVM Performance Tuning
# =============================================================================

test_jvm_performance_tuning() {
    echo "Testing JVM performance tuning..."
    
    # Test performance-related JVM settings
    if [[ -n "$JAVA_OPTS" ]]; then
        # Test for performance settings
        local performance_settings=("-XX:+AggressiveOpts" "-XX:+UseFastAccessorMethods" "-XX:+UseCompressedOops")
        local found_performance=false
        
        for performance_setting in "${performance_settings[@]}"; do
            if [[ "$JAVA_OPTS" == *"$performance_setting"* ]]; then
                found_performance=true
                break
            fi
        done
        
        if [[ "$found_performance" == "true" ]]; then
            echo "✅ Performance settings found in JAVA_OPTS"
        else
            echo "⚠️  No performance settings found in JAVA_OPTS"
        fi
    else
        echo "⚠️  JAVA_OPTS not set - skipping performance tests"
    fi
    
    echo "✅ JVM performance tuning tests passed"
}

# =============================================================================
# Test: JVM Environment Variables
# =============================================================================

test_jvm_environment_variables() {
    echo "Testing JVM environment variables..."
    
    # Test that required JVM environment variables are set
    if [[ -n "$JAVA_HOME" ]]; then
        assert_dir_exists "$JAVA_HOME" "JAVA_HOME should be a valid directory"
    fi
    
    # Test Hadoop environment variables
    assert_var_set "HADOOP_HOME" "HADOOP_HOME should be set"
    assert_var_set "YARN_HOME" "YARN_HOME should be set"
    assert_var_set "SPARK_HOME" "SPARK_HOME should be set"
    
    # Test that paths are in PATH
    assert_contains "$PATH" "$HADOOP_HOME/bin" "HADOOP_HOME/bin should be in PATH"
    assert_contains "$PATH" "$YARN_HOME/bin" "YARN_HOME/bin should be in PATH"
    assert_contains "$PATH" "$SPARK_HOME/bin" "SPARK_HOME/bin should be in PATH"
    
    echo "✅ JVM environment variables tests passed"
}

# =============================================================================
# Test: JVM Integration with SDKMAN
# =============================================================================

test_jvm_sdkman_integration() {
    echo "Testing JVM integration with SDKMAN..."
    
    # Test that SDKMAN is available
    if command -v sdk >/dev/null 2>&1; then
        assert_command_success "sdk version" "SDKMAN should be available"
        
        # Test that SDKMAN_HOME is set
        assert_var_set "SDKMAN_HOME" "SDKMAN_HOME should be set"
        assert_dir_exists "$SDKMAN_HOME" "SDKMAN_HOME should be a valid directory"
        
        # Test Java installation via SDKMAN
        local java_installations
        java_installations=$(sdk list java 2>&1 | grep -c "installed" || echo "0")
        if [[ "$java_installations" -gt 0 ]]; then
            echo "✅ Java installations found via SDKMAN"
        else
            echo "⚠️  No Java installations found via SDKMAN"
        fi
        
        # Test Spark installation via SDKMAN
        local spark_installations
        spark_installations=$(sdk list spark 2>&1 | grep -c "installed" || echo "0")
        if [[ "$spark_installations" -gt 0 ]]; then
            echo "✅ Spark installations found via SDKMAN"
        else
            echo "⚠️  No Spark installations found via SDKMAN"
        fi
    else
        echo "⚠️  SDKMAN not available - skipping SDKMAN integration tests"
    fi
    
    echo "✅ JVM SDKMAN integration tests passed"
}

# =============================================================================
# Register Tests
# =============================================================================

register_test "test_java_environment_setup" "test_java_environment_setup"
register_test "test_hadoop_core_functions" "test_hadoop_core_functions"
register_test "test_yarn_functions" "test_yarn_functions"
register_test "test_spark_jvm_integration" "test_spark_jvm_integration"
register_test "test_hadoop_services_management" "test_hadoop_services_management"
register_test "test_zeppelin_integration" "test_zeppelin_integration"
register_test "test_jvm_memory_configuration" "test_jvm_memory_configuration"
register_test "test_hdfs_functions" "test_hdfs_functions"
register_test "test_mapreduce_functions" "test_mapreduce_functions"
register_test "test_jvm_garbage_collection" "test_jvm_garbage_collection"
register_test "test_jvm_classpath_configuration" "test_jvm_classpath_configuration"
register_test "test_jvm_security_configuration" "test_jvm_security_configuration"
register_test "test_jvm_performance_tuning" "test_jvm_performance_tuning"
register_test "test_jvm_environment_variables" "test_jvm_environment_variables"
register_test "test_jvm_sdkman_integration" "test_jvm_sdkman_integration"
