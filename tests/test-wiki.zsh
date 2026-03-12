#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

test_wiki_internal_links_resolve() {
    local out
    out="$(ROOT_DIR="$ROOT_DIR" python3 - <<'PY'
import os
from pathlib import Path
import re

wiki = Path(os.environ["ROOT_DIR"]) / "wiki"
files = {p.stem for p in wiki.glob("*.md")}
errors = []
for p in wiki.glob("*.md"):
    txt = p.read_text(encoding="utf-8")
    for m in re.finditer(r"\[[^\]]+\]\(([^)]+)\)", txt):
        t = m.group(1)
        if t.startswith("http") or t.startswith("../") or t.startswith("#"):
            continue
        target = t.split("#", 1)[0]
        stem = Path(target).stem if target.endswith(".md") else target
        if stem and stem not in files:
            errors.append(f"{p.name} -> {t}")

if errors:
    print("BROKEN")
    for e in errors:
        print(e)
else:
    print("OK")
PY
)"
    assert_equal "OK" "$out" "all internal wiki links should resolve"
}

test_bash_docs_no_stale_commands() {
    local user_guide compat_guide text
    user_guide="$ROOT_DIR/wiki/Bash-User-Guide.md"
    compat_guide="$ROOT_DIR/wiki/Bash-Compatibility.md"
    text="$(cat "$user_guide" "$compat_guide")"

    local -a stale=(
        "bash-compatibility.zsh"
        "install-for-bash.sh"
        "quick-install-bash.sh"
        "install-bash-compatibility.sh"
        "setup_python_manager"
        "setup_pyenv"
        "setup_uv"
        "setup_spark"
        "show_spark_config"
        "spark_shell_scala"
        "smart_spark_shell"
        "setup_hadoop"
        "setup_yarn"
        "show_hadoop_config"
        "show_yarn_config"
        "start_hadoop_services"
        "stop_hadoop_services"
        "setup_jupyter"
        "start_jupyter"
        "stop_jupyter"
        "jupyter_status"
        "setup_jupyter_lab"
        "start_jupyter_lab"
        "stop_jupyter_lab"
        "setup_jupyter_hub"
        "start_jupyter_hub"
        "stop_jupyter_hub"
        "enhanced_backup"
        "list_zsh_backups"
        "zsh_repo_status"
        "sync_and_backup"
        "sync_zsh_repositories"
        "test_system"
        "test_backup"
        "test_python"
        "test_spark"
        "test_jvm"
        "test_jupyter"
        "zsh_help"
        "pyhelp"
        "deduplicate_path"
        "optimize_shell"
        "validate_environment"
    )

    local token
    for token in "${stale[@]}"; do
        assert_not_contains "$text" "$token" "bash docs should not mention stale command: $token"
    done
}

test_home_quick_commands_are_defined() {
    skip_in_ci
    local out
    out="$(ROOT_DIR="$ROOT_DIR" ZSH_TEST_MODE=1 zsh -fc '
        source "$ROOT_DIR/zshrc" >/dev/null 2>&1
        missing=0
        for fn in \
            help zshconfig zshreboot backup secrets_profiles secrets_bootstrap_from_1p screen_ensure_pyenv \
            toggle_hidden_files toggle_key_repeat \
            pyspark_shell spark_shell smart_spark_submit \
            setup_pyenv setup_uv python_status \
            test_system test_backup test_python test_spark test_jvm test_jupyter test_compatibility test_bash_install
        do
            typeset -f "$fn" >/dev/null 2>&1 || { echo "MISSING:$fn"; missing=1; }
        done
        [[ "$missing" -eq 0 ]] || exit 1
    ' 2>&1 || true)"
    assert_not_contains "$out" "MISSING:" "Home quick commands should map to defined functions"
}

register_test "test_wiki_internal_links_resolve" "test_wiki_internal_links_resolve"
register_test "test_bash_docs_no_stale_commands" "test_bash_docs_no_stale_commands"
register_test "test_home_quick_commands_are_defined" "test_home_quick_commands_are_defined"
