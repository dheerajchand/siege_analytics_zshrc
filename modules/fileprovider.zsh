#!/usr/bin/env zsh
# =================================================================
# FILEPROVIDER — diagnostics for macOS FileProvider daemon wedges
# =================================================================
# When iCloud Drive (or another cloud-storage provider) corrupts its
# local index, /usr/libexec/fileproviderd pegs CPU for hours/days,
# starves disk I/O, and downstream JetBrains / Finder pinwheel.
#
# This module provides:
#   fileprovider_status  — read-only health check across all providers
#   fileprovider_check   — wraps `fileproviderctl check` (FPCK)
#   fileprovider_unwedge — guided recovery (bounce + check + UI fallback)
#
# Trigger: if zsh_doctor reports `File providers: WARN` or your shell
# feels slow + Activity Monitor shows fileproviderd at the top.
# Saved a 109-hour CPU spinner on 2026-05-06.

# Pretty size for a byte count. Falls through both BSD/GNU stat sites.
_fp_human_size() {
    local bytes="${1:-0}"
    if (( bytes < 1024 )); then printf "%dB" "$bytes"
    elif (( bytes < 1024**2 )); then printf "%.1fK" "$((bytes / 1024.0))"
    elif (( bytes < 1024**3 )); then printf "%.1fM" "$((bytes / 1024.0**2))"
    elif (( bytes < 1024**4 )); then printf "%.1fG" "$((bytes / 1024.0**3))"
    else printf "%.1fT" "$((bytes / 1024.0**4))"
    fi
}

_fp_size_of() {
    [[ -f "$1" ]] || { echo 0; return 0; }
    stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || echo 0
}

# Report fileproviderd state + every active provider's local DB size.
# Flags DB > 1 GB and presence of SQLite spill files. Read-only.
fileprovider_status() {
    emulate -L zsh
    local fpd_pid fpd_cpu fpd_etime
    fpd_pid="$(pgrep -x fileproviderd 2>/dev/null || true)"
    if [[ -z "$fpd_pid" ]]; then
        print -- "fileproviderd: not running"
        return 0
    fi
    fpd_cpu="$(ps -p "$fpd_pid" -o %cpu= 2>/dev/null | tr -d ' ')"
    fpd_etime="$(ps -p "$fpd_pid" -o etime= 2>/dev/null | tr -d ' ')"
    print -- "fileproviderd  pid=${fpd_pid}  cpu=${fpd_cpu}%  etime=${fpd_etime}"
    local cpu_int="${fpd_cpu%.*}"
    if (( ${cpu_int:-0} >= 50 )); then
        print -- "  ⚠️  CPU ≥ 50% — provider may be stuck. Run fileprovider_unwedge."
    fi

    local fp_root="$HOME/Library/Application Support/FileProvider"
    if [[ ! -d "$fp_root" ]]; then
        print -- "no provider directory at $fp_root"
        return 0
    fi
    print -- ""
    print -- "Providers (DB sizes):"
    local entry name db wal db_size wal_size
    for entry in "$fp_root"/*(N/); do
        name="${entry:t}"
        db="$entry/database/db"
        wal="$entry/database/db-wal"
        db_size="$(_fp_size_of "$db")"
        wal_size="$(_fp_size_of "$wal")"
        printf "  %-50s db=%-7s wal=%s\n" \
            "$name" "$(_fp_human_size "$db_size")" "$(_fp_human_size "$wal_size")"
        if (( db_size > 1024**3 )); then
            print -- "    ⚠️  DB > 1 GB — likely the wedged provider."
        fi
    done

    # SQLite temp spill (the etilqs_ prefix is sqlite reversed).
    local tmp_dir="${TMPDIR:-/tmp}com.apple.fileproviderd"
    [[ -d "$tmp_dir" ]] || tmp_dir="/private/var/folders/$(echo "$USER" | head -c2)/$(echo "$USER" | head -c2)/T/com.apple.fileproviderd"
    local spill_files=()
    if [[ -d "$tmp_dir" ]]; then
        spill_files=("$tmp_dir"/etilqs_*(N))
    fi
    if (( ${#spill_files[@]} > 0 )); then
        print -- ""
        print -- "  ⚠️  SQLite temp spill files present (provider mid-operation):"
        local f
        for f in "${spill_files[@]}"; do
            printf "      %s  (%s)\n" "${f:t}" "$(_fp_human_size "$(_fp_size_of "$f")")"
        done
    fi
}

# Run Apple's FPCK (FileProvider Consistency Check) to detect index
# corruption. Read-only; reports without modifying.
fileprovider_check() {
    emulate -L zsh
    if ! command -v fileproviderctl >/dev/null 2>&1; then
        print -u2 -- "fileproviderctl not found — only available on recent macOS"
        return 1
    fi
    print -- "Running fileproviderctl check (this can take a few minutes)..."
    /usr/bin/fileproviderctl check -P -d "$@"
}

# Guided recovery for a wedged provider. Walks user through escalating
# steps with confirmation between each. Never goes further than killing
# fileproviderd; the toggle-off / reboot / toggle-on sequence is left as
# manual instructions because it requires GUI interaction.
fileprovider_unwedge() {
    emulate -L zsh
    print -- "fileprovider_unwedge — guided recovery"
    print -- ""
    fileprovider_status
    print -- ""

    local pid cpu_int
    pid="$(pgrep -x fileproviderd 2>/dev/null || true)"
    if [[ -z "$pid" ]]; then
        print -- "fileproviderd not running. Nothing to do."
        return 0
    fi
    cpu_int="$(ps -p "$pid" -o %cpu= 2>/dev/null | awk '{printf "%d", $1}')"
    if (( cpu_int < 50 )); then
        print -- "fileproviderd at ${cpu_int}% CPU — looks fine. Skipping bounce."
        return 0
    fi

    print -u2 -n -- "Bounce fileproviderd (sudo killall)? [y/N] "
    local ans
    read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || { print -- "Aborted."; return 1; }

    sudo killall fileproviderd
    print -- "Killed. Watching trajectory for 60 seconds..."
    local i new_pid new_cpu
    for i in 1 2 3 4 5 6; do
        sleep 10
        new_pid="$(pgrep -x fileproviderd 2>/dev/null || true)"
        if [[ -z "$new_pid" ]]; then
            print -- "  [$(date +%H:%M:%S)] not yet respawned"
            continue
        fi
        new_cpu="$(ps -p "$new_pid" -o %cpu= 2>/dev/null | tr -d ' ')"
        printf "  [%s] pid=%s cpu=%s%%\n" "$(date +%H:%M:%S)" "$new_pid" "$new_cpu"
    done

    print -- ""
    new_cpu="${new_cpu%.*}"
    if (( ${new_cpu:-0} < 30 )); then
        print -- "✅ fileproviderd settled to ${new_cpu}% CPU — likely fixed."
    else
        print -- "⚠️  fileproviderd still busy after bounce."
        print -- ""
        print -- "Next step (manual, GUI required):"
        print -- "  1. Settings → iCloud → Drive → tap 'Drive' tile"
        print -- "  2. Toggle 'Sync this Mac' OFF — choose 'Keep a Copy'"
        print -- "  3. Reboot"
        print -- "  4. Same toggle back ON — index rebuilds clean"
        print -- ""
        print -- "fileprovider_check  — run Apple's FPCK consistency check"
    fi
}
