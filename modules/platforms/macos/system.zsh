#!/usr/bin/env zsh

# =====================================================
# MACOS SYSTEM UTILITIES
# =====================================================
#
# macOS-specific system utilities and performance tools.
# These functions help manage macOS system services and diagnostics.
# =====================================================

restart_finder() {
    # Restart Finder to resolve file dialog and browsing issues
    #
    # This function is useful when experiencing:
    #   - Slow file dialogs in applications
    #   - File browser navigation issues
    #   - Stale file system caches
    #   - Problems with file creation/saving dialogs
    #
    # Examples:
    #     restart_finder
    #     restart_finder && echo "Finder restarted successfully"
    echo "🔄 Restarting Finder..."
    killall Finder 2>/dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ Finder restarted successfully"
        echo "💡 This should resolve file dialog and navigation issues"
    else
        echo "⚠️  Finder may not have been running, but it will start automatically"
    fi
}

icloud_diagnose() {
    # Diagnose iCloud sync issues and identify problematic containers
    #
    # This function identifies containers that are:
    #   - Stuck in sync loops (high CPU usage)
    #   - Blocked due to uninstalled apps
    #   - Failed sync operations
    #   - Consuming excessive system resources
    #
    # Usage:
    #     icloud_diagnose                # Full diagnostic report
    #     icloud_diagnose --cpu          # Focus on CPU-intensive containers
    #     icloud_diagnose --blocked      # Show only blocked containers
    #
    # Examples:
    #     icloud_diagnose
    #     icloud_diagnose --blocked | grep uninstalled

    local focus_mode="${1:-all}"

    echo "🔍 iCloud Drive Diagnostic Report"
    echo "================================="
    echo ""

    # Check fileproviderd CPU usage
    echo "📊 File Provider Daemon Status:"
    local fpd_cpu=$(ps aux | grep fileproviderd | grep -v grep | awk '{print $3}' | head -1)
    if [[ -n "$fpd_cpu" ]]; then
        echo "   CPU Usage: ${fpd_cpu}%"
        if (( $(echo "$fpd_cpu > 50" | bc -l 2>/dev/null || echo 0) )); then
            echo "   ⚠️  HIGH CPU USAGE - Investigating sync issues..."
        elif (( $(echo "$fpd_cpu > 10" | bc -l 2>/dev/null || echo 0) )); then
            echo "   ⚡ Moderate activity"
        else
            echo "   ✅ Normal operation"
        fi
    else
        echo "   ❓ fileproviderd not running"
    fi
    echo ""

    # Analyze container sync status
    echo "📦 Container Sync Analysis:"

    case "$focus_mode" in
        "--cpu"|"--performance")
            echo "   🔍 Focusing on performance issues..."
            brctl status 2>/dev/null | grep -E "(blocked|error|failed|needs-sync)" | head -10
            ;;
        "--blocked")
            echo "   🔍 Showing blocked containers..."
            brctl status 2>/dev/null | grep -E "blocked-app-uninstalled" | head -10
            ;;
        *)
            echo "   📋 Full container status (showing issues only):"
            brctl status 2>/dev/null | grep -E "(blocked|error|failed|needs-sync|uninstalled)" | head -15
            ;;
    esac

    echo ""
    echo "🔧 Quick Actions Available:"
    echo "   icloud_cleanup                 # Interactive cleanup of problematic containers"
    echo "   icloud_cleanup --uninstalled   # Remove all uninstalled app containers"
    echo "   icloud_cleanup --force <name>  # Force remove specific container"
    echo ""
    echo "💡 If fileproviderd CPU > 50%, run icloud_cleanup to resolve sync issues"
}

icloud_cleanup() {
    # Clean up problematic iCloud containers that cause system performance issues
    #
    # This function can:
    #   - Remove containers for uninstalled apps
    #   - Disable sync for problematic containers
    #   - Force remove specific containers causing issues
    #
    # Usage:
    #     icloud_cleanup                    # Interactive mode - shows options
    #     icloud_cleanup --uninstalled     # Remove all uninstalled app containers
    #     icloud_cleanup --disable <name>  # Disable sync for container
    #     icloud_cleanup --force <name>    # Force remove container (requires sudo)
    #
    # Examples:
    #     icloud_cleanup --uninstalled
    #     icloud_cleanup --force "com.dave.bike"
    #     icloud_cleanup --disable "2NSFZY54JA.com.dave.bike"

    local action="${1:-interactive}"
    local target_container="$2"

    echo "🧹 iCloud Container Cleanup Utility"
    echo "==================================="
    echo ""

    case "$action" in
        "--uninstalled"|"--blocked")
            echo "🔍 Finding containers for uninstalled apps..."
            local blocked_containers=($(brctl status 2>/dev/null | grep "blocked-app-uninstalled" | cut -d'<' -f2 | cut -d'[' -f1))

            if [[ ${#blocked_containers[@]} -eq 0 ]]; then
                echo "✅ No blocked containers found!"
                return 0
            fi

            echo "Found ${#blocked_containers[@]} problematic containers:"
            for container in "${blocked_containers[@]}"; do
                echo "   📦 $container"
            done
            echo ""

            echo "🔧 Disabling sync for these containers..."
            for container in "${blocked_containers[@]}"; do
                echo "   Disabling: $container"
                defaults write com.apple.bird disable-sync-for-bundle-ids -array-add "$container" 2>/dev/null || {
                    echo "   ⚠️  Could not disable sync for $container"
                }
            done

            echo ""
            echo "🔄 Restarting fileproviderd to apply changes..."
            pkill -f fileproviderd 2>/dev/null
            sleep 2

            echo "✅ Cleanup completed! Run 'icloud_diagnose' to verify the fix."
            ;;

        "--disable")
            if [[ -z "$target_container" ]]; then
                echo "❌ Error: Container name required"
                echo "Usage: icloud_cleanup --disable <container-name>"
                return 1
            fi

            echo "🔧 Disabling sync for: $target_container"
            defaults write com.apple.bird disable-sync-for-bundle-ids -array-add "$target_container"
            pkill -f fileproviderd 2>/dev/null
            echo "✅ Sync disabled. fileproviderd restarted."
            ;;

        "--force")
            if [[ -z "$target_container" ]]; then
                echo "❌ Error: Container name required"
                echo "Usage: icloud_cleanup --force <container-name>"
                return 1
            fi

            echo "⚠️  Force removing container: $target_container"
            echo "This will permanently delete all data for this container."
            echo -n "Are you sure? (y/N): "
            read -r confirmation

            if [[ "$confirmation" =~ ^[Yy]$ ]]; then
                echo "🗑️  Removing container files..."
                local container_path="$HOME/Library/Mobile Documents/*${target_container}*"
                if sudo rm -rf $container_path 2>/dev/null; then
                    echo "✅ Container removed successfully"
                    pkill -f fileproviderd 2>/dev/null
                    echo "🔄 Restarted fileproviderd"
                else
                    echo "❌ Failed to remove container. Check permissions or container name."
                fi
            else
                echo "❌ Operation cancelled"
            fi
            ;;

        *)
            echo "🛠️  Available cleanup options:"
            echo ""
            echo "1. 📱 Remove containers for uninstalled apps (RECOMMENDED)"
            echo "   icloud_cleanup --uninstalled"
            echo ""
            echo "2. 🚫 Disable sync for specific container"
            echo "   icloud_cleanup --disable <container-name>"
            echo ""
            echo "3. 🗑️  Force remove container (permanent deletion)"
            echo "   icloud_cleanup --force <container-name>"
            echo ""
            echo "💡 Run 'icloud_diagnose' first to identify problematic containers"
            echo ""
            echo -n "Choose option (1-3) or press Enter to exit: "
            read -r choice

            case "$choice" in
                "1")
                    icloud_cleanup --uninstalled
                    ;;
                "2")
                    echo -n "Enter container name: "
                    read -r container_name
                    icloud_cleanup --disable "$container_name"
                    ;;
                "3")
                    echo -n "Enter container name: "
                    read -r container_name
                    icloud_cleanup --force "$container_name"
                    ;;
                *)
                    echo "👋 Cleanup cancelled"
                    ;;
            esac
            ;;
    esac
}

# macOS system module loaded indicator
export MACOS_SYSTEM_LOADED=true