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
# ADVANCED DOCKER FEATURES
# =====================================================

# Purpose: Create development environment with Docker Compose
# Arguments: $1 - environment type (fullstack, api, data)
# Returns: 0 on success, 1 on error
# Usage: docker_create_env fullstack
docker_create_env() {
    local env_type="$1"

    if [[ -z "$env_type" ]]; then
        echo "💡 Usage: docker_create_env <type>"
        echo "📋 Available types: fullstack, api, data, custom"
        return 1
    fi

    if [[ -f "docker-compose.yml" ]]; then
        echo "❌ docker-compose.yml already exists"
        return 1
    fi

    echo "🏗️  Creating Docker development environment: $env_type"
    echo "================================================"

    case "$env_type" in
        "fullstack")
            cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: app_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  app:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - redis
    environment:
      - DATABASE_URL=postgresql://postgres:dev_password@postgres:5432/app_db
      - REDIS_URL=redis://redis:6379
    volumes:
      - .:/app
      - /app/node_modules

volumes:
  postgres_data:
EOF
            echo "✅ Full-stack environment created"
            echo "💡 Includes: PostgreSQL, Redis, Application container"
            ;;

        "api")
            cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: api_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  api:
    build: .
    ports:
      - "8000:8000"
    depends_on:
      - postgres
    environment:
      - DATABASE_URL=postgresql://postgres:dev_password@postgres:5432/api_db
    volumes:
      - .:/app

volumes:
  postgres_data:
EOF
            echo "✅ API environment created"
            echo "💡 Includes: PostgreSQL, API container"
            ;;

        "data")
            cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: dev_password
      POSTGRES_DB: data_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  jupyter:
    image: jupyter/datascience-notebook:latest
    ports:
      - "8888:8888"
    environment:
      - JUPYTER_ENABLE_LAB=yes
    volumes:
      - .:/home/jovyan/work
    command: start-notebook.sh --NotebookApp.token=''

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
EOF
            echo "✅ Data science environment created"
            echo "💡 Includes: PostgreSQL, Jupyter Lab, Redis"
            ;;

        "custom")
            cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - .:/app
EOF
            echo "✅ Custom environment template created"
            echo "💡 Customize docker-compose.yml as needed"
            ;;

        *)
            echo "❌ Unknown environment type: $env_type"
            return 1
            ;;
    esac

    # Create .env file
    cat > .env << 'EOF'
# Development Environment Variables
POSTGRES_PASSWORD=dev_password
POSTGRES_DB=app_db
DATABASE_URL=postgresql://postgres:dev_password@localhost:5432/app_db
REDIS_URL=redis://localhost:6379
EOF

    echo ""
    echo "🚀 Next steps:"
    echo "  docker-compose up -d     # Start services in background"
    echo "  docker-compose logs -f   # View logs"
    echo "  docker-compose down      # Stop services"
}

# Purpose: Monitor Docker containers with live updates
# Arguments: None
# Returns: 0 always
# Usage: docker_monitor
docker_monitor() {
    echo "📊 Docker Container Monitor (press Ctrl+C to exit)"
    echo "================================================"

    while true; do
        clear
        echo "🐳 Docker Status - $(date)"
        echo "========================="

        if docker info >/dev/null 2>&1; then
            # Container status
            echo "📦 Running Containers:"
            if docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | head -10; then
                :
            else
                echo "  No containers running"
            fi

            echo ""
            echo "💾 System Resources:"
            docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | head -6

            echo ""
            echo "💿 Disk Usage:"
            docker system df --format "table {{.Type}}\t{{.Total}}\t{{.Size}}\t{{.Reclaimable}}"
        else
            echo "❌ Docker daemon not running"
        fi

        sleep 5
    done
}

# Purpose: Execute command in running container with auto-detection
# Arguments: $1 - container name pattern, $@ - command to execute
# Returns: Command exit code
# Usage: docker_exec web bash
docker_exec() {
    local container_pattern="$1"
    shift

    if [[ -z "$container_pattern" ]]; then
        echo "💡 Usage: docker_exec <container_name_pattern> <command>"
        echo "📋 Running containers:"
        docker ps --format "  {{.Names}}"
        return 1
    fi

    # Find matching container
    local container=$(docker ps --format "{{.Names}}" | grep "$container_pattern" | head -1)

    if [[ -z "$container" ]]; then
        echo "❌ No running container found matching: $container_pattern"
        echo "📋 Available containers:"
        docker ps --format "  {{.Names}}"
        return 1
    fi

    echo "🔗 Executing in container: $container"
    echo "📜 Command: $*"
    echo ""

    docker exec -it "$container" "$@"
}

# =====================================================
# ALIASES
# =====================================================

alias dstatus='docker_status'
alias dps='docker ps'
alias dclean='docker_cleanup'
alias dstart='docker_quick_start'
alias denv='docker_create_env'
alias dmon='docker_monitor'
alias dexec='docker_exec'

echo "✅ Docker module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export DOCKER_MODULE_LOADED=true