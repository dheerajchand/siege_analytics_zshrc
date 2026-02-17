#!/usr/bin/env zsh
# =================================================================
# CREDENTIALS - Secure Credential Management
# =================================================================
# Multi-backend credential storage: 1Password → Keychain → Environment
# Simplified validation (no security theater)
# =================================================================

# Backend order (space-separated). Override in your shell if needed.
: "${CRED_BACKENDS:=op keychain env}"
# Backends to write into (space-separated). Defaults to safest set.
: "${CRED_STORE_BACKENDS:=op keychain}"
# OP_VAULT is defined by secrets module; only default when account is set.
[[ -n "${OP_ACCOUNT:-}" ]] && : "${OP_VAULT:=Private}"

_cred_backends() {
    echo "${=CRED_BACKENDS}"
}

_cred_store_backends() {
    echo "${=CRED_STORE_BACKENDS}"
}

_cred_is_known_backend() {
    case "$1" in
        op|keychain|env|vault|aws) return 0 ;;
        *) return 1 ;;
    esac
}

_cred_warn_unknown_backend() {
    echo "⚠️  Unknown credential backend: $1" >&2
}

_cred_get_op() {
    local service="$1" user="$2" field="$3"
    command -v op >/dev/null 2>&1 || return 1
    op item get "$service-$user" \
        ${OP_ACCOUNT:+--account="$OP_ACCOUNT"} \
        ${OP_VAULT:+--vault="$OP_VAULT"} \
        --field="$field" --reveal 2>/dev/null && return 0
    op item get "$service" \
        ${OP_ACCOUNT:+--account="$OP_ACCOUNT"} \
        ${OP_VAULT:+--vault="$OP_VAULT"} \
        --field="$field" --reveal 2>/dev/null && return 0
    return 1
}

_cred_put_op() {
    local service="$1" user="$2" value="$3"
    command -v op >/dev/null 2>&1 || return 1
    if op item get "$service-$user" >/dev/null 2>&1; then
        op item edit "$service-$user" \
            ${OP_ACCOUNT:+--account="$OP_ACCOUNT"} \
            ${OP_VAULT:+--vault="$OP_VAULT"} \
            "password=$value" >/dev/null 2>&1 && {
            echo "✅ Updated in 1Password"
            return 0
        }
        return 1
    fi
    op item create \
        --category="Login" \
        --title="$service-$user" \
        --vault="$OP_VAULT" \
        ${OP_ACCOUNT:+--account="$OP_ACCOUNT"} \
        "username=$user" \
        "password=$value" \
        --tags="zsh-credentials" >/dev/null 2>&1 && {
        echo "✅ Stored in 1Password"
        return 0
    }
    return 1
}

_cred_status_op() {
    if command -v op >/dev/null 2>&1; then
        if op account list >/dev/null 2>&1; then
            echo "✅ 1Password: Ready (account: ${OP_ACCOUNT:-default} vault: $OP_VAULT)"
        else
            echo "⚠️  1Password: Authentication required (run: op signin)"
        fi
    else
        echo "❌ 1Password: Not installed"
    fi
}

_cred_get_keychain() {
    local service="$1" user="$2"
    command -v security >/dev/null 2>&1 || return 1
    security find-generic-password -s "$service-$user" -a "$user" -w 2>/dev/null
}

_cred_put_keychain() {
    local service="$1" user="$2" value="$3"
    command -v security >/dev/null 2>&1 || return 1
    security delete-generic-password -s "$service-$user" -a "$user" 2>/dev/null
    security add-generic-password -s "$service-$user" -a "$user" -w "$value" 2>/dev/null && {
        echo "✅ Stored in Keychain"
        return 0
    }
    return 1
}

_cred_status_keychain() {
    if command -v security >/dev/null 2>&1; then
        echo "✅ Keychain: Available"
    else
        echo "❌ Keychain: Not available"
    fi
}

_cred_get_env() {
    local service="$1"
    case "$service" in
        postgres)   [[ -n "$PGPASSWORD" ]] && echo "$PGPASSWORD" && return 0 ;;
        mysql)      [[ -n "$MYSQL_PASSWORD" ]] && echo "$MYSQL_PASSWORD" && return 0 ;;
        snowflake)  [[ -n "$SNOWFLAKE_PASSWORD" ]] && echo "$SNOWFLAKE_PASSWORD" && return 0 ;;
    esac
    return 1
}

_cred_put_env() {
    return 1
}

_cred_status_env() {
    echo "Environment variables:"
    echo "  PGPASSWORD: ${PGPASSWORD:+[SET]}"
    echo "  MYSQL_PASSWORD: ${MYSQL_PASSWORD:+[SET]}"
    echo "  SNOWFLAKE_PASSWORD: ${SNOWFLAKE_PASSWORD:+[SET]}"
}

_cred_get_vault() {
    command -v vault >/dev/null 2>&1 || return 1
    if [[ -z "${VAULT_ADDR:-}" || -z "${VAULT_TOKEN:-}" ]]; then
        echo "Vault backend configured but VAULT_ADDR/VAULT_TOKEN not set." >&2
        return 1
    fi
    return 1
}

_cred_put_vault() {
    command -v vault >/dev/null 2>&1 || return 1
    if [[ -z "${VAULT_ADDR:-}" || -z "${VAULT_TOKEN:-}" ]]; then
        echo "Vault backend configured but VAULT_ADDR/VAULT_TOKEN not set." >&2
        return 1
    fi
    return 1
}

_cred_status_vault() {
    if command -v vault >/dev/null 2>&1; then
        echo "⚠️  Vault: CLI present, backend not wired (configure VAULT_ADDR and token)"
    else
        echo "❌ Vault: Not installed"
    fi
}

_cred_get_aws() {
    command -v aws >/dev/null 2>&1 || return 1
    if [[ -z "${AWS_PROFILE:-}" && -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
        echo "AWS backend configured but AWS_PROFILE or access keys not set." >&2
        return 1
    fi
    return 1
}

_cred_put_aws() {
    command -v aws >/dev/null 2>&1 || return 1
    if [[ -z "${AWS_PROFILE:-}" && -z "${AWS_ACCESS_KEY_ID:-}" ]]; then
        echo "AWS backend configured but AWS_PROFILE or access keys not set." >&2
        return 1
    fi
    return 1
}

_cred_status_aws() {
    if command -v aws >/dev/null 2>&1; then
        echo "⚠️  AWS Secrets Manager: CLI present, backend not wired (configure AWS_PROFILE/AWS_REGION)"
    else
        echo "❌ AWS Secrets Manager: Not installed"
    fi
}

# Get credential from secure storage
get_credential() {
    local service="$1"
    local user="$2"
    local field="${3:-password}"

    if [[ -z "$service" || -z "$user" ]]; then
        echo "Usage: get_credential <service> <user> [field]" >&2
        return 1
    fi

    local backend
    for backend in $(_cred_backends); do
        if ! _cred_is_known_backend "$backend"; then
            _cred_warn_unknown_backend "$backend"
            continue
        fi
        case "$backend" in
            op)        _cred_get_op "$service" "$user" "$field" && return 0 ;;
            keychain)  _cred_get_keychain "$service" "$user" && return 0 ;;
            env)       _cred_get_env "$service" && return 0 ;;
            vault)     _cred_get_vault "$service" "$user" "$field" && return 0 ;;
            aws)       _cred_get_aws "$service" "$user" "$field" && return 0 ;;
        esac
    done

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
    local backend
    for backend in $(_cred_store_backends); do
        if ! _cred_is_known_backend "$backend"; then
            _cred_warn_unknown_backend "$backend"
            continue
        fi
        case "$backend" in
            op)        _cred_put_op "$service" "$user" "$value" && ((success++)) ;;
            keychain)  _cred_put_keychain "$service" "$user" "$value" && ((success++)) ;;
            env)       _cred_put_env "$service" "$user" "$value" && true ;;
            vault)     _cred_put_vault "$service" "$user" "$value" && ((success++)) ;;
            aws)       _cred_put_aws "$service" "$user" "$value" && ((success++)) ;;
        esac
    done

    if [[ $success -gt 0 ]]; then
        echo "🔐 Stored in $success backend(s)"
        return 0
    fi

    echo "❌ Storage failed"
    return 1
}

# Check credential backend status
credential_backend_status() {
    echo "🔐 Credential Backends"
    echo "===================="

    _cred_status_op
    _cred_status_keychain
    _cred_status_vault
    _cred_status_aws
    echo ""
    _cred_status_env
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

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ credentials loaded"
fi
