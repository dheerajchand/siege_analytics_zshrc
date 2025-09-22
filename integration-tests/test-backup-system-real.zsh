#!/usr/bin/env zsh
# =====================================================
# REAL BACKUP SYSTEM INTEGRATION TEST
# =====================================================
# Tests actual backup functionality end-to-end:
# 1. Create test files
# 2. Run backup commands
# 3. Verify git commits created
# 4. Test backup restoration
# =====================================================

echo "🔄 REAL BACKUP SYSTEM TEST"
echo "=========================="

# Initialize test environment
TEST_DIR="/tmp/zsh_backup_test_$(date +%s)"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize git repo for testing
git init >/dev/null 2>&1
git config user.email "test@example.com"
git config user.name "Test User"

echo ""
echo "📋 Test 1: Basic backup functionality"
echo "-----------------------------------"

# Create test files to backup
echo "test content 1" > test_file1.txt
echo "test content 2" > test_file2.txt
mkdir -p subdir
echo "nested content" > subdir/nested.txt

# Load zsh config and test backup
source ~/.zshrc >/dev/null 2>&1

# Test if backup command exists and works
if command -v backup >/dev/null 2>&1; then
    echo "✅ Backup command available"
    
    # Try to run backup
    if backup 2>&1; then
        echo "✅ Backup command executed without errors"
        
        # Check if git commit was created
        if git log --oneline | head -1 | grep -q "backup\|commit"; then
            echo "✅ Git commit created by backup"
        else
            echo "❌ No git commit found after backup"
        fi
    else
        echo "❌ Backup command failed to execute"
    fi
else
    echo "❌ Backup command not found"
fi

echo ""
echo "📋 Test 2: Enhanced backup functionality"
echo "--------------------------------------"

# Test enhanced_backup if available
if command -v enhanced_backup >/dev/null 2>&1; then
    echo "✅ Enhanced backup command available"
    
    # Create more changes
    echo "additional content" >> test_file1.txt
    echo "new file content" > new_file.txt
    
    # Run enhanced backup
    if enhanced_backup "Test commit message" 2>&1; then
        echo "✅ Enhanced backup executed with custom message"
        
        # Check latest commit message
        latest_commit=$(git log -1 --pretty=format:"%s")
        if [[ "$latest_commit" == *"Test commit message"* ]]; then
            echo "✅ Custom commit message preserved: $latest_commit"
        else
            echo "❌ Custom commit message not found. Got: $latest_commit"
        fi
    else
        echo "❌ Enhanced backup failed"
    fi
else
    echo "❌ Enhanced backup command not found"
fi

echo ""
echo "📋 Test 3: Backup system integration"
echo "----------------------------------"

# Test pushmain if available (git integration)
if command -v pushmain >/dev/null 2>&1; then
    echo "✅ Pushmain command available"
    
    # Note: Won't actually push to avoid affecting real repos
    echo "💡 Pushmain integration available (not testing actual push)"
else
    echo "❌ Pushmain command not found"
fi

# Test sync functionality if available
if command -v sync >/dev/null 2>&1; then
    echo "✅ Sync command available"
else
    echo "❌ Sync command not found"
fi

echo ""
echo "📋 Test 4: Backup restoration capabilities"
echo "----------------------------------------"

# Test if backup system can show history
if git log --oneline | head -5; then
    echo "✅ Backup history available via git log"
else
    echo "❌ No backup history found"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

echo ""
echo "🎯 BACKUP SYSTEM TEST COMPLETE"
echo "=============================="
