# DEBUGGING DIRECTIVES & INVESTIGATION PROTOCOL

## 🚨 **MANDATORY PROCESS ENFORCEMENT**

### **BEFORE ANY DEBUGGING OR TROUBLESHOOTING:**

```
1. INVESTIGATE: What's actually happening?
2. BASELINE: What's the current state?
3. TEST: What's the simplest test?
4. VERIFY: Does my assumption match reality?
5. PROCEED: Only then make changes
```

**NEVER skip steps 1-4. ALWAYS complete the investigation before making changes.**

---

## 📋 **INVESTIGATION CHECKLIST**

### **System State Verification:**
- [ ] What commands are actually available? (`which`, `command -v`)
- [ ] What's the current system state? (PATH, environment variables)
- [ ] What's the actual error vs what I assume it is?
- [ ] Have I tested the simplest possible solution first?
- [ ] Am I using the right tool for the environment? (uv run vs python3)

### **Error Analysis:**
- [ ] Read the actual error message completely
- [ ] Check if my assumption about the cause is correct
- [ ] Verify the error occurs in the environment I think it does
- [ ] Test if the "missing" component actually exists elsewhere

### **Environment-Specific Checks:**
- [ ] **siege_utilities projects**: Always use `uv run python3`, never direct `python3`
- [ ] **zsh configuration**: Always check PATH length before and after changes
- [ ] **Python debugging**: Check if packages are installed via the right package manager
- [ ] **Shell debugging**: Verify which shell and environment I'm actually in

---

## 🎯 **MEMORY DIRECTIVES**

### **Core Investigation Principles:**
1. **Always investigate system state before making changes**
2. **Test incrementally - verify each change works before proceeding**
3. **Check what's actually available before assuming what's missing**
4. **Use proper environment tools (uv run, not direct python)**
5. **Read error messages completely before jumping to solutions**

### **Environment-Specific Rules:**
- **For siege_utilities projects**: Always use `uv run python3`, never direct `python3`
- **For zsh configuration**: Always check PATH length before and after changes
- **For debugging**: Always verify the actual error message matches my assumption
- **For Python**: Check if packages are installed via the right package manager

### **Process Enforcement:**
- **Never skip investigation steps** - always complete 1-4 before proceeding
- **Always verify assumptions** - test if what I think is wrong actually is
- **Always check system state** - understand the environment before changing it
- **Always test incrementally** - make one change, test, then proceed

---

## 🔧 **DEBUGGING WORKFLOW**

### **Step 1: INVESTIGATE**
```bash
# Check what's actually available
which python python3 python3.13
command -v python3

# Check environment state
echo $PATH
echo $VIRTUAL_ENV
echo $PIPENV_ACTIVE

# Check if tools are installed
uv pip list | grep package_name
pip3 list | grep package_name
```

### **Step 2: BASELINE**
```bash
# Establish current state
echo "Current PATH length: ${#PATH}"
echo "Current working directory: $(pwd)"
echo "Current shell: $SHELL"

# Check what's actually working
python3 -c "import sys; print('Python:', sys.executable)"
```

### **Step 3: TEST**
```bash
# Test simplest possible solution first
uv run python3 -c "import package_name; print('Package available')"

# Test in different environments
python3 -c "import package_name"  # vs
uv run python3 -c "import package_name"  # vs
```

### **Step 4: VERIFY**
```bash
# Verify my assumption matches reality
echo "Assumption: Package not installed"
echo "Reality: $(uv pip list | grep package_name || echo 'Not found')"

# Test the actual error scenario
# Run the exact command that failed
```

### **Step 5: PROCEED**
```bash
# Only after steps 1-4 are complete
# Make targeted, minimal changes
# Test each change immediately
# Verify the fix actually works
```

---

## 🚨 **CRITICAL FAILURE PATTERNS TO AVOID**

### **❌ DON'T DO THIS:**
- Jump straight to installing packages without checking if they exist
- Assume PATH issues without checking actual PATH length
- Use wrong Python command (python3 vs uv run python3)
- Skip error message analysis
- Make multiple changes without testing each one

### **✅ DO THIS INSTEAD:**
- Check what's actually available first
- Verify system state before making changes
- Use the right tool for the environment
- Read error messages completely
- Test incrementally with verification

---

## 📝 **ENFORCEMENT REMINDERS**

### **Before Every Debugging Session:**
1. **Read this checklist**
2. **Follow the 5-step process**
3. **Complete the investigation checklist**
4. **Apply environment-specific rules**
5. **Test incrementally**

### **When I Catch Myself Blazing Through:**
1. **STOP immediately**
2. **Go back to Step 1: INVESTIGATE**
3. **Complete the full checklist**
4. **Only then proceed with changes**

### **Success Metrics:**
- ✅ I understand the actual problem before making changes
- ✅ I've verified my assumptions match reality
- ✅ I'm using the right tools for the environment
- ✅ I've tested each change incrementally
- ✅ The fix actually works and doesn't break other things

---

**Last Updated**: $(date)
**Status**: ACTIVE - Must be followed for all debugging and troubleshooting
**Violation**: Any debugging without following this protocol is a failure


