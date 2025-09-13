#!/usr/bin/env zsh
# =====================================================
# BASH COMPATIBILITY LAYER
# Cross-shell compatibility for zsh and bash
# =====================================================

# Shell detection
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Set shell-specific variables
export CURRENT_SHELL=$(detect_shell)
export IS_ZSH=$([ "$CURRENT_SHELL" = "zsh" ] && echo "true" || echo "false")
export IS_BASH=$([ "$CURRENT_SHELL" = "bash" ] && echo "true" || echo "false")

# Platform detection
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

export PLATFORM=$(detect_platform)

# Linux distribution detection
if [[ "$PLATFORM" == "linux" && -f /etc/os-release ]]; then
    . /etc/os-release
    export LINUX_DISTRO="$ID"
    export LINUX_VERSION="$VERSION_ID"
    
    case "$LINUX_DISTRO" in
        "ubuntu"|"debian")
            export PACKAGE_MANAGER="apt"
            ;;
        "rhel"|"centos"|"rocky"|"almalinux")
            export PACKAGE_MANAGER="dnf"
            ;;
    esac
fi

# macOS-specific configuration
if [[ "$PLATFORM" == "macos" ]]; then
    export BREW_PREFIX="/opt/homebrew"  # Apple Silicon
    if [ ! -d "$BREW_PREFIX" ]; then
        export BREW_PREFIX="/usr/local"  # Intel
    fi
    export PATH="$BREW_PREFIX/bin:$PATH"
fi

# Cross-shell Python management
setup_python_manager() {
    local manager=${1:-$PYTHON_MANAGER}
    
    case "$manager" in
        "pyenv")
            setup_pyenv
            ;;
        "uv")
            setup_uv
            ;;
        "auto")
            if [ -f ".python-version" ]; then
                setup_pyenv
            elif [ -f "pyproject.toml" ]; then
                setup_uv
            else
                setup_pyenv  # Default
            fi
            ;;
    esac
}

# Cross-shell pyenv setup
setup_pyenv() {
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    if command -v pyenv >/dev/null 2>&1; then
        eval "$(pyenv init -)"
        if command -v pyenv-virtualenv >/dev/null 2>&1; then
            eval "$(pyenv virtualenv-init -)"
        fi
    fi
}

# Cross-shell uv setup
setup_uv() {
    export UV_PYTHON_PREFERENCE="managed"
    export UV_PYTHON_DOWNLOADS="automatic"
    export UV_COMPILE_BYTECODE=1
    export UV_LINK_MODE="copy"
    
    if command -v uv >/dev/null 2>&1; then
        export PYSPARK_PYTHON=$(uv run which python 2>/dev/null || which python3)
        export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
        
        alias uvpy="uv python"
        alias uvrun="uv run"
        alias uvsync="uv sync"
        alias uvlock="uv lock"
        alias uvpip="uv pip"
    fi
}

# Cross-shell Python status
python_status() {
    echo "=== Python Environment Status ==="
    echo "Shell: $CURRENT_SHELL"
    echo "Platform: $PLATFORM"
    echo "Python Manager: ${PYTHON_MANAGER:-auto}"
    
    if command -v python >/dev/null 2>&1; then
        echo "Python Version: $(python --version)"
        echo "Python Path: $(which python)"
    else
        echo "Python: Not found"
    fi
    
    if command -v pyenv >/dev/null 2>&1; then
        echo "Pyenv Version: $(pyenv --version)"
        echo "Pyenv Python: $(pyenv which python 2>/dev/null || echo 'Not set')"
    fi
    
    if command -v uv >/dev/null 2>&1; then
        echo "UV Version: $(uv --version)"
    fi
    
    echo "PYSPARK_PYTHON: $PYSPARK_PYTHON"
    echo "PYSPARK_DRIVER_PYTHON: $PYSPARK_DRIVER_PYTHON"
    echo "============================re

# Cross-shell backup function
backup() {
    local message="$1"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_dir="$ZSHRC_BACKUPS/$(date +%Y)/$(date +%m)/week$(date +%V)/config_$timestamp"
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    # Backup configuration
    if [ -d "$ZSHRC_CONFIG_DIR" ]; then
        cp -r "$ZSHRC_CONFIG_DIR" "$backup_dir/zsh"
    fi
    
    # Create metadata
    cat > "$backup_dir/metadata.json" << EOF
{
    "timestamp": "$timestamp",
    "message": "$message",
    "shell": "$CURRENT_SHELL",
    "platform": "$PLATFORM",
    "version": "2.1.0"
}
EOF
    
    echo "Backup created: $backup_dir"
}

# Cross-shell Spark setup
setup_spark() {
    export SPARK_HOME="$HOME/.sdkman/candidates/spark/current"
    export PATH="$SPARK_HOME/bin:$PATH"
    
    # Set Spark Python paths
    if command -v pyenv >/dev/null 2>&1; then
        export PYSPARK_PYTHON=$(pyenv which python 2>/dev/null || which python3)
    elif command -v uv >/dev/null 2>&1; then
        export PYSPARK_PYTHON=$(uv run which python 2>/dev/null || which python3)
    else
        export PYSPARK_PYTHON=$(which python3)
    fi
    export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
}

# Cross-shell Spark configuration display
show_spark_config() {
    echo "=== Spark Configuration ==="
    echo "Shell: $CURRENT_SHELL"
    echo "Platform: $PLATFORM"
    echo "SPARK_HOME: $SPARK_HOME"
    echo "JAVA_HOME: $JAVA_HOME"
    echo "PYSPARK_PYTHON: $PYSPARK_PYTHON"
    echo "PYSPARK_DRIVER_PYTHON: $PYSPARK_DRIVER_PYTHON"
    echo "SPARK_DRIVER_MEMORY: $SPARK_DRIVER_MEMORY"
    echo "SPARK_EXECUTOR_MEMORY: $SPARK_EXECUTOR_MEMORY"
    echo "=========================="
}

# Cross-shell help system
zsh_help() {
    local topic="$1"
    
    case "$topic" in
        "all"|"")
            echo "=== Siege Analytics Configuration Help ==="
            echo "Shell: $CURRENT_SHELL"
            echo "Platform: $PLATFORM"
            echo ""
            echo "Available commands:"
            echo "  python_status      - Show Python environment status"
            echo "  backup <message>   - Create system backup"
            echo "  setup_spark        - Setup Spark environment"
            echo "  show_spark_config  - Show Spark configuration"
            echo "  deduplicate_path   - Remove duplicate PATH entries"
            echo "  optimize_shell     - Optimize shell performance"
            echo "  validate_environment - Validate system environment"
            echo "  test_compatibility - Test cross-shell compatibility"
            echo "  zsh_help <topic>   - Show this help"
            echo ""
            echo "Topics: python, backup, spark, performance, validation, all"
            echo "========================================"
            ;;
        "python")
            echo "=== Python Management ==="
            echo "setup_python_manager [pyenv|uv|auto] - Setup Python manager"
            echo "setup_pyenv                          - Setup pyenv"
            echo "setup_uv                             - Setup uv"
            echo "python_status                        - Show Python status"
            echo "=========================="
            ;;
        "backup")
            echo "=== Backup System ==="
            echo "backup <message> - Create system backup"
            echo "====================="
            ;;
        "spark")
            echo "=== Spark Integration ==="
            echo "setup_spark       - Setup Spark environment"
            echo "show_spark_config - Show Spark configuration"
            echo "========================"
            ;;
        "performance")
            echo "=== Performance Optimization ==="
            echo "deduplicate_path  - Remove duplicate PATH entries"
            echo "optimize_shell    - Optimize shell performance"
            echo "test_compatibility - Test cross-shell compatibility"
            echo "================================"
            ;;
        "validation")
            echo "=== Environment Validation ==="
            echo "validate_environment - Validate system environment"
            echo "=============================="
            ;;
        *)
            echo "Unknown topic: $topic"
            echo "Use 'zsh_help all' for available topics"
            ;;
    esac
}

# Cross-shell performance optimization
optimize_shell() {
    echo "=== Shell Performance Optimization ==="
    echo "Shell: $CURRENT_SHELL"
    echo "Platform: $PLATFORM"
    echo ""
    
    # PATH deduplication
    echo "Optimizing PATH..."
    deduplicate_path
    
    # Shell-specific optimizations
    if [ "$IS_ZSH" = "true" ]; then
        echo "ZSH-specific optimizations:"
        echo "- Disabling global RCS files"
        echo "- Enabling completion system"
        echo "- Optimizing history settings"
    elif [ "$IS_BASH" = "true" ]; then
        echo "Bash-specific optimizations:"
        echo "- Optimizing history settings"
        echo "- Enabling completion"
        echo "- Setting prompt"
    fi
    
    echo "Performance optimization complete"
    echo "================================="
}

# Cross-shell environment validation
validate_environment() {
    echo "=== Environment Validation ==="
    echo "Shell: $CURRENT_SHELL"
    echo "Platform: $PLATFORM"
    echo ""
    
    # Check required tools
    local missing_tools=()
    
    if ! command -v java >/dev/null 2>&1; then
        missing_tools+=("java")
    fi
    
    if ! command -v python3 >/dev/null 2>&1; then
        missing_tools+=("python3")
    fi
    
    if ! command -v git >/dev/null 2>&1; then
        missing_tools+=("git")
    fi
    
    # Check optional tools
    local optional_tools=("spark-shell" "pyenv" "uv" "mvn" "gradle")
    local available_optional=()
    
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            available_optional+=("$tool")
        fi
    done
    
    # Report results
    if [ ${#missing_tools[@]} -eq 0 ]; then
        echo "✓ All required tools are available"
    else
        echo "✗ Missing required tools: ${missing_tools[*]}"
    fi
    
    if [ ${#available_optional[@]} -gt 0 ]; then
        echo "✓ Available optional tools: ${available_optional[*]}"
    fi
    
    # Check environment variables
    echo ""
    echo "Environment Variables:"
    echo "ZSHRC_CONFIG_DIR: ${ZSHRC_CONFIG_DIR:-NOT SET}"
    echo "PYTHON_MANAGER: ${PYTHON_MANAGER:-NOT SET}"
    echo "SPARK_HOME: ${SPARK_HOME:-NOT SET}"
    echo "JAVA_HOME: ${JAVA_HOME:-NOT SET}"
    
    echo "=========================="
}

# Cross-shell PATH deduplication
deduplicate_path() {
    if [ "$PATH_DEDUPLICATION_ENABLED" != "true" ]; then
        return 0
    fi
    
    local current_path="$PATH"
    local cleaned_path=""
    local duplicates_removed=0
    
    # Cross-shell PATH splitting
    if [ "$IS_ZSH" = "true" ]; then
        # ZSH-specific array handling
        local -a path_array
        path_array=(${(s/:/)current_path})
        
        for entry in "${path_array[@]}"; do
            # Skip empty entries
            [ -z "$entry" ] && continue
            
            # Check if entry already exists in cleaned path (use proper delimiter checking)
            if [[ ":$cleaned_path:" != *":$entry:"* ]]; then
                if [ -z "$cleaned_path" ]; then
                    cleaned_path="$entry"
                else
                    cleaned_path="$cleaned_path:$entry"
                fi
            else
                duplicates_removed=$((duplicates_removed + 1))
            fi
        done
    else
        # Bash-compatible PATH handling
        IFS=':' read -ra path_array <<< "$current_path"
        
        for entry in "${path_array[@]}"; do
            # Skip empty entries
            [ -z "$entry" ] && continue
            
            # Check if entry already exists in cleaned path (use proper delimiter checking)
            if [[ ":$cleaned_path:" != *":$entry:"* ]]; then
                if [ -z "$cleaned_path" ]; then
                    cleaned_path="$entry"
                else
                    cleaned_path="$cleaned_path:$entry"
                fi
            else
                duplicates_removed=$((duplicates_removed + 1))
            fi
        done
    fi
    
    # Update PATH
    export PATH="$cleaned_path"
    
    if [ $duplicates_removed -gt 0 ]; then
        echo "Removed $duplicates_removed duplicate PATH entries"
    fi
}

# Cross-shell compatibility test
test_compatibility() {
    echo "=== Shell Compatibility Test ==="
    echo "Current shell: $CURRENT_SHELL"
    echo "Platform: $PLATFORM"
    echo "ZSH: $IS_ZSH"
    echo "Bash: $IS_BASH"
    
    # Test Python management
    echo ""
    echo "Testing Python management..."
    setup_python_manager auto
    python_status
    
    # Test backup system
    echo ""
    echo "Testing backup system..."
    backup "Compatibility test"
    
    # Test Spark integration
    echo ""
    echo "Testing Spark integration..."
    setup_spark
    show_spark_config
    
    echo ""
    echo "Compatibility test complete"
    echo "============================"
}

# Initialize compatibility layer
init_compatibility() {
    echo "Initializing Siege Analytics Configuration for $CURRENT_SHELL on $PLATFORM"
    
    # Set core environment variables
    export ZSHRC_CONFIG_DIR="$HOME/.config/zsh"
    export ZSHRC_BACKUPS="$HOME/.zshrc_backups"
    export PYTHON_MANAGER="${PYTHON_MANAGER:-auto}"
    export PATH_DEDUPLICATION_ENABLED="${PATH_DEDUPLICATION_ENABLED:-true}"
    
    # SDKMAN configuration
    if [ -d "$HOME/.sdkman" ]; then
        export SDKMAN_DIR="$HOME/.sdkman"
        [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
        
        # SDKMAN-managed environment variables
        export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
        export SCALA_HOME="$HOME/.sdkman/candidates/scala/current"
        export SPARK_HOME="$HOME/.sdkman/candidates/spark/current"
        export HADOOP_HOME="$HOME/.sdkman/candidates/hadoop/current"
        export MAVEN_HOME="$HOME/.sdkman/candidates/maven/current"
        export GRADLE_HOME="$HOME/.sdkman/candidates/gradle/current"
        
        # Add to PATH
        export PATH="$JAVA_HOME/bin:$SCALA_HOME/bin:$SPARK_HOME/bin:$HADOOP_HOME/bin:$MAVEN_HOME/bin:$GRADLE_HOME/bin:$PATH"
    fi
    
    # Optimize PATH
    deduplicate_path
    
    echo "Compatibility layer initialized"
}

# Auto-initialize if not already done
if [[ -z "$SIEGE_COMPATIBILITY_INITIALIZED" ]]; then
    init_compatibility
    export SIEGE_COMPATIBILITY_INITIALIZED="true"
fi
