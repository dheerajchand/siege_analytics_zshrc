#!/usr/bin/env zsh
# Test the new 3-tier system

echo "🧪 Testing 3-Tier System User Experience"
echo "========================================"
echo ""

# Test 1: Check if minimal config loads basic functions
echo "📝 Test 1: Basic function availability"
if command -v load_module >/dev/null 2>&1; then
    echo "✅ load_module function available"
else
    echo "❌ load_module function missing"
fi

if command -v show_loaded_modules >/dev/null 2>&1; then
    echo "✅ show_loaded_modules function available"
else
    echo "❌ show_loaded_modules function missing"
fi

echo ""

# Test 2: Test module loading with feedback
echo "📝 Test 2: Module loading user experience"
echo "Loading Python module..."
load_module python 2>/dev/null
echo ""

# Test 3: Check module tracking
echo "📝 Test 3: Module tracking"
echo "LOADED_MODULES: ${LOADED_MODULES:-'None'}"
echo ""

# Test 4: Show modules command
echo "📝 Test 4: Modules status display"
show_loaded_modules
echo ""

# Test 5: Help system
echo "📝 Test 5: Help system"
zsh_help | head -10
echo ""

echo "✅ User experience test complete!"