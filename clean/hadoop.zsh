#!/usr/bin/env zsh
# =================================================================
# HADOOP - Hadoop & YARN Cluster Management
# =================================================================
# HDFS, YARN, and Hadoop ecosystem management
# =================================================================

# Hadoop environment setup
# Use SDKMAN installation if HADOOP_HOME not already set
if [[ -z "$HADOOP_HOME" ]]; then
    if [[ -d "$HOME/.sdkman/candidates/hadoop/current" ]]; then
        export HADOOP_HOME="$HOME/.sdkman/candidates/hadoop/current"
    elif [[ -d "/opt/homebrew/opt/hadoop/libexec" ]]; then
        export HADOOP_HOME="/opt/homebrew/opt/hadoop/libexec"
    else
        export HADOOP_HOME="/opt/homebrew/opt/hadoop/libexec"  # Default fallback
    fi
fi
export HADOOP_CONF_DIR="${HADOOP_CONF_DIR:-$HADOOP_HOME/etc/hadoop}"
export YARN_CONF_DIR="${YARN_CONF_DIR:-$HADOOP_CONF_DIR}"
export HDFS_NAMENODE_USER="${HDFS_NAMENODE_USER:-$USER}"
export HDFS_DATANODE_USER="${HDFS_DATANODE_USER:-$USER}"
export YARN_RESOURCEMANAGER_USER="${YARN_RESOURCEMANAGER_USER:-$USER}"
export YARN_NODEMANAGER_USER="${YARN_NODEMANAGER_USER:-$USER}"

# Add Hadoop to PATH if available
if [[ -d "$HADOOP_HOME" ]]; then
    # Add to PATH directly (don't rely on path_add function)
    [[ ":$PATH:" != *":$HADOOP_HOME/bin:"* ]] && export PATH="$HADOOP_HOME/bin:$PATH"
    [[ ":$PATH:" != *":$HADOOP_HOME/sbin:"* ]] && export PATH="$HADOOP_HOME/sbin:$PATH"
fi

# Start Hadoop services (HDFS + YARN)
start_hadoop() {
    if [[ ! -d "$HADOOP_HOME" ]]; then
        echo "❌ HADOOP_HOME not found: $HADOOP_HOME"
        echo "Install: brew install hadoop"
        return 1
    fi
    
    echo "🚀 Starting Hadoop services..."
    
    # Check if HDFS needs formatting
    local namenode_dir="${HOME}/hadoop-data/namenode"
    if [[ ! -d "$namenode_dir/current" ]]; then
        echo "📝 Formatting HDFS namenode..."
        # Clean any old data to avoid clusterID mismatch
        rm -rf "${HOME}/hadoop-data/datanode" 2>/dev/null
        rm -rf "${HOME}/hadoop-data/tmp" 2>/dev/null
        hdfs namenode -format -force -nonInteractive
    fi
    
    # Start HDFS using daemon mode (bypasses SSH issues on macOS)
    echo "Starting HDFS NameNode..."
    hdfs --daemon start namenode
    sleep 4
    
    echo "Starting HDFS DataNode..."
    hdfs --daemon start datanode
    sleep 4
    
    # Check if DataNode started (clusterID mismatch detection)
    if ! jps | grep -q "DataNode"; then
        echo "⚠️  DataNode failed to start (likely clusterID mismatch)"
        echo "   Cleaning DataNode data and restarting..."
        rm -rf "${HOME}/hadoop-data/datanode" 2>/dev/null
        hdfs --daemon start datanode
        sleep 3
    fi
    
    # Create HDFS directories if needed
    if hdfs dfs -test -d /user 2>/dev/null; then
        echo "✅ HDFS directories exist"
    else
        echo "📁 Creating HDFS directories..."
        hdfs dfs -mkdir -p /user/$USER
        hdfs dfs -mkdir -p /tmp
        hdfs dfs -chmod 777 /tmp
    fi
    
    # Start YARN
    echo "Starting YARN..."
    "$HADOOP_HOME/sbin/start-yarn.sh"
    sleep 3
    
    echo ""
    echo "✅ Hadoop started"
    echo "HDFS UI: http://localhost:9870"
    echo "YARN UI: http://localhost:8088"
}

# Stop Hadoop services
stop_hadoop() {
    if [[ ! -d "$HADOOP_HOME" ]]; then
        echo "❌ HADOOP_HOME not found"
        return 1
    fi
    
    echo "⏹️  Stopping Hadoop services..."
    
    # Stop using daemon mode (consistent with start)
    hdfs --daemon stop datanode 2>/dev/null
    hdfs --daemon stop namenode 2>/dev/null
    "$HADOOP_HOME/sbin/stop-yarn.sh" 2>/dev/null
    
    echo "✅ Hadoop stopped"
}

# Restart Hadoop
restart_hadoop() {
    stop_hadoop
    sleep 2
    start_hadoop
}

# Show Hadoop status
hadoop_status() {
    echo "🐘 Hadoop Status"
    echo "================"
    
    if [[ ! -d "$HADOOP_HOME" ]]; then
        echo "❌ HADOOP_HOME not found"
        return 1
    fi
    
    echo "HADOOP_HOME: $HADOOP_HOME"
    echo "Version: $(hadoop version 2>/dev/null | head -1)"
    echo ""
    
    # HDFS status
    echo "HDFS:"
    if jps | grep -q NameNode; then
        echo "  ✅ NameNode running (http://localhost:9870)"
    else
        echo "  ❌ NameNode not running"
    fi
    
    if jps | grep -q DataNode; then
        echo "  ✅ DataNode running"
    else
        echo "  ❌ DataNode not running"
    fi
    
    # YARN status
    echo ""
    echo "YARN:"
    if jps | grep -q ResourceManager; then
        echo "  ✅ ResourceManager running (http://localhost:8088)"
    else
        echo "  ❌ ResourceManager not running"
    fi
    
    if jps | grep -q NodeManager; then
        echo "  ✅ NodeManager running"
    else
        echo "  ❌ NodeManager not running"
    fi
    
    # Show running applications
    echo ""
    if command -v yarn >/dev/null 2>&1 && jps | grep -q ResourceManager; then
        local apps=$(yarn application -list 2>/dev/null | grep -c "application_")
        echo "Running applications: $apps"
    fi
}

# List YARN applications
yarn_application_list() {
    if ! command -v yarn >/dev/null 2>&1; then
        echo "❌ YARN not available"
        return 1
    fi
    
    yarn application -list
}

# Kill all YARN applications
yarn_kill_all_apps() {
    echo "🗑️  Killing all YARN applications..."
    
    local app_ids=$(yarn application -list 2>/dev/null | grep "application_" | awk '{print $1}')
    
    if [[ -z "$app_ids" ]]; then
        echo "✅ No running applications"
        return 0
    fi
    
    for app_id in $app_ids; do
        echo "  Killing $app_id..."
        yarn application -kill "$app_id"
    done
    
    echo "✅ All applications killed"
}

# View YARN application logs
yarn_logs() {
    local app_id="${1:-}"
    
    if [[ -z "$app_id" ]]; then
        echo "Usage: yarn_logs <application_id>"
        echo ""
        echo "Recent applications:"
        yarn application -list 2>/dev/null | grep "application_" | head -5
        return 1
    fi
    
    yarn logs -applicationId "$app_id"
}

# Show YARN cluster info
yarn_cluster_info() {
    if ! command -v yarn >/dev/null 2>&1; then
        echo "❌ YARN not available"
        return 1
    fi
    
    echo "🗂️  YARN Cluster Info"
    yarn node -list
}

# HDFS quick commands
hdfs_ls() {
    hdfs dfs -ls "${1:-/user/$USER}"
}

hdfs_put() {
    local local_file="$1"
    local hdfs_path="${2:-/user/$USER/}"
    
    if [[ ! -f "$local_file" ]]; then
        echo "Usage: hdfs_put <local_file> [hdfs_path]"
        return 1
    fi
    
    hdfs dfs -put "$local_file" "$hdfs_path"
}

hdfs_get() {
    local hdfs_file="$1"
    local local_path="${2:-.}"
    
    if [[ -z "$hdfs_file" ]]; then
        echo "Usage: hdfs_get <hdfs_file> [local_path]"
        return 1
    fi
    
    hdfs dfs -get "$hdfs_file" "$local_path"
}

# Remove file from HDFS
hdfs_rm() {
    local hdfs_path="$1"
    
    if [[ -z "$hdfs_path" ]]; then
        echo "Usage: hdfs_rm <hdfs_path>"
        return 1
    fi
    
    hdfs dfs -rm -r "$hdfs_path"
}

# Aliases
alias hstart='start_hadoop'
alias hstop='stop_hadoop'
alias hstatus='hadoop_status'
alias yls='yarn_application_list'
alias ykill='yarn_kill_all_apps'
alias hls='hdfs_ls'

echo "✅ hadoop loaded"




# Rehash to ensure commands are found
rehash 2>/dev/null
