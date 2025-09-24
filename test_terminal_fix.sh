#!/bin/bash
# Test script to verify terminal tool compatibility fix

echo "🧪 Testing Terminal Tool Compatibility Fix"
echo "=========================================="
echo ""

# Set up the tool environment
export TOOL_ENVIRONMENT="true"
export ZSH_CONFIG_DIR="$HOME/.config/zsh"

echo "📊 Environment Setup:"
echo "  TOOL_ENVIRONMENT: $TOOL_ENVIRONMENT"
echo "  ZSH_CONFIG_DIR: $ZSH_CONFIG_DIR"
echo "  Current shell: $SHELL"
echo ""

# Source the compatibility layer
if [[ -f "$ZSH_CONFIG_DIR/terminal_tool_compatibility.zsh" ]]; then
    echo "🔧 Loading compatibility layer..."
    source "$ZSH_CONFIG_DIR/terminal_tool_compatibility.zsh"
    echo ""
else
    echo "❌ Compatibility layer not found"
    exit 1
fi

# Test the functions
echo "🧪 Testing Functions:"
echo ""

echo "1. Testing zsh_exec wrapper:"
zsh_exec "echo 'ZSH wrapper test successful'"
echo ""

echo "2. Testing startup_status:"
zsh_exec "startup_status"
echo ""

echo "3. Testing modules:"
zsh_exec "modules"
echo ""

echo "4. Testing python_info:"
zsh_exec "python_info"
echo ""

echo "✅ Terminal compatibility test complete"


