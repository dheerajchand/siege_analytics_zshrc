#!/usr/bin/env zsh
# =====================================================
# DATABASE MODULE - Database connection and management
# =====================================================
#
# Purpose: Database connectivity and quick operations
# Provides: PostgreSQL, MySQL connection helpers
# Dependencies: centralized variables
# =====================================================

echo "🗄️ Loading Database module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# DATABASE FUNCTIONS
# =====================================================

# Purpose: Show database connection status and configuration
# Arguments: None
# Returns: 0 always
# Usage: database_status
database_status() {
    echo "🗄️ Database Connection Status"
    echo "============================="

    # PostgreSQL status
    echo "🐘 PostgreSQL:"
    if command -v psql >/dev/null 2>&1; then
        echo "✅ psql: Available"
        echo "🔧 Configuration:"
        echo "  Host: $PGHOST"
        echo "  Port: $PGPORT"
        echo "  User: $PGUSER"
        echo "  Database: $PGDATABASE"

        # Test connection
        if psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c '\q' 2>/dev/null; then
            echo "✅ Connection: Success"
        else
            echo "❌ Connection: Failed"
        fi
    else
        echo "❌ psql: Not installed"
    fi

    echo ""

    # MySQL status
    echo "🐬 MySQL:"
    if command -v mysql >/dev/null 2>&1; then
        echo "✅ mysql: Available"
    else
        echo "❌ mysql: Not installed"
    fi
}

# Purpose: Quick PostgreSQL connection
# Arguments: $1 - optional database name
# Returns: 0 on success, 1 on error
# Usage: pg [database_name]
pg() {
    local database="${1:-$PGDATABASE}"

    if ! command -v psql >/dev/null 2>&1; then
        echo "❌ PostgreSQL client not installed"
        return 1
    fi

    echo "🐘 Connecting to PostgreSQL: $database@$PGHOST:$PGPORT"
    psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$database"
}

# Purpose: Setup PostgreSQL credentials interactively
# Arguments: None
# Returns: 0 on success
# Usage: setup_postgres_credentials
setup_postgres_credentials() {
    echo "🔧 PostgreSQL Credential Setup"
    echo "=============================="

    # Get credentials
    echo -n "Host [$PGHOST]: "
    read -r host
    [[ -n "$host" ]] && export PGHOST="$host"

    echo -n "Port [$PGPORT]: "
    read -r port
    [[ -n "$port" ]] && export PGPORT="$port"

    echo -n "Username [$PGUSER]: "
    read -r user
    [[ -n "$user" ]] && export PGUSER="$user"

    echo -n "Database [$PGDATABASE]: "
    read -r database
    [[ -n "$database" ]] && export PGDATABASE="$database"

    echo "✅ Credentials configured"
    echo "🧪 Testing connection..."

    if pg -c '\q' 2>/dev/null; then
        echo "✅ Connection successful!"
    else
        echo "❌ Connection failed. Please check credentials."
        return 1
    fi
}

# =====================================================
# ALIASES
# =====================================================

alias db-status='database_status'
alias pg-setup='setup_postgres_credentials'

echo "✅ Database module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export DATABASE_MODULE_LOADED=true