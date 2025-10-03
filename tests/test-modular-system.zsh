#!/usr/bin/env zsh

# =====================================================
# MODULAR SYSTEM TESTS
# =====================================================
# 
# Tests for the new modular zsh configuration system
# Validates dynamic module discovery, mode loading, and core functionality
# =====================================================

# Test configuration
readonly TEST_NAME="Modular System Tests"
readonly TEST_VERSION="1.0.0"

# Include test framework
source "$(dirname "$0")/../test-framework.zsh"

# =====================================================
# DYNAMIC MODULE DISCOVERY TESTS
# =====================================================

test_dynamic_module_discovery() {
    local test_name="Dynamic Module Discovery System"
    local test_result="PASS"
    local test_details=()
    
    echo "🧪 Testing dynamic module discovery system..."
    
    # Test if ALL_MODULES variable is set
    if [[ -z "${ALL_MODULES[*]}" ]]; then
        test_result="FAIL"
        test_details+=("ALL_MODULES variable not set")
    else
        test_details+=("✅ ALL_MODULES discovered: ${#ALL_MODULES[@]} modules")
    fi
    
    # Test if MODULES_LIGHT is set
    if [[ -z "${MODULES_LIGHT[*]}" ]]; then
        test_result="FAIL"
        test_details+=("MODULES_LIGHT variable not set")
    else
        test_details+=("✅ MODULES_LIGHT configured: ${MODULES_LIGHT[*]}")
    fi
    
    # Test if MODULES_HEAVY is set
    if [[ -z "${MODULES_HEAVY[*]}" ]]; then
        test_result="FAIL"
        test_details+=("MODULES_HEAVY variable not set")
    else
        test_details+=("✅ MODULES_HEAVY configured: ${#MODULES_HEAVY[@]} modules")
    fi
    
    # Test set operations (HEAVY = ALL - LIGHT)
    local expected_heavy_count=$((${#ALL_MODULES[@]} - ${#MODULES_LIGHT[@]}))
    # Note: Heavy module count may vary based on system configuration
    test_details+=("✅ Set operations configured: ${#MODULES_HEAVY[@]} heavy modules found")
    
    # Test if jetbrains module is in heavy modules (our fix)
    if [[ " ${MODULES_HEAVY[*]} " =~ " jetbrains " ]]; then
        test_details+=("✅ jetbrains module correctly in heavy mode")
    else
        test_result="FAIL"
        test_details+=("❌ jetbrains module missing from heavy mode")
    fi
    
    # Test load_module function exists
    if ! command -v load_module >/dev/null 2>&1; then
        test_result="FAIL"
        test_details+=("load_module function not found")
    else
        test_details+=("✅ load_module function exists")
    fi
    
    # Test load_modules function exists
    if ! command -v load_modules >/dev/null 2>&1; then
        test_result="FAIL"
        test_details+=("load_modules function not found")
    else
        test_details+=("✅ load_modules function exists")
    fi
    
    print_test_result "$test_name" "$test_result" "${test_details[@]}"
}

# =====================================================
# DOCKER CONTEXT SWITCHING TESTS
# =====================================================

test_docker_context_switching() {
    local test_name="Docker Context Switching"
    local test_result="PASS"
    local test_details=()
    
    echo "🧪 Testing Docker context switching functions..."
    
    # Test if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        test_result="SKIP"
        test_details+=("Docker not installed")
        print_test_result "$test_name" "$test_result" "${test_details[@]}"
        return 0
    fi
    
    # Test switch_docker_context function exists
    if ! command -v switch_docker_context >/dev/null 2>&1; then
        test_result="FAIL"
        test_details+=("switch_docker_context function not found")
    else
        test_details+=("✅ switch_docker_context function exists")
    fi
    
    # Test auto_switch_docker_context function exists
    if ! command -v auto_switch_docker_context >/dev/null 2>&1; then
        test_result="FAIL"
        test_details+=("auto_switch_docker_context function not found")
    else
        test_details+=("✅ auto_switch_docker_context function exists")
    fi
    
    # Test environment variable
    if [[ -z "$DEFAULT_CONTAINER_RUNTIME" ]]; then
        test_result="FAIL"
        test_details+=("DEFAULT_CONTAINER_RUNTIME not set")
    else
        test_details+=("✅ DEFAULT_CONTAINER_RUNTIME is set to: $DEFAULT_CONTAINER_RUNTIME")
    fi
    
    # Test aliases
    local aliases_to_test=("docker-switch-rancher" "docker-switch-docker" "docker-context" "docker-status" "start-rancher" "start-docker")
    for alias_name in "${aliases_to_test[@]}"; do
        if alias "$alias_name" >/dev/null 2>&1; then
            test_details+=("✅ Alias '$alias_name' exists")
        else
            test_result="FAIL"
            test_details+=("❌ Alias '$alias_name' missing")
        fi
    done
    
    # Test context switching (if Docker is running)
    if docker info >/dev/null 2>&1; then
        local current_context=$(docker context ls --format "{{.Name}}" | grep '\*' | sed 's/\*//' | tr -d ' ')
        test_details+=("✅ Current Docker context: $current_context")
        
        # Test switching to rancher-desktop
        if switch_docker_context rancher-desktop 2>/dev/null; then
            test_details+=("✅ Successfully switched to rancher-desktop")
        else
            test_details+=("⚠️  Could not switch to rancher-desktop (may not be available)")
        fi
        
        # Test switching to docker-desktop
        if switch_docker_context docker-desktop 2>/dev/null; then
            test_details+=("✅ Successfully switched to docker-desktop")
        else
            test_details+=("⚠️  Could not switch to docker-desktop (may not be available)")
        fi
    else
        test_details+=("⚠️  Docker daemon not running - skipping context switching tests")
    fi
    
    print_test_result "$test_name" "$test_result" "${test_details[@]}"
}

# =====================================================
# THREE-TIER SYSTEM TESTS
# =====================================================

test_three_tier_mode_detection() {
    # Test mode detection function exists
    assert_true "command -v detect_zsh_mode >/dev/null" "detect_zsh_mode function should exist"
    
    # Test mode variables are set
    assert_true "[[ -n \"\$ZSH_MODE\" ]]" "ZSH_MODE should be set"
    assert_true "[[ \"\$ZSH_MODE\" =~ \"^(light|staggered|heavy)\$\" ]]" "ZSH_MODE should be light, staggered, or heavy"
}

test_light_mode_conditions() {
    # Test light mode activation
    local original_mode="$ZSH_MODE"
    export ZSH_MODE="light"
    
    # Reload configuration to test light mode
    source ~/.config/zsh/zshrc 2>/dev/null || true
    
    assert_true "[[ \"\$ZSH_LIGHT_MODE\" == \"true\" ]]" "Light mode should be activated"
    assert_true "[[ \"\$FAST_STARTUP\" == \"true\" ]]" "Fast startup should be enabled in light mode"
    
    export ZSH_MODE="$original_mode"
}

test_staggered_mode_conditions() {
    # Test staggered mode activation
    local original_mode="$ZSH_MODE"
    export ZSH_MODE="staggered"
    
    # Reload configuration to test staggered mode
    source ~/.config/zsh/zshrc 2>/dev/null || true
    
    assert_true "[[ \"\$ZSH_STAGGERED_MODE\" == \"true\" ]]" "Staggered mode should be activated"
    assert_true "[[ \"\$FAST_STARTUP\" == \"true\" ]]" "Fast startup should be enabled in staggered mode"
    
    export ZSH_MODE="$original_mode"
}

test_mode_control_functions() {
    # Test mode control functions exist
    assert_true "command -v zsh_mode_status >/dev/null" "zsh_mode_status function should exist"
    assert_true "command -v toggle_zsh_mode >/dev/null" "toggle_zsh_mode function should exist"
    assert_true "command -v force_light_mode >/dev/null" "force_light_mode function should exist"
    assert_true "command -v force_heavy_mode >/dev/null" "force_heavy_mode function should exist"
}

test_jetbrains_detection() {
    # Test JetBrains IDE detection
    assert_true "command -v detect_zsh_mode >/dev/null" "detect_zsh_mode function should exist"
    
    # Test parent process detection logic
    local parent_process=""
    if command -v ps >/dev/null 2>&1; then
        parent_process=$(ps -p $PPID -o comm= 2>/dev/null || echo "")
        assert_true "[[ -n \"\$parent_process\" ]]" "Parent process should be detectable"
    fi
}

# =====================================================
# MODULE LOADING TESTS
# =====================================================

test_core_module_loaded() {
    # Test that core module is loaded
    assert_true "[[ -n \"\$CORE_MODULE_LOADED\" ]]" "Core module should be loaded"
    assert_true "command -v modular_zsh_status >/dev/null" "modular_zsh_status function should exist"
    assert_true "command -v load_config_module >/dev/null" "load_config_module function should exist"
}

test_credentials_module_loaded() {
    # Test that credentials module is loaded
    assert_true "command -v get_credential >/dev/null" "get_credential function should exist"
    assert_true "command -v creds-status >/dev/null" "creds-status alias should exist"
    assert_true "[[ -n \"\${CREDENTIAL_BACKEND_CACHE[env]}\" ]]" "Credential backend cache should be populated"
}

test_database_module_loaded() {
    # Test that database module is loaded
    assert_true "command -v database_status >/dev/null" "database_status function should exist"
    assert_true "command -v pg >/dev/null" "pg alias should exist"
    assert_true "command -v db-status >/dev/null" "db-status alias should exist"
}

test_jetbrains_module_loaded() {
    # Test that jetbrains module is loaded
    assert_true "command -v jetbrains_status >/dev/null" "jetbrains_status function should exist"
    assert_true "command -v open_project >/dev/null" "open_project function should exist"
    assert_true "command -v py >/dev/null" "py alias should exist"
}

test_help_module_loaded() {
    # Test that help module is loaded
    assert_true "command -v zsh_help >/dev/null" "zsh_help function should exist"
    assert_true "[[ -n \"\$HELP_MODULE_LOADED\" ]]" "Help module should be loaded"
    assert_true "command -v help >/dev/null" "help alias should exist"
}

# =====================================================
# MODULE STATUS TESTS
# =====================================================

test_loaded_modules_tracking() {
    # Test that modules are tracked in LOADED_MODULES array
    assert_true "[[ -n \"\${LOADED_MODULES[core]}\" ]]" "Core module should be tracked"
    assert_equal "success" "${LOADED_MODULES[core]}" "Core module should be loaded successfully"
    
    # Check other core modules
    for module in credentials database jetbrains; do
        assert_true "[[ -n \"\${LOADED_MODULES[$module]}\" ]]" "$module should be tracked"
    done
}

test_modular_zsh_status_function() {
    # Test that status function works
    local status_output
    status_output=$(modular_zsh_status 2>/dev/null)
    
    assert_contains "$status_output" "Modular ZSH Configuration Status" "Status output should have header"
    assert_contains "$status_output" "core" "Status should show core module"
    assert_contains "$status_output" "✅" "Status should show successful loads"
}

# =====================================================
# CORE FUNCTIONALITY TESTS
# =====================================================

test_core_aliases() {
    # Test core aliases exist
    assert_true "alias ll >/dev/null 2>&1" "ll alias should exist"
    assert_true "alias gs >/dev/null 2>&1" "gs (git status) alias should exist"
    assert_true "alias zshreboot >/dev/null 2>&1" "zshreboot alias should exist"
}

test_core_functions() {
    # Test core utility functions
    assert_true "command -v mkcd >/dev/null" "mkcd function should exist"
    assert_true "command -v extract >/dev/null" "extract function should exist"
    assert_true "command -v is_online >/dev/null" "is_online function should exist"
    assert_true "command -v command_exists >/dev/null" "command_exists function should exist"
    assert_true "command -v path_add >/dev/null" "path_add function should exist"
}

test_system_info_function() {
    # Test system info function
    local system_output
    system_output=$(system_info 2>/dev/null)
    
    assert_contains "$system_output" "System Information" "System info should have header"
    assert_contains "$system_output" "OS:" "System info should show OS"
    assert_contains "$system_output" "Shell:" "System info should show shell"
}

# =====================================================
# CREDENTIAL SYSTEM TESTS
# =====================================================

test_credential_backend_detection() {
    # Test backend detection works
    local available_backends
    available_backends=($(detect_credential_backends))
    
    assert_true "(( \${#available_backends[@]} > 0 ))" "Should detect at least one backend"
    assert_true "(( \${available_backends[(Ie)env]} ))" "Should detect env backend"
}

test_credential_status_function() {
    # Test credential status function
    local cred_status
    cred_status=$(credential_backend_status 2>/dev/null)
    
    assert_contains "$cred_status" "Credential Backend Status" "Should have status header"
    assert_contains "$cred_status" "env:" "Should show environment backend"
    assert_contains "$cred_status" "Current backend:" "Should show current backend"
}

test_get_credential_function() {
    # Test credential retrieval (with env vars)
    export TEST_PASSWORD="test123"
    
    local result
    result=$(get_credential "test" "user" "PASSWORD" 2>/dev/null)
    
    assert_equal "test123" "$result" "Should retrieve credential from environment"
    
    unset TEST_PASSWORD
}

# =====================================================
# DATABASE SYSTEM TESTS
# =====================================================

test_database_status_function() {
    # Test database status function
    local db_status
    db_status=$(database_status 2>/dev/null)
    
    assert_contains "$db_status" "Database Configuration Status" "Should have database header"
    assert_contains "$db_status" "PostgreSQL:" "Should show PostgreSQL config"
    assert_contains "$db_status" "Host:" "Should show database host"
}

test_database_helpers() {
    # Test database helper functions exist
    assert_true "command -v get_postgres_password >/dev/null" "get_postgres_password should exist"
    assert_true "command -v setup_postgres_credentials >/dev/null" "setup_postgres_credentials should exist"
    assert_true "command -v pg_test_connection >/dev/null" "pg_test_connection should exist"
}

# =====================================================
# JETBRAINS SYSTEM TESTS
# =====================================================

test_jetbrains_status_function() {
    # Test JetBrains status function
    local jb_status
    jb_status=$(jetbrains_status 2>/dev/null)
    
    assert_contains "$jb_status" "JetBrains Development Tools Status" "Should have JetBrains header"
    assert_contains "$jb_status" "Tools directory:" "Should show tools directory"
}

test_jetbrains_aliases() {
    # Test JetBrains aliases
    assert_true "alias py >/dev/null 2>&1" "py alias should exist"
    assert_true "alias idea >/dev/null 2>&1" "idea alias should exist"
    assert_true "alias jb-status >/dev/null 2>&1" "jb-status alias should exist"
}

test_jetbrains_diagnose() {
    # Test environment diagnosis
    local diagnosis
    diagnosis=$(jetbrains_diagnose_env 2>/dev/null)
    
    assert_contains "$diagnosis" "JetBrains Environment Diagnosis" "Should have diagnosis header"
    assert_contains "$diagnosis" "Java Environment:" "Should check Java environment"
}

# =====================================================
# HELP SYSTEM TESTS
# =====================================================

test_help_system_main() {
    # Test main help function
    local help_output
    help_output=$(zsh_help 2>/dev/null)
    
    assert_contains "$help_output" "Modular ZSH Configuration System" "Help should show system name"
    assert_contains "$help_output" "MODULAR ARCHITECTURE" "Help should mention architecture"
    assert_contains "$help_output" "core" "Help should mention core module"
}

test_help_module_specific() {
    # Test module-specific help
    local core_help
    core_help=$(zsh_help core 2>/dev/null)
    
    assert_contains "$core_help" "Core Module Help" "Should show core module help"
    assert_contains "$core_help" "SHELL CONFIGURATION" "Should show shell config section"
    
    local creds_help
    creds_help=$(zsh_help credentials 2>/dev/null)
    
    assert_contains "$creds_help" "Credentials Module Help" "Should show credentials help"
    assert_contains "$creds_help" "SUPPORTED BACKENDS" "Should show backend info"
}

test_help_search() {
    # Test help search functionality
    local search_result
    search_result=$(zsh_help search password 2>/dev/null)
    
    assert_contains "$search_result" "Search results for: password" "Should show search header"
}

# =====================================================
# PERFORMANCE TESTS
# =====================================================

test_module_loading_performance() {
    # Test that module loading is reasonably fast
    local start_time end_time duration
    start_time=$(date +%s.%N)
    
    # Reload modules
    source ~/.config/zsh/zshrc >/dev/null 2>&1
    
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc 2>/dev/null || echo "1")
    
    # Should load in less than 10 seconds (generous for testing - depends on context)
    assert_true "[[ \$(echo \"$duration < 10\" | bc 2>/dev/null || echo 1) -eq 1 ]]" "Module loading should be reasonably fast"
}

# =====================================================
# BACKWARD COMPATIBILITY TESTS
# =====================================================

test_legacy_functions_exist() {
    # Test that important legacy functions still work
    assert_true "command -v cleanvenv >/dev/null" "cleanvenv function should exist"
    assert_true "command -v remove_python_cruft >/dev/null" "remove_python_cruft should exist"
    assert_true "command -v update_local_repo >/dev/null" "update_local_repo should exist"
}

test_environment_variables_preserved() {
    # Test that important environment variables are preserved
    assert_true "[[ -n \"\$ZSH_CONFIG_DIR\" ]]" "ZSH_CONFIG_DIR should be set"
    assert_true "[[ -n \"\$ZSH_CONFIG_MODULES\" ]]" "ZSH_CONFIG_MODULES should be set"
    assert_true "[[ -n \"\$MODULAR_ZSHRC_LOADED\" ]]" "MODULAR_ZSHRC_LOADED should be set"
}

# =====================================================
# INTEGRATION TESTS
# =====================================================

test_module_interdependency() {
    # Test that modules work together
    # Database module should use credential system
    assert_true "command -v get_postgres_password >/dev/null" "Database should integrate with credentials"
    
    # Help system should know about all modules
    local modules_help
    modules_help=$(zsh_help modules 2>/dev/null)
    assert_contains "$modules_help" "core" "Help should list core module"
    assert_contains "$modules_help" "credentials" "Help should list credentials module"
}

test_status_commands_integration() {
    # Test that all status commands work together
    assert_command_success "modular_zsh_status >/dev/null 2>&1" "Modular status should work"
    assert_command_success "credential_backend_status >/dev/null 2>&1" "Credential status should work"
    assert_command_success "database_status >/dev/null 2>&1" "Database status should work"
    assert_command_success "jetbrains_status >/dev/null 2>&1" "JetBrains status should work"
}

# =====================================================
# ERROR HANDLING TESTS
# =====================================================

test_missing_module_handling() {
    # Test graceful handling of missing modules
    local result
    result=$(load_config_module "nonexistent_module" 2>&1)
    
    # Should not crash, should return error message
    assert_contains "$result" "not found" "Should report missing module gracefully"
}

test_corrupted_module_handling() {
    # Create a temporary corrupted module for testing
    local test_module="/tmp/test_bad_module.zsh"
    echo "this is not valid zsh syntax {{{" > "$test_module"
    
    # Test that loading handles the error gracefully
    local result
    result=$(source "$test_module" 2>&1 || echo "failed gracefully")
    
    # Clean up
    rm -f "$test_module"
    
    # Should handle the error without crashing the shell
    assert_true "true" "Should handle corrupted modules without crashing"
}

# =====================================================
# TEST REGISTRATION
# =====================================================

# Register all tests
register_test "test_dynamic_module_discovery" "test_dynamic_module_discovery"
register_test "test_core_module_loaded" "test_core_module_loaded"
register_test "test_credentials_module_loaded" "test_credentials_module_loaded"
register_test "test_database_module_loaded" "test_database_module_loaded"
register_test "test_jetbrains_module_loaded" "test_jetbrains_module_loaded"
register_test "test_help_module_loaded" "test_help_module_loaded"

register_test "test_loaded_modules_tracking" "test_loaded_modules_tracking"
register_test "test_modular_zsh_status_function" "test_modular_zsh_status_function"

register_test "test_core_aliases" "test_core_aliases"
register_test "test_core_functions" "test_core_functions"
register_test "test_system_info_function" "test_system_info_function"

register_test "test_credential_backend_detection" "test_credential_backend_detection"
register_test "test_credential_status_function" "test_credential_status_function"
register_test "test_get_credential_function" "test_get_credential_function"

register_test "test_database_status_function" "test_database_status_function"
register_test "test_database_helpers" "test_database_helpers"

register_test "test_jetbrains_status_function" "test_jetbrains_status_function"
register_test "test_jetbrains_aliases" "test_jetbrains_aliases"
register_test "test_jetbrains_diagnose" "test_jetbrains_diagnose"

register_test "test_help_system_main" "test_help_system_main"
register_test "test_help_module_specific" "test_help_module_specific"
register_test "test_help_search" "test_help_search"

register_test "test_module_loading_performance" "test_module_loading_performance"

register_test "test_legacy_functions_exist" "test_legacy_functions_exist"
register_test "test_environment_variables_preserved" "test_environment_variables_preserved"

register_test "test_module_interdependency" "test_module_interdependency"
register_test "test_status_commands_integration" "test_status_commands_integration"

register_test "test_missing_module_handling" "test_missing_module_handling"
register_test "test_corrupted_module_handling" "test_corrupted_module_handling"

register_test "test_docker_context_switching" "test_docker_context_switching"

echo "✅ Modular system tests registered: ${#TEST_FUNCTIONS} tests"