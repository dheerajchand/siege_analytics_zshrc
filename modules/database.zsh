#!/usr/bin/env zsh
# =================================================================
# DATABASE - Database Connection Management
# =================================================================
# PostgreSQL, MySQL connection helpers and credential management
# =================================================================

# PostgreSQL default configuration
export PGHOST="${PGHOST:-localhost}"
export DEFAULT_PG_USER="${DEFAULT_PG_USER:-$USER}"
export PGUSER="${PGUSER:-${DEFAULT_PG_USER}}"
export PGPORT="${PGPORT:-5432}"
export PGDATABASE="${PGDATABASE:-postgres}"

# Setup PostgreSQL credentials
setup_postgres_credentials() {
    echo "🐘 PostgreSQL Credential Setup"
    echo "Host: $PGHOST"
    echo "User: $PGUSER"
    echo "Port: $PGPORT"
    echo "Database: $PGDATABASE"
    echo ""
    
    # Check if already set
    if [[ -n "$PGPASSWORD" ]]; then
        echo "✅ PGPASSWORD already configured"
        return 0
    fi
    
    # Try to get from credential system
    if command -v get_credential >/dev/null 2>&1; then
        local password
        password=$(get_credential "postgres" "$PGUSER" "PASSWORD" 2>/dev/null)
        if [[ -n "$password" ]]; then
            export PGPASSWORD="$password"
            echo "✅ Loaded from secure storage"
            return 0
        fi
    fi
    
    # Interactive setup
    echo "Enter PostgreSQL password for $PGUSER@$PGHOST:"
    local password store_it
    read -s password
    echo ""

    if [[ -n "$password" ]]; then
        export PGPASSWORD="$password"

        # Offer to store
        echo -n "Store password securely? (y/n): "
        read store_it
        if [[ "$store_it" == "y" ]] && command -v store_credential >/dev/null 2>&1; then
            store_credential "postgres" "$PGUSER" "$password" && echo "🔐 Stored securely"
        fi
        
        echo "✅ Password configured"
    else
        echo "❌ No password entered"
        return 1
    fi
}

# Test PostgreSQL connection
pg_test_connection() {
    echo "🧪 Testing PostgreSQL connection..."
    echo "Connecting to: $PGUSER@$PGHOST:$PGPORT/$PGDATABASE"
    
    if ! command -v psql >/dev/null 2>&1; then
        echo "❌ psql not installed"
        return 1
    fi
    
    if psql -c "SELECT version();" >/dev/null 2>&1; then
        echo "✅ Connection successful"
        psql -c "SELECT version();" | head -3
        return 0
    else
        echo "❌ Connection failed"
        echo "💡 Try: setup_postgres_credentials"
        return 1
    fi
}

# Connect to PostgreSQL
pg_connect() {
    local database="${1:-$PGDATABASE}"
    local flag="$2"
    
    # Handle --test flag
    if [[ "$database" == "--test" || "$flag" == "--test" ]]; then
        pg_test_connection
        return $?
    fi
    
    # Ensure credentials are set
    if [[ -z "$PGPASSWORD" ]]; then
        echo "⚠️  Password not configured"
        setup_postgres_credentials || return 1
    fi
    
    # Connect
    PGDATABASE="$database" psql
}

# Quick psql session
psql_quick() {
    PGDATABASE="${1:-$PGDATABASE}" psql
}

# Show database status
database_status() {
    echo "🗄️  Database Status"
    echo "================="
    
    echo "PostgreSQL:"
    echo "  Host: $PGHOST:$PGPORT"
    echo "  User: $PGUSER"
    echo "  Database: $PGDATABASE"
    echo "  Password: ${PGPASSWORD:+[SET]}"
    
    if command -v psql >/dev/null 2>&1; then
        echo "  psql: $(psql --version | cut -d' ' -f3)"
        
        if psql -c "SELECT 1" >/dev/null 2>&1; then
            echo "  Connection: ✅ Working"
        else
            echo "  Connection: ❌ Failed"
        fi
    else
        echo "  psql: ❌ Not installed"
    fi
}

# Aliases
alias pg='pg_connect'
alias pgtest='pg_test_connection'
alias pgsetup='setup_postgres_credentials'

echo "✅ database loaded"


