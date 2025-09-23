#!/usr/bin/env zsh
# =====================================================
# UTILS MODULE - Essential utility functions
# =====================================================
#
# Purpose: Core utility functions for error reporting and validation
# Provides: _report_* functions, validation helpers, system utilities
# Dependencies: None (foundational module)
# =====================================================

# Loading Utils module silently

# =====================================================
# ERROR REPORTING FUNCTIONS
# =====================================================

# Purpose: Report missing dependency with installation guidance
# Arguments: $1 - tool name, $2 - description, $3 - context, $4 - install command
# Returns: 1 always (indicates missing dependency)
# Usage: _report_missing_dependency "pyenv" "Python version manager" "Python setup" "brew install pyenv"
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
    return 1
}

# Purpose: Report path-related errors with resolution guidance
# Arguments: $1 - path, $2 - error description, $3 - context, $4 - resolution
# Returns: 1 always (indicates path error)
# Usage: _report_path_error "/missing/path" "Directory not found" "Setup" "mkdir -p /path"
_report_path_error() {
    local path="$1"
    local error="$2"
    local context="$3"
    local resolution="$4"

    echo "❌ Path Error: $path"
    echo "   Error: $error"
    echo "   Context: $context"
    echo "   Resolution: $resolution"
    echo ""
    return 1
}

# Purpose: Report validation errors with expected format
# Arguments: $1 - field name, $2 - value, $3 - expected, $4 - example
# Returns: 1 always (indicates validation error)
# Usage: _report_validation_error "port" "abc" "numeric value" "8080"
_report_validation_error() {
    local field="$1"
    local value="$2"
    local expected="$3"
    local example="$4"

    echo "❌ Validation Error: $field"
    echo "   Value: $value"
    echo "   Expected: $expected"
    echo "   Example: $example"
    echo ""
    return 1
}

# Purpose: Report configuration errors with current state
# Arguments: $1 - setting name, $2 - current value, $3 - issue, $4 - fix
# Returns: 1 always (indicates config error)
# Usage: _report_config_error "JAVA_HOME" "/wrong/path" "Invalid path" "export JAVA_HOME=/correct/path"
_report_config_error() {
    local setting="$1"
    local current="$2"
    local issue="$3"
    local fix="$4"

    echo "❌ Configuration Error: $setting"
    echo "   Current: $current"
    echo "   Issue: $issue"
    echo "   Fix: $fix"
    echo ""
    return 1
}

# =====================================================
# VALIDATION HELPER FUNCTIONS
# =====================================================

# Purpose: Check if a command exists in PATH
# Arguments: $1 - command name
# Returns: 0 if exists, 1 if not
# Usage: if _command_exists "git"; then echo "Git available"; fi
_command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Purpose: Check if a directory exists and is accessible
# Arguments: $1 - directory path
# Returns: 0 if accessible, 1 if not
# Usage: if _directory_accessible "/path"; then echo "Directory OK"; fi
_directory_accessible() {
    [[ -d "$1" && -r "$1" ]]
}

# Purpose: Check if a file exists and is readable
# Arguments: $1 - file path
# Returns: 0 if readable, 1 if not
# Usage: if _file_readable "/etc/hosts"; then echo "File OK"; fi
_file_readable() {
    [[ -f "$1" && -r "$1" ]]
}

# Purpose: Validate if a string is a positive integer
# Arguments: $1 - value to check
# Returns: 0 if valid positive integer, 1 if not
# Usage: if _is_positive_integer "123"; then echo "Valid"; fi
_is_positive_integer() {
    [[ "$1" =~ ^[1-9][0-9]*$ ]]
}

# =====================================================
# SYSTEM DIAGNOSTIC FUNCTIONS
# =====================================================

# Purpose: Display comprehensive system information
# Arguments: None
# Returns: 0 always
# Usage: _system_info
_system_info() {
    echo "🖥️  System Information"
    echo "===================="
    echo "OS: $(uname -s)"
    echo "Version: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Shell: $SHELL ($ZSH_VERSION)"
    echo "User: $USER"
    echo "Home: $HOME"
    echo ""
}

# Purpose: Perform basic environment health checks
# Arguments: None
# Returns: 0 if healthy, 1 if issues found
# Usage: _environment_health_check
_environment_health_check() {
    echo "🔍 Environment Health Check"
    echo "==========================="

    local issues=0

    # Check essential commands
    local essential_commands=("ls" "cd" "pwd" "echo" "which")
    for cmd in "${essential_commands[@]}"; do
        if _command_exists "$cmd"; then
            echo "✅ $cmd: Available"
        else
            echo "❌ $cmd: Missing"
            ((issues++))
        fi
    done

    # Check PATH
    if [[ -n "$PATH" ]]; then
        echo "✅ PATH: Set (${#PATH} characters)"
    else
        echo "❌ PATH: Empty or unset"
        ((issues++))
    fi

    # Check HOME directory
    if _directory_accessible "$HOME"; then
        echo "✅ HOME: Accessible ($HOME)"
    else
        echo "❌ HOME: Not accessible ($HOME)"
        ((issues++))
    fi

    echo ""
    if [[ $issues -eq 0 ]]; then
        echo "🎉 Environment appears healthy"
        return 0
    else
        echo "⚠️  Found $issues issue(s)"
        return 1
    fi
}

# Load backup system - ESSENTIAL for production use
if [[ -f "$ZSH_CONFIG_DIR/scripts/utils/backup-system.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/scripts/utils/backup-system.zsh" >/dev/null 2>&1
    # Backup system loaded (enhanced_backup, pushmain, sync available)
else
    echo "⚠️  Backup system not found - manual git commits required"
fi

# Utils module loaded successfully

# =====================================================
# COMPLETION
# =====================================================
export UTILS_MODULE_LOADED=true
# Functions are available in zsh subshells by default
# (export -f is bash-specific and causes output spam in zsh)
