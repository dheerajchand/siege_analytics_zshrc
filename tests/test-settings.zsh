#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

test_settings_load_order() {
    local tmp
    tmp="$(mktemp -d)"
    mkdir -p "$tmp"
    ZSH_SETTINGS_DIR="$tmp"
    ZSH_VARS_FILE="$tmp/vars.env"
    ZSH_ALIASES_FILE="$tmp/aliases.zsh"
    ZSH_PATHS_FILE="$tmp/paths.env"
    printf 'export JARS_DIR="/tmp/jars"\n' > "$ZSH_VARS_FILE"
    printf 'alias foo="bar"\n' > "$ZSH_ALIASES_FILE"
    printf 'export WRITING_STUFF="/tmp/writing"\n' > "$ZSH_PATHS_FILE"
    local out
    out="$(ZSH_SETTINGS_DIR="$tmp" ZSH_VARS_FILE="$ZSH_VARS_FILE" ZSH_ALIASES_FILE="$ZSH_ALIASES_FILE" ZSH_PATHS_FILE="$ZSH_PATHS_FILE" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/settings.zsh; echo \"\$JARS_DIR|\$WRITING_STUFF\"; alias foo")"
    assert_contains "$out" "/tmp/jars" "vars.env should load"
    assert_contains "$out" "/tmp/writing" "paths.env should load"
    assert_contains "$out" "foo=" "aliases should load"
    rm -rf "$tmp"
}

test_settings_machine_override() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp"
    printf 'export PYENV_DEFAULT_VENV="shared_default"\n' > "$tmp/vars.env"
    printf 'export PYENV_DEFAULT_VENV="machine_override"\n' > "$tmp/vars.cyberpower.env"
    printf 'export WRITING_STUFF="/tmp/writing"\n' > "$tmp/paths.env"
    printf 'alias foo="bar"\n' > "$tmp/aliases.zsh"
    out="$(ZSH_SETTINGS_DIR="$tmp" ZSH_VARS_FILE="$tmp/vars.env" ZSH_MACHINE_PROFILE="cyberpower" ZSH_VARS_MACHINE_FILE="$tmp/vars.cyberpower.env" ZSH_ALIASES_FILE="$tmp/aliases.zsh" ZSH_PATHS_FILE="$tmp/paths.env" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/settings.zsh; echo \"\$PYENV_DEFAULT_VENV|\$WRITING_STUFF\"")"
    assert_contains "$out" "machine_override|/tmp/writing" "machine vars should override shared vars and keep other files loading"
    rm -rf "$tmp"
}

test_settings_os_then_machine_override_order() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp"
    printf 'export PYENV_DEFAULT_VENV="shared_default"\n' > "$tmp/vars.env"
    printf 'export PYENV_DEFAULT_VENV="os_default"\n' > "$tmp/vars.linux.env"
    printf 'export PYENV_DEFAULT_VENV="machine_override"\n' > "$tmp/vars.cyberpower.env"
    printf 'export WRITING_STUFF="/tmp/writing"\n' > "$tmp/paths.env"
    printf 'alias foo="bar"\n' > "$tmp/aliases.zsh"
    out="$(ZSH_SETTINGS_DIR="$tmp" ZSH_VARS_FILE="$tmp/vars.env" ZSH_OS_PROFILE="linux" ZSH_VARS_OS_FILE="$tmp/vars.linux.env" ZSH_MACHINE_PROFILE="cyberpower" ZSH_VARS_MACHINE_FILE="$tmp/vars.cyberpower.env" ZSH_ALIASES_FILE="$tmp/aliases.zsh" ZSH_PATHS_FILE="$tmp/paths.env" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/settings.zsh; echo \"\$PYENV_DEFAULT_VENV\"")"
    assert_equal "machine_override" "$out" "machine vars should override os vars and shared defaults"
    rm -rf "$tmp"
}

test_settings_macos_gis_autoconfig_from_config_prefix() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/bin" "$tmp/gdal/lib" "$tmp/geos/lib" "$tmp/settings"
    : > "$tmp/gdal/lib/libgdal.dylib"
    : > "$tmp/geos/lib/libgeos_c.dylib"
    cat > "$tmp/bin/gdal-config" <<EOF
#!/usr/bin/env zsh
if [[ "\$1" == "--prefix" ]]; then
  echo "$tmp/gdal"
  exit 0
fi
if [[ "\$1" == "--version" ]]; then
  echo "3.9.0"
  exit 0
fi
EOF
    cat > "$tmp/bin/geos-config" <<EOF
#!/usr/bin/env zsh
if [[ "\$1" == "--prefix" ]]; then
  echo "$tmp/geos"
  exit 0
fi
if [[ "\$1" == "--version" ]]; then
  echo "3.12.0"
  exit 0
fi
EOF
    chmod +x "$tmp/bin/gdal-config" "$tmp/bin/geos-config"
    out="$(OSTYPE=darwin PATH="$tmp/bin:/usr/bin:/bin" ZSH_SETTINGS_DIR="$tmp/settings" ZSH_TEST_MODE=1 zsh -fc "unset GDAL_LIBRARY_PATH GEOS_LIBRARY_PATH; source $ROOT_DIR/modules/settings.zsh; echo \"\$GDAL_LIBRARY_PATH|\$GEOS_LIBRARY_PATH\"")"
    assert_contains "$out" "$tmp/gdal/lib/libgdal.dylib" "should auto-configure GDAL_LIBRARY_PATH from gdal-config prefix"
    assert_contains "$out" "$tmp/geos/lib/libgeos_c.dylib" "should auto-configure GEOS_LIBRARY_PATH from geos-config prefix"
    rm -rf "$tmp"
}

test_django_gis_doctor_defined() {
    source "$ROOT_DIR/modules/settings.zsh"
    assert_command_success "typeset -f django_gis_doctor >/dev/null 2>&1" "django_gis_doctor should be defined"
}

test_mac_gis_env_sync_defined() {
    source "$ROOT_DIR/modules/settings.zsh"
    assert_command_success "typeset -f mac_gis_env_sync >/dev/null 2>&1" "mac_gis_env_sync should be defined"
}

register_test "test_settings_load_order" "test_settings_load_order"
register_test "test_settings_machine_override" "test_settings_machine_override"
register_test "test_settings_os_then_machine_override_order" "test_settings_os_then_machine_override_order"
register_test "test_settings_macos_gis_autoconfig_from_config_prefix" "test_settings_macos_gis_autoconfig_from_config_prefix"
register_test "test_django_gis_doctor_defined" "test_django_gis_doctor_defined"
register_test "test_mac_gis_env_sync_defined" "test_mac_gis_env_sync_defined"
