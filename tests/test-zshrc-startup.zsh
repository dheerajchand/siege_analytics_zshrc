#!/usr/bin/env zsh
# Structural invariants of zshrc: helper presence, OMZ knobs/plugins,
# archived-module guard, and XDG-cache compinit behavior.
#
# The body runs inside a function so `set -euo pipefail` and scratch
# locals are scoped. A top-level `set -euo pipefail` would LEAK into
# the test runner's shell when this file is sourced, causing downstream
# tests that pipe to short-circuiting tools (e.g. `grep -q`) to flake
# under SIGPIPE. See #90 and the flake investigation in the commit
# that introduced this scoping.

# Capture the test file's location BEFORE entering the function —
# inside a function, $0 refers to the function name, not the file.
_ZSHRC_TEST_ROOT="${0:A:h:h}"

_test_zshrc_structure() {
    emulate -L zsh
    setopt errexit nounset pipefail

    local ROOT_DIR="$_ZSHRC_TEST_ROOT"
    local ZSHRC_FILE="$ROOT_DIR/zshrc"

    local _p _m _first_plugin _last_plugin
    local _knob_line _omz_line
    local _cache_tmp _home_tmp _block
    local -a _archived_modules _dumps _stragglers

    fail() {
        print -u2 -- "FAIL: $1"
        return 1
    }

    grep -q '_zsh_is_warp_terminal()' "$ZSHRC_FILE" || fail "missing Warp detection helper" || return 1
    grep -q '_zsh_show_full_startup_banner()' "$ZSHRC_FILE" || fail "missing startup banner mode helper" || return 1
    grep -q '_zsh_should_auto_recover_services()' "$ZSHRC_FILE" || fail "missing auto recover mode helper" || return 1
    grep -q 'ZSH_STATUS_BANNER_MODE:=auto' "$ZSHRC_FILE" || fail "missing banner mode default" || return 1
    grep -q 'ZSH_AUTO_RECOVER_MODE:=auto' "$ZSHRC_FILE" || fail "missing auto-recover mode default" || return 1
    grep -q 'if _zsh_should_auto_recover_services; then' "$ZSHRC_FILE" || fail "missing guarded auto-recover call" || return 1
    grep -q 'if _zsh_show_full_startup_banner; then' "$ZSHRC_FILE" || fail "missing guarded banner call" || return 1

    # OMZ overhead knobs — all must be set before sourcing oh-my-zsh.sh.
    grep -q "zstyle ':omz:update' mode disabled" "$ZSHRC_FILE" || fail "missing OMZ auto-update disable" || return 1
    grep -q 'ZSH_DISABLE_COMPFIX=true' "$ZSHRC_FILE" || fail "missing ZSH_DISABLE_COMPFIX=true" || return 1
    grep -q 'DISABLE_MAGIC_FUNCTIONS=true' "$ZSHRC_FILE" || fail "missing DISABLE_MAGIC_FUNCTIONS=true" || return 1
    grep -q 'DISABLE_AUTO_TITLE=true' "$ZSHRC_FILE" || fail "missing DISABLE_AUTO_TITLE=true" || return 1
    _knob_line=$(grep -n "zstyle ':omz:update' mode disabled" "$ZSHRC_FILE" | head -1 | cut -d: -f1)
    _omz_line=$(grep -n 'source "\$ZSH/oh-my-zsh.sh"' "$ZSHRC_FILE" | head -1 | cut -d: -f1)
    [[ -n "$_knob_line" && -n "$_omz_line" && "$_knob_line" -lt "$_omz_line" ]] \
        || { fail "OMZ knobs must appear before the oh-my-zsh.sh source line"; return 1; }

    for _p in git gitfast gh fzf sudo copybuffer copypath copyfile history-substring-search aliases brew; do
        grep -qE "^\s+${_p}\b" "$ZSHRC_FILE" \
            || { fail "expected OMZ plugin '${_p}' to be enabled"; return 1; }
    done
    if grep -qE "^\s+command-not-found\b" "$ZSHRC_FILE"; then
        fail "command-not-found must not be in plugins=(...) — too slow at startup"; return 1
    fi

    for _p in zsh-defer zsh-autosuggestions zsh-syntax-highlighting zsh-completions; do
        grep -qE "^\s+${_p}\b" "$ZSHRC_FILE" \
            || { fail "expected third-party plugin '${_p}' to be enabled"; return 1; }
    done
    _first_plugin=$(awk '/^plugins=\(/{flag=1; next} flag && /^[ \t]+[a-z]/{print $1; exit}' "$ZSHRC_FILE")
    [[ "$_first_plugin" == "zsh-defer" ]] \
        || { fail "zsh-defer must be the first plugin (got: '${_first_plugin}')"; return 1; }
    _last_plugin=$(awk '/^plugins=\(/{flag=1; next} /^\)/{flag=0} flag && /^[ \t]+[a-z]/{p=$1} END{print p}' "$ZSHRC_FILE")
    [[ "$_last_plugin" == "zsh-syntax-highlighting" ]] \
        || { fail "zsh-syntax-highlighting must be the last plugin (got: '${_last_plugin}')"; return 1; }

    grep -q "zsh-defer source .*command-not-found" "$ZSHRC_FILE" \
        || { fail "command-not-found should be deferred via zsh-defer"; return 1; }

    grep -qE "^\s+git-extras\b" "$ZSHRC_FILE" \
        || { fail "expected OMZ plugin 'git-extras' to be enabled"; return 1; }
    [[ -f "$ROOT_DIR/docs/git-aliases.md" ]] \
        || { fail "docs/git-aliases.md cheat sheet missing"; return 1; }

    grep -q "bindkey '\^\[\[A' history-substring-search-up" "$ZSHRC_FILE" \
        || { fail "history-substring-search up-arrow binding missing"; return 1; }
    grep -q "bindkey '\^\[\[B' history-substring-search-down" "$ZSHRC_FILE" \
        || { fail "history-substring-search down-arrow binding missing"; return 1; }

    # Archived modules must not be loaded from zshrc.
    _archived_modules=("$ROOT_DIR"/modules/archived/*.zsh(N:t:r))
    for _m in $_archived_modules; do
        [[ "$_m" == "README" ]] && continue
        if grep -qE "^\s*load_module\s+${_m}\b" "$ZSHRC_FILE"; then
            fail "archived module '${_m}' is still loaded from zshrc"; return 1
        fi
    done

    # Completion cache must live under $XDG_CACHE_HOME/zsh.
    grep -q 'XDG_CACHE_HOME:=\$HOME/.cache' "$ZSHRC_FILE" || { fail "missing XDG_CACHE_HOME default"; return 1; }
    grep -q '_zcompdump="\$XDG_CACHE_HOME/zsh/zcompdump-' "$ZSHRC_FILE" \
        || { fail "_zcompdump path should be rooted in \$XDG_CACHE_HOME/zsh/"; return 1; }
    grep -q 'compinit -d "\$_zcompdump"' "$ZSHRC_FILE" \
        || { fail "compinit must target \$_zcompdump with -d (rebuild path)"; return 1; }
    grep -q 'compinit -C -d "\$_zcompdump"' "$ZSHRC_FILE" \
        || { fail "compinit fast path must target \$_zcompdump with -C -d"; return 1; }

    # Behavioral check: execute the compinit block with scratch HOME/XDG.
    # The real invariant is that NOTHING lands in $HOME/.zcompdump* — that's
    # the whole point of the XDG move. Whether compinit itself produces a
    # dump depends on the host's zsh + completion install (on a vanilla
    # Ubuntu runner with minimal zsh, compinit may no-op), so we don't
    # require a dump to materialize — only that IF one exists, it's under
    # $XDG_CACHE_HOME/zsh/, not $HOME.
    _cache_tmp="$(mktemp -d)" || { fail "mktemp failed"; return 1; }
    _home_tmp="$(mktemp -d)" || { fail "mktemp failed"; return 1; }
    _block="$(awk '/^# Initialize completion system/,/^unset _zcompdump/' "$ZSHRC_FILE")"
    [[ -n "$_block" ]] || { fail "could not extract compinit block from zshrc"; rm -rf "$_cache_tmp" "$_home_tmp"; return 1; }
    HOME="$_home_tmp" XDG_CACHE_HOME="$_cache_tmp" \
        zsh -c "$_block" >/dev/null 2>&1 \
        || { fail "compinit block errored under scratch HOME/XDG"; rm -rf "$_cache_tmp" "$_home_tmp"; return 1; }
    _stragglers=("$_home_tmp"/.zcompdump*(N))
    rm -rf "$_cache_tmp" "$_home_tmp"
    (( ${#_stragglers} == 0 )) \
        || { fail "compinit block leaked .zcompdump* into \$HOME"; return 1; }

    print -- "test-zshrc-startup: ok"
    return 0
}

_test_zshrc_structure
_zshrc_structure_rc=$?
unfunction _test_zshrc_structure 2>/dev/null
if (( _zshrc_structure_rc != 0 )); then
    exit $_zshrc_structure_rc
fi
unset _zshrc_structure_rc _ZSHRC_TEST_ROOT
