#!/usr/bin/env zsh
# =====================================================
# UNIVERSAL IDE INTEGRATION HELPERS
# =====================================================
#
# Purpose: Provide consistent development environment setup across all IDEs
# Supports: JetBrains IDEs, Cursor, VS Code, and others
# Dependencies: Universal Python/UV system, modules system
# =====================================================

# =====================================================
# IDE DETECTION
# =====================================================

detect_current_ide() {
    local ide_name="Terminal"

    # JetBrains IDEs
    if [[ -n "$JETBRAINS_IDE" ]]; then
        ide_name="$JETBRAINS_IDE"
    elif [[ -n "$PYCHARM_HOSTED" ]]; then
        ide_name="PyCharm"
    elif [[ -n "$DATASPELL_IDE" ]]; then
        ide_name="DataSpell"
    elif [[ "$TERM_PROGRAM" == "JetBrains"* ]]; then
        ide_name="JetBrains IDE"
    elif [[ "$0" == *"pycharm"* ]]; then
        ide_name="PyCharm"
    elif [[ "$0" == *"dataspell"* ]]; then
        ide_name="DataSpell"
    elif [[ "$0" == *"intellij"* ]]; then
        ide_name="IntelliJ IDEA"
    elif [[ "$0" == *"webstorm"* ]]; then
        ide_name="WebStorm"
    elif [[ "$0" == *"clion"* ]]; then
        ide_name="CLion"
    elif [[ "$0" == *"goland"* ]]; then
        ide_name="GoLand"
    elif [[ "$0" == *"rider"* ]]; then
        ide_name="Rider"
    elif [[ "$0" == *"phpstorm"* ]]; then
        ide_name="PhpStorm"
    elif [[ "$0" == *"rubymine"* ]]; then
        ide_name="RubyMine"
    elif [[ "$0" == *"appcode"* ]]; then
        ide_name="AppCode"
    elif [[ "$0" == *"android-studio"* ]]; then
        ide_name="Android Studio"
    # Cursor
    elif [[ -n "$CURSOR_IDE" ]] || [[ "$TERM_PROGRAM" == "Cursor"* ]] || [[ "$0" == *"cursor"* ]]; then
        ide_name="Cursor"
    # VS Code
    elif [[ "$TERM_PROGRAM" == "vscode" ]] || [[ -n "$VSCODE_INJECTION" ]]; then
        ide_name="VS Code"
    fi

    echo "$ide_name"
}

get_ide_category() {
    local ide_name="$1"
    case "$ide_name" in
        "PyCharm"|"DataSpell"|"IntelliJ IDEA"|"WebStorm"|"CLion"|"GoLand"|"Rider"|"PhpStorm"|"RubyMine"|"AppCode"|"Android Studio"|"JetBrains IDE")
            echo "jetbrains"
            ;;
        "Cursor")
            echo "cursor"
            ;;
        "VS Code")
            echo "vscode"
            ;;
        *)
            echo "terminal"
            ;;
    esac
}

# =====================================================
# UNIVERSAL ENVIRONMENT INFO
# =====================================================

ide-env-info() {
    local ide=$(detect_current_ide)
    local category=$(get_ide_category "$ide")

    echo "🚀 $ide Development Environment"
    echo "=================================="
    echo "IDE: $ide ($category)"
    echo "Python: $(which python3)"
    echo "Virtual Env: ${VIRTUAL_ENV:-'None'}"
    echo "Pyenv Version: ${PYENV_VERSION:-$(pyenv version-name 2>/dev/null)}"
    echo "UV Available: $(command -v uv >/dev/null && echo 'Yes' || echo 'No')"
    echo "UV Version: $(uv --version 2>/dev/null | head -1)"
    echo ""

    if [[ -f "pyproject.toml" ]]; then
        echo "📦 UV Project: Found pyproject.toml"
        if [[ -d ".venv" ]]; then
            echo "🔗 Virtual Environment: Ready"
        else
            echo "⚠️  Virtual Environment: Run 'uv sync'"
        fi
    else
        echo "💡 No UV project found. Use: 'uv-init' or 'py-uv'"
    fi

    echo ""
    echo "🔧 Universal Commands Available:"
    echo "   py-switch list    # List all Python environments"
    echo "   py-uv            # Activate UV project (universal)"
    echo "   py-info          # Show Python environment info"
    echo "   ide-uv-setup     # Setup UV with IDE interpreter info"
}

# =====================================================
# UNIVERSAL UV SETUP
# =====================================================

ide-uv-setup() {
    local ide=$(detect_current_ide)
    echo "🛠️  Setting up UV project for $ide..."

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
        echo "🎯 $ide Python Interpreter Path:"
        echo "   $venv_python"
        echo ""

        case "$(get_ide_category "$ide")" in
            "jetbrains")
                echo "📝 To configure $ide:"
                echo "   1. File > Settings > Project > Python Interpreter"
                echo "   2. Add Interpreter > Existing Environment"
                echo "   3. Select: $venv_python"
                ;;
            "cursor")
                echo "📝 To configure Cursor:"
                echo "   1. Cmd+Shift+P > Python: Select Interpreter"
                echo "   2. Select: $venv_python"
                echo "   3. Or set in .vscode/settings.json:"
                echo "      \"python.pythonPath\": \"$venv_python\""
                ;;
            "vscode")
                echo "📝 To configure VS Code:"
                echo "   1. Cmd+Shift+P > Python: Select Interpreter"
                echo "   2. Select: $venv_python"
                ;;
        esac

        echo ""
        echo "💡 Use universal command 'py-uv' to activate this environment in terminal"
    fi
}

# =====================================================
# UNIVERSAL ENVIRONMENT ACTIVATION
# =====================================================

ide-activate-uv() {
    local ide=$(detect_current_ide)
    echo "🔄 Activating UV environment for $ide using universal system..."
    py-uv
}

# =====================================================
# UNIVERSAL IDE DIAGNOSTIC
# =====================================================

ide-fix() {
    local ide=$(detect_current_ide)
    local category=$(get_ide_category "$ide")

    echo "🔧 Running $ide diagnostic fix..."

    # Reload zsh configuration
    echo "1. Reloading zsh configuration..."
    if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
        source "$HOME/.config/zsh/zshrc"
        echo "   ✅ Configuration reloaded"
    fi

    # Load appropriate modules based on IDE
    echo "2. Loading development modules..."
    case "$category" in
        "jetbrains"|"cursor"|"vscode")
            if command -v load_module >/dev/null 2>&1; then
                load_module python
                echo "   ✅ Python module loaded"

                # Load additional modules based on IDE type
                case "$ide" in
                    "WebStorm"|"IntelliJ IDEA"|"Cursor")
                        command -v load_module >/dev/null 2>&1 && load_module javascript
                        echo "   ✅ JavaScript module loaded"
                        ;;
                    "CLion")
                        # C++ specific modules if available
                        echo "   ✅ C++ development ready"
                        ;;
                    "GoLand")
                        # Go specific modules if available
                        echo "   ✅ Go development ready"
                        ;;
                    "Android Studio")
                        # Android specific modules if available
                        echo "   ✅ Android development ready"
                        ;;
                esac
            else
                echo "   ⚠️  Module loading not available"
            fi
            ;;
    esac

    # Check environment
    echo "3. Environment check:"
    ide-env-info
}

# =====================================================
# IDE-SPECIFIC HELPERS
# =====================================================

# JetBrains-specific functions
jetbrains-fix() {
    if [[ "$(get_ide_category "$(detect_current_ide)")" == "jetbrains" ]]; then
        ide-fix
    else
        echo "❌ Not running in a JetBrains IDE"
    fi
}

jetbrains-uv-setup() {
    if [[ "$(get_ide_category "$(detect_current_ide)")" == "jetbrains" ]]; then
        ide-uv-setup
    else
        echo "❌ Not running in a JetBrains IDE"
    fi
}

# Cursor-specific functions
cursor-fix() {
    if [[ "$(get_ide_category "$(detect_current_ide)")" == "cursor" ]]; then
        ide-fix
    else
        echo "❌ Not running in Cursor IDE"
    fi
}

cursor-uv-setup() {
    if [[ "$(get_ide_category "$(detect_current_ide)")" == "cursor" ]]; then
        ide-uv-setup
    else
        echo "❌ Not running in Cursor IDE"
    fi
}

# VS Code-specific functions
vscode-fix() {
    if [[ "$(get_ide_category "$(detect_current_ide)")" == "vscode" ]]; then
        ide-fix
    else
        echo "❌ Not running in VS Code"
    fi
}

vscode-uv-setup() {
    if [[ "$(get_ide_category "$(detect_current_ide)")" == "vscode" ]]; then
        ide-uv-setup
    else
        echo "❌ Not running in VS Code"
    fi
}

# =====================================================
# BACKWARD COMPATIBILITY
# =====================================================

# Keep PyCharm-specific names for compatibility
pycharm-env-info() { ide-env-info; }
pycharm-uv-setup() { ide-uv-setup; }
pycharm-activate-uv() { ide-activate-uv; }
pycharm-fix() { ide-fix; }

# =====================================================
# EXPORTS
# =====================================================

export -f detect_current_ide get_ide_category ide-env-info ide-uv-setup ide-activate-uv ide-fix
export -f jetbrains-fix jetbrains-uv-setup cursor-fix cursor-uv-setup vscode-fix vscode-uv-setup
export -f pycharm-env-info pycharm-uv-setup pycharm-activate-uv pycharm-fix

echo "✅ Universal IDE integration helpers loaded for $(detect_current_ide)"