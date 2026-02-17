# Module: GitLab

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
GitLab CLI workflows for group cloning, issue branching, and safe MR operations.

## Dependencies
- `glab` CLI authenticated (`glab auth login`)
- `git`
- `python3` (or `python`) for JSON parsing and URL encoding

## Functions

| Function | Purpose | Notes |
|---|---|---|
| `gl_auth_status` | Show GitLab auth status | Wrapper around `glab auth status` |
| `gl_group_clone_all` | Clone all projects in a group | Uses `glab api`; excludes archived unless `--include-archived` |
| `gl_project_clone_matrix` | Clone projects from a file | Supports retries and skip-if-exists |
| `gl_issue_ls_mine` | List assigned issues | Optional `--project` |
| `gl_issue_start` | Create branch from issue title | Branch format: `issue/<iid>-<slug>` |
| `gl_issue_close_with_commit` | Close issue with commit reference | Writes note then closes via API |
| `gl_mr_create_from_branch` | Open MR from current branch | Supports optional target branch |
| `gl_mr_merge_safe` | Merge MR with safety checks | Requires opened + non-draft + mergeable status |
| `gl_mr_rebase_safe` | Request MR rebase safely | Requires opened + non-draft |
| `gl_release_cut` | Create release tag/entry | Supports optional ref |

## Examples

```bash
gl_group_clone_all --group siege --dest ~/src
gl_project_clone_matrix --file ~/repos/gitlab.txt --dest ~/src --retries 3
gl_issue_start 87 --project siege/platform
gl_mr_merge_safe 22 --project siege/platform
```
