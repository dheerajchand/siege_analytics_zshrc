# =====================================================
# UTILITY FUNCTIONS & DATABASE CONFIG
# =====================================================

# Database settings
export PGHOST="localhost"
export PGUSER="dheerajchand"
export PGPASSWORD="dessert"
export PGPORT="5432"
export PGDATABASE="gis"
export GEODJANGO_TEMPLATE_SQL_DATABASE="geodjango_template_db"
export GEODJANGO_TEMPLATE_SQL_USER="dheerajchand"
export GEODJANGO_TEMPLATE_SQL_PASSWORD="dessert"
export GEODJANGO_TEMPLATE_SQL_PORT="5432"

# Docker & GIS
export DEFAULT_DOCKER_CONTEXT="rancher-desktop"
if command -v gdal-config &>/dev/null; then
    export GDAL_LIBRARY_PATH="$(gdal-config --prefix)/lib/libgdal.dylib"
fi
if command -v geos-config &>/dev/null; then
    export GEOS_LIBRARY_PATH="$(geos-config --prefix)/lib/libgeos_c.dylib"
fi


# Legacy utility functions - these are now handled by the modular system
# is_online, cleanvenv, remove_python_cruft are now in config/core.zsh

function delpycache() {
    local target_dir="${1:-.}" # Use current directory if no argument is provided

    # Check if the target directory exists
    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory '$target_dir' not found."
        return 1
    fi

    echo "Searching for and deleting __pycache__ directories in '$target_dir'..."
    # Find all directories named __pycache__ and delete them recursively
    find "$target_dir" -name "__pycache__" -type d -exec rm -rf {} +
    echo "Deletion complete."
}

# =====================================================
# macOS SYSTEM CONFIGURATIONS
# =====================================================

# Show hidden files in Finder (open/save dialogs)
function show_hidden_files() {
    defaults write com.apple.finder AppleShowAllFiles -bool true
    killall Finder
    echo "✅ Hidden files are now visible in Finder"
}

function hide_hidden_files() {
    defaults write com.apple.finder AppleShowAllFiles -bool false
    killall Finder
    echo "✅ Hidden files are now hidden in Finder"
}

# Enable key repeat for special characters and accents
function enable_key_repeat() {
    defaults write -g ApplePressAndHoldEnabled -bool false
    echo "✅ Key repeat enabled - hold keys for special characters"
}

function disable_key_repeat() {
    defaults write -g ApplePressAndHoldEnabled -bool true
    echo "✅ Key repeat disabled - hold keys for accents"
}

# Quick toggle functions
function toggle_hidden_files() {
    local current_state=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "false")
    if [[ "$current_state" == "true" ]]; then
        hide_hidden_files
    else
        show_hidden_files
    fi
}

function toggle_key_repeat() {
    local current_state=$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null || echo "true")
    if [[ "$current_state" == "false" ]]; then
        disable_key_repeat
    else
        enable_key_repeat
    fi
}

# Auto-configure on macOS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Enable key repeat by default (better for coding)
    if [[ ! -f "$HOME/.key_repeat_configured" ]]; then
        enable_key_repeat
        touch "$HOME/.key_repeat_configured"
    fi
    
    # Show current status
    echo "🔧 macOS Config: Key repeat $(defaults read -g ApplePressAndHoldEnabled 2>/dev/null || echo 'true' | sed 's/false/ENABLED/' | sed 's/false/DISABLED/')"
    echo "🔧 macOS Config: Hidden files $(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo 'false' | sed 's/true/VISIBLE/' | sed 's/false/HIDDEN/')"
    
    # Set up Cursor command-line tool
    if [[ -f "/Applications/Cursor.app/Contents/Resources/app/bin/cursor" ]]; then
        alias cursor="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
        alias c="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
        echo "🚀 Cursor CLI available: use 'cursor' or 'c' command"
    fi
fi

# =====================================================
# Git settings and utilities
# =====================================================
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# update_local_repo is now in the main zshrc file

function clone_repos_from_github_organisation {
    local organisation="${1:-dheerajchand}"
    local target_dir="${2:-.}"
    
    # Convert target_dir to absolute path
    target_dir=$(realpath "$target_dir")

    # Check if the target directory exists
    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory '$target_dir' not found."
        return 1
    fi

    echo "Cloning repositories from GitHub organisation '$organisation' into '$target_dir'..."
    
    # Clone repositories from the specified GitHub organisation
    gh repo list "$organisation" --limit 4000 | while read -r repo _; do
        local repo_name=$(basename "$repo")
        local repo_path="$target_dir/$repo_name"
        echo "Processing $repo..."
        
        if [ -d "$repo_path" ]; then
            echo "  Repository $repo_name already exists, updating..."
            (
                cd "$repo_path"
                # Handle case where local checkout is on a non-main/master branch
                # - ignore checkout errors because some repos may have zero commits
                git checkout -q main 2>/dev/null || git checkout -q master 2>/dev/null || true
                git pull -q 2>/dev/null || echo "  Warning: Could not pull updates for $repo_name"
            )
        else
            echo "  Cloning $repo..."
            gh repo clone "$repo" "$repo_path" 2>/dev/null || echo "  Warning: Could not clone $repo"
        fi
    done

    echo "Cloning complete."
}
alias test-enhanced-sync="source /tmp/sync_functions_fixed.zsh && sync_all_passwords_to_1password"
