#!/usr/bin/env zsh
# =================================================================
# CLEAN ZSHRC - Focused Shell Configuration
# =================================================================
# Purpose: Python, Spark/Hadoop, Docker, Database, Git management
# No security theater, just useful functionality
# =================================================================

# Basic environment
export EDITOR="zed"
export VISUAL="$EDITOR"
export ZSH_CONFIG_DIR="$HOME/.config/zsh"

# Set base PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"

# Initialize SDKMAN (sets HADOOP_HOME, SPARK_HOME, JAVA_HOME)
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

# Set *_HOME variables if not set by SDKMAN
[[ -z "$HADOOP_HOME" && -d "$SDKMAN_DIR/candidates/hadoop/current" ]] && export HADOOP_HOME="$SDKMAN_DIR/candidates/hadoop/current"
[[ -z "$SPARK_HOME" && -d "$SDKMAN_DIR/candidates/spark/current" ]] && export SPARK_HOME="$SDKMAN_DIR/candidates/spark/current"
[[ -z "$JAVA_HOME" && -d "$SDKMAN_DIR/candidates/java/current" ]] && export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"

# Oh-My-Zsh setup
export ZSH="$HOME/.dotfiles/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

# Initialize completion system
autoload -Uz compinit && compinit
zmodload zsh/compctl 2>/dev/null

# Load Oh-My-Zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# =================================================================
# STAGGERED LOADING - Performance Optimization for IDEs
# =================================================================
# IDEs take longer to load zsh, so we load modules progressively
# Regular terminals get everything immediately
# =================================================================

# Detect if running in an IDE
detect_ide() {
    # Check for common IDE environment variables
    [[ -n "$PYCHARM_HOSTED" ]] && return 0
    [[ -n "$DATASPELL_HOSTED" ]] && return 0
    [[ -n "$INTELLIJ_ENVIRONMENT_READER" ]] && return 0
    [[ -n "$JETBRAINS_IDE" ]] && return 0
    [[ "$TERM_PROGRAM" == "vscode" ]] && return 0
    
    # Check process tree for IDE
    local parent_proc=$(ps -p $PPID -o comm= 2>/dev/null)
    [[ "$parent_proc" =~ (pycharm|idea|webstorm|goland|datagrip|dataspell|code) ]] && return 0
    
    return 1
}

# Module loader
load_module() {
    local module="$1"
    if [[ -f "$ZSH_CONFIG_DIR/clean/$module.zsh" ]]; then
        source "$ZSH_CONFIG_DIR/clean/$module.zsh"
    else
        echo "❌ Module not found: $module"
        return 1
    fi
}

# =================================================================
# ESSENTIAL ALIASES & CONSTANTS - Load First
# =================================================================

# Basic aliases (always available immediately)
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Git shortcuts (in addition to Oh-My-Zsh)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# =================================================================
# MODULE LOADING - Staggered for IDEs, Immediate for Terminals
# =================================================================

# Load modules based on environment
if detect_ide; then
    echo "🖥️  IDE detected - using staggered loading for faster startup"
    
    # Tier 1: Essential (load immediately - IDE needs Python right away)
    load_module utils       # Provides is_online, mkcd, extract, path_add
    load_module python      # Python environment (geo31111 auto-activated)
    
    # Tier 2: Credentials & paths (load in background after brief delay)
    {
        sleep 0.1
        load_module credentials  # 1Password/Keychain
        load_module database     # PostgreSQL with credentials
        load_module backup       # Git self-backup
    } &
    
    # Tier 3: Heavy tools (load in background - Spark/Hadoop/Docker)
    {
        sleep 0.5
        load_module docker       # Docker management
        load_module spark        # Spark cluster (uses is_online!)
        load_module hadoop       # Hadoop/YARN/HDFS
        echo "✅ All modules loaded" >&2
    } &
    
    echo "💡 Python ready now, Spark/Hadoop loading in background"
    
else
    # Regular terminal - load everything immediately (fast enough)
    echo "🚀 Loading modules..."
    
    load_module utils
    load_module python
    load_module credentials
    load_module database
    load_module backup
    load_module docker
    load_module spark
    load_module hadoop
fi

# =================================================================
# FIX PATH - Ensure Hadoop/Spark bins are in PATH after all loading
# =================================================================
# Problem: pyenv init and other tools may reorganize PATH
# Solution: Explicitly ensure SDKMAN tools are in PATH after everything loads

if [[ -n "$HADOOP_HOME" && -d "$HADOOP_HOME/bin" ]]; then
    [[ ":$PATH:" != *":$HADOOP_HOME/bin:"* ]] && export PATH="$HADOOP_HOME/bin:$PATH"
    [[ ":$PATH:" != *":$HADOOP_HOME/sbin:"* ]] && export PATH="$HADOOP_HOME/sbin:$PATH"
fi

if [[ -n "$SPARK_HOME" && -d "$SPARK_HOME/bin" ]]; then
    [[ ":$PATH:" != *":$SPARK_HOME/bin:"* ]] && export PATH="$SPARK_HOME/bin:$PATH"
    [[ ":$PATH:" != *":$SPARK_HOME/sbin:"* ]] && export PATH="$SPARK_HOME/sbin:$PATH"
fi

# Rehash command table after PATH changes
rehash

# Help
help() {
    echo "🚀 ZSH Quick Reference"
    echo "===================="
    echo ""
    echo "🐍 Python:"
    echo "  py_env_switch [env]    - Switch Python environment"
    echo "  python_status          - Show current environment"
    echo "  ds_project_init <name> - Create data science project"
    echo ""
    echo "⚡ Spark:"
    echo "  spark_start            - Start Spark cluster"
    echo "  spark_stop             - Stop cluster"
    echo "  spark_status           - Show status"
    echo "  smart_spark_submit <file> - Submit job (auto-detects cluster)"
    echo "  spark_yarn_submit <file> - Submit to YARN"
    echo "  pyspark_shell          - Interactive PySpark"
    echo ""
    echo "🐘 Hadoop:"
    echo "  start_hadoop           - Start HDFS + YARN"
    echo "  stop_hadoop            - Stop services"
    echo "  hadoop_status          - Show status"
    echo "  yarn_application_list  - List YARN apps"
    echo "  hdfs_ls [path]         - List HDFS files"
    echo ""
    echo "🐳 Docker:"
    echo "  docker_status          - System status"
    echo "  docker_cleanup         - Remove stopped containers"
    echo "  docker_shell <container> - Shell into container"
    echo "  docker_logs <container> - View logs"
    echo ""
    echo "🗄️  Database:"
    echo "  pg_connect [db]        - Connect to PostgreSQL"
    echo "  pg_test_connection     - Test connection"
    echo "  setup_postgres_credentials - Setup passwords"
    echo ""
    echo "🔐 Credentials:"
    echo "  get_credential <service> <user> - Retrieve from 1Password/Keychain"
    echo "  store_credential <service> <user> <pass> - Store securely"
    echo "  ga_store_service_account <file.json> - Store GA credentials"
    echo ""
    echo "📦 Backup:"
    echo "  backup ['message']     - Commit and push to GitHub"
    echo "  pushmain               - Quick push"
    echo "  sync                   - Sync repository"
    echo ""
    echo "🛠️  Utilities:"
    echo "  is_online              - Check internet (used by Spark)"
    echo "  mkcd <dir>             - Create and cd"
    echo "  extract <file>         - Universal archive extraction"
    echo "  path_clean             - Remove duplicate PATH entries"
    echo ""
    echo "📚 Full docs: $ZSH_CONFIG_DIR/README.md"
}

# Show loaded modules
modules() {
    echo "📦 Loaded Modules"
    echo "================"
    echo "✅ utils       - Core utilities (is_online, mkcd, extract)"
    echo "✅ python      - Python/pyenv management"
    echo "✅ spark       - Spark cluster operations"
    echo "✅ hadoop      - Hadoop/YARN management"
    echo "✅ docker      - Container management"
    echo "✅ database    - PostgreSQL connections"
    echo "✅ credentials - Secure credential storage"
    echo "✅ backup      - Git self-backup system"
}

# Powerlevel10k configuration
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Welcome message
echo ""
echo "✅ ZSH loaded successfully"
echo "💡 Type 'help' for commands or 'modules' to see what's loaded"
echo ""

# Export FEC API key (from old config)
export FEC_API_KEY="37J9ykQjEo7xjA0I8Zb0vC0H8AwCQhIcsGlWYDZv"

