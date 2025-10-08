# TESTING DIRECTIVES - MANDATORY BEFORE DECLARING SUCCESS

## CRITICAL RULES

### 1. NEVER DECLARE VICTORY WITHOUT TESTING
- **BEFORE** saying "this should work" or "you should see"
- **BEFORE** using phrases like "the fix" or "this resolves"
- **BEFORE** marking todos as complete
- **ALWAYS** test the actual functionality first

### 2. SYSTEMATIC TESTING APPROACH
- Make ONE change at a time
- Test that ONE change immediately
- Verify the change actually works
- Only then proceed to the next change

### 3. REAL TESTING, NOT VANITY TESTING
- Test in the ACTUAL environment where the problem occurs
- Test the ACTUAL functionality, not simulated scenarios
- Ask the user to test if you cannot reproduce the environment
- Scripts that run in different contexts are NOT valid tests

### 4. ACKNOWLEDGE UNCERTAINTY
- Say "I think this might work" instead of "this will work"
- Say "please test this" instead of "you should see"
- Say "this change should help" instead of "this fixes the problem"
- Always acknowledge when you haven't tested

### 5. ERROR HANDLING
- When a test fails, diagnose WHY it failed
- Don't immediately try another "fix"
- Understand the root cause before attempting solutions
- Admit when you don't understand something

### 6. DOCUMENTATION OF TESTS
- Document what was tested
- Document the expected vs actual results
- Keep a log of what works and what doesn't
- Learn from failed tests

## VIOLATION CONSEQUENCES

Breaking these rules results in:
- User frustration and lost trust
- Wasted time on ineffective solutions
- Band-aid fixes instead of root cause solutions
- Repeated failures of the same type

## EXAMPLES OF GOOD TESTING

✅ "I've made this change. Can you test it and tell me if the warning disappears?"
✅ "This might fix the issue, but I need you to verify it works in PyCharm"
✅ "Let me test this change first before we proceed"

## EXAMPLES OF BAD BEHAVIOR

❌ "This fix should work - you should see no warnings"
❌ "The problem is now resolved"
❌ "Test this - it will definitely work"
❌ Creating complex test scripts instead of simple direct testing

## MANDATORY CHECKLIST BEFORE CLAIMING SUCCESS

- [ ] Have I actually tested this change?
- [ ] Does the test environment match the problem environment?
- [ ] Have I verified the specific functionality works?
- [ ] Am I making claims about things I haven't verified?
- [ ] Would I bet money that this fix works?

**IF ANY ANSWER IS NO, DO NOT DECLARE SUCCESS**