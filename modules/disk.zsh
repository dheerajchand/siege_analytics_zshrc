#!/usr/bin/env zsh
# =================================================================
# DISK AUDIT & CLEANUP
# =================================================================
#
# Surveys disk usage and reclaims space from regenerable caches.
# All destructive functions are DRY-RUN BY DEFAULT — pass --execute
# to actually delete.
#
# Targets the cleanup categories codified during the 2026-04-28
# session: app caches that regenerate, stale JetBrains version
# dirs, npm cache, Claude vm_bundles, and timestamped backup
# pruning.
#
# Refuses to operate on iCloud-synced paths to avoid the corruption
# pattern documented in the session memory — see
# `disk_check_icloud_corruption` for the symptom test.
#
# Feature-flag opt-out: ZSH_DISABLE_DISK=1

typeset -ga _DISK_SAFE_CACHE_TARGETS=(
    "$HOME/.cache"
    "$HOME/.npm/_cacache"
    "$HOME/Library/Caches/CloudKit"
    "$HOME/Library/Caches/com.lukilabs.craft-agent.ShipIt"
    "$HOME/Library/Caches/BraveSoftware"
    "$HOME/Library/Caches/JetBrains"
    "$HOME/Library/Caches/@craft-agentelectron-updater"
    "$HOME/Library/Application Support/Slack/Service Worker"
    "$HOME/Library/Application Support/Claude/vm_bundles"
    "$HOME/Library/Application Support/Notion/Partitions"
)

# Print human-readable disk usage of a path, "MISSING" if absent.
_disk_size() {
    local path="$1"
    if [[ ! -e "$path" ]]; then
        printf "MISSING"
        return
    fi
    # Read into an array split on whitespace; first field is the size token
    local -a fields
    fields=(${=$(command du -sh "$path" 2>/dev/null)})
    printf "%s" "${fields[1]:-?}"
}

# True if path lives under iCloud-Drive-synced ~/Documents tree.
_disk_is_icloud_path() {
    local path="$1"
    case "$path" in
        "$HOME/Documents"|"$HOME/Documents/"*) return 0 ;;
        "$HOME/Desktop"|"$HOME/Desktop/"*) return 0 ;;
        *) return 1 ;;
    esac
}

# Show top N space consumers in a directory.
_disk_top_n() {
    local dir="$1" n="${2:-10}"
    [[ -d "$dir" ]] || { echo "disk: not a directory: $dir" >&2; return 1; }
    du -sh "$dir"/* 2>/dev/null | sort -rh | head -n "$n"
}

# Survey of biggest space consumers across the home dir.
disk_audit() {
    local n="${1:-15}"
    echo "=== Disk free ==="
    df -h "$HOME" 2>/dev/null | head -2
    echo
    echo "=== Top $n in \$HOME ==="
    du -sh "$HOME"/* "$HOME"/.[a-z]* 2>/dev/null | sort -rh | head -n "$n"
    echo
    echo "=== Top $n in ~/Library/Application Support ==="
    _disk_top_n "$HOME/Library/Application Support" "$n"
    echo
    echo "=== Top $n in ~/Library/Caches ==="
    _disk_top_n "$HOME/Library/Caches" "$n"
}

# Deeper audit including Documents and code project caches.
disk_audit_deep() {
    disk_audit "${1:-20}"
    echo
    echo "=== Top consumers under ~/Documents (3-deep) ==="
    du -sh "$HOME/Documents"/*/*/ 2>/dev/null | sort -rh | head -20
    echo
    echo "=== Project virtualenvs under ~/Documents/Professional ==="
    find "$HOME/Documents/Professional" -maxdepth 5 -type d \
        \( -name .venv -o -name venv -o -name node_modules -o -name target -o -name build \) \
        2>/dev/null | head -20 | while read -r d; do
            printf "%s\t%s\n" "$(_disk_size "$d")" "$d"
        done
}

# Find iCloud duplicate-filename corruption signature in a path.
disk_check_icloud_corruption() {
    local path="${1:-$HOME/Documents}"
    [[ -d "$path" ]] || { echo "disk: not a directory: $path" >&2; return 1; }
    echo "Scanning $path for iCloud duplicate-filename pattern (* 2.*)..."
    # zsh-native recursive glob; (N) = nullglob, (D) = include dotfiles,
    # avoids any reliance on external find which can be sandboxed away in
    # some non-interactive runners.
    local -a matches
    matches=("$path"/**/*' 2.'*(DN) "$path"/**/*' 2'(DN))
    local count=${#matches[@]}
    echo "Files matching pattern: $count"
    if (( count > 0 )); then
        echo
        echo "Top 10 dirs with most matches:"
        local m
        local -A dir_counts
        for m in "${matches[@]}"; do
            local d="${m%/*}"
            dir_counts[$d]=$(( ${dir_counts[$d]:-0} + 1 ))
        done
        for d in "${(@k)dir_counts}"; do
            printf "%6d %s\n" "${dir_counts[$d]}" "$d"
        done | sort -rn | head -10
    fi
    (( count == 0 ))
}

# Show what disk_clean_caches would delete (size + path). Use --execute to apply.
disk_clean_caches() {
    local execute=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --execute) execute=1; shift ;;
            --dry-run) execute=0; shift ;;
            -h|--help)
                cat <<EOF
disk_clean_caches [--execute|--dry-run]

Sweeps a curated list of regenerable caches:
$(printf '  %s\n' "${_DISK_SAFE_CACHE_TARGETS[@]}")

Plus: npm cache clean --force (if npm is installed).

Default is dry-run. Pass --execute to actually delete.
EOF
                return 0
                ;;
            *) echo "disk_clean_caches: unknown arg: $1" >&2; return 1 ;;
        esac
    done
    local total_logical=0 t sz
    local action="WOULD DELETE"
    (( execute )) && action="DELETING"
    for t in "${_DISK_SAFE_CACHE_TARGETS[@]}"; do
        if [[ ! -e "$t" ]]; then
            printf "  skip (missing): %s\n" "$t"
            continue
        fi
        if _disk_is_icloud_path "$t"; then
            printf "  skip (iCloud path, refuses to operate): %s\n" "$t" >&2
            continue
        fi
        sz=$(_disk_size "$t")
        printf "  %s (%s): %s\n" "$action" "$sz" "$t"
        if (( execute )); then
            rm -rf "$t" || { echo "disk: failed to remove $t" >&2; return 1; }
        fi
    done
    if command -v npm >/dev/null 2>&1; then
        if (( execute )); then
            echo "  running: npm cache clean --force"
            npm cache clean --force >/dev/null 2>&1 || \
                echo "disk: npm cache clean failed" >&2
        else
            echo "  WOULD RUN: npm cache clean --force"
        fi
    fi
    (( execute )) || echo "(dry-run; pass --execute to apply)"
    return 0
}

# Prune timestamped snapshot dirs in a backups tree, keeping --keep newest.
disk_prune_snapshots() {
    local root="" keep=5 execute=0 pattern='config_*'
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --root)    root="${2:-}"; shift 2 ;;
            --keep)    keep="${2:-5}"; shift 2 ;;
            --pattern) pattern="${2:-config_*}"; shift 2 ;;
            --execute) execute=1; shift ;;
            --dry-run) execute=0; shift ;;
            -h|--help)
                cat <<EOF
disk_prune_snapshots --root DIR [--keep N] [--pattern GLOB] [--execute]

Find timestamped snapshot dirs matching PATTERN under ROOT and delete
all but the newest N. Default keep=5, pattern=config_*, dry-run.

Example (zshrc_backups):
  disk_prune_snapshots --root ~/.zshrc_backups --pattern 'config_*' --keep 5 --execute
EOF
                return 0
                ;;
            *) echo "disk_prune_snapshots: unknown arg: $1" >&2; return 1 ;;
        esac
    done
    [[ -d "$root" ]] || { echo "disk_prune_snapshots: missing root: $root" >&2; return 1; }
    if _disk_is_icloud_path "$root"; then
        echo "disk_prune_snapshots: refusing to operate on iCloud path: $root" >&2
        return 2
    fi
    local -a snapshots
    snapshots=($(find "$root" -maxdepth 5 -type d -name "$pattern" 2>/dev/null | sort -r))
    local total=${#snapshots[@]}
    if (( total <= keep )); then
        echo "Only $total snapshot(s) matching '$pattern' — nothing to prune."
        return 0
    fi
    local to_delete=(${snapshots[$((keep+1)),-1]})
    local action="WOULD DELETE"
    (( execute )) && action="DELETING"
    printf "Found %d, keeping newest %d, %s %d:\n" \
        "$total" "$keep" "$action" "${#to_delete[@]}"
    local s
    for s in "${to_delete[@]}"; do
        printf "  %s (%s)\n" "$s" "$(_disk_size "$s")"
        (( execute )) && rm -rf "$s"
    done
    (( execute )) || echo "(dry-run; pass --execute to apply)"
    return 0
}

# Prune stale JetBrains config/cache dirs (keeps only the newest 2026.x).
disk_prune_jetbrains_stale() {
    local execute=0 keep_prefix='2026'
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --execute)     execute=1; shift ;;
            --dry-run)     execute=0; shift ;;
            --keep-prefix) keep_prefix="${2:-2026}"; shift 2 ;;
            -h|--help)
                cat <<EOF
disk_prune_jetbrains_stale [--execute] [--keep-prefix YEAR]

Deletes JetBrains config dirs under
~/Library/Application Support/JetBrains/ whose version prefix is NOT
the keep year (default 2026). Targets stale post-upgrade leftovers.
EOF
                return 0
                ;;
        esac
    done
    local base="$HOME/Library/Application Support/JetBrains"
    [[ -d "$base" ]] || { echo "JetBrains config dir not present."; return 0; }
    local d name action="WOULD DELETE"
    (( execute )) && action="DELETING"
    for d in "$base"/*/; do
        name="${d:t}"
        case "$name" in
            *"$keep_prefix"*) continue ;;
            Daemon|JBA|consentOptions|FileBrowser|edu) continue ;;
        esac
        printf "  %s (%s): %s\n" "$action" "$(_disk_size "$d")" "$d"
        (( execute )) && rm -rf "$d"
    done
    (( execute )) || echo "(dry-run; pass --execute to apply)"
    return 0
}

# Show the documented session-recovery for iCloud git corruption.
disk_icloud_recovery_steps() {
    cat <<'EOF'
iCloud git corruption recovery (per session 260428-smart-dune):

1. Stop the bleeding (root cause):
   System Settings -> Apple ID -> iCloud -> iCloud Drive
   Toggle Desktop & Documents Folders OFF (choose "Keep a Copy")
   Reboot
   Toggle Desktop & Documents Folders ON
   Do NOT enable Optimize Mac Storage

2. Audit:
   disk_check_icloud_corruption ~/Documents

3. Per broken repo: re-clone from origin into a non-iCloud path
   (~/Code/ or ~/git/), not ~/Documents/. Salvage any unpushed work
   with `git bundle create salvage.bundle --all` first.

4. Long-term: keep active dev repos OUT of iCloud-synced trees.

Full plan archived in session 260428-smart-dune at
plans/icloud-git-corruption-repair.md
EOF
}
