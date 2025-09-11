# =====================================================
# JETBRAINS IDE INTEGRATION MODULE
# =====================================================
#
# This module provides optimized shell configuration for JetBrains IDEs
# including DataSpell, PyCharm, IntelliJ, WebStorm, CLion, GoLand, etc.
#
# Features:
# - Fast startup with minimal configuration
# - Progressive loading of full functionality
# - IDE-specific optimizations
# - On-demand function loading
# =====================================================

# =====================================================
# IDE DETECTION
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
    fi
    
    # Additional DataSpell detection
    if [[ "$ide_name" == "JetBrains IDE" ]] && [[ -n "$DATASPELL_APPLICATION_HOME" ]]; then
        ide_name="DataSpell"
    fi
    
    echo "$ide_name"
}

# =====================================================
# JETBRAINS CONFIGURATION
# =====================================================

# Set IDE mode flags
export IDE_MODE=true
export FAST_STARTUP=true
export JETBRAINS_PROGRESSIVE_LOADING=true
export CURRENT_JETBRAINS_IDE=$(detect_jetbrains_ide)

# Essential environment variables for JetBrains IDEs
export SIEGE_UTILITIES_TEST="$HOME/Desktop/in_process/code/siege_utilities_verify"

# Ensure essential PATH components
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# UV integration (fast Python package manager)
if [[ -d "$HOME/.local/share/uv" ]]; then
    export PATH="$HOME/.local/share/uv/bin:$PATH"
fi

# Node.js for web development IDEs
if [[ -d "$HOME/.nvm" ]] && [[ "$CURRENT_JETBRAINS_IDE" =~ "(WebStorm|IntelliJ|DataSpell)" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh" --no-use
fi

# =====================================================
# PROGRESSIVE LOADING SYSTEM
# =====================================================

# Phase 1: Immediate essential functions
load_jetbrains_essentials() {
    echo "⚡ Loading essential functions for $CURRENT_JETBRAINS_IDE..."
    
    # Load paths configuration (always needed) - with error handling
    if [[ -f "$HOME/.config/zsh/config/paths.zsh" ]]; then
        source "$HOME/.config/zsh/config/paths.zsh" 2>/dev/null || {
            echo "⚠️  Could not load paths.zsh, using minimal PATH"
            export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
        }
        echo "✅ Path configuration loaded"
    else
        echo "⚠️  paths.zsh not found, using minimal PATH"
        export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    fi
    
    # Skip core.zsh loading in JetBrains mode to avoid conflicts
    # Essential PATH is already set above
    
    echo "🎯 Essential functions ready"
}

# Phase 2: Progressive enhancement (background loading)
progressive_jetbrains_load() {
    # Wait for IDE to stabilize
    sleep 3
    
    echo "🔄 Progressive enhancement for $CURRENT_JETBRAINS_IDE..."
    
    # Load IDE-specific configurations
    case "$CURRENT_JETBRAINS_IDE" in
        "DataSpell"|"PyCharm")
            echo "🐍 Loading Python development tools..."
            # Python-specific setup
            if [[ -f "$HOME/.config/zsh/config/python.zsh" ]]; then
                source "$HOME/.config/zsh/config/python.zsh"
            fi
            ;;
        "WebStorm"|"IntelliJ")
            echo "🌐 Loading web development tools..."
            # Web development tools
            if [[ -f "$HOME/.config/zsh/config/web.zsh" ]]; then
                source "$HOME/.config/zsh/config/web.zsh"
            fi
            ;;
        "CLion")
            echo "⚙️  Loading C++ development tools..."
            # C++ development tools
            if [[ -f "$HOME/.config/zsh/config/cpp.zsh" ]]; then
                source "$HOME/.config/zsh/config/cpp.zsh"
            fi
            ;;
        "GoLand")
            echo "🐹 Loading Go development tools..."
            # Go development tools
            if [[ -f "$HOME/.config/zsh/config/go.zsh" ]]; then
                source "$HOME/.config/zsh/config/go.zsh"
            fi
            ;;
        "Android Studio")
            echo "📱 Loading Android development tools..."
            # Android development tools
            if [[ -f "$HOME/.config/zsh/config/android.zsh" ]]; then
                source "$HOME/.config/zsh/config/android.zsh"
            fi
            ;;
    esac
    
    # Load backup functions if available and not explicitly disabled
    if [[ -f "$HOME/.config/zsh/config/backup.zsh" ]] && [[ "$SKIP_BACKUP_FUNCTIONS" != "true" ]]; then
        source "$HOME/.config/zsh/config/backup.zsh"
        echo "✅ Backup functions loaded"
    fi
    
    echo "🎯 $CURRENT_JETBRAINS_IDE fully configured!"
}

# Phase 3: Manual upgrade function
upgrade_jetbrains_shell() {
    echo "⚡ Manual upgrade for $CURRENT_JETBRAINS_IDE..."
    progressive_jetbrains_load
}

# =====================================================
# JETBRAINS-SPECIFIC FUNCTIONS
# =====================================================

# Function to reload JetBrains configuration
reload_jetbrains_config() {
    echo "🔄 Reloading JetBrains configuration..."
    source "$HOME/.config/zsh/config/jetbrains.zsh"
}

# Function to show JetBrains status
jetbrains_status() {
    echo "🚀 JetBrains IDE Configuration Status"
    echo "====================================="
    echo "IDE: $CURRENT_JETBRAINS_IDE"
    echo "Mode: $([[ "$IDE_MODE" == "true" ]] && echo "IDE Mode" || echo "Normal Mode")"
    echo "Fast Startup: $([[ "$FAST_STARTUP" == "true" ]] && echo "Enabled" || echo "Disabled")"
    echo "Progressive Loading: $([[ "$JETBRAINS_PROGRESSIVE_LOADING" == "true" ]] && echo "Enabled" || echo "Disabled")"
    echo ""
    echo "Available Commands:"
    echo "  upgrade_jetbrains_shell - Load full configuration"
    echo "  reload_jetbrains_config - Reload JetBrains module"
    echo "  jetbrains_status - Show this status"
}

# =====================================================
# INITIALIZATION
# =====================================================

# Load essential functions immediately
load_jetbrains_essentials

# Start progressive loading in background
progressive_jetbrains_load &

# Welcome message
echo "🚀 $CURRENT_JETBRAINS_IDE detected - Progressive loading enabled"
echo "💡 Type 'upgrade_jetbrains_shell' for immediate full configuration"
echo "💡 Type 'jetbrains_status' for configuration details"

# =====================================================
# ALIASES
# =====================================================

alias jetbrains-upgrade='upgrade_jetbrains_shell'
alias jetbrains-reload='reload_jetbrains_config'
alias jetbrains-status='jetbrains_status'

# =====================================================
# MODULE COMPLETION
# =====================================================

echo "✅ JetBrains module loaded successfully"