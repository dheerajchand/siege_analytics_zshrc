# Module: System Diagnostics

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
macOS iCloud/Dropbox helpers, Linux system summary, and data platform health.

## Environment
- `ZSH_TEST_MODE` (suppresses side effects)
- `OSTYPE` (OS detection)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `_run_with_timeout` | Run a command with timeout | `timeout`/`gtimeout`/`perl` | Timeout tool available or best-effort |
| `_is_macos` | macOS check | `OSTYPE` | None |
| `_icloud_js_is_suspect_name` | Detect npm-like iCloud root dirs | shell pattern checks | None |
| `_icloud_js_collect_suspects` | Enumerate suspicious iCloud dirs | `find`/glob | Root exists |
| `data_platform_health` | Spark/Hadoop/YARN health | `spark_health`, `hadoop_health` | Modules loaded |
| `icloud_status` | iCloud status | `brctl`, `fileproviderctl` | macOS only |
| `icloud_logs` | Recent CloudDocs logs | `log` | macOS only |
| `icloud_snapshot` | Write snapshot file | `icloud_status` | macOS only |
| `icloud_preflight` | Detect active sync | `brctl` | macOS only |
| `icloud_js_guard` | Detect/quarantine npm-like dirs in iCloud root | `mv`, `mkdir` | iCloud root exists |
| `icloud_js_restore` | Restore quarantined dirs from move log | `mv` | Move log exists |
| `icloud_reset_state` | Reset CloudDocs/FileProvider state | `killall` | Interactive shell |
| `dropbox_status` | Dropbox health summary | `ls`, `cat` | macOS only |
| `dropbox_restart` | Restart Dropbox app | `open` | macOS only |
| `dropbox_relink_helper` | Assist relink flow | `open`, `Finder` | macOS only |
| `linux_system_status` | Linux summary | `uname`, `df`, `free`/`vmstat`, `systemctl` | Linux only |
| `data_platform_config_status` | Spark/Hadoop/Python config | module functions | Modules loaded |
| `data_platform_use_versions` | Switch versions | SDKMAN/pyenv | Version tools installed |
| `data_platform_default_versions` | Persist versions | SDKMAN/pyenv | Version tools installed |
| `cross_host_smoke` | Multi-host smoke checks + reports | `ssh` (remote), local toolchain | Hosts reachable |
| `onboarding_validate` | Timed onboarding validation + evidence artifacts | shell toolchain | Config repo present |

## Notes
- `icloud_reset_state` is destructive; it moves state to `.bak.<timestamp>`.
- `icloud_js_guard` is report-only by default; use `--fix` to move suspicious directories to quarantine.
- `icloud_js_restore <move_log.tsv>` restores moves from a guard run.
- `data_platform_health` delegates to Spark/Hadoop/YARN modules.
- `cross_host_smoke` can emit both human-readable and machine-readable reports.
- `onboarding_validate` includes recovery hints per failed checkpoint and records config git-ref.

## Examples
```bash
# Report suspicious npm-like directories in iCloud Drive root
icloud_js_guard

# Quarantine them without prompt
icloud_js_guard --fix --yes

# Restore using the move log produced by a guard run
icloud_js_restore ~/Documents/iCloud_js_quarantine/<timestamp>/move_log.tsv

# Cross-host smoke report artifacts
cross_host_smoke --hosts local,cyberpower --json-out /tmp/smoke.json --report-out /tmp/smoke.txt

# Fresh-machine onboarding validation evidence
onboarding_validate --target-minutes 30 --json-out /tmp/onboarding.json --report-out /tmp/onboarding.txt
```
