#!/usr/bin/env zsh
# =====================================================
# DOCKER MODULE - Container management and development
# =====================================================
#
# Purpose: Docker management, development workflows, and container operations
# Provides: Docker status, container management, development environments
# Dependencies: Docker installed
# =====================================================

echo "🐳 Loading Docker module..."

# Load docker configuration and functions
if [[ -f "$ZSH_CONFIG_DIR/config/docker.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/config/docker.zsh"
    echo "✅ Docker functions loaded"
else
    echo "❌ Docker config not found: $ZSH_CONFIG_DIR/config/docker.zsh"
    return 1
fi

echo "✅ Docker module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export DOCKER_MODULE_LOADED=true
