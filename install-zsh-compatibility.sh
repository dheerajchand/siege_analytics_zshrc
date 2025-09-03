#!/bin/zsh
# =====================================================
# ZSH COMPATIBILITY INSTALLATION SCRIPT
# Installs Siege Analytics Configuration for ZSH
# =====================================================

set -e

echo "=========================================="
echo "Siege Analytics Configuration for ZSH"
echo "=========================================="

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    echo "Platform: macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
    echo "Platform: Linux"
else
    echo "Error: Unsupported platform: $OSTYPE"
    exit 1
fi

# Check if running in zsh
if [ -z "$ZSH_VERSION" ]; then
    echo "Error: This script must be run in zsh"
    exit 1
fi

echo "Shell: ZSH $ZSH_VERSION"
echo ""

# Install SDKMAN
echo "Installing SDKMAN..."
if [ ! -d "$HOME/.sdkman" ]; then
    curl -s "https://get.sdkman.io" | bash
    echo "SDKMAN installed successfully"
else
    echo "SDKMAN already installed"
fi

# Source SDKMAN
echo "Sourcing SDKMAN..."
source "$HOME/.sdkman/bin/sdkman-init.sh"

# Install Java
echo "Installing Java 17..."
sdk install java 17.0.9-tem
sdk default java 17.0.9-tem
echo "Java installed successfully"

# Install Scala
echo "Installing Scala 2.12.18..."
sdk install scala 2.12.18
sdk default scala 2.12.18
echo "Scala installed successfully"

# Install Spark
echo "Installing Spark 3.5.3..."
sdk install spark 3.5.3
sdk default spark 3.5.3
echo "Spark installed successfully"

# Install Hadoop
echo "Installing Hadoop 3.3.6..."
sdk install hadoop 3.3.6
sdk default hadoop 3.3.6
echo "Hadoop installed successfully"

# Install Maven
echo "Installing Maven 3.9.6..."
sdk install maven 3.9.6
sdk default maven 3.9.6
echo "Maven installed successfully"

# Install Gradle
echo "Installing Gradle 8.5..."
sdk install gradle 8.5
sdk default gradle 8.5
echo "Gradle installed successfully"

# Install pyenv
echo "Installing pyenv..."
sdk install pyenv
sdk default pyenv
echo "pyenv installed successfully"

# Clone configuration repository
echo "Cloning configuration repository..."
cd ~/.config
if [ -d "zsh" ]; then
    echo "Configuration directory already exists, backing up..."
    mv zsh zsh.backup.$(date +%Y%m%d_%H%M%S)
fi

git clone https://github.com/dheerajchand/siege_analytics_zshrc.git zsh
echo "Configuration repository cloned successfully"

# Create zsh symlink
echo "Creating zsh configuration symlink..."
if [ -f ~/.zshrc ]; then
    echo "Backing up existing .zshrc..."
    mv ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
fi

ln -sf ~/.config/zsh/zshrc ~/.zshrc
echo "ZSH configuration symlink created"

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My Zsh installed successfully"
else
    echo "Oh My Zsh already installed"
fi

# Install Powerlevel10k theme
echo "Installing Powerlevel10k theme..."
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
    echo "Powerlevel10k theme installed successfully"
else
    echo "Powerlevel10k theme already installed"
fi

# Create validation script
echo "Creating validation script..."
cat > ~/.config/zsh/validate-zsh.sh << 'EOF'
#!/bin/zsh
# Validation script for zsh compatibility

echo "=== ZSH Compatibility Validation ==="
echo "Shell: $CURRENT_SHELL"
echo "Platform: $PLATFORM"
echo ""

# Test basic functions
echo "Testing basic functions..."
python_status
echo ""

# Test backup system
echo "Testing backup system..."
backup "ZSH compatibility validation"
echo ""

# Test Spark integration
echo "Testing Spark integration..."
setup_spark
show_spark_config
echo ""

# Test tool availability
echo "Testing tool availability..."
command -v java >/dev/null && echo "Java: OK" || echo "Java: MISSING"
command -v spark-shell >/dev/null && echo "Spark: OK" || echo "Spark: MISSING"
command -v pyenv >/dev/null && echo "Pyenv: OK" || echo "Pyenv: MISSING"
command -v mvn >/dev/null && echo "Maven: OK" || echo "Maven: MISSING"
command -v gradle >/dev/null && echo "Gradle: OK" || echo "Gradle: MISSING"
echo ""

echo "Validation complete"
echo "==================="
EOF

chmod +x ~/.config/zsh/validate-zsh.sh

# Create test script
echo "Creating test script..."
cat > ~/.config/zsh/test-zsh.sh << 'EOF'
#!/bin/zsh
# Test script for zsh compatibility

echo "=== ZSH Compatibility Test ==="
test_compatibility
echo ""

echo "=== Help System Test ==="
zsh_help all
echo ""

echo "=== Python Management Test ==="
zsh_help python
echo ""

echo "=== Backup System Test ==="
zsh_help backup
echo ""

echo "=== Spark Integration Test ==="
zsh_help spark
echo ""

echo "Test complete"
echo "============="
EOF

chmod +x ~/.config/zsh/test-zsh.sh

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "To use the configuration:"
echo "1. Restart your shell or run: exec zsh"
echo "2. Test the installation: ~/.config/zsh/test-zsh.sh"
echo "3. Validate the setup: ~/.config/zsh/validate-zsh.sh"
echo "4. Get help: zsh_help all"
echo ""
echo "Configuration files:"
echo "- Main config: ~/.config/zsh/"
echo "- ZSH config: ~/.zshrc (symlink)"
echo "- Compatibility: ~/.config/zsh/bash-compatibility.zsh"
echo ""
echo "For support, visit: https://github.com/dheerajchand/siege_analytics_zshrc"
echo "=========================================="
