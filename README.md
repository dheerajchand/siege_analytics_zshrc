# 🚀 Enhanced Zsh Configuration

A comprehensive, modular zsh configuration system optimized for macOS development with advanced Spark integration and intelligent dependency management.

## 🎯 **What Makes This Special?**

**Modular Architecture**: Fast, maintainable shell configuration split into logical modules  
**macOS Optimization**: Automatic system configuration for optimal development experience  
**Advanced Spark Integration**: Multi-language shells with smart dependency resolution  
**Intelligent Backup System**: Timestamped configuration rotation and version control  
**Cursor IDE Integration**: Seamless command-line integration with modern development tools  

## 🍎 **macOS Development Environment Enhancements**

### **🚀 System Configuration Management**
- ✅ **Hidden Files Management**: Toggle hidden file visibility in Finder and open/save dialogs
- ✅ **Key Repeat Optimization**: Enable key repeat for special characters (better for coding)
- ✅ **Auto-Configuration**: Automatically sets optimal development settings on first load
- ✅ **Quick Toggle Functions**: Easy commands to switch between configurations

### **Cursor IDE Integration**
- ✅ **Command-Line Tools**: Full Cursor CLI integration with `cursor` and `c` aliases
- ✅ **Workspace Management**: Add folders to workspace via terminal: `cursor --add /path/to/folder`
- ✅ **Smart Aliases**: Automatic setup of development-friendly aliases

**macOS Configuration Commands**:
```bash
# Toggle hidden files in Finder
toggle_hidden_files

# Toggle key repeat behavior
toggle_key_repeat

# Add folder to Cursor workspace
cursor --add /Users/dheerajchand/.config/zsh

# Quick status check
defaults read com.apple.finder AppleShowAllFiles
defaults read -g ApplePressAndHoldEnabled
```

## ⚡ **Advanced Spark Shell Management**

### **Multi-Language Support**
- **Python**: `pyspark_shell` - Enhanced Python shell with full dependency resolution
- **Scala**: `spark_shell_scala` - Optimized Scala shell for production workflows
- **R**: `sparkr_shell` - Statistical analysis shell with Spark integration
- **Smart Selection**: `smart_spark_shell` - Intelligent shell selection based on environment
- **Heavy Operations**: `heavy_api_shell` - High-memory shell for complex operations

### **Intelligent Dependency Management**
- **Online/Offline Detection**: Automatic fallback to local JARs when offline
- **Local JAR Storage**: Efficient local storage with automatic cleanup
- **Smart Downloading**: Downloads essential JARs only when needed
- **Version Management**: Tracks and manages JAR versions automatically

**Spark Shell Commands**:
```bash
# Launch enhanced Spark shells
pyspark_shell              # Python shell with full dependency resolution
spark_shell_scala          # Scala shell with optimized settings
sparkr_shell               # R shell for statistical analysis
smart_spark_shell          # Intelligent shell selection based on environment
heavy_api_shell            # High-memory shell for complex operations

# JAR management
list_local_jars            # Show available local JARs
clean_local_jars           # Remove old/unused JARs
download_local_jars        # Download essential JARs (Sedona, GraphFrames, etc.)
force_download_local_jars  # Force re-download of all JARs

# Dependency testing
test_spark_dependencies    # Verify all dependencies are available
show_spark_config          # Display current Spark configuration
```

## 🏗️ **Configuration Architecture**

### **Core Modules**
```
~/.config/zsh/
├── zshrc                  # Main configuration orchestrator
├── core.zsh              # Core shell settings and aliases
├── environment.zsh        # Environment variables and paths
├── utilities.zsh          # General utilities and macOS configs
├── spark.zsh             # Spark-specific functions and shells
├── hadoop.zsh            # Hadoop configuration and utilities
├── docker.zsh            # Docker management and switching
├── notebooks.zsh         # Jupyter and notebook integration
├── backup-system.zsh     # Configuration backup and rotation
├── auto-setup.zsh        # Automatic environment setup
└── local.zsh             # Local customizations
```

### **Module Loading Strategy**
- **Always Load**: Core, environment, utilities (essential functions)
- **Conditional Load**: Spark, Hadoop (only if tools exist)
- **Optional Load**: Docker, notebooks, auto-setup (enhancement features)

## 🔧 **Backup and Version Control**

### **Intelligent Backup System**
- **Timestamped Rotation**: Automatic backup creation with timestamps
- **Git Integration**: All backups committed to dedicated repository
- **Metadata Tracking**: JSON metadata for each configuration snapshot
- **Restore Scripts**: One-click restoration from any backup point

**Backup Commands**:
```bash
# Create backup with custom message
backup_zsh_config "Description of changes"

# List all available backups
list_zsh_backups

# Restore from backup
cd /path/to/backup && ./restore.sh
```

## 🚀 **Quick Start**

### **1. Load Configuration**
```bash
# Reload entire configuration
source ~/.config/zsh/zshrc

# Or reload specific module
source ~/.config/zsh/utilities.zsh
```

### **2. Verify Setup**
```bash
# Check macOS configuration status
defaults read com.apple.finder AppleShowAllFiles
defaults read -g ApplePressAndHoldEnabled

# Test Spark functions
test_spark_dependencies
show_spark_config
```

### **3. Launch Enhanced Shells**
```bash
# Start Python Spark shell
pyspark_shell

# Start Scala shell
spark_shell_scala

# Start R shell
sparkr_shell
```

## 🧪 **Testing and Validation**

### **Function Testing Framework**
- **Built-in Tests**: Comprehensive testing of all shell functions
- **Color-coded Output**: Easy identification of test results
- **Automatic Validation**: Self-testing on configuration load

### **Health Checks**
```bash
# Test all functions
zsh_test_all

# Test specific category
zsh_test_spark

# Quick health check
zsh_health_check
```

## 🔌 **Integration Features**

### **IDE Integration**
- **Cursor**: Full CLI integration with workspace management
- **VSCode**: Compatible with standard VSCode extensions
- **Terminal**: Enhanced terminal experience with Powerlevel10k

### **Development Tools**
- **Git**: Enhanced git workflow and repository management
- **Docker**: Multi-provider Docker management (Desktop/Rancher)
- **Notebooks**: Jupyter integration and environment management

## 📚 **Function Reference**

### **Core Utilities**
- `zsh_help` - Display comprehensive help information
- `zshconfig` - Edit configuration directory
- `zshreboot` - Reload configuration
- `backup_zsh_config` - Create configuration backup

### **macOS Management**
- `show_hidden_files` / `hide_hidden_files` - Toggle Finder hidden files
- `enable_key_repeat` / `disable_key_repeat` - Toggle key repeat behavior
- `toggle_hidden_files` / `toggle_key_repeat` - Smart toggles

### **Spark Management**
- `pyspark_shell` / `spark_shell_scala` / `sparkr_shell` - Enhanced shells
- `list_local_jars` / `clean_local_jars` - JAR management
- `download_local_jars` / `force_download_local_jars` - JAR downloading

### **Docker Management**
- `use_docker_desktop` / `use_rancher` - Switch Docker providers
- `docker_status` - Show current Docker configuration
- `docker_reset` - Reset to default provider

## 🆘 **Troubleshooting**

### **Common Issues**
1. **Functions not found**: Run `source ~/.config/zsh/zshrc`
2. **Spark not working**: Check `test_spark_dependencies`
3. **Backup failures**: Verify git configuration and permissions
4. **macOS settings not applied**: Run `toggle_hidden_files` or `toggle_key_repeat`

### **Emergency Recovery**
```bash
# Restore from latest backup
cd $(ls -t ~/.zshrc_backups/*/config_* | head -1) && ./restore.sh

# Reset to defaults
defaults delete com.apple.finder AppleShowAllFiles
defaults delete -g ApplePressAndHoldEnabled
```

## 🤝 **Contributing**

This configuration system is designed for personal use but can be adapted for teams:

1. **Fork the configuration structure**
2. **Customize for your environment**
3. **Add your own modules and functions**
4. **Maintain the modular architecture**
5. **Use the backup system for version control**

## 📝 **License**

Personal configuration - adapt and use as needed for your development environment.

---

**Enhanced Zsh Configuration**: Modern, modular, and intelligent shell configuration for productive development! 🚀

**Features**: macOS optimization, Spark integration, Cursor CLI, intelligent backup system
