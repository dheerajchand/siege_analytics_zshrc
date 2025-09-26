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

# Ensure essential PATH components (check for duplicates)
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
    export PATH="/usr/local/bin:$PATH"
fi
if [[ ":$PATH:" != *":/usr/bin:"* ]]; then
    export PATH="/usr/bin:$PATH"
fi
if [[ ":$PATH:" != *":/bin:"* ]]; then
    export PATH="/bin:$PATH"
fi
if [[ ":$PATH:" != *":/usr/sbin:"* ]]; then
    export PATH="/usr/sbin:$PATH"
fi
if [[ ":$PATH:" != *":/sbin:"* ]]; then
    export PATH="/sbin:$PATH"
fi

# UV integration (fast Python package manager)
if [[ -d "$HOME/.local/share/uv" ]] && [[ ":$PATH:" != *":$HOME/.local/share/uv/bin:"* ]]; then
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
            # Add system paths only if not already present
            for sys_path in "/usr/local/bin" "/usr/bin" "/bin" "/usr/sbin" "/sbin"; do
                if [[ ":$PATH:" != *":$sys_path:"* ]]; then
                    export PATH="$sys_path:$PATH"
                fi
            done
        }
        echo "✅ Path configuration loaded"
    else
        echo "⚠️  paths.zsh not found, using minimal PATH"
        # Add system paths only if not already present
        for sys_path in "/usr/local/bin" "/usr/bin" "/bin" "/usr/sbin" "/sbin"; do
            if [[ ":$PATH:" != *":$sys_path:"* ]]; then
                export PATH="$sys_path:$PATH"
            fi
        done
    fi
    
    # Skip core.zsh loading in JetBrains mode to avoid conflicts
    # Essential PATH is already set above
    
    echo "🎯 Essential functions ready"
}

# Phase 2: Progressive enhancement (background loading)
progressive_jetbrains_load() {
    # Wait for IDE to stabilize
    sleep 2
    
    echo ""
    echo "🔄 Progressive enhancement for $CURRENT_JETBRAINS_IDE..."
    echo "⏳ Loading additional modules in background..."
    
    # Load IDE-specific configurations
    case "$CURRENT_JETBRAINS_IDE" in
        "DataSpell"|"PyCharm")
            echo "🐍 Loading Python development tools..."
            # Python-specific setup
            if [[ -f "$HOME/.config/zsh/modules/python.module.zsh" ]]; then
                source "$HOME/.config/zsh/modules/python.module.zsh"
                echo "✅ Python module loaded"
            elif [[ -f "$HOME/.config/zsh/config/python.zsh" ]]; then
                source "$HOME/.config/zsh/config/python.zsh"
                echo "✅ Python tools loaded"
            fi

            # Load Python managers (universal pyenv/UV system)
            if [[ -f "$HOME/.config/zsh/modules/languages/python/managers.zsh" ]]; then
                source "$HOME/.config/zsh/modules/languages/python/managers.zsh"
                echo "✅ Universal Python/UV managers loaded"
            fi
            ;;
        "WebStorm"|"IntelliJ")
            echo "🌐 Loading web development tools..."
            # Web development tools
            if [[ -f "$HOME/.config/zsh/config/web.zsh" ]]; then
                source "$HOME/.config/zsh/config/web.zsh"
                echo "✅ Web tools loaded"
            fi
            ;;
        "CLion")
            echo "⚙️  Loading C++ development tools..."
            # C++ development tools
            if [[ -f "$HOME/.config/zsh/config/cpp.zsh" ]]; then
                source "$HOME/.config/zsh/config/cpp.zsh"
                echo "✅ C++ tools loaded"
            fi
            ;;
        "GoLand")
            echo "🐹 Loading Go development tools..."
            # Go development tools
            if [[ -f "$HOME/.config/zsh/config/go.zsh" ]]; then
                source "$HOME/.config/zsh/config/go.zsh"
                echo "✅ Go tools loaded"
            fi
            ;;
        "Android Studio")
            echo "📱 Loading Android development tools..."
            # Android development tools
            if [[ -f "$HOME/.config/zsh/config/android.zsh" ]]; then
                source "$HOME/.config/zsh/config/android.zsh"
                echo "✅ Android tools loaded"
            fi
            ;;
        *)
            echo "🔧 Loading general development tools..."
            ;;
    esac
    
    # Load universal IDE helpers
    echo "📦 Loading universal IDE integration..."
    if [[ -f "$HOME/.config/zsh/ide_helpers.zsh" ]]; then
        source "$HOME/.config/zsh/ide_helpers.zsh"
        echo "✅ Universal IDE helpers loaded"
    fi

    # Load additional utility modules
    echo "📦 Loading utility modules..."
    if [[ -f "$HOME/.config/zsh/config/credentials.zsh" ]]; then
        source "$HOME/.config/zsh/config/credentials.zsh" 2>/dev/null && echo "✅ Credentials module loaded"
    fi

    if [[ -f "$HOME/.config/zsh/config/database.zsh" ]]; then
        source "$HOME/.config/zsh/config/database.zsh" 2>/dev/null && echo "✅ Database module loaded"
    fi

    if [[ -f "$HOME/.config/zsh/config/status.zsh" ]]; then
        source "$HOME/.config/zsh/config/status.zsh" 2>/dev/null && echo "✅ Status module loaded"
    fi

    if [[ -f "$HOME/.config/zsh/config/docker.zsh" ]]; then
        source "$HOME/.config/zsh/config/docker.zsh" 2>/dev/null && echo "✅ Docker module loaded"
    fi

    # Load backup functions if available and not explicitly disabled
    if [[ -f "$HOME/.config/zsh/config/backup.zsh" ]] && [[ "$SKIP_BACKUP_FUNCTIONS" != "true" ]]; then
        source "$HOME/.config/zsh/config/backup.zsh"
        echo "✅ Backup functions loaded"
    fi
    
    echo ""
    echo "🎯 $CURRENT_JETBRAINS_IDE fully configured!"
    echo "💡 All development tools are now available"
    echo ""
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

# Welcome message
echo "🚀 $CURRENT_JETBRAINS_IDE detected - Progressive loading enabled"
echo "💡 Type 'upgrade_jetbrains_shell' for immediate full configuration"
echo "💡 Type 'jetbrains_status' for configuration details"

# =====================================================
# FILE ASSOCIATION MANAGEMENT
# =====================================================

toggle_notebook_association() {
    """
    Toggle notebook (.ipynb) file associations between JetBrains IDEs
    Works on macOS, Ubuntu, and Red Hat Linux systems
    """
    local system=$(uname -s)
    local current_ide=""
    local target_ide=""
    
    # Detect current system
    case "$system" in
        "Darwin")
            echo "🍎 macOS detected"
            ;;
        "Linux")
            echo "🐧 Linux detected"
            # Detect Linux distribution
            if [[ -f /etc/os-release ]]; then
                source /etc/os-release
                case "$ID" in
                    "ubuntu"|"debian")
                        echo "📦 Ubuntu/Debian detected"
                        ;;
                    "rhel"|"centos"|"fedora")
                        echo "📦 Red Hat/CentOS/Fedora detected"
                        ;;
                    *)
                        echo "📦 Other Linux distribution: $ID"
                        ;;
                esac
            fi
            ;;
        *)
            echo "❌ Unsupported system: $system"
            return 1
            ;;
    esac
    
    # Get current association (if possible)
    case "$system" in
        "Darwin")
            # macOS - check current default app
            local current_app=$(defaults read com.apple.LaunchServices/com.apple.launchservices.secure LSHandlers 2>/dev/null | grep -A 2 -B 2 "ipynb" | grep "CFBundleIdentifier" | head -1 | cut -d'"' -f4)
            if [[ -n "$current_app" ]]; then
                echo "Current association: $current_app"
                if [[ "$current_app" == *"dataspell"* ]]; then
                    current_ide="DataSpell"
                    target_ide="PyCharm"
                elif [[ "$current_app" == *"pycharm"* ]]; then
                    current_ide="PyCharm"
                    target_ide="DataSpell"
                else
                    echo "Unknown IDE: $current_app"
                    target_ide="DataSpell"
                fi
            else
                echo "No current association found"
                target_ide="DataSpell"
            fi
            ;;
        "Linux")
            # Linux - check xdg-mime
            local current_app=$(xdg-mime query default application/x-ipynb+json 2>/dev/null)
            if [[ -n "$current_app" ]]; then
                echo "Current association: $current_app"
                if [[ "$current_app" == *"dataspell"* ]]; then
                    current_ide="DataSpell"
                    target_ide="PyCharm"
                elif [[ "$current_app" == *"pycharm"* ]]; then
                    current_ide="PyCharm"
                    target_ide="DataSpell"
                else
                    echo "Unknown IDE: $current_app"
                    target_ide="DataSpell"
                fi
            else
                echo "No current association found"
                target_ide="DataSpell"
            fi
            ;;
    esac
    
    echo "🔄 Toggling from $current_ide to $target_ide"
    
    # Set new association
    case "$system" in
        "Darwin")
            # macOS - use duti if available, otherwise use defaults
            if command -v duti >/dev/null 2>&1; then
                case "$target_ide" in
                    "DataSpell")
                        duti -s com.jetbrains.dataspell ipynb all
                        ;;
                    "PyCharm")
                        duti -s com.jetbrains.pycharm ipynb all
                        ;;
                esac
            else
                echo "⚠️  duti not installed. Install with: brew install duti"
                echo "   Or manually set in System Preferences > Default Apps"
                return 1
            fi
            ;;
        "Linux")
            # Linux - use xdg-mime
            case "$target_ide" in
                "DataSpell")
                    xdg-mime default dataspell.desktop application/x-ipynb+json
                    ;;
                "PyCharm")
                    xdg-mime default pycharm.desktop application/x-ipynb+json
                    ;;
            esac
            ;;
    esac
    
    echo "✅ Notebook files now associated with $target_ide"
    echo "💡 Test with: open /path/to/notebook.ipynb"
}

# =====================================================
# ALIASES
# =====================================================

alias jetbrains-upgrade='upgrade_jetbrains_shell'
alias jetbrains-reload='reload_jetbrains_config'
alias jetbrains-status='jetbrains_status'
alias toggle-notebooks='toggle_notebook_association'

# =====================================================
# MODULE COMPLETION
# =====================================================

echo "✅ JetBrains module loaded successfully"