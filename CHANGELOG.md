# Changelog

All notable changes to this zsh configuration, generated from merged
pull requests. New entries are added at the top. Dates use the PR's
merge date.

## Regenerating

```sh
gh pr list --state merged --limit 500 --json number,title,mergedAt \
    --jq '.[] | select(.title | test("^Merge ";"i") | not)
        | "\(.mergedAt[0:10]) #\(.number) \(.title)"'
```

Spot-edit this file from the output. Grouping by epic/topic rather
than strict chronology is fine when it aids readability.

---

## 2026-04 — Infrastructure sprint

### Style enforcement + startup budget (epic #96)

- #110 — chore: pre-commit hook mirroring CI gates
- #109 — test: convention linter enforcing docstring + no-bare-exit rules
- #108 — ci: add shfmt formatting gate for bash scripts
- #107 — ci: add shellcheck gate for bash scripts
- #106 — docs: add STYLE.md
- #105 — fix(test): startup-budget must load the repo's zshrc on CI
- #104 — test: add startup-time budget test

### Secrets split (epic #111)

- #121 — refactor(secrets): extract load.zsh + finalize umbrella
- #120 — refactor(secrets): extract sync-1p + sync-rsync layers (17 functions)
- #119 — refactor(secrets): extract agent-cache + policy + profile (13 functions)
- #118 — refactor(secrets): extract 1Password CLI layer (26 functions)
- #117 — refactor(secrets): scaffold modules/secrets/ + extract core helpers

### Backup test deflake (closes #90)

- #122 — fix(#90): deflake backup test — global pipefail + SIGPIPE
- #123 — docs(wiki): secrets file layout + testing pitfalls

### Profiling + lazy modules + CI robustness (epics #124, #125)

- #149 — test: unskip pushmain + git_sync_safe backup tests
- #148 — ci: skip shellcheck/shfmt install when already present
- #146 — ci: add ubuntu-latest to the test matrix
- #145 — perf: opt-in data-platform module deferral
- #144 — perf: ZSH_PROFILE=1 hook + profiling wiki

### Developer ergonomics (epic #126)

- #150 — chore: add Makefile

### Zshrc cleanup + OMZ rework (epic #79)

- #95 — fix(ci): skip Mirror workflow on the backup copy
- #94 — feat: git-extras plugin + git alias cheat sheet
- #93 — feat: add third-party zsh plugins with zsh-defer
- #92 — feat: enable low-cost Oh-My-Zsh plugins
- #91 — perf: disable unused Oh-My-Zsh overhead at startup
- #89 — chore: archive bitbucket module
- #88 — chore: move zsh completion cache to `$XDG_CACHE_HOME/zsh`
- #87 — chore: archive transitional docs + prune merged branches

## 2026-04 — Earlier work

- #77 — feat: generic Electron app window repair

## 2026-03

- #69 — cleanup+fix+refactor: repo hygiene, setup-software matrix, module dedup
- #51 — fix: speed up Warp startup with compinit caching and terminal allowlist
- #50 — fix: backup merge test CI reliability
- #47 — Optimize shell startup: lazy SDKMAN, cached is_online, parallel probes
- #46 — Sync startup fixes from develop to main
- #45 — Prefer agent cache for startup secrets
- #44 — Lighten Warp startup path
- #43 — Enable CodeRabbit auto review on develop
- #42 — Fix pyenv startup rehash and add Claude temp cleanup
- #41 — refactor: convert all functions to named arguments
- #40 — feat: op sessions file with human-legible account metadata for agents
- #39 — feat: persist op session tokens to file for agent access
- #38 — fix: op_signin_all uses UUID when shorthand not configured
- #37 — Release v1.0.0: Repository Modernization
- #36 — docs: add CONTRIBUTING.md, Testing Guide, and Developer Welcome
- #35 — test: add missing test suites for livy, zeppelin, compat
- #34 — fix: apply code review fixes across modules
- #33 — refactor: simplify backup remote to CI-only
- #32 — chore: add GitHub Actions CI workflows

## 2026-02

- #17 — Consolidate JSON handling, merge signin functions, remove dead code
- #16 — Harden secrets module: reliability, diagnostics, test fixes

## 2025-09

- #4 — Claude systematic repair
- #3 — Complete Modular ZSH System - Production Ready
- #2 — feat: add backup toggle system to prevent unwanted auto-commits
- #1 — Complete Modular ZSH Configuration System with Professional Documentation
