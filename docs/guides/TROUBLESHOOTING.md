# 🚨 ZSH Configuration Troubleshooting Guide

## 🔍 **Quick Diagnostics**

Run these commands to quickly assess system health:

```bash
# Check system state
zsh-status                    # Module loading status
~/.config/zsh/zsh-system status  # Complete system status
echo "PATH length: ${#PATH}"  # Verify PATH size (should be < 800 characters)

# Test module loading
zsh-verbose                   # Detailed loading output
zsh-reload                    # Reload configuration
time zsh-reload               # Check startup performance

# Security & credential system
credential_backend_status     # Check credential system health
creds-test                    # Test credential management
./tests/hostile-comprehensive-final.zsh  # Production readiness test

# Check for common issues
ls -la ~/.config/zsh/config/  # Verify configuration files exist
which zsh                     # Verify zsh installation
```

## 🚨 **Common Problems & Solutions**

### **1. PATH Explosion (2000+ characters)**

**Symptoms:**
- Finder operations are slow or hang
- File dialogs take forever to open
- Shell startup is slow
- System feels sluggish

**Diagnosis:**
```bash
echo "PATH length: ${#PATH}"
echo "PATH entries: $(echo $PATH | tr ':' '\n' | wc -l)"
```

**Solution:**
```bash
# Comprehensive PATH cleanup
repair_path --verbose

# Quick duplicate removal
deduplicate_path

# Check results
echo "PATH length: ${#PATH}"
```

### **5. Credential Management Issues (NEW)**

**Symptoms:**
- Database connections failing
- Google Analytics authentication errors
- 1Password CLI not working
- Credential functions not available

**Diagnosis:**
```bash
# Check credential system status
credential_backend_status

# Test core functions
command -v get_credential && echo "✅ get_credential available" || echo "❌ Missing"
command -v store_credential && echo "✅ store_credential available" || echo "❌ Missing"

# Test 1Password CLI
op account list || echo "❌ 1Password CLI not authenticated"

# Test keychain access
security list-keychains || echo "❌ Keychain access issues"
```

**Solutions:**
```bash
# Load credential system
source ~/.config/zsh/config/credentials.zsh

# Authenticate with 1Password
eval $(op signin)

# Test the system
test_credential_system

# Run security validation
./tests/hostile-credential-testing.zsh
```

### **6. Security & Hostile Testing Issues (NEW)**

**Symptoms:**
- Production deployment concerns
- Security vulnerability questions
- System not passing hostile tests
- Function failures under stress

**Diagnosis:**
```bash
# Run comprehensive security testing
./tests/hostile-security-comprehensive.zsh

# Test critical functions under stress
./tests/hostile-critical-functions.zsh

# Full production readiness test
./tests/hostile-comprehensive-final.zsh
```

**Solutions:**
```bash
# If tests fail, check specific categories:
# 1. Injection resistance
get_credential "service; echo test" "user"  # Should not execute injection

# 2. Information disclosure
get_credential "nonexistent" "user" 2>&1 | grep -i password  # Should find nothing

# 3. Performance under stress
ulimit -v 524288 && source ~/.config/zsh/zshrc  # Test with memory limits

# 4. Error recovery
export LOADED_MODULES="corrupted" && source ~/.config/zsh/zshrc  # Test recovery
```

**Prevention:**
- Follow debugging directives for all changes
- Test PATH impact after modifications
- Use `repair_path --dry-run` before making changes

### **2. Module Loading Failures**

**Symptoms:**
- Functions not available after shell startup
- Error messages during module loading
- Inconsistent behavior between sessions

**Diagnosis:**
```bash
zsh-status                    # Check loaded modules
zsh-verbose                   # See detailed loading output
```

**Solution:**
```bash
# Check module dependencies
ls -la ~/.config/zsh/config/

# Test individual modules
source ~/.config/zsh/config/python.zsh
source ~/.config/zsh/config/docker.zsh

# Reload configuration
zsh-reload
```

**Prevention:**
- Test modules incrementally
- Check module dependencies before loading
- Use `zsh-verbose` to debug loading issues

### **3. Performance Issues**

**Symptoms:**
- Slow shell startup (varies by context)
- System lag during shell operations
- High CPU usage during startup

**Diagnosis:**
```bash
time zsh-reload               # Measure startup time
zsh-status                    # Check loaded modules count
echo "PATH length: ${#PATH}"  # Check PATH size
```

**Solution:**
```bash
# Use minimal mode
zsh-light

# Optimize PATH
repair_path --verbose

# Check for heavy modules
zsh-status
```

**Prevention:**
- Monitor startup performance
- Use on-demand module loading
- Keep PATH optimized

### **4. Configuration Not Loading**

**Symptoms:**
- Shell behaves like default zsh
- No custom functions available
- No custom prompt or aliases

**Diagnosis:**
```bash
echo $MODULAR_ZSHRC_LOADED    # Should be "true"
ls -la ~/.config/zsh/zshrc    # Check if file exists
```

**Solution:**
```bash
# Check configuration file
cat ~/.config/zsh/zshrc | head -20

# Reload manually
source ~/.config/zsh/zshrc

# Check for errors
zsh -n ~/.config/zsh/zshrc    # Syntax check
```

**Prevention:**
- Verify configuration file exists
- Check for syntax errors
- Test configuration loading

## 🔧 **Advanced Troubleshooting**

### **Emergency Recovery**

If the shell is completely broken:

```bash
# Reset to basic PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Test in clean shell
zsh -f

# Gradually add modules back
source ~/.config/zsh/config/core.zsh
source ~/.config/zsh/config/environment.zsh
```

### **Debugging Module Loading**

```bash
# Enable verbose mode
export MODULAR_ZSHRC_VERBOSE=true
zsh-reload

# Check specific module
source ~/.config/zsh/config/python.zsh
python_status

# Test module isolation
zsh -f -c "source ~/.config/zsh/config/python.zsh && python_status"
```

### **PATH Debugging**

```bash
# Check PATH composition
echo $PATH | tr ':' '\n' | nl

# Check for duplicates
echo $PATH | tr ':' '\n' | sort | uniq -d

# Check for non-existent directories
for dir in $(echo $PATH | tr ':' ' '); do
    if [[ ! -d "$dir" ]]; then
        echo "Missing directory: $dir"
    fi
done
```

## 📋 **Maintenance Checklist**

### **Daily Checks**
- [ ] PATH length < 800 characters, < 25 entries
- [ ] Context-appropriate startup times
- [ ] All essential functions available

### **Weekly Checks**
- [ ] Run `repair_path --verbose`
- [ ] Check module loading with `zsh-status`
- [ ] Verify system performance

### **After Configuration Changes**
- [ ] Test PATH impact
- [ ] Check module loading
- [ ] Verify system performance
- [ ] Test in clean shell

## 🚨 **Critical Rules**

### **Before Making Any Changes:**
1. **Follow debugging directives** (see `DEBUGGING_DIRECTIVES.md`)
2. **Check current system state**
3. **Test in isolated environment**
4. **Verify changes work incrementally**

### **Emergency Procedures:**
1. **STOP immediately** if system becomes unstable
2. **Reset to basic configuration**
3. **Test incrementally**
4. **Document what went wrong**

## 📞 **Getting Help**

### **Self-Service:**
1. Check this troubleshooting guide
2. Follow debugging directives
3. Use diagnostic commands
4. Test in clean environment

### **Community Support:**
- **Repository**: [dheerajchand/siege_analytics_zshrc](https://github.com/dheerajchand/siege_analytics_zshrc)
- **Issues**: [GitHub Issues](https://github.com/dheerajchand/siege_analytics_zshrc/issues)
- **Documentation**: [docs/guides/](docs/guides/)

---

**Last Updated**: $(date)
**Status**: ACTIVE - Use this guide for all troubleshooting
**Related**: [DEBUGGING_DIRECTIVES.md](DEBUGGING_DIRECTIVES.md)


