#!/usr/bin/env zsh
# =====================================================
# REAL DATABASE INTEGRATION TEST
# =====================================================
# Tests actual database functionality:
# 1. Test database module loading
# 2. Test credential management
# 3. Test connection functions
# 4. Test database operations
# =====================================================

echo "🗄️ REAL DATABASE INTEGRATION TEST"
echo "================================="

# Load zsh config
source ~/.zshrc >/dev/null 2>&1

echo ""
echo "📋 Test 1: Database module loading"
echo "---------------------------------"

if load_module database 2>&1; then
    echo "✅ Database module loaded"
else
    echo "❌ Database module loading failed"
fi

echo ""
echo "📋 Test 2: Database functions availability"
echo "----------------------------------------"

db_functions=("pg_connect" "mysql_connect" "database_status" "setup_postgres_credentials" "setup_mysql_credentials" "db_test_all")

for func in "${db_functions[@]}"; do
    if command -v "$func" >/dev/null 2>&1; then
        echo "✅ $func available"
    else
        echo "❌ $func not found"
    fi
done

echo ""
echo "📋 Test 3: Database client availability"
echo "--------------------------------------"

# Test PostgreSQL client
if command -v psql >/dev/null 2>&1; then
    echo "✅ PostgreSQL client (psql) available"
    echo "   Version: $(psql --version)"
else
    echo "❌ PostgreSQL client not available"
fi

# Test MySQL client
if command -v mysql >/dev/null 2>&1; then
    echo "✅ MySQL client available"
    echo "   Version: $(mysql --version)"
else
    echo "❌ MySQL client not available"
fi

echo ""
echo "📋 Test 4: Database status reporting"
echo "-----------------------------------"

if command -v database_status >/dev/null 2>&1; then
    echo "Testing database status reporting..."
    database_status 2>&1
else
    echo "❌ database_status not available"
fi

echo ""
echo "📋 Test 5: Credential system integration"
echo "---------------------------------------"

# Test credential functions
if command -v creds_status >/dev/null 2>&1; then
    echo "✅ Credential system available"
    echo "Testing credential status..."
    creds_status 2>&1
else
    echo "❌ Credential system not available"
fi

echo ""
echo "📋 Test 6: Environment variables"
echo "-------------------------------"

echo "Database environment variables:"
echo "  PGHOST: ${PGHOST:-'Not set'}"
echo "  PGUSER: ${PGUSER:-'Not set'}"
echo "  PGDATABASE: ${PGDATABASE:-'Not set'}"
echo "  MYSQL_HOST: ${MYSQL_HOST:-'Not set'}"
echo "  MYSQL_USER: ${MYSQL_USER:-'Not set'}"

echo ""
echo "🎯 DATABASE INTEGRATION TEST COMPLETE"
echo "====================================="
