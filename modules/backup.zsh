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
    local branch=""
    
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

    branch="$(git branch --show-current 2>/dev/null || true)"
    if [[ -z "$branch" ]]; then
        echo "❌ Cannot determine current branch"
        return 1
    fi
    
    # Push current branch to main repo
    if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
        git push origin "$branch" && echo "✅ Pushed to main repo ($branch)"
    else
        git push --set-upstream origin "$branch" && echo "✅ Pushed to main repo ($branch)"
    fi
    
    # Push to backup repo if configured
    if git remote | grep -q backup; then
        git push backup "$branch" && echo "✅ Pushed to backup repo ($branch)"
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
alias zshsync='repo_sync'
alias zshstatus='repo_status'

echo "✅ backup loaded"

