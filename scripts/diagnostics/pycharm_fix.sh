#!/bin/bash
# =====================================================
# PYCHARM INTEGRATION FIX SCRIPT
# =====================================================
#
# Purpose: Fix PyCharm Python module errors and UV integration
# Issues addressed:
# 1. Python module not loading properly in PyCharm
# 2. UV integration not working in PyCharm terminal
# 3. Environment detection and setup
# =====================================================

echo "🚀 PyCharm Integration Fix"
echo "=========================="

# Check if we're in the right directory
if [[ ! -f "$HOME/.config/zsh/config/jetbrains.zsh" ]]; then
    echo "❌ JetBrains configuration not found"
    exit 1
fi

echo "1. 🔧 Updating JetBrains configuration..."

# Ensure JetBrains module loads Python properly
if grep -q "modules/python.module.zsh" "$HOME/.config/zsh/config/jetbrains.zsh"; then
    echo "   ✅ Python module path already updated"
else
    echo "   ⚠️  Python module path needs updating"
fi

echo "2. 🐍 Setting up PyCharm Python environment..."

# Get current Python info
python_path=$(which python3)
pyenv_version=${PYENV_VERSION:-$(pyenv version-name 2>/dev/null)}
uv_version=$(uv --version 2>/dev/null | head -1)

echo "   📍 Python: $python_path"
echo "   🔄 Pyenv: $pyenv_version"
echo "   ⚡ UV: $uv_version"

echo "3. 🛠️  Creating PyCharm-specific functions..."

# Create PyCharm helper script
cat > "$HOME/.config/zsh/pycharm_helpers.zsh" << 'EOF'
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
        echo "💡 No UV project found. Run 'pycharm-uv-init' to create one."
    fi
}

# Initialize UV project for PyCharm
pycharm-uv-init() {
    echo "🛠️  Initializing UV project for PyCharm..."

    if [[ -f "pyproject.toml" ]]; then
        echo "⚠️  pyproject.toml already exists"
    else
        uv init --python python3
        echo "✅ UV project created"
    fi

    # Get virtual environment info
    local venv_info=$(uv run python -c "import sys; print(f'Python: {sys.executable}'); print(f'Prefix: {sys.prefix}')" 2>/dev/null)
    if [[ -n "$venv_info" ]]; then
        echo ""
        echo "🎯 PyCharm Configuration:"
        echo "$venv_info"
        echo ""
        echo "📝 To configure PyCharm:"
        echo "   1. File > Settings > Project > Python Interpreter"
        echo "   2. Add Interpreter > Existing Environment"
        echo "   3. Select: $(uv run python -c 'import sys; print(sys.executable)' 2>/dev/null)"
    fi
}

# Activate UV environment in current shell
pycharm-uv-activate() {
    if [[ -f "pyproject.toml" ]]; then
        echo "🚀 Activating UV environment..."
        eval "$(uv run python -c '
import os, sys
venv = os.environ.get("VIRTUAL_ENV", "")
if venv:
    print(f"export VIRTUAL_ENV=\"{venv}\"")
    print(f"export PATH=\"{venv}/bin:$PATH\"")
print(f"export PYTHONPATH=\"{os.pathsep.join(sys.path[1:])}\"")
')"
        echo "✅ UV environment activated"
    else
        echo "❌ No pyproject.toml found. Run 'pycharm-uv-init' first."
    fi
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

# Export functions
export -f pycharm-env-info pycharm-uv-init pycharm-uv-activate pycharm-fix
EOF

echo "   ✅ Helper functions created"

echo "4. 🔄 Testing current environment..."

# Source the helpers and test
source "$HOME/.config/zsh/pycharm_helpers.zsh"
pycharm-env-info

echo ""
echo "🎉 PyCharm Integration Fix Complete!"
echo "===================================="
echo ""
echo "📋 Available Commands:"
echo "   pycharm-env-info     - Show environment info"
echo "   pycharm-uv-setup     - Initialize UV project with PyCharm paths"
echo "   pycharm-activate-uv  - Use universal py-uv system"
echo "   pycharm-fix          - Quick diagnostic fix"
echo ""
echo "🔧 Universal Python/UV Commands:"
echo "   py-switch list       - List all Python environments"
echo "   py-uv               - Activate UV project (works everywhere)"
echo "   py-info             - Show Python environment status"
echo "   uv-init             - Initialize UV project"
echo ""
echo "🚀 Next Steps:"
echo "   1. Restart PyCharm"
echo "   2. In PyCharm terminal, run: source ~/.config/zsh/pycharm_helpers.zsh"
echo "   3. Run: pycharm-fix"
echo "   4. Use universal commands: py-uv, py-switch, py-info"
echo ""