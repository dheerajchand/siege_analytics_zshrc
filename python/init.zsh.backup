#!/usr/bin/env zsh
# ============================================
# Python Environment Management System
# Entry Point - Loads all Python-related modules
# ============================================

# Set Python module home
export PYTHON_ZSH_HOME="${0:A:h}"
export PYTHON_ZSH_VERSION="2.0.0"

# Configuration
export PYTHON_MANAGER="${PYTHON_MANAGER:-pyenv}"
export PYTHON_MANAGER_STATE_FILE="$HOME/.config/python_manager_state"
export PYTHON_DEBUG="${PYTHON_DEBUG:-0}"
export PYTHON_AUTOLOAD_MODULES="${PYTHON_AUTOLOAD_MODULES:-1}"

# Module loader
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

# Load core modules
load_python_module "core.zsh" 1 || return 1

# Load utilities
for util in $PYTHON_ZSH_HOME/utils/*.zsh(N); do
    load_python_module "utils/$(basename $util)" 0
done

# Load active manager
load_python_module "managers/${PYTHON_MANAGER}.zsh" 0

# Load project management
for proj in $PYTHON_ZSH_HOME/projects/*.zsh(N); do
    load_python_module "projects/$(basename $proj)" 0
done

# Load integrations (suppress verbose output from integrations only)
if [[ $PYTHON_AUTOLOAD_MODULES -eq 1 ]]; then
    {
        for integration in $PYTHON_ZSH_HOME/integrations/*.zsh(N); do
            load_python_module "integrations/$(basename $integration)" 0
        done
    } >/dev/null 2>&1
fi

# Load saved preferences
[[ -f "$PYTHON_MANAGER_STATE_FILE" ]] && source "$PYTHON_MANAGER_STATE_FILE"
[[ -f "$HOME/.config/pyenv_default_env" ]] && source "$HOME/.config/pyenv_default_env"

# Initialize
init_python_manager "$PYTHON_MANAGER" >/dev/null 2>&1

# Auto-activate venv
auto_activate_venv >/dev/null 2>&1

# Startup message
if [[ "${PYTHON_SHOW_STATUS_ON_LOAD:-0}" -eq 1 ]]; then
    echo "🐍 Python ($PYTHON_MANAGER): $(get_current_python_version)"
    echo "   Type 'pyhelp' for help"
fi
