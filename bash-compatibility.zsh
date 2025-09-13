#!/usr/bin/env bash
# =====================================================
# BASH COMPATIBILITY LOADER
# Lightweight entry point for cross-shell compatibility
# =====================================================

# Determine the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

# Load core cross-shell compatibility
if [[ -f "$SCRIPT_DIR/modules/core/cross-shell.zsh" ]]; then
    source "$SCRIPT_DIR/modules/core/cross-shell.zsh"
else
    echo "Warning: Core cross-shell module not found"
    # Fallback basic detection
    if [ -n "$ZSH_VERSION" ]; then
        export CURRENT_SHELL="zsh"
    elif [ -n "$BASH_VERSION" ]; then
        export CURRENT_SHELL="bash"
    else
        export CURRENT_SHELL="unknown"
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        export PLATFORM="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        export PLATFORM="linux"
    else
        export PLATFORM="unknown"
    fi
fi

# Function to safely load module
load_compatibility_module() {
    local module_path="$1"
    if [[ -f "$SCRIPT_DIR/$module_path" ]]; then
        source "$SCRIPT_DIR/$module_path"
        return 0
    else
        echo "Warning: Module $module_path not found"
        return 1
    fi
}

# Load additional modules based on shell and requirements
case "$CURRENT_SHELL" in
    "zsh")
        # ZSH can load everything
        load_compatibility_module "modules/core/utilities.zsh" 2>/dev/null || true
        ;;
    "bash")
        # Bash-specific compatibility layers
        echo "Loading bash compatibility for platform: $PLATFORM"
        ;;
esac

# Provide essential functions for scripts that depend on them
python_status() {
    echo "Python Status (compatibility mode):"
    echo "• Current shell: $CURRENT_SHELL"
    echo "• Platform: $PLATFORM"

    if command -v python3 >/dev/null 2>&1; then
        echo "• Python: $(python3 --version)"
    else
        echo "• Python: Not available"
    fi

    if command -v pyenv >/dev/null 2>&1; then
        echo "• Pyenv: Available"
    else
        echo "• Pyenv: Not available"
    fi
}

# Basic backup function for compatibility
backup() {
    local source_file="$1"
    local backup_dir="${2:-$HOME/.backups}"

    if [[ -z "$source_file" ]]; then
        echo "Usage: backup <file> [backup_dir]"
        return 1
    fi

    mkdir -p "$backup_dir"
    local backup_file="$backup_dir/$(basename "$source_file").$(date +%Y%m%d_%H%M%S).bak"
    cp "$source_file" "$backup_file"
    echo "Backed up $source_file to $backup_file"
}

# Basic help function
zsh_help() {
    echo "Bash Compatibility Help System"
    echo "=============================="
    echo "Available functions:"
    echo "• python_status  - Show Python environment status"
    echo "• backup <file>  - Backup a file"
    echo "• deduplicate_path - Clean up PATH variable"
    echo ""
    echo "Environment variables:"
    echo "• CURRENT_SHELL: $CURRENT_SHELL"
    echo "• PLATFORM: $PLATFORM"
    echo "• IN_CONTAINER: ${IN_CONTAINER:-false}"
}

# Mark compatibility as loaded
export SIEGE_COMPATIBILITY_INITIALIZED="true"
export COMPATIBILITY_LOADER_VERSION="2.0"

echo "Bash compatibility loader initialized (v2.0) for $CURRENT_SHELL on $PLATFORM"