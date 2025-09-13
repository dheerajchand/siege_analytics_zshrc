#!/usr/bin/env zsh
# =====================================================
# CROSS-SHELL COMPATIBILITY CORE
# Core shell and platform detection for zsh/bash compatibility
# =====================================================

# Shell detection
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# Set shell-specific variables
export CURRENT_SHELL=$(detect_shell)
export IS_ZSH=$([ "$CURRENT_SHELL" = "zsh" ] && echo "true" || echo "false")
export IS_BASH=$([ "$CURRENT_SHELL" = "bash" ] && echo "true" || echo "false")

# Platform detection
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

export PLATFORM=$(detect_platform)

# Linux distribution detection
if [[ "$PLATFORM" == "linux" && -f /etc/os-release ]]; then
    . /etc/os-release
    export LINUX_DISTRO="$ID"
    export LINUX_VERSION="$VERSION_ID"

    case "$LINUX_DISTRO" in
        "ubuntu"|"debian")
            export PACKAGE_MANAGER="apt"
            ;;
        "rhel"|"centos"|"rocky"|"almalinux")
            export PACKAGE_MANAGER="dnf"
            ;;
    esac
fi

# Container detection
detect_container() {
    if [ -f /.dockerenv ] || [ -n "$DOCKER_CONTAINER" ]; then
        echo "docker"
        return 0
    elif [ -n "$KUBERNETES_SERVICE_HOST" ]; then
        echo "kubernetes"
        return 0
    elif [ -n "$WSL_DISTRO_NAME" ] || [ -n "$WSL_INTEROP" ]; then
        echo "wsl"
        return 0
    else
        echo "none"
        return 1
    fi
}

export CONTAINER_TYPE=$(detect_container)
export IN_CONTAINER=$([ "$CONTAINER_TYPE" != "none" ] && echo "true" || echo "false")

# Shell-specific compatibility functions
setup_shell_options() {
    if [ "$IS_ZSH" = "true" ]; then
        # ZSH-specific options
        setopt EXTENDED_GLOB
        setopt NO_CASE_GLOB
        setopt NULL_GLOB
        setopt NUMERIC_GLOB_SORT
    elif [ "$IS_BASH" = "true" ]; then
        # Bash-specific options
        shopt -s extglob
        shopt -s nocaseglob
        shopt -s nullglob
    fi
}

# PATH management
deduplicate_path() {
    # Remove duplicate entries from PATH
    if [ -n "$PATH" ]; then
        local new_path=""
        local IFS=":"

        for dir in $PATH; do
            if [[ ":$new_path:" != *":$dir:"* ]] && [[ -d "$dir" ]]; then
                if [ -z "$new_path" ]; then
                    new_path="$dir"
                else
                    new_path="$new_path:$dir"
                fi
            fi
        done

        export PATH="$new_path"
    fi
}

# Cross-shell command existence check
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Cross-shell array handling
join_array() {
    local delimiter="$1"
    shift
    local first="$1"
    shift
    printf '%s' "$first" "${@/#/$delimiter}"
}

# Cross-shell initialization
init_cross_shell() {
    setup_shell_options
    deduplicate_path

    # Set common aliases that work in both shells
    alias ll='ls -la'
    alias la='ls -A'
    alias l='ls -CF'

    echo "Cross-shell compatibility initialized for $CURRENT_SHELL on $PLATFORM"
}

# Auto-initialize if not already done
if [[ -z "$CROSS_SHELL_INITIALIZED" ]]; then
    init_cross_shell
    export CROSS_SHELL_INITIALIZED="true"
fi