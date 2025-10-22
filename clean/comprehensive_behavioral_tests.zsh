#!/usr/bin/env zsh
# =================================================================
# COMPREHENSIVE BEHAVIORAL TESTS
# Tests actual behavior, not just existence
# =================================================================

# Load all modules
source ~/.config/zsh/clean/utils.zsh
source ~/.config/zsh/clean/python.zsh
source ~/.config/zsh/clean/spark.zsh
source ~/.config/zsh/clean/hadoop.zsh
source ~/.config/zsh/clean/docker.zsh
source ~/.config/zsh/clean/database.zsh
source ~/.config/zsh/clean/credentials.zsh
source ~/.config/zsh/clean/backup.zsh

TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

test_result() {
    local name="$1"
    local result="$2"
    local message="$3"
    
    if [[ $result -eq 0 ]]; then
        echo "  ✅ $name: PASS"
        ((TESTS_PASSED++))
    elif [[ $result -eq 2 ]]; then
        echo "  ⊘ $name: SKIP - $message"
        ((TESTS_SKIPPED++))
    else
        echo "  ❌ $name: FAIL - $message"
        ((TESTS_FAILED++))
    fi
}

# =================================================================
# UTILS MODULE - Test actual PATH manipulation and utilities
# =================================================================
echo "════════════════════════════════════════════════════════════"
echo "1. UTILS MODULE - Behavioral Tests"
echo "════════════════════════════════════════════════════════════"

# Test 1: path_add - adds directory and prevents duplicates
test_path_add() {
    local original_path="$PATH"
    export PATH="/usr/bin:/bin"
    
    # Add /usr/local/bin
    path_add /usr/local/bin
    [[ "$PATH" == "/usr/local/bin:/usr/bin:/bin" ]] || return 1
    
    # Try to add again (should not duplicate)
    path_add /usr/local/bin
    [[ "$PATH" == "/usr/local/bin:/usr/bin:/bin" ]] || return 1
    
    # Restore
    export PATH="$original_path"
    return 0
}
test_path_add && result=0 || result=1
test_result "path_add behavior" $result "Should add dir and prevent duplicates"

# Test 2: path_clean - removes duplicates from PATH
test_path_clean() {
    local original_path="$PATH"
    export PATH="/usr/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/bin"
    
    path_clean >/dev/null
    
    # Count occurrences of /usr/bin
    local count=$(echo "$PATH" | tr ':' '\n' | grep -c "^/usr/bin$")
    [[ $count -eq 1 ]] || return 1
    
    # Count occurrences of /usr/local/bin
    count=$(echo "$PATH" | tr ':' '\n' | grep -c "^/usr/local/bin$")
    [[ $count -eq 1 ]] || return 1
    
    export PATH="$original_path"
    return 0
}
test_path_clean && result=0 || result=1
test_result "path_clean behavior" $result "Should remove all duplicates"

# Test 3: mkcd - creates directory and changes into it
test_mkcd() {
    local test_dir="/tmp/test_mkcd_$$"
    
    mkcd "$test_dir" >/dev/null || return 1
    
    # Verify we're in the directory
    [[ "$(pwd)" == "$test_dir" ]] || return 1
    
    # Cleanup
    cd /tmp
    rm -rf "$test_dir"
    return 0
}
test_mkcd && result=0 || result=1
test_result "mkcd behavior" $result "Should create dir and cd into it"

# Test 4: extract - extracts various archive formats
test_extract() {
    local test_dir="/tmp/test_extract_$$"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Create test file
    echo "test content" > test.txt
    
    # Create tar.gz
    tar -czf test.tar.gz test.txt
    rm test.txt
    
    # Extract it
    extract test.tar.gz >/dev/null 2>&1
    
    # Verify extraction
    [[ -f test.txt ]] || return 1
    [[ "$(cat test.txt)" == "test content" ]] || return 1
    
    # Cleanup
    cd /tmp
    rm -rf "$test_dir"
    return 0
}
test_extract && result=0 || result=1
test_result "extract behavior" $result "Should extract archives correctly"

# Test 5: is_online - actually checks network connectivity
test_is_online() {
    # Run the function and capture behavior
    if is_online >/dev/null 2>&1; then
        # If online, verify we can actually reach something
        ping -c 1 -t 1 8.8.8.8 >/dev/null 2>&1 || return 1
    else
        # If offline, verify we actually can't reach anything
        ping -c 1 -t 1 8.8.8.8 >/dev/null 2>&1 && return 1
    fi
    return 0
}
test_is_online && result=0 || result=1
test_result "is_online behavior" $result "Should match actual network state"

# Test 6: command_exists - accurately detects commands
test_command_exists() {
    # Should find existing command
    command_exists ls || return 1
    
    # Should not find non-existent command
    command_exists fake_command_xyz_$$ && return 1
    
    return 0
}
test_command_exists && result=0 || result=1
test_result "command_exists behavior" $result "Should accurately detect commands"

echo ""

# =================================================================
# PYTHON MODULE - Test actual Python environment manipulation
# =================================================================
echo "════════════════════════════════════════════════════════════"
echo "2. PYTHON MODULE - Behavioral Tests"
echo "════════════════════════════════════════════════════════════"

# Test 1: py_env_switch - actually switches Python versions
test_py_env_switch() {
    # Get current version
    local original=$(python --version 2>&1 | awk '{print $2}')
    
    # Get list of available versions
    local versions=($(pyenv versions --bare))
    
    # Need at least 2 versions to test switching
    [[ ${#versions[@]} -lt 2 ]] && return 2  # Skip if only one version
    
    # Find a different version
    local target=""
    for v in "${versions[@]}"; do
        if [[ "$v" != "$original" ]] && [[ "$v" != *"/"* ]]; then
            target="$v"
            break
        fi
    done
    
    [[ -z "$target" ]] && return 2  # Skip if can't find alternate
    
    # Switch to it
    py_env_switch "$target" >/dev/null 2>&1 || return 1
    
    # Verify switch worked
    local after=$(python --version 2>&1 | awk '{print $2}')
    [[ "$after" == "$target" ]] || return 1
    
    # Switch back
    py_env_switch "$original" >/dev/null 2>&1
    
    return 0
}
test_py_env_switch
result=$?
[[ $result -eq 2 ]] && test_result "py_env_switch behavior" $result "Need multiple Python versions"
[[ $result -ne 2 ]] && test_result "py_env_switch behavior" $result "Should actually switch versions"

# Test 2: python_status - reports accurate information
test_python_status() {
    local output=$(python_status 2>&1)
    
    # Should contain key information
    echo "$output" | grep -q "Python Environment" || return 1
    echo "$output" | grep -q "Python:" || return 1
    
    # Should match actual Python version
    local reported=$(echo "$output" | grep "Python:" | awk '{print $NF}')
    local actual=$(python --version 2>&1 | awk '{print $2}')
    [[ "$reported" == "$actual" ]] || return 1
    
    return 0
}
test_python_status && result=0 || result=1
test_result "python_status behavior" $result "Should report accurate Python info"

# Test 3: ds_project_init - creates project structure
test_ds_project_init() {
    local test_dir="/tmp/test_ds_project_$$"
    
    cd /tmp
    ds_project_init "test_ds_project_$$" >/dev/null 2>&1 || return 1
    
    # Verify directory created
    [[ -d "$test_dir" ]] || return 1
    
    # Verify basic structure exists
    [[ -d "$test_dir/data" ]] || return 1
    [[ -d "$test_dir/notebooks" ]] || return 1
    [[ -f "$test_dir/README.md" ]] || return 1
    
    # Cleanup
    rm -rf "$test_dir"
    return 0
}
test_ds_project_init && result=0 || result=1
test_result "ds_project_init behavior" $result "Should create project structure"

echo ""

# =================================================================
# SPARK MODULE - Test actual Spark operations
# =================================================================
echo "════════════════════════════════════════════════════════════"
echo "3. SPARK MODULE - Behavioral Tests"
echo "════════════════════════════════════════════════════════════"

# Test 1: spark_start - actually starts Spark cluster
test_spark_start() {
    # Stop if already running
    spark_stop >/dev/null 2>&1
    sleep 2
    
    # Start Spark
    spark_start >/dev/null 2>&1 || return 1
    sleep 5
    
    # Verify Master is running
    jps | grep -q "Master" || return 1
    
    # Verify Worker is running
    jps | grep -q "Worker" || return 1
    
    # Verify web UI is accessible
    curl -s http://localhost:8080 | grep -q "Spark Master" || return 1
    
    return 0
}
test_spark_start && result=0 || result=1
test_result "spark_start behavior" $result "Should start Master and Worker"

# Test 2: spark_status - accurately reports cluster state
test_spark_status() {
    local output=$(spark_status 2>&1)
    
    # Should detect running services
    echo "$output" | grep -q "Master.*running" || return 1
    echo "$output" | grep -q "Worker.*running" || return 1
    
    return 0
}
test_spark_status && result=0 || result=1
test_result "spark_status behavior" $result "Should detect running services"

# Test 3: smart_spark_submit - submits job and it runs
test_smart_spark_submit() {
    # Create test PySpark script
    cat > /tmp/test_spark_$$.py << 'EOF'
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("test").getOrCreate()
result = spark.range(100).count()
print(f"RESULT:{result}")
spark.stop()
EOF
    
    # Submit job
    local output=$(smart_spark_submit /tmp/test_spark_$$.py 2>&1)
    
    # Verify job ran and produced correct result
    echo "$output" | grep -q "RESULT:100" || return 1
    
    # Cleanup
    rm /tmp/test_spark_$$.py
    return 0
}
test_smart_spark_submit && result=0 || result=1
test_result "smart_spark_submit behavior" $result "Should run job and return results"

# Test 4: get_spark_dependencies - detects imports
test_get_spark_dependencies() {
    # Create script with known imports
    cat > /tmp/test_deps_$$.py << 'EOF'
from pyspark.sql import SparkSession
import pandas as pd
import numpy as np
EOF
    
    local deps=$(get_spark_dependencies /tmp/test_deps_$$.py 2>&1)
    
    # Should detect pandas and numpy (not pyspark - that's always included)
    echo "$deps" | grep -qE "(pandas|numpy)" || return 1
    
    rm /tmp/test_deps_$$.py
    return 0
}
test_get_spark_dependencies && result=0 || result=1
test_result "get_spark_dependencies behavior" $result "Should detect Python imports"

# Test 5: spark_stop - actually stops cluster
test_spark_stop() {
    # Stop Spark
    spark_stop >/dev/null 2>&1 || return 1
    sleep 3
    
    # Verify Master stopped
    jps | grep -q "Master" && return 1
    
    # Verify Worker stopped
    jps | grep -q "Worker" && return 1
    
    return 0
}
test_spark_stop && result=0 || result=1
test_result "spark_stop behavior" $result "Should stop all Spark processes"

# Test 6: spark_restart - cleanly restarts cluster
test_spark_restart() {
    spark_restart >/dev/null 2>&1 || return 1
    sleep 5
    
    # Verify cluster is running after restart
    jps | grep -q "Master" || return 1
    jps | grep -q "Worker" || return 1
    
    # Stop for cleanup
    spark_stop >/dev/null 2>&1
    
    return 0
}
test_spark_restart && result=0 || result=1
test_result "spark_restart behavior" $result "Should cleanly restart cluster"

echo ""

# =================================================================
# HADOOP MODULE - Test actual Hadoop/YARN operations
# =================================================================
echo "════════════════════════════════════════════════════════════"
echo "4. HADOOP MODULE - Behavioral Tests"
echo "════════════════════════════════════════════════════════════"

# Test 1: start_hadoop - actually starts HDFS and YARN
test_start_hadoop() {
    # Stop if running
    stop_hadoop >/dev/null 2>&1
    sleep 3
    
    # Start Hadoop
    start_hadoop >/dev/null 2>&1 || return 1
    sleep 10
    
    # Verify NameNode running
    jps | grep -q "NameNode" || return 1
    
    # Verify DataNode running
    jps | grep -q "DataNode" || return 1
    
    # Verify ResourceManager running
    jps | grep -q "ResourceManager" || return 1
    
    # Verify NodeManager running  
    jps | grep -q "NodeManager" || return 1
    
    return 0
}
test_start_hadoop && result=0 || result=1
test_result "start_hadoop behavior" $result "Should start HDFS and YARN services"

# Test 2: hadoop_status - accurately reports service state
test_hadoop_status() {
    local output=$(hadoop_status 2>&1)
    
    # Should detect running services
    echo "$output" | grep -q "NameNode.*running" || return 1
    echo "$output" | grep -q "DataNode.*running" || return 1
    echo "$output" | grep -q "ResourceManager.*running" || return 1
    echo "$output" | grep -q "NodeManager.*running" || return 1
    
    return 0
}
test_hadoop_status && result=0 || result=1
test_result "hadoop_status behavior" $result "Should detect all running services"

# Test 3: hdfs_put - actually uploads file to HDFS
test_hdfs_put() {
    # Create test file
    echo "test data $$" > /tmp/test_hdfs_$$.txt
    
    # Upload to HDFS
    hdfs_put /tmp/test_hdfs_$$.txt /test_$$.txt >/dev/null 2>&1 || return 1
    
    # Verify it's there
    hdfs dfs -test -e /test_$$.txt || return 1
    
    # Cleanup
    rm /tmp/test_hdfs_$$.txt
    return 0
}
test_hdfs_put && result=0 || result=1
test_result "hdfs_put behavior" $result "Should upload file to HDFS"

# Test 4: hdfs_ls - lists HDFS files
test_hdfs_ls() {
    local output=$(hdfs_ls / 2>&1)
    
    # Should show our test file
    echo "$output" | grep -q "test_$$" || return 1
    
    return 0
}
test_hdfs_ls && result=0 || result=1
test_result "hdfs_ls behavior" $result "Should list HDFS files"

# Test 5: hdfs_get - downloads file from HDFS
test_hdfs_get() {
    # Download file
    hdfs_get /test_$$.txt /tmp/test_hdfs_download_$$.txt >/dev/null 2>&1 || return 1
    
    # Verify contents match
    [[ "$(cat /tmp/test_hdfs_download_$$.txt)" == "test data $$" ]] || return 1
    
    # Cleanup
    rm /tmp/test_hdfs_download_$$.txt
    return 0
}
test_hdfs_get && result=0 || result=1
test_result "hdfs_get behavior" $result "Should download file with correct content"

# Test 6: hdfs_rm - deletes file from HDFS
test_hdfs_rm() {
    # Remove file
    hdfs_rm /test_$$.txt >/dev/null 2>&1 || return 1
    
    # Verify it's gone
    hdfs dfs -test -e /test_$$.txt && return 1
    
    return 0
}
test_hdfs_rm && result=0 || result=1
test_result "hdfs_rm behavior" $result "Should delete file from HDFS"

# Test 7: spark_yarn_submit - submits job to YARN
test_spark_yarn_submit() {
    # Create test job
    cat > /tmp/test_yarn_$$.py << 'EOF'
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("yarn_test").getOrCreate()
result = spark.range(50).count()
print(f"YARN_RESULT:{result}")
spark.stop()
EOF
    
    # Submit to YARN
    local output=$(spark_yarn_submit /tmp/test_yarn_$$.py 2>&1)
    
    # Verify job ran
    echo "$output" | grep -q "YARN_RESULT:50" || return 1
    
    # Cleanup
    rm /tmp/test_yarn_$$.py
    return 0
}
test_spark_yarn_submit && result=0 || result=1
test_result "spark_yarn_submit behavior" $result "Should run job on YARN cluster"

# Test 8: yarn_application_list - shows YARN apps
test_yarn_application_list() {
    # Should be able to list applications (even if empty)
    yarn_application_list >/dev/null 2>&1 || return 1
    return 0
}
test_yarn_application_list && result=0 || result=1
test_result "yarn_application_list behavior" $result "Should list YARN applications"

# Test 9: yarn_cluster_info - shows cluster state
test_yarn_cluster_info() {
    local output=$(yarn_cluster_info 2>&1)
    
    # Should show cluster information
    echo "$output" | grep -qE "(Cluster|Memory|VCores)" || return 1
    
    return 0
}
test_yarn_cluster_info && result=0 || result=1
test_result "yarn_cluster_info behavior" $result "Should show cluster metrics"

# Test 10: stop_hadoop - actually stops all services
test_stop_hadoop() {
    stop_hadoop >/dev/null 2>&1 || return 1
    sleep 5
    
    # Verify all stopped
    jps | grep -q "NameNode" && return 1
    jps | grep -q "DataNode" && return 1
    jps | grep -q "ResourceManager" && return 1
    jps | grep -q "NodeManager" && return 1
    
    return 0
}
test_stop_hadoop && result=0 || result=1
test_result "stop_hadoop behavior" $result "Should stop all Hadoop services"

echo ""

# =================================================================
# CREDENTIALS MODULE - Test actual credential operations
# =================================================================
echo "════════════════════════════════════════════════════════════"
echo "5. CREDENTIALS MODULE - Behavioral Tests"
echo "════════════════════════════════════════════════════════════"

# Test 1: store_credential and get_credential - round-trip
test_credential_roundtrip() {
    local service="test_service_$$"
    local account="test_account"
    local password="test_password_$$"
    
    # Store credential
    store_credential "$service" "$account" "$password" >/dev/null 2>&1 || return 1
    
    # Retrieve it
    local retrieved=$(get_credential "$service" "$account" 2>&1)
    [[ "$retrieved" == "$password" ]] || return 1
    
    # Cleanup
    security delete-generic-password -s "$service" -a "$account" 2>/dev/null
    
    return 0
}
test_credential_roundtrip && result=0 || result=1
test_result "credential round-trip" $result "Should store and retrieve correctly"

# Test 2: credential_backend_status - detects available backends
test_credential_backend() {
    local output=$(credential_backend_status 2>&1)
    
    # Should detect at least one backend (keychain on macOS)
    echo "$output" | grep -qE "(Keychain|1Password)" || return 1
    
    return 0
}
test_credential_backend && result=0 || result=1
test_result "credential_backend_status" $result "Should detect credential backend"

echo ""

# =================================================================
# DOCKER MODULE - Test actual Docker operations
# =================================================================
echo "════════════════════════════════════════════════════════════"
echo "6. DOCKER MODULE - Behavioral Tests"
echo "════════════════════════════════════════════════════════════"

# Test 1: docker_status - reports Docker state
test_docker_status() {
    if ! command -v docker >/dev/null 2>&1; then
        return 2  # Skip if Docker not installed
    fi
    
    docker_status >/dev/null 2>&1 || return 1
    return 0
}
test_docker_status
result=$?
[[ $result -eq 2 ]] && test_result "docker_status" $result "Docker not installed"
[[ $result -ne 2 ]] && test_result "docker_status" $result "Should report Docker state"

echo ""

# =================================================================
# FINAL RESULTS
# =================================================================
echo "════════════════════════════════════════════════════════════"
echo "FINAL RESULTS"
echo "════════════════════════════════════════════════════════════"
echo "✅ Passed:  $TESTS_PASSED"
echo "❌ Failed:  $TESTS_FAILED"
echo "⊘  Skipped: $TESTS_SKIPPED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total:     $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "🎉 ALL BEHAVIORAL TESTS PASSED"
    echo "✅ Clean build verified with real operations"
    exit 0
else
    echo "⚠️  SOME TESTS FAILED"
    echo "Review failures above"
    exit 1
fi

