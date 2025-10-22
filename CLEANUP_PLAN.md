# ZSH Configuration Cleanup Plan

## 📊 **Current State**
- **Total lines**: 21,434 lines across 113 files
- **Useful code**: ~1,420 lines (7%)
- **Bloat**: ~20,014 lines (93%)
- **Main culprit**: Security theater and hostile testing

---

## 🎯 **Goal**
Reduce to ~1,420 lines while keeping 100% of useful functionality:
- ✅ Python environment management (pyenv, UV)
- ✅ Spark cluster operations
- ✅ Docker helpers
- ✅ Database connections
- ✅ Credential management (1Password/Keychain)
- ✅ Git backup system

---

## 📋 **Cleanup Checklist**

### **Phase 1: Analysis Complete** ✅
- [x] Identify all functions
- [x] Categorize useful vs theater
- [x] Document mistakes
- [x] Create cleanup plan

### **Phase 2: Extract Useful Code**
- [ ] Create `modules/utils_clean.zsh` (50 lines)
- [ ] Create `modules/python_clean.zsh` (150 lines)
- [ ] Create `modules/spark_clean.zsh` (200 lines)
- [ ] Create `modules/docker_clean.zsh` (150 lines)
- [ ] Create `modules/database_clean.zsh` (200 lines)
- [ ] Create `modules/credentials_clean.zsh` (120 lines - simplified validation)
- [ ] Create `modules/backup_clean.zsh` (40 lines)
- [ ] Create `modules/hadoop_clean.zsh` (150 lines) - IF YOU USE IT

### **Phase 3: Create Clean zshrc**
- [ ] Write new zshrc (~60 lines)
- [ ] Load only clean modules
- [ ] Test basic functionality

### **Phase 4: Testing**
- [ ] Test Python environment switching
- [ ] Test Spark cluster start/stop
- [ ] Test docker_status and cleanup
- [ ] Test pg_connect
- [ ] Test credential get/store
- [ ] Test backup system

### **Phase 5: Backup & Replace**
- [ ] Backup current system: `cp -r ~/.config/zsh ~/.config/zsh.bloated.backup`
- [ ] Replace with clean version
- [ ] Test in real terminal
- [ ] Push clean version to main repo

### **Phase 6: Delete Bloat**
- [ ] Delete `tests/hostile-*` (12,508 lines)
- [ ] Delete security theater from zshrc
- [ ] Delete duplicate module system
- [ ] Delete help.zsh (746 lines)
- [ ] Delete iCloud functions
- [ ] Delete shell-compat.zsh (426 lines)
- [ ] Archive or delete docs/ directory (Sphinx)

---

## 🔍 **Questions to Answer**

Before cleanup, clarify:

1. **Do you use Hadoop locally?**
   - Yes → Keep simplified hadoop.zsh (~150 lines)
   - No → Delete entirely (save 623 lines)

2. **Do you use Rancher Desktop?**
   - Yes → Keep simple context switcher (~10 lines)
   - No → Remove Rancher support (save 100 lines)

3. **Do you use the iCloud diagnostic functions?**
   - Yes → Move to separate script
   - No → Delete (save 439 lines)

4. **Which database functions do you actually use?**
   - PostgreSQL only → Keep just pg_* functions
   - MySQL/Snowflake too → Keep all database functions

5. **Google Analytics credential functions?**
   - Use regularly → Keep ga_* functions
   - Rarely/never → Move to separate script

---

## 📁 **Clean Module Structure**

### **utils_clean.zsh** (~50 lines)
```zsh
is_online()              # ⭐ CRITICAL - Used by Spark
is_online_status()       # Helper
command_exists()         # Check if command exists
mkcd()                   # Create and cd
extract()                # Archive extraction
findtext()               # Text search
```

### **python_clean.zsh** (~150 lines)
```zsh
# Pyenv initialization
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Auto-activate default environment
pyenv activate geo31111

# Functions
py_env_switch()          # Switch environments
python_status()          # Show current environment
ds_project_init()        # Create project structure
use_uv()                 # Switch to UV
```

### **spark_clean.zsh** (~200 lines)
```zsh
spark_start()            # Start cluster
spark_stop()             # Stop cluster
spark_status()           # Show status
smart_spark_submit()     # Intelligent submission (uses is_online!)
get_spark_dependencies() # Deps based on connectivity
pyspark_shell()          # Interactive shell
spark_history_server()   # History server

# Consolidate submit modes into one function:
spark_submit_job() {
    local mode="${1:-auto}"  # auto|local|distributed|yarn
    local script="$2"
    # ... logic
}
```

### **docker_clean.zsh** (~150 lines)
```zsh
docker_status()          # System status
docker_cleanup()         # Remove stopped containers
docker_deep_clean()      # Aggressive cleanup
docker_shell()           # Shell into container
docker_logs()            # View logs
docker_restart_container() # Restart container

# Simplified context switching
switch_docker_context() {
    docker context use "${1:-docker-desktop}"
}
```

### **database_clean.zsh** (~200 lines)
```zsh
# PostgreSQL defaults
export PGHOST="localhost"
export PGUSER="dheerajchand"
export PGPORT="5432"
export PGDATABASE="postgres"

setup_postgres_credentials()  # Setup with prompts
pg_test_connection()          # Test connection
pg_connect()                  # Connect to database
psql_quick()                  # Quick session
database_status()             # Show connections

# MySQL/Snowflake if you use them
```

### **credentials_clean.zsh** (~120 lines)
```zsh
get_credential() {
    # Try 1Password
    if command -v op >/dev/null 2>&1; then
        op item get "$service-$user" --field="password" --reveal 2>/dev/null && return 0
    fi
    
    # Try Keychain
    if command -v security >/dev/null 2>&1; then
        security find-generic-password -s "$service-$user" -a "$user" -w 2>/dev/null && return 0
    fi
    
    # Fall back to environment
    case "$service" in
        "postgres") [[ -n "$PGPASSWORD" ]] && echo "$PGPASSWORD" && return 0 ;;
    esac
    
    return 1
}

store_credential() {
    # Store in 1Password
    op item create --category="Login" --title="$service-$user" ...
    
    # Store in Keychain as backup
    security add-generic-password -s "$service-$user" -a "$user" -w "$value"
}

# Google Analytics
ga_store_service_account()   # Store GA JSON
ga_get_service_account()     # Retrieve GA creds

# Aliases
alias creds-get='get_credential'
alias creds-store='store_credential'
```

**Key change**: Remove excessive validation (lines 34-190). Keep only basic null checks.

### **backup_clean.zsh** (~40 lines)
```zsh
backup() {
    # Commit and push to backup repo
    enhanced_backup "$@"
}

pushmain() {
    # Quick push to main repo
    push_main "$@"
}

sync() {
    # Sync both repos
    # ... logic
}

# Repository info
export ZSHRC_MAIN_REPO="https://github.com/dheerajchand/siege_analytics_zshrc"
export ZSHRC_BACKUP_REPO="https://github.com/dheerajchand/zshrc_backups"
```

### **zshrc_clean** (~60 lines)
```zsh
#!/usr/bin/env zsh

# Basic setup
export ZSH="$HOME/.dotfiles/oh-my-zsh"
export EDITOR="zed"
export VISUAL="$EDITOR"
export ZSH_CONFIG_DIR="$HOME/.config/zsh"

# PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Oh-My-Zsh
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)
autoload -Uz compinit && compinit
source $ZSH/oh-my-zsh.sh

# Load modules
source $ZSH_CONFIG_DIR/modules/utils_clean.zsh
source $ZSH_CONFIG_DIR/modules/python_clean.zsh
source $ZSH_CONFIG_DIR/modules/spark_clean.zsh
source $ZSH_CONFIG_DIR/modules/docker_clean.zsh
source $ZSH_CONFIG_DIR/modules/database_clean.zsh
source $ZSH_CONFIG_DIR/modules/credentials_clean.zsh
source $ZSH_CONFIG_DIR/modules/backup_clean.zsh

# Powerlevel10k config
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Basic aliases
alias help='echo "See ~/.config/zsh/README.md for documentation"'
alias modules='echo "Loaded: utils, python, spark, docker, database, credentials, backup"'

echo "✅ ZSH loaded - Type 'help' for documentation"
```

---

## 📊 **Expected Results**

### **Before**:
```
Total: 21,434 lines
Startup: Unknown (probably slow)
Maintainability: Impossible to find anything
```

### **After**:
```
Total: ~1,420 lines  
Startup: <100ms
Maintainability: Easy to understand and modify
```

### **Functions Lost**: 0 (zero)
All your actual workflows still work:
- ✅ Python environments
- ✅ Spark cluster
- ✅ Docker operations
- ✅ Database connections
- ✅ Credential storage
- ✅ Git backups

---

## ⚠️ **Safety Plan**

Before any changes:
```bash
# Full backup
cp -r ~/.config/zsh ~/.config/zsh.pre-cleanup.$(date +%Y%m%d)

# Also backup current zshrc
cp ~/.zshrc ~/.zshrc.pre-cleanup.$(date +%Y%m%d)
```

After cleanup, if anything breaks:
```bash
# Restore from backup
cp -r ~/.config/zsh.pre-cleanup.YYYYMMDD ~/.config/zsh
cp ~/.zshrc.pre-cleanup.YYYYMMDD ~/.zshrc
exec zsh
```

---

## 🚀 **Ready to Execute?**

Options:
1. **Gradual cleanup** - Remove security theater first, test, then simplify
2. **Fresh rebuild** - Extract useful functions, build clean from scratch
3. **Hybrid** - Keep current as backup, create parallel clean version

Which approach would you prefer?


