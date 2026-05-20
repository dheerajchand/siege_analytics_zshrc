# Module: Ollama

Back: [Functions & Dependencies](Functions-Dependencies)

## Overview

Local helpers for [Ollama](https://ollama.com). Mirrors the
spark/hadoop service-helper pattern: start/stop/status/logs/health.
Server runs on demand via `ollama serve` rather than as a `brew
services` daemon.

## Environment

| Variable | Default | Purpose |
|---|---|---|
| `OLLAMA_HOST` | unset (`127.0.0.1:11434`) | Bind/target endpoint. Set per-host in `vars.<host>.env` to point at a remote box. Standard libc resolution honors `/etc/hosts` aliases. |
| `OLLAMA_FLASH_ATTENTION` | `1` | Apple Silicon perf flag, set in `vars.mac.env`. |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` | KV cache quantization, also from the brew caveat. |
| `OLLAMA_AUTO_START` | `0` | Set to `1` to make the `ollama` wrapper lazy-start the local server on first use. |
| `OLLAMA_LOG_DIR` | `$XDG_CACHE_HOME/ollama` | Where the log file lives. |
| `OLLAMA_LOG_FILE` | `$OLLAMA_LOG_DIR/serve.log` | Log file path. |

## Functions

| Function | Purpose |
|---|---|
| `ollama_start` | Idempotent background `ollama serve`. Refuses if `OLLAMA_HOST` is remote. |
| `ollama_stop` | SIGTERM (then SIGKILL after 3s) the local server. |
| `ollama_status` | Print binary path, endpoint, scope (local/remote), pid, reachability. |
| `ollama_logs [-f] [-n N]` | Tail or follow the log; default 200 lines. |
| `ollama_health` | `curl` against `/api/tags`. Used by `zsh_doctor`. |
| `ollama` | Wrapper around the binary. With `OLLAMA_AUTO_START=1`, kicks `ollama_start` first when local and not up. |

## Common patterns

### Local, on-demand

```sh
ollama_start              # one-shot warm-up
ollama run llama3.1       # hit it
```

### Local, lazy on first use

```sh
echo 'export OLLAMA_AUTO_START=1' >> ~/.config/zsh/vars.mac.env
exec zsh
ollama run llama3.1       # auto-starts, then forwards
```

### Pointing at a remote ollama

In `vars.<host>.env` for the host that should reach out:

```sh
export OLLAMA_HOST="studio.local:11434"
```

`ollama_start` will refuse with a message; `ollama_health` and the
client CLI work normally against the remote endpoint. `studio.local`
can be a real DNS name or a `/etc/hosts` alias.

## Troubleshooting

`could not connect to ollama server` from the brew install greeting
means the server isn't running. Run `ollama_start` once (or set
`OLLAMA_AUTO_START=1`).

If `ollama_start` says "server did not become ready in 5s", `ollama_logs`
shows the upstream output.
