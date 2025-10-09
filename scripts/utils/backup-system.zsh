# =====================================================
# ENHANCED BACKUP SYSTEM MODULE
# =====================================================

# Enhanced backup system with time-based organization and automatic pushing
export ZSHRC_CONFIG_DIR="$HOME/.config/zsh"
export ZSHRC_BACKUPS="$HOME/.zshrc_backups"

# Zshrc sync configuration
export ZSHRC_WORKING_FILE="$HOME/.dotfiles/homedir/.zshrc"
export ZSHRC_REPO_FILE="$ZSHRC_CONFIG_DIR/zshrc"

# Automatic backup triggers
export AUTO_BACKUP_ON_CHANGE=false
export AUTO_BACKUP_INTERVAL=3600  # 1 hour in seconds

# Performance optimization: PATH deduplication
export PATH_DEDUPLICATION_ENABLED=true

# PATH deduplication function for performance optimization
function deduplicate_path {
    # Remove duplicate PATH entries while preserving order for optimal performance.
    #
    # This function eliminates duplicate PATH entries that can cause slow Finder
    # dialogs and other performance issues on macOS. It preserves the order of
    # entries while removing duplicates.
    #
    # Args:
    #     None (uses global PATH variable)
    #
    # Returns:
    #     None (modifies global PATH variable)
    #
    # Performance Impact:
    #     - Reduces PATH length by removing duplicates
    #     - Improves Finder dialog performance
    #     - Faster shell startup and command execution
    #
    # Example:
    #     deduplicate_path  # Removes duplicates from current PATH
    
    # Only run if enabled
    if [[ "$PATH_DEDUPLICATION_ENABLED" != "true" ]]; then
        return 0
    fi
    
    # Get current PATH
    local current_path="$PATH"
    local cleaned_path=""
    local seen=()
    local duplicates_removed=0
    
    # Split PATH and process each entry
    for entry in ${(s/:/)current_path}; do
        # Skip empty entries
        if [[ -z "$entry" ]]; then
            continue
        fi
        
        # Check if we've seen this entry before
        if [[ ! " ${seen[@]} " =~ " ${entry} " ]]; then
            seen+=("$entry")
            if [[ -z "$cleaned_path" ]]; then
                cleaned_path="$entry"
            else
                cleaned_path="$cleaned_path:$entry"
            fi
        else
            duplicates_removed=$((duplicates_removed + 1))
        fi
    done
    
    # Set the cleaned PATH
    export PATH="$cleaned_path"
    
    # Log if duplicates were removed (only in verbose mode)
    if [[ $duplicates_removed -gt 0 && -n "$VERBOSE_BACKUP" ]]; then
        echo "🔧 PATH optimized: removed $duplicates_removed duplicates"
    fi
}

function get_backup_path {
    # Generate a time-based backup path with year/month/week organization.
    #
    # Args:
    #     timestamp (str): Timestamp string in format YYYY-MM-DD_HH-MM-SS
    #     
    # Returns:
    #     str: Organized backup path in format ~/.zshrc_backups/YYYY/MM/weekN/
    #     
    # Example:
    #     get_backup_path "2025-08-29_14-13-00"
    #     # Returns: ~/.zshrc_backups/2025/08/week5/
    local timestamp="$1"
    local year=$(date -d "$timestamp" +"%Y" 2>/dev/null || date -j -f "%Y-%m-%d_%H-%M-%S" "$timestamp" +"%Y" 2>/dev/null || echo "2025")
    local month=$(date -d "$timestamp" +"%m" 2>/dev/null || date -j -f "%Y-%m-%d_%H-%M-%S" "$timestamp" +"%m" 2>/dev/null || echo "01")
    local week_of_month=$(( ($(date -d "$timestamp" +"%d" 2>/dev/null || date -j -f "%Y-%m-%d_%H-%M-%S" "$timestamp" +"%d" 2>/dev/null || echo "1") - 1) / 7 + 1 ))

    echo "$ZSHRC_BACKUPS/$year/$month/week$week_of_month"
}

function backup_zsh_config {
    # Create a comprehensive backup of the zsh configuration with Git integration.
    #
    # This function creates a timestamped backup of the main zshrc and all module files,
    # organizes them by time, generates metadata, creates restore scripts, and
    # automatically commits and pushes to the backup repository.
    #
    # Args:
    #     commit_message (str, optional): Custom commit message for the backup.
    #                                    Defaults to "Automatic backup".
    #
    # Returns:
    #     int: 0 on success, 1 on failure
    #     
    # Features:
    #     - Time-based organization (year/month/week)
    #     - Metadata generation with system info
    #     - Restore script creation
    #     - Automatic Git commit and push
    #     - Retry logic with exponential backoff
    #     - Conflict resolution
    #     
    # Example:
    #     backup_zsh_config "Feature update backup"
    #     backup_zsh_config  # Uses default message
    local commit_message="${1:-Automatic backup}"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    local backup_base_path=$(get_backup_path "$timestamp")
    local backup_dir="$backup_base_path/config_$timestamp"
    local push_attempts=0
    local max_push_attempts=3

    echo "💾 Creating enhanced modular config backup..."
    echo "📁 Location: $backup_dir"
    echo "💬 Message: $commit_message"

    mkdir -p "$backup_dir"

    # Backup main zshrc (ensure it's not hidden)
    if [[ -f ~/.zshrc ]]; then
    cp ~/.zshrc "$backup_dir/zshrc.txt"
        echo "✅ Main zshrc backed up"
    else
        echo "⚠️  Main zshrc not found"
    fi

    # Backup all module files if they exist
    if [[ -d "$ZSHRC_CONFIG_DIR" ]]; then
        # Copy config files but exclude git metadata
            mkdir -p "$backup_dir/zsh"
            # Copy files but exclude .git directories
            rsync -av --exclude='.git' "$ZSHRC_CONFIG_DIR/" "$backup_dir/zsh/"
        echo "✅ Module files backed up"
    fi

    # Create metadata
    cat > "$backup_dir/metadata.json" << METADATA_EOF
{
    "timestamp": "$timestamp",
    "commit_message": "$commit_message",
    "backup_type": "modular",
    "system": "$(uname -s)",
    "user": "$USER",
    "hostname": "$HOSTNAME",
    "shell_version": "$ZSH_VERSION",
    "config_dir": "$ZSHRC_CONFIG_DIR",
    "backup_dir": "$ZSHRC_BACKUPS"
}
METADATA_EOF

    # Create restore script
    cat > "$backup_dir/restore.sh" << 'RESTORE_EOF'
#!/bin/bash
echo "🔄 Restoring modular zsh configuration..."
if [[ -f ~/.zshrc ]]; then
    echo "💾 Backing up current config..."
    cp ~/.zshrc ~/.zshrc.pre-restore.$(date +%s)
fi
echo "📂 Restoring main zshrc..."
cp zshrc.txt ~/.zshrc
if [[ -d zsh ]]; then
    echo "📂 Restoring modular config..."
    mkdir -p ~/.config
    cp -r zsh ~/.config/
fi
echo "✅ Configuration restored!"
source ~/.zshrc
RESTORE_EOF
    chmod +x "$backup_dir/restore.sh"

    echo "✅ Enhanced backup created: $backup_dir"

    # =====================================================
    # ENHANCED GIT INTEGRATION WITH AUTOMATIC PUSHING
    # =====================================================

    # Ensure Git repository is initialized
    if [[ ! -d "$ZSHRC_BACKUPS/.git" ]]; then
        echo "🔧 Initializing backup Git repository..."
        git -C "$ZSHRC_BACKUPS" init
        # Use dynamic repository configuration from variables.zsh
        local git_url="${ZSH_BACKUP_REPO/https:\/\/github.com\//git@github.com:}.git"
        git -C "$ZSHRC_BACKUPS" remote add origin "$git_url" 2>/dev/null || true
        git -C "$ZSHRC_BACKUPS" branch -M main 2>/dev/null || true
    fi

    echo "🔄 Adding backup files to git..."
    git -C "$ZSHRC_BACKUPS" add .

    echo "📝 Creating commit..."
    if git -C "$ZSHRC_BACKUPS" commit -m "$commit_message ($timestamp)"; then
        echo "🚀 Pushing to GitHub..."
        
        # Retry push with exponential backoff
        while [[ $push_attempts -lt $max_push_attempts ]]; do
        if git -C "$ZSHRC_BACKUPS" push origin main; then
            echo "✅ Successfully pushed to GitHub!"
                return 0
            else
                ((push_attempts++))
                echo "❌ Git push failed (attempt $push_attempts/$max_push_attempts)"
                
                if [[ $push_attempts -lt $max_push_attempts ]]; then
                    local wait_time=$((2 ** push_attempts))
                    echo "⏳ Waiting $wait_time seconds before retry..."
                    sleep $wait_time
                    
                    # Try to pull latest changes before retry
                    echo "🔄 Pulling latest changes before retry..."
                    git -C "$ZSHRC_BACKUPS" pull origin main --rebase
                fi
            fi
        done
        
        echo "❌ All push attempts failed. Manual intervention required."
            echo "💡 Manual push: cd ~/.zshrc_backups && git push origin main"
        return 1
    else
        echo "⚠️  Nothing new to commit (files unchanged)"
        return 0
    fi
}

# Automatic backup trigger function
function auto_backup_trigger {
    # Automatically trigger backups based on time intervals.
    #
    # This function is called as a zsh hook and checks if enough time has passed
    # since the last backup to trigger a new one. It respects the AUTO_BACKUP_INTERVAL
    # setting and only creates backups when needed.
    #
    # Args:
    #     None (called automatically by zsh hooks)
    #
    # Returns:
    #     None
    #     
    # Configuration:
    #     AUTO_BACKUP_ON_CHANGE: Enable/disable automatic backups
    #     AUTO_BACKUP_INTERVAL: Time between backups in seconds (default: 3600)
    #     
    # Example:
    #     # Called automatically by zsh hooks
    #     # Can be called manually: auto_backup_trigger
    if [[ "$AUTO_BACKUP_ON_CHANGE" == "true" ]]; then
        local last_backup_file="$ZSHRC_BACKUPS/.last_backup"
        local current_time=$(date +%s)
        local last_backup_time=0
        
        # Check if we need to backup
        if [[ -f "$last_backup_file" ]]; then
            last_backup_time=$(cat "$last_backup_file")
        fi
        
        local time_since_backup=$((current_time - last_backup_time))
        
        if [[ $time_since_backup -ge $AUTO_BACKUP_INTERVAL ]]; then
            echo "🔄 Auto-backup triggered..."
            backup_zsh_config "Automatic periodic backup"
            echo "$current_time" > "$last_backup_file"
        fi
    fi
}

# Enhanced backup with automatic sync
function enhanced_backup {
    # Perform a complete backup operation with automatic repository synchronization.
    #
    # This function orchestrates a full backup workflow: first syncs the config
    # repository, then syncs documentation between repos, creates a backup,
    # and finally syncs the backup repository. It's the recommended way to
    # perform backups as it ensures both repositories are up-to-date.
    #
    # Args:
    #     commit_message (str, optional): Custom commit message for the backup.
    #                                    Defaults to "Enhanced backup with sync".
    #
    # Returns:
    #     int: 0 on success, 1 on failure
    #         
    # Workflow:
    #     1. Sync config repository
    #     2. Sync documentation between repositories
    #     3. Create backup with metadata
    #     4. Sync backup repository
    #         
    # Example:
    #     enhanced_backup "Major feature update"
    #     enhanced_backup  # Uses default message
    local commit_message="${1:-Enhanced backup with sync}"
    
    echo "🚀 Starting enhanced backup with automatic sync..."
    
    # First sync the config repository
    if sync_config_repository "$commit_message"; then
        echo "✅ Config repository synced"
        
            # Then sync documentation between repositories
    if sync_documentation_between_repos "$commit_message"; then
        echo "✅ Documentation synced between repositories"
    else
        echo "⚠️  Documentation sync failed, continuing with backup"
    fi
    
    # Optimize PATH performance
    if [[ "$PATH_DEDUPLICATION_ENABLED" == "true" ]]; then
        deduplicate_path
        echo "✅ PATH optimized for performance"
    fi
        
        # Then create backup
        if backup_zsh_config "$commit_message"; then
            echo "✅ Backup created and pushed"
            
            # Finally sync the backup repository
            if sync_backup_repository "$commit_message"; then
                echo "✅ Backup repository synced"
                echo "🎉 Enhanced backup completed successfully!"
                return 0
            else
                echo "❌ Backup repository sync failed"
                return 1
            fi
        else
            echo "❌ Backup creation failed"
            return 1
        fi
    else
        echo "❌ Config repository sync failed"
        return 1
    fi
}

# Sync only config repository
function sync_config_repository {
    # Synchronize only the config repository with GitHub.
    #
    # This function handles committing and pushing changes to the main configuration
    # repository. It includes retry logic with exponential backoff and automatic
    # conflict resolution.
    #
    # Args:
    #     commit_message (str, optional): Custom commit message for the sync.
    #                                    Defaults to "Config repository sync".
    #
    # Returns:
    #     int: 0 on success, 1 on failure
    #         
    # Features:
    #     - Automatic conflict detection and resolution
    #     - Retry logic with exponential backoff
    #     - Pull before retry to resolve conflicts
    #         
    # Example:
    #     sync_config_repository "Update core functions"
    #     sync_config_repository  # Uses default message
    local commit_message="${1:-Config repository sync}"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    
    if [[ ! -d "$ZSHRC_CONFIG_DIR/.git" ]]; then
        echo "❌ Config repository not found"
        return 1
    fi
    
    echo "🔄 Syncing config repository..."
    cd "$ZSHRC_CONFIG_DIR"
    
    # Add all changes
    git add .
    
    # Commit if there are changes
    if git diff --staged --quiet; then
        echo "✅ Config repo: No changes to commit"
        return 0
    else
        if git commit -m "$commit_message ($timestamp)"; then
            echo "✅ Config repo: Changes committed"
            
            # Push to origin with retry logic
            local push_attempts=0
            local max_push_attempts=3
            
            while [[ $push_attempts -lt $max_push_attempts ]]; do
                if git push origin main; then
                    echo "🚀 Config repo: Successfully pushed to GitHub"
                    return 0
                else
                    ((push_attempts++))
                    echo "❌ Config repo: Push failed (attempt $push_attempts/$max_push_attempts)"
                    
                    if [[ $push_attempts -lt $max_push_attempts ]]; then
                        local wait_time=$((2 ** push_attempts))
                        echo "⏳ Waiting $wait_time seconds before retry..."
                        sleep $wait_time
                        
                        # Try to pull latest changes before retry
                        echo "🔄 Pulling latest changes before retry..."
                        git pull origin main --rebase
                    fi
                fi
            done
            
            echo "❌ All push attempts failed for config repository"
            return 1
        else
            echo "❌ Config repo: Commit failed"
            return 1
        fi
    fi
}

# Sync documentation between repositories
function sync_documentation_between_repos {
    # """
    # Synchronize key documentation files between the main config and backup repositories.
    #
    # This function ensures that important documentation files (README, docs, etc.)
    # are kept in sync between both repositories. It copies updated files from
    # the main config repo to the backup repo's root directory.
    #
    # Args:
    #     commit_message (str, optional): Custom commit message for the sync.
    #                                    Defaults to "Documentation sync between repos".
    #
    # Returns:
    #     int: 0 on success, 1 on failure
    #
    # Files Synced:
    #     - README.md (main repository overview)
    #     - docs/ directory (comprehensive documentation)
    #     - Key configuration files
    #
    # Example:
    #     sync_documentation_between_repos "Update documentation"
    #     sync_documentation_between_repos  # Uses default message
    # """
    local commit_message="${1:-Documentation sync between repos}"
    
    echo "📚 Syncing documentation between repositories..."
    
    # Check if both repositories exist
    if [[ ! -d "$ZSHRC_CONFIG_DIR" ]] || [[ ! -d "$ZSHRC_BACKUPS" ]]; then
        echo "❌ One or both repositories not found"
        return 1
    fi
    
    # List of key files to sync
    local key_files=(
        "docs/MAIN_README.md"
        "docs/"
        "help-module.zsh"
        "backup-system.zsh"
    )
    
    local sync_success=true
    
    for file in "${key_files[@]}"; do
        local source_path="$ZSHRC_CONFIG_DIR/$file"
        local dest_path="$ZSHRC_BACKUPS/$file"
        
        if [[ -e "$source_path" ]]; then
            echo "📄 Syncing $file..."
            
            if [[ -d "$source_path" ]]; then
                # Directory sync
                if rsync -av --delete "$source_path/" "$dest_path/" 2>/dev/null; then
                    echo "✅ Directory $file synced successfully"
                else
                    echo "❌ Failed to sync directory $file"
                    sync_success=false
                fi
            else
                # File sync
                if cp "$source_path" "$dest_path" 2>/dev/null; then
                    echo "✅ File $file synced successfully"
                else
                    echo "❌ Failed to sync file $file"
                    sync_success=false
                fi
            fi
        else
            echo "⚠️  Source file $file not found, skipping"
        fi
    done
    
    if [[ "$sync_success" == true ]]; then
        echo "✅ Documentation sync completed successfully"
        return 0
    else
        echo "❌ Some documentation files failed to sync"
        return 1
    fi
}

# Sync only backup repository
function sync_backup_repository {
#
    # Synchronize only the backup repository with GitHub.
    
    # This function handles committing and pushing changes to the backup repository.
    # It includes retry logic with exponential backoff and automatic conflict
    # resolution, similar to the config repository sync.
    
    # Args:
    #     commit_message (str, optional): Custom commit message for the sync.
    #                                    Defaults to "Backup repository sync".
    
    # Returns:
    #     int: 0 on success, 1 on failure
    #     
    # Features:
    #     - Automatic conflict detection and resolution
    #     - Retry logic with exponential backoff
    #     - Pull before retry to resolve conflicts
    #     
    # Example:
    #     sync_backup_repository "Update backup metadata"
    #     sync_backup_repository  # Uses default message
#
    local commit_message="${1:-Backup repository sync}"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    
    if [[ ! -d "$ZSHRC_BACKUPS/.git" ]]; then
        echo "❌ Backup repository not found"
        return 1
    fi
    
    echo "🔄 Syncing backup repository..."
    cd "$ZSHRC_BACKUPS"
    
    # Add all changes
    git add .
    
    # Commit if there are changes
    if git diff --staged --quiet; then
        echo "✅ Backup repo: No changes to commit"
        return 0
    else
        if git commit -m "$commit_message ($timestamp)"; then
            echo "✅ Backup repo: Changes committed"
            
            # Push to origin with retry logic
            local push_attempts=0
            local max_push_attempts=3
            
            while [[ $push_attempts -lt $max_push_attempts ]]; do
                if git push origin main; then
                    echo "🚀 Backup repo: Successfully pushed to GitHub"
                    return 0
                else
                    ((push_attempts++))
                    echo "❌ Backup repo: Push failed (attempt $push_attempts/$max_push_attempts)"
                    
                    if [[ $push_attempts -lt $max_push_attempts ]]; then
                        local wait_time=$((2 ** push_attempts))
                        echo "⏳ Waiting $wait_time seconds before retry..."
                        sleep $wait_time
                        
                        # Try to pull latest changes before retry
                        echo "🔄 Pulling latest changes before retry..."
                        git pull origin main --rebase
                    fi
                fi
            done
            
            echo "❌ All push attempts failed for backup repository"
            return 1
        else
            echo "❌ Backup repo: Commit failed"
            return 1
        fi
    fi
}

function list_zsh_backups {
#
    # Display a list of available zsh configuration backups.
    
    # This function scans the backup directory and displays all available backups
    # organized by time, showing the most recent backups first. It provides
    # information about backup size and total count.
    
    # Args:
    #     None
    
    # Returns:
    #     None (displays formatted output)
    #     
    # Output Format:
    #     - Timestamp of each backup
    #     - Size of backup directory
    #     - Total count of backups
    #     - Shows last 10 backups by default
    #     
    # Example:
    #     list_zsh_backups
    #     # Output:
    #     # 📋 ZSH Configuration Backups (Time-Organized):
    #     #    🗂️  2025-08-29_14-13-00 (2.1M)
    #     #    🗂️  2025-08-29_13-13-00 (2.1M)
    #     # Total backups: 15 (showing recent 10)
#
    echo "📋 ZSH Configuration Backups (Time-Organized):"
    echo ""

    local backup_dirs=($(find "$ZSHRC_BACKUPS" -name "config_*" -type d 2>/dev/null | sort -r))

    if [[ ${#backup_dirs[@]} -eq 0 ]]; then
        echo "   No backups found in $ZSHRC_BACKUPS"
        return
    fi

    for backup_dir in "${backup_dirs[@]:0:10}"; do  # Show last 10
        local dir_name=$(basename "$backup_dir")
        local timestamp="${dir_name#config_}"
        local size=$(du -sh "$backup_dir" 2>/dev/null | cut -f1 || echo "?")
        echo "    🗂️  $timestamp ($size)"
    done

    echo ""
    echo "Total backups: ${#backup_dirs[@]} (showing recent 10)"
}

# Convenience aliases
# alias backup='enhanced_backup'  # Commented out - using function instead
alias backups='list_zsh_backups'
alias autobackup='auto_backup_trigger'
alias optimize='deduplicate_path'

# =====================================================
# ENHANCED DUAL REPOSITORY SYNC SYSTEM
# =====================================================

# Enhanced sync with better error handling and automatic pushing
function sync_zsh_repositories {
    # Synchronize both the config and backup repositories with GitHub.
    #
    # This function performs a complete synchronization of both repositories,
    # ensuring they are up-to-date with the remote GitHub repositories. It
    # handles errors gracefully and provides detailed feedback on the sync process.
    #
    # Args:
    #     commit_message (str, optional): Custom commit message for the sync.
    #                                    Defaults to "Automatic sync of zsh configuration".
    #
    # Returns:
    #     int: 0 on success, 1 on failure
    #         
    # Workflow:
    #     1. Sync config repository
    #     2. Sync documentation between repositories
    #     3. Sync backup repository
    #         
    # Example:
    #     sync_zsh_repositories "Update all modules"
    #     sync_zsh_repositories  # Uses default message
    local commit_message="${1:-Automatic sync of zsh configuration}"
    
    echo "🔄 Syncing zsh configuration repositories..."
    echo "📁 Config repo: $ZSHRC_CONFIG_DIR"
    echo "💾 Backup repo: $ZSHRC_BACKUPS"
    
    # Step 1: Sync config repository
    if ! sync_config_repository "$commit_message"; then
        echo "❌ Config repository sync failed"
        return 1
    fi
    
    # Step 2: Sync documentation between repositories
    if ! sync_documentation_between_repos "$commit_message"; then
        echo "⚠️  Documentation sync failed, continuing with backup sync"
    fi
    
    # Step 2.5: Optimize PATH performance
    if [[ "$PATH_DEDUPLICATION_ENABLED" == "true" ]]; then
        deduplicate_path
        echo "✅ PATH optimized for performance"
    fi
    
    # Step 3: Sync backup repository
    if ! sync_backup_repository "$commit_message - backup sync"; then
        echo "❌ Backup repository sync failed"
        return 1
    fi
    
    echo "✅ Both repositories synced successfully!"
    echo "📚 Config: $ZSH_MAIN_REPO"
    echo "💾 Backups: $ZSH_BACKUP_REPO"
}

# Quick sync with default message
function sync_zsh {
#
    # Perform a quick synchronization of both repositories.
    
    # This is a convenience function that calls sync_zsh_repositories with
    # a default commit message. It's useful for regular maintenance and
    # quick sync operations.
    
    # Args:
    #     None
    
    # Returns:
    #     int: 0 on success, 1 on failure
    #     
    # Example:
    #     sync_zsh  # Quick sync with default message
#
    sync_zsh_repositories "Configuration update"
}

# Enhanced sync and backup in one operation
function sync_and_backup {
#
    # Perform both synchronization and backup in a single operation.
    
    # This function combines repository synchronization with backup creation,
    # ensuring that both operations complete successfully. It's useful for
    # comprehensive maintenance operations.
    
    # Args:
    #     commit_message (str, optional): Custom commit message for the operation.
    #                                    Defaults to "Configuration update and backup".
    
    # Returns:
    #     int: 0 on success, 1 on failure
    #     
    # Workflow:
    #     1. Sync both repositories
    #     2. Create comprehensive backup
    #     3. Verify all operations completed
    #     
    # Example:
    #     sync_and_backup "Major system update"
    #     sync_and_backup  # Uses default message
#
    local commit_message="${1:-Configuration update and backup}"
    
    echo "🔄 Performing enhanced sync and backup operation..."
    
    # First sync the repositories
    if sync_zsh_repositories "$commit_message"; then
        echo "💾 Creating backup after successful sync..."
        if enhanced_backup "$commit_message - post-sync backup"; then
            echo "🎉 Complete sync and backup operation successful!"
            return 0
        else
            echo "❌ Backup failed after successful sync"
            return 1
        fi
    else
        echo "❌ Sync failed, skipping backup"
        return 1
    fi
}

# Status check for both repositories
function zsh_repo_status {
#
    # Display the current status of both zsh configuration repositories.
    
    # This function provides a comprehensive overview of the status of both
    # the config and backup repositories, including branch information,
    # modification status, remote URLs, and commit differences.
    
    # Args:
    #     None
    
    # Returns:
    #     None (displays formatted status information)
    #     
    # Information Displayed:
    #     - Current branch
    #     - Number of modified files
    #     - Remote repository URL
    #     - Commits ahead/behind remote
    #     - Repository health status
    #     
    # Example:
    #     zsh_repo_status
    #     # Output:
    #     # 📊 ZSH Repository Status
    #     # ========================
    #     # 📁 Config Repository (~/.config/zsh):
    #     #    Branch: main
    #     #    Status: 0 files modified
    #     #    Remote: git@github.com:dheerajchand/siege_analytics_zshrc.git
    #     #    Ahead: 0 commits ahead
    #     #    Behind: 0 commits behind
#
    echo "📊 ZSH Repository Status"
    echo "========================"
    
    # Config repository status
    if [[ -d "$ZSHRC_CONFIG_DIR/.git" ]]; then
        echo "📁 Config Repository ($ZSHRC_CONFIG_DIR):"
        cd "$ZSHRC_CONFIG_DIR"
        echo "   Branch: $(git branch --show-current)"
        echo "   Status: $(git status --porcelain | wc -l | tr -d ' ') files modified"
        echo "   Remote: $(git remote get-url origin)"
        echo "   Ahead: $(git rev-list --count origin/main..HEAD) commits ahead"
        echo "   Behind: $(git rev-list --count HEAD..origin/main) commits behind"
        echo ""
    else
        echo "❌ Config repository not found"
    fi
    
    # Backup repository status
    if [[ -d "$ZSHRC_BACKUPS/.git" ]]; then
        echo "💾 Backup Repository ($ZSHRC_BACKUPS):"
        cd "$ZSHRC_BACKUPS"
        echo "   Branch: $(git branch --show-current)"
        echo "   Status: $(git status --porcelain | wc -l | tr -d ' ') files modified"
        echo "   Remote: $(git remote get-url origin)"
        echo "   Ahead: $(git rev-list --count origin/main..HEAD) commits ahead"
        echo "   Behind: $(git rev-list --count HEAD..origin/main) commits behind"
        echo ""
    else
        echo "❌ Backup repository not found"
    fi
    
    # Return to original directory
    cd "$ZSHRC_CONFIG_DIR"
}

# Convenience aliases for sync functions
alias sync='sync_zsh'
alias syncbackup='sync_and_backup'
alias repostatus='zsh_repo_status'
alias autobackup='enhanced_backup'
alias optimize='deduplicate_path'
alias push='push_to_main_repo'
# alias pushmain='push_main'  # Commented out - using function instead for script compatibility

# Auto-backup hook for zsh (DISABLED - was causing unwanted auto-commits)
# autoload -U add-zsh-hook
# add-zsh-hook preexec auto_backup_trigger

# Backup critical functions (placeholder for functions that might not exist)
function backup_critical_functions {
    echo "🔄 Backing up critical functions..."
    # This function can be extended to backup specific functions
    return 0
}

# Spark fix logging (placeholder for functions that might not exist)
function spark_fix_logging {
    echo "🔧 Fixing Spark logging..."
    # This function can be extended to fix Spark logging issues
    return 0
}

# =====================================================
# MAIN REPOSITORY UPDATE FUNCTIONS
# =====================================================

# Push to main repository with commit and push
function push_to_main_repo {
    # Push current changes directly to the main GitHub repository.
    #
    # This function adds, commits, and pushes changes to the main config repository
    # (using ZSH_MAIN_REPO from variables.zsh). It handles the
    # complete workflow for updating the main repository with your changes.
    #
    # Args:
    #     commit_message (str, optional): Custom commit message for the push.
    #                                    Defaults to timestamp-based message.
    #
    # Returns:
    #     int: 0 on success, 1 on failure
    #
    # Features:
    #     - Automatic conflict detection and resolution
    #     - Retry logic with exponential backoff
    #     - Pull before retry to resolve conflicts
    #     - Shows repository status before and after
    #
    # Example:
    #     push_to_main_repo "Add 3-tier architecture functions"
    #     push_to_main_repo  # Uses default timestamp message
    local commit_message="${1:-Update configuration $(date +"%Y-%m-%d_%H-%M-%S")}"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")

    echo "🚀 Pushing to main repository..."
    echo "📁 Repository: $ZSHRC_CONFIG_DIR"
    echo "💬 Message: $commit_message"
    echo ""

    if [[ ! -d "$ZSHRC_CONFIG_DIR/.git" ]]; then
        echo "❌ Main repository not found or not a git repository"
        echo "💡 Expected location: $ZSHRC_CONFIG_DIR"
        return 1
    fi

    cd "$ZSHRC_CONFIG_DIR"

    # Show current status
    echo "📊 Current repository status:"
    git status --short
    echo ""

    # Add all changes
    echo "📝 Adding all changes..."
    git add .

    # Check if there are any changes to commit
    if git diff --staged --quiet; then
        echo "ℹ️  No changes to commit - repository is up to date"
        return 0
    fi

    # Commit changes
    echo "💾 Committing changes..."
    if git commit -m "$commit_message

🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"; then
        echo "✅ Changes committed successfully"

        # Push to origin with retry logic
        local push_attempts=0
        local max_push_attempts=3

        echo "🔄 Pushing to GitHub..."
        while [[ $push_attempts -lt $max_push_attempts ]]; do
            if git push origin main; then
                echo "🚀 Successfully pushed to main repository!"
                echo "🌐 View changes: $ZSH_MAIN_REPO"
                return 0
            else
                ((push_attempts++))
                echo "❌ Push failed (attempt $push_attempts/$max_push_attempts)"

                if [[ $push_attempts -lt $max_push_attempts ]]; then
                    local wait_time=$((2 ** push_attempts))
                    echo "⏳ Waiting $wait_time seconds before retry..."
                    sleep $wait_time

                    # Try to pull latest changes before retry
                    echo "🔄 Pulling latest changes before retry..."
                    git pull origin main --rebase
                fi
            fi
        done

        echo "❌ All push attempts failed"
        echo "💡 Manual intervention required - check for conflicts"
        return 1
    else
        echo "❌ Commit failed"
        return 1
    fi
}

# Quick push function with default message
function push_main {
    # Quick push to main repository with timestamp-based commit message.
    #
    # This is a convenience function that calls push_to_main_repo with
    # a default commit message. Useful for quick updates without
    # needing to specify a custom message.
    #
    # Args:
    #     None
    #
    # Returns:
    #     int: 0 on success, 1 on failure
    #
    # Example:
    #     push_main  # Quick push with default message
    push_to_main_repo "Configuration update $(date +"%Y-%m-%d_%H-%M-%S")"
}

# =====================================================
# ZSHRC SYNC FUNCTIONS
# =====================================================

# Sync zshrc from working file to repository
function sync_zshrc_to_repo {
    # Sync the working zshrc file to the repository for distribution.
    #
    # This function copies the current working zshrc file to the repository
    # so that others can use the configuration when they clone the repo.
    # It handles the symlink issue by providing actual file content.
    #
    # Args:
    #     None
    #
    # Returns:
    #     None
    #
    # Example:
    #     sync_zshrc_to_repo  # Copy working zshrc to repo
    
    echo "🔄 Syncing zshrc from working file to repository..."
    
    # Check if working file exists
    if [[ ! -f "$ZSHRC_WORKING_FILE" ]]; then
        echo "❌ Working zshrc file not found: $ZSHRC_WORKING_FILE"
        echo "💡 Make sure your zshrc symlink is properly configured"
        return 1
    fi
    
    # Check if repo directory exists
    if [[ ! -d "$ZSHRC_CONFIG_DIR" ]]; then
        echo "❌ Repository directory not found: $ZSHRC_CONFIG_DIR"
        return 1
    fi
    
    # Create backup of current repo file
    if [[ -f "$ZSHRC_REPO_FILE" ]]; then
        local backup_file="$ZSHRC_REPO_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ZSHRC_REPO_FILE" "$backup_file"
        echo "💾 Created backup: $(basename "$backup_file")"
    fi
    
    # Copy working file to repository
    if cp "$ZSHRC_WORKING_FILE" "$ZSHRC_REPO_FILE"; then
        echo "✅ Successfully synced zshrc to repository"
        echo "📁 Source: $ZSHRC_WORKING_FILE"
        echo "📁 Target: $ZSHRC_REPO_FILE"
        
        # Show file sizes for verification
        local source_size=$(wc -l < "$ZSHRC_WORKING_FILE")
        local target_size=$(wc -l < "$ZSHRC_REPO_FILE")
        echo "📊 Lines: $source_size → $target_size"
        
        return 0
    else
        echo "❌ Failed to sync zshrc to repository"
        return 1
    fi
}

# Sync zshrc from repository to working file
function sync_zshrc_from_repo {
    # Sync the repository zshrc file to the working file.
    #
    # This function copies the repository zshrc file to the working location.
    # Useful when you want to restore from a repository version or when
    # setting up a new environment.
    #
    # Args:
    #     None
    #
    # Returns:
    #     None
    #
    # Example:
    #     sync_zshrc_from_repo  # Copy repo zshrc to working file
    
    echo "🔄 Syncing zshrc from repository to working file..."
    
    # Check if repo file exists
    if [[ ! -f "$ZSHRC_REPO_FILE" ]]; then
        echo "❌ Repository zshrc file not found: $ZSHRC_REPO_FILE"
        echo "💡 Make sure you're in the correct repository directory"
        return 1
    fi
    
    # Check if working directory exists
    local working_dir=$(dirname "$ZSHRC_WORKING_FILE")
    if [[ ! -d "$working_dir" ]]; then
        echo "❌ Working directory not found: $working_dir"
        return 1
    fi
    
    # Create backup of current working file
    if [[ -f "$ZSHRC_WORKING_FILE" ]]; then
        local backup_file="$ZSHRC_WORKING_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ZSHRC_WORKING_FILE" "$backup_file"
        echo "💾 Created backup: $(basename "$backup_file")"
    fi
    
    # Copy repo file to working location
    if cp "$ZSHRC_REPO_FILE" "$ZSHRC_WORKING_FILE"; then
        echo "✅ Successfully synced zshrc from repository"
        echo "📁 Source: $ZSHRC_REPO_FILE"
        echo "📁 Target: $ZSHRC_WORKING_FILE"
        
        # Show file sizes for verification
        local source_size=$(wc -l < "$ZSHRC_REPO_FILE")
        local target_size=$(wc -l < "$ZSHRC_WORKING_FILE")
        echo "📊 Lines: $source_size → $target_size"
        
        echo "💡 You may need to reload your shell: source ~/.zshrc"
        return 0
    else
        echo "❌ Failed to sync zshrc from repository"
        return 1
    fi
}

# Compare zshrc files
function compare_zshrc_files {
    # Compare the working zshrc file with the repository version.
    #
    # This function shows the differences between the working zshrc file
    # and the repository version, helping you understand what changes
    # need to be synced.
    #
    # Args:
    #     None
    #
    # Returns:
    #     None
    #
    # Example:
    #     compare_zshrc_files  # Show differences between files
    
    echo "🔍 Comparing zshrc files..."
    echo "📁 Working file: $ZSHRC_WORKING_FILE"
    echo "📁 Repository file: $ZSHRC_REPO_FILE"
    echo ""
    
    # Check if both files exist
    if [[ ! -f "$ZSHRC_WORKING_FILE" ]]; then
        echo "❌ Working zshrc file not found: $ZSHRC_WORKING_FILE"
        return 1
    fi
    
    if [[ ! -f "$ZSHRC_REPO_FILE" ]]; then
        echo "❌ Repository zshrc file not found: $ZSHRC_REPO_FILE"
        return 1
    fi
    
    # Show file info
    echo "📊 File Information:"
    echo "   Working file: $(wc -l < "$ZSHRC_WORKING_FILE") lines, $(stat -f%z "$ZSHRC_WORKING_FILE") bytes"
    echo "   Repository file: $(wc -l < "$ZSHRC_REPO_FILE") lines, $(stat -f%z "$ZSHRC_REPO_FILE") bytes"
    echo ""
    
    # Check if files are identical
    if cmp -s "$ZSHRC_WORKING_FILE" "$ZSHRC_REPO_FILE"; then
        echo "✅ Files are identical - no sync needed"
        return 0
    fi
    
    # Show differences
    echo "📋 Differences found:"
    echo "===================="
    diff -u "$ZSHRC_REPO_FILE" "$ZSHRC_WORKING_FILE" || true
    echo ""
    echo "💡 Use 'sync_zshrc_to_repo' to update repository with working changes"
    echo "💡 Use 'sync_zshrc_from_repo' to update working file with repository changes"
}

# Complete zshrc sync workflow
function sync_zshrc_workflow {
    # Complete workflow for syncing zshrc changes to repository.
    #
    # This function performs a complete sync workflow:
    # 1. Compares files to show differences
    # 2. Syncs working file to repository
    # 3. Commits changes to git
    # 4. Pushes to remote repository
    #
    # Args:
    #     None
    #
    # Returns:
    #     None
    #
    # Example:
    #     sync_zshrc_workflow  # Complete sync and push workflow
    
    echo "🚀 Starting complete zshrc sync workflow..."
    echo "=========================================="
    
    # Step 1: Compare files
    echo "📋 Step 1: Comparing files..."
    compare_zshrc_files
    echo ""
    
    # Step 2: Sync to repository
    echo "📋 Step 2: Syncing to repository..."
    if ! sync_zshrc_to_repo; then
        echo "❌ Sync failed - aborting workflow"
        return 1
    fi
    echo ""
    
    # Step 3: Commit changes
    echo "📋 Step 3: Committing changes..."
    cd "$ZSHRC_CONFIG_DIR"
    
    if git add zshrc; then
        if git diff --cached --quiet; then
            echo "ℹ️  No changes to commit"
        else
            git commit -m "Update zshrc: Sync from working file

- Synced working zshrc file to repository
- Ensures repository contains latest configuration
- Fixes symlink issues for repository users
- Timestamp: $(date)"
            echo "✅ Changes committed"
        fi
    else
        echo "❌ Failed to stage changes"
        return 1
    fi
    echo ""
    
    # Step 4: Push to remote
    echo "📋 Step 4: Pushing to remote repository..."
    if git push; then
        echo "✅ Changes pushed to remote repository"
    else
        echo "❌ Failed to push changes"
        return 1
    fi
    echo ""
    
    echo "🎉 Zshrc sync workflow completed successfully!"
    echo "💡 Repository now contains the latest zshrc configuration"
}

# Show zshrc sync status
function zshrc_sync_status {
    # Show the current status of zshrc files and sync state.
    #
    # This function displays information about both zshrc files,
    # their modification times, sizes, and whether they're in sync.
    #
    # Args:
    #     None
    #
    # Returns:
    #     None
    #
    # Example:
    #     zshrc_sync_status  # Show sync status information
    
    echo "📊 Zshrc Sync Status"
    echo "==================="
    echo ""
    
    # Working file status
    if [[ -f "$ZSHRC_WORKING_FILE" ]]; then
        local working_size=$(stat -f%z "$ZSHRC_WORKING_FILE")
        local working_lines=$(wc -l < "$ZSHRC_WORKING_FILE")
        local working_mtime=$(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$ZSHRC_WORKING_FILE")
        echo "📁 Working File: $ZSHRC_WORKING_FILE"
        echo "   Size: $working_size bytes, $working_lines lines"
        echo "   Modified: $working_mtime"
        echo "   Type: $(file "$ZSHRC_WORKING_FILE" | cut -d: -f2-)"
    else
        echo "❌ Working file not found: $ZSHRC_WORKING_FILE"
    fi
    echo ""
    
    # Repository file status
    if [[ -f "$ZSHRC_REPO_FILE" ]]; then
        local repo_size=$(stat -f%z "$ZSHRC_REPO_FILE")
        local repo_lines=$(wc -l < "$ZSHRC_REPO_FILE")
        local repo_mtime=$(stat -f%Sm -t "%Y-%m-%d %H:%M:%S" "$ZSHRC_REPO_FILE")
        echo "📁 Repository File: $ZSHRC_REPO_FILE"
        echo "   Size: $repo_size bytes, $repo_lines lines"
        echo "   Modified: $repo_mtime"
        echo "   Type: $(file "$ZSHRC_REPO_FILE" | cut -d: -f2-)"
    else
        echo "❌ Repository file not found: $ZSHRC_REPO_FILE"
    fi
    echo ""
    
    # Sync status
    if [[ -f "$ZSHRC_WORKING_FILE" ]] && [[ -f "$ZSHRC_REPO_FILE" ]]; then
        if cmp -s "$ZSHRC_WORKING_FILE" "$ZSHRC_REPO_FILE"; then
            echo "✅ Files are in sync"
        else
            echo "⚠️  Files are out of sync"
            echo "💡 Use 'compare_zshrc_files' to see differences"
            echo "💡 Use 'sync_zshrc_workflow' to sync and push changes"
        fi
    else
        echo "❌ Cannot compare files - one or both missing"
    fi
    echo ""
    
    # Git status
    if [[ -d "$ZSHRC_CONFIG_DIR/.git" ]]; then
        cd "$ZSHRC_CONFIG_DIR"
        echo "📊 Git Status:"
        echo "   Branch: $(git branch --show-current)"
        echo "   Status: $(git status --porcelain | wc -l | tr -d ' ') files modified"
        if git diff --quiet zshrc; then
            echo "   Zshrc: No uncommitted changes"
        else
            echo "   Zshrc: Has uncommitted changes"
        fi
    else
        echo "❌ Not in a git repository"
    fi
}

# Test configuration script
function test_config_script {
    # Test the shell configuration script functionality.
    #
    # This function tests the configure-shell.sh script to ensure it works
    # correctly with different modes and options.
    #
    # Args:
    #     None
    #
    # Returns:
    #     None
    #
    # Example:
    #     test_config_script  # Test the configuration script
    
    echo "🧪 Testing shell configuration script..."
    echo "========================================"
    
    local script_path="$ZSHRC_CONFIG_DIR/configure-shell.sh"
    
    # Check if script exists
    if [[ ! -f "$script_path" ]]; then
        echo "❌ Configuration script not found: $script_path"
        return 1
    fi
    
    # Check if script is executable
    if [[ ! -x "$script_path" ]]; then
        echo "⚠️  Script is not executable, making it executable..."
        chmod +x "$script_path"
    fi
    
    echo "✅ Script found and executable: $script_path"
    echo ""
    
    # Test help functionality
    echo "📋 Testing help functionality..."
    if "$script_path" --help > /dev/null 2>&1; then
        echo "✅ Help functionality works"
    else
        echo "❌ Help functionality failed"
        return 1
    fi
    
    # Test validation
    echo "📋 Testing validation..."
    if "$script_path" --mode invalid 2>&1 | grep -q "Invalid mode"; then
        echo "✅ Validation works"
    else
        echo "❌ Validation failed"
        return 1
    fi
    
    # Test dry run (validation only)
    echo "📋 Testing dry run..."
    if "$script_path" --mode standalone --shell zsh 2>&1 | grep -q "Configuration Summary"; then
        echo "✅ Dry run works"
    else
        echo "❌ Dry run failed"
        return 1
    fi
    
    echo ""
    echo "🎉 Configuration script tests passed!"
    echo "💡 You can now use: ./configure-shell.sh --help"
}

# Convenience aliases for zshrc sync functions
alias zshrc-sync='sync_zshrc_to_repo'
alias zshrc-restore='sync_zshrc_from_repo'
alias zshrc-compare='compare_zshrc_files'
alias zshrc-workflow='sync_zshrc_workflow'
alias zshrc-status='zshrc_sync_status'
alias test-config='test_config_script'

# Script-compatible backup function (aliases don't work in non-interactive shells)
backup() {
    enhanced_backup "$@"
}

# Function available in zsh subshells by default


# Script-compatible pushmain function (aliases don't work in non-interactive shells)
pushmain() {
    push_main "$@"
}

# Function available in zsh subshells by default

