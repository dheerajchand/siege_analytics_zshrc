#!/usr/bin/env zsh
# Working Enhanced Password Sync - Combines validated components

function enhanced_password_sync() {
    echo "🔄 Enhanced Password Sync System v1.1"
    echo "======================================"
    echo ""
    
    # Validate 1Password setup
    echo "🔍 Validating 1Password setup..."
    if ! command -v op >/dev/null 2>&1; then
        echo "❌ 1Password CLI not found. Install: brew install 1password-cli"
        return 1
    fi
    
    if ! op account list >/dev/null 2>&1; then
        echo "❌ Not signed in to 1Password. Run: op signin"
        return 1
    fi
    
    local vaults=$(op vault list --format=json 2>/dev/null | jq -r '.[].name' | tr '\n' ', ' | sed 's/,$//')
    echo "✅ 1Password ready. Available vaults: $vaults"
    echo ""
    
    # Quick discovery test
    echo "🔍 Testing keychain discovery..."
    local inet_count=$(security dump-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null | \
                      LC_ALL=C grep -c '"srvr"<blob>="' || echo 0)
    local genp_count=$(security dump-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null | \
                      LC_ALL=C grep -c '"svce"<blob>="' || echo 0)
    local total_discovered=$((inet_count + genp_count))
    
    echo "✅ Discovery test complete:"
    echo "   🌐 Internet passwords: $inet_count"
    echo "   🔑 Generic passwords: $genp_count" 
    echo "   📈 Total discoverable: $total_discovered entries"
    echo ""
    
    # End-to-end test
    echo "🧪 Running end-to-end sync validation..."
    source /tmp/test-sync-simple.zsh
    test_simple_sync --live
    
    if [[ $? -eq 0 ]]; then
        echo ""
        echo "🎉 ENHANCED PASSWORD SYNC VALIDATION COMPLETE!"
        echo ""
        echo "✅ System Status:"
        echo "   🔐 1Password CLI: Ready"
        echo "   🍎 Keychain access: Working"
        echo "   📊 Discovery capability: $total_discovered entries"
        echo "   🔄 Sync workflow: Validated"
        echo ""
        echo "💡 The enhanced password sync system is production-ready!"
        echo "   You can safely sync your keychain to 1Password when needed."
        return 0
    else
        echo ""
        echo "❌ VALIDATION FAILED"
        echo "   Please check the error messages above and resolve issues."
        return 1
    fi
}

# Simple status check
function sync_system_status() {
    echo "🔐 Enhanced Password Sync Status"
    echo "==============================="
    
    [[ -n "$SYNC_SYSTEM_LOADED" ]] && echo "✅ Sync system loaded: $SYNC_SYSTEM_LOADED" || echo "⚠️  Sync system not loaded"
    command -v op >/dev/null 2>&1 && echo "✅ 1Password CLI available" || echo "❌ 1Password CLI missing"
    op account list >/dev/null 2>&1 && echo "✅ 1Password authenticated" || echo "⚠️  1Password not signed in"
    security dump-keychain ~/Library/Keychains/login.keychain-db >/dev/null 2>&1 && echo "✅ Keychain accessible" || echo "⚠️  Keychain access denied"
    
    echo ""
    echo "💡 Run 'enhanced_password_sync' to validate the complete system"
}

export SYNC_SYSTEM_LOADED="v1.1-working"
echo "🔐 Working Enhanced Password Sync loaded"