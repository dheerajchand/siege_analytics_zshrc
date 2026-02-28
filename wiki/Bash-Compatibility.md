# Bash Compatibility

Back: [Home](Home)

## Current Support Model
This repository does not ship a separate bash-native implementation of all functions.
Compatibility is provided by executing zsh functions from bash, for example via `zsh -lc`.

That means:
- canonical function implementations live in `modules/*.zsh`
- behavior is consistent when invoked from zsh directly
- bash can interoperate reliably using wrappers

## Practical Interop Pattern

### Minimal bridge
Add to `~/.bashrc`:
```bash
source ~/.config/zsh/bash-bridge.sh
```

Usage:
```bash
zrun "help"
zrun "settings_status"
zrun "spark_status"
zrun "hadoop_status"
```

Built-in wrapper commands from the bridge:
`zhelp`, `zmodules`, `zstatus`, `zspark`, `zhadoop`, `zzeppelin`, `zsecrets`, `zbackup`, `ztest`

### Grouped execution (faster)
```bash
zsh -lc 'spark_status; hadoop_status; zeppelin_status'
```

## What Is Guaranteed
- zsh functions are source-of-truth.
- bash users can call those functions through `zsh -lc`.
- machine-localized settings still apply (`vars.env` -> `vars.<os>.env` -> `vars.<machine>.env`).

## What Is Not Guaranteed
- direct function execution inside pure bash without spawning zsh.
- older legacy command names that are no longer present in modules.

## Cross-Shell Operational Examples

### Data platform checks
```bash
zrun "spark_mode_status"
zrun "spark_workers_health --summary"
zrun "hadoop_status"
zrun "data_platform_health"
```

### Zeppelin checks
```bash
zrun "zeppelin_status"
zrun "zeppelin_integration_status"
zrun "zeppelin_seed_smoke_notebook"
```

### Secrets and profile
```bash
zrun "secrets_status"
zrun "secrets_profiles"
zrun "secrets_profile_switch cyberpower"
```

### Git workflows
```bash
zrun "backup \"cross-shell backup\""
zrun "git_sync_safe"
zrun "gh_auth_status"
zrun "gl_auth_status"
```

## Validation
Validate current exported zsh functions:
```bash
zsh -lc 'help'
```

Run automated test checks:
```bash
zsh ~/.config/zsh/run-tests.zsh --test test_wiki_internal_links_resolve
zsh ~/.config/zsh/run-tests.zsh --test test_bash_docs_no_stale_commands
```

## Migration Guidance
If you previously used legacy helper names from older docs, map them to current commands:
- use `help` as the canonical command index
- use `spark_shell` for Scala REPL and `smart_spark_submit <file>` for job execution
- use `spark_config_status` and `hadoop_config_status` plus version helpers for stack setup checks
- use `zsh run-tests.zsh --list` and run named tests directly

## References
- [Shell Operations Guide](Shell-Operations-Guide)
- [Module-Zshrc](Module-Zshrc)
- [Testing-Framework](Testing-Framework)
