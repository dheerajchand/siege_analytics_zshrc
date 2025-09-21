#!/usr/bin/env zsh

# =====================================================
# CORE UTILITIES - Essential Shell Functions
# =====================================================
#
# Essential shell utilities that should be loaded in all modes.
# These are the fundamental functions needed by other modules.
# =====================================================

is_online() {
    # Check if internet connection is available
    #
    # Returns:
    #     0: Online
    #     1: Offline
    #
    # Examples:
    #     if is_online; then echo "Connected"; fi
    #     [[ "$(is_online_status)" == "online" ]] && do_something
    ping -c 1 google.com &> /dev/null
}

is_online_status() {
    # Get online status as string
    #
    # Returns:
    #     str: "online" or "offline"
    if is_online; then
        echo "online"
    else
        echo "offline"
    fi
}

command_exists() {
    # Check if a command exists
    #
    # Args:
    #     command (str): Command to check
    #
    # Returns:
    #     0: Command exists
    #     1: Command not found
    #
    # Examples:
    #     command_exists git && echo "Git is available"
    #     if command_exists python3; then python3 --version; fi
    command -v "$1" >/dev/null 2>&1
}

mkcd() {
    # Create directory and cd into it
    #
    # Args:
    #     directory (str): Directory name to create
    #
    # Examples:
    #     mkcd new_project
    #     mkcd ~/projects/my_app
    mkdir -p "$1" && cd "$1"
}

extract() {
    # Universal extraction function
    #
    # Args:
    #     file (str): Archive file to extract
    #
    # Examples:
    #     extract archive.tar.gz
    #     extract package.zip
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "Don't know how to extract '$1'" ;;
        esac
    else
        echo "File '$1' not found"
    fi
}

findtext() {
    # Search for text in files recursively
    #
    # Args:
    #     text (str): Text to search for
    #     path (str, optional): Path to search in (default: current directory)
    #
    # Examples:
    #     findtext "TODO"
    #     findtext "function.*python" ~/projects
    local text="$1"
    local path="${2:-.}"

    if command_exists rg; then
        rg "$text" "$path"
    elif command_exists ag; then
        ag "$text" "$path"
    else
        grep -r "$text" "$path"
    fi
}

# Core module loaded indicator
export CORE_UTILITIES_LOADED=true