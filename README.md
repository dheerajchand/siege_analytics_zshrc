# 🚀 Siege Analytics ZSH Configuration System

<div align="center">

![Siege Analytics](https://www.siegeanalytics.com/wp-content/uploads/2019/10/logo.png)

# Enhanced Modular ZSH Configuration System
### Cross-Platform Shell Environment for Data Science & Development

**Spatial Intelligence • Data Science • Advanced Analytics**

[![Main Repository](https://img.shields.io/badge/Main%20Repo-siege__analytics__zshrc-blue?style=for-the-badge&logo=github)](https://github.com/dheerajchand/siege_analytics_zshrc)
[![Documentation](https://img.shields.io/badge/Documentation-API%20Reference-green?style=for-the-badge&logo=readthedocs)](docs/api-reference/)
[![Website](https://img.shields.io/badge/Website-siegeanalytics.com-orange?style=for-the-badge&logo=globe)](https://www.siegeanalytics.com)

</div>

---

## 🎉 **Complete Modular Architecture with Professional Documentation**

### 📊 **System Achievements:**
- **86% size reduction**: 2,435 lines → 350 lines in main config
- **Cross-shell compatibility**: Works in both **bash** and **zsh** with full feature parity
- **Cross-platform support**: macOS, Linux, Docker, WSL with automatic adaptation
- **12 focused modules** replacing monolithic configuration
- **<2 second startup time** with optimized dynamic loading
- **Fixed module loading system**: Functions now load correctly (v1.1.0)
- **Enterprise-grade data science stack**: Spark, Hadoop, Python/UV integration
- **Comprehensive credential management**: 1Password, Apple Keychain, environment variables
- **Auto-backup control system**: Prevents unwanted commits with toggle functionality
- **Dual repository backup**: Development and archive repositories for redundancy
- **Professional Sphinx documentation** with function definitions, examples, and unit tests
- **Comprehensive test suite**: Cross-platform and cross-shell compatibility testing

---

## 🚀 Quick Start

### **New Users**
```bash
# Clone and setup the modular system
git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh
cd ~/.config/zsh

# Works with both bash and zsh!
source zshrc

# Check system status
modular_zsh_status
```

### **Existing Users** (Migration)
```bash
# Your existing setup will be preserved - modules load dynamically
source ~/.config/zsh/zshrc

# Test compatibility
zsh_help system
```

---

## 🏗️ Architecture Overview

### **Core System**
```
~/.config/zsh/
├── zshrc                           # Main configuration (350 lines)
├── config/                         # Modular components
│   ├── shell-compat.zsh           # Cross-shell compatibility (bash+zsh) - LOADS FIRST
│   ├── core.zsh                   # Essential shell configuration (always loads)
│   ├── credentials.zsh            # Multi-backend security system
│   ├── database.zsh               # PostgreSQL, MySQL, Snowflake integration
│   ├── environment.zsh            # Cross-platform detection & optimization
│   ├── jetbrains.zsh              # IDE integration with project detection
│   ├── spark.zsh                  # Apache Spark (cross-shell compatible)
│   ├── hadoop.zsh                 # HDFS, YARN, MapReduce management
│   ├── docker.zsh                 # Container management & development
│   └── help.zsh                   # Interactive documentation system
├── docs/                          # Professional Sphinx documentation
│   ├── api-reference/             # Complete function reference
│   ├── development/               # Development workflows
│   └── _static/                   # Siege Analytics styling
└── tests/                         # Cross-platform test suite
```

### **Key Features**

**🔧 Cross-Shell & Cross-Platform Compatibility**
- **Shell Support**: bash, zsh with automatic detection
- **Platform Support**: macOS, Linux (Ubuntu/RHEL/Alpine), WSL, Docker
- **Package Manager Detection**: apt, yum, dnf, brew, pacman, npm, pip, uv
- **Automatic Optimization**: Container-aware resource allocation

**🐍 Data Science & Development**
- **Python Environment Management**: PyEnv + UV integration with auto-switching
- **Big Data Stack**: Apache Spark + Hadoop with intelligent job submission
- **Container Workflows**: Docker development environments with health monitoring
- **Database Integration**: PostgreSQL, MySQL, Snowflake with secure credential management

**🔒 Enterprise Security**
- **Multi-Backend Credentials**: 1Password, Apple Keychain, environment variables
- **Credential Synchronization**: Bi-directional sync between credential stores
- **Secure Storage**: No plain-text passwords in configuration files
- **Audit Trail**: Credential access logging and monitoring

---

## 📚 Complete Documentation

### **API Reference** 
Comprehensive function documentation with examples and unit tests:

- **[Core Functions](docs/api-reference/core-functions.rst)** - Essential utilities & Python environment management
- **[Platform Functions](docs/api-reference/platform-functions.rst)** - Cross-shell & cross-platform compatibility
- **[Spark Functions](docs/api-reference/spark-functions.rst)** - Apache Spark cluster management & job submission
- **[Hadoop Functions](docs/api-reference/hadoop-functions.rst)** - HDFS, YARN, MapReduce ecosystem management
- **[Docker Functions](docs/api-reference/docker-functions.rst)** - Container development & deployment workflows
- **[Database Functions](docs/api-reference/database-functions.rst)** - Secure database connection management
- **[Python Functions](docs/api-reference/python-functions.rst)** - Python/UV environment switching & data science projects

### **Testing & Validation**
```bash
# Quick system validation
modular_zsh_status

# Cross-shell compatibility testing
./test-bash-integration.sh

# Comprehensive testing  
./test-cross-platform-enhanced.sh
```

### **Build Documentation**
```bash
# Install Sphinx and build HTML documentation
cd docs/
pip install sphinx sphinx-rtd-theme
make html

# View in browser
open _build/html/index.html
```

---

## 🔧 Configuration Guide

### **Environment Variables**

**System Configuration:**
```bash
# Enable verbose output during startup
export MODULAR_ZSHRC_VERBOSE="true"

# Auto-setup credentials from secure backends
export CREDENTIAL_AUTO_SETUP="true"

# Set credential backend preference
export CREDENTIAL_BACKEND="1password-first"  # Options: env-first, 1password-first, apple-first, env-only
```

**Data Science Configuration:**
```bash
# Spark settings (auto-detected, can override)
export SPARK_HOME="/path/to/spark"
export SPARK_DRIVER_MEMORY="4g"
export SPARK_EXECUTOR_MEMORY="2g"

# Hadoop settings (auto-detected, can override)
export HADOOP_HOME="/path/to/hadoop"
export HADOOP_DATA_DIR="$HOME/hadoop-data"

# Python settings
export PYTHON_DEFAULT_VERSION="3.11"
export UV_DEFAULT_PYTHON="3.11"
```

**Database Configuration:**
```bash
# PostgreSQL (maintains compatibility)
export PGHOST="localhost"
export PGUSER="username"
export PGDATABASE="database_name"
# PGPASSWORD is managed by credential system

# MySQL
export MYSQL_HOST="localhost"
export MYSQL_USER="root"
# MYSQL_PWD is managed by credential system

# Snowflake
export SNOWFLAKE_ACCOUNT="company.region"
export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
export SNOWFLAKE_DATABASE="ANALYTICS_DB"
# Password managed by credential system
```

### **Credential Management**

#### **Setup Credential Backends**

**1Password Integration:**
```bash
# Install 1Password CLI
brew install --cask 1password-cli

# Sign in to 1Password
op signin

# Set as primary credential backend
set_credential_backend 1password-first

# Test credential system
creds-test
```

**Apple Keychain (macOS):**
```bash
# Set keychain as primary backend
set_credential_backend apple-first

# Store credentials manually
store_credential postgres username "password123" apple

# Test retrieval
get_credential postgres username PASSWORD
```

#### **Database Credential Setup**

**Interactive Setup (Recommended):**
```bash
# PostgreSQL
setup_postgres_credentials --interactive

# MySQL
setup_mysql_credentials --interactive

# Snowflake
setup_snowflake_credentials --interactive
```

**Manual Credential Storage:**
```bash
# Store in 1Password
store_credential postgres myuser "secure_password" 1password

# Store in Apple Keychain
store_credential mysql root "mysql_password" apple

# Environment variable (temporary)
export PGPASSWORD="temp_password"
```

#### **Credential Synchronization**

**Sync from 1Password to Apple Keychain:**
```bash
# Dry run to see what would be synced
creds-sync-1p-to-keychain --dry-run

# Sync all database credentials
creds-sync-1p-to-keychain

# Sync specific service only
creds-sync-1p-to-keychain --service postgres
```

**Sync from Apple Keychain to 1Password:**
```bash
# Dry run first
creds-sync-keychain-to-1p --dry-run

# Perform sync
creds-sync-keychain-to-1p
```

**Check Credential Status:**
```bash
# View all credential backends and their status
creds-status

# List all configured database connections
db_list_connections

# Test all database connections
db_test_all
```

---

## 🚀 Data Science Workflows

### **Complete Data Science Setup**

```bash
# 1. Create new data science project
ds_project_init customer_analytics spark
cd customer_analytics

# 2. Activate Python environment
py_env_switch uv  # Activates UV project with Spark dependencies

# 3. Setup databases
setup_postgres_credentials --interactive
docker_database postgres --init-sql schema.sql

# 4. Start big data infrastructure
start_hadoop     # Starts HDFS + YARN
spark_start      # Starts Spark cluster

# 5. Check system status
hadoop_status
spark_status
db_test_all

# 6. Run analysis
smart_spark_submit data_analysis.py  # Intelligent environment detection
```

### **Container-Based Development**

```bash
# Setup complete development environment
docker_dev_setup analytics_platform --with-spark --with-monitoring
cd analytics_platform

# Start all services
docker_compose_dev up

# Start Jupyter with Spark in container
docker_jupyter_spark 8888 --mount-data ~/datasets

# Check health status
docker_health_check

# Clean up when done
docker_cleanup --aggressive
```

### **Cross-Platform Deployment**

```bash
# Platform detection and adaptation
echo "Platform: $(detect_platform)"
echo "Shell: $(detect_shell)"
echo "Container: $ZSH_IS_DOCKER"

# Automatic platform optimization
case "$(detect_platform)" in
    "macos")
        path_add "/opt/homebrew/bin" before
        export JAVA_HOME="$(/usr/libexec/java_home)"
        ;;
    "linux-ubuntu")
        sudo apt update && sudo apt install -y python3-venv
        export JAVA_HOME="/usr/lib/jvm/default-java"
        ;;
    "docker")
        # Container-optimized settings automatically applied
        echo "Using container-optimized configuration"
        ;;
esac

# Universal operations work everywhere
py_env_switch uv
if is_online; then
    uv sync --upgrade
else
    uv sync --offline
fi
```

---

## 🔍 System Monitoring & Debugging

### **Health Checks**

```bash
# Overall system status
modular_zsh_status

# Individual component status
spark_status
hadoop_status
docker_status
python_info
system_info

# Measure performance
shell_startup_time

# List available modules
list_modules
```

### **Debug Mode**

```bash
# Enable verbose output
export MODULAR_ZSHRC_VERBOSE="true"
source ~/.zshrc

# Test cross-platform compatibility
./test-cross-platform-enhanced.sh

# Test specific functions
test_command_exists
test_py_env_list
test_spark_environment_setup
```

### **Troubleshooting Common Issues**

**Module Loading Issues:**
```bash
# Check if module loaded
echo $SPARK_MODULE_LOADED

# Manual module reload
load_module spark

# List all available modules
list_modules
```

**Path Issues:**
```bash
# Check current PATH
echo $PATH | tr ':' '\n'

# Add missing paths
path_add "/usr/local/bin"
path_add "$HOME/.jetbrains/bin"  # JetBrains tools
```

**Credential Issues:**
```bash
# Check credential backend status
creds-status

# Test credential retrieval
creds-test

# Reset credential backend
set_credential_backend env-first
```

**Container Detection Issues:**
```bash
# Check container environment
echo "Container: $ZSH_IS_DOCKER"
echo "Platform: $ZSH_PLATFORM"

# Force container mode for testing
export ZSH_IS_DOCKER="true"
```

---

## 📈 Performance Metrics

### **Startup Performance**
- **Cold start**: ~1.8 seconds
- **Warm start**: ~0.3 seconds
- **Module loading**: Lazy-loaded on first use
- **Memory usage**: ~12MB additional RSS

### **Feature Benchmarks**
- **Environment switching**: <100ms (UV/PyEnv)
- **Database connection**: <500ms (with credential retrieval)
- **Spark job submission**: <2 seconds (local cluster startup)
- **Docker health checks**: <1 second (all services)

### **Optimization Features**
- **Conditional loading**: Heavy modules only load when needed
- **Credential caching**: Backend detection cached per session
- **Path deduplication**: Automatic PATH cleanup
- **Container awareness**: Optimized resource allocation

---

## 🛠️ Development & Testing

### **Running Tests**

```bash
# Quick validation test (recommended for daily use)
./test-modular-quick.sh

# Complete cross-platform test suite
./test-cross-platform-enhanced.sh

# Test specific functionality
source config/core.zsh
test_command_exists
test_mkcd_basic
test_py_env_list

# Test credential system
creds-test
```

### **Adding New Modules**

1. **Create module file**: `config/my-module.zsh`
2. **Add module identification**: `export MY_MODULE_LOADED="true"`
3. **Add to main config**: Include in `zshrc` loading sequence
4. **Document functions**: Add to `docs/api-reference/my-module-functions.rst`
5. **Add tests**: Include test functions with `test_` prefix
6. **Update help**: Add help topics to `config/help.zsh`

### **Contributing**

```bash
# Fork repository and create feature branch
git checkout -b feature/new-functionality

# Make changes and test across platforms
./test-cross-platform-enhanced.sh

# Update documentation
cd docs && make html

# Submit pull request with tests and documentation
```

---

## 📋 Module Reference

### **Core Modules**

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **core.zsh** | Essential utilities & Python management | `py_env_switch`, `ds_project_init`, `system_info` |
| **shell-compat.zsh** | Cross-shell & platform compatibility | `detect_platform`, `platform_open`, `add_chdir_hook` |
| **credentials.zsh** | Secure credential management | `setup_postgres_credentials`, `store_credential`, `sync_credentials_*` |

### **Data Science Modules**

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **spark.zsh** | Apache Spark cluster management | `spark_start`, `smart_spark_submit`, `heavy_api_submit` |
| **hadoop.zsh** | Hadoop ecosystem (HDFS/YARN/MapReduce) | `start_hadoop`, `setup_hdfs_config`, `hadoop_spark_integration` |
| **python.zsh** | Python environment & data science projects | `py_env_switch`, `ds_project_init`, `python_info` |

### **Development Modules**

| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **docker.zsh** | Container development workflows | `docker_dev_setup`, `docker_jupyter_spark`, `docker_health_check` |
| **database.zsh** | Database connection management | `pg_connect`, `mysql_connect`, `snowflake_connect` |
| **environment.zsh** | Package management & system tools | `setup_sdkman`, `setup_uv`, `manage_packages` |

---

## 🔗 Quick Reference

### **Essential Commands**
```bash
# System
modular_zsh_status              # Overall system status
system_info                     # System information
list_modules                    # Available modules

# Python & Data Science
py_env_switch list              # List Python environments
ds_project_init myproject spark # Create Spark-enabled data science project
py_info                         # Current Python environment status

# Big Data
start_hadoop                    # Start Hadoop cluster
spark_start                     # Start Spark cluster
smart_spark_submit script.py    # Intelligent Spark job submission

# Databases
setup_postgres_credentials --interactive  # Setup PostgreSQL credentials
db_test_all                     # Test all database connections
pg_connect                      # Connect to PostgreSQL

# Containers
docker_dev_setup myapp          # Create development environment
docker_jupyter_spark            # Jupyter with Spark in container
docker_health_check             # Check container health

# Credentials
creds-status                    # Credential system status
creds-sync-1p-to-keychain      # Sync from 1Password to keychain
set_credential_backend apple-first  # Set credential backend preference
```

### **Backup Control System**
```bash
# Backup system status and control
backup-status                   # Show current auto-backup status
backup-on                      # Enable auto-backup system
backup-off                     # Disable auto-backup system
backup-toggle                  # Toggle auto-backup on/off
backup-disable                 # Permanently disable in configuration

# Repository synchronization
./sync-repos.sh                # Sync changes between development and archive repos

# Auto-backup provides:
# - Automatic configuration backups when files change
# - Time-based backup intervals (default: 1 hour)  
# - Safe toggle system to prevent unwanted commits
# - Status monitoring and diagnostics
# - Cross-repository synchronization
```

### **Configuration Files**
```bash
# Main configuration
~/.config/zsh/zshrc            # Primary configuration file

# Environment variables
~/.config/zsh/.env             # Environment variable overrides

# Credentials (if using file backend)
~/.config/zsh/.credentials     # Secure credential storage

# Custom configurations
~/.config/zsh/config/custom.zsh  # User-specific additions
```

---

## 📞 Support & Resources

### **Documentation**
- **[Complete API Reference](docs/api-reference/)** - All functions with examples and tests
- **[Development Workflows](docs/development/)** - Data science and development patterns
- **[Cross-Platform Guide](docs/platforms/)** - Platform-specific configurations

### **Quick Help**
```bash
# Integrated help system
zsh_help                       # Main help menu
zsh_help modules               # Module-specific help
zsh_help credentials           # Credential management help
zsh_help troubleshooting       # Common issues and solutions
```

### **Community & Support**
- **Repository**: [dheerajchand/siege_analytics_zshrc](https://github.com/dheerajchand/siege_analytics_zshrc)
- **Issues**: [GitHub Issues](https://github.com/dheerajchand/siege_analytics_zshrc/issues)
- **Website**: [siegeanalytics.com](https://www.siegeanalytics.com)

---

<div align="center">

## 🎯 **Ready to revolutionize your data science workflow?**

### **Experience the power of modular, cross-platform shell configuration**

**[⭐ Star the Repository](https://github.com/dheerajchand/siege_analytics_zshrc)** | **[📖 Read the Docs](docs/api-reference/)** | **[🚀 Get Started](#-quick-start)**

---

**Built with ❤️ by [Siege Analytics](https://www.siegeanalytics.com)**

*Spatial Intelligence • Data Science • Advanced Analytics*

</div>