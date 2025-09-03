# 🚀 Quick Start Guide

Get your enhanced zsh configuration up and running in minutes! **Now with full bash compatibility!**

## ⚡ **Immediate Setup**

### **For Bash Users (One-Line Installation)**
```bash
# Install for bash users
curl -fsSL https://raw.githubusercontent.com/dheerajchand/siege_analytics_zshrc/main/quick-install-bash.sh | bash

# Or full installation
curl -fsSL https://raw.githubusercontent.com/dheerajchand/siege_analytics_zshrc/main/install-for-bash.sh | bash
```

### **1. Load Your Configuration**
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

# Test core functions
zsh_help
```

### **3. Enable Auto-Setup (Optional)**
```bash
# Enable automatic environment setup
enable_auto_setup

# Or run setup manually
auto_setup_environment
```

## 🎯 **Essential Commands**

### **Core Functions**
```bash
zsh_help                    # Display comprehensive help
zshconfig                   # Edit configuration directory
zshreboot                   # Reload configuration
backup_zsh_config          # Create configuration backup
```

### **macOS Management**
```bash
toggle_hidden_files         # Toggle Finder hidden files
toggle_key_repeat          # Toggle key repeat behavior
```

### **Cursor IDE Integration**
```bash
cursor --add /path/to/folder  # Add folder to workspace
c                           # Quick cursor command
```

## 🐍 **Python Environment Setup**

### **Initialize Python Managers**
```bash
# Setup pyenv (Python version management)
setup_pyenv

# Setup uv (fast package manager)
setup_uv

# Check status
python_status
```

### **Virtual Environment Workflow**
```bash
# Create virtual environment
pyenv virtualenv 3.11.11 myproject

# Activate for session
pyenv activate myproject

# Set as project default
pyenv local myproject
```

## ⚡ **Spark & Big Data**

### **Launch Enhanced Shells**
```bash
# Python Spark shell with dependencies
pyspark_shell

# Scala shell with optimization
spark_shell_scala

# R shell for statistical analysis
sparkr_shell

# Intelligent shell selection
smart_spark_shell
```

### **Jupyter Integration**
```bash
# Start Jupyter Lab with Spark optimization
jupyter_spark 8889

# Create notebook templates
create_notebook_templates
```

## 🏗️ **Configuration Architecture**

Your configuration is organized into logical modules:

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
└── auto-setup.zsh        # Automatic environment setup
```

## 🔧 **First-Time Configuration**

### **macOS Optimization**
```bash
# Enable hidden files in Finder
toggle_hidden_files

# Enable key repeat for coding
toggle_key_repeat

# Verify settings
defaults read com.apple.finder AppleShowAllFiles
defaults read -g ApplePressAndHoldEnabled
```

### **Backup Your Current Config**
```bash
# Create initial backup
backup_zsh_config "Initial setup backup"

# List available backups
list_zsh_backups
```

## 🧪 **Testing Your Setup**

### **Function Testing**
```bash
# Test all functions
test_system

# Test specific category
test_backup
test_python
test_compatibility
test_bash_install
test_spark
test_jvm
test_jupyter

# Run comprehensive test suite
zsh run-tests.zsh
zsh run-tests.zsh --coverage
```

### **Spark Dependencies**
```bash
# Test Spark setup
test_spark_dependencies

# Show configuration
show_spark_config
```

## 🚨 **Troubleshooting**

### **Common Issues**
1. **Functions not found**: Run `source ~/.config/zsh/zshrc`
2. **Spark not working**: Check `test_spark_dependencies`
3. **Backup failures**: Verify git configuration and permissions

### **Emergency Recovery**
```bash
# Restore from latest backup
cd $(ls -t ~/.zshrc_backups/*/config_* | head -1) && ./restore.sh

# Reset to defaults
defaults delete com.apple.finder AppleShowAllFiles
defaults delete -g ApplePressAndHoldEnabled
```

## 📚 **Next Steps**

1. **Read [System Architecture](System-Architecture)** to understand the design
2. **Explore [macOS Integration](macOS-Integration)** for system optimization
3. **Check [Backup & Recovery](Backup-Recovery)** for safety procedures
4. **Review [Advanced Features](Advanced-Features)** for power user tips

## 💡 **Pro Tips**

- **Always backup before major changes**: `backup_zsh_config "Description"`
- **Use `zsh_help`** to discover new functions
- **Check `python_status`** when Python issues arise
- **Test with `zsh_test_all`** after configuration changes

---

**Ready to supercharge your development environment!** 🚀

**Need help?** Check the other wiki sections or run `zsh_help` for comprehensive assistance.
