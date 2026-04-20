#!/usr/bin/env zsh
# =================================================================
# DOCTOR — fast health checks
# =================================================================
# `zsh_doctor` runs a curated set of environment sanity checks and
# prints a short OK/WARN/FAIL summary. Each individual check runs
# in-process and returns quickly; total runtime should stay under a
# few seconds on a warm cache.

typeset -g _DOCTOR_CHECK_COUNT=0
typeset -g _DOCTOR_OK_COUNT=0
typeset -g _DOCTOR_WARN_COUNT=0
typeset -g _DOCTOR_FAIL_COUNT=0

_doctor_ok()   { printf "  \033[32mok\033[0m    %s\n" "$*"; (( _DOCTOR_OK_COUNT++ )); (( _DOCTOR_CHECK_COUNT++ )); }
_doctor_warn() { printf "  \033[33mwarn\033[0m  %s\n" "$*"; (( _DOCTOR_WARN_COUNT++ )); (( _DOCTOR_CHECK_COUNT++ )); }
_doctor_fail() { printf "  \033[31mFAIL\033[0m  %s\n" "$*"; (( _DOCTOR_FAIL_COUNT++ )); (( _DOCTOR_CHECK_COUNT++ )); }

_doctor_check_has_command() {
    local bin="$1"
    local kind="${2:-required}"  # required|optional
    if command -v "$bin" >/dev/null 2>&1; then
        _doctor_ok "$bin found ($(command -v "$bin"))"
    elif [[ "$kind" == optional ]]; then
        _doctor_warn "$bin not installed (optional)"
    else
        _doctor_fail "$bin missing on PATH"
    fi
}

# Run all curated health checks, print a summary. Returns 0 if no fails.
zsh_doctor() {
    _DOCTOR_CHECK_COUNT=0
    _DOCTOR_OK_COUNT=0
    _DOCTOR_WARN_COUNT=0
    _DOCTOR_FAIL_COUNT=0

    print -- "🩺 zsh_doctor"
    print -- ""

    print -- "● Core tooling"
    _doctor_check_has_command zsh required
    _doctor_check_has_command git required
    _doctor_check_has_command curl required
    _doctor_check_has_command jq optional
    _doctor_check_has_command python3 optional
    _doctor_check_has_command gh optional
    _doctor_check_has_command op optional
    _doctor_check_has_command fzf optional
    _doctor_check_has_command shellcheck optional
    _doctor_check_has_command shfmt optional
    print -- ""

    print -- "● Paths"
    if [[ ":$PATH:" == *":/opt/homebrew/bin:"* || ":$PATH:" == *":/usr/local/bin:"* ]]; then
        _doctor_ok "homebrew/usrlocal on PATH"
    else
        _doctor_warn "neither /opt/homebrew/bin nor /usr/local/bin on PATH"
    fi
    if [[ -d "$HOME/.pyenv" ]]; then
        if [[ ":$PATH:" == *":$HOME/.pyenv/bin:"* ]]; then
            _doctor_ok "pyenv on PATH"
        else
            _doctor_warn "~/.pyenv exists but not on PATH"
        fi
    fi
    print -- ""

    print -- "● XDG cache"
    local xdg_zsh="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
    if [[ -d "$xdg_zsh" ]]; then
        _doctor_ok "$xdg_zsh exists"
    else
        _doctor_warn "$xdg_zsh not yet created (will be on next shell)"
    fi
    if ls "$HOME"/.zcompdump* >/dev/null 2>&1; then
        _doctor_fail "stale ~/.zcompdump* found (should be under \$XDG_CACHE_HOME/zsh/)"
    else
        _doctor_ok "no legacy ~/.zcompdump* in \$HOME"
    fi
    print -- ""

    print -- "● Secrets"
    local secrets_file="${ZSH_SECRETS_FILE:-$HOME/.config/zsh/secrets.env}"
    if [[ -f "$secrets_file" ]]; then
        local perms
        perms="$(stat -f %Lp "$secrets_file" 2>/dev/null || stat -c %a "$secrets_file" 2>/dev/null)"
        if [[ "$perms" == "600" ]]; then
            _doctor_ok "secrets.env permissions are 600"
        else
            _doctor_warn "secrets.env permissions are $perms (want 600)"
        fi
    else
        _doctor_warn "secrets.env not found at $secrets_file"
    fi
    if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then
        _doctor_ok "1Password CLI authenticated"
    elif command -v op >/dev/null 2>&1; then
        _doctor_warn "op installed but not signed in (run: eval \"\$(op signin)\")"
    fi
    print -- ""

    print -- "● Modules"
    local loaded=0 available=0 m
    local modules_dir="${ZSHRC_CONFIG_DIR:-$HOME/.config/zsh}/modules"
    if [[ -d "$modules_dir" ]]; then
        for m in "$modules_dir"/*.zsh(N); do
            (( available++ ))
            # Best-effort: check for a module-named status function.
            local base="${m:t:r}"
            if typeset -f "${base}_status" >/dev/null 2>&1; then
                (( loaded++ ))
            fi
        done
        _doctor_ok "${loaded}/${available} modules expose *_status"
    else
        _doctor_warn "modules dir $modules_dir not found"
    fi
    print -- ""

    print -- "● Summary"
    printf "  %d ok, %d warn, %d fail (total %d)\n" \
        "$_DOCTOR_OK_COUNT" "$_DOCTOR_WARN_COUNT" "$_DOCTOR_FAIL_COUNT" "$_DOCTOR_CHECK_COUNT"

    (( _DOCTOR_FAIL_COUNT == 0 ))
}
