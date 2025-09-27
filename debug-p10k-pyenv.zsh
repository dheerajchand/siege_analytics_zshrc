#!/usr/bin/env zsh
# Quick debug test for the two fixes

echo "🔍 DEBUG: Tracing P10k and Pyenv fixes"
echo "======================================"

echo ""
echo "1. INITIAL STATE:"
echo "   POWERLEVEL9K_INSTANT_PROMPT: '$POWERLEVEL9K_INSTANT_PROMPT'"
echo "   ENABLE_P10K_INSTANT_PROMPT: '$ENABLE_P10K_INSTANT_PROMPT'"

echo ""
echo "2. TESTING VARIABLE NAME FIX:"
# Check for the critical variable name fix
if grep -q "module_file=" ~/.config/zsh/zshrc && ! grep -q "module_path=" ~/.config/zsh/zshrc; then
    echo "   ✅ Variable fix: PASS (uses module_file, not module_path)"
else
    echo "   ❌ Variable fix: FAIL (still uses problematic module_path)"
fi

echo ""
echo "3. SIMULATING VARIABLE COLLISION:"
# Set up module_path array (this was causing the pyenv issue)
typeset -a module_path
module_path=(/usr/lib/zsh /usr/local/share/zsh)
echo "   Set global module_path array: ${module_path[@]}"

# Test load_module function
echo "   Testing load_module with collision..."
source ~/.config/zsh/zshrc >/dev/null 2>&1

if typeset -f load_module >/dev/null 2>&1; then
    echo "   ✅ load_module function available"

    # Test loading a module
    load_module utils >/dev/null 2>&1
    if typeset -f backup >/dev/null 2>&1; then
        echo "   ✅ Module loading works despite global module_path array"
    else
        echo "   ❌ Module loading failed - variable collision occurred"
    fi

    # Check if global array preserved
    if [[ "${module_path[1]}" == "/usr/lib/zsh" ]]; then
        echo "   ✅ Global module_path array preserved"
    else
        echo "   ❌ Global module_path array was overwritten"
    fi
else
    echo "   ❌ load_module function not available"
fi

echo ""
echo "4. P10K INSTANT PROMPT TEST:"
echo "   After sourcing zshrc:"
echo "   POWERLEVEL9K_INSTANT_PROMPT: '$POWERLEVEL9K_INSTANT_PROMPT'"
echo "   ENABLE_P10K_INSTANT_PROMPT: '$ENABLE_P10K_INSTANT_PROMPT'"

# Test the toggle
echo ""
echo "5. TESTING P10K TOGGLE:"
echo "   Testing enable toggle..."
export ENABLE_P10K_INSTANT_PROMPT="true"

# Create isolated test
zsh -c '
    export ENABLE_P10K_INSTANT_PROMPT="true"
    # Run just the P10k logic
    if [[ "$ENABLE_P10K_INSTANT_PROMPT" == "true" ]]; then
        export POWERLEVEL9K_INSTANT_PROMPT="verbose"
    else
        export POWERLEVEL9K_INSTANT_PROMPT="off"
    fi
    echo "   With ENABLE=true: POWERLEVEL9K_INSTANT_PROMPT=$POWERLEVEL9K_INSTANT_PROMPT"
'

zsh -c '
    export ENABLE_P10K_INSTANT_PROMPT="false"
    # Run just the P10k logic
    if [[ "$ENABLE_P10K_INSTANT_PROMPT" == "true" ]]; then
        export POWERLEVEL9K_INSTANT_PROMPT="verbose"
    else
        export POWERLEVEL9K_INSTANT_PROMPT="off"
    fi
    echo "   With ENABLE=false: POWERLEVEL9K_INSTANT_PROMPT=$POWERLEVEL9K_INSTANT_PROMPT"
'

echo ""
echo "6. FINAL ASSESSMENT:"

# Check current state after full source
current_p10k="$POWERLEVEL9K_INSTANT_PROMPT"
current_enable="$ENABLE_P10K_INSTANT_PROMPT"

if [[ "$current_enable" != "true" ]] && [[ "$current_p10k" == "off" ]]; then
    echo "   ✅ P10k fix: WORKING (instant prompt off by default)"
elif [[ "$current_enable" == "true" ]] && [[ "$current_p10k" == "verbose" ]]; then
    echo "   ✅ P10k fix: WORKING (toggle enabled instant prompt)"
else
    echo "   ❌ P10k fix: BROKEN (ENABLE=$current_enable, P10K=$current_p10k)"
fi

echo ""
echo "SUMMARY:"
echo "========="
variable_fix=$(grep -q "module_file=" ~/.config/zsh/zshrc && ! grep -q "module_path=" ~/.config/zsh/zshrc && echo "PASS" || echo "FAIL")
echo "• Variable name fix (pyenv completion): $variable_fix"

if [[ "$POWERLEVEL9K_INSTANT_PROMPT" == "off" ]] || [[ "$POWERLEVEL9K_INSTANT_PROMPT" == "verbose" && "$ENABLE_P10K_INSTANT_PROMPT" == "true" ]]; then
    p10k_fix="PASS"
else
    p10k_fix="FAIL"
fi
echo "• P10k instant prompt fix: $p10k_fix"

if [[ "$variable_fix" == "PASS" ]] && [[ "$p10k_fix" == "PASS" ]]; then
    echo ""
    echo "🎉 BOTH FIXES ARE WORKING"
    exit 0
else
    echo ""
    echo "🚨 FIXES NEED ATTENTION"
    exit 1
fi