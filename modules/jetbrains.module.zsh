#!/usr/bin/env zsh
# =====================================================
# JETBRAINS MODULE - JetBrains IDE Integration
# =====================================================
#
# Purpose: JetBrains IDE integration and PATH setup
# Provides: PyCharm, DataSpell, IntelliJ command line tools
# Dependencies: None
# =====================================================

# Loading JetBrains module...

# =====================================================
# JETBRAINS PATH SETUP
# =====================================================

# Add JetBrains Toolbox script paths
if [[ -d "$HOME/.local/share/JetBrains/Toolbox/scripts" ]]; then
    export PATH="$HOME/.local/share/JetBrains/Toolbox/scripts:$PATH"
fi

# Add JetBrains command line tools (common locations)
if [[ -d "/Applications/PyCharm.app/Contents/MacOS" ]]; then
    export PATH="/Applications/PyCharm.app/Contents/MacOS:$PATH"
fi

if [[ -d "/Applications/DataSpell.app/Contents/MacOS" ]]; then
    export PATH="/Applications/DataSpell.app/Contents/MacOS:$PATH"
fi

if [[ -d "/Applications/IntelliJ IDEA.app/Contents/MacOS" ]]; then
    export PATH="/Applications/IntelliJ IDEA.app/Contents/MacOS:$PATH"
fi

# Add JetBrains Toolbox bin directory if it exists
if [[ -d "$HOME/.jetbrains/bin" ]]; then
    export PATH="$HOME/.jetbrains/bin:$PATH"
    echo "✅ JetBrains bin added to PATH"
fi

# =====================================================
# JETBRAINS DETECTION FUNCTIONS
# =====================================================

detect_jetbrains_ide() {
    local ide_name="JetBrains IDE"

    # Check environment variables first
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
    fi

    echo "$ide_name"
}

# =====================================================
# JETBRAINS UTILITY FUNCTIONS
# =====================================================

# Quick launch functions
pycharm() {
    if command -v pycharm >/dev/null 2>&1; then
        command pycharm "$@"
    elif [[ -d "/Applications/PyCharm.app" ]]; then
        open -a "PyCharm" "$@"
    else
        echo "❌ PyCharm not found"
        return 1
    fi
}

dataspell() {
    if command -v dataspell >/dev/null 2>&1; then
        command dataspell "$@"
    elif [[ -d "/Applications/DataSpell.app" ]]; then
        open -a "DataSpell" "$@"
    else
        echo "❌ DataSpell not found"
        return 1
    fi
}

intellij() {
    if command -v idea >/dev/null 2>&1; then
        command idea "$@"
    elif [[ -d "/Applications/IntelliJ IDEA.app" ]]; then
        open -a "IntelliJ IDEA" "$@"
    else
        echo "❌ IntelliJ IDEA not found"
        return 1
    fi
}

# JetBrains IDE status
jetbrains_status() {
    echo "🎯 JetBrains IDE Integration Status"
    echo "==================================="
    echo ""

    # Check for installed IDEs
    echo "📱 Installed IDEs:"
    [[ -d "/Applications/PyCharm.app" ]] && echo "  ✅ PyCharm" || echo "  ❌ PyCharm"
    [[ -d "/Applications/DataSpell.app" ]] && echo "  ✅ DataSpell" || echo "  ❌ DataSpell"
    [[ -d "/Applications/IntelliJ IDEA.app" ]] && echo "  ✅ IntelliJ IDEA" || echo "  ❌ IntelliJ IDEA"
    [[ -d "/Applications/WebStorm.app" ]] && echo "  ✅ WebStorm" || echo "  ❌ WebStorm"

    echo ""
    echo "🛠️  Command Line Tools:"
    command -v pycharm >/dev/null 2>&1 && echo "  ✅ pycharm command available" || echo "  ❌ pycharm command not found"
    command -v dataspell >/dev/null 2>&1 && echo "  ✅ dataspell command available" || echo "  ❌ dataspell command not found"
    command -v idea >/dev/null 2>&1 && echo "  ✅ idea command available" || echo "  ❌ idea command not found"

    echo ""
    echo "📂 JetBrains Paths in PATH:"
    echo "$PATH" | tr ':' '\n' | grep -i jetbrains | sed 's/^/  /'

    if [[ -n "$(echo "$PATH" | tr ':' '\n' | grep -i jetbrains)" ]]; then
        echo "  ✅ JetBrains paths found in PATH"
    else
        echo "  ⚠️  No JetBrains paths in PATH"
    fi
}

# IDE environment detection
ide_detect() {
    local current_ide=$(detect_jetbrains_ide)
    echo "🎯 Current IDE: $current_ide"

    if [[ "$current_ide" != "JetBrains IDE" ]]; then
        echo "✅ JetBrains IDE environment detected"
        export IDE_MODE=true
        export CURRENT_JETBRAINS_IDE="$current_ide"
    else
        echo "📱 Running in regular terminal"
        export IDE_MODE=false
    fi
}

# =====================================================
# MODULE COMPLETION
# =====================================================

echo "✅ JetBrains functions loaded"
echo "✅ JetBrains module loaded successfully"