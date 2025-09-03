# 🧪 ZSH Testing Framework

Comprehensive unit testing framework for Zsh functions, similar to pytest for Python.

## 🚀 Quick Start

### Run All Tests
```bash
# Run all tests
zsh run-tests.zsh

# Run with verbose output
zsh run-tests.zsh --verbose

# Run with coverage reporting
zsh run-tests.zsh --coverage

# Run specific test
zsh run-tests.zsh --test "test_python_status"

# Run tests in parallel
zsh run-tests.zsh --parallel 4
```

### Quick System Tests
```bash
# Run quick integration tests
test_system

# Test specific components
test_backup
test_python
test_compatibility
```

## 📁 Test Structure

```
tests/
├── README.md                    # This file
├── test-config.zsh             # Test configuration and setup
├── test-python-functions.zsh   # Python function tests
├── test-backup-functions.zsh   # Backup system tests
├── test-bash-compatibility.zsh # Bash compatibility tests
└── test-results/               # Test output directory
    ├── test-report.json        # Detailed test results
    └── coverage-report.html    # Coverage report (if enabled)
```

## 🧪 Test Framework Features

### Assertions
- `assert_true(condition, message)` - Assert condition is true
- `assert_false(condition, message)` - Assert condition is false
- `assert_equal(expected, actual, message)` - Assert values are equal
- `assert_not_equal(expected, actual, message)` - Assert values are not equal
- `assert_contains(string, substring, message)` - Assert string contains substring
- `assert_not_contains(string, substring, message)` - Assert string doesn't contain substring
- `assert_command_success(command, message)` - Assert command succeeds
- `assert_command_failure(command, message)` - Assert command fails
- `assert_file_exists(file, message)` - Assert file exists
- `assert_dir_exists(dir, message)` - Assert directory exists
- `assert_var_set(var_name, message)` - Assert variable is set
- `assert_var_unset(var_name, message)` - Assert variable is not set

### Test Registration
```zsh
# Register a test function
register_test "test_function_name" "test_function_name"
```

### Test Execution
```zsh
# Run a single test
run_test "test_name" "test_function"

# Run all tests
run_all_tests
```

## 📊 Test Coverage

The framework supports coverage reporting to identify untested code paths:

```bash
# Run tests with coverage
zsh run-tests.zsh --coverage

# View coverage report
open test-results/coverage-report.html
```

## 🔧 Writing Tests

### Basic Test Structure
```zsh
#!/usr/bin/env zsh

# Source the test framework
source "$(dirname "$0")/../test-framework.zsh"

# Source the functions to test
source "$(dirname "$0")/../path/to/functions.zsh"

# Test function
test_my_function() {
    echo "Testing my_function..."
    
    # Test assertions
    assert_equal "expected" "actual" "Values should be equal"
    assert_true "[[ condition ]]" "Condition should be true"
    
    echo "✅ my_function tests passed"
}

# Register the test
register_test "test_my_function" "test_my_function"
```

### Test Best Practices

1. **Isolation**: Each test should be independent
2. **Cleanup**: Clean up any temporary files or state
3. **Descriptive Names**: Use clear, descriptive test names
4. **Single Responsibility**: Test one thing per test function
5. **Assertions**: Use appropriate assertions for the test
6. **Error Handling**: Test both success and failure cases

### Example Test
```zsh
test_backup_function() {
    echo "Testing backup function..."
    
    # Setup
    local test_dir="/tmp/test_backup_$$"
    mkdir -p "$test_dir"
    echo "test content" > "$test_dir/test_file.txt"
    
    # Test
    local backup_path=$(backup_function "$test_dir" "test backup")
    
    # Assertions
    assert_true "[[ -n '$backup_path' ]]" "Backup path should be returned"
    assert_dir_exists "$backup_path" "Backup directory should exist"
    assert_file_exists "$backup_path/test_file.txt" "Backup file should exist"
    
    # Cleanup
    rm -rf "$test_dir"
    rm -rf "$backup_path"
    
    echo "✅ backup function tests passed"
}
```

## 🚀 Integration with CI/CD

### GitHub Actions
```yaml
name: ZSH Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run ZSH Tests
        run: zsh run-tests.zsh --coverage
      - name: Upload Test Results
        uses: actions/upload-artifact@v2
        with:
          name: test-results
          path: test-results/
```

### Local Development
```bash
# Run tests before committing
zsh run-tests.zsh --verbose

# Run specific test during development
zsh run-tests.zsh --test "test_my_function"

# Check coverage
zsh run-tests.zsh --coverage
```

## 📈 Test Reports

### JSON Report
Test results are saved in `test-results/test-report.json`:
```json
{
    "total": 25,
    "passed": 23,
    "failed": 2,
    "skipped": 0,
    "duration": 15,
    "success_rate": 92,
    "timestamp": "2025-09-03T12:00:00Z"
}
```

### Coverage Report
Coverage reports are generated in HTML format for easy viewing.

## 🐛 Debugging Tests

### Verbose Output
```bash
# Run with verbose output to see detailed test execution
zsh run-tests.zsh --verbose
```

### Test Isolation
```bash
# Run a single test for debugging
zsh run-tests.zsh --test "test_specific_function"
```

### Test Environment
```bash
# Check test environment
zsh tests/test-config.zsh
```

## 🔄 Continuous Testing

### Watch Mode
```bash
# Run tests when files change (requires fswatch)
fswatch -o . | xargs -n1 -I{} zsh run-tests.zsh
```

### Pre-commit Hook
```bash
# Add to .git/hooks/pre-commit
#!/bin/bash
zsh run-tests.zsh
if [[ $? -ne 0 ]]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi
```

## 📚 Advanced Usage

### Parallel Testing
```bash
# Run tests in parallel for faster execution
zsh run-tests.zsh --parallel 4
```

### Test Patterns
```bash
# Run tests matching a pattern
zsh run-tests.zsh --test "python"
```

### Custom Output Directory
```bash
# Specify custom output directory
zsh run-tests.zsh --output "./custom-results"
```

## 🎯 Test Categories

### Unit Tests
- Test individual functions in isolation
- Mock external dependencies
- Test edge cases and error conditions

### Integration Tests
- Test function interactions
- Test with real dependencies
- Test end-to-end workflows

### System Tests
- Test complete system functionality
- Test with real environment
- Test performance and reliability

## 🚨 Troubleshooting

### Common Issues

1. **Test Framework Not Found**
   ```bash
   # Ensure test framework is in the correct location
   ls -la test-framework.zsh
   ```

2. **Functions Not Found**
   ```bash
   # Check that source files exist
   ls -la python/core.zsh
   ls -la backup-system.zsh
   ```

3. **Permission Denied**
   ```bash
   # Make scripts executable
   chmod +x run-tests.zsh test-framework.zsh
   ```

4. **Test Environment Issues**
   ```bash
   # Check test environment
   zsh tests/test-config.zsh
   ```

### Getting Help
```bash
# Show help
zsh run-tests.zsh --help
```

---

**Happy Testing!** 🧪✨

This testing framework provides comprehensive unit testing capabilities for your Zsh configuration, helping ensure reliability and maintainability of your shell functions.
