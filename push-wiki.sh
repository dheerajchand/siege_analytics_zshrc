#!/bin/bash

# Script to push wiki content to GitHub wiki repository

set -e

echo "🚀 Pushing wiki content to GitHub wiki repository..."

# Create a temporary directory for wiki content
TEMP_DIR=$(mktemp -d)
echo "📁 Created temporary directory: $TEMP_DIR"

# Clone the wiki repository
cd "$TEMP_DIR"
git clone https://github.com/dheerajchand/siege_analytics_zshrc.wiki.git wiki-repo
cd wiki-repo

# Copy wiki files from the main repository
echo "📄 Copying wiki files..."
cp /Users/dheerajchand/.config/zsh/wiki/*.md .

# Add and commit the files
git add *.md
git commit -m "Add comprehensive wiki documentation

- Home.md: Main wiki index with navigation
- Bash-Compatibility.md: Cross-shell compatibility guide
- Functions-Dependencies.md: Function reference and dependencies
- Quick-Start.md: Quick start guide
- Repository-Management.md: Dual repository system guide
- System-Architecture.md: Technical architecture documentation
- Testing-Validation.md: Testing and validation procedures

All documentation is cross-referenced with Read the Docs documentation."

# Push to GitHub wiki
echo "🚀 Pushing to GitHub wiki..."
git push origin master

echo "✅ Wiki content successfully pushed to GitHub!"
echo "📖 View your wiki at: https://github.com/dheerajchand/siege_analytics_zshrc/wiki"

# Clean up
cd /Users/dheerajchand/.config/zsh
rm -rf "$TEMP_DIR"
echo "🧹 Cleaned up temporary files"
