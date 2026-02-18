# Module: Databricks

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Databricks CLI workflows for profiles, clusters, jobs, workspace/repos sync, SQL warehouses, and Lakebase database management.

## Dependencies
- `databricks` CLI authenticated (`databricks auth login`)
- `python3` (or `python`) for JSON parsing
- `git` for `dbx_repos_sync`
- `psql` for `dbx_lakebase_psql`

## Functions

| Function | Purpose | Notes |
|---|---|---|
| `dbx_auth_status` | Show Databricks profile/auth status | Uses `databricks auth profiles` |
| `dbx_profiles_list` | List configured profiles | Useful before switching profile |
| `dbx_profile_use` | Set active profile in shell | Optional `--persist` writes `vars.env` |
| `dbx_clusters_list` | List clusters | Wrapper over `databricks clusters list` |
| `dbx_cluster_start` | Start cluster | Requires cluster id |
| `dbx_cluster_stop` | Stop cluster | Requires cluster id |
| `dbx_jobs_list` | List jobs | Wrapper over `databricks jobs list` |
| `dbx_job_run_now` | Trigger job run | Requires job id |
| `dbx_workspace_ls` | List workspace path | Defaults to `/` |
| `dbx_repos_sync` | Sync Databricks repo to local branch | Matches local repo path to Databricks repo id |
| `dbx_sql_warehouses_list` | List SQL warehouses | Uses API endpoint |
| `dbx_lakebase_instances_list` | List Lakebase instances | Supports `--json` passthrough |
| `dbx_lakebase_dbs_list` | List databases in Lakebase instance | Resolves instance by id or name |
| `dbx_lakebase_db_create` | Create Lakebase database | Instance by id or name |
| `dbx_lakebase_db_drop` | Drop Lakebase database | Requires explicit `--force` |
| `dbx_lakebase_psql` | Connect to Lakebase instance/database via psql | Resolves host from instance metadata |
| `dbx_lakebase_health` | Show instance + database health snapshot | Prints instance and db inventory |

## Examples

```bash
dbx_profile_use DEFAULT --persist
dbx_clusters_list
dbx_job_run_now 12345
dbx_repos_sync ~/work/my_repo

# Lakebase
dbx_lakebase_instances_list
dbx_lakebase_dbs_list --instance family
dbx_lakebase_db_create --instance family --db analytics
dbx_lakebase_db_drop --instance family --db analytics --force
```
