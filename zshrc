#!/usr/bin/env zsh
# =====================================================
# MINIMAL ZSHRC - Essential Shell Configuration
# =====================================================
#
# Lightweight zshrc focused on core functionality only.
# Heavy features moved to on-demand modules and background services.
#
# Performance target: <0.5s startup, <500 char PATH
# =====================================================

# =====================================================
# INSTANT PROMPT (P10K)
# =====================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =====================================================
# ESSENTIAL ENVIRONMENT
# =====================================================
export EDITOR="${EDITOR:-zed}"
export VISUAL="$EDITOR"
export ZSH_CONFIG_DIR="$HOME/.config/zsh"

# =====================================================
# CORE PATH SETUP
# =====================================================
# Clean, minimal PATH with only essential directories
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Add user binaries if they exist
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

# =====================================================
# OH-MY-ZSH MINIMAL SETUP
# =====================================================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

# Load Oh My Zsh if available
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source $ZSH/oh-my-zsh.sh
else
    echo "⚠️  Oh My Zsh not found - continuing with basic setup"
    # Basic git aliases if Oh My Zsh unavailable
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
fi

# =====================================================
# ESSENTIAL ALIASES & FUNCTIONS
# =====================================================
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Core utilities
mkcd() { mkdir -p "$1" && cd "$1"; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

# =====================================================
# ON-DEMAND MODULE SYSTEM
# =====================================================
load_module() {
    local module="$1"
    local module_path="$ZSH_CONFIG_DIR/modules/$module.module.zsh"

    if [[ -f "$module_path" ]]; then
        echo "📦 Loading $module module..."
        source "$module_path"

        # Track loaded modules
        if [[ -z "$LOADED_MODULES" ]]; then
            export LOADED_MODULES="$module"
        else
            export LOADED_MODULES="$LOADED_MODULES $module"
        fi

        echo "✅ Module $module loaded successfully!"

        # Show what's available after loading
        echo "💡 Additional modules available:"
        ls $ZSH_CONFIG_DIR/modules/*.zsh 2>/dev/null | xargs -n1 basename | sed 's/.zsh$//' | grep -v "^$module$" | sed 's/^/  load-/' | tr '\n' ' '
        echo ""

    else
        echo "❌ Module not found: $module"
        echo ""
        echo "📦 Available modules:"
        ls $ZSH_CONFIG_DIR/modules/*.zsh 2>/dev/null | xargs -n1 basename | sed 's/.zsh$//' | sed 's/^/  load-/'
        echo ""
        echo "💡 Use 'zsh-system modules' for detailed information"
    fi
}

# Show loaded modules
show_loaded_modules() {
    echo "📊 Module Status"
    echo "==============="
    echo "🚀 Core: Minimal (always loaded)"

    if [[ -n "$LOADED_MODULES" ]]; then
        echo "📦 Loaded: $LOADED_MODULES"
    else
        echo "📦 Loaded: None (use load-<module> to load)"
    fi

    echo ""
    echo "📋 Available modules:"
    ls $ZSH_CONFIG_DIR/modules/*.zsh 2>/dev/null | xargs -n1 basename | sed 's/.zsh$//' | sed 's/^/  load-/'
    echo ""
    echo "💡 Type 'load-<module>' or 'help' for assistance"
}

# Quick module aliases
alias load-python='load_module python'
alias load-docker='load_module docker'
alias load-database='load_module database'
alias load-spark='load_module spark'
alias load-jetbrains='load_module jetbrains'

# =====================================================
# CLAUDE CODE ENVIRONMENT DETECTION & STAGGERED MODE
# =====================================================
detect_claude_environment() {
    # Method 1: Environment variable (most reliable)
    if [[ -n "$CLAUDE_CODE_SESSION" ]]; then
        return 0
    fi

    # Method 2: Process tree walking
    local current_pid=$$
    local depth=0
    local max_depth=10

    while [[ $current_pid -gt 1 && $depth -lt $max_depth ]]; do
        # Get process command line
        local proc_cmdline=$(ps -p $current_pid -o args= 2>/dev/null || echo "")
        if [[ "$proc_cmdline" == *"claude"* ]]; then
            return 0  # Found claude in process tree
        fi

        # Get parent PID
        current_pid=$(ps -p $current_pid -o ppid= 2>/dev/null | tr -d ' ' || echo "1")
        ((depth++))
    done

    return 1
}

# Auto-load essential modules in staggered mode (default for all environments)
if [[ "$ZSH_MODE" != "light" ]]; then
    echo "🚀 Loading in staggered mode..."

    # Load utils first (essential for backup system)
    if load_module utils 2>/dev/null; then
        true  # Success
    else
        echo "❌ Utils module failed - continuing without backup system"
    fi

    # Load python (essential for development)
    if load_module python 2>/dev/null; then
        true  # Success
    else
        echo "❌ Python module failed - continuing without Python tools"
    fi

    echo "✅ Staggered mode ready - 2 essential modules loaded"
    echo "💡 Load more with: load-docker, load-database, load-spark, load-jetbrains"
fi

# =====================================================
# POWERLEVEL10K CONFIG
# =====================================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# =====================================================
# HELP & USER GUIDANCE
# =====================================================

# 3-tier help system
zsh_help() {
    echo "🚀 3-Tier ZSH System Help"
    echo "========================="
    echo ""
    echo "📦 Load modules on demand:"
    echo "  load-python     # Python environments (pyenv, UV, virtualenv)"
    echo "  load-docker     # Docker management & development"
    echo "  load-database   # PostgreSQL integration"
    echo "  load-spark      # Apache Spark & Hadoop"
    echo "  load-jetbrains  # IDE integration"
    echo ""
    echo "📊 Check what's loaded:"
    echo "  modules         # Show loaded/available modules"
    echo "  zsh-system status       # Complete system overview"
    echo ""
    echo "🔧 System management:"
    echo "  zsh-system modules          # Detailed module info"
    echo "  zsh-system service list     # Background services"
    echo "  zsh-system switch-minimal   # Switch to minimal mode"
    echo "  zsh-system switch-full      # Switch to full mode"
    echo ""
    echo "🚀 Repository management:"
    echo "  push 'message'              # Push changes to main repo"
    echo "  pushmain                    # Quick push with timestamp"
    echo "  sync                        # Sync config repository"
    echo "  backup 'message'            # Create backup with sync"
    echo ""
    echo "📚 Documentation:"
    echo "  See CLAUDE.md for complete guide"
    echo "  See MIGRATION.md for switching help"
}

alias help='zsh_help'
alias modules='show_loaded_modules'

# Welcome message for new users
echo "🚀 3-Tier ZSH System loaded!"
echo "💡 Type 'help' for module loading guide or 'modules' to see what's available"
echo "📦 Quick start: load-python, load-docker, load-database, load-spark, load-jetbrains"
echo ""

# =====================================================
# COMPLETION
# =====================================================
export MINIMAL_ZSHRC_LOADED=true