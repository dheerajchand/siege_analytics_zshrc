#!/usr/bin/env zsh
# =====================================================
# UTILS MODULE - System utility functions
# =====================================================
#
# Purpose: Common utility functions for error reporting and validation
# Provides: Error reporting, validation helpers, system diagnostics
# Dependencies: None (core utilities)
# =====================================================

echo "🔧 Loading Utils module..."

# =====================================================
# ERROR REPORTING FUNCTIONS
# =====================================================

# Purpose: Report missing dependency with structured error message
# Arguments: $1 - tool name, $2 - description, $3 - context, $4 - installation command
# Returns: Always 1 (error)
# Usage: _report_missing_dependency "git" "Version control system" "Required for repo management" "brew install git"
_report_missing_dependency() {
    local tool="$1"
    local description="$2"
    local context="$3"
    local install_cmd="$4"

    echo "❌ Missing Dependency: $tool"
    echo "   Description: $description"
    echo "   Context: $context"
    echo "   Installation: $install_cmd"
    echo ""
}

# Purpose: Report path-related errors with context
# Arguments: $1 - path, $2 - error description, $3 - suggested action, $4 - optional command
# Returns: Always 1 (error)
# Usage: _report_path_error "/missing/path" "Directory not found" "Create the directory" "mkdir -p /missing/path"
_report_path_error() {
    local path="$1"
    local error_desc="$2"
    local suggestion="$3"
    local cmd="${4:-}"

    echo "❌ Path Error: $path"
    echo "   Issue: $error_desc"
    echo "   Suggestion: $suggestion"
    if [[ -n "$cmd" ]]; then
        echo "   Command: $cmd"
    fi
    echo ""
}

# Purpose: Report validation errors with detailed context
# Arguments: $1 - parameter name, $2 - actual value, $3 - expected format, $4 - usage example
# Returns: Always 1 (error)
# Usage: _report_validation_error "port" "abc" "numeric value 1-65535" "my_function 8080"
_report_validation_error() {
    local param="$1"
    local actual="$2"
    local expected="$3"
    local usage="$4"

    echo "❌ Validation Error: $param"
    echo "   Actual: '$actual'"
    echo "   Expected: $expected"
    echo "   Usage: $usage"
    echo ""
}

# Purpose: Report configuration errors
# Arguments: $1 - config item, $2 - current value, $3 - issue description, $4 - fix suggestion
# Returns: Always 1 (error)
# Usage: _report_config_error "PATH" "$PATH" "Too long (${#PATH} chars)" "Run path_clean to optimize"
_report_config_error() {
    local config_item="$1"
    local current_value="$2"
    local issue="$3"
    local fix="$4"

    echo "❌ Configuration Error: $config_item"
    echo "   Current: $current_value"
    echo "   Issue: $issue"
    echo "   Fix: $fix"
    echo ""
}

# =====================================================
# VALIDATION HELPERS
# =====================================================

# Purpose: Check if a command exists in PATH
# Arguments: $1 - command name
# Returns: 0 if exists, 1 if not found
# Usage: if _command_exists "git"; then echo "Git available"; fi
_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Purpose: Check if a directory exists and is accessible
# Arguments: $1 - directory path
# Returns: 0 if accessible, 1 if not
# Usage: if _directory_accessible "/path/to/dir"; then echo "Directory OK"; fi
_directory_accessible() {
    [[ -d "$1" && -r "$1" ]]
}

# Purpose: Check if a file exists and is readable
# Arguments: $1 - file path
# Returns: 0 if readable, 1 if not
# Usage: if _file_readable "/path/to/file"; then echo "File OK"; fi
_file_readable() {
    [[ -f "$1" && -r "$1" ]]
}

# Purpose: Validate that a value is a positive integer
# Arguments: $1 - value to check
# Returns: 0 if valid positive integer, 1 if not
# Usage: if _is_positive_integer "$port"; then echo "Valid port"; fi
_is_positive_integer() {
    [[ "$1" =~ ^[0-9]+$ && "$1" -gt 0 ]]
}

# =====================================================
# SYSTEM DIAGNOSTICS
# =====================================================

# Purpose: Get system information summary
# Arguments: None
# Returns: 0 always
# Usage: _system_info
_system_info() {
    echo "🖥️  System Information"
    echo "===================="
    echo "OS: $(uname -s) $(uname -r)"
    echo "Shell: $SHELL"
    echo "ZSH Version: $ZSH_VERSION"
    echo "PATH Length: ${#PATH} characters"
    echo "Working Directory: $(pwd)"
    echo "User: $USER"
    echo "Home: $HOME"
    echo ""
}

# Purpose: Check environment health
# Arguments: None
# Returns: 0 if healthy, 1 if issues found
# Usage: _environment_health_check
_environment_health_check() {
    local issues=0

    echo "🏥 Environment Health Check"
    echo "=========================="

    # Check essential commands
    local essential_commands=("git" "curl" "grep" "find" "sed" "awk")
    for cmd in "${essential_commands[@]}"; do
        if _command_exists "$cmd"; then
            echo "✅ $cmd available"
        else
            echo "❌ $cmd missing"
            ((issues++))
        fi
    done

    # Check PATH length
    if [[ ${#PATH} -gt 2000 ]]; then
        echo "⚠️  PATH very long (${#PATH} chars) - may cause performance issues"
        ((issues++))
    elif [[ ${#PATH} -gt 1000 ]]; then
        echo "⚠️  PATH long (${#PATH} chars) - consider optimization"
    else
        echo "✅ PATH length optimal (${#PATH} chars)"
    fi

    # Check ZSH configuration
    if [[ -n "$ZSH_CONFIG_DIR" && -d "$ZSH_CONFIG_DIR" ]]; then
        echo "✅ ZSH configuration directory accessible"
    else
        echo "❌ ZSH configuration directory issue"
        ((issues++))
    fi

    echo ""
    if [[ $issues -eq 0 ]]; then
        echo "🎉 Environment is healthy!"
        return 0
    else
        echo "⚠️  Found $issues issues"
        return 1
    fi
}

echo "✅ Utils module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export UTILS_MODULE_LOADED=true