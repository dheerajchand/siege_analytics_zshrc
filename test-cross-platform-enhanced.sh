#!/usr/bin/env bash

# =====================================================
# COMPREHENSIVE CROSS-PLATFORM TEST SUITE
# =====================================================
#
# Tests the modular ZSH configuration system on:
# - Multiple shells (bash, zsh)
# - Multiple platforms (macOS, Linux, Docker, WSL)
# - All major functions and modules
# =====================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# =====================================================
# TEST FRAMEWORK
# =====================================================

log_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
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

log_header() {
    echo -e "\n${PURPLE}═══════════════════════════════════════${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════${NC}"
}

test_function() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_TOTAL++))
    log_info "Testing: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        log_success "$test_name"
    else
        log_error "$test_name - Command failed: $test_command"
    fi
}

test_function_exists() {
    local function_name="$1"
    
    ((TESTS_TOTAL++))
    if declare -f "$function_name" >/dev/null 2>&1; then
        log_success "Function exists: $function_name"
    else
        log_error "Function missing: $function_name"
    fi
}

test_command_exists() {
    local command_name="$1"
    local description="$2"
    
    ((TESTS_TOTAL++))
    if command -v "$command_name" >/dev/null 2>&1; then
        log_success "$description: $command_name"
    else
        log_warning "$description: $command_name (not installed)"
        # Don't count as failure since some tools are optional
        ((TESTS_TOTAL--))
    fi
}

# =====================================================
# SYSTEM DETECTION
# =====================================================

detect_platform() {
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "macos"
    elif [[ "$(uname -s)" == "Linux" ]]; then
        if [[ -f "/.dockerenv" ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
            echo "docker"
        elif [[ -n "${WSL_DISTRO_NAME}" ]] || [[ -n "${WSLENV}" ]]; then
            echo "wsl"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# =====================================================
# MAIN TEST SUITE
# =====================================================

main() {
    local platform=$(detect_platform)
    local shell=$(detect_shell)
    
    log_header "MODULAR ZSH CONFIGURATION TEST SUITE"
    log_info "Platform: $platform"
    log_info "Shell: $shell"
    log_info "Config Directory: $HOME/.config/zsh"
    echo ""
    
    # Source the configuration
    log_info "Loading modular configuration..."
    if source "$HOME/.config/zsh/zshrc" 2>/dev/null; then
        log_success "Configuration loaded successfully"
    else
        log_error "Failed to load configuration"
        exit 1
    fi
    
    # Test 1: Shell Compatibility
    log_header "SHELL COMPATIBILITY TESTS"
    test_function_exists "detect_shell"
    test_function_exists "detect_platform"
    test_function_exists "platform_open"
    test_function_exists "platform_copy"
    test_function_exists "platform_paste"
    test_function_exists "path_add"
    
    # Test 2: Core Functions
    log_header "CORE FUNCTION TESTS"
    test_function_exists "command_exists"
    test_function_exists "is_online"
    test_function_exists "mkcd"
    test_function_exists "extract"
    test_function_exists "reload_shell"
    test_function_exists "python_info"
    test_function_exists "py_env_switch"
    test_function_exists "ds_project_init"
    
    # Test 3: Environment Detection
    log_header "ENVIRONMENT DETECTION TESTS"
    test_function "ZSH_PLATFORM set" '[[ -n "$ZSH_PLATFORM" ]]'
    test_function "ZSH_IS_DOCKER set" '[[ -n "$ZSH_IS_DOCKER" ]]'
    test_function "SHELL_COMPAT_MODULE_LOADED" '[[ "$SHELL_COMPAT_MODULE_LOADED" == "true" ]]'
    
    # Test 4: Package Manager Detection
    log_header "PACKAGE MANAGER TESTS"
    test_command_exists "brew" "Homebrew"
    test_command_exists "uv" "UV Python package manager"
    test_command_exists "pyenv" "Python version manager"
    test_command_exists "java" "Java runtime"
    test_command_exists "python" "Python interpreter"
    
    # Test 5: Big Data Tools (if available)
    log_header "BIG DATA TOOLS TESTS"
    if command -v spark-submit >/dev/null 2>&1; then
        test_function_exists "spark_status"
        test_function_exists "smart_spark_submit"
        test_function_exists "get_spark_dependencies"
        test_function_exists "pyspark_shell"
        test_function "SPARK_HOME set" '[[ -n "$SPARK_HOME" ]]'
        test_function "Spark dependencies generation" 'get_spark_dependencies | grep -q "packages\|jars"'
    else
        log_warning "Spark not installed - skipping Spark tests"
    fi
    
    if command -v hadoop >/dev/null 2>&1; then
        test_function_exists "hadoop_status"
        test_function_exists "start_hadoop"
        test_function "HADOOP_HOME set" '[[ -n "$HADOOP_HOME" ]]'
    else
        log_warning "Hadoop not installed - skipping Hadoop tests"
    fi
    
    # Test 6: Database Integration
    log_header "DATABASE INTEGRATION TESTS"
    test_function_exists "database_status"
    test_function_exists "credential_backend_status"
    
    # Test 7: Docker Integration (if available)
    log_header "DOCKER INTEGRATION TESTS"
    if command -v docker >/dev/null 2>&1; then
        test_function_exists "docker_status"
        test_function_exists "docker_cleanup"
    else
        log_warning "Docker not installed - skipping Docker tests"
    fi
    
    # Test 8: JetBrains Integration
    log_header "JETBRAINS INTEGRATION TESTS"
    test_function_exists "jetbrains_diagnose_env"
    test_function_exists "open_project"
    
    # Test 9: Python/UV Integration
    log_header "PYTHON/UV INTEGRATION TESTS"
    test_function "Python version detection" 'python --version | grep -q "Python"'
    
    if command -v uv >/dev/null 2>&1; then
        test_function "UV version detection" 'uv --version | grep -q "uv"'
        # Test UV auto-activation function
        test_function_exists "uv_auto_activate"
    fi
    
    # Test 10: Cross-Platform Utilities
    log_header "CROSS-PLATFORM UTILITY TESTS"
    
    # Test platform_open with a safe file
    echo "test" > /tmp/test_file.txt
    case "$platform" in
        "macos")
            test_function "Platform open (macOS)" 'platform_open /tmp/test_file.txt'
            ;;
        "linux"|"docker"|"wsl")
            # Only test if we have a display or are in WSL
            if [[ -n "$DISPLAY" ]] || [[ "$platform" == "wsl" ]]; then
                test_function "Platform open (Linux)" 'platform_open /tmp/test_file.txt'
            else
                log_warning "No display detected - skipping GUI tests"
            fi
            ;;
    esac
    rm -f /tmp/test_file.txt
    
    # Test clipboard operations (basic test)
    case "$platform" in
        "macos")
            test_function "Clipboard test (macOS)" 'echo "test" | platform_copy && platform_paste | grep -q "test"'
            ;;
        "linux")
            if command -v xclip >/dev/null 2>&1 || command -v xsel >/dev/null 2>&1; then
                test_function "Clipboard test (Linux)" 'echo "test" | platform_copy && platform_paste | grep -q "test"'
            else
                log_warning "No clipboard utility found - install xclip or xsel"
            fi
            ;;
        "wsl")
            test_function "Clipboard test (WSL)" 'echo "test" | platform_copy'
            ;;
    esac
    
    # Test 11: Module Status
    log_header "MODULE STATUS TESTS"
    test_function_exists "modular_zsh_status"
    test_function "Module status execution" 'modular_zsh_status | grep -q "Module Status"'
    
    # Test 12: Help System
    log_header "HELP SYSTEM TESTS"
    test_function_exists "zsh_help"
    if declare -f zsh_help >/dev/null 2>&1; then
        test_function "Help system basic test" 'zsh_help modules | grep -q "Core Modules"'
    fi
    
    # Test 13: Aliases
    log_header "ALIAS TESTS"
    local expected_aliases=(
        "ll"
        "la"
        "l"
        "py-switch"
        "py-info"
        "ds-init"
        "spark-status"
        "env-info"
    )
    
    for alias_name in "${expected_aliases[@]}"; do
        ((TESTS_TOTAL++))
        if alias "$alias_name" >/dev/null 2>&1; then
            log_success "Alias exists: $alias_name"
        else
            log_warning "Alias missing: $alias_name (may be optional)"
            ((TESTS_TOTAL--))
        fi
    done
    
    # Test 14: Performance Test
    log_header "PERFORMANCE TESTS"
    log_info "Testing configuration reload time..."
    
    local start_time=$(date +%s.%N)
    source "$HOME/.config/zsh/zshrc" >/dev/null 2>&1
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "N/A")
    
    if [[ "$duration" != "N/A" ]]; then
        log_info "Configuration reload time: ${duration}s"
        if (( $(echo "$duration < 3.0" | bc -l) )); then
            log_success "Performance test: Fast startup (<3s)"
            ((TESTS_PASSED++))
        else
            log_warning "Performance test: Slow startup (>3s)"
        fi
        ((TESTS_TOTAL++))
    fi
    
    # Final Results
    log_header "TEST RESULTS SUMMARY"
    log_info "Platform: $platform"
    log_info "Shell: $shell"
    log_info "Total Tests: $TESTS_TOTAL"
    log_success "Passed: $TESTS_PASSED"
    log_error "Failed: $TESTS_FAILED"
    
    local success_rate=$((TESTS_PASSED * 100 / TESTS_TOTAL))
    log_info "Success Rate: ${success_rate}%"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 ALL TESTS PASSED! Configuration is working perfectly.${NC}\n"
        return 0
    elif [[ $success_rate -ge 80 ]]; then
        echo -e "\n${YELLOW}⚠️  Most tests passed. Check warnings above.${NC}\n"
        return 0
    else
        echo -e "\n${RED}❌ SIGNIFICANT ISSUES FOUND. Please review failures.${NC}\n"
        return 1
    fi
}

# Run tests
main "$@"