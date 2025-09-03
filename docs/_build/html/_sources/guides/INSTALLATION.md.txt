# 🛠️ Installation Guide for Enterprise ZSH System (SDKMAN-Based)

## 🎯 System Requirements

### **Prerequisites**
- macOS, Ubuntu Linux, or RedHat Linux
- Zsh shell (macOS default, installable on Linux)
- Git for version control
- Oh My Zsh framework
- **SDKMAN** for all tool management (cross-platform consistency)

### **SDKMAN-First Philosophy**
This system uses **SDKMAN** for all development tool management, ensuring:
- **Consistent installation** across all platforms
- **Version management** for all tools
- **No root privileges** required
- **Cross-platform compatibility** (macOS, Ubuntu, RedHat)

## 🚀 Installation Methods

### **Method 1: Complete System Clone (Recommended)**

#### Step 1: Install SDKMAN
```bash
# Install SDKMAN (works on all platforms)
curl -s "https://get.sdkman.io" | bash

# Reload shell
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Verify installation
sdk version
```

#### Step 2: Install All Tools via SDKMAN
```bash
# Java (OpenJDK 17 - recommended for Spark 3.5.3)
sdk install java 17.0.9-tem
sdk default java 17.0.9-tem

# Scala (2.12.18 for Spark compatibility)
sdk install scala 2.12.18
sdk default scala 2.12.18

# Spark (3.5.3 - latest stable)
sdk install spark 3.5.3
sdk default spark 3.5.3

# Hadoop (3.3.6 - compatible with Spark 3.5.3)
sdk install hadoop 3.3.6
sdk default hadoop 3.3.6

# Maven (for dependency management)
sdk install maven 3.9.6
sdk default maven 3.9.6

# Gradle (alternative build tool)
sdk install gradle 8.5
sdk default gradle 8.5
```

#### Step 3: Install Python Tools
```bash
# pyenv (Python version management)
sdk install pyenv
sdk default pyenv

# Initialize pyenv
export PYENV_ROOT="$HOME/.sdkman/candidates/pyenv/current"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Install Python 3.11 (recommended)
pyenv install 3.11.7
pyenv global 3.11.7

# Install uv (modern Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
```

#### Step 4: Install Node.js Tools
```bash
# NVM (Node version management)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Node.js LTS
nvm install --lts
nvm use --lts
nvm alias default lts/*
```

#### Step 5: Clone and Setup Configuration
```bash
# 1. Navigate to configuration directory
cd ~/.config

# 2. Backup existing zsh config
[ -d zsh ] && mv zsh zsh.backup.$(date +%Y%m%d_%H%M%S)

# 3. Clone the enterprise system
git clone https://github.com/dheerajchand/siege_analytics_zshrc.git zsh

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
git clone https://github.com/dheerajchand/siege_analytics_zshrc.git zsh-dev
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
zsh_help all               # Comprehensive guide
zsh_help backup            # Backup system help
zsh_help spark             # Spark system help

# 3. Test Python system
setup_pyenv               # Initialize Python management
pyenv versions            # Should show available versions

# 4. Test big data system  
load_big_data             # Load 74K-line Spark system
# Should see: Spark, Hadoop, notebook support loaded

# 5. Test advanced features
jupyter_spark 8889        # Spark-enabled Jupyter
python_benchmark         # Performance testing
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
source ~/.config/zsh/backup-system.zsh # Reload backup system

# Spark not working  
load_big_data                        # Manual loading required

# Python environment issues
setup_pyenv && python_status         # Reinitialize and check

# SDKMAN issues
source "$HOME/.sdkman/bin/sdkman-init.sh"  # Reload SDKMAN
sdk current                          # Check installed tools
```

## 🔧 Configuration

### **Set Default Python Environment**
```bash
# After installation
setup_pyenv  
pyenv install 3.11.7              # Install Python version
pyenv virtualenv 3.11.7 default   # Create default environment
pyenv global default               # Set as system default

# For data science
pyenv virtualenv 3.11.7 data_science
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

### **SDKMAN Environment Variables**
```bash
# Add to ~/.zshrc for consistent SDKMAN integration
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# SDKMAN-managed environment variables
export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
export SCALA_HOME="$HOME/.sdkman/candidates/scala/current"
export SPARK_HOME="$HOME/.sdkman/candidates/spark/current"
export HADOOP_HOME="$HOME/.sdkman/candidates/hadoop/current"
export MAVEN_HOME="$HOME/.sdkman/candidates/maven/current"
export GRADLE_HOME="$HOME/.sdkman/candidates/gradle/current"

# Add to PATH
export PATH="$JAVA_HOME/bin:$SCALA_HOME/bin:$SPARK_HOME/bin:$HADOOP_HOME/bin:$MAVEN_HOME/bin:$GRADLE_HOME/bin:$PATH"
```

## 🎯 Post-Installation

### **Verify Complete System**
```bash
# Check all major components
zsh_help all                  # Help system
load_big_data && hadoop_status # Big data stack  
python_status                 # Python system

# Performance check
time zsh -i -c 'exit'        # Should be fast

# Module inventory
find ~/.config/zsh -name "*.zsh" | wc -l  # Should show 15+ modules

# SDKMAN verification
sdk current                   # Should show all installed tools
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

## 🌍 Cross-Platform Notes

### **macOS**
- SDKMAN works natively
- No additional system dependencies required
- All tools managed through SDKMAN

### **Ubuntu Linux**
```bash
# Install minimal system dependencies
sudo apt update
sudo apt install -y zsh git curl wget build-essential python3 python3-pip python3-venv python3-dev

# Then follow SDKMAN installation above
```

### **RedHat Linux**
```bash
# Install minimal system dependencies
sudo dnf install -y epel-release
sudo dnf install -y zsh git curl wget gcc gcc-c++ make python3 python3-pip python3-devel

# Then follow SDKMAN installation above
```

## 🔧 Troubleshooting

### **SDKMAN Issues**
```bash
# Check SDKMAN installation
ls -la ~/.sdkman

# Reinstall if needed
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Check installed tools
sdk current

# List available candidates
sdk list java
sdk list scala
sdk list spark
```

### **Tool Not Found Issues**
```bash
# Check environment variables
echo "JAVA_HOME: $JAVA_HOME"
echo "SPARK_HOME: $SPARK_HOME"
echo "HADOOP_HOME: $HADOOP_HOME"

# Reload SDKMAN
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Reinstall tools if needed
sdk install java 17.0.9-tem
sdk default java 17.0.9-tem
```

### **Performance Issues**
```bash
# Profile shell startup
time zsh -i -c exit

# Check for slow-loading modules
zsh -i -c "echo 'Shell loaded'"

# Use optimization function
optimize
```

---

**🎉 Installation complete!** You now have access to the enterprise-grade modular ZSH system with 100K+ lines of professional development capabilities, all managed through SDKMAN for consistent cross-platform operation.