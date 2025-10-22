#!/usr/bin/env zsh
# =================================================================
# BACKUP - Git Self-Backup System
# =================================================================
# Automatic backup and sync to GitHub repositories
# =================================================================

# Repository locations
export ZSHRC_CONFIG_DIR="$HOME/.config/zsh"
export ZSHRC_MAIN_REPO="siege_analytics_zshrc"
export ZSHRC_BACKUP_REPO="zshrc_backups"

# Main backup function
backup() {
    local message="${1:-Config update}"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    cd "$ZSHRC_CONFIG_DIR" || {
        echo "❌ Cannot cd to $ZSHRC_CONFIG_DIR"
        return 1
    }
    
    # Check if git repo
    if [[ ! -d .git ]]; then
        echo "❌ Not a git repository"
        return 1
    fi
    
    echo "📦 Creating backup..."
    
    # Add all changes
    git add -A
    
    # Commit
    git commit -m "[$timestamp] $message" || {
        echo "⚠️  No changes to commit"
        return 0
    }
    
    # Push to main repo
    git push origin main && echo "✅ Pushed to main repo"
    
    # Push to backup repo if configured
    if git remote | grep -q backup; then
        git push backup main && echo "✅ Pushed to backup repo"
    fi
    
    echo "🎉 Backup complete"
}

# Quick push to main
pushmain() {
    backup "${1:-Quick update}"
}

# Sync repository (renamed to avoid conflict with sync command)
repo_sync() {
    cd "$ZSHRC_CONFIG_DIR" || return 1
    
    echo "🔄 Syncing repository..."
    
    git pull origin main --rebase
    git push origin main
    
    if git remote | grep -q backup; then
        git push backup main
    fi
    
    echo "✅ Sync complete"
}

# Show repository status
repo_status() {
    cd "$ZSHRC_CONFIG_DIR" || return 1
    
    echo "📊 Repository Status"
    echo "==================="
    echo "Location: $ZSHRC_CONFIG_DIR"
    echo "Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
    echo ""
    
    git status
}

# Aliases
alias zshbackup='backup'
alias zshsync='sync'
alias zshstatus='repo_status'

echo "✅ backup loaded"



