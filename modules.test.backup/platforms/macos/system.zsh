#!/usr/bin/env zsh

# =====================================================
# MACOS SYSTEM UTILITIES
# =====================================================
#
# macOS-specific system utilities and performance tools.
# These functions help manage macOS system services and diagnostics.
# =====================================================

restart_finder() {
    # Restart Finder to resolve file dialog and browsing issues
    #
    # This function is useful when experiencing:
    #   - Slow file dialogs in applications
    #   - File browser navigation issues
    #   - Stale file system caches
    #   - Problems with file creation/saving dialogs
    #
    # Examples:
    #     restart_finder
    #     restart_finder && echo "Finder restarted successfully"
    echo "🔄 Restarting Finder..."
    killall Finder 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ Finder restarted successfully"
        echo "💡 This should resolve file dialog and navigation issues"
    else
        echo "⚠️  Finder may not have been running, but it will start automatically"
    fi
}

# =====================================================
# ICLOUD FUNCTIONS MOVED TO CORE.ZSH
# =====================================================
#
# The icloud_diagnose() and icloud_cleanup() functions that were previously
# defined here have been moved to core.zsh with improved dependency checking
# and error handling.
#
# These functions were duplicated between this module and core.zsh, causing
# potential conflicts and maintenance issues. The authoritative versions now
# reside in core.zsh and include:
#
# - Better dependency validation (brctl command availability)
# - Improved error handling and user feedback
# - Consistent code style and documentation
# - Enhanced safety checks for file operations
#
# To use these functions:
#   icloud_diagnose          # Diagnose iCloud sync issues
#   icloud_cleanup           # Interactive cleanup utility
#
# Note: These functions will be available automatically when core.zsh is loaded.
# =====================================================

# macOS system module loaded indicator
export MACOS_SYSTEM_LOADED=true