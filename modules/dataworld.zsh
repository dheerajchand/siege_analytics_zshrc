#!/usr/bin/env zsh

# =================================================================
# DATA.WORLD - CSV source retention + derived geo cleanup
# =================================================================

_dataworld_usage() {
    echo "Usage:"
    echo "  dataworld_sync_csv [root] --owner <owner> --dataset <dataset> [--prefix <path>] [--apply] [--create-dataset]"
    echo "  data_csv_prune_derived [root] [--apply]"
}

_dataworld_token() {
    if [[ -n "${DATA_WORLD_API_TOKEN:-}" ]]; then
        printf '%s\n' "${DATA_WORLD_API_TOKEN}"
        return 0
    fi
    if [[ -n "${DATAWORLD_API_TOKEN:-}" ]]; then
        printf '%s\n' "${DATAWORLD_API_TOKEN}"
        return 0
    fi
    if [[ -n "${DW_AUTH_TOKEN:-}" ]]; then
        printf '%s\n' "${DW_AUTH_TOKEN}"
        return 0
    fi
    return 1
}

_dataworld_require_next_arg() {
    local flag="$1"
    local next="${2-}"
    if [[ -z "$next" || "$next" == --* ]]; then
        echo "❌ Missing value for ${flag}" >&2
        return 1
    fi
    return 0
}

_dataworld_urlencode() {
    local raw="${1:-}"
    python3 - "$raw" <<'PY'
import sys
from urllib.parse import quote
print(quote(sys.argv[1], safe=""))
PY
}

_dataworld_slugify_name() {
    local raw="${1:-dataset}"
    python3 - "$raw" <<'PY'
import re,sys
s=(sys.argv[1] or "dataset").strip().lower()
s=re.sub(r"[^a-z0-9]+","-",s).strip("-")
print(s[:60] or "dataset")
PY
}

_dataworld_collect_csv() {
    local root="$1"
    find "$root" \
        -path "$root/.git" -prune -o \
        -path "$root/.venv" -prune -o \
        -path "$root/venv" -prune -o \
        -path "$root/node_modules" -prune -o \
        -type f -iname "*.csv" -print
}

dataworld_sync_csv() {
    local root="$PWD"
    local owner="${DATA_WORLD_OWNER:-${DATAWORLD_OWNER:-}}"
    local dataset="${DATA_WORLD_DATASET:-${DATAWORLD_DATASET:-}}"
    local prefix="${DATA_WORLD_PREFIX:-${DATAWORLD_PREFIX:-}}"
    local create_dataset=0
    local dry_run=1

    if [[ $# -gt 0 && "$1" != --* ]]; then
        root="$1"
        shift
    fi
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --owner)
                _dataworld_require_next_arg "$1" "${2-}" || return 1
                owner="${2:-}"
                shift 2
                ;;
            --dataset)
                _dataworld_require_next_arg "$1" "${2-}" || return 1
                dataset="${2:-}"
                shift 2
                ;;
            --prefix)
                _dataworld_require_next_arg "$1" "${2-}" || return 1
                prefix="${2:-}"
                shift 2
                ;;
            --create-dataset)
                create_dataset=1
                shift
                ;;
            --apply)
                dry_run=0
                shift
                ;;
            --dry-run)
                dry_run=1
                shift
                ;;
            --help|-h)
                _dataworld_usage
                return 0
                ;;
            *)
                _dataworld_usage >&2
                return 1
                ;;
        esac
    done

    [[ -d "$root" ]] || { echo "❌ Root path not found: $root" >&2; return 1; }
    [[ -n "$owner" ]] || { echo "❌ Missing --owner (or DATA_WORLD_OWNER)" >&2; return 1; }
    [[ -n "$dataset" ]] || { echo "❌ Missing --dataset (or DATA_WORLD_DATASET)" >&2; return 1; }

    local token
    token="$(_dataworld_token 2>/dev/null || true)"
    if [[ -z "$token" ]]; then
        echo "❌ Missing data.world token (DATA_WORLD_API_TOKEN or DATAWORLD_API_TOKEN)" >&2
        return 1
    fi

    local -a files
    files=("${(@f)$(_dataworld_collect_csv "$root")}")
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "⚠️  No CSV files found under: $root"
        return 0
    fi

    local total_bytes=0
    local f sz
    for f in "${files[@]}"; do
        sz="$(stat -f "%z" "$f" 2>/dev/null || echo 0)"
        total_bytes=$((total_bytes + sz))
    done

    local total_mb
    total_mb="$(python3 - <<PY
b=$total_bytes
print(f"{b/1024/1024:.1f}")
PY
)"
    echo "📦 CSV source sync plan"
    echo "root=$root"
    echo "owner=$owner dataset=$dataset"
    echo "files=${#files[@]} total_mb=${total_mb}"

    if (( dry_run )); then
        local limit=25
        local i=0
        for f in "${files[@]}"; do
            echo "$f"
            i=$((i + 1))
            (( i >= limit )) && break
        done
        if (( ${#files[@]} > limit )); then
            echo "... (${#files[@]} total)"
        fi
        echo "🧪 Dry run only. Use --apply to upload."
        return 0
    fi

    command -v curl >/dev/null 2>&1 || { echo "❌ curl required for upload" >&2; return 1; }

    local base="https://api.data.world/v0"
    local owner_enc dataset_enc
    owner_enc="$(_dataworld_urlencode "$owner")"
    dataset_enc="$(_dataworld_urlencode "$dataset")"

    if (( create_dataset )); then
        local ds_title
        ds_title="$(_dataworld_slugify_name "$dataset")"
        curl -fsS \
            -H "Authorization: Bearer ${token}" \
            -H "Content-Type: application/json" \
            -X POST \
            -d "{\"title\":\"${ds_title}\",\"description\":\"CSV source archive from ${root}\",\"visibility\":\"PRIVATE\"}" \
            "${base}/datasets/${owner_enc}" >/dev/null 2>&1 || true
    fi

    local uploaded=0
    local uploaded_gz=0
    local failed=0
    local rel remote_name code gz_tmp
    for f in "${files[@]}"; do
        rel="${f#$root/}"
        remote_name="${prefix}${rel}"
        remote_name="${remote_name//\//__}"
        code="$(curl -sS -o /tmp/dw_upload_resp.$$ \
            -H "Authorization: Bearer ${token}" \
            -X POST \
            -F "file=@${f};filename=${remote_name}" \
            "${base}/uploads/${owner_enc}/${dataset_enc}/files" \
            -w "%{http_code}" || true)"
        if [[ "$code" == "200" || "$code" == "201" || "$code" == "202" ]]; then
            uploaded=$((uploaded + 1))
        elif [[ "$code" == "413" ]]; then
            gz_tmp="$(mktemp /tmp/dataworld-upload.XXXXXX.csv.gz)"
            if gzip -c "$f" > "$gz_tmp"; then
                code="$(curl -sS -o /tmp/dw_upload_resp.$$ \
                    -H "Authorization: Bearer ${token}" \
                    -X POST \
                    -F "file=@${gz_tmp};filename=${remote_name}.gz" \
                    "${base}/uploads/${owner_enc}/${dataset_enc}/files" \
                    -w "%{http_code}" || true)"
                if [[ "$code" == "200" || "$code" == "201" || "$code" == "202" ]]; then
                    uploaded=$((uploaded + 1))
                    uploaded_gz=$((uploaded_gz + 1))
                else
                    failed=$((failed + 1))
                    echo "❌ upload failed after gzip fallback: $f (http ${code:-unknown})" >&2
                fi
            else
                failed=$((failed + 1))
                echo "❌ gzip failed: $f" >&2
            fi
            rm -f "$gz_tmp" >/dev/null 2>&1 || true
        else
            failed=$((failed + 1))
            echo "❌ upload failed: $f (http ${code:-unknown})" >&2
        fi
    done
    rm -f /tmp/dw_upload_resp.$$ >/dev/null 2>&1 || true

    echo "✅ Upload complete: uploaded=${uploaded} (gz_fallback=${uploaded_gz}) failed=${failed}"
    (( failed == 0 ))
}

data_csv_prune_derived() {
    local root="$PWD"
    local apply=0

    if [[ $# -gt 0 && "$1" != --* ]]; then
        root="$1"
        shift
    fi
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --apply)
                apply=1
                shift
                ;;
            --dry-run)
                apply=0
                shift
                ;;
            --help|-h)
                _dataworld_usage
                return 0
                ;;
            *)
                _dataworld_usage >&2
                return 1
                ;;
        esac
    done

    [[ -d "$root" ]] || { echo "❌ Root path not found: $root" >&2; return 1; }

    local list
    list="$(mktemp)"
    find "$root" \
        -path "$root/.git" -prune -o \
        -type f \( -iname "*.shp" -o -iname "*.shx" -o -iname "*.dbf" -o -iname "*.prj" -o -iname "*.cpg" -o -iname "*.qpj" -o -iname "*.geojson" -o -iname "*.gpkg" -o -iname "*.kml" -o -iname "*.kmz" -o -iname "*.fgb" \) -print > "$list"
    find "$root" \
        -path "$root/.git" -prune -o \
        -type f -iname "*.zip" -print | rg "/census_fetcher/downloads/|/inputs/census/" >> "$list"

    local files bytes
    files="$(wc -l < "$list" | tr -d ' ')"
    bytes="$(while IFS= read -r f; do stat -f "%z" "$f"; done < "$list" | awk '{s+=$1} END{print s+0}')"
    local gb
    gb="$(python3 - <<PY
b=$bytes
print(f"{b/1024/1024/1024:.2f}")
PY
)"
    echo "🧹 Derived geo cleanup plan: files=${files} reclaim_gb=${gb}"

    if (( apply == 0 )); then
        sed -n '1,25p' "$list"
        if (( files > 25 )); then
            echo "... (${files} total)"
        fi
        rm -f "$list"
        echo "🧪 Dry run only. Use --apply to delete."
        return 0
    fi

    if (( files > 0 )); then
        while IFS= read -r f; do
            rm -f "$f"
        done < "$list"
        find "$root" -depth -type d -empty -not -path "$root/.git*" -delete
    fi
    rm -f "$list"
    echo "✅ Deleted derived geo outputs: files=${files} reclaim_gb=${gb}"
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ dataworld loaded"
fi
