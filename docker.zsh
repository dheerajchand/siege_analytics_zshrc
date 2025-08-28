# =====================================================
# DOCKER CONTEXT SWITCHING UTILITIES
# =====================================================
# Switch between Rancher Desktop and Docker Desktop

# Docker context configuration
export RANCHER_DOCKER_CONTEXT="rancher-desktop"
export DOCKER_DESKTOP_CONTEXT="desktop-linux"

# Current context tracking
export CURRENT_DOCKER_PROVIDER="${CURRENT_DOCKER_PROVIDER:-rancher}"

# Function to switch to Rancher Desktop
function use_rancher() {
    echo "🐄 Switching to Rancher Desktop..."
    
    # Set Docker context
    if docker context ls | grep -q "$RANCHER_DOCKER_CONTEXT"; then
        docker context use "$RANCHER_DOCKER_CONTEXT" &>/dev/null
        echo "✅ Docker context set to: $RANCHER_DOCKER_CONTEXT"
    else
        echo "⚠️  Rancher Desktop context not found. Make sure Rancher Desktop is installed and running."
    fi
    
    # Update PATH to prioritize Rancher Desktop binaries
    export PATH="/Users/dheerajchand/.rd/bin:$(echo $PATH | sed 's|/Users/dheerajchand/.rd/bin:||g')"
    
    # Set environment variables
    export CURRENT_DOCKER_PROVIDER="rancher"
    export DEFAULT_DOCKER_CONTEXT="$RANCHER_DOCKER_CONTEXT"
    
    echo "🎯 Current Docker provider: Rancher Desktop"
    docker version --format 'Client: {{.Client.Version}}' 2>/dev/null || echo "⚠️  Docker client not responding"
}

# Function to switch to Docker Desktop
function use_docker_desktop() {
    echo "🐳 Switching to Docker Desktop..."
    
    # Set Docker context
    if docker context ls | grep -q "$DOCKER_DESKTOP_CONTEXT"; then
        docker context use "$DOCKER_DESKTOP_CONTEXT" &>/dev/null
        echo "✅ Docker context set to: $DOCKER_DESKTOP_CONTEXT"
    else
        echo "⚠️  Docker Desktop context not found. Make sure Docker Desktop is installed and running."
    fi
    
    # Remove Rancher Desktop from PATH and add Docker Desktop paths
    export PATH="$(echo $PATH | sed 's|/Users/dheerajchand/.rd/bin:||g')"
    
    # Add Docker Desktop paths if they exist
    if [[ -d "/Applications/Docker.app/Contents/Resources/bin" ]]; then
        export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
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
    
    if command -v docker &>/dev/null; then
        echo ""
        echo "Active Context: $(docker context show 2>/dev/null || echo 'unknown')"
        echo "Docker Version: $(docker version --format 'Client: {{.Client.Version}}, Server: {{.Server.Version}}' 2>/dev/null || echo 'not available')"
        echo ""
        echo "Available Contexts:"
        docker context ls 2>/dev/null | grep -E "(NAME|rancher-desktop|desktop-linux)" || echo "No contexts available"
    else
        echo "❌ Docker command not available"
    fi
}

# Function to reset Docker context to default
function docker_reset() {
    echo "🔄 Resetting Docker to default configuration..."
    
    case "$CURRENT_DOCKER_PROVIDER" in
        "rancher")
            use_rancher
            ;;
        "docker-desktop")
            use_docker_desktop
            ;;
        *)
            echo "🐄 Defaulting to Rancher Desktop..."
            use_rancher
            ;;
    esac
}

# Auto-detect and set initial Docker provider based on what's running
function docker_auto_detect() {
    # Check if Docker Desktop is running
    if pgrep -f "Docker Desktop" &>/dev/null || pgrep -f "com.docker.docker" &>/dev/null; then
        if [[ "$CURRENT_DOCKER_PROVIDER" != "docker-desktop" ]]; then
            echo "🔍 Auto-detected Docker Desktop running, switching..."
            use_docker_desktop
        fi
    # Check if Rancher Desktop is running
    elif pgrep -f "Rancher Desktop" &>/dev/null || pgrep -f "rancher-desktop" &>/dev/null; then
        if [[ "$CURRENT_DOCKER_PROVIDER" != "rancher" ]]; then
            echo "🔍 Auto-detected Rancher Desktop running, switching..."
            use_rancher
        fi
    else
        # Default to current provider or Rancher if none set
        if [[ -z "$CURRENT_DOCKER_PROVIDER" ]]; then
            use_rancher
        fi
    fi
}

# Aliases for convenience
alias dr="use_rancher"
alias dd="use_docker_desktop"  
alias dstatus="docker_status"
alias dreset="docker_reset"

# Initialize Docker context on shell startup
docker_auto_detect
