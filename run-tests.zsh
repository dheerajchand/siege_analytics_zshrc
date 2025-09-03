#!/usr/bin/env zsh

# =============================================================================
# ZSH Test Runner - Comprehensive Testing Suite
# =============================================================================

# Colors for output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_WHITE='\033[1;37m'
readonly COLOR_RESET='\033[0m'

# Test configuration
TEST_VERBOSE=false
TEST_COVERAGE=false
TEST_PARALLEL=1
TEST_PATTERN=""
TEST_OUTPUT_DIR="./test-results"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            TEST_VERBOSE=true
            shift
            ;;
        --coverage|-c)
            TEST_COVERAGE=true
            shift
            ;;
        --parallel|-p)
            TEST_PARALLEL="$2"
            shift 2
            ;;
        --test|-t)
            TEST_PATTERN="$2"
            shift 2
            ;;
        --output|-o)
            TEST_OUTPUT_DIR="$2"
            shift 2
            ;;
        --help|-h)
            cat << EOF
ZSH Test Runner

Usage: zsh run-tests.zsh [OPTIONS]

Options:
  -v, --verbose     Verbose output
  -c, --coverage    Enable coverage reporting
  -p, --parallel N  Run N tests in parallel
  -t, --test NAME   Run specific test
  -o, --output DIR  Output directory for results
  -h, --help        Show this help

Examples:
  zsh run-tests.zsh
  zsh run-tests.zsh --verbose --coverage
  zsh run-tests.zsh --test "test_python_status"
  zsh run-tests.zsh --parallel 4
EOF
            exit 0
            ;;
        *)
            echo "${COLOR_RED}Unknown option: $1${COLOR_RESET}"
            exit 1
            ;;
    esac
done

# Create output directory
mkdir -p "$TEST_OUTPUT_DIR"

echo "${COLOR_CYAN}🧪 ZSH Testing Suite${COLOR_RESET}"
echo "${COLOR_CYAN}====================${COLOR_RESET}"
echo ""

# Run the test framework
zsh test-framework.zsh --verbose="$TEST_VERBOSE" --coverage="$TEST_COVERAGE" --parallel="$TEST_PARALLEL" --test="$TEST_PATTERN" --output="$TEST_OUTPUT_DIR"
