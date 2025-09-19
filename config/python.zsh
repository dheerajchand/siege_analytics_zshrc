#!/usr/bin/env zsh

# =====================================================
# PYTHON ENVIRONMENT MANAGEMENT MODULE
# =====================================================
#
# Comprehensive Python environment management supporting:
# - pyenv (Python version management)
# - uv (Fast Python package installer and resolver)
# - Automatic switching between managers
# - Project-specific environments
# =====================================================

# Module identification
export PYTHON_MODULE_LOADED="true"

# Default configuration
export DEFAULT_PYENV_VENV="${DEFAULT_PYENV_VENV:-geo31111}"
export PYTHON_ZSH_HOME="$HOME/.config/zsh/python"
export PYTHON_MANAGER_STATE_FILE="$HOME/.cache/zsh_python_manager"

# Load the comprehensive Python system with auto-initialization enabled
if [[ -f "$PYTHON_ZSH_HOME/init.zsh" ]]; then
    export PYTHON_AUTO_INIT=1
    export PYTHON_AUTOLOAD_MODULES=1
    source "$PYTHON_ZSH_HOME/init.zsh"

    # Explicitly initialize the Python manager if not already done
    if ! command -v python >/dev/null 2>&1; then
        if [[ -f "$PYTHON_ZSH_HOME/managers/pyenv.zsh" ]]; then
            source "$PYTHON_ZSH_HOME/managers/pyenv.zsh"
            setup_pyenv >/dev/null 2>&1
        fi
    fi
else
    # Fallback: Basic Python environment setup
    echo "⚠️  Comprehensive Python system not found, using fallback setup"

    # Initialize pyenv if available with proper PATH setup
    if command -v pyenv >/dev/null 2>&1; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"

        # Critical: Initialize pyenv with both --path and regular init
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"

        # Initialize pyenv-virtualenv if available
        if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
            eval "$(pyenv virtualenv-init -)"
        fi

        # Auto-activate default environment
        if [[ -n "$DEFAULT_PYENV_VENV" ]] && pyenv versions --bare | grep -q "^${DEFAULT_PYENV_VENV}$"; then
            pyenv activate "$DEFAULT_PYENV_VENV" 2>/dev/null || pyenv shell "$DEFAULT_PYENV_VENV" 2>/dev/null || true
        fi

        # Basic switching functions
        use_pyenv() {
            local env_name="${1:-$DEFAULT_PYENV_VENV}"
            if [[ -n "$env_name" ]] && pyenv versions --bare | grep -q "^${env_name}$"; then
                pyenv activate "$env_name" 2>/dev/null || pyenv shell "$env_name" 2>/dev/null || true
                echo "✅ Activated Python environment: $env_name"
            else
                echo "❌ Environment '$env_name' not found"
                echo "Available environments:"
                pyenv versions --bare | grep -v system | sed 's/^/  /'
            fi
        }

        use_uv() {
            if command -v uv >/dev/null 2>&1; then
                echo "✅ Switched to uv (project-based Python management)"
                export PYTHON_MANAGER="uv"
            else
                echo "❌ uv not found. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
            fi
        }

        [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "🐍 Python: $(pyenv version-name 2>/dev/null || echo 'system') (fallback setup)"
    fi
fi

# Ensure Python is available
if ! command -v python >/dev/null 2>&1; then
    # Try to activate default environment if python is missing
    if command -v pyenv >/dev/null 2>&1 && [[ -n "$DEFAULT_PYENV_VENV" ]]; then
        pyenv activate "$DEFAULT_PYENV_VENV" 2>/dev/null || pyenv shell "$DEFAULT_PYENV_VENV" 2>/dev/null || true
    fi
fi