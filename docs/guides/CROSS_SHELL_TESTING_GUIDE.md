# 🔄 Cross-Shell Testing Guide

## Overview

This guide covers testing the modular ZSH configuration system across different shells (ZSH, Bash) and platforms (macOS, Linux, Docker, WSL).

## 🧪 Quick Testing

### **Test Current System**
```bash
# Test in current shell (ZSH)
modular_zsh_status
spark_test_simple

# Test core functions
environment_info
platform_open --help
```

### **Test Bash Compatibility**
```bash
# Run comprehensive bash test
./test-bash-integration.sh

# Quick bash test
bash -c "source ~/.config/zsh/zshrc && modular_zsh_status"
```

---

## 🔧 Detailed Testing Procedures

### **1. ZSH Testing (Primary)**
```bash
# Full reload test
exec zsh

# Module loading test
MODULAR_ZSHRC_VERBOSE=true source ~/.config/zsh/zshrc

# Function availability test
for func in modular_zsh_status environment_info spark_test_simple platform_open; do
    if type "$func" >/dev/null 2>&1; then
        echo "✅ $func available"
    else
        echo "❌ $func missing"
    fi
done
```

### **2. Bash Testing (Secondary)**

#### **Bash Version Requirements:**
- **Minimum**: Bash 3.2+ (basic functionality)
- **Recommended**: Bash 4.0+ (full feature parity)
- **Full Compatibility**: Bash 5.0+ (all advanced features)

#### **macOS Bash Testing:**
```bash
# System bash (3.2.57) - limited compatibility
/bin/bash -c "source ~/.config/zsh/zshrc 2>/dev/null && echo 'Loaded successfully'"

# Install modern bash for full testing
brew install bash
/opt/homebrew/bin/bash --version  # Should be 5.x+
```

#### **Linux Bash Testing:**
```bash
# Most Linux systems have Bash 4.0+
bash --version
bash -c "source ~/.config/zsh/zshrc && modular_zsh_status"
```

### **3. Cross-Platform Testing**

#### **Docker Testing:**
```bash
# Test in Ubuntu container
docker run -it -v ~/.config/zsh:/zsh ubuntu:latest bash -c "
  apt-get update && apt-get install -y git curl
  cd /zsh && source zshrc && modular_zsh_status
"

# Test in Alpine container  
docker run -it -v ~/.config/zsh:/zsh alpine:latest sh -c "
  apk add bash git curl
  cd /zsh && bash -c 'source zshrc && modular_zsh_status'
"
```

#### **WSL Testing:**
```bash
# From Windows WSL
cd /mnt/c/Users/[username]/
git clone [repository]
source zshrc
modular_zsh_status
```

---

## 🔍 Test Results Analysis

### **Expected Results by Shell:**

#### **ZSH (Primary Shell) - 100% Compatibility Expected**
```bash
✅ All 12 modules load successfully
✅ All functions available: modular_zsh_status, environment_info, spark_test_simple
✅ Platform detection works: detect_platform returns correct value
✅ Cross-platform utilities work: platform_open, platform_copy
✅ Data science stack available: Spark, Hadoop, Python/UV functions
```

#### **Bash 5.0+ - 95% Compatibility Expected**
```bash
✅ All core modules load with shell-compat layer
✅ Most functions available (associative arrays supported)
✅ Platform detection works correctly
⚠️  Some advanced ZSH-specific features may be limited
✅ Data science functions work with fallbacks
```

#### **Bash 4.0-4.4 - 80% Compatibility Expected**
```bash
✅ Core modules load with compatibility layer
✅ Basic functions work (limited associative array support)
✅ Platform detection works
⚠️  Some advanced features disabled or use fallbacks
⚠️  Module loading may be slower
```

#### **Bash 3.2 (macOS System) - 60% Compatibility Expected**
```bash
⚠️  Limited module loading (no associative arrays)
⚠️  Fallback mode for complex functions
✅ Basic shell functionality works
❌ Advanced data science features limited
💡 Recommended: Install modern bash via Homebrew
```

---

## 🛠️ Troubleshooting

### **Common Issues:**

#### **"Command not found" errors**
```bash
# Reload configuration
source ~/.config/zsh/zshrc

# Check module loading
MODULAR_ZSHRC_VERBOSE=true source ~/.config/zsh/zshrc

# Verify function exists
type spark_test_simple
```

#### **Module loading failures**
```bash
# Check directory structure
ls -la ~/.config/zsh/config/

# Test individual module
source ~/.config/zsh/config/spark.zsh
type spark_test_simple
```

#### **Bash compatibility issues**
```bash
# Check bash version
bash --version

# Test with explicit bash 4+
/usr/local/bin/bash -c "source ~/.config/zsh/zshrc"

# Use compatibility mode
SHELL_COMPAT_MODE=fallback bash -c "source ~/.config/zsh/zshrc"
```

### **Platform-Specific Issues:**

#### **macOS:**
```bash
# Install modern bash
brew install bash

# Add to /etc/shells
echo "/opt/homebrew/bin/bash" | sudo tee -a /etc/shells

# Test modern bash
/opt/homebrew/bin/bash --version
```

#### **Linux:**
```bash
# Update bash (Ubuntu/Debian)
sudo apt update && sudo apt install bash

# Update bash (RHEL/CentOS)
sudo yum update bash

# Check version
bash --version
```

#### **WSL:**
```bash
# Ensure Windows line endings don't cause issues
dos2unix ~/.config/zsh/zshrc

# Test in native WSL environment
wsl bash -c "source ~/.config/zsh/zshrc"
```

---

## 📋 Testing Checklist

### **Pre-Deployment Testing:**
- [ ] ZSH full functionality test
- [ ] Bash 4.0+ compatibility test  
- [ ] Platform detection on target system
- [ ] Core functions available
- [ ] Data science stack functional
- [ ] Credential system working
- [ ] Backup system functional

### **Cross-Platform Validation:**
- [ ] macOS (Intel + Apple Silicon)
- [ ] Linux (Ubuntu, RHEL, Alpine)
- [ ] Docker containers
- [ ] WSL (Windows Subsystem for Linux)
- [ ] Remote servers via SSH

### **Performance Testing:**
- [ ] Startup time < 2 seconds
- [ ] Module loading without errors
- [ ] Memory usage reasonable
- [ ] No hanging processes

---

## 🚀 Automated Testing

### **Run All Tests:**
```bash
# Comprehensive test suite
./test-bash-integration.sh

# Individual platform tests
./test-cross-platform.sh

# Performance tests
time (source ~/.config/zsh/zshrc)
```

### **Continuous Integration:**
```bash
# Add to CI/CD pipeline
git add tests/
git commit -m "ci: add cross-shell testing"

# Run tests automatically
.github/workflows/cross-shell-test.yml
```

---

## 💡 Best Practices

### **Development:**
1. **Test in ZSH first** - primary development environment
2. **Validate in Bash** - ensure cross-shell compatibility
3. **Check on Linux** - most deployment target
4. **Test incremental changes** - catch issues early

### **Deployment:**
1. **Verify shell version** on target system
2. **Test core functions** before full deployment
3. **Have rollback plan** if compatibility issues arise
4. **Monitor startup performance** after deployment

### **Maintenance:**
1. **Regular cross-shell testing** during development
2. **Update tests** when adding new features
3. **Document compatibility** changes in release notes
4. **Keep fallback options** for older systems

---

## 📖 Related Documentation

- [CLAUDE.md](CLAUDE.md) - Complete system documentation
- [README.md](README.md) - Quick start guide
- [IDIOT_LEVEL_GUIDE.md](IDIOT_LEVEL_GUIDE.md) - Step-by-step setup
- [Module Documentation](docs/) - Individual module guides

---

*Last Updated: September 2025 - Version 1.1.0*