# =====================================================
# ENHANCED BACKUP SYSTEM MODULE
# =====================================================

# Enhanced backup system with time-based organization and automatic pushing
export ZSHRC_CONFIG_DIR="$HOME/.config/zsh"
export ZSHRC_BACKUPS="$HOME/.zshrc_backups"

# Automatic backup triggers
export AUTO_BACKUP_ON_CHANGE=true
export AUTO_BACKUP_INTERVAL=3600  # 1 hour in seconds

function get_backup_path {
    local timestamp="$1"
    local year=$(date -d "$timestamp" +"%Y" 2>/dev/null || date -j -f "%Y-%m-%d_%H-%M-%S" "$timestamp" +"%Y" 2>/dev/null || echo "2025")
    local month=$(date -d "$timestamp" +"%m" 2>/dev/null || date -j -f "%Y-%m-%d_%H-%M-%S" "$timestamp" +"%m" 2>/dev/null || echo "01")
    local week_of_month=$(( ($(date -d "$timestamp" +"%d" 2>/dev/null || date -j -f "%Y-%m-%d_%H-%M-%S" "$timestamp" +"%d" 2>/dev/null || echo "1") - 1) / 7 + 1 ))

    echo "$ZSHRC_BACKUPS/$year/$month/week$week_of_month"
}

function backup_zsh_config {
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
    local commit_message="${1:-Enhanced backup with sync}"
    
    echo "🚀 Starting enhanced backup with automatic sync..."
    
    # First sync the config repository
    if sync_config_repository "$commit_message"; then
        echo "✅ Config repository synced"
        
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

# Sync only backup repository
function sync_backup_repository {
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

# =====================================================
# ENHANCED DUAL REPOSITORY SYNC SYSTEM
# =====================================================

# Enhanced sync with better error handling and automatic pushing
function sync_zsh_repositories {
    local commit_message="${1:-Automatic sync of zsh configuration}"
    
    echo "🔄 Syncing zsh configuration repositories..."
    echo "📁 Config repo: $ZSHRC_CONFIG_DIR"
    echo "💾 Backup repo: $ZSHRC_BACKUPS"
    
    # Step 1: Sync config repository
    if ! sync_config_repository "$commit_message"; then
        echo "❌ Config repository sync failed"
        return 1
    fi
    
    # Step 2: Sync backup repository
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
    sync_zsh_repositories "Configuration update"
}

# Enhanced sync and backup in one operation
function sync_and_backup {
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

# Auto-backup hook for zsh
autoload -U add-zsh-hook
add-zsh-hook preexec auto_backup_trigger
