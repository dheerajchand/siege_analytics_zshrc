#!/usr/bin/env zsh
# =================================================================
# GITHUB - GitHub CLI workflows
# =================================================================

_gh_usage() {
    echo "Usage:"
    echo "  gh_org_clone_all --org <org> [--dest <dir>] [--include-archived]"
    echo "  gh_repo_clone_matrix --file <repos.txt> [--dest <dir>] [--retries <n>]"
    echo "  gh_issue_ls_mine [--repo <owner/repo>]"
    echo "  gh_issue_start <issue_number> --repo <owner/repo>"
    echo "  gh_issue_close_with_commit <issue_number> --repo <owner/repo> --commit <sha>"
    echo "  gh_pr_create_from_branch [--repo <owner/repo>] [--base <branch>]"
    echo "  gh_pr_merge_safe <pr_number> --repo <owner/repo>"
    echo "  gh_pr_rebase_safe <pr_number> --repo <owner/repo>"
    echo "  gh_release_cut --repo <owner/repo> --tag <tag> [--target <branch>]"
}

_gh_require() {
    if ! command -v gh >/dev/null 2>&1; then
        echo "❌ gh CLI not found" >&2
        return 1
    fi
    return 0
}

_gh_require_auth() {
    _gh_require || return 1
    if ! gh auth status >/dev/null 2>&1; then
        echo "❌ GitHub auth required (run: gh auth login)" >&2
        return 1
    fi
    return 0
}

_gh_slugify() {
    local s="${1:-}"
    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    "$py" -c 'import re,sys
s=(sys.argv[1] or "").lower()
s=re.sub(r"[^a-z0-9]+","-",s).strip("-")
print(s[:60])
' "$s"
}

_gh_current_branch() {
    git branch --show-current 2>/dev/null
}

gh_auth_status() {
    _gh_require || return 1
    gh auth status
}

gh_org_clone_all() {
    local org=""
    local dest="${PWD}"
    local include_archived=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --org) org="${2:-}"; shift 2 ;;
            --dest) dest="${2:-}"; shift 2 ;;
            --include-archived) include_archived=1; shift ;;
            --help|-h) _gh_usage; return 0 ;;
            *) _gh_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$org" ]] || { echo "❌ --org is required" >&2; return 1; }
    _gh_require_auth || return 1
    mkdir -p "$dest" || return 1

    local repos_json
    repos_json="$(gh repo list "$org" --limit 1000 --json nameWithOwner,isArchived 2>/dev/null || true)"
    [[ -n "$repos_json" ]] || { echo "❌ No repos found for org: $org" >&2; return 1; }

    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    local repo_lines
    repo_lines="$(printf '%s' "$repos_json" | "$py" -c 'import json,sys
data=json.load(sys.stdin)
inc_arch=(sys.argv[1]=="1")
for r in data:
    if (not inc_arch) and r.get("isArchived"):
        continue
    print(r.get("nameWithOwner") or "")
' "$include_archived")"

    local name target clone_out
    local -a failed_permissions=()
    local -a failed_other=()
    local total=0
    local cloned=0
    local skipped=0
    while IFS= read -r name || [[ -n "$name" ]]; do
        [[ -z "$name" ]] && continue
        (( total++ ))
        target="$dest/${name#*/}"
        if [[ -d "$target/.git" ]]; then
            echo "⏭️  skip $name (already cloned)"
            (( skipped++ ))
            continue
        fi
        echo "📥 clone $name"
        clone_out="$(gh repo clone "$name" "$target" 2>&1)"
        if [[ $? -eq 0 ]]; then
            (( cloned++ ))
            continue
        fi
        if [[ "$clone_out" == *"Permission denied"* || "$clone_out" == *"Repository not found"* || "$clone_out" == *"Could not read from remote repository"* ]]; then
            failed_permissions+=("$name")
            echo "⚠️  no access: $name (skipping)"
        else
            failed_other+=("$name")
            echo "⚠️  clone failed: $name (skipping)"
        fi
    done <<< "$repo_lines"

    echo "📊 gh_org_clone_all summary"
    echo "   total: $total  cloned: $cloned  skipped-existing: $skipped  no-access: ${#failed_permissions[@]}  other-fail: ${#failed_other[@]}"
    if [[ ${#failed_permissions[@]} -gt 0 ]]; then
        echo "   no-access repos:"
        printf "   - %s\n" "${failed_permissions[@]}"
    fi
    if [[ ${#failed_other[@]} -gt 0 ]]; then
        echo "   other failures:"
        printf "   - %s\n" "${failed_other[@]}"
        return 1
    fi
}

gh_project_clone_all() {
    # Backward compatibility wrapper.
    gh_org_clone_all "$@"
}

gh_repo_clone_matrix() {
    local file=""
    local dest="${PWD}"
    local retries=2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --file) file="${2:-}"; shift 2 ;;
            --dest) dest="${2:-}"; shift 2 ;;
            --retries) retries="${2:-2}"; shift 2 ;;
            --help|-h) _gh_usage; return 0 ;;
            *) _gh_usage >&2; return 1 ;;
        esac
    done

    [[ -n "$file" ]] || { echo "❌ --file is required" >&2; return 1; }
    [[ -f "$file" ]] || { echo "❌ File not found: $file" >&2; return 1; }
    _gh_require_auth || return 1
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
            if gh repo clone "$repo" "$target"; then
                rc=0
                break
            fi
            rc=$?
            sleep 1
        done
        [[ "$rc" -eq 0 ]] || return "$rc"
    done < "$file"
}

gh_issue_ls_mine() {
    local repo=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo) repo="${2:-}"; shift 2 ;;
            --help|-h) _gh_usage; return 0 ;;
            *) _gh_usage >&2; return 1 ;;
        esac
    done
    _gh_require_auth || return 1
    if [[ -n "$repo" ]]; then
        gh issue list --assignee @me --repo "$repo"
    else
        gh issue list --assignee @me
    fi
}

gh_issue_start() {
    local issue="${1:-}"
    local repo=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo) repo="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -n "$issue" && -n "$repo" ]] || { echo "Usage: gh_issue_start <issue_number> --repo <owner/repo>" >&2; return 1; }

    _gh_require_auth || return 1
    local title
    title="$(gh issue view "$issue" --repo "$repo" --json title --jq .title 2>/dev/null || true)"
    [[ -n "$title" ]] || { echo "❌ Unable to read issue $issue in $repo" >&2; return 1; }

    local slug branch
    slug="$(_gh_slugify "$title")"
    [[ -n "$slug" ]] || slug="issue-${issue}"
    branch="issue/${issue}-${slug}"
    git checkout -b "$branch" || return 1
    echo "✅ Created branch: $branch"
}

gh_issue_close_with_commit() {
    local issue="${1:-}"
    local repo=""
    local commit=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo) repo="${2:-}"; shift 2 ;;
            --commit) commit="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -n "$issue" && -n "$repo" && -n "$commit" ]] || {
        echo "Usage: gh_issue_close_with_commit <issue_number> --repo <owner/repo> --commit <sha>" >&2
        return 1
    }

    _gh_require_auth || return 1
    gh issue close "$issue" --repo "$repo" --comment "Fixed in commit $commit"
}

gh_pr_create_from_branch() {
    local repo=""
    local base=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo) repo="${2:-}"; shift 2 ;;
            --base) base="${2:-}"; shift 2 ;;
            --help|-h) _gh_usage; return 0 ;;
            *) _gh_usage >&2; return 1 ;;
        esac
    done

    _gh_require_auth || return 1
    if [[ -n "$repo" && -n "$base" ]]; then
        gh pr create --fill --repo "$repo" --base "$base"
    elif [[ -n "$repo" ]]; then
        gh pr create --fill --repo "$repo"
    elif [[ -n "$base" ]]; then
        gh pr create --fill --base "$base"
    else
        gh pr create --fill
    fi
}

gh_pr_merge_safe() {
    local pr="${1:-}"
    local repo=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo) repo="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -n "$pr" && -n "$repo" ]] || { echo "Usage: gh_pr_merge_safe <pr_number> --repo <owner/repo>" >&2; return 1; }

    _gh_require_auth || return 1
    local info
    info="$(gh pr view "$pr" --repo "$repo" --json state,isDraft,mergeStateStatus 2>/dev/null || true)"
    [[ -n "$info" ]] || { echo "❌ Unable to inspect PR $pr" >&2; return 1; }

    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    local check
    check="$(printf '%s' "$info" | "$py" -c 'import json,sys
d=json.load(sys.stdin)
state=d.get("state","")
draft=bool(d.get("isDraft", False))
ms=(d.get("mergeStateStatus","") or "").upper()
ok=(state=="OPEN" and (not draft) and ms in {"CLEAN","HAS_HOOKS","UNSTABLE"})
print("1" if ok else "0")
')"
    if [[ "$check" != "1" ]]; then
        echo "❌ PR $pr is not merge-safe (must be OPEN, non-draft, mergeStateStatus CLEAN/HAS_HOOKS/UNSTABLE)" >&2
        return 1
    fi

    gh pr merge "$pr" --repo "$repo" --squash --delete-branch
}

gh_pr_rebase_safe() {
    local pr="${1:-}"
    local repo=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo) repo="${2:-}"; shift 2 ;;
            *) shift ;;
        esac
    done
    [[ -n "$pr" && -n "$repo" ]] || { echo "Usage: gh_pr_rebase_safe <pr_number> --repo <owner/repo>" >&2; return 1; }

    _gh_require_auth || return 1
    local info
    info="$(gh pr view "$pr" --repo "$repo" --json state,isDraft 2>/dev/null || true)"
    [[ -n "$info" ]] || { echo "❌ Unable to inspect PR $pr" >&2; return 1; }

    local py="python3"
    command -v python3 >/dev/null 2>&1 || py="python"
    local check
    check="$(printf '%s' "$info" | "$py" -c 'import json,sys
d=json.load(sys.stdin)
state=d.get("state","")
draft=bool(d.get("isDraft", False))
print("1" if (state=="OPEN" and (not draft)) else "0")
')"
    [[ "$check" == "1" ]] || { echo "❌ PR $pr must be OPEN and non-draft before rebase" >&2; return 1; }

    gh pr update-branch "$pr" --repo "$repo" --rebase
}

gh_release_cut() {
    local repo=""
    local tag=""
    local target=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --repo) repo="${2:-}"; shift 2 ;;
            --tag) tag="${2:-}"; shift 2 ;;
            --target) target="${2:-}"; shift 2 ;;
            --help|-h) _gh_usage; return 0 ;;
            *) _gh_usage >&2; return 1 ;;
        esac
    done
    [[ -n "$repo" && -n "$tag" ]] || { echo "Usage: gh_release_cut --repo <owner/repo> --tag <tag> [--target <branch>]" >&2; return 1; }

    _gh_require_auth || return 1
    if [[ -n "$target" ]]; then
        gh release create "$tag" --repo "$repo" --generate-notes --target "$target"
    else
        gh release create "$tag" --repo "$repo" --generate-notes
    fi
}

git_hosting_status() {
    echo "🔎 Git Hosting Status"
    echo "===================="
    local branch
    branch="$(_gh_current_branch)"
    echo "Branch: ${branch:-<none>}"

    if command -v gh >/dev/null 2>&1; then
        if gh auth status >/dev/null 2>&1; then
            echo "GitHub: authenticated"
        else
            echo "GitHub: not authenticated"
        fi
    else
        echo "GitHub: gh CLI not installed"
    fi

    if command -v glab >/dev/null 2>&1; then
        if glab auth status >/dev/null 2>&1; then
            echo "GitLab: authenticated"
        else
            echo "GitLab: not authenticated"
        fi
    else
        echo "GitLab: glab CLI not installed"
    fi
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ github loaded"
fi
