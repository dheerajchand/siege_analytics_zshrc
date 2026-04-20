#!/usr/bin/env zsh
# Conventions linter — enforces a subset of STYLE.md mechanically.
#
# Rules checked:
#   1. Every user-facing function (no leading underscore) in modules/*.zsh
#      has a comment line immediately above its definition.
#   2. No bare `exit` at indent level 0 in modules/*.zsh (exit inside a
#      subshell `( ... )` is permitted and ignored).
#
# Rules intentionally out of scope for now (see STYLE.md §grandfathering):
#   - Named-arg preference (too many grandfathered positional args).
#   - typeset -g for module globals (hard to check statically).
#   - Docstrings on user-facing functions in zshrc itself (a module-sized
#     file with its own structure).

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

# Allowlist format: one entry per line as "basename.zsh:func_name()".
# Grandfathered violations from before this linter existed. Shrink this
# file over time as functions get docstrings.
ALLOWLIST_FILE="$ROOT_DIR/tests/conventions.allowlist.txt"

_conv_lint_missing_docstrings() {
    typeset -A allowed
    local key
    if [[ -f "$ALLOWLIST_FILE" ]]; then
        while IFS= read -r key; do
            [[ -z "$key" || "$key" == \#* ]] && continue
            allowed[$key]=1
        done < "$ALLOWLIST_FILE"
    fi

    local -a violations
    # key is already declared above; don't redeclare or zsh echoes its value.
    local file line func prev
    local -a module_files
    module_files=("$ROOT_DIR"/modules/*.zsh(N))
    for file in "${module_files[@]}"; do
        [[ "${file:t:r}" == "archived"* ]] && continue
        prev=""
        line=0
        while IFS= read -r l; do
            line=$(( line + 1 ))
            if [[ "$l" =~ '^[a-z][a-zA-Z0-9_]*\(\)[[:space:]]*\{?' ]]; then
                func="${l%%\(*}"
                if [[ ! "$prev" =~ '^[[:space:]]*#' ]]; then
                    key="${file:t}:${func}()"
                    if (( ! ${+allowed[$key]} )); then
                        violations+=("${file:t}:${line}: ${func}() — missing docstring comment on preceding line")
                    fi
                fi
            fi
            [[ -n "$l" ]] && prev="$l"
        done < "$file"
    done
    print -l -- "${violations[@]}"
}

_conv_lint_bare_exit_in_modules() {
    local -a violations
    local file line_no in_subshell depth
    local -a module_files
    module_files=("$ROOT_DIR"/modules/*.zsh(N))
    for file in "${module_files[@]}"; do
        [[ "${file:t:r}" == "archived"* ]] && continue
        depth=0
        line_no=0
        while IFS= read -r l; do
            line_no=$(( line_no + 1 ))
            # Crude subshell tracking: count '(' and ')' that start a line
            # (not inside strings). Not perfect but adequate for this codebase.
            if [[ "$l" =~ '^[[:space:]]*\(([[:space:]]|$)' ]]; then
                depth=$(( depth + 1 ))
                continue
            fi
            if [[ "$l" =~ '^[[:space:]]*\)[[:space:]]*$' ]]; then
                (( depth > 0 )) && depth=$(( depth - 1 ))
                continue
            fi
            # Flag a bare `exit` at indent level 0 outside any tracked subshell.
            if (( depth == 0 )) && [[ "$l" =~ '^exit([[:space:]]|$)' ]]; then
                violations+=("${file:t}:${line_no}: bare \`exit\` in sourced module (use \`return\`)")
            fi
        done < "$file"
    done
    print -l -- "${violations[@]}"
}

test_conventions_docstrings() {
    local violations
    violations="$(_conv_lint_missing_docstrings)"
    if [[ -n "$violations" ]]; then
        _print_fail $'user-facing functions missing docstring:\n'"$violations"
        return 1
    fi
    return 0
}

test_conventions_no_bare_exit() {
    local violations
    violations="$(_conv_lint_bare_exit_in_modules)"
    if [[ -n "$violations" ]]; then
        _print_fail $'bare exit in sourced module:\n'"$violations"
        return 1
    fi
    return 0
}

test_conventions_runner_no_global_pipefail() {
    # `set -o pipefail` at global scope in run-tests.zsh silently broke
    # assertions of the form `cmd | grep -q "..."`: grep -q exits on match,
    # upstream producer gets SIGPIPE, and pipefail surfaces the 141 as the
    # pipeline's status, failing flakily. Scoped inside `emulate -L` is fine;
    # unscoped at run-tests.zsh top level is not. See #90 for the history.
    # Match only statement lines, not comment lines, that enable pipefail.
    if grep -qE '^[[:space:]]*(set[[:space:]]+[^#]*pipefail|setopt[[:space:]]+[^#]*pipefail)' "$ROOT_DIR/run-tests.zsh"; then
        _print_fail "run-tests.zsh must not enable pipefail globally (#90)"
        return 1
    fi
    return 0
}

register_test "conventions_docstrings" test_conventions_docstrings
register_test "conventions_no_bare_exit" test_conventions_no_bare_exit
register_test "conventions_runner_no_global_pipefail" test_conventions_runner_no_global_pipefail
