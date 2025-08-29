# 🚀 Comprehensive Function Documentation

## Overview

This document provides comprehensive documentation for all functions in the enhanced Zsh configuration system. Every function has been documented with Python-style docstrings (converted to Zsh comments) that include:

- **Function description** and purpose
- **Parameter documentation** with types and descriptions
- **Return value** specifications
- **Feature lists** and capabilities
- **Usage examples** and practical demonstrations
- **Dependencies** and requirements

## 📋 Table of Contents

1. [Backup System Module](#backup-system-module)
2. [Help Module](#help-module)
3. [Core Module](#core-module)
4. [Spark Module](#spark-module)
5. [Python Module](#python-module)
6. [Utilities Module](#utilities-module)
7. [Hadoop Module](#hadoop-module)
8. [Docker Module](#docker-module)
9. [Notebooks Module](#notebooks-module)
10. [Environment Module](#environment-module)

---

## 💾 Backup System Module

### `get_backup_path(timestamp)`

**Purpose**: Generate a time-based backup path with year/month/week organization.

**Parameters**:
- `timestamp` (str): Timestamp string in format YYYY-MM-DD_HH-MM-SS

**Returns**: Organized backup path in format `~/.zshrc_backups/YYYY/MM/weekN/`

**Features**:
- Time-based organization (year/month/week)
- Cross-platform date parsing (Linux/macOS)
- Automatic week calculation

**Example**:
```bash
get_backup_path "2025-08-29_14-13-00"
# Returns: ~/.zshrc_backups/2025/08/week5/
```

### `backup_zsh_config(commit_message)`

**Purpose**: Create a comprehensive backup of the zsh configuration with Git integration.

**Parameters**:
- `commit_message` (str, optional): Custom commit message. Defaults to "Automatic backup"

**Returns**: 0 on success, 1 on failure

**Features**:
- Time-based organization (year/month/week)
- Metadata generation with system info
- Restore script creation
- Automatic Git commit and push
- Retry logic with exponential backoff
- Conflict resolution

**Example**:
```bash
backup_zsh_config "Feature update backup"
backup_zsh_config  # Uses default message
```

### `auto_backup_trigger()`

**Purpose**: Automatically trigger backups based on time intervals.

**Parameters**: None (called automatically by zsh hooks)

**Returns**: None

**Configuration**:
- `AUTO_BACKUP_ON_CHANGE`: Enable/disable automatic backups
- `AUTO_BACKUP_INTERVAL`: Time between backups in seconds (default: 3600)

**Features**:
- Automatic execution via zsh hooks
- Configurable backup intervals
- Prevents excessive backups

### `enhanced_backup(commit_message)`

**Purpose**: Perform a complete backup operation with automatic repository synchronization.

**Parameters**:
- `commit_message` (str, optional): Custom commit message. Defaults to "Enhanced backup with sync"

**Returns**: 0 on success, 1 on failure

**Workflow**:
1. Sync config repository
2. Create backup with metadata
3. Sync backup repository

**Example**:
```bash
enhanced_backup "Major feature update"
enhanced_backup  # Uses default message
```

### `sync_config_repository(commit_message)`

**Purpose**: Synchronize only the config repository with GitHub.

**Parameters**:
- `commit_message` (str, optional): Custom commit message. Defaults to "Config repository sync"

**Returns**: 0 on success, 1 on failure

**Features**:
- Automatic conflict detection and resolution
- Retry logic with exponential backoff
- Pull before retry to resolve conflicts

**Example**:
```bash
sync_config_repository "Update core functions"
sync_config_repository  # Uses default message
```

### `sync_backup_repository(commit_message)`

**Purpose**: Synchronize only the backup repository with GitHub.

**Parameters**:
- `commit_message` (str, optional): Custom commit message. Defaults to "Backup repository sync"

**Returns**: 0 on success, 1 on failure

**Features**:
- Automatic conflict detection and resolution
- Retry logic with exponential backoff
- Pull before retry to resolve conflicts

**Example**:
```bash
sync_backup_repository "Update backup metadata"
sync_backup_repository  # Uses default message
```

### `list_zsh_backups()`

**Purpose**: Display a list of available zsh configuration backups.

**Parameters**: None

**Returns**: None (displays formatted output)

**Output Format**:
- Timestamp of each backup
- Size of backup directory
- Total count of backups
- Shows last 10 backups by default

**Example**:
```bash
list_zsh_backups
# Output:
# 📋 ZSH Configuration Backups (Time-Organized):
#    🗂️  2025-08-29_14-13-00 (2.1M)
#    🗂️  2025-08-29_13-13-00 (2.1M)
# Total backups: 15 (showing recent 10)
```

### `sync_zsh_repositories(commit_message)`

**Purpose**: Synchronize both the config and backup repositories with GitHub.

**Parameters**:
- `commit_message` (str, optional): Custom commit message. Defaults to "Automatic sync of zsh configuration"

**Returns**: 0 on success, 1 on failure

**Workflow**:
1. Sync config repository
2. Sync backup repository

**Example**:
```bash
sync_zsh_repositories "Update all modules"
sync_zsh_repositories  # Uses default message
```

### `sync_zsh()`

**Purpose**: Perform a quick synchronization of both repositories.

**Parameters**: None

**Returns**: 0 on success, 1 on failure

**Example**:
```bash
sync_zsh  # Quick sync with default message
```

### `sync_and_backup(commit_message)`

**Purpose**: Perform both synchronization and backup in a single operation.

**Parameters**:
- `commit_message` (str, optional): Custom commit message. Defaults to "Configuration update and backup"

**Returns**: 0 on success, 1 on failure

**Workflow**:
1. Sync both repositories
2. Create comprehensive backup
3. Verify all operations completed

**Example**:
```bash
sync_and_backup "Major system update"
sync_and_backup  # Uses default message
```

### `zsh_repo_status()`

**Purpose**: Display the current status of both zsh configuration repositories.

**Parameters**: None

**Returns**: None (displays formatted status information)

**Information Displayed**:
- Current branch
- Number of modified files
- Remote repository URL
- Commits ahead/behind remote
- Repository health status

**Example**:
```bash
zsh_repo_status
# Output:
# 📊 ZSH Repository Status
# ========================
# 📁 Config Repository (~/.config/zsh):
#    Branch: main
#    Status: 0 files modified
#    Remote: git@github.com:dheerajchand/siege_analytics_zshrc.git
#    Ahead: 0 commits ahead
#    Behind: 0 commits behind
```

---

## ❓ Help Module

### `zsh_help(module, subcommand)`

**Purpose**: Main help function providing comprehensive assistance for the zsh configuration system.

**Parameters**:
- `module` (str, optional): Module name to get help for. Defaults to "all"
- `subcommand` (str, optional): Specific function or subcommand to get help for

**Valid Module Values**:
- `core`, `spark`, `python`, `utilities`, `backup`, `hadoop`, `docker`, `notebooks`, `environment`, `sync`, `test`, `list`, `search`, `usage`, `modules`

**Returns**: None (displays formatted help information)

**Examples**:
```bash
zsh_help                    # Show main help overview
zsh_help spark             # Show Spark module help
zsh_help backup sync       # Show sync function help in backup module
zsh_help list              # List all available functions
zsh_help search backup     # Search for backup-related functions
zsh_help modules           # List available modules
```

### `show_main_help()`

**Purpose**: Display the main help overview for the enhanced zsh configuration system.

**Parameters**: None

**Returns**: None (displays formatted help overview)

**Information Displayed**:
- List of available modules with descriptions
- Help command syntax and usage
- Practical examples for common operations

### `show_core_help(subcommand)`

**Purpose**: Display help information for the core module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Core Functions**:
- `zsh_help`: Comprehensive help system
- `zshconfig`: Edit configuration directory
- `zshreboot`: Reload configuration
- `zsh_health_check`: Quick health check
- `zsh_test_all`: Run comprehensive tests
- `zsh_diagnostic_report`: Generate diagnostic report

### `show_spark_help(subcommand)`

**Purpose**: Display help information for the Spark module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Spark Functions**:
- `pyspark_shell`: Launch Python Spark shell
- `spark_shell_scala`: Launch Scala Spark shell
- `smart_spark_shell`: Intelligent shell selection
- `heavy_api_shell`: High-memory shell
- `test_spark_dependencies`: Test Spark setup
- `list_local_jars`: List available JARs

**Dependencies**:
- Java 17+
- Spark 3.5.3+
- Python 3.8+
- Scala 2.12+

### `show_python_help(subcommand)`

**Purpose**: Display help information for the Python module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Python Functions**:
- `setup_pyenv`: Initialize pyenv environment
- `setup_uv`: Initialize uv environment
- `python_status`: Check environment status
- `pyhelp`: Quick Python help
- `python_help`: Detailed Python help
- `test_python_environment`: Test Python setup

**Package Managers**:
- pyenv: Python version management
- uv: Fast Python package manager
- pip: Standard package installer
- conda: Anaconda package manager

### `show_utilities_help(subcommand)`

**Purpose**: Display help information for the utilities module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Utility Functions**:
- `toggle_hidden_files`: Toggle Finder hidden files
- `toggle_key_repeat`: Toggle key repeat behavior
- `show_hidden_files`: Show hidden files
- `hide_hidden_files`: Hide hidden files
- `test_macos_integration`: Test macOS integration

**macOS Features**:
- Finder integration
- System preferences
- Key repeat optimization
- Performance tuning

### `show_backup_help(subcommand)`

**Purpose**: Display help information for the backup module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Backup Functions**:
- `enhanced_backup`: Enhanced backup with sync
- `backup_zsh_config`: Create configuration backup
- `list_zsh_backups`: List available backups
- `auto_backup_trigger`: Trigger automatic backup
- `get_backup_path`: Generate backup path
- `restore_from_backup`: Restore from backup

**Backup Features**:
- Time-based organization
- Automatic Git integration
- Metadata generation
- Restore scripts
- Health monitoring

### `show_sync_help(subcommand)`

**Purpose**: Display help information for the sync module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Sync Functions**:
- `sync_zsh_repositories`: Sync both repositories
- `sync_zsh`: Quick sync
- `sync_and_backup`: Sync + backup combo
- `sync_config_repository`: Sync config repo only
- `sync_backup_repository`: Sync backup repo only
- `zsh_repo_status`: Repository status

**Sync Features**:
- Dual repository sync
- Automatic conflict resolution
- Retry logic with backoff
- Health monitoring
- Performance tracking

### `show_testing_help(subcommand)`

**Purpose**: Display help information for the testing module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Testing Functions**:
- `zsh_test_all`: Run all tests
- `zsh_health_check`: Quick health check
- `zsh_test_core`: Test core functions
- `zsh_test_spark`: Test Spark functions
- `zsh_test_python`: Test Python functions
- `zsh_diagnostic_report`: Generate diagnostics

**Testing Features**:
- Comprehensive test suite
- Performance benchmarking
- Health monitoring
- Diagnostic reporting
- Test history tracking

### `show_hadoop_help(subcommand)`

**Purpose**: Display help information for the Hadoop module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Hadoop Functions**:
- `hadoop_shell`: Launch Hadoop shell
- `test_hadoop_dependencies`: Test Hadoop setup
- `list_hadoop_jars`: List Hadoop JARs
- `get_hadoop_jars`: Get Hadoop JAR paths
- `check_hadoop_environment`: Check environment
- `setup_hadoop_local`: Setup local Hadoop

**Dependencies**:
- Java 17+
- Hadoop 3.3.6+
- HDFS (optional)
- YARN (optional)

### `show_docker_help(subcommand)`

**Purpose**: Display help information for the Docker module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Docker Functions**:
- `docker_status`: Check Docker status
- `docker_cleanup`: Clean up Docker resources
- `docker_stats`: Show Docker statistics
- `docker_logs`: Show container logs
- `docker_exec`: Execute command in container
- `docker_build`: Build Docker image

**Dependencies**:
- Docker Desktop or Docker Engine
- Docker CLI
- Docker Compose (optional)

### `show_notebooks_help(subcommand)`

**Purpose**: Display help information for the notebooks module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Notebook Functions**:
- `jupyter_start`: Start Jupyter server
- `jupyter_stop`: Stop Jupyter server
- `jupyter_status`: Check Jupyter status
- `jupyter_list`: List running servers
- `jupyter_kernels`: List available kernels
- `notebook_create`: Create new notebook

**Dependencies**:
- Python 3.8+
- Jupyter
- JupyterLab (optional)
- IPython kernels

### `show_environment_help(subcommand)`

**Purpose**: Display help information for the environment module.

**Parameters**:
- `subcommand` (str, optional): Specific function to get detailed help for

**Returns**: None (displays formatted help information)

**Environment Functions**:
- `show_environment_variables`: Display all environment variables
- `set_project_path`: Set project path
- `get_project_path`: Get project path
- `list_project_paths`: List all project paths
- `add_to_path`: Add path to PATH
- `remove_from_path`: Remove path from PATH

**Environment Variables**:
- `ZSHRC_CONFIG_DIR`: Configuration directory
- `ZSHRC_BACKUPS`: Backup directory
- `PYTHON_ACTIVE`: Active Python environment
- `JAVA_HOME`: Java installation path
- `SPARK_HOME`: Spark installation path

### `show_function_help(function_name)`

**Purpose**: Display detailed help information for a specific function.

**Parameters**:
- `function_name` (str): Name of the function to get help for

**Returns**: None (displays formatted function help)

**Features**:
- Function existence validation
- Source code display
- Comment extraction
- Usage examples

**Example**:
```bash
show_function_help pyspark_shell
# Output:
# 📚 Help for function: pyspark_shell
# =====================================
# [Function documentation and source code]
```

### `show_function_usage_examples(function_name)`

**Purpose**: Display usage examples for a specific function.

**Parameters**:
- `function_name` (str): Name of the function to show examples for

**Returns**: None (displays formatted usage examples)

**Supported Functions**:
- `pyspark_shell`: Spark shell launching examples
- `backup_zsh_config`: Backup operation examples
- `sync_zsh`: Repository sync examples
- `zsh_help`: Help system examples
- `zsh_test_all`: Testing examples
- `enhanced_backup`: Enhanced backup examples

**Example**:
```bash
show_function_usage_examples pyspark_shell
# Output:
# 💡 Usage Examples:
#    pyspark_shell              # Default port 4040, memory 2g
#    pyspark_shell 8080         # Custom port 8080
```

### `list_all_functions()`

**Purpose**: Display a categorized list of all available functions in the zsh configuration.

**Parameters**: None

**Returns**: None (displays categorized function list)

**Categories**:
- Core Functions: Configuration and management functions
- Spark Functions: Big Data and Spark-related functions
- Python Functions: Python environment management
- Utility Functions: macOS and system utility functions
- Backup Functions: Backup and sync operations
- Sync Functions: Repository synchronization
- Test Functions: Testing and validation
- Help Functions: Help system functions
- Other Functions: Uncategorized functions

**Example**:
```bash
list_all_functions
# Output:
# 🔍 All Available Functions
# ==========================
# 📊 Total functions: 45
# 🔧 Core Functions (12):
#    zsh_help, zshconfig, zshreboot, ...
```

### `search_functions(search_term)`

**Purpose**: Search for functions by name or description within the zsh configuration.

**Parameters**:
- `search_term` (str): The search term to look for in function names or definitions

**Returns**: None (displays search results)

**Search Scope**:
- Function names (exact and partial matches)
- Function definitions (content within functions)
- Case-insensitive matching

**Example**:
```bash
search_functions backup
# Output:
# 🔍 Searching for functions matching: 'backup'
# =================================================
# ✅ Found 3 matching functions:
#    🔧 backup_zsh_config
#    🔧 enhanced_backup
#    🔧 auto_backup_trigger
```

### `show_usage_examples(function_name)`

**Purpose**: Display general or function-specific usage examples.

**Parameters**:
- `function_name` (str, optional): Specific function to show examples for

**Returns**: None (displays formatted usage examples)

**Example Categories**:
- Core Operations: Configuration and management
- Spark Operations: Big Data operations
- Backup Operations: Backup and sync operations
- Testing Operations: Testing and validation

**Example**:
```bash
show_usage_examples              # Show general examples
show_usage_examples pyspark_shell # Show function-specific examples
```

### `list_available_modules()`

**Purpose**: Display a list of all available modules in the zsh configuration system.

**Parameters**: None

**Returns**: None (displays module list)

**Module Categories**:
- Core configuration and management
- Big Data and Spark integration
- Python environment management
- macOS utility functions
- Backup and sync system
- Hadoop integration
- Docker management
- Jupyter notebook integration
- Environment variable management
- Help system

**Example**:
```bash
list_available_modules
# Output:
# 📦 Available Modules
# ====================
#    📁 core.zsh - Core configuration and management
#    📁 spark.zsh - Spark & Big Data integration
#    📁 python.zsh - Python environment management
```

---

## 🔧 Core Module

*[Core module functions will be documented here with their docstrings]*

## ⚡ Spark Module

*[Spark module functions will be documented here with their docstrings]*

## 🐍 Python Module

*[Python module functions will be documented here with their docstrings]*

## 🛠️ Utilities Module

*[Utilities module functions will be documented here with their docstrings]*

## 🐘 Hadoop Module

*[Hadoop module functions will be documented here with their docstrings]*

## 🐳 Docker Module

*[Docker module functions will be documented here with their docstrings]*

## 📓 Notebooks Module

*[Notebooks module functions will be documented here with their docstrings]*

## 🌐 Environment Module

*[Environment module functions will be documented here with their docstrings]*

---

## 📖 Usage Guide

### Getting Help

The help system provides multiple levels of assistance:

1. **General Help**: `zsh_help all` - Overview of all modules
2. **Module Help**: `zsh_help <module>` - Specific module information
3. **Function Help**: `zsh_help <module> <function>` - Detailed function documentation
4. **Search**: `zsh_help search <term>` - Find functions by name or description
5. **Examples**: `zsh_help examples` - Usage examples for common operations

### Quick Reference

```bash
# Main help commands
zsh_help                    # Show main help
zsh_help list              # List all functions
zsh_help modules           # List available modules
zsh_help search <term>     # Search for functions

# Module-specific help
zsh_help backup            # Backup module help
zsh_help spark             # Spark module help
zsh_help python            # Python module help

# Function-specific help
zsh_help backup enhanced_backup    # Specific function help
zsh_help spark pyspark_shell       # Spark function help

# Examples and usage
zsh_help examples          # General examples
zsh_help usage <function>  # Function-specific examples
```

### Dual Repository System

This enhanced Zsh configuration uses a sophisticated dual repository system to maintain both active configuration and comprehensive historical backups.

#### Repository Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    DUAL REPOSITORY SYSTEM                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  📁 MAIN CONFIG REPOSITORY (~/.config/zsh)                     │
│  ├── Repository: siege_analytics_zshrc                         │
│  ├── Purpose: Active configuration and modules                 │
│  ├── Content: Current working configuration files              │
│  ├── Updates: Frequent commits and pushes                      │
│  └── Remote: git@github.com:dheerajchand/siege_analytics_zshrc │
│                                                                 │
│  💾 BACKUP REPOSITORY (~/.zshrc_backups)                      │
│  ├── Repository: zshrc_backups                                 │
│  ├── Purpose: Historical backups and comprehensive docs        │
│  ├── Content: Time-organized backups + full documentation      │
│  ├── Updates: Automatic backup creation and sync              │
│  └── Remote: git@github.com/dheerajchand/zshrc_backups        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Repository Relationships

1. **Main Config Repository** (`siege_analytics_zshrc`)
   - Contains active, working configuration files
   - Updated frequently with new features and changes
   - Pushed to GitHub for version control and collaboration
   - Serves as the source of truth for current configuration

2. **Backup Repository** (`zshrc_backups`)
   - Contains historical backups with timestamps
   - Stores comprehensive documentation and wiki content
   - Automatically synchronized with main repository
   - Provides disaster recovery and rollback capabilities

#### How They Work Together

- **Automatic Sync**: Changes in main repo automatically trigger backup creation
- **Bidirectional Updates**: Both repositories stay synchronized
- **Conflict Resolution**: Built-in retry logic and conflict handling
- **Health Monitoring**: Status checking for both repositories
- **Documentation Sync**: Wiki and docs automatically backed up

### Backup and Sync Operations

#### Quick Operations (Daily Use)
```bash
# Quick sync (commits and pushes both repos)
sync                       # Alias for sync_zsh

# Enhanced backup with sync (recommended for major changes)
backup                     # Alias for enhanced_backup

# Sync and backup combo
syncbackup                 # Alias for sync_and_backup
```

#### Detailed Operations
```bash
# Enhanced backup with automatic sync
enhanced_backup "Message"  # Sync repos, create backup, sync backup repo

# Repository synchronization
sync_zsh_repositories      # Sync both repositories
sync_config_repository     # Sync config repo only
sync_backup_repository     # Sync backup repo only

# Status and health checking
zsh_repo_status           # Check repository health and status
```

#### Automatic Operations
```bash
# Trigger automatic backup
autobackup                 # Alias for auto_backup_trigger

# Check if auto-backup is enabled
echo $AUTO_BACKUP_ON_CHANGE
echo $AUTO_BACKUP_INTERVAL
```

#### Repository Management Workflow

##### Daily Operations
```bash
# 1. Check repository status
repostatus

# 2. Make changes to configuration
# ... edit files ...

# 3. Quick sync (commits and pushes both repos)
sync

# 4. Verify status
repostatus
```

##### Major Changes
```bash
# 1. Check current status
repostatus

# 2. Make significant changes
# ... edit multiple files ...

# 3. Create enhanced backup with sync
backup "Major feature update"

# 4. Verify both repositories are in sync
repostatus
```

##### Troubleshooting
```bash
# Check individual repository status
cd ~/.config/zsh && git status
cd ~/.zshrc_backups && git status

# Force sync if issues occur
sync_zsh_repositories "Emergency sync"

# Check for conflicts
zsh_repo_status
```

#### Git Operations Explained

##### Committing Changes
```bash
# The system automatically handles commits, but you can also:

# In main config repo
cd ~/.config/zsh
git add .
git commit -m "Your commit message"
git push origin main

# In backup repo
cd ~/.zshrc_backups
git add .
git commit -m "Backup update"
git push origin main
```

##### Resolving Conflicts
```bash
# If conflicts occur, the system will:
# 1. Pull latest changes
# 2. Rebase local changes
# 3. Retry push with exponential backoff

# Manual conflict resolution:
cd ~/.config/zsh
git pull origin main --rebase
# Resolve conflicts if any
git push origin main
```

##### Repository Health
```bash
# Check both repositories
zsh_repo_status

# Check individual repos
cd ~/.config/zsh && git status
cd ~/.zshrc_backups && git status

# Check remote URLs
git remote -v
```

---

## 🔍 Troubleshooting

### Common Issues

1. **Function not found**: Ensure the module is sourced with `source <module>.zsh`
2. **Help not working**: Check that `help-module.zsh` is properly sourced
3. **Backup failures**: Verify Git repository setup and permissions
4. **Sync conflicts**: Use `zsh_repo_status` to check repository health

### Debugging Commands

```bash
# Check system health
zsh_health_check           # Quick health check
zsh_diagnostic_report      # Generate comprehensive diagnostics

# Repository status
zsh_repo_status           # Check both repositories
git status                 # Check individual repository status

# Function availability
typeset -f <function>      # Show function definition
which <function>           # Check function location
```

---

## 📚 Additional Resources

- **README.md**: Main repository documentation
- **Wiki**: Comprehensive system documentation
- **Backup Repository**: Historical configurations and documentation
- **Module Files**: Individual module documentation and source code

---

*This documentation is automatically generated and maintained as part of the enhanced Zsh configuration system.*
