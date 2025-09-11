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

# =====================================================
# REPOSITORY PATHS (Dual Repository System)
# =====================================================
export ZSH_ACTIVE_REPO="$HOME/.config/zsh"          # Active development repository
export ZSH_ARCHIVE_REPO="$HOME/.zshrc_backups"      # Backup/archive repository
export ZSHRC_BACKUPS="$ZSH_ARCHIVE_REPO"            # Legacy compatibility

# Ensure directories exist
mkdir -p "$ZSH_CONFIG_MODULES"
mkdir -p "$ZSH_CONFIG_FUNCTIONS"

# =====================================================
# CENTRALIZED SYSTEM VARIABLES
# =====================================================
# 
# This section contains ALL system-wide configuration variables.
# Variables are organized by category with clear documentation
# showing which modules/functions use each variable.
#
# IMPORTANT: All modules should reference these centralized variables
# rather than defining their own. This ensures consistency and makes
# the system easier to configure and maintain.
# =====================================================

# -----------------------------------------------------
# USER PREFERENCES (Personal Settings)
# -----------------------------------------------------
# Used by: config/core.zsh, various scripts
export EDITOR="${EDITOR:-zed}"                        # Default text editor
export VISUAL="${VISUAL:-zed}"                        # Visual editor
export WORKING_ON_LAPTOP="${WORKING_ON_LAPTOP:-True}" # Laptop optimization flag

# User project paths (used by: environment.zsh, various navigation functions)
export SIEGE="${SIEGE:-$HOME/Documents/Professional/Siege_Analytics}"
export GEOCODE="${GEOCODE:-$HOME/Documents/Professional/Siege_Analytics/Clients/TAN/Projects/tan_geocoding_test}"
export MASAI="${MASAI:-$HOME/Documents/Professional/Siege_Analytics/Clients/MI}"
export RESUME_GENERATOR="${RESUME_GENERATOR:-$HOME/Documents/Professional/resume_generator}"
export SIEGE_UTILITIES_TEST="${SIEGE_UTILITIES_TEST:-$HOME/Desktop/in_process/code/siege_utilities_verify}"
export SIEGE_UTILITIES="${SIEGE_UTILITIES:-$HOME/Documents/Professional/Siege_Analytics/Code/siege_utilities}"

# -----------------------------------------------------
# PYTHON ENVIRONMENT CONFIGURATION
# -----------------------------------------------------
# Used by: python/init.zsh, python/core.zsh, config/spark.zsh
export PYTHON_MANAGER="${PYTHON_MANAGER:-auto}"       # pyenv, uv, or auto
export PREFERRED_VENV="${PREFERRED_VENV:-geo31111}"   # Default Python virtual environment
export PYTHON_DEFAULT_VERSION="${PYTHON_DEFAULT_VERSION:-3.11}"
export UV_DEFAULT_PYTHON="${UV_DEFAULT_PYTHON:-3.11}"

# UV Configuration (used by: bash-compatibility.zsh, python modules)
export UV_PYTHON_PREFERENCE="${UV_PYTHON_PREFERENCE:-managed}"
export UV_PYTHON_DOWNLOADS="${UV_PYTHON_DOWNLOADS:-automatic}"
export UV_COMPILE_BYTECODE="${UV_COMPILE_BYTECODE:-1}"
export UV_LINK_MODE="${UV_LINK_MODE:-copy}"

# -----------------------------------------------------
# JAVA & JVM CONFIGURATION
# -----------------------------------------------------
# Used by: auto-setup.zsh, config/spark.zsh, config/hadoop.zsh
export TARGET_JAVA_VERSION="${TARGET_JAVA_VERSION:-17.0.12-tem}"
export TARGET_SCALA_VERSION="${TARGET_SCALA_VERSION:-2.12.18}"

# JVM Memory Settings (used by: config/hadoop.zsh, config/spark.zsh)
export HADOOP_HEAPSIZE="${HADOOP_HEAPSIZE:-1024}"     # Hadoop JVM heap size (MB)
export YARN_HEAPSIZE="${YARN_HEAPSIZE:-1024}"         # YARN JVM heap size (MB)

# -----------------------------------------------------
# BIG DATA TOOL CONFIGURATION
# -----------------------------------------------------
# Used by: auto-setup.zsh, config/spark.zsh, config/hadoop.zsh
export TARGET_SPARK_VERSION="${TARGET_SPARK_VERSION:-3.5.3}"
export TARGET_HADOOP_VERSION="${TARGET_HADOOP_VERSION:-3.3.6}"
export TARGET_MAVEN_VERSION="${TARGET_MAVEN_VERSION:-3.9.6}"

# Spark Configuration (used by: config/spark.zsh, python/integrations/spark.zsh)
export SPARK_DRIVER_MEMORY="${SPARK_DRIVER_MEMORY:-2g}"
export SPARK_EXECUTOR_MEMORY="${SPARK_EXECUTOR_MEMORY:-1g}"
export SPARK_MASTER_URL="${SPARK_MASTER_URL:-spark://localhost:7077}"
export SPARK_NUM_EXECUTORS="${SPARK_NUM_EXECUTORS:-4}"
export SPARK_EXECUTOR_CORES="${SPARK_EXECUTOR_CORES:-1}"
export SPARK_DRIVER_MAX_RESULT_SIZE="${SPARK_DRIVER_MAX_RESULT_SIZE:-2g}"

# Hadoop Configuration (used by: config/hadoop.zsh)
export HADOOP_DATA_DIR="${HADOOP_DATA_DIR:-$HOME/hadoop-data}"

# -----------------------------------------------------
# DATABASE CONFIGURATION
# -----------------------------------------------------
# Used by: config/database.zsh, utilities.zsh
# PostgreSQL
export PGHOST="${PGHOST:-localhost}"
export PGUSER="${PGUSER:-dheerajchand}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-gis}"

# GeoDjango Template Database (used by: config/database.zsh, utilities.zsh)
export GEODJANGO_TEMPLATE_SQL_DATABASE="${GEODJANGO_TEMPLATE_SQL_DATABASE:-geodjango_template_db}"
export GEODJANGO_TEMPLATE_SQL_USER="${GEODJANGO_TEMPLATE_SQL_USER:-dheerajchand}"
export GEODJANGO_TEMPLATE_SQL_PORT="${GEODJANGO_TEMPLATE_SQL_PORT:-5432}"

# MySQL Configuration (used by: config/database.zsh)
export MYSQL_HOST="${MYSQL_HOST:-localhost}"
export MYSQL_USER="${MYSQL_USER:-$USER}"
export MYSQL_PORT="${MYSQL_PORT:-3306}"
export MYSQL_DATABASE="${MYSQL_DATABASE:-}"

# Snowflake Configuration (used by: config/database.zsh)
export SNOWFLAKE_ACCOUNT="${SNOWFLAKE_ACCOUNT:-}"
export SNOWFLAKE_USER="${SNOWFLAKE_USER:-dheerajchand}"
export SNOWFLAKE_WAREHOUSE="${SNOWFLAKE_WAREHOUSE:-}"
export SNOWFLAKE_DATABASE="${SNOWFLAKE_DATABASE:-}"
export SNOWFLAKE_SCHEMA="${SNOWFLAKE_SCHEMA:-PUBLIC}"

# -----------------------------------------------------
# DOCKER CONFIGURATION
# -----------------------------------------------------
# Used by: config/docker.zsh, docker.zsh, utilities.zsh
export RANCHER_DOCKER_CONTEXT="${RANCHER_DOCKER_CONTEXT:-rancher-desktop}"
export DOCKER_DESKTOP_CONTEXT="${DOCKER_DESKTOP_CONTEXT:-desktop-linux}"
export CURRENT_DOCKER_PROVIDER="${CURRENT_DOCKER_PROVIDER:-rancher}"
export DEFAULT_DOCKER_CONTEXT="${DEFAULT_DOCKER_CONTEXT:-rancher-desktop}"

# Docker Build Configuration (used by: config/docker.zsh)
export DOCKER_BUILDKIT="${DOCKER_BUILDKIT:-1}"
export COMPOSE_DOCKER_CLI_BUILD="${COMPOSE_DOCKER_CLI_BUILD:-1}"

# -----------------------------------------------------
# BACKUP SYSTEM CONFIGURATION
# -----------------------------------------------------
# Used by: backup-system.zsh, config/backup-toggle.zsh
export AUTO_BACKUP_ON_CHANGE="${AUTO_BACKUP_ON_CHANGE:-false}"
export AUTO_BACKUP_INTERVAL="${AUTO_BACKUP_INTERVAL:-3600}"  # 1 hour in seconds
export PATH_DEDUPLICATION_ENABLED="${PATH_DEDUPLICATION_ENABLED:-true}"

# -----------------------------------------------------
# SYSTEM BEHAVIOR CONTROL
# -----------------------------------------------------
# Used by: zshrc (this file), various modules for debugging
export MODULAR_ZSHRC_VERBOSE="${MODULAR_ZSHRC_VERBOSE:-false}"  # Show module loading messages
export ZSH_STARTUP_TIMING="${ZSH_STARTUP_TIMING:-false}"        # Display startup performance

# Auto-setup Configuration (used by: auto-setup.zsh)
export AUTO_SETUP_ON_STARTUP="${AUTO_SETUP_ON_STARTUP:-false}"
export AUTO_SETUP_CHECK_ONLINE="${AUTO_SETUP_CHECK_ONLINE:-true}"
export AUTO_SETUP_VERBOSE="${AUTO_SETUP_VERBOSE:-false}"

# Shell Configuration (used by: config/core.zsh)
export CASE_SENSITIVE="${CASE_SENSITIVE:-true}"
export DISABLE_AUTO_TITLE="${DISABLE_AUTO_TITLE:-true}"

# -----------------------------------------------------
# CREDENTIAL SYSTEM CONFIGURATION
# -----------------------------------------------------
# Used by: config/credentials.zsh (when module exists)
export CREDENTIAL_BACKEND="${CREDENTIAL_BACKEND:-env-first}"     # env-first, 1password-first, apple-first, env-only
export CREDENTIAL_AUTO_SETUP="${CREDENTIAL_AUTO_SETUP:-true}"

# -----------------------------------------------------
# GIT CONFIGURATION
# -----------------------------------------------------
# Used by: config/core.zsh, various git functions
export GIT_DISCOVERY_ACROSS_FILESYSTEM="${GIT_DISCOVERY_ACROSS_FILESYSTEM:-1}"

# =====================================================
# END CENTRALIZED VARIABLES SECTION
# =====================================================

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
        # Load module and capture only errors (not stdout)
        local error_output
        if source "$module_path" 2>/tmp/module_load_error_$$; then
            # Check if there were any errors
            if [[ -s "/tmp/module_load_error_$$" ]]; then
                error_output=$(cat "/tmp/module_load_error_$$")
                [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "⚠️  Warnings in module: $module_name: $error_output"
            fi
            LOADED_MODULES[$module_name]="success"
            [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "✅ Loaded: $module_name"
            rm -f "/tmp/module_load_error_$$"
            return 0
        else
            error_output=$(cat "/tmp/module_load_error_$$" 2>/dev/null)
            LOADED_MODULES[$module_name]="error"
            echo "❌ Error loading module: $module_name"
            [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "   Error details: $error_output"
            rm -f "/tmp/module_load_error_$$"
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

# Advanced Python Management System (v2.1.0-optimized)
if [[ -f "$ZSH_CONFIG_DIR/python/init.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/python/init.zsh"
fi


# pyenv setup
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

# SDKMAN initialization (if available)
if [[ -s "${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh" ]]; then
    export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec 2>/dev/null || export SDKMAN_DIR="$HOME/.sdkman"
    source "${SDKMAN_DIR}/bin/sdkman-init.sh"
fi

# Load big data modules (functions always available)
load_config_module "spark"
load_config_module "hadoop"

# =====================================================
# SYSTEM-SPECIFIC MODULES
# =====================================================

# Docker integration (functions always available)
load_config_module "docker"

# Load backup system (optional module)
# load_config_module "backup-system"

# Load backup toggle system (for controlling auto-backup)
load_config_module "backup-toggle"

# Load status system (master_status and other status functions)
load_config_module "status"

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
    local legacy_module_path="$ZSH_CONFIG_DIR/$module"
    if [[ -f "$legacy_module_path" ]]; then
        if source "$legacy_module_path" 2>/dev/null; then
            [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "✅ Legacy: $module"
        else
            echo "⚠️  Error in legacy module: $module"
        fi
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
