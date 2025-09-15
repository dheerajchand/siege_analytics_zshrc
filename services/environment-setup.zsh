#!/usr/bin/env zsh
# =====================================================
# ENVIRONMENT SETUP SERVICE - Heavy initialization
# =====================================================
#
# This service handles heavy environment setup that would
# slow down shell startup if done synchronously.
# =====================================================

SERVICE_NAME="environment-setup"
LOG_FILE="$HOME/.config/zsh/logs/${SERVICE_NAME}.log"
CACHE_FILE="$HOME/.config/zsh/cache/environment.cache"

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$CACHE_FILE")"

# =====================================================
# SETUP FUNCTIONS
# =====================================================

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

setup_sdkman() {
    log_message "Setting up SDKMAN..."

    if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"

        # Cache SDKMAN paths for quick loading
        echo "export SDKMAN_DIR=\"$SDKMAN_DIR\"" > "$CACHE_FILE.sdkman"

        if [[ -d "$SDKMAN_DIR/candidates/java/current" ]]; then
            echo "export JAVA_HOME=\"$SDKMAN_DIR/candidates/java/current\"" >> "$CACHE_FILE.sdkman"
        fi

        if [[ -d "$SDKMAN_DIR/candidates/spark/current" ]]; then
            echo "export SPARK_HOME=\"$SDKMAN_DIR/candidates/spark/current\"" >> "$CACHE_FILE.sdkman"
        fi

        if [[ -d "$SDKMAN_DIR/candidates/hadoop/current" ]]; then
            echo "export HADOOP_HOME=\"$SDKMAN_DIR/candidates/hadoop/current\"" >> "$CACHE_FILE.sdkman"
        fi

        log_message "SDKMAN setup complete"
    else
        log_message "SDKMAN not found"
    fi
}

setup_python_managers() {
    log_message "Setting up Python managers..."

    # Pyenv setup
    if command -v pyenv >/dev/null 2>&1; then
        echo "export PYENV_ROOT=\"$HOME/.pyenv\"" > "$CACHE_FILE.python"
        echo "export PATH=\"\$PYENV_ROOT/bin:\$PATH\"" >> "$CACHE_FILE.python"

        # Cache available versions
        pyenv versions --bare > "$CACHE_FILE.pyenv_versions" 2>/dev/null

        log_message "Pyenv cached"
    fi

    # UV setup
    if command -v uv >/dev/null 2>&1; then
        echo "# UV available" >> "$CACHE_FILE.python"
        log_message "UV detected"
    fi
}

setup_node_managers() {
    log_message "Setting up Node.js managers..."

    # NVM setup
    if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
        echo "export NVM_DIR=\"$HOME/.nvm\"" > "$CACHE_FILE.node"
        log_message "NVM cached"
    fi

    # fnm setup
    if command -v fnm >/dev/null 2>&1; then
        echo "# fnm available" >> "$CACHE_FILE.node"
        log_message "fnm detected"
    fi
}

setup_completion_systems() {
    log_message "Setting up completion systems..."

    # Generate completion cache
    local completion_cache="$CACHE_FILE.completions"
    echo "# Completion cache generated $(date)" > "$completion_cache"

    # Cache available commands for faster completion
    if command -v docker >/dev/null 2>&1; then
        echo "docker" >> "$completion_cache"
    fi

    if command -v kubectl >/dev/null 2>&1; then
        echo "kubectl" >> "$completion_cache"
    fi

    if command -v git >/dev/null 2>&1; then
        echo "git" >> "$completion_cache"
    fi

    log_message "Completion cache updated"
}

# =====================================================
# MAIN SETUP ROUTINE
# =====================================================

run_full_setup() {
    log_message "Starting full environment setup"

    # Clear old cache
    rm -f "$CACHE_FILE".*

    # Run setup functions
    setup_sdkman
    setup_python_managers
    setup_node_managers
    setup_completion_systems

    # Create main cache file with timestamp
    echo "# Environment cache generated at $(date)" > "$CACHE_FILE"
    echo "export ENVIRONMENT_CACHE_TIMESTAMP=$(date +%s)" >> "$CACHE_FILE"

    log_message "Full environment setup complete"
}

load_cached_environment() {
    # Load cached environment quickly
    [[ -f "$CACHE_FILE.sdkman" ]] && source "$CACHE_FILE.sdkman"
    [[ -f "$CACHE_FILE.python" ]] && source "$CACHE_FILE.python"
    [[ -f "$CACHE_FILE.node" ]] && source "$CACHE_FILE.node"
}

# =====================================================
# SERVICE INTERFACE
# =====================================================

case "${1:-help}" in
    "setup")
        echo "🔧 Running environment setup..."
        run_full_setup
        echo "✅ Environment setup complete"
        ;;
    "load")
        load_cached_environment
        echo "✅ Cached environment loaded"
        ;;
    "status")
        echo "🔧 Environment Setup Service Status"
        echo "==================================="

        if [[ -f "$CACHE_FILE" ]]; then
            local timestamp=$(grep ENVIRONMENT_CACHE_TIMESTAMP "$CACHE_FILE" | cut -d'=' -f2)
            local cache_age=$(($(date +%s) - timestamp))
            echo "Cache status: ✅ Available (${cache_age}s old)"

            echo ""
            echo "Cached components:"
            [[ -f "$CACHE_FILE.sdkman" ]] && echo "  ✅ SDKMAN"
            [[ -f "$CACHE_FILE.python" ]] && echo "  ✅ Python managers"
            [[ -f "$CACHE_FILE.node" ]] && echo "  ✅ Node.js managers"
            [[ -f "$CACHE_FILE.completions" ]] && echo "  ✅ Completions"
        else
            echo "Cache status: ❌ Not available"
            echo "💡 Run: $0 setup"
        fi

        if [[ -f "$LOG_FILE" ]]; then
            echo ""
            echo "Recent activity:"
            tail -3 "$LOG_FILE" | sed 's/^/  /'
        fi
        ;;
    *)
        echo "Environment Setup Service"
        echo "========================"
        echo ""
        echo "Commands:"
        echo "  setup  - Run full environment setup and create cache"
        echo "  load   - Load cached environment (fast)"
        echo "  status - Show service status"
        echo ""
        echo "This service pre-processes heavy environment setup"
        echo "to keep shell startup fast."
        ;;
esac