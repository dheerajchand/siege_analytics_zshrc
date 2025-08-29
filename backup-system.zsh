# =====================================================
# ENHANCED BACKUP SYSTEM MODULE
# =====================================================

# Enhanced backup system with time-based organization
export ZSHRC_CONFIG_DIR="$HOME/.config/zsh"
export ZSHRC_BACKUPS="$HOME/.zshrc_backups"

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

    echo "💾 Creating enhanced modular config backup..."
    echo "📁 Location: $backup_dir"
    echo "💬 Message: $commit_message"

    mkdir -p "$backup_dir"

    # Backup main zshrc (ensure it's not hidden)
    cp ~/.zshrc "$backup_dir/zshrc.txt"

    # Backup all module files if they exist
    if [[ -d "$ZSHRC_CONFIG_DIR" ]]; then
        # Copy config files but exclude git metadata
        if [[ -d "$ZSHRC_CONFIG_DIR" ]]; then
            mkdir -p "$backup_dir/zsh"
            # Copy files but exclude .git directories
            rsync -av --exclude='.git' "$ZSHRC_CONFIG_DIR/" "$backup_dir/zsh/"
        fi
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
    "shell_version": "$ZSH_VERSION"
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
    # GIT INTEGRATION
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
        if git -C "$ZSHRC_BACKUPS" push origin main; then
            echo "✅ Successfully pushed to GitHub!"
        else
            echo "❌ Git push failed. Check connection."
            echo "💡 Manual push: cd ~/.zshrc_backups && git push origin main"
        fi
    else
        echo "⚠️  Nothing new to commit (files unchanged)"
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
alias backup='backup_zsh_config'
alias backups='list_zsh_backups'

# =====================================================
# DUAL REPOSITORY SYNC SYSTEM
# =====================================================

# Sync both config and backup repositories
function sync_zsh_repositories {
    local commit_message="${1:-Automatic sync of zsh configuration}"
    local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    
    echo "🔄 Syncing zsh configuration repositories..."
    echo "📁 Config repo: $ZSHRC_CONFIG_DIR"
    echo "💾 Backup repo: $ZSHRC_BACKUPS"
    
    # Step 1: Sync config repository
    if [[ -d "$ZSHRC_CONFIG_DIR/.git" ]]; then
        echo "🔄 Syncing config repository..."
        cd "$ZSHRC_CONFIG_DIR"
        
        # Add all changes
        git add .
        
        # Commit if there are changes
        if git diff --staged --quiet; then
            echo "✅ Config repo: No changes to commit"
        else
            if git commit -m "$commit_message ($timestamp)"; then
                echo "✅ Config repo: Changes committed"
                
                # Push to origin
                if git push origin main; then
                    echo "🚀 Config repo: Successfully pushed to GitHub"
                else
                    echo "❌ Config repo: Push failed"
                    return 1
                fi
            else
                echo "❌ Config repo: Commit failed"
                return 1
            fi
        fi
    else
        echo "❌ Config repo: Not a git repository"
        return 1
    fi
    
    # Step 2: Sync backup repository
    if [[ -d "$ZSHRC_BACKUPS/.git" ]]; then
        echo "🔄 Syncing backup repository..."
        cd "$ZSHRC_BACKUPS"
        
        # Add all changes
        git add .
        
        # Commit if there are changes
        if git diff --staged --quiet; then
            echo "✅ Backup repo: No changes to commit"
        else
            if git commit -m "$commit_message - backup sync ($timestamp)"; then
                echo "✅ Backup repo: Changes committed"
                
                # Push to origin
                if git push origin main; then
                    echo "🚀 Backup repo: Successfully pushed to GitHub"
                else
                    echo "❌ Backup repo: Push failed"
                    return 1
                fi
            else
                echo "❌ Backup repo: Commit failed"
                return 1
            fi
        fi
    else
        echo "❌ Backup repo: Not a git repository"
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

# Sync and backup in one operation
function sync_and_backup {
    local commit_message="${1:-Configuration update and backup}"
    
    echo "🔄 Performing sync and backup operation..."
    
    # First sync the repositories
    if sync_zsh_repositories "$commit_message"; then
        echo "💾 Creating backup after successful sync..."
        backup_zsh_config "$commit_message - post-sync backup"
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
