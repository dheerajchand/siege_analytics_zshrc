#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/ollama.zsh"

test_ollama_helpers_defined() {
    for fn in ollama_start ollama_stop ollama_status ollama_logs ollama_health ollama; do
        assert_command_success "typeset -f $fn >/dev/null" "$fn should be defined"
    done
}

test_ollama_endpoint_default_is_loopback() {
    local saved="${OLLAMA_HOST-}"
    unset OLLAMA_HOST
    local out
    out="$(_ollama_endpoint)"
    [[ -n "$saved" ]] && export OLLAMA_HOST="$saved"
    assert_equal "127.0.0.1:11434" "$out" "default endpoint matches ollama upstream"
}

test_ollama_endpoint_honors_OLLAMA_HOST() {
    local saved="${OLLAMA_HOST-}"
    OLLAMA_HOST="studio.local:11434" out="$(_ollama_endpoint)"
    [[ -n "$saved" ]] && export OLLAMA_HOST="$saved" || unset OLLAMA_HOST
    assert_equal "studio.local:11434" "$out" "override is read"
}

test_ollama_endpoint_local_classification() {
    local saved="${OLLAMA_HOST-}"
    OLLAMA_HOST="127.0.0.1:11434" assert_command_success \
        "_ollama_endpoint_is_local" "127.0.0.1 is local"
    OLLAMA_HOST="localhost:11434" assert_command_success \
        "_ollama_endpoint_is_local" "localhost is local"
    OLLAMA_HOST="studio.local:11434" assert_command_failure \
        "_ollama_endpoint_is_local" "studio.local is remote"
    [[ -n "$saved" ]] && export OLLAMA_HOST="$saved" || unset OLLAMA_HOST
}

test_ollama_start_refuses_remote_host() {
    # Stub `ollama` so the not-installed branch doesn't short-circuit.
    local tmp_bin saved_path saved_host
    tmp_bin="$(mktemp -d)"
    cat > "$tmp_bin/ollama" <<'STUB'
#!/usr/bin/env zsh
exit 0
STUB
    chmod +x "$tmp_bin/ollama"
    saved_path="$PATH"
    saved_host="${OLLAMA_HOST-}"
    PATH="$tmp_bin:$PATH"
    local out rc
    out="$(OLLAMA_HOST=studio.local:11434 ollama_start 2>&1)"
    rc=$?
    PATH="$saved_path"
    [[ -n "$saved_host" ]] && export OLLAMA_HOST="$saved_host" || unset OLLAMA_HOST
    rm -rf "$tmp_bin"
    assert_not_equal "0" "$rc" "ollama_start should refuse for remote host"
    assert_contains "$out" "remote" "message should mention remote"
}

test_ollama_logs_warns_when_no_log() {
    local saved="$OLLAMA_LOG_FILE"
    OLLAMA_LOG_FILE="/no/such/path/serve.log"
    local out rc
    out="$(ollama_logs 2>&1)"
    rc=$?
    OLLAMA_LOG_FILE="$saved"
    assert_not_equal "0" "$rc" "ollama_logs should fail when log missing"
    assert_contains "$out" "no log at" "should name the missing path"
}

test_ollama_wrapper_passes_through() {
    # With AUTO_START off the wrapper just forwards to `command ollama`.
    # If ollama binary is absent we get a "command not found"; if present
    # we get its real exit code. Either is fine, we're checking the
    # wrapper doesn't reject the call before reaching the binary.
    local saved_auto="${OLLAMA_AUTO_START-}"
    OLLAMA_AUTO_START=0
    ollama --version >/dev/null 2>&1
    [[ -n "$saved_auto" ]] && export OLLAMA_AUTO_START="$saved_auto" || unset OLLAMA_AUTO_START
    return 0
}

register_test "ollama_helpers_defined" test_ollama_helpers_defined
register_test "ollama_endpoint_default_is_loopback" test_ollama_endpoint_default_is_loopback
register_test "ollama_endpoint_honors_OLLAMA_HOST" test_ollama_endpoint_honors_OLLAMA_HOST
register_test "ollama_endpoint_local_classification" test_ollama_endpoint_local_classification
register_test "ollama_start_refuses_remote_host" test_ollama_start_refuses_remote_host
register_test "ollama_logs_warns_when_no_log" test_ollama_logs_warns_when_no_log
register_test "ollama_wrapper_passes_through" test_ollama_wrapper_passes_through
