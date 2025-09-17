#!/usr/bin/env zsh
# =====================================================
# JETBRAINS MODULE - IDE integration and project management
# =====================================================
#
# Purpose: JetBrains IDE integration with intelligent project detection
# Provides: Project opening, IDE management, development workflows
# Dependencies: centralized variables
# =====================================================

echo "🧠 Loading JetBrains module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# IDE FUNCTIONS
# =====================================================

# Purpose: Intelligent project detection and opening in appropriate IDE
# Arguments: $1 - target directory (default: current directory)
# Returns: 0 on success, 1 on error
# Usage: open_project [directory]
open_project() {
    local target_dir="${1:-.}"

    if [[ ! -d "$target_dir" ]]; then
        echo "❌ Directory not found: $target_dir"
        return 1
    fi

    cd "$target_dir"

    # Detect project type and open in appropriate IDE
    if [[ -f "pyproject.toml" || -f "requirements.txt" || -f "setup.py" ]]; then
        echo "🐍 Python project detected - opening in PyCharm"
        pycharm_open "$target_dir"
    elif [[ -f "package.json" ]]; then
        echo "📦 Node.js project detected - opening in WebStorm"
        webstorm_open "$target_dir"
    elif [[ -f "pom.xml" || -f "build.gradle" ]]; then
        echo "☕ Java project detected - opening in IntelliJ"
        idea_open "$target_dir"
    elif [[ -f "go.mod" ]]; then
        echo "🐹 Go project detected - opening in GoLand"
        goland_open "$target_dir"
    else
        echo "📁 Generic project - opening in IntelliJ"
        idea_open "$target_dir"
    fi
}

# Purpose: Open directory in PyCharm
# Arguments: $1 - directory path (default: current directory)
# Returns: 0 on success, 1 if PyCharm not found
# Usage: pycharm_open [directory]
pycharm_open() {
    local dir="${1:-.}"
    if command -v pycharm >/dev/null 2>&1; then
        pycharm "$dir"
    else
        echo "❌ PyCharm not found. Install or add to PATH."
        return 1
    fi
}

# Purpose: Open directory in IntelliJ IDEA
# Arguments: $1 - directory path (default: current directory)
# Returns: 0 on success, 1 if IntelliJ not found
# Usage: idea_open [directory]
idea_open() {
    local dir="${1:-.}"
    if command -v idea >/dev/null 2>&1; then
        idea "$dir"
    else
        echo "❌ IntelliJ IDEA not found. Install or add to PATH."
        return 1
    fi
}

# Purpose: Open directory in WebStorm
# Arguments: $1 - directory path (default: current directory)
# Returns: 0 on success, 1 if WebStorm not found
# Usage: webstorm_open [directory]
webstorm_open() {
    local dir="${1:-.}"
    if command -v webstorm >/dev/null 2>&1; then
        webstorm "$dir"
    else
        echo "❌ WebStorm not found. Install or add to PATH."
        return 1
    fi
}

# Purpose: Open directory in GoLand
# Arguments: $1 - directory path (default: current directory)
# Returns: 0 on success, 1 if GoLand not found
# Usage: goland_open [directory]
goland_open() {
    local dir="${1:-.}"
    if command -v goland >/dev/null 2>&1; then
        goland "$dir"
    else
        echo "❌ GoLand not found. Install or add to PATH."
        return 1
    fi
}

# Purpose: Show status of all JetBrains IDEs
# Arguments: None
# Returns: 0 always
# Usage: jetbrains_status
jetbrains_status() {
    echo "🧠 JetBrains IDEs Status"
    echo "======================="

    local ides=("idea:IntelliJ IDEA" "pycharm:PyCharm" "webstorm:WebStorm" "goland:GoLand" "clion:CLion")

    for ide_info in "${ides[@]}"; do
        local cmd="${ide_info%%:*}"
        local name="${ide_info##*:}"

        if command -v "$cmd" >/dev/null 2>&1; then
            echo "✅ $name: Available"
        else
            echo "❌ $name: Not found"
        fi
    done

    echo ""
    echo "💡 Install JetBrains Toolbox for easy IDE management"
    echo "🔗 https://www.jetbrains.com/toolbox-app/"
}

# =====================================================
# ALIASES
# =====================================================

alias open-project='open_project'
alias jetbrains-status='jetbrains_status'

echo "✅ JetBrains module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export JETBRAINS_MODULE_LOADED=true