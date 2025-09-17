#!/usr/bin/env zsh
# =====================================================
# ENVIRONMENT MODULE - Platform detection and configuration
# =====================================================
#
# Purpose: Cross-platform environment detection and configuration
# Provides: Platform detection, package manager detection, environment setup
# Dependencies: centralized variables, system module (for path_add)
# =====================================================

echo "🌍 Loading Environment module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# PLATFORM DETECTION
# =====================================================

# Purpose: Detect current platform and set environment variables
# Arguments: None
# Returns: 0 always, sets ZSH_PLATFORM, ZSH_DISTRO, ZSH_IS_DOCKER, ZSH_IS_WSL
# Usage: detect_platform
detect_platform() {
    local platform=""
    local distro=""
    local is_docker="false"
    local is_wsl="false"
    local architecture=""

    # Detect base platform
    case "$(uname -s)" in
        Darwin)
            platform="macos"
            architecture="$(uname -m)"
            ;;
        Linux)
            platform="linux"
            architecture="$(uname -m)"

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
            elif [[ -f /etc/redhat-release ]]; then
                distro="rhel"
            elif [[ -f /etc/debian_version ]]; then
                distro="debian"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            platform="windows"
            architecture="$(uname -m)"
            ;;
        *)
            platform="unknown"
            architecture="$(uname -m 2>/dev/null || echo "unknown")"
            ;;
    esac

    # Export platform information
    export ZSH_PLATFORM="$platform"
    export ZSH_DISTRO="$distro"
    export ZSH_ARCHITECTURE="$architecture"
    export ZSH_IS_DOCKER="$is_docker"
    export ZSH_IS_WSL="$is_wsl"

    # Set convenience flags
    export IS_MACOS="$([[ "$platform" == "macos" ]] && echo "true" || echo "false")"
    export IS_LINUX="$([[ "$platform" == "linux" ]] && echo "true" || echo "false")"
    export IS_WINDOWS="$([[ "$platform" == "windows" ]] && echo "true" || echo "false")"
    export IS_DOCKER="$is_docker"
    export IS_WSL="$is_wsl"

    # Set macOS specific architecture flags
    if [[ "$platform" == "macos" ]]; then
        export IS_ARM64="$([[ "$architecture" == "arm64" ]] && echo "true" || echo "false")"
        export IS_X86_64="$([[ "$architecture" == "x86_64" ]] && echo "true" || echo "false")"
    fi
}

# =====================================================
# PACKAGE MANAGER DETECTION
# =====================================================

# Purpose: Detect available package managers on the system
# Arguments: None
# Returns: 0 always, sets ZSH_PACKAGE_MANAGERS array
# Usage: detect_package_managers
detect_package_managers() {
    local package_managers=()

    # macOS package managers
    command -v brew >/dev/null 2>&1 && package_managers+=("brew")
    command -v port >/dev/null 2>&1 && package_managers+=("macports")

    # Linux package managers
    command -v apt >/dev/null 2>&1 && package_managers+=("apt")
    command -v yum >/dev/null 2>&1 && package_managers+=("yum")
    command -v dnf >/dev/null 2>&1 && package_managers+=("dnf")
    command -v zypper >/dev/null 2>&1 && package_managers+=("zypper")
    command -v pacman >/dev/null 2>&1 && package_managers+=("pacman")
    command -v apk >/dev/null 2>&1 && package_managers+=("apk")

    # Universal package managers
    command -v snap >/dev/null 2>&1 && package_managers+=("snap")
    command -v flatpak >/dev/null 2>&1 && package_managers+=("flatpak")
    command -v nix >/dev/null 2>&1 && package_managers+=("nix")

    # Development package managers
    command -v npm >/dev/null 2>&1 && package_managers+=("npm")
    command -v pip >/dev/null 2>&1 && package_managers+=("pip")
    command -v cargo >/dev/null 2>&1 && package_managers+=("cargo")
    command -v gem >/dev/null 2>&1 && package_managers+=("gem")

    export ZSH_PACKAGE_MANAGERS=("${package_managers[@]}")
}

# =====================================================
# ENVIRONMENT SETUP
# =====================================================

# Purpose: Configure platform-specific environment settings
# Arguments: None
# Returns: 0 on success, 1 if platform setup fails
# Usage: setup_platform_environment
setup_platform_environment() {
    case "$ZSH_PLATFORM" in
        "macos")
            # macOS-specific environment setup
            export HOMEBREW_PREFIX="/opt/homebrew"
            [[ ! -d "$HOMEBREW_PREFIX" ]] && export HOMEBREW_PREFIX="/usr/local"

            # Configure Homebrew environment
            if [[ -d "$HOMEBREW_PREFIX" ]]; then
                export HOMEBREW_REPOSITORY="$HOMEBREW_PREFIX"
                export HOMEBREW_CELLAR="$HOMEBREW_PREFIX/Cellar"
                export MANPATH="$HOMEBREW_PREFIX/share/man${MANPATH+:$MANPATH}:"
                export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
            fi

            # Java environment (macOS)
            if [[ -x /usr/libexec/java_home ]]; then
                local java_home="$(/usr/libexec/java_home -v 11 2>/dev/null || /usr/libexec/java_home 2>/dev/null)"
                [[ -n "$java_home" ]] && export JAVA_HOME="$java_home"
            fi

            # macOS specific settings
            if [[ -z "$DISABLE_AUTO_TITLE" ]]; then
                export DISABLE_AUTO_TITLE="true"
            fi
            ;;

        "linux")
            # Linux-specific environment setup

            # Docker-specific adjustments
            if [[ "$ZSH_IS_DOCKER" == "true" ]]; then
                export DOCKER_CONTAINER="true"

                # Set minimal environment for containers
                export TERM="${TERM:-xterm-256color}"
                export LANG="${LANG:-C.UTF-8}"
                export LC_ALL="${LC_ALL:-C.UTF-8}"
            fi

            # WSL-specific adjustments
            if [[ "$ZSH_IS_WSL" == "true" ]]; then
                export WSL_ENABLED="true"

                # WSL display setup for GUI applications
                if [[ -z "$DISPLAY" ]]; then
                    export DISPLAY="$(grep nameserver /etc/resolv.conf | awk '{print $2}'):0"
                fi
            fi

            # Java environment (Linux)
            if [[ -z "$JAVA_HOME" ]]; then
                for java_dir in /usr/lib/jvm/default-java /usr/lib/jvm/java-11-openjdk* /usr/lib/jvm/java-8-openjdk*; do
                    if [[ -d "$java_dir" ]]; then
                        export JAVA_HOME="$java_dir"
                        break
                    fi
                done
            fi
            ;;

        "windows")
            # Windows/MSYS/Cygwin specific setup
            export WINDOWS_ENV="true"
            export TERM="${TERM:-xterm-256color}"
            ;;

        *)
            echo "⚠️  Unknown platform: $ZSH_PLATFORM"
            return 1
            ;;
    esac

    return 0
}

# =====================================================
# SYSTEM INFORMATION
# =====================================================

# Purpose: Display comprehensive environment information
# Arguments: None
# Returns: 0 always
# Usage: environment_status
environment_status() {
    echo "🌍 Environment Status"
    echo "===================="
    echo "🖥️  Platform: ${ZSH_PLATFORM:-Unknown}"
    echo "🏗️  Architecture: ${ZSH_ARCHITECTURE:-Unknown}"

    if [[ -n "$ZSH_DISTRO" ]]; then
        echo "🐧 Distribution: $ZSH_DISTRO"
    fi

    echo ""
    echo "🏷️  Environment Flags:"
    echo "  macOS: ${IS_MACOS:-false}"
    echo "  Linux: ${IS_LINUX:-false}"
    echo "  Windows: ${IS_WINDOWS:-false}"
    echo "  Docker: ${IS_DOCKER:-false}"
    echo "  WSL: ${IS_WSL:-false}"

    if [[ "$IS_MACOS" == "true" ]]; then
        echo "  ARM64: ${IS_ARM64:-false}"
        echo "  x86_64: ${IS_X86_64:-false}"
    fi

    echo ""
    echo "📦 Package Managers:"
    if [[ ${#ZSH_PACKAGE_MANAGERS[@]} -gt 0 ]]; then
        for pm in "${ZSH_PACKAGE_MANAGERS[@]}"; do
            echo "  ✅ $pm"
        done
    else
        echo "  ❌ No package managers detected"
    fi

    echo ""
    echo "🔧 Environment Variables:"
    echo "  JAVA_HOME: ${JAVA_HOME:-Not set}"
    echo "  HOMEBREW_PREFIX: ${HOMEBREW_PREFIX:-Not set}"
    echo "  DISPLAY: ${DISPLAY:-Not set}"
    echo "  LANG: ${LANG:-Not set}"
    echo "  TERM: ${TERM:-Not set}"
}

# =====================================================
# COMPATIBILITY FUNCTIONS
# =====================================================

# Purpose: Get the preferred package manager for the current platform
# Arguments: None
# Returns: Prints package manager name, returns 0 if found, 1 if none
# Usage: pm=$(get_package_manager)
get_package_manager() {
    case "$ZSH_PLATFORM" in
        "macos")
            if command -v brew >/dev/null 2>&1; then
                echo "brew"
                return 0
            elif command -v port >/dev/null 2>&1; then
                echo "macports"
                return 0
            fi
            ;;
        "linux")
            case "$ZSH_DISTRO" in
                "ubuntu"|"debian")
                    if command -v apt >/dev/null 2>&1; then
                        echo "apt"
                        return 0
                    fi
                    ;;
                "fedora"|"rhel"|"centos")
                    if command -v dnf >/dev/null 2>&1; then
                        echo "dnf"
                        return 0
                    elif command -v yum >/dev/null 2>&1; then
                        echo "yum"
                        return 0
                    fi
                    ;;
                "arch"|"manjaro")
                    if command -v pacman >/dev/null 2>&1; then
                        echo "pacman"
                        return 0
                    fi
                    ;;
                "alpine")
                    if command -v apk >/dev/null 2>&1; then
                        echo "apk"
                        return 0
                    fi
                    ;;
            esac
            ;;
    esac

    echo "none"
    return 1
}

# Purpose: Check if a command exists and provide installation suggestions
# Arguments: $1 - command name to check
# Returns: 0 if command exists, 1 if not found
# Usage: check_command_with_install git
check_command_with_install() {
    local cmd="$1"

    if command -v "$cmd" >/dev/null 2>&1; then
        echo "✅ $cmd is available"
        return 0
    else
        echo "❌ $cmd not found"

        local pm=$(get_package_manager)
        if [[ "$pm" != "none" ]]; then
            case "$pm" in
                "brew")      echo "💡 Install with: brew install $cmd" ;;
                "apt")       echo "💡 Install with: sudo apt install $cmd" ;;
                "dnf")       echo "💡 Install with: sudo dnf install $cmd" ;;
                "yum")       echo "💡 Install with: sudo yum install $cmd" ;;
                "pacman")    echo "💡 Install with: sudo pacman -S $cmd" ;;
                "apk")       echo "💡 Install with: sudo apk add $cmd" ;;
                "macports")  echo "💡 Install with: sudo port install $cmd" ;;
                *)           echo "💡 Install using your package manager" ;;
            esac
        fi
        return 1
    fi
}

# =====================================================
# INITIALIZATION
# =====================================================

# Purpose: Initialize environment detection and setup
# Arguments: None
# Returns: 0 on success
# Usage: init_environment (called automatically)
init_environment() {
    detect_platform
    detect_package_managers
    setup_platform_environment
}

# =====================================================
# ALIASES
# =====================================================

alias envinfo='environment_status'
alias platform='echo $ZSH_PLATFORM'
alias distro='echo $ZSH_DISTRO'

# Automatically initialize environment on module load
init_environment

echo "✅ Environment module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export ENVIRONMENT_MODULE_LOADED=true