#!/usr/bin/env bash

# =====================================================
# AUTO-COMMIT DEBUG SCRIPT
# =====================================================
# This script helps identify what might be triggering 
# automatic commits when changing directories
# =====================================================

echo "🔍 Auto-Commit Debug Test"
echo "========================="
echo ""

# Record initial state
INITIAL_COMMIT=$(git log --oneline -1)
INITIAL_FILES=$(git status --porcelain | wc -l | tr -d ' ')

echo "📊 Initial State:"
echo "  Last commit: $INITIAL_COMMIT"
echo "  Modified files: $INITIAL_FILES"
echo ""

# Test 1: Check current hooks
echo "🪝 Current Directory Change Hooks:"
if command -v zsh >/dev/null 2>&1; then
    zsh -c 'source ~/.config/zsh/zshrc >/dev/null 2>&1 && echo ${chpwd_functions[@]} 2>/dev/null || echo "No chpwd_functions"'
else
    echo "ZSH not available"
fi
echo ""

# Test 2: Check for git aliases or functions
echo "🔧 Git-Related Aliases/Functions:"
alias | grep -E "git|commit|push" || echo "No git aliases found"
echo ""

# Test 3: Simulate directory change
echo "🚶 Testing Directory Change..."
echo "Current directory: $(pwd)"

# Create temp directory and test cd
TEMP_DIR="/tmp/zsh-cd-test-$$"
mkdir -p "$TEMP_DIR"
echo "Created test directory: $TEMP_DIR"

# Test cd in subshell to avoid changing our working directory
echo "Testing cd in subshell..."
(
    cd "$TEMP_DIR" 2>/dev/null && echo "CD successful" || echo "CD failed"
    sleep 1
    cd - >/dev/null 2>&1
)

# Clean up
rm -rf "$TEMP_DIR"

# Test 4: Check if anything changed
FINAL_COMMIT=$(git log --oneline -1)
FINAL_FILES=$(git status --porcelain | wc -l | tr -d ' ')

echo ""
echo "📊 Final State:"
echo "  Last commit: $FINAL_COMMIT"
echo "  Modified files: $FINAL_FILES"

if [[ "$INITIAL_COMMIT" != "$FINAL_COMMIT" ]]; then
    echo "❌ COMMIT DETECTED! Something committed automatically."
    echo "   Initial: $INITIAL_COMMIT"
    echo "   Final:   $FINAL_COMMIT"
else
    echo "✅ No automatic commits detected"
fi

if [[ "$INITIAL_FILES" != "$FINAL_FILES" ]]; then
    echo "⚠️  File changes detected during test"
    echo "   Initial: $INITIAL_FILES files"
    echo "   Final:   $FINAL_FILES files"
fi

echo ""
echo "🔍 Recommendations:"
echo "1. Run this script in a new terminal after cd'ing to this directory"
echo "2. Watch for any output during the directory change"
echo "3. Check if your terminal app has any automation enabled"
echo "4. Look for any scripts in ~/.zshrc, ~/.bashrc, or terminal profiles"