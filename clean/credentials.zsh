#!/usr/bin/env zsh
# =================================================================
# CREDENTIALS - Secure Credential Management
# =================================================================
# Multi-backend credential storage: 1Password → Keychain → Environment
# Simplified validation (no security theater)
# =================================================================

# Get credential from secure storage
get_credential() {
    local service="$1"
    local user="$2"
    local field="${3:-password}"
    
    # Basic validation only
    if [[ -z "$service" || -z "$user" ]]; then
        echo "Usage: get_credential <service> <user> [field]" >&2
        return 1
    fi
    
    # Try 1Password first
    if command -v op >/dev/null 2>&1; then
        # Try service-user format
        op item get "$service-$user" --field="$field" --reveal 2>/dev/null && return 0
        # Try just service
        op item get "$service" --field="$field" --reveal 2>/dev/null && return 0
    fi
    
    # Try macOS Keychain
    if command -v security >/dev/null 2>&1; then
        security find-generic-password -s "$service-$user" -a "$user" -w 2>/dev/null && return 0
    fi
    
    # Fall back to environment variables
    case "$service" in
        postgres)   [[ -n "$PGPASSWORD" ]] && echo "$PGPASSWORD" && return 0 ;;
        mysql)      [[ -n "$MYSQL_PASSWORD" ]] && echo "$MYSQL_PASSWORD" && return 0 ;;
        snowflake)  [[ -n "$SNOWFLAKE_PASSWORD" ]] && echo "$SNOWFLAKE_PASSWORD" && return 0 ;;
    esac
    
    return 1
}

# Store credential securely
store_credential() {
    local service="$1"
    local user="$2"
    local value="$3"
    
    if [[ -z "$service" || -z "$user" || -z "$value" ]]; then
        echo "Usage: store_credential <service> <user> <value>" >&2
        return 1
    fi
    
    local success=0
    
    # Store in 1Password
    if command -v op >/dev/null 2>&1; then
        if op item get "$service-$user" >/dev/null 2>&1; then
            # Update existing
            op item edit "$service-$user" "password=$value" >/dev/null 2>&1 && {
                echo "✅ Updated in 1Password"
                ((success++))
            }
        else
            # Create new
            op item create \
                --category="Login" \
                --title="$service-$user" \
                --vault="Private" \
                "username=$user" \
                "password=$value" \
                --tags="zsh-credentials" >/dev/null 2>&1 && {
                echo "✅ Stored in 1Password"
                ((success++))
            }
        fi
    fi
    
    # Store in Keychain as backup
    if command -v security >/dev/null 2>&1; then
        # Delete existing first
        security delete-generic-password -s "$service-$user" -a "$user" 2>/dev/null
        # Add new
        security add-generic-password -s "$service-$user" -a "$user" -w "$value" 2>/dev/null && {
            echo "✅ Stored in Keychain"
            ((success++))
        }
    fi
    
    if [[ $success -gt 0 ]]; then
        echo "🔐 Stored in $success backend(s)"
        return 0
    else
        echo "❌ Storage failed"
        return 1
    fi
}

# Check credential backend status
credential_backend_status() {
    echo "🔐 Credential Backends"
    echo "===================="
    
    # 1Password
    if command -v op >/dev/null 2>&1; then
        if op account list >/dev/null 2>&1; then
            echo "✅ 1Password: Ready"
        else
            echo "⚠️  1Password: Authentication required (run: op signin)"
        fi
    else
        echo "❌ 1Password: Not installed"
    fi
    
    # Keychain
    if command -v security >/dev/null 2>&1; then
        echo "✅ Keychain: Available"
    else
        echo "❌ Keychain: Not available"
    fi
    
    # Environment variables
    echo ""
    echo "Environment variables:"
    echo "  PGPASSWORD: ${PGPASSWORD:+[SET]}"
    echo "  MYSQL_PASSWORD: ${MYSQL_PASSWORD:+[SET]}"
    echo "  SNOWFLAKE_PASSWORD: ${SNOWFLAKE_PASSWORD:+[SET]}"
}

# Google Analytics service account management
ga_store_service_account() {
    local json_file="$1"
    
    if [[ ! -f "$json_file" ]]; then
        echo "Usage: ga_store_service_account <service-account.json>"
        return 1
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        echo "❌ jq not installed (brew install jq)"
        return 1
    fi
    
    local client_email=$(jq -r '.client_email' "$json_file" 2>/dev/null)
    local project_id=$(jq -r '.project_id' "$json_file" 2>/dev/null)
    
    if [[ -z "$client_email" || "$client_email" == "null" ]]; then
        echo "❌ Invalid service account file"
        return 1
    fi
    
    echo "📧 Service Account: $client_email"
    echo "🎯 Project: $project_id"
    
    op item create \
        --category="API Credential" \
        --title="GA-$project_id" \
        --vault="Private" \
        "project_id=$project_id" \
        "client_email=$client_email" \
        "private_key[password]=$(jq -r '.private_key' "$json_file")" \
        "raw_json[text]=$(cat "$json_file")" \
        --tags="google-analytics,service-account"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Stored in 1Password"
        echo "🔒 Original file can be deleted"
    else
        echo "❌ Storage failed"
        return 1
    fi
}

ga_get_service_account() {
    if ! command -v op >/dev/null 2>&1; then
        echo "❌ 1Password CLI not installed"
        return 1
    fi
    
    local item_id=$(op item list --tags="service-account,google-analytics" --format=json 2>/dev/null | jq -r '.[0].id')
    
    if [[ -z "$item_id" || "$item_id" == "null" ]]; then
        echo "❌ No GA service account found"
        echo "💡 Use: ga_store_service_account <file.json>"
        return 1
    fi
    
    local client_email=$(op item get "$item_id" --field="client_email" --reveal 2>/dev/null)
    local project_id=$(op item get "$item_id" --field="project_id" --reveal 2>/dev/null)
    
    echo "✅ Found GA service account:"
    echo "   📧 Email: $client_email"
    echo "   🎯 Project: $project_id"
}

ga_list_credentials() {
    echo "📋 Google Analytics Credentials"
    op item list --tags="google-analytics" 2>/dev/null
}

# Test credential system with round-trip
test_credential_system() {
    echo "🧪 Testing credential system..."
    
    local test_pass="test123"
    
    if store_credential "test-zsh" "testuser" "$test_pass"; then
        local retrieved=$(get_credential "test-zsh" "testuser")
        if [[ "$retrieved" == "$test_pass" ]]; then
            echo "✅ Round-trip test passed"
            # Cleanup
            op item delete "test-zsh-testuser" 2>/dev/null
            security delete-generic-password -s "test-zsh-testuser" -a "testuser" 2>/dev/null
        else
            echo "❌ Retrieved value doesn't match"
            return 1
        fi
    else
        echo "❌ Store failed"
        return 1
    fi
}

# Aliases
alias creds-get='get_credential'
alias creds-store='store_credential'
alias creds-status='credential_backend_status'
alias creds-test='test_credential_system'
alias ga-store='ga_store_service_account'
alias ga-get='ga_get_service_account'
alias ga-list='ga_list_credentials'
alias pg-setup='setup_postgres_credentials'
alias pg-test='pg_test_connection'

echo "✅ credentials loaded"



