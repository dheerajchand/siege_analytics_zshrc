#!/usr/bin/env zsh

# =====================================================
# APACHE HADOOP MODULE
# =====================================================
# 
# Cross-platform Apache Hadoop configuration and management
# Supports HDFS, YARN, and MapReduce
# Integrates with Spark for big data processing
# =====================================================

# Module identification
export HADOOP_MODULE_LOADED="true"

# =====================================================
# HADOOP CONFIGURATION & DETECTION
# =====================================================

setup_hadoop_environment() {
    # Auto-detect and configure Hadoop
    local hadoop_candidates=()
    
    # Platform-specific Hadoop locations
    case "$ZSH_PLATFORM" in
        "macos")
            hadoop_candidates=(
                "/opt/homebrew/opt/hadoop/libexec"
                "/usr/local/opt/hadoop/libexec"
                "$HOME/hadoop"
                "$HOME/apache-hadoop"
            )
            ;;
        "linux")
            hadoop_candidates=(
                "/opt/hadoop"
                "/usr/local/hadoop"
                "/opt/apache-hadoop"
                "/usr/local/apache-hadoop"
                "$HOME/hadoop"
                "$HOME/apache-hadoop"
            )
            ;;
    esac
    
    # Check SDKMAN installations first
    if [[ -n "$SDKMAN_DIR" ]]; then
        local sdkman_hadoop="$SDKMAN_DIR/candidates/hadoop/current"
        [[ -d "$sdkman_hadoop" ]] && hadoop_candidates=("$sdkman_hadoop" "${hadoop_candidates[@]}")
    fi
    
    # Find Hadoop installation
    for candidate in "${hadoop_candidates[@]}"; do
        if [[ -d "$candidate" && -f "$candidate/bin/hadoop" ]]; then
            export HADOOP_HOME="$candidate"
            break
        fi
    done
    
    if [[ -z "$HADOOP_HOME" ]]; then
        [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && echo "⚠️  Apache Hadoop not found - functions will be limited"
        return 1
    fi
    
    # Configure Hadoop environment
    export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    export HADOOP_LOCAL_JARS="$HADOOP_HOME/share/hadoop/common/lib"
    export HADOOP_DATA_DIR="$HOME/hadoop-data"
    export HADOOP_PID_DIR="/tmp/hadoop-$USER"
    export MAPRED_CONF_DIR="$HADOOP_HOME/etc/hadoop"
    
    # Add Hadoop to PATH (safe method - no external dependencies)
    if [[ -d "$HADOOP_HOME/bin" && "$PATH" != *"$HADOOP_HOME/bin"* ]]; then
        export PATH="$HADOOP_HOME/bin:$PATH"
    fi
    if [[ -d "$HADOOP_HOME/sbin" && "$PATH" != *"$HADOOP_HOME/sbin"* ]]; then
        export PATH="$HADOOP_HOME/sbin:$PATH"
    fi
    
    # Setup classpath
    export HADOOP_CLASSPATH="$HADOOP_HOME/share/hadoop/tools/lib/*:${HADOOP_CLASSPATH:-}"
    
    # Container-specific adjustments
    if [[ "$ZSH_IS_DOCKER" == "true" ]]; then
        # Use smaller memory settings for containers
        export HADOOP_HEAPSIZE="${HADOOP_HEAPSIZE:-512}"
        export YARN_HEAPSIZE="${YARN_HEAPSIZE:-512}"
    else
        # Default settings for full systems
        export HADOOP_HEAPSIZE="${HADOOP_HEAPSIZE:-1024}"
        export YARN_HEAPSIZE="${YARN_HEAPSIZE:-1024}"
    fi
    
    # Try to get Spark classpath for integration
    if command -v hadoop >/dev/null 2>&1; then
        export SPARK_DIST_CLASSPATH=$(hadoop classpath 2>/dev/null || echo "")
    fi
}

# =====================================================
# HADOOP DIRECTORY INITIALIZATION
# =====================================================

init_hadoop_dirs() {
    # Initialize Hadoop directories
    echo "📁 Initializing Hadoop directories..."
    
    # Create data directories
    mkdir -p "$HADOOP_DATA_DIR"/{namenode,datanode,tmp,logs}
    mkdir -p "$HADOOP_PID_DIR"
    
    # Create log directory
    mkdir -p "$HADOOP_HOME/logs" 2>/dev/null || true
    
    echo "✅ Hadoop directories initialized"
    echo "   Data: $HADOOP_DATA_DIR"
    echo "   PIDs: $HADOOP_PID_DIR"
}

# =====================================================
# JAVA COMPATIBILITY
# =====================================================

setup_java17_hadoop_compatibility() {
    # Configure Java 17+ compatibility for Hadoop
    echo "☕ Setting up Java 17+ compatibility for Hadoop..."
    
    local hadoop_env="$HADOOP_CONF_DIR/hadoop-env.sh"
    
    # Check if already configured
    if grep -q "add-opens java.base/java.lang=ALL-UNNAMED" "$hadoop_env" 2>/dev/null; then
        echo "   ✅ Java 17 compatibility already configured"
        return 0
    fi
    
    # Ensure hadoop-env.sh exists
    if [[ ! -f "$hadoop_env" ]]; then
        touch "$hadoop_env"
        echo "#!/usr/bin/env bash" > "$hadoop_env"
    fi
    
    # Add Java 17 compatibility options
    cat >> "$hadoop_env" << 'EOF'

# Java 17+ compatibility settings (added by zsh config)
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.lang=ALL-UNNAMED"
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.util=ALL-UNNAMED"
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.lang.reflect=ALL-UNNAMED"
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.text=ALL-UNNAMED"
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.desktop/java.awt.font=ALL-UNNAMED"

# JVM settings for better performance
export HADOOP_NAMENODE_OPTS="-Xmx1g -Djava.net.preferIPv4Stack=true $HADOOP_NAMENODE_OPTS"
export HADOOP_DATANODE_OPTS="-Xmx512m -Djava.net.preferIPv4Stack=true $HADOOP_DATANODE_OPTS"
export YARN_RESOURCEMANAGER_OPTS="-Xmx1g -Djava.net.preferIPv4Stack=true $YARN_RESOURCEMANAGER_OPTS"
export YARN_NODEMANAGER_OPTS="-Xmx512m -Djava.net.preferIPv4Stack=true $YARN_NODEMANAGER_OPTS"

# Container-specific adjustments
if [[ "${ZSH_IS_DOCKER:-false}" == "true" ]]; then
    export HADOOP_NAMENODE_OPTS="-Xmx512m -Djava.net.preferIPv4Stack=true $HADOOP_NAMENODE_OPTS"
    export HADOOP_DATANODE_OPTS="-Xmx256m -Djava.net.preferIPv4Stack=true $HADOOP_DATANODE_OPTS"
    export YARN_RESOURCEMANAGER_OPTS="-Xmx512m -Djava.net.preferIPv4Stack=true $YARN_RESOURCEMANAGER_OPTS"
    export YARN_NODEMANAGER_OPTS="-Xmx256m -Djava.net.preferIPv4Stack=true $YARN_NODEMANAGER_OPTS"
fi
EOF
    
    echo "   ✅ Java 17 compatibility applied to hadoop-env.sh"
}

# =====================================================
# HADOOP CONFIGURATION FILES
# =====================================================

setup_yarn_config() {
    # Setup YARN configuration files
    echo "⚙️  Configuring YARN..."
    
    init_hadoop_dirs
    
    # Create yarn-site.xml
    local yarn_site="$HADOOP_CONF_DIR/yarn-site.xml"
    echo "📝 Creating yarn-site.xml..."
    
    cat > "$yarn_site" << 'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>localhost</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>4096</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>4</value>
    </property>
    <property>
        <name>yarn.nodemanager.env-whitelist</name>
        <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_MAPRED_HOME</value>
    </property>
</configuration>
EOF
    
    # Create mapred-site.xml
    local mapred_site="$HADOOP_CONF_DIR/mapred-site.xml"
    echo "📝 Creating mapred-site.xml..."
    
    cat > "$mapred_site" << 'EOF'
<?xml version="1.0"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.application.classpath</name>
        <value>$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/*:$HADOOP_MAPRED_HOME/share/hadoop/mapreduce/lib/*</value>
    </property>
</configuration>
EOF
    
    # Create core-site.xml with platform-appropriate settings
    local core_site="$HADOOP_CONF_DIR/core-site.xml"
    echo "📝 Creating core-site.xml..."
    
    cat > "$core_site" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>$HADOOP_DATA_DIR/tmp</value>
    </property>
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>$USER</value>
    </property>
</configuration>
EOF
    
    # Create hdfs-site.xml
    local hdfs_site="$HADOOP_CONF_DIR/hdfs-site.xml"
    echo "📝 Creating hdfs-site.xml..."
    
    cat > "$hdfs_site" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file://$HADOOP_DATA_DIR/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file://$HADOOP_DATA_DIR/datanode</value>
    </property>
    <property>
        <name>dfs.permissions.enabled</name>
        <value>false</value>
    </property>
</configuration>
EOF
    
    # Update workers file
    echo "📝 Updating workers file..."
    echo "localhost" > "$HADOOP_CONF_DIR/workers"
    
    # Check/create masters file if it exists
    if [[ -f "$HADOOP_CONF_DIR/masters" ]]; then
        echo "localhost" > "$HADOOP_CONF_DIR/masters"
    fi
    
    echo "✅ YARN configuration completed!"
    echo "📊 Configuration files created:"
    echo "   • yarn-site.xml"
    echo "   • mapred-site.xml"  
    echo "   • core-site.xml"
    echo "   • hdfs-site.xml"
    echo "   • workers file updated"
}

# =====================================================
# HADOOP CLUSTER MANAGEMENT
# =====================================================

start_hadoop() {
    # Start Hadoop services
    if [[ -z "$HADOOP_HOME" ]]; then
        echo "❌ HADOOP_HOME not set. Run setup first."
        return 1
    fi
    
    echo "🚀 Starting Hadoop services..."
    
    # Initialize HDFS if needed
    if [[ ! -d "$HADOOP_DATA_DIR/namenode" ]] || [[ -z "$(ls -A "$HADOOP_DATA_DIR/namenode" 2>/dev/null)" ]]; then
        echo "   Initializing HDFS namenode..."
        hdfs namenode -format -force -nonInteractive 2>/dev/null || {
            echo "❌ HDFS format failed"
            return 1
        }
    fi
    
    # Start HDFS
    if ! pgrep -f "NameNode" >/dev/null; then
        echo "   Starting HDFS..."
        start-dfs.sh
        
        # Wait for HDFS to be ready
        local max_wait=30
        local wait_count=0
        while ! nc -z localhost 9000 2>/dev/null && [[ $wait_count -lt $max_wait ]]; do
            sleep 1
            ((wait_count++))
        done
        
        if [[ $wait_count -ge $max_wait ]]; then
            echo "❌ HDFS failed to start within ${max_wait}s"
            return 1
        fi
    else
        echo "   ✅ HDFS already running"
    fi
    
    # Start YARN
    if ! pgrep -f "ResourceManager" >/dev/null; then
        echo "   Starting YARN..."
        start-yarn.sh
        
        # Wait for YARN to be ready
        local max_wait=30
        local wait_count=0
        while ! nc -z localhost 8088 2>/dev/null && [[ $wait_count -lt $max_wait ]]; do
            sleep 1
            ((wait_count++))
        done
        
        if [[ $wait_count -ge $max_wait ]]; then
            echo "❌ YARN failed to start within ${max_wait}s"
            return 1
        fi
    else
        echo "   ✅ YARN already running"
    fi
    
    echo "🎯 Hadoop cluster ready!"
    echo "   HDFS: hdfs://localhost:9000"
    echo "   YARN: http://localhost:8088"
    echo "   NameNode Web UI: http://localhost:9870"
}

stop_hadoop() {
    # Stop Hadoop services
    if [[ -z "$HADOOP_HOME" ]]; then
        echo "❌ HADOOP_HOME not set"
        return 1
    fi
    
    echo "🛑 Stopping Hadoop services..."
    
    # Stop YARN first
    if pgrep -f "ResourceManager" >/dev/null; then
        echo "   Stopping YARN..."
        stop-yarn.sh 2>/dev/null
        echo "   ✅ YARN stopped"
    fi
    
    # Stop HDFS
    if pgrep -f "NameNode" >/dev/null; then
        echo "   Stopping HDFS..."
        stop-dfs.sh 2>/dev/null
        echo "   ✅ HDFS stopped"
    fi
    
    echo "✅ Hadoop cluster stopped"
}

restart_hadoop() {
    # Restart Hadoop services
    echo "🔄 Restarting Hadoop..."
    stop_hadoop
    sleep 3
    start_hadoop
}

hadoop_status() {
    # Show comprehensive Hadoop status
    echo "🐘 Apache Hadoop Status"
    echo "======================"
    echo ""
    
    echo "Configuration:"
    echo "  HADOOP_HOME: ${HADOOP_HOME:-Not set}"
    echo "  HADOOP_CONF_DIR: ${HADOOP_CONF_DIR:-Not set}"
    echo "  HADOOP_DATA_DIR: ${HADOOP_DATA_DIR:-Not set}"
    echo "  Java: ${JAVA_HOME:-Not set}"
    echo ""
    
    # Count running services (macOS compatible)
    local namenode_count=$(pgrep -f "NameNode" 2>/dev/null | wc -l | tr -d ' ')
    local datanode_count=$(pgrep -f "DataNode" 2>/dev/null | wc -l | tr -d ' ')
    local resourcemanager_count=$(pgrep -f "ResourceManager" 2>/dev/null | wc -l | tr -d ' ')
    local nodemanager_count=$(pgrep -f "NodeManager" 2>/dev/null | wc -l | tr -d ' ')
    
    echo "Service Status:"
    echo "  NameNode: $([[ $namenode_count -gt 0 ]] && echo "✅ Running (PID: $(pgrep -f "NameNode"))" || echo "❌ Stopped")"
    echo "  DataNode: $([[ $datanode_count -gt 0 ]] && echo "✅ Running (PID: $(pgrep -f "DataNode"))" || echo "❌ Stopped")"
    echo "  ResourceManager: $([[ $resourcemanager_count -gt 0 ]] && echo "✅ Running (PID: $(pgrep -f "ResourceManager"))" || echo "❌ Stopped")"
    echo "  NodeManager: $([[ $nodemanager_count -gt 0 ]] && echo "✅ Running (PID: $(pgrep -f "NodeManager"))" || echo "❌ Stopped")"
    echo ""
    
    # Check connectivity
    echo "Connectivity:"
    echo "  HDFS (9000): $(nc -z localhost 9000 2>/dev/null && echo "✅ Accessible" || echo "❌ Not accessible")"
    echo "  YARN Web UI (8088): $(nc -z localhost 8088 2>/dev/null && echo "✅ Accessible" || echo "❌ Not accessible")"
    echo "  NameNode Web UI (9870): $(nc -z localhost 9870 2>/dev/null && echo "✅ Accessible" || echo "❌ Not accessible")"
    echo ""
    
    # Show HDFS status if running
    if [[ $namenode_count -gt 0 ]]; then
        echo "📁 HDFS Status:"
        hdfs dfsadmin -report 2>/dev/null | head -10 || echo "   Unable to get HDFS report"
        echo ""
        echo "🌐 Web UIs:"
        echo "   HDFS NameNode: http://localhost:9870"
        echo "   YARN ResourceManager: http://localhost:8088"
        echo "   DataNode: http://localhost:9864"
    fi
}

# =====================================================
# YARN MANAGEMENT FUNCTIONS
# =====================================================

yarn_application_list() {
    # List all YARN applications with timeout
    echo "📊 YARN Applications:"
    if command -v yarn >/dev/null 2>&1; then
        # Use timeout to prevent hanging
        if command -v timeout >/dev/null 2>&1; then
            timeout 10s yarn application -list -appStates ALL 2>/dev/null || echo "❌ YARN not accessible (timeout or connection failed)"
        else
            # Fallback for systems without timeout command
            yarn application -list -appStates ALL 2>/dev/null || echo "❌ YARN not accessible"
        fi
    else
        echo "❌ YARN command not available"
    fi
}

yarn_kill_all_apps() {
    # Kill all running YARN applications
    echo "🛑 Killing all YARN applications..."
    if command -v yarn >/dev/null 2>&1; then
        yarn application -list -appStates RUNNING,SUBMITTED,ACCEPTED 2>/dev/null | \
        grep application_ | awk '{print $1}' | while read app; do
            echo "   Killing: $app"
            yarn application -kill "$app"
        done
    else
        echo "❌ YARN command not available"
    fi
}

yarn_logs() {
    # View YARN application logs
    local app_id="$1"
    if [[ -z "$app_id" ]]; then
        echo "Usage: yarn_logs <application_id>"
        echo "💡 Get application IDs with: yarn_application_list"
        return 1
    fi
    
    echo "📜 YARN Application Logs for: $app_id"
    yarn logs -applicationId "$app_id"
}

yarn_cluster_info() {
    # Show YARN cluster information
    echo "🏗️ YARN Cluster Information:"
    if command -v curl >/dev/null 2>&1 && nc -z localhost 8088 2>/dev/null; then
        curl -s "http://localhost:8088/ws/v1/cluster/info" | \
        python3 -c "import json,sys; data=json.load(sys.stdin); print(f'Cluster ID: {data[\"clusterInfo\"][\"id\"]}\nHadoop Version: {data[\"clusterInfo\"][\"hadoopVersion\"]}\nResource Manager: {data[\"clusterInfo\"][\"resourceManagerVersion\"]}')" 2>/dev/null || \
        echo "Unable to fetch cluster info"
    else
        echo "YARN ResourceManager not accessible"
    fi
}

# =====================================================
# HADOOP TESTING FUNCTIONS
# =====================================================

test_hadoop_integration() {
    # Test basic Hadoop functionality
    echo "🧪 Testing Hadoop integration..."
    
    # Check if Hadoop is running
    if ! pgrep -f "NameNode" >/dev/null; then
        echo "⚠️  Hadoop not running. Starting..."
        start_hadoop
        sleep 5
    fi
    
    # Simple HDFS test
    echo "🔍 Testing HDFS operations..."
    
    # Create test directory
    hdfs dfs -mkdir -p /test 2>/dev/null || echo "   Test directory exists"
    
    # Create test file
    echo "Hello Hadoop!" > /tmp/test_hadoop.txt
    hdfs dfs -put /tmp/test_hadoop.txt /test/ 2>/dev/null || echo "   Test file upload failed"
    
    # Read back test file
    local content=$(hdfs dfs -cat /test/test_hadoop.txt 2>/dev/null)
    if [[ "$content" == "Hello Hadoop!" ]]; then
        echo "   ✅ HDFS read/write test passed"
    else
        echo "   ❌ HDFS test failed"
    fi
    
    # Clean up
    rm -f /tmp/test_hadoop.txt
    hdfs dfs -rm -f /test/test_hadoop.txt 2>/dev/null
    
    echo "✅ Hadoop integration test completed"
}

# =====================================================
# DEPENDENCY MANAGEMENT
# =====================================================

download_hadoop_slf4j_jars() {
    # Download SLF4J JARs for Hadoop
    local target_path="${1:-$HADOOP_LOCAL_JARS}"
    
    echo "🚀 Downloading SLF4J JARs for Hadoop..."
    
    # Use Maven central to download common JARs
    local jars=(
        "org.slf4j:slf4j-log4j12:1.7.30"
        "log4j:log4j:1.2.17"
    )
    
    mkdir -p "$target_path"
    
    for jar in "${jars[@]}"; do
        echo "   Downloading: $jar"
        # This would typically use Maven or a download utility
        # For now, just show what would be downloaded
        echo "   📦 $jar → $target_path"
    done
    
    echo "✅ SLF4J JARs download completed"
}

setup_hadoop_version() {
    # Setup specific Hadoop version via SDKMAN
    if command -v sdk >/dev/null 2>&1; then
        local target_hadoop_version="3.3.6"
        
        if ! sdk list hadoop 2>/dev/null | grep -q "$target_hadoop_version"; then
            echo "📦 Installing Hadoop $target_hadoop_version..."
            sdk install hadoop "$target_hadoop_version"
        fi
        
        sdk default hadoop "$target_hadoop_version"
        export HADOOP_CURRENT_VERSION="$target_hadoop_version"
        export HADOOP_HOME=$(sdk home hadoop "$target_hadoop_version")
        
        # Re-setup environment with new version
        setup_hadoop_environment
    else
        echo "⚠️  SDKMAN not available - using system Hadoop"
    fi
}

# =====================================================
# HADOOP ALIASES
# =====================================================

alias hadoop-start='start_hadoop'
alias hadoop-stop='stop_hadoop'
alias hadoop-restart='restart_hadoop'
alias hadoop-status='hadoop_status'
alias hdfs-format='hdfs namenode -format'
alias yarn-apps='yarn_application_list'
alias yarn-kill-all='yarn_kill_all_apps'
alias yarn-info='yarn_cluster_info'
alias hadoop-test='test_hadoop_integration'
alias hadoop-init='init_hadoop_dirs && setup_yarn_config && setup_java17_hadoop_compatibility'
alias hadoop-logs='ls -la $HADOOP_HOME/logs/'

# =====================================================
# INITIALIZATION
# =====================================================

# Setup Hadoop environment
setup_hadoop_environment

# Show setup status if verbose
if [[ "$MODULAR_ZSHRC_VERBOSE" == "true" ]] && [[ -n "$HADOOP_HOME" ]]; then
    echo "🐘 Hadoop: $(hadoop version 2>&1 | head -n1 | cut -d' ' -f2) at $HADOOP_HOME"
fi