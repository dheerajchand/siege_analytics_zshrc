#!/usr/bin/env zsh
# =====================================================
# CURSOR IDE INTEGRATION MODULE
# =====================================================
#
# Purpose: Optimized shell configuration for Cursor IDE
# Features: Fast startup, Python/UV integration, AI-aware tools
# Dependencies: Universal Python/UV system, IDE helpers
# =====================================================

# =====================================================
# CURSOR DETECTION AND SETUP
# =====================================================

detect_cursor_ide() {
    [[ -n "$CURSOR_IDE" ]] || \
    [[ "$TERM_PROGRAM" == "Cursor"* ]] || \
    [[ "$0" == *"cursor"* ]] || \
    [[ -n "$CURSOR_SESSION" ]]
}

setup_cursor_environment() {
    if detect_cursor_ide; then
        echo "🎯 Cursor IDE detected - Setting up optimized environment"

        # Set Cursor-specific environment variables
        export IDE_MODE=true
        export CURSOR_IDE_MODE=true
        export FAST_STARTUP=true

        # Load universal IDE helpers
        if [[ -f "$HOME/.config/zsh/ide_helpers.zsh" ]]; then
            source "$HOME/.config/zsh/ide_helpers.zsh"
        fi

        # Load essential modules for development
        echo "📦 Loading development modules for Cursor..."

        # Python environment (universal system)
        if [[ -f "$HOME/.config/zsh/modules/languages/python/managers.zsh" ]]; then
            source "$HOME/.config/zsh/modules/languages/python/managers.zsh"
            echo "✅ Universal Python/UV system loaded"
        fi

        # JavaScript/Node.js for web development
        if command -v load_module >/dev/null 2>&1; then
            load_module javascript 2>/dev/null && echo "✅ JavaScript module loaded"
        fi

        echo "🚀 Cursor IDE environment ready!"
        echo "💡 Available commands: cursor-fix, cursor-uv-setup, py-uv, py-switch"
    fi
}

# =====================================================
# CURSOR-SPECIFIC OPTIMIZATIONS
# =====================================================

cursor_status() {
    if detect_cursor_ide; then
        echo "🎯 Cursor IDE Configuration Status"
        echo "=================================="
        echo "IDE: Cursor"
        echo "Mode: Cursor IDE Mode"
        echo "Fast Startup: Enabled"
        echo ""
        ide-env-info
    else
        echo "❌ Not running in Cursor IDE"
    fi
}

cursor_ai_context() {
    echo "🤖 Cursor AI Context Information"
    echo "==============================="
    echo "Working Directory: $PWD"
    echo "Git Status: $(git status --porcelain 2>/dev/null | wc -l | xargs echo) changed files"
    echo "Python Environment: ${VIRTUAL_ENV:-$(pyenv version-name 2>/dev/null)}"

    if [[ -f "package.json" ]]; then
        echo "Node Project: ✅ $(node --version 2>/dev/null)"
    fi

    if [[ -f "pyproject.toml" ]]; then
        echo "UV Project: ✅ $(uv --version 2>/dev/null)"
    fi

    if [[ -f "requirements.txt" || -f "setup.py" || -f "poetry.lock" ]]; then
        echo "Python Project: ✅"
    fi
}

# =====================================================
# CURSOR-AWARE DEVELOPMENT TOOLS
# =====================================================

cursor_project_setup() {
    local project_type="${1:-auto}"

    echo "🚀 Setting up Cursor project environment..."

    case "$project_type" in
        "python"|"py")
            echo "🐍 Setting up Python project for Cursor..."
            cursor-uv-setup
            ;;
        "node"|"js"|"javascript")
            echo "🌐 Setting up Node.js project for Cursor..."
            if [[ ! -f "package.json" ]]; then
                npm init -y
            fi
            echo "✅ Node.js project ready"
            ;;
        "auto")
            echo "🔍 Auto-detecting project type..."
            if [[ -f "pyproject.toml" || -f "requirements.txt" || -f "setup.py" ]]; then
                cursor_project_setup "python"
            elif [[ -f "package.json" ]]; then
                cursor_project_setup "node"
            else
                echo "💡 No specific project type detected. Use:"
                echo "   cursor_project_setup python"
                echo "   cursor_project_setup node"
            fi
            ;;
        *)
            echo "❌ Unknown project type: $project_type"
            echo "Available types: python, node, auto"
            ;;
    esac
}

cursor_quick_commands() {
    echo "⚡ Cursor Quick Commands"
    echo "======================="
    echo ""
    echo "🔧 Environment:"
    echo "   cursor-fix           # Fix common issues"
    echo "   cursor-uv-setup      # Setup UV project"
    echo "   cursor_status        # Show status"
    echo "   cursor_ai_context    # Show AI context info"
    echo ""
    echo "🐍 Python (Universal):"
    echo "   py-uv               # Activate UV project"
    echo "   py-switch list      # List environments"
    echo "   py-info             # Python status"
    echo ""
    echo "🚀 Project Setup:"
    echo "   cursor_project_setup auto    # Auto-detect and setup"
    echo "   cursor_project_setup python # Python project"
    echo "   cursor_project_setup node   # Node.js project"
}

# =====================================================
# ALIASES AND SHORTCUTS
# =====================================================

alias cursor-status='cursor_status'
alias cursor-commands='cursor_quick_commands'
alias cursor-context='cursor_ai_context'
alias cursor-setup='cursor_project_setup'

# =====================================================
# INITIALIZATION
# =====================================================

# Auto-setup if running in Cursor
if detect_cursor_ide; then
    setup_cursor_environment

    # Show welcome message
    echo ""
    echo "💡 Type 'cursor-commands' to see all available commands"
    echo "💡 Type 'cursor-context' for AI context information"
fi

echo "✅ Cursor integration module loaded"