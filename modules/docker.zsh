#!/usr/bin/env zsh
# =================================================================
# DOCKER - Container Management
# =================================================================
# Docker status, cleanup, and development helpers
# =================================================================

# Show Docker system status
docker_status() {
    echo "🐳 Docker Status"
    echo "==============="
    
    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker not installed"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker daemon not running"
        echo "💡 Start Docker Desktop"
        return 1
    fi
    
    echo "Version: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    echo ""
    
    # System info
    docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}"
    echo ""
    
    # Running containers
    local running=$(docker ps -q | wc -l | tr -d ' ')
    echo "Running containers: $running"
    
    if [[ $running -gt 0 ]]; then
        echo ""
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    fi
}

# Clean up Docker resources
docker_cleanup() {
    echo "🧹 Docker Cleanup"
    echo "================"
    
    # Show current usage
    docker system df
    echo ""
    
    # Remove stopped containers. `docker rm` returns 404 on some Desktop contexts.
    local stopped_count=$(docker ps -aq --filter "status=exited" | wc -l | tr -d '[:space:]')
    if [[ "$stopped_count" -gt 0 ]]; then
        echo "🗑️  Removing stopped containers..."
        docker container prune -f
    else
        echo "✅ No stopped containers"
    fi
    
    # Remove dangling images
    local dangling=$(docker images -qf "dangling=true")
    if [[ -n "$dangling" ]]; then
        echo "🗑️  Removing dangling images..."
        docker rmi $dangling
    else
        echo "✅ No dangling images"
    fi
    
    # Remove unused volumes
    echo "🗑️  Removing unused volumes..."
    docker volume prune -f
    
    echo ""
    echo "After cleanup:"
    docker system df
}

# Aggressive cleanup (includes volumes, networks)
docker_deep_clean() {
    echo "🧹 Deep Docker Cleanup"
    echo "===================="
    echo "⚠️  This will remove ALL unused resources"
    echo -n "Continue? (y/n): "
    read confirm
    
    if [[ "$confirm" != "y" ]]; then
        echo "Cancelled"
        return 0
    fi
    
    docker system prune -a --volumes -f
    echo "✅ Deep clean complete"
}

# Shell into running container
docker_shell() {
    local container="${1:-}"
    
    if [[ -z "$container" ]]; then
        echo "Usage: docker_shell <container>"
        echo ""
        echo "Running containers:"
        docker ps --format "{{.Names}}"
        return 1
    fi
    
    # Try bash first, fall back to sh
    docker exec -it "$container" bash 2>/dev/null || docker exec -it "$container" sh
}

# View container logs
docker_logs() {
    local container="${1:-}"
    
    if [[ -z "$container" ]]; then
        echo "Usage: docker_logs <container> [-f]"
        echo ""
        echo "Running containers:"
        docker ps --format "{{.Names}}"
        return 1
    fi
    
    docker logs "$container" "${@:2}"
}

# Restart container
docker_restart_container() {
    local container="${1:-}"
    
    if [[ -z "$container" ]]; then
        echo "Usage: docker_restart_container <container>"
        return 1
    fi
    
    docker restart "$container"
}

# Quick container run
docker_quick_run() {
    local image="${1:-ubuntu}"
    docker run -it --rm "$image" /bin/bash
}

# Aliases
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias dimg='docker images'
alias dstop='docker stop $(docker ps -q)'
alias dexec='docker exec -it'
alias dlogs='docker logs -f'

echo "✅ docker loaded"


