# Module: GitHub

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
GitHub CLI workflows for repo cloning, issue branching, and safe PR operations.

## Dependencies
- `gh` CLI authenticated (`gh auth login`)
- `git`
- `python3` (or `python`) for JSON parsing

## Functions

| Function | Purpose | Notes |
|---|---|---|
| `gh_auth_status` | Show GitHub auth status | Wrapper around `gh auth status` |
| `gh_org_clone_all` | Clone all repos in an org | Skips already-cloned repos; excludes archived unless `--include-archived` |
| `gh_project_clone_all` | Backward-compatible alias | Calls `gh_org_clone_all` |
| `gh_repo_clone_matrix` | Clone repos from a file | Supports retries and skip-if-exists |
| `gh_issue_ls_mine` | List assigned issues | Optional `--repo` |
| `gh_issue_start` | Create branch from issue title | Branch format: `issue/<num>-<slug>` |
| `gh_issue_close_with_commit` | Close issue with commit reference | Adds standardized close comment |
| `gh_pr_create_from_branch` | Open PR from current branch | Supports optional base branch |
| `gh_pr_merge_safe` | Merge PR with safety checks | Requires OPEN + non-draft + mergeable state |
| `gh_pr_rebase_safe` | Rebase/update PR branch safely | Requires OPEN + non-draft |
| `gh_release_cut` | Create release with generated notes | Supports optional target branch |
| `git_hosting_status` | Shared GitHub/GitLab auth + branch summary | Works with both modules loaded |

## Examples

```bash
gh_org_clone_all --org siegeanalytics --dest ~/src
gh_repo_clone_matrix --file ~/repos/github.txt --dest ~/src --retries 3
gh_issue_start 123 --repo dheerajchand/siege_analytics_zshrc
gh_pr_merge_safe 45 --repo dheerajchand/siege_analytics_zshrc
```
