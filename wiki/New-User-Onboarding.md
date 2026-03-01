# New User Onboarding

Back: [Home](Home)

## Goal
Get a new user productive with this shell in under 30 minutes with safe defaults.

## Prerequisites
- Repo cloned at `~/.config/zsh`
- `zsh` installed
- `git` available
- Optional but recommended: `op` CLI, SDKMAN, pyenv

## 1) Load Shell Config
If zsh is your shell:
```bash
source ~/.config/zsh/zshrc
```

If bash is your shell:
```bash
source ~/.config/zsh/bash-bridge.sh
```

## 2) Verify Core Commands
```bash
help
modules
settings_status
python_status
spark_mode_status
hadoop_status
secrets_status
```

## 3) Set Profile and Machine Overrides
Use layered settings:
- shared: `vars.env`
- OS-specific: `vars.<os>.env`
- machine-specific: `vars.<machine>.env`

```bash
settings_edit_vars
settings_edit_vars_os
settings_edit_vars_machine
settings_status
```

Recommended minimum:
```bash
# in vars.env
export DEFAULT_PG_USER="${DEFAULT_PG_USER:-$USER}"
export ZSH_STARTUP_MODE="${ZSH_STARTUP_MODE:-auto}"
```

## 4) Secrets and 1Password
Initialize local files and map:
```bash
secrets_init
secrets_init_map
op_accounts_edit
```

Validate and sync:
```bash
secrets_validate_setup
secrets_sync_all_to_1p
secrets_pull_all_from_1p
secrets_status
```

## 5) Python Setup
```bash
setup_pyenv
setup_uv
py_env_switch default_31111
python_status
python_config_status
```

## 6) Data Stack Setup
```bash
spark_mode_status
spark_log_level WARN --persist
spark_start
start_hadoop
spark_workers_health --summary
hadoop_status
```

If using Zeppelin:
```bash
zeppelin_start
zeppelin_status
zeppelin_seed_smoke_notebook
```

## 7) Git Workflow Basics
```bash
backup "initial shell setup"
git_sync_safe
```

GitHub/GitLab auth checks:
```bash
gh_auth_status
gl_auth_status
```

## 8) Run Validation Tests
```bash
zsh run-tests.zsh --test test_wiki_internal_links_resolve
zsh run-tests.zsh --test test_settings_os_then_machine_override_order
zsh run-tests.zsh --test test_bash_bridge_defines_functions
dbx_preflight
cross_host_smoke --hosts local --json-out /tmp/smoke.json --report-out /tmp/smoke.txt
onboarding_validate --target-minutes 30 --json-out /tmp/onboarding.json --report-out /tmp/onboarding.txt
```

## 9) Common Failure Recovery
Config drift:
```bash
git -C ~/.config/zsh pull origin main
zshreboot
```

Secrets sync fallback:
```bash
secrets_rsync_to_cyberpower
secrets_rsync_verify --host cyberpower
```

Worker diagnostics:
```bash
spark_workers_health --probe --with-packages
spark41_route_health --spark-smoke
```

## 10) What to Read Next
- [Shell Operations Guide](Shell-Operations-Guide)
- [Coding Standards](Coding-Standards)
- [How-To Recipes](How-To-Recipes)
