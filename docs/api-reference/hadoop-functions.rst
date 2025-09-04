Hadoop Functions API Reference
===============================

This module provides comprehensive Apache Hadoop ecosystem management including HDFS, YARN, and MapReduce with seamless integration to Apache Spark for big data processing workflows.

.. note::
   All functions support cross-platform operation (macOS/Linux/Docker) and automatically configure Java 17+ compatibility for modern environments.

Environment Setup Functions
---------------------------

setup_hadoop_environment()
~~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Automatically detects and configures Apache Hadoop installation across different platforms, setting up all necessary environment variables and paths.

.. code-block:: bash

   setup_hadoop_environment()

**Examples and Elaboration:**

This function is automatically called when the Hadoop module loads:

.. code-block:: bash

   # Manual environment setup (usually automatic)
   setup_hadoop_environment
   
   # Check if setup was successful
   echo $HADOOP_HOME
   # Output: /opt/homebrew/opt/hadoop/libexec
   
   # Verify Hadoop is in PATH
   which hadoop
   # Output: /opt/homebrew/opt/hadoop/libexec/bin/hadoop
   
   # Check Spark integration
   echo $SPARK_DIST_CLASSPATH
   # Output: [Long classpath with all Hadoop JARs]

The function searches for Hadoop in platform-specific locations:

- **macOS**: `/opt/homebrew/opt/hadoop/libexec`, `/usr/local/opt/hadoop/libexec`
- **Linux**: `/opt/hadoop`, `/usr/local/hadoop`, `/opt/apache-hadoop`
- **SDKMAN**: `$SDKMAN_DIR/candidates/hadoop/current` (checked first)
- **Custom**: `$HOME/hadoop`, `$HOME/apache-hadoop`

Environment variables configured:

.. code-block:: bash

   export HADOOP_HOME="/path/to/hadoop"
   export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
   export HADOOP_DATA_DIR="$HOME/hadoop-data"
   export HADOOP_PID_DIR="/tmp/hadoop-$USER"
   export HADOOP_CLASSPATH="$HADOOP_HOME/share/hadoop/tools/lib/*"
   export SPARK_DIST_CLASSPATH="[Hadoop classpath for Spark integration]"

Container optimizations:

- **Docker**: Uses 512MB heap sizes for NameNode/ResourceManager
- **Host Systems**: Uses 1GB+ heap sizes for better performance

**Unit Tests:**

.. code-block:: bash

   # Test: Environment setup success
   test_hadoop_environment_setup() {
       setup_hadoop_environment
       [[ -n "$HADOOP_HOME" ]] && [[ -f "$HADOOP_HOME/bin/hadoop" ]]
   }
   
   # Test: PATH configuration
   test_hadoop_path_setup() {
       setup_hadoop_environment
       command -v hadoop >/dev/null 2>&1
   }
   
   # Test: Spark integration
   test_spark_hadoop_integration() {
       setup_hadoop_environment
       [[ -n "$SPARK_DIST_CLASSPATH" ]]
   }

init_hadoop_dirs()
~~~~~~~~~~~~~~~~~

**Function Definition:**

Initialize all necessary Hadoop directories for NameNode, DataNode, temporary files, and logging.

.. code-block:: bash

   init_hadoop_dirs()

**Examples and Elaboration:**

.. code-block:: bash

   # Initialize Hadoop directories
   init_hadoop_dirs
   # Output:
   # 📁 Initializing Hadoop directories...
   # ✅ Hadoop directories initialized
   #    Data: /Users/username/hadoop-data
   #    PIDs: /tmp/hadoop-username

   # Check created structure
   ls -la ~/hadoop-data/
   # Output:
   # drwxr-xr-x namenode/
   # drwxr-xr-x datanode/
   # drwxr-xr-x tmp/
   # drwxr-xr-x logs/

Directory structure created:

- `$HADOOP_DATA_DIR/namenode/` - NameNode metadata storage
- `$HADOOP_DATA_DIR/datanode/` - DataNode block storage
- `$HADOOP_DATA_DIR/tmp/` - Temporary files
- `$HADOOP_DATA_DIR/logs/` - Application logs
- `$HADOOP_PID_DIR/` - Process ID files

**Unit Tests:**

.. code-block:: bash

   # Test: Directory creation
   test_hadoop_dirs_creation() {
       init_hadoop_dirs
       [[ -d "$HADOOP_DATA_DIR/namenode" ]] && 
       [[ -d "$HADOOP_DATA_DIR/datanode" ]] &&
       [[ -d "$HADOOP_PID_DIR" ]]
   }

Java Compatibility Functions
----------------------------

setup_java17_hadoop_compatibility()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Configure Hadoop for Java 17+ compatibility by adding necessary JVM flags and optimizations to hadoop-env.sh.

.. code-block:: bash

   setup_java17_hadoop_compatibility()

**Examples and Elaboration:**

Modern Java versions require additional configuration for Hadoop:

.. code-block:: bash

   # Setup Java 17 compatibility (run once)
   setup_java17_hadoop_compatibility
   # Output:
   # ☕ Setting up Java 17+ compatibility for Hadoop...
   #    ✅ Java 17 compatibility applied to hadoop-env.sh

   # Check applied configuration
   grep "add-opens" $HADOOP_CONF_DIR/hadoop-env.sh
   # Output:
   # export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.lang=ALL-UNNAMED"
   # export HADOOP_OPTS="$HADOOP_OPTS --add-opens java.base/java.util=ALL-UNNAMED"
   # [additional JVM flags...]

Applied JVM configurations:

**Access Control Flags:**
- `--add-opens java.base/java.lang=ALL-UNNAMED`
- `--add-opens java.base/java.util=ALL-UNNAMED`
- `--add-opens java.base/java.lang.reflect=ALL-UNNAMED`
- `--add-opens java.base/java.text=ALL-UNNAMED`
- `--add-opens java.desktop/java.awt.font=ALL-UNNAMED`

**Memory Optimization:**
- NameNode: 1GB heap (512MB in containers)
- DataNode: 512MB heap (256MB in containers)  
- ResourceManager: 1GB heap (512MB in containers)
- NodeManager: 512MB heap (256MB in containers)

**Unit Tests:**

.. code-block:: bash

   # Test: Java compatibility setup
   test_java17_compatibility() {
       setup_java17_hadoop_compatibility
       grep -q "add-opens java.base/java.lang=ALL-UNNAMED" "$HADOOP_CONF_DIR/hadoop-env.sh"
   }
   
   # Test: Idempotent execution
   test_java17_compatibility_idempotent() {
       setup_java17_hadoop_compatibility
       setup_java17_hadoop_compatibility  # Run twice
       local count=$(grep -c "add-opens java.base/java.lang=ALL-UNNAMED" "$HADOOP_CONF_DIR/hadoop-env.sh")
       [[ $count -eq 1 ]]  # Should only appear once
   }

Configuration Functions
-----------------------

setup_yarn_config()
~~~~~~~~~~~~~~~~~~

**Function Definition:**

Create and configure YARN (Yet Another Resource Negotiator) configuration files for distributed resource management.

.. code-block:: bash

   setup_yarn_config()

**Examples and Elaboration:**

.. code-block:: bash

   # Setup YARN configuration
   setup_yarn_config
   # Output:
   # ⚙️  Configuring YARN...
   # 📁 Initializing Hadoop directories...
   # ✅ Hadoop directories initialized
   #    Data: /Users/username/hadoop-data
   #    PIDs: /tmp/hadoop-username
   # 📝 Creating yarn-site.xml...
   # ✅ YARN configuration complete

   # Verify configuration file
   cat $HADOOP_CONF_DIR/yarn-site.xml
   # Output: [XML configuration with resource management settings]

YARN configuration includes:

**Core Services:**
- `yarn.nodemanager.aux-services=mapreduce_shuffle`
- `yarn.nodemanager.aux-services.mapreduce_shuffle.class=org.apache.hadoop.mapred.ShuffleHandler`

**Resource Management:**
- `yarn.resourcemanager.hostname=localhost`
- `yarn.nodemanager.resource.memory-mb=[Memory allocation based on system/container]`
- `yarn.scheduler.maximum-allocation-mb=[Maximum memory per container]`

**Container Settings:**
- `yarn.nodemanager.vmem-check-enabled=false` (Disables virtual memory checking)
- Container executor configurations for different platforms

**Unit Tests:**

.. code-block:: bash

   # Test: YARN config file creation
   test_yarn_config_creation() {
       setup_yarn_config
       [[ -f "$HADOOP_CONF_DIR/yarn-site.xml" ]] &&
       grep -q "mapreduce_shuffle" "$HADOOP_CONF_DIR/yarn-site.xml"
   }

setup_hdfs_config()
~~~~~~~~~~~~~~~~~~

**Function Definition:**

Configure HDFS (Hadoop Distributed File System) with appropriate replication, block sizes, and storage locations.

.. code-block:: bash

   setup_hdfs_config()

**Examples and Elaboration:**

.. code-block:: bash

   # Setup HDFS configuration
   setup_hdfs_config
   # Output:
   # 💾 Configuring HDFS...
   # 📝 Creating core-site.xml...
   # 📝 Creating hdfs-site.xml...
   # ✅ HDFS configuration complete

   # Check NameNode configuration
   grep -A2 -B2 "dfs.namenode.name.dir" $HADOOP_CONF_DIR/hdfs-site.xml
   # Output:
   # <property>
   #     <name>dfs.namenode.name.dir</name>
   #     <value>file:///Users/username/hadoop-data/namenode</value>
   # </property>

HDFS configuration includes:

**Core Settings (core-site.xml):**
- `fs.defaultFS=hdfs://localhost:9000` (Default file system)
- `hadoop.tmp.dir=[Temporary directory path]`

**HDFS Settings (hdfs-site.xml):**
- `dfs.replication=1` (Single node replication)
- `dfs.namenode.name.dir=[NameNode storage directory]`
- `dfs.datanode.data.dir=[DataNode storage directory]`
- `dfs.permissions.enabled=false` (Simplified permissions for development)

**Unit Tests:**

.. code-block:: bash

   # Test: HDFS config files creation
   test_hdfs_config_creation() {
       setup_hdfs_config
       [[ -f "$HADOOP_CONF_DIR/core-site.xml" ]] &&
       [[ -f "$HADOOP_CONF_DIR/hdfs-site.xml" ]] &&
       grep -q "hdfs://localhost:9000" "$HADOOP_CONF_DIR/core-site.xml"
   }

Cluster Management Functions
---------------------------

start_hadoop()
~~~~~~~~~~~~~

**Function Definition:**

Start the complete Hadoop ecosystem including HDFS services (NameNode, DataNode) and YARN services (ResourceManager, NodeManager).

.. code-block:: bash

   start_hadoop()

**Examples and Elaboration:**

.. code-block:: bash

   # Start complete Hadoop cluster
   start_hadoop
   # Output:
   # 🚀 Starting Hadoop ecosystem...
   # 📋 Checking configuration...
   # ✅ Configuration ready
   # 🗃️  Formatting NameNode (if needed)...
   # 🌐 Starting HDFS services...
   #    Starting NameNode...
   #    Starting DataNode...
   # ⚙️  Starting YARN services...
   #    Starting ResourceManager...
   #    Starting NodeManager...
   # ✅ Hadoop cluster started successfully!
   #    HDFS Web UI: http://localhost:9870
   #    YARN Web UI: http://localhost:8088

   # Check cluster status after startup
   hadoop_status

Startup process:

1. **Validation**: Checks for Hadoop installation and configuration
2. **NameNode Formatting**: Formats NameNode if not already done
3. **HDFS Services**: Starts NameNode (port 9000) and DataNode
4. **YARN Services**: Starts ResourceManager (port 8032) and NodeManager
5. **Health Check**: Verifies all services are running

**Unit Tests:**

.. code-block:: bash

   # Test: Hadoop startup
   test_hadoop_startup() {
       start_hadoop
       sleep 10  # Allow services to start
       pgrep -f "NameNode" >/dev/null && pgrep -f "DataNode" >/dev/null
   }
   
   # Test: HDFS accessibility
   test_hdfs_accessibility() {
       start_hadoop
       sleep 10
       hadoop fs -ls / >/dev/null 2>&1
   }

stop_hadoop()
~~~~~~~~~~~~

**Function Definition:**

Gracefully stop all Hadoop services in the correct order (YARN services first, then HDFS services).

.. code-block:: bash

   stop_hadoop()

**Examples and Elaboration:**

.. code-block:: bash

   # Stop Hadoop cluster
   stop_hadoop
   # Output:
   # 🛑 Stopping Hadoop ecosystem...
   # ⚙️  Stopping YARN services...
   #    Stopping NodeManager...
   #    Stopping ResourceManager...
   # 🗃️  Stopping HDFS services...
   #    Stopping DataNode...
   #    Stopping NameNode...
   # ✅ Hadoop cluster stopped

   # Verify services are stopped
   hadoop_status
   # Output shows all services as "Not running"

**Unit Tests:**

.. code-block:: bash

   # Test: Hadoop shutdown
   test_hadoop_shutdown() {
       start_hadoop
       sleep 10
       stop_hadoop
       sleep 5
       ! pgrep -f "NameNode" >/dev/null && ! pgrep -f "DataNode" >/dev/null
   }

hadoop_status()
~~~~~~~~~~~~~~

**Function Definition:**

Display comprehensive status information about all Hadoop services, web interfaces, and connectivity.

.. code-block:: bash

   hadoop_status()

**Examples and Elaboration:**

.. code-block:: bash

   hadoop_status
   # Output:
   # 🐘 Apache Hadoop Status
   # =======================
   # 
   # Configuration:
   #   HADOOP_HOME: /opt/homebrew/opt/hadoop/libexec
   #   HADOOP_CONF_DIR: /opt/homebrew/opt/hadoop/libexec/etc/hadoop
   #   Data Directory: /Users/username/hadoop-data
   # 
   # HDFS Services:
   #   ✅ NameNode: Running (PID: 12345)
   #      Web UI: http://localhost:9870
   #      RPC: hdfs://localhost:9000
   #   ✅ DataNode: Running (PID: 12346)
   #      Web UI: http://localhost:9864
   # 
   # YARN Services:
   #   ✅ ResourceManager: Running (PID: 12347)
   #      Web UI: http://localhost:8088
   #      Scheduler: http://localhost:8030
   #   ✅ NodeManager: Running (PID: 12348)
   #      Web UI: http://localhost:8042
   # 
   # Connectivity:
   #   ✅ HDFS (9000): Accessible
   #   ✅ NameNode Web (9870): Accessible
   #   ✅ YARN Web (8088): Accessible

**Unit Tests:**

.. code-block:: bash

   # Test: Status command execution
   test_hadoop_status_execution() {
       hadoop_status >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }

HDFS Utility Functions
---------------------

hdfs_format()
~~~~~~~~~~~~

**Function Definition:**

Format the HDFS NameNode filesystem, required for initial setup or clean restart.

.. code-block:: bash

   hdfs_format [force]

**Examples and Elaboration:**

.. code-block:: bash

   # Format NameNode (first time setup)
   hdfs_format
   # Output:
   # 🗃️  Formatting HDFS NameNode...
   #    WARNING: This will erase all data in HDFS
   #    Continue? (y/n): y
   # ✅ NameNode formatted successfully

   # Force format without confirmation
   hdfs_format force
   # Output:
   # 🗃️  Force formatting HDFS NameNode...
   # ✅ NameNode formatted successfully

**Unit Tests:**

.. code-block:: bash

   # Test: NameNode formatting
   test_hdfs_format() {
       hdfs_format force >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }

hdfs_safe_mode()
~~~~~~~~~~~~~~~

**Function Definition:**

Control HDFS safe mode for maintenance operations and cluster health checks.

.. code-block:: bash

   hdfs_safe_mode [enter|leave|get|wait]

**Examples and Elaboration:**

.. code-block:: bash

   # Check safe mode status
   hdfs_safe_mode get
   # Output: Safe mode is OFF
   
   # Enter safe mode for maintenance
   hdfs_safe_mode enter
   # Output: Safe mode is ON
   
   # Leave safe mode
   hdfs_safe_mode leave
   # Output: Safe mode is OFF
   
   # Wait for safe mode to turn off automatically
   hdfs_safe_mode wait
   # Output: Safe mode is OFF (or waits until it's off)

**Unit Tests:**

.. code-block:: bash

   # Test: Safe mode control
   test_hdfs_safe_mode() {
       start_hadoop
       sleep 10
       hdfs_safe_mode enter
       status=$(hdfs_safe_mode get)
       [[ "$status" == *"ON"* ]]
   }

Integration Functions
--------------------

hadoop_spark_integration()
~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Verify and configure Hadoop-Spark integration, ensuring Spark can access HDFS and YARN resources.

.. code-block:: bash

   hadoop_spark_integration()

**Examples and Elaboration:**

.. code-block:: bash

   # Test Hadoop-Spark integration
   hadoop_spark_integration
   # Output:
   # 🔗 Testing Hadoop-Spark Integration
   # ================================
   # ✅ HADOOP_HOME: /opt/homebrew/opt/hadoop/libexec
   # ✅ SPARK_HOME: /opt/homebrew/opt/apache-spark/libexec
   # ✅ SPARK_DIST_CLASSPATH: [Long classpath]
   # ✅ HDFS accessible from Spark
   # ✅ YARN accessible from Spark
   # 
   # 🎯 Integration Summary:
   #    • Spark can read/write HDFS
   #    • Spark can submit to YARN
   #    • All necessary JARs in classpath

**Unit Tests:**

.. code-block:: bash

   # Test: Hadoop-Spark integration
   test_hadoop_spark_integration() {
       hadoop_spark_integration >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }

Aliases and Shortcuts
--------------------

The module provides convenient aliases for all major functions:

.. code-block:: bash

   # Cluster management
   hadoop-start         # start_hadoop
   hadoop-stop          # stop_hadoop
   hadoop-status        # hadoop_status
   hadoop-restart       # stop_hadoop && start_hadoop
   
   # HDFS operations
   hdfs-format          # hdfs_format
   hdfs-safe-mode       # hdfs_safe_mode
   hdfs-ls              # hadoop fs -ls
   hdfs-mkdir           # hadoop fs -mkdir
   hdfs-put             # hadoop fs -put
   hdfs-get             # hadoop fs -get
   
   # Configuration
   hadoop-config        # setup_yarn_config && setup_hdfs_config
   hadoop-java17        # setup_java17_hadoop_compatibility
   
   # Web interfaces
   hadoop-web-hdfs      # Open HDFS web UI
   hadoop-web-yarn      # Open YARN web UI

Complete Usage Examples
----------------------

**Example 1: Complete Hadoop setup from scratch**

.. code-block:: bash

   # Setup environment (automatic on module load)
   setup_hadoop_environment
   
   # Configure Java 17 compatibility
   setup_java17_hadoop_compatibility
   
   # Initialize directories and configuration
   init_hadoop_dirs
   setup_hdfs_config
   setup_yarn_config
   
   # Format NameNode (first time only)
   hdfs_format
   
   # Start the cluster
   start_hadoop
   
   # Check status
   hadoop_status

**Example 2: Data science workflow with Hadoop and Spark**

.. code-block:: bash

   # Start Hadoop cluster
   start_hadoop
   
   # Verify Hadoop-Spark integration
   hadoop_spark_integration
   
   # Create HDFS directory for data
   hadoop fs -mkdir /data
   hadoop fs -mkdir /data/input
   hadoop fs -mkdir /data/output
   
   # Upload local data to HDFS
   hadoop fs -put local_data.csv /data/input/
   
   # Run Spark job with YARN
   spark-submit \
       --master yarn \
       --deploy-mode client \
       --num-executors 2 \
       --executor-memory 1g \
       data_analysis.py
   
   # Download results from HDFS
   hadoop fs -get /data/output/results.parquet ./

**Example 3: Container-based Hadoop development**

.. code-block:: bash

   # Container environment automatically detected
   echo "Container mode: $ZSH_IS_DOCKER"
   # Output: Container mode: true
   
   # Setup uses optimized memory settings
   setup_hadoop_environment
   setup_java17_hadoop_compatibility
   
   # Start with container-optimized settings
   start_hadoop
   
   # Status shows reduced memory usage
   hadoop_status

**Example 4: Maintenance operations**

.. code-block:: bash

   # Enter safe mode for maintenance
   hdfs_safe_mode enter
   
   # Perform maintenance operations
   hadoop fs -fsck /
   
   # Leave safe mode
   hdfs_safe_mode leave
   
   # Restart cluster for configuration changes
   hadoop-restart

Integration with Other Modules
-----------------------------

**With Spark Module:**

.. code-block:: bash

   # Start both Hadoop and Spark
   start_hadoop
   spark_start
   
   # Submit Spark job to YARN
   spark_yarn_submit my_analysis.py
   
   # Monitor via web interfaces
   platform_open "http://localhost:8088"  # YARN
   platform_open "http://localhost:4040"  # Spark

**With Python Module:**

.. code-block:: bash

   # Setup Python environment for big data
   ds_project_init hadoop_analysis spark
   cd hadoop_analysis
   py_env_switch uv
   
   # Add Hadoop Python libraries
   uv add hdfs3 pydoop snakebite
   
   # Start Hadoop cluster
   start_hadoop

**With Docker Module:**

.. code-block:: bash

   # Hadoop in containers gets optimized settings
   if [[ "$ZSH_IS_DOCKER" == "true" ]]; then
       echo "Using container-optimized Hadoop configuration"
       # Reduced memory settings automatically applied
   fi

This comprehensive Hadoop module provides everything needed for big data processing workflows, from single-node development to distributed cluster operations, with seamless integration to Apache Spark and modern Java environments.