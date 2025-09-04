#!/usr/bin/env zsh

# =====================================================
# ENVIRONMENT & PLATFORM DETECTION MODULE
# =====================================================
# 
# Cross-platform environment detection and configuration
# Handles differences between macOS, Linux, and Docker environments
# Provides unified interface for platform-specific operations
# =====================================================

# Module identification
export ENVIRONMENT_MODULE_LOADED="true"

# =====================================================
# PLATFORM DETECTION
# =====================================================

detect_platform() {
    # Detect the current platform and set environment variables
    local platform=""
    local distro=""
    local is_docker="false"
    local is_wsl="false"
    
    # Detect base platform
    case "$(uname -s)" in
        Darwin)
            platform="macos"
            ;;
        Linux)
            platform="linux"
            
            # Check if running in Docker
            if [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
                is_docker="true"
            fi
            
            # Check if running in WSL
            if [[ -n "${WSL_DISTRO_NAME}" ]] || grep -q Microsoft /proc/version 2>/dev/null; then
                is_wsl="true"
            fi
            
            # Detect Linux distribution
            if [[ -f /etc/os-release ]]; then
                distro=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
            elif command -v lsb_release >/dev/null 2>&1; then
                distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
            fi
            ;;
        *)
            platform="unknown"
            ;;
    esac
    
    # Export platform information
    export ZSH_PLATFORM="$platform"
    export ZSH_DISTRO="$distro"
    export ZSH_IS_DOCKER="$is_docker"
    export ZSH_IS_WSL="$is_wsl"
    
    # Set convenience flags
    export IS_MACOS="$([[ "$platform" == "macos" ]] && echo "true" || echo "false")"
    export IS_LINUX="$([[ "$platform" == "linux" ]] && echo "true" || echo "false")"
    export IS_DOCKER="$is_docker"
    export IS_WSL="$is_wsl"
}

# =====================================================
# PACKAGE MANAGER DETECTION
# =====================================================

detect_package_managers() {
    # Detect available package managers
    local package_managers=()
    
    # macOS package managers
    command -v brew >/dev/null 2>&1 && package_managers+="brew"
    command -v port >/dev/null 2>&1 && package_managers+="macports"
    
    # Linux package managers
    command -v apt >/dev/null 2>&1 && package_managers+="apt"
    command -v yum >/dev/null 2>&1 && package_managers+="yum"
    command -v dnf >/dev/null 2>&1 && package_managers+="dnf"
    command -v zypper >/dev/null 2>&1 && package_managers+="zypper"
    command -v pacman >/dev/null 2>&1 && package_managers+="pacman"
    command -v apk >/dev/null 2>&1 && package_managers+="apk"
    
    # Universal package managers
    command -v snap >/dev/null 2>&1 && package_managers+="snap"
    command -v flatpak >/dev/null 2>&1 && package_managers+="flatpak"
    
    export ZSH_PACKAGE_MANAGERS=("${package_managers[@]}")
}

# =====================================================
# PLATFORM-SPECIFIC PATHS
# =====================================================

setup_platform_paths() {
    # Configure platform-specific paths
    case "$ZSH_PLATFORM" in
        "macos")
            # macOS-specific paths
            export HOMEBREW_PREFIX="/opt/homebrew"
            [[ ! -d "$HOMEBREW_PREFIX" ]] && export HOMEBREW_PREFIX="/usr/local"
            
            # Add Homebrew paths if available
            if [[ -d "$HOMEBREW_PREFIX/bin" ]]; then
                path_add "$HOMEBREW_PREFIX/bin"
                path_add "$HOMEBREW_PREFIX/sbin"
            fi
            
            # Java paths (macOS)
            if [[ -x /usr/libexec/java_home ]]; then
                export JAVA_HOME="$(/usr/libexec/java_home -v 11 2>/dev/null || /usr/libexec/java_home 2>/dev/null)"
            fi
            ;;
            
        "linux")
            # Linux-specific paths
            path_add "/usr/local/bin"
            path_add "/usr/local/sbin"
            
            # Docker-specific adjustments
            if [[ "$ZSH_IS_DOCKER" == "true" ]]; then
                # Docker containers often have minimal PATH
                path_add "/bin"
                path_add "/usr/bin"
                path_add "/sbin"
                path_add "/usr/sbin"
            fi
            
            # Java paths (Linux)
            if [[ -z "$JAVA_HOME" ]]; then
                # Try common Linux Java locations
                for java_dir in /usr/lib/jvm/default-java /usr/lib/jvm/java-11-openjdk* /usr/lib/jvm/java-8-openjdk*; do
                    if [[ -d "$java_dir" ]]; then
                        export JAVA_HOME="$java_dir"
                        break
                    fi
                done
            fi
            ;;
    esac
    
    # Universal paths (work on both platforms)
    path_add "$HOME/.local/bin"
    path_add "$HOME/bin"
}

# =====================================================
# CROSS-PLATFORM UTILITIES
# =====================================================

# Universal file operations
platform_open() {
    # Open file/directory with default application
    local target="${1:-.}"
    
    case "$ZSH_PLATFORM" in
        "macos")
            open "$target"
            ;;
        "linux")
            if [[ "$ZSH_IS_WSL" == "true" ]]; then
                # WSL - use Windows explorer
                explorer.exe "$(wslpath -w "$target")" 2>/dev/null || xdg-open "$target" 2>/dev/null
            elif command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$target" 2>/dev/null
            else
                echo "No file opener available for: $target"
                return 1
            fi
            ;;
        *)
            echo "Unsupported platform: $ZSH_PLATFORM"
            return 1
            ;;
    esac
}

# Universal clipboard operations
platform_copy() {
    # Copy to system clipboard
    case "$ZSH_PLATFORM" in
        "macos")
            pbcopy
            ;;
        "linux")
            if [[ "$ZSH_IS_WSL" == "true" ]]; then
                clip.exe
            elif command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard
            elif command -v xsel >/dev/null 2>&1; then
                xsel --clipboard --input
            else
                echo "No clipboard utility available" >&2
                return 1
            fi
            ;;
        *)
            echo "Unsupported platform: $ZSH_PLATFORM" >&2
            return 1
            ;;
    esac
}

platform_paste() {
    # Paste from system clipboard
    case "$ZSH_PLATFORM" in
        "macos")
            pbpaste
            ;;
        "linux")
            if [[ "$ZSH_IS_WSL" == "true" ]]; then
                powershell.exe -command "Get-Clipboard" 2>/dev/null
            elif command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard -o
            elif command -v xsel >/dev/null 2>&1; then
                xsel --clipboard --output
            else
                echo "No clipboard utility available" >&2
                return 1
            fi
            ;;
        *)
            echo "Unsupported platform: $ZSH_PLATFORM" >&2
            return 1
            ;;
    esac
}

# Universal browser opening
platform_browser() {
    # Open URL in default browser
    local url="$1"
    
    if [[ -z "$url" ]]; then
        echo "Usage: platform_browser <url>"
        return 1
    fi
    
    case "$ZSH_PLATFORM" in
        "macos")
            open "$url"
            ;;
        "linux")
            if [[ "$ZSH_IS_WSL" == "true" ]]; then
                # WSL - use Windows default browser
                cmd.exe /c start "$url" 2>/dev/null || xdg-open "$url" 2>/dev/null
            elif command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$url" 2>/dev/null
            else
                echo "No browser opener available for: $url"
                return 1
            fi
            ;;
        *)
            echo "Unsupported platform: $ZSH_PLATFORM"
            return 1
            ;;
    esac
}

# =====================================================
# ENVIRONMENT INFORMATION
# =====================================================

environment_info() {
    # Display comprehensive environment information
    echo "🌍 Environment & Platform Information"
    echo "=================================="
    echo ""
    
    echo "Platform Details:"
    echo "  OS: $ZSH_PLATFORM"
    [[ -n "$ZSH_DISTRO" ]] && echo "  Distribution: $ZSH_DISTRO"
    echo "  Architecture: $(uname -m)"
    echo "  Kernel: $(uname -r)"
    [[ "$ZSH_IS_DOCKER" == "true" ]] && echo "  Environment: Docker Container"
    [[ "$ZSH_IS_WSL" == "true" ]] && echo "  Environment: Windows Subsystem for Linux"
    echo ""
    
    echo "Shell Information:"
    echo "  Shell: $SHELL"
    echo "  ZSH Version: $ZSH_VERSION"
    echo "  Home: $HOME"
    echo "  User: $USER"
    echo ""
    
    if [[ "${#ZSH_PACKAGE_MANAGERS[@]}" -gt 0 ]]; then
        echo "Package Managers:"
        for pm in "${ZSH_PACKAGE_MANAGERS[@]}"; do
            echo "  ✅ $pm"
        done
        echo ""
    fi
    
    echo "Key Paths:"
    echo "  Config: $ZSH_CONFIG_DIR"
    echo "  Modules: $ZSH_CONFIG_MODULES"
    [[ -n "$JAVA_HOME" ]] && echo "  Java: $JAVA_HOME"
    [[ -n "$HOMEBREW_PREFIX" ]] && echo "  Homebrew: $HOMEBREW_PREFIX"
    echo ""
    
    echo "Runtime Features:"
    echo "  Docker: $([[ "$ZSH_IS_DOCKER" == "true" ]] && echo "✅ Yes" || echo "❌ No")"
    echo "  WSL: $([[ "$ZSH_IS_WSL" == "true" ]] && echo "✅ Yes" || echo "❌ No")"
    command -v git >/dev/null 2>&1 && echo "  Git: ✅ $(git --version | cut -d' ' -f3)"
    command -v python3 >/dev/null 2>&1 && echo "  Python: ✅ $(python3 --version | cut -d' ' -f2)"
    command -v node >/dev/null 2>&1 && echo "  Node.js: ✅ $(node --version)"
    command -v java >/dev/null 2>&1 && echo "  Java: ✅ $(java -version 2>&1 | head -n1 | cut -d'"' -f2)"
}

# =====================================================
# CONTAINER & DOCKER UTILITIES
# =====================================================

is_container() {
    # Check if running in any type of container
    [[ "$ZSH_IS_DOCKER" == "true" ]] || [[ -f /.dockerenv ]] || grep -q container /proc/1/cgroup 2>/dev/null
}

container_info() {
    # Display container-specific information
    if is_container; then
        echo "📦 Container Environment Detected"
        echo "==============================="
        
        if [[ -f /.dockerenv ]]; then
            echo "Type: Docker Container"
        fi
        
        # Show container ID if available
        local container_id=""
        if [[ -f /proc/self/cgroup ]]; then
            container_id=$(grep docker /proc/self/cgroup | head -n1 | sed 's/.*\/docker\///' | cut -c1-12 2>/dev/null)
            [[ -n "$container_id" ]] && echo "Container ID: $container_id"
        fi
        
        echo ""
    else
        echo "Not running in a container"
    fi
}

# =====================================================
# ALIASES FOR PLATFORM UTILITIES
# =====================================================

# Universal aliases that work across platforms
alias open-here='platform_open .'
alias copy='platform_copy'
alias paste='platform_paste'
alias browse='platform_browser'
alias env-info='environment_info'
alias platform-info='environment_info'
alias container-info='container_info'

# Platform-specific aliases
if [[ "$ZSH_PLATFORM" == "linux" ]]; then
    alias ls='ls --color=auto'
    alias ll='ls -alF --color=auto'
    alias la='ls -A --color=auto'
    alias l='ls -CF --color=auto'
elif [[ "$ZSH_PLATFORM" == "macos" ]]; then
    alias ls='ls -G'
    alias ll='ls -alFG'
    alias la='ls -AG'
    alias l='ls -CFG'
fi

# =====================================================
# INITIALIZATION
# =====================================================

# Run platform detection
detect_platform
detect_package_managers
setup_platform_paths

# Show platform info if verbose
if [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]]; then
    echo "🌍 Platform: $ZSH_PLATFORM $([[ -n "$ZSH_DISTRO" ]] && echo "($ZSH_DISTRO)") $([[ "$ZSH_IS_DOCKER" == "true" ]] && echo "[Docker]") $([[ "$ZSH_IS_WSL" == "true" ]] && echo "[WSL]")"
fi