#!/usr/bin/env zsh
# =====================================================
# SERVICES MODULE - Background services infrastructure
# =====================================================
#
# Purpose: Background service management for ZSH configuration system
# Provides: Service lifecycle management, monitoring, logging
# Dependencies: centralized variables, system module
# =====================================================

echo "⚙️  Loading Services module..."

# Load centralized variables
[[ -f "$ZSH_CONFIG_DIR/config/variables.zsh" ]] && source "$ZSH_CONFIG_DIR/config/variables.zsh"

# =====================================================
# SERVICE INFRASTRUCTURE
# =====================================================

# Service directories
ZSH_SERVICES_DIR="${ZSH_SERVICES_DIR:-$ZSH_CONFIG_DIR/services}"
ZSH_LOGS_DIR="${ZSH_LOGS_DIR:-$ZSH_CONFIG_DIR/logs}"
ZSH_RUN_DIR="${ZSH_CONFIG_DIR}/run"

# Ensure service directories exist
mkdir -p "$ZSH_SERVICES_DIR" "$ZSH_LOGS_DIR" "$ZSH_RUN_DIR"

# =====================================================
# CORE SERVICE FUNCTIONS
# =====================================================

# Purpose: Log message with timestamp to service log
# Arguments: $1 - service name, $2 - log message
# Returns: 0 always
# Usage: service_log "path-optimizer" "Service started"
service_log() {
    local service_name="$1"
    local message="$2"
    local log_file="$ZSH_LOGS_DIR/${service_name}.log"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$log_file"
}

# Purpose: Check if service is running
# Arguments: $1 - service name
# Returns: 0 if running, 1 if not running
# Usage: if service_is_running "path-optimizer"; then echo "Running"; fi
service_is_running() {
    local service_name="$1"
    local pid_file="$ZSH_RUN_DIR/${service_name}.pid"

    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        else
            # Clean up stale PID file
            rm -f "$pid_file"
            return 1
        fi
    fi

    return 1
}

# Purpose: Get service PID if running
# Arguments: $1 - service name
# Returns: Prints PID if running, returns 0 if found, 1 if not
# Usage: pid=$(service_get_pid "path-optimizer")
service_get_pid() {
    local service_name="$1"
    local pid_file="$ZSH_RUN_DIR/${service_name}.pid"

    if service_is_running "$service_name"; then
        cat "$pid_file"
        return 0
    fi

    return 1
}

# Purpose: Stop a service by name
# Arguments: $1 - service name
# Returns: 0 on success, 1 if not running or error
# Usage: service_stop "path-optimizer"
service_stop() {
    local service_name="$1"
    local pid_file="$ZSH_RUN_DIR/${service_name}.pid"

    if service_is_running "$service_name"; then
        local pid=$(cat "$pid_file")
        echo "🛑 Stopping $service_name service (PID: $pid)..."

        if kill "$pid" 2>/dev/null; then
            # Wait for process to stop
            local attempts=0
            while kill -0 "$pid" 2>/dev/null && [[ $attempts -lt 10 ]]; do
                sleep 1
                ((attempts++))
            done

            if kill -0 "$pid" 2>/dev/null; then
                echo "⚠️  Process still running, forcing stop..."
                kill -9 "$pid" 2>/dev/null
            fi

            rm -f "$pid_file"
            service_log "$service_name" "Service stopped"
            echo "✅ $service_name service stopped"
            return 0
        else
            echo "❌ Failed to stop $service_name service"
            return 1
        fi
    else
        echo "⚠️  $service_name service is not running"
        return 1
    fi
}

# Purpose: Show status of a service
# Arguments: $1 - service name
# Returns: 0 always
# Usage: service_status "path-optimizer"
service_status() {
    local service_name="$1"
    local pid_file="$ZSH_RUN_DIR/${service_name}.pid"
    local log_file="$ZSH_LOGS_DIR/${service_name}.log"

    echo "🔧 $service_name Service Status"
    echo "================================"

    if service_is_running "$service_name"; then
        local pid=$(cat "$pid_file")
        echo "✅ Status: RUNNING (PID: $pid)"

        # Show process info if available
        if ps -p "$pid" -o pid,ppid,etime,command 2>/dev/null | tail -n +2; then
            echo ""
        fi
    else
        echo "❌ Status: STOPPED"
    fi

    echo "📁 PID File: $pid_file"
    echo "📋 Log File: $log_file"

    if [[ -f "$log_file" ]]; then
        local log_size=$(wc -l < "$log_file" 2>/dev/null || echo "0")
        echo "📊 Log Lines: $log_size"

        if [[ $log_size -gt 0 ]]; then
            echo ""
            echo "📄 Recent Log Entries:"
            tail -5 "$log_file" | sed 's/^/  /'
        fi
    else
        echo "📊 Log Lines: 0 (no log file)"
    fi
}

# Purpose: List all available services
# Arguments: None
# Returns: 0 always
# Usage: service_list
service_list() {
    echo "📋 Available Services"
    echo "===================="

    local services_found=0

    # Check for service scripts
    if [[ -d "$ZSH_SERVICES_DIR" ]]; then
        for service_file in "$ZSH_SERVICES_DIR"/*.zsh; do
            if [[ -f "$service_file" ]]; then
                local service_name=$(basename "$service_file" .zsh)
                local status="STOPPED"

                if service_is_running "$service_name"; then
                    status="RUNNING"
                fi

                echo "  📦 $service_name - $status"
                ((services_found++))
            fi
        done
    fi

    # Check for built-in services
    local builtin_services=("path-optimizer" "environment-setup")
    for service_name in "${builtin_services[@]}"; do
        local status="STOPPED"

        if service_is_running "$service_name"; then
            status="RUNNING"
        fi

        echo "  🔧 $service_name (built-in) - $status"
        ((services_found++))
    done

    if [[ $services_found -eq 0 ]]; then
        echo "  ❌ No services found"
    fi

    echo ""
    echo "💡 Usage:"
    echo "  service_start <name>    # Start a service"
    echo "  service_stop <name>     # Stop a service"
    echo "  service_status <name>   # Show service status"
    echo "  service_logs <name>     # View service logs"
}

# Purpose: View service logs
# Arguments: $1 - service name, $2 - optional number of lines (default: 20)
# Returns: 0 if log exists, 1 if not found
# Usage: service_logs "path-optimizer" [50]
service_logs() {
    local service_name="$1"
    local lines="${2:-20}"
    local log_file="$ZSH_LOGS_DIR/${service_name}.log"

    if [[ -f "$log_file" ]]; then
        echo "📋 $service_name Service Logs (last $lines lines)"
        echo "================================================"
        tail -n "$lines" "$log_file"
        echo ""
        echo "💡 Full log: $log_file"
    else
        echo "❌ No log file found for service: $service_name"
        echo "📁 Expected location: $log_file"
        return 1
    fi
}

# =====================================================
# BUILT-IN SERVICES
# =====================================================

# Purpose: Start PATH optimizer service
# Arguments: None
# Returns: 0 on success, 1 if already running or error
# Usage: start_path_optimizer
start_path_optimizer() {
    local service_name="path-optimizer"

    if service_is_running "$service_name"; then
        echo "❌ PATH optimizer service already running (PID: $(service_get_pid "$service_name"))"
        return 1
    fi

    echo "🚀 Starting PATH optimizer service..."
    service_log "$service_name" "Service starting"

    # Background monitoring loop
    (
        echo $$ > "$ZSH_RUN_DIR/${service_name}.pid"
        local check_interval=300  # 5 minutes

        while true; do
            # PATH optimization logic
            local original_length=${#PATH}

            if [[ $original_length -gt 1500 ]]; then
                service_log "$service_name" "PATH length ($original_length) exceeds threshold, cleaning..."

                # Backup current PATH
                echo "$PATH" > "$ZSH_CONFIG_DIR/.path_backup_$(date +%Y%m%d_%H%M%S)"

                # Use system module's path_clean if available, otherwise basic cleanup
                if command -v path_clean >/dev/null 2>&1; then
                    path_clean --auto >/dev/null 2>&1
                else
                    # Basic PATH deduplication
                    local new_path=""
                    local IFS=":"

                    for dir in $PATH; do
                        [[ -z "$dir" ]] && continue
                        [[ ":$new_path:" == *":$dir:"* ]] && continue
                        [[ ! -d "$dir" ]] && continue

                        if [[ -z "$new_path" ]]; then
                            new_path="$dir"
                        else
                            new_path="$new_path:$dir"
                        fi
                    done

                    export PATH="$new_path"
                fi

                local new_length=${#PATH}
                service_log "$service_name" "PATH optimized: $original_length → $new_length chars"
            else
                service_log "$service_name" "PATH length ($original_length) is healthy"
            fi

            sleep $check_interval
        done
    ) &

    local pid=$!
    echo "✅ PATH optimizer service started (PID: $pid)"
    service_log "$service_name" "Service started with PID $pid"
}

# Purpose: Start environment setup service
# Arguments: None
# Returns: 0 on success, 1 if already running or error
# Usage: start_environment_setup
start_environment_setup() {
    local service_name="environment-setup"

    if service_is_running "$service_name"; then
        echo "❌ Environment setup service already running (PID: $(service_get_pid "$service_name"))"
        return 1
    fi

    echo "🚀 Starting environment setup service..."
    service_log "$service_name" "Service starting"

    # Background caching loop
    (
        echo $$ > "$ZSH_RUN_DIR/${service_name}.pid"
        local cache_interval=1800  # 30 minutes

        while true; do
            service_log "$service_name" "Refreshing environment cache..."

            # Cache common tool locations
            local cache_file="$ZSH_CACHE_DIR/environment_cache.zsh"
            mkdir -p "$ZSH_CACHE_DIR"

            {
                echo "# Environment cache generated $(date)"
                echo "# Cached tool locations"

                for tool in git python3 node npm java mvn gradle docker; do
                    if command -v "$tool" >/dev/null 2>&1; then
                        echo "export CACHED_${tool^^}_PATH=\"$(command -v "$tool")\""
                    fi
                done
            } > "$cache_file"

            service_log "$service_name" "Environment cache updated"
            sleep $cache_interval
        done
    ) &

    local pid=$!
    echo "✅ Environment setup service started (PID: $pid)"
    service_log "$service_name" "Service started with PID $pid"
}

# =====================================================
# SERVICE MANAGEMENT INTERFACE
# =====================================================

# Purpose: Start a service by name
# Arguments: $1 - service name
# Returns: 0 on success, 1 on error
# Usage: service_start "path-optimizer"
service_start() {
    local service_name="$1"

    if [[ -z "$service_name" ]]; then
        echo "❌ Usage: service_start <service_name>"
        echo ""
        service_list
        return 1
    fi

    case "$service_name" in
        "path-optimizer")
            start_path_optimizer
            ;;
        "environment-setup")
            start_environment_setup
            ;;
        *)
            # Try to find and execute service script
            local service_script="$ZSH_SERVICES_DIR/${service_name}.zsh"
            if [[ -f "$service_script" ]]; then
                echo "🚀 Starting custom service: $service_name"
                source "$service_script"
            else
                echo "❌ Unknown service: $service_name"
                echo ""
                service_list
                return 1
            fi
            ;;
    esac
}

# =====================================================
# CLEANUP AND MAINTENANCE
# =====================================================

# Purpose: Clean up old log files and service data
# Arguments: $1 - optional days to keep (default: 7)
# Returns: 0 always
# Usage: service_cleanup [days]
service_cleanup() {
    local days="${1:-7}"

    echo "🧹 Cleaning up service data older than $days days..."

    # Clean old log files
    if [[ -d "$ZSH_LOGS_DIR" ]]; then
        find "$ZSH_LOGS_DIR" -name "*.log" -mtime +$days -delete 2>/dev/null
        echo "✅ Cleaned old log files"
    fi

    # Clean old PATH backups
    find "$ZSH_CONFIG_DIR" -name ".path_backup_*" -mtime +$days -delete 2>/dev/null
    echo "✅ Cleaned old PATH backups"

    # Clean old cache files
    if [[ -d "$ZSH_CACHE_DIR" ]]; then
        find "$ZSH_CACHE_DIR" -name "*.cache" -mtime +$days -delete 2>/dev/null
        echo "✅ Cleaned old cache files"
    fi

    echo "🎉 Service cleanup complete"
}

# =====================================================
# ALIASES
# =====================================================

alias services='service_list'
alias svc-start='service_start'
alias svc-stop='service_stop'
alias svc-status='service_status'
alias svc-logs='service_logs'
alias svc-list='service_list'

echo "✅ Services module loaded successfully"

# =====================================================
# COMPLETION
# =====================================================
export SERVICES_MODULE_LOADED=true