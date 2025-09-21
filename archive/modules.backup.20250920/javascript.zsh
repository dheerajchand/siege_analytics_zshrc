#!/usr/bin/env zsh
# =====================================================
# JAVASCRIPT MODULE - Node.js, npm, and related tools
# =====================================================

echo "📦 Loading JavaScript module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# NVM SETUP
# =====================================================

# Setup NVM if available
if [[ -d "$NVM_DIR" ]]; then
    echo "🟢 Setting up Node Version Manager (nvm)..."

    export NVM_DIR="$HOME/.nvm"

    # Load nvm script
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
        source "$NVM_DIR/nvm.sh"
    elif [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
        source "/opt/homebrew/opt/nvm/nvm.sh"
    fi

    # Load nvm bash completion
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
        source "$NVM_DIR/bash_completion"
    elif [[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ]]; then
        source "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
    fi

    # Auto-load .nvmrc files when changing directories
    auto_load_nvmrc() {
        if [[ -f .nvmrc && -r .nvmrc ]]; then
            echo "📝 Found .nvmrc file, switching to specified Node version..."
            nvm use 2>/dev/null || echo "⚠️  Node version in .nvmrc not installed"
        fi
    }

    # Add hook for directory changes
    if command -v add-zsh-hook >/dev/null 2>&1; then
        add-zsh-hook chpwd auto_load_nvmrc
        auto_load_nvmrc  # Run once on load
    fi

    echo "✅ NVM configured with auto .nvmrc detection"
else
    echo "⚠️  NVM not found - install with: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
fi

# =====================================================
# NODE/NPM FUNCTIONS
# =====================================================

# Node.js environment status
node_status() {
    echo "📦 Node.js Environment Status"
    echo "============================="

    if command -v node >/dev/null 2>&1; then
        echo "✅ Node.js: $(node --version)"
        echo "📍 Location: $(which node)"
    else
        echo "❌ Node.js: Not found"
    fi

    if command -v npm >/dev/null 2>&1; then
        echo "✅ npm: $(npm --version)"
    else
        echo "❌ npm: Not found"
    fi

    if command -v nvm >/dev/null 2>&1; then
        echo "✅ nvm: $(nvm --version)"
        echo "🔄 Current version: $(nvm current)"
        echo "📋 Installed versions:"
        nvm list --no-colors | head -10
    else
        echo "❌ nvm: Not available"
    fi

    # Show global packages
    if command -v npm >/dev/null 2>&1; then
        echo ""
        echo "🌍 Global packages:"
        npm list -g --depth=0 2>/dev/null | head -10
    fi
}

# Quick Node version switching
node_switch() {
    local version="$1"

    if [[ -z "$version" ]]; then
        echo "📋 Available Node versions:"
        nvm list
        echo ""
        echo "💡 Usage: node_switch <version>"
        echo "   Examples: node_switch 18, node_switch lts, node_switch latest"
        return 1
    fi

    if command -v nvm >/dev/null 2>&1; then
        echo "🔄 Switching to Node.js $version..."
        nvm use "$version"
    else
        echo "❌ nvm not available"
        return 1
    fi
}

# Install and use latest LTS
node_use_lts() {
    if command -v nvm >/dev/null 2>&1; then
        echo "🔄 Installing and using latest LTS Node.js..."
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*
        echo "✅ Latest LTS Node.js is now default"
    else
        echo "❌ nvm not available"
        return 1
    fi
}

# Project setup helpers
npm_init_project() {
    local project_name="$1"
    local template="${2:-basic}"

    if [[ -z "$project_name" ]]; then
        echo "❌ Project name required"
        echo "💡 Usage: npm_init_project <name> [template]"
        echo "   Templates: basic, react, vue, express"
        return 1
    fi

    echo "🚀 Creating new Node.js project: $project_name"
    mkdir -p "$project_name"
    cd "$project_name"

    case "$template" in
        "react")
            npx create-react-app . --template typescript
            ;;
        "vue")
            npx create-vue@latest .
            ;;
        "express")
            npm init -y
            npm install express
            npm install -D @types/express typescript ts-node nodemon
            ;;
        *)
            npm init -y
            ;;
    esac

    echo "✅ Project $project_name created with $template template"
}

# =====================================================
# YARN SUPPORT
# =====================================================

# Yarn status check
yarn_status() {
    if command -v yarn >/dev/null 2>&1; then
        echo "✅ Yarn: $(yarn --version)"
        echo "📍 Location: $(which yarn)"
    else
        echo "❌ Yarn: Not found (install with: npm install -g yarn)"
    fi
}

# =====================================================
# PATH MANAGEMENT
# =====================================================

# Add Node.js paths only if they exist and aren't already in PATH
add_node_to_path() {
    # Add current Node version to PATH if nvm is loaded
    if command -v nvm >/dev/null 2>&1; then
        local current_node="$(nvm which current 2>/dev/null)"
        if [[ -n "$current_node" ]]; then
            local node_bin_dir="$(dirname "$current_node")"
            if [[ ":$PATH:" != *":$node_bin_dir:"* ]]; then
                export PATH="$node_bin_dir:$PATH"
            fi
        fi
    fi

    # Add local node_modules/.bin to PATH for project tools
    if [[ -d "./node_modules/.bin" && ":$PATH:" != *":./node_modules/.bin:"* ]]; then
        export PATH="./node_modules/.bin:$PATH"
    fi
}

# Run path setup
add_node_to_path

# =====================================================
# ALIASES
# =====================================================

# Essential aliases only
alias node-status='node_status'
alias node-switch='node_switch'
alias node-lts='node_use_lts'
alias npm-init='npm_init_project'

# Common npm shortcuts
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

# Yarn shortcuts (if available)
if command -v yarn >/dev/null 2>&1; then
    alias yi='yarn install'
    alias ya='yarn add'
    alias yad='yarn add --dev'
    alias yr='yarn run'
    alias ys='yarn start'
    alias yt='yarn test'
    alias yb='yarn build'
fi

echo "✅ JavaScript module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export JAVASCRIPT_MODULE_LOADED=true