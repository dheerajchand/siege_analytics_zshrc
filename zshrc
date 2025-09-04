#!/usr/bin/env zsh

# =====================================================
# MODULAR ZSHRC - Enhanced Shell Configuration System
# =====================================================
#
# This is the new modular zshrc that replaces the monolithic 2400+ line file.
# It loads configuration modules dynamically based on available tools and requirements.
#
# Configuration modules are stored in ~/.config/zsh/config/
# Functions are stored in ~/.config/zsh/functions/
# =====================================================

# =====================================================
# POWERLEVEL10K INSTANT PROMPT (Must be first)
# =====================================================

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Suppress Powerlevel10k console output warnings
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# =====================================================
# OH-MY-ZSH SETUP
# =====================================================

# Path to oh-my-zsh configuration
export ZSH=$HOME/.dotfiles/oh-my-zsh

# Theme configuration
export ZSH_THEME="powerlevel10k/powerlevel10k"

# Oh-my-zsh plugins
plugins=(colorize compleat dirpersist autojump git gulp history cp)

# Source oh-my-zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source $ZSH/oh-my-zsh.sh
else
    echo "⚠️  Oh-my-zsh not found at $ZSH"
fi

# =====================================================
# CONFIGURATION DIRECTORIES
# =====================================================

export ZSH_CONFIG_DIR="$HOME/.config/zsh"
export ZSH_CONFIG_MODULES="$ZSH_CONFIG_DIR/config"
export ZSH_CONFIG_FUNCTIONS="$ZSH_CONFIG_DIR/functions"

# Ensure directories exist
mkdir -p "$ZSH_CONFIG_MODULES"
mkdir -p "$ZSH_CONFIG_FUNCTIONS"

# =====================================================
# MODULE LOADING SYSTEM
# =====================================================

# Track loaded modules (cross-shell compatible)
# Initialize associative array based on shell type
if [[ -n "$ZSH_VERSION" ]]; then
    typeset -gA LOADED_MODULES
elif [[ -n "$BASH_VERSION" ]]; then
    declare -gA LOADED_MODULES
fi

load_config_module() {
    # Load a configuration module with error handling
    #
    # Args:
    #     module_name (str): Name of module (without .zsh extension)
    #     required (bool, optional): Whether module is required (default: false)
    local module_name="$1"
    local required="${2:-false}"
    local module_path="$ZSH_CONFIG_MODULES/${module_name}.zsh"
    
    if [[ -f "$module_path" ]]; then
        if source "$module_path" 2>/dev/null; then
            LOADED_MODULES[$module_name]="success"
            [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "✅ Loaded: $module_name"
            return 0
        else
            LOADED_MODULES[$module_name]="error"
            echo "❌ Error loading module: $module_name"
            [[ "$required" == "true" ]] && return 1
        fi
    else
        LOADED_MODULES[$module_name]="missing"
        if [[ "$required" == "true" ]]; then
            echo "❌ Required module missing: $module_name"
            return 1
        else
            [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "⏭️  Module not found: $module_name"
        fi
    fi
    
    return 0
}

# =====================================================
# CORE MODULE LOADING (Required)
# =====================================================

# Load shell compatibility layer first (for cross-shell support)
load_config_module "shell-compat"

# Load core configuration (essential shell setup)
load_config_module "core" true || {
    echo "💥 FATAL: Core module failed to load. Shell may not function properly."
    return 1
}

# =====================================================
# CREDENTIAL & SECURITY MODULES
# =====================================================

# Load credential management system
load_config_module "credentials"

# Load database configuration (depends on credentials)
load_config_module "database"

# =====================================================
# DEVELOPMENT TOOLS
# =====================================================

# =====================================================
# ENVIRONMENT & PLATFORM DETECTION
# =====================================================

# Load environment detection (after core, needs path_add function)
load_config_module "environment"

# JetBrains IDE integration
load_config_module "jetbrains"

# =====================================================
# LANGUAGE & RUNTIME ENVIRONMENTS
# =====================================================

# Node.js/NVM setup
if command -v nvm >/dev/null 2>&1 || [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
    # NVM setup
    export NVM_DIR="$HOME/.nvm"
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
    [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

    # Auto-load .nvmrc files
    load-nvmrc() {
        if [[ -f .nvmrc && -r .nvmrc ]]; then
            nvm use &> /dev/null
        else
            nvm use stable &> /dev/null
        fi
    }
    autoload -U add-zsh-hook
    add-zsh-hook chpwd load-nvmrc
    load-nvmrc
fi

# Python setup (pyenv)
if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    eval "$(pyenv init --path)"
    
    # Auto-activate preferred environment
    if [[ -n "$PREFERRED_VENV" ]]; then
        pyenv activate "$PREFERRED_VENV" 2>/dev/null || true
    fi
fi

# UV setup (fast Python package manager) - Cross-shell compatible
if command -v uv >/dev/null 2>&1; then
    
    uv_auto_activate() {
        # Check if we're in a UV project directory
        if [[ -f "pyproject.toml" ]] && [[ -d ".venv" ]]; then
            # Only activate if not already in this virtual environment
            if [[ "$VIRTUAL_ENV" != "$PWD/.venv" ]]; then
                echo "🔄 Activating UV project: $(basename $PWD)"
                source .venv/bin/activate
            fi
        fi
    }
    
    # Cross-shell hook setup
    if [[ -n "$ZSH_VERSION" ]]; then
        # ZSH: Use add-zsh-hook
        autoload -U add-zsh-hook
        add-zsh-hook chpwd uv_auto_activate
    elif [[ -n "$BASH_VERSION" ]]; then
        # Bash: Override cd function
        if ! declare -f cd_original >/dev/null 2>&1; then
            cd_original() { builtin cd "$@"; }
        fi
        cd() {
            cd_original "$@"
            uv_auto_activate
        }
    fi
    
    # Check current directory on shell startup
    uv_auto_activate
fi

# =====================================================
# BIG DATA & ANALYTICS (Conditional Loading)
# =====================================================

# Load big data tools if SDKMAN is available
if [[ -s "${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh" ]]; then
    # SDKMAN initialization
    export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec 2>/dev/null || export SDKMAN_DIR="$HOME/.sdkman"
    source "${SDKMAN_DIR}/bin/sdkman-init.sh"
    
    # Load big data modules if tools are available
    load_config_module "spark"
    load_config_module "hadoop"
fi

# =====================================================
# SYSTEM-SPECIFIC MODULES
# =====================================================

# Docker integration
if command -v docker >/dev/null 2>&1; then
    load_config_module "docker"
fi

# Load backup system
load_config_module "backup-system"

# Load help system
load_config_module "help"

# =====================================================
# UTILITY FUNCTIONS FROM OLD ZSHRC
# =====================================================

# Python utility functions
if command -v pip >/dev/null 2>&1; then
    cleanvenv() {
        # Clean current virtual environment
        pip freeze | grep -v "^-e" | xargs pip uninstall -y
    }
fi

remove_python_cruft() {
    # Remove Python bytecode and cache files
    find . -name "*.pyc" -delete 2>/dev/null
    find . -name "__pycache__" -exec rm -rf {} + 2>/dev/null
}

# Git utility
update_local_repo() {
    # Track all remote branches locally
    for remote in $(git branch -r); do 
        git branch --track ${remote#origin/} $remote 2>/dev/null
    done
}

# Set Git discovery across filesystem
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# =====================================================
# LEGACY MODULE SOURCES (Temporary)
# =====================================================

# Source existing modules that haven't been refactored yet
legacy_modules=(
    "utilities.zsh"
)

for module in "${legacy_modules[@]}"; do
    module_path="$ZSH_CONFIG_DIR/$module"
    if [[ -f "$module_path" ]]; then
        source "$module_path" 2>/dev/null && {
            [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "✅ Legacy: $module"
        } || {
            echo "⚠️  Error in legacy module: $module"
        }
    fi
done

# =====================================================
# USER CUSTOMIZATIONS
# =====================================================

# Load user-specific customizations if they exist
if [[ -f "$ZSH_CONFIG_DIR/user.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/user.zsh"
fi

# Load local machine-specific customizations
if [[ -f "$ZSH_CONFIG_DIR/local.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/local.zsh"
fi

# =====================================================
# MODULE STATUS & DIAGNOSTICS
# =====================================================

modular_zsh_status() {
    # Show status of all modules
    echo "📦 Modular ZSH Configuration Status"
    echo "==================================="
    echo ""
    
    echo "Configuration Directory: $ZSH_CONFIG_DIR"
    echo "Modules Directory: $ZSH_CONFIG_MODULES"
    echo ""
    
    echo "Module Status:"
    for module module_status in ${(kv)LOADED_MODULES}; do
        case "$module_status" in
            "success")
                echo "  ✅ $module: Loaded successfully"
                ;;
            "error")
                echo "  ❌ $module: Failed to load"
                ;;
            "missing")
                echo "  ⏭️  $module: Not found (optional)"
                ;;
            *)
                echo "  ❓ $module: Unknown status ($module_status)"
                ;;
        esac
    done
    
    echo ""
    
    # Show available but not loaded modules
    echo "Available Modules:"
    if [[ -d "$ZSH_CONFIG_MODULES" ]]; then
        for module_file in "$ZSH_CONFIG_MODULES"/*.zsh; do
            if [[ -f "$module_file" ]]; then
                local module_name=$(basename "$module_file" .zsh)
                if [[ -z "${LOADED_MODULES[$module_name]}" ]]; then
                    echo "  📄 $module_name: Available but not loaded"
                fi
            fi
        done
    fi
}

reload_modular_zsh() {
    # Reload the modular zsh configuration
    echo "🔄 Reloading modular ZSH configuration..."
    
    # Clear loaded modules tracking
    LOADED_MODULES=()
    
    # Source this file again
    source ~/.zshrc
    
    echo "✅ Configuration reloaded"
    echo "💡 Run 'modular_zsh_status' to see module status"
}

# =====================================================
# ALIASES FOR MODULE MANAGEMENT
# =====================================================

alias zsh-status='modular_zsh_status'
alias zsh-reload='reload_modular_zsh'
alias zsh-modules='list_modules'
alias zsh-verbose='export MODULAR_ZSHRC_VERBOSE=true && zsh-reload'

# =====================================================
# STARTUP PERFORMANCE
# =====================================================

# Track startup time if requested
if [[ "$ZSH_STARTUP_TIMING" == "true" ]]; then
    echo "⏱️  Modular ZSH startup completed in ${SECONDS}s"
    echo "📦 Loaded ${#LOADED_MODULES} modules"
fi

# =====================================================
# INITIALIZATION COMPLETE
# =====================================================

export MODULAR_ZSHRC_LOADED=true
export MODULAR_ZSHRC_VERSION="1.0.0"

# Welcome message (only if verbose)
if [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]]; then
    echo "🚀 Enhanced Modular ZSH Configuration System v${MODULAR_ZSHRC_VERSION}"
    echo "💡 Run 'zsh-status' to see configuration details"
fi