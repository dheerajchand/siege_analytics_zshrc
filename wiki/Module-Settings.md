# Module: Settings

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview
Centralized config loader for shared vars, machine overrides, aliases, and paths.

## Environment
- `ZSH_SETTINGS_DIR` (default `~/.config/zsh`)
- `ZSH_VARS_FILE`, `ZSH_ALIASES_FILE`, `ZSH_PATHS_FILE`
- `ZSH_MACHINE_PROFILE` (detected from `ZSH_ENV_PROFILE` or hostname/OS)
- `ZSH_VARS_MACHINE_FILE` (default `~/.config/zsh/vars.<profile>.env`)

## Functions

| Function | Purpose | Dependencies | Assumptions |
|---|---|---|---|
| `settings_init` | Create settings files | `cat` | Config dir writable |
| `settings_edit_vars` | Edit vars.env | `$EDITOR` | Editor installed |
| `settings_edit_vars_machine` | Edit machine vars file | `$EDITOR` | Editor installed |
| `settings_edit_aliases` | Edit aliases.zsh | `$EDITOR` | Editor installed |
| `settings_edit_paths` | Edit paths.env | `$EDITOR` | Editor installed |
| `settings_status` | Show settings file locations | None | None |

## Notes
- Load order: `vars.env` → `vars.<profile>.env` → `aliases.zsh` → `paths.env`.
- Use `vars.env` for universal defaults and `vars.<profile>.env` for machine-specific overrides (e.g. `vars.mac.env`, `vars.cyberpower.env`).

## Example
```zsh
# Shared defaults (all machines)
# ~/.config/zsh/vars.env
export ZSH_STARTUP_MODE="${ZSH_STARTUP_MODE:-auto}"
export PYENV_DEFAULT_VENV="${PYENV_DEFAULT_VENV:-default_31111}"

# mac-specific override
# ~/.config/zsh/vars.mac.env
export PYENV_DEFAULT_VENV="${PYENV_DEFAULT_VENV:-geo31111}"

# cyberpower-specific override
# ~/.config/zsh/vars.cyberpower.env
export PYENV_DEFAULT_VENV="${PYENV_DEFAULT_VENV:-default_31111}"
```
