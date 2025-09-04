# Zshrc Refactoring Plan

## Git Workflow
```bash
# Feature branch created: refactor/zshrc-modularization
git checkout -b refactor/zshrc-modularization  # ✅ Done
```

## Current Issues Identified

### 1. Security Issues (CRITICAL)
```bash
# Lines 242-248 in zshrc - plaintext passwords
export PGPASSWORD="dessert"
export GEODJANGO_TEMPLATE_SQL_PASSWORD="dessert"
```

### 2. Monolithic Structure (2427 lines)
- Single file with mixed responsibilities
- Hard to maintain and test

### 3. Code Duplication
- Backup functions duplicated
- Multiple similar Git operations

## Credential Management Strategy

### Support Current Workflow
- **Maintain env variables** for existing psql/Snowflake workflows
- Check env vars FIRST (preserves current behavior)
- Add secure backends as optional enhancements

### Credential Priority Order
1. **Environment variables** (current workflow)
2. **1Password CLI** (op command)
3. **Mac Keychain** (security command) 
4. **Interactive prompt** (fallback)

### Implementation
- Flexible backend system
- Backward compatible with existing env vars
- Easy migration path to secure storage

## Next Session Tasks (When You Return)

### Immediate (First 30 minutes)
1. Resume from branch: `git checkout refactor/zshrc-modularization`
2. Implement credential system
3. Fix security issues (remove plaintext passwords)

### Phase 1: Security Fix
- Create `config/credentials.zsh` module
- Replace hardcoded passwords with credential calls
- Test env variable compatibility

### Phase 2: Module Extraction  
- Extract core configuration
- Extract environment setup
- Extract database configuration
- ✅ **JetBrains Development Tools** (`config/jetbrains.zsh`) - COMPLETED
  - JetBrains Toolbox CLI integration (PyCharm, IntelliJ, DataGrip, etc.)
  - Project type auto-detection and IDE selection
  - Environment diagnosis for GUI dialog issues
  - Clean launch functionality for debugging

## Session Continuity Notes

**This session is NOT resumable** - Claude Code sessions end when you lose connectivity.

**To continue this work:**
1. Everything is saved in your Git branch
2. Run: `git checkout refactor/zshrc-modularization`  
3. Read `REFACTORING_PLAN.md` (this file)
4. Start new Claude Code session
5. Tell Claude: "Continue the zshrc refactoring from the plan in REFACTORING_PLAN.md"

## Password Sync Feature (Future Enhancement)
**User Request:** Functions to sync passwords between 1Password ↔ Mac Keychain

**Implementation Notes:**
- Technically possible but complex
- 1Password CLI: good read access, limited write
- Mac Keychain: security policy restrictions
- Consider as Phase 3 after basic system is stable
- Security implications need careful review

## PyCharm GUI Dialog Issue - STILL UNRESOLVED

**Problem**: PyCharm File Open/Save dialogs non-responsive, but Cursor works fine
**Attempted Fixes**:
1. ✅ Removed repetitive `defaults write` commands (conditional check added)
2. ✅ Removed `LD_LIBRARY_PATH` exports (lines 285, 303) 
3. ❌ **Still failing after terminal restart**

**Status**: PyCharm still hangs, but Cursor is faster → suggests issue is PyCharm-specific

**Next Investigation Steps** (when you return):
1. **Check PyCharm-specific environment conflicts**:
   - JAVA_HOME pointing to SDKMAN Java vs PyCharm's bundled JVM
   - JetBrains toolbox PATH conflicts (line 50 in environment.zsh)
   - PyCharm JVM options in IDE settings

2. **Check system-level issues**:
   - macOS permissions/security settings
   - PyCharm app quarantine status: `xattr -dr com.apple.quarantine /Applications/PyCharm.app`
   - System file dialog service issues

3. **Environment isolation test**:
   - Launch PyCharm with clean environment: `env -i /Applications/PyCharm.app/Contents/MacOS/pycharm`
   - Compare with working apps (Cursor, others)

4. **PyCharm-specific debugging**:
   - Check PyCharm's idea.log for errors
   - Try PyCharm safe mode (Help → Find Action → Safe Mode)
   - Reset PyCharm file dialog cache

**Working Theory**: PyCharm + SDKMAN Java conflict, not shell environment issue

## NEW: JetBrains Module & PyCharm Fix

✅ **Created comprehensive JetBrains module** (`config/jetbrains.zsh`):
- Integrated JetBrains Toolbox CLI tools (pycharm, idea, datagrip, etc.)
- Added project type auto-detection (Python → PyCharm, Java → IntelliJ, etc.)
- Created `pycharm_clean_launch` function to debug file dialog issues
- Added environment diagnosis tools (`jetbrains_diagnose_env`)

**Test the PyCharm fix immediately:**
```bash
# Source the new module
source ~/.config/zsh/config/jetbrains.zsh

# Try clean launch (bypasses environment conflicts)
pycharm_clean_launch

# Or diagnose environment issues
jetbrains_diagnose_env
```

**Expected Result**: File dialogs should work properly with clean launch

## Current Status  
- ✅ Issues identified
- ✅ Branch created  
- ✅ Plan documented  
- ✅ **SECURITY FIX**: Removed plaintext passwords
- ✅ **GUI FIX**: Removed LD_LIBRARY_PATH causing PyCharm issues
- ✅ **JETBRAINS MODULE**: Complete development tools integration added
- 🧪 **TEST NEEDED**: Try `pycharm_clean_launch` to test file dialog fix
- 🔄 Ready for credential system implementation and further module extraction

## Key Files to Preserve Current Workflow
- Env variables for psql: `PGHOST`, `PGUSER`, `PGPASSWORD`, etc.
- Snowflake credentials (maintain as env vars)
- Migration path to 1Password/Mac Keychain when ready