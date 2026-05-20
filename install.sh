#!/usr/bin/env bash
# =================================================================
# ZSH Configuration Installer
# =================================================================
# Installs the modular zsh configuration on a new or existing system
# =================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/dheerajchand/siege_analytics_zshrc.git"
CONFIG_DIR="$HOME/.config/zsh"
BACKUP_DIR="$HOME/.config/zsh_backup_$(date +%Y%m%d_%H%M%S)"

# Functions
print_header() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_prerequisites() {
    print_header "Checking Prerequisites"

    local os="unknown"
    local pkg_mgr="unknown"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        os="macos"
        pkg_mgr="brew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os="linux"
        if [[ -f /etc/os-release ]]; then
            # shellcheck disable=SC1091
            source /etc/os-release
            case "$ID" in
                ubuntu | debian) pkg_mgr="apt" ;;
                rhel | centos | fedora) pkg_mgr="yum" ;;
                *) pkg_mgr="unknown" ;;
            esac
        fi
    fi

    if [[ "$os" == "linux" ]]; then
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            print_info "Added ~/.local/bin to PATH for this session"
        fi
    fi

    # Check for zsh
    if ! command -v zsh > /dev/null 2>&1; then
        print_error "zsh is not installed"
        case "$pkg_mgr" in
            brew) echo "Install with: brew install zsh" ;;
            apt) echo "Install with: sudo apt-get install zsh" ;;
            yum) echo "Install with: sudo yum install zsh" ;;
            *) echo "Install zsh using your system's package manager" ;;
        esac
        exit 1
    fi
    print_success "zsh found: $(which zsh)"

    # Check for git
    if ! command -v git > /dev/null 2>&1; then
        print_error "git is not installed"
        case "$pkg_mgr" in
            brew) echo "Install with: brew install git" ;;
            apt) echo "Install with: sudo apt-get install git" ;;
            yum) echo "Install with: sudo yum install git" ;;
            *) echo "Install git using your system's package manager" ;;
        esac
        exit 1
    fi
    print_success "git found: $(which git)"

    # Check for homebrew (macOS)
    if [[ "$os" == "macos" ]]; then
        if ! command -v brew > /dev/null 2>&1; then
            print_warning "Homebrew not found - some features may not work"
        else
            print_success "Homebrew found: $(which brew)"
        fi
    fi
}

backup_existing_config() {
    print_header "Backing Up Existing Configuration"

    local backed_up=false

    # Backup ~/.zshrc
    if [ -f ~/.zshrc ] || [ -L ~/.zshrc ]; then
        mkdir -p "$BACKUP_DIR"
        cp -L ~/.zshrc "$BACKUP_DIR/zshrc" 2> /dev/null || cp ~/.zshrc "$BACKUP_DIR/zshrc"
        print_success "Backed up ~/.zshrc"
        backed_up=true
    fi

    # Backup ~/.zshenv
    if [ -f ~/.zshenv ]; then
        mkdir -p "$BACKUP_DIR"
        cp ~/.zshenv "$BACKUP_DIR/zshenv"
        print_success "Backed up ~/.zshenv"
        backed_up=true
    fi

    # Backup existing config dir
    if [ -d "$CONFIG_DIR" ] && [ ! -L "$CONFIG_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$CONFIG_DIR" "$BACKUP_DIR/zsh_config"
        print_success "Backed up $CONFIG_DIR"
        backed_up=true
    fi

    if $backed_up; then
        print_info "Backups saved to: $BACKUP_DIR"
    else
        print_info "No existing configuration to backup"
    fi
}

install_oh_my_zsh() {
    print_header "Installing Oh-My-Zsh"

    if [ -d "$HOME/.dotfiles/oh-my-zsh" ]; then
        print_success "Oh-My-Zsh already installed"
        return
    fi

    # Create dotfiles directory
    mkdir -p "$HOME/.dotfiles"

    # Clone Oh-My-Zsh
    print_info "Cloning Oh-My-Zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.dotfiles/oh-my-zsh" --depth=1

    # Install Powerlevel10k theme
    if [ ! -d "$HOME/.dotfiles/oh-my-zsh/custom/themes/powerlevel10k" ]; then
        print_info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$HOME/.dotfiles/oh-my-zsh/custom/themes/powerlevel10k"
    fi

    # Install third-party OMZ custom plugins referenced from zshrc.
    local plugins_dir="$HOME/.dotfiles/oh-my-zsh/custom/plugins"
    mkdir -p "$plugins_dir"
    local repo name
    for repo in \
        romkatv/zsh-defer \
        zsh-users/zsh-autosuggestions \
        zsh-users/zsh-syntax-highlighting \
        zsh-users/zsh-completions; do
        name="${repo##*/}"
        if [ ! -d "$plugins_dir/$name" ]; then
            print_info "Installing $name..."
            git clone --depth=1 "https://github.com/$repo.git" "$plugins_dir/$name"
        fi
    done

    print_success "Oh-My-Zsh installed"
}

clone_or_update_repo() {
    print_header "Installing ZSH Configuration"

    if [ -d "$CONFIG_DIR/.git" ]; then
        print_info "Configuration already exists, updating..."
        cd "$CONFIG_DIR"
        git pull origin main
        print_success "Configuration updated"
    else
        print_info "Cloning configuration repository..."

        # Remove directory if it exists but isn't a git repo
        if [ -d "$CONFIG_DIR" ]; then
            rm -rf "$CONFIG_DIR"
        fi

        mkdir -p "$(dirname "$CONFIG_DIR")"
        git clone "$REPO_URL" "$CONFIG_DIR"
        print_success "Configuration cloned"
    fi
}

create_symlinks() {
    print_header "Creating Symlinks"

    # Remove existing ~/.zshrc if it exists
    if [ -f ~/.zshrc ] || [ -L ~/.zshrc ]; then
        rm ~/.zshrc
        print_info "Removed existing ~/.zshrc"
    fi

    # Create symlink
    ln -s "$CONFIG_DIR/zshrc" ~/.zshrc
    print_success "Created symlink: ~/.zshrc -> $CONFIG_DIR/zshrc"

    # Verify symlink
    if [ -L ~/.zshrc ]; then
        print_success "Symlink verified"
    else
        print_error "Failed to create symlink"
        exit 1
    fi
}

install_dependencies() {
    print_header "Checking Dependencies"

    # Check for pyenv
    if ! command -v pyenv > /dev/null 2>&1; then
        print_warning "pyenv not found"
        echo ""
        echo "To install pyenv:"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "  brew install pyenv pyenv-virtualenv"
        else
            echo "  curl https://pyenv.run | bash"
        fi
        echo ""
        echo "Then install Python:"
        echo "  pyenv install 3.11.11"
        echo "  pyenv virtualenv 3.11.11 default_31111"
        echo ""
    else
        print_success "pyenv found: $(which pyenv)"
    fi

    # Check for SDKMAN (for Hadoop/Spark)
    if [ ! -d "$HOME/.sdkman" ]; then
        print_warning "SDKMAN not found (needed for Hadoop/Spark)"
        echo ""
        echo "To install SDKMAN:"
        echo "  curl -s https://get.sdkman.io | bash"
        echo ""
    else
        print_success "SDKMAN found"
    fi

    # Check for Docker
    if ! command -v docker > /dev/null 2>&1; then
        print_warning "Docker not found"
        echo "Install from: https://www.docker.com/products/docker-desktop"
    else
        print_success "Docker found: $(which docker)"
    fi
}

verify_installation() {
    print_header "Verifying Installation"

    # Check symlink
    if [ -L ~/.zshrc ]; then
        print_success "Symlink exists: $(readlink ~/.zshrc)"
    else
        print_error "Symlink not found"
        return 1
    fi

    # Check config directory
    if [ -d "$CONFIG_DIR" ]; then
        print_success "Config directory exists"
    else
        print_error "Config directory not found"
        return 1
    fi

    # Check module files
    # Dynamically discover all modules
    local modules=()
    local f
    for f in "$CONFIG_DIR"/modules/*.zsh; do
        [ -f "$f" ] && modules+=("$(basename "${f%.zsh}")")
    done
    local missing_modules=()

    for module in "${modules[@]}"; do
        if [ ! -f "$CONFIG_DIR/modules/$module.zsh" ]; then
            missing_modules+=("$module")
        fi
    done

    if [ ${#missing_modules[@]} -eq 0 ]; then
        print_success "All modules present"
    else
        print_warning "Missing modules: ${missing_modules[*]}"
    fi

    # Try to source the config (syntax check)
    if zsh -n "$CONFIG_DIR/zshrc" 2> /dev/null; then
        print_success "Configuration syntax valid"
    else
        print_error "Configuration has syntax errors"
        return 1
    fi
}

print_next_steps() {
    print_header "Installation Complete! 🎉"

    echo "Next steps:"
    echo ""
    echo "1. Restart your terminal or run:"
    printf "   %b\n" "${GREEN}exec zsh${NC}"
    echo ""
    echo "2. Configure Powerlevel10k theme (if prompted):"
    echo "   Follow the interactive configuration wizard"
    echo ""
    echo "3. Install Python environment (if needed):"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        printf "   %b\n" "${BLUE}brew install pyenv pyenv-virtualenv${NC}"
    else
        printf "   %b\n" "${BLUE}curl https://pyenv.run | bash${NC}"
    fi
    printf "   %b\n" "${BLUE}pyenv install 3.11.11${NC}"
    printf "   %b\n" "${BLUE}pyenv virtualenv 3.11.11 default_31111${NC}"
    echo ""
    echo "4. Check your setup:"
    printf "   %b\n" "${BLUE}help${NC}          - Show all commands"
    printf "   %b\n" "${BLUE}modules${NC}       - List loaded modules"
    printf "   %b\n" "${BLUE}python_status${NC} - Check Python environment"
    echo ""

    if [ -d "$BACKUP_DIR" ]; then
        echo "Your old configuration was backed up to:"
        printf "   %b\n" "${YELLOW}$BACKUP_DIR${NC}"
        echo ""
    fi

    print_success "Enjoy your new shell configuration!"
}

# Main installation flow
main() {
    clear
    print_header "ZSH Configuration Installer"

    echo "This script will install the modular zsh configuration"
    echo "Repository: $REPO_URL"
    echo ""
    echo "Press Enter to continue or Ctrl+C to cancel..."
    read

    check_prerequisites
    backup_existing_config
    install_oh_my_zsh
    clone_or_update_repo
    create_symlinks
    install_dependencies

    if verify_installation; then
        print_next_steps
    else
        print_error "Installation verification failed"
        echo ""
        echo "Please check the errors above and try again"
        exit 1
    fi
}

# Run the installer
main "$@"
