# 🚀 Enhanced Zsh Configuration Wiki

Welcome to the comprehensive documentation for your enhanced zsh configuration system! This wiki contains detailed guides, function references, and best practices for your modular zsh setup.

## 📚 **Documentation Sections**

### **📖 [GitHub Wiki Documentation](https://github.com/dheerajchand/siege_analytics_zshrc/wiki)**
- **Professional documentation** with comprehensive guides
- **Complete system documentation** for all components
- **Interactive navigation** and search functionality
- **Siege Analytics branding** with custom styling

### **📘 [Shell Operations Guide](Shell-Operations-Guide)**
- End-to-end shell usage and workflows
- Localization and host override model
- Complete public function index by module

### **🚀 [Quick Start Guide](Quick-Start)**
- Installation and setup
- First-time configuration
- Essential commands

### **🎯 [Idiot-Proof Guide](../IDIOT_LEVEL_GUIDE.md)**
- **Complete beginner-friendly setup guide**
- **Step-by-step instructions** for all skill levels
- **Multiple setup options** (simple, power user, bash)
- **Troubleshooting guide** with common solutions
- **Environment variable setup** and management
- **Quick reference card** with essential commands

### **🏗️ [System Architecture](System-Architecture)**
- Modular design overview
- Configuration flow
- Environment variables

### **🐚 [Bash Compatibility](Bash-Compatibility)**
- Cross-shell compatibility layer
- Platform-specific adaptations
- Function translation between zsh and bash
- Installation scripts for both shells

### **⚡ [Spark + Hadoop + Zeppelin](Module-Spark)**
- Spark shell management
- Hadoop integration
- Jar matrix and compatibility checks

### **🧩 [Functions & Dependencies](Functions-Dependencies)**
- Detailed function reference
- Jar matrix resolution
- Spark/Hadoop safety flags

### **🐍 [Python Environment](Module-Python)**
- Pyenv and UV management
- Virtual environment setup
- Project management

### **🛠️ [System Diagnostics](Module-System-Diagnostics)**
- macOS/Linux diagnostics
- iCloud and Dropbox helpers
- Data platform checks

### **💾 [Backup & Recovery](Module-Backup)**
- Configuration backup system
- Restore procedures
- Version management

### **🔧 [Settings + Secrets](Module-Settings)**
- Shared/OS/machine variable layering
- Alias/path customization
- Host-aware local overrides

### **🧪 [Testing Framework](Testing-Framework)**
- Comprehensive unit testing for Zsh functions
- pytest-like functionality for shell scripting
- Test coverage and reporting
- CI/CD integration

## 🎯 **What Makes This Special?**

**Modular Architecture**: Fast, maintainable shell configuration split into logical modules  
**macOS Optimization**: Automatic system configuration for optimal development experience  
**Advanced Spark Integration**: Multi-language shells with smart dependency resolution  
**Intelligent Backup System**: Timestamped configuration rotation and version control  
**Cursor IDE Integration**: Seamless command-line integration with modern development tools  

## 🚀 **Quick Commands Reference**

```bash
# Core functions
help                        # Display comprehensive help
zshconfig                   # Edit configuration directory
zshreboot                   # Reload configuration
backup "message"            # Commit + push current branch
secrets_profiles            # List profiles and colors
secrets_bootstrap_from_1p   # Pull secrets files from 1Password
screen_ensure_pyenv         # Ensure pyenv init for screen shells

# Profiles & PT host mapping
# ZSH_ENV_PROFILE=dev
# PT_ENV_HOSTNAME=cyberpower

# macOS management
toggle_hidden_files         # Toggle Finder hidden files
toggle_key_repeat          # Toggle key repeat behavior

# Spark management
pyspark_shell              # Python shell with dependencies
spark_shell                # Scala shell with optimization
smart_spark_submit job.py  # Intelligent submit wrapper

# Python management
setup_pyenv                # Initialize pyenv
setup_uv                   # Initialize uv
python_status              # Check environment status

# Testing framework
test_system                # Run quick system tests
test_backup                # Test backup system
test_python                # Test Python functions
test_spark                 # Test Spark functions
test_jvm                   # Test JVM/Hadoop/YARN functions
test_jupyter               # Test Jupyter functions
test_compatibility         # Test bash compatibility
test_bash_install          # Test bash installation
zsh run-tests.zsh          # Run comprehensive test suite
zsh run-tests.zsh --coverage # Run tests with coverage
```

## 🔗 **Repository Links**

- **Main Config**: [~/.config/zsh](https://github.com/dheerajchand/spark_ready_zshrc)
- **Backup System**: [zshrc_backups](https://github.com/dheerajchand/zshrc_backups)
- **Main Dotfiles**: [~/.dotfiles](https://github.com/dheerajchand/dotfiles)

## 📖 **Getting Started**

1. **Read the [Shell Operations Guide](Shell-Operations-Guide)** for complete workflows
2. **Explore [System Architecture](System-Architecture)** to understand the design
3. **Read [Quick-Start](Quick-Start)** for rapid setup
4. **Review [Module-Backup](Module-Backup)** for safety

---

**Enhanced Zsh Configuration**: Modern, modular, and intelligent shell configuration for productive development! 🚀

**Last Updated**: January 2025  
**Version**: 2.1.0-optimized
