#!/usr/bin/env zsh
# =====================================================
# 3-TIER SYSTEM TESTS
# =====================================================

test_minimal_startup() {
    echo "🧪 Testing minimal startup..."

    # Test minimal zshrc loads quickly
    local start_time=$(date +%s.%N)
    zsh -c 'source ~/.config/zsh/zshrc.minimal; exit'
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc)

    echo "⏱️  Startup time: ${duration}s"

    if (( $(echo "$duration < 3.0" | bc -l) )); then
        echo "✅ Startup test passed"
    else
        echo "❌ Startup too slow: ${duration}s"
    fi
}

test_module_loading() {
    echo "🧪 Testing module loading..."

    # Test each module loads without errors (7 primary + 5 hierarchical = 12 total)
    local modules=("python" "docker" "database" "spark" "jetbrains" "utils" "javascript")

    for module in "${modules[@]}"; do
        if zsh -c "source ~/.config/zsh/modules/$module.zsh" 2>/dev/null; then
            echo "✅ Module $module loads successfully"
        else
            echo "❌ Module $module failed to load"
        fi
    done
}

test_service_control() {
    echo "🧪 Testing service control..."

    if [[ -x ~/.config/zsh/zsh-system ]]; then
        echo "✅ zsh-system executable"

        # Test service listing
        if ~/.config/zsh/zsh-system service list >/dev/null 2>&1; then
            echo "✅ Service listing works"
        else
            echo "❌ Service listing failed"
        fi
    else
        echo "❌ zsh-system not executable"
    fi
}

# Run tests
echo "🚀 3-Tier System Test Suite"
echo "============================"
test_minimal_startup
echo ""
test_module_loading
echo ""
test_service_control
echo ""
echo "✅ Test suite complete"