# 🚨 ZSH Configuration Troubleshooting Guide

## 🔍 **Quick Diagnostics**

Run these commands to quickly assess system health:

```bash
# Check system state
zsh-status                    # Module loading status
repair_path --dry-run         # Check for PATH issues without making changes
echo "PATH length: ${#PATH}"  # Verify PATH size (should be < 500 characters)

# Test module loading
zsh-verbose                   # Detailed loading output
zsh-reload                    # Reload configuration
time zsh-reload               # Check startup performance

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
- Slow shell startup (>2 seconds)
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
- [ ] PATH length < 500 characters
- [ ] Shell startup time < 2 seconds
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
