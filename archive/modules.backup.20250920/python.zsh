#!/usr/bin/env zsh
# =====================================================
# PYTHON MODULE - On-demand Python environment management
# =====================================================

echo "🐍 Loading Python environment module..."

# =====================================================
# PYTHON MANAGER DETECTION & SETUP
# =====================================================

# Python manager preference
export PYTHON_MANAGER="${PYTHON_MANAGER:-auto}"
export PREFERRED_VENV="${PREFERRED_VENV:-geo31111}"

# Pyenv setup (if available)
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    # Pyenv-virtualenv
    if command -v pyenv-virtualenv >/dev/null 2>&1; then
        eval "$(pyenv virtualenv-init -)"

        # Auto-activate preferred environment
        if [[ -n "$PREFERRED_VENV" ]] && pyenv versions --bare | grep -q "^$PREFERRED_VENV$"; then
            pyenv activate "$PREFERRED_VENV" 2>/dev/null
        fi
    fi

    echo "✅ Pyenv initialized"
fi

# UV setup (if available)
if command -v uv >/dev/null 2>&1; then
    # UV completion
    eval "$(uv generate-shell-completion zsh)"
    echo "✅ UV initialized"
fi

# =====================================================
# PYTHON FUNCTIONS
# =====================================================

python_status() {
    echo "🐍 Python Environment Status"
    echo "============================"
    echo "Python: $(python --version 2>&1)"
    echo "Location: $(which python)"
    echo "Virtual Env: ${VIRTUAL_ENV:-'None'}"

    if command -v pyenv >/dev/null 2>&1; then
        echo "Pyenv: $(pyenv version | cut -d' ' -f1)"
    fi

    if command -v uv >/dev/null 2>&1; then
        echo "UV: $(uv --version)"
    fi

    if [[ -f "pyproject.toml" ]]; then
        echo "Project: ✅ UV project detected"
    fi
}

py_env_switch() {
    local target="${1:-list}"

    case "$target" in
        "list"|"-l"|"--list")
            echo "🐍 Available Python Environments:"
            if command -v pyenv >/dev/null 2>&1; then
                echo "📦 Pyenv:"
                pyenv versions | sed 's/^/  /'
            fi
            if [[ -f "pyproject.toml" ]]; then
                echo "⚡ UV: Current directory"
            fi
            ;;
        "uv")
            if [[ -f "pyproject.toml" ]]; then
                echo "⚡ Activating UV project"
                uv sync && source .venv/bin/activate
            else
                echo "❌ No pyproject.toml found"
            fi
            ;;
        *)
            if command -v pyenv >/dev/null 2>&1; then
                pyenv activate "$target"
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