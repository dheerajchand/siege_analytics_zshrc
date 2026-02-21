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

# Or reload a specific module (example)
source ~/.config/zsh/modules/utils.zsh
```

### **2. Verify Setup**
```bash
# Check macOS configuration status
defaults read com.apple.finder AppleShowAllFiles
defaults read -g ApplePressAndHoldEnabled

# Test core functions
help
```

### **Profiles & PT Host Mapping**
```bash
# Show available profiles and color palettes
secrets_profiles

# Example secrets.env entries:
# ZSH_ENV_PROFILE=dev
# PT_ENV_HOSTNAME=cyberpower
```

### **Screen + Pyenv**
```bash
screen_ensure_pyenv
```

### **Bootstrap from 1Password**
```bash
secrets_bootstrap_from_1p
```

### **Verify 1Password Accounts**
```bash
op_verify_accounts
```
Item titles are redacted if they look like secrets.

### **Headless 1Password Login**
```bash
op_login_headless
```

### **Rsync Secrets (Fallback)**
```bash
secrets_rsync_to_host user@host
secrets_rsync_from_host user@host
secrets_rsync_to_host --user dheerajchand --host cyberpower --path ~/.config/zsh
secrets_rsync_to_cyberpower
secrets_rsync_from_cyberpower
secrets_rsync_verify --host cyberpower
```

### **Set 1Password Account Aliases**
```bash
op_accounts_set_alias Dheeraj_Chand_Family I3C75JBKZJGSLMVQDGRKCVNHIM
op_accounts_seed
```

### **Set 1Password Source of Truth**
```bash
secrets_source_set Dheeraj_Chand_Family Private
secrets_source_status
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
help                       # Display comprehensive help
zshconfig                   # Edit configuration directory
zshreboot                   # Reload configuration
backup "message"           # Commit + push current branch
backup_merge_main          # Merge current branch into main + push
pushmain "message"         # backup + merge-to-main
secrets_profiles           # List available profiles and colors
```

### **Welcome Banner**
On shell startup, the banner includes:
- Git branch + last commit for this config
- Python version + active venv
- Profile and stack availability
- Spark/Scala/Hadoop versions
- Secrets status

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

## 🤖 AI Config Initialization

Use these from any project root:

```bash
# Claude-only initialization
claude_init --yes

# Codex-only initialization
codex_init --yes

# Update existing Codex files with required policy rules (non-destructive)
codex_init --update

# Both Claude + Codex initialization
ai_init --yes
```

Session helpers:
```bash
codex_init --yes --add-session --session-name myproj_dev --session-desc "Project dev session"
codex_session myproj_dev
claude_session myproj_dev
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

### **Install Spark from Tarball**
```bash
spark_install_from_tar 4.1.1 /path/to/spark-4.1.1-bin-hadoop3-connect.tar
spark_install_from_tar --default --dry-run 4.1.1 /path/to/spark-4.1.1-bin-hadoop3-connect.tar
```
Optional dependency overrides:
```bash
export SPARK_VERSION=4.1.1
export SPARK_SCALA_VERSION=2.13.17
```
Universal jars directory:
```bash
export JARS_DIR="$HOME/.jars"
```
Sedona defaults:
```bash
export SPARK_SEDONA_ENABLE=1
export SPARK_SEDONA_VERSION=1.8.1
export SPARK_GEOTOOLS_VERSION=1.8.1-33.1
```
Resolve jar matrix:
```bash
jar_matrix_resolve
jar_matrix_status
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
├── modules/utils.zsh      # General utilities and macOS configs
├── spark.zsh             # Spark-specific functions and shells
├── hadoop.zsh            # Hadoop configuration and utilities
├── docker.zsh            # Docker management and switching
├── notebooks.zsh         # Jupyter and notebook integration
├── modules/backup.zsh     # Git backup and merge workflow
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
# Create initial branch backup
backup "Initial setup backup"

# Merge branch work to main
backup_merge_main
```

## 🧪 **Testing Your Setup**

### **Function Testing**
```bash
# Run all tests
zsh run-tests.zsh

# Run a specific test
zsh run-tests.zsh --test backup_pushes_current_branch
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

- **Always backup before major changes**: `backup "Description"`
- **Use `help`** to discover functions
- **Check `python_status`** when Python issues arise
- **Test with `zsh_test_all`** after configuration changes

---

**Ready to supercharge your development environment!** 🚀

**Need help?** Check the other wiki sections or run `help` for comprehensive assistance.
