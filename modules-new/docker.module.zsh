#!/usr/bin/env zsh
# =====================================================
# DOCKER MODULE - Container management and development
# =====================================================
#
# Purpose: Docker container management and quick development setup
# Provides: container operations, quick starts, cleanup
# Dependencies: centralized variables
# =====================================================

echo "🐳 Loading Docker module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# DOCKER FUNCTIONS
# =====================================================

# Purpose: Show Docker system status and information
# Arguments: None
# Returns: 0 on success, 1 if Docker unavailable
# Usage: docker_status
docker_status() {
    echo "🐳 Docker System Status"
    echo "======================"

    if ! command -v docker >/dev/null 2>&1; then
        echo "❌ Docker: Not installed"
        return 1
    fi

    # Docker version and status
    echo "✅ Docker: $(docker --version)"

    if docker info >/dev/null 2>&1; then
        echo "✅ Docker daemon: Running"

        # Container statistics
        local running=$(docker ps -q | wc -l | tr -d ' ')
        local total=$(docker ps -a -q | wc -l | tr -d ' ')
        echo "📦 Containers: $running running, $total total"

        # Image count
        local images=$(docker images -q | wc -l | tr -d ' ')
        echo "💿 Images: $images"

        # Disk usage
        echo "💾 Disk usage:"
        docker system df | tail -n +2 | sed 's/^/  /'
    else
        echo "❌ Docker daemon: Not running"
        return 1
    fi
}

# Purpose: Quick start development containers
# Arguments: $1 - service name (postgres, redis, mongo)
# Returns: 0 on success, 1 on error
# Usage: docker_quick_start postgres
docker_quick_start() {
    local service="$1"

    if [[ -z "$service" ]]; then
        echo "💡 Usage: docker_quick_start <service>"
        echo "📋 Available services: postgres, redis, mongo"
        return 1
    fi

    case "$service" in
        "postgres"|"pg")
            echo "🐘 Starting PostgreSQL container..."
            docker run --name postgres-dev \
                -e POSTGRES_PASSWORD="$DOCKER_POSTGRES_PASSWORD" \
                -p "$DOCKER_POSTGRES_PORT:5432" \
                -d "$DOCKER_POSTGRES_IMAGE"
            ;;
        "redis")
            echo "🔴 Starting Redis container..."
            docker run --name redis-dev \
                -p "$DOCKER_REDIS_PORT:6379" \
                -d "$DOCKER_REDIS_IMAGE"
            ;;
        "mongo")
            echo "🌿 Starting MongoDB container..."
            docker run --name mongo-dev \
                -p "$DOCKER_MONGO_PORT:27017" \
                -d "$DOCKER_MONGO_IMAGE"
            ;;
        *)
            echo "❌ Unknown service: $service"
            echo "📋 Available: postgres, redis, mongo"
            return 1
            ;;
    esac

    echo "✅ $service container started"
    echo "💡 Use 'docker ps' to check status"
}

# Purpose: Comprehensive Docker system cleanup
# Arguments: None
# Returns: 0 always
# Usage: docker_cleanup
docker_cleanup() {
    echo "🧹 Docker System Cleanup"
    echo "========================"

    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker daemon not running"
        return 1
    fi

    echo "🗑️  Removing stopped containers..."
    docker container prune -f

    echo "🗑️  Removing unused images..."
    docker image prune -f

    echo "🗑️  Removing unused networks..."
    docker network prune -f

    echo "🗑️  Removing unused volumes..."
    docker volume prune -f

    echo "✅ Docker cleanup complete"
    docker_status
}

# =====================================================
# ALIASES
# =====================================================

alias dstatus='docker_status'
alias dps='docker ps'
alias dclean='docker_cleanup'
alias dstart='docker_quick_start'

echo "✅ Docker module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export DOCKER_MODULE_LOADED=true