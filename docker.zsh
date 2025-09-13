# =====================================================
# DOCKER CONTEXT SWITCHING UTILITIES
# =====================================================
# Switch between Rancher Desktop and Docker Desktop

# Docker context configuration
export RANCHER_DOCKER_CONTEXT="rancher-desktop"
export DOCKER_DESKTOP_CONTEXT="desktop-linux"

# Current context tracking (default to none)
export CURRENT_DOCKER_PROVIDER="${CURRENT_DOCKER_PROVIDER:-none}"

# Function to turn off both Docker providers
function docker_off() {
    echo "🛑 Turning off all Docker providers..."

    # Stop Docker Desktop if running
    if pgrep -f "Docker Desktop" &>/dev/null || pgrep -f "com.docker.docker" &>/dev/null; then
        echo "🐳 Stopping Docker Desktop..."
        osascript -e 'quit app "Docker Desktop"' 2>/dev/null || echo "⚠️  Could not stop Docker Desktop via AppleScript"
    fi

    # Stop Rancher Desktop if running
    if pgrep -f "Rancher Desktop" &>/dev/null || pgrep -f "rancher-desktop" &>/dev/null; then
        echo "🐄 Stopping Rancher Desktop..."
        osascript -e 'quit app "Rancher Desktop"' 2>/dev/null || echo "⚠️  Could not stop Rancher Desktop via AppleScript"
    fi

    # Clean up PATH
    export PATH="$(echo $PATH | sed 's|/Users/dheerajchand/.rd/bin:||g' | sed 's|/Applications/Docker.app/Contents/Resources/bin:||g')"

    # Set environment variables
    export CURRENT_DOCKER_PROVIDER="none"
    export DEFAULT_DOCKER_CONTEXT=""

    echo "✅ All Docker providers stopped"
}

# Function to switch to Rancher Desktop
function use_rancher() {
    echo "🐄 Switching to Rancher Desktop..."

    # First turn off Docker Desktop
    if pgrep -f "Docker Desktop" &>/dev/null || pgrep -f "com.docker.docker" &>/dev/null; then
        echo "🐳 Stopping Docker Desktop..."
        osascript -e 'quit app "Docker Desktop"' 2>/dev/null
        sleep 2
    fi

    # Start Rancher Desktop if not running
    if ! pgrep -f "Rancher Desktop" &>/dev/null && ! pgrep -f "rancher-desktop" &>/dev/null; then
        echo "🚀 Starting Rancher Desktop..."
        open -a "Rancher Desktop" 2>/dev/null || echo "⚠️  Could not start Rancher Desktop"
        echo "⏳ Waiting for Rancher Desktop to start..."
        sleep 5
    fi

    # Set Docker context
    if docker context ls | grep -q "$RANCHER_DOCKER_CONTEXT"; then
        docker context use "$RANCHER_DOCKER_CONTEXT" &>/dev/null
        echo "✅ Docker context set to: $RANCHER_DOCKER_CONTEXT"
    else
        echo "⚠️  Rancher Desktop context not found. Make sure Rancher Desktop is installed and running."
    fi
    
    # Update PATH to prioritize Rancher Desktop binaries (avoid duplicates)
    local rd_bin="/Users/dheerajchand/.rd/bin"
    # Remove any existing instances first
    export PATH="$(echo $PATH | sed 's|/Users/dheerajchand/.rd/bin:||g')"
    # Add to front only if directory exists
    if [[ -d "$rd_bin" ]]; then
        export PATH="$rd_bin:$PATH"
    fi
    
    # Set environment variables
    export CURRENT_DOCKER_PROVIDER="rancher"
    export DEFAULT_DOCKER_CONTEXT="$RANCHER_DOCKER_CONTEXT"
    
    echo "🎯 Current Docker provider: Rancher Desktop"
    docker version --format 'Client: {{.Client.Version}}' 2>/dev/null || echo "⚠️  Docker client not responding"
}

# Function to switch to Docker Desktop
function use_docker_desktop() {
    echo "🐳 Switching to Docker Desktop..."

    # First turn off Rancher Desktop
    if pgrep -f "Rancher Desktop" &>/dev/null || pgrep -f "rancher-desktop" &>/dev/null; then
        echo "🐄 Stopping Rancher Desktop..."
        osascript -e 'quit app "Rancher Desktop"' 2>/dev/null
        sleep 2
    fi

    # Start Docker Desktop if not running
    if ! pgrep -f "Docker Desktop" &>/dev/null && ! pgrep -f "com.docker.docker" &>/dev/null; then
        echo "🚀 Starting Docker Desktop..."
        open -a "Docker Desktop" 2>/dev/null || echo "⚠️  Could not start Docker Desktop"
        echo "⏳ Waiting for Docker Desktop to start..."
        sleep 5
    fi

    # Set Docker context
    if docker context ls | grep -q "$DOCKER_DESKTOP_CONTEXT"; then
        docker context use "$DOCKER_DESKTOP_CONTEXT" &>/dev/null
        echo "✅ Docker context set to: $DOCKER_DESKTOP_CONTEXT"
    else
        echo "⚠️  Docker Desktop context not found. Make sure Docker Desktop is installed and running."
    fi
    
    # Remove Rancher Desktop from PATH and add Docker Desktop paths
    export PATH="$(echo $PATH | sed 's|/Users/dheerajchand/.rd/bin:||g' | sed 's|/Applications/Docker.app/Contents/Resources/bin:||g')"

    # Add Docker Desktop paths if they exist and not already in PATH
    local docker_bin="/Applications/Docker.app/Contents/Resources/bin"
    if [[ -d "$docker_bin" ]] && [[ ":$PATH:" != *":$docker_bin:"* ]]; then
        export PATH="$docker_bin:$PATH"
    fi
    
    # Set environment variables
    export CURRENT_DOCKER_PROVIDER="docker-desktop"
    export DEFAULT_DOCKER_CONTEXT="$DOCKER_DESKTOP_CONTEXT"
    
    echo "🎯 Current Docker provider: Docker Desktop"
    docker version --format 'Client: {{.Client.Version}}' 2>/dev/null || echo "⚠️  Docker client not responding"
}

# Function to show current Docker configuration
function docker_status() {
    echo "🐳 Docker Configuration Status"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Current Provider: $CURRENT_DOCKER_PROVIDER"
    echo "Default Context: $DEFAULT_DOCKER_CONTEXT"

    # Show what's actually running
    local running_status=""
    if pgrep -f "Docker Desktop" &>/dev/null || pgrep -f "com.docker.docker" &>/dev/null; then
        running_status+="🐳 Docker Desktop (running) "
    fi
    if pgrep -f "Rancher Desktop" &>/dev/null || pgrep -f "rancher-desktop" &>/dev/null; then
        running_status+="🐄 Rancher Desktop (running) "
    fi

    if [[ -n "$running_status" ]]; then
        echo "Running: $running_status"
    else
        echo "Running: 🛑 None (all Docker providers off)"
    fi

    if command -v docker &>/dev/null; then
        echo ""
        echo "Active Context: $(docker context show 2>/dev/null || echo 'unknown')"
        echo "Docker Version: $(docker version --format 'Client: {{.Client.Version}}, Server: {{.Server.Version}}' 2>/dev/null || echo 'not available')"
        echo ""
        echo "Available Contexts:"
        docker context ls 2>/dev/null | grep -E "(NAME|rancher-desktop|desktop-linux)" || echo "No contexts available"
        echo ""
        echo "Commands:"
        echo "  dr / use_rancher      - Switch to Rancher Desktop"
        echo "  dd / use_docker_desktop - Switch to Docker Desktop"
        echo "  doff / docker_off     - Turn off both providers"
        echo "  dstatus / docker_status - Show this status"
    else
        echo "❌ Docker command not available"
    fi
}

# Function to reset Docker context to default (now means turn everything off)
function docker_reset() {
    echo "🔄 Resetting Docker to default configuration (all off)..."
    docker_off
}

# Show what Docker providers are currently running (but don't auto-switch)
function docker_auto_detect() {
    local running_providers=()

    # Check what's currently running
    if pgrep -f "Docker Desktop" &>/dev/null || pgrep -f "com.docker.docker" &>/dev/null; then
        running_providers+=("Docker Desktop")
    fi

    if pgrep -f "Rancher Desktop" &>/dev/null || pgrep -f "rancher-desktop" &>/dev/null; then
        running_providers+=("Rancher Desktop")
    fi

    # Report status without auto-switching
    if [[ ${#running_providers[@]} -eq 0 ]]; then
        echo "ℹ️  No Docker providers currently running"
        echo "💡 Use 'dr' for Rancher Desktop or 'dd' for Docker Desktop"
    elif [[ ${#running_providers[@]} -eq 1 ]]; then
        echo "ℹ️  Currently running: ${running_providers[1]}"
    else
        echo "⚠️  Multiple Docker providers running: ${(j:, :)running_providers}"
        echo "💡 Use 'docker_off' to stop all, then 'dr' or 'dd' to start one"
    fi
}

# Aliases for convenience
alias dr="use_rancher"
alias dd="use_docker_desktop"
alias doff="docker_off"
alias dstatus="docker_status"
alias dreset="docker_reset"

# Show Docker status on shell startup (but don't auto-switch)
docker_auto_detect
