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
    # Remove duplicate entries from PATH while preserving essential system directories
    if [ -n "$PATH" ]; then
        local new_path=""
        local IFS=":"

        # Essential system directories that must always be preserved
        local essential_dirs=("/usr/bin" "/bin" "/usr/sbin" "/sbin" "/usr/local/bin")

        for dir in $PATH; do
            # Always keep essential directories even if -d test fails
            local is_essential=false
            for essential in "${essential_dirs[@]}"; do
                if [ "$dir" = "$essential" ]; then
                    is_essential=true
                    break
                fi
            done

            # Keep if not duplicate and (essential OR directory exists)
            if [[ ":$new_path:" != *":$dir:"* ]] && ($is_essential || [[ -d "$dir" ]]); then
                if [ -z "$new_path" ]; then
                    new_path="$dir"
                else
                    new_path="$new_path:$dir"
                fi
            fi
        done

        # Ensure essential directories are present even if they weren't in original PATH
        for essential in "${essential_dirs[@]}"; do
            if [[ ":$new_path:" != *":$essential:"* ]]; then
                if [ -z "$new_path" ]; then
                    new_path="$essential"
                else
                    new_path="$new_path:$essential"
                fi
            fi
        done

        export PATH="$new_path"
    fi
}

repair_path() {
    # Comprehensive PATH repair and cleanup function
    # Usage: repair_path [--verbose] [--dry-run]
    #
    # Fixes common PATH issues:
    # - Empty entries (::)
    # - Non-existent directories
    # - Duplicate entries
    # - Malformed entries (spaces, special chars)
    # - Relative paths (converts to absolute when possible)
    # - Common broken entries (old Homebrew, removed apps, etc.)

    local verbose=false
    local dry_run=false
    local show_help=false

    # Parse arguments
    for arg in "$@"; do
        case "$arg" in
            --verbose|-v) verbose=true ;;
            --dry-run|-n) dry_run=true ;;
            --help|-h) show_help=true ;;
        esac
    done

    if [[ "$show_help" == "true" ]]; then
        echo "repair_path - Comprehensive PATH cleanup and repair"
        echo ""
        echo "Usage: repair_path [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --verbose, -v    Show detailed information about changes"
        echo "  --dry-run, -n    Show what would be changed without making changes"
        echo "  --help, -h       Show this help message"
        echo ""
        echo "Fixes:"
        echo "  • Empty entries (::)"
        echo "  • Non-existent directories"
        echo "  • Duplicate entries"
        echo "  • Malformed paths"
        echo "  • Relative paths (converts to absolute)"
        echo "  • Common broken entries"
        return 0
    fi

    if [[ -z "$PATH" ]]; then
        echo "⚠️  PATH is empty - cannot repair"
        return 1
    fi

    local original_path="$PATH"
    local original_count=$(echo "$PATH" | tr ':' '\n' | wc -l)
    local new_path=""
    local issues_found=0
    local duplicates_removed=0
    local nonexistent_removed=0
    local malformed_fixed=0
    local empty_removed=0
    local relative_converted=0

    echo "🔧 PATH Repair Tool"
    echo "==================="
    [[ "$dry_run" == "true" ]] && echo "🔍 DRY RUN MODE - No changes will be made"
    echo ""

    # Split PATH and process each entry
    local IFS=":"
    for entry in $PATH; do
        local fixed_entry="$entry"
        local entry_issues=""

        # Skip completely empty entries
        if [[ -z "$entry" ]]; then
            entry_issues="${entry_issues}empty "
            ((empty_removed++))
            ((issues_found++))
            [[ "$verbose" == "true" ]] && echo "❌ Removed empty entry"
            continue
        fi

        # Fix relative paths by converting to absolute
        if [[ "$entry" =~ ^[^/] ]]; then
            if [[ -d "$PWD/$entry" ]]; then
                fixed_entry="$PWD/$entry"
                entry_issues="${entry_issues}relative->absolute "
                ((relative_converted++))
                ((issues_found++))
                [[ "$verbose" == "true" ]] && echo "🔄 Converted relative: $entry → $fixed_entry"
            else
                entry_issues="${entry_issues}relative-nonexistent "
                ((nonexistent_removed++))
                ((issues_found++))
                [[ "$verbose" == "true" ]] && echo "❌ Removed non-existent relative path: $entry"
                continue
            fi
        fi

        # Check for malformed entries (containing spaces without quotes, etc.)
        if [[ "$fixed_entry" =~ [[:space:]] ]] && [[ ! "$fixed_entry" =~ ^\" ]]; then
            entry_issues="${entry_issues}malformed-spaces "
            ((malformed_fixed++))
            ((issues_found++))
            [[ "$verbose" == "true" ]] && echo "⚠️  Malformed path with spaces: $fixed_entry"
            # Don't automatically fix - might break intentional paths
        fi

        # Check if directory exists
        if [[ ! -d "$fixed_entry" ]]; then
            entry_issues="${entry_issues}nonexistent "
            ((nonexistent_removed++))
            ((issues_found++))
            [[ "$verbose" == "true" ]] && echo "❌ Removed non-existent: $fixed_entry"
            continue
        fi

        # Check for duplicates
        if [[ ":$new_path:" == *":$fixed_entry:"* ]]; then
            entry_issues="${entry_issues}duplicate "
            ((duplicates_removed++))
            ((issues_found++))
            [[ "$verbose" == "true" ]] && echo "🔄 Removed duplicate: $fixed_entry"
            continue
        fi

        # Add to new PATH
        if [[ -z "$new_path" ]]; then
            new_path="$fixed_entry"
        else
            new_path="$new_path:$fixed_entry"
        fi

        if [[ "$verbose" == "true" ]] && [[ -z "$entry_issues" ]]; then
            echo "✅ Kept: $fixed_entry"
        fi
    done

    # Report results
    local new_count=$(echo "$new_path" | tr ':' '\n' | wc -l)
    local removed_count=$((original_count - new_count))

    echo ""
    echo "📊 PATH Repair Summary:"
    echo "======================="
    echo "• Original entries: $original_count"
    echo "• Final entries: $new_count"
    echo "• Total removed: $removed_count"
    echo ""
    echo "Issues fixed:"
    echo "• Empty entries removed: $empty_removed"
    echo "• Non-existent paths removed: $nonexistent_removed"
    echo "• Duplicate entries removed: $duplicates_removed"
    echo "• Relative paths converted: $relative_converted"
    echo "• Malformed paths detected: $malformed_fixed"
    echo ""

    if [[ $issues_found -eq 0 ]]; then
        echo "✅ PATH is already clean - no issues found!"
        return 0
    fi

    if [[ "$dry_run" == "true" ]]; then
        echo "🔍 DRY RUN COMPLETE - Run without --dry-run to apply changes"
        return 0
    fi

    # Apply changes
    export PATH="$new_path"
    echo "✅ PATH repaired successfully!"
    echo ""
    echo "💡 Tips:"
    echo "• Run 'repair_path --verbose' to see detailed changes"
    echo "• Use 'deduplicate_path' for quick duplicate removal"
    echo "• Consider running repair_path after major software installs/removals"

    return 0
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
    # deduplicate_path - commented out, call manually when needed

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