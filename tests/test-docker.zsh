#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/docker.zsh"

_make_stub_docker() {
    local bin_dir="$1"
    cat > "$bin_dir/docker" <<'DOCKER'
#!/usr/bin/env zsh
cmd="$1"
shift
case "$cmd" in
    info)
        exit 0
        ;;
    --version)
        echo "Docker version 24.0.0, build stub"
        exit 0
        ;;
    system)
        if [[ "$1" == "df" ]]; then
            echo "TYPE TOTAL ACTIVE SIZE RECLAIMABLE"
            exit 0
        fi
        ;;
    ps)
        if [[ "$1" == "-q" ]]; then
            exit 0
        fi
        echo ""
        exit 0
        ;;
    images)
        exit 0
        ;;
    *)
        exit 0
        ;;
esac
DOCKER
    chmod +x "$bin_dir/docker"
}

test_docker_status_output() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_docker "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    out="$(docker_status 2>&1)"
    assert_contains "$out" "Docker Status" "docker_status should print header"
    assert_contains "$out" "Running containers: 0" "docker_status should show running count"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_docker_cleanup_output() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_docker "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    out="$(docker_cleanup 2>&1)"
    assert_contains "$out" "Docker Cleanup" "docker_cleanup should print header"
    PATH="$old_path"
    rm -rf "$tmp"
}

test_docker_shell_usage() {
    local out
    out="$(docker_shell 2>&1 || true)"
    assert_contains "$out" "Usage: docker_shell" "docker_shell with no args should show usage"
}

test_dstop_no_containers() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_stub_docker "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r
    out="$(dstop 2>&1)"
    assert_contains "$out" "No running containers" "dstop with no containers should report none"
    PATH="$old_path"
    rm -rf "$tmp"
}

register_test "docker_status" test_docker_status_output
register_test "docker_cleanup_output" test_docker_cleanup_output
register_test "docker_shell_usage" test_docker_shell_usage
register_test "dstop_no_containers" test_dstop_no_containers
