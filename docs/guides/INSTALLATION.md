# 🛠️ Installation Guide

## 🎯 System Requirements

### Prerequisites
- **macOS** with Homebrew
- **Zsh** shell  
- **Oh My Zsh** framework
- **Git** for version control

### Required Tools
```bash
# Core tools
brew install pyenv
brew install uv
brew install node

# Big data stack (optional)
brew install java@17
# Spark and Hadoop installed via system
```

## 🚀 Installation Methods

### Method 1: Direct Clone (Recommended)
```bash
# 1. Backup existing config
cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d)

# 2. Clone the configuration system  
git clone [your-repo-url] ~/.config/zsh.new

# 3. Replace current system
mv ~/.config/zsh ~/.config/zsh.backup
mv ~/.config/zsh.new ~/.config/zsh

# 4. Update symlink (if needed)
ln -sf ~/.config/zsh/zshrc ~/.zshrc

# 5. Test
exec zsh
```

### Method 2: Selective Installation
```bash
# Install just Python system
mkdir -p ~/.config/zsh/python
cp -r python/ ~/.config/zsh/

# Install specific modules
cp spark.zsh ~/.config/zsh/
cp hadoop.zsh ~/.config/zsh/

# Update main zshrc to source modules
```

## 🧪 Validation

After installation:
```bash
# Test startup time (target: <1.5s)
time zsh -i -c 'exit'

# Test core functions
python_help
python_status
load_big_data

# Test advanced features
setup_pyenv
pyenv versions
```

## 🔧 Configuration

### Set Default Python Environment
```bash
setup_pyenv
pyenv global 3.11.11  # or your preferred version
pyenv global geo31111  # or your preferred virtualenv
```

### Enable Advanced Features
```bash
# In ~/.config/zsh/python/init.zsh, set:
export PYTHON_AUTOLOAD_MODULES="1"     # Auto-load Python modules
export PYTHON_AUTO_INIT="1"            # Auto-initialize Python
export PYTHON_SHOW_STATUS_ON_LOAD="1"  # Show startup status
```
