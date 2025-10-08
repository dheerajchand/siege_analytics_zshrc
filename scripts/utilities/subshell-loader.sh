#!/bin/bash
# Subshell function loader - ensures functions are available in script contexts

# Source main configuration
source ~/.zshrc >/dev/null 2>&1

# Force load essential modules
load_module utils >/dev/null 2>&1
load_module python >/dev/null 2>&1

# Verify critical functions are available
if ! typeset -f backup >/dev/null && ! command -v backup >/dev/null; then
    # Manually source backup system if needed
    if [[ -f "$HOME/.config/zsh/scripts/utils/backup-system.zsh" ]]; then
        source "$HOME/.config/zsh/scripts/utils/backup-system.zsh" 2>/dev/null
    fi
fi

# Export all essential functions
export -f enhanced_backup 2>/dev/null || true
export -f backup 2>/dev/null || true
export -f load_module 2>/dev/null || true
export -f mkcd 2>/dev/null || true
export -f command_exists 2>/dev/null || true

