# Style Guide

Conventions for functions, variables, and error handling across this
config. The goal is mechanical enforcement where possible — see
`tests/test-conventions.zsh` (when it lands) and the CI `shellcheck`
and `shfmt` gates.

New code must conform. Legacy code is grandfathered until a refactor
touches it, at which point it should be brought in line.

---

## Functions

### Naming

- **User-facing functions** use `noun_verb` or `namespace_action`,
  snake_case, no leading underscore:
  `docker_status`, `claude_init`, `path_add`, `is_online`.
- **Private helpers** (not intended to be called outside their module)
  start with a single underscore:
  `_persist_env_var`, `_zsh_is_warp_terminal`.
- Don't use two leading underscores — reserved by convention for very
  deep internals.

### Docstring comment

Every user-facing function has a **single comment line immediately
above** its definition describing what it does.

```zsh
# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}
```

Longer explanations go in the module header or a `## heading` section
within the module. One-liner above the function is the minimum.

Private helpers (underscore-prefixed) may skip the docstring if the
name is self-explanatory. If a private helper has surprising behavior,
document it.

### Arguments

Prefer **named arguments** for any function taking more than one
argument:

```zsh
# Good
path_add() {
    local new_path position="prepend"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --path)     new_path="${2:-}"; shift 2 ;;
            --position) position="${2:-prepend}"; shift 2 ;;
            --prepend)  position="prepend"; shift ;;
            --append)   position="append"; shift ;;
            *) echo "Unknown option: $1" >&2; return 1 ;;
        esac
    done
    ...
}
```

Positional `$1` is acceptable only for:
- Single-argument functions where the meaning is obvious (`mkcd dir`).
- Pass-through wrappers (`gh_clone_all "$@"`).

### Return codes

- **0** for success.
- **Nonzero** for failure, with a specific code where practical (e.g.,
  `1` for usage error, `2` for environment not ready).
- Functions that are imperative (do a thing) should explicitly `return
  0` at the end if they might otherwise return the exit code of an
  intermediate command.
- Functions that are predicates (`is_online`, `is_macos`) return 0 for
  true, nonzero for false — no echoed "yes"/"no".

### Output conventions

- **Results → stdout.** Things the caller might want to pipe.
- **Messages → stderr.** Progress, warnings, errors.
- Error messages start with a context prefix:
  `"module_name: something bad happened"`.
- Don't mix results and messages on stdout. A function that both
  computes a value and reports progress must send progress to stderr.

### `exit` vs `return`

Modules are **sourced**, not executed. Never use `exit` inside a module
or inside a function that will be called from an interactive shell —
it will kill the user's shell. Use `return <code>` instead.

`exit` is fine in scripts executed standalone (`install.sh`,
`setup-software.sh`).

---

## Variables

### Scoping

- Inside functions, always `local` (or `typeset`) every variable the
  function uses. Zsh leaks variables to outer scope by default.
- Module-level globals that need to persist across function calls use
  `typeset -g` with a clear module-prefixed name:
  `typeset -g DIAG_CACHE_TTL=300`.
- Module-level constants use `typeset -gr` (readonly) when appropriate.

### `local` must live inside functions

`local` at the top level of a sourced file errors under zsh. If you
need a module-level variable, use `typeset -g`. If you're tempted to
use `local` outside a function, wrap the relevant block in a function
and call it.

### Naming

- **Exported env vars** the user might override: `SCREAMING_SNAKE_CASE`
  with a module prefix where ambiguity exists: `ZSH_STATUS_BANNER_MODE`,
  `SPARK_EXECUTION_MODE`.
- **Internal globals**: lowercase with underscore prefix or module prefix:
  `_zsh_is_warp_terminal`, `diag_cache_file`.
- **Loop indices and short-lived locals**: single letters are fine
  (`i`, `f`, `line`).

---

## Error handling

- **Validate inputs early**, return nonzero with a useful message if
  invalid. Don't silently soldier on.
- For external commands that may fail, check the exit code explicitly.
  Don't rely on `set -e` inside sourced modules — it leaks to the
  caller.
- Prefer `|| return $?` / `|| { echo "..." >&2; return 1; }` over
  unchecked chains.
- When wrapping a tool that may not be installed, guard with
  `command -v ... >/dev/null` and a clear "install X" message.

---

## Tests

- Every test file lives in `tests/` and is named `test-<topic>.zsh`.
- Use the framework in `tests/test-framework.zsh`: `register_test`,
  `assert_true`, `assert_equal`, `assert_contains`, etc.
- Tests run in sourced context — never use bare `exit` in a test file
  (use the framework's fail paths).
- Behavior-changing code gets a test in the same PR. Pure moves and
  renames don't.

---

## Shell flags

- Don't set `set -e` / `set -u` / `set -o pipefail` at the top of
  modules, tests, or `run-tests.zsh`. They propagate to the sourcing
  shell and create action-at-a-distance bugs.
- If you need strict mode in a scope, use `emulate -L zsh` + `setopt`
  **inside a function** — `emulate -L` scopes the options to the
  function.
- **Pipefail gotcha (#90):** `cmd | grep -q "..."` is fragile under
  `pipefail`. `grep -q` exits on first match; the upstream producer
  receives SIGPIPE and exits 141; pipefail surfaces the 141 as the
  pipe's status, so a successful match can fail flakily. Two fixes:
  1. Don't enable pipefail at runner/test-file scope.
  2. Capture the producer output first, then grep the variable:
     `out="$(cmd)"; echo "$out" | grep -q "..."`. No live pipe to the
     short-circuiting consumer.
  `test_conventions_runner_no_global_pipefail` guards run-tests.zsh.

---

## Enforcement

- `tests/test-zshrc-startup.zsh` — structural invariants of `zshrc`.
- `tests/test-startup-budget.zsh` — startup time <= budget.
- `tests/test-conventions.zsh` — the rules in this doc that can be
  checked mechanically (when it lands: #101).
- CI: `shellcheck`, `shfmt -d` (when they land: #98, #99).
- Local: pre-commit hook runs the same checks (when it lands: #103).
