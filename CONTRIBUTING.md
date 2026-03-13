# Contributing

Back: [Home](wiki/Home)

## Branching Model

- `main` receives merges only from `develop`.
- `develop` receives merges from feature branches.
- Feature branches use prefixes: `feature/`, `fix/`, `docs/`, `test/`, `refactor/`, `chore/`.
- All branches target `develop` via pull request unless releasing to `main`.

```
main ← develop ← feature/<name>
                ← fix/<name>
                ← docs/<name>
                ← test/<name>
```

## Commit Messages

Use conventional commit format:

| Prefix      | Purpose                              |
|-------------|--------------------------------------|
| `feat:`     | New functionality                    |
| `fix:`      | Bug fix                              |
| `docs:`     | Documentation only                   |
| `test:`     | New or updated tests                 |
| `refactor:` | Code restructuring (no behavior change) |
| `chore:`    | Tooling, CI, build changes           |

Example:
```
feat: add Livy session timeout configuration

Add LIVY_SESSION_TIMEOUT env var with 3600s default.
```

## Pull Request Requirements

1. Branch from `develop` (never directly from `main`).
2. All CI checks must pass (the `test` workflow).
3. Keep PRs focused — one logical change per PR.
4. Use a descriptive title (under 70 characters).
5. Include a summary of what changed and why.

## Code Style

Follow the conventions in [Coding Standards](wiki/Coding-Standards).

Key points:
- Declare all variables with `local` inside functions.
- Use `${VAR:-default}` for optional env vars.
- Never hardcode user/host-specific paths in module logic.
- Guard loaded messages with `if [[ -z "${ZSH_TEST_MODE:-}" ]]; then ... fi`.
- Use `set -u` in test files (inherited from the framework).

## Testing

Every new public function needs a corresponding test.

- Test files live in `tests/test-<module>.zsh`.
- See [Testing Guide](wiki/Testing-Guide) for how to write and run tests.
- Run the full suite before opening a PR: `zsh run-tests.zsh`.
- Use `skip_in_ci` or `skip_if_missing "<tool>"` for tests that need tools unavailable in CI.

## Development Workflow

```bash
# 1. Create a feature branch
git checkout develop
git pull origin develop
git checkout -b feature/my-change

# 2. Make changes and test
zsh run-tests.zsh --verbose

# 3. Commit and push
git add <files>
git commit -m "feat: describe your change"
git push -u origin feature/my-change

# 4. Open a PR targeting develop
gh pr create --base develop
```
