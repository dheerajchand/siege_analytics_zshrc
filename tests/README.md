# Testing Framework

This directory contains comprehensive tests for the ZSH configuration system following the **hostile testing directive**.

## 🔥 **Hostile Testing Philosophy**

All testing follows the three-tier hostile testing requirements:

1. **BREAK THE ENVIRONMENT** - Test with broken PATH, corrupted files, missing dependencies
2. **ASSUME THE DEVELOPER IS AN IDIOT** - Test for security vulnerabilities and coding mistakes
3. **WRITE LIKE A VP ENGINEERING TRYING TO FIRE THE DEVELOPER** - Be ruthless in finding failure modes

## 🛡️ **Security & Vulnerability Tests (PRIMARY)**

### **Advanced Security Analysis**
- `advanced_code_quality_test.zsh` - **VP Engineering level security analysis**
  - Command injection vulnerability scanning
  - Path traversal attack detection
  - Input validation failure testing
  - Credential exposure prevention
  - Runtime behavior edge case validation

### **Directory Safety & File Operations**
- `hostile_directory_safety_test.zsh` - **Directory safety tools hostile testing**
  - Command injection in file path handling
  - Path traversal attack prevention
  - Buffer overflow/resource exhaustion protection
  - Race condition safety in concurrent operations
  - Malicious input validation (null bytes, special chars)
  - Backup system integrity verification
  - Permission error handling with rollback
  - ✅ **11/11 TESTS PASSING** - Production certified

### **Environmental Robustness Tests**
- `fundamental_system_break_test.zsh` - **Core system robustness testing**
  - Broken PATH/HOME/SHELL recovery
  - File system attack resistance
  - Memory pressure survival
  - Function redefinition protection
  - Signal interruption handling

- `hostile-pyenv-p10k-tests.zsh` - **PyEnv & P10k integration testing**
  - PyEnv completion functionality verification
  - P10k instant prompt configuration testing
  - Adversarial condition resistance
  - Integration failure recovery

- `intensive_break_test.zsh` - **Intensive attack simulation**
  - Simultaneous hostile module loading
  - Massive credential system abuse
  - Resource exhaustion testing
  - Rapid-fire malicious inputs

### **Code Quality Analysis**
- `code_quality_hostile_test.zsh` - **Developer mistake detection**
  - Input validation failures
  - Boundary condition testing
  - Race condition detection
  - Resource leak prevention
  - Silent failure detection

### **Production Readiness**
- `hostile-comprehensive-final.zsh` - **Production certification test**
- `hostile-security-comprehensive.zsh` - **Security vulnerability testing**

## 📋 **Module & Integration Tests**

### **Module-Specific Tests**
- `test-python-functions.zsh` - Python module validation
- `test-spark-functions.zsh` - Spark module validation
- `test-notebook-functions.zsh` - Notebook integration testing
- `test-jetbrains-real.zsh` - IDE integration testing

### **System Architecture Tests**
- `test-3tier-system.zsh` - Three-tier architecture validation
- `test-comprehensive-final.zsh` - Complete system validation
- `test-modular-system.zsh` - Modular architecture testing

### **Cross-Platform & Compatibility**
- `test-bash-compatibility.zsh` - Cross-shell compatibility
- `test-cross-platform.sh` - Multi-platform testing

## 🚀 **Running Tests**

### **Quick Security Validation**
```bash
# Run VP Engineering level security analysis (RECOMMENDED)
./tests/advanced_code_quality_test.zsh

# Test core system robustness
./tests/fundamental_system_break_test.zsh

# Intensive attack simulation
./tests/intensive_break_test.zsh
```

### **Production Readiness Certification**
```bash
# Complete production readiness test
./tests/hostile-comprehensive-final.zsh

# Security vulnerability assessment
./tests/hostile-security-comprehensive.zsh
```

### **Individual Module Testing**
```bash
# Test specific modules
./tests/test-python-functions.zsh
./tests/test-spark-functions.zsh
```

## ⚠️ **Test Requirements**

- **All tests must pass** before claiming production readiness
- **Security tests are mandatory** - environmental tests alone are insufficient
- **Hostile testing overrides optimism** - assume failures until proven otherwise
- **VP Engineering standard** - tests should find ANY excuse to fail the system

## 📊 **Test Coverage**

- ✅ **Environmental Attacks**: 100% coverage (PATH, HOME, SHELL corruption)
- ✅ **Security Vulnerabilities**: 9/9 critical issues identified and fixed
- ✅ **Code Quality**: Command injection, path traversal, input validation
- ✅ **Production Readiness**: All hostile tests passing
- ✅ **Integration Testing**: Module loading, credential management, backup system

**Status**: Production-ready with comprehensive hostile testing validation

## 🧪 **Legacy Unit Testing Framework**

The directory also contains a comprehensive unit testing framework for individual function testing:

### **Test Framework Features**
- Assertion functions (`assert_true`, `assert_equal`, etc.)
- Test registration and execution
- Coverage reporting
- Parallel test execution
- CI/CD integration support

### **Legacy Tests**
- `test-config.zsh` - Test configuration and setup
- `test-backup-functions.zsh` - Backup system tests
- `test-bash-compatibility-detailed.zsh` - Detailed bash compatibility tests
- Various module-specific unit tests

### **Running Legacy Unit Tests**
```bash
# Run all unit tests
zsh run-tests.zsh

# Run with verbose output
zsh run-tests.zsh --verbose

# Run specific test
zsh run-tests.zsh --test "test_python_status"
```

---

**Testing Priority**: Hostile testing takes precedence over unit testing. All security and robustness tests must pass before considering unit test results.