# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Testing
```bash
# Run all tests
zsh run-tests.zsh

# Run specific test
zsh run-tests.zsh --test "test_name"

# Run with verbose output and coverage
zsh run-tests.zsh --verbose --coverage

# Run tests in parallel
zsh run-tests.zsh --parallel 4
```

### Configuration Setup
```bash
# Simple standalone setup (copies files to home directory)
./configure-shell.sh --mode standalone

# Setup with backup creation
./configure-shell.sh --mode standalone --backup

# Personal setup (symlinks to ~/.dotfiles/homedir)
./configure-shell.sh --personal

# One-time environment setup
./configure-shell.sh --mode standalone --setup-env

# Bash compatibility setup
./configure-shell.sh --mode standalone --shell bash
```

### Help System
```bash
# Main help overview
zsh_help

# Module-specific help
zsh_help spark
zsh_help python
zsh_help backup

# Search for functions
zsh_help search <term>

# List all functions
zsh_help list
```

### Repository Management
```bash
# Create backup with sync
backup "Your message"

# Check repository status
repostatus

# Quick sync of repositories
sync
```

## Architecture

### High-Level Structure
The system implements a modular architecture with three main layers:
- **Configuration Layer**: Main `.zshrc` file that orchestrates module loading
- **Module Layer**: Specialized modules for different functionality (spark.zsh, python.zsh, backup-system.zsh, etc.)
- **Repository Layer**: Dual repository system with main config and backup repositories

### Key Components
- **Core Module** (`core.zsh`): Basic shell functionality with no dependencies
- **Feature Modules**: Spark/Hadoop integration, Python tools, Docker utilities, Jupyter notebook helpers
- **System Modules**: Backup system, help module, testing framework
- **Bash Compatibility**: Cross-shell compatibility layer for bash users

### Module Dependencies
- Core modules have no dependencies and load first
- Feature modules depend on external tools (Java, Python, Docker, etc.)
- System modules depend on core functionality and Git
- Bash compatibility provides cross-shell function translations

### Testing Framework
The repository includes a comprehensive pytest-like testing framework for Zsh functions:
- Assertion functions (`assert_true`, `assert_equal`, `assert_contains`, etc.)
- Test discovery and execution
- Coverage reporting (planned)
- Parallel test execution
- CI/CD integration support

### Repository System
Uses a dual repository architecture:
- **Main Config Repository**: Active configuration files and modules
- **Backup Repository**: Historical backups with time-based organization
- Automatic synchronization between repositories
- Git-based version control with conflict resolution

### Documentation
- Comprehensive wiki documentation in `wiki/` directory
- Interactive help system accessible via `zsh_help` commands
- Function-level docstrings in Python format (converted to Zsh comments)
- Step-by-step setup guide in `IDIOT_LEVEL_GUIDE.md`

## Development Workflow

1. **Make Changes**: Edit configuration files or modules
2. **Test Changes**: Run `zsh run-tests.zsh` to verify functionality
3. **Create Backup**: Use `backup "description"` to save and sync changes
4. **Validate Setup**: Test with `./configure-shell.sh --mode standalone` on clean environment

## Key Features

- **SDKMAN-First Architecture**: All tools managed through SDKMAN for consistency
- **Cross-Platform Compatibility**: Works on macOS, Ubuntu, and RedHat systems
- **Interactive Help System**: Built-in documentation and function discovery
- **Automated Backup System**: Time-organized backups with metadata
- **Testing Framework**: Unit testing for shell functions
- **Dual Repository Sync**: Automatic synchronization and conflict resolution