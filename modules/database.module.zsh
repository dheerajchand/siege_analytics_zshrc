#!/usr/bin/env zsh
# =====================================================
# DATABASE MODULE - Database connection management
# =====================================================
#
# Purpose: PostgreSQL, MySQL, and database connection management
# Provides: Database connections, credential management, utilities
# Dependencies: Database clients (psql, mysql, etc.)
# =====================================================

echo "🗄️ Loading Database module..."

# Load database configuration and functions
if [[ -f "$ZSH_CONFIG_DIR/config/database.zsh" ]]; then
    source "$ZSH_CONFIG_DIR/config/database.zsh"
    echo "✅ Database functions loaded"
else
    echo "❌ Database config not found: $ZSH_CONFIG_DIR/config/database.zsh"
    return 1
fi

echo "✅ Database module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export DATABASE_MODULE_LOADED=true
