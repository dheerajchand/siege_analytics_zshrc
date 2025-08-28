# =====================================================
# HADOOP/YARN CONFIGURATION MODULE
# =====================================================
# Only loaded when HADOOP_HOME exists

# Hadoop environment
export HADOOP_CURRENT_VERSION="3.3.6"
export HADOOP_HOME="${HADOOP_HOME:-/opt/homebrew/opt/sdkman-cli/libexec/candidates/hadoop/current}"
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
export LD_LIBRARY_PATH="$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop/"
export HADOOP_LOCAL_JARS="$HADOOP_HOME/share/hadoop/common/lib/"
export HADOOP_DATA_DIR="$HOME/hadoop-data"

# Add Hadoop to PATH
export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"

# YARN configuration
export MAPRED_CONF_DIR="$HADOOP_HOME/etc/hadoop"

# Hadoop + Spark Integration
export HADOOP_CLASSPATH="$HADOOP_HOME/share/hadoop/tools/lib/*:$HADOOP_CLASSPATH"
export SPARK_DIST_CLASSPATH=$(hadoop classpath 2>/dev/null || echo "")

# =====================================================
# HADOOP SERVICE MANAGEMENT
# =====================================================

function start_hadoop {
    echo "🚀 Starting Hadoop services..."
    
    # Initialize directories if needed
    if [[ ! -d "$HADOOP_DATA_DIR/hdfs/namenode" ]]; then
        echo "📁 Initializing Hadoop directories..."
        mkdir -p "$HADOOP_DATA_DIR/hdfs/namenode"
        mkdir -p "$HADOOP_DATA_DIR/hdfs/datanode"
        echo "🔧 Formatting namenode..."
        hdfs namenode -format -force
    fi
    
    # Start services
    echo "🔄 Starting HDFS..."
    start-dfs.sh
    echo "🔄 Starting YARN..."
    start-yarn.sh
    
    sleep 5
    hadoop_status
}

function stop_hadoop {
    echo "🛑 Stopping Hadoop services..."
    stop-yarn.sh 2>/dev/null
    stop-dfs.sh 2>/dev/null
    echo "✅ Hadoop services stopped"
}

function restart_hadoop {
    echo "🔄 Restarting Hadoop services..."
    stop_hadoop && sleep 3 && start_hadoop
}

function hadoop_status {
    echo "📊 Hadoop Services Status:"
    local namenode_count=$(jps | grep NameNode | wc -l)
    local datanode_count=$(jps | grep DataNode | wc -l)
    local resourcemanager_count=$(jps | grep ResourceManager | wc -l)
    local nodemanager_count=$(jps | grep NodeManager | wc -l)
    
    echo "   NameNode: $([ $namenode_count -gt 0 ] && echo '✅ Running' || echo '❌ Stopped')"
    echo "   DataNode: $([ $datanode_count -gt 0 ] && echo '✅ Running' || echo '❌ Stopped')"
    echo "   ResourceManager: $([ $resourcemanager_count -gt 0 ] && echo '✅ Running' || echo '❌ Stopped')"
    echo "   NodeManager: $([ $nodemanager_count -gt 0 ] && echo '✅ Running' || echo '❌ Stopped')"
    
    if [[ $namenode_count -gt 0 ]]; then
        echo ""
        echo "🌐 Web UIs:"
        echo "   HDFS NameNode: http://localhost:9870"
        echo "   YARN ResourceManager: http://localhost:8088"
    fi
}

function test_hadoop_integration {
    echo "🧪 Testing Hadoop integration..."
    
    if ! jps | grep -q "NameNode"; then
        echo "⚠️  Hadoop not running. Starting..."
        start_hadoop
        sleep 5
    fi
    
    echo "🔍 Testing HDFS operations..."
    hdfs dfs -mkdir -p /test 2>/dev/null || echo "   Test directory exists"
    echo "Hello Hadoop!" > /tmp/test_hadoop.txt
    hdfs dfs -put /tmp/test_hadoop.txt /test/ 2>/dev/null || echo "   Test file upload failed"
    
    local content=$(hdfs dfs -cat /test/test_hadoop.txt 2>/dev/null)
    if [[ "$content" == "Hello Hadoop!" ]]; then
        echo "   ✅ HDFS read/write test passed"
    else
        echo "   ❌ HDFS test failed"
    fi
    
    rm -f /tmp/test_hadoop.txt
    hdfs dfs -rm -f /test/test_hadoop.txt 2>/dev/null
    echo "✅ Hadoop integration test completed"
}

# Convenience aliases
alias hstart='start_hadoop'
alias hstop='stop_hadoop'
alias hrestart='restart_hadoop'
alias hstatus='hadoop_status'
alias htest='test_hadoop_integration'

echo "🐘 Hadoop module loaded - $(hadoop version 2>/dev/null | head -1 || echo 'Hadoop ready')"
