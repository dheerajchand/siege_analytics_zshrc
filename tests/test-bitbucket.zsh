#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/bitbucket.zsh"

test_bitbucket_slugify_normalizes_name() {
    local out
    out="$(_bitbucket_slugify "My Repo @ 2026")"
    assert_equal "my-repo-2026" "$out" "slugify should normalize repo names"
}

test_git_remote_health_detects_hostkey_failure() {
    local old_git
    old_git="$(whence -p git || true)"
    git() {
        echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        echo "@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @"
        echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        return 1
    }
    local health
    health="$(_git_remote_health "$PWD" origin)"
    assert_equal "ssh_hostkey_failed" "$health" "should classify host key mismatch"
    unfunction git
    [[ -n "$old_git" ]] && hash -r
}

test_bb_repo_create_requires_auth() {
    local old_workspace="${BITBUCKET_WORKSPACE-}"
    local old_user="${BITBUCKET_USERNAME-}"
    local old_pass="${BITBUCKET_APP_PASSWORD-}"
    unset BITBUCKET_WORKSPACE BITBUCKET_USERNAME BITBUCKET_APP_PASSWORD
    local out rc
    out="$(bb_repo_create --name test-repo 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "bb_repo_create should fail without auth env vars"
    assert_contains "$out" "BITBUCKET_WORKSPACE" "should explain missing auth env var"
    [[ -n "${old_workspace-}" ]] && export BITBUCKET_WORKSPACE="$old_workspace" || unset BITBUCKET_WORKSPACE
    [[ -n "${old_user-}" ]] && export BITBUCKET_USERNAME="$old_user" || unset BITBUCKET_USERNAME
    [[ -n "${old_pass-}" ]] && export BITBUCKET_APP_PASSWORD="$old_pass" || unset BITBUCKET_APP_PASSWORD
}

test_git_remote_rescue_dry_run_reports_target() {
    local tmp
    tmp="$(mktemp -d)"
    git init "$tmp" >/dev/null 2>&1
    git -C "$tmp" config user.email "test@example.com"
    git -C "$tmp" config user.name "Test User"
    echo "seed" > "$tmp/README.md"
    git -C "$tmp" add README.md
    git -C "$tmp" commit -m "init" >/dev/null 2>&1
    git -C "$tmp" remote add origin git@example.com:missing/repo.git

    local old_workspace="${BITBUCKET_WORKSPACE-}"
    export BITBUCKET_WORKSPACE="dchand"

    local old_health
    old_health="$(typeset -f _git_remote_health || true)"
    _git_remote_health() { echo "ssh_hostkey_failed"; }

    local out
    out="$(git_remote_rescue_to_bitbucket "$tmp" --dry-run 2>&1)"
    assert_contains "$out" "Rescue target: https://bitbucket.org/dchand/" "dry-run should print Bitbucket target"
    assert_contains "$out" "Dry run only" "dry-run should not mutate remotes"

    rm -rf "$tmp"
    if [[ -n "$old_health" ]]; then
        eval "$old_health"
    else
        unfunction _git_remote_health
    fi
    [[ -n "${old_workspace-}" ]] && export BITBUCKET_WORKSPACE="$old_workspace" || unset BITBUCKET_WORKSPACE
}

test_git_ssh_fail_rescue_rejects_missing_workspace_value() {
    local out rc
    out="$(git_ssh_fail_rescue_to_bitbucket ~/Documents --workspace 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "should fail when --workspace has no value"
    assert_contains "$out" "Missing value for --workspace" "should show missing value error"
}

test_bb_auth_setup_interactive_persists_with_helpers() {
    local tmp_vars tmp_secrets
    local old_settings_persist_var old_secrets_update_env_file
    tmp_vars="$(mktemp)"
    tmp_secrets="$(mktemp)"
    export ZSH_VARS_FILE="$tmp_vars"
    export ZSH_SECRETS_FILE="$tmp_secrets"
    unset BITBUCKET_WORKSPACE BITBUCKET_USERNAME BITBUCKET_APP_PASSWORD
    old_settings_persist_var="$(typeset -f settings_persist_var || true)"
    old_secrets_update_env_file="$(typeset -f _secrets_update_env_file || true)"

    settings_persist_var() {
        local key="$1" val="$2" file="${3:-$ZSH_VARS_FILE}"
        echo "export ${key}=\"\${${key}:-${val}}\"" >> "$file"
    }
    _secrets_update_env_file() {
        local key="$1" val="$2"
        echo "${key}=${val}" >> "$ZSH_SECRETS_FILE"
    }

    local out_file out
    out_file="$(mktemp)"
    bb_auth_setup <<< $'myspace\n\nmyuser\nmypassword\n' >"$out_file" 2>&1
    out="$(cat "$out_file")"
    assert_contains "$out" "Saved workspace/username" "setup should report persisted credentials"
    assert_equal "myspace" "${BITBUCKET_WORKSPACE:-}" "workspace should be exported"
    assert_equal "myuser" "${BITBUCKET_USERNAME:-}" "username should be exported"
    assert_equal "mypassword" "${BITBUCKET_APP_PASSWORD:-}" "password should be exported"
    assert_command_success "rg -q \"BITBUCKET_WORKSPACE\" \"$tmp_vars\"" "vars file should include workspace"
    assert_command_success "rg -q \"BITBUCKET_USERNAME\" \"$tmp_vars\"" "vars file should include username"
    assert_command_success "rg -q \"BITBUCKET_APP_PASSWORD=mypassword\" \"$tmp_secrets\"" "secrets file should include app password"

    if [[ -n "$old_settings_persist_var" ]]; then
        eval "$old_settings_persist_var"
    else
        unfunction settings_persist_var 2>/dev/null || true
    fi
    if [[ -n "$old_secrets_update_env_file" ]]; then
        eval "$old_secrets_update_env_file"
    else
        unfunction _secrets_update_env_file 2>/dev/null || true
    fi
    rm -f "$tmp_vars" "$tmp_secrets" "$out_file"
}

register_test "test_bitbucket_slugify_normalizes_name" "test_bitbucket_slugify_normalizes_name"
register_test "test_git_remote_health_detects_hostkey_failure" "test_git_remote_health_detects_hostkey_failure"
register_test "test_bb_repo_create_requires_auth" "test_bb_repo_create_requires_auth"
register_test "test_git_remote_rescue_dry_run_reports_target" "test_git_remote_rescue_dry_run_reports_target"
register_test "test_git_ssh_fail_rescue_rejects_missing_workspace_value" "test_git_ssh_fail_rescue_rejects_missing_workspace_value"
register_test "test_bb_auth_setup_interactive_persists_with_helpers" "test_bb_auth_setup_interactive_persists_with_helpers"
