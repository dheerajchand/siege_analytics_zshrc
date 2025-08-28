#!/usr/bin/env zsh
# ============================================
# OPTIMIZED Python Environment Management System
# Ultra-fast loading with lazy initialization
# ============================================

# Set Python module home
export PYTHON_ZSH_HOME="${0:A:h}"
export PYTHON_ZSH_VERSION="2.1.0-optimized"

# Configuration (performance-optimized defaults)
export PYTHON_MANAGER="${PYTHON_MANAGER:-pyenv}"
export PYTHON_MANAGER_STATE_FILE="$HOME/.config/python_manager_state"
export PYTHON_DEBUG="${PYTHON_DEBUG:-0}"
export PYTHON_AUTOLOAD_MODULES="${PYTHON_AUTOLOAD_MODULES:-0}"  # Keep disabled for speed

# Fast logging (only errors by default)
python_log() {
    local level=$1
    shift
    [[ "$level" == "ERROR" ]] && echo "[PYTHON-ERROR] $*" >&2
}

# Optimized module loader with caching
declare -A PYTHON_LOADED_MODULES
load_python_module() {
    local module=$1
    local required=${2:-0}  # Default to optional for speed
    local module_path="$PYTHON_ZSH_HOME/$module"

    # Check cache first
    [[ -n "${PYTHON_LOADED_MODULES[$module]}" ]] && return 0

    if [[ -f "$module_path" ]]; then
        source "$module_path"
        PYTHON_LOADED_MODULES[$module]=1
        return 0
    else
        [[ $required -eq 1 ]] && python_log ERROR "Required module missing: $module"
        return 1
    fi
}

# OPTIMIZED init_python_manager (no slow calls during startup)
init_python_manager() {
    local manager=${1:-$PYTHON_MANAGER}

    case "$manager" in
        "pyenv")
            if command -v pyenv >/dev/null 2>&1; then
                export PYENV_ROOT="$HOME/.pyenv"
                export PATH="$PYENV_ROOT/bin:$PATH"
                eval "$(pyenv init -)" 2>/dev/null

                # Fastest virtualenv check - no pyenv commands call!
                if [ -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
                    eval "$(pyenv virtualenv-init -)" 2>/dev/null
                fi
                return 0
            fi
            ;;
        "uv")
            command -v uv >/dev/null 2>&1 && return 0
            ;;
    esac
    return 1
}

# Load only essential modules during startup
load_python_module "core.zsh" 0

# Load manager only if autoload enabled
if [[ $PYTHON_AUTOLOAD_MODULES -eq 1 ]]; then
    load_python_module "managers/${PYTHON_MANAGER}.zsh" 0
fi

# Fast initialization (no heavy operations)
if [[ "${PYTHON_AUTO_INIT:-0}" -eq 1 ]]; then
    init_python_manager "$PYTHON_MANAGER" >/dev/null 2>&1
fi

# Load state files (cached)
[[ -f "$PYTHON_MANAGER_STATE_FILE" ]] && source "$PYTHON_MANAGER_STATE_FILE" 2>/dev/null

# Minimal startup message
if [[ "${PYTHON_SHOW_STATUS_ON_LOAD:-0}" -eq 1 ]]; then
    echo "🐍 Advanced Python System Ready"
fi
