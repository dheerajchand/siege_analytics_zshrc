#!/bin/bash
# Diagnostic script to understand terminal tool environment issues

echo "🔍 Terminal Tool Environment Diagnostic"
echo "======================================"
echo ""

echo "📊 Shell Information:"
echo "  Current shell: $SHELL"
echo "  Shell version: $BASH_VERSION${ZSH_VERSION}"
echo "  Process ID: $$"
echo "  Parent PID: $PPID"
echo ""

echo "📁 Working Directory:"
echo "  PWD: $PWD"
echo "  Real PWD: $(pwd 2>/dev/null || echo 'pwd command failed')"
echo ""

echo "🔧 Environment Variables:"
echo "  ZSH_CONFIG_DIR: ${ZSH_CONFIG_DIR:-'not set'}"
echo "  LOADED_MODULES: ${LOADED_MODULES:-'not set'}"
echo "  PATH length: ${#PATH}"
echo ""

echo "📦 Available Commands:"
echo "  which zsh: $(which zsh 2>/dev/null || echo 'not found')"
echo "  which bash: $(which bash 2>/dev/null || echo 'not found')"
echo "  which python3: $(which python3 2>/dev/null || echo 'not found')"
echo ""

echo "🧪 Test Commands:"
echo "  echo test: $(echo 'test')"
echo "  date: $(date 2>/dev/null || echo 'date failed')"
echo "  ls: $(ls -la 2>/dev/null | head -3 || echo 'ls failed')"
echo ""

echo "🔍 ZSH Configuration Status:"
if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
    echo "  ✅ zshrc exists"
    echo "  📏 zshrc size: $(wc -l < "$HOME/.config/zsh/zshrc") lines"
else
    echo "  ❌ zshrc not found"
fi

if [[ -f "$HOME/.config/zsh/config/core.zsh" ]]; then
    echo "  ✅ core.zsh exists"
else
    echo "  ❌ core.zsh not found"
fi

echo ""
echo "💡 This diagnostic helps identify why terminal tools may not work"




