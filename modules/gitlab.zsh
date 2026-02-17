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

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ gitlab loaded"
fi
