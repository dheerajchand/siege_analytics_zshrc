#!/usr/bin/env bash
# This file is compatible with both bash and zsh

# =====================================================
# SHELL COMPATIBILITY LAYER
# =====================================================
#
# Provides cross-shell compatibility functions for bash and zsh
# Ensures all functions work consistently across different shells
# Also handles platform differences (macOS vs Linux)
# =====================================================

export SHELL_COMPAT_MODULE_LOADED="true"
export SHELL_COMPAT_MODULE_VERSION="1.0.0"

# =====================================================
# SHELL DETECTION
# =====================================================

# Detect current shell
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        echo "zsh"
    elif [ -n "$BASH_VERSION" ]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

export CURRENT_SHELL=$(detect_shell)

# =====================================================
# ARRAY HANDLING COMPATIBILITY
# =====================================================

# Cross-shell array expansion
# Usage: array_expand array_name
array_expand() {
    local array_name="$1"
    
    case "$CURRENT_SHELL" in
        "zsh")
            # ZSH: Use parameter expansion with word splitting
            eval "echo \${${array_name}[*]}"
            ;;
        "bash")
            # Bash: Use array expansion
            eval "echo \${${array_name}[@]}"
            ;;
        *)
            # Fallback: treat as single variable
            eval "echo \$$array_name"
            ;;
    esac
}

# Cross-shell associative array support
# Usage: assoc_array_set ARRAY_NAME key value
assoc_array_set() {
    local array_name="$1"
    local key="$2"
    local value="$3"
    
    case "$CURRENT_SHELL" in
        "zsh")
            # ZSH: Use typeset -A
            eval "typeset -gA $array_name 2>/dev/null || true"
            eval "${array_name}[${key}]='${value}'"
            ;;
        "bash")
            # Bash: Use declare -A
            eval "declare -gA $array_name 2>/dev/null || true"
            eval "${array_name}[${key}]='${value}'"
            ;;
        *)
            # Fallback: Use simple variables
            eval "${array_name}_${key}='${value}'"
            ;;
    esac
}

# Cross-shell associative array get
# Usage: assoc_array_get ARRAY_NAME key
assoc_array_get() {
    local array_name="$1"
    local key="$2"
    
    case "$CURRENT_SHELL" in
        "zsh"|"bash")
            eval "echo \${${array_name}[${key}]}"
            ;;
        *)
            # Fallback: simple variables
            eval "echo \${${array_name}_${key}}"
            ;;
    esac
}

# =====================================================
# HOOK SYSTEM COMPATIBILITY
# =====================================================

# Cross-shell directory change hooks
# Usage: add_chdir_hook function_name
add_chdir_hook() {
    local function_name="$1"
    
    case "$CURRENT_SHELL" in
        "zsh")
            # ZSH: Use add-zsh-hook
            if command -v add-zsh-hook >/dev/null 2>&1; then
                autoload -U add-zsh-hook
                add-zsh-hook chpwd "$function_name"
            fi
            ;;
        "bash")
            # Bash: Override cd function
            if ! declare -f cd_original >/dev/null 2>&1; then
                eval "cd_original() { builtin cd \"\$@\"; }"
            fi
            eval "cd() {
                cd_original \"\$@\"
                $function_name
            }"
            ;;
    esac
}

# =====================================================
# PLATFORM DETECTION
# =====================================================

# Enhanced platform detection
detect_platform() {
    local platform="unknown"
    
    # Check for macOS
    if [[ "$(uname -s)" == "Darwin" ]]; then
        platform="macos"
    # Check for Linux
    elif [[ "$(uname -s)" == "Linux" ]]; then
        # Check for specific Linux distributions
        if [[ -f "/etc/os-release" ]]; then
            . /etc/os-release
            case "$ID" in
                "ubuntu"|"debian")
                    platform="linux-debian"
                    ;;
                "centos"|"rhel"|"fedora")
                    platform="linux-redhat"
                    ;;
                "alpine")
                    platform="linux-alpine"
                    ;;
                *)
                    platform="linux"
                    ;;
            esac
        else
            platform="linux"
        fi
    # Check for Windows Subsystem for Linux
    elif [[ -n "${WSL_DISTRO_NAME}" ]] || [[ -n "${WSLENV}" ]]; then
        platform="wsl"
    # Check for Docker container
    elif [[ -f "/.dockerenv" ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        platform="docker"
    fi
    
    echo "$platform"
}

export ZSH_PLATFORM=$(detect_platform)

# Container detection
is_container() {
    [[ -f "/.dockerenv" ]] || grep -q docker /proc/1/cgroup 2>/dev/null
}

export ZSH_IS_DOCKER=$(is_container && echo "true" || echo "false")

# =====================================================
# CROSS-PLATFORM PATH UTILITIES
# =====================================================

# Cross-platform path addition
# Usage: path_add /path/to/add [before|after]
path_add() {
    local new_path="$1"
    local position="${2:-after}"
    
    # Check if path exists and is not already in PATH
    if [[ -d "$new_path" ]] && [[ ":$PATH:" != *":$new_path:"* ]]; then
        case "$position" in
            "before")
                export PATH="$new_path:$PATH"
                ;;
            "after"|*)
                export PATH="$PATH:$new_path"
                ;;
        esac
    fi
}

# Cross-platform library path handling
# Usage: lib_path_add /path/to/lib
lib_path_add() {
    local new_lib_path="$1"
    
    if [[ -d "$new_lib_path" ]]; then
        case "$ZSH_PLATFORM" in
            "macos")
                # macOS uses DYLD_LIBRARY_PATH (but it's restricted)
                if [[ ":${DYLD_LIBRARY_PATH:-}:" != *":$new_lib_path:"* ]]; then
                    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:+$DYLD_LIBRARY_PATH:}$new_lib_path"
                fi
                ;;
            "linux"|"linux-"*|"wsl"|"docker")
                # Linux uses LD_LIBRARY_PATH
                if [[ ":${LD_LIBRARY_PATH:-}:" != *":$new_lib_path:"* ]]; then
                    export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$new_lib_path"
                fi
                ;;
        esac
    fi
}

# =====================================================
# CROSS-PLATFORM UTILITIES
# =====================================================

# Cross-platform file opening
platform_open() {
    local file_or_url="$1"
    
    case "$ZSH_PLATFORM" in
        "macos")
            open "$file_or_url"
            ;;
        "linux"|"linux-"*)
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$file_or_url"
            elif command -v gnome-open >/dev/null 2>&1; then
                gnome-open "$file_or_url"
            else
                echo "❌ No suitable open command found"
                return 1
            fi
            ;;
        "wsl")
            # Windows Subsystem for Linux
            cmd.exe /c start "$file_or_url"
            ;;
        *)
            echo "❌ Platform not supported: $ZSH_PLATFORM"
            return 1
            ;;
    esac
}

# Cross-platform clipboard operations
platform_copy() {
    case "$ZSH_PLATFORM" in
        "macos")
            pbcopy
            ;;
        "linux"|"linux-"*)
            if command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard
            elif command -v xsel >/dev/null 2>&1; then
                xsel --clipboard --input
            else
                echo "❌ No clipboard utility found. Install xclip or xsel."
                return 1
            fi
            ;;
        "wsl")
            clip.exe
            ;;
        *)
            echo "❌ Platform not supported: $ZSH_PLATFORM"
            return 1
            ;;
    esac
}

platform_paste() {
    case "$ZSH_PLATFORM" in
        "macos")
            pbpaste
            ;;
        "linux"|"linux-"*)
            if command -v xclip >/dev/null 2>&1; then
                xclip -selection clipboard -o
            elif command -v xsel >/dev/null 2>&1; then
                xsel --clipboard --output
            else
                echo "❌ No clipboard utility found. Install xclip or xsel."
                return 1
            fi
            ;;
        "wsl")
            powershell.exe Get-Clipboard
            ;;
        *)
            echo "❌ Platform not supported: $ZSH_PLATFORM"
            return 1
            ;;
    esac
}

# Cross-platform browser opening
platform_browser() {
    local url="$1"
    
    case "$ZSH_PLATFORM" in
        "macos")
            open "$url"
            ;;
        "linux"|"linux-"*)
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$url"
            elif command -v firefox >/dev/null 2>&1; then
                firefox "$url" &
            elif command -v chrome >/dev/null 2>&1; then
                chrome "$url" &
            else
                echo "❌ No suitable browser command found"
                return 1
            fi
            ;;
        "wsl")
            cmd.exe /c start "$url"
            ;;
        *)
            echo "❌ Platform not supported: $ZSH_PLATFORM"
            return 1
            ;;
    esac
}

# =====================================================
# WORD SPLITTING COMPATIBILITY
# =====================================================

# Cross-shell word splitting for arguments
# Usage: word_split "$variable"
word_split() {
    local input="$1"
    
    case "$CURRENT_SHELL" in
        "zsh")
            # ZSH: Use parameter expansion flag
            echo ${=input}
            ;;
        "bash")
            # Bash: Word splitting is default, just echo
            echo $input
            ;;
        *)
            # Fallback: basic expansion
            echo $input
            ;;
    esac
}

# =====================================================
# PACKAGE MANAGER DETECTION
# =====================================================

# Detect available package managers
detect_package_managers() {
    local managers=()
    
    # System package managers
    if command -v apt >/dev/null 2>&1; then
        managers+=("apt")
    fi
    if command -v yum >/dev/null 2>&1; then
        managers+=("yum")
    fi
    if command -v dnf >/dev/null 2>&1; then
        managers+=("dnf")
    fi
    if command -v pacman >/dev/null 2>&1; then
        managers+=("pacman")
    fi
    if command -v brew >/dev/null 2>&1; then
        managers+=("brew")
    fi
    
    # Development package managers
    if command -v npm >/dev/null 2>&1; then
        managers+=("npm")
    fi
    if command -v pip >/dev/null 2>&1; then
        managers+=("pip")
    fi
    if command -v uv >/dev/null 2>&1; then
        managers+=("uv")
    fi
    
    # Join array elements
    case "$CURRENT_SHELL" in
        "zsh")
            echo "${managers[*]}"
            ;;
        "bash")
            echo "${managers[@]}"
            ;;
        *)
            echo "$managers"
            ;;
    esac
}

export AVAILABLE_PACKAGE_MANAGERS=$(detect_package_managers)

# =====================================================
# INITIALIZATION
# =====================================================

# Show compatibility status if verbose
if [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]]; then
    echo "🔄 Shell Compat: $CURRENT_SHELL on $ZSH_PLATFORM v${SHELL_COMPAT_MODULE_VERSION}"
fi