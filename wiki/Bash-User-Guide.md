# Bash User Guide

Back: [Home](Home)

## Reality Check
This repository is a zsh-first system (`zshrc` + `modules/*.zsh`).
There is no standalone bash compatibility shim file in this repo.

If your login shell is bash, the supported pattern is:
- keep bash as your shell
- run zsh functions through `zsh -lc` wrappers

## Recommended Setup for Bash Users

### 1. Keep zsh config up to date
```bash
git -C ~/.config/zsh pull origin main
```

### 2. Add bridge aliases/functions to `~/.bashrc`
```bash
# zsh bridge
zcfg='zsh -lc'

# quick wrappers
alias zhelp='zsh -lc "help"'
alias zstatus='zsh -lc "python_status; spark_mode_status; hadoop_status; secrets_status"'
alias zspark='zsh -lc "spark_status"'
alias zhadoop='zsh -lc "hadoop_status"'
alias zzeppelin='zsh -lc "zeppelin_status"'

# run any zsh function from bash
zrun() {
  zsh -lc "$*"
}
```

Reload:
```bash
source ~/.bashrc
```

## Daily Bash Workflow

```bash
zhelp
zstatus

# examples
zrun "spark_mode_use cluster --persist"
zrun "spark_log_level WARN --persist"
zrun "spark_workers_health --summary"
zrun "data_platform_health"
```

## High-Value Commands from Bash

### Settings and Localization
```bash
zrun "settings_status"
zrun "settings_edit_vars"
zrun "settings_edit_vars_os"
zrun "settings_edit_vars_machine"
```

### Secrets and 1Password
```bash
zrun "secrets_status"
zrun "secrets_profiles"
zrun "secrets_profile_switch dev"
zrun "secrets_sync_all_to_1p"
zrun "secrets_pull_all_from_1p"
zrun "op_signin_all"
```

### Python
```bash
zrun "python_status"
zrun "py_env_switch default_31111"
zrun "python_config_status"
```

### Spark + Hadoop + Zeppelin
```bash
zrun "spark_start"
zrun "start_hadoop"
zrun "spark_status"
zrun "hadoop_status"
zrun "spark_workers_health --probe --with-packages"
zrun "zeppelin_start"
zrun "zeppelin_seed_smoke_notebook"
```

### Git Hosting and Backup
```bash
zrun "backup \"bash-driven checkpoint\""
zrun "git_sync_safe"
zrun "gh_auth_status"
zrun "gl_auth_status"
```

## Testing from Bash
Run zsh tests directly:
```bash
zsh ~/.config/zsh/run-tests.zsh --list
zsh ~/.config/zsh/run-tests.zsh --test test_settings_load_order
zsh ~/.config/zsh/run-tests.zsh --test test_settings_os_then_machine_override_order
zsh ~/.config/zsh/run-tests.zsh --test test_wiki_internal_links_resolve
```

## Troubleshooting

### "command not found" for a zsh function
Cause: function only exists after sourcing zsh modules.
Fix:
```bash
zsh -lc "help"
```
If that works, use `zrun "..."` wrappers.

### Slow startup from bash wrappers
Use single zsh call for grouped operations:
```bash
zsh -lc 'spark_status; hadoop_status; zeppelin_status'
```

### Wrong machine profile or overrides
```bash
zsh -lc 'settings_status'
```
Confirm:
- `Vars:` shared defaults
- `Vars(OS):` OS-specific overrides
- `Vars(M):` machine overrides

## What to Read Next
- [Shell Operations Guide](Shell-Operations-Guide)
- [Module-Settings](Module-Settings)
- [Module-Spark](Module-Spark)
- [Module-Secrets](Module-Secrets)
