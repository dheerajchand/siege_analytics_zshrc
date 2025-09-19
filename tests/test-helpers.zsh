#!/usr/bin/env zsh

# =====================================================
# TEST HELPER FUNCTIONS
# =====================================================
#
# Comprehensive test helpers that handle function detection,
# module loading, and context synchronization issues.
#
# =====================================================

# =====================================================
# ROBUST FUNCTION DETECTION
# =====================================================

# Purpose: Reliable function existence check across all contexts
# Arguments: $1 - function name
# Returns: 0 if function exists, 1 if not
# Usage: if robust_function_exists "load_module"; then echo "exists"; fi
robust_function_exists() {
    local func_name="$1"

    # Method 1: Standard type check
    if [[ $(type -w "$func_name" 2>/dev/null) == *": function" ]]; then
        return 0
    fi

    # Method 2: Alternate type check
    if type "$func_name" >/dev/null 2>&1; then
        local func_type=$(type "$func_name" 2>/dev/null | head -1)
        if [[ "$func_type" == *"function"* ]]; then
            return 0
        fi
    fi

    # Method 3: Direct command check
    if command -v "$func_name" >/dev/null 2>&1; then
        # Check if it's actually a function
        local cmd_type=$(command -V "$func_name" 2>/dev/null)
        if [[ "$cmd_type" == *"function"* ]]; then
            return 0
        fi
    fi

    # Method 4: Declare check
    if declare -f "$func_name" >/dev/null 2>&1; then
        return 0
    fi

    return 1
}

# Purpose: Test function with actual call to verify it works
# Arguments: $1 - function name, $2 - test args (optional)
# Returns: 0 if callable, 1 if not
# Usage: if robust_function_callable "python_status" ""; then echo "callable"; fi
robust_function_callable() {
    local func_name="$1"
    local test_args="${2:-}"

    # First check if function exists
    if ! robust_function_exists "$func_name"; then
        return 1
    fi

    # Try to call with --help first
    if eval "$func_name --help" >/dev/null 2>&1; then
        return 0
    fi

    # Try to call with test args
    if [[ -n "$test_args" ]]; then
        if eval "$func_name $test_args" >/dev/null 2>&1; then
            return 0
        fi
    fi

    # Try to call with no args
    if eval "$func_name" >/dev/null 2>&1; then
        return 0
    fi

    # Function exists but not callable with our test methods
    return 1
}

# =====================================================
# MODULE LOADING SYNCHRONIZATION
# =====================================================

# Purpose: Ensure all modules are loaded before testing
# Arguments: None
# Returns: 0 when loading complete
# Usage: wait_for_module_loading_complete
wait_for_module_loading_complete() {
    local max_wait=30  # Maximum wait time in seconds
    local wait_interval=0.5
    local elapsed=0

    echo "Waiting for module loading to complete..."

    while [[ $elapsed -lt $max_wait ]]; do
        # Check if background loading is complete
        if [[ -n "$ZSH_STAGGERED_MODE" ]]; then
            # Check if all background modules are loaded
            local bg_jobs=$(jobs | wc -l)
            if [[ $bg_jobs -eq 0 ]]; then
                echo "✅ Background loading complete"
                return 0
            fi
        fi

        # Check for completion indicators
        if [[ -f "/tmp/zsh_loading_complete_$$" ]]; then
            echo "✅ Module loading completion detected"
            rm -f "/tmp/zsh_loading_complete_$$"
            return 0
        fi

        sleep $wait_interval
        elapsed=$(echo "$elapsed + $wait_interval" | bc 2>/dev/null || echo "$((elapsed + 1))")
    done

    echo "⚠️  Module loading timeout after ${max_wait}s - proceeding anyway"
    return 1
}

# Purpose: Force load a specific module with multiple fallback methods
# Arguments: $1 - module name
# Returns: 0 if loaded, 1 if failed
# Usage: force_load_module "utils"
force_load_module() {
    local module_name="$1"

    echo "Force loading module: $module_name"

    # Method 1: Use existing load_module function
    if robust_function_exists "load_module"; then
        if load_module "$module_name" >/dev/null 2>&1; then
            echo "✅ Loaded $module_name via load_module"
            return 0
        fi
    fi

    # Method 2: Direct sourcing from modules-new
    local module_file="$ZSH_CONFIG_DIR/modules-new/${module_name}.module.zsh"
    if [[ -f "$module_file" ]]; then
        if source "$module_file" >/dev/null 2>&1; then
            echo "✅ Loaded $module_name via direct sourcing (modules-new)"
            return 0
        fi
    fi

    # Method 3: Direct sourcing from config
    local config_file="$ZSH_CONFIG_DIR/config/${module_name}.zsh"
    if [[ -f "$config_file" ]]; then
        if source "$config_file" >/dev/null 2>&1; then
            echo "✅ Loaded $module_name via direct sourcing (config)"
            return 0
        fi
    fi

    # Method 4: Search for module file
    local found_module=$(find "$ZSH_CONFIG_DIR" -name "*${module_name}*" -type f | head -1)
    if [[ -n "$found_module" && -f "$found_module" ]]; then
        if source "$found_module" >/dev/null 2>&1; then
            echo "✅ Loaded $module_name via search: $found_module"
            return 0
        fi
    fi

    echo "❌ Failed to load module: $module_name"
    return 1
}

# =====================================================
# COMPREHENSIVE TEST ENVIRONMENT SETUP
# =====================================================

# Purpose: Set up complete test environment with all modules loaded
# Arguments: None
# Returns: 0 on success
# Usage: setup_comprehensive_test_environment
setup_comprehensive_test_environment() {
    echo "🔧 Setting up comprehensive test environment..."

    # Step 1: Source main configuration
    echo "  Sourcing main configuration..."
    source ~/.config/zsh/zshrc >/dev/null 2>&1 || true

    # Step 2: Wait for initial loading
    echo "  Waiting for initial loading..."
    wait_for_module_loading_complete

    # Step 3: Force load critical modules
    echo "  Force loading critical modules..."
    force_load_module "utils"
    force_load_module "python"
    force_load_module "docker"
    force_load_module "database"

    # Step 4: Verify critical functions are available
    echo "  Verifying critical function availability..."
    local critical_functions=(
        "load_module"
        "_report_missing_dependency"
        "_command_exists"
        "_directory_accessible"
    )

    local missing_functions=()
    for func in "${critical_functions[@]}"; do
        if ! robust_function_exists "$func"; then
            missing_functions+=("$func")
        fi
    done

    if [[ ${#missing_functions[@]} -eq 0 ]]; then
        echo "✅ All critical functions available"
        return 0
    else
        echo "⚠️  Missing functions: ${missing_functions[*]}"
        return 1
    fi
}

# =====================================================
# BACKGROUND MODULE STATUS DETECTION
# =====================================================

# Purpose: Check if a specific module is loaded and available
# Arguments: $1 - module name
# Returns: 0 if loaded, 1 if not, 2 if pending
# Usage: check_module_status "python"
check_module_status() {
    local module_name="$1"

    # Check for module-specific loaded indicator
    local loaded_var="${module_name^^}_MODULE_LOADED"
    if [[ "${(P)loaded_var}" == "true" ]]; then
        return 0  # Loaded
    fi

    # Check for module-specific status function
    local status_func="${module_name}_status"
    if robust_function_callable "$status_func"; then
        return 0  # Loaded
    fi

    # Check if module is in LOADED_MODULES array
    if [[ -n "${LOADED_MODULES[$module_name]}" ]]; then
        return 0  # Loaded
    fi

    # Check if module file exists and has been sourced
    local module_file="$ZSH_CONFIG_DIR/modules-new/${module_name}.module.zsh"
    if [[ -f "$module_file" ]]; then
        # Module file exists - check if functions from it are available
        case "$module_name" in
            "python")
                if robust_function_exists "python_status"; then
                    return 0  # Loaded
                fi
                ;;
            "docker")
                if robust_function_exists "docker_status"; then
                    return 0  # Loaded
                fi
                ;;
            "database")
                if robust_function_exists "database_status"; then
                    return 0  # Loaded
                fi
                ;;
        esac
        return 2  # Pending
    fi

    return 1  # Not loaded
}

# Purpose: Get human-readable module status
# Arguments: $1 - module name
# Returns: Status string
# Usage: status=$(get_module_status_text "python")
get_module_status_text() {
    local module_name="$1"

    check_module_status "$module_name"
    local status_code=$?

    case $status_code in
        0) echo "loaded" ;;
        1) echo "not_loaded" ;;
        2) echo "pending" ;;
        *) echo "unknown" ;;
    esac
}

# =====================================================
# TEST RESULT HELPERS
# =====================================================

# Purpose: Enhanced test result reporting with detailed context
# Arguments: $1 - test name, $2 - expected, $3 - actual, $4 - context
# Returns: 0 if match, 1 if not
# Usage: enhanced_test_result "function_check" "available" "missing" "After loading utils"
enhanced_test_result() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    local context="${4:-}"

    if [[ "$expected" == "$actual" ]]; then
        echo "${GREEN}    ✓ $test_name${NC}"
        if [[ -n "$context" ]]; then
            echo "${GREEN}      Context: $context${NC}"
        fi
        return 0
    else
        echo "${RED}    ✗ $test_name${NC}"
        echo "${RED}      Expected: '$expected'${NC}"
        echo "${RED}      Actual: '$actual'${NC}"
        if [[ -n "$context" ]]; then
            echo "${RED}      Context: $context${NC}"
        fi
        return 1
    fi
}

echo "✅ Test helpers loaded successfully"