#!/bin/bash

# =====================================================
# REPOSITORY SYNC SCRIPT
# =====================================================
# Syncs the active development repo with the archive repo
# Ensures both repositories stay consistent
# =====================================================

set -e

echo "🔄 Syncing repositories..."

# Load centralized configuration
source "$HOME/.config/zsh/zshrc" 2>/dev/null || {
    # Fallback to hardcoded paths if config unavailable
    export ZSH_ACTIVE_REPO="$HOME/.config/zsh"
    export ZSH_ARCHIVE_REPO="$HOME/.zshrc_backups"
}

# Use centralized repository paths
ACTIVE_REPO="$ZSH_ACTIVE_REPO"
ARCHIVE_REPO="$ZSH_ARCHIVE_REPO"

# Check if both repos exist
if [[ ! -d "$ACTIVE_REPO/.git" ]]; then
    echo "❌ Active repo not found at $ACTIVE_REPO"
    exit 1
fi

if [[ ! -d "$ARCHIVE_REPO/.git" ]]; then
    echo "❌ Archive repo not found at $ARCHIVE_REPO"
    exit 1
fi

# Copy from active to archive
echo "📂 Copying files from active to archive repo..."
cd "$ACTIVE_REPO"
cp -r * "$ARCHIVE_REPO/" 2>/dev/null || true

# Commit and push archive
echo "📦 Committing changes to archive repo..."
cd "$ARCHIVE_REPO"

if [[ -n "$(git status --porcelain)" ]]; then
    git add .
    git commit -m "sync: update archive from active development repo

Automated sync from active repository at $(date)
Branch: $(cd "$ACTIVE_REPO" && git branch --show-current)
Last commit: $(cd "$ACTIVE_REPO" && git log -1 --format="%h %s")"
    
    echo "🚀 Pushing to archive repository..."
    git push origin main
    
    echo "✅ Sync completed successfully"
    echo "📊 Archive repo updated with latest changes"
else
    echo "✅ Archive repo already up to date"
fi

echo ""
echo "📍 Repository Status:"
echo "  Active:  $(cd "$ACTIVE_REPO" && git branch --show-current) - $(cd "$ACTIVE_REPO" && git log -1 --format="%h %s")"
echo "  Archive: $(cd "$ARCHIVE_REPO" && git branch --show-current) - $(cd "$ARCHIVE_REPO" && git log -1 --format="%h %s")"
