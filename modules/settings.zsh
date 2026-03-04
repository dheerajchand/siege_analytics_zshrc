#!/usr/bin/env zsh
# =================================================================
# SETTINGS - Centralized user config (vars/paths/aliases)
# =================================================================

: "${ZSH_SETTINGS_DIR:=${ZSHRC_CONFIG_DIR:-${ZSH_CONFIG_DIR:-$HOME/.config/zsh}}}"
: "${ZSH_VARS_FILE:=$ZSH_SETTINGS_DIR/vars.env}"
: "${ZSH_ALIASES_FILE:=$ZSH_SETTINGS_DIR/aliases.zsh}"
: "${ZSH_PATHS_FILE:=$ZSH_SETTINGS_DIR/paths.env}"

_settings_detect_os_profile() {
    if [[ "$OSTYPE" == darwin* ]]; then
        echo "mac"
    else
        echo "linux"
    fi
}

_settings_detect_machine_profile() {
    if [[ -n "${ZSH_MACHINE_PROFILE:-}" ]]; then
        printf '%s\n' "${ZSH_MACHINE_PROFILE:l}"
        return 0
    fi
    if [[ -n "${ZSH_ENV_PROFILE:-}" ]]; then
        printf '%s\n' "${ZSH_ENV_PROFILE:l}"
        return 0
    fi
    local hn
    hn="$(hostname 2>/dev/null || echo "")"
    hn="${hn:l}"
    if [[ "$hn" == *cyberpower* ]]; then
        echo "cyberpower"
        return 0
    fi
    if [[ "$OSTYPE" == darwin* ]]; then
        echo "mac"
    else
        echo "linux"
    fi
}

: "${ZSH_OS_PROFILE:=$(_settings_detect_os_profile)}"
: "${ZSH_MACHINE_PROFILE:=$(_settings_detect_machine_profile)}"
: "${ZSH_VARS_OS_FILE:=$ZSH_SETTINGS_DIR/vars.${ZSH_OS_PROFILE}.env}"
: "${ZSH_VARS_MACHINE_FILE:=$ZSH_SETTINGS_DIR/vars.${ZSH_MACHINE_PROFILE}.env}"

settings_persist_var() {
    local key="$1"
    local value="$2"
    local file="${3:-$ZSH_VARS_FILE}"
    [[ -z "$key" || -z "$file" ]] && return 1
    [[ -f "$file" ]] || touch "$file"
    python3 - "$file" "$key" "$value" <<'PY'
import sys
path, key, value = sys.argv[1:4]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()
needle = f'export {key}="'
new_line = f'export {key}="${{{key}:-{value}}}"'
updated = False
out = []
for line in lines:
    if line.startswith(needle):
        out.append(new_line)
        updated = True
    else:
        out.append(line)
if not updated:
    out.append(new_line)
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
}

settings_init() {
    local created=0
    umask 077
    if [[ ! -f "$ZSH_VARS_FILE" ]]; then
        cat > "$ZSH_VARS_FILE" <<'EOF'
# Custom variables (export VAR="value")
# Example:
# export JARS_DIR="$HOME/.jars"
# export PYENV_DEFAULT_VENV="default_31111"
EOF
        created=1
        echo "Created $ZSH_VARS_FILE"
    fi
    if [[ ! -f "$ZSH_ALIASES_FILE" ]]; then
        cat > "$ZSH_ALIASES_FILE" <<'EOF'
# Custom aliases
# Example:
# alias proj='cd ~/Projects'
EOF
        created=1
        echo "Created $ZSH_ALIASES_FILE"
    fi
    if [[ ! -f "$ZSH_PATHS_FILE" ]]; then
        cat > "$ZSH_PATHS_FILE" <<'EOF'
# Custom convenience paths
# Example:
# export WRITING_STUFF="$HOME/Documents/Writing_Projects/Current"
EOF
        created=1
        echo "Created $ZSH_PATHS_FILE"
    fi
    if [[ ! -f "$ZSH_VARS_OS_FILE" ]]; then
        cat > "$ZSH_VARS_OS_FILE" <<EOF
# OS-specific variable overrides for profile: ${ZSH_OS_PROFILE}
# Loaded after vars.env and before machine-specific overrides.
# Example:
# export ZSH_STARTUP_MODE="\${ZSH_STARTUP_MODE:-auto}"
EOF
        created=1
        echo "Created $ZSH_VARS_OS_FILE"
    fi
    if [[ ! -f "$ZSH_VARS_MACHINE_FILE" ]]; then
        cat > "$ZSH_VARS_MACHINE_FILE" <<EOF
# Machine-specific variable overrides for profile: ${ZSH_MACHINE_PROFILE}
# Loaded last; values here override shared + OS defaults.
# Example:
# export PYENV_DEFAULT_VENV="\${PYENV_DEFAULT_VENV:-default_31111}"
EOF
        created=1
        echo "Created $ZSH_VARS_MACHINE_FILE"
    fi
    [[ "$created" -eq 1 ]] || echo "All settings files already exist"
}

settings_edit_vars() {
    [[ -f "$ZSH_VARS_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_VARS_FILE"
}

settings_edit_vars_machine() {
    [[ -f "$ZSH_VARS_MACHINE_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_VARS_MACHINE_FILE"
}

settings_edit_vars_os() {
    [[ -f "$ZSH_VARS_OS_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_VARS_OS_FILE"
}

settings_edit_aliases() {
    [[ -f "$ZSH_ALIASES_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_ALIASES_FILE"
}

settings_edit_paths() {
    [[ -f "$ZSH_PATHS_FILE" ]] || settings_init >/dev/null 2>&1
    "${EDITOR:-vi}" "$ZSH_PATHS_FILE"
}

settings_status() {
    echo "⚙️  Settings"
    echo "============"
    echo "OS profile: $ZSH_OS_PROFILE"
    echo "Profile: $ZSH_MACHINE_PROFILE"
    echo "Vars:    $ZSH_VARS_FILE"
    echo "Vars(OS): $ZSH_VARS_OS_FILE"
    echo "Vars(M): $ZSH_VARS_MACHINE_FILE"
    echo "Aliases: $ZSH_ALIASES_FILE"
    echo "Paths:   $ZSH_PATHS_FILE"
}

_settings_find_first_existing() {
    local candidate
    for candidate in "$@"; do
        [[ -n "$candidate" && -f "$candidate" ]] && { echo "$candidate"; return 0; }
    done
    return 1
}

settings_macos_gis_autoconfig() {
    [[ "$OSTYPE" == darwin* ]] || return 0

    local gdal_prefix="" geos_prefix=""
    if command -v gdal-config >/dev/null 2>&1; then
        gdal_prefix="$(gdal-config --prefix 2>/dev/null || true)"
    fi
    if command -v geos-config >/dev/null 2>&1; then
        geos_prefix="$(geos-config --prefix 2>/dev/null || true)"
    fi
    if [[ -z "$gdal_prefix" ]] && command -v brew >/dev/null 2>&1; then
        gdal_prefix="$(brew --prefix gdal 2>/dev/null || true)"
    fi
    if [[ -z "$geos_prefix" ]] && command -v brew >/dev/null 2>&1; then
        geos_prefix="$(brew --prefix geos 2>/dev/null || true)"
    fi

    local gdal_lib geos_lib
    gdal_lib="$(_settings_find_first_existing \
        "${GDAL_LIBRARY_PATH:-}" \
        "${gdal_prefix:+$gdal_prefix/lib/libgdal.dylib}" \
        "${gdal_prefix:+$gdal_prefix/lib/libgdal.so}" \
        "/opt/homebrew/opt/gdal/lib/libgdal.dylib" \
        "/usr/local/opt/gdal/lib/libgdal.dylib")"
    geos_lib="$(_settings_find_first_existing \
        "${GEOS_LIBRARY_PATH:-}" \
        "${geos_prefix:+$geos_prefix/lib/libgeos_c.dylib}" \
        "${geos_prefix:+$geos_prefix/lib/libgeos_c.so}" \
        "/opt/homebrew/opt/geos/lib/libgeos_c.dylib" \
        "/usr/local/opt/geos/lib/libgeos_c.dylib")"

    if [[ -n "$gdal_lib" ]]; then
        export GDAL_LIBRARY_PATH="$gdal_lib"
    fi
    if [[ -n "$geos_lib" ]]; then
        export GEOS_LIBRARY_PATH="$geos_lib"
    fi

    local -a lib_dirs=()
    [[ -n "$gdal_lib" ]] && lib_dirs+=("${gdal_lib:h}")
    [[ -n "$geos_lib" ]] && lib_dirs+=("${geos_lib:h}")
    if (( ${#lib_dirs[@]} > 0 )); then
        local joined
        joined="$(IFS=:; echo "${lib_dirs[*]}")"
        if [[ -n "${DYLD_FALLBACK_LIBRARY_PATH:-}" ]]; then
            case ":${DYLD_FALLBACK_LIBRARY_PATH}:" in
                *":${joined}:"*) ;;
                *) export DYLD_FALLBACK_LIBRARY_PATH="${joined}:${DYLD_FALLBACK_LIBRARY_PATH}" ;;
            esac
        else
            export DYLD_FALLBACK_LIBRARY_PATH="${joined}"
        fi
    fi
}

django_gis_doctor() {
    settings_macos_gis_autoconfig
    echo "🗺️  Django GIS Doctor"
    echo "====================="
    echo "OSTYPE: $OSTYPE"
    echo "GDAL_LIBRARY_PATH: ${GDAL_LIBRARY_PATH:-unset}"
    echo "GEOS_LIBRARY_PATH: ${GEOS_LIBRARY_PATH:-unset}"
    echo "gdal-config: $(command -v gdal-config >/dev/null 2>&1 && gdal-config --version 2>/dev/null || echo missing)"
    echo "geos-config: $(command -v geos-config >/dev/null 2>&1 && geos-config --version 2>/dev/null || echo missing)"
    if command -v python3 >/dev/null 2>&1; then
        python3 - <<'PY'
import os, ctypes
for name in ("GDAL_LIBRARY_PATH", "GEOS_LIBRARY_PATH"):
    p = os.environ.get(name)
    if not p:
        print(f"{name}_LOAD=SKIP (unset)")
        continue
    try:
        ctypes.CDLL(p)
        print(f"{name}_LOAD=OK")
    except Exception as e:
        print(f"{name}_LOAD=FAIL ({e})")
PY
    fi
}

mac_gis_env_sync() {
    local mode="set"
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --unset) mode="unset"; shift ;;
            --check) mode="check"; shift ;;
            --help|-h)
                echo "Usage: mac_gis_env_sync [--check|--unset]" >&2
                return 0
                ;;
            *)
                echo "Usage: mac_gis_env_sync [--check|--unset]" >&2
                return 1
                ;;
        esac
    done

    [[ "$OSTYPE" == darwin* ]] || { echo "mac_gis_env_sync is macOS-only" >&2; return 1; }
    command -v launchctl >/dev/null 2>&1 || { echo "launchctl not found" >&2; return 1; }

    settings_macos_gis_autoconfig

    if [[ "$mode" == "unset" ]]; then
        launchctl unsetenv GDAL_LIBRARY_PATH
        launchctl unsetenv GEOS_LIBRARY_PATH
        echo "✅ Cleared launchctl GIS env vars"
        return 0
    fi
    if [[ "$mode" == "check" ]]; then
        echo "GDAL_LIBRARY_PATH=$(launchctl getenv GDAL_LIBRARY_PATH)"
        echo "GEOS_LIBRARY_PATH=$(launchctl getenv GEOS_LIBRARY_PATH)"
        return 0
    fi

    [[ -n "${GDAL_LIBRARY_PATH:-}" ]] || { echo "GDAL_LIBRARY_PATH is unset; run django_gis_doctor" >&2; return 1; }
    [[ -n "${GEOS_LIBRARY_PATH:-}" ]] || { echo "GEOS_LIBRARY_PATH is unset; run django_gis_doctor" >&2; return 1; }
    launchctl setenv GDAL_LIBRARY_PATH "$GDAL_LIBRARY_PATH"
    launchctl setenv GEOS_LIBRARY_PATH "$GEOS_LIBRARY_PATH"
    echo "✅ launchctl setenv applied"
    echo "GDAL_LIBRARY_PATH=$(launchctl getenv GDAL_LIBRARY_PATH)"
    echo "GEOS_LIBRARY_PATH=$(launchctl getenv GEOS_LIBRARY_PATH)"
}

# Load order: shared vars -> os vars -> machine vars -> aliases -> paths
if [[ -f "$ZSH_VARS_FILE" ]]; then
    source "$ZSH_VARS_FILE"
fi
if [[ -f "$ZSH_VARS_OS_FILE" && "$ZSH_VARS_OS_FILE" != "$ZSH_VARS_FILE" ]]; then
    source "$ZSH_VARS_OS_FILE"
fi
if [[ -f "$ZSH_VARS_MACHINE_FILE" ]]; then
    if [[ "$ZSH_VARS_MACHINE_FILE" != "$ZSH_VARS_FILE" && "$ZSH_VARS_MACHINE_FILE" != "$ZSH_VARS_OS_FILE" ]]; then
        source "$ZSH_VARS_MACHINE_FILE"
    fi
fi
if [[ -f "$ZSH_ALIASES_FILE" ]]; then
    source "$ZSH_ALIASES_FILE"
fi
if [[ -f "$ZSH_PATHS_FILE" ]]; then
    export PATHS_LOADED=1
    source "$ZSH_PATHS_FILE"
fi

settings_macos_gis_autoconfig

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ settings loaded"
fi
