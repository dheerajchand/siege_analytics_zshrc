#!/usr/bin/env zsh
# ============================================
# Core Python Management Functions
# ============================================

# Initialize Python manager
init_python_manager() {
    local manager=${1:-$PYTHON_MANAGER}
    
    python_log DEBUG "Initializing $manager..."
    
    local manager_module="$PYTHON_ZSH_HOME/managers/${manager}.zsh"
    if [[ -f "$manager_module" ]]; then
        source "$manager_module"
        
        if type "setup_${manager}" > /dev/null; then
            "setup_${manager}"
            export PYTHON_MANAGER="$manager"
            echo "$PYTHON_MANAGER" > "$PYTHON_MANAGER_STATE_FILE"
            return 0
        fi
    fi
    return 1
}

# Switch managers
switch_python_manager() {
    local target=$1
    
    if [[ -z "$target" ]]; then
        echo "Usage: switch_python_manager [pyenv|uv]"
        echo "Current: $PYTHON_MANAGER"
        return 1
    fi
    
    cleanup_python_env
    
    if init_python_manager "$target"; then
        python_log SUCCESS "Switched to $target"
        echo "Reload shell: exec zsh"
    else
        python_log ERROR "Failed to switch"
        return 1
    fi
}

# Clean environment
cleanup_python_env() {
    unset PYENV_ROOT PYENV_SHELL PYENV_VERSION
    unset UV_HOME UV_PYTHON_PREFERENCE
    unset PYSPARK_PYTHON PYSPARK_DRIVER_PYTHON
    
    local aliases=(uvpy uvrun uvsync uvlock uvpip)
    for alias in $aliases; do
        unalias $alias 2>/dev/null
    done
}

# Get Python version
get_current_python_version() {
    case "$PYTHON_MANAGER" in
        pyenv)
            pyenv version-name 2>/dev/null || echo "none"
            ;;
        uv)
            uv run python --version 2>&1 | cut -d' ' -f2 || echo "none"
            ;;
        *)
            python --version 2>&1 | cut -d' ' -f2 || echo "none"
            ;;
    esac
}

# Create virtual environment
create_venv() {
    local name=${1:-.venv}
    local python_version=$2
    
    case "$PYTHON_MANAGER" in
        pyenv)
            if [[ -n "$python_version" ]]; then
                PYENV_VERSION="$python_version" python -m venv "$name"
            else
                python -m venv "$name"
            fi
            ;;
        uv)
            if [[ -n "$python_version" ]]; then
                uv venv --python "$python_version" "$name"
            else
                uv venv "$name"
            fi
            ;;
    esac
}

# Auto-activate venv
auto_activate_venv() {
    local venv_dirs=(.venv venv env)
    
    for venv in $venv_dirs; do
        if [[ -d "$venv" ]] && [[ -f "$venv/bin/activate" ]]; then
            if [[ "$VIRTUAL_ENV" != "$PWD/$venv" ]]; then
                source "$venv/bin/activate"
                return 0
            fi
        fi
    done
    
    if [[ -n "$VIRTUAL_ENV" ]] && [[ ! "$PWD" =~ "$(dirname $VIRTUAL_ENV)" ]]; then
        deactivate 2>/dev/null
    fi
}

# Status
python_status() {
    echo "╔════════════════════════════════════════╗"
    echo "║        Python Environment Status        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Manager:  $PYTHON_MANAGER"
    echo "Python:   $(get_current_python_version)"
    echo "Venv:     ${VIRTUAL_ENV:-none}"
    echo "Config:   $PYTHON_ZSH_HOME"
}

# Help
pyhelp() {
    echo "Python Environment Commands"
    echo "=========================="
    echo ""
    echo "Manager:"
    echo "  use_pyenv    Switch to pyenv"
    echo "  use_uv       Switch to uv"
    echo "  pystatus     Show status"
    echo ""
    echo "Projects:"
    echo "  pyproject    Create project"
    echo "  pyvenv       Create venv"
    echo "  activate     Activate venv"
    echo ""
    echo "Notebooks:"
    echo "  pynb         Start Jupyter"
    echo "  pyds         Setup DataSpell"
    echo ""
    echo "Spark:"
    echo "  pyspark-init Create Spark project"
}

# Aliases
alias use_pyenv="switch_python_manager pyenv"
alias use_uv="switch_python_manager uv"
alias pystatus="python_status"
alias pyvenv="create_venv"
alias activate="source .venv/bin/activate 2>/dev/null || source venv/bin/activate 2>/dev/null"

# Hooks
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -U add-zsh-hook
    add-zsh-hook chpwd auto_activate_venv
fi
