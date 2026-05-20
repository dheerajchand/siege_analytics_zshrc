# Git aliases & extras cheat sheet

Aliases come from the Oh-My-Zsh `git` plugin (auto-loaded). The `git-*`
subcommands come from `git-extras` (install: `brew install git-extras`).

Grouped by how often you'll reach for them. When in doubt:
`alias | grep '^g'` lists every alias starting with `g`, or use the
`aliases` plugin's grouped view: `aliases -s git`.

---

## Daily drivers (OMZ `git` plugin)

| Alias | Expands to | Why |
|---|---|---|
| `gst` | `git status` | Fastest status peek |
| `gd` | `git diff` | Working tree diff |
| `gdca` | `git diff --cached` | What's staged |
| `gaa` | `git add --all` | Stage everything |
| `gcmsg "msg"` | `git commit -m "msg"` | Quick commit |
| `gca` | `git commit -v -a` | Commit all tracked, verbose |
| `gcan!` | `git commit -v -a --no-edit --amend` | Amend last commit silently |
| `gco <b>` | `git checkout <b>` | Switch branch |
| `gcb <b>` | `git checkout -b <b>` | New branch |
| `gl` | `git pull` | Pull current branch |
| `gp` | `git push` | Push current branch |
| `gpsup` | `git push --set-upstream origin $(current_branch)` | First push of a new branch |
| `ggpur` | `git pull origin $(current_branch)` | Pull from matching upstream |

## History & log

| Alias | Expands to | Why |
|---|---|---|
| `glog` | `git log --oneline --decorate --graph` | Readable oneline log |
| `glola` | `git log --graph --abbrev-commit --decorate --all --pretty=format:'%C(bold blue)%h%Creset...'` | Beautiful all-branches graph |
| `glol` | `glola` but current branch only | Focused history |
| `gbl` | `git blame -b -w` | Ignore whitespace + boundary |

## Rebasing & history surgery

| Alias | Expands to | Why |
|---|---|---|
| `grb` | `git rebase` | Base |
| `grbi` | `git rebase -i` | Interactive rebase |
| `grba` | `git rebase --abort` | Escape hatch |
| `grbc` | `git rebase --continue` | After conflicts |
| `gwip` | Stage + commit as `--wip--` | Park in-progress work |
| `gunwip` | Undo a `gwip` | Resume |

## Stash

| Alias | Expands to |
|---|---|
| `gsta` | `git stash push` |
| `gstp` | `git stash pop` |
| `gstl` | `git stash list` |
| `gstd` | `git stash drop` |

## Inspection shortcuts

| Alias | Expands to |
|---|---|
| `gsta` | `git stash push` |
| `gcl` | `git clone --recurse-submodules` |
| `grh` | `git reset` |
| `grhh` | `git reset --hard` |
| `gclean` | `git clean -id` |

---

## `git-extras` subcommands worth knowing

Install: `brew install git-extras` (already required by Stage 7).

| Command | What it does |
|---|---|
| `git summary` | Project stats: first/last commit, authors, commit count |
| `git undo` | Undo the last commit (keeps changes staged) |
| `git ignore <pattern>` | Append to `.gitignore` from the CLI |
| `git info` | Condensed repo overview (remotes, local branches, last commit) |
| `git delete-merged-branches` | Prune branches already merged into default |
| `git changelog` | Scaffold/append to CHANGELOG.md from commit messages |
| `git effort` | Commit count per file — find churn hotspots |
| `git count` | Total commits |
| `git alias` | Define a git alias without editing .gitconfig |

Run `git <TAB>` to see completion for all 60+ subcommands.

---

## When to use which

- **Reading code / PR review:** `gst`, `gd`, `gdca`, `glola`
- **Starting a change:** `gcb feature/x`, then `gaa && gcmsg "..."`, then `gpsup`
- **Rebasing:** `grbi HEAD~5`, with `grba` / `grbc` as needed
- **Undoing:** `gcan!` (amend) or `git undo` (from git-extras) — reach for both before `grhh`
- **Understanding a repo for the first time:** `git summary`, `git info`, `glola`
