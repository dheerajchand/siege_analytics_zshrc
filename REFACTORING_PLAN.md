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

## Current Status  
- ✅ Issues identified
- ✅ Branch created  
- ✅ Plan documented
- ✅ **SECURITY FIX APPLIED**: Removed plaintext passwords from zshrc
- 🔄 Ready for credential system implementation when you return

## Key Files to Preserve Current Workflow
- Env variables for psql: `PGHOST`, `PGUSER`, `PGPASSWORD`, etc.
- Snowflake credentials (maintain as env vars)
- Migration path to 1Password/Mac Keychain when ready