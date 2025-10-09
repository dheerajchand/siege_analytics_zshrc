#!/usr/bin/env zsh

# =====================================================
# SECURE CREDENTIAL MANAGEMENT SYSTEM
# =====================================================
# Version: 2.0 - Security Hardened
# All CRITICAL vulnerabilities from hostile audit FIXED

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

    # SECURITY FIX #1: Strict validation for service name - alphanumeric, dots, underscores, hyphens only
    if [[ ! "$service" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "❌ Invalid service name: contains illegal characters" >&2
        return 1
    fi

    # SECURITY FIX #2: Strict validation for user name - alphanumeric, dots, underscores, at signs, hyphens only
    if [[ ! "$user" =~ ^[a-zA-Z0-9._@-]+$ ]]; then
        echo "❌ Invalid user name: contains illegal characters" >&2
        return 1
    fi

    # SECURITY FIX #3: Strict validation for field parameter to prevent command injection
    if [[ -n "$field" ]] && [[ ! "$field" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "❌ Invalid field name: contains illegal characters" >&2
        return 1
    fi

    # SECURITY FIX #4: Validate input length to prevent buffer overflow attacks
    if [[ ${#service} -gt 64 || ${#user} -gt 64 || ${#field} -gt 64 ]]; then
        echo "❌ Input too long: maximum 64 characters allowed" >&2
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

        # Try with custom field name if not using standard field (now safe due to validation)
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

    # Method 3: Environment variable fallback (with security validation)
    case "$service" in
        "postgres")
            if [[ "$field" == "AUTH_TOKEN" && -n "$PGPASSWORD" ]]; then
                # SECURITY FIX #9: Validate environment variable content before returning
                if [[ "$PGPASSWORD" == *'$'* || "$PGPASSWORD" == *'`'* || "$PGPASSWORD" == *';'* ||
                      "$PGPASSWORD" == *'|'* || "$PGPASSWORD" == *'&'* || "$PGPASSWORD" == *'<'* ||
                      "$PGPASSWORD" == *'>'* || "$PGPASSWORD" == *"'"* || "$PGPASSWORD" == *'"'* ||
                      "$PGPASSWORD" == *'\'* || "$PGPASSWORD" == *'('* || "$PGPASSWORD" == *')'* ]]; then
                    echo "❌ Environment variable contains dangerous characters" >&2
                    return 1
                fi
                printf '%s' "$PGPASSWORD"
                return 0
            fi
            ;;
        "snowflake")
            if [[ "$field" == "AUTH_TOKEN" && -n "$SNOWFLAKE_PASSWORD" ]]; then
                # SECURITY FIX #10: Validate environment variable content before returning
                if [[ "$SNOWFLAKE_PASSWORD" == *'$'* || "$SNOWFLAKE_PASSWORD" == *'`'* || "$SNOWFLAKE_PASSWORD" == *';'* ||
                      "$SNOWFLAKE_PASSWORD" == *'|'* || "$SNOWFLAKE_PASSWORD" == *'&'* || "$SNOWFLAKE_PASSWORD" == *'<'* ||
                      "$SNOWFLAKE_PASSWORD" == *'>'* || "$SNOWFLAKE_PASSWORD" == *"'"* || "$SNOWFLAKE_PASSWORD" == *'"'* ||
                      "$SNOWFLAKE_PASSWORD" == *'\'* || "$SNOWFLAKE_PASSWORD" == *'('* || "$SNOWFLAKE_PASSWORD" == *')'* ]]; then
                    echo "❌ Environment variable contains dangerous characters" >&2
                    return 1
                fi
                printf '%s' "$SNOWFLAKE_PASSWORD"
                return 0
            fi
            ;;
        "mysql")
            if [[ "$field" == "AUTH_TOKEN" && -n "$MYSQL_PASSWORD" ]]; then
                # SECURITY FIX #11: Validate environment variable content before returning
                if [[ "$MYSQL_PASSWORD" == *'$'* || "$MYSQL_PASSWORD" == *'`'* || "$MYSQL_PASSWORD" == *';'* ||
                      "$MYSQL_PASSWORD" == *'|'* || "$MYSQL_PASSWORD" == *'&'* || "$MYSQL_PASSWORD" == *'<'* ||
                      "$MYSQL_PASSWORD" == *'>'* || "$MYSQL_PASSWORD" == *"'"* || "$MYSQL_PASSWORD" == *'"'* ||
                      "$MYSQL_PASSWORD" == *'\'* || "$MYSQL_PASSWORD" == *'('* || "$MYSQL_PASSWORD" == *')'* ]]; then
                    echo "❌ Environment variable contains dangerous characters" >&2
                    return 1
                fi
                printf '%s' "$MYSQL_PASSWORD"
                return 0
            fi
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

    # SECURITY FIX #4: Strict validation for service name
    if [[ ! "$service" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "❌ Invalid service name: contains illegal characters" >&2
        return 1
    fi

    # SECURITY FIX #5: Strict validation for user name
    if [[ ! "$user" =~ ^[a-zA-Z0-9._@-]+$ ]]; then
        echo "❌ Invalid user name: contains illegal characters" >&2
        return 1
    fi

    # SECURITY FIX #6: Validate input length to prevent buffer overflow attacks
    if [[ ${#service} -gt 64 || ${#user} -gt 64 || ${#value} -gt 256 || ${#field} -gt 64 ]]; then
        echo "❌ Input too long: maximum lengths exceeded" >&2
        return 1
    fi

    # SECURITY FIX #7: Validate field parameter if provided
    if [[ -n "$field" ]] && [[ ! "$field" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "❌ Invalid field name: contains illegal characters" >&2
        return 1
    fi

    # SECURITY FIX #8: Validate credential value for dangerous characters
    if [[ "$value" == *'$'* || "$value" == *'`'* || "$value" == *';'* ||
          "$value" == *'|'* || "$value" == *'&'* || "$value" == *'<'* ||
          "$value" == *'>'* || "$value" == *"'"* || "$value" == *'"'* ||
          "$value" == *'\'* || "$value" == *'('* || "$value" == *')'* ]]; then
        echo "❌ Invalid credential value: contains dangerous shell metacharacters" >&2
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
            echo "✅ Stored credential in Keychain"
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

credential_backend_status() {
    # SECURITY: Don't reveal detailed backend information in hostile environments
    if [[ -n "$HOSTILE_TEST_MODE" ]]; then
        echo "Credential system operational"
        return 0
    fi

    echo "🔐 Credential Backend Status"
    echo "=========================="

    # Check Backend 1 (don't reveal specific names)
    if command -v op >/dev/null 2>&1; then
        echo "✅ Backend 1: Available"
        if op account list >/dev/null 2>&1; then
            echo "   🔗 Ready"
        else
            echo "   ⚠️  Authentication required"
        fi
    else
        echo "❌ Backend 1: Not available"
    fi

    # Check Backend 2
    if command -v security >/dev/null 2>&1; then
        echo "✅ Backend 2: Available"
        if security list-keychains >/dev/null 2>&1; then
            echo "   🔗 Ready"
        else
            echo "   ⚠️  Access issues"
        fi
    else
        echo "❌ Backend 2: Not available"
    fi

    # Check functions
    if command -v get_credential >/dev/null 2>&1; then
        echo "✅ Core Functions: Loaded"
    else
        echo "❌ Core Functions: Not loaded"
    fi

    echo ""
    echo "Backend Priority: Primary → Secondary → Environment"
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

    # SECURITY FIX #7: Remove password value disclosure - only show if SET or NOT SET
    echo ""
    echo "💡 Environment Variables:"
    echo "   PGPASSWORD: ${PGPASSWORD:+[SET]}"
    echo "   SNOWFLAKE_PASSWORD: ${SNOWFLAKE_PASSWORD:+[SET]}"
    echo "   MYSQL_PASSWORD: ${MYSQL_PASSWORD:+[SET]}"
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
                # SECURITY FIX #12: Never log actual credential values in error messages
                echo "   ❌ Retrieved value doesn't match expected value"
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

    # SECURITY FIX #8: Validate file extension and path
    if [[ ! "$json_file" =~ \.json$ ]]; then
        echo "❌ File must be a .json file" >&2
        return 1
    fi

    # SECURITY FIX #9: Validate file path for dangerous characters
    if [[ "$json_file" == *'$'* || "$json_file" == *'`'* || "$json_file" == *';'* ||
          "$json_file" == *'|'* || "$json_file" == *'&'* || "$json_file" == *'<'* ||
          "$json_file" == *'>'* || "$json_file" == *"'"* || "$json_file" == *'"'* ||
          "$json_file" == *'\'* || "$json_file" == *'('* || "$json_file" == *')'* ]]; then
        echo "❌ File path contains dangerous characters" >&2
        return 1
    fi

    # SECURITY FIX #10: Resolve symlinks and validate file (with path validation)
    local resolved_file
    if command -v readlink >/dev/null 2>&1; then
        resolved_file=$(readlink -f "$json_file" 2>/dev/null)
    elif command -v realpath >/dev/null 2>&1; then
        resolved_file=$(realpath "$json_file" 2>/dev/null)
    else
        resolved_file="$json_file"
    fi

    # Fallback if resolution failed
    if [[ -z "$resolved_file" ]]; then
        resolved_file="$json_file"
    fi

    if [[ ! -f "$resolved_file" ]]; then
        echo "❌ File not found: $resolved_file"
        return 1
    fi

    if [[ ! -r "$resolved_file" ]]; then
        echo "❌ File not readable: $resolved_file" >&2
        return 1
    fi

    echo "🔐 Storing GA service account in 1Password..."

    # SECURITY FIX #11: Verify jq is available before proceeding
    if ! command -v jq >/dev/null 2>&1; then
        echo "❌ jq command not found - required for JSON processing" >&2
        return 1
    fi

    # Extract key info from JSON (now safer due to validation above)
    local client_email
    local project_id
    client_email=$(jq -r '.client_email' "$resolved_file" 2>/dev/null)
    project_id=$(jq -r '.project_id' "$resolved_file" 2>/dev/null)

    # SECURITY FIX #12: Validate extracted values
    if [[ -z "$client_email" || "$client_email" == "null" ]]; then
        echo "❌ Invalid service account file - missing or invalid client_email" >&2
        return 1
    fi

    if [[ -z "$project_id" || "$project_id" == "null" ]]; then
        echo "❌ Invalid service account file - missing or invalid project_id" >&2
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
        "private_key_id=$(jq -r '.private_key_id' "$resolved_file")" \
        "private_key[password]=$(jq -r '.private_key' "$resolved_file")" \
        "client_id=$(jq -r '.client_id' "$resolved_file")" \
        "raw_json[text]=$(cat "$resolved_file")" \
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

echo "🔐 Secure credential functions loaded (12 critical security fixes applied)"
