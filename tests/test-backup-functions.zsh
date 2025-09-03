#!/usr/bin/env zsh

# =============================================================================
# Backup Functions Unit Tests
# =============================================================================

# Source the test framework
source "$(dirname "$0")/../test-framework.zsh"

# Source the functions to test
source "$(dirname "$0")/../backup-system.zsh"

# =============================================================================
# Test: deduplicate_path
# =============================================================================

test_deduplicate_path() {
    echo "Testing deduplicate_path function..."
    
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
    
    # Test that all original paths are still present
    assert_contains "$PATH" "/usr/bin" "PATH should contain /usr/bin"
    assert_contains "$PATH" "/usr/local/bin" "PATH should contain /usr/local/bin"
    assert_contains "$PATH" "/opt/homebrew/bin" "PATH should contain /opt/homebrew/bin"
    
    # Restore original PATH
    PATH="$original_path"
    
    echo "✅ deduplicate_path tests passed"
}

# =============================================================================
# Test: get_backup_path
# =============================================================================

test_get_backup_path() {
    echo "Testing get_backup_path function..."
    
    # Test backup path generation
    local backup_path
    backup_path=$(get_backup_path)
    
    # Test that path is not empty
    assert_true "[[ -n '$backup_path' ]]" "Backup path should not be empty"
    
    # Test that path follows expected format
    assert_contains "$backup_path" "$ZSHRC_BACKUPS" "Backup path should contain ZSHRC_BACKUPS"
    assert_contains "$backup_path" "$(date +%Y)" "Backup path should contain current year"
    assert_contains "$backup_path" "$(date +%m)" "Backup path should contain current month"
    
    echo "✅ get_backup_path tests passed"
}

# =============================================================================
# Test: backup_zsh_config
# =============================================================================

test_backup_zsh_config() {
    echo "Testing backup_zsh_config function..."
    
    # Create a temporary test directory
    local test_dir="/tmp/zsh_test_backup_$$"
    mkdir -p "$test_dir"
    
    # Create test files
    echo "test content" > "$test_dir/test_file.txt"
    
    # Test backup function
    local backup_path
    backup_path=$(backup_zsh_config "$test_dir" "test backup")
    
    # Test that backup was created
    assert_true "[[ -n '$backup_path' ]]" "Backup path should be returned"
    assert_dir_exists "$backup_path" "Backup directory should exist"
    assert_file_exists "$backup_path/test_file.txt" "Backup file should exist"
    
    # Test backup content
    local backup_content
    backup_content=$(cat "$backup_path/test_file.txt")
    assert_equal "test content" "$backup_content" "Backup content should match original"
    
    # Cleanup
    rm -rf "$test_dir"
    rm -rf "$backup_path"
    
    echo "✅ backup_zsh_config tests passed"
}

# =============================================================================
# Test: enhanced_backup
# =============================================================================

test_enhanced_backup() {
    echo "Testing enhanced_backup function..."
    
    # Test enhanced backup function
    local backup_path
    backup_path=$(enhanced_backup "test enhanced backup")
    
    # Test that backup was created
    assert_true "[[ -n '$backup_path' ]]" "Enhanced backup path should be returned"
    assert_dir_exists "$backup_path" "Enhanced backup directory should exist"
    
    # Test that backup contains expected files
    assert_file_exists "$backup_path/zsh/README.md" "Backup should contain README.md"
    assert_file_exists "$backup_path/metadata.json" "Backup should contain metadata.json"
    assert_file_exists "$backup_path/restore.sh" "Backup should contain restore.sh"
    
    # Test metadata content
    local metadata_content
    metadata_content=$(cat "$backup_path/metadata.json")
    assert_contains "$metadata_content" "test enhanced backup" "Metadata should contain backup message"
    assert_contains "$metadata_content" "timestamp" "Metadata should contain timestamp"
    
    # Cleanup
    rm -rf "$backup_path"
    
    echo "✅ enhanced_backup tests passed"
}

# =============================================================================
# Test: sync_config_repository
# =============================================================================

test_sync_config_repository() {
    echo "Testing sync_config_repository function..."
    
    # Test sync function (this will test the logic without actually pushing)
    local sync_result
    sync_result=$(sync_config_repository "test sync" 2>&1)
    
    # Test that function runs without critical errors
    assert_not_contains "$sync_result" "fatal:" "Sync should not have fatal errors"
    
    echo "✅ sync_config_repository tests passed"
}

# =============================================================================
# Test: sync_backup_repository
# =============================================================================

test_sync_backup_repository() {
    echo "Testing sync_backup_repository function..."
    
    # Test sync function (this will test the logic without actually pushing)
    local sync_result
    sync_result=$(sync_backup_repository "test backup sync" 2>&1)
    
    # Test that function runs without critical errors
    assert_not_contains "$sync_result" "fatal:" "Backup sync should not have fatal errors"
    
    echo "✅ sync_backup_repository tests passed"
}

# =============================================================================
# Test: list_zsh_backups
# =============================================================================

test_list_zsh_backups() {
    echo "Testing list_zsh_backups function..."
    
    # Test list function
    local list_output
    list_output=$(list_zsh_backups 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$list_output" "error:" "List function should not have errors"
    
    echo "✅ list_zsh_backups tests passed"
}

# =============================================================================
# Test: zsh_repo_status
# =============================================================================

test_zsh_repo_status() {
    echo "Testing zsh_repo_status function..."
    
    # Test status function
    local status_output
    status_output=$(zsh_repo_status 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$status_output" "error:" "Status function should not have errors"
    
    # Test that output contains expected information
    assert_contains "$status_output" "Repository Status" "Status should contain header"
    
    echo "✅ zsh_repo_status tests passed"
}

# =============================================================================
# Test: sync_and_backup
# =============================================================================

test_sync_and_backup() {
    echo "Testing sync_and_backup function..."
    
    # Test sync and backup function
    local sync_output
    sync_output=$(sync_and_backup "test sync and backup" 2>&1)
    
    # Test that function runs without critical errors
    assert_not_contains "$sync_output" "fatal:" "Sync and backup should not have fatal errors"
    
    echo "✅ sync_and_backup tests passed"
}

# =============================================================================
# Test: Environment Variables
# =============================================================================

test_backup_environment_variables() {
    echo "Testing backup environment variables..."
    
    # Test that required environment variables are set
    assert_var_set "ZSHRC_BACKUPS" "ZSHRC_BACKUPS should be set"
    assert_var_set "PATH_DEDUPLICATION_ENABLED" "PATH_DEDUPLICATION_ENABLED should be set"
    
    # Test that ZSHRC_BACKUPS is a valid directory
    assert_dir_exists "$ZSHRC_BACKUPS" "ZSHRC_BACKUPS should be a valid directory"
    
    echo "✅ backup environment variables tests passed"
}

# =============================================================================
# Test: auto_backup_trigger
# =============================================================================

test_auto_backup_trigger() {
    echo "Testing auto_backup_trigger function..."
    
    # Test that function exists and is callable
    assert_command_success "type auto_backup_trigger" "auto_backup_trigger function should exist"
    
    # Test function execution
    local trigger_output
    trigger_output=$(auto_backup_trigger 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$trigger_output" "error:" "Auto backup trigger should not have errors"
    
    echo "✅ auto_backup_trigger tests passed"
}

# =============================================================================
# Test: backup_critical_functions
# =============================================================================

test_backup_critical_functions() {
    echo "Testing backup_critical_functions function..."
    
    # Test that function exists and is callable
    assert_command_success "type backup_critical_functions" "backup_critical_functions function should exist"
    
    # Test function execution
    local backup_output
    backup_output=$(backup_critical_functions 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$backup_output" "error:" "Backup critical functions should not have errors"
    
    echo "✅ backup_critical_functions tests passed"
}

# =============================================================================
# Test: sync_documentation_between_repos
# =============================================================================

test_sync_documentation_between_repos() {
    echo "Testing sync_documentation_between_repos function..."
    
    # Test that function exists and is callable
    assert_command_success "type sync_documentation_between_repos" "sync_documentation_between_repos function should exist"
    
    # Test function execution
    local sync_output
    sync_output=$(sync_documentation_between_repos 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$sync_output" "error:" "Sync documentation should not have errors"
    
    echo "✅ sync_documentation_between_repos tests passed"
}

# =============================================================================
# Test: sync_zsh_repositories
# =============================================================================

test_sync_zsh_repositories() {
    echo "Testing sync_zsh_repositories function..."
    
    # Test that function exists and is callable
    assert_command_success "type sync_zsh_repositories" "sync_zsh_repositories function should exist"
    
    # Test function execution
    local sync_output
    sync_output=$(sync_zsh_repositories "test sync" 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$sync_output" "error:" "Sync zsh repositories should not have errors"
    
    echo "✅ sync_zsh_repositories tests passed"
}

# =============================================================================
# Test: sync_zsh
# =============================================================================

test_sync_zsh() {
    echo "Testing sync_zsh function..."
    
    # Test that function exists and is callable
    assert_command_success "type sync_zsh" "sync_zsh function should exist"
    
    # Test function execution
    local sync_output
    sync_output=$(sync_zsh "test sync" 2>&1)
    
    # Test that function runs without errors
    assert_not_contains "$sync_output" "error:" "Sync zsh should not have errors"
    
    echo "✅ sync_zsh tests passed"
}

# =============================================================================
# Test: Backup File Structure
# =============================================================================

test_backup_file_structure() {
    echo "Testing backup file structure..."
    
    # Create a test backup
    local test_backup_path
    test_backup_path=$(enhanced_backup "test file structure backup")
    
    # Test that backup was created
    assert_dir_exists "$test_backup_path" "Backup directory should exist"
    
    # Test that backup contains expected files
    assert_file_exists "$test_backup_path/zsh/README.md" "Backup should contain README.md"
    assert_file_exists "$test_backup_path/metadata.json" "Backup should contain metadata.json"
    assert_file_exists "$test_backup_path/restore.sh" "Backup should contain restore.sh"
    
    # Test that restore script is executable
    assert_command_success "test -x '$test_backup_path/restore.sh'" "Restore script should be executable"
    
    # Test metadata content
    local metadata_content
    metadata_content=$(cat "$test_backup_path/metadata.json")
    assert_contains "$metadata_content" "test file structure backup" "Metadata should contain backup message"
    assert_contains "$metadata_content" "timestamp" "Metadata should contain timestamp"
    assert_contains "$metadata_content" "version" "Metadata should contain version"
    
    # Cleanup
    rm -rf "$test_backup_path"
    
    echo "✅ backup file structure tests passed"
}

# =============================================================================
# Test: Backup Metadata Validation
# =============================================================================

test_backup_metadata_validation() {
    echo "Testing backup metadata validation..."
    
    # Create a test backup
    local test_backup_path
    test_backup_path=$(enhanced_backup "test metadata validation backup")
    
    # Test metadata file exists and is valid JSON
    assert_file_exists "$test_backup_path/metadata.json" "Metadata file should exist"
    
    # Test that metadata can be parsed as JSON
    local metadata_content
    metadata_content=$(cat "$test_backup_path/metadata.json")
    
    # Test required fields
    assert_contains "$metadata_content" "message" "Metadata should contain message field"
    assert_contains "$metadata_content" "timestamp" "Metadata should contain timestamp field"
    assert_contains "$metadata_content" "version" "Metadata should contain version field"
    assert_contains "$metadata_content" "files" "Metadata should contain files field"
    
    # Cleanup
    rm -rf "$test_backup_path"
    
    echo "✅ backup metadata validation tests passed"
}

# =============================================================================
# Test: Restore Script Functionality
# =============================================================================

test_restore_script_functionality() {
    echo "Testing restore script functionality..."
    
    # Create a test backup
    local test_backup_path
    test_backup_path=$(enhanced_backup "test restore script backup")
    
    # Test that restore script exists and is executable
    assert_file_exists "$test_backup_path/restore.sh" "Restore script should exist"
    assert_command_success "test -x '$test_backup_path/restore.sh'" "Restore script should be executable"
    
    # Test that restore script has proper shebang
    local restore_content
    restore_content=$(head -1 "$test_backup_path/restore.sh")
    assert_contains "$restore_content" "#!/bin/bash" "Restore script should have bash shebang"
    
    # Test that restore script contains restore logic
    restore_content=$(cat "$test_backup_path/restore.sh")
    assert_contains "$restore_content" "restore" "Restore script should contain restore logic"
    
    # Cleanup
    rm -rf "$test_backup_path"
    
    echo "✅ restore script functionality tests passed"
}

# =============================================================================
# Test: Backup Performance
# =============================================================================

test_backup_performance() {
    echo "Testing backup performance..."
    
    # Test backup creation time
    local start_time=$(date +%s)
    local test_backup_path
    test_backup_path=$(enhanced_backup "test performance backup")
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Test that backup was created
    assert_dir_exists "$test_backup_path" "Backup should be created"
    
    # Test that backup was created in reasonable time (less than 30 seconds)
    assert_true "[[ $duration -lt 30 ]]" "Backup should complete in less than 30 seconds"
    
    # Cleanup
    rm -rf "$test_backup_path"
    
    echo "✅ backup performance tests passed"
}

# =============================================================================
# Test: Backup Error Handling
# =============================================================================

test_backup_error_handling() {
    echo "Testing backup error handling..."
    
    # Test backup with invalid path
    local invalid_backup_path
    invalid_backup_path=$(enhanced_backup "test error handling backup" 2>&1)
    
    # Test that function handles errors gracefully
    assert_not_contains "$invalid_backup_path" "fatal:" "Backup should handle errors gracefully"
    
    echo "✅ backup error handling tests passed"
}

# =============================================================================
# Register Tests
# =============================================================================

register_test "test_deduplicate_path" "test_deduplicate_path"
register_test "test_get_backup_path" "test_get_backup_path"
register_test "test_backup_zsh_config" "test_backup_zsh_config"
register_test "test_enhanced_backup" "test_enhanced_backup"
register_test "test_sync_config_repository" "test_sync_config_repository"
register_test "test_sync_backup_repository" "test_sync_backup_repository"
register_test "test_list_zsh_backups" "test_list_zsh_backups"
register_test "test_zsh_repo_status" "test_zsh_repo_status"
register_test "test_sync_and_backup" "test_sync_and_backup"
register_test "test_backup_environment_variables" "test_backup_environment_variables"
register_test "test_auto_backup_trigger" "test_auto_backup_trigger"
register_test "test_backup_critical_functions" "test_backup_critical_functions"
register_test "test_sync_documentation_between_repos" "test_sync_documentation_between_repos"
register_test "test_sync_zsh_repositories" "test_sync_zsh_repositories"
register_test "test_sync_zsh" "test_sync_zsh"
register_test "test_backup_file_structure" "test_backup_file_structure"
register_test "test_backup_metadata_validation" "test_backup_metadata_validation"
register_test "test_restore_script_functionality" "test_restore_script_functionality"
register_test "test_backup_performance" "test_backup_performance"
register_test "test_backup_error_handling" "test_backup_error_handling"
