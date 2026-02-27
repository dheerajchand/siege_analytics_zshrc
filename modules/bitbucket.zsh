#!/usr/bin/env zsh

# -----------------------------------------------------------------
# Bitbucket repo helpers
# -----------------------------------------------------------------
# Requires:
#   BITBUCKET_WORKSPACE
#   BITBUCKET_TOKEN (preferred)
#   BITBUCKET_USERNAME
#   BITBUCKET_APP_PASSWORD

_bitbucket_require_auth() {
    local workspace="${1:-${BITBUCKET_WORKSPACE:-}}"
    local username="${2:-${BITBUCKET_USERNAME:-}}"
    local app_password="${3:-${BITBUCKET_APP_PASSWORD:-}}"
    local token="${4:-${BITBUCKET_TOKEN:-}}"
    [[ -n "$workspace" ]] || { echo "❌ BITBUCKET_WORKSPACE is not set" >&2; return 1; }
    if [[ -n "$token" ]]; then
        return 0
    fi
    [[ -n "$username" ]] || { echo "❌ BITBUCKET_USERNAME is not set" >&2; return 1; }
    [[ -n "$app_password" ]] || { echo "❌ BITBUCKET_APP_PASSWORD is not set" >&2; return 1; }
    return 0
}

_bitbucket_curl_auth_args() {
    if [[ -n "${BITBUCKET_TOKEN:-}" ]]; then
        printf '%s\n' "-H" "Authorization: Bearer ${BITBUCKET_TOKEN}"
    else
        printf '%s\n' "-u" "${BITBUCKET_USERNAME}:${BITBUCKET_APP_PASSWORD}"
    fi
}

_bitbucket_urlencode() {
    local raw="${1:-}"
    python3 - "$raw" <<'PY'
import sys
from urllib.parse import quote
print(quote(sys.argv[1], safe=""))
PY
}

_bitbucket_git_auth_remote_url() {
    local workspace="$1" slug="$2"
    local clean="https://bitbucket.org/${workspace}/${slug}.git"
    if [[ -n "${BITBUCKET_TOKEN:-}" ]]; then
        local enc_token
        enc_token="$(_bitbucket_urlencode "${BITBUCKET_TOKEN}")"
        printf '%s\n' "https://x-token-auth:${enc_token}@bitbucket.org/${workspace}/${slug}.git"
        return 0
    fi
    if [[ -n "${BITBUCKET_USERNAME:-}" && -n "${BITBUCKET_APP_PASSWORD:-}" ]]; then
        local enc_user enc_pass
        enc_user="$(_bitbucket_urlencode "${BITBUCKET_USERNAME}")"
        enc_pass="$(_bitbucket_urlencode "${BITBUCKET_APP_PASSWORD}")"
        printf '%s\n' "https://${enc_user}:${enc_pass}@bitbucket.org/${workspace}/${slug}.git"
        return 0
    fi
    printf '%s\n' "$clean"
}

_bitbucket_slugify() {
    local raw="${1:-repo}"
    local slug
    slug="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
    [[ -n "$slug" ]] || slug="repo"
    printf '%s\n' "$slug"
}

_bitbucket_set_secret_var() {
    local key="$1" value="$2"
    if typeset -f _secrets_update_env_file >/dev/null 2>&1; then
        _secrets_update_env_file "$key" "$value"
        return $?
    fi
    local file="${ZSH_SECRETS_FILE:-$HOME/.config/zsh/secrets.env}"
    umask 077
    [[ -f "$file" ]] || : > "$file"
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$file" "$key" "$value" <<'PY'
import sys
path,key,val=sys.argv[1:4]
with open(path,"r",encoding="utf-8") as f:
    lines=f.read().splitlines()
needle=f"{key}="
out=[]
done=False
for line in lines:
    if line.startswith(needle):
        out.append(f"{key}={val}")
        done=True
    else:
        out.append(line)
if not done:
    out.append(f"{key}={val}")
with open(path,"w",encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
    else
        echo "❌ python3 is required to persist secrets safely" >&2
        return 1
    fi
    chmod 600 "$file" 2>/dev/null || true
}

_bitbucket_require_next_arg() {
    local flag="$1"
    local next="${2-}"
    if [[ -z "$next" || "$next" == --* ]]; then
        echo "❌ Missing value for ${flag}" >&2
        return 1
    fi
    return 0
}

_git_remote_health() {
    local repo_path="${1:-$PWD}"
    local remote_name="${2:-origin}"
    local out rc

    out="$(git -C "$repo_path" ls-remote --heads "$remote_name" 2>&1)"
    rc=$?
    if [[ $rc -eq 0 ]]; then
        echo "ok"
        return 0
    fi
    if [[ "$out" == *"REMOTE HOST IDENTIFICATION HAS CHANGED"* || "$out" == *"Host key verification failed"* ]]; then
        echo "ssh_hostkey_failed"
        return 0
    fi
    if [[ "$out" == *"Permission denied"* || "$out" == *"Could not read from remote repository"* ]]; then
        echo "ssh_auth_failed"
        return 0
    fi
    echo "unreachable"
    return 0
}

bb_repo_create() {
    local name="" slug="" workspace="${BITBUCKET_WORKSPACE:-}" private="true"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --name)
                _bitbucket_require_next_arg "$1" "${2-}" || return 1
                name="${2:-}"; shift 2
                ;;
            --slug)
                _bitbucket_require_next_arg "$1" "${2-}" || return 1
                slug="${2:-}"; shift 2
                ;;
            --workspace)
                _bitbucket_require_next_arg "$1" "${2-}" || return 1
                workspace="${2:-}"; shift 2
                ;;
            --public) private="false"; shift ;;
            *)
                echo "Usage: bb_repo_create --name <name> [--slug <slug>] [--workspace <workspace>] [--public]" >&2
                return 1
                ;;
        esac
    done

    [[ -n "$name" ]] || { echo "❌ Missing --name" >&2; return 1; }
    slug="${slug:-$(_bitbucket_slugify "$name")}"
    _bitbucket_require_auth "$workspace" || return 1
    local -a auth_args
    auth_args=("${(@f)$(_bitbucket_curl_auth_args)}")

    local base="https://api.bitbucket.org/2.0/repositories/${workspace}/${slug}"
    if curl -fsS "${auth_args[@]}" "$base" >/dev/null 2>&1; then
        echo "✅ Bitbucket repo already exists: ${workspace}/${slug}"
        printf '%s\n' "https://bitbucket.org/${workspace}/${slug}.git"
        return 0
    fi

    local payload
    payload="$(printf '{"scm":"git","is_private":%s,"name":"%s"}' "$private" "$name")"
    if ! curl -fsS "${auth_args[@]}" \
        -H "Content-Type: application/json" \
        -X POST \
        -d "$payload" \
        "$base" >/dev/null; then
        echo "❌ Failed to create Bitbucket repo: ${workspace}/${slug}" >&2
        return 1
    fi

    echo "✅ Created Bitbucket repo: ${workspace}/${slug}"
    printf '%s\n' "https://bitbucket.org/${workspace}/${slug}.git"
}

bb_auth_setup() {
    local persist=1 workspace="${BITBUCKET_WORKSPACE:-}" username="${BITBUCKET_USERNAME:-}" app_password="${BITBUCKET_APP_PASSWORD:-}" token="${BITBUCKET_TOKEN:-}"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-persist) persist=0; shift ;;
            *)
                echo "Usage: bb_auth_setup [--no-persist]" >&2
                return 1
                ;;
        esac
    done

    echo "Bitbucket auth setup"
    echo "Workspace is usually your personal username/workspace slug."
    read "?Bitbucket workspace [${workspace:-none}]: " input_workspace
    [[ -n "$input_workspace" ]] && workspace="$input_workspace"
    read -s "?Bitbucket token (preferred, hidden, Enter to skip): " input_token
    echo ""
    [[ -n "$input_token" ]] && token="$input_token"
    read "?Bitbucket username [${username:-none}, optional with token]: " input_username
    [[ -n "$input_username" ]] && username="$input_username"
    read -s "?Bitbucket app password [hidden, optional with token]: " input_password
    echo ""
    [[ -n "$input_password" ]] && app_password="$input_password"

    [[ -n "$workspace" ]] || { echo "❌ Workspace is required" >&2; return 1; }
    if [[ -z "$token" ]]; then
        [[ -n "$username" ]] || { echo "❌ Username is required without token" >&2; return 1; }
        [[ -n "$app_password" ]] || { echo "❌ App password is required without token" >&2; return 1; }
    fi

    export BITBUCKET_WORKSPACE="$workspace"
    [[ -n "$username" ]] && export BITBUCKET_USERNAME="$username"
    [[ -n "$app_password" ]] && export BITBUCKET_APP_PASSWORD="$app_password"
    [[ -n "$token" ]] && export BITBUCKET_TOKEN="$token"

    if (( persist )); then
        if typeset -f settings_persist_var >/dev/null 2>&1; then
            settings_persist_var "BITBUCKET_WORKSPACE" "$workspace" "${ZSH_VARS_FILE:-$HOME/.config/zsh/vars.env}" || return 1
            [[ -n "$username" ]] && settings_persist_var "BITBUCKET_USERNAME" "$username" "${ZSH_VARS_FILE:-$HOME/.config/zsh/vars.env}" || true
        else
            echo "⚠️  settings_persist_var unavailable; workspace/username not persisted" >&2
        fi
        [[ -n "$app_password" ]] && _bitbucket_set_secret_var "BITBUCKET_APP_PASSWORD" "$app_password" || true
        [[ -n "$token" ]] && _bitbucket_set_secret_var "BITBUCKET_TOKEN" "$token" || true
        echo "✅ Saved workspace/username to vars.env and Bitbucket auth secret(s) to secrets.env"
    fi

    echo "✅ Bitbucket auth variables exported in current shell"
}

git_remote_rescue_to_bitbucket() {
    local repo_path="$PWD"
    local workspace="${BITBUCKET_WORKSPACE:-}"
    local name="" slug="" remote_name="origin" dry_run=0
    if [[ $# -gt 0 && "$1" != --* ]]; then
        repo_path="$1"
        shift
    fi
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --workspace)
                _bitbucket_require_next_arg "$1" "${2-}" || return 1
                workspace="${2:-}"; shift 2
                ;;
            --name)
                _bitbucket_require_next_arg "$1" "${2-}" || return 1
                name="${2:-}"; shift 2
                ;;
            --slug)
                _bitbucket_require_next_arg "$1" "${2-}" || return 1
                slug="${2:-}"; shift 2
                ;;
            --remote)
                _bitbucket_require_next_arg "$1" "${2-}" || return 1
                remote_name="${2:-}"; shift 2
                ;;
            --dry-run) dry_run=1; shift ;;
            *)
                echo "❌ Unknown arg: $1" >&2
                echo "Usage: git_remote_rescue_to_bitbucket [repo_path] [--workspace <workspace>] [--name <name>] [--slug <slug>] [--remote <name>] [--dry-run]" >&2
                return 1
                ;;
        esac
    done

    git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
        echo "❌ Not a git repo: $repo_path" >&2
        return 1
    }
    local repo_base
    repo_base="$(basename "$repo_path")"
    name="${name:-$repo_base}"
    slug="${slug:-$(_bitbucket_slugify "$name")}"

    local health
    health="$(_git_remote_health "$repo_path" "$remote_name")"
    if [[ "$health" == "ok" ]]; then
        echo "✅ Remote '$remote_name' is reachable for $repo_path"
        return 0
    fi

    local target_url="https://bitbucket.org/${workspace}/${slug}.git"
    local push_url
    push_url="$(_bitbucket_git_auth_remote_url "$workspace" "$slug")"
    echo "⚠️  Remote '$remote_name' health: $health"
    echo "➡️  Rescue target: $target_url"
    if (( dry_run )); then
        echo "🧪 Dry run only; no remote changes made"
        return 0
    fi

    _bitbucket_require_auth "$workspace" || return 1
    bb_repo_create --name "$name" --slug "$slug" --workspace "$workspace" >/dev/null || return 1

    if git -C "$repo_path" remote get-url bb_rescue >/dev/null 2>&1; then
        git -C "$repo_path" remote remove bb_rescue >/dev/null 2>&1 || true
    fi
    git -C "$repo_path" remote add bb_rescue "$push_url" || return 1
    git -C "$repo_path" push bb_rescue --all || { git -C "$repo_path" remote remove bb_rescue >/dev/null 2>&1 || true; return 1; }
    git -C "$repo_path" push bb_rescue --tags || { git -C "$repo_path" remote remove bb_rescue >/dev/null 2>&1 || true; return 1; }

    git -C "$repo_path" remote set-url "$remote_name" "$target_url" || {
        git -C "$repo_path" remote remove bb_rescue >/dev/null 2>&1 || true
        return 1
    }
    git -C "$repo_path" remote remove bb_rescue >/dev/null 2>&1 || true
    echo "✅ Origin rewritten to: $target_url"
}

git_ssh_fail_repos() {
    local root="${1:-$HOME/Documents}"
    find "$root" -maxdepth 4 -name .git -type d 2>/dev/null | while read -r gitdir; do
        local repo="${gitdir%/.git}"
        local origin
        origin="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
        [[ "$origin" == git@* ]] || continue
        local health
        health="$(_git_remote_health "$repo" origin)"
        if [[ "$health" != "ok" ]]; then
            printf '%s\t%s\t%s\n' "$health" "$repo" "$origin"
        fi
    done
}

git_ssh_fail_rescue_to_bitbucket() {
    local root="$HOME/Documents" workspace="${BITBUCKET_WORKSPACE:-}" dry_run=1
    if [[ $# -gt 0 && "$1" != --* ]]; then
        root="$1"
        shift
    fi
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --workspace)
                _bitbucket_require_next_arg "$1" "${2-}" || return 1
                workspace="${2:-}"; shift 2
                ;;
            --apply) dry_run=0; shift ;;
            --dry-run) dry_run=1; shift ;;
            *)
                echo "❌ Unknown arg: $1" >&2
                echo "Usage: git_ssh_fail_rescue_to_bitbucket [root] [--workspace <workspace>] [--apply|--dry-run]" >&2
                return 1
                ;;
        esac
    done

    git_ssh_fail_repos "$root" | while IFS=$'\t' read -r health repo origin; do
        [[ -n "$repo" ]] || continue
        echo "== $repo =="
        echo "health=$health"
        echo "origin=$origin"
        if (( dry_run )); then
            git_remote_rescue_to_bitbucket "$repo" --workspace "$workspace" --dry-run || true
        else
            git_remote_rescue_to_bitbucket "$repo" --workspace "$workspace" || true
        fi
        echo ""
    done
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ bitbucket loaded"
fi
