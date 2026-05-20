# Startup Performance

## Profiling: `ZSH_PROFILE=1`

```sh
ZSH_PROFILE=1 zsh -i -c exit
```

Loads `zsh/zprof` before any config runs and prints the per-function
breakdown on shell exit. Columns:

- **num** — number of calls.
- **time** — total time inside this function (ms), children included.
- **self** — time spent directly in the function body, excluding
  children. This is the honest per-function cost.
- **name** — function name.

Reading the table:

- Dominant `self` → the function itself is slow; profile internally.
- Dominant `time` but small `self` → slow because of children; drill in.

The hook costs a single test on every shell when `ZSH_PROFILE` is
unset — zero measurable overhead when off.

## Budget test

`tests/test-startup-budget.zsh` fails CI if the median of 5 interactive
starts exceeds `ZSH_STARTUP_BUDGET_MS` (default 2500). Local warm-shell
median: ~500ms. Tune per host via env var; skip entirely with
`SKIP_STARTUP_BUDGET=1` (escape hatch).

## Known hotspots (2026-04-19)

From a representative `ZSH_PROFILE=1` run on macOS (warm cache):

| Function | self (ms) | Notes |
|---|---:|---|
| `pyenv` init | ~335 | `eval "$(pyenv init -)"` on every shell. Lazy-load candidate (#130). |
| `op_signin_all` | ~295 | Warms 1Password sessions at load via `_secrets_auto_signin_all_on_load`. Candidate for deferral (#140). |
| `_omz_source` | ~135 total (37 calls) | OMZ plugin sourcing; mostly unavoidable. Already minimized by #79 / #91. |
| `_secrets_export_kv` | ~120 total (23 calls) | Bounded by secrets.env size. |
| `fzf_setup_using_base_dir` | ~80 | One-time fzf plugin init. |

## Opt-in deferral

- `ZSH_DEFER_DATA_PLATFORM=1` — defers `spark`, `hadoop`, `livy`, and
  `zeppelin` module sourcing via `zsh-defer` until after the first
  prompt renders. Useful if you rarely (or never) use these tools
  from this shell. Off by default because the startup status banner
  calls a couple of spark/hadoop helpers during init; enabling the
  flag makes those banner lines skip until the deferred sourcing
  completes a moment later.

## Warp defaults

Interactive startup now takes a lighter path inside Warp by default.

- `ZSH_STATUS_BANNER_MODE=auto` suppresses the probe-heavy status banner in Warp.
- `ZSH_AUTO_RECOVER_MODE=auto` skips automatic service recovery in Warp.
- `ZSH_SECRETS_STARTUP_SOURCE=auto` prefers the local agent cache over live 1Password reads when startup is running in the IDE/staggered path.

Outside Warp, both settings still behave normally unless overridden.

## Overrides

Use these when you explicitly want the heavier interactive checks:

```zsh
export ZSH_STATUS_BANNER_MODE=full
export ZSH_AUTO_RECOVER_MODE=on
export ZSH_SECRETS_STARTUP_SOURCE=live
```

Use these when you want the lightest possible startup everywhere:

```zsh
export ZSH_STATUS_BANNER_MODE=off
export ZSH_AUTO_RECOVER_MODE=off
export ZSH_SECRETS_STARTUP_SOURCE=cache
```
