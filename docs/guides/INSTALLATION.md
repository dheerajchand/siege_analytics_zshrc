# 🛠️ Installation Guide for Enterprise ZSH System

## 🎯 System Requirements

### **Prerequisites**
- macOS with Homebrew (recommended)  
- Zsh shell (macOS default)
- Git for version control
- Oh My Zsh framework

### **Development Tools**
```bash
# Essential Python tools
brew install pyenv
brew install uv  

# Big data prerequisites
brew install java@17
brew install node  # For development integration

# Optional but recommended
brew install tree  # For directory visualization
brew install bat   # Enhanced file viewing
```

## 🚀 Installation Methods

### **Method 1: Complete System Clone**
```bash
# 1. Navigate to configuration directory
cd ~/.config

# 2. Backup existing zsh config
[ -d zsh ] && mv zsh zsh.backup.$(date +%Y%m%d_%H%M%S)

# 3. Clone the enterprise system
git clone [repository-url] zsh

# 4. Setup main zshrc symlink  
ln -sf ~/.config/zsh/zshrc ~/.zshrc

# 5. Install Oh My Zsh if needed
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 6. Install Powerlevel10k theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

# 7. Test installation
exec zsh
```

### **Method 2: Selective Module Installation**
```bash
# Install just Python system
mkdir -p ~/.config/zsh/python
cp -r python/ ~/.config/zsh/

# Install specific big data modules
cp spark.zsh ~/.config/zsh/     # 74K-line Spark system
cp hadoop.zsh ~/.config/zsh/    # Hadoop integration
cp notebooks.zsh ~/.config/zsh/ # Jupyter integration

# Update main zshrc to source selected modules
```

### **Method 3: Development Setup**
```bash
# For development/customization of the system
cd ~/.config
git clone [repository-url] zsh-dev
cd zsh-dev

# Make modifications
# Test with: ./scripts/setup/quick_install.sh

# Apply when ready:
mv ~/.config/zsh ~/.config/zsh.backup
mv ~/.config/zsh-dev ~/.config/zsh
```

## 🧪 Validation & Testing

### **Installation Validation**
```bash
# 1. Test startup time (should be <1.5s)
time zsh -i -c 'exit'

# 2. Test core functions
python_help                    # Comprehensive guide
python_status                  # Environment information
pyhelp                        # Quick reference

# 3. Test Python system
setup_pyenv                   # Initialize Python management
pyenv versions                # Should show available versions

# 4. Test big data system  
load_big_data                 # Load 74K-line Spark system
# Should see: Spark, Hadoop, notebook support loaded

# 5. Test advanced features
jupyter_spark 8889            # Spark-enabled Jupyter
python_benchmark             # Performance testing
```

### **Performance Targets**
- **✅ Startup time**: <1.5 seconds
- **✅ Memory usage**: <100MB baseline  
- **✅ Command response**: Immediate (no hanging)
- **✅ Module loading**: On-demand, fast

### **Common Issues & Fixes**
```bash
# Slow startup
export PYTHON_AUTOLOAD_MODULES="0"   # Disable auto-loading

# Missing functions
source ~/.config/zsh/python/init.zsh # Reload Python system

# Spark not working  
load_big_data                        # Manual loading required

# Python environment issues
setup_pyenv && python_status         # Reinitialize and check
```

## 🔧 Configuration

### **Set Default Python Environment**
```bash
# After installation
setup_pyenv  
pyenv install 3.11.11              # Install Python version
pyenv virtualenv 3.11.11 default   # Create default environment
pyenv global default               # Set as system default

# For data science
pyenv virtualenv 3.11.11 data_science
pip install pandas numpy jupyter matplotlib seaborn
pyenv global data_science
```

### **Enable Advanced Features**
```bash
# Edit ~/.config/zsh/python/init.zsh for more automation:
export PYTHON_AUTOLOAD_MODULES="1"     # Auto-load all Python modules
export PYTHON_AUTO_INIT="1"            # Auto-initialize Python
export PYTHON_SHOW_STATUS_ON_LOAD="1"  # Show startup status

# Trade some startup speed for more automatic functionality
```

### **Big Data Configuration**
```bash
# Configure Spark memory (adjust for your system)
export SPARK_DRIVER_MEMORY="4g"
export SPARK_EXECUTOR_MEMORY="2g"

# For heavy API workloads
export HEAVY_API_MODE="1"
```

## 🎯 Post-Installation

### **Verify Complete System**
```bash
# Check all major components
python_status                  # Python system
load_big_data && hadoop_status # Big data stack  
python_help                    # Full documentation

# Performance check
time zsh -i -c 'exit'         # Should be fast

# Module inventory
find ~/.config/zsh -name "*.zsh" | wc -l  # Should show 15+ modules
```

### **Create First Project**
```bash
# Data science project
mkdir my_analysis && cd my_analysis
setup_pyenv && pyenv local data_science
load_big_data && jupyter_spark 8889

# Modern web project
mkdir my_api && cd my_api  
setup_uv && uv init --python 3.12
uv add fastapi uvicorn
```

---

**🎉 Installation complete!** You now have access to the enterprise-grade modular ZSH system with 100K+ lines of professional development capabilities.
