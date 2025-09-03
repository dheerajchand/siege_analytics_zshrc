#!/bin/bash

# =============================================================================
# Siege Analytics Zsh Configuration - Bash Compatibility Installer
# =============================================================================
# 
# This script automatically installs the Zsh configuration for bash users,
# providing full compatibility and functionality across both shells.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/dheerajchand/siege_analytics_zshrc/main/install-for-bash.sh | bash
#   wget -qO- https://raw.githubusercontent.com/dheerajchand/siege_analytics_zshrc/main/install-for-bash.sh | bash
#
# =============================================================================

set -e

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly RESET='\033[0m'

# Configuration
readonly REPO_URL="https://github.com/dheerajchand/siege_analytics_zshrc.git"
readonly INSTALL_DIR="$HOME/.config/zsh"
readonly BACKUP_DIR="$HOME/.zshrc_backups"
readonly BASH_CONFIG_FILE="$HOME/.bashrc"
readonly BASH_PROFILE_FILE="$HOME/.bash_profile"

# =============================================================================
# Utility Functions
# =============================================================================

print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                    Siege Analytics Zsh Configuration                        ║"
    echo "║                         Bash Compatibility Installer                        ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_step() {
    echo -e "${BLUE}🔧 $1${RESET}"
}

print_success() {
    echo -e "${GREEN}✅ $1${RESET}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${RESET}"
}

print_error() {
    echo -e "${RED}❌ $1${RESET}"
}

print_info() {
    echo -e "${WHITE}ℹ️  $1${RESET}"
}

# =============================================================================
# System Detection
# =============================================================================

detect_system() {
    print_step "Detecting system environment..."
    
    # Detect OS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_success "Detected macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            OS="ubuntu"
            print_success "Detected Ubuntu/Debian"
        elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
            OS="redhat"
            print_success "Detected RedHat/CentOS/Rocky Linux"
        else
            OS="linux"
            print_success "Detected Linux"
        fi
    else
        OS="unknown"
        print_warning "Unknown OS: $OSTYPE"
    fi
    
    # Detect shell
    CURRENT_SHELL=$(basename "$SHELL")
    print_success "Current shell: $CURRENT_SHELL"
    
    # Detect architecture
    ARCH=$(uname -m)
    print_success "Architecture: $ARCH"
}

# =============================================================================
# Prerequisites Check
# =============================================================================

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    local missing_deps=()
    
    # Check for git
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    # Check for curl or wget
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        missing_deps+=("curl or wget")
    fi
    
    # Check for zsh (optional but recommended)
    if ! command -v zsh >/dev/null 2>&1; then
        print_warning "Zsh not found - will install bash compatibility only"
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_info "Please install the missing dependencies and run this script again."
        exit 1
    fi
    
    print_success "All prerequisites satisfied"
}

# =============================================================================
# Installation Functions
# =============================================================================

install_sdkman() {
    print_step "Installing SDKMAN..."
    
    if [[ -d "$HOME/.sdkman" ]]; then
        print_success "SDKMAN already installed"
        return 0
    fi
    
    # Install SDKMAN
    curl -s "https://get.sdkman.io" | bash
    
    # Source SDKMAN
    if [[ -f "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        print_success "SDKMAN installed successfully"
    else
        print_error "Failed to install SDKMAN"
        return 1
    fi
}

install_java() {
    print_step "Installing Java via SDKMAN..."
    
    if command -v java >/dev/null 2>&1; then
        print_success "Java already installed: $(java -version 2>&1 | head -1)"
        return 0
    fi
    
    # Install Java 11 (LTS)
    if command -v sdk >/dev/null 2>&1; then
        sdk install java 11.0.21-tem
        sdk use java 11.0.21-tem
        print_success "Java 11 installed successfully"
    else
        print_error "SDKMAN not available - cannot install Java"
        return 1
    fi
}

install_spark() {
    print_step "Installing Apache Spark via SDKMAN..."
    
    if command -v spark-shell >/dev/null 2>&1; then
        print_success "Spark already installed"
        return 0
    fi
    
    # Install Spark
    if command -v sdk >/dev/null 2>&1; then
        sdk install spark 3.5.0
        sdk use spark 3.5.0
        print_success "Spark 3.5.0 installed successfully"
    else
        print_error "SDKMAN not available - cannot install Spark"
        return 1
    fi
}

install_hadoop() {
    print_step "Installing Hadoop via SDKMAN..."
    
    if command -v hadoop >/dev/null 2>&1; then
        print_success "Hadoop already installed"
        return 0
    fi
    
    # Install Hadoop
    if command -v sdk >/dev/null 2>&1; then
        sdk install hadoop 3.3.6
        sdk use hadoop 3.3.6
        print_success "Hadoop 3.3.6 installed successfully"
    else
        print_error "SDKMAN not available - cannot install Hadoop"
        return 1
    fi
}

install_python_tools() {
    print_step "Installing Python tools..."
    
    # Install pyenv
    if ! command -v pyenv >/dev/null 2>&1; then
        print_info "Installing pyenv..."
        curl https://pyenv.run | bash
        print_success "pyenv installed"
    else
        print_success "pyenv already installed"
    fi
    
    # Install uv
    if ! command -v uv >/dev/null 2>&1; then
        print_info "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        print_success "uv installed"
    else
        print_success "uv already installed"
    fi
}

# =============================================================================
# Configuration Installation
# =============================================================================

clone_repository() {
    print_step "Cloning Siege Analytics Zsh Configuration..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        print_info "Configuration directory already exists - updating..."
        cd "$INSTALL_DIR"
        git pull origin main
    else
        print_info "Cloning repository..."
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi
    
    print_success "Configuration repository ready"
}

install_bash_compatibility() {
    print_step "Installing bash compatibility layer..."
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR/bash-compatibility.zsh"
    chmod +x "$INSTALL_DIR/install-bash-compatibility.sh"
    
    # Run bash compatibility installer
    if [[ -f "$INSTALL_DIR/install-bash-compatibility.sh" ]]; then
        bash "$INSTALL_DIR/install-bash-compatibility.sh"
        print_success "Bash compatibility layer installed"
    else
        print_error "Bash compatibility installer not found"
        return 1
    fi
}

configure_bash() {
    print_step "Configuring bash environment..."
    
    # Create backup of existing bash configuration
    if [[ -f "$BASH_CONFIG_FILE" ]]; then
        cp "$BASH_CONFIG_FILE" "$BASH_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Backed up existing .bashrc"
    fi
    
    # Add configuration to .bashrc
    cat >> "$BASH_CONFIG_FILE" << 'EOF'

# =============================================================================
# Siege Analytics Configuration - Bash Compatibility
# =============================================================================

# Source the bash compatibility layer
if [[ -f "$HOME/.config/zsh/bash-compatibility.zsh" ]]; then
    source "$HOME/.config/zsh/bash-compatibility.zsh"
    echo "🚀 Siege Analytics Configuration loaded for bash"
fi

# Initialize compatibility layer
if command -v init_compatibility >/dev/null 2>&1; then
    init_compatibility
fi
EOF
    
    print_success "Bash configuration updated"
}

configure_bash_profile() {
    print_step "Configuring bash profile..."
    
    # Ensure .bashrc is sourced from .bash_profile on macOS
    if [[ "$OS" == "macos" ]] && [[ -f "$BASH_PROFILE_FILE" ]]; then
        if ! grep -q "source.*bashrc" "$BASH_PROFILE_FILE"; then
            echo "source ~/.bashrc" >> "$BASH_PROFILE_FILE"
            print_success "Updated .bash_profile to source .bashrc"
        fi
    fi
}

# =============================================================================
# Testing and Validation
# =============================================================================

test_installation() {
    print_step "Testing installation..."
    
    # Test bash compatibility
    if bash -c "source $INSTALL_DIR/bash-compatibility.zsh && init_compatibility && echo 'Bash compatibility test passed'"; then
        print_success "Bash compatibility test passed"
    else
        print_error "Bash compatibility test failed"
        return 1
    fi
    
    # Test function availability
    if bash -c "source $INSTALL_DIR/bash-compatibility.zsh && type setup_python_manager >/dev/null 2>&1"; then
        print_success "Core functions available"
    else
        print_error "Core functions not available"
        return 1
    fi
    
    print_success "Installation test completed"
}

# =============================================================================
# Post-Installation Setup
# =============================================================================

setup_environment() {
    print_step "Setting up environment..."
    
    # Create backup directory
    mkdir -p "$BACKUP_DIR"
    print_success "Backup directory created: $BACKUP_DIR"
    
    # Set up Python environment
    if command -v setup_python_manager >/dev/null 2>&1; then
        bash -c "source $INSTALL_DIR/bash-compatibility.zsh && setup_python_manager auto"
        print_success "Python environment configured"
    fi
    
    # Set up Spark environment
    if command -v setup_spark >/dev/null 2>&1; then
        bash -c "source $INSTALL_DIR/bash-compatibility.zsh && setup_spark"
        print_success "Spark environment configured"
    fi
}

show_completion_message() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                           Installation Complete!                            ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
    
    echo -e "${WHITE}🎉 Siege Analytics Zsh Configuration has been successfully installed for bash!${RESET}"
    echo ""
    echo -e "${CYAN}📋 What was installed:${RESET}"
    echo "  • Bash compatibility layer"
    echo "  • Python environment management (pyenv, uv)"
    echo "  • Java and JVM tools (via SDKMAN)"
    echo "  • Apache Spark and Hadoop"
    echo "  • Comprehensive testing framework"
    echo "  • Backup and sync system"
    echo ""
    echo -e "${CYAN}🚀 Quick start commands:${RESET}"
    echo "  • test_system          # Run system tests"
    echo "  • setup_python_manager # Configure Python"
    echo "  • setup_spark          # Configure Spark"
    echo "  • zsh_help            # Show help"
    echo ""
    echo -e "${CYAN}📚 Documentation:${RESET}"
    echo "  • Wiki: https://github.com/dheerajchand/siege_analytics_zshrc/wiki"
    echo "  • README: $INSTALL_DIR/README.md"
    echo ""
    echo -e "${YELLOW}⚠️  Important:${RESET}"
    echo "  • Restart your terminal or run: source ~/.bashrc"
    echo "  • All functions are now available in bash"
    echo "  • Use 'test_system' to verify everything works"
    echo ""
    echo -e "${GREEN}✨ Enjoy your enhanced bash environment!${RESET}"
}

# =============================================================================
# Main Installation Process
# =============================================================================

main() {
    print_header
    
    # System detection
    detect_system
    
    # Prerequisites check
    check_prerequisites
    
    # Install tools
    install_sdkman
    install_java
    install_spark
    install_hadoop
    install_python_tools
    
    # Install configuration
    clone_repository
    install_bash_compatibility
    configure_bash
    configure_bash_profile
    
    # Setup and test
    setup_environment
    test_installation
    
    # Show completion message
    show_completion_message
}

# =============================================================================
# Error Handling
# =============================================================================

trap 'print_error "Installation failed at line $LINENO"; exit 1' ERR

# =============================================================================
# Run Main Function
# =============================================================================

main "$@"
