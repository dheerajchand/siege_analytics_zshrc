#!/usr/bin/env zsh

# =====================================================
# SIMPLIFIED CREDENTIAL MANAGEMENT SYSTEM
# =====================================================
# 
# Simple credential management without associative arrays
# - Environment variables (maintains current workflow)  
# - 1Password CLI integration
# - Apple Keychain (macOS)
# - Interactive prompts (fallback)
#
# Priority: ENV_VARS → 1PASSWORD → APPLE_KEYCHAIN → PROMPT
# =====================================================

# Default credential backend
export CREDENTIAL_BACKEND="${CREDENTIAL_BACKEND:-env-first}"

# =====================================================
# SIMPLIFIED STATUS FUNCTIONS
# =====================================================

credential_backend_status() {
    echo "🔐 Credential Backend Status"
    echo ""
    
    # Environment variables
    echo "  ✅ env: Always available"
    
    # 1Password CLI
    if command -v op >/dev/null 2>&1; then
        if op account list >/dev/null 2>&1; then
            echo "  ✅ 1password: Available and signed in"
        else
            echo "  ⚠️  1password: Available but not signed in"
            echo "     💡 Run: op signin"
        fi
    else
        echo "  ❌ 1password: Not installed"
        echo "     💡 Install: brew install 1password-cli"
    fi
    
    # Apple Keychain (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if security dump-keychain ~/Library/Keychains/login.keychain-db >/dev/null 2>&1; then
            echo "  ✅ apple: Available"
        else
            echo "  ⚠️  apple: Access denied"
        fi
    else
        echo "  ❌ apple: Not available (requires macOS)"
    fi
    
    # Prompt fallback
    echo "  ✅ prompt: Always available (fallback)"
    
    echo ""
    echo "Current backend: ${CREDENTIAL_BACKEND:-env-first}"
}

# =====================================================
# SIMPLIFIED CREDENTIAL RETRIEVAL
# =====================================================

get_credential() {
    local service="$1"
    local username="$2" 
    local field="${3:-password}"
    
    if [[ -z "$service" || -z "$username" ]]; then
        echo "Usage: get_credential <service> <username> [field]" >&2
        return 1
    fi
    
    # Try environment variables first
    local env_var="${service}_${field}"
    local env_value="${(P)env_var}"  # Indirect parameter expansion
    if [[ -n "$env_value" ]]; then
        echo "$env_value"
        return 0
    fi
    
    # Try 1Password
    if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
        local op_result
        op_result=$(op item get "$service" --field="$field" 2>/dev/null)
        if [[ $? -eq 0 && -n "$op_result" ]]; then
            echo "$op_result"
            return 0
        fi
    fi
    
    # Try Apple Keychain (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local keychain_result
        keychain_result=$(security find-generic-password -s "$service" -a "$username" -w 2>/dev/null)
        if [[ $? -eq 0 && -n "$keychain_result" ]]; then
            echo "$keychain_result"
            return 0
        fi
    fi
    
    # Interactive prompt fallback
    echo "Enter $field for $service ($username):" >&2
    read -s credential
    echo "$credential"
}

# =====================================================
# DATABASE INTEGRATION
# =====================================================

get_postgres_password() {
    local pguser="${PGUSER:-$USER}"
    get_credential "postgres" "$pguser" "password"
}

# =====================================================
# ALIASES
# =====================================================

alias creds-status='credential_backend_status'

echo "🔐 Simplified Credential Management loaded"