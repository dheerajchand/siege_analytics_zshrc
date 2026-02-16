#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

test_status_banner_includes_secrets_and_spark_version() {
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    cat > "$bin/spark-submit" <<'SPARK'
#!/usr/bin/env zsh
echo "version 4.1.1"
SPARK
    chmod +x "$bin/spark-submit"
    cat > "$tmp/secrets.env" <<'EOF'
FOO=bar
EOF
    out="$(PATH="$bin:/usr/bin:/bin" ZSH_SECRETS_MODE=file ZSH_SECRETS_FILE="$tmp/secrets.env" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/zshrc; zsh_status_banner")"
    assert_contains "$out" "🔐 Secrets:" "banner should show secrets status"
    assert_contains "$out" "Spark version:" "banner should show spark version"
    assert_contains "$out" "Spark workers:" "banner should show spark worker status"
    assert_contains "$out" "Auto-recovery:" "banner should show auto-recovery summary"
    rm -rf "$tmp"
}

register_test "test_status_banner_includes_secrets_and_spark_version" "test_status_banner_includes_secrets_and_spark_version"
