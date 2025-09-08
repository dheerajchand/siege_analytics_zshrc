#!/usr/bin/env zsh

# =====================================================
# MODULAR HELP SYSTEM
# =====================================================
# 
# Comprehensive help system for the modular zsh configuration
# Provides documentation for all modules, functions, and features
# Updated for the complete modular architecture (v3.0)
# =====================================================

export HELP_MODULE_LOADED="true"
export HELP_MODULE_VERSION="3.0.0"

# Help system colors
readonly HELP_COLOR_HEADER='\033[1;36m'    # Cyan bold
readonly HELP_COLOR_MODULE='\033[1;34m'     # Blue bold  
readonly HELP_COLOR_FUNCTION='\033[1;32m'   # Green bold
readonly HELP_COLOR_EXAMPLE='\033[0;33m'    # Yellow
readonly HELP_COLOR_RESET='\033[0m'         # Reset

# =====================================================
# MAIN HELP INTERFACE
# =====================================================

zsh_help() {
    # Main help function for the modular zsh configuration system
    #
    # Provides comprehensive assistance for all modules and functions.
    # Completely updated for the new modular architecture.
    #
    # Args:
    #     module (str, optional): Module name or help topic
    #     subcommand (str, optional): Specific function or topic within module
    #
    # Examples:
    #     zsh_help                    # Main help overview
    #     zsh_help modules            # List all modules
    #     zsh_help core               # Core module help
    #     zsh_help environment        # Platform detection help
    #     zsh_help credentials        # Credential management help
    #     zsh_help database           # Database configuration help
    #     zsh_help jetbrains          # JetBrains IDE help
    #     zsh_help docker             # Container management help
    #     zsh_help spark              # Apache Spark help
    #     zsh_help hadoop             # Hadoop ecosystem help
    #     zsh_help search password    # Search for credential functions
    local module="${1:-all}"
    local subcommand="${2:-}"
    
    case "$module" in
        "all"|""|"main")
            show_main_help
            ;;
        "modules"|"list")
            show_modules_list
            ;;
        "core")
            show_core_help "$subcommand"
            ;;
        "environment"|"env")
            show_environment_help "$subcommand"
            ;;
        "credentials"|"creds")
            show_credentials_help "$subcommand"
            ;;
        "database"|"db")
            show_database_help "$subcommand"
            ;;
        "jetbrains"|"jb"|"ide")
            show_jetbrains_help "$subcommand"
            ;;
        "docker"|"container")
            show_docker_help "$subcommand"
            ;;
        "spark")
            show_spark_help "$subcommand"
            ;;
        "hadoop"|"hdfs"|"yarn")
            show_hadoop_help "$subcommand"
            ;;
        "backup"|"backup-toggle")
            show_backup_help "$subcommand"
            ;;
        "status")
            show_status_help
            ;;
        "quick-start"|"quickstart")
            show_quick_start_help
            ;;
        "search")
            search_help "$subcommand"
            ;;
        "testing"|"tests")
            show_testing_help
            ;;
        "config"|"customization")
            show_customization_help
            ;;
        *)
            echo -e "${HELP_COLOR_HEADER}❓ Unknown module: $module${HELP_COLOR_RESET}"
            echo ""
            echo "Available modules:"
            show_modules_list
            ;;
    esac
}

# =====================================================
# MAIN HELP DISPLAY
# =====================================================

show_main_help() {
    echo -e "${HELP_COLOR_HEADER}🚀 Modular ZSH Configuration System v3.0${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}=====================================${HELP_COLOR_RESET}"
    echo ""
    echo "Welcome to the enhanced modular shell configuration system!"
    echo ""
    echo -e "${HELP_COLOR_MODULE}📊 System Achievements:${HELP_COLOR_RESET}"
    echo "  • 86% size reduction (2,435 → 350 lines main config)"
    echo "  • 10 focused modules replacing monolithic file"
    echo "  • Full cross-platform support (macOS, Linux, Docker, WSL)"
    echo "  • <2 second startup time with dynamic loading"
    echo "  • Enterprise-grade security with multi-backend credentials"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🎯 Quick Commands:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}modular_zsh_status${HELP_COLOR_RESET}     # Show all module status"
    echo -e "  ${HELP_COLOR_FUNCTION}environment_info${HELP_COLOR_RESET}       # Platform and system details"
    echo -e "  ${HELP_COLOR_FUNCTION}zsh_help modules${HELP_COLOR_RESET}       # List all available modules"
    echo -e "  ${HELP_COLOR_FUNCTION}zsh_help quick-start${HELP_COLOR_RESET}   # Quick start guide"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔍 Help Usage:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}zsh_help <module>${HELP_COLOR_RESET}       # Module-specific help"
    echo -e "  ${HELP_COLOR_EXAMPLE}zsh_help search <term>${HELP_COLOR_RESET}  # Search for functions"
    echo -e "  ${HELP_COLOR_EXAMPLE}help${HELP_COLOR_RESET}                   # Alias for zsh_help"
    echo ""
    echo -e "${HELP_COLOR_MODULE}📖 Available Help Topics:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}modules${HELP_COLOR_RESET}     • List all 10 modules and their status"
    echo -e "  ${HELP_COLOR_FUNCTION}core${HELP_COLOR_RESET}        • Essential shell functions and utilities"
    echo -e "  ${HELP_COLOR_FUNCTION}environment${HELP_COLOR_RESET} • Cross-platform detection and paths"
    echo -e "  ${HELP_COLOR_FUNCTION}credentials${HELP_COLOR_RESET} • Secure credential management system"
    echo -e "  ${HELP_COLOR_FUNCTION}database${HELP_COLOR_RESET}    • PostgreSQL, MySQL, Snowflake integration"
    echo -e "  ${HELP_COLOR_FUNCTION}jetbrains${HELP_COLOR_RESET}   • IDE integration and project detection"
    echo -e "  ${HELP_COLOR_FUNCTION}docker${HELP_COLOR_RESET}      • Container management and development"
    echo -e "  ${HELP_COLOR_FUNCTION}spark${HELP_COLOR_RESET}       • Apache Spark (all execution modes)"
    echo -e "  ${HELP_COLOR_FUNCTION}hadoop${HELP_COLOR_RESET}      • Hadoop ecosystem (HDFS, YARN, MapReduce)"
    echo -e "  ${HELP_COLOR_FUNCTION}backup${HELP_COLOR_RESET}      • Auto-backup control system (toggle on/off)"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🛠️ System Management:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}status${HELP_COLOR_RESET}      • System status and diagnostics"
    echo -e "  ${HELP_COLOR_FUNCTION}testing${HELP_COLOR_RESET}     • Testing and validation framework"
    echo -e "  ${HELP_COLOR_FUNCTION}config${HELP_COLOR_RESET}      • Customization and configuration"
}

# =====================================================
# MODULE LISTING
# =====================================================

show_modules_list() {
    echo -e "${HELP_COLOR_HEADER}📦 Modular System Architecture${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}==============================${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}10 Core Modules:${HELP_COLOR_RESET}"
    echo ""
    
    # Show module status dynamically
    local modules=(
        "core:Essential shell configuration (always loads)"
        "environment:Cross-platform detection & paths (always loads)"  
        "credentials:Multi-backend security system (always loads)"
        "database:PostgreSQL, MySQL, Snowflake integration"
        "jetbrains:IDE integration & project detection"
        "spark:Apache Spark (all execution modes)"
        "hadoop:HDFS, YARN, MapReduce management"
        "docker:Container management & development"
        "backup-toggle:Auto-backup control system (prevents unwanted commits)"
        "help:Interactive documentation system"
    )
    
    for module_info in "${modules[@]}"; do
        local module_name="${module_info%%:*}"
        local module_desc="${module_info##*:}"
        
        # Check if module is loaded
        local status_var="${(U)module_name}_MODULE_LOADED"
        local is_loaded="${(P)status_var:-false}"
        
        if [[ "$is_loaded" == "true" ]]; then
            echo -e "  ✅ ${HELP_COLOR_FUNCTION}$module_name${HELP_COLOR_RESET}: $module_desc"
        else
            echo -e "  ⏭️  ${HELP_COLOR_FUNCTION}$module_name${HELP_COLOR_RESET}: $module_desc ${HELP_COLOR_EXAMPLE}(not loaded)${HELP_COLOR_RESET}"
        fi
    done
    
    echo ""
    echo -e "${HELP_COLOR_MODULE}Module Loading:${HELP_COLOR_RESET}"
    echo "  • Core modules (core, environment, credentials): Always load"
    echo "  • Tool modules: Load only if tools are installed"
    echo "  • Dynamic loading improves startup performance"
    echo ""
    echo -e "${HELP_COLOR_EXAMPLE}Usage: zsh_help <module_name>${HELP_COLOR_RESET}"
}

# =====================================================
# MODULE-SPECIFIC HELP
# =====================================================

show_core_help() {
    echo -e "${HELP_COLOR_HEADER}🔧 Core Module Help${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}===================${HELP_COLOR_RESET}"
    echo ""
    echo "Essential shell configuration that always loads."
    echo "Provides core utilities, aliases, and shell settings."
    echo ""
    echo -e "${HELP_COLOR_MODULE}🛠️ Utility Functions:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}mkcd <directory>${HELP_COLOR_RESET}       # Create directory and cd into it"
    echo -e "  ${HELP_COLOR_FUNCTION}extract <archive>${HELP_COLOR_RESET}      # Universal archive extraction"
    echo -e "  ${HELP_COLOR_FUNCTION}is_online${HELP_COLOR_RESET}              # Check internet connectivity"
    echo -e "  ${HELP_COLOR_FUNCTION}command_exists <cmd>${HELP_COLOR_RESET}   # Check if command is available"
    echo ""
    echo -e "${HELP_COLOR_MODULE}📂 Path Management:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}path_add <path>${HELP_COLOR_RESET}        # Add to PATH safely"
    echo -e "  ${HELP_COLOR_FUNCTION}path_remove <path>${HELP_COLOR_RESET}     # Remove from PATH"
    echo ""
    echo -e "${HELP_COLOR_MODULE}⚡ Enhanced Aliases:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}ll, la, l${HELP_COLOR_RESET}              # Enhanced ls with colors"
    echo -e "  ${HELP_COLOR_FUNCTION}gs, gp, gc${HELP_COLOR_RESET}             # Git shortcuts (status, push, commit)"
    echo -e "  ${HELP_COLOR_FUNCTION}zshreboot${HELP_COLOR_RESET}              # Restart zsh shell"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🎯 System Management:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}modular_zsh_status${HELP_COLOR_RESET}     # Show all module status"
    echo -e "  ${HELP_COLOR_FUNCTION}reload_modular_zsh${HELP_COLOR_RESET}     # Reload configuration"
    echo -e "  ${HELP_COLOR_FUNCTION}load_config_module${HELP_COLOR_RESET}     # Load specific module"
}

show_environment_help() {
    echo -e "${HELP_COLOR_HEADER}🌍 Environment Module Help${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}===========================${HELP_COLOR_RESET}"
    echo ""
    echo "Cross-platform detection and path management."
    echo "Automatically adapts to macOS, Linux, Docker, and WSL."
    echo ""
    echo -e "${HELP_COLOR_MODULE}🎯 Platform Detection:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}\$ZSH_PLATFORM${HELP_COLOR_RESET}          # Current platform (macos/linux/unknown)"
    echo -e "  ${HELP_COLOR_FUNCTION}\$ZSH_DISTRO${HELP_COLOR_RESET}            # Linux distribution (ubuntu/rhel/arch/etc)"
    echo -e "  ${HELP_COLOR_FUNCTION}\$ZSH_IS_DOCKER${HELP_COLOR_RESET}         # Container detection (true/false)"
    echo -e "  ${HELP_COLOR_FUNCTION}\$IS_MACOS, \$IS_LINUX${HELP_COLOR_RESET}  # Platform flags"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔄 Cross-Platform Utilities:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}platform_open <file>${HELP_COLOR_RESET}   # Open with default application"
    echo -e "  ${HELP_COLOR_FUNCTION}platform_copy${HELP_COLOR_RESET}          # Copy to system clipboard"
    echo -e "  ${HELP_COLOR_FUNCTION}platform_paste${HELP_COLOR_RESET}         # Paste from system clipboard"
    echo -e "  ${HELP_COLOR_FUNCTION}platform_browser <url>${HELP_COLOR_RESET} # Open URL in default browser"
    echo ""
    echo -e "${HELP_COLOR_MODULE}📊 Information Commands:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}environment_info${HELP_COLOR_RESET}       # Complete system information"
    echo -e "  ${HELP_COLOR_FUNCTION}env-info${HELP_COLOR_RESET}               # Alias for environment_info"
    echo -e "  ${HELP_COLOR_FUNCTION}platform-info${HELP_COLOR_RESET}          # Platform detection details"
    echo -e "  ${HELP_COLOR_FUNCTION}container-info${HELP_COLOR_RESET}         # Container environment info"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🐳 Container Support:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}is_container${HELP_COLOR_RESET}           # Check if running in container"
    echo -e "  ${HELP_COLOR_FUNCTION}container_host_info${HELP_COLOR_RESET}    # Show container details"
    echo "  • Automatic memory optimization for containers"
    echo "  • Package manager detection for all platforms"
    echo "  • Graceful fallbacks for minimal environments"
}

show_credentials_help() {
    echo -e "${HELP_COLOR_HEADER}🔐 Credentials Module Help${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}==========================${HELP_COLOR_RESET}"
    echo ""
    echo "Multi-backend credential management system."
    echo "Secure storage with automatic fallback chain."
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔒 Backend Priority Chain:${HELP_COLOR_RESET}"
    echo "  1. Environment variables (preserves existing workflows)"
    echo "  2. 1Password CLI (op command)"
    echo "  3. macOS Keychain (security command)"
    echo "  4. Interactive prompts (secure fallback)"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🛠️ Core Functions:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}get_credential <service> <user> [field]${HELP_COLOR_RESET}"
    echo "    # Get credential from any available backend"
    echo -e "  ${HELP_COLOR_FUNCTION}credential_backend_status${HELP_COLOR_RESET} # Show available backends"
    echo -e "  ${HELP_COLOR_FUNCTION}detect_credential_backends${HELP_COLOR_RESET} # Scan for credential systems"
    echo ""
    echo -e "${HELP_COLOR_MODULE}⚡ Quick Commands:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}creds-status${HELP_COLOR_RESET}           # Show credential backend status"
    echo ""
    echo -e "${HELP_COLOR_MODULE}💡 Usage Examples:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}export PGPASSWORD=\$(get_credential \"postgres\" \"\$PGUSER\" \"PASSWORD\")${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}api_key=\$(get_credential \"myservice\" \"myuser\")${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔄 Backward Compatibility:${HELP_COLOR_RESET}"
    echo "  • All existing environment variables continue to work"
    echo "  • PGPASSWORD, MYSQL_PWD workflows preserved"
    echo "  • Easy migration to secure storage when ready"
}

show_database_help() {
    echo -e "${HELP_COLOR_HEADER}🗄️ Database Module Help${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}========================${HELP_COLOR_RESET}"
    echo ""
    echo "Secure database connection management."
    echo "Integrates with credential system for secure access."
    echo ""
    echo -e "${HELP_COLOR_MODULE}📊 Status & Configuration:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}database_status${HELP_COLOR_RESET}        # Show all database configurations"
    echo -e "  ${HELP_COLOR_FUNCTION}db-status${HELP_COLOR_RESET}              # Alias for database_status"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🐘 PostgreSQL:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}setup_postgres_credentials${HELP_COLOR_RESET} # Setup secure PostgreSQL credentials"
    echo -e "  ${HELP_COLOR_FUNCTION}get_postgres_password${HELP_COLOR_RESET}  # Get PostgreSQL password from secure storage"
    echo -e "  ${HELP_COLOR_FUNCTION}pg_test_connection${HELP_COLOR_RESET}     # Test PostgreSQL connection"
    echo -e "  ${HELP_COLOR_FUNCTION}pg${HELP_COLOR_RESET}                     # Connect to PostgreSQL with auto-credentials"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🐬 MySQL:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}setup_mysql_credentials${HELP_COLOR_RESET} # Setup MySQL credentials"
    echo -e "  ${HELP_COLOR_FUNCTION}mysql-local${HELP_COLOR_RESET}            # MySQL connection with auto-credentials"
    echo ""
    echo -e "${HELP_COLOR_MODULE}❄️ Snowflake:${HELP_COLOR_RESET}"
    echo "  • Automatic credential detection from environment"
    echo "  • Secure storage integration available"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔧 Quick Tests:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}pgtest${HELP_COLOR_RESET}                 # Test PostgreSQL connection"
    echo -e "  ${HELP_COLOR_FUNCTION}mytest${HELP_COLOR_RESET}                 # Test MySQL connection"
}

show_jetbrains_help() {
    echo -e "${HELP_COLOR_HEADER}💻 JetBrains Module Help${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}========================${HELP_COLOR_RESET}"
    echo ""
    echo "IDE integration with smart project detection."
    echo "Supports all JetBrains tools with environment diagnosis."
    echo ""
    echo -e "${HELP_COLOR_MODULE}🚀 IDE Shortcuts:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}py <directory>${HELP_COLOR_RESET}         # Open in PyCharm"
    echo -e "  ${HELP_COLOR_FUNCTION}idea <directory>${HELP_COLOR_RESET}       # Open in IntelliJ IDEA"
    echo -e "  ${HELP_COLOR_FUNCTION}ws <directory>${HELP_COLOR_RESET}         # Open in WebStorm"
    echo -e "  ${HELP_COLOR_FUNCTION}dg${HELP_COLOR_RESET}                     # Open DataGrip"
    echo -e "  ${HELP_COLOR_FUNCTION}ds <directory>${HELP_COLOR_RESET}         # Open in DataSpell"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🎯 Smart Project Detection:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}open_project <directory>${HELP_COLOR_RESET} # Auto-detect project type, open appropriate IDE"
    echo -e "  ${HELP_COLOR_FUNCTION}project <directory>${HELP_COLOR_RESET}    # Same as open_project"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔍 Diagnostics:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}jetbrains_status${HELP_COLOR_RESET}       # Show JetBrains installation status"
    echo -e "  ${HELP_COLOR_FUNCTION}jb-status${HELP_COLOR_RESET}              # Alias for jetbrains_status"
    echo -e "  ${HELP_COLOR_FUNCTION}jetbrains_diagnose_env${HELP_COLOR_RESET} # Diagnose environment issues"
    echo -e "  ${HELP_COLOR_FUNCTION}jb-diagnose${HELP_COLOR_RESET}            # Alias for environment diagnosis"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🎨 Project Types Detected:${HELP_COLOR_RESET}"
    echo "  • Python projects → PyCharm"
    echo "  • Java projects → IntelliJ IDEA"
    echo "  • Web projects → WebStorm"
    echo "  • Data projects → DataSpell"
    echo "  • Mixed projects → Smart selection"
}

show_docker_help() {
    echo -e "${HELP_COLOR_HEADER}🐳 Docker Module Help${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}=====================${HELP_COLOR_RESET}"
    echo ""
    echo "Container management and development utilities."
    echo "Includes container detection and optimization."
    echo ""
    echo -e "${HELP_COLOR_MODULE}📊 Status & Management:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}docker_status${HELP_COLOR_RESET}          # Comprehensive Docker system status"
    echo -e "  ${HELP_COLOR_FUNCTION}dstatus${HELP_COLOR_RESET}                # Alias for docker_status"
    echo -e "  ${HELP_COLOR_FUNCTION}docker_cleanup${HELP_COLOR_RESET}         # Clean unused containers and images"
    echo -e "  ${HELP_COLOR_FUNCTION}docker_deep_clean${HELP_COLOR_RESET}      # Aggressive cleanup (with confirmation)"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🛠️ Development Utilities:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}docker_dev_env <language>${HELP_COLOR_RESET} # Quick development environments"
    echo "    # Supported: python, node, go, java"
    echo -e "  ${HELP_COLOR_FUNCTION}docker_shell <container>${HELP_COLOR_RESET} # Interactive shell in running container"
    echo -e "  ${HELP_COLOR_FUNCTION}docker_logs <container> [lines] [follow]${HELP_COLOR_RESET} # Container logs"
    echo -e "  ${HELP_COLOR_FUNCTION}docker_restart_container <name>${HELP_COLOR_RESET} # Restart specific container"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔍 Container Detection:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}is_in_container${HELP_COLOR_RESET}        # Check if running in container"
    echo -e "  ${HELP_COLOR_FUNCTION}container_host_info${HELP_COLOR_RESET}    # Show container environment details"
    echo ""
    echo -e "${HELP_COLOR_MODULE}⚡ Quick Aliases:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}d, dc, dps, di${HELP_COLOR_RESET}         # Docker shortcuts"
    echo -e "  ${HELP_COLOR_FUNCTION}dcup, dcdown, dcrestart${HELP_COLOR_RESET} # Docker Compose shortcuts"
    echo -e "  ${HELP_COLOR_FUNCTION}ddev, drun${HELP_COLOR_RESET}             # Development utilities"
}

show_spark_help() {
    echo -e "${HELP_COLOR_HEADER}⚡ Apache Spark Module Help${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}===========================${HELP_COLOR_RESET}"
    echo ""
    echo "Complete Apache Spark integration with all execution modes."
    echo "Supports local, distributed, and YARN execution."
    echo ""
    echo -e "${HELP_COLOR_MODULE}🏗️ Cluster Management:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}spark_start${HELP_COLOR_RESET}            # Start local Spark cluster"
    echo -e "  ${HELP_COLOR_FUNCTION}spark_stop${HELP_COLOR_RESET}             # Stop Spark cluster"
    echo -e "  ${HELP_COLOR_FUNCTION}spark_restart${HELP_COLOR_RESET}          # Restart cluster"
    echo -e "  ${HELP_COLOR_FUNCTION}spark_status${HELP_COLOR_RESET}           # Show cluster and configuration status"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🚀 Job Submission:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}smart_spark_submit <script>${HELP_COLOR_RESET} # Auto-detect best execution mode"
    echo -e "  ${HELP_COLOR_FUNCTION}default_spark_submit <script>${HELP_COLOR_RESET} # Local mode execution"
    echo -e "  ${HELP_COLOR_FUNCTION}distributed_spark_submit <script>${HELP_COLOR_RESET} # Distributed cluster mode"
    echo -e "  ${HELP_COLOR_FUNCTION}spark_yarn_submit <script>${HELP_COLOR_RESET} # YARN cluster mode"
    echo -e "  ${HELP_COLOR_FUNCTION}heavy_api_submit <script>${HELP_COLOR_RESET} # Optimized for API-heavy workloads"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🐚 Interactive Shells:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}spark_shell${HELP_COLOR_RESET}            # Scala Spark shell with dependencies"
    echo -e "  ${HELP_COLOR_FUNCTION}pyspark_shell${HELP_COLOR_RESET}          # Python Spark shell with dependencies"
    echo ""
    echo -e "${HELP_COLOR_MODULE}⚡ Quick Aliases:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}spark-start, spark-stop, spark-status${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}spark-submit-local, spark-submit-smart${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🎯 Execution Modes:${HELP_COLOR_RESET}"
    echo "  • Local: Uses all CPU cores on current machine"
    echo "  • Distributed: Uses Spark cluster (start with spark_start)"
    echo "  • YARN: Integrates with Hadoop YARN resource manager"
    echo "  • Smart: Auto-detects best mode based on available resources"
}

show_hadoop_help() {
    echo -e "${HELP_COLOR_HEADER}🐘 Hadoop Module Help${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}=====================${HELP_COLOR_RESET}"
    echo ""
    echo "Complete Hadoop ecosystem management."
    echo "HDFS, YARN, and MapReduce with Java 17+ compatibility."
    echo ""
    echo -e "${HELP_COLOR_MODULE}🏗️ Cluster Management:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}start_hadoop${HELP_COLOR_RESET}           # Start HDFS and YARN services"
    echo -e "  ${HELP_COLOR_FUNCTION}stop_hadoop${HELP_COLOR_RESET}            # Stop Hadoop services"
    echo -e "  ${HELP_COLOR_FUNCTION}restart_hadoop${HELP_COLOR_RESET}         # Restart Hadoop cluster"
    echo -e "  ${HELP_COLOR_FUNCTION}hadoop_status${HELP_COLOR_RESET}          # Comprehensive Hadoop status"
    echo ""
    echo -e "${HELP_COLOR_MODULE}📁 HDFS Operations:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}hdfs-format${HELP_COLOR_RESET}            # Format HDFS namenode"
    echo -e "  ${HELP_COLOR_FUNCTION}test_hadoop_integration${HELP_COLOR_RESET} # Test basic HDFS functionality"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🧶 YARN Management:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}yarn_application_list${HELP_COLOR_RESET}  # List all YARN applications"
    echo -e "  ${HELP_COLOR_FUNCTION}yarn_kill_all_apps${HELP_COLOR_RESET}     # Kill all running YARN applications"
    echo -e "  ${HELP_COLOR_FUNCTION}yarn_logs <app_id>${HELP_COLOR_RESET}     # View logs for specific application"
    echo -e "  ${HELP_COLOR_FUNCTION}yarn_cluster_info${HELP_COLOR_RESET}      # Show YARN cluster information"
    echo ""
    echo -e "${HELP_COLOR_MODULE}⚙️ Configuration:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}setup_yarn_config${HELP_COLOR_RESET}      # Configure YARN settings"
    echo -e "  ${HELP_COLOR_FUNCTION}setup_java17_hadoop_compatibility${HELP_COLOR_RESET} # Fix Java 17+ compatibility"
    echo ""
    echo -e "${HELP_COLOR_MODULE}⚡ Quick Aliases:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}hadoop-start, hadoop-stop, hadoop-status${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}yarn-apps, yarn-kill-all, yarn-info${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🌐 Web UIs:${HELP_COLOR_RESET}"
    echo "  • HDFS NameNode: http://localhost:9870"
    echo "  • YARN ResourceManager: http://localhost:8088"
    echo "  • DataNode: http://localhost:9864"
}

show_backup_help() {
    echo -e "${HELP_COLOR_HEADER}📦 Backup Toggle Module Help${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}=============================${HELP_COLOR_RESET}"
    echo ""
    echo "Auto-backup control system to prevent unwanted commits."
    echo "Provides safe toggle functionality for backup automation."
    echo ""
    echo -e "${HELP_COLOR_MODULE}📊 Status & Control:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}backup_status${HELP_COLOR_RESET}          # Show current auto-backup status and settings"
    echo -e "  ${HELP_COLOR_FUNCTION}backup-status${HELP_COLOR_RESET}          # Alias for backup_status"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔄 Toggle Controls:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}backup_auto_on${HELP_COLOR_RESET}         # Enable auto-backup system"
    echo -e "  ${HELP_COLOR_FUNCTION}backup-on${HELP_COLOR_RESET}              # Alias for backup_auto_on"
    echo -e "  ${HELP_COLOR_FUNCTION}backup_auto_off${HELP_COLOR_RESET}        # Disable auto-backup system"
    echo -e "  ${HELP_COLOR_FUNCTION}backup-off${HELP_COLOR_RESET}             # Alias for backup_auto_off"
    echo -e "  ${HELP_COLOR_FUNCTION}backup_auto_toggle${HELP_COLOR_RESET}     # Toggle auto-backup on/off"
    echo -e "  ${HELP_COLOR_FUNCTION}backup-toggle${HELP_COLOR_RESET}          # Alias for backup_auto_toggle"
    echo ""
    echo -e "${HELP_COLOR_MODULE}⚙️ Configuration Management:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}backup_auto_disable_permanent${HELP_COLOR_RESET} # Permanently disable in config file"
    echo -e "  ${HELP_COLOR_FUNCTION}backup-disable${HELP_COLOR_RESET}         # Alias for permanent disable"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🛡️ What Auto-Backup Provides:${HELP_COLOR_RESET}"
    echo "  • Automatic configuration backups when files change"
    echo "  • Time-based backup intervals (default: 1 hour)"
    echo "  • Safe toggle system to prevent unwanted commits"
    echo "  • Status monitoring and diagnostics"
    echo "  • Hook management (preexec_functions control)"
    echo ""
    echo -e "${HELP_COLOR_MODULE}💡 Usage Examples:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}backup-status${HELP_COLOR_RESET}          # Check if auto-backup is active"
    echo -e "  ${HELP_COLOR_EXAMPLE}backup-off${HELP_COLOR_RESET}             # Disable to prevent unwanted commits"
    echo -e "  ${HELP_COLOR_EXAMPLE}backup-toggle${HELP_COLOR_RESET}          # Switch auto-backup on or off"
}

# =====================================================
# SYSTEM HELP
# =====================================================

show_status_help() {
    echo -e "${HELP_COLOR_HEADER}📊 System Status Commands${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}=========================${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🎯 Main Status Commands:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}modular_zsh_status${HELP_COLOR_RESET}     # Complete module status overview"
    echo -e "  ${HELP_COLOR_FUNCTION}zsh-status${HELP_COLOR_RESET}             # Alias for modular_zsh_status"
    echo -e "  ${HELP_COLOR_FUNCTION}environment_info${HELP_COLOR_RESET}       # Platform and environment details"
    echo -e "  ${HELP_COLOR_FUNCTION}env-info${HELP_COLOR_RESET}               # Alias for environment_info"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔐 Security Status:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}credential_backend_status${HELP_COLOR_RESET} # Security system status"
    echo -e "  ${HELP_COLOR_FUNCTION}creds-status${HELP_COLOR_RESET}           # Alias for credential status"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🛠️ Tool-Specific Status:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}database_status${HELP_COLOR_RESET}        # Database configuration status"
    echo -e "  ${HELP_COLOR_FUNCTION}docker_status${HELP_COLOR_RESET}          # Docker system status (if available)"
    echo -e "  ${HELP_COLOR_FUNCTION}spark_status${HELP_COLOR_RESET}           # Spark cluster status (if available)"
    echo -e "  ${HELP_COLOR_FUNCTION}hadoop_status${HELP_COLOR_RESET}          # Hadoop cluster status (if available)"
    echo -e "  ${HELP_COLOR_FUNCTION}jetbrains_status${HELP_COLOR_RESET}       # JetBrains tools status (if available)"
    echo -e "  ${HELP_COLOR_FUNCTION}backup_status${HELP_COLOR_RESET}          # Auto-backup system status"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔄 Configuration Management:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}zsh-reload${HELP_COLOR_RESET}             # Reload entire configuration"
    echo -e "  ${HELP_COLOR_FUNCTION}zsh-verbose${HELP_COLOR_RESET}            # Reload with verbose module loading"
}

show_testing_help() {
    echo -e "${HELP_COLOR_HEADER}🧪 Testing & Validation${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}=======================${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔍 Cross-Platform Test Suite:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}./test-modular-quick.sh${HELP_COLOR_RESET}      # Quick validation test (recommended)"
    echo -e "  ${HELP_COLOR_FUNCTION}./test-cross-platform.sh${HELP_COLOR_RESET}     # Comprehensive compatibility tests"
    echo ""
    echo -e "${HELP_COLOR_MODULE}📋 Test Coverage:${HELP_COLOR_RESET}"
    echo "  ✅ Platform detection (macos, linux, docker, wsl)"
    echo "  ✅ All 10 modules load successfully"
    echo "  ✅ All core functions available"
    echo "  ✅ All status functions working"
    echo "  ✅ Cross-platform utilities functional"
    echo "  ✅ Credential system working"
    echo "  ✅ Startup performance <2 seconds"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🛠️ Manual Testing Commands:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}echo \$CORE_MODULE_LOADED${HELP_COLOR_RESET}      # Check core module"
    echo -e "  ${HELP_COLOR_FUNCTION}echo \$ENVIRONMENT_MODULE_LOADED${HELP_COLOR_RESET} # Check environment module"
    echo -e "  ${HELP_COLOR_FUNCTION}command -v docker_status${HELP_COLOR_RESET}      # Check function availability"
    echo -e "  ${HELP_COLOR_FUNCTION}time zsh -c 'source zshrc'${HELP_COLOR_RESET}   # Measure startup time"
    echo ""
    echo -e "${HELP_COLOR_MODULE}⏱️ Performance Testing:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}ZSH_STARTUP_TIMING=true source zshrc${HELP_COLOR_RESET} # Show timing details"
    echo -e "  ${HELP_COLOR_FUNCTION}echo \${#LOADED_MODULES[@]}${HELP_COLOR_RESET}   # Count loaded modules"
}

show_customization_help() {
    echo -e "${HELP_COLOR_HEADER}🔧 Customization & Configuration${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}================================${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}📁 Customization Files:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}~/.config/zsh/user.zsh${HELP_COLOR_RESET}   # Personal customizations (gitignored)"
    echo -e "  ${HELP_COLOR_FUNCTION}~/.config/zsh/local.zsh${HELP_COLOR_RESET}  # Machine-specific settings (gitignored)"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🎯 Environment Variables:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}MODULAR_ZSHRC_VERBOSE=\"true\"${HELP_COLOR_RESET}     # Show module loading messages"
    echo -e "  ${HELP_COLOR_FUNCTION}ZSH_STARTUP_TIMING=\"true\"${HELP_COLOR_RESET}        # Display startup performance"
    echo -e "  ${HELP_COLOR_FUNCTION}SPARK_DRIVER_MEMORY=\"4g\"${HELP_COLOR_RESET}         # Spark configuration"
    echo -e "  ${HELP_COLOR_FUNCTION}HADOOP_HEAPSIZE=\"1024\"${HELP_COLOR_RESET}           # Hadoop JVM settings"
    echo ""
    echo -e "${HELP_COLOR_MODULE}💡 Example user.zsh:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}export PREFERRED_VENV=\"myproject\"${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}export SPARK_DRIVER_MEMORY=\"8g\"${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}alias myalias=\"my custom command\"${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔄 Apply Changes:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}zsh-reload${HELP_COLOR_RESET}               # Reload configuration after changes"
}

show_quick_start_help() {
    echo -e "${HELP_COLOR_HEADER}🚀 Quick Start Guide${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}===================${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🎯 New Installation:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}cd ~/.config/zsh && source zshrc${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}modular_zsh_status${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🔄 Existing Installation:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}cd ~/.config/zsh && git pull origin main${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}source zshrc${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_EXAMPLE}zsh-status${HELP_COLOR_RESET}"
    echo ""
    echo -e "${HELP_COLOR_MODULE}✅ Essential First Commands:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}modular_zsh_status${HELP_COLOR_RESET}      # Check what modules loaded"
    echo -e "  ${HELP_COLOR_FUNCTION}environment_info${HELP_COLOR_RESET}        # See platform details"
    echo -e "  ${HELP_COLOR_FUNCTION}zsh_help modules${HELP_COLOR_RESET}        # List all available modules"
    echo -e "  ${HELP_COLOR_FUNCTION}credential_backend_status${HELP_COLOR_RESET} # Check security system"
    echo ""
    echo -e "${HELP_COLOR_MODULE}🧪 Test Your Setup:${HELP_COLOR_RESET}"
    echo -e "  ${HELP_COLOR_FUNCTION}./test-modular-quick.sh${HELP_COLOR_RESET}      # Quick validation test"
    echo -e "  ${HELP_COLOR_FUNCTION}./test-cross-platform.sh${HELP_COLOR_RESET}     # Full compatibility tests"
    echo -e "  ${HELP_COLOR_FUNCTION}mkcd /tmp/test${HELP_COLOR_RESET}          # Test core functions"
    echo -e "  ${HELP_COLOR_FUNCTION}time zsh -c 'source zshrc'${HELP_COLOR_RESET} # Check startup time"
}

# =====================================================
# SEARCH FUNCTIONALITY
# =====================================================

search_help() {
    local search_term="$1"
    
    if [[ -z "$search_term" ]]; then
        echo -e "${HELP_COLOR_HEADER}🔍 Help Search${HELP_COLOR_RESET}"
        echo ""
        echo "Usage: zsh_help search <term>"
        echo ""
        echo "Examples:"
        echo "  zsh_help search password    # Find credential functions"
        echo "  zsh_help search docker      # Find container functions"
        echo "  zsh_help search spark       # Find Spark functions"
        echo "  zsh_help search status      # Find status commands"
        return
    fi
    
    echo -e "${HELP_COLOR_HEADER}🔍 Search Results for: $search_term${HELP_COLOR_RESET}"
    echo -e "${HELP_COLOR_HEADER}=================================${HELP_COLOR_RESET}"
    echo ""
    
    # Search through different categories based on search term
    local search_lower=$(echo "$search_term" | tr '[:upper:]' '[:lower:]')
    case "$search_lower" in
        *password*|*credential*|*auth*|*security*)
            echo -e "${HELP_COLOR_MODULE}🔐 Credential Functions:${HELP_COLOR_RESET}"
            echo -e "  ${HELP_COLOR_FUNCTION}get_credential${HELP_COLOR_RESET} - Get credential from any backend"
            echo -e "  ${HELP_COLOR_FUNCTION}credential_backend_status${HELP_COLOR_RESET} - Show available backends"
            echo -e "  ${HELP_COLOR_FUNCTION}get_postgres_password${HELP_COLOR_RESET} - Get PostgreSQL password"
            echo -e "  ${HELP_COLOR_FUNCTION}setup_postgres_credentials${HELP_COLOR_RESET} - Setup secure PostgreSQL"
            echo "  Use: zsh_help credentials"
            ;;
        *docker*|*container*)
            echo -e "${HELP_COLOR_MODULE}🐳 Container Functions:${HELP_COLOR_RESET}"
            echo -e "  ${HELP_COLOR_FUNCTION}docker_status${HELP_COLOR_RESET} - Docker system status"
            echo -e "  ${HELP_COLOR_FUNCTION}docker_cleanup${HELP_COLOR_RESET} - Clean containers and images"
            echo -e "  ${HELP_COLOR_FUNCTION}docker_dev_env${HELP_COLOR_RESET} - Development environments"
            echo -e "  ${HELP_COLOR_FUNCTION}is_in_container${HELP_COLOR_RESET} - Check if in container"
            echo "  Use: zsh_help docker"
            ;;
        *spark*)
            echo -e "${HELP_COLOR_MODULE}⚡ Spark Functions:${HELP_COLOR_RESET}"
            echo -e "  ${HELP_COLOR_FUNCTION}spark_start${HELP_COLOR_RESET} - Start Spark cluster"
            echo -e "  ${HELP_COLOR_FUNCTION}smart_spark_submit${HELP_COLOR_RESET} - Auto-detect execution mode"
            echo -e "  ${HELP_COLOR_FUNCTION}spark_status${HELP_COLOR_RESET} - Cluster status"
            echo -e "  ${HELP_COLOR_FUNCTION}heavy_api_submit${HELP_COLOR_RESET} - API-optimized submission"
            echo "  Use: zsh_help spark"
            ;;
        *hadoop*|*hdfs*|*yarn*)
            echo -e "${HELP_COLOR_MODULE}🐘 Hadoop Functions:${HELP_COLOR_RESET}"
            echo -e "  ${HELP_COLOR_FUNCTION}start_hadoop${HELP_COLOR_RESET} - Start HDFS and YARN"
            echo -e "  ${HELP_COLOR_FUNCTION}hadoop_status${HELP_COLOR_RESET} - Cluster status"
            echo -e "  ${HELP_COLOR_FUNCTION}yarn_application_list${HELP_COLOR_RESET} - List YARN apps"
            echo -e "  ${HELP_COLOR_FUNCTION}test_hadoop_integration${HELP_COLOR_RESET} - Test HDFS"
            echo "  Use: zsh_help hadoop"
            ;;
        *database*|*postgres*|*mysql*)
            echo -e "${HELP_COLOR_MODULE}🗄️ Database Functions:${HELP_COLOR_RESET}"
            echo -e "  ${HELP_COLOR_FUNCTION}database_status${HELP_COLOR_RESET} - Database configuration status"
            echo -e "  ${HELP_COLOR_FUNCTION}pg_test_connection${HELP_COLOR_RESET} - Test PostgreSQL"
            echo -e "  ${HELP_COLOR_FUNCTION}setup_postgres_credentials${HELP_COLOR_RESET} - Setup PostgreSQL"
            echo "  Use: zsh_help database"
            ;;
        *ide*|*pycharm*|*jetbrains*)
            echo -e "${HELP_COLOR_MODULE}💻 IDE Functions:${HELP_COLOR_RESET}"
            echo -e "  ${HELP_COLOR_FUNCTION}py${HELP_COLOR_RESET} - Open in PyCharm"
            echo -e "  ${HELP_COLOR_FUNCTION}idea${HELP_COLOR_RESET} - Open in IntelliJ"
            echo -e "  ${HELP_COLOR_FUNCTION}open_project${HELP_COLOR_RESET} - Smart project detection"
            echo -e "  ${HELP_COLOR_FUNCTION}jetbrains_status${HELP_COLOR_RESET} - IDE status"
            echo "  Use: zsh_help jetbrains"
            ;;
        *status*)
            echo -e "${HELP_COLOR_MODULE}📊 Status Functions:${HELP_COLOR_RESET}"
            echo -e "  ${HELP_COLOR_FUNCTION}modular_zsh_status${HELP_COLOR_RESET} - Module status"
            echo -e "  ${HELP_COLOR_FUNCTION}environment_info${HELP_COLOR_RESET} - Platform info"
            echo -e "  ${HELP_COLOR_FUNCTION}credential_backend_status${HELP_COLOR_RESET} - Security status"
            echo -e "  ${HELP_COLOR_FUNCTION}docker_status${HELP_COLOR_RESET} - Docker status"
            echo "  Use: zsh_help status"
            ;;
        *platform*|*environment*)
            echo -e "${HELP_COLOR_MODULE}🌍 Platform Functions:${HELP_COLOR_RESET}"
            echo -e "  ${HELP_COLOR_FUNCTION}environment_info${HELP_COLOR_RESET} - Complete system info"
            echo -e "  ${HELP_COLOR_FUNCTION}platform_open${HELP_COLOR_RESET} - Cross-platform file open"
            echo -e "  ${HELP_COLOR_FUNCTION}is_container${HELP_COLOR_RESET} - Container detection"
            echo -e "  ${HELP_COLOR_FUNCTION}platform_copy${HELP_COLOR_RESET} - Cross-platform clipboard"
            echo "  Use: zsh_help environment"
            ;;
        *backup*|*commit*|*auto-backup*)
            echo -e "${HELP_COLOR_MODULE}📦 Backup Functions:${HELP_COLOR_RESET}"
            echo -e "  ${HELP_COLOR_FUNCTION}backup_status${HELP_COLOR_RESET} - Show auto-backup status"
            echo -e "  ${HELP_COLOR_FUNCTION}backup_auto_on${HELP_COLOR_RESET} - Enable auto-backup"
            echo -e "  ${HELP_COLOR_FUNCTION}backup_auto_off${HELP_COLOR_RESET} - Disable auto-backup"
            echo -e "  ${HELP_COLOR_FUNCTION}backup_auto_toggle${HELP_COLOR_RESET} - Toggle auto-backup"
            echo "  Use: zsh_help backup"
            ;;
        *)
            echo "No specific matches found for '$search_term'"
            echo ""
            echo "Try searching for:"
            echo "  password, credential, security"
            echo "  docker, container"
            echo "  spark, hadoop"
            echo "  database, postgres, mysql"
            echo "  ide, pycharm, jetbrains"
            echo "  status, environment, platform"
            echo "  backup, commit, auto-backup"
            ;;
    esac
}

# =====================================================
# ALIASES
# =====================================================

# Main help alias
alias help='zsh_help'

# Quick access aliases
alias help-modules='zsh_help modules'
alias help-status='zsh_help status'
alias help-search='zsh_help search'

# Module-specific help aliases
alias help-core='zsh_help core'
alias help-credentials='zsh_help credentials'
alias help-database='zsh_help database'
alias help-docker='zsh_help docker'
alias help-spark='zsh_help spark'
alias help-hadoop='zsh_help hadoop'
alias help-backup='zsh_help backup'

# Show help system is loaded
if [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]]; then
    echo "📚 Help: Interactive help system v${HELP_MODULE_VERSION}"
fi