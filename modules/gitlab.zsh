#!/usr/bin/env zsh
# =================================================================
# GITLAB - GitLab CLI workflows
# =================================================================

_gl_usage() {
    echo "Usage:"
    echo "  gl_group_clone_all --group <group> [--dest <dir>] [--include-archived]"
    echo "  gl_project_clone_matrix --file <repos.txt> [--dest <dir>] [--retries <n>]"
    echo "  gl_issue_ls_mine [--project <group/project>]"
    echo "  gl_issue_start <iid> --project <group/project>"
    echo "  gl_issue_close_with_commit <iid> --project <group/project> --commit <sha>"
    echo "  gl_mr_create_from_branch --project <group/project> [--target <branch>]"
    echo "  gl_mr_merge_safe <iid> --project <group/project>"
    echo "  gl_mr_rebase_safe <iid> --project <group/project>"
    echo "  gl_release_cut --project <group/project> --tag <tag> [--ref <branch>]"
    echo "  git_remote_rescue_to_gitlab [repo_path] [--group <group>] [--dry-run]"
    echo "  git_ssh_fail_rescue_to_gitlab [root] [--group <group>] [--apply|--dry-run]"
}

_gl_require() {
    if ! command -v glab >/dev/null 2>&1; then
        echo "❌ glab CLI not found" >&2
        return 1
    fi
    return 0
}

_gl_require_auth() {
    _gl_require || return 1
    if ! glab auth status >/dev/null 2>&1; then
        echo "❌ GitLab auth required (run: glab auth login)" >&2
        return 1
    fi
    return 0
}

_gl_slugify() {
    local s="${1:-}"
    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    "$py" -c 'import re,sys
s=(sys.argv[1] or "").lower()
s=re.sub(r"[^a-z0-9]+","-",s).strip("-")
print(s[:60])
' "$s"
}

_gl_urlencode() {
    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    "$py" -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "$1"
}

_gl_require_next_arg() {
    local flag="$1"
    local next="${2-}"
    if [[ -z "$next" || "$next" == --* ]]; then
        echo "❌ Missing value for ${flag}" >&2
        return 1
    fi
    return 0
}

_git_remote_health_gl() {
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
    if [[ "$out" == *"Permission denied"* || "$out" == *"Could not read from remote repository"* || "$out" == *"Repository not found"* ]]; then
        echo "ssh_auth_failed"
        return 0
    fi
    echo "unreachable"
    return 0
}

_gl_current_username() {
    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    glab api user 2>/dev/null | "$py" -c 'import json,sys; d=json.load(sys.stdin); print(d.get("username",""))'
}

_gl_git_auth_remote_url() {
    local project_path="$1"
    local clean_url="https://gitlab.com/${project_path}.git"
    if [[ -n "${GITLAB_TOKEN:-}" ]]; then
        local enc
        enc="$(_gl_urlencode "${GITLAB_TOKEN}")"
        printf '%s\n' "https://oauth2:${enc}@gitlab.com/${project_path}.git"
        return 0
    fi
    if [[ -n "${GITLAB_ACCESS_TOKEN:-}" ]]; then
        local enc2
        enc2="$(_gl_urlencode "${GITLAB_ACCESS_TOKEN}")"
        printf '%s\n' "https://oauth2:${enc2}@gitlab.com/${project_path}.git"
        return 0
    fi
    printf '%s\n' "$clean_url"
}

gl_auth_status() {
    _gl_require || return 1
    glab auth status
}

gl_group_clone_all() {
    local group=""
    local dest="${PWD}"
    local include_archived=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --group) group="${2:-}"; shift 2 ;;
            --dest) dest="${2:-}"; shift 2 ;;
            --include-archived) include_archived=1; shift ;;
            --help|-h) _gl_usage; return 0 ;;
            *) _gl_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$group" ]] || { echo "❌ --group is required" >&2; return 1; }

    _gl_require_auth || return 1
    mkdir -p "$dest" || return 1

    local encoded_group
    encoded_group="$(_gl_urlencode "$group")"
    local projects_json
    projects_json="$(glab api "groups/${encoded_group}/projects?include_subgroups=true&per_page=100" 2>/dev/null || true)"
    [[ -n "$projects_json" ]] || { echo "❌ No projects found for group: $group" >&2; return 1; }

    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    local project_lines
    project_lines="$(printf '%s' "$projects_json" | "$py" -c 'import json,sys
data=json.load(sys.stdin)
inc_arch=(sys.argv[1]=="1")
for p in data:
    if (not inc_arch) and p.get("archived"):
        continue
    name=p.get("path_with_namespace") or ""
    if name:
        print(name)
' "$include_archived")"

    local name target
    while IFS= read -r name || [[ -n "$name" ]]; do
        [[ -z "$name" ]] && continue
        target="$dest/${name#*/}"
        if [[ -d "$target/.git" ]]; then
            echo "⏭️  skip $name (already cloned)"
            continue
        fi
        echo "📥 clone $name"
        glab repo clone "$name" "$target" || return 1
    done <<< "$project_lines"
}

gl_project_clone_matrix() {
    local file=""
    local dest="${PWD}"
    local retries=2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) file="${2:-}"; shift 2 ;;
            --dest) dest="${2:-}"; shift 2 ;;
            --retries) retries="${2:-2}"; shift 2 ;;
            --help|-h) _gl_usage; return 0 ;;
            *) _gl_usage >&2; return 1 ;;
        esac
    done

    [[ -n "$file" ]] || { echo "❌ --file is required" >&2; return 1; }
    [[ -f "$file" ]] || { echo "❌ File not found: $file" >&2; return 1; }
    _gl_require_auth || return 1
    mkdir -p "$dest" || return 1

    local line repo target attempt rc
    while IFS= read -r line || [[ -n "$line" ]]; do
        repo="${line%%#*}"
        repo="${repo## }"
        repo="${repo%% }"
        [[ -z "$repo" ]] && continue

        target="$dest/${repo#*/}"
        if [[ -d "$target/.git" ]]; then
            echo "⏭️  skip $repo (already cloned)"
            continue
        fi

        attempt=0
        rc=1
        while [[ "$attempt" -le "$retries" ]]; do
            (( attempt++ ))
            echo "📥 clone $repo (attempt $attempt/$((retries+1)))"
            if glab repo clone "$repo" "$target"; then
                rc=0
                break
            fi
            rc=$?
            sleep 1
        done
        [[ "$rc" -eq 0 ]] || return "$rc"
    done < "$file"
}

gl_issue_ls_mine() {
    local project=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project="${2:-}"; shift 2 ;;
            --help|-h) _gl_usage; return 0 ;;
            *) _gl_usage >&2; return 1 ;;
        esac
    done

    _gl_require_auth || return 1
    if [[ -n "$project" ]]; then
        glab issue list --assignee @me --repo "$project"
    else
        glab issue list --assignee @me
    fi
}

gl_issue_start() {
    local iid="${1:-}"
    local project=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -n "$iid" && -n "$project" ]] || { echo "Usage: gl_issue_start <iid> --project <group/project>" >&2; return 1; }

    _gl_require_auth || return 1
    local encoded_project title
    encoded_project="$(_gl_urlencode "$project")"
    title="$(glab api "projects/${encoded_project}/issues/${iid}" 2>/dev/null | python3 -c 'import json,sys; print((json.load(sys.stdin) or {}).get("title", ""))' 2>/dev/null || true)"
    [[ -n "$title" ]] || { echo "❌ Unable to read issue $iid in $project" >&2; return 1; }

    local slug branch
    slug="$(_gl_slugify "$title")"
    [[ -n "$slug" ]] || slug="issue-${iid}"
    branch="issue/${iid}-${slug}"
    git checkout -b "$branch" || return 1
    echo "✅ Created branch: $branch"
}

gl_issue_close_with_commit() {
    local iid="${1:-}"
    local project=""
    local commit=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project="${2:-}"; shift 2 ;;
            --commit) commit="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -n "$iid" && -n "$project" && -n "$commit" ]] || {
        echo "Usage: gl_issue_close_with_commit <iid> --project <group/project> --commit <sha>" >&2
        return 1
    }

    _gl_require_auth || return 1
    local encoded_project
    encoded_project="$(_gl_urlencode "$project")"
    glab api -X POST "projects/${encoded_project}/issues/${iid}/notes" -f body="Fixed in commit ${commit}" >/dev/null || return 1
    glab api -X PUT "projects/${encoded_project}/issues/${iid}" -f state_event=close >/dev/null || return 1
    echo "✅ Closed issue $iid"
}

gl_mr_create_from_branch() {
    local project=""
    local target=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project="${2:-}"; shift 2 ;;
            --target) target="${2:-}"; shift 2 ;;
            --help|-h) _gl_usage; return 0 ;;
            *) _gl_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$project" ]] || { echo "Usage: gl_mr_create_from_branch --project <group/project> [--target <branch>]" >&2; return 1; }

    _gl_require_auth || return 1
    if [[ -n "$target" ]]; then
        glab mr create --repo "$project" --target-branch "$target" --fill
    else
        glab mr create --repo "$project" --fill
    fi
}

gl_mr_merge_safe() {
    local iid="${1:-}"
    local project=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -n "$iid" && -n "$project" ]] || { echo "Usage: gl_mr_merge_safe <iid> --project <group/project>" >&2; return 1; }

    _gl_require_auth || return 1
    local encoded_project mr_json
    encoded_project="$(_gl_urlencode "$project")"
    mr_json="$(glab api "projects/${encoded_project}/merge_requests/${iid}" 2>/dev/null || true)"
    [[ -n "$mr_json" ]] || { echo "❌ Unable to inspect MR $iid" >&2; return 1; }

    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    local check
    check="$(printf '%s' "$mr_json" | "$py" -c 'import json,sys
d=json.load(sys.stdin)
state=(d.get("state") or "").lower()
title=d.get("title") or ""
draft=title.startswith("Draft:") or title.startswith("WIP:") or bool(d.get("work_in_progress", False))
status=(d.get("detailed_merge_status") or d.get("merge_status") or "").lower()
ok=(state=="opened" and (not draft) and status in {"can_be_merged", "mergeable", "unchecked", "ci_still_running"})
print("1" if ok else "0")
')"
    if [[ "$check" != "1" ]]; then
        echo "❌ MR $iid is not merge-safe (must be opened, non-draft, mergeable status)" >&2
        return 1
    fi

    glab mr merge "$iid" --repo "$project" --squash --remove-source-branch --yes
}

gl_mr_rebase_safe() {
    local iid="${1:-}"
    local project=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -n "$iid" && -n "$project" ]] || { echo "Usage: gl_mr_rebase_safe <iid> --project <group/project>" >&2; return 1; }

    _gl_require_auth || return 1
    local encoded_project mr_json
    encoded_project="$(_gl_urlencode "$project")"
    mr_json="$(glab api "projects/${encoded_project}/merge_requests/${iid}" 2>/dev/null || true)"
    [[ -n "$mr_json" ]] || { echo "❌ Unable to inspect MR $iid" >&2; return 1; }

    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    local check
    check="$(printf '%s' "$mr_json" | "$py" -c 'import json,sys
d=json.load(sys.stdin)
state=(d.get("state") or "").lower()
title=d.get("title") or ""
draft=title.startswith("Draft:") or title.startswith("WIP:") or bool(d.get("work_in_progress", False))
print("1" if (state=="opened" and (not draft)) else "0")
')"
    [[ "$check" == "1" ]] || { echo "❌ MR $iid must be opened and non-draft before rebase" >&2; return 1; }

    glab api -X PUT "projects/${encoded_project}/merge_requests/${iid}/rebase" >/dev/null
    echo "✅ Rebase requested for MR $iid"
}

gl_release_cut() {
    local project=""
    local tag=""
    local ref=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --project) project="${2:-}"; shift 2 ;;
            --tag) tag="${2:-}"; shift 2 ;;
            --ref) ref="${2:-}"; shift 2 ;;
            --help|-h) _gl_usage; return 0 ;;
            *) _gl_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$project" && -n "$tag" ]] || { echo "Usage: gl_release_cut --project <group/project> --tag <tag> [--ref <branch>]" >&2; return 1; }

    _gl_require_auth || return 1
    if [[ -n "$ref" ]]; then
        glab release create "$tag" --repo "$project" --ref "$ref" --notes "Release $tag"
    else
        glab release create "$tag" --repo "$project" --notes "Release $tag"
    fi
}

git_remote_rescue_to_gitlab() {
    local repo_path="$PWD"
    local group=""
    local name_prefix=""
    local name="" slug="" remote_name="origin" dry_run=0

    if [[ $# -gt 0 && "$1" != --* ]]; then
        repo_path="$1"
        shift
    fi
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --group)
                _gl_require_next_arg "$1" "${2-}" || return 1
                group="${2:-}"; shift 2
                ;;
            --name-prefix)
                _gl_require_next_arg "$1" "${2-}" || return 1
                name_prefix="${2:-}"; shift 2
                ;;
            --name)
                _gl_require_next_arg "$1" "${2-}" || return 1
                name="${2:-}"; shift 2
                ;;
            --slug)
                _gl_require_next_arg "$1" "${2-}" || return 1
                slug="${2:-}"; shift 2
                ;;
            --remote)
                _gl_require_next_arg "$1" "${2-}" || return 1
                remote_name="${2:-}"; shift 2
                ;;
            --dry-run) dry_run=1; shift ;;
            *)
                echo "Usage: git_remote_rescue_to_gitlab [repo_path] [--group <group>] [--name-prefix <prefix>] [--name <name>] [--slug <slug>] [--remote <name>] [--dry-run]" >&2
                return 1
                ;;
        esac
    done

    git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "❌ Not a git repo: $repo_path" >&2; return 1; }
    _gl_require_auth || return 1

    local health repo_base namespace project_path target_url push_url
    health="$(_git_remote_health_gl "$repo_path" "$remote_name")"
    repo_base="$(basename "$repo_path")"
    name="${name:-$repo_base}"
    slug="${slug:-$(_gl_slugify "$name")}"
    [[ -n "$slug" ]] || slug="$repo_base"
    if [[ -n "$name_prefix" ]]; then
        slug="$(_gl_slugify "${name_prefix}${slug}")"
    fi

    namespace="$group"
    if [[ -z "$namespace" ]]; then
        namespace="$(_gl_current_username)"
    fi
    [[ -n "$namespace" ]] || { echo "❌ Could not determine GitLab namespace; pass --group <namespace>" >&2; return 1; }

    project_path="${namespace}/${slug}"
    target_url="https://gitlab.com/${project_path}.git"
    push_url="$(_gl_git_auth_remote_url "$project_path")"

    if [[ "$health" == "ok" ]]; then
        echo "✅ Remote '$remote_name' is reachable for $repo_path"
        return 0
    fi

    echo "⚠️  Remote '$remote_name' health: $health"
    echo "➡️  Rescue target: $target_url"
    if (( dry_run )); then
        echo "🧪 Dry run only; no remote changes made"
        return 0
    fi

    if ! glab repo view "$project_path" >/dev/null 2>&1; then
        glab repo create "$project_path" --private >/dev/null || {
            echo "❌ Failed to create GitLab project: $project_path" >&2
            return 1
        }
        echo "✅ Created GitLab project: $project_path"
    else
        echo "✅ GitLab project already exists: $project_path"
    fi

    if git -C "$repo_path" remote get-url gl_rescue >/dev/null 2>&1; then
        git -C "$repo_path" remote remove gl_rescue >/dev/null 2>&1 || true
    fi
    git -C "$repo_path" remote add gl_rescue "$push_url" || return 1
    git -C "$repo_path" push gl_rescue --all || { git -C "$repo_path" remote remove gl_rescue >/dev/null 2>&1 || true; return 1; }
    git -C "$repo_path" push gl_rescue --tags || { git -C "$repo_path" remote remove gl_rescue >/dev/null 2>&1 || true; return 1; }
    git -C "$repo_path" remote set-url "$remote_name" "$target_url" || { git -C "$repo_path" remote remove gl_rescue >/dev/null 2>&1 || true; return 1; }
    git -C "$repo_path" remote remove gl_rescue >/dev/null 2>&1 || true
    echo "✅ Origin rewritten to: $target_url"
}

git_ssh_fail_repos_gl() {
    local root="${1:-$HOME/Documents}"
    find "$root" -maxdepth 4 -name .git -type d 2>/dev/null | while read -r gitdir; do
        local repo="${gitdir%/.git}"
        local origin
        origin="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
        [[ "$origin" == git@* || "$origin" == ssh://git@* ]] || continue
        local health
        health="$(_git_remote_health_gl "$repo" origin)"
        if [[ "$health" != "ok" ]]; then
            printf '%s\t%s\t%s\n' "$health" "$repo" "$origin"
        fi
    done
}

git_ssh_fail_rescue_to_gitlab() {
    local root="$HOME/Documents"
    local group=""
    local name_prefix=""
    local dry_run=1
    if [[ $# -gt 0 && "$1" != --* ]]; then
        root="$1"
        shift
    fi
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --group)
                _gl_require_next_arg "$1" "${2-}" || return 1
                group="${2:-}"; shift 2
                ;;
            --name-prefix)
                _gl_require_next_arg "$1" "${2-}" || return 1
                name_prefix="${2:-}"; shift 2
                ;;
            --apply) dry_run=0; shift ;;
            --dry-run) dry_run=1; shift ;;
            *)
                echo "Usage: git_ssh_fail_rescue_to_gitlab [root] [--group <group>] [--name-prefix <prefix>] [--apply|--dry-run]" >&2
                return 1
                ;;
        esac
    done

    _gl_require_auth || return 1

    git_ssh_fail_repos_gl "$root" | while IFS=$'\t' read -r health repo origin; do
        [[ -n "$repo" ]] || continue
        echo "== $repo =="
        echo "health=$health"
        echo "origin=$origin"
        if (( dry_run )); then
            if [[ -n "$group" ]]; then
                if [[ -n "$name_prefix" ]]; then
                    git_remote_rescue_to_gitlab "$repo" --group "$group" --name-prefix "$name_prefix" --dry-run || true
                else
                    git_remote_rescue_to_gitlab "$repo" --group "$group" --dry-run || true
                fi
            else
                if [[ -n "$name_prefix" ]]; then
                    git_remote_rescue_to_gitlab "$repo" --name-prefix "$name_prefix" --dry-run || true
                else
                    git_remote_rescue_to_gitlab "$repo" --dry-run || true
                fi
            fi
        else
            if [[ -n "$group" ]]; then
                if [[ -n "$name_prefix" ]]; then
                    git_remote_rescue_to_gitlab "$repo" --group "$group" --name-prefix "$name_prefix" || true
                else
                    git_remote_rescue_to_gitlab "$repo" --group "$group" || true
                fi
            else
                if [[ -n "$name_prefix" ]]; then
                    git_remote_rescue_to_gitlab "$repo" --name-prefix "$name_prefix" || true
                else
                    git_remote_rescue_to_gitlab "$repo" || true
                fi
            fi
        fi
        echo ""
    done
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ gitlab loaded"
fi
