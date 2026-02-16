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

_backup_cd_repo() {
    cd "$ZSHRC_CONFIG_DIR" || {
        echo "❌ Cannot cd to $ZSHRC_CONFIG_DIR"
        return 1
    }
    if [[ ! -d .git ]]; then
        echo "❌ Not a git repository"
        return 1
    fi
    return 0
}

_backup_current_branch() {
    git branch --show-current 2>/dev/null || true
}

# Main backup function
backup() {
    local message="${1:-Config update}"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local branch=""
    _backup_cd_repo || return 1
    
    echo "📦 Creating backup..."
    
    # Add all changes
    git add -A
    
    # Commit
    git commit -m "[$timestamp] $message" || {
        echo "⚠️  No changes to commit"
        return 0
    }

    branch="$(_backup_current_branch)"
    if [[ -z "$branch" ]]; then
        echo "❌ Cannot determine current branch"
        return 1
    fi
    if [[ "$branch" == "main" ]]; then
        echo "⚠️  You are committing directly on main. Recommended workflow is branch -> push -> merge."
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

# Merge a branch into main and push
backup_merge_main() {
    local source_branch="${1:-}"
    local start_branch=""
    local merged=0

    _backup_cd_repo || return 1

    start_branch="$(_backup_current_branch)"
    [[ -z "$start_branch" ]] && { echo "❌ Cannot determine current branch"; return 1; }
    [[ -z "$source_branch" ]] && source_branch="$start_branch"

    if [[ -n "$(git status --porcelain)" ]]; then
        echo "❌ Working tree is not clean. Commit/stash changes before merge."
        return 1
    fi
    if ! git show-ref --verify --quiet "refs/heads/$source_branch"; then
        echo "❌ Branch not found: $source_branch"
        return 1
    fi

    echo "🔀 Merging $source_branch -> main"
    git fetch origin --prune || return 1

    if [[ "$source_branch" == "main" ]]; then
        git pull --ff-only origin main || return 1
        git push origin main || return 1
        if git remote | grep -q backup; then
            git push backup main || return 1
        fi
        echo "✅ main pushed"
        return 0
    fi

    if [[ "$start_branch" != "main" ]]; then
        git checkout main || return 1
    fi
    git pull --ff-only origin main || {
        [[ "$start_branch" != "main" ]] && git checkout "$start_branch" >/dev/null 2>&1 || true
        return 1
    }
    git merge --no-ff "$source_branch" -m "Merge branch '$source_branch'" || {
        echo "❌ Merge failed. Resolve conflicts and complete merge manually."
        return 1
    }
    merged=1
    git push origin main || return 1
    if git remote | grep -q backup; then
        git push backup main || return 1
    fi
    [[ "$start_branch" != "main" ]] && git checkout "$start_branch" >/dev/null 2>&1 || true
    [[ "$merged" -eq 1 ]] && echo "✅ Merged and pushed: $source_branch -> main"
}

# Quick push + merge to main
pushmain() {
    local message="${1:-Quick update}"
    backup "$message" || return 1
    backup_merge_main
}

# Sync repository (renamed to avoid conflict with sync command)
repo_sync() {
    _backup_cd_repo || return 1
    
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
alias zshmerge='backup_merge_main'

echo "✅ backup loaded"
