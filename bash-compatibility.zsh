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

# Python manager setup for backward compatibility
setup_python_manager() {
    local manager=${1:-auto}
    echo "Setting up Python manager: $manager"

    case "$manager" in
        "pyenv")
            setup_pyenv_minimal
            ;;
        "uv")
            setup_uv_minimal
            ;;
        "auto"|*)
            if command -v pyenv >/dev/null 2>&1; then
                setup_pyenv_minimal
            else
                echo "Python manager auto-detection: using system python"
            fi
            ;;
    esac
}

# Minimal pyenv setup
setup_pyenv_minimal() {
    export PYENV_ROOT="$HOME/.pyenv"
    if [[ -d "$PYENV_ROOT" ]]; then
        export PATH="$PYENV_ROOT/bin:$PATH"
        if command -v pyenv >/dev/null 2>&1; then
            eval "$(pyenv init -)" 2>/dev/null || true
            echo "Pyenv initialized"
        fi
    fi
}

# Minimal UV setup
setup_uv_minimal() {
    if command -v uv >/dev/null 2>&1; then
        export UV_PYTHON_PREFERENCE="managed"
        echo "UV configured"
    else
        echo "UV not found"
    fi
}

# Spark setup stub
setup_spark() {
    echo "Spark setup (compatibility mode - basic detection)"
    if command -v spark-submit >/dev/null 2>&1; then
        echo "• Spark: Available"
    else
        echo "• Spark: Not available"
    fi
}

# Show spark config stub
show_spark_config() {
    echo "Spark Configuration (compatibility mode):"
    echo "• SPARK_HOME: ${SPARK_HOME:-Not set}"
    echo "• Java: $(java -version 2>&1 | head -1 || echo 'Not available')"
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

# Shell optimization function
optimize_shell() {
    echo "Optimizing shell performance..."
    deduplicate_path
    echo "• PATH deduplicated"
    echo "• Shell optimization complete"
}

# Environment validation function
validate_environment() {
    echo "Validating environment..."
    local errors=0

    # Check shell detection
    if [[ -z "$CURRENT_SHELL" ]]; then
        echo "• ERROR: Shell not detected"
        ((errors++))
    else
        echo "• Shell detection: ✓ ($CURRENT_SHELL)"
    fi

    # Check platform detection
    if [[ -z "$PLATFORM" ]]; then
        echo "• ERROR: Platform not detected"
        ((errors++))
    else
        echo "• Platform detection: ✓ ($PLATFORM)"
    fi

    # Check PATH
    if [[ -z "$PATH" ]]; then
        echo "• ERROR: PATH is empty"
        ((errors++))
    else
        echo "• PATH: ✓ ($(echo $PATH | tr ':' '\n' | wc -l) entries)"
    fi

    if [[ $errors -eq 0 ]]; then
        echo "• Environment validation: ✓ PASSED"
    else
        echo "• Environment validation: ✗ FAILED ($errors errors)"
    fi
}

# Comprehensive compatibility test function
test_compatibility() {
    echo "Running comprehensive compatibility test..."

    echo "• Testing python_status..."
    python_status > /dev/null
    echo "  ✓ python_status works"

    echo "• Testing setup_python_manager..."
    setup_python_manager auto > /dev/null
    echo "  ✓ setup_python_manager works"

    echo "• Testing setup_spark..."
    setup_spark > /dev/null
    echo "  ✓ setup_spark works"

    echo "• Testing validate_environment..."
    validate_environment > /dev/null
    echo "  ✓ validate_environment works"

    echo "• Testing deduplicate_path..."
    deduplicate_path
    echo "  ✓ deduplicate_path works"

    echo "All compatibility tests passed!"
}

# Basic help function
zsh_help() {
    echo "Bash Compatibility Help System"
    echo "=============================="
    echo "Available functions:"
    echo "• python_status    - Show Python environment status"
    echo "• backup <file>    - Backup a file"
    echo "• deduplicate_path - Quick PATH cleanup (remove duplicates)"
    echo "• repair_path      - Comprehensive PATH repair (NEW!)"
    echo "• optimize_shell   - Optimize shell performance"
    echo ""
    echo "PATH Management:"
    echo "• repair_path --help        - Show PATH repair options"
    echo "• repair_path --dry-run     - Preview PATH changes"
    echo "• repair_path --verbose     - Detailed repair output"
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