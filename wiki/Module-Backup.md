# Module: Backup

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Git-based backup and merge workflow for the zsh config repo.

## Environment
- `ZSHRC_CONFIG_DIR` (default `~/.config/zsh`)
- `ZSHRC_MAIN_REPO` (informational)
- `ZSHRC_BACKUP_REPO` (informational)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `backup` | Commit + push current branch | `git` | Repo initialized, remotes set |
| `backup_merge_main` | Merge source branch into `main` and push | `git` | Clean working tree, mergeable branch |
| `pushmain` | `backup` + `backup_merge_main` for current branch | `backup`, `backup_merge_main` | Same as both |
| `repo_sync` | Pull/rebase + push | `git` | Clean repo, remote reachable |
| `git_sync_safe` | Safe pull on current branch (`rebase` + `autostash`) | `git` | Remote branch exists |
| `git_sync_hard` | Destructive hard sync to remote branch | `git` | User confirmed or `--yes` |
| `repo_status` | Print repo status | `git` | Repo initialized |

## Notes
- Default workflow is branch-first:
  1) work on branch
  2) run `backup`
  3) run `backup_merge_main` (or `pushmain`)
- `backup` pushes the active branch to `origin` (and `backup` remote if present).
- `backup_merge_main` returns to the starting branch after merge/push.
- `git_sync_hard` does `fetch --prune`, `reset --hard`, and `clean -fd`; it removes local uncommitted work.
- Aliases: `zshbackup`, `zshmerge`, `zshsync`, `zshstatus`, `gitsync` (`git_sync_safe`).
