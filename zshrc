#!/usr/bin/env zsh
# =====================================================
# SIEGE ANALYTICS ZSH SYSTEM - Main Configuration
# =====================================================
#
# CRITICAL: This is the ONLY ZSH system to use
# - NEVER reference ~/.dotfiles/ or atomantic files
# - ~/.zshrc is a symlink to this file
# - Uses ~/.config/zsh/oh-my-zsh (NOT ~/.dotfiles/oh-my-zsh)
#
# Lightweight zshrc focused on core functionality only.
# Heavy features moved to on-demand modules and background services.
#
# Performance target: <0.5s startup, <500 char PATH
# =====================================================

# =====================================================
# P10K INSTANT PROMPT - HANDLED BY MAIN ~/.zshrc
# =====================================================
# P10K instant prompt initialization is handled by the main ~/.zshrc file
# to prevent dual initialization that causes corruption

# =====================================================
# ESSENTIAL ENVIRONMENT
# =====================================================
export ZSH_CONFIG_DIR="$HOME/.config/zsh"

# Load centralized variables first
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

export EDITOR="${EDITOR:-zed}"
export VISUAL="$EDITOR"

# =====================================================
# CORE PATH SETUP
# =====================================================
# Clean, minimal PATH with only essential directories
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Add user binaries if they exist
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

# Removed: Ad hoc PATH addition for zsh-system command

# =====================================================
# OH-MY-ZSH MINIMAL SETUP
# =====================================================
export ZSH="$HOME/.config/zsh/oh-my-zsh"
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

# Purpose: Create directory and change into it in one command
# Arguments: $1 - directory path to create and enter
# Returns: 0 on success, non-zero on failure
# Usage: mkcd /path/to/new/directory
mkcd() { mkdir -p "$1" && cd "$1"; }

# Purpose: Check if a command exists in PATH
# Arguments: $1 - command name to check
# Returns: 0 if command exists, 1 if not found
# Usage: if command_exists git; then echo "Git available"; fi
command_exists() { command -v "$1" >/dev/null 2>&1; }

# ZSH configuration management

# Purpose: Reload ZSH configuration without restarting shell
# Arguments: None
# Returns: Always 0
# Usage: zshreload
zshreload() {
    echo "🔄 Reloading ZSH configuration..."
    source ~/.zshrc
    echo "✅ Configuration reloaded successfully"
}

# Purpose: Restart the ZSH shell completely
# Arguments: None
# Returns: Does not return (exec replaces process)
# Usage: zshreboot
zshreboot() {
    echo "🔄 Restarting ZSH shell..."
    exec zsh
}

# ZSH mode switching functions

# Purpose: Detect appropriate ZSH mode based on environment context
# Arguments: None
# Returns: Prints mode name (minimal, light, staggered, heavy)
# Usage: mode=$(detect_zsh_mode)
detect_zsh_mode() {
    # Load centralized variables for configuration
    [[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

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

    # VSCode and VSCode-based IDEs
    if [[ -n "$VSCODE_PID" || "$TERM_PROGRAM" == "vscode" || -n "$VSCODE_INJECTION" ]]; then
        echo "staggered"
        return 0
    fi

    # Cursor IDE (VSCode-based)
    if [[ "$TERM_PROGRAM" == "Cursor" || -n "$CURSOR_IDE" ]]; then
        echo "staggered"
        return 0
    fi

    # Check parent process for common IDEs
    if [[ "$parent_process" == *"pycharm"* || "$parent_process" == *"dataspell"* ||
          "$parent_process" == *"intellij"* || "$parent_process" == *"webstorm"* ||
          "$parent_process" == *"clion"* || "$parent_process" == *"goland"* ]]; then
        echo "staggered"
        return 0
    fi

    # Check parent process for VSCode/Cursor
    if [[ "$parent_process" == *"code"* || "$parent_process" == *"Code"* ||
          "$parent_process" == *"cursor"* || "$parent_process" == *"Cursor"* ]]; then
        echo "staggered"
        return 0
    fi

    # Default to staggered mode for better performance and user experience
    echo "staggered"
}

# Purpose: Auto-switch to appropriate mode based on environment
# Arguments: None
# Returns: 0 on success
# Usage: zsh-auto-switch
zsh-auto-switch() {
    local detected_mode=$(detect_zsh_mode)

    echo "🔍 Auto-detecting environment..."
    echo "📋 Detected mode: $detected_mode"

    case "$detected_mode" in
        "minimal")
            zsh-switch-minimal
            ;;
        "light")
            zsh-switch-light
            ;;
        "staggered")
            zsh-switch-staggered
            ;;
        "heavy")
            zsh-switch-heavy
            ;;
        *)
            echo "⚠️  Unknown mode: $detected_mode, defaulting to staggered"
            zsh-switch-staggered
            ;;
    esac
}

# Purpose: Switch to light mode with essential modules only
# Arguments: None
# Returns: 0 on success
# Usage: zsh-switch-light
# Note: Uses dynamic discovery to load only ZSH_LIGHT_MODULES
zsh-switch-light() {
    echo "💡 Switching to Light Mode..."

    # Load centralized variables if not already loaded
    [[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

    # Use new modules directory
    local modules_dir="$ZSH_CONFIG_DIR/modules-new"

    # Discover all available modules dynamically
    local all_modules=($(find "$modules_dir" -name "$MODULE_FILE_PATTERN" -exec basename {} "$MODULE_NAME_SUFFIX" \; 2>/dev/null))
    local light_modules=(${=ZSH_LIGHT_MODULES})

    echo "📦 Loading essential modules: ${light_modules[*]}"
    echo "🔍 Discovered ${#all_modules[@]} total modules: ${all_modules[*]}"

    # Load only light mode modules
    local loaded_count=0
    for module in "${light_modules[@]}"; do
        if [[ -f "$modules_dir/${module}.module.zsh" ]]; then
            echo "  Loading $module..."
            source "$modules_dir/${module}.module.zsh" && ((loaded_count++))
        else
            echo "  ❌ Module not found: $module"
        fi
    done

    export ZSH_CURRENT_MODE="light"
    export ZSH_LIGHT_MODE="true"

    echo "✅ Light mode activated ($loaded_count/${#light_modules[@]} modules loaded)"
    echo "💡 Use 'modules' to see status"
}

# Purpose: Switch to heavy mode with all modules loaded
# Arguments: None
# Returns: 0 on success
# Usage: zsh-switch-heavy
# Note: Dynamically discovers and loads ALL available modules
zsh-switch-heavy() {
    echo "🔥 Switching to Heavy Mode..."

    # Load centralized variables if not already loaded
    [[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

    # Use new modules directory
    local modules_dir="$ZSH_CONFIG_DIR/modules-new"

    # Discover ALL available modules dynamically
    local all_modules=($(find "$modules_dir" -name "$MODULE_FILE_PATTERN" -exec basename {} "$MODULE_NAME_SUFFIX" \; 2>/dev/null))

    echo "📦 Loading all available modules: ${all_modules[*]}"

    # Load ALL discovered modules
    local loaded_count=0
    for module in "${all_modules[@]}"; do
        echo "  Loading $module..."
        source "$modules_dir/${module}.module.zsh" && ((loaded_count++))
    done

    export ZSH_CURRENT_MODE="heavy"
    export ZSH_LIGHT_MODE="false"

    echo "✅ Heavy mode activated ($loaded_count/${#all_modules[@]} modules loaded)"
    echo "💡 Use 'modules' to see status"
}

# Purpose: Switch to staggered mode with progressive loading (IDE-optimized)
# Arguments: None
# Returns: 0 on success
# Usage: zsh-switch-staggered
# Note: Loads core modules immediately, others in background. Perfect for IDEs.
zsh-switch-staggered() {
    echo "⚡ Switching to Staggered Mode..."

    # Load centralized variables if not already loaded
    [[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

    # Use new modules directory
    local modules_dir="$ZSH_CONFIG_DIR/modules-new"

    # Discover all available modules dynamically
    local all_modules=($(find "$modules_dir" -name "$MODULE_FILE_PATTERN" -exec basename {} "$MODULE_NAME_SUFFIX" \; 2>/dev/null))
    local light_modules=(${=ZSH_LIGHT_MODULES})

    # Calculate heavy modules (ALL - LIGHT) using set difference
    local heavy_modules=()
    for module in "${all_modules[@]}"; do
        if [[ ! " ${light_modules[*]} " =~ " ${module} " ]]; then
            heavy_modules+=("$module")
        fi
    done

    echo "📦 Loading core modules immediately: ${light_modules[*]}"
    echo "⏱️  Real-time loading progress:"

    # Load core modules immediately for fast startup with real-time feedback
    local loaded_count=0
    local total_core=${#light_modules[@]}
    for module in "${light_modules[@]}"; do
        if [[ -f "$modules_dir/${module}.module.zsh" ]]; then
            printf "  [%d/%d] Loading %s... " $((loaded_count + 1)) $total_core "$module"
            if source "$modules_dir/${module}.module.zsh" 2>/dev/null; then
                echo "✅"
                ((loaded_count++))
            else
                echo "❌"
            fi
        else
            printf "  [%d/%d] Loading %s... " $((loaded_count + 1)) $total_core "$module"
            echo "⚠️  (not found)"
        fi
    done

    echo ""
    echo "🔄 Background loading remaining modules: ${heavy_modules[*]}"
    echo "💡 Background modules will show progress as they load..."

    # Load remaining modules in background with real-time progress updates
    # Using &! to auto-disown and prevent hanging background jobs
    {
        local bg_loaded=0
        local total_bg=${#heavy_modules[@]}
        for module in "${heavy_modules[@]}"; do
            sleep 0.5  # Reduced delay for better user experience
            if [[ -f "$modules_dir/${module}.module.zsh" ]]; then
                printf "  [BG %d/%d] Loading %s... " $((bg_loaded + 1)) $total_bg "$module" >&2
                if source "$modules_dir/${module}.module.zsh" 2>/dev/null; then
                    echo "✅" >&2
                    ((bg_loaded++))
                else
                    echo "❌" >&2
                fi
            else
                printf "  [BG %d/%d] Loading %s... " $((bg_loaded + 1)) $total_bg "$module" >&2
                echo "⚠️  (not found)" >&2
            fi
        done
        echo "" >&2
        echo "🎉 Staggered loading complete! ($((loaded_count + bg_loaded))/${#all_modules[@]} total modules loaded)" >&2
        echo "💫 All modules ready for use" >&2
    } &!

    export ZSH_CURRENT_MODE="staggered"
    export ZSH_LIGHT_MODE="false"

    echo "✅ Staggered mode activated ($loaded_count/${#light_modules[@]} core modules ready)"
    echo "💡 Additional ${#heavy_modules[@]} modules loading in background for IDE performance"
}

zsh-switch-minimal() {
    echo "🪶 Switching to Minimal Mode..."
    echo "🔄 Restarting with minimal configuration..."

    # Clear loaded modules and restart
    unset LOADED_MODULES
    exec zsh
}

# =====================================================
# ON-DEMAND MODULE SYSTEM
# =====================================================
load_module() {
    local module="$1"
    local module_path="$ZSH_CONFIG_DIR/modules/$module.zsh"

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
alias load-javascript='load_module javascript'

# Removed: Ad hoc wrapper function - use direct path instead

# =====================================================
# POWERLEVEL10K CONFIG - HANDLED BY MAIN ~/.zshrc
# =====================================================
# P10K configuration sourcing is handled by the main ~/.zshrc file
# to prevent duplicate sourcing that can cause prompt corruption

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
    echo "  load-javascript # Node.js, npm, nvm integration"
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
    echo ""
    echo "⚡ Mode switching:"
    echo "  zsh-auto-switch             # Auto-detect and switch to optimal mode"
    echo "  zsh-switch-minimal          # Minimal mode (no modules)"
    echo "  zsh-switch-light            # Light mode (essential modules)"
    echo "  zsh-switch-heavy            # Heavy mode (all modules)"
    echo "  zsh-switch-staggered        # Staggered loading mode (DEFAULT - best performance)"
    echo ""
    echo "🔍 Mode detection:"
    echo "  detect_zsh_mode             # Show detected mode for current environment"
    echo "  ZSH_MODE=heavy zsh-auto-switch  # Override mode detection"
    echo ""
    echo "🔧 Configuration management:"
    echo "  zshreload                   # Reload config without restart"
    echo "  zshreboot                   # Restart zsh shell"
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

# =====================================================
# STARTUP STATUS & GUIDANCE
# =====================================================

startup_status() {
    local path_length=${#PATH}
    local loaded_count=0
    local available_modules=""
    local loaded_list=""

    # Count loaded modules
    if [[ -n "$LOADED_MODULES" ]]; then
        loaded_count=$(echo $LOADED_MODULES | wc -w | tr -d ' ')
        loaded_list="$LOADED_MODULES"
    fi

    # Get available modules
    if [[ -d "$ZSH_CONFIG_DIR/modules" ]]; then
        available_modules=$(ls "$ZSH_CONFIG_DIR/modules"/*.zsh 2>/dev/null | wc -l | tr -d ' ')
    fi

    echo "🚀 3-Tier ZSH System - Staggered Mode (Default)"
    echo "==============================================="
    echo "📊 Status: PATH=$path_length chars, $loaded_count/$available_modules modules loaded"

    if [[ $loaded_count -gt 0 ]]; then
        echo "✅ Loaded: $loaded_list"
    else
        echo "💤 No modules loaded yet (run 'zsh-auto-switch' for staggered loading)"
    fi

    echo ""
    echo "📦 Available modules (load on-demand):"
    echo "  load-python     # Python environments (pyenv, UV, virtualenv)"
    echo "  load-javascript # Node.js, npm, nvm integration"
    echo "  load-docker     # Docker management & development"
    echo "  load-database   # PostgreSQL integration"
    echo "  load-spark      # Apache Spark & Hadoop"
    echo "  load-jetbrains  # IDE integration"
    echo ""
    echo "🔧 System management:"
    echo "  ~/.config/zsh/zsh-system status        # Detailed system overview"
    echo "  ~/.config/zsh/zsh-system modules       # Module information"
    echo "  ~/.config/zsh/zsh-system switch-full   # Switch to full mode (all modules)"
    echo ""
    echo "💡 Quick help: 'help' | Module status: 'modules'"
}

# startup_status  # Commented out - call manually with 'startup_status' if needed

# =====================================================
# REPOSITORY MANAGEMENT FUNCTIONS
# =====================================================

# Load backup system for repository management
if [[ -f "$ZSH_CONFIG_DIR/scripts/utils/backup-system.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/scripts/utils/backup-system.zsh"

    # Ensure repository aliases are available
    alias push='push_to_main_repo'
    alias pushmain='push_main'
    alias sync='sync_zsh'
    alias backup='enhanced_backup'
    alias repostatus='zsh_repo_status'
fi

# =====================================================
# AUTO-MODE DETECTION & STARTUP
# =====================================================

# Auto-detect and switch to optimal mode based on environment if not already done
# This ensures proper module loading based on context (IDE, terminal, etc.)
if [[ -z "$ZSH_CURRENT_MODE" || "$ZSH_CURRENT_MODE" == "minimal" ]]; then
    zsh-auto-switch
fi

# =====================================================
# COMPLETION
# =====================================================
export MINIMAL_ZSHRC_LOADED=true