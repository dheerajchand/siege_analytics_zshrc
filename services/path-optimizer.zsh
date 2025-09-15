#!/usr/bin/env zsh
# =====================================================
# PATH OPTIMIZER SERVICE - Background PATH management
# =====================================================
#
# This service runs periodically to maintain PATH health
# and prevent the PATH pollution that causes Finder issues.
# =====================================================

# Service configuration
SERVICE_NAME="path-optimizer"
LOG_FILE="$HOME/.config/zsh/logs/${SERVICE_NAME}.log"
PID_FILE="$HOME/.config/zsh/run/${SERVICE_NAME}.pid"
CHECK_INTERVAL=300  # 5 minutes

# Ensure directories exist
mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$PID_FILE")"

# =====================================================
# PATH OPTIMIZATION FUNCTIONS
# =====================================================

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

optimize_path() {
    local original_length=${#PATH}
    local original_count=$(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')

    # Clean PATH if it's too long
    if [[ $original_length -gt 1500 ]]; then
        log_message "PATH length ($original_length) exceeds threshold, cleaning..."

        # Backup current PATH
        echo "$PATH" > "$HOME/.config/zsh/.path_backup_$(date +%Y%m%d_%H%M%S)"

        # Remove duplicates and non-existent paths
        local new_path=""
        local IFS=":"

        for dir in $PATH; do
            # Skip empty entries
            [[ -z "$dir" ]] && continue

            # Skip if already in new_path
            [[ ":$new_path:" == *":$dir:"* ]] && continue

            # Skip if directory doesn't exist
            [[ ! -d "$dir" ]] && continue

            # Add to new PATH
            if [[ -z "$new_path" ]]; then
                new_path="$dir"
            else
                new_path="$new_path:$dir"
            fi
        done

        # Apply cleaned PATH
        export PATH="$new_path"

        local new_length=${#PATH}
        local new_count=$(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')
        local saved_chars=$((original_length - new_length))
        local saved_entries=$((original_count - new_count))

        log_message "PATH optimized: $original_length→$new_length chars (-$saved_chars), $original_count→$new_count entries (-$saved_entries)"
    else
        log_message "PATH length ($original_length) is healthy"
    fi
}

# =====================================================
# SERVICE CONTROL
# =====================================================

start_service() {
    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "❌ PATH optimizer service already running (PID: $(cat "$PID_FILE"))"
        return 1
    fi

    echo "🚀 Starting PATH optimizer service..."
    log_message "PATH optimizer service starting"

    # Background monitoring loop
    (
        echo $$ > "$PID_FILE"
        while true; do
            optimize_path
            sleep $CHECK_INTERVAL
        done
    ) &

    echo "✅ PATH optimizer service started (PID: $!)"
}

stop_service() {
    if [[ -f "$PID_FILE" ]]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$PID_FILE"
            log_message "PATH optimizer service stopped"
            echo "🛑 PATH optimizer service stopped"
        else
            rm -f "$PID_FILE"
            echo "⚠️  PATH optimizer service was not running"
        fi
    else
        echo "⚠️  No PID file found"
    fi
}

service_status() {
    echo "🔧 PATH Optimizer Service Status"
    echo "================================"

    if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
        echo "Status: ✅ Running (PID: $(cat "$PID_FILE"))"
    else
        echo "Status: ❌ Stopped"
    fi

    echo "Check interval: ${CHECK_INTERVAL}s"
    echo "Log file: $LOG_FILE"

    if [[ -f "$LOG_FILE" ]]; then
        echo ""
        echo "Recent activity:"
        tail -5 "$LOG_FILE" | sed 's/^/  /'
    fi
}

# =====================================================
# MAIN COMMAND INTERFACE
# =====================================================

case "${1:-status}" in
    "start")
        start_service
        ;;
    "stop")
        stop_service
        ;;
    "restart")
        stop_service
        sleep 1
        start_service
        ;;
    "status")
        service_status
        ;;
    "optimize")
        optimize_path
        echo "✅ Manual PATH optimization complete"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|optimize}"
        echo ""
        echo "PATH Optimizer Service - Prevents PATH pollution"
        echo "Commands:"
        echo "  start    - Start background service"
        echo "  stop     - Stop background service"
        echo "  restart  - Restart service"
        echo "  status   - Show service status"
        echo "  optimize - Run manual optimization"
        ;;
esac