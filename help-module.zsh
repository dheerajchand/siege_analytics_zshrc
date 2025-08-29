# =====================================================
# COMPREHENSIVE HELP MODULE
# =====================================================

# Enhanced help system with module-specific help and function listings
export HELP_MODULE_LOADED=true

# Main help function with module support
function zsh_help {
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
