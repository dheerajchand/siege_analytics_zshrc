#!/usr/bin/env zsh
# EMERGENCY MINIMAL ZSHRC - GUARANTEED WORKING

export ZSH_CONFIG_DIR="$HOME/.config/zsh"

# Load centralized variables first
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"
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

# ZSH management functions
zshreload() {
    echo "🔄 Reloading ZSH configuration..."
    source ~/.zshrc
    echo "✅ Configuration reloaded successfully"
}

zshreboot() {
    echo "🔄 Restarting ZSH shell..."
    exec zsh
}

# System status function
startup_status() {
    local path_length=${#PATH}
    local loaded_count=0
    local available_modules=""

    # Count loaded modules
    if [[ -n "$LOADED_MODULES" ]]; then
        loaded_count=$(echo $LOADED_MODULES | wc -w | tr -d ' ')
    fi

    # Get available modules
    if [[ -d "$ZSH_MODULES_DIR" ]]; then
        available_modules=$(ls "$ZSH_MODULES_DIR"/*.module.zsh 2>/dev/null | wc -l | tr -d ' ')
    fi

    echo "🚀 3-Tier ZSH System - Minimal Mode"
    echo "=================================="
    echo "📊 Status: PATH=$path_length chars, $loaded_count/$available_modules modules loaded"
    echo ""
    echo "💡 Manual commands available:"
    echo "  startup_status  # Show this status"
    echo "  zshreload       # Reload configuration"
    echo "  zshreboot       # Restart shell"
}

# Simple module loading system
load_module() {
    local module="$1"
    local module_path="$ZSH_MODULES_DIR/$module.module.zsh"

    if [[ -z "$module" ]]; then
        echo "❌ Error: No module name provided"
        echo "📋 Usage: load_module <module_name>"
        echo "📋 Available modules:"
        ls "$ZSH_MODULES_DIR"/*.module.zsh 2>/dev/null | xargs -n1 basename | sed 's/.module.zsh$//'
        return 1
    fi

    if [[ -f "$module_path" ]]; then
        echo "📦 Loading $module module..."

        # Source the module and capture any output
        if source "$module_path"; then
            # Track loaded modules
            if [[ -z "$LOADED_MODULES" ]]; then
                export LOADED_MODULES="$module"
            else
                export LOADED_MODULES="$LOADED_MODULES $module"
            fi
            echo "✅ Module $module loaded successfully!"
            echo "📊 Total modules loaded: $(echo $LOADED_MODULES | wc -w | tr -d ' ')"
        else
            echo "❌ Error: Failed to load $module module"
            return 1
        fi
    else
        echo "❌ Module not found: $module"
        echo "📋 Available modules:"
        ls "$ZSH_MODULES_DIR"/*.module.zsh 2>/dev/null | xargs -n1 basename | sed 's/.module.zsh$//'
        return 1
    fi
}

# Quick module aliases
alias load-python='load_module python'
alias load-utils='load_module utils'

# Manual mode switching functions
show_loaded_modules() {
    echo "📊 Module Status"
    echo "==============="
    echo "🚀 Core: Minimal (always loaded)"

    if [[ -n "$LOADED_MODULES" ]]; then
        echo "📦 Loaded: $LOADED_MODULES"
    else
        echo "📦 Loaded: None (use load_module to load)"
    fi

    echo ""
    echo "📋 Available modules:"
    ls "$ZSH_MODULES_DIR"/*.module.zsh 2>/dev/null | xargs -n1 basename | sed 's/.module.zsh$//' | sed 's/^/  /'
    echo ""
    echo "💡 Use 'load_module <name>' to load modules"
}

alias modules='show_loaded_modules'

# Essential Claude Code support
claude_parent_process=$(ps -p $PPID -o comm= 2>/dev/null || echo "")
if [[ "$claude_parent_process" == "claude" ]]; then
    if source "$ZSH_CONFIG_DIR/modules/utils.module.zsh" 2>/dev/null; then
        export LOADED_MODULES="utils"
        if source "$ZSH_CONFIG_DIR/modules/python.module.zsh" 2>/dev/null; then
            export LOADED_MODULES="utils python"
        fi
    fi
fi

export MINIMAL_ZSHRC_LOADED=true