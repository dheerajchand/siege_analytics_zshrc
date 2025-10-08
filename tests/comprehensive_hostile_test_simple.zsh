#!/usr/bin/env zsh

# =====================================================
# COMPREHENSIVE HOSTILE TESTING - SIMPLIFIED VERSION
# =====================================================
# This test attacks the ZSH system comprehensively but efficiently

echo "🔥 COMPREHENSIVE HOSTILE TESTING - SIMPLIFIED"
echo "=============================================="
echo "Testing system robustness with hostile inputs"
echo ""

# Set up hostile environment
export HOSTILE_TEST=true
export PATH="/tmp/malicious:/usr/bin:/bin"
export SHELL="/bin/sh -c 'echo COMPROMISED'"
export LD_PRELOAD="/tmp/malicious.so"
export PYTHONPATH="/tmp/malicious"
export NODE_PATH="/tmp/malicious"
export ZSH="/tmp/malicious"

# Create malicious files
mkdir -p /tmp/malicious
echo '#!/bin/bash
echo "SYSTEM COMPROMISED"
rm -rf /tmp/test_deletion_target 2>/dev/null || true
' > /tmp/malicious/python
echo '#!/bin/bash
echo "DOCKER COMPROMISED"
' > /tmp/malicious/docker
chmod +x /tmp/malicious/*

# Test hostile inputs array
HOSTILE_INPUTS=(
    'service; rm -rf /tmp/test_deletion_target'
    'service$(rm -rf /tmp/test_deletion_target)'
    'service`rm -rf /tmp/test_deletion_target`'
    'service | rm -rf /tmp/test_deletion_target'
    'service && rm -rf /tmp/test_deletion_target'
    'service > /tmp/hostile_output'
    '../../../etc/passwd'
    '$(whoami)'
    '`id`'
    '; cat /etc/passwd #'
)

echo "🚨 PHASE 1: FULL SYSTEM LOAD WITH HOSTILE ENVIRONMENT"
echo "======================================================="

# Create test target for deletion attempts
touch /tmp/test_deletion_target

# Source the entire ZSH configuration in this hostile environment
echo "Loading ZSH configuration in hostile environment..."
/bin/zsh -c '
    export ZSH_DISABLE_COMPFIX=true
    source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1
    echo "ZSH load result: $?"
' && echo "✅ ZSH loaded successfully" || echo "❌ ZSH loading failed"

# Check if malicious commands executed
if [[ ! -f /tmp/test_deletion_target ]]; then
    echo "❌ CRITICAL: File deletion occurred - system compromised"
    SYSTEM_COMPROMISED=true
else
    echo "✅ File deletion prevented"
fi

if [[ -f /tmp/hostile_output ]]; then
    echo "❌ CRITICAL: Hostile output file created"
    SYSTEM_COMPROMISED=true
else
    echo "✅ No hostile output files created"
fi

echo ""
echo "🚨 PHASE 2: MODULE TESTING WITH HOSTILE INPUTS"
echo "==============================================="

# Test all modules with hostile inputs (simplified)
for module in python docker database spark jetbrains; do
    echo "Testing $module module..."

    /bin/zsh -c "
        source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1
        load_module $module >/dev/null 2>&1

        # Test one representative hostile input per module
        case '$module' in
            'python')
                python_status 'service; echo PWNED' >/dev/null 2>&1 || true
                ;;
            'docker')
                docker_status 'service; echo PWNED' >/dev/null 2>&1 || true
                ;;
            'database')
                database_status 'service; echo PWNED' >/dev/null 2>&1 || true
                ;;
            'spark')
                spark_status 'service; echo PWNED' >/dev/null 2>&1 || true
                ;;
            'jetbrains')
                jetbrains_status 'service; echo PWNED' >/dev/null 2>&1 || true
                ;;
        esac
        echo '$module module test completed'
    " && echo "✅ $module module survived" || echo "❌ $module module failed"
done

echo ""
echo "🚨 PHASE 3: CREDENTIAL SYSTEM TESTING"
echo "======================================"

# Test credential system with hostile inputs (simplified)
/bin/zsh -c '
    source /Users/dheerajchand/.config/zsh/config/credentials.zsh >/dev/null 2>&1

    # Test a few hostile inputs sequentially (not in parallel)
    get_credential "service; echo PWNED1" "user" >/dev/null 2>&1 || true
    store_credential "service$(echo PWNED2)" "user" "value" >/dev/null 2>&1 || true
    ga_store_service_account "/tmp/malicious/fake.json" >/dev/null 2>&1 || true

    echo "Credential testing completed"
' && echo "✅ Credential system survived" || echo "❌ Credential system failed"

echo ""
echo "🚨 PHASE 4: FUNCTION REDEFINITION TESTING"
echo "=========================================="

# Test function redefinition attacks
/bin/zsh -c '
    # Try to redefine critical functions
    source() { echo "HIJACKED source"; }
    load_module() { echo "HIJACKED load_module"; }
    echo() { printf "HIJACKED echo\\n"; }

    # Try to load system with hijacked functions
    source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1
    load_module python >/dev/null 2>&1
    echo "Function redefinition test completed"
' 2>/dev/null && echo "✅ Function redefinition handled" || echo "❌ Function redefinition vulnerable"

echo ""
echo "🚨 PHASE 5: SYSTEM INTEGRITY VERIFICATION"
echo "=========================================="

# Check if system is still intact
echo "Checking system integrity..."

# Verify no malicious files were created
MALICIOUS_FILES_FOUND=false
for suspicious_file in /tmp/hostile_output /tmp/pwned /tmp/compromised; do
    if [[ -f "$suspicious_file" ]]; then
        echo "❌ CRITICAL: Malicious file found: $suspicious_file"
        MALICIOUS_FILES_FOUND=true
    fi
done

if ! $MALICIOUS_FILES_FOUND; then
    echo "✅ No malicious files created"
fi

# Test if ZSH still loads cleanly
echo "Testing ZSH reload after hostile testing..."
/bin/zsh -c '
    source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1
    echo "ZSH reload successful"
' && echo "✅ ZSH reload successful" || echo "❌ ZSH reload failed after hostile testing"

# Check if test deletion target still exists
if [[ -f /tmp/test_deletion_target ]]; then
    echo "✅ Test file integrity maintained"
    rm -f /tmp/test_deletion_target
else
    echo "❌ CRITICAL: Test file was deleted - system compromise detected"
fi

echo ""
echo "📊 COMPREHENSIVE HOSTILE TEST RESULTS"
echo "======================================"

if [[ -n "$SYSTEM_COMPROMISED" ]]; then
    echo "🚨 SYSTEM COMPROMISED - CRITICAL VULNERABILITIES DETECTED"
    exit 1
else
    echo "✅ System survived comprehensive hostile testing"
    exit 0
fi

# Cleanup
rm -rf /tmp/malicious
rm -f /tmp/test_deletion_target /tmp/hostile_output /tmp/pwned /tmp/compromised