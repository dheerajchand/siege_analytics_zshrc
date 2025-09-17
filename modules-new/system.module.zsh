#!/usr/bin/env zsh
# =====================================================
# SYSTEM MODULE - Core utilities and PATH management
# =====================================================
#
# Purpose: Essential system utilities, PATH management, and core functionality
# Provides: PATH optimization, system info, file management, shell utilities
# Dependencies: centralized variables
# =====================================================

echo "🔧 Loading System module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# SHELL CONFIGURATION & MANAGEMENT
# =====================================================

# Purpose: Open ZSH configuration directory in default editor
# Arguments: None
# Returns: 0 on success, 1 if editor not found
# Usage: edit-config
edit-config() {
    local editor="${VISUAL:-${EDITOR:-zed}}"
    if command -v "$editor" >/dev/null 2>&1; then
        echo "Opening ZSH configuration with $editor..."
        "$editor" "$ZSH_CONFIG_DIR"
    else
        echo "❌ Editor '$editor' not found"
        return 1
    fi
}

# Purpose: Open ZSH configuration directory (alternative name)
# Arguments: None
# Returns: 0 on success, 1 if editor not found
# Usage: zshconfig
zshconfig() {
    edit-config
}

# Purpose: Reload shell configuration without restarting
# Arguments: None
# Returns: 0 always
# Usage: reload_shell
reload_shell() {
    echo "🔄 Reloading shell configuration..."
    source ~/.zshrc
    echo "✅ Shell configuration reloaded"
}

# =====================================================
# CORE UTILITY FUNCTIONS
# =====================================================

# Purpose: Check if a command exists in PATH
# Arguments: $1 - command name to check
# Returns: 0 if command exists, 1 if not found
# Usage: if command_exists git; then echo "Git available"; fi
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Purpose: Create directory and change into it in one command
# Arguments: $1 - directory path to create and enter
# Returns: 0 on success, non-zero on failure
# Usage: mkcd /path/to/new/directory
mkcd() {
    if [[ -z "$1" ]]; then
        echo "❌ Usage: mkcd <directory>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Purpose: Check if internet connection is available
# Arguments: None
# Returns: 0 if online, 1 if offline
# Usage: if is_online; then echo "Connected"; fi
is_online() {
    ping -c 1 google.com &> /dev/null
}

# Purpose: Get online status as string
# Arguments: None
# Returns: Prints "online" or "offline"
# Usage: status=$(is_online_status)
is_online_status() {
    if is_online; then
        echo "online"
    else
        echo "offline"
    fi
}

# Purpose: Universal extraction function for archives
# Arguments: $1 - archive file to extract
# Returns: 0 on success, 1 on error
# Usage: extract file.tar.gz
extract() {
    if [[ -z "$1" ]]; then
        echo "❌ Usage: extract <archive_file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "❌ File not found: $1"
        return 1
    fi

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
        *)           echo "❌ Unsupported archive format: $1" ;;
    esac
}

# =====================================================
# SYSTEM INFORMATION
# =====================================================

# Purpose: Display comprehensive system information
# Arguments: None
# Returns: 0 always
# Usage: system_info
system_info() {
    echo "🖥️  System Information"
    echo "===================="
    echo "OS: $OSTYPE"
    echo "Shell: $SHELL"
    echo "User: $USER"
    echo "Home: $HOME"
    echo "Hostname: $(hostname)"

    if command_exists uname; then
        echo "Kernel: $(uname -r)"
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS Version: $(sw_vers -productVersion 2>/dev/null || echo "Unknown")"
    fi

    echo ""
    echo "🔧 Shell Configuration:"
    echo "  Editor: ${EDITOR:-Not set}"
    echo "  Visual: ${VISUAL:-Not set}"
    echo "  Case sensitive: ${CASE_SENSITIVE:-false}"
    echo "  ZSH Config Dir: ${ZSH_CONFIG_DIR:-Not set}"

    echo ""
    echo "📊 PATH Information:"
    echo "  Length: ${#PATH} characters"
    echo "  Entries: $(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')"
}

# =====================================================
# PATH MANAGEMENT SYSTEM
# =====================================================

# Purpose: Add directory to PATH if not already present
# Arguments: $1 - directory path, $2 - position (prepend/append, default: prepend)
# Returns: 0 on success, 1 if directory doesn't exist
# Usage: path_add "/usr/local/bin" [append]
path_add() {
    local new_path="$1"
    local position="${2:-prepend}"

    if [[ -z "$new_path" ]]; then
        echo "❌ Usage: path_add <directory> [prepend|append]"
        return 1
    fi

    if [[ ! -d "$new_path" ]]; then
        echo "⚠️  Directory does not exist: $new_path"
        return 1
    fi

    # Check if path is already in PATH
    if [[ ":$PATH:" == *":$new_path:"* ]]; then
        echo "✅ Path already in PATH: $new_path"
        return 0
    fi

    case "$position" in
        "prepend")
            export PATH="$new_path:$PATH"
            echo "✅ Prepended to PATH: $new_path"
            ;;
        "append")
            export PATH="$PATH:$new_path"
            echo "✅ Appended to PATH: $new_path"
            ;;
        *)
            echo "❌ Invalid position: $position (use prepend or append)"
            return 1
            ;;
    esac
}

# Purpose: Remove directory from PATH
# Arguments: $1 - directory path to remove
# Returns: 0 on success, 1 if not found
# Usage: path_remove "/usr/local/bin"
path_remove() {
    local target_path="$1"

    if [[ -z "$target_path" ]]; then
        echo "❌ Usage: path_remove <directory>"
        return 1
    fi

    if [[ ":$PATH:" != *":$target_path:"* ]]; then
        echo "⚠️  Path not found in PATH: $target_path"
        return 1
    fi

    # Remove the path
    export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^$target_path$" | tr '\n' ':' | sed 's/:$//')
    echo "✅ Removed from PATH: $target_path"
}

# Purpose: Show comprehensive PATH status and health information
# Arguments: $1 - optional flag (--length, --duplicates, --invalid)
# Returns: 0 always
# Usage: path_status [--length|--duplicates|--invalid]
path_status() {
    local flag="$1"
    local path_length=${#PATH}
    local path_entries=(${(s/:/)PATH})
    local entry_count=${#path_entries[@]}

    case "$flag" in
        "--length")
            echo "📏 PATH Length: $path_length characters"
            echo "📊 PATH Entries: $entry_count directories"
            ;;
        "--duplicates")
            echo "🔍 Checking for duplicate PATH entries..."
            local seen_paths=()
            local duplicates=()

            for path_entry in "${path_entries[@]}"; do
                if [[ " ${seen_paths[*]} " =~ " ${path_entry} " ]]; then
                    duplicates+=("$path_entry")
                else
                    seen_paths+=("$path_entry")
                fi
            done

            if [[ ${#duplicates[@]} -gt 0 ]]; then
                echo "❌ Found ${#duplicates[@]} duplicate entries:"
                for dup in "${duplicates[@]}"; do
                    echo "  $dup"
                done
            else
                echo "✅ No duplicate entries found"
            fi
            ;;
        "--invalid")
            echo "🔍 Checking for invalid PATH entries..."
            local invalid_count=0

            for path_entry in "${path_entries[@]}"; do
                if [[ ! -d "$path_entry" ]]; then
                    echo "❌ Invalid directory: $path_entry"
                    ((invalid_count++))
                fi
            done

            if [[ $invalid_count -eq 0 ]]; then
                echo "✅ All PATH entries are valid directories"
            else
                echo "⚠️  Found $invalid_count invalid entries"
            fi
            ;;
        *)
            echo "📊 PATH Status Report"
            echo "===================="
            echo "📏 Length: $path_length characters"
            echo "📊 Entries: $entry_count directories"

            # Health assessment
            if [[ $path_length -gt 2000 ]]; then
                echo "🔴 Status: CRITICAL - PATH too long (may cause Finder issues)"
            elif [[ $path_length -gt 1000 ]]; then
                echo "🟡 Status: WARNING - PATH getting long"
            else
                echo "🟢 Status: HEALTHY - PATH length optimal"
            fi

            echo ""
            echo "🔍 Quick checks:"
            path_status --duplicates
            path_status --invalid

            echo ""
            echo "💡 Management commands:"
            echo "  path_clean --auto       # Clean duplicates and invalid entries"
            echo "  path_status --duplicates # Show duplicate entries"
            echo "  path_add <dir>          # Add directory to PATH"
            echo "  path_remove <dir>       # Remove directory from PATH"
            ;;
    esac
}

# Purpose: Clean and optimize PATH by removing duplicates and invalid entries
# Arguments: $1 - optional flag (--auto, --dry-run)
# Returns: 0 on success, 1 on error
# Usage: path_clean [--auto|--dry-run]
path_clean() {
    local mode="$1"
    local original_path="$PATH"
    local original_length=${#PATH}
    local path_entries=(${(s/:/)PATH})
    local cleaned_paths=()
    local seen_paths=()
    local removed_count=0
    local invalid_count=0

    echo "🧹 PATH Cleaning Utility"
    echo "========================"
    echo "📏 Original PATH length: $original_length characters"
    echo "📊 Original entries: ${#path_entries[@]}"

    # Process each PATH entry
    for path_entry in "${path_entries[@]}"; do
        # Skip empty entries
        if [[ -z "$path_entry" ]]; then
            ((removed_count++))
            continue
        fi

        # Check for duplicates
        if [[ " ${seen_paths[*]} " =~ " ${path_entry} " ]]; then
            echo "🔄 Removing duplicate: $path_entry"
            ((removed_count++))
            continue
        fi

        # Check if directory exists
        if [[ ! -d "$path_entry" ]]; then
            echo "🗑️  Removing invalid: $path_entry"
            ((invalid_count++))
            ((removed_count++))
            continue
        fi

        # Keep this entry
        cleaned_paths+=("$path_entry")
        seen_paths+=("$path_entry")
    done

    # Build new PATH
    local new_path=$(IFS=':'; echo "${cleaned_paths[*]}")
    local new_length=${#new_path}
    local saved_chars=$((original_length - new_length))
    local saved_entries=$((${#path_entries[@]} - ${#cleaned_paths[@]}))

    echo ""
    echo "📊 Cleaning Results:"
    echo "  Duplicates removed: $((removed_count - invalid_count))"
    echo "  Invalid paths removed: $invalid_count"
    echo "  Total entries removed: $removed_count"
    echo "  Characters saved: $saved_chars"
    echo "  New PATH length: $new_length characters"
    echo "  New entry count: ${#cleaned_paths[@]}"

    case "$mode" in
        "--dry-run")
            echo ""
            echo "🔍 DRY RUN - No changes made"
            echo "💡 Run 'path_clean --auto' to apply changes"
            ;;
        "--auto"|"")
            if [[ "$mode" != "--auto" ]]; then
                echo ""
                echo "❓ Apply these changes? (y/N)"
                read -r response
                if [[ ! "$response" =~ ^[Yy]$ ]]; then
                    echo "❌ Cancelled - no changes made"
                    return 1
                fi
            fi

            export PATH="$new_path"
            echo ""
            echo "✅ PATH cleaned successfully!"
            echo "💾 Backup saved to ~/.path_backup_$(date +%Y%m%d_%H%M%S)"
            echo "$original_path" > ~/.path_backup_$(date +%Y%m%d_%H%M%S)
            ;;
        *)
            echo "❌ Invalid mode: $mode"
            echo "💡 Usage: path_clean [--auto|--dry-run]"
            return 1
            ;;
    esac
}

# =====================================================
# MACOS SPECIFIC UTILITIES
# =====================================================

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Purpose: Restart Finder (fixes file dialog issues caused by long PATH)
    # Arguments: None
    # Returns: 0 always
    # Usage: restart_finder
    restart_finder() {
        echo "🔄 Restarting Finder..."
        killall Finder 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "✅ Finder restarted successfully"
            echo "💡 This should resolve file dialog and navigation issues"
        else
            echo "⚠️  Finder may not have been running, but it will start automatically"
        fi
    }
fi

# =====================================================
# ALIASES
# =====================================================

# Core system aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Editor aliases
alias vim='nvim'
alias edit='nvim'

# System management aliases
alias sysinfo='system_info'
alias pathinfo='path_status'
alias pathclean='path_clean'

echo "✅ System module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export SYSTEM_MODULE_LOADED=true