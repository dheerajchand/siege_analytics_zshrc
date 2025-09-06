Docker Functions API Reference
===============================

This module provides comprehensive Docker and container management utilities with cross-platform support, development-focused shortcuts, and integration with data science workflows.

.. note::
   All functions support Docker Desktop (macOS/Windows) and Docker Engine (Linux) with automatic environment detection and BuildKit optimization.

Environment Setup Functions
---------------------------

setup_docker_environment()
~~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Configure Docker environment variables, detect Docker installation, and set up development-optimized settings.

.. code-block:: bash

   setup_docker_environment()

**Examples and Elaboration:**

This function is automatically called when the Docker module loads:

.. code-block:: bash

   # Manual environment setup (usually automatic)
   setup_docker_environment
   
   # Check Docker configuration
   echo "Docker Config: $DOCKER_CONFIG"
   # Output: Docker Config: /Users/username/.docker
   
   echo "BuildKit enabled: $DOCKER_BUILDKIT"
   # Output: BuildKit enabled: 1
   
   echo "Compose CLI Build: $COMPOSE_DOCKER_CLI_BUILD"
   # Output: Compose CLI Build: 1

Platform-specific configurations:

**macOS (Docker Desktop):**
- Sets `DOCKER_CONFIG` to `$HOME/.docker`
- Detects Docker Desktop at `/Applications/Docker.app`
- Exports `DOCKER_DESKTOP_PATH` for desktop operations

**Linux (Docker Engine):**
- Sets `DOCKER_CONFIG` to `$HOME/.docker`
- Checks Docker service status via systemctl or service command
- Sets `DOCKER_SERVICE_ACTIVE=true` if running

**Docker Compose Detection:**
- `DOCKER_COMPOSE_AVAILABLE=true` for standalone docker-compose
- `DOCKER_COMPOSE_AVAILABLE=v2` for built-in `docker compose`

Development optimizations enabled:
- `DOCKER_BUILDKIT=1` - Modern build system
- `COMPOSE_DOCKER_CLI_BUILD=1` - Use Docker CLI for Compose builds

**Unit Tests:**

.. code-block:: bash

   # Test: Docker environment setup
   test_docker_environment_setup() {
       setup_docker_environment
       [[ -n "$DOCKER_CONFIG" ]] && [[ "$DOCKER_BUILDKIT" == "1" ]]
   }
   
   # Test: Docker availability check
   test_docker_availability() {
       setup_docker_environment
       command -v docker >/dev/null 2>&1
   }

Status and Information Functions
-------------------------------

docker_status()
~~~~~~~~~~~~~~

**Function Definition:**

Display comprehensive Docker status including daemon health, version information, and system resources.

.. code-block:: bash

   docker_status()

**Examples and Elaboration:**

.. code-block:: bash

   docker_status
   # Output:
   # 🐳 Docker Status
   # ===============
   # 
   # Configuration:
   #   Docker Version: 24.0.6
   #   Docker Config: /Users/username/.docker
   #   BuildKit: 1
   #   Compose Version: 2.21.0
   # 
   # System Resources:
   #   CPUs: 8
   #   Memory: 7.67 GiB
   #   Disk: 59.6 GB
   # 
   # Container Status:
   #   Running: 3
   #   Stopped: 7
   #   Total: 10
   # 
   # Image Status:
   #   Images: 15
   #   Size: 4.2 GB
   # 
   # Network Status:
   #   Networks: 4
   #   Volumes: 8

When Docker is not available:

.. code-block:: bash

   docker_status
   # Output:
   # 🐳 Docker Status
   # ===============
   # 
   # ❌ Docker daemon not running
   #    Start Docker daemon or Docker Desktop

Information displayed:

1. **Configuration**: Version, config paths, BuildKit status
2. **System Resources**: Available CPUs, memory, disk space  
3. **Container Status**: Running, stopped, and total containers
4. **Image Status**: Number of images and total size
5. **Network Status**: Networks and volumes count

**Unit Tests:**

.. code-block:: bash

   # Test: Status command execution
   test_docker_status_execution() {
       docker_status >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }
   
   # Test: Status shows version info
   test_docker_status_version() {
       if command -v docker >/dev/null 2>&1; then
           docker_status | grep -q "Docker Version"
       else
           return 0  # Skip if Docker not available
       fi
   }

Container Management Functions
-----------------------------

docker_cleanup()
~~~~~~~~~~~~~~~~

**Function Definition:**

Comprehensive Docker cleanup including stopped containers, unused images, networks, volumes, and build cache.

.. code-block:: bash

   docker_cleanup [--aggressive]

**Examples and Elaboration:**

.. code-block:: bash

   # Standard cleanup (safe)
   docker_cleanup
   # Output:
   # 🧹 Docker Cleanup
   # =================
   # 
   # 🗑️  Removing stopped containers...
   # Deleted Containers:
   # abc123def456
   # 789ghi012jkl
   # 
   # 🗑️  Removing unused images...
   # Deleted Images:
   # untagged: old-image:latest
   # deleted: sha256:1234567890abcdef...
   # 
   # 🗑️  Removing unused networks...
   # 🗑️  Removing unused volumes...
   # 🗑️  Removing build cache...
   # 
   # ✅ Cleanup complete!
   # 💾 Space reclaimed: 2.3 GB

   # Aggressive cleanup (removes all unused data)
   docker_cleanup --aggressive
   # Output:
   # 🧹 Docker Aggressive Cleanup
   # ============================
   # ⚠️  This will remove ALL unused data!
   # Continue? (y/n): y
   # 
   # [More comprehensive cleanup output]
   # ✅ Aggressive cleanup complete!
   # 💾 Space reclaimed: 5.7 GB

Cleanup operations performed:

**Standard Cleanup:**
- Stopped containers
- Unused images (dangling)
- Unused networks  
- Unused volumes (anonymous)
- Build cache (older than 24h)

**Aggressive Cleanup:**
- All unused containers (not just stopped)
- All unused images (including tagged but unused)
- All unused networks and volumes
- All build cache
- System prune with `--all` flag

**Unit Tests:**

.. code-block:: bash

   # Test: Cleanup execution
   test_docker_cleanup() {
       if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
           docker_cleanup >/dev/null 2>&1
           [[ $? -eq 0 ]]
       else
           return 0  # Skip if Docker not available
       fi
   }

docker_logs_tail()
~~~~~~~~~~~~~~~~~

**Function Definition:**

Advanced container log viewing with filtering, following, and multi-container support.

.. code-block:: bash

   docker_logs_tail [container] [lines] [follow]

**Examples and Elaboration:**

.. code-block:: bash

   # View last 50 lines of container logs
   docker_logs_tail my-app
   # Output: [Last 50 log lines from my-app container]
   
   # View specific number of lines
   docker_logs_tail my-app 100
   # Output: [Last 100 log lines]
   
   # Follow logs in real-time
   docker_logs_tail my-app 20 follow
   # Output: [Last 20 lines, then continues streaming new logs]
   
   # Interactive container selection
   docker_logs_tail
   # Output:
   # 📋 Available containers:
   # 1) my-app (running)
   # 2) database (running) 
   # 3) redis (running)
   # Select container (1-3): 1
   # [Shows logs from selected container]

Features:

- **Auto-completion**: Lists running containers for selection
- **Smart defaults**: 50 lines by default, can be customized
- **Real-time following**: Streams new log entries
- **Color preservation**: Maintains container log formatting
- **Error handling**: Gracefully handles non-existent containers

**Unit Tests:**

.. code-block:: bash

   # Test: Log viewing function exists
   test_docker_logs_function() {
       type docker_logs_tail >/dev/null 2>&1
   }
   
   # Test: Container selection works
   test_docker_logs_container_selection() {
       # Would need running containers to test properly
       docker_logs_tail nonexistent 2>&1 | grep -q "not found\|No such container"
   }

Development Workflow Functions
-----------------------------

docker_dev_setup()
~~~~~~~~~~~~~~~~~~

**Function Definition:**

Create a complete Docker development environment with common services (database, cache, monitoring).

.. code-block:: bash

   docker_dev_setup [project-name] [--with-spark] [--with-monitoring]

**Examples and Elaboration:**

.. code-block:: bash

   # Basic development setup
   docker_dev_setup my-project
   # Output:
   # 🚀 Setting up Docker development environment: my-project
   # 📁 Creating project structure...
   # 📝 Generating docker-compose.yml...
   # 📝 Creating Dockerfile...
   # 🌐 Creating development services:
   #    ✅ PostgreSQL database
   #    ✅ Redis cache
   #    ✅ Application container
   # 
   # 🎯 Next steps:
   #    cd my-project
   #    docker-compose up -d

   # Setup with Apache Spark
   docker_dev_setup data-project --with-spark
   # Output:
   # 🚀 Setting up Docker development environment: data-project
   # [Standard setup...]
   # ⚡ Adding Apache Spark services:
   #    ✅ Spark Master
   #    ✅ Spark Worker
   #    ✅ Jupyter Notebook with Spark

   # Setup with monitoring stack
   docker_dev_setup api-project --with-monitoring
   # Output:
   # 🚀 Setting up Docker development environment: api-project
   # [Standard setup...]
   # 📊 Adding monitoring services:
   #    ✅ Prometheus metrics
   #    ✅ Grafana dashboards
   #    ✅ Redis Exporter

Generated project structure:

.. code-block:: text

   my-project/
   ├── docker-compose.yml         # Service definitions
   ├── Dockerfile                # Application container
   ├── .dockerignore             # Docker ignore patterns
   ├── .env.example              # Environment template
   ├── scripts/
   │   ├── wait-for-it.sh       # Service dependency script
   │   └── init-db.sql          # Database initialization
   └── config/
       ├── nginx.conf           # Web server config
       └── postgres.conf        # Database config

**Unit Tests:**

.. code-block:: bash

   # Test: Development setup creation
   test_docker_dev_setup() {
       local test_project="test-docker-project"
       docker_dev_setup "$test_project"
       [[ -f "$test_project/docker-compose.yml" ]] && [[ -f "$test_project/Dockerfile" ]]
       rm -rf "$test_project"
   }

docker_build_optimized()
~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Build Docker images with BuildKit optimizations, multi-stage caching, and development best practices.

.. code-block:: bash

   docker_build_optimized [image-name] [--target stage] [--push] [--cache-from image]

**Examples and Elaboration:**

.. code-block:: bash

   # Optimized build with BuildKit
   docker_build_optimized my-app
   # Output:
   # 🔨 Optimized Docker Build: my-app
   # =====================================
   # 
   # Build Configuration:
   #   BuildKit: ✅ Enabled
   #   Multi-stage: ✅ Detected
   #   Cache: ✅ Inline cache enabled
   # 
   # [Build progress with enhanced output]
   # ✅ Build complete: my-app:latest

   # Build specific stage
   docker_build_optimized my-app --target development
   # Output:
   # 🔨 Building stage: development
   # [Build output for development stage only]

   # Build and push to registry
   docker_build_optimized my-app --push
   # Output:
   # 🔨 Building and pushing: my-app
   # [Build output]
   # 🚀 Pushing to registry...
   # ✅ Push complete

Build optimizations applied:

- **BuildKit**: Modern build system with parallel layers
- **Inline Cache**: `--cache-from type=inline` for better caching
- **Multi-stage Support**: Builds only required stages
- **Progress Output**: Enhanced build progress display
- **Security**: Runs builds with security scanning if available

**Unit Tests:**

.. code-block:: bash

   # Test: Build function execution
   test_docker_build_optimized() {
       # Create minimal Dockerfile for testing
       mkdir -p test-build
       echo "FROM alpine:latest" > test-build/Dockerfile
       cd test-build
       docker_build_optimized test-image >/dev/null 2>&1
       local result=$?
       cd .. && rm -rf test-build
       [[ $result -eq 0 ]]
   }

docker_compose_dev()
~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Enhanced docker-compose operations with development-focused profiles, health checks, and log management.

.. code-block:: bash

   docker_compose_dev [command] [--profile profile-name]

**Examples and Elaboration:**

.. code-block:: bash

   # Start development environment
   docker_compose_dev up
   # Output:
   # 🚀 Starting development environment...
   # 📋 Services: app, database, redis, nginx
   # 🔍 Health checks enabled
   # 
   # [Container startup logs]
   # ✅ All services healthy!

   # Start with specific profile
   docker_compose_dev up --profile monitoring
   # Output:
   # 🚀 Starting with profile: monitoring
   # 📋 Services: app, database, redis, prometheus, grafana
   # [Startup output]

   # View aggregated logs
   docker_compose_dev logs
   # Output: [Colored logs from all services]

   # Scale services
   docker_compose_dev scale app=3
   # Output:
   # ⚡ Scaling app to 3 instances...
   # ✅ Scaling complete

Enhanced features:

- **Health Checks**: Monitors service health and dependencies
- **Development Profiles**: Different service combinations (dev, test, prod)
- **Log Aggregation**: Colored, timestamped logs from all services  
- **Auto-reload**: File watching for development
- **Service Dependencies**: Proper startup ordering

**Unit Tests:**

.. code-block:: bash

   # Test: Compose dev function exists
   test_docker_compose_dev_function() {
       type docker_compose_dev >/dev/null 2>&1
   }

Data Science Integration Functions
---------------------------------

docker_jupyter_spark()
~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Launch Jupyter Lab with Apache Spark in a Docker container, pre-configured for data science workflows.

.. code-block:: bash

   docker_jupyter_spark [port] [--spark-master url] [--mount-data path]

**Examples and Elaboration:**

.. code-block:: bash

   # Start Jupyter with Spark (default port 8888)
   docker_jupyter_spark
   # Output:
   # 🔬 Starting Jupyter Lab with Apache Spark
   # ==========================================
   # 
   # Container Configuration:
   #   Jupyter Port: 8888
   #   Spark UI Port: 4040
   #   Data Mount: ./data -> /home/jovyan/work/data
   # 
   # 🚀 Starting container...
   # ✅ Jupyter Lab ready at: http://localhost:8888
   # 🔗 Access token: abc123def456...

   # Custom port and data directory
   docker_jupyter_spark 9999 --mount-data ~/datasets
   # Output:
   # 🔬 Starting Jupyter Lab with Apache Spark
   # Container Configuration:
   #   Jupyter Port: 9999
   #   Data Mount: /Users/user/datasets -> /home/jovyan/work/data
   # ✅ Jupyter Lab ready at: http://localhost:9999

   # Connect to external Spark cluster
   docker_jupyter_spark 8888 --spark-master spark://cluster:7077
   # Output:
   # 🔬 Connecting to external Spark cluster
   # Spark Master: spark://cluster:7077
   # [Container startup...]

Features:

- **Pre-installed Libraries**: pandas, numpy, matplotlib, seaborn, pyspark
- **Data Mounting**: Automatic mounting of data directories
- **Spark Integration**: Pre-configured Spark session
- **Port Management**: Automatic port conflict resolution
- **Token Display**: Shows access token for easy connection

**Unit Tests:**

.. code-block:: bash

   # Test: Jupyter Spark function
   test_docker_jupyter_spark_function() {
       type docker_jupyter_spark >/dev/null 2>&1
   }

docker_database()
~~~~~~~~~~~~~~~~

**Function Definition:**

Quick database container deployment with initialization scripts and data persistence.

.. code-block:: bash

   docker_database [type] [--name container-name] [--port port] [--init-sql file]

**Examples and Elaboration:**

.. code-block:: bash

   # Start PostgreSQL database
   docker_database postgres
   # Output:
   # 🗄️  Starting PostgreSQL database
   # ===============================
   # 
   # Configuration:
   #   Type: PostgreSQL 15
   #   Port: 5432
   #   Database: dev_db
   #   Username: postgres
   #   Password: postgres
   # 
   # 🚀 Starting container: postgres-dev
   # ✅ Database ready!
   # 
   # Connection:
   #   Host: localhost:5432
   #   Database: dev_db
   #   URL: postgresql://postgres:postgres@localhost:5432/dev_db

   # Start MySQL with custom settings
   docker_database mysql --name my-mysql --port 3307
   # Output:
   # 🗄️  Starting MySQL database
   # Container: my-mysql
   # Port: 3307
   # ✅ MySQL ready at localhost:3307

   # Start with initialization script
   docker_database postgres --init-sql schema.sql
   # Output:
   # 🗄️  Starting PostgreSQL with initialization
   # 📜 Loading schema.sql...
   # ✅ Database initialized and ready!

Supported database types:

- **PostgreSQL**: Latest stable with common extensions
- **MySQL**: Latest stable with development configuration
- **MongoDB**: Latest with authentication disabled for development
- **Redis**: Latest with persistence enabled

**Unit Tests:**

.. code-block:: bash

   # Test: Database function execution
   test_docker_database_function() {
       type docker_database >/dev/null 2>&1
   }

Monitoring and Debugging Functions
----------------------------------

docker_health_check()
~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Comprehensive health monitoring for Docker containers with detailed diagnostics and remediation suggestions.

.. code-block:: bash

   docker_health_check [container-name]

**Examples and Elaboration:**

.. code-block:: bash

   # Check all containers
   docker_health_check
   # Output:
   # 🏥 Docker Health Check
   # =====================
   # 
   # Container Health Status:
   #   ✅ my-app: healthy (up 2 hours)
   #   ⚠️  database: unhealthy (failing health check)
   #   ❌ redis: exited (code 1, 5 minutes ago)
   # 
   # System Resources:
   #   CPU Usage: 45%
   #   Memory Usage: 3.2GB / 8GB (40%)
   #   Disk Usage: 12GB / 60GB (20%)
   # 
   # Recommendations:
   #   • database: Check connection string configuration
   #   • redis: Review logs for startup errors

   # Check specific container
   docker_health_check my-app
   # Output:
   # 🏥 Health Check: my-app
   # ======================
   # 
   # Container Status:
   #   State: running
   #   Health: healthy
   #   Uptime: 2h 15m
   #   Restarts: 0
   # 
   # Resource Usage:
   #   CPU: 2.3%
   #   Memory: 234MB / 512MB (45%)
   # 
   # Port Mappings:
   #   8080:80 (accessible)
   #   5432:5432 (accessible)
   # 
   # ✅ All checks passed!

**Unit Tests:**

.. code-block:: bash

   # Test: Health check execution
   test_docker_health_check() {
       docker_health_check >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }

Aliases and Shortcuts
--------------------

The module provides convenient aliases for all major Docker operations:

.. code-block:: bash

   # Container management
   dps              # docker ps
   dpsa             # docker ps -a
   dimg             # docker images
   drm              # docker rm
   drmi             # docker rmi
   
   # Docker Compose shortcuts
   dcup             # docker-compose up -d
   dcdown           # docker-compose down
   dcbuild          # docker-compose build
   dclogs           # docker-compose logs -f
   dcrestart        # docker-compose restart
   
   # Development shortcuts
   ddev             # docker_dev_setup
   djupyter         # docker_jupyter_spark
   ddb              # docker_database
   dcleanup         # docker_cleanup
   
   # Monitoring
   dstatus          # docker_status
   dhealthcheck     # docker_health_check
   dlogs            # docker_logs_tail

Complete Usage Examples
----------------------

**Example 1: Complete development environment setup**

.. code-block:: bash

   # Create new project with full stack
   docker_dev_setup my-api --with-monitoring
   cd my-api
   
   # Start all services
   docker_compose_dev up
   
   # Check health status
   docker_health_check
   
   # View aggregated logs
   docker_compose_dev logs

**Example 2: Data science workflow**

.. code-block:: bash

   # Start Jupyter with Spark
   docker_jupyter_spark 8888 --mount-data ~/datasets
   
   # Start supporting databases
   docker_database postgres --name analytics-db
   docker_database redis --name cache
   
   # Check all services are healthy
   docker_health_check

**Example 3: Container maintenance**

.. code-block:: bash

   # Check overall system status
   docker_status
   
   # Clean up unused resources
   docker_cleanup
   
   # Monitor specific container
   docker_logs_tail my-app 100 follow

**Example 4: Production deployment preparation**

.. code-block:: bash

   # Build optimized production image
   docker_build_optimized my-app --target production --push
   
   # Test with production profile
   docker_compose_dev up --profile production
   
   # Health check before deployment
   docker_health_check
   
   # Final cleanup
   docker_cleanup --aggressive

Integration with Other Modules
-----------------------------

**With Spark Module:**

.. code-block:: bash

   # Container-aware Spark configuration
   if [[ "$ZSH_IS_DOCKER" == "true" ]]; then
       export SPARK_DRIVER_MEMORY="1g"    # Container optimized
   fi
   
   # Start Spark in container
   docker_jupyter_spark
   
   # Connect to external Spark cluster
   spark_start
   docker_jupyter_spark 8888 --spark-master $SPARK_MASTER_URL

**With Python Module:**

.. code-block:: bash

   # Container-based data science project
   ds_project_init analytics_project
   cd analytics_project
   
   # Create Docker environment
   docker_dev_setup . --with-spark
   
   # Start development environment  
   docker_compose_dev up

**With Database Module:**

.. code-block:: bash

   # Quick database for development
   docker_database postgres --init-sql schema.sql
   
   # Connect from host applications
   export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/dev_db"

This comprehensive Docker module provides everything needed for modern containerized development workflows, from simple container management to complex multi-service environments with monitoring and optimization.