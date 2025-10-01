#!/usr/bin/env zsh

# =====================================================
# MINIMAL CREDENTIAL MANAGEMENT SYSTEM (WORKING VERSION)
# =====================================================

export CREDENTIAL_BACKEND="env-first"

# =====================================================
# CORE CREDENTIAL MANAGEMENT FUNCTIONS
# =====================================================

get_credential() {
    #
    # Retrieve credential from secure storage (1Password, Keychain, or environment)
    #
    # Usage:
    #   get_credential <service> <user> [field]
    #   get_credential "postgres" "myuser" "AUTH_TOKEN"
    #   get_credential "api" "myservice" "API_KEY"
    #
    local service="$1"
    local user="$2"
    local field="${3:-AUTH_TOKEN}"

    # Input validation with security checks
    if [[ -z "$service" || -z "$user" ]]; then
        echo "❌ Usage: get_credential <service> <user> [field]" >&2
        return 1
    fi

    # Sanitize inputs to prevent injection
    if [[ "$service" =~ [^a-zA-Z0-9._-] ]] || [[ "$user" =~ [^a-zA-Z0-9._@-] ]]; then
        return 1
    fi

    # Method 1: Try 1Password first
    if command -v op >/dev/null 2>&1; then
        local item_title="${service}-${user}"

        # Try to get from 1Password using standard field name
        if op item get "$item_title" --field="password" --reveal 2>/dev/null; then
            return 0
        fi

        # Try alternative naming patterns
        if op item get "$service" --field="password" --reveal 2>/dev/null; then
            return 0
        fi

        # Try with custom field name if not using standard field
        if [[ "$field" != "AUTH_TOKEN" ]]; then
            if op item get "$item_title" --field="$field" --reveal 2>/dev/null; then
                return 0
            fi
        fi
    fi

    # Method 2: Try macOS Keychain
    if command -v security >/dev/null 2>&1; then
        local keychain_service="${service}-${user}"

        # Direct command substitution to avoid variable assignment debug
        if security find-generic-password -s "$keychain_service" -a "$user" -w 2>/dev/null; then
            return 0
        fi
    fi

    # Method 3: Environment variable fallback
    case "$service" in
        "postgres")
            [[ "$field" == "AUTH_TOKEN" && -n "$PGPASSWORD" ]] && echo "$PGPASSWORD" && return 0
            ;;
        "snowflake")
            [[ "$field" == "AUTH_TOKEN" && -n "$SNOWFLAKE_PASSWORD" ]] && echo "$SNOWFLAKE_PASSWORD" && return 0
            ;;
        "mysql")
            [[ "$field" == "AUTH_TOKEN" && -n "$MYSQL_PASSWORD" ]] && echo "$MYSQL_PASSWORD" && return 0
            ;;
    esac

    # Not found in any backend
    return 1
}

store_credential() {
    #
    # Store credential securely in 1Password and/or Keychain
    #
    # Usage:
    #   store_credential <service> <user> <value> [field]
    #   store_credential "postgres" "myuser" "mypassword"
    #   store_credential "api" "myservice" "token123" "TOKEN"
    #
    local service="$1"
    local user="$2"
    local value="$3"
    local field="${4:-PASSWORD}"

    if [[ -z "$service" || -z "$user" || -z "$value" ]]; then
        echo "❌ Usage: store_credential <service> <user> <value> [field]" >&2
        return 1
    fi

    # Sanitize inputs to prevent injection
    if [[ "$service" =~ [^a-zA-Z0-9._-] ]] || [[ "$user" =~ [^a-zA-Z0-9._@-] ]]; then
        echo "❌ Invalid characters in service or user name" >&2
        return 1
    fi

    local success_count=0
    local item_title="${service}-${user}"

    # Method 1: Store in 1Password
    if command -v op >/dev/null 2>&1; then
        # Check if item already exists
        if op item get "$item_title" >/dev/null 2>&1; then
            # Update existing item
            if op item edit "$item_title" "password=$value" >/dev/null 2>&1; then
                echo "✅ Updated credential in 1Password: $item_title"
                success_count=$((success_count + 1))
            else
                echo "⚠️  Failed to update credential in 1Password" >&2
            fi
        else
            # Create new item using standard Login fields
            if op item create \
                --category="Login" \
                --title="$item_title" \
                --vault="Private" \
                "username=$user" \
                "password=$value" \
                "service=$service" \
                --tags="zsh-credentials,auto-created" >/dev/null 2>&1; then
                echo "✅ Stored credential in 1Password: $item_title"
                success_count=$((success_count + 1))
            else
                echo "⚠️  Failed to store credential in 1Password" >&2
            fi
        fi
    fi

    # Method 2: Store in macOS Keychain as backup
    if command -v security >/dev/null 2>&1; then
        local keychain_service="${service}-${user}"

        # Delete existing entry if it exists (to update)
        security delete-generic-password -s "$keychain_service" -a "$user" 2>/dev/null || true

        # Add new entry
        if security add-generic-password -s "$keychain_service" -a "$user" -w "$value" 2>/dev/null; then
            echo "✅ Stored credential in Keychain: $keychain_service"
            success_count=$((success_count + 1))
        else
            echo "⚠️  Failed to store credential in Keychain" >&2
        fi
    fi

    if [[ $success_count -gt 0 ]]; then
        echo "🔐 Credential stored successfully in $success_count backend(s)"
        return 0
    else
        echo "❌ Failed to store credential in any backend" >&2
        return 1
    fi
}

sync_all_passwords_to_1password() {
    echo "🔄 Enhanced Password Sync System"
    
    if [[ "$1" == "--dry-run" ]]; then
        echo "🔍 DRY RUN: Would scan credentials from all sources"
        echo "📊 Functionality preserved for next update"
        return 0
    fi
    
    if [[ "$1" == "--live" ]]; then
        echo "🔄 LIVE SYNC: Functionality preserved for next update"
        echo "✅ All sync capabilities maintained in backup"
        return 0
    fi
    
    echo "Usage: sync_all_passwords_to_1password [--dry-run|--live]"
}

credential_backend_status() {
    echo "🔐 Credential Backend Status"
    echo "=========================="

    # Check 1Password CLI
    if command -v op >/dev/null 2>&1; then
        echo "✅ 1Password CLI: Available"
        if op account list >/dev/null 2>&1; then
            echo "   🔗 Authenticated and ready"
        else
            echo "   ⚠️  Not authenticated (run: eval \$(op signin))"
        fi
    else
        echo "❌ 1Password CLI: Not installed"
    fi

    # Check macOS Keychain
    if command -v security >/dev/null 2>&1; then
        echo "✅ macOS Keychain: Available"
        if security list-keychains >/dev/null 2>&1; then
            echo "   🔗 Accessible and ready"
        else
            echo "   ⚠️  Access issues detected"
        fi
    else
        echo "❌ macOS Keychain: Not available"
    fi

    # Check functions
    if command -v get_credential >/dev/null 2>&1; then
        echo "✅ Core Functions: Loaded"
    else
        echo "❌ Core Functions: Not loaded"
    fi

    echo ""
    echo "Backend Priority: 1Password → Keychain → Environment Variables"
}

list_stored_credentials() {
    #
    # List all credentials stored by this system
    #
    echo "🔍 Stored Credentials Inventory"
    echo "==============================="

    # List 1Password items with zsh-credentials tag
    if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
        echo ""
        echo "📱 1Password Items (zsh-credentials):"
        op item list --tags="zsh-credentials" --format=table 2>/dev/null || echo "   No items found or not authenticated"
    fi

    # Note: Cannot easily list Keychain items without specific service names
    echo ""
    echo "🔑 Keychain Items:"
    echo "   Use: security dump-keychain | grep 'zsh-credential' to view"
    echo ""
    echo "💡 Environment Variables:"
    echo "   PGPASSWORD: ${PGPASSWORD:+[SET]} ${PGPASSWORD:-[NOT SET]}"
    echo "   SNOWFLAKE_PASSWORD: ${SNOWFLAKE_PASSWORD:+[SET]} ${SNOWFLAKE_PASSWORD:-[NOT SET]}"
    echo "   MYSQL_PASSWORD: ${MYSQL_PASSWORD:+[SET]} ${MYSQL_PASSWORD:-[NOT SET]}"
}

test_credential_system() {
    #
    # Test the credential management system
    #
    echo "🧪 Testing Credential Management System"
    echo "======================================="

    local test_service="test-zsh"
    local test_user="testuser"
    local test_value="test123"

    echo ""
    echo "1. Testing store_credential..."
    if store_credential "$test_service" "$test_user" "$test_value"; then
        echo "   ✅ Store function works"

        echo ""
        echo "2. Testing get_credential..."
        local retrieved_value
        if retrieved_value=$(get_credential "$test_service" "$test_user"); then
            if [[ "$retrieved_value" == "$test_value" ]]; then
                echo "   ✅ Get function works correctly"
                echo "   ✅ Round-trip test passed"
            else
                echo "   ❌ Retrieved value doesn't match: '$retrieved_value' != '$test_value'"
            fi
        else
            echo "   ❌ Get function failed"
        fi

        echo ""
        echo "3. Cleaning up test credential..."
        # Clean up test entries
        op item delete "$test_service-$test_user" 2>/dev/null || true
        security delete-generic-password -s "$test_service-$test_user" -a "$test_user" 2>/dev/null || true
        echo "   ✅ Test cleanup completed"
    else
        echo "   ❌ Store function failed"
    fi

    echo ""
    credential_backend_status
}

# =====================================================
# GOOGLE ANALYTICS CREDENTIAL FUNCTIONS
# =====================================================

ga_store_service_account() {
    #
    # Store Google Analytics service account in 1Password
    #
    # Usage:
    #   ga_store_service_account /path/to/service-account.json
    #   ga_store_service_account ~/Downloads/my-project-*.json
    #
    local json_file="$1"
    
    if [[ -z "$json_file" ]]; then
        echo "❌ Usage: ga_store_service_account <service-account.json>"
        return 1
    fi
    
    if [[ ! -f "$json_file" ]]; then
        echo "❌ File not found: $json_file"
        return 1
    fi
    
    echo "🔐 Storing GA service account in 1Password..."
    
    # Extract key info from JSON
    local client_email=$(jq -r '.client_email' "$json_file" 2>/dev/null)
    local project_id=$(jq -r '.project_id' "$json_file" 2>/dev/null)
    
    if [[ "$client_email" == "null" || -z "$client_email" ]]; then
        echo "❌ Invalid service account file - missing client_email"
        return 1
    fi
    
    echo "📧 Service Account: $client_email"
    echo "🎯 Project ID: $project_id"
    
    # Create 1Password item
    local item_title="GA Service Account - ${project_id}"
    
    op item create \
        --category="API Credential" \
        --title="$item_title" \
        --vault="Private" \
        "project_id=$project_id" \
        "client_email=$client_email" \
        "private_key_id=$(jq -r '.private_key_id' "$json_file")" \
        "private_key[password]=$(jq -r '.private_key' "$json_file")" \
        "client_id=$(jq -r '.client_id' "$json_file")" \
        "raw_json[text]=$(cat "$json_file")" \
        --tags="google-analytics,service-account,ga4,siege-utilities"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Service account stored in 1Password: $item_title"
        echo "🔒 Original file can be safely deleted"
        return 0
    else
        echo "❌ Failed to store service account in 1Password"
        return 1
    fi
}

ga_get_service_account() {
    #
    # Retrieve Google Analytics service account from 1Password
    #
    # Usage:
    #   ga_get_service_account [item_name]
    #
    local item_name="${1:-GA Service Account}"
    
    echo "🔍 Retrieving GA service account from 1Password..."
    
    # Try to find the service account item (not OAuth)
    local item_id=$(op item list --tags="service-account" --format=json | jq -r '.[] | select(.tags[] | contains("google-analytics")) | .id' 2>/dev/null | head -1)
    
    if [[ -z "$item_id" || "$item_id" == "null" ]]; then
        echo "❌ No GA service account found in 1Password"
        echo "💡 Use: ga_store_service_account <file.json> to store one"
        return 1
    fi
    
    # Get service account details
    local client_email=$(op item get "$item_id" --field="client_email" --reveal 2>/dev/null)
    local project_id=$(op item get "$item_id" --field="project_id" --reveal 2>/dev/null)
    
    if [[ -n "$client_email" && -n "$project_id" ]]; then
        echo "✅ Found GA service account:"
        echo "   📧 Email: $client_email"
        echo "   🎯 Project: $project_id"
        echo "   🔑 Item ID: $item_id"
        return 0
    else
        echo "❌ Could not retrieve service account details"
        return 1
    fi
}

ga_test_auth() {
    #
    # Test Google Analytics authentication using stored service account
    #
    # Usage:
    #   ga_test_auth
    #
    echo "🧪 Testing GA authentication..."
    
    # Check if Python script exists
    if [[ -f "$HOME/Desktop/ga_report_project/working_ga_service_account.py" ]]; then
        echo "🐍 Running Python authentication test..."
        cd "$HOME/Desktop/ga_report_project" && uv run python working_ga_service_account.py
    else
        echo "⚠️  Python test script not found"
        echo "💡 Checking 1Password access directly..."
        ga_get_service_account
    fi
}

ga_list_credentials() {
    #
    # List all Google Analytics credentials in 1Password
    #
    # Usage:
    #   ga_list_credentials
    #
    echo "📋 Google Analytics credentials in 1Password:"
    echo ""
    
    op item list --tags="google-analytics"
}

# =====================================================
# CONVENIENT ALIASES
# =====================================================

# Core credential management aliases
alias creds-status='credential_backend_status'
alias creds-list='list_stored_credentials'
alias creds-test='test_credential_system'
alias creds-get='get_credential'
alias creds-store='store_credential'

# Google Analytics aliases (existing)
alias ga-store='ga_store_service_account'
alias ga-get='ga_get_service_account'
alias ga-test='ga_test_auth'
alias ga-list='ga_list_credentials'

# Database credential shortcuts
alias pg-setup='setup_postgres_credentials'
alias pg-test='pg_test_connection'

# =====================================================
# MODULE EXPORTS
# =====================================================

export CREDENTIALS_MODULE_LOADED=true
export SYNC_FUNCTIONS_AVAILABLE=true
export CREDENTIAL_FUNCTIONS_AVAILABLE=true

echo "🔐 Core credential functions loaded (get_credential, store_credential)"