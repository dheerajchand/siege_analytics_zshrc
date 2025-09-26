#!/bin/bash
# Create a new branch for terminal repair work

echo "🔧 Creating terminal repair branch..."

# Check current branch
current_branch=$(git branch --show-current)
echo "Current branch: $current_branch"

# Create and switch to new branch
git checkout -b terminal-tool-repair

echo "✅ Created and switched to 'terminal-tool-repair' branch"
echo "Ready to work on terminal tool compatibility fixes"




