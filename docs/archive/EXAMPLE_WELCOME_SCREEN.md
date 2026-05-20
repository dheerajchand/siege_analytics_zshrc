# Welcome Screen Example

This is what you see when opening a new terminal with the configuration loaded:

```
🚀 Loading modules...
✅ utils loaded
✅ python loaded (geo31111)
✅ credentials loaded
✅ database loaded
✅ backup loaded
✅ docker loaded
✅ spark loaded
✅ hadoop loaded

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 ZSH Configuration Loaded
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🐍 Python: geo31111
📁 Location: /Users/dheerajchand/Documents/Work
🐳 Docker: running

💡 Quick Commands:
   help          - Show all available commands
   modules       - List loaded modules
   python_status - Check Python environment
   backup        - Commit and push config to GitHub

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[your-prompt-here] $
```

## Customizing the Welcome Screen

Edit `~/.config/zsh/zshrc` around line 232:

```bash
# Welcome message - show useful context
if [[ -o interactive ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 ZSH Configuration Loaded"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show Python environment
    if command -v pyenv >/dev/null 2>&1; then
        local pyenv_version=$(pyenv version-name 2>/dev/null || echo 'system')
        echo "🐍 Python: $pyenv_version"
    fi
    
    # Show current directory
    echo "📁 Location: $(pwd)"
    
    # Show key services status
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        echo "🐳 Docker: running"
    fi
    
    # Quick tips
    echo ""
    echo "💡 Quick Commands:"
    echo "   help          - Show all available commands"
    echo "   modules       - List loaded modules"
    echo "   python_status - Check Python environment"
    echo "   backup        - Commit and push config to GitHub"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi
```

## Disabling the Welcome Screen

If you prefer a minimal startup, comment out the welcome message block:

```bash
# Welcome message - show useful context
# if [[ -o interactive ]]; then
#     ...
# fi
```

Or set a flag at the top of your zshrc:

```bash
export SHOW_WELCOME=false

# Then modify the if statement:
if [[ -o interactive ]] && [[ "$SHOW_WELCOME" != "false" ]]; then
    ...
fi
```

