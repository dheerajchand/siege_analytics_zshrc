#!/usr/bin/env zsh
# =================================================================
# UTILS - Core Utilities
# =================================================================
# Essential helper functions for daily shell work
# =================================================================

: "${JARS_DIR:=$HOME/.jars}"

# Check if internet connection is available
# Used by Spark to decide: local JARs vs Maven downloads
is_online() {
    ping -c 1 google.com &> /dev/null
}

is_online_status() {
    is_online && echo "online" || echo "offline"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Universal archive extraction
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar x "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "Unknown archive format: $1" ;;
        esac
    else
        echo "File not found: $1"
    fi
}

download_jars() {
    local dest="${JARS_DIR}"
    local -a coords=()
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dest)
                dest="$2"
                shift 2
                ;;
            --help|-h)
                echo "Usage: download_jars [--dest <dir>] <group:artifact:version> [more...]" >&2
                return 0
                ;;
            *)
                coords+=("$1")
                shift
                ;;
        esac
    done
    if [[ ${#coords[@]} -eq 0 ]]; then
        echo "Usage: download_jars [--dest <dir>] <group:artifact:version> [more...]" >&2
        return 1
    fi
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        echo "Neither curl nor wget found; cannot download jars" >&2
        return 1
    fi
    mkdir -p "$dest" || return 1
    local coord
    for coord in "${coords[@]}"; do
        for c in ${(s:,:)coord}; do
            [[ -z "$c" ]] && continue
            local group artifact version
            IFS=':' read -r group artifact version <<< "$c"
            if [[ -z "$group" || -z "$artifact" || -z "$version" ]]; then
                echo "Invalid coordinate: $c" >&2
                return 1
            fi
            local group_path="${group//./\/}"
            local jar_name="${artifact}-${version}.jar"
            local url="https://repo1.maven.org/maven2/${group_path}/${artifact}/${version}/${jar_name}"
            local out="${dest}/${jar_name}"
            if [[ -f "$out" ]]; then
                continue
            fi
            if command -v curl >/dev/null 2>&1; then
                curl -fsSL "$url" -o "$out" || return 1
            else
                wget -qO "$out" "$url" || return 1
            fi
        done
    done
}

# Recursive text search
findtext() {
    grep -r "$1" .
}

# Add directory to PATH if not already present
path_add() {
    local new_path="$1"
    local position="${2:-prepend}"
    
    if [[ -d "$new_path" && ":$PATH:" != *":$new_path:"* ]]; then
        case "$position" in
            prepend) export PATH="$new_path:$PATH" ;;
            append)  export PATH="$PATH:$new_path" ;;
        esac
    fi
}

# Simple PATH deduplication
path_clean() {
    local seen=()
    local cleaned=""
    for dir in ${(s/:/)PATH}; do
        if [[ -d "$dir" ]] && [[ ! " ${seen[@]} " =~ " $dir " ]]; then
            seen+=("$dir")
            cleaned="${cleaned:+$cleaned:}$dir"
        fi
    done
    export PATH="$cleaned"
    echo "✅ PATH cleaned: $(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ') directories"
}

# Edit zsh configuration
zshconfig() {
    local editor="${EDITOR:-vim}"
    local config_dir="${ZSHRC_CONFIG_DIR:-${ZSH_CONFIG_DIR:-$HOME/.config/zsh}}"
    
    if [[ ! -d "$config_dir" ]]; then
        echo "❌ Configuration directory not found: $config_dir"
        return 1
    fi
    
    echo "🔧 Opening configuration directory: $config_dir"
    echo "📝 Using editor: $editor"
    
    # Open the directory in the specified editor
    if command -v "$editor" >/dev/null 2>&1; then
        "$editor" "$config_dir"
    else
        echo "❌ Editor not found: $editor"
        echo "💡 Set EDITOR environment variable or install $editor"
        return 1
    fi
}

# Reload zsh configuration
zshreboot() {
    echo "🔄 Reloading zsh configuration..."
    
    # Use exec to replace current shell with fresh one (cleanest reload)
    exec zsh
}

setup_pyenv() {
    if ! command -v pyenv >/dev/null 2>&1; then
        echo "❌ pyenv not found on PATH" >&2
        echo "💡 Install pyenv first, then run setup_pyenv again" >&2
        return 1
    fi
    export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
    [[ ":$PATH:" == *":$PYENV_ROOT/bin:"* ]] || export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path 2>/dev/null)"
    eval "$(pyenv init - 2>/dev/null)"
    echo "✅ pyenv initialized"
    pyenv --version 2>/dev/null | head -n 1 || true
}

setup_uv() {
    if ! command -v uv >/dev/null 2>&1; then
        echo "❌ uv not found on PATH" >&2
        echo "Install: curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
        return 1
    fi
    echo "✅ uv available"
    uv --version 2>/dev/null | head -n 1 || true
}

toggle_hidden_files() {
    if [[ "$OSTYPE" != darwin* ]]; then
        echo "toggle_hidden_files is macOS-only" >&2
        return 1
    fi
    local current
    current="$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo 0)"
    if [[ "$current" == "1" || "$current" == "true" ]]; then
        defaults write com.apple.finder AppleShowAllFiles -bool false
        echo "✅ Hidden files disabled"
    else
        defaults write com.apple.finder AppleShowAllFiles -bool true
        echo "✅ Hidden files enabled"
    fi
    killall Finder >/dev/null 2>&1 || true
}

toggle_key_repeat() {
    if [[ "$OSTYPE" != darwin* ]]; then
        echo "toggle_key_repeat is macOS-only" >&2
        return 1
    fi
    local current
    current="$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null || echo 1)"
    if [[ "$current" == "1" || "$current" == "true" ]]; then
        defaults write -g ApplePressAndHoldEnabled -bool false
        echo "✅ Key repeat enabled (press-and-hold disabled)"
    else
        defaults write -g ApplePressAndHoldEnabled -bool true
        echo "✅ Press-and-hold enabled (key repeat disabled)"
    fi
}

_utils_run_named_tests() {
    local root="${ZSHRC_CONFIG_DIR:-${ZSH_CONFIG_DIR:-$HOME/.config/zsh}}"
    local runner="$root/run-tests.zsh"
    [[ -f "$runner" ]] || { echo "❌ Test runner not found: $runner" >&2; return 1; }
    local t
    for t in "$@"; do
        zsh "$runner" --test "$t" || return 1
    done
}

test_system() {
    local root="${ZSHRC_CONFIG_DIR:-${ZSH_CONFIG_DIR:-$HOME/.config/zsh}}"
    local runner="$root/run-tests.zsh"
    [[ -f "$runner" ]] || { echo "❌ Test runner not found: $runner" >&2; return 1; }
    zsh "$runner"
}

test_backup() { _utils_run_named_tests backup_requires_git backup_pushes_current_branch; }
test_python() { _utils_run_named_tests test_python_status_defined test_python_config_status_defined; }
test_spark() { _utils_run_named_tests test_spark_mode_functions_defined test_spark_workers_health_defined; }
test_jvm() { _utils_run_named_tests test_hadoop_health_defined test_spark_health_defined; }
test_jupyter() { _utils_run_named_tests test_spark41_route_health_defined; }
test_compatibility() { _utils_run_named_tests test_bash_bridge_defines_functions test_wiki_internal_links_resolve; }
test_bash_install() { _utils_run_named_tests test_bash_bridge_defines_functions test_bash_docs_no_stale_commands; }

# Aliases for common variations
alias reload='zshreboot'
alias zshreload='zshreboot'
alias editconfig='zshconfig'

echo "✅ utils loaded"

