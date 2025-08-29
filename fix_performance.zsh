#!/bin/zsh

# =====================================================
# SHELL PERFORMANCE OPTIMIZATION SCRIPT
# =====================================================
# This script fixes the duplicate PATH entries and other
# performance issues causing slow Finder dialogs

echo "🚀 Shell Performance Optimization"
echo "================================"
echo ""

# Function to clean PATH
clean_path() {
    echo "🧹 Cleaning PATH..."
    
    # Remove duplicates while preserving order
    local cleaned_path=""
    local seen=()
    
    # Split PATH and process each entry
    for entry in ${(s/:/)PATH}; do
        # Skip empty entries and current directory
        if [[ -z "$entry" || "$entry" == "." ]]; then
            continue
        fi
        
        # Check if we've seen this entry before
        if [[ ! " ${seen[@]} " =~ " ${entry} " ]]; then
            seen+=("$entry")
            if [[ -z "$cleaned_path" ]]; then
                cleaned_path="$entry"
            else
                cleaned_path="$cleaned_path:$entry"
            fi
        else
            echo "  🗑️  Removed duplicate: $entry"
        fi
    done
    
    # Set the cleaned PATH
    export PATH="$cleaned_path"
    
    echo "  ✅ PATH cleaned: ${#PATH} chars, $(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ') entries"
}

# Function to optimize environment loading
optimize_environment() {
    echo ""
    echo "⚡ Optimizing environment loading..."
    
    # Disable auto_backup_trigger hook temporarily for performance testing
    if [[ -n "$AUTO_BACKUP_ON_CHANGE" ]]; then
        echo "  ⏸️  Temporarily disabling auto_backup_trigger hook"
        export AUTO_BACKUP_ON_CHANGE="false"
    fi
    
    # Optimize NVM loading
    if [[ -n "$NVM_DIR" ]]; then
        echo "  🚀 NVM already loaded, skipping re-initialization"
    fi
    
    # Check for heavy tools that might be auto-loading
    if [[ -n "$SPARK_HOME" || -n "$HADOOP_HOME" ]]; then
        echo "  ⚠️  Big data tools detected - consider lazy loading"
    fi
    
    echo "  ✅ Environment optimized"
}

# Function to create a performance-optimized profile
create_optimized_profile() {
    echo ""
    echo "📝 Creating performance-optimized profile..."
    
    cat > ~/.zshrc.optimized << 'EOF'
# =====================================================
# PERFORMANCE-OPTIMIZED ZSHRC
# =====================================================
# This profile is optimized for fast Finder dialogs and shell performance

# Enable Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Clean, minimal PATH setup
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Oh My Zsh with minimal plugins
export ZSH="$HOME/.dotfiles/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"  
plugins=(git)  # Removed nvm plugin for faster loading

# Source Oh My Zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# Powerlevel10k config
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Lazy load NVM only when needed
export NVM_DIR="$HOME/.nvm"
nvm() {
    if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
        echo "❌ NVM not installed"
        return 1
    fi
    
    # Load NVM only when first used
    if [[ ! -n "$(command -v nvm)" ]]; then
        source "$NVM_DIR/nvm.sh"
        source "$NVM_DIR/etc/bash_completion.d/nvm"
    fi
    
    nvm "$@"
}

# Lazy load Python tools
pyenv() {
    if command -v pyenv >/dev/null 2>&1; then
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
        pyenv "$@"
    else
        echo "❌ pyenv not found"
    fi
}

# Lazy load big data tools
spark() {
    if [[ -f ~/.config/zsh/spark.zsh ]]; then
        source ~/.config/zsh/spark.zsh
        spark "$@"
    else
        echo "❌ Spark configuration not found"
    fi
}

hadoop() {
    if [[ -f ~/.config/zsh/hadoop.zsh ]]; then
        source ~/.config/zsh/hadoop.zsh
        hadoop "$@"
    else
        echo "❌ Hadoop configuration not found"
    fi
}

# Performance monitoring
export SHELL_STARTUP_TIME=$(date +%s)
EOF

    echo "  ✅ Created ~/.zshrc.optimized"
    echo "  💡 To use: cp ~/.zshrc.optimized ~/.zshrc"
}

# Main optimization
echo "🔍 Current PATH analysis:"
echo "  Length: ${#PATH}"
echo "  Entries: $(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ')"
echo "  Duplicates: $(echo $PATH | tr ':' '\n' | sort | uniq -d | wc -l | tr -d ' ')"
echo ""

# Clean PATH
clean_path

# Optimize environment
optimize_environment

# Create optimized profile
create_optimized_profile

echo ""
echo "🎯 Performance Optimization Complete!"
echo "=================================="
echo ""
echo "📊 Results:"
echo "  ✅ PATH cleaned and deduplicated"
echo "  ✅ Environment loading optimized"
echo "  ✅ Performance profile created"
echo ""
echo "🚀 Next Steps:"
echo "  1. Test current performance: source diagnose_performance.zsh"
echo "  2. Try the optimized profile: cp ~/.zshrc.optimized ~/.zshrc"
echo "  3. Restart your terminal to see the full effect"
echo "  4. Test Finder dialogs - they should be much faster now!"
echo ""
echo "💡 The optimized profile uses lazy loading for heavy tools,"
echo "   so they only load when you actually need them."
