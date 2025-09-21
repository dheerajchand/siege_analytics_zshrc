#!/usr/bin/env zsh
# =====================================================
# DATABASE MODULE - On-demand database management
# =====================================================

echo "🗄️ Loading Database module..."

# =====================================================
# DATABASE CONFIGURATION
# =====================================================

export PGUSER="${PGUSER:-dheerajchand}"
export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5432}"

# =====================================================
# DATABASE FUNCTIONS
# =====================================================

database_status() {
    echo "🗄️ Database Status"
    echo "=================="

    # PostgreSQL
    if command -v psql >/dev/null 2>&1; then
        echo "PostgreSQL: ✅ Available"
        echo "User: $PGUSER"
        echo "Host: $PGHOST:$PGPORT"

        # Test connection
        if psql -c '\l' >/dev/null 2>&1; then
            echo "Connection: ✅ Working"
            echo "Databases: $(psql -t -c '\l' | grep -c '|')"
        else
            echo "Connection: ❌ Failed"
        fi
    else
        echo "PostgreSQL: ❌ Not installed"
    fi

    echo ""

    # MySQL/MariaDB
    if command -v mysql >/dev/null 2>&1; then
        echo "MySQL: ✅ Available"
    else
        echo "MySQL: ❌ Not installed"
    fi
}

pg() {
    # Quick PostgreSQL connection with auto-credentials
    if command -v psql >/dev/null 2>&1; then
        psql "$@"
    else
        echo "❌ psql not found. Install with: brew install postgresql"
    fi
}

setup_postgres_credentials() {
    echo "🔐 Setting up PostgreSQL credentials..."
    echo "Current user: $PGUSER"
    echo "Current host: $PGHOST:$PGPORT"

    echo "💡 Credentials are managed via environment variables:"
    echo "  PGUSER, PGHOST, PGPORT, PGPASSWORD"
}

# =====================================================
# ALIASES
# =====================================================

alias db-status='database_status'
alias pg-setup='setup_postgres_credentials'

echo "✅ Database module loaded successfully"