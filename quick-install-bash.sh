#!/bin/bash

# =============================================================================
# Quick Bash Installation Script
# =============================================================================
# 
# One-liner installation for bash users:
# curl -fsSL https://raw.githubusercontent.com/dheerajchand/siege_analytics_zshrc/main/quick-install-bash.sh | bash
#
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}🚀 Installing Siege Analytics Configuration for Bash...${RESET}"

# Create config directory
mkdir -p "$HOME/.config/zsh"

# Clone repository
if [[ -d "$HOME/.config/zsh" ]]; then
    cd "$HOME/.config/zsh"
    if [[ -d ".git" ]]; then
        echo -e "${BLUE}📁 Updating existing configuration...${RESET}"
        git pull origin main
    else
        echo -e "${BLUE}📁 Cloning configuration...${RESET}"
        git clone https://github.com/dheerajchand/siege_analytics_zshrc.git .
    fi
else
    echo -e "${BLUE}📁 Cloning configuration...${RESET}"
    git clone https://github.com/dheerajchand/siege_analytics_zshrc.git "$HOME/.config/zsh"
fi

# Make scripts executable
chmod +x "$HOME/.config/zsh/bash-compatibility.zsh"
chmod +x "$HOME/.config/zsh/install-bash-compatibility.sh"

# Install bash compatibility
echo -e "${BLUE}🔧 Installing bash compatibility...${RESET}"
bash "$HOME/.config/zsh/install-bash-compatibility.sh"

# Add to .bashrc
echo -e "${BLUE}📝 Configuring bash...${RESET}"
cat >> "$HOME/.bashrc" << 'EOF'

# Siege Analytics Configuration
if [[ -f "$HOME/.config/zsh/bash-compatibility.zsh" ]]; then
    source "$HOME/.config/zsh/bash-compatibility.zsh"
    echo "🚀 Siege Analytics Configuration loaded for bash"
fi
EOF

echo -e "${GREEN}✅ Installation complete!${RESET}"
echo -e "${YELLOW}⚠️  Please restart your terminal or run: source ~/.bashrc${RESET}"
echo -e "${CYAN}📚 Documentation: https://github.com/dheerajchand/siege_analytics_zshrc/wiki${RESET}"
echo -e "${CYAN}🧪 Test installation: test_system${RESET}"
