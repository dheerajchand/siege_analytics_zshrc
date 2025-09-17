#!/usr/bin/env zsh
# =====================================================
# PYTHON MODULE - Python environment management
# =====================================================
#
# Purpose: Comprehensive Python environment management
# Provides: pyenv, UV, virtualenv, project management
# Dependencies: centralized variables
# =====================================================

echo "🐍 Loading Python module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# PYTHON ENVIRONMENT SETUP
# =====================================================

# Setup pyenv if available (uses centralized PYENV_ROOT)
if [[ -d "$PYENV_ROOT" ]]; then
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
        echo "✅ Pyenv initialized"
    fi
fi

# Setup UV if available (uses centralized UV_BIN_PATH)
if command -v uv >/dev/null 2>&1; then
    export PATH="$UV_BIN_PATH:$PATH"
    echo "✅ UV initialized"
fi

# =====================================================
# PYTHON FUNCTIONS
# =====================================================

# Purpose: Show comprehensive Python environment status
# Arguments: None
# Returns: 0 always
# Usage: python_status
python_status() {
    echo "🐍 Python Environment Status"
    echo "============================"

    # Python version info
    if command -v python3 >/dev/null 2>&1; then
        echo "✅ Python: $(python3 --version)"
        echo "📍 Location: $(which python3)"
    else
        echo "❌ Python: Not found"
    fi

    # Pyenv status
    if command -v pyenv >/dev/null 2>&1; then
        echo "✅ Pyenv: $(pyenv --version)"
        echo "🔄 Current: $(pyenv version)"
        echo "📋 Available:"
        pyenv versions --bare | head -5 | sed 's/^/  /'
    else
        echo "❌ Pyenv: Not available"
    fi

    # UV status
    if command -v uv >/dev/null 2>&1; then
        echo "✅ UV: $(uv --version)"
    else
        echo "❌ UV: Not available"
    fi

    # Virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "🌟 Active virtualenv: $(basename $VIRTUAL_ENV)"
    else
        echo "💤 No virtual environment active"
    fi
}

# Purpose: Interactive Python environment switching
# Arguments: $1 - environment name or 'list' or 'uv'
# Returns: 0 on success, 1 on error
# Usage: py_env_switch <env_name> | py_env_switch list | py_env_switch uv
py_env_switch() {
    local action="$1"

    case "$action" in
        "list")
            echo "📋 Available Python environments:"
            if command -v pyenv >/dev/null 2>&1; then
                echo "  Pyenv versions:"
                pyenv versions --bare | sed 's/^/    /'
            fi
            if command -v uv >/dev/null 2>&1; then
                echo "  UV projects:"
                find . -name "pyproject.toml" -exec dirname {} \; 2>/dev/null | sed 's/^/    /'
            fi
            ;;
        "uv")
            if command -v uv >/dev/null 2>&1; then
                if [[ -f "pyproject.toml" ]]; then
                    echo "🔄 Activating UV project environment..."
                    source .venv/bin/activate 2>/dev/null || uv venv && source .venv/bin/activate
                else
                    echo "❌ No pyproject.toml found in current directory"
                    return 1
                fi
            else
                echo "❌ UV not available"
                return 1
            fi
            ;;
        "")
            echo "💡 Usage: py_env_switch <env_name> | list | uv"
            echo "📋 Available environments:"
            py_env_switch list
            ;;
        *)
            if command -v pyenv >/dev/null 2>&1; then
                echo "🔄 Switching to Python $action..."
                pyenv global "$action" && echo "✅ Switched to $(python --version)"
            else
                echo "❌ Pyenv not available"
                return 1
            fi
            ;;
    esac
}

# =====================================================
# ALIASES
# =====================================================

alias py-status='python_status'
alias py-switch='py_env_switch'
alias py-list='py_env_switch list'
alias py-uv='py_env_switch uv'

echo "✅ Python module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export PYTHON_MODULE_LOADED=true