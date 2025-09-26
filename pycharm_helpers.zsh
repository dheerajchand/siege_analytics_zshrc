#!/usr/bin/env zsh
# PyCharm Helper Functions

# Quick PyCharm environment setup
pycharm-env-info() {
    echo "🚀 PyCharm Environment Info"
    echo "============================"
    echo "Python: $(which python3)"
    echo "Virtual Env: ${VIRTUAL_ENV:-'None'}"
    echo "Pyenv Version: ${PYENV_VERSION:-$(pyenv version-name 2>/dev/null)}"
    echo "UV Available: $(command -v uv >/dev/null && echo 'Yes' || echo 'No')"
    echo "UV Version: $(uv --version 2>/dev/null | head -1)"
    echo ""

    if [[ -f "pyproject.toml" ]]; then
        echo "📦 UV Project: Found pyproject.toml"
    else
        echo "💡 No UV project found. Use universal commands: 'py-uv' or 'uv-init'"
    fi

    echo ""
    echo "🔧 Universal Commands Available:"
    echo "   py-switch list    # List all Python environments"
    echo "   py-uv            # Activate UV project (universal)"
    echo "   py-info          # Show Python environment info"
}

# Initialize UV project with PyCharm interpreter info
pycharm-uv-setup() {
    echo "🛠️  Setting up UV project with PyCharm integration..."

    # Use universal UV init
    if [[ ! -f "pyproject.toml" ]]; then
        echo "Creating UV project using universal system..."
        uv-init
    fi

    # Sync and get interpreter path
    echo "Syncing UV project..."
    uv sync
    local venv_python=$(uv run python -c "import sys; print(sys.executable)" 2>/dev/null)

    if [[ -n "$venv_python" ]]; then
        echo ""
        echo "🎯 PyCharm Python Interpreter Path:"
        echo "   $venv_python"
        echo ""
        echo "📝 To configure PyCharm:"
        echo "   1. File > Settings > Project > Python Interpreter"
        echo "   2. Add Interpreter > Existing Environment"
        echo "   3. Select: $venv_python"
        echo ""
        echo "💡 Use universal command 'py-uv' to activate this environment in terminal"
    fi
}

# Wrapper that uses universal system
pycharm-activate-uv() {
    echo "🔄 Using universal Python/UV system..."
    echo "Run: py-uv"
    py-uv
}

# Quick fix for common PyCharm issues
pycharm-fix() {
    echo "🔧 Running PyCharm diagnostic fix..."

    # Reload zsh configuration
    echo "1. Reloading zsh configuration..."
    if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
        source "$HOME/.config/zsh/zshrc"
        echo "   ✅ Configuration reloaded"
    fi

    # Load Python module
    echo "2. Loading Python module..."
    if command -v load-python >/dev/null 2>&1; then
        load-python
        echo "   ✅ Python module loaded"
    else
        echo "   ⚠️  load-python command not available"
    fi

    # Check environment
    echo "3. Environment check:"
    pycharm-env-info
}

# Export functions (updated to use universal system)
export -f pycharm-env-info pycharm-uv-setup pycharm-activate-uv pycharm-fix
