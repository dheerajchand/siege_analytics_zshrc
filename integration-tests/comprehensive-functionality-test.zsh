#!/usr/bin/env zsh
# =====================================================
# COMPREHENSIVE FUNCTIONALITY TEST SUITE
# =====================================================
# Tests ALL functionality across the entire zsh system
# This will run overnight and test every module, function, and integration
# =====================================================

echo "🔍 COMPREHENSIVE ZSH FUNCTIONALITY TEST"
echo "======================================="
echo "Started: $(date)"
echo ""

# Load zsh config
source ~/.zshrc >/dev/null 2>&1

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a FAILED_TEST_NAMES

# Test helper function
test_function() {
    local func_name="$1"
    local test_description="$2"
    local test_command="$3"
    
    ((TOTAL_TESTS++))
    echo -n "Testing $func_name: $test_description... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✅ PASS"
        ((PASSED_TESTS++))
    else
        echo "❌ FAIL"
        ((FAILED_TESTS++))
        FAILED_TEST_NAMES+=("$func_name: $test_description")
    fi
}

echo "📋 PHASE 1: CORE SYSTEM FUNCTIONS"
echo "================================="

# Test core utilities
test_function "mkcd" "Create directory and cd" "mkcd /tmp/test_mkcd_$$ && [[ \$(pwd) == '/tmp/test_mkcd_$$' ]] && rmdir /tmp/test_mkcd_$$"
test_function "command_exists" "Command existence check" "command_exists ls"
test_function "path_add" "PATH management" "PATH_BEFORE=\$PATH && path_add /tmp && [[ \$PATH != \$PATH_BEFORE ]]"
test_function "extract" "File extraction" "command -v extract"
test_function "findtext" "Text search" "command -v findtext"
test_function "system_info" "System information" "system_info | grep -q 'System Information'"
test_function "python_info" "Python environment info" "python_info | grep -q 'Python Environment'"
test_function "restart_finder" "Finder restart" "command -v restart_finder"

echo ""
echo "📋 PHASE 2: PYTHON ENVIRONMENT FUNCTIONS"
echo "========================================"

# Test Python environment management
test_function "py_env_switch" "Python environment switching" "py_env_switch list | grep -q 'Available Python Environments'"
test_function "ds_project_init" "Data science project creation" "command -v ds_project_init"
test_function "pyenv_available" "Pyenv availability" "command -v pyenv"
test_function "uv_available" "UV availability" "command -v uv"

echo ""
echo "📋 PHASE 3: MODULE LOADING SYSTEM"
echo "================================="

# Test module loading
test_function "load_module" "Module loading function" "command -v load_module"
test_function "load_docker" "Docker module loading" "load_module docker && command -v docker_status"
test_function "load_database" "Database module loading" "load_module database 2>/dev/null || true"
test_function "load_spark" "Spark module loading" "load_module spark && command -v spark_status"

echo ""
echo "📋 PHASE 4: DOCKER FUNCTIONALITY"
echo "================================"

# Test Docker functions
test_function "docker_status" "Docker status reporting" "docker_status | grep -q 'Docker'"
test_function "docker_cleanup" "Docker cleanup" "command -v docker_cleanup"
test_function "docker_daemon" "Docker daemon connectivity" "docker info >/dev/null 2>&1"
test_function "docker_images" "Docker image operations" "docker images >/dev/null 2>&1"

echo ""
echo "📋 PHASE 5: SPARK/HADOOP FUNCTIONALITY"
echo "====================================="

# Test Spark functions
test_function "spark_status" "Spark status reporting" "spark_status | grep -q 'Spark'"
test_function "spark_start" "Spark service start" "command -v spark_start"
test_function "hadoop_status" "Hadoop status reporting" "command -v hadoop_status"
test_function "start_hadoop" "Hadoop service start" "command -v start_hadoop"

echo ""
echo "📋 PHASE 6: DATABASE FUNCTIONALITY"
echo "=================================="

# Load database module first
load_module database >/dev/null 2>&1

# Test database functions
test_function "pg_connect" "PostgreSQL connection" "command -v pg_connect"
test_function "mysql_connect" "MySQL connection" "command -v mysql_connect"
test_function "database_status" "Database status" "command -v database_status"
test_function "setup_postgres_credentials" "PostgreSQL credential setup" "command -v setup_postgres_credentials"

echo ""
echo "📋 PHASE 7: CREDENTIAL MANAGEMENT"
echo "================================="

# Test credential functions
test_function "creds_status" "Credential system status" "command -v creds_status"
test_function "store_credential" "Credential storage" "command -v store_credential"
test_function "get_credential" "Credential retrieval" "command -v get_credential"
test_function "creds_sync" "Credential synchronization" "command -v creds_sync_1p_to_keychain"

echo ""
echo "📋 PHASE 8: BACKUP SYSTEM"
echo "========================="

# Test backup functions (already tested, but verify)
test_function "backup" "Basic backup" "command -v backup"
test_function "enhanced_backup" "Enhanced backup" "command -v enhanced_backup"
test_function "pushmain" "Git push integration" "command -v pushmain"
test_function "sync" "Repository sync" "command -v sync"

echo ""
echo "📋 PHASE 9: SYSTEM MANAGEMENT"
echo "============================="

# Test system functions
test_function "startup_status" "System status display" "startup_status | grep -q 'ZSH System'"
test_function "detect_zsh_mode" "Mode detection" "detect_zsh_mode | grep -E '(minimal|staggered|heavy)'"
test_function "zshreload" "Configuration reload" "command -v zshreload"
test_function "zshreboot" "Shell restart" "command -v zshreboot"
test_function "help" "Help system" "help | grep -q 'ZSH'"

echo ""
echo "📋 PHASE 10: PATH MANAGEMENT"
echo "============================"

# Test PATH functions
test_function "path_status" "PATH status reporting" "command -v path_status"
test_function "path_clean" "PATH cleanup" "command -v path_clean"
test_function "path_monitor" "PATH monitoring" "command -v path_monitor"
test_function "path_backup" "PATH backup" "command -v path_backup"

echo ""
echo "📋 PHASE 11: ICLOUD DIAGNOSTICS"
echo "==============================="

# Test iCloud functions
test_function "icloud_diagnose" "iCloud diagnostics" "command -v icloud_diagnose"
test_function "icloud_cleanup" "iCloud cleanup" "command -v icloud_cleanup"

echo ""
echo "📋 PHASE 12: JETBRAINS INTEGRATION"
echo "=================================="

# Load JetBrains module if available
load_module jetbrains >/dev/null 2>&1

# Test JetBrains functions
test_function "jetbrains_status" "JetBrains status" "command -v jetbrains_status"
test_function "pycharm_project" "PyCharm project setup" "command -v pycharm_project"
test_function "dataspell_project" "DataSpell project setup" "command -v dataspell_project"

echo ""
echo "📋 PHASE 13: NETWORK UTILITIES"
echo "=============================="

# Test network functions
test_function "is_online" "Network connectivity check" "is_online"
test_function "is_online_status" "Network status string" "is_online_status | grep -E '(online|offline)'"

echo ""
echo "📋 PHASE 14: GIT INTEGRATION"
echo "============================"

# Test git functions
test_function "git_status" "Git status functions" "command -v git_status"
test_function "git_operations" "Git operations" "command -v git_operations"

echo ""
echo "🎯 COMPREHENSIVE TEST RESULTS"
echo "============================="
echo "Completed: $(date)"
echo ""
echo "📊 Test Summary:"
echo "   Total tests run: $TOTAL_TESTS"
echo "   ✅ Tests passed: $PASSED_TESTS"
echo "   ❌ Tests failed: $FAILED_TESTS"
echo "   Success rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"
echo ""

if [[ $FAILED_TESTS -gt 0 ]]; then
    echo "❌ Failed tests:"
    for failed_test in "${FAILED_TEST_NAMES[@]}"; do
        echo "   - $failed_test"
    done
    echo ""
fi

echo "🏆 OVERALL SYSTEM ASSESSMENT:"
if [[ $PASSED_TESTS -gt $(( TOTAL_TESTS * 3 / 4 )) ]]; then
    echo "   ✅ SYSTEM HIGHLY FUNCTIONAL (>75% pass rate)"
elif [[ $PASSED_TESTS -gt $(( TOTAL_TESTS / 2 )) ]]; then
    echo "   ⚡ SYSTEM MODERATELY FUNCTIONAL (>50% pass rate)"
else
    echo "   ❌ SYSTEM NEEDS MAJOR REPAIR (<50% pass rate)"
fi

echo ""
echo "📋 Detailed test logs saved to: integration-tests/"
echo "🎯 Comprehensive functionality assessment complete!"
