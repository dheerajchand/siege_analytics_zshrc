# Tests

Minimal zsh test framework and test suites for this repo.

## Suites

- `test-credentials.zsh`
- `test-secrets-core.zsh`
- `test-secrets-1password.zsh`
- `test-secrets-load.zsh`
- `test-secrets-sync.zsh`
- `test-secrets-profile.zsh`
- `test-secrets-misc.zsh`
- `test-python.zsh`
- `test-spark-hadoop.zsh`
- `test-system-diagnostics.zsh`
- `test-agents.zsh`
- `test-docs.zsh`
- `test-paths.zsh`
- `test-settings.zsh`
- `test-banner.zsh`
- `test-utils.zsh`
- `test-zshrc-startup.zsh`
- `test-startup-budget.zsh`
- `test-conventions.zsh`
- `test-doctor.zsh`
- `test-module-flags.zsh`
- `test-env-detect.zsh`
- `test-backup.zsh`
- `test-database.zsh`
- `test-docker.zsh`
- `test-screen.zsh`
- `test-git-hosting.zsh`
- `test-databricks.zsh`
- `test-bash-bridge.zsh`
- `test-dataworld.zsh`
- `test-wiki.zsh`
- `test-livy.zsh`
- `test-zeppelin.zsh`
- `test-compat.zsh`
- `test-electron-fix.zsh`

## Run tests

```bash
zsh run-tests.zsh
```

## Options

```bash
zsh run-tests.zsh --list
zsh run-tests.zsh --test test_get_credential_env
zsh run-tests.zsh --verbose
```
