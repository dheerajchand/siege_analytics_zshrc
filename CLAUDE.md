# CLAUDE.md

This file provides comprehensive guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 🎉 **CROSS-SHELL ARCHITECTURE COMPLETE (v4.0)**

**MAJOR ACHIEVEMENT**: Complete cross-shell compatibility layer added! System now works seamlessly in **both bash and zsh** with full cross-platform support and **86% size reduction** from original monolithic config.

### Quick Status Check
```bash
# Check system status and loaded modules (works in bash AND zsh)
modular_zsh_status              # Show all module loading status
environment_info               # Platform detection and system info
credential_backend_status      # Security system status
python_info                    # Python/UV environment status
backup_status                  # Auto-backup system status and control
```

### System Overview
```bash
# Performance metrics achieved:
📊 Size reduction: 2,435 → 350 lines (86% reduction)
🐚 Shell compatibility: Bash + ZSH seamless operation
⚡ Startup time: <2 seconds in both shells
🎯 Modules: 10 focused modules with cross-shell compatibility
🌍 Platforms: macOS, Linux, Docker, WSL fully supported
🔐 Security: Multi-backend credential management
🔬 Data Science: Enhanced Python/UV + Spark/Hadoop integration
```

---

## 📦 **Module System Architecture**

### **Complete Module List (10 active modules)**
```bash
🔄 shell-compat.zsh   # Cross-shell compatibility (bash+zsh) - LOADS FIRST
🔧 core.zsh           # Essential shell configuration (always loads)
🌍 environment.zsh    # Cross-platform detection & optimization  
🔐 credentials.zsh    # Multi-backend security system
🗄️ database.zsh       # PostgreSQL, MySQL, Snowflake integration
💻 jetbrains.zsh      # IDE integration with project detection
⚡ spark.zsh          # Apache Spark (cross-shell compatible)
🐘 hadoop.zsh         # HDFS, YARN, MapReduce management
🐳 docker.zsh         # Container management & development
📦 backup-toggle.zsh  # Auto-backup control system (prevents unwanted commits)
❓ help.zsh           # Interactive documentation system
```

### **Dynamic Loading Status Commands**
```bash
# System status
modular_zsh_status          # Complete module status overview
zsh-status                  # Alias for modular_zsh_status
zsh-reload                  # Reload entire configuration
zsh-verbose                 # Reload with verbose module loading

# Platform detection
echo $ZSH_PLATFORM          # Shows: macos, linux, unknown
echo $ZSH_IS_DOCKER         # Shows: true/false
echo $IS_WSL                # Shows: true/false for Windows Subsystem
environment_info            # Comprehensive platform information
```

---

## 🛠️ **Module-Specific Commands**

### **Core Module** (Always Available)
```bash
# Utility functions
mkcd /path/to/new/dir       # Create directory and cd into it
extract archive.tar.gz      # Universal archive extraction
is_online                   # Check internet connectivity
command_exists docker       # Check if command is available

# Path management
path_add /custom/bin        # Add to PATH safely
path_remove /old/path       # Remove from PATH

# Enhanced aliases
ll, la, l                   # Enhanced ls with colors
gs, gp, gc                  # Git shortcuts
zshreboot                   # Restart zsh
```

### **Environment Module** (Cross-Platform)
```bash
# Platform detection
echo $ZSH_PLATFORM          # Current platform (macos/linux/unknown)
echo $ZSH_DISTRO            # Linux distribution (ubuntu/rhel/arch/etc)
echo $ZSH_IS_DOCKER         # Container detection
echo $IS_MACOS, $IS_LINUX   # Platform flags

# Cross-platform utilities
platform_open file.txt     # Open file with default application
platform_copy < file.txt   # Copy to system clipboard
platform_paste > out.txt   # Paste from system clipboard
platform_browser url       # Open URL in default browser

# Information commands
environment_info            # Complete system information
env-info                   # Alias for environment_info
platform-info              # Platform detection details
container-info             # Container environment info
```

### **Credentials Module** (Security System)
```bash
# Multi-backend credential management
get_credential "postgres" "myuser" "PASSWORD"    # Get credential from any backend
credential_backend_status   # Show available backends
creds-status               # Alias for credential status

# Backend priority: env vars → 1Password → Apple Keychain → interactive prompt
detect_credential_backends  # Scan for available credential systems

# Usage examples
export PGPASSWORD=$(get_credential "postgres" "$PGUSER" "PASSWORD")
password=$(get_credential "myservice" "myuser")
```

### **Database Module** (Secure Database Access)
```bash
# Database status and configuration
database_status            # Show all database configurations
db-status                  # Alias for database status

# PostgreSQL
setup_postgres_credentials  # Setup secure PostgreSQL credentials
pg_test_connection         # Test PostgreSQL connection
pg                         # Connect to PostgreSQL with auto-credentials
pgtest                     # Test PostgreSQL connection

# Credential integration
get_postgres_password      # Get PostgreSQL password from secure storage
setup_mysql_credentials    # Setup MySQL credentials

# Aliases
pg, mysql-local            # Database connections with auto-credentials
```

### **JetBrains Module** (IDE Integration)
```bash
# IDE shortcuts with project detection
py project_dir             # Open in PyCharm
idea project_dir           # Open in IntelliJ IDEA  
ws project_dir             # Open in WebStorm
dg                         # Open DataGrip
ds project_dir             # Open in DataSpell

# Smart project detection
open_project .             # Auto-detect project type, open in appropriate IDE
project ~/my_app           # Same as above

# Diagnostics and troubleshooting
jetbrains_status           # Show JetBrains installation status
jb-status                  # Alias for jetbrains_status
jetbrains_diagnose_env     # Diagnose environment issues
jb-diagnose                # Alias for environment diagnosis
```

### **Docker Module** (Container Management)
```bash
# Status and management
docker_status              # Comprehensive Docker system status
dstatus                   # Alias for docker_status
docker_cleanup            # Clean unused containers and images
docker_deep_clean         # Aggressive cleanup (with confirmation)

# Development utilities
docker_dev_env python     # Quick Python development environment
docker_shell myapp        # Interactive shell in running container
docker_logs myapp 50 true # Follow container logs (50 lines, follow)
docker_restart_container myapp  # Restart specific container

# Container detection
is_in_container           # Check if currently running in container
container_host_info       # Show container environment details

# Aliases
d, dc, dps, di           # Docker shortcuts
dcup, dcdown, dcrestart  # Docker Compose shortcuts
ddev, drun               # Development utilities
```

### **Backup Toggle Module** (Auto-Backup Control)
```bash
# Status and control
backup_status                  # Show current auto-backup status and settings
backup-status                  # Alias for backup_status

# Toggle controls
backup_auto_on                 # Enable auto-backup system
backup-on                      # Alias for backup_auto_on
backup_auto_off                # Disable auto-backup system  
backup-off                     # Alias for backup_auto_off
backup_auto_toggle             # Toggle auto-backup on/off
backup-toggle                  # Alias for backup_auto_toggle

# Configuration management
backup_auto_disable_permanent  # Permanently disable in configuration file
backup-disable                 # Alias for backup_auto_disable_permanent

# Auto-backup provides:
# - Automatic configuration backups when files change
# - Time-based backup intervals (default: 1 hour)
# - Safe toggle system to prevent unwanted commits
# - Status monitoring and diagnostics
# - Hook management (preexec_functions control)
```

### **Spark Module** (Apache Spark)
```bash
# Cluster management
spark_start               # Start local Spark cluster
spark_stop                # Stop Spark cluster
spark_restart             # Restart cluster
spark_status              # Show cluster and configuration status

# Job submission (multiple modes)
smart_spark_submit script.py          # Auto-detect best execution mode
default_spark_submit script.py        # Local mode execution
distributed_spark_submit script.py    # Distributed cluster mode
spark_yarn_submit script.py           # YARN cluster mode
heavy_api_submit script.py            # Optimized for API-heavy workloads

# Interactive shells
spark_shell               # Scala Spark shell with dependencies
pyspark_shell            # Python Spark shell with dependencies

# Aliases
spark-start, spark-stop, spark-status
spark-submit-local, spark-submit-smart
```

### **Hadoop Module** (Big Data Ecosystem)
```bash
# Hadoop cluster management
start_hadoop              # Start HDFS and YARN services
stop_hadoop               # Stop Hadoop services  
restart_hadoop            # Restart Hadoop cluster
hadoop_status             # Comprehensive Hadoop status

# HDFS operations
hdfs-format               # Format HDFS namenode
test_hadoop_integration   # Test basic HDFS functionality

# YARN management  
yarn_application_list     # List all YARN applications
yarn_kill_all_apps       # Kill all running YARN applications
yarn_logs app_id          # View logs for specific application
yarn_cluster_info         # Show YARN cluster information

# Configuration
setup_yarn_config         # Configure YARN settings
setup_java17_hadoop_compatibility  # Fix Java 17+ compatibility

# Aliases
hadoop-start, hadoop-stop, hadoop-status
yarn-apps, yarn-kill-all, yarn-info
```

---

## 🔬 **Data Science Integration (Enhanced)**

### **Python/UV Environment Management**
```bash
# Environment switching (cross-shell compatible)
py-switch list             # List all Python environments
py-switch myenv            # Switch to pyenv environment
py-switch uv              # Activate UV project in current directory
py-info                   # Show Python environment status

# Data science project creation
ds-init myproject         # Basic data science project
ds-init myproject spark   # Project with Spark dependencies  
ds-init myproject geo     # Project with geospatial tools

# UV integration features
# - Auto-activates when entering UV project directories
# - Works in both bash and zsh
# - Compatible with pyenv environments
```

### **Advanced Spark Integration** 
```bash
# Your sophisticated JAR management system:
get_spark_dependencies    # Intelligent JAR discovery across:
                         #   $HOME/spark-jars (personal)
                         #   $HOME/.spark/jars (spark-specific)
                         #   $SPARK_HOME/jars (installation)
                         #   $HOME/local-jars (development)

# Multi-mode execution (auto-detection):
smart_spark_submit script.py        # Auto-detects best execution mode
heavy_api_submit script.py yarn     # API-intensive workload optimization
spark_yarn_submit script.py         # Enterprise YARN integration
```

---

## 🧪 **Testing & Validation**

### **Test Suite Options**
```bash
# Quick validation test (recommended for daily use)
./test-modular-quick.sh         # Fast 5-second test of core functionality

# Comprehensive compatibility tests (for full validation)
./test-cross-platform-enhanced.sh   # Complete test suite (may take longer)

# Quick test results include:
✅ Configuration loads without hanging
✅ All core modules load successfully  
✅ Essential functions are available
✅ Status commands work
✅ Startup performance under 3 seconds

# Full test results include:
✅ Cross-shell compatibility (bash + zsh)
✅ Platform detection (macOS, Linux, Docker, WSL)
✅ All 10 modules load successfully
✅ All core functions available
✅ Python/UV integration working
✅ Spark JAR management functional
✅ Cross-platform utilities functional
✅ Credential system working
```

### **Module Testing Commands**
```bash
# Test individual modules
zsh -c 'source zshrc && echo $CORE_MODULE_LOADED'        # Core module
zsh -c 'source zshrc && echo $ENVIRONMENT_MODULE_LOADED' # Environment
zsh -c 'source zshrc && echo $DOCKER_MODULE_LOADED'      # Docker
zsh -c 'source zshrc && echo $SPARK_MODULE_LOADED'       # Spark

# Function availability testing
zsh -c 'source zshrc && command -v docker_status'        # Check function exists
zsh -c 'source zshrc && docker_status' | head -5         # Test function works

# Performance testing
time zsh -c 'source zshrc >/dev/null 2>&1'              # Measure startup time
ZSH_STARTUP_TIMING=true source zshrc                     # Show timing info
```

---

## 🌍 **Cross-Platform Support**

### **Platform Detection and Adaptation**
```bash
# Automatic platform detection
Platform Support:
  ✅ macOS (Intel + Apple Silicon)
  ✅ Linux (Ubuntu, RHEL, Debian, Arch, Alpine, etc.)
  ✅ Docker containers (all base images)
  ✅ WSL (Windows Subsystem for Linux)
  ✅ Remote servers via SSH

# Platform-specific optimizations
Memory Settings:
  🐳 Container: Reduced memory for Spark/Hadoop (512MB/256MB)
  🖥️  Host: Full memory utilization (2GB/1GB)

Package Manager Detection:
  🍎 macOS: brew, macports
  🐧 Linux: apt, yum, dnf, zypper, pacman, apk
  🐳 Container: Minimal assumptions, graceful fallbacks
```

### **Container-Specific Features**
```bash
# Container detection and optimization
is_container              # Returns true if running in any container
is_in_container          # Alias for is_container  
echo $ZSH_IS_DOCKER      # Environment variable for container detection

# Container optimizations applied automatically:
- Reduced memory limits for big data tools
- Minimal PATH assumptions  
- Package manager detection for container environments
- Optimized startup for resource-constrained environments
```

---

## 🔐 **Security & Credential Management**

### **Multi-Backend Credential System**
```bash
# Credential priority chain (automatic fallback):
1. Environment variables (preserves existing workflows)
2. 1Password CLI (op command)
3. macOS Keychain (security command)
4. Interactive prompts (fallback)

# Backend management
detect_credential_backends    # Scan for available backends
credential_backend_status    # Show status of all backends
creds-status                 # Alias for status

# Examples
export PGPASSWORD=$(get_credential "postgres" "$PGUSER" "PASSWORD")
api_key=$(get_credential "myapi" "$USER" "API_KEY")
```

### **Database Security Integration**
```bash
# Secure database connections
setup_postgres_credentials   # Migrate from env vars to secure storage
get_postgres_password        # Retrieve password from secure backend
pg_test_connection          # Test connection with secure credentials

# Migration tools
database_status             # Show current credential configuration
db-migrate                  # Migrate plaintext to secure storage (when available)
```

---

## 🔧 **Configuration & Customization**

### **User Customization Files**
```bash
# User-specific customizations (gitignored)
~/.config/zsh/user.zsh     # Personal customizations
~/.config/zsh/local.zsh    # Machine-specific settings

# Example user.zsh:
export PREFERRED_VENV="myproject"        # Auto-activate Python venv
export SPARK_DRIVER_MEMORY="4g"         # Custom Spark settings  
alias myalias="my custom command"       # Personal aliases
```

### **Environment Variables for Control**
```bash
# Module behavior control
export MODULAR_ZSHRC_VERBOSE="true"     # Show module loading messages
export ZSH_STARTUP_TIMING="true"        # Display startup performance
export SPARK_DRIVER_MEMORY="4g"         # Spark configuration
export HADOOP_HEAPSIZE="1024"           # Hadoop JVM settings
export DOCKER_BUILDKIT="1"              # Docker BuildKit support
```

---

## ❓ **Interactive Help System**

### **Help Commands**
```bash
# Main help system
zsh_help                    # Overview of all modules and functions
help                       # Alias for zsh_help

# Module-specific help
zsh_help core              # Core module functions
zsh_help environment       # Platform detection utilities  
zsh_help credentials       # Credential management
zsh_help database          # Database integration
zsh_help jetbrains         # IDE integration
zsh_help docker            # Container management
zsh_help spark             # Apache Spark functions
zsh_help hadoop            # Hadoop ecosystem

# Search functionality
zsh_help search password   # Find credential-related functions
zsh_help search docker     # Find container-related functions
zsh_help search pycharm    # Find IDE-related functions
```

---

## 🚨 **Troubleshooting Guide**

### **Common Issues and Solutions**

**Modules Not Loading**
```bash
# Diagnostic steps
modular_zsh_status                    # Check module load status
MODULAR_ZSHRC_VERBOSE=true source zshrc  # Reload with verbose output
echo $DOCKER_MODULE_LOADED            # Check specific module

# Solutions
source ~/.config/zsh/zshrc           # Reload configuration
zsh-reload                           # Use reload alias
```

**Functions Not Available**
```bash
# Check function existence
command -v docker_status             # Should show function path
type docker_status                   # Show function definition
which docker_status                  # Show function location

# Reload if needed
source ~/.config/zsh/zshrc
source ~/.config/zsh/config/docker.zsh  # Load specific module
```

**Platform Detection Issues**
```bash
# Check platform variables
echo $ZSH_PLATFORM                  # Should show: macos, linux, unknown
echo $ZSH_DISTRO                    # Linux distribution
echo $IS_DOCKER                     # true/false for containers
environment_info                    # Comprehensive platform info

# Manual platform detection
detect_platform                     # Re-run detection
```

**Performance Issues**
```bash
# Measure startup time
time zsh -c 'source ~/.config/zsh/zshrc'    # Should be <2 seconds
ZSH_STARTUP_TIMING=true source zshrc        # Show detailed timing

# Optimize if needed
echo ${#LOADED_MODULES[@]}          # Number of loaded modules
modular_zsh_status | grep "✅"      # Count successful loads
```

**Credential System Issues**
```bash
# Check backends
credential_backend_status           # Show available backends
detect_credential_backends         # Re-scan for backends

# Test credential retrieval
get_credential "postgres" "$USER" "PASSWORD"  # Should return password or error
```

---

## 📁 **Repository Structure & File Locations**

### **New Modular Structure**
```
~/.config/zsh/                      # Main configuration directory
├── zshrc                           # Main loader (350 lines vs 2,435)
├── zshrc.original                  # Backup of monolithic version
├── config/                         # Modular configuration files
│   ├── core.zsh                    # Essential shell configuration
│   ├── environment.zsh             # Cross-platform detection
│   ├── credentials.zsh             # Multi-backend security
│   ├── database.zsh                # Database integration
│   ├── jetbrains.zsh               # IDE integration
│   ├── spark.zsh                   # Apache Spark
│   ├── hadoop.zsh                  # Hadoop ecosystem
│   ├── docker.zsh                  # Container management
│   └── help.zsh                    # Documentation system
├── functions/                      # Additional function libraries
├── tests/                          # Testing framework
│   ├── test-framework.zsh         # Test utilities
│   └── test-modular-system.zsh    # Comprehensive module tests
├── test-cross-platform.sh         # Cross-platform compatibility test
├── README.md                       # Updated documentation
├── REFACTORING_PLAN.md            # Complete refactoring history
├── CLAUDE.md                      # This file
├── IDIOT_LEVEL_GUIDE.md           # Step-by-step setup guide
├── sync-repos.sh                  # Repository synchronization script
├── user.zsh                       # User customizations (gitignored)
└── local.zsh                      # Machine-specific settings (gitignored)
```

---

## 🎯 **Development Workflow (Updated)**

### **1. Check System Status**
```bash
modular_zsh_status          # Overall system status
environment_info            # Platform and environment details
credential_backend_status   # Security system status
docker_status              # Container system status (if available)
```

### **2. Work with Modules**
```bash
# Edit specific modules
$EDITOR ~/.config/zsh/config/core.zsh         # Core functionality
$EDITOR ~/.config/zsh/config/credentials.zsh  # Security system
$EDITOR ~/.config/zsh/config/database.zsh     # Database integration

# Reload after changes
zsh-reload                  # Reload entire configuration
zsh-verbose                 # Reload with detailed output
```

### **3. Test Changes**
```bash
# Test module loading
echo $CORE_MODULE_LOADED            # Should show "true"
command -v modular_zsh_status       # Should show function exists

# Run test suite
./test-cross-platform.sh           # Cross-platform compatibility
zsh tests/test-modular-system.zsh   # Module-specific tests

# Performance testing  
time zsh -c 'source zshrc'         # Should be <2 seconds
```

### **4. Validate Functionality**
```bash
# Test core functions
mkcd /tmp/test_dir              # Should create and enter directory
is_online && echo "Connected"   # Test network connectivity

# Test platform detection
echo $ZSH_PLATFORM              # Should show correct platform
environment_info                # Should show comprehensive info

# Test credential system (if configured)
credential_backend_status       # Should show available backends

# Test module-specific functionality
docker_status                   # If Docker available
spark_status                    # If Spark installed
hadoop_status                   # If Hadoop installed
```

---

## 🔄 **Migration & Backward Compatibility**

### **Preserved Functionality**
```bash
✅ All environment variables preserved
✅ All existing aliases continue to work
✅ PGPASSWORD workflow maintained
✅ Snowflake credentials preserved  
✅ SDKMAN integration unchanged
✅ Git configurations preserved
✅ Tool paths (Homebrew, etc.) maintained
```

### **Enhanced Features**
```bash
🆕 Cross-platform support (Linux, Docker, WSL)
🆕 Dynamic module loading
🆕 Multi-backend credential system
🆕 Container environment detection
🆕 Performance optimizations
🆕 Comprehensive error handling
🆕 Built-in testing framework
🆕 Enhanced status monitoring
```

---

## 🚀 **Key Benefits for Claude Code**

### **For Development Tasks**
1. **Module Isolation**: Issues can be isolated to specific modules
2. **Fast Iteration**: Reload individual modules instead of entire config  
3. **Clear Structure**: Easy to understand and modify focused modules
4. **Comprehensive Testing**: Built-in test framework for validation

### **For Cross-Platform Work**
1. **Platform Detection**: Automatic adaptation to different environments
2. **Container Support**: Optimized for Docker development workflows
3. **Resource Awareness**: Memory and performance optimizations
4. **Universal Commands**: Same commands work across all platforms

### **For Security & Credentials**
1. **Secure by Default**: No plaintext passwords in configuration
2. **Multiple Backends**: Flexible credential storage options
3. **Backward Compatible**: Existing workflows continue to work
4. **Easy Migration**: Tools to move to secure storage

---

## 🎉 **Status: Production Ready**

The modular system is complete and fully tested. All objectives achieved:

- ✅ **86% size reduction** (2,435 → 350 lines main config)
- ✅ **10 focused modules** replacing monolithic design
- ✅ **Full cross-platform support** (macOS, Linux, Docker, WSL)
- ✅ **<2 second startup time** with dynamic loading
- ✅ **Enterprise security** with multi-backend credentials
- ✅ **Auto-backup control system** preventing unwanted commits
- ✅ **Cross-repository synchronization** between development and archive
- ✅ **Comprehensive testing** with cross-platform test suite
- ✅ **Complete documentation** for all modules and functions
- ✅ **Interactive help system** with search functionality

The system is ready for production use and provides a solid foundation for future enhancements. Both development and archive repositories are synchronized and up-to-date.