# Manual Testing Plan - ZSH Configuration System

**🚨 SYSTEM UPDATE (2025-09-09)**: Auto-loading issues resolved! System is now STABLE.
**For step-by-step testing**: See `MANUAL_TESTING_CHECKLIST.md` for the latest validation checklist.

## 🎯 **TESTING OBJECTIVES**
1. Verify all enhanced functions are immediately available after shell startup
2. Test smart dependency management capabilities 
3. Validate comprehensive password sync functionality
4. Confirm status systems work across all modules
5. Test cross-platform compatibility features

---

## 1. **Function Auto-Loading Test**

### **Critical Functions to Test**:
```bash
# Enhanced Password Sync (should work without manual loading)
sync_all_passwords_to_1password --help
comprehensive_1password_to_apple_sync
comprehensive_apple_to_1password_sync --help

# Smart Dependency Management
ensure_docker_available
ensure_spark_available
start_spark_cluster

# Status Functions
master_status
spark_status
docker_status
credential_backend_status
```

### **Expected Result**: 
All functions should be available immediately in a fresh shell without requiring `source` commands.

### **Current Issue**: 
Some functions require manual loading: `source ~/.config/zsh/config/credentials.zsh`

---

## 2. **Enhanced Password Sync End-to-End Test**

### **Test 1: Comprehensive 1Password → Apple Sync**
```bash
# This should sync ALL accounts, ALL vaults to Apple Passwords
comprehensive_1password_to_apple_sync
```

**Expected Results**:
- Process all 4 1Password accounts
- Access all vaults (Private, Shared, Employee, Imported CSV, etc.)
- Successfully add login items to Apple Keychain
- Display progress with ✅ success indicators
- Final summary with counts of synced/failed items

### **Test 2: Targeted Reverse Sync**
```bash
# Test environment variables → specific 1Password account/vault
comprehensive_apple_to_1password_sync --account "dheeraj@siegeanalytics.com" --vault "Private"
```

**Expected Results**:
- Identify available environment credentials (PGPASSWORD, etc.)
- Create items in specified 1Password account and vault
- Apply appropriate tags (env-sync, auto-imported)
- Handle duplicate detection gracefully

---

## 3. **Smart Dependency Management Test**

### **Test 1: Spark Auto-Install and Start**
```bash
# Should auto-install Spark via SDKMAN if needed, then start cluster
spark_start
```

**Expected Results**:
- Check for Spark installation
- Auto-install via SDKMAN if missing
- Start both master and worker processes
- Display cluster URLs (Web UI at http://localhost:8080)
- Set environment variables (SPARK_HOME, SPARK_MASTER_URL)

### **Test 2: Docker Auto-Start**
```bash
# Should detect Docker status and start Docker Desktop if needed
ensure_docker_available
docker_status
```

**Expected Results**:
- Check Docker daemon status
- Auto-start Docker Desktop on macOS if not running
- Wait for Docker to become ready
- Display comprehensive container and system information

---

## 4. **Status Systems Validation**

### **Test All Status Functions**:
```bash
# Master aggregated status
master_status

# Individual system status
spark_status
docker_status
hadoop_status
jetbrains_status
py-info
backup_status
environment_info
credential_backend_status
```

**Expected Results**:
- Each function should display comprehensive, formatted status
- Show ✅ for working components, ⚠️ for issues, ❌ for missing
- Provide helpful setup instructions for missing components
- Display relevant metrics and configuration details

---

## 5. **Cross-Platform Compatibility Test**

### **Platform Detection**:
```bash
environment_info
echo $ZSH_PLATFORM
echo $ZSH_IS_DOCKER
```

**Expected Results**:
- Correctly identify macOS ARM64 platform
- Detect container environment if applicable
- Show comprehensive system information

### **Tool Integration**:
```bash
# JetBrains IDE integration
jetbrains_status
py ~/some/project  # Should open in PyCharm

# Python environment management  
py-info
py-switch list
```

**Expected Results**:
- Detect available JetBrains tools
- Correctly identify Python environments
- Smart project detection and IDE launching

---

## 6. **Module Loading System Test**

### **Module Status Check**:
```bash
modular_zsh_status
```

**Current Issue**: Shows modules as "Available but not loaded"
**Expected Fix**: Should show loaded modules with ✅ status

### **Function Availability Check**:
```bash
# Test that functions from each module are available
command -v spark_start          # spark.zsh
command -v docker_status        # docker.zsh  
command -v credential_backend_status  # credentials.zsh
command -v master_status        # status.zsh
command -v py-info             # python system
```

---

## 🔧 **KNOWN ISSUES TO RESOLVE**

1. **Function Loading**: Some functions not auto-loading (especially sync functions)
2. **Module Status**: `modular_zsh_status` shows incorrect loading status
3. **Startup Performance**: Ensure <2 second startup time maintained

---

## ✅ **SUCCESS CRITERIA**

- [ ] All functions available in fresh shell without manual loading
- [ ] Comprehensive password sync completes successfully  
- [ ] Smart dependency management auto-installs and starts services
- [ ] All status functions display accurate, helpful information
- [ ] Module loading system shows correct status
- [ ] Startup time remains under 2 seconds
- [ ] No syntax errors or broken function calls

---

## 🎯 **TESTING ORDER**

1. **Start with fresh shell** (`exec zsh`)
2. **Test function availability** (no manual loading)
3. **Test core status functions** (master_status, etc.)
4. **Test smart dependency management** (spark_start, docker)
5. **Test enhanced password sync** (comprehensive sync)
6. **Validate results** (check Apple Passwords app)
7. **Performance check** (startup time)

This plan ensures comprehensive validation of all enhanced features while identifying and resolving any remaining issues.