# =====================================================
# ENHANCED BACKUP SYSTEM MODULE
# =====================================================

# Enhanced backup system with time-based organization and automatic pushing
export ZSHRC_CONFIG_DIR="$HOME/.config/zsh"
export ZSHRC_BACKUPS="$HOME/.zshrc_backups"

# Automatic backup triggers
export AUTO_BACKUP_ON_CHANGE=true
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
        git -C "$ZSHRC_BACKUPS" remote add origin "git@github.com:dheerajchand/zshrc_backups.git" 2>/dev/null || true
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
        "README.md"
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
alias backup='enhanced_backup'
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
    echo "📚 Config: https://github.com/dheerajchand/siege_analytics_zshrc"
    echo "💾 Backups: https://github.com/dheerajchand/zshrc_backups"
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

# Auto-backup hook for zsh
autoload -U add-zsh-hook
add-zsh-hook preexec auto_backup_trigger

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
