# Idiot-Level Guide: Shell Configuration Script

## 🎯 What This Does (In Simple Terms)

This script helps you set up your shell configuration files (`.zshrc` and `.bashrc`) in different ways. Think of it as a smart installer that can:

1. **Copy files** to your home directory (like installing software)
2. **Create shortcuts** (symlinks) to files in other locations
3. **Set up everything automatically** with your preferred settings

## 🚀 Quick Start (Just Want It Working?)

### Option 1: Simple Setup (Recommended for Most People)
```bash
# Download and run the script
./configure-shell.sh --mode standalone
```
**What this does:** Copies the configuration files to your home directory. Works everywhere, no fancy stuff.

### Option 2: One-Time Setup (Set It and Forget It)
```bash
# Set up once with your preferences
./configure-shell.sh --mode standalone --setup-env

# Now you can just run this anytime:
./configure-shell.sh
```
**What this does:** Sets up your preferences once, then remembers them forever.

## 📋 Step-by-Step Instructions

### Step 1: Download the Repository
```bash
git clone https://github.com/dheerajchand/siege_analytics_zshrc.git
cd siege_analytics_zshrc
```

### Step 2: Make the Script Executable
```bash
chmod +x configure-shell.sh
```

### Step 3: Choose Your Setup Method

#### Method A: Simple Copy (Easiest)
```bash
./configure-shell.sh --mode standalone
```
- ✅ Works on any computer
- ✅ No dependencies on other files
- ✅ Simple and reliable

#### Method B: Smart Shortcuts (For Power Users)
```bash
./configure-shell.sh --mode symlink --target ~/.dotfiles/homedir
```
- ✅ Changes to source files update automatically
- ✅ Saves disk space
- ⚠️ Requires the target directory to exist

#### Method C: Set Up Once, Use Forever
```bash
# First time: Set up your preferences
./configure-shell.sh --mode standalone --setup-env

# Every time after: Just run this
./configure-shell.sh
```

### Step 4: Test Your Setup
```bash
# Reload your shell
source ~/.zshrc

# Test if it worked
zsh_help
```

## 🎛️ All the Options Explained (Like You're 5)

### `--mode` (How to Install)
- **`standalone`**: Copy files to your home directory (like installing an app)
- **`symlink`**: Create shortcuts to files elsewhere (like desktop shortcuts)
- **`copy`**: Same as standalone, but more explicit

### `--target` (Where to Put Shortcuts)
- Only needed for `symlink` mode
- Example: `--target ~/.dotfiles/homedir`
- The script can usually figure this out automatically

### `--shell` (Which Shell to Configure)
- **`zsh`**: Only configure Zsh
- **`bash`**: Only configure Bash  
- **`both`**: Configure both (default)

### `--backup` (Safety First)
- Creates a backup of your existing files
- Always recommended: `--backup`

### `--force` (Skip Confirmation)
- Overwrites files without asking
- Use with caution: `--force`

### `--setup-env` (Remember My Settings)
- Saves your preferences for future use
- Creates environment variables
- One-time setup: `--setup-env`

### `--personal` (Use the Author's Setup)
- Uses the same setup as the script author
- Symlinks to `~/.dotfiles/homedir`
- Quick setup: `--personal`

## 🔧 Common Scenarios

### "I Just Want It Working"
```bash
./configure-shell.sh --mode standalone --backup
```

### "I Want to Try Different Options"
```bash
# Try standalone first
./configure-shell.sh --mode standalone --backup

# If you don't like it, try symlink
./configure-shell.sh --mode symlink --target ~/.dotfiles/homedir --backup
```

### "I Want to Set It Up Once and Forget It"
```bash
# Set up your preferences
./configure-shell.sh --mode standalone --setup-env

# Now just run this anytime
./configure-shell.sh
```

### "I Want the Same Setup as the Author"
```bash
./configure-shell.sh --personal --backup
```

### "I Want to Override My Saved Settings"
```bash
# Use environment variables
SHELL_CONFIG_MODE=copy ./configure-shell.sh

# Or use command line options
./configure-shell.sh --mode copy
```

## 🚨 Troubleshooting (When Things Go Wrong)

### "Script says 'Permission denied'"
```bash
chmod +x configure-shell.sh
```

### "Script says 'File not found'"
```bash
# Make sure you're in the right directory
ls -la configure-shell.sh
```

### "Script says 'Invalid mode'"
```bash
# Use one of these modes:
./configure-shell.sh --mode standalone
./configure-shell.sh --mode copy
./configure-shell.sh --mode symlink
```

### "The script asks for confirmation and I'm confused"
```bash
# When the script asks [Y/n] or [y/N]:
# [Y/n] means: Press Enter for YES, or type 'n' for NO
# [y/N] means: Press Enter for NO, or type 'y' for YES

# Examples:
# "Proceed with shell configuration? [Y/n]" - Press Enter to proceed
# "Overwrite existing file? [y/N]" - Type 'y' to overwrite, Enter to skip
```

### "Script says 'Target path does not exist'"
```bash
# Create the directory first
mkdir -p ~/.dotfiles/homedir

# Or use a different target
./configure-shell.sh --mode symlink --target ~/.config/shell
```

### "My shell is broken after running the script"
```bash
# Restore from backup
cp ~/.zshrc.backup.YYYYMMDD_HHMMSS ~/.zshrc

# Or restore from repository
./configure-shell.sh --mode standalone --force
```

### "Environment variables aren't working"
```bash
# Reload your shell
source ~/.zshrc

# Or check if the file exists
ls -la ~/.shell-config-env
```

## 📚 What Happens Behind the Scenes

### When You Run `--mode standalone`
1. Script copies `zshrc` → `~/.zshrc`
2. Script copies `bash-compatibility.zsh` → `~/.bashrc`
3. Creates backups if `--backup` is used
4. Shows you what it did

### When You Run `--mode symlink`
1. Script creates `~/.zshrc` → points to target directory
2. Script creates `~/.bashrc` → points to target directory
3. Copies source files to target if they don't exist
4. Creates backups if `--backup` is used

### When You Run `--setup-env`
1. Script creates `~/.shell-config-env` with your preferences
2. Adds a line to your shell RC file to load these preferences
3. Next time you run the script, it uses these preferences

## 🎯 Quick Reference Card

### Most Common Commands
```bash
# Simple setup
./configure-shell.sh --mode standalone

# Set up once, use forever
./configure-shell.sh --mode standalone --setup-env

# Use author's setup
./configure-shell.sh --personal

# Safe setup with backup
./configure-shell.sh --mode standalone --backup

# Force overwrite
./configure-shell.sh --mode standalone --force
```

### Environment Variables (After `--setup-env`)
```bash
# These get set automatically:
SHELL_CONFIG_MODE=standalone
SHELL_CONFIG_TARGET=/path/to/target
SHELL_CONFIG_SHELL=both
SHELL_CONFIG_BACKUP=true
SHELL_CONFIG_FORCE=false
```

### File Locations
- **Script**: `configure-shell.sh`
- **Environment config**: `~/.shell-config-env`
- **Zsh config**: `~/.zshrc`
- **Bash config**: `~/.bashrc`
- **Backups**: `~/.zshrc.backup.YYYYMMDD_HHMMSS`

## 🆘 Getting Help

### Built-in Help
```bash
./configure-shell.sh --help
```

### Check What the Script Will Do
```bash
# Run without --force to see what it would do
./configure-shell.sh --mode standalone
# (It will ask for confirmation)
```

### Test the Script
```bash
# Test if the script works
./configure-shell.sh --help
```

## 🎉 Success Indicators

### You Know It Worked When:
- ✅ Script says "Shell configuration completed successfully!"
- ✅ You can run `zsh_help` and see help text
- ✅ Your shell loads without errors
- ✅ New functions are available (like `zshrc-status`)

### You Know It Didn't Work When:
- ❌ Script says "Configuration validation failed"
- ❌ Your shell shows errors when starting
- ❌ Commands like `zsh_help` don't work
- ❌ Files don't exist where they should

## 🔄 What to Do After Setup

### 1. Reload Your Shell
```bash
source ~/.zshrc
```

### 2. Test the Configuration
```bash
zsh_help
```

### 3. Check Sync Status (if available)
```bash
zshrc-status
```

### 4. Explore Available Functions
```bash
# See all available functions
zsh_help list

# Get help for specific modules
zsh_help backup
zsh_help spark
zsh_help python
```

## 💡 Pro Tips

### Tip 1: Always Use Backups
```bash
./configure-shell.sh --mode standalone --backup
```

### Tip 2: Set Up Environment Variables Once
```bash
./configure-shell.sh --mode standalone --setup-env
# Now you can just run: ./configure-shell.sh
```

### Tip 3: Use Personal Mode for Quick Setup
```bash
./configure-shell.sh --personal
```

### Tip 4: Test Before Committing
```bash
# Test what it would do first
./configure-shell.sh --mode standalone
# (Don't use --force, let it ask for confirmation)
```

### Tip 5: Keep Your Environment File
```bash
# Don't delete this file after setup
ls -la ~/.shell-config-env
```

## 🎯 Summary: The Three Ways to Use This

### 1. **Simple User** (Just Want It Working)
```bash
./configure-shell.sh --mode standalone --backup
```

### 2. **Power User** (Want to Customize)
```bash
./configure-shell.sh --mode standalone --setup-env
# Now: ./configure-shell.sh
```

### 3. **Author's Setup** (Want Same as Developer)
```bash
./configure-shell.sh --personal --backup
```

That's it! The script is designed to be simple but powerful. Start with the simple approach, and as you get comfortable, you can explore the more advanced options.
