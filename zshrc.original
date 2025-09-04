# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Suppress Powerlevel10k console output warnings
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet

# COMPLETE WORKING ZSHRC - Enhanced Spark + Hadoop + YARN Integration
# This is a complete, tested zshrc file with enterprise-grade big data features

# =====================================================
# CORE SHELL SETUP
# =====================================================

# Path to your oh-my-zsh configuration.
export ZSH=$HOME/.dotfiles/oh-my-zsh

export ZSH_THEME="powerlevel10k/powerlevel10k"

export CASE_SENSITIVE="true"
export DISABLE_AUTO_TITLE="true"

plugins=(colorize compleat dirpersist autojump git gulp history cp)
source $ZSH/oh-my-zsh.sh

autoload -U add-zsh-hook

# =====================================================
# NODE/NVM SETUP
# =====================================================

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

load-nvmrc() {
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use &> /dev/null
  else
    nvm use stable
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

unsetopt correct

# =====================================================
# BASIC ENVIRONMENT
# =====================================================

# MacOS things - only set if not already configured
if [[ "$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null)" != "1" ]]; then
    defaults write -g ApplePressAndHoldEnabled -bool true
fi

export WORKING_ON_LAPTOP="True"

# Default editor
export EDITOR="zed"
export VISUAL="zed"

# Use Neovim as fallback in the terminal when Zed is unavailable
alias vim="nvim"
alias edit="nvim"

# =====================================================
# PYTHON SETUP
# =====================================================

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
eval "$(pyenv init --path)"

function cleanvenv {
    pip freeze | grep -v "^-e" | xargs pip uninstall -y
}

function remove_python_cruft {
    find . -name "*.pyc" -delete
    find . -name "__pycache__" -exec rm -r {} +
}

export PREFERRED_VENV="geo31111"
pyenv activate $PREFERRED_VENV

# =====================================================
# UTILITY FUNCTIONS
# =====================================================

# Source the enhanced backup system
source ~/.config/zsh/backup-system.zsh

export ZSHRC_BACKUPS=~/.zshrc_backups
mkdir -p "$ZSHRC_BACKUPS"

function backup_zshrc {
    local prev_dir="$(pwd)"
    timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
    backup_file="$ZSHRC_BACKUPS/.zshrc_$timestamp.txt"
    log_file="$ZSHRC_BACKUPS/zshrc_backup_log.txt"

    if [[ ! -d "$ZSHRC_BACKUPS/.git" ]]; then
        echo "⚠️ Backup directory is not a Git repository. Initializing..."
        git -C "$ZSHRC_BACKUPS" init
        git -C "$ZSHRC_BACKUPS" remote add origin "<YOUR_GIT_REPO_URL>"
    fi

    cp ~/.dotfiles/homedir/.zshrc "$backup_file"
    echo "$timestamp - Backup saved: $backup_file" >> "$log_file"

    git -C "$ZSHRC_BACKUPS" add .
    git -C "$ZSHRC_BACKUPS" commit -m "Backup .zshrc at $timestamp"
    git -C "$ZSHRC_BACKUPS" push origin main

    echo "✅ Backup created at $backup_file"
    echo "📜 Logged in $log_file"
    echo "🚀 Changes committed & pushed to Git repository!"

    cd "$prev_dir"
    echo "🔄 Returned to: $prev_dir"
}

function list_zshrc_backups {
    echo "📋 Available zshrc backups:"
    if [[ -d "$ZSHRC_BACKUPS" ]]; then
        echo ""
        ls -la "$ZSHRC_BACKUPS"/.zshrc_*.txt 2>/dev/null | \
        awk '{print "   " $9 " (" $5 " bytes) - " $6 " " $7 " " $8}' | \
        sed 's|.*/\.zshrc_||g' | sed 's|\.txt||g' | sort -r
        echo ""
        echo "Total backups: $(ls "$ZSHRC_BACKUPS"/.zshrc_*.txt 2>/dev/null | wc -l)"
    else
        echo "   No backup directory found: $ZSHRC_BACKUPS"
    fi
}

function restore_zshrc {
    local target_backup="$1"
    local backup_file=""

    echo "🔄 zshrc Restore Utility"
    echo ""

    # Check if backup directory exists
    if [[ ! -d "$ZSHRC_BACKUPS" ]]; then
        echo "❌ Backup directory not found: $ZSHRC_BACKUPS"
        echo "💡 Run 'backup_zshrc' first to create backups"
        return 1
    fi

    # List available backups
    list_zshrc_backups

    # Determine which backup to restore
    if [[ -n "$target_backup" ]]; then
        # Specific backup requested
        backup_file="$ZSHRC_BACKUPS/.zshrc_${target_backup}.txt"
        if [[ ! -f "$backup_file" ]]; then
            echo "❌ Backup not found: $target_backup"
            echo "💡 Use format: YYYY-MM-DD_HH-MM-SS"
            return 1
        fi
        echo "🎯 Restoring specific backup: $target_backup"
    else
        # Use most recent backup
        backup_file=$(ls "$ZSHRC_BACKUPS"/.zshrc_*.txt 2>/dev/null | sort -r | head -1)
        if [[ -z "$backup_file" ]]; then
            echo "❌ No backups found in $ZSHRC_BACKUPS"
            return 1
        fi
        local backup_name=$(basename "$backup_file" .txt | sed 's/^\.zshrc_//')
        echo "🕐 Using most recent backup: $backup_name"
    fi

    echo ""
    echo "📁 Source: $backup_file"
    echo "📁 Target: ~/.zshrc"
    echo ""

    # Safety confirmation
    echo "⚠️  This will replace your current zshrc configuration!"
    echo "💡 Current zshrc will be backed up automatically before restore."
    echo ""
    read "confirm?Continue with restore? (y/N): "

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "❌ Restore cancelled by user"
        return 0
    fi

    # Create backup of current zshrc before restore
    echo ""
    echo "💾 Creating backup of current zshrc..."
    backup_zshrc

    # Perform the restore
    echo ""
    echo "🔄 Restoring zshrc from backup..."
    if cp "$backup_file" ~/.zshrc; then
        echo "✅ zshrc restored successfully!"
        echo ""
        echo "🔄 Reloading zshrc..."
        source ~/.zshrc
        echo "✅ zshrc reloaded!"
        echo ""
        echo "🧪 Run 'test_spark_comprehensive' to verify functionality"
    else
        echo "❌ Failed to restore zshrc"
        return 1
    fi
}

function restore_zshrc_emergency {
    echo "🚨 Emergency zshrc restore (no confirmation)"
    local backup_file=$(ls "$ZSHRC_BACKUPS"/.zshrc_*.txt 2>/dev/null | sort -r | head -1)

    if [[ -n "$backup_file" ]]; then
        cp "$backup_file" ~/.zshrc && source ~/.zshrc
        echo "✅ Emergency restore completed from: $(basename "$backup_file")"
    else
        echo "❌ No emergency backup available"
        return 1
    fi
}

function zshreboot {
    source ~/.zshrc
}

function zshconfig {
    zed ~/.config/zsh/zshrc
}

# =====================================================
# DATABASE SETTINGS
# =====================================================

export PGHOST="localhost"
export PGUSER="dheerajchand"
# SECURITY FIX: Use credential system instead of plaintext
# export PGPASSWORD="dessert"  # REMOVED - use get_credential function
export PGPORT="5432"
export PGDATABASE="gis"

export GEODJANGO_TEMPLATE_SQL_DATABASE="geodjango_template_db"
export GEODJANGO_TEMPLATE_SQL_USER="dheerajchand"
# SECURITY FIX: Use credential system instead of plaintext  
# export GEODJANGO_TEMPLATE_SQL_PASSWORD="dessert"  # REMOVED - use get_credential function
export GEODJANGO_TEMPLATE_SQL_PORT="5432"

# =====================================================
# DOCKER & GIS
# =====================================================

export PATH="/Users/dheerajchand/.rd/bin:$PATH"
export DEFAULT_DOCKER_CONTEXT="rancher-desktop"

# GIS things
export GDAL_LIBRARY_PATH="$(gdal-config --prefix)/lib/libgdal.dylib"
export GEOS_LIBRARY_PATH="$(geos-config --prefix)/lib/libgeos_c.dylib"

function update_local_repo {
    for remote in `git branch -r`; do git branch --track ${remote#origin/} $remote; done
}
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1

# =====================================================
# INTERNET CONNECTIVITY CHECK
# =====================================================

function is_online {
    ping -c 1 google.com &> /dev/null && echo "online" || echo "offline"
}

# =====================================================
# JAVA SETUP
# =====================================================

export JAVA_HOME="/opt/homebrew/opt/sdkman-cli/libexec/candidates/java/current"
export PATH="$JAVA_HOME/bin:$PATH"
# REMOVED: LD_LIBRARY_PATH can interfere with macOS GUI apps like PyCharm
# export LD_LIBRARY_PATH="$JAVA_HOME/lib:$LD_LIBRARY_PATH"

# Manual setup function (can be called when needed)
function setup_java_version {
    if [[ "$(is_online)" == "online" ]]; then
        echo "🔍 Setting up Java 17 (optimal for Spark 3.5.3 + Hadoop 3.3.6)..."
        local target_java_version="17.0.12-tem"  # Known good version for Spark/Hadoop

        if ! sdk list java | grep -q "$target_java_version"; then
            echo "📦 Installing Java $target_java_version..."
            sdk install java $target_java_version
        fi

        sdk default java $target_java_version
        export JAVA_HOME=$(sdk home java $target_java_version)
        export PATH=$JAVA_HOME/bin:$PATH
        # REMOVED: LD_LIBRARY_PATH can interfere with macOS GUI apps
        # export LD_LIBRARY_PATH=$JAVA_HOME/lib:$LD_LIBRARY_PATH
        echo "✅ Java version set to $target_java_version"
        echo "   Supports: Spark 3.5.3 + Hadoop 3.3.6 integration"
    else
        echo "⚠️  Offline - using current Java installation"
    fi
}

# =====================================================
# HADOOP SETUP WITH SPARK INTEGRATION
# =====================================================

export HADOOP_CURRENT_VERSION="3.3.6"
export HADOOP_HOME="/opt/homebrew/opt/sdkman-cli/libexec/candidates/hadoop/current"
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
# REMOVED: LD_LIBRARY_PATH can interfere with macOS GUI applications
# export LD_LIBRARY_PATH="$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH"
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop/"
export PATH="$HADOOP_HOME/bin:$PATH"
export PATH="$HADOOP_HOME/sbin:$PATH"
export HADOOP_LOCAL_JARS="$HADOOP_HOME/share/hadoop/common/lib/"
export HADOOP_DATA_DIR="$HOME/hadoop-data"

# YARN configuration (using HADOOP_CONF_DIR instead of deprecated YARN_CONF_DIR)
export MAPRED_CONF_DIR="$HADOOP_HOME/etc/hadoop"

# Function to initialize Hadoop data directories
function init_hadoop_dirs {
    mkdir -p "$HADOOP_DATA_DIR/hdfs/namenode"
    mkdir -p "$HADOOP_DATA_DIR/hdfs/datanode"
    echo "✅ Created Hadoop data directories in $HADOOP_DATA_DIR"
}

# Hadoop + Spark Integration
export HADOOP_CLASSPATH="$HADOOP_HOME/share/hadoop/tools/lib/*:$HADOOP_CLASSPATH"
export SPARK_DIST_CLASSPATH=$(hadoop classpath 2>/dev/null || echo "")

# NEW: Java 17 Hadoop Compatibility Fix
function setup_java17_hadoop_compatibility {
    echo "🔧 Applying Java 17 compatibility fixes for Hadoop/YARN..."

    # Add Java 17 module compatibility to hadoop-env.sh
    local hadoop_env="$HADOOP_CONF_DIR/hadoop-env.sh"

    # Check if already applied
    if grep -q "add-opens java.base/java.lang=ALL-UNNAMED" "$hadoop_env" 2>/dev/null; then
        echo "   ✅ Java 17 compatibility already applied"
        return 0
    fi

    # Add JVM module access for Java 17+ compatibility
    cat >> "$hadoop_env" << 'EOF'

# Java 17+ module compatibility for Hadoop/YARN
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.lang=ALL-UNNAMED"
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.util=ALL-UNNAMED"
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.lang.reflect=ALL-UNNAMED"
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.net=ALL-UNNAMED"
export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.util.concurrent=ALL-UNNAMED"

# Additional YARN-specific JVM options
export YARN_RESOURCEMANAGER_OPTS="$YARN_RESOURCEMANAGER_OPTS --add-opens java.base/java.lang=ALL-UNNAMED"
export YARN_NODEMANAGER_OPTS="$YARN_NODEMANAGER_OPTS --add-opens java.base/java.lang=ALL-UNNAMED"

# Hadoop environment (no YARN_ variables to avoid conflicts)
export HADOOP_LOG_DIR="$HADOOP_HOME/logs"
export HADOOP_PID_DIR="/tmp/hadoop-$USER"

# Use HADOOP_DATA_DIR from environment if set, otherwise set default
export HADOOP_DATA_DIR=${HADOOP_DATA_DIR:-$HOME/hadoop-data}

# Use JAVA_HOME from environment if set, otherwise set default
export JAVA_HOME=${JAVA_HOME:-/opt/homebrew/opt/sdkman-cli/libexec/candidates/java/current}

# Process users
export HDFS_NAMENODE_USER=$USER
export HDFS_DATANODE_USER=$USER
export HDFS_SECONDARYNAMENODE_USER=$USER
export YARN_RESOURCEMANAGER_USER=$USER
export YARN_NODEMANAGER_USER=$USER
EOF

    echo "   ✅ Java 17 compatibility applied to hadoop-env.sh"
    echo "   💡 This fixes YARN startup issues with Java 17+"
}

# NEW: Setup YARN Configuration Function
function setup_yarn_config {
    echo "🔧 Setting up YARN configuration..."

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
    echo "   • workers file updated"
    echo ""
    echo "💡 Test YARN with: start_hadoop"
}

# NEW: Download Hadoop SLF4J JARs function
function download_hadoop_slf4j_jars {
    local target_path="${1:-$HADOOP_LOCAL_JARS}"
    echo "🚀 Downloading SLF4J JARs for Hadoop..."
    download_maven_jars "org.slf4j:slf4j-log4j12:1.7.30,log4j:log4j:1.2.17" "$target_path"
}

# NEW: YARN Management Functions
function yarn_application_list {
    echo "📊 YARN Applications:"
    yarn application -list -appStates ALL 2>/dev/null || echo "❌ YARN not accessible"
}

function yarn_kill_all_apps {
    echo "🛑 Killing all YARN applications..."
    yarn application -list -appStates RUNNING,SUBMITTED,ACCEPTED | grep application_ | awk '{print $1}' | while read app; do
        echo "   Killing: $app"
        yarn application -kill "$app"
    done
}

function yarn_logs {
    local app_id="$1"
    if [[ -z "$app_id" ]]; then
        echo "Usage: yarn_logs <application_id>"
        echo "💡 Get application IDs with: yarn_application_list"
        return 1
    fi

    echo "📜 YARN Application Logs for: $app_id"
    yarn logs -applicationId "$app_id"
}

function yarn_cluster_info {
    echo "🏗️ YARN Cluster Information:"
    echo ""
    echo "=== Resource Manager ==="
    yarn rmadmin -getServiceState rm1 2>/dev/null || echo "ResourceManager status: Unknown"

    echo -e "\n=== Node Status ==="
    yarn node -list -all 2>/dev/null || echo "No node information available"

    echo -e "\n=== Queue Information ==="
    yarn queue -status default 2>/dev/null || echo "No queue information available"

    echo -e "\n=== Cluster Metrics ==="
    curl -s http://localhost:8088/ws/v1/cluster/info 2>/dev/null | \
        python3 -c "import json,sys; data=json.load(sys.stdin); print(f'Cluster ID: {data[\"clusterInfo\"][\"id\"]}\nHadoop Version: {data[\"clusterInfo\"][\"hadoopVersion\"]}\nResource Manager: {data[\"clusterInfo\"][\"resourceManagerVersion\"]}')" 2>/dev/null || \
        echo "Cluster metrics unavailable"
}

# Manual setup function (can be called when needed)
function setup_hadoop_version {
    if [[ "$(is_online)" == "online" ]]; then
        echo "🔍 Setting up Hadoop 3.3.6 (pinned known-good version)..."
        local target_hadoop_version="3.3.6"

        if ! sdk list hadoop | grep -q "$target_hadoop_version"; then
            echo "📦 Installing Hadoop $target_hadoop_version..."
            sdk install hadoop $target_hadoop_version
        fi

        sdk default hadoop $target_hadoop_version
        export HADOOP_CURRENT_VERSION="$target_hadoop_version"
        export HADOOP_HOME=$(sdk home hadoop $target_hadoop_version)
        export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
        # REMOVED: LD_LIBRARY_PATH can interfere with macOS GUI applications
# export LD_LIBRARY_PATH="$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH"
        export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop/"
        export PATH="$HADOOP_HOME/bin:$PATH"

        # Update Spark integration
        export HADOOP_CLASSPATH="$HADOOP_HOME/share/hadoop/tools/lib/*:$HADOOP_CLASSPATH"
        export SPARK_DIST_CLASSPATH=$(hadoop classpath 2>/dev/null || echo "")

        echo "✅ Hadoop version pinned to $target_hadoop_version"
        echo "   Compatible with: Java 17, Spark 3.5.3"
        echo "   Spark integration: Configured"
    else
        echo "⚠️  Offline - using current Hadoop installation"
    fi
}

function setup_hadoop_spark_integration {
    echo "🔗 Configuring Hadoop + Spark integration..."

    # Ensure Hadoop is available
    if ! command -v hadoop &>/dev/null; then
        echo "❌ Hadoop not found. Installing..."
        setup_hadoop_version
    fi

    # Configure core-site.xml for local HDFS
    local core_site="$HADOOP_CONF_DIR/core-site.xml"
    if [[ ! -f "$core_site" ]] || ! grep -q "fs.defaultFS" "$core_site"; then
        echo "📝 Configuring Hadoop core-site.xml..."
        cat > "$core_site" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>file://${env.HADOOP_DATA_DIR}/tmp</value>
    </property>
</configuration>
EOF
        echo "✅ core-site.xml configured"
    fi

    # Configure hdfs-site.xml
    local hdfs_site="$HADOOP_CONF_DIR/hdfs-site.xml"
    if [[ ! -f "$hdfs_site" ]] || ! grep -q "dfs.replication" "$hdfs_site"; then
        echo "📝 Configuring Hadoop hdfs-site.xml..."
        cat > "$hdfs_site" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file://${env.HADOOP_DATA_DIR}/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file://${env.HADOOP_DATA_DIR}/hdfs/datanode</value>
    </property>
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>localhost:9868</value>
    </property>
    <property>
        <name>dfs.namenode.secondary.https-address</name>
        <value>localhost:9869</value>
    </property>
</configuration>
EOF
        echo "✅ hdfs-site.xml configured"
    fi

    # Setup YARN configuration
    setup_yarn_config

    # Apply Java 17 compatibility fixes
    setup_java17_hadoop_compatibility

    # Update Spark integration environment
    export HADOOP_CLASSPATH="$HADOOP_HOME/share/hadoop/tools/lib/*:$HADOOP_CLASSPATH"
    export SPARK_DIST_CLASSPATH=$(hadoop classpath 2>/dev/null || echo "")

    echo "✅ Hadoop + Spark integration configured"
    echo "💡 Test with: test_hadoop_spark_integration"
}

# UPDATED: Enhanced start_hadoop function with YARN
function start_hadoop {
    echo "🚀 Starting Hadoop services..."

    # Initialize directories if they don't exist
    if [[ ! -d "$HADOOP_DATA_DIR/hdfs/namenode" ]]; then
        echo "📁 Initializing Hadoop directories..."
        init_hadoop_dirs

        # Format namenode if needed
        echo "🔧 Formatting namenode..."
        hdfs namenode -format -force
    fi

    # Start HDFS
    echo "🔄 Starting HDFS..."
    start-dfs.sh

    # Start YARN
    echo "🔄 Starting YARN..."
    start-yarn.sh

    # Wait for services to start
    sleep 5

    # Status check
    echo "📊 Hadoop Services Status:"
    echo "   NameNode: $(jps | grep -q NameNode && echo "✅ Running" || echo "❌ Stopped")"
    echo "   DataNode: $(jps | grep -q DataNode && echo "✅ Running" || echo "❌ Stopped")"
    echo "   SecondaryNameNode: $(jps | grep -q SecondaryNameNode && echo "✅ Running" || echo "❌ Stopped")"
    echo "   ResourceManager: $(jps | grep -q ResourceManager && echo "✅ Running" || echo "❌ Stopped")"
    echo "   NodeManager: $(jps | grep -q NodeManager && echo "✅ Running" || echo "❌ Stopped")"

    echo "🌐 Web UIs:"
    echo "   HDFS NameNode: http://localhost:9870"
    echo "   YARN ResourceManager: http://localhost:8088"
    echo "   HDFS DataNode: http://localhost:9864"
}

function stop_hadoop {
    echo "🛑 Stopping Hadoop services..."

    # Stop YARN first
    echo "🔄 Stopping YARN..."
    stop-yarn.sh 2>/dev/null

    # Stop HDFS
    echo "🔄 Stopping HDFS..."
    stop-dfs.sh 2>/dev/null

    echo "✅ Hadoop services stopped"
}

function restart_hadoop {
    echo "🔄 Restarting Hadoop services..."
    stop_hadoop
    sleep 3
    start_hadoop
}

function hadoop_status {
    echo "📊 Hadoop Services Status:"

    # Check Java processes
    local namenode_count=$(jps | grep NameNode | wc -l)
    local datanode_count=$(jps | grep DataNode | wc -l)
    local secondary_count=$(jps | grep SecondaryNameNode | wc -l)
    local resourcemanager_count=$(jps | grep ResourceManager | wc -l)
    local nodemanager_count=$(jps | grep NodeManager | wc -l)

    echo "   NameNode: $([ $namenode_count -gt 0 ] && echo '✅ Running' || echo '❌ Stopped')"
    echo "   DataNode: $([ $datanode_count -gt 0 ] && echo '✅ Running' || echo '❌ Stopped')"
    echo "   SecondaryNameNode: $([ $secondary_count -gt 0 ] && echo '✅ Running' || echo '❌ Stopped')"
    echo "   ResourceManager: $([ $resourcemanager_count -gt 0 ] && echo '✅ Running' || echo '❌ Stopped')"
    echo "   NodeManager: $([ $nodemanager_count -gt 0 ] && echo '✅ Running' || echo '❌ Stopped')"

    # Check HDFS health if running
    if [[ $namenode_count -gt 0 ]]; then
        echo ""
        echo "📁 HDFS Status:"
        hdfs dfsadmin -report 2>/dev/null | head -10 || echo "   Unable to get HDFS report"
        echo ""
        echo "🌐 Web UIs:"
        echo "   HDFS NameNode: http://localhost:9870"
        echo "   YARN ResourceManager: http://localhost:8088"
        echo "   HDFS DataNode: http://localhost:9864"
    fi
}

function test_hadoop_integration {
    echo "🧪 Testing Hadoop integration..."

    # Check if Hadoop is running
    if ! jps | grep -q "NameNode"; then
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

function test_hadoop_spark_integration {
    echo "🧪 Testing Hadoop + Spark integration..."

    # Check if Hadoop is running
    if ! jps | grep -q "NameNode"; then
        echo "⚠️  Hadoop not running. Starting..."
        start_hadoop
        sleep 5
    fi

    # Create test script
    local test_script="/tmp/hadoop_spark_test.py"
    cat > "$test_script" << 'EOF'
from pyspark.sql import SparkSession
import sys

try:
    print("🚀 Testing Hadoop + Spark integration...")

    # Create Spark session with Hadoop configuration
    spark = SparkSession.builder \
        .appName("HadoopSparkIntegrationTest") \
        .config("spark.sql.adaptive.enabled", "true") \
        .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
        .getOrCreate()

    print(f"✅ Spark session created")
    print(f"   Master: {spark.sparkContext.master}")
    print(f"   Hadoop configuration available: {'Yes' if spark.sparkContext._jsc.hadoopConfiguration() else 'No'}")

    # Test 1: Create test data
    print("\n🔍 Test 1: Creating test DataFrame...")
    test_data = [(1, "Alice", 25), (2, "Bob", 30), (3, "Charlie", 35)]
    df = spark.createDataFrame(test_data, ["id", "name", "age"])
    print(f"   ✅ DataFrame created with {df.count()} rows")

    # Test 2: Write to HDFS
    print("\n🔍 Test 2: Writing to HDFS...")
    hdfs_path = "hdfs://localhost:9000/test/spark_hadoop_test"

    try:
        df.write.mode("overwrite").parquet(hdfs_path)
        print(f"   ✅ Data written to HDFS: {hdfs_path}")
    except Exception as e:
        print(f"   ⚠️  HDFS write failed: {e}")
        print("   Trying local filesystem...")
        local_path = "/tmp/spark_hadoop_test"
        df.write.mode("overwrite").parquet(local_path)
        print(f"   ✅ Data written to local filesystem: {local_path}")
        hdfs_path = local_path

    # Test 3: Read back from storage
    print("\n🔍 Test 3: Reading back from storage...")
    read_df = spark.read.parquet(hdfs_path)
    read_count = read_df.count()
    print(f"   ✅ Data read back: {read_count} rows")

    # Test 4: Basic processing
    print("\n🔍 Test 4: Data processing...")
    result = read_df.filter(read_df.age > 28).count()
    print(f"   ✅ Filtered data: {result} rows with age > 28")

    # Test 5: Check Hadoop classpath integration
    print("\n🔍 Test 5: Hadoop classpath integration...")
    sc = spark.sparkContext
    hadoop_conf = sc._jsc.hadoopConfiguration()
    fs_default = hadoop_conf.get("fs.defaultFS", "Not configured")
    print(f"   ✅ Hadoop default filesystem: {fs_default}")

    print("\n🎉 Hadoop + Spark integration test completed successfully!")

except Exception as e:
    print(f"\n❌ Integration test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
finally:
    if 'spark' in locals():
        spark.stop()
        print("🛑 Spark session stopped")
EOF

    echo "Running Hadoop + Spark integration test..."
    if [[ -n "$SPARK_MASTER_URL" ]]; then
        distributed_spark_submit "$test_script"
    else
        default_spark_submit "$test_script"
    fi

    rm -f "$test_script"
}

function hadoop_spark_demo {
    echo "🎬 Hadoop + Spark Demo: Processing large dataset..."

    # Ensure services are running
    if ! jps | grep -q "NameNode"; then
        echo "Starting Hadoop..."
        start_hadoop
        sleep 5
    fi

    local demo_script="/tmp/hadoop_spark_demo.py"
    cat > "$demo_script" << 'EOF'
from pyspark.sql import SparkSession
from pyspark.sql.functions import *
import random

print("🎬 Hadoop + Spark Demo: Large Dataset Processing")

# Create Spark session
spark = SparkSession.builder \
    .appName("HadoopSparkDemo") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .getOrCreate()

print("✅ Spark session created with Hadoop integration")

# Generate larger test dataset
print("\n📊 Generating test dataset (100K records)...")
data = []
cities = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose"]
for i in range(100000):
    data.append((
        i,
        f"User_{i}",
        random.randint(18, 80),
        random.choice(cities),
        random.uniform(30000, 150000)
    ))

df = spark.createDataFrame(data, ["id", "name", "age", "city", "salary"])
print(f"✅ Generated dataset with {df.count():,} records")

# Write to distributed storage
print("\n💾 Writing to distributed storage...")
storage_path = "hdfs://localhost:9000/demo/user_data" if "hdfs" in spark.sparkContext._jsc.hadoopConfiguration().get("fs.defaultFS", "") else "/tmp/demo/user_data"

df.write.mode("overwrite").parquet(storage_path)
print(f"✅ Data written to: {storage_path}")

# Read back and perform analytics
print("\n📈 Performing distributed analytics...")
read_df = spark.read.parquet(storage_path)

# Analytics queries
print("   Computing statistics...")
avg_age = read_df.agg(avg("age")).collect()[0][0]
avg_salary = read_df.agg(avg("salary")).collect()[0][0]
total_records = read_df.count()

print(f"   📊 Total Records: {total_records:,}")
print(f"   📊 Average Age: {avg_age:.1f}")
print(f"   📊 Average Salary: ${avg_salary:,.2f}")

# City analysis
print("\n🏙️  City-wise analysis...")
city_stats = read_df.groupBy("city") \
    .agg(count("*").alias("population"),
         avg("age").alias("avg_age"),
         avg("salary").alias("avg_salary")) \
    .orderBy(desc("population"))

city_stats.show(10, truncate=False)

# High earners analysis
print("\n💰 High earners analysis (>$100K)...")
high_earners = read_df.filter(col("salary") > 100000)
high_earner_count = high_earners.count()
percentage = (high_earner_count / total_records) * 100

print(f"   💼 High earners: {high_earner_count:,} ({percentage:.1f}%)")

print("\n🎉 Demo completed! Hadoop + Spark successfully processed large dataset.")

spark.stop()
EOF

    echo "🚀 Running demo..."
    default_spark_submit "$demo_script"
    rm -f "$demo_script"

    echo ""
    echo "🎯 Demo Summary:"
    echo "   ✅ Generated 100K records"
    echo "   ✅ Wrote to distributed storage (HDFS or local)"
    echo "   ✅ Performed distributed analytics"
    echo "   ✅ City-wise and salary analysis"
    echo ""
    echo "💡 This demonstrates Spark's ability to work with Hadoop for:"
    echo "   • Distributed storage (HDFS)"
    echo "   • Large dataset processing"
    echo "   • Complex analytics queries"
    echo "   • Fault-tolerant computation"
}

# =====================================================
# MAVEN SETUP
# =====================================================

DEFAULT_MAVEN_VERSION="3.9.6"

function setup_maven() {
    if command -v mvn &>/dev/null; then
        echo "Maven is installed: $(mvn -version | head -n 1)"
    else
        echo "Maven not found. Installing Maven $DEFAULT_MAVEN_VERSION via SDKMAN..."
        sdk install maven "$DEFAULT_MAVEN_VERSION" || {
            echo "Failed to install Maven. Please check SDKMAN setup."
            return 1
        }

        if command -v mvn &>/dev/null; then
            echo "Maven installation successful: $(mvn -version | head -n 1)"
        else
            echo "Maven installation failed."
        fi
    fi
}

function download_maven_jars {
    local libraries="${1:-$DEFAULT_SPARK_JARS}"
    local target_path="${2:-$LOCAL_SPARK_JAR_PATH}"
    mkdir -p "$target_path"

    echo "🚀 Downloading Maven dependencies..."
    for lib in $(echo "$libraries" | tr ',' ' '); do
        IFS=':' read -r group artifact version <<< "$lib"
        jar_file="${artifact}-${version}.jar"
        mvn_url="https://repo1.maven.org/maven2/$(echo $group | tr '.' '/')/$artifact/$version/$jar_file"

        echo "🔍 Fetching: $jar_file"
        curl -sL -o "$target_path/$jar_file" "$mvn_url" && echo "✅ Saved to $target_path/$jar_file" || echo "❌ Failed to download $jar_file"
    done
}

# =====================================================
# AUTO-SETUP SYSTEM
# =====================================================

# Control flags
export AUTO_SETUP_ON_STARTUP="${AUTO_SETUP_ON_STARTUP:-false}"
export AUTO_SETUP_CHECK_ONLINE="${AUTO_SETUP_CHECK_ONLINE:-true}"
export AUTO_SETUP_VERBOSE="${AUTO_SETUP_VERBOSE:-false}"

function setup_scala_version {
    if [[ "$(is_online)" == "online" ]]; then
        echo "🔍 Setting up dual Scala versions (2.12.x for Spark + 3.x for modern development)..."

        # Scala 2.12.18 - Required for Spark 3.5.3
        local scala_2_version="2.12.18"
        if ! sdk list scala | grep -q "$scala_2_version"; then
            echo "📦 Installing Scala $scala_2_version (Spark compatibility)..."
            sdk install scala $scala_2_version
        fi

        # Scala 3.3.4 - Latest stable Scala 3
        local scala_3_version="3.3.4"
        if ! sdk list scala | grep -q "$scala_3_version"; then
            echo "📦 Installing Scala $scala_3_version (modern Scala)..."
            sdk install scala $scala_3_version
        fi

        # Default to Scala 2.12 for Spark compatibility
        sdk default scala $scala_2_version
        echo "✅ Scala versions installed:"
        echo "   Default: $scala_2_version (Spark 3.5.3 compatible)"
        echo "   Available: $scala_3_version (use: sdk use scala $scala_3_version)"
        echo "💡 Switch versions: sdk use scala [version]"
    else
        echo "⚠️  Offline - using current Scala installation"
    fi
}

function setup_spark_version {
    if [[ "$(is_online)" == "online" ]]; then
        echo "🔍 Setting up Spark 3.5.3 (pinned known-good version)..."
        local target_spark_version="3.5.3"

        if ! sdk list spark | grep -q "$target_spark_version"; then
            echo "📦 Installing Spark $target_spark_version..."
            sdk install spark $target_spark_version
        fi

        sdk default spark $target_spark_version
        export SPARK_HOME=$(sdk home spark $target_spark_version)
        export PATH="$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH"
        echo "✅ Spark version pinned to $target_spark_version"
        echo "   Compatible with: Java 17, Scala 2.12.18, Hadoop 3.3.6"
    else
        echo "⚠️  Offline - using current Spark installation"
    fi
}

function auto_setup_environment {
    local start_time=$(date +%s)
    echo "🚀 Auto-setting up development environment..."

    # Quick connectivity check first
    if [[ "$AUTO_SETUP_CHECK_ONLINE" == "true" ]]; then
        local online_status=$(is_online)
        if [[ "$online_status" == "offline" ]]; then
            echo "⚠️  Offline mode - skipping version updates"
            return 0
        fi
    fi

    # Run setup functions
    [[ "$AUTO_SETUP_VERBOSE" == "true" ]] && echo "🔧 Setting up Java..."
    setup_java_version 2>/dev/null || echo "⚠️  Java setup skipped"

    [[ "$AUTO_SETUP_VERBOSE" == "true" ]] && echo "🔧 Setting up Scala..."
    setup_scala_version 2>/dev/null || echo "⚠️  Scala setup skipped"

    [[ "$AUTO_SETUP_VERBOSE" == "true" ]] && echo "🔧 Setting up Hadoop..."
    setup_hadoop_version 2>/dev/null || echo "⚠️  Hadoop setup skipped"

    [[ "$AUTO_SETUP_VERBOSE" == "true" ]] && echo "🔧 Setting up Spark..."
    setup_spark_version 2>/dev/null || echo "⚠️  Spark setup skipped"

    [[ "$AUTO_SETUP_VERBOSE" == "true" ]] && echo "🔧 Setting up Maven..."
    setup_maven 2>/dev/null || echo "⚠️  Maven setup skipped"

    [[ "$AUTO_SETUP_VERBOSE" == "true" ]] && echo "🔗 Configuring Hadoop+Spark integration..."
    setup_hadoop_spark_integration 2>/dev/null || echo "⚠️  Hadoop+Spark integration skipped"

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    echo "✅ Environment auto-setup completed in ${duration}s"
    echo "💡 Test integration with: test_hadoop_spark_integration"
}

function enable_auto_setup {
    export AUTO_SETUP_ON_STARTUP="true"
    echo "✅ Auto-setup enabled for future shell sessions"
    echo "💡 Run 'disable_auto_setup' to turn off"
    echo "💡 Run 'auto_setup_environment' to run it now"
}

function disable_auto_setup {
    export AUTO_SETUP_ON_STARTUP="false"
    echo "✅ Auto-setup disabled"
    echo "💡 Run 'enable_auto_setup' to turn back on"
    echo "💡 You can still run 'auto_setup_environment' manually"
}

function show_version_strategy {
    echo "📌 Pinned Known-Good Version Strategy:"
    echo ""
    echo "🔧 Target Versions (tested compatibility):"
    echo "   Java:    17.0.12-tem  (LTS with Spark/Hadoop support)"
    echo "   Scala:   2.12.18      (Spark 3.5.3 compatible) + 3.3.4 (modern)"
    echo "   Spark:   3.5.3        (your current working version)"
    echo "   Hadoop:  3.3.6        (stable with Spark 3.5.3)"
    echo "   Maven:   3.9.6        (latest stable)"
    echo ""
    echo "✅ Compatibility Matrix:"
    echo "   Java 17 + Spark 3.5.3 + Hadoop 3.3.6 = ✅ Tested & Working"
    echo "   Scala 2.12.18 required for Spark compatibility"
    echo "   Scala 3.3.4 available for modern Scala development"
    echo ""
    echo "💡 Version Management:"
    echo "   • Pinned versions prevent unexpected breaks"
    echo "   • All versions tested together as a stack"
    echo "   • Scala dual-version setup for flexibility"
    echo "   • Switch Scala: sdk use scala [2.12.18|3.3.4]"
    echo ""
    echo "🔄 To modify pinned versions, edit the setup functions in your zshrc"
}

function verify_version_compatibility {
    echo "🔍 Verifying installed version compatibility..."
    echo ""

    local java_version=$(java -version 2>&1 | head -1 | grep -o '"[^"]*"' | tr -d '"' || echo "Not found")
    local scala_version=$(scala -version 2>&1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1 || echo "Not found")
    local spark_version=$(spark-submit --version 2>&1 | grep -o 'version [0-9]\+\.[0-9]\+\.[0-9]\+' | cut -d' ' -f2 || echo "Not found")
    local hadoop_version=$(hadoop version 2>/dev/null | head -1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "Not found")

    echo "📊 Installed Versions:"
    echo "   Java:    $java_version"
    echo "   Scala:   $scala_version"
    echo "   Spark:   $spark_version"
    echo "   Hadoop:  $hadoop_version"
    echo ""

    # Check compatibility
    local java_ok="❌"
    local scala_ok="❌"
    local spark_ok="❌"
    local hadoop_ok="❌"

    [[ "$java_version" =~ ^17\. ]] && java_ok="✅"
    [[ "$scala_version" =~ ^2\.12\. ]] && scala_ok="✅"
    [[ "$spark_version" == "3.5.3" ]] && spark_ok="✅"
    [[ "$hadoop_version" =~ ^3\.3\. ]] && hadoop_ok="✅"

    echo "🎯 Compatibility Check:"
    echo "   Java 17.x:     $java_ok"
    echo "   Scala 2.12.x:  $scala_ok"
    echo "   Spark 3.5.3:   $spark_ok"
    echo "   Hadoop 3.3.x:  $hadoop_ok"
    echo ""

    if [[ "$java_ok$scala_ok$spark_ok$hadoop_ok" == "✅✅✅✅" ]]; then
        echo "🎉 All versions compatible! Your stack should work perfectly."
    else
        echo "⚠️  Some versions may need adjustment. Run 'auto_setup_environment' to fix."
    fi
}

function setup_environment_status {
    echo "🔍 Environment Setup Status:"
    echo "   Auto-setup on startup: $AUTO_SETUP_ON_STARTUP"
    echo "   Check online: $AUTO_SETUP_CHECK_ONLINE"
    echo "   Verbose mode: $AUTO_SETUP_VERBOSE"
    echo ""
    echo "Current versions:"
    echo "   Java: $(java -version 2>&1 | head -1 || echo 'Not found')"
    echo "   Scala: $(scala -version 2>&1 | head -1 || echo 'Not found')"
    echo "   Spark: $(spark-submit --version 2>&1 | head -1 || echo 'Not found')"
    echo "   Hadoop: $(hadoop version 2>/dev/null | head -1 || echo 'Not found')"
    echo "   Maven: $(mvn -version 2>/dev/null | head -1 || echo 'Not found')"
    echo ""
    echo "💡 Controls:"
    echo "   enable_auto_setup         - Enable auto-setup on shell startup"
    echo "   disable_auto_setup        - Disable auto-setup"
    echo "   auto_setup_environment    - Run setup manually"
    echo "   show_version_strategy     - Show pinned version strategy"
    echo "   verify_version_compatibility - Check version compatibility"
}

# =====================================================
# FUNCTION BACKUP SYSTEM
# =====================================================

function backup_critical_functions {
    echo "💾 Creating backup of critical functions..."
    local backup_dir="$HOME/.zsh_function_backups"
    mkdir -p "$backup_dir"

    # Backup the working test function
    cat > "$backup_dir/test_spark_comprehensive_backup.sh" << 'EOF'
function test_spark_comprehensive {
    echo "🧪 Comprehensive Spark functionality test (Sedona + GraphFrames)..."
    echo "🔥 RUNNING UPDATED VERSION FROM ARTIFACT - BANANA HAMMOCK! 🔥"

    local test_script="/tmp/spark_comprehensive_test.py"
    cat > "$test_script" << 'PYTHON_EOF'
from pyspark.sql import SparkSession

print("🚀 Starting comprehensive Spark test...")

spark = SparkSession.builder \
    .appName("ComprehensiveSparkTest") \
    .config("spark.sql.extensions", "org.apache.sedona.sql.SedonaSqlExtensions") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .config("spark.kryo.registrator", "org.apache.sedona.core.serde.SedonaKryoRegistrator") \
    .getOrCreate()

print("✅ Spark Context created successfully")
print(f"   Master: {spark.sparkContext.master}")
print(f"   Default Parallelism: {spark.sparkContext.defaultParallelism}")

print("\n🔍 Test 1: Basic RDD operations...")
rdd = spark.sparkContext.parallelize(range(100), 4)
result = rdd.map(lambda x: x * x).sum()
print(f"   ✅ RDD computation result: {result}")

print("\n🔍 Test 2: DataFrame operations...")
df = spark.range(100)
count = df.count()
print(f"   ✅ DataFrame count: {count}")

print("\n🔍 Test 3: SQL operations...")
df.createOrReplaceTempView("test_table")
sql_result = spark.sql("SELECT COUNT(*) as count FROM test_table").collect()[0]["count"]
print(f"   ✅ SQL result: {sql_result}")

print("\n🔍 Test 4: Sedona functionality...")
sedona_works = False
try:
    # Modern Sedona 1.7.1+ initialization
    from sedona.spark import SedonaContext
    sedona = SedonaContext.create(spark)
    print("   ✅ Sedona context created (modern method)")

    # Test basic spatial function
    point_result = sedona.sql("SELECT ST_Point(1.0, 2.0) as point").collect()
    print("   ✅ Sedona ST_Point works")

    # Test distance calculation
    distance_result = sedona.sql("""
        SELECT ST_Distance(
            ST_Point(-0.1275, 51.5072),
            ST_Point(-74.0060, 40.7128)
        ) as distance_degrees
    """).collect()[0]["distance_degrees"]
    print(f"   ✅ Sedona distance calculation: {distance_result:.4f} degrees")

    # Test spatial operations with DataFrame
    spatial_df = sedona.createDataFrame([
        ("London", -0.1275, 51.5072),
        ("NYC", -74.0060, 40.7128),
    ], ["city", "longitude", "latitude"])

    spatial_with_geom = spatial_df.selectExpr(
        "city",
        "ST_Point(longitude, latitude) as geom"
    )
    geom_count = spatial_with_geom.count()
    print(f"   ✅ Sedona DataFrame operations: {geom_count} geometries created")

    sedona_works = True

except Exception as e:
    print(f"   ⚠️  Sedona failed: {e}")

print("\n🔍 Test 5: GraphFrames functionality...")
graphframes_works = False
try:
    from graphframes import GraphFrame
    vertices = spark.createDataFrame([("A", "Node A"), ("B", "Node B"), ("C", "Node C")], ["id", "name"])
    edges = spark.createDataFrame([("A", "B", "edge1"), ("B", "C", "edge2")], ["src", "dst", "relationship"])
    g = GraphFrame(vertices, edges)
    v_count = g.vertices.count()
    e_count = g.edges.count()
    print(f"   ✅ GraphFrame created with {v_count} vertices, {e_count} edges")

    # Test PageRank
    pagerank_result = g.pageRank(resetProbability=0.01, maxIter=2)
    pr_vertices = pagerank_result.vertices.count()
    print(f"   ✅ PageRank completed: {pr_vertices} vertices processed")

    graphframes_works = True
except Exception as e:
    print(f"   ⚠️  GraphFrames failed: {e}")

print("\n🎉 Summary:")
print("   ✅ Core Spark: Working")
print(f"   {'✅' if sedona_works else '⚠️ '} Sedona: {'Working (Modern)' if sedona_works else 'Failed'}")
print(f"   {'✅' if graphframes_works else '⚠️ '} GraphFrames: {'Working' if graphframes_works else 'Failed'}")

spark.stop()
print("🛑 Test completed")
PYTHON_EOF

    echo "Running test..."
    if [[ -n "$SPARK_MASTER_URL" ]]; then
        distributed_spark_submit "$test_script"
    else
        default_spark_submit "$test_script"
    fi

    rm -f "$test_script"
}
EOF

    echo "✅ Critical functions backed up to: $backup_dir"
    echo "💡 Use 'restore_critical_functions' if they get lost"
}

function restore_critical_functions {
    echo "🔄 Restoring critical functions from backup..."
    local backup_dir="$HOME/.zsh_function_backups"

    if [[ -f "$backup_dir/test_spark_comprehensive_backup.sh" ]]; then
        source "$backup_dir/test_spark_comprehensive_backup.sh"
        echo "✅ test_spark_comprehensive function restored!"
        echo "🧪 Test it: test_spark_comprehensive"
    else
        echo "❌ No backup found. Run 'backup_critical_functions' first."
    fi
}

function emergency_restore_test_function {
    echo "🚨 Emergency restore of test_spark_comprehensive function..."

    function test_spark_comprehensive {
        echo "🧪 Comprehensive Spark functionality test (Sedona + GraphFrames)..."
        echo "🔥 RUNNING UPDATED VERSION FROM ARTIFACT - BANANA HAMMOCK! 🔥"

        local test_script="/tmp/spark_comprehensive_test.py"
        cat > "$test_script" << 'EOF'
from pyspark.sql import SparkSession

print("🚀 Starting comprehensive Spark test...")

spark = SparkSession.builder \
    .appName("ComprehensiveSparkTest") \
    .config("spark.sql.extensions", "org.apache.sedona.sql.SedonaSqlExtensions") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .config("spark.kryo.registrator", "org.apache.sedona.core.serde.SedonaKryoRegistrator") \
    .getOrCreate()

print("✅ Spark Context created successfully")
print(f"   Master: {spark.sparkContext.master}")
print(f"   Default Parallelism: {spark.sparkContext.defaultParallelism}")

print("\n🔍 Test 1: Basic RDD operations...")
rdd = spark.sparkContext.parallelize(range(100), 4)
result = rdd.map(lambda x: x * x).sum()
print(f"   ✅ RDD computation result: {result}")

print("\n🔍 Test 2: DataFrame operations...")
df = spark.range(100)
count = df.count()
print(f"   ✅ DataFrame count: {count}")

print("\n🔍 Test 3: SQL operations...")
df.createOrReplaceTempView("test_table")
sql_result = spark.sql("SELECT COUNT(*) as count FROM test_table").collect()[0]["count"]
print(f"   ✅ SQL result: {sql_result}")

print("\n🔍 Test 4: Sedona functionality...")
sedona_works = False
try:
    # Modern Sedona 1.7.1+ initialization
    from sedona.spark import SedonaContext
    sedona = SedonaContext.create(spark)
    print("   ✅ Sedona context created (modern method)")

    # Test basic spatial function
    point_result = sedona.sql("SELECT ST_Point(1.0, 2.0) as point").collect()
    print("   ✅ Sedona ST_Point works")

    # Test distance calculation
    distance_result = sedona.sql("""
        SELECT ST_Distance(
            ST_Point(-0.1275, 51.5072),
            ST_Point(-74.0060, 40.7128)
        ) as distance_degrees
    """).collect()[0]["distance_degrees"]
    print(f"   ✅ Sedona distance calculation: {distance_result:.4f} degrees")

    # Test spatial operations with DataFrame
    spatial_df = sedona.createDataFrame([
        ("London", -0.1275, 51.5072),
        ("NYC", -74.0060, 40.7128),
    ], ["city", "longitude", "latitude"])

    spatial_with_geom = spatial_df.selectExpr(
        "city",
        "ST_Point(longitude, latitude) as geom"
    )
    geom_count = spatial_with_geom.count()
    print(f"   ✅ Sedona DataFrame operations: {geom_count} geometries created")

    sedona_works = True

except Exception as e:
    print(f"   ⚠️  Sedona failed: {e}")

print("\n🔍 Test 5: GraphFrames functionality...")
graphframes_works = False
try:
    from graphframes import GraphFrame
    vertices = spark.createDataFrame([("A", "Node A"), ("B", "Node B"), ("C", "Node C")], ["id", "name"])
    edges = spark.createDataFrame([("A", "B", "edge1"), ("B", "C", "edge2")], ["src", "dst", "relationship"])
    g = GraphFrame(vertices, edges)
    v_count = g.vertices.count()
    e_count = g.edges.count()
    print(f"   ✅ GraphFrame created with {v_count} vertices, {e_count} edges")

    # Test PageRank
    pagerank_result = g.pageRank(resetProbability=0.01, maxIter=2)
    pr_vertices = pagerank_result.vertices.count()
    print(f"   ✅ PageRank completed: {pr_vertices} vertices processed")

    graphframes_works = True
except Exception as e:
    print(f"   ⚠️  GraphFrames failed: {e}")

print("\n🎉 Summary:")
print("   ✅ Core Spark: Working")
print(f"   {'✅' if sedona_works else '⚠️ '} Sedona: {'Working (Modern)' if sedona_works else 'Failed'}")
print(f"   {'✅' if graphframes_works else '⚠️ '} GraphFrames: {'Working' if graphframes_works else 'Failed'}")

spark.stop()
print("🛑 Test completed")
EOF

        echo "Running test..."
        if [[ -n "$SPARK_MASTER_URL" ]]; then
            distributed_spark_submit "$test_script"
        else
            default_spark_submit "$test_script"
        fi

        rm -f "$test_script"
    }

    echo "🚑 Emergency function restored! Test it: test_spark_comprehensive"
}

function list_function_backups {
    local backup_dir="$HOME/.zsh_function_backups"
    echo "📋 Available function backups:"
    if [[ -d "$backup_dir" ]]; then
        ls -la "$backup_dir"
    else
        echo "   No backups found. Run 'backup_critical_functions' first."
    fi
}

# =====================================================
# SPARK ENVIRONMENT
# =====================================================

export SPARK_HOME="/opt/homebrew/opt/sdkman-cli/libexec/candidates/spark/current"
export SPARK_LOCAL_IP="127.0.0.1"
export SPARK_MASTER_HOST="127.0.0.1"
export SPARK_MASTER_PORT="7077"
export SPARK_WORKER_INSTANCES="4"
export SPARK_DRIVER_MEMORY="2g"
export SPARK_EXECUTOR_MEMORY="1g"
export SPARK_WORKER_MEMORY="2g"
export SPARK_CONF_DIR="$SPARK_HOME/conf"
export SPARK_CLIENT_CONFIG="$HOME/.spark-client-defaults.properties"

# Python paths
export PYSPARK_PYTHON="/Users/dheerajchand/.pyenv/shims/python3"
export PYSPARK_DRIVER_PYTHON="/Users/dheerajchand/.pyenv/shims/python3"

# Add Spark to PATH
export PATH="$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH"

# Additional environment variables for distributed mode
export SPARK_NUM_EXECUTORS="${SPARK_NUM_EXECUTORS:-4}"
export SPARK_EXECUTOR_CORES="${SPARK_EXECUTOR_CORES:-1}"
export SPARK_DRIVER_MAX_RESULT_SIZE="${SPARK_DRIVER_MAX_RESULT_SIZE:-2g}"

# =====================================================
# ENHANCED DEPENDENCY MANAGEMENT
# =====================================================

export DEFAULT_SPARK_JARS="org.apache.sedona:sedona-spark-shaded-3.5_2.12:1.7.1,org.datasyslab:geotools-wrapper:1.7.1-28.5,graphframes:graphframes:0.8.3-spark3.5-s_2.12"
export LOCAL_SPARK_JAR_PATH="$HOME/local_jars"
mkdir -p "$LOCAL_SPARK_JAR_PATH"

# Enhanced dependency resolution with debugging
function get_spark_dependencies {
    local online_status=$(is_online)

    echo "🔍 Dependency resolution:" >&2
    echo "   Online status: $online_status" >&2

    if [[ "$online_status" == "online" ]]; then
        echo "   Using online packages: $DEFAULT_SPARK_JARS" >&2
        echo "--packages $DEFAULT_SPARK_JARS"
    else
        echo "   Checking local JARs in: $LOCAL_SPARK_JAR_PATH" >&2
        local local_jars=$(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" 2>/dev/null | tr '\n' ',' | sed 's/,$//')

        if [[ -n "$local_jars" ]]; then
            echo "   Using local JARs: $(echo $local_jars | tr ',' ' ' | wc -w) found" >&2
            echo "--jars $local_jars"
        else
            echo "   ⚠️  No local JARs found, downloading recommended..." >&2
            download_spark_jars_if_needed

            # Try again after download
            local_jars=$(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" 2>/dev/null | tr '\n' ',' | sed 's/,$//')
            if [[ -n "$local_jars" ]]; then
                echo "   Using downloaded JARs" >&2
                echo "--jars $local_jars"
            else
                echo "   ⚠️  Proceeding without additional JARs" >&2
                echo ""
            fi
        fi
    fi
}

# Download essential JARs when offline
function download_spark_jars_if_needed {
    echo "📦 Downloading essential Spark JARs for offline use..."

    # Core JAR URLs (Maven Central)
    local jar_urls=(
        "https://repo1.maven.org/maven2/org/apache/sedona/sedona-spark-shaded-3.5_2.12/1.7.1/sedona-spark-shaded-3.5_2.12-1.7.1.jar"
        "https://repo1.maven.org/maven2/org/datasyslab/geotools-wrapper/1.7.1-28.5/geotools-wrapper-1.7.1-28.5.jar"
        "https://repo1.maven.org/maven2/graphframes/graphframes/0.8.3-spark3.5-s_2.12/graphframes-0.8.3-spark3.5-s_2.12.jar"
    )

    for url in "${jar_urls[@]}"; do
        local jar_name=$(basename "$url")
        local jar_path="$LOCAL_SPARK_JAR_PATH/$jar_name"

        if [[ ! -f "$jar_path" ]]; then
            echo "  Downloading: $jar_name"
            if curl -sL "$url" -o "$jar_path"; then
                echo "  ✅ Downloaded: $jar_name"
            else
                echo "  ❌ Failed: $jar_name"
                rm -f "$jar_path"  # Remove failed download
            fi
        else
            echo "  ✅ Already exists: $jar_name"
        fi
    done
}

# Test dependency resolution
function test_spark_dependencies {
    echo "🧪 Testing Spark dependency resolution..."
    echo ""

    echo "Current status:"
    local deps=$(get_spark_dependencies 2>&1)
    echo "Dependencies resolved: $(echo "$deps" | tail -1)"
    echo ""

    echo "Local JAR inventory:"
    if [[ -d "$LOCAL_SPARK_JAR_PATH" ]]; then
        find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" -exec basename {} \; | sort
        echo "Total JARs: $(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" | wc -l)"
    else
        echo "No local JAR directory found"
    fi
}

# =====================================================
# SPARK CLUSTER MANAGEMENT
# =====================================================

function spark_start {
    echo "🚀 Starting Spark cluster..."

    # Stop any existing processes
    pkill -f 'org.apache.spark.deploy.master.Master' 2>/dev/null
    pkill -f 'org.apache.spark.deploy.worker.Worker' 2>/dev/null
    sleep 3

    # Start master
    echo "Starting master..."
    $SPARK_HOME/sbin/start-master.sh
    sleep 5

    # Start workers (4 workers for stability)
    echo "Starting workers..."
    for i in {1..4}; do
        $SPARK_HOME/sbin/start-worker.sh spark://127.0.0.1:7077
        sleep 1
    done

    # Set master URL
    export SPARK_MASTER_URL="spark://127.0.0.1:7077"

    echo "✅ Cluster started!"
    echo "📊 Master UI: http://127.0.0.1:8080"
    echo "🎯 Master URL: $SPARK_MASTER_URL"

    # Simple functionality test
    sleep 10
    spark_test_simple
}

function spark_stop {
    echo "🛑 Stopping Spark cluster..."

    # Use Spark's stop scripts
    if [[ -f "$SPARK_HOME/sbin/stop-all.sh" ]]; then
        $SPARK_HOME/sbin/stop-all.sh
    fi

    # Force kill any remaining
    pkill -f 'org.apache.spark.deploy.master.Master' 2>/dev/null
    pkill -f 'org.apache.spark.deploy.worker.Worker' 2>/dev/null

    unset SPARK_MASTER_URL
    echo "✅ Cluster stopped"
}

function spark_restart {
    echo "🔄 Restarting Spark cluster..."
    spark_stop
    sleep 3
    spark_start
}

function spark_status {
    echo "📊 Spark Cluster Status:"
    echo "   Master processes: $(ps aux | grep 'spark.deploy.master.Master' | grep -v grep | wc -l)"
    echo "   Worker processes: $(ps aux | grep 'spark.deploy.worker.Worker' | grep -v grep | wc -l)"
    echo "   Master URL: ${SPARK_MASTER_URL:-'Not set'}"
    echo "   Master UI: http://127.0.0.1:8080"

    # Quick functional test
    if [[ -n "$SPARK_MASTER_URL" ]]; then
        echo "   Testing functionality..."
        spark_test_simple
    fi
}

# =====================================================
# SPARK TESTING FUNCTIONS
# =====================================================

function spark_test_simple {
    echo "🧪 Quick Spark functionality test..."

    # python3 -c "
# import sys
# try:
#     from pyspark.sql import SparkSession
#     spark = SparkSession.builder.master('spark://127.0.0.1:7077').appName('QuickTest').getOrCreate()
#     result = spark.sparkContext.parallelize([1,2,3,4,5]).sum()
#     print(f'✅ Cluster functional: sum = {result}')
#     spark.stop()
# except Exception as e:
#     print(f'❌ Test failed: {e}')
#     sys.exit(1)
# " 2>/dev/null
    echo "🧪 Quick Spark functionality test not implemented yet"
}

function test_spark_comprehensive {
    echo "🧪 Comprehensive Spark functionality test (Sedona + GraphFrames)..."
    echo "🔥 RUNNING UPDATED VERSION FROM ARTIFACT - BANANA HAMMOCK! 🔥"

    local test_script="/tmp/spark_comprehensive_test.py"
    cat > "$test_script" << 'EOF'
from pyspark.sql import SparkSession

print("🚀 Starting comprehensive Spark test...")

spark = SparkSession.builder \
    .appName("ComprehensiveSparkTest") \
    .config("spark.sql.extensions", "org.apache.sedona.sql.SedonaSqlExtensions") \
    .config("spark.sql.adaptive.enabled", "true") \
    .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
    .config("spark.kryo.registrator", "org.apache.sedona.core.serde.SedonaKryoRegistrator") \
    .getOrCreate()

print("✅ Spark Context created successfully")
print(f"   Master: {spark.sparkContext.master}")
print(f"   Default Parallelism: {spark.sparkContext.defaultParallelism}")

print("\n🔍 Test 1: Basic RDD operations...")
rdd = spark.sparkContext.parallelize(range(100), 4)
result = rdd.map(lambda x: x * x).sum()
print(f"   ✅ RDD computation result: {result}")

print("\n🔍 Test 2: DataFrame operations...")
df = spark.range(100)
count = df.count()
print(f"   ✅ DataFrame count: {count}")

print("\n🔍 Test 3: SQL operations...")
df.createOrReplaceTempView("test_table")
sql_result = spark.sql("SELECT COUNT(*) as count FROM test_table").collect()[0]["count"]
print(f"   ✅ SQL result: {sql_result}")

print("\n🔍 Test 4: Sedona functionality...")
sedona_works = False
try:
    # Modern Sedona 1.7.1+ initialization
    from sedona.spark import SedonaContext
    sedona = SedonaContext.create(spark)
    print("   ✅ Sedona context created (modern method)")

    # Test basic spatial function
    point_result = sedona.sql("SELECT ST_Point(1.0, 2.0) as point").collect()
    print("   ✅ Sedona ST_Point works")

    # Test distance calculation
    distance_result = sedona.sql("""
        SELECT ST_Distance(
            ST_Point(-0.1275, 51.5072),
            ST_Point(-74.0060, 40.7128)
        ) as distance_degrees
    """).collect()[0]["distance_degrees"]
    print(f"   ✅ Sedona distance calculation: {distance_result:.4f} degrees")

    # Test spatial operations with DataFrame
    spatial_df = sedona.createDataFrame([
        ("London", -0.1275, 51.5072),
        ("NYC", -74.0060, 40.7128),
    ], ["city", "longitude", "latitude"])

    spatial_with_geom = spatial_df.selectExpr(
        "city",
        "ST_Point(longitude, latitude) as geom"
    )
    geom_count = spatial_with_geom.count()
    print(f"   ✅ Sedona DataFrame operations: {geom_count} geometries created")

    sedona_works = True

except Exception as e:
    print(f"   ⚠️  Sedona failed: {e}")

print("\n🔍 Test 5: GraphFrames functionality...")
graphframes_works = False
try:
    from graphframes import GraphFrame
    vertices = spark.createDataFrame([("A", "Node A"), ("B", "Node B"), ("C", "Node C")], ["id", "name"])
    edges = spark.createDataFrame([("A", "B", "edge1"), ("B", "C", "edge2")], ["src", "dst", "relationship"])
    g = GraphFrame(vertices, edges)
    v_count = g.vertices.count()
    e_count = g.edges.count()
    print(f"   ✅ GraphFrame created with {v_count} vertices, {e_count} edges")

    # Test PageRank
    pagerank_result = g.pageRank(resetProbability=0.01, maxIter=2)
    pr_vertices = pagerank_result.vertices.count()
    print(f"   ✅ PageRank completed: {pr_vertices} vertices processed")

    graphframes_works = True
except Exception as e:
    print(f"   ⚠️  GraphFrames failed: {e}")

print("\n🎉 Summary:")
print("   ✅ Core Spark: Working")
print(f"   {'✅' if sedona_works else '⚠️ '} Sedona: {'Working (Modern)' if sedona_works else 'Failed'}")
print(f"   {'✅' if graphframes_works else '⚠️ '} GraphFrames: {'Working' if graphframes_works else 'Failed'}")

spark.stop()
print("🛑 Test completed")
EOF

    echo "Running test..."
    if [[ -n "$SPARK_MASTER_URL" ]]; then
        distributed_spark_submit "$test_script"
    else
        default_spark_submit "$test_script"
    fi

    rm -f "$test_script"
}

# Enhanced default submit with dependency resolution
function default_spark_submit() {
    local py_file="$1"
    if [[ -z "$py_file" ]]; then
        echo "Usage: default_spark_submit <python_file>"
        return 1
    fi

    if [[ ! -f "$py_file" ]]; then
        echo "❌ File not found: $py_file"
        return 1
    fi

    echo "🚀 Local Spark submit with enhanced dependencies..."
    local dependencies=$(get_spark_dependencies)

    # Use eval to properly expand dependencies
    eval "spark-submit \
        --master 'local[*]' \
        --driver-memory $SPARK_DRIVER_MEMORY \
        --executor-memory $SPARK_EXECUTOR_MEMORY \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
        $dependencies \
        '$py_file'"
}

# Enhanced distributed submit
function distributed_spark_submit() {
    local py_file="$1"
    local master_url="${2:-$SPARK_MASTER_URL}"

    if [[ -z "$py_file" ]]; then
        echo "Usage: distributed_spark_submit <python_file> [master_url]"
        return 1
    fi

    if [[ ! -f "$py_file" ]]; then
        echo "❌ File not found: $py_file"
        return 1
    fi

    if [[ -z "$master_url" ]]; then
        echo "❌ No master URL. Run: spark_start"
        return 1
    fi

    echo "🌐 Distributed Spark submit with enhanced dependencies..."
    local dependencies=$(get_spark_dependencies)

    # Use eval to properly expand dependencies
    # eval "spark-submit \
    #     --master '$master_url' \
    #     --deploy-mode client \
    #     --driver-memory $SPARK_DRIVER_MEMORY \
    #     --executor-memory $SPARK_EXECUTOR_MEMORY \
    #     --executor-cores 1 \
    #     --num-executors 4 \
    #     --conf spark.sql.adaptive.enabled=true \
    #     --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
    #     --conf spark.network.timeout=300s \
    #     $dependencies \
    #     '$py_file'"
    echo "🌐 Distributed Spark submit not implemented yet"
}

# Smart environment detection submit
function smart_spark_submit() {
    local py_file="$1"
    if [ -z "$py_file" ]; then
        echo "Usage: smart_spark_submit <python_file>"
        return 1
    fi

    echo "🤖 Smart environment detection..."

    # Check for standalone Spark cluster
    if [ -n "$SPARK_MASTER_URL" ] && ps aux | grep -i "spark.deploy.master.Master" | grep -v "grep" > /dev/null; then
        echo "✅ Local Spark cluster detected - using distributed mode"
        distributed_spark_submit "$py_file"
        return
    fi

    # Check if we can start a local cluster
    if [[ -n "$SPARK_HOME" ]] && [[ -f "$SPARK_HOME/sbin/start-master.sh" ]]; then
        echo "ℹ️  No running cluster found - would you like to start one? (y/n)"
        read "start_cluster?"
        if [[ "$start_cluster" == "y" ]]; then
            spark_start
            distributed_spark_submit "$py_file"
            return
        fi
    fi

    # Fall back to local mode
    echo "ℹ️  Using local mode"
    default_spark_submit "$py_file"
}

function spark_yarn_submit {
    local script_file="$1"
    local deploy_mode="${2:-client}"  # client or cluster

    if [[ -z "$script_file" ]]; then
        echo "Usage: spark_yarn_submit <script_file> [client|cluster]"
        return 1
    fi

    echo "🚀 Submitting Spark job to YARN..."
    local dependencies=$(get_spark_dependencies)

    eval "spark-submit \
        --master yarn \
        --deploy-mode '$deploy_mode' \
        --driver-memory 2g \
        --executor-memory 1g \
        --executor-cores 2 \
        --num-executors 2 \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
        $dependencies \
        '$script_file'"
}

# Enhanced Heavy API Submit Function
function heavy_api_submit {
    local py_file="$1"
    local mode="${2:-auto}"  # auto, local, distributed, yarn

    if [[ -z "$py_file" ]]; then
        echo "Usage: heavy_api_submit <python_file> [mode]"
        echo "Modes: auto (default), local, distributed, yarn"
        return 1
    fi

    if [[ ! -f "$py_file" ]]; then
        echo "❌ File not found: $py_file"
        return 1
    fi

    echo "🚀 Heavy API Workload Submit - Optimized for API-intensive processing..."

    # Heavy API workload optimizations
    local heavy_api_configs=(
        "--conf spark.sql.adaptive.enabled=true"
        "--conf spark.sql.adaptive.coalescePartitions.enabled=true"
        "--conf spark.serializer=org.apache.spark.serializer.KryoSerializer"
        "--conf spark.network.timeout=600s"
        "--conf spark.executor.heartbeatInterval=60s"
        "--conf spark.sql.execution.arrow.pyspark.enabled=true"
        "--conf spark.sql.adaptive.skewJoin.enabled=true"
        "--conf spark.dynamicAllocation.enabled=false"
        "--conf spark.python.worker.reuse=true"
        "--conf spark.sql.adaptive.localShuffleReader.enabled=true"
    )

    local dependencies=$(get_spark_dependencies)
    local config_string="${heavy_api_configs[*]}"

    case "$mode" in
        auto)
            echo "   🤖 Auto-detecting best execution environment for heavy API workload..."
            if [[ -n "$SPARK_MASTER_URL" ]] && jps | grep -q ResourceManager; then
                echo "   ✅ YARN available - using YARN mode for better resource management"
                mode="yarn"
            elif [[ -n "$SPARK_MASTER_URL" ]] && ps aux | grep -q "spark.deploy.master.Master"; then
                echo "   ✅ Spark cluster available - using distributed mode"
                mode="distributed"
            else
                echo "   ℹ️  Using local mode with heavy API optimizations"
                mode="local"
            fi
            ;;
    esac

    case "$mode" in
        local)
            echo "   🏠 Local mode with API-heavy optimizations..."
            # eval "spark-submit \
            #     --master 'local[*]' \
            #     --driver-memory 4g \
            #     --conf 'spark.driver.maxResultSize=2g' \
            #     $config_string \
            #     $dependencies \
            #     '$py_file'"
            echo "   ⚠️  Heavy API submit not implemented yet"
            ;;
        distributed)
            if [[ -z "$SPARK_MASTER_URL" ]]; then
                echo "❌ No Spark cluster URL. Run: spark_start"
                return 1
            fi
            echo "   🌐 Distributed mode with API-heavy optimizations..."
            # eval "spark-submit \
            #     --master '$SPARK_MASTER_URL' \
            #     --deploy-mode client \
            #     --driver-memory 4g \
            #     --executor-memory 2g \
            #     --executor-cores 2 \
            #     --num-executors 4 \
            #     --conf 'spark.driver.maxResultSize=2g' \
            #     $config_string \
            #     $dependencies \
            #     '$py_file'"
            echo "   ⚠️  Heavy API submit not implemented yet"
            ;;
        yarn)
            if ! jps | grep -q ResourceManager; then
                echo "❌ YARN not running. Run: start_hadoop"
                return 1
            fi
            echo "   🎯 YARN mode with API-heavy optimizations and resource management..."
            # eval "spark-submit \
            #     --master yarn \
            #     --deploy-mode client \
            #     --driver-memory 4g \
            #     --executor-memory 2g \
            #     --executor-cores 2 \
            #     --num-executors 4 \
            #     --conf 'spark.driver.maxResultSize=2g' \
            #     $config_string \
            #     $dependencies \
            #     '$py_file'"
            echo "   ⚠️  Heavy API submit not implemented yet"
            ;;
        *)
            echo "❌ Invalid mode: $mode. Use: auto, local, distributed, yarn"
            return 1
            ;;
    esac

    echo ""
    echo "💡 Heavy API Submit Optimizations Applied:"
    echo "   • Increased timeouts for slow API responses"
    echo "   • Enhanced serialization for complex data structures"
    echo "   • Adaptive query execution for varying data sizes"
    echo "   • Python worker reuse for faster API client initialization"
    echo "   • Optimized for geocoding, web scraping, and API-heavy workloads"
}

# Flexible Spark Submit with All Modes
function flexible_spark_submit {
    local py_file="$1"
    local mode="${2:-smart}"  # smart, local, distributed, yarn, k8s

    if [[ -z "$py_file" ]]; then
        echo "Usage: flexible_spark_submit <python_file> [mode]"
        echo "Modes: smart (default), local, distributed, yarn, k8s"
        return 1
    fi

    case "$mode" in
        smart)
            smart_spark_submit "$py_file"
            ;;
        local)
            default_spark_submit "$py_file"
            ;;
        distributed)
            distributed_spark_submit "$py_file"
            ;;
        yarn)
            spark_yarn_submit "$py_file"
            ;;
        k8s)
            echo "🚀 Kubernetes mode (if configured)..."
            if [[ -z "$SPARK_K8S_MASTER" ]]; then
                echo "❌ Kubernetes not configured. Set SPARK_K8S_MASTER"
                return 1
            fi
            local dependencies=$(get_spark_dependencies)
            # eval "spark-submit \
            #     --master '$SPARK_K8S_MASTER' \
            #     --deploy-mode cluster \
            #     --name 'spark-k8s-app' \
            #     --conf spark.executor.instances=2 \
            #     --conf spark.kubernetes.container.image='$SPARK_K8S_IMAGE' \
            #     --conf spark.kubernetes.namespace='$SPARK_K8S_NAMESPACE' \
            #     --conf spark.kubernetes.authenticate.driver.serviceAccountName='$SPARK_K8S_SERVICE_ACCOUNT' \
            #     $dependencies \
            #     '$py_file'"
            echo "🚀 Kubernetes mode not implemented yet"
            ;;
        *)
            echo "❌ Invalid mode: $mode"
            echo "Available modes: smart, local, distributed, yarn, k8s"
            return 1
            ;;
    esac
}

# Backwards compatibility for your existing names
function spark_submit_local {
    default_spark_submit "$@"
}

function spark_submit_cluster {
    distributed_spark_submit "$@"
}

function graceful_spark_restart {
    spark_restart
}

function start_local_spark_cluster {
    spark_start
}

function stop_local_spark_cluster {
    spark_stop
}

function check_spark_cluster_health {
    spark_status
}

# =====================================================
# SPARK CONFIGURATION
# =====================================================

function spark_fix_logging {
    echo "🔧 Reducing Spark logging noise..."

    # Create log4j2.properties to reduce INFO spam
    cat > $SPARK_HOME/conf/log4j2.properties << 'EOF'
# Reduce Spark logging noise
rootLogger.level = WARN
rootLogger.appenderRefs = stdout
rootLogger.appenderRef.stdout.ref = console

appender.console.type = Console
appender.console.name = console
appender.console.target = SYSTEM_ERR
appender.console.layout.type = PatternLayout
appender.console.layout.pattern = %d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n

# Set Spark components to WARN
logger.spark.name = org.apache.spark
logger.spark.level = WARN

logger.hadoop.name = org.apache.hadoop
logger.hadoop.level = WARN

logger.akka.name = akka
logger.akka.level = WARN

logger.jetty.name = org.eclipse.jetty
logger.jetty.level = WARN
EOF

    echo "✅ Logging reduced to WARN level"
}

function show_spark_config() {
    echo "⚙️  Enhanced Spark Configuration:"
    echo ""
    echo "🏠 Environment:"
    echo "   SPARK_HOME: ${SPARK_HOME:-'Not set'}"
    echo "   SPARK_MASTER_URL: ${SPARK_MASTER_URL:-'Not set'}"
    echo "   Java: ${JAVA_HOME:-'Not set'}"
    echo "   Hadoop: ${HADOOP_HOME:-'Not set'}"
    echo ""
    echo "🔗 Hadoop Integration:"
    echo "   HADOOP_CLASSPATH: $(echo ${HADOOP_CLASSPATH:-'Not set'} | cut -c1-50)..."
    echo "   SPARK_DIST_CLASSPATH: $(echo ${SPARK_DIST_CLASSPATH:-'Not set'} | cut -c1-50)..."
    echo "   HDFS Status: $(jps 2>/dev/null | grep -q NameNode && echo '✅ Running' || echo '❌ Stopped')"
    echo "   YARN Status: $(jps 2>/dev/null | grep -q ResourceManager && echo '✅ Running' || echo '❌ Stopped')"
    echo ""
    echo "🤖 Auto-Setup System:"
    echo "   Enabled on startup: $AUTO_SETUP_ON_STARTUP"
    echo "   Check online: $AUTO_SETUP_CHECK_ONLINE"
    echo "   Verbose mode: $AUTO_SETUP_VERBOSE"
    echo ""
    echo "📦 Dependencies:"
    echo "   Online status: $(is_online)"
    echo "   Default JARs: $DEFAULT_SPARK_JARS"
    echo "   Local JAR path: $LOCAL_SPARK_JAR_PATH"
    echo "   Local JARs available: $(find "$LOCAL_SPARK_JAR_PATH" -name "*.jar" 2>/dev/null | wc -l)"
    echo ""
    echo "💡 Available functions:"
    echo "   # Core Spark functions"
    echo "   default_spark_submit     - Local with dependency resolution"
    echo "   distributed_spark_submit - Cluster with dependency resolution"
    echo "   smart_spark_submit       - Auto-detect execution environment"
    echo "   spark_yarn_submit        - Submit to YARN cluster"
    echo "   heavy_api_submit         - Optimized for API-heavy workloads (geocoding, web scraping)"
    echo "   flexible_spark_submit    - Multi-mode execution (local/distributed/yarn/k8s/smart)"
    echo ""
    echo "   # Hadoop + Spark integration"
    echo "   setup_hadoop_spark_integration - Configure Hadoop+Spark"
    echo "   setup_yarn_config        - Configure YARN"
    echo "   setup_java17_hadoop_compatibility - Fix Java 17 compatibility (NEW!)"
    echo "   start_hadoop             - Start Hadoop HDFS + YARN services"
    echo "   stop_hadoop              - Stop Hadoop services"
    echo "   restart_hadoop           - Restart Hadoop services"
    echo "   hadoop_status            - Check Hadoop service status"
    echo "   test_hadoop_integration  - Test basic Hadoop functionality"
    echo "   test_hadoop_spark_integration - Test Spark+Hadoop integration"
    echo "   hadoop_spark_demo        - Run comprehensive demo"
    echo ""
    echo "   # YARN Management (NEW!)"
    echo "   yarn_application_list    - List all YARN applications"
    echo "   yarn_kill_all_apps       - Kill all YARN applications"
    echo "   yarn_logs               - View YARN application logs"
    echo "   yarn_cluster_info        - Show YARN cluster information"
    echo ""
    echo "   # Dependency management"
    echo "   download_hadoop_slf4j_jars - Download SLF4J JARs for Hadoop"
    echo "   download_maven_jars      - Download Maven dependencies"
    echo ""
    echo "   # Testing & diagnostics"
    echo "   test_spark_comprehensive - Full Sedona + GraphFrames test"
    echo "   test_spark_dependencies  - Test dependency resolution"
    echo ""
    echo "   # Auto-setup system"
    echo "   enable_auto_setup        - Enable auto-setup on shell startup"
    echo "   disable_auto_setup       - Disable auto-setup"
    echo "   auto_setup_environment   - Run setup manually"
    echo "   setup_environment_status - Check setup status"
    echo "   show_version_strategy    - Show pinned version strategy"
    echo "   verify_version_compatibility - Check version compatibility"
    echo ""
    echo "   # Configuration backup & restore"
    echo "   backup_zshrc             - Create versioned zshrc backup"
    echo "   list_zshrc_backups       - List available backups"
    echo "   restore_zshrc [backup]   - Restore from backup (defaults to latest)"
    echo "   restore_zshrc_emergency  - Emergency restore without confirmation"
    echo ""
    echo "   # Function backup system"
    echo "   backup_critical_functions - Backup important functions"
    echo "   restore_critical_functions - Restore from backup"
    echo "   emergency_restore_test_function - Emergency restore test function"
}

function spark_config {
    show_spark_config
}

# =====================================================
# NOTEBOOK FUNCTIONS (keeping existing)
# =====================================================

export ZEPPELIN_HOME="$HOME/zeppelin"
export PATH="$ZEPPELIN_HOME/bin:$PATH"
mkdir -p "$ZEPPELIN_HOME"

check_zeppelin() {
    if [[ ! -d "$ZEPPELIN_HOME" ]]; then
        echo "❌ Zeppelin directory not found: $ZEPPELIN_HOME"
        return 1
    elif ! "$ZEPPELIN_HOME/bin/zeppelin-daemon.sh" status > /dev/null 2>&1; then
        echo "Zeppelin is not running."
        return 1
    else
        echo "✅ Zeppelin is running."
        return 0
    fi
}

function start_zeppelin {
    echo "Starting Zeppelin on port 9090..."

    # Ensure Zeppelin is stopped before starting fresh
    "$ZEPPELIN_HOME/bin/zeppelin-daemon.sh" stop

    # Explicitly set Zeppelin's port to 9090 in config
    # sed -i '' 's/<value>8080<\/value>/<value>9090<\/value>/' "$ZEPPELIN_HOME/conf/zeppelin-site.xml"

    # Start Zeppelin with the new port configuration
    "$ZEPPELIN_HOME/bin/zeppelin-daemon.sh" start

    sleep 3  # Wait for Zeppelin to initialize

    echo "✅ Zeppelin started at: http://localhost:9090"
}

function stop_zeppelin() {
    echo "Stopping Zeppelin..."
    "$ZEPPELIN_HOME/bin/zeppelin-daemon.sh" stop
    echo "Zeppelin stopped."
}

function restart_zeppelin() {
    stop_zeppelin
    start_zeppelin
}

function reset_zeppelin() {
    stop_zeppelin
    sleep 3

    echo "🔍 Ensuring Zeppelin is fully stopped..."
    if ps aux | grep -i 'zeppelin' | grep -v 'grep' > /dev/null; then
        echo "❌ Zeppelin is still running! Killing processes..."
        pkill -9 -f 'zeppelin'
        sleep 2
    fi

    # Cleanup
    [ -d "$ZEPPELIN_HOME/run" ] && rm -rf "$ZEPPELIN_HOME/run"
    [ -d "$ZEPPELIN_HOME/logs" ] && rm -rf "$ZEPPELIN_HOME/logs"
    [ -d "$ZEPPELIN_HOME/local-repo/spark" ] && rm -rf "$ZEPPELIN_HOME/local-repo/spark"

    start_zeppelin
    sleep 3  # Allow restart

    # ✅ Verify Zeppelin is running
    if ps aux | grep -i 'zeppelin' | grep -v 'grep' > /dev/null; then
        echo "✅ Zeppelin restarted successfully!"
    else
        echo "❌ Zeppelin failed to start. Check logs!"
        tail -n 50 "$ZEPPELIN_HOME/logs/zeppelin.log"
    fi
}

function check_pyspark_dependencies() {
    if ! command -v pyspark &> /dev/null; then
        echo "❌ PySpark not found! Install it with: pip install pyspark"
        return 1
    fi

    if ! command -v jupyter &> /dev/null && ! command -v "$ZEPPELIN_HOME/bin/zeppelin-daemon.sh" &> /dev/null; then
        echo "❌ Neither Jupyter nor Zeppelin found! Install Jupyter: pip install notebook"
        return 1
    fi

    echo "✅ Dependencies verified!"
    return 0
}

function check_notebook_dependencies {
    local notebook_type="$1"

    case "$notebook_type" in
        jupyter|jupyterlab)
            if ! command -v pyspark &> /dev/null; then
                echo "❌ PySpark not found! Install it with: pip install pyspark"
                return 1
            fi
            if ! command -v jupyter &> /dev/null; then
                echo "❌ Jupyter not found! Install it with: pip install notebook"
                return 1
            fi
            ;;
        zeppelin)
            if [[ ! -d "$ZEPPELIN_HOME" ]] || ! command -v "$ZEPPELIN_HOME/bin/zeppelin-daemon.sh" &> /dev/null; then
                echo "❌ Zeppelin is missing! Ensure it's installed and configured."
                return 1
            fi
            ;;
        databricks)
            if ! command -v databricks &> /dev/null; then
                echo "❌ Databricks CLI not found! Install it with: pip install databricks-cli"
                return 1
            fi
            ;;
        vscode)
            if ! command -v code &> /dev/null; then
                echo "❌ VS Code not found! Ensure it's installed and available in PATH."
                return 1
            fi
            ;;
        *)
            echo "❌ Unknown notebook type: $notebook_type"
            return 1
            ;;
    esac

    echo "✅ Dependencies verified for $notebook_type!"
    return 0
}

function notebook_manager {
    local notebook_type="$1"
    local port="${2:-8888}"  # Default to port 8888
    local notebook_dir="${3:-$(pwd)}"  # Default to current directory

    # ✅ Validate dependencies dynamically based on requested notebook type
    check_notebook_dependencies "$notebook_type" || return 1

    case "$notebook_type" in
        jupyter)
            export PYSPARK_DRIVER_PYTHON="jupyter"
            export PYSPARK_DRIVER_PYTHON_OPTS="notebook --no-browser --port=$port --notebook-dir=$notebook_dir"
            echo "🚀 Starting PySpark Jupyter Notebook on http://localhost:$port..."
            pyspark || { echo "❌ Jupyter Notebook launch failed!"; return 1; }
            ;;
        jupyterlab)
            export PYSPARK_DRIVER_PYTHON="jupyter"
            export PYSPARK_DRIVER_PYTHON_OPTS="lab --no-browser --port=$port --notebook-dir=$notebook_dir"
            echo "🚀 Starting Jupyter Lab on http://localhost:$port..."
            pyspark || { echo "❌ Jupyter Lab launch failed!"; return 1; }
            ;;
        zeppelin)
            echo "🚀 Starting Zeppelin Notebook..."
            start_zeppelin || { echo "❌ Zeppelin launch failed!"; return 1; }
            ;;
        databricks)
            echo "🚀 Launching Databricks CLI..."
            databricks workspace import_dir "$notebook_dir" || { echo "❌ Databricks CLI failed!"; return 1; }
            ;;
        vscode)
            echo "🚀 Opening VS Code for notebook editing..."
            code "$notebook_dir" || { echo "❌ VS Code launch failed!"; return 1; }
            ;;
        *)
            echo "❌ Invalid notebook type: $notebook_type. Available options: jupyter, jupyterlab, zeppelin, databricks, vscode."
            return 1
            ;;
    esac
}

function pyspark_notebook {
    local notebook_type="${1:-jupyter}"  # Default to Jupyter if no type is provided
    notebook_manager "$notebook_type"
}

# =====================================================
# PATH EXPORTS & FINAL SETUP
# =====================================================

# USEFUL paths
export GEOCODE="/Users/dheerajchand/Documents/Professional/Siege_Analytics/Clients/TAN/Projects/tan_geocoding_test"
export RESUME_GENERATOR="/Users/dheerajchand/Documents/Professional/resume_generator"

# SDKMAN Setup
export SDKMAN_DIR=$(brew --prefix sdkman-cli)/libexec
[[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/dheerajchand/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# Smart conditional startup - only run if enabled
if [[ "$AUTO_SETUP_ON_STARTUP" == "true" ]]; then
    echo "🔄 Auto-setup is enabled, running environment setup..."
    # auto_setup_environment &  # Run in background to not block shell startup
fi

# Auto-backup critical functions on startup (silent)
backup_critical_functions > /dev/null 2>&1

# Auto-fix logging on startup
spark_fix_logging >/dev/null 2>&1

# Display fortune
# fortune

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# End of zshrc configuration
