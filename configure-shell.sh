#!/bin/bash
# =====================================================
# SHELL CONFIGURATION SCRIPT
# =====================================================
# 
# This script provides flexible configuration options for setting up
# zshrc and bashrc files. It can create symlinks, copy files, or
# set up standalone configurations based on user preferences.
#
# Usage:
#   ./configure-shell.sh [options]
#
# Options:
#   --mode <mode>           Setup mode: symlink, copy, standalone
#   --target <path>         Target path for symlinks (default: auto-detect)
#   --shell <shell>         Shell to configure: zsh, bash, both (default: both)
#   --backup                Create backup of existing files
#   --force                 Overwrite existing files without confirmation
#   --setup-env             Set up environment variables for future use
#   --personal              Use personal defaults (symlink to ~/.dotfiles/homedir)
#   --help                  Show this help message
#
# Environment Variables:
#   SHELL_CONFIG_MODE       Default mode (symlink, copy, standalone)
#   SHELL_CONFIG_TARGET     Default target path
#   SHELL_CONFIG_BACKUP     Default backup behavior (true/false)
#
# Examples:
#   ./configure-shell.sh --mode symlink --target ~/.dotfiles/homedir
#   ./configure-shell.sh --mode copy --shell zsh --backup
#   ./configure-shell.sh --mode standalone --force
#   SHELL_CONFIG_MODE=copy ./configure-shell.sh

set -e

# =====================================================
# CONFIGURATION
# =====================================================

# Script configuration
SCRIPT_NAME="configure-shell.sh"
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default configuration (can be overridden by environment variables)
DEFAULT_MODE="${SHELL_CONFIG_MODE:-standalone}"
DEFAULT_SHELL="${SHELL_CONFIG_SHELL:-both}"
DEFAULT_TARGET="${SHELL_CONFIG_TARGET:-}"
DEFAULT_BACKUP="${SHELL_CONFIG_BACKUP:-true}"
DEFAULT_FORCE="${SHELL_CONFIG_FORCE:-false}"

# Your personal defaults (can be overridden by environment variables)
PERSONAL_MODE="${SHELL_CONFIG_PERSONAL_MODE:-symlink}"
PERSONAL_TARGET="${SHELL_CONFIG_PERSONAL_TARGET:-$HOME/.dotfiles/homedir}"
PERSONAL_SHELL="${SHELL_CONFIG_PERSONAL_SHELL:-both}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =====================================================
# FUNCTIONS
# =====================================================

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo -e "${PURPLE}$1${NC}"
}

# Show help message
show_help() {
    cat << EOF
${PURPLE}Shell Configuration Script v${SCRIPT_VERSION}${NC}
===============================================

${CYAN}DESCRIPTION${NC}
This script provides flexible configuration options for setting up
zshrc and bashrc files. It can create symlinks, copy files, or
set up standalone configurations based on user preferences.

${CYAN}USAGE${NC}
    ./${SCRIPT_NAME} [options]

${CYAN}OPTIONS${NC}
    --mode <mode>           Setup mode: symlink, copy, standalone
    --target <path>         Target path for symlinks (default: auto-detect)
    --shell <shell>         Shell to configure: zsh, bash, both (default: both)
    --backup                Create backup of existing files
    --force                 Overwrite existing files without confirmation
    --setup-env             Set up environment variables for future use
    --personal              Use personal defaults (symlink to ~/.dotfiles/homedir)
    --help                  Show this help message

${CYAN}ENVIRONMENT VARIABLES${NC}
    SHELL_CONFIG_MODE       Default mode (symlink, copy, standalone)
    SHELL_CONFIG_TARGET     Default target path
    SHELL_CONFIG_BACKUP     Default backup behavior (true/false)

${CYAN}MODES${NC}
    ${GREEN}symlink${NC}     Create symlinks to target directory
    ${GREEN}copy${NC}        Copy files to home directory
    ${GREEN}standalone${NC}  Set up standalone configuration (default)

${CYAN}EXAMPLES${NC}
    # Create symlinks to dotfiles directory
    ./${SCRIPT_NAME} --mode symlink --target ~/.dotfiles/homedir

    # Copy zshrc only with backup
    ./${SCRIPT_NAME} --mode copy --shell zsh --backup

    # Standalone setup (force overwrite)
    ./${SCRIPT_NAME} --mode standalone --force

    # Use personal defaults (your symlink setup)
    ./${SCRIPT_NAME} --personal

    # Set up environment variables for future use
    ./${SCRIPT_NAME} --mode standalone --setup-env

    # Use environment variables
    SHELL_CONFIG_MODE=copy ./${SCRIPT_NAME}

${CYAN}FILE STRUCTURE${NC}
    Repository files:
    - zshrc                 (Zsh configuration)
    - bash-compatibility.zsh (Bash compatibility layer)
    
    Target locations:
    - ~/.zshrc              (Zsh configuration)
    - ~/.bashrc             (Bash configuration)

${CYAN}NOTES${NC}
    - The script automatically detects the best target path for symlinks
    - Backups are created with timestamp suffixes
    - Existing files are preserved unless --force is used
    - The bash-compatibility.zsh file is used for bash configuration

EOF
}

# Detect shell type
detect_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Auto-detect target path for symlinks
auto_detect_target() {
    local possible_paths=(
        "$HOME/.dotfiles/homedir"
        "$HOME/.config/shell"
        "$HOME/.shell-config"
        "$SCRIPT_DIR"
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -d "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    # If no existing directory found, return the first option as default
    echo "$HOME/.dotfiles/homedir"
    return 0
}

# Check if file exists and is not a symlink
file_exists() {
    local file="$1"
    [[ -f "$file" ]] && [[ ! -L "$file" ]]
}

# Check if file exists (including symlinks)
file_or_symlink_exists() {
    local file="$1"
    [[ -f "$file" ]] || [[ -L "$file" ]]
}

# Create backup of file
create_backup() {
    local file="$1"
    local backup_file="${file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    if cp "$file" "$backup_file"; then
        print_success "Created backup: $(basename "$backup_file")"
        return 0
    else
        print_error "Failed to create backup of $file"
        return 1
    fi
}

# Confirm action
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "$FORCE" == "true" ]]; then
        return 0
    fi
    
    local prompt="$message [y/N]: "
    if [[ "$default" == "y" ]]; then
        prompt="$message [Y/n]: "
    fi
    
    read -p "$prompt" -r
    if [[ "$default" == "y" ]]; then
        # Default is yes, so return 0 (proceed) unless user explicitly says no
        [[ $REPLY =~ ^[Nn]$ ]] && return 1
        return 0
    else
        # Default is no, so return 0 (proceed) only if user explicitly says yes
        [[ $REPLY =~ ^[Yy]$ ]] && return 0
        return 1
    fi
}

# Setup zshrc
setup_zshrc() {
    local mode="$1"
    local target_path="$2"
    
    print_info "Setting up zshrc in $mode mode..."
    
    local source_file="$SCRIPT_DIR/zshrc"
    local target_file="$HOME/.zshrc"
    
    # Check if source file exists
    if [[ ! -f "$source_file" ]]; then
        print_error "Source zshrc file not found: $source_file"
        return 1
    fi
    
    # Handle existing file
    if file_or_symlink_exists "$target_file"; then
        if [[ "$BACKUP" == "true" ]]; then
            if file_exists "$target_file"; then
                create_backup "$target_file"
            fi
        fi
        
        if ! confirm_action "Overwrite existing $target_file?"; then
            print_warning "Skipping zshrc setup"
            return 0
        fi
    fi
    
    # Remove existing file/symlink
    rm -f "$target_file"
    
    case "$mode" in
        "symlink")
            local symlink_target="$target_path/zshrc"
            if [[ ! -f "$symlink_target" ]]; then
                print_warning "Target file not found: $symlink_target"
                print_info "Copying source file to target location first..."
                cp "$source_file" "$symlink_target"
            fi
            ln -sf "$symlink_target" "$target_file"
            print_success "Created symlink: $target_file -> $symlink_target"
            ;;
        "copy")
            cp "$source_file" "$target_file"
            print_success "Copied zshrc to: $target_file"
            ;;
        "standalone")
            cp "$source_file" "$target_file"
            print_success "Set up standalone zshrc: $target_file"
            ;;
        *)
            print_error "Invalid mode: $mode"
            return 1
            ;;
    esac
    
    return 0
}

# Setup bashrc
setup_bashrc() {
    local mode="$1"
    local target_path="$2"
    
    print_info "Setting up bashrc in $mode mode..."
    
    local source_file="$SCRIPT_DIR/bash-compatibility.zsh"
    local target_file="$HOME/.bashrc"
    
    # Check if source file exists
    if [[ ! -f "$source_file" ]]; then
        print_error "Source bash-compatibility.zsh file not found: $source_file"
        return 1
    fi
    
    # Handle existing file
    if file_or_symlink_exists "$target_file"; then
        if [[ "$BACKUP" == "true" ]]; then
            if file_exists "$target_file"; then
                create_backup "$target_file"
            fi
        fi
        
        if ! confirm_action "Overwrite existing $target_file?"; then
            print_warning "Skipping bashrc setup"
            return 0
        fi
    fi
    
    # Remove existing file/symlink
    rm -f "$target_file"
    
    case "$mode" in
        "symlink")
            local symlink_target="$target_path/bash-compatibility.zsh"
            if [[ ! -f "$symlink_target" ]]; then
                print_warning "Target file not found: $symlink_target"
                print_info "Copying source file to target location first..."
                cp "$source_file" "$symlink_target"
            fi
            ln -sf "$symlink_target" "$target_file"
            print_success "Created symlink: $target_file -> $symlink_target"
            ;;
        "copy")
            cp "$source_file" "$target_file"
            print_success "Copied bash-compatibility.zsh to: $target_file"
            ;;
        "standalone")
            cp "$source_file" "$target_file"
            print_success "Set up standalone bashrc: $target_file"
            ;;
        *)
            print_error "Invalid mode: $mode"
            return 1
            ;;
    esac
    
    return 0
}

# Validate configuration
validate_config() {
    local errors=0
    
    # Check if we're in the right directory
    if [[ ! -f "$SCRIPT_DIR/zshrc" ]]; then
        print_error "zshrc file not found in script directory"
        ((errors++))
    fi
    
    if [[ ! -f "$SCRIPT_DIR/bash-compatibility.zsh" ]]; then
        print_error "bash-compatibility.zsh file not found in script directory"
        ((errors++))
    fi
    
    # Validate mode
    case "$MODE" in
        "symlink"|"copy"|"standalone")
            ;;
        *)
            print_error "Invalid mode: $MODE (must be: symlink, copy, standalone)"
            ((errors++))
            ;;
    esac
    
    # Validate shell
    case "$SHELL" in
        "zsh"|"bash"|"both")
            ;;
        *)
            print_error "Invalid shell: $SHELL (must be: zsh, bash, both)"
            ((errors++))
            ;;
    esac
    
    # Validate target path for symlink mode
    if [[ "$MODE" == "symlink" ]]; then
        if [[ ! -d "$TARGET_PATH" ]]; then
            print_warning "Target path does not exist: $TARGET_PATH"
            if confirm_action "Create target directory?" "y"; then
                mkdir -p "$TARGET_PATH"
                print_success "Created target directory: $TARGET_PATH"
            else
                print_error "Cannot proceed without target directory"
                ((errors++))
            fi
        fi
    fi
    
    return $errors
}

# Setup environment variables
setup_environment() {
    local config_file="$HOME/.shell-config-env"
    local shell_rc=""
    
    # Detect shell RC file
    if [[ -n "$ZSH_VERSION" ]]; then
        shell_rc="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        shell_rc="$HOME/.bashrc"
    else
        shell_rc="$HOME/.profile"
    fi
    
    print_info "Setting up environment variables..."
    echo ""
    
    # Create environment configuration
    cat > "$config_file" << EOF
# Shell Configuration Environment Variables
# Generated by configure-shell.sh on $(date)
# 
# These variables control the default behavior of configure-shell.sh
# You can override them by setting them in your shell before running the script

# Default configuration mode
export SHELL_CONFIG_MODE="$MODE"

# Default target path for symlinks
export SHELL_CONFIG_TARGET="$TARGET_PATH"

# Default shell to configure
export SHELL_CONFIG_SHELL="$SHELL"

# Default backup behavior
export SHELL_CONFIG_BACKUP="$BACKUP"

# Default force behavior
export SHELL_CONFIG_FORCE="$FORCE"

# Personal defaults (for your specific setup)
export SHELL_CONFIG_PERSONAL_MODE="symlink"
export SHELL_CONFIG_PERSONAL_TARGET="$HOME/.dotfiles/homedir"
export SHELL_CONFIG_PERSONAL_SHELL="both"
EOF

    print_success "Created environment configuration: $config_file"
    
    # Add source command to shell RC
    local source_line="source $config_file"
    if ! grep -q "$source_line" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Shell configuration environment variables" >> "$shell_rc"
        echo "$source_line" >> "$shell_rc"
        print_success "Added environment variables to: $shell_rc"
    else
        print_info "Environment variables already configured in: $shell_rc"
    fi
    
    echo ""
    print_info "Environment setup complete!"
    echo "You can now use:"
    echo "  ./configure-shell.sh  # Uses your configured defaults"
    echo "  ./configure-shell.sh --personal  # Uses personal symlink defaults"
    echo ""
    print_info "To reload environment variables:"
    echo "  source $shell_rc"
}

# Show configuration summary
show_summary() {
    print_header "Configuration Summary"
    echo "========================"
    echo "Mode: $MODE"
    echo "Shell: $SHELL"
    echo "Target Path: $TARGET_PATH"
    echo "Backup: $BACKUP"
    echo "Force: $FORCE"
    echo "Script Directory: $SCRIPT_DIR"
    echo ""
    
    # Show environment variable status
    if [[ -n "$SHELL_CONFIG_MODE" ]]; then
        echo "Environment Variables:"
        echo "  SHELL_CONFIG_MODE: $SHELL_CONFIG_MODE"
        echo "  SHELL_CONFIG_TARGET: ${SHELL_CONFIG_TARGET:-'(not set)'}"
        echo "  SHELL_CONFIG_SHELL: ${SHELL_CONFIG_SHELL:-'(not set)'}"
        echo "  SHELL_CONFIG_BACKUP: ${SHELL_CONFIG_BACKUP:-'(not set)'}"
        echo ""
    fi
}

# =====================================================
# MAIN SCRIPT
# =====================================================

# Parse command line arguments
MODE="${SHELL_CONFIG_MODE:-$DEFAULT_MODE}"
SHELL="${SHELL_CONFIG_SHELL:-$DEFAULT_SHELL}"
TARGET_PATH="${SHELL_CONFIG_TARGET:-}"
BACKUP="${SHELL_CONFIG_BACKUP:-$DEFAULT_BACKUP}"
FORCE="${SHELL_CONFIG_FORCE:-$DEFAULT_FORCE}"
SETUP_ENV="false"
USE_PERSONAL="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --mode)
            MODE="$2"
            shift 2
            ;;
        --target)
            TARGET_PATH="$2"
            shift 2
            ;;
        --shell)
            SHELL="$2"
            shift 2
            ;;
        --backup)
            BACKUP="true"
            shift
            ;;
        --force)
            FORCE="true"
            shift
            ;;
        --setup-env)
            SETUP_ENV="true"
            shift
            ;;
        --personal)
            USE_PERSONAL="true"
            MODE="$PERSONAL_MODE"
            TARGET_PATH="$PERSONAL_TARGET"
            SHELL="$PERSONAL_SHELL"
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Auto-detect target path if not specified
if [[ -z "$TARGET_PATH" ]]; then
    TARGET_PATH=$(auto_detect_target)
fi

# Show header
print_header "Shell Configuration Script v$SCRIPT_VERSION"
echo "==============================================="
echo ""

# Show current shell
CURRENT_SHELL=$(detect_shell)
print_info "Current shell: $CURRENT_SHELL"
echo ""

# Show configuration summary
show_summary

# Validate configuration
if ! validate_config; then
    print_error "Configuration validation failed"
    exit 1
fi

# Handle environment setup
if [[ "$SETUP_ENV" == "true" ]]; then
    setup_environment
    exit 0
fi

# Confirm action
if [[ "$FORCE" != "true" ]]; then
    if ! confirm_action "Proceed with shell configuration?" "y"; then
        print_info "Configuration cancelled by user"
        exit 0
    fi
fi

echo ""

# Setup shells
SUCCESS=true

if [[ "$SHELL" == "zsh" || "$SHELL" == "both" ]]; then
    if ! setup_zshrc "$MODE" "$TARGET_PATH"; then
        SUCCESS=false
    fi
fi

if [[ "$SHELL" == "bash" || "$SHELL" == "both" ]]; then
    if ! setup_bashrc "$MODE" "$TARGET_PATH"; then
        SUCCESS=false
    fi
fi

echo ""

# Show results
if [[ "$SUCCESS" == "true" ]]; then
    print_success "Shell configuration completed successfully!"
    echo ""
    print_info "Next steps:"
    echo "  1. Reload your shell: source ~/.zshrc (or ~/.bashrc)"
    echo "  2. Test the configuration: zsh_help (or bash equivalent)"
    echo "  3. Check sync status: zshrc-status (if available)"
    echo ""
    
    if [[ "$MODE" == "symlink" ]]; then
        print_info "Symlink mode notes:"
        echo "  - Configuration files are symlinked to: $TARGET_PATH"
        echo "  - Changes to source files will be reflected immediately"
        echo "  - Use sync functions to update repository files"
    elif [[ "$MODE" == "copy" ]]; then
        print_info "Copy mode notes:"
        echo "  - Configuration files are copied to your home directory"
        echo "  - Changes are local to your system"
        echo "  - Use sync functions to update repository files"
    else
        print_info "Standalone mode notes:"
        echo "  - Configuration files are independent"
        echo "  - No symlinks or dependencies on other locations"
        echo "  - Use sync functions to update repository files"
    fi
else
    print_error "Shell configuration completed with errors"
    exit 1
fi
