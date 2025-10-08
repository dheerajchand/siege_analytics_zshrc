#!/usr/bin/env zsh
# =====================================================
# TERMINAL TOOL COMPATIBILITY LAYER
# =====================================================
#
# Purpose: Provide compatibility between AI terminal tools and zsh functions
# Problem: AI terminal tools run in different shell environment than user's zsh
# Solution: Create a bridge that makes zsh functions available to any shell
# =====================================================

# =====================================================
# SHELL DETECTION AND COMPATIBILITY
# =====================================================

# Detect if we're running in a tool environment vs interactive shell
_is_tool_environment() {
    # Check for common tool environment indicators
    [[ -n "$TOOL_ENVIRONMENT" ]] || \
    [[ -n "$AI_ASSISTANT" ]] || \
    [[ -n "$CURSOR_AI" ]] || \
    [[ "$0" == *"tool"* ]] || \
    [[ "$PPID" == 1 ]] || \
    [[ -z "$TERM" ]] || \
    [[ -z "$DISPLAY" && "$OSTYPE" == "linux-gnu"* ]]
}

# =====================================================
# FUNCTION EXPORT MECHANISM
# =====================================================

# Create a function export file that can be sourced by any shell
_export_zsh_functions() {
    local export_file="$ZSH_CONFIG_DIR/.zsh_functions_export"
    
    cat > "$export_file" << 'EOF'
#!/bin/bash
# Auto-generated zsh functions export for tool compatibility
# This file is created by terminal_tool_compatibility.zsh

# Core functions that should be available in any shell
startup_status() {
    if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
        zsh -c "source $HOME/.config/zsh/zshrc && startup_status"
    else
        echo "❌ ZSH configuration not found"
    fi
}

modules() {
    if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
        zsh -c "source $HOME/.config/zsh/zshrc && modules"
    else
        echo "❌ ZSH configuration not found"
    fi
}

python_info() {
    if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
        zsh -c "source $HOME/.config/zsh/zshrc && python_info"
    else
        echo "❌ ZSH configuration not found"
    fi
}

system_info() {
    if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
        zsh -c "source $HOME/.config/zsh/zshrc && system_info"
    else
        echo "❌ ZSH configuration not found"
    fi
}

load_module() {
    if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
        zsh -c "source $HOME/.config/zsh/zshrc && load_module $*"
    else
        echo "❌ ZSH configuration not found"
    fi
}

# Make functions available in current shell
export -f startup_status modules python_info system_info load_module
EOF

    chmod +x "$export_file"
    echo "✅ Exported zsh functions to: $export_file"
}

# =====================================================
# TOOL ENVIRONMENT SETUP
# =====================================================

_setup_tool_environment() {
    echo "🔧 Setting up terminal tool compatibility..."
    
    # Set environment variables for tool detection
    export TOOL_ENVIRONMENT="true"
    export ZSH_CONFIG_DIR="$HOME/.config/zsh"
    
    # Export zsh functions for tool compatibility
    _export_zsh_functions
    
    # Source the export file if we're in bash
    if [[ -n "$BASH_VERSION" ]]; then
        source "$ZSH_CONFIG_DIR/.zsh_functions_export" 2>/dev/null || true
    fi
    
    echo "✅ Tool environment setup complete"
}

# =====================================================
# COMPATIBILITY FUNCTIONS
# =====================================================

# Wrapper function that works in any shell
zsh_exec() {
    local command="$*"
    if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
        zsh -c "source $HOME/.config/zsh/zshrc && $command"
    else
        echo "❌ ZSH configuration not found at $HOME/.config/zsh/zshrc"
        return 1
    fi
}

# Test function to verify compatibility
test_terminal_compatibility() {
    echo "🧪 Testing terminal tool compatibility..."
    echo ""
    
    echo "1. Testing zsh_exec wrapper:"
    zsh_exec "echo 'ZSH wrapper test successful'"
    echo ""
    
    echo "2. Testing function availability:"
    if command -v startup_status >/dev/null 2>&1; then
        echo "  ✅ startup_status function available"
    else
        echo "  ❌ startup_status function not available"
    fi
    
    if command -v modules >/dev/null 2>&1; then
        echo "  ✅ modules function available"
    else
        echo "  ❌ modules function not available"
    fi
    
    echo ""
    echo "3. Testing direct zsh execution:"
    zsh_exec "startup_status"
}

# =====================================================
# AUTO-SETUP FOR TOOL ENVIRONMENTS
# =====================================================

# Automatically set up if we detect a tool environment
if _is_tool_environment; then
    _setup_tool_environment
fi

# =====================================================
# COMPLETION
# =====================================================

echo "🔧 Terminal tool compatibility layer loaded"
echo "💡 Use 'test_terminal_compatibility' to verify setup"
echo "💡 Use 'zsh_exec <command>' to run zsh functions from any shell"




