# 📦 Module Guide - Production System with Security Layer

## 🎯 Primary Modules (Auto-loaded in Staggered Mode)

**Current Status**: Production-ready with integrated credential management and hostile testing framework

### **utils.module.zsh**
Essential utilities and backup system
- Core shell utilities (mkcd, extract, findtext)
- Enhanced backup system (enhanced_backup, pushmain, sync)
- Repository management and PATH utilities
- **Auto-loads**: Always (dependency for other modules)

### **database.module.zsh**
Database integration and management
- PostgreSQL connection management with secure credentials
- MySQL integration functions
- Snowflake data warehouse support
- **Load with**: `load-database`
- **NEW**: Integrated with credential management system

### **docker.module.zsh**
Container management and development
- Docker container lifecycle management
- Development environment setup
- Container networking and volumes
- **Load with**: `load-docker`

### **javascript.module.zsh**
Node.js and web development tools
- Node.js environment management
- npm/yarn package management
- Web development utilities
- **Load with**: Not needed (auto-loads)

### **jetbrains.module.zsh**
JetBrains IDE integration
- PyCharm, DataSpell, IntelliJ command-line tools
- IDE detection and environment setup
- Command-line launcher functions (pycharm, dataspell, idea)
- **Load with**: `load-jetbrains`

### **python.module.zsh**
Python environment management
- pyenv integration and Python version switching
- UV package manager support
- Virtual environment management
- **Load with**: `load-python`

### **spark.module.zsh**
Apache Spark and big data processing
- Spark cluster management and job submission
- Hadoop integration (HDFS, YARN)
- PySpark development environment
- **Load with**: `load-spark`

## 🔧 Hierarchical Modules (Auto-loaded with Primary Modules)

### **modules/platforms/macos/system.zsh**
macOS system integration
- System-specific utilities and optimizations
- macOS file system integrations
- **Auto-loads**: With primary modules in staggered mode

### **modules/core/module-loader.zsh**
Dynamic module discovery system
- Module loading utilities and management
- Module dependency resolution
- **Auto-loads**: With primary modules in staggered mode

### **modules/core/cross-shell.zsh**
Cross-shell compatibility functions
- Bash/Zsh compatibility layer
- Shell detection and adaptation
- **Auto-loads**: With primary modules in staggered mode

### **modules/languages/python/managers.zsh**
Python environment switching utilities
- Advanced pyenv management (py_env_switch, python_info)
- Environment switching and validation
- **Auto-loads**: With primary modules in staggered mode

### **modules/languages/python/projects.zsh**
Python project initialization tools
- Project setup and configuration utilities
- Template and boilerplate management
- **Auto-loads**: With primary modules in staggered mode

## 🚀 Legacy Big Data Modules (For Reference)

### **spark.zsh** (74,000 lines!)
Comprehensive Apache Spark integration
- Multiple execution modes
- Geospatial analytics (Sedona)
- Graph processing (GraphFrames)
- Performance optimization
- Testing framework

### **hadoop.zsh** (4,800 lines)
Hadoop ecosystem management  
- HDFS distributed storage
- YARN resource management
- Cluster administration
- Web UI integration

### **notebooks.zsh** (4,200 lines)
Notebook integration system
- Jupyter Lab with Spark
- DataSpell configuration
- Template management
- Auto-configuration

## 🐍 Python Subsystem (8 modules)

Advanced Python management with:
- pyenv + uv integration
- Virtual environment management
- Project detection
- Performance monitoring
- Health diagnostics

## 🛠️ Development Modules

### **docker.zsh** (4,800 lines)
Docker development integration
- Container management
- Development workflows
- Service orchestration

### **auto-setup.zsh** (3,000 lines)
Environment auto-setup system
- Dependency detection
- Automatic configuration
- Version management

## 🔐 Security & Credential Management (NEW)

### **config/credentials.zsh**
Multi-backend secure credential management
- **get_credential()**: Secure credential retrieval with injection protection
- **store_credential()**: Dual-storage (1Password + Keychain) credential storage
- **ga_get_service_account()**: Google Analytics service account integration
- **credential_backend_status()**: Backend health monitoring
- **Priority**: 1Password → macOS Keychain → Environment Variables
- **Security**: Zero information disclosure, comprehensive input validation

### **Hostile Testing Framework**
Production-grade adversarial testing
- **tests/hostile-critical-functions.zsh**: Function availability under stress
- **tests/hostile-security-comprehensive.zsh**: Security vulnerability testing
- **tests/hostile-comprehensive-final.zsh**: Production readiness certification
- **tests/hostile-credential-testing.zsh**: Credential system security validation

**Testing Categories:**
- Injection attack simulation (command, path, environment)
- Information disclosure prevention
- Resource exhaustion resistance
- Concurrent access validation
- Error recovery verification

### **Quick Commands**
```bash
# Credential management
creds-status                    # Check backend status
creds-test                      # Test credential system
get_credential "service" "user" # Retrieve credentials
credential_backend_status       # Full system status

# Google Analytics
ga-list                         # List GA credentials
ga-get                          # Get GA service account
ga-test                         # Test GA authentication

# Hostile testing
./tests/hostile-comprehensive-final.zsh     # Full production test
./tests/hostile-credential-testing.zsh      # Credential security test
```
