#!/usr/bin/env zsh
# =====================================================
# JETBRAINS MODULE - On-demand JetBrains IDE integration
# =====================================================

echo "🧠 Loading JetBrains module..."

# =====================================================
# IDE FUNCTIONS
# =====================================================

# Enhanced project detection and opening
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

# Individual IDE functions
pycharm_open() {
    local dir="${1:-.}"
    if command -v pycharm >/dev/null 2>&1; then
        pycharm "$dir"
    else
        echo "❌ PyCharm not found. Install or add to PATH."
    fi
}

idea_open() {
    local dir="${1:-.}"
    if command -v idea >/dev/null 2>&1; then
        idea "$dir"
    else
        echo "❌ IntelliJ IDEA not found. Install or add to PATH."
    fi
}

webstorm_open() {
    local dir="${1:-.}"
    if command -v webstorm >/dev/null 2>&1; then
        webstorm "$dir"
    else
        echo "❌ WebStorm not found. Install or add to PATH."
    fi
}

goland_open() {
    local dir="${1:-.}"
    if command -v goland >/dev/null 2>&1; then
        goland "$dir"
    else
        echo "❌ GoLand not found. Install or add to PATH."
    fi
}

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
}

# =====================================================
# ALIASES
# =====================================================

alias py='pycharm_open'
alias idea='idea_open'
alias webstorm='webstorm_open'
alias goland='goland_open'
alias open-project='open_project'
alias jetbrains-status='jetbrains_status'

echo "✅ JetBrains module loaded successfully"