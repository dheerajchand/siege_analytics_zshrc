#!/usr/bin/env zsh
# =====================================================
# CENTRALIZED VARIABLES & CONSTANTS
# =====================================================
#
# Single source of truth for all environment variables,
# paths, and constants used across the ZSH configuration.
#
# =====================================================

# =====================================================
# CORE DIRECTORIES & PATHS
# =====================================================

# ZSH Configuration
export ZSH_CONFIG_DIR="$HOME/.config/zsh"
export ZSH_MODULES_DIR="$ZSH_CONFIG_DIR/modules"
export ZSH_CONFIG_MODULES="$ZSH_CONFIG_DIR/config"  # Legacy config location
export ZSH_SERVICES_DIR="$ZSH_CONFIG_DIR/services"
export ZSH_SCRIPTS_DIR="$ZSH_CONFIG_DIR/scripts"
export ZSH_CACHE_DIR="$ZSH_CONFIG_DIR/cache"
export ZSH_LOGS_DIR="$ZSH_CONFIG_DIR/logs"

# Development Paths
export SIEGE_UTILITIES_TEST="$HOME/Desktop/in_process/code/siege_utilities_verify"
export DEVELOPMENT_ROOT="$HOME/Desktop/in_process/code"

# User Binary Paths
export USER_LOCAL_BIN="$HOME/.local/bin"
export USER_BIN="$HOME/bin"
export JETBRAINS_BIN="$HOME/.jetbrains/bin"

# =====================================================
# TOOL-SPECIFIC PATHS
# =====================================================

# Python Environment Paths
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export UV_BIN_PATH="$HOME/.local/share/uv/bin"
export PYTHON_VENV_PATH="$HOME/.virtualenvs"

# Node.js/JavaScript Paths
export NVM_DIR="$HOME/.nvm"
export NODE_MODULES_BIN="./node_modules/.bin"

# Java/JVM Paths
export SDKMAN_DIR="$HOME/.sdkman"
export JAVA_TOOLS_PATH="/opt/homebrew/opt/sdkman-cli/libexec/candidates/java/current/bin"

# Big Data Paths
export SPARK_HOME_PATH="/opt/homebrew/opt/sdkman-cli/libexec/candidates/spark/current"
export HADOOP_HOME_PATH="/opt/homebrew/opt/sdkman-cli/libexec/candidates/hadoop/current"
export SPARK_BIN_PATH="$SPARK_HOME_PATH/bin"
export SPARK_SBIN_PATH="$SPARK_HOME_PATH/sbin"
export HADOOP_BIN_PATH="$HADOOP_HOME_PATH/bin"
export HADOOP_SBIN_PATH="$HADOOP_HOME_PATH/sbin"

# Docker & Container Paths
export DOCKER_CONFIG_PATH="$HOME/.docker"
export RANCHER_DESKTOP_PATH="$HOME/.rd/bin"

# Homebrew Paths
export HOMEBREW_BIN="/opt/homebrew/bin"
export HOMEBREW_SBIN="/opt/homebrew/sbin"

# =====================================================
# CORE SYSTEM PATHS
# =====================================================

# Essential system paths (order matters for precedence)
export CORE_SYSTEM_PATHS=(
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
)

# User paths (highest precedence)
export USER_PATHS=(
    "$USER_LOCAL_BIN"
    "$USER_BIN"
    "$HOMEBREW_BIN"
)

# Development tool paths (loaded on demand)
export PYTHON_PATHS=(
    "$PYENV_ROOT/bin"
    "$UV_BIN_PATH"
)

export JAVASCRIPT_PATHS=(
    "$NVM_DIR/versions/node/*/bin"
    "$NODE_MODULES_BIN"
)

export BIGDATA_PATHS=(
    "$SPARK_BIN_PATH"
    "$SPARK_SBIN_PATH"
    "$HADOOP_BIN_PATH"
    "$HADOOP_SBIN_PATH"
    "$JAVA_TOOLS_PATH"
)

export CONTAINER_PATHS=(
    "$RANCHER_DESKTOP_PATH"
)

export IDE_PATHS=(
    "$JETBRAINS_BIN"
)

# =====================================================
# APPLICATION DEFAULTS
# =====================================================

# Database Configuration
export PGUSER="${PGUSER:-dheerajchand}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-postgres}"

# Python Configuration
export PYTHON_MANAGER="${PYTHON_MANAGER:-auto}"
export PREFERRED_VENV="${PREFERRED_VENV:-geo31111}"
export PYTHONPATH="${PYTHONPATH:-}"

# Spark Configuration
export SPARK_DRIVER_MEMORY="${SPARK_DRIVER_MEMORY:-2g}"
export SPARK_EXECUTOR_MEMORY="${SPARK_EXECUTOR_MEMORY:-2g}"
export SPARK_DRIVER_CORES="${SPARK_DRIVER_CORES:-2}"
export SPARK_EXECUTOR_CORES="${SPARK_EXECUTOR_CORES:-2}"

# Docker Configuration
export DOCKER_BUILDKIT="${DOCKER_BUILDKIT:-1}"
export COMPOSE_DOCKER_CLI_BUILD="${COMPOSE_DOCKER_CLI_BUILD:-1}"

# Editor Configuration
export EDITOR="${EDITOR:-zed}"
export VISUAL="$EDITOR"
export PAGER="${PAGER:-less}"

# =====================================================
# SYSTEM BEHAVIOR FLAGS
# =====================================================

# Path Management
export PATH_DEDUPLICATION_ENABLED="${PATH_DEDUPLICATION_ENABLED:-true}"
export PATH_MONITORING_ENABLED="${PATH_MONITORING_ENABLED:-false}"
export PATH_OPTIMIZATION_ENABLED="${PATH_OPTIMIZATION_ENABLED:-true}"

# Module Loading
export MODULE_LOADING_VERBOSE="${MODULE_LOADING_VERBOSE:-false}"
export MODULE_AUTO_LOAD="${MODULE_AUTO_LOAD:-false}"

# Performance Monitoring
export ZSH_STARTUP_TIMING="${ZSH_STARTUP_TIMING:-false}"
export ZSH_PERFORMANCE_LOGGING="${ZSH_PERFORMANCE_LOGGING:-false}"

# Backup System
export AUTO_BACKUP_ENABLED="${AUTO_BACKUP_ENABLED:-true}"
export BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# =====================================================
# MODULE SYSTEM CONFIGURATION
# =====================================================

# Mode Definitions (Light mode modules - others calculated dynamically)
# Keep this minimal - only essential modules for fast startup
export ZSH_LIGHT_MODULES="utils python javascript"

# Module Discovery Patterns
export MODULE_FILE_PATTERN="*.module.zsh"
export MODULE_NAME_SUFFIX=".module.zsh"

# Mode State Tracking
export ZSH_CURRENT_MODE="${ZSH_CURRENT_MODE:-minimal}"
export ZSH_LIGHT_MODE="${ZSH_LIGHT_MODE:-false}"

# =====================================================
# REPOSITORY CONFIGURATION
# =====================================================

# Main repository paths
export ZSH_MAIN_REPO="https://github.com/dheerajchand/siege_analytics_zshrc"
export ZSH_BACKUP_REPO="https://github.com/dheerajchand/zshrc_backups"

# Local repository paths
export ZSH_ACTIVE_REPO="$ZSH_CONFIG_DIR"
export ZSH_ARCHIVE_REPO="$HOME/.zsh_backups"

# =====================================================
# COMPLETION
# =====================================================
export ZSH_VARIABLES_LOADED=true

# Debug information
if [[ "$MODULE_LOADING_VERBOSE" == "true" ]]; then
    echo "✅ Centralized variables loaded from $ZSH_CONFIG_DIR/config/variables.zsh"
fi