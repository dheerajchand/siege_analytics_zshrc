# =====================================================
# COMPREHENSIVE HELP MODULE
# =====================================================

# Enhanced help system with module-specific help and function listings
export HELP_MODULE_LOADED=true

# Main help function with module support
function zsh_help {
    # Main help function providing comprehensive assistance for the zsh configuration system.
    #
    # This function serves as the central entry point for all help-related operations.
    # It can display general help, module-specific help, or function-specific help
    # depending on the arguments provided.
    #
    # Args:
    #     module (str, optional): Module name to get help for. Defaults to "all".
    #                            Valid values: core, spark, python, utilities, backup,
    #                            hadoop, docker, notebooks, environment, sync, test,
    #                            list, search, usage, modules
    #     subcommand (str, optional): Specific function or subcommand to get help for.
    #                                  Used with module names for detailed function help.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Examples:
    #     zsh_help                    # Show main help overview
    #     zsh_help spark             # Show Spark module help
    #     zsh_help backup sync       # Show sync function help in backup module
    #     zsh_help list              # List all available functions
    #     zsh_help search backup     # Search for backup-related functions
    #     zsh_help modules           # List available modules
    local module="${1:-all}"
    local subcommand="${2:-}"
    
    case "$module" in
        "all"|"")
            show_main_help
            ;;
        "core"|"core.zsh")
            show_core_help "$subcommand"
            ;;
        "spark"|"spark.zsh")
            show_spark_help "$subcommand"
            ;;
        "python"|"python.zsh")
            show_python_help "$subcommand"
            ;;
        "utilities"|"utilities.zsh")
            show_utilities_help "$subcommand"
            ;;
        "backup"|"backup-system.zsh")
            show_backup_help "$subcommand"
            ;;
        "hadoop"|"hadoop.zsh")
            show_hadoop_help "$subcommand"
            ;;
        "docker"|"docker.zsh")
            show_docker_help "$subcommand"
            ;;
        "notebooks"|"notebooks.zsh")
            show_notebooks_help "$subcommand"
            ;;
        "environment"|"environment.zsh")
            show_environment_help "$subcommand"
            ;;
        "sync"|"sync-system")
            show_sync_help "$subcommand"
            ;;
        "test"|"testing")
            show_testing_help "$subcommand"
            ;;
        "list"|"functions")
            list_all_functions
            ;;
        "search"|"find")
            search_functions "$subcommand"
            ;;
        "usage"|"examples")
            show_usage_examples "$subcommand"
            ;;
        "modules")
            list_available_modules
            ;;
        *)
            echo "❌ Unknown module: $module"
            echo "💡 Use 'zsh_help modules' to see available modules"
            echo "💡 Use 'zsh_help all' for general help"
            return 1
            ;;
    esac
}

# Show main help overview
function show_main_help {
    # Display the main help overview for the enhanced zsh configuration system.
    #
    # This function provides a comprehensive overview of all available modules,
    # help commands, and usage examples. It serves as the starting point for
    # users exploring the system's capabilities.
    #
    # Args:
    #     None
    #
    # Returns:
    #     None (displays formatted help overview)
    #         
    # Information Displayed:
    #     - List of available modules with descriptions
    #     - Help command syntax and usage
    #     - Practical examples for common operations
    #         
    # Example:
    #     show_main_help
    #     # Output:
    #     # 🚀 Enhanced ZSH Configuration Help
    #     # ==================================
    #     # 📚 Available Modules:
    #     #    core        - Core configuration functions
    #     #    spark       - Spark & Big Data functions
    #     #    ...
    echo "🚀 Enhanced ZSH Configuration Help"
    echo "=================================="
    echo ""
    echo "📚 Available Modules:"
    echo "   core        - Core configuration functions"
    echo "   spark       - Spark & Big Data functions"
    echo "   python      - Python environment management"
    echo "   utilities   - macOS utility functions"
    echo "   backup      - Backup and sync system"
    echo "   hadoop      - Hadoop integration"
    echo "   docker      - Docker management"
    echo "   notebooks   - Jupyter notebook integration"
    echo "   environment - Environment variables"
    echo "   sync        - Repository sync system"
    echo "   test        - Testing and validation"
    echo ""
    echo "🔍 Help Commands:"
    echo "   zsh_help <module>           - Show help for specific module"
    echo "   zsh_help <module> <function> - Show help for specific function"
    echo "   zsh_help list               - List all available functions"
    echo "   zsh_help search <term>      - Search functions by name/description"
    echo "   zsh_help usage <function>   - Show usage examples"
    echo "   zsh_help modules            - List available modules"
    echo ""
    echo "💡 Examples:"
    echo "   zsh_help spark              - Show Spark module help"
    echo "   zsh_help backup sync        - Show backup sync help"
    echo "   zsh_help search backup      - Search for backup functions"
    echo "   zsh_help usage pyspark_shell - Show pyspark_shell usage"
}

# Show core module help
function show_core_help {
    # Display help information for the core module.
    #
    # This function shows all available functions in the core module, including
    # configuration management, health checks, testing, and diagnostic functions.
    # If a subcommand is provided, it shows detailed help for that specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Core Functions:
    #     - zsh_help: Comprehensive help system
    #     - zshconfig: Edit configuration directory
    #     - zshreboot: Reload configuration
    #     - zsh_health_check: Quick health check
    #     - zsh_test_all: Run comprehensive tests
    #     - zsh_diagnostic_report: Generate diagnostic report
    #         
    # Example:
    #     show_core_help              # Show core module overview
    #     show_core_help zshconfig   # Show detailed help for zshconfig function
    local subcommand="$1"
    
    echo "🔧 Core Module Help"
    echo "==================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   zsh_help [module] [function] - Show comprehensive help"
        echo "   zshconfig                   - Edit configuration directory"
        echo "   zshreboot                   - Reload configuration"
        echo "   zsh_health_check            - Quick health check"
        echo "   zsh_test_all                - Run comprehensive tests"
        echo "   zsh_diagnostic_report       - Generate diagnostic report"
        echo "   discover_functions          - Find all available functions"
        echo "   function_help <function>    - Get help for specific function"
        echo ""
        echo "💡 Use 'zsh_help core <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show Spark module help
function show_spark_help {
    # Display help information for the Spark module.
    #
    # This function shows all available functions in the Spark module, including
    # shell launching, dependency management, testing, and utility functions.
    # If a subcommand is provided, it shows detailed help for that specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Spark Functions:
    #     - pyspark_shell: Launch Python Spark shell
    #     - spark_shell_scala: Launch Scala Spark shell
    #     - smart_spark_shell: Intelligent shell selection
    #     - heavy_api_shell: High-memory shell
    #     - test_spark_dependencies: Test Spark setup
    #     - list_local_jars: List available JARs
    #         
    # Dependencies:
    #     - Java 17+
    #     - Spark 3.5.3+
    #     - Python 3.8+
    #     - Scala 2.12+
    #         
    # Example:
    #     show_spark_help              # Show Spark module overview
    #     show_spark_help pyspark_shell # Show detailed help for pyspark_shell
    local subcommand="$1"
    
    echo "⚡ Spark Module Help"
    echo "===================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   pyspark_shell [port] [memory]     - Launch Python Spark shell"
        echo "   spark_shell_scala [port] [memory] - Launch Scala Spark shell"
        echo "   smart_spark_shell                 - Intelligent shell selection"
        echo "   heavy_api_shell [memory]          - High-memory shell"
        echo "   test_spark_dependencies           - Test Spark setup"
        echo "   test_spark_shells                 - Test shell launching"
        echo "   list_local_jars                   - List available JARs"
        echo "   get_spark_jars                    - Get Spark JAR paths"
        echo "   get_python_files                  - Get Python file paths"
        echo "   check_spark_dependencies          - Check dependencies"
        echo "   get_available_memory             - Get system memory"
        echo "   get_cpu_cores                    - Get CPU core count"
        echo "   check_network_status             - Check network status"
        echo ""
        echo "🔧 Dependencies:"
        echo "   - Java 17+"
        echo "   - Spark 3.5.3+"
        echo "   - Python 3.8+"
        echo "   - Scala 2.12+"
        echo ""
        echo "💡 Use 'zsh_help spark <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show Python module help
function show_python_help {
    # Display help information for the Python module.
    #
    # This function shows all available functions in the Python module, including
    # environment management, package manager setup, testing, and utility functions.
    # If a subcommand is provided, it shows detailed help for that specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Python Functions:
    #     - setup_pyenv: Initialize pyenv environment
    #     - setup_uv: Initialize uv environment
    #     - python_status: Check environment status
    #     - pyhelp: Quick Python help
    #     - python_help: Detailed Python help
    #     - test_python_environment: Test Python setup
    #         
    # Package Managers:
    #     - pyenv: Python version management
    #     - uv: Fast Python package manager
    #     - pip: Standard package installer
    #     - conda: Anaconda package manager
    #         
    # Example:
    #     show_python_help              # Show Python module overview
    #     show_python_help setup_pyenv  # Show detailed help for setup_pyenv
    local subcommand="$1"
    
    echo "🐍 Python Module Help"
    echo "====================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   setup_pyenv                    - Initialize pyenv environment"
        echo "   setup_uv                       - Initialize uv environment"
        echo "   python_status                   - Check environment status"
        echo "   pyhelp                          - Quick Python help"
        echo "   python_help                     - Detailed Python help"
        echo "   test_python_environment         - Test Python setup"
        echo "   test_python_managers            - Test package managers"
        echo "   discover_python_environments    - Find Python environments"
        echo "   list_python_packages            - List installed packages"
        echo "   create_python_project           - Create new Python project"
        echo "   activate_python_environment     - Activate environment"
        echo ""
        echo "🔧 Package Managers:"
        echo "   - pyenv (Python version management)"
        echo "   - uv (Fast Python package manager)"
        echo "   - pip (Standard package installer)"
        echo "   - conda (Anaconda package manager)"
        echo ""
        echo "💡 Use 'zsh_help python <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show utilities module help
function show_utilities_help {
    # Display help information for the utilities module.
    #
    # This function shows all available functions in the utilities module, including
    # macOS integration, system preferences, performance optimization, and development
    # environment setup. If a subcommand is provided, it shows detailed help for
    # that specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Utility Functions:
    #     - toggle_hidden_files: Toggle Finder hidden files
    #     - toggle_key_repeat: Toggle key repeat behavior
    #     - show_hidden_files: Show hidden files
    #     - hide_hidden_files: Hide hidden files
    #     - test_macos_integration: Test macOS integration
    #         
    # macOS Features:
    #     - Finder integration
    #     - System preferences
    #     - Key repeat optimization
    #     - Performance tuning
    #         
    # Example:
    #     show_utilities_help              # Show utilities module overview
    #     show_utilities_help toggle_hidden_files # Show detailed help for toggle_hidden_files
    local subcommand="$1"
    
    echo "🛠️  Utilities Module Help"
    echo "========================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   toggle_hidden_files             - Toggle Finder hidden files"
        echo "   show_hidden_files               - Show hidden files"
        echo "   hide_hidden_files               - Hide hidden files"
        echo "   toggle_key_repeat               - Toggle key repeat behavior"
        echo "   enable_key_repeat               - Enable key repeat"
        echo "   disable_key_repeat              - Disable key repeat"
        echo "   test_macos_integration          - Test macOS integration"
        echo "   test_system_preferences         - Test system preferences"
        echo "   get_macos_version               - Get macOS version"
        echo "   check_macos_features            - Check available features"
        echo "   optimize_macos_performance      - Optimize system performance"
        echo "   setup_development_environment   - Setup dev environment"
        echo ""
        echo "🍎 macOS Features:"
        echo "   - Finder integration"
        echo "   - System preferences"
        echo "   - Key repeat optimization"
        echo "   - Performance tuning"
        echo ""
        echo "💡 Use 'zsh_help utilities <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show backup module help
function show_backup_help {
    # Display help information for the backup module.
    #
    # This function shows all available functions in the backup module, including
    # backup creation, repository synchronization, health monitoring, and recovery
    # operations. If a subcommand is provided, it shows detailed help for that
    # specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Backup Functions:
    #     - enhanced_backup: Enhanced backup with sync
    #     - backup_zsh_config: Create configuration backup
    #     - list_zsh_backups: List available backups
    #     - auto_backup_trigger: Trigger automatic backup
    #     - get_backup_path: Generate backup path
    #     - restore_from_backup: Restore from backup
    #         
    # Backup Features:
    #     - Time-based organization
    #     - Automatic Git integration
    #     - Metadata generation
    #     - Restore scripts
    #     - Health monitoring
    #         
    # Example:
    #     show_backup_help              # Show backup module overview
    #     show_backup_help enhanced_backup # Show detailed help for enhanced_backup
    local subcommand="$1"
    
    echo "💾 Backup Module Help"
    echo "====================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   enhanced_backup [message]        - Enhanced backup with sync"
        echo "   backup_zsh_config [message]      - Create configuration backup"
        echo "   list_zsh_backups                 - List available backups"
        echo "   auto_backup_trigger              - Trigger automatic backup"
        echo "   get_backup_path [timestamp]      - Generate backup path"
        echo "   restore_from_backup [path]       - Restore from backup"
        echo "   cleanup_old_backups [days]       - Clean old backups"
        echo "   maintain_repositories             - Repository maintenance"
        echo "   check_repository_health          - Check repository health"
        echo "   emergency_repository_recovery    - Emergency recovery"
        echo "   repair_repository [path]         - Repair corrupted repository"
        echo ""
        echo "🔄 Zshrc Sync Functions:"
        echo "   sync_zshrc_to_repo               - Sync working zshrc to repository"
        echo "   sync_zshrc_from_repo             - Sync repository zshrc to working file"
        echo "   compare_zshrc_files              - Compare zshrc files"
        echo "   sync_zshrc_workflow              - Complete sync and push workflow"
        echo "   zshrc_sync_status                - Show sync status"
        echo ""
        echo "🔗 Convenience Aliases:"
        echo "   zshrc-sync                       - sync_zshrc_to_repo"
        echo "   zshrc-restore                    - sync_zshrc_from_repo"
        echo "   zshrc-compare                    - compare_zshrc_files"
        echo "   zshrc-workflow                   - sync_zshrc_workflow"
        echo "   zshrc-status                     - zshrc_sync_status"
        echo ""
        echo "🔧 Backup Features:"
        echo "   - Time-based organization"
        echo "   - Automatic Git integration"
        echo "   - Metadata generation"
        echo "   - Restore scripts"
        echo "   - Health monitoring"
        echo ""
        echo "💡 Use 'zsh_help backup <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show sync module help
function show_sync_help {
    # Display help information for the sync module.
    #
    # This function shows all available functions in the sync module, including
    # repository synchronization, conflict resolution, health monitoring, and
    # performance tracking. If a subcommand is provided, it shows detailed help
    # for that specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Sync Functions:
    #     - sync_zsh_repositories: Sync both repositories
    #     - sync_zsh: Quick sync
    #     - sync_and_backup: Sync + backup combo
    #     - sync_config_repository: Sync config repo only
    #     - sync_backup_repository: Sync backup repo only
    #     - zsh_repo_status: Repository status
    #         
    # Sync Features:
    #     - Dual repository sync
    #     - Automatic conflict resolution
    #     - Retry logic with backoff
    #     - Health monitoring
    #     - Performance tracking
    #         
    # Example:
    #     show_sync_help              # Show sync module overview
    #     show_sync_help sync_zsh_repositories # Show detailed help for sync_zsh_repositories
    local subcommand="$1"
    
    echo "🔄 Sync Module Help"
    echo "==================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   sync_zsh_repositories [message]  - Sync both repositories"
        echo "   sync_zsh                         - Quick sync"
        echo "   sync_and_backup [message]        - Sync + backup combo"
        echo "   sync_config_repository [message] - Sync config repo only"
        echo "   sync_backup_repository [message] - Sync backup repo only"
        echo "   zsh_repo_status                  - Repository status"
        echo "   check_repository_health          - Health check"
        echo "   maintain_repositories             - Maintenance"
        echo "   repository_analytics             - Analytics"
        echo "   repository_performance_metrics   - Performance metrics"
        echo ""
        echo "🔧 Sync Features:"
        echo "   - Dual repository sync"
        echo "   - Automatic conflict resolution"
        echo "   - Retry logic with backoff"
        echo "   - Health monitoring"
        echo "   - Performance tracking"
        echo ""
        echo "💡 Use 'zsh_help sync <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show testing module help
function show_testing_help {
    # Display help information for the testing module.
    #
    # This function shows all available functions in the testing module, including
    # test execution, health checks, diagnostic reporting, and performance testing.
    # If a subcommand is provided, it shows detailed help for that specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Testing Functions:
    #     - zsh_test_all: Run all tests
    #     - zsh_health_check: Quick health check
    #     - zsh_test_core: Test core functions
    #     - zsh_test_spark: Test Spark functions
    #     - zsh_test_python: Test Python functions
    #     - zsh_diagnostic_report: Generate diagnostics
    #         
    # Testing Features:
    #     - Comprehensive test suite
    #     - Performance benchmarking
    #     - Health monitoring
    #     - Diagnostic reporting
    #     - Test history tracking
    #         
    # Example:
    #     show_testing_help              # Show testing module overview
    #     show_testing_help zsh_test_all # Show detailed help for zsh_test_all
    local subcommand="$1"
    
    echo "🧪 Testing Module Help"
    echo "======================"
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   zsh_test_all                     - Run all tests"
        echo "   zsh_health_check                 - Quick health check"
        echo "   zsh_test_core                    - Test core functions"
        echo "   zsh_test_spark                   - Test Spark functions"
        echo "   zsh_test_python                  - Test Python functions"
        echo "   zsh_test_utilities               - Test utility functions"
        echo "   zsh_test_integration             - Test integration"
        echo "   zsh_test_performance             - Test performance"
        echo "   test_spark_dependencies          - Test Spark setup"
        echo "   test_python_environment          - Test Python setup"
        echo "   test_macos_integration           - Test macOS integration"
        echo "   zsh_diagnostic_report            - Generate diagnostics"
        echo "   generate_test_report             - Generate test report"
        echo "   show_test_statistics             - Show test stats"
        echo ""
        echo "🔧 Testing Features:"
        echo "   - Comprehensive test suite"
        echo "   - Performance benchmarking"
        echo "   - Health monitoring"
        echo "   - Diagnostic reporting"
        echo "   - Test history tracking"
        echo ""
        echo "💡 Use 'zsh_help test <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show Hadoop module help
function show_hadoop_help {
    # Display help information for the Hadoop module.
    #
    # This function shows all available functions in the Hadoop module, including
    # shell launching, dependency management, service management, and testing
    # functions. If a subcommand is provided, it shows detailed help for that
    # specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Hadoop Functions:
    #     - hadoop_shell: Launch Hadoop shell
    #     - test_hadoop_dependencies: Test Hadoop setup
    #     - list_hadoop_jars: List Hadoop JARs
    #     - get_hadoop_jars: Get Hadoop JAR paths
    #     - check_hadoop_environment: Check environment
    #     - setup_hadoop_local: Setup local Hadoop
    #         
    # Dependencies:
    #     - Java 17+
    #     - Hadoop 3.3.6+
    #     - HDFS (optional)
    #     - YARN (optional)
    #         
    # Example:
    #     show_hadoop_help              # Show Hadoop module overview
    #     show_hadoop_help hadoop_shell # Show detailed help for hadoop_shell
    local subcommand="$1"
    
    echo "🐘 Hadoop Module Help"
    echo "====================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   hadoop_shell [port] [memory]      - Launch Hadoop shell"
        echo "   test_hadoop_dependencies          - Test Hadoop setup"
        echo "   list_hadoop_jars                  - List Hadoop JARs"
        echo "   get_hadoop_jars                   - Get Hadoop JAR paths"
        echo "   check_hadoop_environment          - Check environment"
        echo "   setup_hadoop_local                - Setup local Hadoop"
        echo "   start_hadoop_services             - Start Hadoop services"
        echo "   stop_hadoop_services              - Stop Hadoop services"
        echo "   hadoop_status                     - Check service status"
        echo "   hdfs_commands                     - HDFS command shortcuts"
        echo "   yarn_commands                     - YARN command shortcuts"
        echo ""
        echo "🔧 Dependencies:"
        echo "   - Java 17+"
        echo "   - Hadoop 3.3.6+"
        echo "   - HDFS (optional)"
        echo "   - YARN (optional)"
        echo ""
        echo "💡 Use 'zsh_help hadoop <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show Docker module help
function show_docker_help {
    # Display help information for the Docker module.
    #
    # This function shows all available functions in the Docker module, including
    # container management, image management, cleanup operations, and monitoring
    # functions. If a subcommand is provided, it shows detailed help for that
    # specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Docker Functions:
    #     - docker_status: Check Docker status
    #     - docker_cleanup: Clean up Docker resources
    #     - docker_stats: Show Docker statistics
    #     - docker_logs: Show container logs
    #     - docker_exec: Execute command in container
    #     - docker_build: Build Docker image
    #         
    # Dependencies:
    #     - Docker Desktop or Docker Engine
    #     - Docker CLI
    #     - Docker Compose (optional)
    #         
    # Example:
    #     show_docker_help              # Show Docker module overview
    #     show_docker_help docker_status # Show detailed help for docker_status
    local subcommand="$1"
    
    echo "🐳 Docker Module Help"
    echo "====================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   docker_status                      - Check Docker status"
        echo "   docker_cleanup                     - Clean up Docker resources"
        echo "   docker_stats                       - Show Docker statistics"
        echo "   docker_logs [container]           - Show container logs"
        echo "   docker_exec [container] [command] - Execute command in container"
        echo "   docker_build [context] [tag]      - Build Docker image"
        echo "   docker_run [image] [options]      - Run Docker container"
        echo "   docker_stop_all                   - Stop all containers"
        echo "   docker_remove_all                 - Remove all containers"
        echo "   docker_images_cleanup             - Clean up unused images"
        echo "   docker_volumes_cleanup            - Clean up unused volumes"
        echo "   docker_network_cleanup            - Clean up unused networks"
        echo ""
        echo "🔧 Dependencies:"
        echo "   - Docker Desktop or Docker Engine"
        echo "   - Docker CLI"
        echo "   - Docker Compose (optional)"
        echo ""
        echo "💡 Use 'zsh_help docker <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show notebooks module help
function show_notebooks_help {
    # Display help information for the notebooks module.
    #
    # This function shows all available functions in the notebooks module, including
    # Jupyter server management, kernel management, notebook operations, and
    # JupyterLab integration. If a subcommand is provided, it shows detailed help
    # for that specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Notebook Functions:
    #     - jupyter_start: Start Jupyter server
    #     - jupyter_stop: Stop Jupyter server
    #     - jupyter_status: Check Jupyter status
    #     - jupyter_list: List running servers
    #     - jupyter_kernels: List available kernels
    #     - notebook_create: Create new notebook
    #         
    # Dependencies:
    #     - Python 3.8+
    #     - Jupyter
    #     - JupyterLab (optional)
    #     - IPython kernels
    #         
    # Example:
    #     show_notebooks_help              # Show notebooks module overview
    #     show_notebooks_help jupyter_start # Show detailed help for jupyter_start
    local subcommand="$1"
    
    echo "📓 Notebooks Module Help"
    echo "========================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   jupyter_start [port] [directory]   - Start Jupyter server"
        echo "   jupyter_stop                       - Stop Jupyter server"
        echo "   jupyter_status                     - Check Jupyter status"
        echo "   jupyter_list                       - List running servers"
        echo "   jupyter_kernels                    - List available kernels"
        echo "   jupyter_install_kernel [name]      - Install new kernel"
        echo "   jupyter_remove_kernel [name]       - Remove kernel"
        echo "   notebook_create [name] [type]      - Create new notebook"
        echo "   notebook_open [path]               - Open notebook"
        echo "   notebook_convert [path] [format]   - Convert notebook"
        echo "   lab_start [port] [directory]       - Start JupyterLab"
        echo "   lab_stop                           - Stop JupyterLab"
        echo "   lab_status                         - Check Lab status"
        echo ""
        echo "🔧 Dependencies:"
        echo "   - Python 3.8+"
        echo "   - Jupyter"
        echo "   - JupyterLab (optional)"
        echo "   - IPython kernels"
        echo ""
        echo "💡 Use 'zsh_help notebooks <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show environment module help
function show_environment_help {
    # Display help information for the environment module.
    #
    # This function shows all available functions in the environment module, including
    # environment variable management, path management, project path handling, and
    # environment health monitoring. If a subcommand is provided, it shows detailed
    # help for that specific function.
    #
    # Args:
    #     subcommand (str, optional): Specific function to get detailed help for.
    #                                  If not provided, shows module overview.
    #
    # Returns:
    #     None (displays formatted help information)
    #         
    # Environment Functions:
    #     - show_environment_variables: Display all environment variables
    #     - set_project_path: Set project path
    #     - get_project_path: Get project path
    #     - list_project_paths: List all project paths
    #     - add_to_path: Add path to PATH
    #     - remove_from_path: Remove path from PATH
    #         
    # Environment Variables:
    #     - ZSHRC_CONFIG_DIR: Configuration directory
    #     - ZSHRC_BACKUPS: Backup directory
    #     - PYTHON_ACTIVE: Active Python environment
    #     - JAVA_HOME: Java installation path
    #     - SPARK_HOME: Spark installation path
    #         
    # Example:
    #     show_environment_help              # Show environment module overview
    #     show_environment_help set_project_path # Show detailed help for set_project_path
    local subcommand="$1"
    
    echo "🌐 Environment Module Help"
    echo "=========================="
    echo ""
    echo "📋 Available Functions:"
    echo ""
    
    if [[ -z "$subcommand" ]]; then
        echo "   show_environment_variables         - Display all environment variables"
        echo "   set_project_path [name] [path]     - Set project path"
        echo "   get_project_path [name]            - Get project path"
        echo "   list_project_paths                 - List all project paths"
        echo "   add_to_path [path]                 - Add path to PATH"
        echo "   remove_from_path [path]            - Remove path from PATH"
        echo "   clean_path                         - Clean duplicate paths"
        echo "   export_environment                 - Export environment to file"
        echo "   import_environment [file]          - Import environment from file"
        echo "   reset_environment                  - Reset to default environment"
        echo "   environment_backup                 - Backup current environment"
        echo "   environment_restore [backup]       - Restore environment from backup"
        echo "   check_environment_health           - Check environment health"
        echo ""
        echo "🔧 Environment Variables:"
        echo "   - ZSHRC_CONFIG_DIR"
        echo "   - ZSHRC_BACKUPS"
        echo "   - PYTHON_ACTIVE"
        echo "   - JAVA_HOME"
        echo "   - SPARK_HOME"
        echo "   - HADOOP_HOME"
        echo "   - SDKMAN_DIR"
        echo ""
        echo "💡 Use 'zsh_help environment <function>' for detailed help on specific functions"
    else
        show_function_help "$subcommand"
    fi
}

# Show function-specific help
function show_function_help {
    # Display detailed help information for a specific function.
    #
    # This function provides comprehensive documentation for individual functions,
    # including their source code, comments, and usage examples. It's used by
    # the module help functions to provide function-specific assistance.
    #
    # Args:
    #     function_name (str): Name of the function to get help for.
    #
    # Returns:
    #     None (displays formatted function help)
    #         
    # Features:
    #     - Function existence validation
    #     - Source code display
    #     - Comment extraction
    #     - Usage examples
    #         
    # Example:
    #     show_function_help pyspark_shell
    #     # Output:
    #     # 📚 Help for function: pyspark_shell
    #     # =====================================
    #     # [Function documentation and source code]
    local function_name="$1"
    
    if [[ -z "$function_name" ]]; then
        echo "❌ Please specify a function name"
        return 1
    fi
    
    # Check if function exists
    if ! typeset -f "$function_name" >/dev/null 2>&1; then
        echo "❌ Function '$function_name' not found"
        echo "💡 Use 'zsh_help list' to see all available functions"
        return 1
    fi
    
    echo "📚 Help for function: $function_name"
    echo "====================================="
    echo ""
    
    # Get function source
    local function_source=$(typeset -f "$function_name")
    
    # Extract comments and documentation
    echo "$function_source" | grep '^#' | sed 's/^# //'
    echo ""
    
    # Show function definition
    echo "🔧 Function Definition:"
    echo "$function_source"
    echo ""
    
    # Show usage examples if available
    show_function_usage_examples "$function_name"
}

# Show function usage examples
function show_function_usage_examples {
    # Display usage examples for a specific function.
    #
    # This function provides practical examples of how to use various functions
    # in the zsh configuration system. It includes common use cases and
    # parameter variations for better understanding.
    #
    # Args:
    #     function_name (str): Name of the function to show examples for.
    #
    # Returns:
    #     None (displays formatted usage examples)
    #         
    # Supported Functions:
    #     - pyspark_shell: Spark shell launching examples
    #     - backup_zsh_config: Backup operation examples
    #     - sync_zsh: Repository sync examples
    #     - zsh_help: Help system examples
    #     - zsh_test_all: Testing examples
    #     - enhanced_backup: Enhanced backup examples
    #         
    # Example:
    #     show_function_usage_examples pyspark_shell
    #     # Output:
    #     # 💡 Usage Examples:
    #     #    pyspark_shell              # Default port 4040, memory 2g
    #     #    pyspark_shell 8080         # Custom port 8080
    local function_name="$1"
    
    echo "💡 Usage Examples:"
    
    case "$function_name" in
        "pyspark_shell")
            echo "   pyspark_shell              # Default port 4040, memory 2g"
            echo "   pyspark_shell 8080         # Custom port 8080"
            echo "   pyspark_shell 8080 4g      # Custom port and memory"
            ;;
        "backup_zsh_config")
            echo "   backup_zsh_config                          # Default message"
            echo "   backup_zsh_config 'Custom backup message'  # Custom message"
            ;;
        "sync_zsh")
            echo "   sync_zsh                                   # Default sync"
            echo "   sync_zsh 'Custom sync message'             # Custom message"
            ;;
        "zsh_help")
            echo "   zsh_help                                   # Show main help"
            echo "   zsh_help spark                             # Show Spark help"
            echo "   zsh_help backup sync                       # Show specific function help"
            ;;
        "zsh_test_all")
            echo "   zsh_test_all                               # Run all tests"
            echo "   zsh_test_all | tee test_results.txt        # Save results to file"
            ;;
        "enhanced_backup")
            echo "   enhanced_backup                             # Default backup"
            echo "   enhanced_backup 'Feature update'            # Custom message"
            ;;
        *)
            echo "   $function_name                              # Basic usage"
            echo "   $function_name --help                       # Check for help flag"
            ;;
    esac
}

# List all available functions
function list_all_functions {
    # Display a categorized list of all available functions in the zsh configuration.
    #
    # This function scans the current shell environment and categorizes all
    # available functions by their purpose and module. It provides a comprehensive
    # overview of the system's capabilities and helps users discover available
    # functionality.
    #
    # Args:
    #     None
    #
    # Returns:
    #     None (displays categorized function list)
    #         
    # Categories:
    #     - Core Functions: Configuration and management functions
    #     - Spark Functions: Big Data and Spark-related functions
    #     - Python Functions: Python environment management
    #     - Utility Functions: macOS and system utility functions
    #     - Backup Functions: Backup and sync operations
    #     - Sync Functions: Repository synchronization
    #     - Test Functions: Testing and validation
    #     - Help Functions: Help system functions
    #     - Other Functions: Uncategorized functions
    #         
    # Example:
    #     list_all_functions
    #     # Output:
    #     # 🔍 All Available Functions
    #     # ==========================
    #     # 📊 Total functions: 45
    #     # 🔧 Core Functions (12):
    #     #    zsh_help, zshconfig, zshreboot, ...
    echo "🔍 All Available Functions"
    echo "=========================="
    echo ""
    
    # Get all function names
    local functions=($(typeset -f | grep '^[a-zA-Z_][a-zA-Z0-9_]* ()' | cut -d' ' -f1))
    
    echo "📊 Total functions: ${#functions[@]}"
    echo ""
    
    # Categorize functions
    local core_functions=()
    local spark_functions=()
    local python_functions=()
    local utility_functions=()
    local backup_functions=()
    local sync_functions=()
    local test_functions=()
    local help_functions=()
    local other_functions=()
    
    for func in "${functions[@]}"; do
        case "$func" in
            zsh_*|backup_*|list_*)
                core_functions+=("$func")
                ;;
            *spark*|*hadoop*)
                spark_functions+=("$func")
                ;;
            *python*|*pyenv*|*uv*)
                python_functions+=("$func")
                ;;
            toggle_*|show_*|hide_*|enable_*|disable_*)
                utility_functions+=("$func")
                ;;
            sync_*|repo*)
                sync_functions+=("$func")
                ;;
            *test*|*check*|*diagnostic*)
                test_functions+=("$func")
                ;;
            *help*|*show*|*list*)
                help_functions+=("$func")
                ;;
            *)
                other_functions+=("$func")
                ;;
        esac
    done
    
    # Display categorized functions
    echo "🔧 Core Functions (${#core_functions[@]}):"
    printf "   %s\n" "${core_functions[@]}"
    echo ""
    
    echo "⚡ Spark Functions (${#spark_functions[@]}):"
    printf "   %s\n" "${spark_functions[@]}"
    echo ""
    
    echo "🐍 Python Functions (${#python_functions[@]}):"
    printf "   %s\n" "${python_functions[@]}"
    echo ""
    
    echo "🛠️  Utility Functions (${#utility_functions[@]}):"
    printf "   %s\n" "${utility_functions[@]}"
    echo ""
    
    echo "💾 Backup Functions (${#backup_functions[@]}):"
    printf "   %s\n" "${backup_functions[@]}"
    echo ""
    
    echo "🔄 Sync Functions (${#sync_functions[@]}):"
    printf "   %s\n" "${sync_functions[@]}"
    echo ""
    
    echo "🧪 Test Functions (${#test_functions[@]}):"
    printf "   %s\n" "${test_functions[@]}"
    echo ""
    
    echo "❓ Help Functions (${#help_functions[@]}):"
    printf "   %s\n" "${help_functions[@]}"
    echo ""
    
    if [[ ${#other_functions[@]} -gt 0 ]]; then
        echo "🔍 Other Functions (${#other_functions[@]}):"
        printf "   %s\n" "${other_functions[@]}"
        echo ""
    fi
    
    echo "💡 Use 'zsh_help <module>' for detailed help on specific modules"
    echo "💡 Use 'zsh_help <function>' for detailed help on specific functions"
}

# Search functions by name or description
function search_functions {
    # Search for functions by name or description content.
    #
    # This function provides a powerful search capability across all available
    # functions in the zsh configuration. It searches both function names and
    # their definitions to find relevant functions based on user search terms.
    #
    # Args:
    #     search_term (str): Search term to look for in function names or definitions.
    #
    # Returns:
    #     None (displays search results)
    #         
    # Search Features:
    #     - Function name matching
    #     - Definition content matching
    #     - Case-insensitive search
    #     - Comprehensive result display
    #         
    # Example:
    #     search_functions backup
    #     # Output:
    #     # 🔍 Searching for functions matching: 'backup'
    #     # =================================================
    #     # ✅ Found 5 matching functions:
    #     #    🔧 backup_zsh_config
    #       #    function backup_zsh_config () { ... }
    local search_term="$1"
    
    if [[ -z "$search_term" ]]; then
        echo "❌ Please provide a search term"
        echo "💡 Usage: zsh_help search <term>"
        return 1
    fi
    
    echo "🔍 Searching for functions matching: '$search_term'"
    echo "================================================="
    echo ""
    
    local functions=($(typeset -f | grep '^[a-zA-Z_][a-zA-Z0-9_]* ()' | cut -d' ' -f1))
    local matches=()
    
    for func in "${functions[@]}"; do
        # Search in function name
        if [[ "$func" == *"$search_term"* ]]; then
            matches+=("$func")
            continue
        fi
        
        # Search in function definition
        local func_def=$(typeset -f "$func")
        if [[ "$func_def" == *"$search_term"* ]]; then
            matches+=("$func")
        fi
    done
    
    if [[ ${#matches[@]} -eq 0 ]]; then
        echo "❌ No functions found matching '$search_term'"
        return 1
    fi
    
    echo "✅ Found ${#matches[@]} matching functions:"
    echo ""
    
    for func in "${matches[@]}"; do
        echo "   🔧 $func"
        # Show first line of function definition
        local func_def=$(typeset -f "$func" | head -1)
        echo "      $func_def"
        echo ""
    done
    
    echo "💡 Use 'zsh_help <function>' for detailed help on specific functions"
}

# Show usage examples
function show_usage_examples {
    # Display general or function-specific usage examples.
    #
    # This function provides practical examples of how to use the zsh configuration
    # system. It can show general examples for common operations or specific
    # examples for individual functions, helping users understand the system's
    # capabilities and proper usage patterns.
    #
    # Args:
    #     function_name (str, optional): Specific function to show examples for.
    #                                   If not provided, shows general examples.
    #
    # Returns:
    #     None (displays formatted usage examples)
    #         
    # Example Categories:
    #     - Core Operations: Configuration and management
    #     - Spark Operations: Big Data operations
    #     - Backup Operations: Backup and sync operations
    #     - Testing Operations: Testing and validation
    #         
    # Example:
    #     show_usage_examples              # Show general examples
    #     show_usage_examples pyspark_shell # Show function-specific examples
    local function_name="$1"
    
    if [[ -z "$function_name" ]]; then
        echo "📚 General Usage Examples"
        echo "========================="
        echo ""
        echo "🔧 Core Operations:"
        echo "   zsh_help all                    # Show all help"
        echo "   zshconfig                       # Edit configuration"
        echo "   zshreboot                       # Reload configuration"
        echo "   zsh_health_check                # Check system health"
        echo ""
        echo "⚡ Spark Operations:"
        echo "   pyspark_shell                   # Launch Python Spark shell"
        echo "   spark_shell_scala               # Launch Scala Spark shell"
        echo "   smart_spark_shell               # Intelligent shell selection"
        echo ""
        echo "💾 Backup Operations:"
        echo "   backup                          # Create backup"
        echo "   sync                            # Sync repositories"
        echo "   syncbackup                      # Sync and backup"
        echo "   repostatus                      # Check repository status"
        echo ""
        echo "🧪 Testing Operations:"
        echo "   zsh_test_all                    # Run all tests"
        echo "   zsh_diagnostic_report           # Generate diagnostics"
        echo ""
        echo "💡 Use 'zsh_help <module>' for module-specific examples"
        echo "💡 Use 'zsh_help usage <function>' for function-specific examples"
    else
        show_function_usage_examples "$function_name"
    fi
}

# List available modules
function list_available_modules {
    # Display a list of all available modules in the zsh configuration system.
    #
    # This function provides an overview of all modules that make up the
    # enhanced zsh configuration, including their descriptions and purposes.
    # It helps users understand the system's modular architecture and
    # available functionality.
    #
    # Args:
    #     None
    #
    # Returns:
    #     None (displays formatted module list)
    #         
    # Available Modules:
    #     - core.zsh: Core configuration and management
    #     - spark.zsh: Spark & Big Data integration
    #     - python.zsh: Python environment management
    #     - utilities.zsh: macOS utility functions
    #     - backup-system.zsh: Backup and sync system
    #     - hadoop.zsh: Hadoop integration
    #     - docker.zsh: Docker management
    #     - notebooks.zsh: Jupyter notebook integration
    #     - environment.zsh: Environment variables
    #     - help-module.zsh: Help system
    #         
    # Example:
    #     list_available_modules
    #     # Output:
    #     # 📦 Available Modules
    #     # ====================
    #     #    📁 core.zsh - Core configuration and management
    #    #    📁 spark.zsh - Spark & Big Data integration
    #    #    ...
    echo "📦 Available Modules"
    echo "===================="
    echo ""
    
    local modules=(
        "core.zsh - Core configuration and management"
        "spark.zsh - Spark & Big Data integration"
        "python.zsh - Python environment management"
        "utilities.zsh - macOS utility functions"
        "backup-system.zsh - Backup and sync system"
        "hadoop.zsh - Hadoop integration"
        "docker.zsh - Docker management"
        "notebooks.zsh - Jupyter notebook integration"
        "environment.zsh - Environment variables"
        "help-module.zsh - This help system"
    )
    
    for module in "${modules[@]}"; do
        echo "   📁 $module"
    done
    
    echo ""
    echo "💡 Use 'zsh_help <module>' for detailed help on specific modules"
    echo "💡 Use 'zsh_help <module> <function>' for function-specific help"
}

# Convenience aliases
alias help='zsh_help'
alias h='zsh_help'
alias functions='list_all_functions'
alias search='search_functions'
alias modules='list_available_modules'
alias examples='show_usage_examples'
