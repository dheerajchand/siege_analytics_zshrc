# CLAUDE DIRECTIVE: SYSTEMATIC VERIFICATION REQUIRED

## CRITICAL REQUIREMENT: NEVER DECLARE SUCCESS WITHOUT VERIFICATION

### The Problem Pattern:
Claude consistently declares "victory" or "success" without properly examining the actual output or verifying that changes work as intended.

### Examples of Failure:
1. **Assuming restart = success**: Seeing `zshreboot` work and assuming all functions loaded
2. **Ignoring user output**: Not carefully reading what the user actually posted
3. **Premature victory declarations**: Saying "✅ SUCCESS!" without testing the actual functionality
4. **Missing critical details**: Failing to notice when functions don't load or commands produce no output

### MANDATORY VERIFICATION PROCESS:

#### 1. READ USER OUTPUT CAREFULLY
- **ALWAYS** examine every line of user output
- **NEVER** assume success based on partial information
- **LOOK FOR** missing expected output, error messages, unexpected behavior

#### 2. VERIFY EACH CLAIM
- If I say "function X works" → Must see actual evidence of function X working
- If I say "no errors" → Must see actual error checking performed
- If I say "loading successful" → Must see actual loaded functionality demonstrated

#### 3. TEST SYSTEMATIC VERIFICATION
Before declaring any step complete:
```bash
# Example verification pattern:
# 1. Check the thing exists
type function_name

# 2. Check it produces expected output
function_name

# 3. Check related functionality
check_related_feature

# 4. Verify integration works
test_integration_point
```

#### 4. ACKNOWLEDGE WHEN WRONG
- When user points out failure, immediately acknowledge the verification failure
- Don't make excuses or deflect
- Focus on proper investigation of what actually happened

### USER FEEDBACK THAT TRIGGERED THIS:
> "You didn't even check the output I pasted, just saw that I pasted and said you won."

### COMMITMENT:
I will follow systematic verification for every change and never declare success without confirming the actual functionality works as intended.

**Date Created:** 2025-01-23
**Context:** ZSH configuration restoration project - repeated verification failures