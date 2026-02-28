#!/usr/bin/env bash
# Bash bridge for zsh-native functions.
# Source from ~/.bashrc:
#   source ~/.config/zsh/bash-bridge.sh

if [ -n "${ZSH_BASH_BRIDGE_LOADED:-}" ]; then
  return 0
fi
export ZSH_BASH_BRIDGE_LOADED=1

export ZSH_BRIDGE_DIR="${ZSH_BRIDGE_DIR:-$HOME/.config/zsh}"

_zbridge_quote() {
  if [ "$#" -eq 0 ]; then
    return 0
  fi
  printf '%q ' "$@"
}

zrun() {
  if [ "$#" -eq 0 ]; then
    echo "Usage: zrun <function> [args...]" >&2
    return 2
  fi
  if ! command -v zsh >/dev/null 2>&1; then
    echo "zrun: zsh not found on PATH" >&2
    return 127
  fi

  local cmd
  if [ "$#" -eq 1 ]; then
    cmd="$1"
  else
    cmd="$(_zbridge_quote "$@")"
  fi
  zsh -lc "source \"$ZSH_BRIDGE_DIR/zshrc\" >/dev/null 2>&1; ${cmd}"
}

zhelp() { zrun help; }
zmodules() { zrun modules; }
zstatus() { zrun python_status ';' spark_mode_status ';' hadoop_status ';' secrets_status; }
zspark() { zrun spark_status "$@"; }
zhadoop() { zrun hadoop_status "$@"; }
zzeppelin() { zrun zeppelin_status "$@"; }
zsecrets() { zrun secrets_status "$@"; }
zbackup() { zrun backup "$@"; }

ztest() {
  if ! command -v zsh >/dev/null 2>&1; then
    echo "ztest: zsh not found on PATH" >&2
    return 127
  fi
  (
    cd "$ZSH_BRIDGE_DIR" || exit 1
    zsh run-tests.zsh "$@"
  )
}
