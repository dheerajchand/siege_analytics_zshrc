# How-To Recipes

Back: [Home](Home)

## Daily Health Snapshot
```bash
python_status
spark_status
hadoop_status
secrets_status
data_platform_health
```

## Switch Spark Mode Safely
```bash
spark_mode_status
spark_mode_use local --persist
spark_mode_use cluster --persist
```

## Set Spark Log Level
```bash
spark_log_level WARN --persist
spark_log_level INFO
```

## Validate Worker Functionality
```bash
spark_workers_health --summary
spark_workers_health --probe --with-packages --master spark://localhost:7077
```

## Validate Spark 4.1 Route
```bash
spark41_route_health --spark-smoke
```

## Start/Stop Data Services
```bash
spark_start
start_hadoop
zeppelin_start

spark_stop
stop_hadoop
zeppelin_stop
```

## Use Bash Without Switching Shell
```bash
source ~/.config/zsh/bash-bridge.sh
zhelp
zstatus
zrun "spark_mode_status"
ztest --test test_wiki_internal_links_resolve
```

## Fix Untracked File Pull Conflict
```bash
mkdir -p ~/tmp/zsh-vars-backup
cp ~/.config/zsh/vars.*.env ~/tmp/zsh-vars-backup/ 2>/dev/null || true
rm -f ~/.config/zsh/vars.cyberpower.env ~/.config/zsh/vars.linux.env ~/.config/zsh/vars.mac.env
git -C ~/.config/zsh pull origin main
```

## Recover from Startup Warnings
For `pyenv init --path)1` typo:
```bash
sed -i 's/pyenv init --path)1/pyenv init --path)/g' ~/.zshenv ~/.zprofile 2>/dev/null || true
```

## Update Settings by Layer
```bash
settings_edit_vars          # shared
settings_edit_vars_os       # mac/linux layer
settings_edit_vars_machine  # host-specific layer
settings_status
```

## Backup and Merge Workflow
```bash
backup "feature checkpoint"
backup_merge_main
```

## Run Focused Test Sets
```bash
zsh run-tests.zsh --test test_settings_load_order
zsh run-tests.zsh --test test_bash_docs_no_stale_commands
zsh run-tests.zsh --test test_bash_bridge_defines_functions
```
