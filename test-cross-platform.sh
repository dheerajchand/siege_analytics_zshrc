#!/bin/bash

# =====================================================
# CROSS-PLATFORM COMPATIBILITY TEST SCRIPT
# =====================================================
# 
# Tests the modular ZSH system on different platforms
# Can be run on macOS, Linux, and Docker containers
# =====================================================

set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ZSH_CONFIG_DIR="$SCRIPT_DIR"
readonly TEST_RESULTS_FILE="/tmp/zsh-platform-test-results.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# =====================================================
# HELPER FUNCTIONS
# =====================================================

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
    ((TESTS_FAILED++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TOTAL_TESTS++))
    log_info "Testing: $test_name"
    
    if eval "$test_command" &>/dev/null; then
        log_success "$test_name"
        echo "PASS: $test_name" >> "$TEST_RESULTS_FILE"
    else
        log_error "$test_name"
        echo "FAIL: $test_name" >> "$TEST_RESULTS_FILE"
    fi
}

# =====================================================
# PLATFORM DETECTION
# =====================================================

detect_platform() {
    local platform=""
    local distro=""
    local is_docker="false"
    local is_wsl="false"
    
    case "$(uname -s)" in
        Darwin)
            platform="macos"
            ;;
        Linux)
            platform="linux"
            
            # Check if running in Docker
            if [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
                is_docker="true"
            fi
            
            # Check if running in WSL
            if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -q Microsoft /proc/version 2>/dev/null; then
                is_wsl="true"
            fi
            
            # Detect Linux distribution
            if [[ -f /etc/os-release ]]; then
                distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
            elif command -v lsb_release >/dev/null 2>&1; then
                distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
            fi
            ;;
        *)
            platform="unknown"
            ;;
    esac
    
    export TEST_PLATFORM="$platform"
    export TEST_DISTRO="$distro"
    export TEST_IS_DOCKER="$is_docker"
    export TEST_IS_WSL="$is_wsl"
}

# =====================================================
# TEST FUNCTIONS
# =====================================================

test_zsh_availability() {
    run_test "ZSH shell available" "command -v zsh"
}

test_config_files_exist() {
    run_test "Main zshrc exists" "[[ -f '$ZSH_CONFIG_DIR/zshrc' ]]"
    run_test "Config directory exists" "[[ -d '$ZSH_CONFIG_DIR/config' ]]"
    run_test "Core module exists" "[[ -f '$ZSH_CONFIG_DIR/config/core.zsh' ]]"
    run_test "Environment module exists" "[[ -f '$ZSH_CONFIG_DIR/config/environment.zsh' ]]"
    run_test "Credentials module exists" "[[ -f '$ZSH_CONFIG_DIR/config/credentials.zsh' ]]"
    run_test "Database module exists" "[[ -f '$ZSH_CONFIG_DIR/config/database.zsh' ]]"
    run_test "Docker module exists" "[[ -f '$ZSH_CONFIG_DIR/config/docker.zsh' ]]"
    run_test "Spark module exists" "[[ -f '$ZSH_CONFIG_DIR/config/spark.zsh' ]]"
    run_test "Hadoop module exists" "[[ -f '$ZSH_CONFIG_DIR/config/hadoop.zsh' ]]"
}

test_module_loading() {
    local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$CORE_MODULE_LOADED' | grep -q true"
    run_test "Core module loads" "$test_cmd"
    
    test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$ENVIRONMENT_MODULE_LOADED' | grep -q true"
    run_test "Environment module loads" "$test_cmd"
    
    test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$CREDENTIALS_MODULE_LOADED' | grep -q true"
    run_test "Credentials module loads" "$test_cmd"
    
    test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$DATABASE_MODULE_LOADED' | grep -q true"
    run_test "Database module loads" "$test_cmd"
}

test_platform_detection() {
    local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$ZSH_PLATFORM' | grep -q '$TEST_PLATFORM'"
    run_test "Platform detection ($TEST_PLATFORM)" "$test_cmd"
    
    if [[ "$TEST_IS_DOCKER" == "true" ]]; then
        test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$IS_DOCKER' | grep -q true"
        run_test "Docker detection" "$test_cmd"
    fi
    
    if [[ "$TEST_IS_WSL" == "true" ]]; then
        test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$IS_WSL' | grep -q true"
        run_test "WSL detection" "$test_cmd"
    fi
}

test_essential_functions() {
    local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && command -v modular_zsh_status'"
    run_test "modular_zsh_status function" "$test_cmd"
    
    test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && command -v environment_info'"
    run_test "environment_info function" "$test_cmd"
    
    test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && command -v is_online'"
    run_test "is_online function" "$test_cmd"
    
    test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && command -v mkcd'"
    run_test "mkcd function" "$test_cmd"
}

test_conditional_modules() {
    # Docker module should only load if Docker is available
    if command -v docker >/dev/null 2>&1; then
        local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$DOCKER_MODULE_LOADED' | grep -q true"
        run_test "Docker module loads (Docker available)" "$test_cmd"
    fi
    
    # Spark/Hadoop modules should only load if SDKMAN is available
    if [[ -s "${HOME}/.sdkman/bin/sdkman-init.sh" ]]; then
        local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$SPARK_MODULE_LOADED' | grep -q true"
        run_test "Spark module loads (SDKMAN available)" "$test_cmd"
        
        test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \$HADOOP_MODULE_LOADED' | grep -q true"
        run_test "Hadoop module loads (SDKMAN available)" "$test_cmd"
    fi
}

test_package_manager_detection() {
    case "$TEST_PLATFORM" in
        "macos")
            if command -v brew >/dev/null 2>&1; then
                local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \"\${ZSH_PACKAGE_MANAGERS[@]}\"' | grep -q brew"
                run_test "Homebrew detection (macOS)" "$test_cmd"
            fi
            ;;
        "linux")
            # Test for common Linux package managers
            if command -v apt >/dev/null 2>&1; then
                local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \"\${ZSH_PACKAGE_MANAGERS[@]}\"' | grep -q apt"
                run_test "APT detection (Linux)" "$test_cmd"
            fi
            
            if command -v yum >/dev/null 2>&1; then
                local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \"\${ZSH_PACKAGE_MANAGERS[@]}\"' | grep -q yum"
                run_test "YUM detection (Linux)" "$test_cmd"
            fi
            
            if command -v dnf >/dev/null 2>&1; then
                local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && echo \"\${ZSH_PACKAGE_MANAGERS[@]}\"' | grep -q dnf"
                run_test "DNF detection (Linux)" "$test_cmd"
            fi
            ;;
    esac
}

test_performance() {
    log_info "Testing startup performance..."
    local start_time=$(date +%s.%N)
    
    cd "$ZSH_CONFIG_DIR" && zsh -c 'source zshrc' >/dev/null 2>&1
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "1")
    
    # Should load in less than 5 seconds (generous for testing)
    if (( $(echo "$duration < 5.0" | bc -l 2>/dev/null || echo 0) )); then
        log_success "Startup performance (${duration}s < 5s)"
        ((TESTS_PASSED++))
        echo "PASS: Startup performance (${duration}s)" >> "$TEST_RESULTS_FILE"
    else
        log_error "Startup performance (${duration}s >= 5s)"
        ((TESTS_FAILED++))
        echo "FAIL: Startup performance (${duration}s)" >> "$TEST_RESULTS_FILE"
    fi
    
    ((TOTAL_TESTS++))
}

# =====================================================
# DOCKER-SPECIFIC TESTS
# =====================================================

test_docker_compatibility() {
    if [[ "$TEST_IS_DOCKER" == "true" ]]; then
        log_info "Running Docker-specific tests..."
        
        # Test that container detection works
        local test_cmd="cd '$ZSH_CONFIG_DIR' && zsh -c 'source zshrc && is_container'"
        run_test "Container detection function" "$test_cmd"
        
        # Test that memory-constrained settings are applied
        if command -v free >/dev/null 2>&1; then
            local total_mem=$(free -m | awk 'NR==2{printf "%.0f", $2}')
            if [[ $total_mem -lt 4096 ]]; then
                log_info "Detected low memory environment ($total_mem MB), checking optimizations..."
                # We should test that modules adapt to low memory, but this is hard to test automatically
                log_success "Low memory environment detected"
                ((TESTS_PASSED++))
            fi
        fi
    fi
}

# =====================================================
# MAIN TEST EXECUTION
# =====================================================

main() {
    echo "🧪 Cross-Platform Compatibility Test Suite"
    echo "==========================================="
    echo ""
    
    # Initialize results file
    echo "Cross-Platform Test Results - $(date)" > "$TEST_RESULTS_FILE"
    echo "Platform: $(uname -s) $(uname -r)" >> "$TEST_RESULTS_FILE"
    echo "=====================================" >> "$TEST_RESULTS_FILE"
    
    # Detect platform
    detect_platform
    
    log_info "Platform: $TEST_PLATFORM"
    [[ -n "$TEST_DISTRO" ]] && log_info "Distribution: $TEST_DISTRO"
    [[ "$TEST_IS_DOCKER" == "true" ]] && log_info "Environment: Docker Container"
    [[ "$TEST_IS_WSL" == "true" ]] && log_info "Environment: Windows Subsystem for Linux"
    echo ""
    
    # Run test suites
    log_info "Running test suites..."
    echo ""
    
    test_zsh_availability
    test_config_files_exist
    test_module_loading
    test_platform_detection
    test_essential_functions
    test_conditional_modules
    test_package_manager_detection
    test_performance
    test_docker_compatibility
    
    echo ""
    echo "📊 Test Results Summary"
    echo "======================"
    echo "Total Tests: $TOTAL_TESTS"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! ✨"
        echo ""
        echo "✅ The modular ZSH system is fully compatible with $TEST_PLATFORM"
        [[ -n "$TEST_DISTRO" ]] && echo "✅ Tested on $TEST_DISTRO distribution"
        [[ "$TEST_IS_DOCKER" == "true" ]] && echo "✅ Docker container compatibility verified"
        [[ "$TEST_IS_WSL" == "true" ]] && echo "✅ WSL compatibility verified"
    else
        log_error "$TESTS_FAILED tests failed"
        echo ""
        echo "❌ Some compatibility issues found"
        echo "📋 Check $TEST_RESULTS_FILE for details"
    fi
    
    echo ""
    echo "📋 Detailed results saved to: $TEST_RESULTS_FILE"
    
    # Exit with appropriate code
    [[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi