#!/bin/bash
# =====================================================
# BASH COMPATIBILITY TEST SCRIPT
# Tests all functions in bash compatibility layer
# =====================================================

set -e

echo "=========================================="
echo "Bash Compatibility Test Suite"
echo "=========================================="

# Test shell detection
echo "Testing shell detection..."
if [ -n "$BASH_VERSION" ]; then
    echo "✓ Running in bash: $BASH_VERSION"
else
    echo "✗ Not running in bash"
    exit 1
fi

# Source the compatibility layer
echo "Sourcing bash compatibility layer..."
if [ -f "$HOME/.config/zsh/bash-compatibility.zsh" ]; then
    source "$HOME/.config/zsh/bash-compatibility.zsh"
    echo "✓ Compatibility layer loaded"
else
    echo "✗ Compatibility layer not found"
    exit 1
fi

# Test shell detection functions
echo ""
echo "Testing shell detection functions..."
echo "Current shell: $CURRENT_SHELL"
echo "Is ZSH: $IS_ZSH"
echo "Is Bash: $IS_BASH"
echo "Platform: $PLATFORM"

if [ "$CURRENT_SHELL" = "bash" ] && [ "$IS_BASH" = "true" ]; then
    echo "✓ Shell detection working correctly"
else
    echo "✗ Shell detection failed"
    exit 1
fi

# Test Python management functions
echo ""
echo "Testing Python management functions..."
echo "Testing setup_python_manager..."
setup_python_manager auto
echo "✓ setup_python_manager completed"

echo "Testing python_status..."
python_status
echo "✓ python_status completed"

# Test backup system
echo ""
echo "Testing backup system..."
echo "Testing backup function..."
# Create a temporary file for testing
echo "test content" > /tmp/test_backup_file.txt
backup "/tmp/test_backup_file.txt" "/tmp/test_backups"
rm -f /tmp/test_backup_file.txt
echo "✓ backup function completed"

# Test Spark integration
echo ""
echo "Testing Spark integration..."
echo "Testing setup_spark..."
setup_spark
echo "✓ setup_spark completed"

echo "Testing show_spark_config..."
show_spark_config
echo "✓ show_spark_config completed"

# Test performance optimization
echo ""
echo "Testing performance optimization..."
echo "Testing deduplicate_path..."
deduplicate_path
echo "✓ deduplicate_path completed"

echo "Testing optimize_shell..."
optimize_shell
echo "✓ optimize_shell completed"

# Test environment validation
echo ""
echo "Testing environment validation..."
echo "Testing validate_environment..."
validate_environment
echo "✓ validate_environment completed"

# Test help system
echo ""
echo "Testing help system..."
echo "Testing zsh_help all..."
zsh_help all
echo "✓ zsh_help all completed"

echo "Testing zsh_help python..."
zsh_help python
echo "✓ zsh_help python completed"

echo "Testing zsh_help backup..."
zsh_help backup
echo "✓ zsh_help backup completed"

echo "Testing zsh_help spark..."
zsh_help spark
echo "✓ zsh_help spark completed"

echo "Testing zsh_help performance..."
zsh_help performance
echo "✓ zsh_help performance completed"

echo "Testing zsh_help validation..."
zsh_help validation
echo "✓ zsh_help validation completed"

# Test compatibility test function
echo ""
echo "Testing compatibility test function..."
echo "Testing test_compatibility..."
test_compatibility
echo "✓ test_compatibility completed"

# Test environment variables
echo ""
echo "Testing environment variables..."
echo "ZSHRC_CONFIG_DIR: $ZSHRC_CONFIG_DIR"
echo "ZSHRC_BACKUPS: $ZSHRC_BACKUPS"
echo "PYTHON_MANAGER: $PYTHON_MANAGER"
echo "PATH_DEDUPLICATION_ENABLED: $PATH_DEDUPLICATION_ENABLED"
echo "SIEGE_COMPATIBILITY_INITIALIZED: $SIEGE_COMPATIBILITY_INITIALIZED"

# Test PATH handling
echo ""
echo "Testing PATH handling..."
echo "Original PATH length: $(echo "$PATH" | tr ':' '\n' | wc -l)"
deduplicate_path
echo "Optimized PATH length: $(echo "$PATH" | tr ':' '\n' | wc -l)"

# Test array handling (bash-specific)
echo ""
echo "Testing bash array handling..."
test_array=("item1" "item2" "item3")
echo "Array contents: ${test_array[*]}"
echo "Array length: ${#test_array[@]}"

# Test arithmetic operations
echo ""
echo "Testing arithmetic operations..."
test_num=5
test_num=$((test_num + 3))
echo "Arithmetic test: $test_num"

echo ""
echo "=========================================="
echo "All tests completed successfully!"
echo "Bash compatibility layer is working correctly"
echo "=========================================="
