#!/usr/bin/env zsh
# =================================================================
# SECRETS — rsync-based host sync
# =================================================================
# Copy secrets env files to/from peer hosts (e.g. cyberpower) via rsync
# and verify the transfer.

_secrets_rsync_parse_args() {
    local user="" host="" path="" remote=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --user)
                user="$2"
                shift 2
                ;;
            --host)
                host="$2"
                shift 2
                ;;
            --path)
                path="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: $0 [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
                return 2
                ;;
            *)
                if [[ -z "$remote" ]]; then
                    remote="$1"
                elif [[ -z "$path" ]]; then
                    path="$1"
                else
                    echo "Usage: $0 [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
                    return 2
                fi
                shift
                ;;
        esac
    done
    if [[ -n "$user" || -n "$host" ]]; then
        [[ -z "$host" ]] && return 1
        if [[ -n "$user" ]]; then
            remote="${user}@${host}"
        else
            remote="$host"
        fi
    fi
    if [[ -z "$path" ]]; then
        path="$(_secrets_remote_path_default)"
    fi
    echo "$remote" "$path"
    return 0
}

secrets_rsync_to_host() {
    local parsed remote remote_path
    parsed="$(_secrets_rsync_parse_args "$@")" || {
        echo "Usage: secrets_rsync_to_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    }
    remote="${parsed%% *}"
    remote_path="${parsed#* }"
    if [[ -z "$remote" ]]; then
        echo "Usage: secrets_rsync_to_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    fi
    if ! command -v rsync >/dev/null 2>&1; then
        _secrets_warn "rsync not found; cannot sync secrets"
        return 1
    fi
    local src_base
    src_base="$(_secrets_local_path_default)"
    local -a src_files=()
    local _f
    for _f in "${_SECRETS_SYNC_FILES[@]}"; do src_files+=("$src_base/$_f"); done
    rsync -av --chmod=Fu=rw,Fgo=,Du=rwx,Dgo= \
        --rsync-path="mkdir -p ${remote_path} && rsync" \
        "${src_files[@]}" \
        "${remote}:${remote_path}/"
}

secrets_rsync_from_host() {
    local parsed remote remote_path
    parsed="$(_secrets_rsync_parse_args "$@")" || {
        echo "Usage: secrets_rsync_from_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    }
    remote="${parsed%% *}"
    remote_path="${parsed#* }"
    if [[ -z "$remote" ]]; then
        echo "Usage: secrets_rsync_from_host [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    fi
    if ! command -v rsync >/dev/null 2>&1; then
        _secrets_warn "rsync not found; cannot sync secrets"
        return 1
    fi
    local dest_base
    dest_base="$(_secrets_local_path_default)"
    umask 077
    mkdir -p "$dest_base"
    local -a remote_files=()
    local _f
    for _f in "${_SECRETS_SYNC_FILES[@]}"; do remote_files+=("${remote}:${remote_path}/$_f"); done
    rsync -av --chmod=Fu=rw,Fgo=,Du=rwx,Dgo= \
        "${remote_files[@]}" \
        "$dest_base/"
}

secrets_rsync_to_cyberpower() {
    local user="${1:-${USER}}"
    secrets_rsync_to_host --user "$user" --host "cyberpower"
}

secrets_rsync_from_cyberpower() {
    local user="${1:-${USER}}"
    secrets_rsync_from_host --user "$user" --host "cyberpower"
}

secrets_rsync_verify() {
    local parsed remote remote_path
    parsed="$(_secrets_rsync_parse_args "$@")" || {
        echo "Usage: secrets_rsync_verify [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    }
    remote="${parsed%% *}"
    remote_path="${parsed#* }"
    if [[ -z "$remote" ]]; then
        echo "Usage: secrets_rsync_verify [--user <user>] --host <host> [--path <path>] | <user@host> [remote_path]" >&2
        return 1
    fi
    if ! command -v ssh >/dev/null 2>&1; then
        _secrets_warn "ssh not found; cannot verify remote"
        return 1
    fi
    local base
    base="$(_secrets_local_path_default)"
    local missing=0
    for f in "${_SECRETS_SYNC_FILES[@]}"; do
        if [[ ! -f "$base/$f" ]]; then
            _secrets_warn "Missing local file: $base/$f"
            missing=1
        fi
    done
    local _test_cmd="true"
    for f in "${_SECRETS_SYNC_FILES[@]}"; do _test_cmd="$_test_cmd && test -f ${remote_path}/$f"; done
    ssh "$remote" "$_test_cmd" >/dev/null 2>&1 || {
        _secrets_warn "Missing one or more remote files in ${remote_path}"
        missing=1
    }
    if [[ "$missing" -eq 0 ]]; then
        _secrets_info "Secrets files present locally and on ${remote}:${remote_path}"
        return 0
    fi
    return 1
}

