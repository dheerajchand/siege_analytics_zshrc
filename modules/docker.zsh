#!/usr/bin/env zsh
# =====================================================
# DOCKER MODULE - On-demand Docker management
# =====================================================

echo "🐳 Loading Docker module..."

# =====================================================
# DOCKER FUNCTIONS
# =====================================================

docker_status() {
    echo "🐳 Docker Status"
    echo "==============="

    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker not installed"
        return 1
    fi

    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker daemon not running"
        echo "💡 Start with: open -a Docker"
        return 1
    fi

    echo "✅ Docker daemon running"
    echo "Version: $(docker --version)"
    echo "Containers: $(docker ps -q | wc -l | tr -d ' ') running"
    echo "Images: $(docker images -q | wc -l | tr -d ' ') total"

    # Show running containers
    local running=$(docker ps --format "table {{.Names}}\t{{.Status}}")
    if [[ -n "$running" ]]; then
        echo ""
        echo "Running containers:"
        echo "$running"
    fi
}

docker_cleanup() {
    echo "🧹 Docker cleanup..."
    docker system prune -f
    echo "✅ Cleanup complete"
}

docker_quick_start() {
    local service="$1"
    case "$service" in
        "postgres"|"pg")
            docker run --name postgres-dev -e POSTGRES_PASSWORD=dev -p 5432:5432 -d postgres:15
            ;;
        "redis")
            docker run --name redis-dev -p 6379:6379 -d redis:7-alpine
            ;;
        "mongo")
            docker run --name mongo-dev -p 27017:27017 -d mongo:7
            ;;
        *)
            echo "Available services: postgres, redis, mongo"
            ;;
    esac
}

# =====================================================
# ALIASES
# =====================================================

alias dstatus='docker_status'
alias dps='docker ps'
alias dclean='docker_cleanup'
alias dstart='docker_quick_start'

echo "✅ Docker module loaded successfully"