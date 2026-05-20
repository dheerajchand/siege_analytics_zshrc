#!/usr/bin/env zsh
# Local helpers for Ollama. Mirrors the spark/hadoop service-helper
# layout (start/stop/status/logs/health). Server runs on demand via
# `ollama serve`, not via brew services. OLLAMA_HOST overrides the
# bind/target endpoint and goes through standard libc resolution, so
# /etc/hosts aliases work without extra wiring.

: "${OLLAMA_LOG_DIR:=${XDG_CACHE_HOME:-$HOME/.cache}/ollama}"
: "${OLLAMA_LOG_FILE:=$OLLAMA_LOG_DIR/serve.log}"
: "${OLLAMA_DEFAULT_HOST:=127.0.0.1:11434}"
: "${OLLAMA_AUTO_START:=0}"

_ollama_endpoint() {
    print -- "${OLLAMA_HOST:-$OLLAMA_DEFAULT_HOST}"
}

_ollama_endpoint_is_local() {
    local ep host
    ep="$(_ollama_endpoint)"
    host="${ep%%:*}"
    case "$host" in
        ""|127.0.0.1|::1|localhost|0.0.0.0) return 0 ;;
    esac
    if (( ${+commands[hostname]} )); then
        local me
        me="$(hostname -s 2>/dev/null)"
        [[ -n "$me" && "$host" == "$me" ]] && return 0
    fi
    return 1
}

_ollama_pid() {
    pgrep -f '[o]llama serve' 2>/dev/null | head -1
}

_ollama_url() {
    local ep
    ep="$(_ollama_endpoint)"
    case "$ep" in
        http://*|https://*) print -- "$ep" ;;
        *) print -- "http://${ep}" ;;
    esac
}

# Quick reachability ping against the configured endpoint.
ollama_health() {
    emulate -L zsh
    local url
    url="$(_ollama_url)/api/tags"
    if (( ${+commands[curl]} )); then
        curl -fsS --max-time 3 "$url" >/dev/null 2>&1
    else
        print -u2 -- "ollama_health: curl not found"
        return 2
    fi
}

# Print binary path, endpoint, scope, pid, and reachability.
ollama_status() {
    emulate -L zsh
    local ep pid
    ep="$(_ollama_endpoint)"
    if (( ${+commands[ollama]} )); then
        print -- "binary:   $(command -v ollama)"
    else
        print -- "binary:   not installed (brew install ollama)"
    fi
    print -- "endpoint: ${ep}"
    if _ollama_endpoint_is_local; then
        print -- "scope:    local"
        pid="$(_ollama_pid)"
        if [[ -n "$pid" ]]; then
            print -- "pid:      ${pid}"
        else
            print -- "pid:      not running"
        fi
    else
        print -- "scope:    remote (will not start a local server)"
    fi
    if ollama_health; then
        print -- "health:   reachable"
        return 0
    else
        print -- "health:   unreachable"
        return 1
    fi
}

# Tail or follow the ollama serve log; default 200 lines.
ollama_logs() {
    emulate -L zsh
    local follow=0 lines=200
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--follow) follow=1; shift ;;
            -n|--lines)  lines="${2:-200}"; shift 2 ;;
            *) print -u2 -- "ollama_logs: unknown arg: $1"; return 1 ;;
        esac
    done
    if [[ ! -f "$OLLAMA_LOG_FILE" ]]; then
        print -u2 -- "ollama_logs: no log at $OLLAMA_LOG_FILE"
        return 1
    fi
    if (( follow )); then
        tail -n "$lines" -f "$OLLAMA_LOG_FILE"
    else
        tail -n "$lines" "$OLLAMA_LOG_FILE"
    fi
}

# Background ollama serve if local and not already up; idempotent.
ollama_start() {
    emulate -L zsh
    if ! (( ${+commands[ollama]} )); then
        print -u2 -- "ollama_start: ollama not installed. brew install ollama"
        return 1
    fi
    if ollama_health; then
        print -- "ollama_start: already up at $(_ollama_endpoint)"
        return 0
    fi
    if ! _ollama_endpoint_is_local; then
        print -u2 -- "ollama_start: OLLAMA_HOST=$(_ollama_endpoint) is remote; refusing to start a local server"
        return 1
    fi
    mkdir -p "$OLLAMA_LOG_DIR"
    print -- "ollama_start: launching ollama serve, log: $OLLAMA_LOG_FILE"
    nohup ollama serve >>"$OLLAMA_LOG_FILE" 2>&1 &!
    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        sleep 0.5
        if ollama_health; then
            print -- "ollama_start: ready at $(_ollama_endpoint)"
            return 0
        fi
    done
    print -u2 -- "ollama_start: server did not become ready in 5s; check ollama_logs"
    return 1
}

# Stop the local ollama serve process.
ollama_stop() {
    emulate -L zsh
    local pid
    pid="$(_ollama_pid)"
    if [[ -z "$pid" ]]; then
        print -- "ollama_stop: no local ollama serve running"
        return 0
    fi
    print -- "ollama_stop: kill $pid"
    kill "$pid" 2>/dev/null
    local i
    for i in 1 2 3 4 5 6; do
        sleep 0.5
        kill -0 "$pid" 2>/dev/null || { print -- "ollama_stop: stopped"; return 0; }
    done
    print -u2 -- "ollama_stop: $pid did not exit; sending SIGKILL"
    kill -9 "$pid" 2>/dev/null
}

# Wrapper around the ollama binary. With OLLAMA_AUTO_START=1, kicks
# ollama_start before forwarding when the server is local and not up.
ollama() {
    emulate -L zsh
    if [[ "${OLLAMA_AUTO_START:-0}" == "1" ]] \
            && _ollama_endpoint_is_local \
            && ! ollama_health; then
        ollama_start || return $?
    fi
    command ollama "$@"
}
