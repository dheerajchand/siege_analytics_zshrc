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
    exec zsh -i
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

# Advanced ZSH functions (MANUAL USE ONLY - NO AUTO-EXECUTION)
detect_zsh_mode() {
    # Load centralized variables for configuration
    [[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

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

    # Default to staggered mode for full functionality
    echo "staggered"
}

# Help system
zsh_help() {
    echo "🚀 3-Tier ZSH System Help"
    echo "========================="
    echo ""
    echo "📦 Manual module loading:"
    echo "  load_module python     # Python environments (pyenv, UV, virtualenv)"
    echo "  load_module utils      # Utility functions"
    echo "  load-python            # Alias for load_module python"
    echo "  load-utils             # Alias for load_module utils"
    echo ""
    echo "📊 Status and information:"
    echo "  startup_status         # Show system status"
    echo "  modules                # Show loaded/available modules"
    echo "  detect_zsh_mode        # Show detected environment mode"
    echo ""
    echo "🔧 Shell management:"
    echo "  zshreload              # Reload configuration"
    echo "  zshreboot              # Restart shell"
    echo "  help                   # Show this help"
    echo ""
    echo "💡 All functions are MANUAL - no automatic execution"
    echo "💡 Safe startup: no hanging, no background jobs"
}

alias help='zsh_help'

# Manual mode switching functions (NO AUTO-EXECUTION)
zsh-switch-light() {
    echo "💡 Switching to Light Mode..."

    # Load centralized variables if not already loaded
    [[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

    local light_modules=(${=ZSH_LIGHT_MODULES})

    echo "📦 Loading essential modules: ${light_modules[*]}"

    # Load modules in dependency order (utils must come first)
    local loaded_count=0
    local failed_modules=()

    # Ensure utils is loaded first if it's in the list
    if [[ " ${light_modules[*]} " =~ " utils " ]]; then
        echo "  Loading utils (dependency)..."
        if load_module utils; then
            ((loaded_count++))
        else
            failed_modules+=("utils")
        fi
    fi

    # Load remaining modules (skip utils if already loaded)
    for module in "${light_modules[@]}"; do
        [[ "$module" == "utils" ]] && continue  # Skip utils - already loaded

        echo "  Loading $module..."
        if load_module "$module"; then
            ((loaded_count++))
        else
            failed_modules+=("$module")
        fi
    done

    # Report any failures
    if [[ ${#failed_modules[@]} -gt 0 ]]; then
        echo "  ⚠️  Failed modules: ${failed_modules[*]}"
    fi

    export ZSH_CURRENT_MODE="light"
    echo "✅ Light mode activated ($loaded_count/${#light_modules[@]} modules loaded)"
}

zsh-switch-minimal() {
    echo "🪶 Minimal mode already active"
    echo "📊 Current status:"
    startup_status
}

zsh-switch-staggered() {
    echo "⚡ Switching to Staggered Mode (Safe Version - No Background Jobs)..."

    # Load centralized variables if not already loaded
    [[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

    local modules_dir="$ZSH_MODULES_DIR"
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

    # Load core modules immediately (synchronously)
    local loaded_count=0
    local total_core=${#light_modules[@]}
    local module_index=0

    # Ensure utils is loaded first if it's in the list
    if [[ " ${light_modules[*]} " =~ " utils " ]]; then
        ((module_index++))
        printf "  [%d/%d] Loading utils (dependency)... " $module_index $total_core
        if load_module utils >/dev/null 2>&1; then
            echo "✅"
            ((loaded_count++))
        else
            echo "❌"
        fi
    fi

    # Load remaining core modules (skip utils if already loaded)
    for module in "${light_modules[@]}"; do
        [[ "$module" == "utils" ]] && continue  # Skip utils - already loaded
        ((module_index++))

        printf "  [%d/%d] Loading %s... " $module_index $total_core "$module"
        if load_module "$module" >/dev/null 2>&1; then
            echo "✅"
            ((loaded_count++))
        else
            echo "❌"
        fi
    done

    echo ""
    echo "📦 Loading additional modules (SYNCHRONOUSLY): ${heavy_modules[*]}"

    # Load heavy modules synchronously (NO background jobs)
    local heavy_loaded=0
    for module in "${heavy_modules[@]}"; do
        printf "  Loading %s... " "$module"
        if load_module "$module" >/dev/null 2>&1; then
            echo "✅"
            ((heavy_loaded++))
        else
            echo "❌ (not found)"
        fi
    done

    export ZSH_CURRENT_MODE="staggered"
    echo ""
    echo "✅ Safe staggered mode activated ($((loaded_count + heavy_loaded))/${#all_modules[@]} total modules loaded)"
    echo "💡 All modules loaded synchronously - no background jobs, no hanging"
}

# Essential Claude Code support
claude_parent_process=$(ps -p $PPID -o comm= 2>/dev/null || echo "")
# Check for Claude Code context: direct parent OR in terminal/IDE that would use Claude Code
if [[ "$claude_parent_process" == "claude" ]] || [[ -n "$CLAUDE_CODE_SESSION" ]] || [[ "$claude_parent_process" == "/bin/zsh" && -n "$TERM_PROGRAM" ]]; then
    echo "🤖 Claude Code environment detected - loading essential modules..."
    # Load utils module first (includes backup system)
    source "$ZSH_CONFIG_DIR/modules/utils.module.zsh"
    # Ensure backup system is loaded
    if ! command -v enhanced_backup >/dev/null 2>&1; then
        source "$ZSH_CONFIG_DIR/scripts/utils/backup-system.zsh"
    fi
    export LOADED_MODULES="utils"
    echo "  ✅ Utils module loaded (with backup system)"

    # Load python module
    source "$ZSH_CONFIG_DIR/modules/python.module.zsh"
    export LOADED_MODULES="utils python"
    echo "  ✅ Python module loaded"

    echo "📦 Claude Code setup complete"
else
    # Regular terminal session - load essential modules for normal use
    echo "🖥️  Regular terminal detected - loading essential modules..."

    # Load utils module first (includes backup system)
    source "$ZSH_CONFIG_DIR/modules/utils.module.zsh"
    # Ensure backup system is loaded
    if ! command -v enhanced_backup >/dev/null 2>&1; then
        source "$ZSH_CONFIG_DIR/scripts/utils/backup-system.zsh"
    fi
    export LOADED_MODULES="utils"
    echo "  ✅ Utils module loaded (with backup system)"

    # Load python module
    source "$ZSH_CONFIG_DIR/modules/python.module.zsh"
    export LOADED_MODULES="utils python"
    echo "  ✅ Python module loaded"

    echo "📦 Essential modules setup complete"
fi

# Show startup status (safe - we know this works)
startup_status

export MINIMAL_ZSHRC_LOADED=true
### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/dheerajchand/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
