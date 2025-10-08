#!/bin/bash
# Cron-safe ZSH configuration loader

# Set basic environment for cron jobs
export HOME="${HOME:-/Users/dheerajchand}"
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"

# Only load if ZSH config exists
if [[ -f "$HOME/.config/zsh/zshrc" ]]; then
    # Load with error suppression for cron compatibility
    source "$HOME/.config/zsh/zshrc" 2>/dev/null || true
fi

# Ensure basic commands are available
command -v ls >/dev/null 2>&1 || export PATH="/bin:/usr/bin:$PATH"
