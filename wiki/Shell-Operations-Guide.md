# Shell Operations Guide

Back: [Home](Home)

## Purpose
This is the operational guide for the `~/.config/zsh` system.
It focuses on day-to-day usage, machine-aware behavior, and production-safe workflows.

Use this with:
- [Quick-Start](Quick-Start)
- [Module-Zshrc](Module-Zshrc)
- Module-specific references under `wiki/Module-*.md`

## How This Shell Is Structured
The shell boot path is:
1. `~/.zshenv` (minimal always-on environment)
2. `~/.config/zsh/zshrc` (module orchestrator + banner + help)
3. `~/.config/zsh/modules/*.zsh` (feature modules)

### Startup Modes
- `ZSH_STARTUP_MODE=auto`: uses staggered loading in IDE terminals, full loading elsewhere.
- `ZSH_STARTUP_MODE=staggered`: always tiered/staggered loading.
- `ZSH_STARTUP_MODE=full`: immediate full module load.

### Localization and Overrides
Settings load order:
1. `vars.env` (shared defaults)
2. `vars.<os>.env` (`vars.mac.env` or `vars.linux.env`)
3. `vars.<machine>.env` (for example `vars.cyberpower.env`)
4. `aliases.zsh`
5. `paths.env`

Detection:
- OS profile: `mac` or `linux`
- Machine profile: `ZSH_MACHINE_PROFILE` override, else `ZSH_ENV_PROFILE`, else hostname-based detection.

Check active files:
```bash
settings_status
```

Edit:
```bash
settings_edit_vars
settings_edit_vars_os
settings_edit_vars_machine
settings_edit_aliases
settings_edit_paths
```

## Core Daily Workflow
Start here each day:
```bash
help
modules
python_status
spark_status
hadoop_status
secrets_status
```

Refresh shell quickly:
```bash
zshreboot
```

Open config:
```bash
zshconfig
```

## Credential and Secrets Workflow
Bootstrap:
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
secrets_sync_status
```

Operate across hosts:
```bash
secrets_rsync_to_cyberpower
secrets_rsync_from_cyberpower
secrets_rsync_verify --host cyberpower
```

Profile-aware usage:
```bash
secrets_profiles
secrets_profile_switch dev
secrets_profile_switch laptop
```

## Python Workflow
Switch environment:
```bash
py_env_switch default_31111
python_status
python_config_status
```

Version pinning:
```bash
pyenv_use_version 3.11.11
pyenv_default_version 3.11.11
```

Run with explicit interpreter:
```bash
with_python "python -V"
```

Create starter project:
```bash
ds_project_init my_project
```

## Spark + Hadoop + Zeppelin Workflow
Cluster lifecycle:
```bash
spark_start
start_hadoop
spark_status
hadoop_status
spark_workers_health --summary
```

Mode and log level:
```bash
spark_mode_status
spark_mode_use cluster --persist
spark_log_level WARN --persist
```

Dependency matrix:
```bash
jar_matrix_resolve
jar_matrix_status
spark_validate_versions
spark_config_status
```

Interactive work:
```bash
pyspark_shell
spark_shell
smart_spark_submit job.py
```

Zeppelin and Livy:
```bash
zeppelin_start
zeppelin_status
zeppelin_integration_status
zeppelin_seed_smoke_notebook
livy_status
```

Spark 4.1 routing diagnostics:
```bash
spark41_route_health --spark-smoke
```

## Git Hosting and Backup Workflow
Safe daily checkpoint:
```bash
backup "Update workflows"
```

Merge to main:
```bash
backup_merge_main
```

One-command backup + merge:
```bash
pushmain "Release changes"
```

Resync local repo safely:
```bash
git_sync_safe
```

Destructive hard-sync:
```bash
git_sync_hard --yes
```

GitHub:
```bash
gh_auth_status
gh_issue_ls_mine --repo owner/repo
gh_issue_start 123 --repo owner/repo
gh_pr_create_from_branch --repo owner/repo
gh_pr_merge_safe 45 --repo owner/repo
```

GitLab:
```bash
gl_auth_status
gl_issue_ls_mine --project group/project
gl_issue_start 12 --project group/project
gl_mr_create_from_branch --project group/project
gl_mr_merge_safe 34 --project group/project
```

Bitbucket rescue/migration:
```bash
bb_auth_setup
git_ssh_fail_repos ~/Documents
git_ssh_fail_rescue_to_bitbucket ~/Documents --workspace myspace
```

## Databricks + Lakebase Workflow
```bash
dbx_auth_status
dbx_profiles_list
dbx_profile_use SUZY_USER --persist
dbx_clusters_list
dbx_jobs_list
dbx_workspace_ls /
dbx_lakebase_instances_list
dbx_lakebase_dbs_list --instance my-instance
```

## Diagnostics Workflow
Platform checks:
```bash
data_platform_config_status
data_platform_health
linux_system_status
```

macOS checks:
```bash
icloud_status
icloud_preflight
dropbox_status
```

## Complete Public Function Index
This index covers public callable functions exported by modules in this repo.

### agents
`codex_session_add`, `codex_session_update`, `codex_session_remove`, `codex_session_list`, `codex_session_edit`, `codex_session`, `codex_start_net`, `codex_start_danger`, `claude_session_add`, `claude_session_update`, `claude_session_remove`, `claude_session_list`, `claude_session_edit`, `claude_session`, `claude_init`, `codex_init`, `ai_init`

### backup
`backup`, `backup_merge_main`, `pushmain`, `repo_sync`, `git_sync_safe`, `git_sync_hard`, `repo_status`

### bitbucket
`bb_repo_create`, `bb_auth_setup`, `git_remote_rescue_to_bitbucket`, `git_ssh_fail_repos`, `git_ssh_fail_rescue_to_bitbucket`

### compat
`compat_profiles`, `stack_profile_use`, `stack_profile_status`, `stack_validate_versions`

### credentials
`get_credential`, `store_credential`, `credential_backend_status`, `ga_store_service_account`, `ga_get_service_account`, `ga_list_credentials`, `test_credential_system`

### database
`setup_postgres_credentials`, `pg_test_connection`, `pg_connect`, `psql_quick`, `database_status`

### databricks
`dbx_auth_status`, `dbx_profiles_list`, `dbx_profile_use`, `dbx_clusters_list`, `dbx_cluster_start`, `dbx_cluster_stop`, `dbx_jobs_list`, `dbx_job_run_now`, `dbx_workspace_ls`, `dbx_repos_sync`, `dbx_sql_warehouses_list`, `dbx_lakebase_instances_list`, `dbx_lakebase_dbs_list`, `dbx_lakebase_db_create`, `dbx_lakebase_db_drop`, `dbx_lakebase_psql`, `dbx_lakebase_health`

### dataworld
`dataworld_sync_csv`, `data_csv_prune_derived`

### docker
`docker_status`, `docker_cleanup`, `docker_deep_clean`, `docker_shell`, `docker_logs`, `docker_restart_container`, `docker_quick_run`

### github
`gh_auth_status`, `gh_org_clone_all`, `gh_project_clone_all`, `gh_repo_clone_matrix`, `gh_issue_ls_mine`, `gh_issue_start`, `gh_issue_close_with_commit`, `gh_pr_create_from_branch`, `gh_pr_merge_safe`, `gh_pr_rebase_safe`, `gh_release_cut`, `git_hosting_status`

### gitlab
`gl_auth_status`, `gl_group_clone_all`, `gl_project_clone_matrix`, `gl_issue_ls_mine`, `gl_issue_start`, `gl_issue_close_with_commit`, `gl_mr_create_from_branch`, `gl_mr_merge_safe`, `gl_mr_rebase_safe`, `gl_release_cut`, `git_remote_rescue_to_gitlab`, `git_ssh_fail_repos_gl`, `git_ssh_fail_rescue_to_gitlab`

### hadoop
`start_hadoop`, `stop_hadoop`, `restart_hadoop`, `hadoop_status`, `yarn_health`, `hadoop_config_status`, `hadoop_versions`, `hadoop_use_version`, `hadoop_default_version`, `hadoop_health`, `yarn_application_list`, `yarn_kill_all_apps`, `yarn_logs`, `yarn_cluster_info`, `hdfs_ls`, `hdfs_put`, `hdfs_get`, `hdfs_rm`

### livy
`livy_status`, `livy_start`, `livy_stop`, `livy_logs`

### paths
`paths_init`, `paths_edit`, `paths_list`

### python
`py_env_switch`, `get_python_path`, `get_python_version`, `python_status`, `python_config_status`, `pyenv_use_version`, `pyenv_default_version`, `with_python`, `use_uv`, `ds_project_init`

### screen
`screen_ensure_pyenv`

### secrets
`op_accounts_edit`, `op_accounts_sanitize`, `secrets_find_account_for_item`, `secrets_source_set`, `secrets_source_status`, `op_accounts_set_alias`, `op_accounts_seed`, `op_verify_accounts`, `secrets_rsync_to_host`, `secrets_rsync_from_host`, `secrets_rsync_to_cyberpower`, `secrets_rsync_from_cyberpower`, `secrets_rsync_verify`, `secrets_load_file`, `secrets_load_op`, `secrets_agent_refresh`, `secrets_agent_source`, `secrets_agent_status`, `secrets_missing_from_1p`, `load_secrets`, `secrets_prune_duplicates_1p`, `secrets_validate_setup`, `secrets_init_profile`, `secrets_status`, `op_set_default`, `op_list_accounts_vaults`, `secrets_edit`, `secrets_init`, `secrets_init_map`, `secrets_map_sanitize`, `secrets_sync_to_1p`, `secrets_pull_from_1p`, `secrets_sync_codex_sessions_to_1p`, `secrets_pull_codex_sessions_from_1p`, `secrets_sync_all_to_1p`, `secrets_pull_all_from_1p`, `secrets_profile_switch`, `op_list_items`, `op_find_item_across_accounts`, `op_signin_account`, `op_signin_all`, `op_login_headless`, `secrets_profiles`, `secrets_bootstrap_from_1p`, `op_signin_account_uuid`, `op_set_default_alias`, `machine_profile`, `secrets_push`, `secrets_pull`, `secrets_sync_status`

### settings
`settings_persist_var`, `settings_init`, `settings_edit_vars`, `settings_edit_vars_machine`, `settings_edit_vars_os`, `settings_edit_aliases`, `settings_edit_paths`, `settings_status`

### spark
`spark_mode_status`, `spark_mode_use`, `spark_log_level`, `jar_matrix_resolve`, `jar_matrix_status`, `spark_validate_versions`, `spark_config_status`, `spark_versions`, `spark_use_version`, `spark_default_version`, `scala_versions`, `scala_use_version`, `scala_default_version`, `java_versions`, `java_use_version`, `java_default_version`, `spark_start`, `spark_stop`, `spark_workers_status_line`, `spark_workers_health`, `spark_status`, `spark_health`, `get_spark_dependencies`, `smart_spark_submit`, `pyspark_shell`, `spark_history_server`, `spark_install_from_tar`, `spark_yarn_submit`, `spark_shell`, `spark_restart`

### system_diagnostics
`data_platform_health`, `data_platform_config_status`, `spark41_route_health`, `data_platform_use_versions`, `data_platform_default_versions`, `icloud_status`, `icloud_logs`, `icloud_snapshot`, `icloud_preflight`, `icloud_js_guard`, `icloud_js_restore`, `icloud_reset_state`, `dropbox_status`, `dropbox_restart`, `dropbox_relink_helper`, `linux_system_status`

### utils
`is_online`, `is_online_status`, `command_exists`, `mkcd`, `extract`, `download_jars`, `findtext`, `path_add`, `path_clean`, `zshconfig`, `zshreboot`

### zeppelin
`zeppelin_start`, `zeppelin_stop`, `zeppelin_status`, `zeppelin_restart`, `zeppelin_ui`, `zeppelin_config_status`, `zeppelin_diagnose`, `zeppelin_logs`, `zeppelin_seed_smoke_notebook`, `zeppelin_integration_status`, `zeppelin_integration_use`

## Troubleshooting Patterns
### Pull failure: untracked file would be overwritten
```bash
mkdir -p ~/tmp/zsh-vars-backup
cp ~/.config/zsh/vars.*.env ~/tmp/zsh-vars-backup/ 2>/dev/null || true
rm -f ~/.config/zsh/vars.cyberpower.env ~/.config/zsh/vars.linux.env ~/.config/zsh/vars.mac.env
git -C ~/.config/zsh pull origin main
```

### Startup warning with `/dev/null1`
Cause: typo like `eval "$(pyenv init --path)1"` in shell init files.
Fix:
```bash
sed -i 's/pyenv init --path)1/pyenv init --path)/g' ~/.zshenv ~/.zprofile 2>/dev/null || true
```

### Slow IDE terminals
Use staggered mode:
```bash
settings_persist_var ZSH_STARTUP_MODE auto ~/.config/zsh/vars.env
zshreboot
```

