# Coding Standards

Back: [Home](Home)

## Scope
These standards apply to:
- `modules/*.zsh`
- `zshrc`
- test files under `tests/*.zsh`
- helper scripts under `scripts/`

Goal: predictable behavior, low maintenance, and testable shell code.

## Core Principles
- Prefer composition over monolithic functions.
- Keep functions small and single-purpose.
- Avoid hardcoded machine paths and secrets.
- Make side effects explicit.
- Keep behavior deterministic and testable.

## Configuration and Hardcoding
- Do not hardcode user- or host-specific paths inside module logic.
- Use layered config files:
  - `vars.env`
  - `vars.<os>.env`
  - `vars.<machine>.env`
- Use defaults with expansion: `${VAR:-default}` for shared defaults.
- Use explicit overrides only in machine files when intentional.

Example:
```zsh
# Good
: "${ZSH_CONFIG_DIR:=$HOME/.config/zsh}"

# Avoid
ZSH_CONFIG_DIR="/Users/dheerajchand/.config/zsh"
```

## Function Design Patterns
- Public functions: clear names, no leading underscore.
- Private helpers: `_prefix_name` convention.
- Parse args at function start; fail fast with clear usage messages.
- Return status codes, do not rely on parsing logs.
- Prefer idempotent behavior for setup operations.

Example:
```zsh
my_func() {
  local arg="${1:-}"
  if [[ -z "$arg" ]]; then
    echo "Usage: my_func <arg>" >&2
    return 1
  fi
  # work
}
```

## Shell Safety and Style
- Quote variable expansions unless intentional globbing/splitting is required.
- Use arrays for argument lists; avoid string-concatenated command lines.
- Prefer `[[ ... ]]` for tests.
- Use `local` for function-scoped variables.
- Avoid global mutation unless it is the function purpose.
- Avoid `eval` unless no safe alternative exists.
- Allowed `eval` patterns are explicitly limited to trusted shell initializers that emit shell code, such as:
  - `eval "$(pyenv init --path ...)"`, `eval "$(pyenv init - ...)"`
  - `eval "$(pyenv virtualenv-init - ...)"`
  - `eval "$(op signin ...)"` in interactive auth helpers
- Do not use `eval` for dynamic command construction from user-provided values.
- If a new `eval` use is introduced, document why a non-`eval` approach is unsafe/infeasible and add tests.
- Use `command -v tool >/dev/null 2>&1` for dependency checks.

## Logging and UX
- Use concise, structured output with stable prefixes (`✅`, `⚠️`, `❌`, section headers).
- Print actionable error messages to stderr.
- Keep noisy debug output opt-in.
- Do not print secrets or full tokens.

## Dependency and Tooling Rules
- Prefer `rg` over `grep` for speed and consistency.
- Use native CLI tools before adding new dependencies.
- Keep Python usage minimal for small text transforms unless it improves safety/readability.

## Python-in-Repo Standards
For Python scripts in `scripts/` used by shell workflows:
- Use explicit functions and `if __name__ == "__main__":` entrypoints.
- Keep I/O and transformation logic separated.
- Validate inputs and exit non-zero on failure.
- Avoid implicit globals; pass values explicitly.
- Keep output machine-readable when used in shell pipelines.

## Testing Requirements
- New public functions should include tests in `tests/test-*.zsh`.
- Doc updates that add links should keep internal link tests passing.
- If behavior changes, add or update tests before merge.

Minimum check:
```bash
zsh run-tests.zsh --list
zsh run-tests.zsh --test <name>
```

## Backward Compatibility
- Keep stable command names where possible.
- If renaming/removing a function:
  - update wiki docs in same change
  - add migration note
  - add test coverage for new canonical command path

## Review Checklist
- No hardcoded personal paths in module logic.
- Inputs validated and usage shown on invalid args.
- Quoting and arrays used safely.
- Errors return non-zero with clear stderr message.
- Tests added/updated and passing.
- Wiki links valid and examples runnable.
