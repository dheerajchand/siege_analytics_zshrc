# Cross-User Portability Guide

## Overview

This ZSH configuration system has been designed for cross-user portability. However, there are certain configuration variables that users may want to customize for their environment.

## Quick Setup for New Users

### 1. Set Your Repository Information (Optional)

If you want to use your own GitHub repositories instead of the defaults:

```bash
# Add to your ~/.zshenv or shell profile BEFORE sourcing the ZSH config
export ZSH_REPO_OWNER="yourgithubusername"    # Defaults to $USER
export ZSH_REPO_NAME="your-zsh-repo"          # Defaults to siege_analytics_zshrc
export ZSH_BACKUP_REPO_NAME="your-backups"    # Defaults to zshrc_backups
```

### 2. Database Configuration

The system defaults to using your system username for database connections:

```bash
# PostgreSQL (defaults to $USER@localhost:5432/postgres)
export PGUSER="your-db-username"               # Defaults to $USER
export PGHOST="your-db-host"                   # Defaults to localhost
export PGDATABASE="your-db-name"               # Defaults to postgres

# MySQL (defaults to $USER@localhost:3306)
export MYSQL_USER="your-mysql-username"       # Defaults to $USER
export MYSQL_HOST="your-mysql-host"            # Defaults to localhost

# Snowflake
export SNOWFLAKE_USER="your-snowflake-user"   # Defaults to $USER
export SNOWFLAKE_ACCOUNT="your-account"       # Must be set by user
```

### 3. Python Environment

```bash
# Python environment preferences
export PREFERRED_VENV="your-preferred-env"    # Defaults to geo31111
export PYTHON_MANAGER="auto"                  # auto, pyenv, uv
```

## Implementation Details

### Dynamic Path Resolution

The system automatically detects:
- **Platform**: macOS (Intel/Apple Silicon), Linux
- **Homebrew Location**: `/opt/homebrew` (Apple Silicon) vs `/usr/local` (Intel)
- **Tool Locations**: SDKMAN, Python, Java, etc.

### User-Specific Defaults

Variables that default to `$USER`:
- `PGUSER` - PostgreSQL username
- `MYSQL_USER` - MySQL username
- `SNOWFLAKE_USER` - Snowflake username
- `ZSH_REPO_OWNER` - GitHub repository owner

### Testing Portability

Run the portability test to verify your setup:

```bash
cd ~/.config/zsh
./test-portability.zsh
```

## For Original User (dheerajchand)

If you are the original author and want to keep your specific settings:

```bash
# Keep your repository URLs
export ZSH_REPO_OWNER="dheerajchand"

# Keep your database username if different from system user
export PGUSER="dheerajchand"
export MYSQL_USER="dheerajchand"
export SNOWFLAKE_USER="dheerajchand"
```

Add these to your `~/.zshenv` or personal shell profile.

## Best Practices

1. **Environment Variables**: Use `~/.zshenv` for user-specific overrides
2. **System-wide**: The ZSH config should work out-of-the-box for any user
3. **Testing**: Always run `./test-portability.zsh` after major changes
4. **Documentation**: Keep this guide updated with any new configuration options

## Migration from Hardcoded Paths

For users upgrading from a version with hardcoded paths:

1. **Backup**: Your existing configuration is automatically backed up
2. **Review**: Check `~/.zshenv` for any hardcoded settings
3. **Update**: Remove hardcoded values and let the system use defaults
4. **Test**: Run the portability test to verify everything works

## Troubleshooting

### Repository URLs Still Hardcoded
- Check that you've sourced the new `variables.zsh`
- Verify environment variables in `~/.zshenv`
- Run `echo $ZSH_MAIN_REPO` to check current value

### Database Connection Issues
- Verify `echo $PGUSER` shows the correct username
- Check that database exists for the target user
- Use `pg_test` or `mysql_test` functions to verify connectivity

### Path Issues
- Run `echo $HOMEBREW_PREFIX` to verify platform detection
- Check `echo $SPARK_HOME_PATH` for tool locations
- Use `which <command>` to verify tool availability