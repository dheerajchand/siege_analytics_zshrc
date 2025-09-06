API Reference
=============

This section provides comprehensive documentation for all functions and modules in the Siege Analytics ZSH Configuration System. Each module is documented with function definitions, usage examples, and unit tests.

.. note::
   All functions support cross-shell compatibility (bash/zsh) and cross-platform operation (macOS/Linux/Docker/WSL) unless otherwise specified.

Core Modules
------------

These modules provide the foundation for all other functionality:

.. toctree::
   :maxdepth: 2

   core-functions
   platform-functions

The **Core Functions** module provides essential shell utilities, Python environment management, and data science workflow helpers. The **Platform Functions** module ensures consistent behavior across different shells and operating systems.

Data Processing and Analytics
----------------------------

Modules for big data processing, distributed computing, and analytics workflows:

.. toctree::
   :maxdepth: 2

   spark-functions
   hadoop-functions
   python-functions

The **Spark Functions** module provides Apache Spark cluster management and job submission with intelligent optimization. The **Hadoop Functions** module manages the complete Hadoop ecosystem including HDFS, YARN, and MapReduce. The **Python Functions** module handles Python environment switching, UV project management, and data science project initialization.

Development Infrastructure
--------------------------

Modules for development environments, containerization, and data storage:

.. toctree::
   :maxdepth: 2

   docker-functions
   database-functions

The **Docker Functions** module provides comprehensive container management with development-focused workflows. The **Database Functions** module offers secure connection management for PostgreSQL, MySQL, Snowflake, and other database systems.

Quick Start Guide
-----------------

**1. Basic Environment Setup**

.. code-block:: bash

   # Check system compatibility
   detect_platform
   # Output: macos, linux, docker, etc.
   
   # Setup Python environment
   py_env_switch list        # See available environments
   py_env_switch uv          # Activate UV project
   
   # Check system status
   system_info

**2. Data Science Workflow**

.. code-block:: bash

   # Create new data science project
   ds_project_init my_analysis spark
   cd my_analysis
   
   # Activate environment
   py_env_switch uv
   
   # Start big data stack
   start_hadoop              # Start Hadoop cluster
   spark_start              # Start Spark cluster
   
   # Submit Spark job
   smart_spark_submit analysis.py

**3. Container Development**

.. code-block:: bash

   # Setup development environment
   docker_dev_setup my_app --with-monitoring
   cd my_app
   
   # Start services
   docker_compose_dev up
   
   # Check health
   docker_health_check

**4. Database Integration**

.. code-block:: bash

   # Setup database credentials
   setup_postgres_credentials --interactive
   
   # Test connections
   db_test_all
   
   # Connect to database
   pg_connect

Function Reference by Category
-----------------------------

Core System Functions
~~~~~~~~~~~~~~~~~~~~~

**Shell and Platform:**
- :func:`detect_shell` - Identify current shell (bash/zsh)
- :func:`detect_platform` - Identify operating system and distribution
- :func:`is_container` - Check if running in Docker container
- :func:`command_exists` - Verify command availability
- :func:`is_online` - Check internet connectivity

**File and Directory Operations:**
- :func:`mkcd` - Create directory and change into it
- :func:`extract` - Universal archive extraction
- :func:`findtext` - Search text in files with multiple backends
- :func:`path_add` - Add directories to PATH safely
- :func:`lib_path_add` - Add library paths (platform-aware)

**System Utilities:**
- :func:`system_info` - Display comprehensive system information
- :func:`shell_startup_time` - Measure shell initialization performance
- :func:`reload_shell` - Reload configuration with feedback

Python and Data Science Functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Environment Management:**
- :func:`py_env_switch` - Switch between Python environments (PyEnv/UV)
- :func:`python_info` - Display Python environment status
- :func:`ds_project_init` - Initialize data science projects with dependencies

**Project Types:**
- Basic: pandas, numpy, matplotlib, seaborn, jupyter
- Spark: + pyspark, findspark  
- Geo: + geopandas, folium, contextily

**Integration:**
- Automatic environment detection on directory change
- UV project auto-activation
- PyEnv version file support

Big Data Processing Functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Apache Spark:**
- :func:`spark_start` / :func:`spark_stop` - Local cluster management
- :func:`spark_status` - Comprehensive cluster status
- :func:`default_spark_submit` - Local job submission
- :func:`distributed_spark_submit` - Cluster job submission
- :func:`smart_spark_submit` - Intelligent environment detection
- :func:`heavy_api_submit` - API-intensive workload optimization

**Apache Hadoop:**
- :func:`start_hadoop` / :func:`stop_hadoop` - Full ecosystem management
- :func:`hadoop_status` - HDFS and YARN status monitoring
- :func:`setup_hdfs_config` - HDFS configuration generation
- :func:`setup_yarn_config` - YARN resource management setup
- :func:`setup_java17_hadoop_compatibility` - Modern Java support

**Integration:**
- Automatic Hadoop-Spark classpath configuration
- Cross-platform service management
- Container-optimized resource allocation

Container and Development Functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Docker Management:**
- :func:`docker_status` - Comprehensive Docker system status
- :func:`docker_cleanup` - System cleanup (standard/aggressive modes)
- :func:`docker_dev_setup` - Complete development environment creation
- :func:`docker_build_optimized` - BuildKit-optimized image building

**Development Workflows:**
- :func:`docker_jupyter_spark` - Spark-enabled Jupyter in containers
- :func:`docker_database` - Quick database container deployment
- :func:`docker_compose_dev` - Enhanced Compose operations
- :func:`docker_health_check` - Service health monitoring

**Features:**
- Automatic port management and conflict resolution
- Health checks and dependency management
- Development-optimized configurations

Database Functions
~~~~~~~~~~~~~~~~~

**Connection Management:**
- :func:`setup_postgres_credentials` - Secure PostgreSQL credential setup
- :func:`setup_mysql_credentials` - MySQL connection configuration  
- :func:`setup_snowflake_credentials` - Snowflake data warehouse setup
- :func:`pg_connect` / :func:`mysql_connect` / :func:`snowflake_connect` - Database connections

**Operations:**
- :func:`db_test_all` - Test all configured database connections
- :func:`db_list_connections` - List available database connections
- :func:`pg_backup` - PostgreSQL backup with compression
- :func:`pg_status` - PostgreSQL server status and diagnostics

**Security:**
- Integrated credential management system
- Secure password storage (system keychain)
- No plain-text credential storage

Cross-Platform Compatibility Functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Platform Operations:**
- :func:`platform_open` - Open files/URLs with system default
- :func:`platform_copy` / :func:`platform_paste` - Clipboard operations
- :func:`platform_browser` - Launch URLs in default browser

**Shell Compatibility:**
- :func:`add_chdir_hook` - Directory change hooks (bash/zsh)
- :func:`array_expand` - Cross-shell array expansion
- :func:`assoc_array_set` / :func:`assoc_array_get` - Associative arrays
- :func:`word_split` - Handle word splitting differences

**Package Management:**
- :func:`detect_package_managers` - Find available package managers
- Supports: apt, yum, dnf, pacman, brew, npm, pip, uv

Module Integration Examples
--------------------------

**Complete Data Science Stack:**

.. code-block:: bash

   # 1. Platform detection and setup
   echo "Platform: $(detect_platform)"
   echo "Shell: $(detect_shell)"
   
   # 2. Python environment
   ds_project_init big_data_analysis spark
   cd big_data_analysis
   py_env_switch uv
   
   # 3. Big data infrastructure
   start_hadoop
   spark_start
   
   # 4. Database setup
   setup_postgres_credentials --interactive
   docker_database postgres --init-sql schema.sql
   
   # 5. Run analysis
   smart_spark_submit data_pipeline.py

**Container-Based Development:**

.. code-block:: bash

   # 1. Development environment
   docker_dev_setup microservice_api --with-monitoring
   cd microservice_api
   
   # 2. Start all services
   docker_compose_dev up
   
   # 3. Monitor health
   docker_health_check
   
   # 4. Database integration
   docker_database postgres --name api-db
   
   # 5. Check system status
   docker_status
   db_test_all

**Cross-Platform Deployment:**

.. code-block:: bash

   # 1. Platform-aware setup
   case "$(detect_platform)" in
       "macos")
           path_add "/opt/homebrew/bin" before
           ;;
       "linux-ubuntu")
           sudo apt update && sudo apt install -y python3-venv
           ;;
       "docker")
           export SPARK_DRIVER_MEMORY="1g"  # Container optimization
           ;;
   esac
   
   # 2. Universal operations
   py_env_switch uv
   if is_online; then
       uv sync --upgrade
   else
       uv sync --offline
   fi

Environment Variables
--------------------

The system exports numerous environment variables for integration:

**Platform Detection:**
- ``CURRENT_SHELL`` - Current shell (zsh, bash, unknown)
- ``ZSH_PLATFORM`` - Platform (macos, linux, docker, wsl)
- ``ZSH_IS_DOCKER`` - Container status (true/false)
- ``AVAILABLE_PACKAGE_MANAGERS`` - Available package managers

**Module Status:**
- ``CORE_MODULE_LOADED`` - Core module loaded
- ``SPARK_MODULE_LOADED`` - Spark module loaded
- ``HADOOP_MODULE_LOADED`` - Hadoop module loaded
- ``DOCKER_MODULE_LOADED`` - Docker module loaded

**Application Paths:**
- ``SPARK_HOME`` - Apache Spark installation
- ``HADOOP_HOME`` - Hadoop installation
- ``JAVA_HOME`` - Java installation (via SDKMAN)

**Development Configuration:**
- ``DOCKER_BUILDKIT`` - BuildKit enabled (1)
- ``COMPOSE_DOCKER_CLI_BUILD`` - Compose CLI build (1)

Testing Framework
----------------

All modules include comprehensive unit tests. Run tests with:

.. code-block:: bash

   # Test core functions
   test_command_exists
   test_mkcd_basic
   test_py_env_list
   
   # Test platform functions
   test_platform_detection
   test_shell_detection
   test_container_detection
   
   # Test data processing
   test_spark_environment_setup
   test_hadoop_environment_setup
   
   # Test integration
   test_hadoop_spark_integration

**Test Categories:**

- **Unit Tests**: Individual function testing
- **Integration Tests**: Module interaction testing
- **Platform Tests**: Cross-platform compatibility
- **Container Tests**: Docker environment testing
- **Security Tests**: Credential management testing

Performance Considerations
-------------------------

**Startup Optimization:**
- Lazy loading of heavy modules (Spark, Hadoop)
- Conditional path additions
- Cached environment detection
- Minimal shell hooks

**Resource Management:**
- Container-aware memory settings
- Platform-specific optimizations
- Automatic cleanup functions
- Health monitoring

**Security Best Practices:**
- Encrypted credential storage
- No plain-text secrets in configuration
- Secure environment variable handling
- Audit trail for credential access

Troubleshooting
--------------

**Common Issues:**

1. **Module Not Loading:**

   .. code-block:: bash
   
      # Check module status
      echo $SPARK_MODULE_LOADED
      
      # Manual reload
      source ~/.config/zsh/config/spark.zsh

2. **Path Issues:**

   .. code-block:: bash
   
      # Check PATH
      echo $PATH | tr ':' '\n'
      
      # Add missing paths
      path_add "/usr/local/bin"

3. **Container Detection:**

   .. code-block:: bash
   
      # Verify container detection
      echo "Container: $ZSH_IS_DOCKER"
      echo "Platform: $ZSH_PLATFORM"

4. **Database Connection Issues:**

   .. code-block:: bash
   
      # Test connections
      db_test_all
      
      # Check credentials
      setup_postgres_credentials --interactive

**Debug Mode:**

.. code-block:: bash

   # Enable verbose output
   export MODULAR_ZSHRC_VERBOSE="true"
   
   # Reload configuration
   source ~/.zshrc

This comprehensive API reference provides everything needed to use and extend the Siege Analytics ZSH Configuration System for data science, development, and system administration workflows.