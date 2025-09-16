# 🔧 ZSH Configuration Maintenance Guide

## 📅 **Maintenance Schedule**

### **Daily Maintenance** (30 seconds)
```bash
# Quick health check
zsh-status
echo "PATH length: ${#PATH}"

# Quick cleanup if needed
if [[ ${#PATH} -gt 500 ]]; then
    echo "⚠️  PATH too long, running cleanup..."
    deduplicate_path
fi
```

### **Weekly Maintenance** (2 minutes)
```bash
# Comprehensive system check
zsh-status
repair_path --verbose
echo "PATH length: ${#PATH}"

# Performance check
time zsh-reload

# Module health check
zsh-verbose | grep -i error || echo "✅ No module errors"
```

### **Monthly Maintenance** (5 minutes)
```bash
# Full system audit
zsh-status
repair_path --verbose
echo "PATH length: ${#PATH}"

# Check for updates
git -C ~/.config/zsh status

# Performance benchmark
time zsh-reload

# Check system impact
echo "Finder performance check:"
echo "Open a file dialog and check if it's responsive"
```

## 🔍 **Health Monitoring**

### **PATH Health**
```bash
# Check PATH size
echo "PATH length: ${#PATH} characters"

# Check PATH entries
echo "PATH entries: $(echo $PATH | tr ':' '\n' | wc -l)"

# Check for duplicates
echo "Duplicate entries: $(echo $PATH | tr ':' '\n' | sort | uniq -d | wc -l)"

# Check for non-existent directories
for dir in $(echo $PATH | tr ':' ' '); do
    if [[ ! -d "$dir" ]]; then
        echo "❌ Missing directory: $dir"
    fi
done
```

### **Module Health**
```bash
# Check loaded modules
zsh-status

# Check for errors
zsh-verbose | grep -i error

# Test critical functions
python_status
docker_status
```

### **Performance Health**
```bash
# Startup time
time zsh-reload

# Memory usage
ps aux | grep zsh

# System responsiveness
echo "Testing Finder responsiveness..."
echo "Open a file dialog and check if it opens quickly"
```

## 🛠️ **Maintenance Procedures**

### **After Configuration Changes**
```bash
# 1. Check current state
echo "PATH length: ${#PATH}"
zsh-status

# 2. Make minimal changes
# (Your configuration changes here)

# 3. Test incrementally
zsh-reload
echo "PATH length: ${#PATH}"

# 4. Verify system impact
time zsh-reload
echo "Testing Finder responsiveness..."

# 5. Monitor performance
zsh-status
```

### **PATH Optimization**
```bash
# Quick cleanup
deduplicate_path

# Comprehensive repair
repair_path --verbose

# Verify results
echo "PATH length: ${#PATH}"
echo "PATH entries: $(echo $PATH | tr ':' '\n' | wc -l)"
```

### **Module Management**
```bash
# Check module status
zsh-status

# Reload specific modules
source ~/.config/zsh/config/python.zsh
source ~/.config/zsh/config/docker.zsh

# Test module functions
python_status
docker_status
```

## 🚨 **Emergency Recovery**

### **If PATH is Completely Broken**
```bash
# Reset to basic PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Reload configuration
zsh-reload

# Restore PATH
repair_path --verbose
```

### **If Modules Won't Load**
```bash
# Test in clean shell
zsh -f

# Load modules incrementally
source ~/.config/zsh/config/core.zsh
source ~/.config/zsh/config/environment.zsh
source ~/.config/zsh/config/python.zsh

# Test each module
python_status
```

### **If System is Unresponsive**
```bash
# Kill all zsh processes
pkill -f zsh

# Start fresh
exec zsh

# Check system state
zsh-status
```

## 📊 **Performance Monitoring**

### **Startup Performance**
```bash
# Measure startup time
time zsh-reload

# Target: < 2 seconds
# Warning: > 3 seconds
# Critical: > 5 seconds
```

### **PATH Performance**
```bash
# Check PATH size
echo "PATH length: ${#PATH}"

# Target: < 500 characters
# Warning: > 1000 characters
# Critical: > 2000 characters
```

### **System Impact**
```bash
# Check Finder performance
echo "Open a file dialog and check responsiveness"

# Check system resources
ps aux | grep zsh
top -l 1 | grep zsh
```

## 🔄 **Automated Maintenance**

### **Daily Health Check Script**
```bash
#!/bin/zsh
# ~/.config/zsh/scripts/daily-health-check.zsh

echo "🔍 Daily ZSH Health Check"
echo "========================="

# PATH check
path_length=${#PATH}
echo "PATH length: $path_length characters"

if [[ $path_length -gt 500 ]]; then
    echo "⚠️  PATH too long, running cleanup..."
    deduplicate_path
    echo "PATH length after cleanup: ${#PATH}"
fi

# Module check
echo "Loaded modules: $(zsh-status | wc -l)"

# Performance check
echo "Startup time: $(time zsh-reload 2>&1 | grep real)"

echo "✅ Daily health check complete"
```

### **Weekly Maintenance Script**
```bash
#!/bin/zsh
# ~/.config/zsh/scripts/weekly-maintenance.zsh

echo "🔧 Weekly ZSH Maintenance"
echo "========================="

# Comprehensive PATH cleanup
repair_path --verbose

# Module health check
zsh-verbose | grep -i error || echo "✅ No module errors"

# Performance benchmark
echo "Startup time: $(time zsh-reload 2>&1 | grep real)"

# System health
echo "PATH length: ${#PATH}"
echo "Loaded modules: $(zsh-status | wc -l)"

echo "✅ Weekly maintenance complete"
```

## 📋 **Maintenance Checklist**

### **Daily (30 seconds)**
- [ ] Check PATH length
- [ ] Quick cleanup if needed
- [ ] Verify essential functions work

### **Weekly (2 minutes)**
- [ ] Run comprehensive PATH cleanup
- [ ] Check module loading
- [ ] Performance check
- [ ] System responsiveness test

### **Monthly (5 minutes)**
- [ ] Full system audit
- [ ] Check for configuration updates
- [ ] Performance benchmark
- [ ] System impact assessment

### **After Any Changes**
- [ ] Follow debugging directives
- [ ] Test incrementally
- [ ] Verify system impact
- [ ] Monitor performance
- [ ] Document changes

## 🎯 **Success Metrics**

### **Performance Targets**
- **Startup time**: < 2 seconds
- **PATH length**: < 500 characters
- **Module loading**: All modules load without errors
- **System responsiveness**: Finder operations < 1 second

### **Health Indicators**
- ✅ All essential functions available
- ✅ No module loading errors
- ✅ PATH optimized and clean
- ✅ System performance acceptable
- ✅ No duplicate functions

---

**Last Updated**: $(date)
**Status**: ACTIVE - Use this guide for all maintenance
**Related**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md), [DEBUGGING_DIRECTIVES.md](DEBUGGING_DIRECTIVES.md)


