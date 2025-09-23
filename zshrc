#!/usr/bin/env zsh
# =====================================================
# 3-TIER ZSH CONFIGURATION - SYSTEMATIC PRODUCTION
# =====================================================
#
# Design: Evidence-based architecture from hostile testing
# Principle: Dependency-first loading with real functionality verification
# Version: Systematic repair based on actual usage analysis
#
# TIER 1: Core (always loaded)
# TIER 2: Modules (on-demand with dependency resolution)
# TIER 3: Services (background optimization)
# =====================================================

export ZSH_CONFIG_DIR="$HOME/.config/zsh"

# =====================================================
# TIER 1: CORE FOUNDATION (CRITICAL - MUST NOT FAIL)
# =====================================================

# Loading core foundation silently

# 1.1 Load centralized variables FIRST
if [[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/config/variables.zsh"
    # Variables loaded silently
else
    echo "  ❌ CRITICAL: Variables not found"
    exit 1
fi

# 1.2 Load core functions BEFORE modules (DEPENDENCY REQUIREMENT)
if [[ -f "$ZSH_CONFIG_DIR/config/core.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/config/core.zsh"
    # Core functions loaded silently

    # Verify critical dependencies for modules
    if ! typeset -f path_add >/dev/null; then
        echo "  ❌ CRITICAL: path_add function missing (required by Spark module)"
        exit 1
    fi
else
    echo "  ❌ CRITICAL: Core functions not found"
    exit 1
fi

# 1.3 Oh My Zsh setup
export ZSH="$HOME/.config/zsh/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source $ZSH/oh-my-zsh.sh >/dev/null 2>&1
    # Oh My Zsh loaded silently
fi

# 1.4 Load P10K config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# 1.5 Basic aliases (always available)
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# 1.6 Basic functions (always available)
mkcd() { mkdir -p "$1" && cd "$1"; }
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Core foundation ready

# =====================================================
# TIER 2: MODULE LOADING SYSTEM WITH DEPENDENCY RESOLUTION
# =====================================================

# Initializing module system silently

# Initialize module tracking
export LOADED_MODULES=""

# Enhanced module loading with dependency checking and real functionality verification
load_module() {
    local module="$1"
    local module_path="$ZSH_CONFIG_DIR/modules/$module.module.zsh"

    if [[ -z "$module" ]]; then
        # Error: No module name provided (run startup_status for usage info)
        return 1
    fi

    # Pre-check dependencies
    case "$module" in
        spark)
            if ! typeset -f path_add >/dev/null; then
                echo "❌ Error: $module requires core.zsh (path_add function missing)"
                echo "🔧 Fix: Ensure core.zsh is loaded before loading $module"
                return 1
            fi
            ;;
        database)
            if ! command -v _report_missing_dependency >/dev/null; then
                echo "❌ Error: $module requires utils module for error reporting"
                echo "🔧 Fix: Load utils module first"
                return 1
            fi
            ;;
    esac

    if [[ -f "$module_path" ]]; then
        # Loading $module module...

        # Load with error capture
        if source "$module_path" 2>/dev/null; then
            # Verify module provides expected functionality
            local verification_result
            case "$module" in
                utils)
                    if command -v backup >/dev/null; then
                        verification_result="✅ Backup system available"
                    else
                        verification_result="⚠️  Backup system not available"
                    fi
                    ;;
                python)
                    if python3 --version >/dev/null 2>&1; then
                        verification_result="✅ Python $(python3 --version | cut -d' ' -f2) functional"
                    else
                        verification_result="⚠️  Python not functional"
                    fi
                    ;;
                docker)
                    if docker version >/dev/null 2>&1; then
                        verification_result="✅ Docker $(docker version --format '{{.Client.Version}}') functional"
                    else
                        verification_result="⚠️  Docker daemon not available"
                    fi
                    ;;
                spark)
                    if command -v spark-submit >/dev/null 2>&1; then
                        verification_result="✅ Spark functional"
                    else
                        verification_result="⚠️  Spark not available"
                    fi
                    ;;
                *)
                    verification_result="✅ Module loaded"
                    ;;
            esac

            # Update module tracking
            if [[ -z "$LOADED_MODULES" ]]; then
                export LOADED_MODULES="$module"
            else
                export LOADED_MODULES="$LOADED_MODULES $module"
            fi

            echo "✅ $module: $verification_result"
            return 0
        else
            # Error: Failed to load $module - source error or missing dependencies
            return 1
        fi
    else
        # Module not found: $module
        # Available modules listed in error (suppressed for clean startup)
        return 1
    fi
}

# Quick module aliases
alias load-python='load_module python'
alias load-utils='load_module utils'
alias load-docker='load_module docker'
alias load-spark='load_module spark'
alias load-database='load_module database'

# Module system ready

# =====================================================
# TIER 2: ESSENTIAL MODULE AUTO-LOADING (CONTEXT-AWARE)
# =====================================================

# Loading essential modules silently

# Process tree walker to find Claude ancestor
find_claude_in_process_tree() {
    local current_pid=$1
    local depth=0
    local max_depth=10  # Prevent infinite loops

    while [[ $current_pid -gt 1 && $depth -lt $max_depth ]]; do
        local process_name=$(ps -p $current_pid -o comm= 2>/dev/null || echo "")
        if [[ "$process_name" == "claude" ]]; then
            return 0  # Found claude in process tree
        fi

        # Get parent PID
        current_pid=$(ps -p $current_pid -o ppid= 2>/dev/null | tr -d ' ' || echo "1")
        ((depth++))
    done

    return 1  # Claude not found in process tree
}

# Enhanced Claude Code environment detection
detect_claude_environment() {
    # Method 1: Environment variable (most reliable)
    if [[ -n "$CLAUDE_CODE_SESSION" ]]; then
        return 0
    fi

    # Method 2: Process tree walking (works in all contexts)
    if find_claude_in_process_tree $$; then
        return 0
    fi

    # Method 3: Process search fallback
    if ps aux | grep -q '[c]laude'; then
        return 0
    fi

    return 1
}

# Detect Claude Code environment and load in STAGGERED mode
# Note: mode detection happens later, defaulting to staggered for Claude Code
if detect_claude_environment; then
    echo "🤖 Claude Code environment detected - loading in staggered mode"

    # Load all available modules in staggered fashion
    if [[ -d "$ZSH_CONFIG_DIR/modules" ]]; then
        # Find .module.zsh files (primary modules)
        primary_modules=($(ls "$ZSH_CONFIG_DIR/modules"/*.module.zsh 2>/dev/null | xargs -n1 basename | sed 's/.module.zsh$//'))

        # Find hierarchical modules in subdirectories
        hierarchical_modules=($(find "$ZSH_CONFIG_DIR/modules" -name "*.zsh" ! -name "*.module.zsh" 2>/dev/null))

        total_modules=$((${#primary_modules[@]} + ${#hierarchical_modules[@]}))
        echo "📦 Loading $total_modules modules systematically (${#primary_modules[@]} primary + ${#hierarchical_modules[@]} hierarchical)..."

        # Load utils first (dependency for others)
        if [[ " ${primary_modules[*]} " =~ " utils " ]]; then
            if load_module utils; then
                true  # Success message handled by load_module
            else
                echo "❌ Utils module failed - continuing without backup system"
            fi
        fi

        # Load remaining primary modules
        for module in "${primary_modules[@]}"; do
            [[ "$module" == "utils" ]] && continue  # Skip utils - already loaded
            load_module "$module"  # Show functional status for each module
        done

        # Load hierarchical modules with PATH protection
        for module_path in "${hierarchical_modules[@]}"; do
            if [[ -f "$module_path" ]]; then
                module_name=$(/usr/bin/basename "$module_path" 2>/dev/null || echo "unknown")
                [[ -n "$module_name" && "$module_name" != "unknown" ]] && echo "📁 Loading hierarchical module: $module_name"

                # Save PATH before loading
                saved_path="$PATH"

                # Load module with error handling
                if source "$module_path" 2>/dev/null; then
                    # Check if essential commands still work after loading
                    if ! command -v date >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
                        echo "❌ $module_name corrupted PATH, restoring..."
                        export PATH="$saved_path"
                    fi
                else
                    [[ -n "$module_name" && "$module_name" != "unknown" ]] && echo "❌ Failed to load $module_name"
                fi
            fi
        done

        echo "✅ Staggered loading complete - all modules processed"
    fi
else
    echo "🖥️  Regular terminal - use load_module commands for features"
fi

# =====================================================
# MODE DETECTION SYSTEM
# =====================================================

detect_zsh_mode() {
    # Manual mode override (highest priority)
    if [[ -n "${ZSH_MODE:-}" ]]; then
        echo "$ZSH_MODE"
        return 0
    fi

    # Check parent process for IDE context
    local parent_process=""
    if command -v ps >/dev/null 2>&1; then
        parent_process=$(ps -p $PPID -o comm= 2>/dev/null || echo "")
    fi

    # JetBrains IDEs
    if [[ -n "$JETBRAINS_IDE" || -n "$PYCHARM_HOSTED" || -n "$DATASPELL_IDE" || "$TERM_PROGRAM" == "JetBrains"* ]]; then
        echo "staggered"
        return 0
    fi

    # VSCode and Cursor
    if [[ -n "$VSCODE_PID" || "$TERM_PROGRAM" == "vscode" || -n "$VSCODE_INJECTION" || "$TERM_PROGRAM" == "Cursor" ]]; then
        echo "staggered"
        return 0
    fi

    # Check parent process patterns
    if [[ "$parent_process" == *"code"* || "$parent_process" == *"cursor"* || "$parent_process" == *"pycharm"* ]]; then
        echo "staggered"
        return 0
    fi

    # Default to staggered mode
    echo "staggered"
}

# =====================================================
# SYSTEM MANAGEMENT FUNCTIONS
# =====================================================

startup_status() {
    local path_length=${#PATH}
    local loaded_count=0
    local available_modules=0

    # Count actually loaded modules
    if [[ -n "$LOADED_MODULES" ]]; then
        loaded_count=$(echo $LOADED_MODULES | wc -w | tr -d ' ')
    fi

    # Count available modules
    if [[ -d "$ZSH_CONFIG_DIR/modules" ]]; then
        available_modules=$(ls "$ZSH_CONFIG_DIR/modules"/*.module.zsh 2>/dev/null | wc -l | tr -d ' ')
    fi

    # System health assessment
    local system_status="Production Ready"
    if [[ $loaded_count -eq 0 ]]; then
        system_status="⚠️  No modules loaded"
    elif [[ ! -f "$ZSH_CONFIG_DIR/config/core.zsh" ]]; then
        system_status="⚠️  Core functions missing"
    fi

    echo "🚀 3-Tier ZSH System - $system_status"
    echo "======================================"
    echo "📊 Status: PATH=$path_length chars, $loaded_count/$available_modules modules loaded"
    echo "🔧 Mode: $(detect_zsh_mode)"
    echo "📦 Loaded modules: ${LOADED_MODULES:-none}"
    echo ""
    echo "💡 Available commands:"
    echo "  startup_status     # Show this status"
    echo "  load_module <name> # Load specific module"
    echo "  modules            # Show available modules"
}

show_loaded_modules() {
    echo "📊 Module Status"
    echo "==============="
    echo "🚀 Core: Always loaded (variables, core functions, Oh-My-Zsh)"

    if [[ -n "$LOADED_MODULES" ]]; then
        echo "📦 Loaded modules: $LOADED_MODULES"
    else
        echo "📦 Loaded modules: None"
    fi

    echo ""
    echo "📋 Available modules:"
    ls "$ZSH_CONFIG_DIR/modules"/*.module.zsh 2>/dev/null | xargs -n1 basename | sed 's/.module.zsh$//' | sed 's/^/  /'
    echo ""
    echo "💡 Use 'load_module <name>' to load modules on-demand"
}

alias modules='show_loaded_modules'

zshreload() {
    echo "🔄 Reloading ZSH configuration..."
    source ~/.zshrc
    echo "✅ Configuration reloaded successfully"
}

zshreboot() {
    echo "🔄 Restarting ZSH shell..."
    exec /bin/zsh -i
}

# =====================================================
# TIER 3: BACKGROUND SERVICES (OPTIONAL)
# =====================================================

# Note: Background services are implemented separately in zsh-system
# This avoids startup delays and potential hanging issues

# Background services available via zsh-system

# =====================================================
# STARTUP COMPLETION
# =====================================================

# 3-Tier ZSH System - Systematic Production Ready

# Show minimal startup confirmation
if command -v wc >/dev/null 2>&1 && command -v tr >/dev/null 2>&1; then
    module_count=$(echo "$LOADED_MODULES" | /usr/bin/wc -w | /usr/bin/tr -d ' ')
else
    # Fallback count using parameter expansion
    module_count=$(echo "$LOADED_MODULES" | awk '{print NF}' 2>/dev/null || echo "?")
fi
echo "⚡ ZSH ready - $module_count modules loaded"

export SYSTEMATIC_ZSHRC_LOADED=true

# =====================================================
# EXTERNAL PATH MODIFICATIONS (KEEP AT END)
# =====================================================

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/dheerajchand/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
# Functions are available in zsh subshells by default
# (export -f is bash-specific and causes output in zsh)

# Removed broken error trap that was causing constant spam

# Shell compatibility layer for script execution
if [[ -n "$BASH_VERSION" ]]; then
    # Running in bash - ensure key functions are available
    shopt -s expand_aliases 2>/dev/null || true
fi

# Ensure functions are available in both zsh and bash contexts
command_exists() { command -v "$1" >/dev/null 2>&1; }
# Function available in zsh by default
