#!/usr/bin/env zsh

# =====================================================
# ADVANCED CODE QUALITY HOSTILE TESTING
# =====================================================
# Tests for real developer mistakes by examining actual code

echo "🔥 ADVANCED CODE QUALITY TESTING - ASSUME DEVELOPER IS IDIOT"
echo "=============================================================="
echo "Examining actual code for common mistakes and vulnerabilities"
echo ""

export FAILURES=0
export TESTS=0

report_issue() {
    local severity="$1"
    local issue="$2"
    local file="$3"
    local line="$4"

    TESTS=$((TESTS + 1))

    if [[ "$severity" == "CRITICAL" ]] || [[ "$severity" == "HIGH" ]]; then
        FAILURES=$((FAILURES + 1))
        echo "❌ [$severity] $issue"
        [[ -n "$file" ]] && echo "   📂 File: $file:$line"
    else
        echo "⚠️  [$severity] $issue"
        [[ -n "$file" ]] && echo "   📂 File: $file:$line"
    fi
}

echo "🚨 PHASE 1: UNVALIDATED INPUT ANALYSIS"
echo "======================================="

# Check for functions that don't validate inputs
echo "Scanning for unvalidated input usage..."

# Look for direct parameter usage without validation
grep -n '\$[1-9]' /Users/dheerajchand/.config/zsh/zshrc | while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    content=$(echo "$line" | cut -d: -f2-)

    # Check if the line uses parameters without validation
    if ! echo "$content" | grep -q '\[\[.*-.*\]\]'; then
        if echo "$content" | grep -q 'eval\|exec\|source\|rm\|cp\|mv'; then
            report_issue "HIGH" "Potentially dangerous command uses unvalidated parameter" "zshrc" "$line_num"
        fi
    fi
done

echo ""
echo "🚨 PHASE 2: COMMAND INJECTION VULNERABILITY SCAN"
echo "================================================="

# Look for eval/exec with user input
grep -n -A2 -B2 'eval\|exec' /Users/dheerajchand/.config/zsh/zshrc | while read -r line; do
    if echo "$line" | grep -q '\$[1-9]\|\${.*}\|\$[A-Za-z]'; then
        line_num=$(echo "$line" | grep -o '^[0-9]*' | head -1)
        report_issue "CRITICAL" "Command injection risk: eval/exec with user input" "zshrc" "$line_num"
    fi
done

echo ""
echo "🚨 PHASE 3: ERROR HANDLING ANALYSIS"
echo "===================================="

# Check for commands without error handling
echo "Scanning for missing error handling..."

# Look for dangerous commands without error checking
patterns=("source " "cd " "mkdir " "rm " "cp " "mv ")
for pattern in "${patterns[@]}"; do
    grep -n "$pattern" /Users/dheerajchand/.config/zsh/zshrc | while read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        content=$(echo "$line" | cut -d: -f2-)

        # Skip if already has error handling
        if ! echo "$content" | grep -q '||.*2>/dev/null\|&&\|;\s*then'; then
            report_issue "MEDIUM" "Command without error handling: $pattern" "zshrc" "$line_num"
        fi
    done
done

echo ""
echo "🚨 PHASE 4: PATH INJECTION VULNERABILITY SCAN"
echo "=============================================="

# Check for PATH manipulation without validation
grep -n -i 'PATH.*=' /Users/dheerajchand/.config/zsh/zshrc | while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    content=$(echo "$line" | cut -d: -f2-)

    # Check if PATH is set from user input without validation
    if echo "$content" | grep -q '\$[1-9]\|\$HOME\|\$USER'; then
        if ! echo "$content" | grep -q 'realpath\|readlink\|test -d'; then
            report_issue "HIGH" "PATH manipulation without validation" "zshrc" "$line_num"
        fi
    fi
done

echo ""
echo "🚨 PHASE 5: FUNCTION DEFINITION SECURITY ANALYSIS"
echo "=================================================="

# Check for functions that could be hijacked
echo "Analyzing function definitions for security issues..."

# Get all function definitions
grep -n '^[a-zA-Z_][a-zA-Z0-9_]*()' /Users/dheerajchand/.config/zsh/zshrc | while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    func_name=$(echo "$line" | sed 's/.*:\([^(]*\)().*/\1/')

    # Check if function name could conflict with system commands
    if command -v "$func_name" >/dev/null 2>&1; then
        report_issue "MEDIUM" "Function shadows system command: $func_name" "zshrc" "$line_num"
    fi
done

echo ""
echo "🚨 PHASE 6: VARIABLE SECURITY ANALYSIS"
echo "======================================="

# Check for potentially dangerous variable usage
grep -n 'export.*=' /Users/dheerajchand/.config/zsh/zshrc | while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    content=$(echo "$line" | cut -d: -f2-)

    # Check for dangerous environment variables
    if echo "$content" | grep -q 'LD_PRELOAD\|DYLD_\|IFS\|PS[1-4]'; then
        report_issue "HIGH" "Export of potentially dangerous environment variable" "zshrc" "$line_num"
    fi
done

echo ""
echo "🚨 PHASE 7: FILE OPERATION SECURITY SCAN"
echo "========================================="

# Check for unsafe file operations
grep -n 'rm\|cp\|mv\|chmod\|chown' /Users/dheerajchand/.config/zsh/zshrc | while read -r line; do
    line_num=$(echo "$line" | cut -d: -f1)
    content=$(echo "$line" | cut -d: -f2-)

    # Check for operations on user-controlled paths
    if echo "$content" | grep -q '\$[1-9]\|\${.*}\|\$[A-Za-z]'; then
        if ! echo "$content" | grep -q 'realpath\|readlink\|test -f\|test -d'; then
            report_issue "HIGH" "File operation on unvalidated path" "zshrc" "$line_num"
        fi
    fi
done

echo ""
echo "🚨 PHASE 8: CREDENTIAL HANDLING ANALYSIS"
echo "========================================="

# Check credential handling code if it exists
if [[ -f "/Users/dheerajchand/.config/zsh/config/credentials.zsh" ]]; then
    echo "Analyzing credential handling code..."

    # Check for hardcoded credentials
    grep -n -i 'password\|secret\|key\|token' /Users/dheerajchand/.config/zsh/config/credentials.zsh | while read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        content=$(echo "$line" | cut -d: -f2-)

        # Check if it looks like a hardcoded credential
        if echo "$content" | grep -q '=.*["\047][A-Za-z0-9+/=]{8,}["\047]'; then
            report_issue "CRITICAL" "Possible hardcoded credential" "credentials.zsh" "$line_num"
        fi
    done

    # Check for credential logging
    grep -n 'echo\|printf\|log' /Users/dheerajchand/.config/zsh/config/credentials.zsh | while read -r line; do
        line_num=$(echo "$line" | cut -d: -f1)
        content=$(echo "$line" | cut -d: -f2-)

        if echo "$content" | grep -q '\$.*password\|\$.*secret\|\$.*key\|\$.*token'; then
            report_issue "CRITICAL" "Credential may be logged or printed" "credentials.zsh" "$line_num"
        fi
    done
fi

echo ""
echo "🚨 PHASE 9: MODULE LOADING SECURITY ANALYSIS"
echo "============================================="

# Check load_module function for security issues
if grep -q "load_module" /Users/dheerajchand/.config/zsh/zshrc; then
    echo "Analyzing module loading security..."

    # Extract load_module function and analyze it
    sed -n '/^load_module.*{/,/^}/p' /Users/dheerajchand/.config/zsh/zshrc > /tmp/load_module_func.txt

    # Check for path traversal protection
    if ! grep -q '\.\./\|realpath\|readlink' /tmp/load_module_func.txt; then
        report_issue "HIGH" "load_module may be vulnerable to path traversal"
    fi

    # Check for input validation
    if ! grep -q '\[\[.*-n.*\]\]\|\[\[.*-z.*\]\]' /tmp/load_module_func.txt; then
        report_issue "MEDIUM" "load_module lacks input validation"
    fi

    rm -f /tmp/load_module_func.txt
fi

echo ""
echo "🚨 PHASE 10: RUNTIME BEHAVIOR TESTING"
echo "====================================="

# Test actual runtime behavior for edge cases
echo "Testing runtime behavior with edge cases..."

# Test with null bytes
echo "Testing null byte handling..."
result=$(/bin/zsh -c '
    source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1
    load_module $'"'"'python\x00rm'"'"' 2>&1
' 2>/dev/null)

if echo "$result" | grep -q "No such file\|not found\|cannot load"; then
    echo "✅ Null byte handling: SECURE"
else
    report_issue "HIGH" "Null byte injection may be possible"
fi

# Test with very long input
echo "Testing buffer overflow protection..."
long_input=$(printf "A%.0s" {1..10000})
result=$(/bin/zsh -c "
    source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1
    load_module '$long_input' 2>&1
" 2>/dev/null)

if echo "$result" | grep -q "too long\|invalid\|not found"; then
    echo "✅ Buffer overflow protection: SECURE"
else
    report_issue "MEDIUM" "Long input handling may be vulnerable"
fi

echo ""
echo "📊 ADVANCED CODE QUALITY RESULTS"
echo "================================="

if [[ $FAILURES -eq 0 ]]; then
    echo "✅ NO CRITICAL ISSUES FOUND ($TESTS tests performed)"
    echo "🎉 Code appears to follow good security practices"
    exit_code=0
else
    echo "❌ SECURITY ISSUES DETECTED ($FAILURES critical/high issues found)"
    echo "🚨 Code has security vulnerabilities that need immediate attention"
    echo ""
    echo "🔧 RECOMMENDATION: Fix all CRITICAL and HIGH severity issues immediately"
    echo "⚠️  Consider fixing MEDIUM severity issues for defense in depth"
    exit_code=1
fi

echo ""
echo "🛡️  SECURITY CATEGORIES ANALYZED:"
echo "- Command injection vulnerabilities"
echo "- Path traversal attacks"
echo "- Input validation bypasses"
echo "- Credential exposure risks"
echo "- File operation security"
echo "- Environment variable manipulation"
echo "- Function hijacking opportunities"
echo "- Buffer overflow conditions"
echo "- Error handling weaknesses"
echo "- Runtime behavior edge cases"

exit $exit_code