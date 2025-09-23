#!/usr/bin/env zsh
# =====================================================
# JAVASCRIPT MODULE - Node.js and JavaScript tooling
# =====================================================
#
# Purpose: JavaScript/Node.js development environment
# Provides: nvm, node, npm, yarn management
# Dependencies: centralized variables
# =====================================================

# Loading JavaScript module silently

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# NODE.JS ENVIRONMENT SETUP
# =====================================================

# Setup NVM if available
if [[ -d "$NVM_DIR" ]]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
fi

# Add node_modules/.bin to PATH if in a project
if [[ -d "./node_modules/.bin" ]]; then
    export PATH="./node_modules/.bin:$PATH"
fi

# =====================================================
# JAVASCRIPT STATUS FUNCTION
# =====================================================

javascript_status() {
    echo "🟨 JavaScript Environment Status"
    echo "================================"

    if command -v node >/dev/null 2>&1; then
        echo "✅ Node.js: $(node --version)"
        echo "📍 Location: $(which node)"
    else
        echo "❌ Node.js: Not available"
    fi

    if command -v npm >/dev/null 2>&1; then
        echo "✅ NPM: $(npm --version)"
    else
        echo "❌ NPM: Not available"
    fi

    if command -v yarn >/dev/null 2>&1; then
        echo "✅ Yarn: $(yarn --version)"
    else
        echo "💤 Yarn: Not installed"
    fi

    if command -v nvm >/dev/null 2>&1; then
        echo "✅ NVM: Available"
        echo "🔄 Current: $(nvm current 2>/dev/null || echo 'system')"
    else
        echo "💤 NVM: Not available"
    fi
}

# JavaScript module loaded successfully

# =====================================================
# COMPLETION
# =====================================================
export JAVASCRIPT_MODULE_LOADED=true