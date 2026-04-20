#!/usr/bin/env zsh
# =================================================================
# CLEAN ZSHRC - Focused Shell Configuration
# =================================================================
# Purpose: Python, Spark/Hadoop, Docker, Database, Git management
# No security theater, just useful functionality
# =================================================================

# Startup profiler — opt-in via ZSH_PROFILE=1. Loads zsh/zprof as early
# as possible so every function call below is sampled. `zprof` is
# printed on shell exit via zshexit_functions. See
# wiki/Startup-Performance.md for how to read the output.
if [[ -n "${ZSH_PROFILE:-}" ]]; then
    zmodload zsh/zprof
    _zsh_profile_dump() { zprof }
    typeset -ga zshexit_functions
    zshexit_functions+=(_zsh_profile_dump)
fi

# Basic environment
export EDITOR="zed"
export VISUAL="$EDITOR"
: "${ZSHRC_CONFIG_DIR:=$HOME/.config/zsh}"
export ZSHRC_CONFIG_DIR
: "${ZSH_CONFIG_DIR:=$ZSHRC_CONFIG_DIR}"
export ZSH_CONFIG_DIR

# Minimal init for non-TTY interactive shells (prevents GUI app timeouts)
# Set ZSH_FORCE_FULL_INIT=1 to override.
# Known terminal programs (Warp, VS Code, etc.) are always allowed full init.
if [[ -o interactive && ! -t 0 && ! -t 1 && -z "${ZSH_FORCE_FULL_INIT:-}" \
      && "$TERM_PROGRAM" != "WarpTerminal" \
      && "$TERM_PROGRAM" != "vscode" \
      && -z "${WARP_IS_LOCAL_SHELL_SESSION:-}" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    else
        export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    fi
    [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
    [[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
    return 0
fi

# Set base PATH
if [[ "$OSTYPE" == "darwin"* ]]; then
    export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
else
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
fi
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
if [[ -d "$HOME/.pyenv/bin" && ":$PATH:" != *":$HOME/.pyenv/bin:"* ]]; then
    export PATH="$HOME/.pyenv/bin:$PATH"
fi

# Initialize SDKMAN lazily - set *_HOME vars from "current" symlinks now
# (fast path: no sourcing), then load the full SDK on first `sdk` call.
export SDKMAN_DIR="$HOME/.sdkman"

# Set *_HOME variables from SDKMAN current symlinks (no sourcing needed)
[[ -z "$HADOOP_HOME" && -d "$SDKMAN_DIR/candidates/hadoop/current" ]] && export HADOOP_HOME="$SDKMAN_DIR/candidates/hadoop/current"
[[ -z "$SPARK_HOME" && -d "$SDKMAN_DIR/candidates/spark/current" ]] && export SPARK_HOME="$SDKMAN_DIR/candidates/spark/current"
[[ -z "$JAVA_HOME" && -d "$SDKMAN_DIR/candidates/java/current" ]] && export JAVA_HOME="$SDKMAN_DIR/candidates/java/current"

# Add SDKMAN candidate bins to PATH without full init
if [[ -d "$SDKMAN_DIR/candidates" ]]; then
    for _sdk_cand in "$SDKMAN_DIR"/candidates/*/current/bin(N); do
        [[ ":$PATH:" != *":$_sdk_cand:"* ]] && export PATH="$_sdk_cand:$PATH"
    done
    unset _sdk_cand
fi

# Lazy-load full SDKMAN on first `sdk` invocation
if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
    sdk() {
        unfunction sdk 2>/dev/null
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
        sdk "$@"
    }
fi

# Oh-My-Zsh setup
export ZSH="$HOME/.dotfiles/oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(
    zsh-defer                 # must be first: defers other plugin work past first prompt
    git                       # canonical alias set + helpers
    git-extras                # completion for 60+ git-* subcommands (needs `brew install git-extras`)
    gitfast                   # upstream git completion (faster than OMZ's default)
    gh                        # gh CLI completion
    fzf                       # Ctrl-R history, Ctrl-T file, Alt-C dir (fzf keybinds)
    sudo                      # double-ESC prepends sudo to the current line
    copybuffer                # Ctrl-O copies current command-line to clipboard
    copypath                  # `copypath` copies $PWD to clipboard
    copyfile                  # `copyfile <f>` copies contents to clipboard
    history-substring-search  # up-arrow filters history by typed prefix
    aliases                   # `aliases` command lists aliases by group
    brew
    zsh-completions           # extra completions OMZ doesn't ship
    zsh-autosuggestions       # fish-style greyed suggestions as you type
    zsh-syntax-highlighting   # MUST BE LAST: colorizes commands as valid/invalid
)

# OMZ overhead we don't use.
# - auto-update: run manually via `omz update` instead of on every shell.
# - COMPFIX: compinit security check is already handled above.
# - MAGIC_FUNCTIONS: bracketed-paste handlers we don't rely on.
# - AUTO_TITLE: we set our own terminal titles elsewhere.
zstyle ':omz:update' mode disabled
ZSH_DISABLE_COMPFIX=true
DISABLE_MAGIC_FUNCTIONS=true
DISABLE_AUTO_TITLE=true


# Initialize completion system (rebuild dump at most once per day).
# Cache lives under $XDG_CACHE_HOME/zsh/ (not the repo root). Keyed by host
# and zsh version so mixed-host setups don't step on each other.
: "${XDG_CACHE_HOME:=$HOME/.cache}"
[[ -d "$XDG_CACHE_HOME/zsh" ]] || mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit
_zcompdump="$XDG_CACHE_HOME/zsh/zcompdump-${HOST}-${ZSH_VERSION}"
# stat -f %m is BSD/macOS; stat -c %Y is GNU/Linux. Fall through both.
_zcompdump_mtime=0
if [[ -f "$_zcompdump" ]]; then
    _zcompdump_mtime="$(stat -f %m "$_zcompdump" 2>/dev/null \
                       || stat -c %Y "$_zcompdump" 2>/dev/null \
                       || echo 0)"
fi
if (( _zcompdump_mtime > 0 )) && (( $(date +%s) - _zcompdump_mtime < 86400 )); then
    compinit -C -d "$_zcompdump"  # fast: skip security check, use cached dump
else
    compinit -d "$_zcompdump"      # full rebuild
fi
unset _zcompdump _zcompdump_mtime

# Warp is sensitive to noisy, probe-heavy interactive startup. Default it to a
# lighter path unless explicitly overridden.
: "${ZSH_STATUS_BANNER_MODE:=auto}"
: "${ZSH_AUTO_RECOVER_MODE:=auto}"

# Detect Warp so interactive startup can use a lighter default path there.
_zsh_is_warp_terminal() {
  [[ "${TERM_PROGRAM:-}" == "WarpTerminal" || "${WARP_IS_LOCAL_SHELL_SESSION:-}" == "1" ]]
}

# Decide whether this shell should render the heavy status banner.
_zsh_show_full_startup_banner() {
  case "${ZSH_STATUS_BANNER_MODE}" in
    full) return 0 ;;
    off|minimal) return 1 ;;
    auto)
      _zsh_is_warp_terminal && return 1
      return 0
      ;;
    *)
      return 0
      ;;
  esac
}

# Decide whether startup should attempt automatic service recovery.
_zsh_should_auto_recover_services() {
  case "${ZSH_AUTO_RECOVER_MODE}" in
    on) return 0 ;;
    off) return 1 ;;
    auto)
      _zsh_is_warp_terminal && return 1
      return 0
      ;;
    *)
      return 0
      ;;
  esac
}
zmodload zsh/compctl 2>/dev/null

# Load Oh-My-Zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"

    # Bind history-substring-search to arrow keys (plugin must be loaded first).
    if (( ${+functions[history-substring-search-up]} )); then
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
    fi

    # Deferred completion loads — heavy inits that don't need to block first prompt.
    # command-not-found runs `brew command-not-found-init` on macOS (~150ms), so we
    # source its plugin file via zsh-defer rather than listing it in plugins=(...).
    if (( ${+functions[zsh-defer]} )); then
        [[ -f "$ZSH/plugins/command-not-found/command-not-found.plugin.zsh" ]] \
            && zsh-defer source "$ZSH/plugins/command-not-found/command-not-found.plugin.zsh"
    fi
fi

# =================================================================
# STAGGERED LOADING - Performance Optimization for IDEs
# =================================================================
# IDEs take longer to load zsh, so we load modules progressively
# Regular terminals get everything immediately
# =================================================================

# Detect if running in an IDE
detect_ide() {
    # Check for common IDE environment variables
    [[ -n "$PYCHARM_HOSTED" ]] && return 0
    [[ -n "$DATASPELL_HOSTED" ]] && return 0
    [[ -n "$INTELLIJ_ENVIRONMENT_READER" ]] && return 0
    [[ -n "$JETBRAINS_IDE" ]] && return 0
    [[ -n "$VSCODE_INJECTION" ]] && return 0
    [[ -n "$VSCODE_GIT_IPC_HANDLE" ]] && return 0
    [[ -n "$CURSOR_TRACE_ID" ]] && return 0
    [[ "$TERM_PROGRAM" == "vscode" ]] && return 0
    [[ "$TERM_PROGRAM" == "Cursor" ]] && return 0
    
    # Check process tree for IDE
    local parent_proc=$(ps -p $PPID -o comm= 2>/dev/null)
    [[ "$parent_proc" =~ (pycharm|idea|webstorm|goland|datagrip|dataspell|code) ]] && return 0
    
    return 1
}

_zsh_startup_use_staggered() {
    local mode="${ZSH_STARTUP_MODE:-auto}"
    mode="${mode:l}"
    case "$mode" in
        full|immediate|eager)
            return 1
            ;;
        staggered|ide)
            return 0
            ;;
        auto|"")
            detect_ide
            return $?
            ;;
        *)
            detect_ide
            return $?
            ;;
    esac
}

# Module loader.
#
# Per-module opt-out flag: set `ZSH_DISABLE_<UPPERNAME>=1` to skip a
# module's load. Name-to-env-var mapping uppercases the module name
# and replaces hyphens with underscores. Examples:
#   ZSH_DISABLE_SPARK=1     # skip modules/spark.zsh
#   ZSH_DISABLE_ZEPPELIN=1  # skip modules/zeppelin.zsh
#   ZSH_DISABLE_SECRETS=1   # skip modules/secrets.zsh (advanced)
#
# Useful in per-host vars files or on-the-fly for debugging.
load_module() {
    local module="$1"
    local flag_name="ZSH_DISABLE_${module:u}"
    flag_name="${flag_name//-/_}"
    if [[ "${(P)flag_name:-0}" == "1" ]]; then
        return 0
    fi
    if [[ -f "$ZSH_CONFIG_DIR/modules/$module.zsh" ]]; then
        source "$ZSH_CONFIG_DIR/modules/$module.zsh"
    else
        echo "❌ Module not found: $module"
        return 1
    fi
}

# =================================================================
# ESSENTIAL ALIASES & CONSTANTS - Load First
# =================================================================

# Basic aliases (always available immediately)
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Git shortcuts (in addition to Oh-My-Zsh)
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# =================================================================
# MODULE LOADING - Staggered for IDEs, Immediate for Terminals
# =================================================================

# Load modules based on environment
if _zsh_startup_use_staggered; then
    export ZSH_IS_IDE_TERMINAL=1
    mode_label="${ZSH_STARTUP_MODE:-auto}"
    echo "🖥️  Staggered startup mode (${mode_label}) - integrated terminal optimization enabled"
    
    # Tier 1: Essential (load immediately - IDE needs Python right away)
    load_module utils       # Provides is_online, mkcd, extract, path_add
    load_module settings    # vars/aliases/paths
    load_module compat      # Stack compatibility profiles + guards
    load_module secrets     # Local + 1Password env vars
    load_module python      # Python environment (geo31111 auto-activated)
    load_module system_diagnostics  # iCloud/Dropbox helpers
    load_module agents
    load_module paths
    load_module screen      # GNU screen helpers
    load_module doctor      # zsh_doctor health-check
    
    # Tier 2: Credentials & paths (defer in current shell)
    _zsh_load_tier2() {
        load_module credentials  # 1Password/Keychain
        load_module database     # PostgreSQL with credentials
        load_module backup       # Git self-backup
        load_module github       # GitHub CLI workflows
        load_module gitlab       # GitLab CLI workflows
        load_module dataworld    # data.world CSV retention + geo cleanup
        load_module databricks   # Databricks + Lakebase workflows
    }
    
    # Tier 3: Heavy tools (defer in current shell)
    _zsh_load_tier3() {
        load_module docker       # Docker management
        load_module spark        # Spark cluster (uses is_online!)
        load_module hadoop       # Hadoop/YARN/HDFS
        load_module livy         # Livy server (Zeppelin Spark 4.1 path)
        load_module zeppelin     # Zeppelin notebooks
        echo "✅ All modules loaded" >&2
    }
    
    if zmodload zsh/sched 2>/dev/null; then
        # Some zsh builds reject fractional sched offsets ("+0.1").
        # Use integer seconds and fall back to immediate loading if scheduling fails.
        if ! sched +1 _zsh_load_tier2 2>/dev/null; then
            _zsh_load_tier2
        fi
        if ! sched +2 _zsh_load_tier3 2>/dev/null; then
            _zsh_load_tier3
        fi
    else
        _zsh_load_tier2
        _zsh_load_tier3
    fi
    
    echo "💡 Python ready now, Spark/Hadoop loading in background"
    
else
    export ZSH_IS_IDE_TERMINAL=0
    # Regular terminal - load everything immediately (fast enough)
    echo "🚀 Loading modules..."

    load_module utils
    load_module settings
    load_module compat
    load_module secrets
    load_module python
    load_module system_diagnostics
    load_module agents
    load_module paths
    load_module screen
    load_module credentials
    load_module database
    load_module backup
    load_module github
    load_module gitlab
    load_module dataworld
    load_module databricks
    load_module docker
    load_module doctor

    # Heavy data-platform modules. Defer past first prompt when the
    # user opts in via ZSH_DEFER_DATA_PLATFORM=1. Deferring is not the
    # default because the startup status banner calls spark_/hadoop_
    # functions during init; deferring breaks them in that window.
    if [[ "${ZSH_DEFER_DATA_PLATFORM:-0}" == "1" ]] \
       && (( ${+functions[zsh-defer]} )); then
        zsh-defer load_module spark
        zsh-defer load_module hadoop
        zsh-defer load_module livy
        zsh-defer load_module zeppelin
    else
        load_module spark
        load_module hadoop
        load_module livy
        load_module zeppelin
    fi
fi

# =================================================================
# FIX PATH - Ensure Hadoop/Spark bins are in PATH after all loading
# =================================================================
# Problem: pyenv init and other tools may reorganize PATH
# Solution: Explicitly ensure SDKMAN tools are in PATH after everything loads

if [[ -n "$HADOOP_HOME" && -d "$HADOOP_HOME/bin" ]]; then
    [[ ":$PATH:" != *":$HADOOP_HOME/bin:"* ]] && export PATH="$HADOOP_HOME/bin:$PATH"
    [[ ":$PATH:" != *":$HADOOP_HOME/sbin:"* ]] && export PATH="$HADOOP_HOME/sbin:$PATH"
fi

if [[ -n "$SPARK_HOME" && -d "$SPARK_HOME/bin" ]]; then
    [[ ":$PATH:" != *":$SPARK_HOME/bin:"* ]] && export PATH="$SPARK_HOME/bin:$PATH"
    [[ ":$PATH:" != *":$SPARK_HOME/sbin:"* ]] && export PATH="$SPARK_HOME/sbin:$PATH"
fi

# Rehash command table after PATH changes without invoking pyenv's wrapper.
builtin rehash

# Help
zsh_help() {
    echo "🚀 ZSH Quick Reference"
    echo "===================="
    echo ""
    echo "🐍 Python:"
    echo "  py_env_switch [env]    - Switch Python environment"
    echo "  py_env_switch --default <env> - Set default venv"
    echo "  python_status          - Show current environment"
    echo "  python_config_status   - Show configuration"
    echo "  pyenv_use_version <v>  - pyenv shell <version>"
    echo "  pyenv_default_version <v> - pyenv global <version>"
    echo "  ds_project_init <name> - Create data science project"
    echo "  claude_tmp_cleanup [min_gb] [dry_run] - Remove runaway Claude temp outputs"
    echo ""
    echo "⚡ Spark:"
    echo "  spark_start            - Start Spark cluster"
    echo "  spark_stop             - Stop cluster"
    echo "  spark_status           - Show status"
    echo "  spark_mode_use <auto|local|cluster> [--persist] - Set Spark execution mode"
    echo "  spark_mode_status      - Show effective Spark master resolution"
    echo "  spark_log_level [level] [--persist] - Set Spark log level (default WARN)"
    echo "  spark_config_status    - Show configuration"
    echo "  spark_use_version <v>  - SDKMAN use Spark version"
    echo "  spark_default_version <v> - SDKMAN default Spark"
    echo "  scala_use_version <v>  - SDKMAN use Scala version"
    echo "  scala_default_version <v> - SDKMAN default Scala"
    echo "  java_use_version <v>   - SDKMAN use Java version"
    echo "  java_default_version <v> - SDKMAN default Java"
    echo "  smart_spark_submit <file> - Submit job (auto-detects cluster)"
    echo "  spark_yarn_submit <file> - Submit to YARN"
    echo "  spark_install_from_tar [--default] [--dry-run] <version> <tarball> - Install Spark via SDKMAN layout"
    echo "  pyspark_shell          - Interactive PySpark"
    echo "  jar_matrix_resolve     - Resolve Spark jar coordinates"
    echo "  jar_matrix_status      - Show Spark jar resolution status"
    echo ""
    echo "📝 Zeppelin:"
    echo "  zeppelin_start         - Start Zeppelin (Spark + Sedona)"
    echo "  zeppelin_stop          - Stop Zeppelin"
    echo "  zeppelin_status        - Show status"
    echo "  zeppelin_restart       - Restart Zeppelin"
    echo "  zeppelin_diagnose      - Diagnose config + runtime"
    echo "  zeppelin_ui [classic|angular] - Open web UI"
    echo "  zeppelin_logs          - Tail latest logs"
    echo "  zeppelin_seed_smoke_notebook - Create/run external diagnostics + Sedona/GraphFrames smoke notebook"
    echo "  zeppelin_integration_use <embedded|livy|external> [--persist] - Set Zeppelin Spark integration mode"
    echo "  zeppelin_integration_status - Show active integration mode"
    echo ""
    echo "🔌 Livy:"
    echo "  livy_start             - Start Livy server"
    echo "  livy_stop              - Stop Livy server"
    echo "  livy_status            - Show Livy status and endpoint"
    echo "  livy_logs              - Tail latest Livy logs"
    echo ""
    echo "🧩 Compatibility:"
    echo "  compat_profiles        - List supported stack profiles"
    echo "  stack_profile_use <profile> [--persist] - Activate a compatibility profile"
    echo "  stack_profile_status   - Show active profile and version pins"
    echo "  stack_validate_versions [--component zeppelin] - Validate runtime combo against matrix"
    echo ""
    echo "🐘 Hadoop:"
    echo "  start_hadoop [--format] - Start HDFS + YARN (format if needed)"
    echo "  stop_hadoop            - Stop services"
    echo "  hadoop_status          - Show status"
    echo "  hadoop_config_status   - Show configuration"
    echo "  hadoop_use_version <v> - SDKMAN use Hadoop version"
    echo "  hadoop_default_version <v> - SDKMAN default Hadoop"
    echo "  yarn_application_list  - List YARN apps"
    echo "  yarn_kill_all_apps --force - Kill all YARN apps"
    echo "  hdfs_ls [path]         - List HDFS files"
    echo "  hdfs_rm --force <path> - Remove from HDFS"
    echo ""
    echo "🐳 Docker:"
    echo "  docker_status          - System status"
    echo "  docker_cleanup         - Remove stopped containers"
    echo "  docker_shell <container> - Shell into container"
    echo "  docker_logs <container> - View logs"
    echo ""
    echo "🗄️  Database:"
    echo "  pg_connect [db]        - Connect to PostgreSQL"
    echo "  pg_test_connection     - Test connection"
    echo "  setup_postgres_credentials - Setup passwords"
    echo ""
    echo "🔐 Credentials:"
    echo "  get_credential <service> <user> - Retrieve from 1Password/Keychain"
    echo "  store_credential <service> <user> <pass> - Store securely"
    echo "  ga_store_service_account <file.json> - Store GA credentials"
    echo ""
    echo "🔐 Secrets:"
    echo "  secrets_status          - Show secrets loader status"
    echo "  secrets_edit            - Edit secrets.env (chmod 600)"
    echo "  secrets_init            - Create secrets.env from example"
    echo "  secrets_init_map        - Create secrets.1p from example"
    echo "  secrets_map_sanitize    - Validate/clean secrets.1p"
    echo "  secrets_init_profile    - Interactive profile setup"
    echo "  secrets_profile_switch  - Set profile (persists) and reload"
    echo "  secrets_validate_setup  - Validate 1Password setup"
    echo "  secrets_profiles        - List profiles and colors"
    echo "  secrets_bootstrap_from_1p - Pull secrets files from 1Password"
    echo "  secrets_sync_to_1p      - Sync secrets.env to 1Password"
    echo "  secrets_pull_from_1p    - Pull secrets.env from 1Password"
    echo "  secrets_sync_all_to_1p  - Sync all secrets files to 1Password"
    echo "  secrets_pull_all_from_1p - Pull all secrets files from 1Password"
    echo "  secrets_agent_refresh   - Build local agent env cache from 1Password map"
    echo "  secrets_agent_source    - Load local agent env cache"
    echo "  secrets_agent_status    - Show agent env cache status"
    echo "  op_accounts_edit        - Edit 1Password account aliases"
    echo "  op_accounts_set_alias   - Set alias in op-accounts.env"
    echo "  op_accounts_seed        - Prompt to seed aliases from op CLI"
    echo "  op_accounts_sanitize    - Validate/clean op-accounts.env"
    echo "  op_verify_accounts      - Sign in + verify secrets per alias"
    echo "  op_set_default          - Set default 1Password account/vault"
    echo "  op_list_accounts_vaults - List accounts and vaults"
    echo "  op_list_items           - List items in account/vault"
    echo "  op_find_item_across_accounts - Find item title across accounts"
    echo "  secrets_find_account_for_item - Find account containing item title"
    echo "  secrets_source_set      - Set 1Password source account/vault"
    echo "  secrets_source_status   - Show 1Password source of truth"
    echo "  op_signin_account       - Sign in to an account alias"
    echo "  op_signin_all           - Sign in to all account aliases"
    echo "  op_set_default_alias    - Set default using alias"
    echo "  secrets_push [host]     - Push secrets (to 1Password + optional host)"
    echo "  secrets_pull [host]     - Pull secrets (from 1Password or host)"
    echo "  secrets_sync_status     - Show sync status and quick workflow"
    echo "  secrets_missing_from_1p - List missing 1Password items"
    echo "  secrets_rsync_to_host   - Rsync secrets files to host"
    echo "  secrets_rsync_from_host - Rsync secrets files from host"
    echo "  secrets_rsync_to_cyberpower   - Rsync secrets to cyberpower"
    echo "  secrets_rsync_from_cyberpower - Rsync secrets from cyberpower"
    echo "  secrets_rsync_verify    - Verify secrets files locally/remote"
    echo ""
    echo "🩺 Diagnostics:"
    echo "  icloud_status           - macOS-only iCloud status"
    echo "  icloud_preflight        - macOS-only iCloud preflight"
    echo "  icloud_js_guard         - Detect/quarantine npm-like dirs in iCloud root"
    echo "  icloud_js_restore       - Restore dirs from icloud_js_guard move log"
    echo "  dropbox_status          - macOS-only Dropbox status"
    echo "  dropbox_restart         - macOS-only Dropbox restart"
    echo "  linux_system_status     - Linux-only system overview"
    echo "  data_platform_health    - Spark/Hadoop/YARN health suite"
    echo "  data_platform_config_status - Spark/Hadoop/Python config"
    echo "  spark41_route_health [--spark-smoke] - Spark 4.1 + Zeppelin route checks"
    echo "  data_platform_use_versions --spark v --hadoop v --scala v --java v --pyenv v"
    echo "  data_platform_default_versions --spark v --hadoop v --scala v --java v --pyenv v"
    echo "  spark_health            - Spark master/worker health"
    echo "  hadoop_health           - HDFS/YARN health overview"
    echo "  yarn_health             - YARN health overview"
    echo ""
    echo "📦 Backup:"
    echo "  backup ['message']     - Commit and push current branch"
    echo "  backup_merge_main [branch] - Merge branch into main and push"
    echo "  pushmain ['message']   - Backup current branch, then merge to main"
    echo "  git_sync_safe          - Safe pull with rebase + autostash"
    echo "  git_sync_hard [--yes]  - Hard sync to remote branch (destructive)"
    echo "  repo_sync              - Sync repository"
    echo ""
    echo "🐙 GitHub:"
    echo "  gh_auth_status         - Check GitHub CLI authentication"
    echo "  gh_org_clone_all --org <org> [--dest <dir>] - Clone all repos from org"
    echo "  gh_repo_clone_matrix --file <repos.txt> [--dest <dir>] - Clone listed repos"
    echo "  gh_issue_ls_mine [--repo <owner/repo>] - List your assigned issues"
    echo "  gh_issue_start <num> --repo <owner/repo> - Create branch from issue"
    echo "  gh_issue_close_with_commit <num> --repo <owner/repo> --commit <sha> - Close issue"
    echo "  gh_pr_create_from_branch [--repo <owner/repo>] [--base <branch>] - Open PR"
    echo "  gh_pr_merge_safe <num> --repo <owner/repo> - Merge PR if safe"
    echo "  gh_pr_rebase_safe <num> --repo <owner/repo> - Rebase PR branch if safe"
    echo "  gh_release_cut --repo <owner/repo> --tag <tag> [--target <branch>] - Create release"
    echo ""
    echo "🦊 GitLab:"
    echo "  gl_auth_status         - Check GitLab CLI authentication"
    echo "  gl_group_clone_all --group <group> [--dest <dir>] - Clone all group repos"
    echo "  gl_project_clone_matrix --file <repos.txt> [--dest <dir>] - Clone listed repos"
    echo "  gl_issue_ls_mine [--project <group/project>] - List your assigned issues"
    echo "  gl_issue_start <iid> --project <group/project> - Create branch from issue"
    echo "  gl_issue_close_with_commit <iid> --project <group/project> --commit <sha> - Close issue"
    echo "  gl_mr_create_from_branch --project <group/project> [--target <branch>] - Open MR"
    echo "  gl_mr_merge_safe <iid> --project <group/project> - Merge MR if safe"
    echo "  gl_mr_rebase_safe <iid> --project <group/project> - Rebase MR if safe"
    echo "  gl_release_cut --project <group/project> --tag <tag> [--ref <branch>] - Create release"
    echo "  git_hosting_status     - GitHub/GitLab auth + branch summary"
    echo ""
    echo "🧱 Databricks:"
    echo "  dbx_auth_status        - Check Databricks CLI authentication/profiles"
    echo "  dbx_profiles_list      - List Databricks auth profiles"
    echo "  dbx_profile_use <profile> [--persist] - Set active Databricks profile"
    echo "  dbx_clusters_list      - List Databricks clusters"
    echo "  dbx_cluster_start <id> - Start Databricks cluster"
    echo "  dbx_cluster_stop <id>  - Stop Databricks cluster"
    echo "  dbx_jobs_list          - List Databricks jobs"
    echo "  dbx_job_run_now <id>   - Trigger Databricks job run"
    echo "  dbx_workspace_ls [path] - List Databricks workspace path"
    echo "  dbx_repos_sync [repo_path] - Sync Databricks repo to current branch"
    echo "  dbx_sql_warehouses_list - List SQL warehouses"
    echo "  dbx_lakebase_instances_list - List Lakebase instances"
    echo "  dbx_lakebase_dbs_list --instance <id_or_name> - List Lakebase databases"
    echo "  dbx_lakebase_db_create --instance <id_or_name> --db <name> - Create Lakebase DB"
    echo "  dbx_lakebase_db_drop --instance <id_or_name> --db <name> --force - Drop Lakebase DB"
    echo "  dbx_lakebase_psql --instance <id_or_name> --db <name> [--user <u>] - Connect via psql"
    echo "  dbx_lakebase_health --instance <id_or_name> - Lakebase instance health snapshot"
    echo ""
    echo "🛠️  Utilities:"
    echo "  zshconfig              - Edit zsh configuration"
    echo "  zshreboot              - Start a fresh shell"
    echo "  zshreload              - Alias for zshreboot"
    echo "  is_online              - Check internet (used by Spark)"
    echo "  download_jars          - Download Maven JARs to JARS_DIR"
    echo "  mkcd <dir>             - Create and cd"
    echo "  extract <file>         - Universal archive extraction"
    echo "  path_clean             - Remove duplicate PATH entries"
    echo ""
    echo "📌 Custom Paths:"
    echo "  paths_init             - Create paths.env"
    echo "  paths_edit             - Edit custom paths"
    echo "  paths_list             - List custom paths"
    echo ""
    echo "⚙️  Settings:"
    echo "  settings_init          - Create vars/aliases/paths files"
    echo "  settings_edit_vars     - Edit vars.env"
    echo "  settings_edit_vars_os  - Edit OS vars override file"
    echo "  settings_edit_vars_machine - Edit machine vars override file"
    echo "  settings_edit_aliases  - Edit aliases.zsh"
    echo "  settings_edit_paths    - Edit paths.env"
    echo "  settings_status        - Show settings file locations"
    echo ""
    echo "🤖 Codex:"
    echo "  codex_session [name]   - Print resume command (select if empty)"
    echo "  codex_session_list     - List saved sessions"
    echo "  codex_session_add      - Add session (name id|desc)"
    echo "  codex_session_update   - Update session"
    echo "  codex_session_remove   - Remove session"
    echo "  codex_session_edit     - Edit sessions file"
    echo "  codex_start_net        - Start Codex with network enabled"
    echo "  codex_start_danger     - Start Codex without sandbox"
    echo "  codex_init [opts]      - Initialize AGENTS.md + .codex defaults (opt: --add-session)"
    echo "  ai_init [opts]         - Initialize Claude and Codex configs together"
    echo "  claude_init [opts]     - Initialize Claude config templates"
    echo "  claude_session [name]  - Print Claude resume command"
    echo ""
    echo "📚 Full docs: $ZSH_CONFIG_DIR/README.md"
}
alias zhelp='zsh_help'

# Show loaded modules
modules() {
    echo "📦 Loaded Modules"
    echo "================"
    echo "✅ utils       - Core utilities (is_online, mkcd, extract)"
    echo "✅ python      - Python/pyenv management"
    echo "✅ spark       - Spark cluster operations"
    echo "✅ hadoop      - Hadoop/YARN management"
    echo "✅ livy        - Livy server for Zeppelin Spark 4.1 integration"
    echo "✅ zeppelin    - Zeppelin notebooks"
    echo "✅ docker      - Container management"
    echo "✅ database    - PostgreSQL connections"
    echo "✅ credentials - Secure credential storage"
    echo "✅ secrets     - Local + 1Password secrets"
    echo "✅ system_diagnostics - iCloud/Dropbox/Linux diagnostics"
    echo "✅ agents      - Codex session helpers"
    echo "✅ compat      - Version compatibility matrix + profile guards"
    echo "✅ paths       - Custom path aliases"
    echo "✅ settings    - Vars/Aliases/Paths"
    echo "✅ backup      - Git self-backup system"
    echo "✅ github      - GitHub CLI repo/issue/PR workflows"
    echo "✅ gitlab      - GitLab CLI repo/issue/MR workflows"
    echo "✅ databricks  - Databricks + Lakebase workflows"
}

# Powerlevel10k configuration
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Profile-aware palette (banner + prompt accents)
typeset -gA ZSH_PROFILE_CONFIGS
ZSH_PROFILE_CONFIGS=(
    dev "Development workstation (green)"
    staging "Staging environment (yellow)"
    prod "Production environment (red)"
    laptop "Personal laptop (cyan)"
    cyberpower "Cyberpower host (dark green)"
)
typeset -gA ZSH_PROFILE_COLORS
ZSH_PROFILE_COLORS=(
    dev "32;1 32"
    staging "33;1 33"
    prod "31;1 31"
    laptop "36;1 36"
    cyberpower "32;2 32"
    default "35;1 35"
)
typeset -ga ZSH_PROFILE_ORDER
ZSH_PROFILE_ORDER=(dev staging prod laptop cyberpower)

_profile_palette() {
    local profile="${ZSH_ENV_PROFILE:-}"
    if typeset -p ZSH_PROFILE_COLORS >/dev/null 2>&1; then
        if [[ -n "$profile" && -n "${ZSH_PROFILE_COLORS[$profile]-}" ]]; then
            echo "${ZSH_PROFILE_COLORS[$profile]}"
            return 0
        fi
        if [[ -n "${ZSH_PROFILE_COLORS[default]-}" ]]; then
            echo "${ZSH_PROFILE_COLORS[default]}"
            return 0
        fi
    fi
    echo "35;1 35"
}

apply_profile_theme() {
    local palette header accent
    palette="$(_profile_palette)"
    header="${palette%% *}"
    accent="${palette##* }"
    export ZSH_PROFILE_HEADER_COLOR="$header"
    export ZSH_PROFILE_ACCENT_COLOR="$accent"

    if command -v p10k >/dev/null 2>&1; then
        typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND="$accent"
        typeset -g POWERLEVEL9K_DIR_FOREGROUND="$accent"
        typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND="$accent"
        p10k reload >/dev/null 2>&1 || true
    fi
}

_zsh_stamp_mtime() {
    local f="$1"
    [[ -f "$f" ]] || { echo "0"; return 0; }
    if stat -f %m "$f" >/dev/null 2>&1; then
        stat -f %m "$f"
        return 0
    fi
    stat -c %Y "$f" 2>/dev/null || echo "0"
}

_zsh_auto_recover_data_services() {
    typeset -g ZSH_DATA_RECOVERY_SUMMARY=""
    [[ -n "${ZSH_TEST_MODE:-}" ]] && return 0
    [[ "${ZSH_AUTO_RECOVER_DATA_SERVICES:-1}" != "1" ]] && return 0
    if [[ "${ZSH_IS_IDE_TERMINAL:-0}" == "1" && "${ZSH_AUTO_RECOVER_IN_IDE:-0}" != "1" ]]; then
        ZSH_DATA_RECOVERY_SUMMARY="skipped in IDE terminal"
        return 0
    fi

    local stamp="${ZSH_DATA_RECOVERY_STAMP:-/tmp/zsh-data-services-recovery-${USER}}"
    local now last window
    now="$(date +%s)"
    last="$(_zsh_stamp_mtime "$stamp")"
    window="${ZSH_DATA_RECOVERY_WINDOW_SEC:-180}"
    if [[ "$last" =~ '^[0-9]+$' ]] && (( now - last < window )); then
        ZSH_DATA_RECOVERY_SUMMARY="skipped (recent attempt ${now-last}s ago)"
        return 0
    fi
    : > "$stamp" 2>/dev/null || true

    local events=()
    local out rc

    if [[ "${ZSH_AUTO_RECOVER_SPARK:-1}" == "1" ]] && typeset -f spark_start >/dev/null 2>&1; then
        if ! pgrep -f "spark.deploy.master.Master" >/dev/null 2>&1 || ! pgrep -f "spark.deploy.worker.Worker" >/dev/null 2>&1; then
            out="$(spark_start 2>&1)"
            rc=$?
            if (( rc == 0 )); then
                events+=("Spark restarted")
            else
                events+=("Spark restart failed")
                [[ -n "$out" ]] && echo "$out" >&2
            fi
        fi
    fi

    if [[ "${ZSH_AUTO_RECOVER_HADOOP:-1}" == "1" ]] && typeset -f start_hadoop >/dev/null 2>&1 && command -v jps >/dev/null 2>&1; then
        if ! jps | grep -q "NameNode" || ! jps | grep -q "DataNode" || ! jps | grep -q "ResourceManager" || ! jps | grep -q "NodeManager"; then
            out="$(start_hadoop 2>&1)"
            rc=$?
            if (( rc == 0 )); then
                events+=("Hadoop/YARN restarted")
            else
                events+=("Hadoop/YARN restart failed")
                [[ -n "$out" ]] && echo "$out" >&2
            fi
        fi
    fi

    if [[ "${ZSH_AUTO_RECOVER_ZEPPELIN:-1}" == "1" ]] && typeset -f zeppelin_start >/dev/null 2>&1; then
        local zep_running=1
        if typeset -f _zeppelin_is_running >/dev/null 2>&1; then
            _zeppelin_is_running || zep_running=0
        else
            zep_running=0
        fi
        if (( zep_running == 0 )); then
            out="$(zeppelin_start 2>&1)"
            rc=$?
            if (( rc == 0 )); then
                events+=("Zeppelin restarted")
            else
                events+=("Zeppelin restart failed")
                [[ -n "$out" ]] && echo "$out" >&2
            fi
        fi
    fi

    if (( ${#events[@]} > 0 )); then
        ZSH_DATA_RECOVERY_SUMMARY="${(j:, :)events}"
    else
        ZSH_DATA_RECOVERY_SUMMARY="all services already running"
    fi
}

# Welcome message - show useful context
zsh_status_banner() {
    local header_color="${ZSH_PROFILE_HEADER_COLOR:-34}"
    local accent_color="${ZSH_PROFILE_ACCENT_COLOR:-36}"
    local reset_color="0"
    echo ""
    printf "\033[%sm%s\033[%sm\n" "$header_color" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$reset_color"
    printf "\033[%sm%s\033[%sm\n" "$header_color" "🚀 ZSH Configuration Loaded" "$reset_color"
    printf "\033[%sm%s\033[%sm\n" "$header_color" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$reset_color"

    # Git status (branch + last commit) for config repo
    local repo_root branch last_commit
    repo_root="$(git -C "$HOME/.config/zsh" rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$repo_root" ]]; then
        branch="$(git -C "$repo_root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
        last_commit="$(git -C "$repo_root" log -1 --pretty='%h %s' 2>/dev/null || true)"
        if [[ -n "$last_commit" && ${#last_commit} -gt 180 ]]; then
            last_commit="${last_commit:0:180}…"
        fi
        if [[ -n "$branch" && -n "$last_commit" ]]; then
            printf "\033[%sm%s\033[%sm (%s): %s\n" "$accent_color" "🌿 Git:" "$reset_color" "$branch" "$last_commit"
        elif [[ -n "$branch" ]]; then
            printf "\033[%sm%s\033[%sm (%s)\n" "$accent_color" "🌿 Git:" "$reset_color" "$branch"
        elif [[ -n "$last_commit" ]]; then
            printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🌿 Git:" "$reset_color" "$last_commit"
        fi
    fi

    # Python environment
    local pyenv_version="system"
    if command -v pyenv >/dev/null 2>&1; then
        pyenv_version="$(pyenv version-name 2>/dev/null || echo 'system')"
    fi
    local py_bin="python"
    command -v python >/dev/null 2>&1 || py_bin="python3"
    local py_version="not found"
    if command -v "$py_bin" >/dev/null 2>&1; then
        py_version="$("$py_bin" --version 2>&1 | head -1)"
    fi
    printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🐍 Python:" "$reset_color" "$pyenv_version (${py_version})"
    if command -v pyenv >/dev/null 2>&1; then
        local default_venv="${PYENV_DEFAULT_VENV:-${DEFAULT_PYENV_VENV:-}}"
        [[ -n "$default_venv" ]] && printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🧪 Pyenv venv:" "$reset_color" "$pyenv_version (default: $default_venv)"
    fi

    # Machine profile (env/role/host)
    if command -v machine_profile >/dev/null 2>&1; then
        printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🧭 Profile:" "$reset_color" "$(machine_profile)"
    fi

    # Spark / Hadoop / Java (lightweight checks only)
    local spark_state="missing"
    local hadoop_state="missing"
    local scala_state="missing"
    if command -v spark-submit >/dev/null 2>&1 || [[ -n "${SPARK_HOME:-}" ]]; then
        spark_state="available"
    fi
    if command -v hadoop >/dev/null 2>&1 || [[ -n "${HADOOP_HOME:-}" ]]; then
        hadoop_state="available"
    fi
    if command -v scala >/dev/null 2>&1; then
        scala_state="available"
    fi
    printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "⚡ Spark:" "$reset_color" "$spark_state  🐘 Hadoop: $hadoop_state  🧠 Scala: $scala_state"
    if command -v spark-submit >/dev/null 2>&1; then
        local spark_ver
        spark_ver="$(spark-submit --version 2>&1 | awk '/version/{print $NF; exit}')"
        [[ -n "$spark_ver" ]] && printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🔧 Spark version:" "$reset_color" "$spark_ver"
    fi
    if typeset -f spark_workers_status_line >/dev/null 2>&1; then
        local workers_line
        workers_line="$(spark_workers_status_line 2>/dev/null || true)"
        [[ -z "$workers_line" ]] && workers_line="unknown (worker diagnostic unavailable)"
        printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "👷 Spark workers:" "$reset_color" "$workers_line"
    fi
    if command -v java >/dev/null 2>&1; then
        local java_version
        java_version="$(java -version 2>&1 | head -n 1)"
        printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "☕ Java:" "$reset_color" "${java_version:-$JAVA_HOME}"
    elif [[ -n "${JAVA_HOME:-}" ]]; then
        printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "☕ Java:" "$reset_color" "$JAVA_HOME"
    fi
    local spark_version=""
    local scala_version=""
    local hadoop_version=""
    if typeset -f _spark_detect_versions >/dev/null 2>&1; then
        local detected
        detected="$(_spark_detect_versions 2>/dev/null || true)"
        spark_version="${detected%% *}"
        scala_version="${detected#* }"
    fi
    scala_version="${scala_version%%,*}"
    scala_version="${scala_version%% *}"
    if [[ -z "$scala_version" ]] && typeset -f _spark_detect_scala_version >/dev/null 2>&1; then
        scala_version="$(_spark_detect_scala_version 2>/dev/null || true)"
    fi
    if command -v hadoop >/dev/null 2>&1; then
        hadoop_version="$(hadoop version 2>/dev/null | awk '/Hadoop/{print $2; exit}')"
    fi
    if [[ -n "$spark_version" || -n "$scala_version" || -n "$hadoop_version" ]]; then
        printf "\033[%sm%s\033[%sm Spark %s  Scala %s  Hadoop %s\n" \
            "$accent_color" "🧪 Stack:" "$reset_color" \
            "${spark_version:-unknown}" "${scala_version:-unknown}" "${hadoop_version:-unknown}"
        if typeset -f spark_validate_versions >/dev/null 2>&1; then
            if ! spark_validate_versions >/dev/null 2>&1; then
                printf "\033[%sm%s\033[%sm\n" "$accent_color" "⚠️  Spark/Scala/Hadoop version mismatch (run: spark_validate_versions)" "$reset_color"
            fi
        fi
    fi

    # Current directory
    printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "📁 Location:" "$reset_color" "$(pwd)"

    # Key services status (never block shell startup)
    # Probes run in parallel to cut worst-case wait from ~6s to ~2s.
    local _startup_probe_timeout=2
    _zsh_startup_probe() {
        local seconds="${1:-2}"
        shift
        if typeset -f _run_with_timeout >/dev/null 2>&1; then
            _run_with_timeout "$seconds" "$@"
            return $?
        fi
        perl -e 'alarm shift; exec @ARGV' "$seconds" "$@"
    }

    # Launch probes in parallel (background subshells writing to temp files)
    local _probe_dir
    _probe_dir="$(mktemp -d 2>/dev/null || mktemp -d -t zsh-probe 2>/dev/null)"
    local -a _probe_pids=()
    local _have_probe_dir=0
    [[ -n "$_probe_dir" && -d "$_probe_dir" ]] && _have_probe_dir=1
    if (( _have_probe_dir )) && command -v docker >/dev/null 2>&1; then
        ( _zsh_startup_probe "$_startup_probe_timeout" docker info >/dev/null 2>&1 && echo "running" || echo "unreachable/timeout" ) > "$_probe_dir/docker" &
        _probe_pids+=($!)
    fi
    if (( _have_probe_dir )) && command -v op >/dev/null 2>&1; then
        ( _zsh_startup_probe "$_startup_probe_timeout" op account list >/dev/null 2>&1 && echo "yes" || echo "no" ) > "$_probe_dir/op" &
        _probe_pids+=($!)
    fi

    # Zeppelin status (lightweight, no network)
    local zeppelin_state=""
    if typeset -f _zeppelin_detect_home >/dev/null 2>&1; then
        zeppelin_state="missing"
        if _zeppelin_detect_home >/dev/null 2>&1; then
            if typeset -f _zeppelin_is_running >/dev/null 2>&1 && _zeppelin_is_running; then
                zeppelin_state="running"
            else
                zeppelin_state="stopped"
            fi
        fi
    elif [[ "${ZSH_IS_IDE_TERMINAL:-0}" == "1" ]]; then
        zeppelin_state="loading"
    fi

    # Collect parallel probe results (only wait on probe PIDs, not unrelated jobs)
    local _probe_pid
    for _probe_pid in "${_probe_pids[@]}"; do
        wait "$_probe_pid" 2>/dev/null
    done

    if (( _have_probe_dir )) && [[ -f "$_probe_dir/docker" ]]; then
        local docker_state
        docker_state="$(<"$_probe_dir/docker")"
        printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🐳 Docker:" "$reset_color" "$docker_state"
    fi

    if [[ -n "$zeppelin_state" ]]; then
        printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "📝 Zeppelin:" "$reset_color" "$zeppelin_state"
    fi
    local recovery_summary="${ZSH_DATA_RECOVERY_SUMMARY:-not attempted in this shell}"
    printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🩺 Auto-recovery:" "$reset_color" "$recovery_summary"

    # Secrets status
    local secrets_status="unknown"
    if [[ "${ZSH_SECRETS_MODE:-}" == "off" ]]; then
        secrets_status="off"
    else
        local file_ok="no"
        local op_ok="no"
        [[ -n "${ZSH_SECRETS_FILE:-}" && -f "$ZSH_SECRETS_FILE" ]] && file_ok="yes"
        if (( _have_probe_dir )) && [[ -f "$_probe_dir/op" ]]; then
            op_ok="$(<"$_probe_dir/op")"
        fi
        secrets_status="file:${file_ok} op:${op_ok} mode:${ZSH_SECRETS_MODE:-unset}"
    fi
    printf "\033[%sm%s\033[%sm %s\n" "$accent_color" "🔐 Secrets:" "$reset_color" "$secrets_status"
    (( _have_probe_dir )) && rm -rf "$_probe_dir" 2>/dev/null

    # Quick tips
    echo ""
    printf "\033[%sm%s\033[%sm\n" "$accent_color" "💡 Quick Commands:" "$reset_color"
    echo "   zsh_help      - Show all available commands"
    echo "   modules       - List loaded modules"
    echo "   python_status - Check Python environment"
    echo "   spark_status  - Check Spark status"
    echo "   hadoop_status - Check Hadoop status"
    echo "   data_platform_config_status - Spark/Hadoop/Python config"
    echo "   data_platform_health - Spark/Hadoop/YARN health"
    echo "   backup        - Commit and push config to GitHub"
    echo ""
    printf "\033[%sm%s\033[%sm\n" "$header_color" "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" "$reset_color"
    echo ""
}

if [[ -o interactive ]]; then
    apply_profile_theme
  if _zsh_should_auto_recover_services; then
    _zsh_auto_recover_data_services
  fi
  if _zsh_show_full_startup_banner; then
    zsh_status_banner
  fi
fi

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
if [[ "$OSTYPE" == "darwin"* && -d "$HOME/.rd/bin" ]]; then
    export PATH="$HOME/.rd/bin:$PATH"
fi
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# API Tokens
# Keep tokens in secrets backends (secrets.env / 1Password map), not in git-tracked files.

# pyenv: canonical init is in modules/python.zsh (setup_pyenv)
# For screen/tmux sessions, call setup_pyenv manually if needed

# cd to STARTUP_DIR if set (configured in vars.env or machine overrides)
if [[ -o interactive && -n "${STARTUP_DIR:-}" && -d "$STARTUP_DIR" ]]; then
    cd "$STARTUP_DIR"
fi
