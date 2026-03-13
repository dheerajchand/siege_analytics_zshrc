# Testing Guide

Back: [Home](Home) | See also: [Testing Framework](Testing-Framework)

## Running Tests

```bash
# Run all tests
zsh run-tests.zsh

# Verbose output (shows RUN/PASS/SKIP for each test)
zsh run-tests.zsh --verbose

# Run a single test by name
zsh run-tests.zsh --test test_docker_status_output

# List all registered tests
zsh run-tests.zsh --list
```

## Writing a Test

### 1. Create or edit the test file

Test files live at `tests/test-<module>.zsh`. Each file sources the framework and the module under test:

```zsh
#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/<module>.zsh"
```

### 2. Write test functions

Each test is a plain zsh function. Use the assertion helpers to check results:

```zsh
test_my_function_returns_expected_value() {
    local out
    out="$(my_function "input" 2>&1)"
    assert_equal "expected" "$out" "my_function should return expected"
}
```

### 3. Register tests

Every test function must be registered at the bottom of the file:

```zsh
register_test "test_my_function_returns_expected_value" "test_my_function_returns_expected_value"
```

The first argument is the display name, the second is the function name.

### 4. Update tests/README.md

Add your new test file to the list in `tests/README.md`.

## Assertion Reference

| Function | Purpose |
|----------|---------|
| `assert_true "condition" "msg"` | Eval condition, fail if false |
| `assert_false "condition" "msg"` | Eval condition, fail if true |
| `assert_equal "expected" "actual" "msg"` | Fail if values differ |
| `assert_not_equal "a" "b" "msg"` | Fail if values match |
| `assert_contains "haystack" "needle" "msg"` | Fail if needle not in haystack |
| `assert_not_contains "haystack" "needle" "msg"` | Fail if needle found |
| `assert_command_success "cmd" "msg"` | Eval cmd, fail if non-zero exit |
| `assert_command_failure "cmd" "msg"` | Eval cmd, fail if zero exit |

## Stub Pattern

For tests that depend on external tools (docker, databricks, op, etc.), create a stub executable in a temp directory and override `PATH`:

```zsh
test_example_with_stub() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"

    # Create stub
    cat > "$bin/mytool" <<'STUB'
#!/usr/bin/env zsh
echo "stub output"
exit 0
STUB
    chmod +x "$bin/mytool"

    # Override PATH
    PATH="$bin:/usr/bin:/bin"
    hash -r

    # Run the function under test
    out="$(my_function 2>&1)"
    assert_contains "$out" "stub output" "should use stub"

    # Cleanup
    PATH="$old_path"
    rm -rf "$tmp"
}
```

See `tests/test-databricks.zsh` for a comprehensive real-world example of this pattern.

## Skip Guards

Use these to skip tests that cannot run in certain environments:

```zsh
test_needs_op() {
    skip_if_missing "op"      # Skip if 'op' CLI not installed
    # ... test body ...
}

test_needs_local_env() {
    skip_in_ci                 # Skip when running in GitHub Actions
    # ... test body ...
}
```

Skipped tests are reported in the summary but do not count as failures.

## CI Behavior

The GitHub Actions workflow (`test.yml`) runs on `macos-latest` with:
- `ZSH_TEST_MODE=1` (suppresses module load side effects)
- Stub directories for `SPARK_HOME`, `HADOOP_HOME`, `ZEPPELIN_HOME`

Tests that require tools not available in CI (1Password CLI, ripgrep, specific Python versions) should use `skip_if_missing`. Tests that depend on local machine state should use `skip_in_ci`.

## Canonical Example

The best reference for writing new tests is `tests/test-databricks.zsh`:
- Creates stub executables for `databricks` CLI
- Overrides `PATH` to isolate from real installation
- Captures output and asserts on content
- Cleans up temp directories
