#!/usr/bin/env zsh
# =================================================================
# SECRETS — profile management
# =================================================================
# Machine profile selection (work, personal, etc.) and the helpers
# that validate / enumerate profiles.

_secrets_check_profile() {
    if [[ -n "${ZSH_ENV_PROFILE:-}" ]]; then
        return 0
    fi
    if [[ -n "${_SECRETS_PROFILE_WARNED:-}" ]]; then
        return 0
    fi
    if [[ -n "${ZSH_TEST_MODE:-}" ]]; then
        return 0
    fi
    if [[ ! -o interactive ]]; then
        return 0
    fi
    _SECRETS_PROFILE_WARNED=1
    _secrets_warn "ZSH_ENV_PROFILE not set. Run: secrets_init_profile"
    _secrets_info "Available profiles: dev, staging, prod, laptop"
    _secrets_info "Run 'secrets_init_profile' for setup wizard"
}

_secrets_profile_list() {
    if typeset -p ZSH_PROFILE_ORDER >/dev/null 2>&1; then
        local -a ordered
        ordered=("${ZSH_PROFILE_ORDER[@]}")
        if typeset -p ZSH_PROFILE_CONFIGS >/dev/null 2>&1; then
            local -a filtered
            local name
            for name in "${ordered[@]}"; do
                [[ -n "${ZSH_PROFILE_CONFIGS[$name]-}" ]] && filtered+=("$name")
            done
            [[ "${#filtered[@]}" -gt 0 ]] && echo "${filtered[*]}" && return 0
        fi
        echo "${ordered[*]}"
        return 0
    fi
    if typeset -p ZSH_PROFILE_CONFIGS >/dev/null 2>&1; then
        local -a keys
        keys=("${(@k)ZSH_PROFILE_CONFIGS}")
        echo "${keys[*]}"
        return 0
    fi
    if [[ -n "${ZSH_PROFILE_LIST:-}" ]]; then
        echo "$ZSH_PROFILE_LIST"
        return 0
    fi
    _secrets_default_profiles
}

_secrets_validate_profile() {
    local profile="${1:-}"
    local list
    list="$(_secrets_profile_list)"
    if [[ " $list " == *" $profile "* ]]; then
        return 0
    fi
    _secrets_warn "Invalid profile: $profile (expected one of: $(_secrets_default_profiles))"
    return 1
}

machine_profile() {
    if [[ -n "${ZSH_ENV_PROFILE:-}" ]]; then
        echo "$ZSH_ENV_PROFILE"
        return 0
    fi
    if command -v hostname >/dev/null 2>&1; then
        hostname -s 2>/dev/null || hostname
        return 0
    fi
    echo "unknown-host"
}

secrets_profile_switch() {
    local profile="" account="${OP_ACCOUNT-}" vault="${OP_VAULT-}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)  profile="${2:-}"; shift 2 ;;
            --account)  account="${2:-}"; shift 2 ;;
            --vault)    vault="${2:-}"; shift 2 ;;
            --help|-h)  echo "Usage: secrets_profile_switch --profile <name> [--account <acct>] [--vault <vault>]" >&2; return 0 ;;
            *)          profile="$1"; shift ;;  # accept bare arg for convenience
        esac
    done
    if [[ -z "$profile" ]]; then
        echo "Usage: secrets_profile_switch --profile <name> [--account <acct>] [--vault <vault>]" >&2
        return 1
    fi
    if ! _secrets_validate_profile "$profile"; then
        echo "Available profiles: $(_secrets_profile_list)" >&2
        return 1
    fi
    _secrets_update_env_file --key "ZSH_ENV_PROFILE" --value "$profile"
    export ZSH_ENV_PROFILE="$profile"
    if [[ -n "$account" ]]; then
        if ! op_set_default "$account" "$vault"; then
            return 1
        fi
    elif [[ -n "$vault" ]]; then
        _secrets_warn "Vault specified without account; clearing vault"
        OP_VAULT=""
        unset OP_VAULT
    fi
    load_secrets
    _secrets_info "Switched profile to $profile"
}

secrets_profiles() {
    local list
    local -a profiles
    list="$(_secrets_profile_list)"
    if [[ -z "$list" ]]; then
        echo "No profiles configured." >&2
        return 1
    fi
    profiles=("${(@s: :)list}")
    local profile desc colors
    for profile in "${profiles[@]}"; do
        desc=""
        colors=""
        if typeset -p ZSH_PROFILE_CONFIGS >/dev/null 2>&1; then
            desc="${ZSH_PROFILE_CONFIGS[$profile]-}"
        fi
        if typeset -p ZSH_PROFILE_COLORS >/dev/null 2>&1; then
            colors="${ZSH_PROFILE_COLORS[$profile]-}"
        fi
        if [[ -n "$colors" && -n "$desc" ]]; then
            echo "$profile - $desc (colors: $colors)"
        elif [[ -n "$desc" ]]; then
            echo "$profile - $desc"
        elif [[ -n "$colors" ]]; then
            echo "$profile (colors: $colors)"
        else
            echo "$profile"
        fi
    done
}

