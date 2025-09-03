#!/usr/bin/env zsh

# =============================================================================
# Test Configuration and Setup
# =============================================================================

# Test environment setup
export TEST_MODE=true
export TEST_OUTPUT_DIR="./test-results"
export TEST_TEMP_DIR="/tmp/zsh_test_$$"

# Create test directories
mkdir -p "$TEST_OUTPUT_DIR"
mkdir -p "$TEST_TEMP_DIR"

# Test cleanup function
cleanup_test_environment() {
    if [[ -d "$TEST_TEMP_DIR" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Register cleanup on exit
trap cleanup_test_environment EXIT

# Test data setup
setup_test_data() {
    # Create test files
    echo "test content" > "$TEST_TEMP_DIR/test_file.txt"
    echo "another test" > "$TEST_TEMP_DIR/test_file2.txt"
    
    # Create test directory structure
    mkdir -p "$TEST_TEMP_DIR/subdir"
    echo "subdir content" > "$TEST_TEMP_DIR/subdir/test_file.txt"
}

# Test environment validation
validate_test_environment() {
    # Check that required tools are available
    command -v zsh >/dev/null 2>&1 || { echo "zsh is required for testing"; exit 1; }
    command -v git >/dev/null 2>&1 || { echo "git is required for testing"; exit 1; }
    
    # Check that test directories exist
    [[ -d "$TEST_OUTPUT_DIR" ]] || { echo "Test output directory not found"; exit 1; }
    [[ -d "$TEST_TEMP_DIR" ]] || { echo "Test temp directory not found"; exit 1; }
}

# Initialize test environment
init_test_environment() {
    validate_test_environment
    setup_test_data
    echo "Test environment initialized successfully"
}
