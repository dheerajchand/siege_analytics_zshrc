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
        # Critical: Initialize pyenv with both --path and regular init for shims
        eval "$(pyenv init --path)"
        eval "$(pyenv init -)"

        # Initialize pyenv-virtualenv if available
        if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
            local virtualenv_init_script
            virtualenv_init_script="$(pyenv virtualenv-init -)"
            if [[ -n "$virtualenv_init_script" ]]; then
                eval "$virtualenv_init_script"
                if [[ "$PYENV_VIRTUALENV_INIT" == "1" ]]; then
                    echo "✅ Pyenv-virtualenv initialized successfully"
                else
                    echo "⚠️  Pyenv-virtualenv initialization may have failed"
                fi
            else
                _report_missing_dependency "pyenv-virtualenv-init" "Virtual environment activation" "Python environment setup" "Ensure pyenv-virtualenv is properly installed"
            fi
        else
            _report_missing_dependency "pyenv-virtualenv-init" "Virtual environment initialization" "Python environment setup" "Install pyenv-virtualenv plugin"
        fi

        echo "✅ Pyenv initialized with shims"
    fi
fi

# Setup UV if available (uses centralized UV_BIN_PATH)
if command -v uv >/dev/null 2>&1; then
    export PATH="$UV_BIN_PATH:$PATH"
    echo "✅ UV initialized"
fi

# Auto-activate preferred pyenv environment
if command -v pyenv >/dev/null 2>&1 && [[ -n "$PREFERRED_VENV" ]]; then
    echo "🔍 Attempting to activate preferred environment: $PREFERRED_VENV"

    if pyenv versions --bare | grep -q "^$PREFERRED_VENV$"; then
        # Try activation with detailed error reporting
        local activation_output
        activation_output="$(pyenv activate "$PREFERRED_VENV" 2>&1)"
        local activation_status=$?

        if [[ $activation_status -eq 0 ]]; then
            echo "✅ Successfully activated pyenv environment: $PREFERRED_VENV"
            echo "🔍 Current pyenv version: $(pyenv version)"
        else
            echo "❌ Failed to activate pyenv environment: $PREFERRED_VENV"
            echo "    Error: $activation_output"
            echo "    Reason: pyenv-virtualenv may not be properly initialized"
            echo "    Current pyenv version: $(pyenv version)"

            # Try alternative activation method
            echo "🔄 Attempting alternative activation method..."
            if pyenv shell "$PREFERRED_VENV" 2>/dev/null; then
                echo "✅ Activated $PREFERRED_VENV using 'pyenv shell'"
            else
                echo "❌ All activation methods failed"
                echo "    You may need to manually run: pyenv activate $PREFERRED_VENV"
            fi
        fi
    else
        _report_config_error "PREFERRED_VENV" "$PREFERRED_VENV" "Environment not found in pyenv" "Create environment: pyenv virtualenv 3.11.11 $PREFERRED_VENV"
        echo "    Available environments:"
        pyenv versions --bare | grep -E "(geo|\..*envs)" | sed 's/^/      /'
    fi
else
    if ! command -v pyenv >/dev/null 2>&1; then
        _report_missing_dependency "pyenv" "Python version manager" "Python environment setup" "brew install pyenv"
    else
        _report_config_error "PREFERRED_VENV" "${PREFERRED_VENV:-unset}" "Variable not set" "Set PREFERRED_VENV in variables.zsh"
    fi
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
        _report_missing_dependency "python3" "Python interpreter" "Python development" "Install Python via pyenv or system package manager"
    fi

    # Pyenv status
    if command -v pyenv >/dev/null 2>&1; then
        echo "✅ Pyenv: $(pyenv --version)"
        echo "🔄 Current: $(pyenv version)"
        echo "📋 Available:"
        pyenv versions --bare | head -5 | sed 's/^/  /'
    else
        _report_missing_dependency "pyenv" "Python version manager" "Python development" "brew install pyenv"
    fi

    # UV status
    if command -v uv >/dev/null 2>&1; then
        echo "✅ UV: $(uv --version)"
    else
        _report_missing_dependency "uv" "Fast Python package manager" "Python development" "curl -LsSf https://astral.sh/uv/install.sh | sh"
    fi

    # Virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "🌟 Active virtualenv: $(basename $VIRTUAL_ENV)"
    else
        echo "💤 No virtual environment active"
    fi
}

echo "✅ Python module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export PYTHON_MODULE_LOADED=true