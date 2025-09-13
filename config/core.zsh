#!/usr/bin/env zsh

# =====================================================
# CORE SHELL CONFIGURATION
# =====================================================
# 
# Essential shell settings, aliases, and basic functionality
# This module contains the fundamental configuration that should
# load first and is required by other modules
# =====================================================

# =====================================================
# SHELL OPTIONS & BEHAVIOR
# =====================================================

# Disable auto-correction (can be annoying with technical terms)
unsetopt correct

# Apply centralized shell configuration
# Note: CASE_SENSITIVE, DISABLE_AUTO_TITLE are defined in main zshrc
if [[ "$CASE_SENSITIVE" == "true" ]]; then
    # Apply case-sensitive completion settings
    zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'
fi

# =====================================================
# EDITOR CONFIGURATION
# =====================================================
# Note: EDITOR and VISUAL are defined in main zshrc centralized section

# Terminal editor aliases (nvim as fallback)
alias vim="nvim"
alias edit="nvim"

# Open config directory shortcut using centralized EDITOR
edit-config() {
    local editor="${VISUAL:-${EDITOR:-zed}}"
    $editor "$ZSH_CONFIG_DIR"
}

# =====================================================
# BASIC SYSTEM CONFIGURATION
# =====================================================

# macOS-specific settings (only set if needed)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Enable diacritical marks (ä, ö, ü, etc.) instead of key repeat
    if [[ "$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null)" != "1" ]]; then
        defaults write -g ApplePressAndHoldEnabled -bool true
    fi
    
    # Note: WORKING_ON_LAPTOP is now defined in main zshrc centralized section
fi

# =====================================================
# ZSH COMPLETION SYSTEM SETUP
# =====================================================

# Load required completion modules early (before oh-my-zsh compinit)
zmodload -i zsh/computil 2>/dev/null
zmodload -i zsh/complete 2>/dev/null
zmodload -i zsh/complist 2>/dev/null

# =====================================================
# CORE ALIASES
# =====================================================

# Shell management
# Unset any existing alias before defining function
unalias zshreboot 2>/dev/null
zshreboot() {
    # Restart zsh shell completely (clears cached functions and reloads config)
    echo "🔄 Restarting zsh shell..."
    exec zsh
}
# Enhanced zshconfig function - opens entire config directory
function zshconfig() {
    local editor="${VISUAL:-${EDITOR:-zed}}"
    echo "Opening ZSH configuration directory with $editor..."
    "$editor" ~/.config/zsh
}

# Directory navigation shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# ls enhancements
alias ll='ls -alF'
alias la='ls -A' 
alias l='ls -CF'

# Git shortcuts (basic)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# =====================================================
# UTILITY FUNCTIONS
# =====================================================

is_online() {
    # Check if internet connection is available
    #
    # Returns:
    #     0: Online
    #     1: Offline
    #
    # Examples:
    #     if is_online; then echo "Connected"; fi
    #     [[ "$(is_online_status)" == "online" ]] && do_something
    ping -c 1 google.com &> /dev/null
}

is_online_status() {
    # Get online status as string
    #
    # Returns:
    #     str: "online" or "offline"
    if is_online; then
        echo "online"
    else
        echo "offline"
    fi
}

command_exists() {
    # Check if a command exists
    #
    # Args:
    #     command (str): Command to check
    #
    # Returns:
    #     0: Command exists
    #     1: Command not found
    #
    # Examples:
    #     command_exists git && echo "Git is available"
    #     if command_exists python3; then python3 --version; fi
    command -v "$1" >/dev/null 2>&1
}

path_add() {
    # Add directory to PATH if not already present
    #
    # Args:
    #     path (str): Directory to add to PATH
    #     position (str, optional): "prepend" or "append" (default: prepend)
    #
    # Examples:
    #     path_add "/usr/local/bin"
    #     path_add "/opt/local/bin" "append"
    local new_path="$1"
    local position="${2:-prepend}"
    
    if [[ -d "$new_path" && ":$PATH:" != *":$new_path:"* ]]; then
        case "$position" in
            "prepend")
                export PATH="$new_path:$PATH"
                ;;
            "append")
                export PATH="$PATH:$new_path"
                ;;
        esac
    fi
}

mkcd() {
    # Create directory and cd into it
    #
    # Args:
    #     directory (str): Directory name to create
    #
    # Examples:
    #     mkcd new_project
    #     mkcd ~/projects/my_app
    mkdir -p "$1" && cd "$1"
}

extract() {
    # Universal extraction function
    #
    # Args:
    #     file (str): Archive file to extract
    #
    # Examples:
    #     extract archive.tar.gz
    #     extract package.zip
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "Don't know how to extract '$1'" ;;
        esac
    else
        echo "File '$1' not found"
    fi
}

findtext() {
    # Search for text in files recursively
    #
    # Args:
    #     text (str): Text to search for
    #     path (str, optional): Path to search in (default: current directory)
    #
    # Examples:
    #     findtext "TODO"
    #     findtext "function.*python" ~/projects
    local text="$1"
    local path="${2:-.}"

    if command_exists rg; then
        rg "$text" "$path"
    elif command_exists ag; then
        ag "$text" "$path"
    else
        grep -r "$text" "$path"
    fi
}

restart_finder() {
    # Restart Finder to resolve file dialog and browsing issues
    #
    # This function is useful when experiencing:
    #   - Slow file dialogs in applications
    #   - File browser navigation issues
    #   - Stale file system caches
    #   - Problems with file creation/saving dialogs
    #
    # Examples:
    #     restart_finder
    #     restart_finder && echo "Finder restarted successfully"
    echo "🔄 Restarting Finder..."
    killall Finder 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ Finder restarted successfully"
        echo "💡 This should resolve file dialog and navigation issues"
    else
        echo "⚠️  Finder may not have been running, but it will start automatically"
    fi
}

# =====================================================
# PERFORMANCE HELPERS
# =====================================================

reload_shell() {
    # Reload shell configuration
    echo "🔄 Reloading shell configuration..."
    source ~/.zshrc
    echo "✅ Shell configuration reloaded"
}

shell_startup_time() {
    # Measure shell startup time
    #
    # Examples:
    #     shell_startup_time
    #     shell_startup_time 5  # Run 5 times and average
    local iterations="${1:-3}"
    echo "🕐 Measuring shell startup time ($iterations iterations)..."
    
    local total_time=0
    for i in $(seq 1 $iterations); do
        local start_time=$(date +%s.%N)
        zsh -i -c exit
        local end_time=$(date +%s.%N)
        local iteration_time=$(echo "$end_time - $start_time" | bc)
        echo "  Iteration $i: ${iteration_time}s"
        total_time=$(echo "$total_time + $iteration_time" | bc)
    done
    
    local average_time=$(echo "scale=3; $total_time / $iterations" | bc)
    echo "📊 Average startup time: ${average_time}s"
}

# =====================================================
# SYSTEM INFORMATION
# =====================================================

system_info() {
    # Display system information
    echo "🖥️  System Information"
    echo "===================="
    echo "OS: $OSTYPE"
    echo "Shell: $SHELL"
    echo "User: $USER"
    echo "Home: $HOME"
    echo "Hostname: $(hostname)"
    
    if command_exists uname; then
        echo "Kernel: $(uname -r)"
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS Version: $(sw_vers -productVersion)"
    fi
    
    echo ""
    echo "Shell Configuration:"
    echo "Editor: $EDITOR"
    echo "Working on laptop: ${WORKING_ON_LAPTOP:-No}"
    echo "Case sensitive: ${CASE_SENSITIVE:-No}"
    echo "Auto title: ${DISABLE_AUTO_TITLE:-Enabled}"
}

# =====================================================
# PYTHON/UV ENVIRONMENT HELPERS
# =====================================================

py_env_switch() {
    # Quick switch between Python environments
    #
    # Usage:
    #   py_env_switch list           # List all environments
    #   py_env_switch myenv          # Switch to pyenv environment
    #   py_env_switch uv             # Use UV in current directory
    local target="${1:-list}"
    
    case "$target" in
        "list"|"-l"|"--list")
            echo "🐍 Available Python Environments:"
            echo ""
            echo "📦 Pyenv Environments:"
            if command_exists pyenv; then
                pyenv versions | sed 's/^/  /'
            else
                echo "  ❌ Pyenv not installed"
            fi
            echo ""
            echo "⚡ UV Projects:"
            if [[ -f "pyproject.toml" ]]; then
                echo "  ✅ Current directory has UV project"
            else
                echo "  ❌ No UV project in current directory"
            fi
            echo ""
            echo "Usage:"
            echo "  py_env_switch <env_name>    # Switch to pyenv environment"
            echo "  py_env_switch uv            # Activate UV project here"
            ;;
        "uv")
            if [[ -f "pyproject.toml" ]]; then
                if [[ -d ".venv" ]]; then
                    echo "⚡ Activating UV project: $(basename $PWD)"
                    source .venv/bin/activate
                else
                    echo "🔨 Setting up UV project..."
                    uv sync && source .venv/bin/activate
                fi
            else
                echo "❌ No pyproject.toml found. Run 'uv init' to create a UV project."
            fi
            ;;
        *)
            if command_exists pyenv; then
                echo "🐍 Switching to pyenv environment: $target"
                pyenv activate "$target" 2>/dev/null || {
                    echo "❌ Environment '$target' not found. Available:"
                    pyenv versions
                }
            else
                echo "❌ Pyenv not available"
            fi
            ;;
    esac
}

ds_project_init() {
    # Initialize a data science project with UV
    #
    # Usage:
    #   ds_project_init myproject        # Basic data science project
    #   ds_project_init myproject spark  # With Spark dependencies
    local project_name="$1"
    local project_type="${2:-basic}"
    
    if [[ -z "$project_name" ]]; then
        echo "Usage: ds_project_init <project_name> [basic|spark|geo]"
        return 1
    fi
    
    echo "🔬 Creating data science project: $project_name"
    mkdir -p "$project_name" && cd "$project_name"
    
    # Initialize UV project
    uv init --name "$project_name" --python 3.11
    
    # Add common data science dependencies
    echo "📦 Adding data science dependencies..."
    uv add pandas numpy matplotlib seaborn jupyter ipykernel
    
    case "$project_type" in
        "spark")
            echo "⚡ Adding Spark dependencies..."
            uv add pyspark findspark
            ;;
        "geo")
            echo "🌍 Adding geospatial dependencies..."
            uv add geopandas folium contextily
            ;;
    esac
    
    # Create project structure
    mkdir -p {notebooks,data/{raw,processed},src,tests}
    
    echo "✅ Data science project '$project_name' created!"
    echo "🚀 Next steps:"
    echo "  source .venv/bin/activate"
    echo "  jupyter lab"
}

python_info() {
    # Show Python environment information
    echo "🐍 Python Environment Status"
    echo "============================"
    echo ""
    
    echo "Current Python:"
    echo "  Version: $(python --version 2>&1)"
    echo "  Location: $(which python)"
    echo "  Virtual Env: ${VIRTUAL_ENV:-'None'}"
    
    if command_exists pyenv; then
        echo "  Pyenv: $(pyenv version | cut -d' ' -f1)"
    fi
    
    if command_exists uv; then
        echo "  UV: $(uv --version)"
    fi
    
    echo ""
    if [[ -f "pyproject.toml" ]]; then
        echo "📦 Current Project:"
        echo "  UV Project: ✅ $(basename $PWD)"
        if [[ -d ".venv" ]]; then
            echo "  Virtual Env: ✅ Ready"
        else
            echo "  Virtual Env: ❌ Run 'uv sync'"
        fi
    else
        echo "📦 No UV project in current directory"
    fi
}

# =====================================================
# MODULE LOADING HELPERS
# =====================================================

load_module() {
    # Load a configuration module if it exists
    #
    # Args:
    #     module_name (str): Name of the module (without .zsh extension)
    #
    # Returns:
    #     0: Module loaded successfully
    #     1: Module not found or failed to load
    #
    # Examples:
    #     load_module "database"
    #     load_module "jetbrains"
    local module_name="$1"
    local module_path="$HOME/.config/zsh/config/${module_name}.zsh"
    
    if [[ -f "$module_path" ]]; then
        source "$module_path"
        echo "✅ Loaded module: $module_name"
        return 0
    else
        echo "⚠️  Module not found: $module_name ($module_path)"
        return 1
    fi
}

list_modules() {
    # List available configuration modules
    echo "📦 Available Configuration Modules:"
    echo ""
    
    local config_dir="$HOME/.config/zsh/config"
    if [[ -d "$config_dir" ]]; then
        for module in "$config_dir"/*.zsh; do
            if [[ -f "$module" ]]; then
                local module_name=$(basename "$module" .zsh)
                echo "  📄 $module_name"
                
                # Try to extract description from module file
                local description=$(grep -m 1 "^# .*" "$module" | sed 's/^# //' | head -1)
                if [[ -n "$description" && "$description" != "#!/usr/bin/env zsh" ]]; then
                    echo "     💡 $description"
                fi
            fi
        done
    else
        echo "  ❌ Config directory not found: $config_dir"
    fi
}

# =====================================================
# INITIALIZATION
# =====================================================

# Core module loaded indicator
export CORE_MODULE_LOADED=true

# Ensure basic directories exist
mkdir -p "$HOME/.config/zsh/config"
mkdir -p "$HOME/.config/zsh/functions"

# Set up basic PATH additions (if directories exist)
path_add "/usr/local/bin"
path_add "/opt/homebrew/bin"
path_add "$HOME/.local/bin"
path_add "$HOME/.jetbrains/bin"

# Load hook system
autoload -U add-zsh-hook

# =====================================================
# ALIASES FOR DATA SCIENCE WORKFLOW
# =====================================================

# Python environment aliases
alias py-switch='py_env_switch'
alias py-list='py_env_switch list'
alias py-info='python_info'
alias py-uv='py_env_switch uv'

# Data science project aliases
alias ds-init='ds_project_init'
alias ds-basic='ds_project_init'
alias ds-spark='ds_project_init'
alias ds-geo='ds_project_init'

# UV aliases
alias uv-init='uv init'
alias uv-add='uv add'
alias uv-sync='uv sync'
alias uv-run='uv run'

# =====================================================
# REPOSITORY PATH FUNCTIONS
# =====================================================

repo_paths() {
    # Display repository paths for the dual repository system
    #
    # Usage:
    #   repo_paths                    # Show all repository paths
    #   repo_paths active             # Show active repo path only
    #   repo_paths archive            # Show archive repo path only
    #
    # Examples:
    #   repo_paths                    # Display all paths
    #   cd "$(repo_paths active)"     # Navigate to active repo
    #   ls -la "$(repo_paths archive)" # List archive repo contents
    
    local target="${1:-all}"
    
    case "$target" in
        "active"|"dev"|"development")
            echo "$ZSH_ACTIVE_REPO"
            ;;
        "archive"|"backup")
            echo "$ZSH_ARCHIVE_REPO"
            ;;
        "all"|"")
            echo "🏠 Repository Paths:"
            echo "  📝 Active (Development): $ZSH_ACTIVE_REPO"
            echo "  📦 Archive (Backup):     $ZSH_ARCHIVE_REPO"
            echo ""
            echo "💡 Usage:"
            echo "  cd \"\$(repo_paths active)\"   # Navigate to active repo"
            echo "  cd \"\$(repo_paths archive)\"  # Navigate to archive repo"
            ;;
        *)
            echo "❌ Invalid option: $target"
            echo "Usage: repo_paths [active|archive|all]"
            return 1
            ;;
    esac
}

repo_status() {
    # Show detailed repository status for both active and archive repos
    #
    # Usage:
    #   repo_status                   # Show status of both repositories
    #
    # Returns:
    #   Comprehensive status including git info, file counts, etc.
    
    echo "📊 Dual Repository System Status"
    echo "================================="
    echo ""
    
    # Active Repository
    echo "📝 Active Repository (Development):"
    echo "   Path: $ZSH_ACTIVE_REPO"
    if [[ -d "$ZSH_ACTIVE_REPO/.git" ]]; then
        cd "$ZSH_ACTIVE_REPO"
        echo "   Status: ✅ Git repository"
        echo "   Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
        echo "   Last Commit: $(git log -1 --format='%h %s' 2>/dev/null || echo 'unknown')"
        echo "   Remote: $(git remote get-url origin 2>/dev/null || echo 'none')"
        local file_count=$(find . -name "*.zsh" -o -name "*.sh" -o -name "*.md" | wc -l | tr -d ' ')
        echo "   Files: $file_count configuration files"
    else
        echo "   Status: ❌ Not a git repository"
    fi
    
    echo ""
    
    # Archive Repository  
    echo "📦 Archive Repository (Backup):"
    echo "   Path: $ZSH_ARCHIVE_REPO"
    if [[ -d "$ZSH_ARCHIVE_REPO/.git" ]]; then
        cd "$ZSH_ARCHIVE_REPO"
        echo "   Status: ✅ Git repository"
        echo "   Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')"
        echo "   Last Commit: $(git log -1 --format='%h %s' 2>/dev/null || echo 'unknown')"
        echo "   Remote: $(git remote get-url origin 2>/dev/null || echo 'none')"
        local backup_count=$(find . -name "config_*" -type d 2>/dev/null | wc -l | tr -d ' ')
        echo "   Backups: $backup_count timestamped backups"
    elif [[ -d "$ZSH_ARCHIVE_REPO" ]]; then
        echo "   Status: ⚠️  Directory exists but not a git repository"
    else
        echo "   Status: ❌ Directory not found"
    fi
    
    echo ""
    echo "🔄 Sync Status:"
    if [[ -d "$ZSH_ACTIVE_REPO/.git" && -d "$ZSH_ARCHIVE_REPO/.git" ]]; then
        local active_commit=$(cd "$ZSH_ACTIVE_REPO" && git rev-parse HEAD 2>/dev/null)
        local archive_commit=$(cd "$ZSH_ARCHIVE_REPO" && git rev-parse HEAD 2>/dev/null)
        
        if [[ "$active_commit" == "$archive_commit" ]]; then
            echo "   ✅ Repositories are synchronized"
        else
            echo "   ⚠️  Repositories are out of sync"
            echo "   💡 Run: ./sync-repos.sh to synchronize"
        fi
    else
        echo "   ❓ Cannot determine sync status"
    fi
}

# Convenience aliases for repository navigation
alias repo-active='cd "$ZSH_ACTIVE_REPO"'
alias repo-archive='cd "$ZSH_ARCHIVE_REPO"'
alias repo-dev='cd "$ZSH_ACTIVE_REPO"'
alias repo-backup='cd "$ZSH_ARCHIVE_REPO"'

# =====================================================
# ICLOUD DIAGNOSTICS & CLEANUP FUNCTIONS
# =====================================================

icloud_diagnose() {
    # Diagnose iCloud sync issues and identify problematic containers
    #
    # This function identifies containers that are:
    #   - Stuck in sync loops (high CPU usage)
    #   - Blocked due to uninstalled apps
    #   - Failed sync operations
    #   - Consuming excessive system resources
    #
    # Usage:
    #     icloud_diagnose                # Full diagnostic report
    #     icloud_diagnose --cpu          # Focus on CPU-intensive containers
    #     icloud_diagnose --blocked      # Show only blocked containers
    #
    # Examples:
    #     icloud_diagnose
    #     icloud_diagnose --blocked | grep uninstalled

    local focus_mode="${1:-all}"

    echo "🔍 iCloud Drive Diagnostic Report"
    echo "================================="
    echo ""

    # Check fileproviderd CPU usage
    echo "📊 File Provider Daemon Status:"
    local fpd_cpu=$(ps aux | grep fileproviderd | grep -v grep | awk '{print $3}' | head -1)
    if [[ -n "$fpd_cpu" ]]; then
        echo "   CPU Usage: ${fpd_cpu}%"
        if (( $(echo "$fpd_cpu > 50" | bc -l 2>/dev/null || echo 0) )); then
            echo "   ⚠️  HIGH CPU USAGE - Investigating sync issues..."
        elif (( $(echo "$fpd_cpu > 10" | bc -l 2>/dev/null || echo 0) )); then
            echo "   ⚡ Moderate activity"
        else
            echo "   ✅ Normal operation"
        fi
    else
        echo "   ❓ fileproviderd not running"
    fi
    echo ""

    # Analyze container sync status
    echo "📦 Container Sync Analysis:"

    case "$focus_mode" in
        "--cpu"|"--performance")
            echo "   🔍 Focusing on performance issues..."
            brctl status 2>/dev/null | grep -E "(blocked|error|failed|needs-sync)" | head -10
            ;;
        "--blocked")
            echo "   🔍 Showing blocked containers..."
            brctl status 2>/dev/null | grep -E "blocked-app-uninstalled" | head -10
            ;;
        *)
            echo "   📋 Full container status (showing issues only):"
            brctl status 2>/dev/null | grep -E "(blocked|error|failed|needs-sync|uninstalled)" | head -15
            ;;
    esac

    echo ""
    echo "🔧 Quick Actions Available:"
    echo "   icloud_cleanup                 # Interactive cleanup of problematic containers"
    echo "   icloud_cleanup --uninstalled   # Remove all uninstalled app containers"
    echo "   icloud_cleanup --force <name>  # Force remove specific container"
    echo ""
    echo "💡 If fileproviderd CPU > 50%, run icloud_cleanup to resolve sync issues"
}

icloud_cleanup() {
    # Clean up problematic iCloud containers that cause system performance issues
    #
    # This function can:
    #   - Remove containers for uninstalled apps
    #   - Disable sync for problematic containers
    #   - Force remove specific containers causing issues
    #
    # Usage:
    #     icloud_cleanup                    # Interactive mode - shows options
    #     icloud_cleanup --uninstalled     # Remove all uninstalled app containers
    #     icloud_cleanup --disable <name>  # Disable sync for container
    #     icloud_cleanup --force <name>    # Force remove container (requires sudo)
    #
    # Examples:
    #     icloud_cleanup --uninstalled
    #     icloud_cleanup --force "com.dave.bike"
    #     icloud_cleanup --disable "2NSFZY54JA.com.dave.bike"

    local action="${1:-interactive}"
    local target_container="$2"

    echo "🧹 iCloud Container Cleanup Utility"
    echo "==================================="
    echo ""

    case "$action" in
        "--uninstalled"|"--blocked")
            echo "🔍 Finding containers for uninstalled apps..."
            local blocked_containers=($(brctl status 2>/dev/null | grep "blocked-app-uninstalled" | cut -d'<' -f2 | cut -d'[' -f1))

            if [[ ${#blocked_containers[@]} -eq 0 ]]; then
                echo "✅ No blocked containers found!"
                return 0
            fi

            echo "Found ${#blocked_containers[@]} problematic containers:"
            for container in "${blocked_containers[@]}"; do
                echo "   📦 $container"
            done
            echo ""

            echo "🔧 Disabling sync for these containers..."
            for container in "${blocked_containers[@]}"; do
                echo "   Disabling: $container"
                defaults write com.apple.bird disable-sync-for-bundle-ids -array-add "$container" 2>/dev/null || {
                    echo "   ⚠️  Could not disable sync for $container"
                }
            done

            echo ""
            echo "🔄 Restarting fileproviderd to apply changes..."
            pkill -f fileproviderd 2>/dev/null
            sleep 2

            echo "✅ Cleanup completed! Run 'icloud_diagnose' to verify the fix."
            ;;

        "--disable")
            if [[ -z "$target_container" ]]; then
                echo "❌ Error: Container name required"
                echo "Usage: icloud_cleanup --disable <container-name>"
                return 1
            fi

            echo "🔧 Disabling sync for: $target_container"
            defaults write com.apple.bird disable-sync-for-bundle-ids -array-add "$target_container"
            pkill -f fileproviderd 2>/dev/null
            echo "✅ Sync disabled. fileproviderd restarted."
            ;;

        "--force")
            if [[ -z "$target_container" ]]; then
                echo "❌ Error: Container name required"
                echo "Usage: icloud_cleanup --force <container-name>"
                return 1
            fi

            echo "⚠️  Force removing container: $target_container"
            echo "This will permanently delete all data for this container."
            echo -n "Are you sure? (y/N): "
            read -r confirmation

            if [[ "$confirmation" =~ ^[Yy]$ ]]; then
                echo "🗑️  Removing container files..."
                local container_path="$HOME/Library/Mobile Documents/*${target_container}*"
                if sudo rm -rf $container_path 2>/dev/null; then
                    echo "✅ Container removed successfully"
                    pkill -f fileproviderd 2>/dev/null
                    echo "🔄 Restarted fileproviderd"
                else
                    echo "❌ Failed to remove container. Check permissions or container name."
                fi
            else
                echo "❌ Operation cancelled"
            fi
            ;;

        *)
            echo "🛠️  Available cleanup options:"
            echo ""
            echo "1. 📱 Remove containers for uninstalled apps (RECOMMENDED)"
            echo "   icloud_cleanup --uninstalled"
            echo ""
            echo "2. 🚫 Disable sync for specific container"
            echo "   icloud_cleanup --disable <container-name>"
            echo ""
            echo "3. 🗑️  Force remove container (permanent deletion)"
            echo "   icloud_cleanup --force <container-name>"
            echo ""
            echo "💡 Run 'icloud_diagnose' first to identify problematic containers"
            echo ""
            echo -n "Choose option (1-3) or press Enter to exit: "
            read -r choice

            case "$choice" in
                "1")
                    icloud_cleanup --uninstalled
                    ;;
                "2")
                    echo -n "Enter container name: "
                    read -r container_name
                    icloud_cleanup --disable "$container_name"
                    ;;
                "3")
                    echo -n "Enter container name: "
                    read -r container_name
                    icloud_cleanup --force "$container_name"
                    ;;
                *)
                    echo "👋 Cleanup cancelled"
                    ;;
            esac
            ;;
    esac
}