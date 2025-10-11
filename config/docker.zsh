#!/usr/bin/env zsh

# =====================================================
# DOCKER MODULE
# =====================================================
# 
# Docker and container management utilities
# Provides cross-platform Docker operations
# Includes development-focused shortcuts and utilities
# =====================================================

# Module identification
export DOCKER_MODULE_LOADED="true"

# =====================================================
# DOCKER/RANCHER CONTEXT MANAGEMENT
# =====================================================

# Set default container runtime (docker-desktop or rancher-desktop)
# Changed to docker-desktop as default per user preference
export DEFAULT_CONTAINER_RUNTIME="${DEFAULT_CONTAINER_RUNTIME:-docker-desktop}"

# Rancher Desktop administrator mode (requires elevated privileges for some features)
# Set to "true" to always run Rancher with admin privileges
export RANCHER_ADMIN_MODE="${RANCHER_ADMIN_MODE:-true}"

start_rancher_desktop() {
    # Start Rancher Desktop with optional administrator privileges
    # Usage: start_rancher_desktop [admin]

    local use_admin="${1:-$RANCHER_ADMIN_MODE}"

    if [[ "$use_admin" == "true" ]]; then
        echo "🔐 Starting Rancher Desktop with administrator privileges..."
        echo "   (You may be prompted for your password)"

        # Start Rancher Desktop with sudo to grant elevated privileges
        # This allows Rancher to manage system-level networking and volumes
        sudo -b open -a "Rancher Desktop" 2>/dev/null

        if [[ $? -eq 0 ]]; then
            echo "✅ Rancher Desktop started with admin privileges"
        else
            echo "⚠️  Admin start failed, trying normal mode..."
            open -a "Rancher Desktop" 2>/dev/null
        fi
    else
        echo "🐄 Starting Rancher Desktop (normal mode)..."
        open -a "Rancher Desktop" 2>/dev/null
    fi
}

switch_docker_context() {
    local context="${1:-$DEFAULT_CONTAINER_RUNTIME}"

    case "$context" in
        "rancher-desktop"|"rancher")
            echo "🐄 Switching to Rancher Desktop..."
            docker context use rancher-desktop 2>/dev/null

            if docker info >/dev/null 2>&1; then
                echo "✅ Rancher Desktop is ready"
                export CURRENT_DOCKER_CONTEXT="rancher-desktop"
            else
                echo "⚠️  Rancher Desktop not ready, attempting to start..."
                start_rancher_desktop
                
                # Wait for Rancher Desktop to start
                local timeout=30
                while ! docker info >/dev/null 2>&1 && [[ $timeout -gt 0 ]]; do
                    sleep 2
                    ((timeout--))
                    echo "⏳ Waiting for Rancher Desktop to start... ($timeout seconds remaining)"
                done
                
                if docker info >/dev/null 2>&1; then
                    echo "✅ Rancher Desktop started successfully"
                    export CURRENT_DOCKER_CONTEXT="rancher-desktop"
                else
                    echo "❌ Rancher Desktop failed to start, trying Docker Desktop..."
                    docker context use desktop-linux 2>/dev/null
                    open -a Docker 2>/dev/null
                    
                    # Wait for Docker Desktop to start
                    timeout=30
                    while ! docker info >/dev/null 2>&1 && [[ $timeout -gt 0 ]]; do
                        sleep 2
                        ((timeout--))
                        echo "⏳ Waiting for Docker Desktop to start... ($timeout seconds remaining)"
                    done
                    
                    if docker info >/dev/null 2>&1; then
                        echo "✅ Docker Desktop started successfully"
                        export CURRENT_DOCKER_CONTEXT="desktop-linux"
                    else
                        echo "❌ Both Rancher Desktop and Docker Desktop failed to start"
                        return 1
                    fi
                fi
            fi
            ;;
        "docker-desktop"|"docker")
            echo "🐳 Switching to Docker Desktop..."
            docker context use desktop-linux 2>/dev/null
            
            if docker info >/dev/null 2>&1; then
                echo "✅ Docker Desktop is ready"
                export CURRENT_DOCKER_CONTEXT="desktop-linux"
            else
                echo "⚠️  Docker Desktop not ready, attempting to start..."
                open -a Docker 2>/dev/null
                
                # Wait for Docker Desktop to start
                local timeout=30
                while ! docker info >/dev/null 2>&1 && [[ $timeout -gt 0 ]]; do
                    sleep 2
                    ((timeout--))
                    echo "⏳ Waiting for Docker Desktop to start... ($timeout seconds remaining)"
                done
                
                if docker info >/dev/null 2>&1; then
                    echo "✅ Docker Desktop started successfully"
                    export CURRENT_DOCKER_CONTEXT="desktop-linux"
                else
                    echo "❌ Docker Desktop failed to start, trying Rancher Desktop..."
                    docker context use rancher-desktop 2>/dev/null
                    start_rancher_desktop

                    # Wait for Rancher Desktop to start
                    timeout=30
                    while ! docker info >/dev/null 2>&1 && [[ $timeout -gt 0 ]]; do
                        sleep 2
                        ((timeout--))
                        echo "⏳ Waiting for Rancher Desktop to start... ($timeout seconds remaining)"
                    done

                    if docker info >/dev/null 2>&1; then
                        echo "✅ Rancher Desktop started successfully"
                        export CURRENT_DOCKER_CONTEXT="rancher-desktop"
                    else
                        echo "❌ Both Docker Desktop and Rancher Desktop failed to start"
                        return 1
                    fi
                fi
            fi
            ;;
        *)
            echo "❌ Unknown context: $context"
            echo "Available contexts: rancher-desktop, docker-desktop"
            return 1
            ;;
    esac
}

# Auto-switch to preferred runtime on module load
auto_switch_docker_context() {
    if [[ -n "$DEFAULT_CONTAINER_RUNTIME" ]]; then
        switch_docker_context "$DEFAULT_CONTAINER_RUNTIME"
    fi
}

# =====================================================
# SMART DEPENDENCY MANAGEMENT
# =====================================================

ensure_docker_available() {
    # Smart function to ensure Docker is available and running
    # Tries to start Docker if it's installed but not running
    
    # Check if Docker command exists
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker not installed. Installing via Homebrew..."
        if command -v brew >/dev/null 2>&1; then
            brew install docker
            # Default: Install Docker Desktop (preferred on macOS)
            brew install --cask docker
            echo "✅ Docker installed. Please start Docker Desktop manually."
            return 1
        else
            echo "❌ Homebrew not found. Please install Docker manually."
            return 1
        fi
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        echo "🔄 Docker daemon not running. Attempting to start..."
        
        # First try to switch to preferred context
        auto_switch_docker_context
        
        # If still not working, try to start the appropriate service
        if ! docker info >/dev/null 2>&1; then
            case "$OSTYPE" in
                darwin*)
                    # macOS: Try to start the preferred container runtime
                    case "$DEFAULT_CONTAINER_RUNTIME" in
                        "rancher-desktop")
                            echo "🐄 Starting Rancher Desktop..."
                            start_rancher_desktop || echo "⚠️  Rancher Desktop not found"
                            ;;
                        "docker-desktop"|*)
                            echo "🐳 Starting Docker Desktop..."
                            open -a Docker 2>/dev/null || echo "⚠️  Docker Desktop not found"
                            ;;
                    esac
                    echo "⏳ Waiting for container runtime to start..."
                    local timeout=30
                    while ! docker info >/dev/null 2>&1 && [[ $timeout -gt 0 ]]; do
                        sleep 2
                        ((timeout--))
                    done
                    
                    if docker info >/dev/null 2>&1; then
                        echo "✅ Docker started successfully"
                        return 0
                    else
                        echo "❌ Docker failed to start within timeout"
                        return 1
                    fi
                ;;
            linux*)
                # Linux: Try to start Docker service
                if command -v systemctl >/dev/null 2>&1; then
                    sudo systemctl start docker
                elif command -v service >/dev/null 2>&1; then
                    sudo service docker start
                else
                    echo "❌ Cannot start Docker service - no systemctl or service command"
                    return 1
                fi
                
                # Wait for Docker to be ready
                local timeout=15
                while ! docker info >/dev/null 2>&1 && [[ $timeout -gt 0 ]]; do
                    sleep 1
                    ((timeout--))
                done
                
                if docker info >/dev/null 2>&1; then
                    echo "✅ Docker service started"
                    return 0
                else
                    echo "❌ Docker service failed to start"
                    return 1
                fi
                ;;
        esac
        fi
    fi
    
    return 0
}

# =====================================================
# DOCKER DETECTION & SETUP
# =====================================================

setup_docker_environment() {
    # Configure Docker environment
    
    # Use smart dependency management
    if ! ensure_docker_available; then
        [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "⚠️  Docker not available - functions will be limited"
        return 1
    fi
    
    # Platform-specific Docker configurations
    case "$ZSH_PLATFORM" in
        "macos")
            # macOS Docker Desktop paths
            export DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
            
            # Check for Docker Desktop
            if [[ -d "/Applications/Docker.app" ]]; then
                export DOCKER_DESKTOP_PATH="/Applications/Docker.app"
            fi
            ;;
            
        "linux")
            # Linux Docker configurations
            export DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
            
            # Check for Docker service
            if systemctl is-active --quiet docker 2>/dev/null; then
                export DOCKER_SERVICE_ACTIVE="true"
            elif command -v service >/dev/null 2>&1 && service docker status >/dev/null 2>&1; then
                export DOCKER_SERVICE_ACTIVE="true"
            fi
            ;;
    esac
    
    # Check Docker Compose
    if command -v docker-compose >/dev/null 2>&1; then
        export DOCKER_COMPOSE_AVAILABLE="true"
    elif docker compose version >/dev/null 2>&1; then
        export DOCKER_COMPOSE_AVAILABLE="v2"
    fi
    
    # Note: Docker build configuration variables are defined in main zshrc centralized section:
    # - DOCKER_BUILDKIT, COMPOSE_DOCKER_CLI_BUILD
}

# =====================================================
# DOCKER UTILITY FUNCTIONS
# =====================================================

docker_status() {
    # Show comprehensive Docker status
    echo "🐳 Docker Status"
    echo "==============="
    echo ""
    
    # Check Docker availability
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker command not found"
        echo "   Install Docker: https://docs.docker.com/get-docker/"
        return 1
    fi
    
    # Check Docker daemon
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker daemon not running"
        echo "   Start Docker daemon or Docker Desktop"
        return 1
    fi
    
    echo "Configuration:"
    echo "  Docker Version: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    echo "  Docker Config: ${DOCKER_CONFIG:-Not set}"
    echo "  BuildKit: ${DOCKER_BUILDKIT:-Not set}"
    
    if [[ "$DOCKER_COMPOSE_AVAILABLE" == "true" ]]; then
        echo "  Compose Version: $(docker-compose --version | cut -d' ' -f3 | tr -d ',')"
    elif [[ "$DOCKER_COMPOSE_AVAILABLE" == "v2" ]]; then
        echo "  Compose Version: $(docker compose version --short)"
    else
        echo "  Compose: Not available"
    fi
    
    echo ""
    
    # Show Docker system info
    echo "System Information:"
    docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}"
    echo ""
    
    # Show running containers
    local running_count=$(docker ps -q | wc -l | tr -d ' ')
    echo "Containers:"
    echo "  Running: $running_count"
    
    if [[ $running_count -gt 0 ]]; then
        echo ""
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    fi
}

docker_cleanup() {
    # Clean up Docker resources
    echo "🧹 Docker Cleanup"
    echo "=================="
    echo ""
    
    # Show current usage
    echo "Current usage:"
    docker system df
    echo ""
    
    # Remove stopped containers
    local stopped_containers=$(docker ps -aq --filter "status=exited")
    if [[ -n "$stopped_containers" ]]; then
        echo "🗑️  Removing stopped containers..."
        docker rm $stopped_containers
    else
        echo "✅ No stopped containers to remove"
    fi
    
    # Remove dangling images
    local dangling_images=$(docker images -qf "dangling=true")
    if [[ -n "$dangling_images" ]]; then
        echo "🗑️  Removing dangling images..."
        docker rmi $dangling_images
    else
        echo "✅ No dangling images to remove"
    fi
    
    # Remove unused networks
    echo "🗑️  Removing unused networks..."
    docker network prune -f >/dev/null 2>&1 || true
    
    # Remove unused volumes (with confirmation)
    local unused_volumes=$(docker volume ls -qf "dangling=true")
    if [[ -n "$unused_volumes" ]]; then
        echo "⚠️  Found unused volumes. Remove them? (y/n)"
        read "remove_volumes?"
        if [[ "$remove_volumes" == "y" ]]; then
            docker volume rm $unused_volumes
        fi
    else
        echo "✅ No unused volumes found"
    fi
    
    echo ""
    echo "After cleanup:"
    docker system df
}

docker_deep_clean() {
    # Aggressive Docker cleanup (removes everything)
    echo "⚠️  DEEP CLEAN WARNING ⚠️"
    echo "This will remove:"
    echo "• All stopped containers"
    echo "• All unused networks"
    echo "• All unused images"
    echo "• All unused volumes"
    echo "• Build cache"
    echo ""
    echo "Continue? (y/N)"
    read "confirm?"
    
    if [[ "$confirm" != "y" ]]; then
        echo "Canceled"
        return 0
    fi
    
    echo "🧹 Performing deep clean..."
    docker system prune -af --volumes
    echo "✅ Deep clean completed"
}

# =====================================================
# CONTAINER MANAGEMENT
# =====================================================

docker_shell() {
    # Interactive shell into running container
    local container_name="$1"
    local shell="${2:-bash}"
    
    if [[ -z "$container_name" ]]; then
        echo "Usage: docker_shell <container_name> [shell]"
        echo ""
        echo "Available containers:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
        return 1
    fi
    
    # Check if container exists and is running
    if ! docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        echo "❌ Container '$container_name' not found or not running"
        return 1
    fi
    
    echo "🐚 Opening $shell shell in $container_name..."
    docker exec -it "$container_name" "$shell" || {
        # Fallback to sh if bash fails
        echo "   Bash not available, trying sh..."
        docker exec -it "$container_name" sh
    }
}

docker_logs() {
    # Enhanced log viewing for containers
    local container_name="$1"
    local lines="${2:-100}"
    local follow="${3:-false}"
    
    if [[ -z "$container_name" ]]; then
        echo "Usage: docker_logs <container_name> [lines] [follow]"
        echo "Example: docker_logs myapp 50 true"
        echo ""
        echo "Available containers:"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
        return 1
    fi
    
    local log_cmd="docker logs --tail $lines"
    [[ "$follow" == "true" ]] && log_cmd="$log_cmd -f"
    
    echo "📜 Logs for $container_name (last $lines lines):"
    $log_cmd "$container_name"
}

docker_restart_container() {
    # Restart a specific container
    local container_name="$1"
    
    if [[ -z "$container_name" ]]; then
        echo "Usage: docker_restart_container <container_name>"
        echo ""
        echo "Available containers:"
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
        return 1
    fi
    
    echo "🔄 Restarting container: $container_name"
    docker restart "$container_name"
    echo "✅ Container restarted"
}

# =====================================================
# DEVELOPMENT UTILITIES
# =====================================================

docker_dev_env() {
    # Quick development environment setup
    local language="${1:-node}"
    local port="${2:-3000}"
    local volume_mount="${3:-$(pwd):/app}"
    
    case "$language" in
        "node"|"nodejs")
            echo "🚀 Starting Node.js development environment..."
            docker run -it --rm \
                -v "$volume_mount" \
                -p "$port:$port" \
                -w /app \
                node:18-alpine sh
            ;;
        "python")
            echo "🚀 Starting Python development environment..."
            docker run -it --rm \
                -v "$volume_mount" \
                -p "$port:$port" \
                -w /app \
                python:3.11-slim bash
            ;;
        "go"|"golang")
            echo "🚀 Starting Go development environment..."
            docker run -it --rm \
                -v "$volume_mount" \
                -p "$port:$port" \
                -w /app \
                golang:1.21-alpine sh
            ;;
        "java")
            echo "🚀 Starting Java development environment..."
            docker run -it --rm \
                -v "$volume_mount" \
                -p "$port:$port" \
                -w /app \
                openjdk:17-slim bash
            ;;
        *)
            echo "❌ Unsupported language: $language"
            echo "Supported: node, python, go, java"
            return 1
            ;;
    esac
}

docker_quick_run() {
    # Quick container run with common options
    local image="$1"
    shift
    local args="$@"
    
    if [[ -z "$image" ]]; then
        echo "Usage: docker_quick_run <image> [additional_args...]"
        echo "Example: docker_quick_run nginx -p 8080:80"
        return 1
    fi
    
    echo "🏃 Quick run: $image"
    docker run -it --rm \
        -v "$(pwd):/workspace" \
        -w /workspace \
        $args \
        "$image"
}

# =====================================================
# DOCKER COMPOSE UTILITIES
# =====================================================

docker_compose_cmd() {
    # Universal docker-compose command (handles v1 and v2)
    if [[ "$DOCKER_COMPOSE_AVAILABLE" == "true" ]]; then
        docker-compose "$@"
    elif [[ "$DOCKER_COMPOSE_AVAILABLE" == "v2" ]]; then
        docker compose "$@"
    else
        echo "❌ Docker Compose not available"
        return 1
    fi
}

docker_compose_dev() {
    # Development-friendly compose operations
    local action="${1:-up}"
    local service="${2:-}"
    
    case "$action" in
        "up")
            echo "🚀 Starting development environment..."
            docker_compose_cmd up -d $service
            ;;
        "down")
            echo "🛑 Stopping development environment..."
            docker_compose_cmd down
            ;;
        "restart")
            echo "🔄 Restarting services..."
            docker_compose_cmd restart $service
            ;;
        "logs")
            echo "📜 Following logs..."
            docker_compose_cmd logs -f $service
            ;;
        "shell")
            if [[ -z "$service" ]]; then
                echo "Usage: docker_compose_dev shell <service_name>"
                return 1
            fi
            echo "🐚 Opening shell in $service..."
            docker_compose_cmd exec $service bash || docker_compose_cmd exec $service sh
            ;;
        "rebuild")
            echo "🏗️ Rebuilding and restarting..."
            docker_compose_cmd down
            docker_compose_cmd build --no-cache $service
            docker_compose_cmd up -d $service
            ;;
        *)
            echo "Usage: docker_compose_dev <action> [service]"
            echo "Actions: up, down, restart, logs, shell, rebuild"
            return 1
            ;;
    esac
}

# =====================================================
# DOCKER NETWORKING
# =====================================================

docker_network_info() {
    # Show Docker network information
    echo "🌐 Docker Networks"
    echo "=================="
    echo ""
    
    echo "Available networks:"
    docker network ls
    echo ""
    
    echo "Network details:"
    local networks=($(docker network ls --format "{{.Name}}" | grep -v "^bridge$\|^host$\|^none$"))
    
    for network in "${networks[@]}"; do
        echo ""
        echo "📡 $network:"
        docker network inspect "$network" --format "  Type: {{.Driver}}"
        docker network inspect "$network" --format "  Subnet: {{range .IPAM.Config}}{{.Subnet}}{{end}}"
        
        # Show connected containers
        local containers=$(docker network inspect "$network" --format "{{range \$k,\$v := .Containers}}{{.Name}} {{end}}")
        if [[ -n "$containers" ]]; then
            echo "  Containers: $containers"
        fi
    done
}

docker_network_create() {
    # Create a development network
    local network_name="${1:-dev-network}"
    local subnet="${2:-172.20.0.0/16}"
    
    if docker network ls | grep -q "$network_name"; then
        echo "✅ Network '$network_name' already exists"
    else
        echo "🌐 Creating network: $network_name ($subnet)"
        docker network create --subnet="$subnet" "$network_name"
        echo "✅ Network created"
    fi
}

# =====================================================
# DOCKER ALIASES
# =====================================================

# Container runtime switching
alias docker-switch-rancher="switch_docker_context rancher-desktop"
alias docker-switch-docker="switch_docker_context docker-desktop"
alias docker-context="docker context ls"
alias docker-status="docker info | head -10"

# Direct runtime starting (with fallback)
alias start-rancher="switch_docker_context rancher-desktop"
alias start-docker="switch_docker_context docker-desktop"

alias d='docker'
alias dc='docker_compose_cmd'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dlog='docker_logs'
alias dex='docker_shell'
alias dclean='docker_cleanup'
alias dstatus='docker_status'
alias drestart='docker_restart_container'

# Docker Compose aliases
alias dcup='docker_compose_dev up'
alias dcdown='docker_compose_dev down'
alias dcrestart='docker_compose_dev restart'
alias dclogs='docker_compose_dev logs'
alias dcshell='docker_compose_dev shell'
alias dcrebuild='docker_compose_dev rebuild'

# Development aliases
alias ddev='docker_dev_env'
alias drun='docker_quick_run'
alias dnet='docker_network_info'

# =====================================================
# CONTAINER DETECTION UTILITIES
# =====================================================

is_in_container() {
    # Check if currently running inside a container
    [[ "$ZSH_IS_DOCKER" == "true" ]] || [[ -f /.dockerenv ]] || grep -q container /proc/1/cgroup 2>/dev/null
}

container_host_info() {
    # Show information about container host
    if is_in_container; then
        echo "📦 Running inside container"
        
        # Show container ID if available
        local container_id=""
        if [[ -f /proc/self/cgroup ]]; then
            container_id=$(grep docker /proc/self/cgroup | head -n1 | sed 's/.*\/docker\///' | cut -c1-12 2>/dev/null)
            [[ -n "$container_id" ]] && echo "Container ID: $container_id"
        fi
        
        # Show mounted volumes
        if command -v mount >/dev/null 2>&1; then
            echo ""
            echo "Mounted volumes:"
            mount | grep -E "^/dev/|docker" | head -5
        fi
    else
        echo "🖥️  Running on host system"
    fi
}

# =====================================================
# INITIALIZATION
# =====================================================

# Setup Docker environment
setup_docker_environment

# Show setup status if verbose
if [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && command -v docker >/dev/null 2>&1; then
    local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "unknown")
    echo "🐳 Docker: $docker_version"
    
    # Show if running in container
    if [[ "$ZSH_IS_DOCKER" == "true" ]]; then
        echo "   📦 Running inside container"
    fi
fi