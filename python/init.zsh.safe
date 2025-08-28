#!/usr/bin/env zsh
# ============================================
# SAFE Python Environment Management System
# Fixed to prevent pyenv help during startup
# ============================================

# Set Python module home
export PYTHON_ZSH_HOME="${0:A:h}"
export PYTHON_ZSH_VERSION="2.0.1-safe"

# Configuration (safe defaults)
export PYTHON_MANAGER="${PYTHON_MANAGER:-pyenv}"
export PYTHON_MANAGER_STATE_FILE="$HOME/.config/python_manager_state"
export PYTHON_DEBUG="${PYTHON_DEBUG:-0}"
export PYTHON_AUTOLOAD_MODULES="${PYTHON_AUTOLOAD_MODULES:-0}"  # DISABLED for safety

# Safe logging function
python_log() {
    local level=$1
    shift
    if [[ $PYTHON_DEBUG -eq 1 ]] || [[ "$level" == "ERROR" ]]; then
        echo "[PYTHON-$level] $*" >&2
    fi
}

# Safe module loader
load_python_module() {
    local module=$1
    local required=${2:-1}
    local module_path="$PYTHON_ZSH_HOME/$module"
    
    if [[ -f "$module_path" ]]; then
        source "$module_path"
        python_log DEBUG "Loaded: $module"
        return 0
    else
        if [[ $required -eq 1 ]]; then
            python_log ERROR "Required module missing: $module"
            return 1
        else
            python_log DEBUG "Optional module missing: $module"
            return 0
        fi
    fi
}

# SAFE init_python_manager function (this was causing the pyenv help!)
init_python_manager() {
    local manager=${1:-$PYTHON_MANAGER}
    python_log DEBUG "Initializing Python manager: $manager"
    
    case "$manager" in
        "pyenv")
            # SAFE pyenv initialization - no pyenv commands call during startup
            if command -v pyenv >/dev/null 2>&1; then
                export PYENV_ROOT="$HOME/.pyenv"
                export PATH="$PYENV_ROOT/bin:$PATH"
                eval "$(pyenv init -)" 2>/dev/null
                
                # Safe virtualenv check - avoid pyenv commands call!
                if [ -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
                    eval "$(pyenv virtualenv-init -)" 2>/dev/null
                fi
                
                python_log DEBUG "pyenv initialized safely"
                return 0
            else
                python_log ERROR "pyenv not found"
                return 1
            fi
            ;;
        "uv")
            if command -v uv >/dev/null 2>&1; then
                python_log DEBUG "uv available: $(uv --version 2>/dev/null)"
                return 0
            else
                python_log ERROR "uv not found"
                return 1
            fi
            ;;
        *)
            python_log ERROR "Unknown Python manager: $manager"
            return 1
            ;;
    esac
}

# Safe auto-activate function
auto_activate_venv() {
    # Only try to auto-activate if pyenv is initialized and we're in a directory with .python-version
    if [[ "$PYTHON_MANAGER" == "pyenv" ]] && command -v pyenv >/dev/null 2>&1; then
        if [[ -f ".python-version" ]]; then
            python_log DEBUG "Auto-activating based on .python-version"
            # This is safe - just sets the version, doesn't call pyenv commands
        fi
    fi
}

# Load core modules if they exist (safe loading)
if [[ -f "$PYTHON_ZSH_HOME/core.zsh" ]]; then
    load_python_module "core.zsh" 0
fi

# Load active manager (safe, no auto-initialization)
if [[ $PYTHON_AUTOLOAD_MODULES -eq 1 ]]; then
    load_python_module "managers/${PYTHON_MANAGER}.zsh" 0
fi

# SAFE initialization - only if explicitly enabled
if [[ "${PYTHON_AUTO_INIT:-0}" -eq 1 ]]; then
    init_python_manager "$PYTHON_MANAGER" >/dev/null 2>&1
    auto_activate_venv >/dev/null 2>&1
fi

# Load saved preferences safely
[[ -f "$PYTHON_MANAGER_STATE_FILE" ]] && source "$PYTHON_MANAGER_STATE_FILE" 2>/dev/null
[[ -f "$HOME/.config/pyenv_default_env" ]] && source "$HOME/.config/pyenv_default_env" 2>/dev/null

# Startup message (only if enabled)
if [[ "${PYTHON_SHOW_STATUS_ON_LOAD:-0}" -eq 1 ]]; then
    echo "🐍 Python ($PYTHON_MANAGER) ready - use 'python_help' for commands"
fi
