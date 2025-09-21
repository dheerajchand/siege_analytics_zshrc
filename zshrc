#!/usr/bin/env zsh
# =====================================================
# 3-TIER ZSH CONFIGURATION - PRODUCTION READY
# =====================================================

export ZSH_CONFIG_DIR="$HOME/.config/zsh"

# Load centralized variables first
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# Oh My Zsh setup
export ZSH="$HOME/.config/zsh/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

# Load Oh My Zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source $ZSH/oh-my-zsh.sh
fi

# Load P10K config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Basic aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Basic functions
mkcd() { mkdir -p "$1" && cd "$1"; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

# =====================================================
# ESSENTIAL MODULE LOADING - ALWAYS LOAD
# =====================================================

echo "🚀 Loading essential modules..."

# Initialize LOADED_MODULES as empty
LOADED_MODULES=""

# Load utils module (includes backup system)
if [[ -f "$ZSH_CONFIG_DIR/modules/utils.module.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/modules/utils.module.zsh"
    echo "  ✅ Utils module loaded"
    LOADED_MODULES="utils"
else
    echo "  ❌ Utils module not found"
fi

# Load python module
if [[ -f "$ZSH_CONFIG_DIR/modules/python.module.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/modules/python.module.zsh"
    echo "  ✅ Python module loaded"
    LOADED_MODULES="${LOADED_MODULES:+$LOADED_MODULES }python"
else
    echo "  ❌ Python module not found"
fi

# Export the actual loaded modules
export LOADED_MODULES

# Load backup system explicitly
if [[ -f "$ZSH_CONFIG_DIR/scripts/utils/backup-system.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/scripts/utils/backup-system.zsh"
    echo "  ✅ Backup system loaded"
else
    echo "  ❌ Backup system not found"
fi

echo "📦 Essential modules loaded: $LOADED_MODULES"

# =====================================================
# MODULE LOADING SYSTEM
# =====================================================

load_module() {
    local module="$1"
    local module_path="$ZSH_CONFIG_DIR/modules/$module.module.zsh"

    if [[ -z "$module" ]]; then
        echo "❌ Error: No module name provided"
        echo "📋 Usage: load_module <module_name>"
        return 1
    fi

    if [[ -f "$module_path" ]]; then
        echo "📦 Loading $module module..."
        source "$module_path"
        echo "✅ Module $module loaded successfully!"
    else
        echo "❌ Module not found: $module"
        return 1
    fi
}

# Quick module aliases
alias load-python='load_module python'
alias load-utils='load_module utils'

# =====================================================
# MODE DETECTION - DEFAULT TO STAGGERED
# =====================================================

detect_zsh_mode() {
    # Manual mode override (highest priority)
    if [[ -n "$ZSH_MODE" ]]; then
        echo "$ZSH_MODE"
        return 0
    fi

    # Check parent process for IDE context
    local parent_process=""
    if command -v ps >/dev/null 2>&1; then
        parent_process=$(ps -p $PPID -o comm= 2>/dev/null || echo "")
    fi

    # JetBrains IDEs - use staggered for better performance
    if [[ -n "$JETBRAINS_IDE" || -n "$PYCHARM_HOSTED" || -n "$DATASPELL_IDE" || "$TERM_PROGRAM" == "JetBrains"* ]]; then
        echo "staggered"
        return 0
    fi

    # Check parent process for VSCode/Cursor
    if [[ "$parent_process" == *"code"* || "$parent_process" == *"Code"* ||
          "$parent_process" == *"cursor"* || "$parent_process" == *"Cursor"* ]]; then
        echo "staggered"
        return 0
    fi

    # Default to staggered mode for full functionality
    echo "staggered"
}

# =====================================================
# SYSTEM MANAGEMENT
# =====================================================

startup_status() {
    local path_length=${#PATH}
    local loaded_count=0
    local available_modules=0

    # Count loaded modules
    if [[ -n "$LOADED_MODULES" ]]; then
        loaded_count=$(echo $LOADED_MODULES | wc -w | tr -d ' ')
    fi

    # Get available modules
    if [[ -d "$ZSH_CONFIG_DIR/modules" ]]; then
        available_modules=$(ls "$ZSH_CONFIG_DIR/modules"/*.module.zsh 2>/dev/null | wc -l | tr -d ' ')
    else
        available_modules=0
    fi

    # Determine system status
    local system_status="Production Ready"
    if [[ $loaded_count -eq 0 ]]; then
        system_status="⚠️  Module Loading Failed"
    elif [[ $available_modules -eq 0 ]]; then
        system_status="⚠️  Modules Directory Missing"
    fi

    echo "🚀 3-Tier ZSH System - $system_status"
    echo "======================================"
    echo "📊 Status: PATH=$path_length chars, $loaded_count/$available_modules modules loaded"
    echo "🔧 Mode: $(detect_zsh_mode)"
    echo ""
    echo "💡 Available commands:"
    echo "  startup_status  # Show this status"
    echo "  load_module     # Load additional modules"
    echo "  backup          # Create backup with sync"
}

zshreload() {
    echo "🔄 Reloading ZSH configuration..."
    source ~/.zshrc
    echo "✅ Configuration reloaded successfully"
}

zshreboot() {
    echo "🔄 Restarting ZSH shell..."
    exec zsh -i
}

# Ensure module tracking variables persist (fix for variable clearing issue)
# Note: LOADED_MODULES is set based on actual module loading above
export UTILS_MODULE_LOADED=true
export PYTHON_MODULE_LOADED=true

# Show startup status
startup_status

export MINIMAL_ZSHRC_LOADED=true

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/dheerajchand/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Final variable setting after all initialization
# Note: LOADED_MODULES is set based on actual module loading success
export UTILS_MODULE_LOADED=true
export PYTHON_MODULE_LOADED=true