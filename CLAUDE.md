# CLAUDE.md - Modular ZSH Configuration Guide

## 🚀 **System Overview**

**Complete cross-shell architecture with 86% size reduction from monolithic config**

- **Performance**: <2s startup, 12+ focused modules, full cross-platform support
- **Compatibility**: Bash + ZSH, macOS/Linux/Docker/WSL
- **Security**: Multi-backend credential system, secure storage integration

## 📊 **Quick Status Commands**

```bash
modular_zsh_status        # Complete system overview
environment_info          # Platform detection & system info
credential_backend_status # Security system status
backup_status            # Auto-backup system status
```

## 🔧 **Core Modules & Commands**

### **Essential System Functions**
```bash
# Core utilities (always available)
mkcd /path/dir           # Create directory and cd
extract archive.tar.gz   # Universal archive extraction
is_online               # Check internet connectivity
deduplicate_path        # Fix PATH duplicates (improves Finder performance)

# Platform detection
echo $ZSH_PLATFORM      # Shows: macos, linux, unknown
echo $ZSH_IS_DOCKER     # Container detection: true/false
```

### **Database Integration**
```bash
database_status         # Database configuration overview
pg                     # PostgreSQL with auto-credentials
setup_postgres_credentials  # Migrate to secure storage
get_credential "service" "user" "PASSWORD"  # Multi-backend retrieval
```

### **Development Tools**
```bash
# JetBrains IDEs with project detection
py project_dir         # Open in PyCharm
idea project_dir       # Open in IntelliJ
open_project .         # Auto-detect project type

# Docker development
docker_status          # Comprehensive Docker status
dstatus               # Quick Docker alias
```

### **Big Data Stack**
```bash
# Apache Spark
spark_status          # Cluster and configuration status
smart_spark_submit script.py  # Auto-detect execution mode
spark_start           # Start local cluster

# Hadoop ecosystem
hadoop_status         # HDFS and YARN status
start_hadoop          # Start services
```

## 🐍 **Python Management System (v2.1.0)**

### **Core Python Commands**
```bash
python_status         # Comprehensive environment status
python_health_check   # Environment diagnostics
switch_python_manager pyenv  # Switch between pyenv/UV
select_pyenv_version  # Interactive version selector
```

### **Environment Management**
```bash
# Virtual environments
create_venv .venv     # Create virtual environment
auto_activate_venv    # Smart project environment detection

# UV integration
uv init --python 3.12 # Create UV project
uv add requests       # Add packages
uv sync              # Install dependencies
```

## 🔐 **Security & Credentials**

### **Multi-Backend System**
```bash
# Credential priority: Environment → 1Password → macOS Keychain → Interactive
get_credential "postgres" "$USER" "PASSWORD"
credential_backend_status  # Show available backends
detect_credential_backends # Rescan for backends
```

### **Password Sync System**
```bash
sync_status           # Complete credential overview
sync_all_passwords_to_1password    # Apple → 1Password (discovers 127+ entries)
sync_1password_to_apple           # 1Password → Apple
```

## ⚡ **Performance & Optimization**

### **PATH Management**
```bash
deduplicate_path      # Remove duplicates (fixes Finder slowdowns)
echo ${#PATH}         # Check PATH length
echo $PATH | tr ':' '\n' | wc -l  # Count PATH entries
```

### **iCloud Drive Diagnostics & Cleanup**
```bash
# Diagnose iCloud sync issues causing system slowdowns
icloud_diagnose              # Full diagnostic report with CPU usage
icloud_diagnose --blocked    # Show only blocked containers
icloud_diagnose --cpu        # Focus on performance issues

# Clean up problematic iCloud containers
icloud_cleanup               # Interactive cleanup utility
icloud_cleanup --uninstalled # Remove all uninstalled app containers
icloud_cleanup --disable <name> # Disable sync for specific container
icloud_cleanup --force <name>   # Force remove container (requires sudo)
```

### **System Utilities**
```bash
restart_finder        # Restart Finder to fix file dialog issues
```

### **Backup System**
```bash
backup_status         # Show backup configuration
backup_auto_on        # Enable automatic backups
backup_auto_off       # Disable automatic backups
```

## 🧪 **Testing & Validation**

```bash
# Quick system validation (recommended)
./test-modular-quick.sh           # 5-second functionality test

# Cross-shell compatibility
./test-bash-integration.sh        # Comprehensive bash compatibility

# Full test suite
./test-cross-platform-enhanced.sh # Complete platform testing
```

## ⚙️ **Configuration**

### **Centralized Variable Management**
All system configuration is centralized in `~/.config/zsh/zshrc` lines 65-217:

```bash
# Key variables you can customize:
export EDITOR="${EDITOR:-zed}"                    # Default editor
export PYTHON_MANAGER="${PYTHON_MANAGER:-auto}"   # Python manager choice
export PREFERRED_VENV="${PREFERRED_VENV:-geo31111}" # Default virtual env
export SPARK_DRIVER_MEMORY="${SPARK_DRIVER_MEMORY:-2g}"
export PGUSER="${PGUSER:-dheerajchand}"           # PostgreSQL user
```

### **Help System**
```bash
zsh_help             # Overview of all modules
zsh_help docker      # Docker-specific functions
zsh_help search password  # Find credential functions
```

## 🔄 **Mode System**

```bash
# Shell modes (set in zshrc)
export ZSH_MODE="${ZSH_MODE:-heavy}"  # light, staggered, heavy

# Reload configuration
zsh-reload           # Full reload
zsh-verbose          # Reload with debug output
```

## 🌍 **Cross-Platform Support**

### **Platform Detection**
```bash
# Automatic platform adaptation:
# macOS: brew, security keychain
# Linux: apt/yum/dnf, various distros  
# Docker: optimized memory settings
# WSL: Windows subsystem detection
```

### **Container Optimization**
```bash
is_in_container      # Check if running in container
echo $ZSH_IS_DOCKER  # Container environment flag
```

## 📁 **Repository Structure**

```
~/.config/zsh/
├── zshrc                    # Main loader (350+ lines, 86% reduction)
├── config/                  # 12 modular configuration files
│   ├── core.zsh            # Essential functions
│   ├── credentials.zsh     # Security system (24KB)
│   ├── database.zsh        # Database integration
│   ├── docker.zsh          # Container management
│   └── [8 more modules]    
├── python/                  # Python management system (8 modules)
├── backup-system.zsh        # Enhanced backup (42KB)
├── bash-compatibility.zsh   # Cross-shell layer (14KB)
└── tests/                   # Testing framework
```

## 🚨 **Troubleshooting**

### **Common Issues**

**Modules not loading:**
```bash
modular_zsh_status          # Check load status
source ~/.config/zsh/zshrc  # Manual reload
```

**Functions not available:**
```bash
command -v function_name    # Check if function exists
type function_name          # Show function definition
```

**Slow Finder/file operations:**
```bash
deduplicate_path           # Remove duplicate PATH entries
echo ${#PATH}              # Check PATH length (should be <1500)
```

**Performance issues:**
```bash
time zsh -c 'source ~/.config/zsh/zshrc'  # Should be <2 seconds
ZSH_STARTUP_TIMING=true source zshrc      # Show timing details
```

## 📈 **Key Achievements**

- ✅ **86% size reduction** (2,435 → 350 lines main config)
- ✅ **<2 second startup** with dynamic loading
- ✅ **Full cross-platform support** (macOS, Linux, Docker, WSL)  
- ✅ **Enterprise security** with multi-backend credentials
- ✅ **Advanced Python management** (pyenv + UV integration)
- ✅ **Comprehensive testing** framework with multiple test tiers
- ✅ **PATH optimization** to fix Finder performance issues

---

**Status: Production-ready enterprise-grade shell configuration system**

For detailed documentation, see:
- `README.md` - Project overview and setup
- `docs/` - Comprehensive Sphinx documentation  
- `wiki/` - Additional guides and workflows