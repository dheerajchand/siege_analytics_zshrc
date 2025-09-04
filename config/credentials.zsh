#!/usr/bin/env zsh

# =====================================================
# CREDENTIAL MANAGEMENT SYSTEM
# =====================================================
# 
# Flexible credential management supporting multiple backends:
# - Environment variables (maintains current workflow)
# - 1Password CLI integration
# - Apple Keychain (macOS)
# - Interactive prompts (fallback)
#
# Priority: ENV_VARS → 1PASSWORD → APPLE_KEYCHAIN → PROMPT
# Maintains backward compatibility with existing psql/Snowflake workflows
# =====================================================

# Default credential backend (env-first maintains current workflow)
export CREDENTIAL_BACKEND="${CREDENTIAL_BACKEND:-env-first}"

# Backend availability cache
typeset -gA CREDENTIAL_BACKEND_CACHE

# =====================================================
# BACKEND DETECTION & AVAILABILITY
# =====================================================

detect_credential_backends() {
    # Detect and cache available credential backends
    #
    # Returns: Array of available backend names
    #
    # Caches results for performance
    local -a available=()
    
    # Environment variables always available
    available+=("env")
    CREDENTIAL_BACKEND_CACHE[env]="true"
    
    # Check 1Password CLI
    if command -v op >/dev/null 2>&1; then
        # Verify 1Password is signed in
        if op account list >/dev/null 2>&1; then
            available+=("1password")
            CREDENTIAL_BACKEND_CACHE[1password]="true"
        else
            CREDENTIAL_BACKEND_CACHE[1password]="not_signed_in"
        fi
    else
        CREDENTIAL_BACKEND_CACHE[1password]="not_installed"
    fi
    
    # Check Apple Keychain (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]] && command -v security >/dev/null 2>&1; then
        available+=("apple")
        CREDENTIAL_BACKEND_CACHE[apple]="true"
    else
        CREDENTIAL_BACKEND_CACHE[apple]="not_available"
    fi
    
    # Interactive prompts always available as fallback
    available+=("prompt")
    CREDENTIAL_BACKEND_CACHE[prompt]="true"
    
    printf '%s\n' "${available[@]}"
}

credential_backend_status() {
    # Show status of all credential backends
    echo "🔐 Credential Backend Status"
    echo ""
    
    local -a backends=(env 1password apple prompt)
    for backend in "${backends[@]}"; do
        local backend_status="${CREDENTIAL_BACKEND_CACHE[$backend]:-unknown}"
        case "$backend_status" in
            "true")
                echo "  ✅ $backend: Available"
                ;;
            "not_signed_in")
                echo "  ⚠️  $backend: Available but not signed in"
                echo "     💡 Run: op signin"
                ;;
            "not_installed")
                echo "  ❌ $backend: Not installed"
                ;;
            "not_available")
                echo "  ❌ $backend: Not available on this platform"
                ;;
            *)
                echo "  ❓ $backend: Unknown $backend_status"
                ;;
        esac
    done
    
    echo ""
    echo "Current backend: $CREDENTIAL_BACKEND"
}

# =====================================================
# CREDENTIAL RETRIEVAL FUNCTIONS
# =====================================================

get_credential_env() {
    # Get credential from environment variables
    #
    # Args:
    #     service (str): Service name (e.g., "postgres", "snowflake")
    #     account (str): Account/username
    #     field (str): Field type (PASSWORD, TOKEN, etc.)
    #
    # Returns:
    #     str: Credential value or empty if not found
    local service="$1"
    local account="$2"
    local field="${3:-PASSWORD}"
    
    # Try multiple environment variable naming patterns
    local -a env_patterns=(
        "${service}_${field}"                    # POSTGRES_PASSWORD
        "${service}_${account}_${field}"         # POSTGRES_USER_PASSWORD
        "${service^^}_${field}"                  # POSTGRES_PASSWORD (uppercase)
        "$(echo $service | tr '[:lower:]' '[:upper:]')_${field}"  # POSTGRES_PASSWORD
    )
    
    for pattern in "${env_patterns[@]}"; do
        local env_var_name="$(echo $pattern | tr '[:lower:]' '[:upper:]')"
        local credential="${(P)env_var_name}"
        
        if [[ -n "$credential" ]]; then
            echo "$credential"
            return 0
        fi
    done
    
    return 1
}

get_credential_1password() {
    # Get credential from 1Password
    #
    # Args:
    #     service (str): Service name
    #     account (str): Account name  
    #     field (str): Field to retrieve (default: password)
    #
    # Returns:
    #     str: Credential value or empty if not found
    local service="$1"
    local account="$2"
    local field="${3:-password}"
    
    if [[ "${CREDENTIAL_BACKEND_CACHE[1password]}" != "true" ]]; then
        return 1
    fi
    
    # Try to find item by service name
    local credential
    credential=$(op item get "$service" --field "$field" 2>/dev/null) && {
        echo "$credential"
        return 0
    }
    
    # Try with account qualifier
    credential=$(op item get "${service}-${account}" --field "$field" 2>/dev/null) && {
        echo "$credential"
        return 0
    }
    
    return 1
}

get_credential_apple() {
    # Get credential from Apple Keychain
    #
    # Args:
    #     service (str): Service name
    #     account (str): Account name
    #
    # Returns:
    #     str: Credential value or empty if not found
    local service="$1"
    local account="$2"
    
    if [[ "${CREDENTIAL_BACKEND_CACHE[apple]}" != "true" ]]; then
        return 1
    fi
    
    # Try to get from keychain
    local credential
    credential=$(security find-generic-password -s "$service" -a "$account" -w 2>/dev/null) && {
        echo "$credential"
        return 0
    }
    
    return 1
}

get_credential_prompt() {
    # Get credential via interactive prompt
    #
    # Args:
    #     service (str): Service name
    #     account (str): Account name
    #     field (str): Field type for display
    #
    # Returns:
    #     str: User-entered credential
    local service="$1"
    local account="$2"
    local field="${3:-password}"
    
    local prompt_text="Enter $field for $account@$service: "
    echo -n "$prompt_text" >&2
    
    local credential
    read -s credential
    echo >&2  # New line after password input
    
    if [[ -n "$credential" ]]; then
        echo "$credential"
        return 0
    fi
    
    return 1
}

# =====================================================
# MAIN CREDENTIAL INTERFACE
# =====================================================

get_credential() {
    # Get credential using configured backend priority
    #
    # Args:
    #     service (str): Service name (e.g., "postgres", "snowflake")
    #     account (str): Account/username
    #     field (str, optional): Field type (default: PASSWORD)
    #
    # Returns:
    #     str: The credential value
    #     int: 0 on success, 1 on failure
    #         
    # Examples:
    #     get_credential "postgres" "dheerajchand"
    #     get_credential "snowflake" "dheerajchand" "TOKEN"
    #     PGPASSWORD=$(get_credential "postgres" "$PGUSER")
    local service="$1"
    local account="$2"  
    local field="${3:-PASSWORD}"
    
    if [[ -z "$service" || -z "$account" ]]; then
        echo "Usage: get_credential <service> <account> [field]" >&2
        return 1
    fi
    
    # Ensure backends are detected
    if [[ -z "${CREDENTIAL_BACKEND_CACHE[env]}" ]]; then
        detect_credential_backends >/dev/null
    fi
    
    local credential=""
    local backend_order=()
    
    # Set backend priority based on configuration
    case "$CREDENTIAL_BACKEND" in
        "env-first"|"")
            backend_order=(env 1password apple prompt)
            ;;
        "1password-first")
            backend_order=(1password env apple prompt)
            ;;
        "apple-first")
            backend_order=(apple 1password env prompt)
            ;;
        "env-only")
            backend_order=(env)
            ;;
        *)
            # Single backend specified
            backend_order=("$CREDENTIAL_BACKEND")
            ;;
    esac
    
    # Try backends in priority order
    for backend in "${backend_order[@]}"; do
        case "$backend" in
            "env")
                credential=$(get_credential_env "$service" "$account" "$field") && {
                    echo "$credential"
                    return 0
                }
                ;;
            "1password")
                credential=$(get_credential_1password "$service" "$account" "$field") && {
                    echo "$credential"
                    return 0
                }
                ;;
            "apple")
                credential=$(get_credential_apple "$service" "$account") && {
                    echo "$credential"
                    return 0
                }
                ;;
            "prompt")
                credential=$(get_credential_prompt "$service" "$account" "$field") && {
                    echo "$credential"
                    return 0
                }
                ;;
        esac
    done
    
    echo "Failed to retrieve credential for $account@$service" >&2
    return 1
}

# =====================================================
# DATABASE-SPECIFIC HELPERS
# =====================================================

get_postgres_password() {
    # Get PostgreSQL password (maintains PGPASSWORD compatibility)
    #
    # Checks environment variables first to maintain current workflow
    #
    # Returns:
    #     str: PostgreSQL password
    get_credential "postgres" "${PGUSER:-$USER}" "PASSWORD"
}

get_snowflake_password() {
    # Get Snowflake password
    #
    # Args:
    #     user (str, optional): Snowflake username (default: SNOWFLAKE_USER or USER)
    #
    # Returns:
    #     str: Snowflake password
    local user="${1:-${SNOWFLAKE_USER:-$USER}}"
    get_credential "snowflake" "$user" "PASSWORD"
}

get_mysql_password() {
    # Get MySQL password
    #
    # Args:
    #     user (str, optional): MySQL username (default: MYSQL_USER or USER)
    #
    # Returns:
    #     str: MySQL password
    local user="${1:-${MYSQL_USER:-$USER}}"
    get_credential "mysql" "$user" "PASSWORD"
}

# =====================================================
# CREDENTIAL STORAGE (for secure backends)
# =====================================================

store_credential() {
    # Store credential in preferred secure backend
    #
    # Args:
    #     service (str): Service name
    #     account (str): Account name
    #     credential (str): Credential to store
    #     backend (str, optional): Backend to use (default: auto-detect best)
    #
    # Returns:
    #     int: 0 on success, 1 on failure
    local service="$1"
    local account="$2"
    local credential="$3"
    local backend="${4:-auto}"
    
    if [[ -z "$service" || -z "$account" || -z "$credential" ]]; then
        echo "Usage: store_credential <service> <account> <credential> [backend]" >&2
        return 1
    fi
    
    if [[ "$backend" == "auto" ]]; then
        # Auto-select best available storage backend
        if [[ "${CREDENTIAL_BACKEND_CACHE[1password]}" == "true" ]]; then
            backend="1password"
        elif [[ "${CREDENTIAL_BACKEND_CACHE[apple]}" == "true" ]]; then
            backend="apple"
        else
            echo "No secure storage backend available" >&2
            echo "Install 1Password CLI or use macOS Keychain" >&2
            return 1
        fi
    fi
    
    case "$backend" in
        "1password")
            # Store in 1Password
            if op item create --category login --title "$service" \
                --field "username=$account" \
                --field "password=$credential" 2>/dev/null; then
                echo "✅ Stored $service credentials in 1Password"
                return 0
            else
                echo "❌ Failed to store in 1Password" >&2
                return 1
            fi
            ;;
        "apple")
            # Store in Apple Keychain
            if security add-generic-password -s "$service" -a "$account" \
                -w "$credential" -U 2>/dev/null; then
                echo "✅ Stored $service credentials in Apple Keychain"
                return 0
            else
                echo "❌ Failed to store in Apple Keychain" >&2
                return 1
            fi
            ;;
        *)
            echo "Unsupported storage backend: $backend" >&2
            return 1
            ;;
    esac
}

# =====================================================
# CONFIGURATION FUNCTIONS
# =====================================================

set_credential_backend() {
    # Set the credential backend preference
    #
    # Args:
    #     backend (str): Backend name or strategy
    #                   Options: env-first, 1password-first, apple-first, env-only
    local backend="$1"
    
    if [[ -z "$backend" ]]; then
        echo "Available backends:"
        echo "  env-first      - Environment variables first (current workflow)"
        echo "  1password-first - 1Password first, env fallback"
        echo "  apple-first    - Apple Keychain first, env fallback"  
        echo "  env-only       - Environment variables only"
        echo ""
        echo "Current: $CREDENTIAL_BACKEND"
        return 0
    fi
    
    local valid_backends=("env-first" "1password-first" "apple-first" "env-only")
    if (( ! ${valid_backends[(Ie)$backend]} )); then
        echo "Invalid backend: $backend" >&2
        echo "Valid options: ${valid_backends[@]}" >&2
        return 1
    fi
    
    export CREDENTIAL_BACKEND="$backend"
    echo "Credential backend set to: $backend"
}

# =====================================================
# TESTING FUNCTIONS
# =====================================================

test_credentials() {
    # Test credential system with common services
    echo "🧪 Testing Credential System"
    echo ""
    
    # Test environment detection
    echo "Backend Detection:"
    detect_credential_backends | while read backend; do
        echo "  ✅ $backend available"
    done
    echo ""
    
    # Test PostgreSQL (if configured)
    if [[ -n "$PGUSER" ]]; then
        echo "Testing PostgreSQL credentials..."
        if password=$(get_postgres_password); then
            echo "  ✅ PostgreSQL: Retrieved successfully"
        else
            echo "  ❌ PostgreSQL: Failed to retrieve"
        fi
    fi
    
    credential_backend_status
}

# =====================================================
# ALIASES AND HELPERS
# =====================================================

alias creds-status='credential_backend_status'
alias creds-test='test_credentials'
alias creds-backend='set_credential_backend'

# =====================================================
# INITIALIZATION
# =====================================================

# Detect available backends on module load
detect_credential_backends >/dev/null

# Set up environment compatibility if needed
if [[ "$CREDENTIAL_AUTO_SETUP" == "true" ]]; then
    # Auto-setup PGPASSWORD if not set but credentials available
    if [[ -z "$PGPASSWORD" && -n "$PGUSER" ]]; then
        export PGPASSWORD="$(get_postgres_password 2>/dev/null || echo "")"
    fi
fi