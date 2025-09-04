Spark Functions API Reference
==============================

This module provides comprehensive Apache Spark cluster management, job submission, and optimization utilities for data science workflows.

.. note::
   All functions in this module support cross-shell compatibility (bash/zsh) and cross-platform operation (macOS/Linux/Docker).

Environment Setup Functions
---------------------------

setup_spark_environment()
~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Automatically detects and configures Apache Spark installation across different platforms and installation methods (Homebrew, SDKMAN, manual installations).

.. code-block:: bash

   setup_spark_environment()

**Examples and Elaboration:**

This function is automatically called when the spark module loads, but can be manually invoked to reconfigure the environment:

.. code-block:: bash

   # Manual environment setup (usually automatic)
   setup_spark_environment
   
   # Check if setup was successful
   echo $SPARK_HOME
   # Output: /opt/homebrew/opt/apache-spark/libexec
   
   # Verify Spark is in PATH
   which spark-submit
   # Output: /opt/homebrew/opt/apache-spark/libexec/bin/spark-submit

The function searches for Spark in platform-specific locations:

- **macOS**: `/opt/homebrew/opt/apache-spark/libexec`, `/usr/local/opt/apache-spark/libexec`
- **Linux**: `/opt/spark`, `/usr/local/spark`, `/opt/apache-spark`
- **SDKMAN**: `$SDKMAN_DIR/candidates/spark/current`
- **Custom**: `$HOME/spark`, `$HOME/apache-spark`

Environment variables set by this function:

.. code-block:: bash

   export SPARK_HOME="/path/to/spark"
   export SPARK_CONF_DIR="$SPARK_HOME/conf"
   export PYSPARK_PYTHON=python3
   export PYSPARK_DRIVER_PYTHON=python3
   export SPARK_DRIVER_MEMORY="2g"
   export SPARK_EXECUTOR_MEMORY="1g"
   export SPARK_MASTER_URL="spark://localhost:7077"

**Unit Tests:**

.. code-block:: bash

   # Test: Environment setup success
   test_spark_environment_setup() {
       setup_spark_environment
       [[ -n "$SPARK_HOME" ]] && [[ -f "$SPARK_HOME/bin/spark-submit" ]]
   }
   
   # Test: PATH configuration
   test_spark_path_setup() {
       setup_spark_environment
       command -v spark-submit >/dev/null 2>&1
   }
   
   # Test: Container memory optimization
   test_container_memory_optimization() {
       export ZSH_IS_DOCKER="true"
       setup_spark_environment
       [[ "$SPARK_DRIVER_MEMORY" == "1g" ]] && [[ "$SPARK_EXECUTOR_MEMORY" == "512m" ]]
   }

Dependency Management Functions
-------------------------------

get_spark_dependencies()
~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Generates a dependency string for Spark jobs including JARs and common packages, with cross-shell compatibility.

.. code-block:: bash

   get_spark_dependencies()

**Examples and Elaboration:**

This function automatically discovers and includes JAR files and common Spark packages:

.. code-block:: bash

   # Get dependency string for spark-submit
   deps=$(get_spark_dependencies)
   echo $deps
   # Output: --jars /home/user/spark-jars/kafka.jar,/home/user/spark-jars/delta.jar --packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0

   # Use in spark-submit command
   spark-submit \
       --master local[*] \
       $(get_spark_dependencies) \
       my_script.py

JAR search locations (in order of priority):

1. `$HOME/spark-jars`
2. `$HOME/.spark/jars` 
3. `$SPARK_HOME/jars`
4. `$HOME/local-jars`

Common packages included (when not in Docker):

- Apache Kafka integration: `org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0`
- Streaming Kafka: `org.apache.spark:spark-streaming-kafka-0-10_2.12:3.5.0`
- CSV support: `com.databricks:spark-csv_2.12:1.5.0`

**Unit Tests:**

.. code-block:: bash

   # Test: JAR discovery
   test_jar_discovery() {
       mkdir -p "$HOME/spark-jars"
       touch "$HOME/spark-jars/test.jar"
       deps=$(get_spark_dependencies)
       [[ "$deps" == *"--jars"* ]] && [[ "$deps" == *"test.jar"* ]]
       rm -rf "$HOME/spark-jars"
   }
   
   # Test: Package inclusion (non-container)
   test_package_inclusion() {
       unset ZSH_IS_DOCKER
       deps=$(get_spark_dependencies)
       [[ "$deps" == *"--packages"* ]] && [[ "$deps" == *"spark-sql-kafka"* ]]
   }
   
   # Test: Container optimization (no packages)
   test_container_optimization() {
       export ZSH_IS_DOCKER="true"
       deps=$(get_spark_dependencies)
       [[ "$deps" != *"--packages"* ]]
   }

Cluster Management Functions
----------------------------

spark_start()
~~~~~~~~~~~~~

**Function Definition:**

Starts a local Spark cluster with master and worker processes, including health checks and connection verification.

.. code-block:: bash

   spark_start()

**Examples and Elaboration:**

Starts a complete local Spark cluster for distributed processing:

.. code-block:: bash

   # Start local Spark cluster
   spark_start
   # Output:
   # 🚀 Starting Spark cluster...
   #    Starting Spark master...
   #    ✅ Master started at spark://localhost:7077
   #    Starting Spark worker...
   #    ✅ Worker started
   # 🎯 Spark cluster ready!
   #    Master URL: spark://localhost:7077
   #    Web UI: http://localhost:8080

   # Verify cluster is running
   spark_status

The function:

1. Checks if master process is already running
2. Starts master on port 7077 with web UI on 8080
3. Waits up to 30 seconds for master to become available
4. Starts worker and registers with master
5. Exports `SPARK_MASTER_URL` environment variable

**Unit Tests:**

.. code-block:: bash

   # Test: Cluster startup success
   test_spark_cluster_startup() {
       spark_start
       pgrep -f "spark.deploy.master.Master" >/dev/null &&
       pgrep -f "spark.deploy.worker.Worker" >/dev/null
   }
   
   # Test: Master connectivity
   test_master_connectivity() {
       spark_start
       nc -z localhost 7077 2>/dev/null
   }
   
   # Test: Web UI availability
   test_web_ui_availability() {
       spark_start
       nc -z localhost 8080 2>/dev/null
   }

spark_stop()
~~~~~~~~~~~~

**Function Definition:**

Gracefully stops all local Spark cluster processes (worker then master).

.. code-block:: bash

   spark_stop()

**Examples and Elaboration:**

.. code-block:: bash

   # Stop local Spark cluster
   spark_stop
   # Output:
   # 🛑 Stopping Spark cluster...
   #    Stopping worker...
   #    ✅ Worker stopped
   #    Stopping master...
   #    ✅ Master stopped
   # ✅ Spark cluster stopped

   # Verify cluster is stopped
   spark_status
   # Output shows all processes as "Not running"

**Unit Tests:**

.. code-block:: bash

   # Test: Cluster shutdown
   test_spark_cluster_shutdown() {
       spark_start
       spark_stop
       ! pgrep -f "spark.deploy.master.Master" >/dev/null &&
       ! pgrep -f "spark.deploy.worker.Worker" >/dev/null
   }

spark_status()
~~~~~~~~~~~~~~

**Function Definition:**

Displays comprehensive status information about the Spark cluster including configuration, running processes, and connectivity.

.. code-block:: bash

   spark_status()

**Examples and Elaboration:**

.. code-block:: bash

   spark_status
   # Output:
   # ⚡ Apache Spark Status
   # ====================
   # 
   # Configuration:
   #   SPARK_HOME: /opt/homebrew/opt/apache-spark/libexec
   #   Driver Memory: 2g
   #   Executor Memory: 1g
   #   Master URL: spark://localhost:7077
   # 
   # Cluster Status:
   #   ✅ Master: Running (PID: 12345)
   #      Web UI: http://localhost:8080
   #   ✅ Worker: Running (PID: 12346)
   #      Web UI: http://localhost:8081
   # 
   # Connectivity:
   #   ✅ Master port (7077): Accessible
   #   ✅ Master Web UI (8080): Accessible

**Unit Tests:**

.. code-block:: bash

   # Test: Status command execution
   test_spark_status_execution() {
       spark_status >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }
   
   # Test: Status shows configuration
   test_status_shows_config() {
       output=$(spark_status)
       [[ "$output" == *"SPARK_HOME"* ]] && [[ "$output" == *"Driver Memory"* ]]
   }

Job Submission Functions
-----------------------

default_spark_submit()
~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Standard local Spark job submission with performance optimizations and dependency injection.

.. code-block:: bash

   default_spark_submit <python_file>

**Examples and Elaboration:**

Optimized for local development and testing:

.. code-block:: bash

   # Submit Python job locally
   default_spark_submit my_analysis.py
   # Output:
   # 🏠 Local Spark submit with enhanced dependencies...
   # [Spark execution logs...]

   # Example Python file structure for Spark jobs:
   cat > data_analysis.py << 'EOF'
   from pyspark.sql import SparkSession
   
   spark = SparkSession.builder.appName("DataAnalysis").getOrCreate()
   
   # Read data
   df = spark.read.csv("data.csv", header=True, inferSchema=True)
   
   # Perform analysis
   result = df.groupBy("category").count()
   result.show()
   
   spark.stop()
   EOF
   
   # Submit the job
   default_spark_submit data_analysis.py

Configuration used:

- Master: `local[*]` (uses all available CPU cores)
- Adaptive Query Execution enabled
- Kryo serialization for performance
- Dynamic dependency loading

**Unit Tests:**

.. code-block:: bash

   # Test: Valid file submission
   test_default_spark_submit_valid() {
       echo 'print("Hello Spark")' > test_spark.py
       default_spark_submit test_spark.py >/dev/null 2>&1
       local result=$?
       rm test_spark.py
       [[ $result -eq 0 ]]
   }
   
   # Test: Invalid file handling
   test_default_spark_submit_invalid() {
       default_spark_submit nonexistent.py 2>/dev/null
       [[ $? -ne 0 ]]
   }

distributed_spark_submit()
~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Submit jobs to a distributed Spark cluster with configurable master URL and optimized for cluster execution.

.. code-block:: bash

   distributed_spark_submit <python_file> [master_url]

**Examples and Elaboration:**

.. code-block:: bash

   # Submit to local cluster (must be started first)
   spark_start
   distributed_spark_submit my_job.py
   # Uses default: spark://localhost:7077
   
   # Submit to remote cluster
   distributed_spark_submit my_job.py spark://remote-master:7077
   
   # Submit large data processing job
   cat > large_data_job.py << 'EOF'
   from pyspark.sql import SparkSession
   
   spark = SparkSession.builder.appName("LargeDataJob").getOrCreate()
   
   # Process large dataset
   df = spark.read.parquet("hdfs://data/large_dataset.parquet")
   
   # Complex transformations
   result = df.filter(df.status == "active") \
             .groupBy("region", "category") \
             .agg({"revenue": "sum", "count": "count"}) \
             .orderBy("sum(revenue)", ascending=False)
   
   # Save results
   result.write.mode("overwrite").parquet("hdfs://output/results")
   
   spark.stop()
   EOF
   
   distributed_spark_submit large_data_job.py

Cluster configuration:

- Deploy mode: client (driver runs locally)
- 4 executors with 1 core each
- Network timeout: 300s for reliability
- Adaptive query execution enabled

**Unit Tests:**

.. code-block:: bash

   # Test: Cluster connectivity check
   test_distributed_submit_cluster_check() {
       # Mock a running cluster
       export SPARK_MASTER_URL="spark://localhost:7077"
       echo 'print("test")' > test.py
       
       # Function should check for cluster availability
       distributed_spark_submit test.py 2>&1 | grep -q "No master URL"
       local result=$?
       rm test.py
       [[ $result -ne 0 ]] # Should NOT find "No master URL" if cluster available
   }

smart_spark_submit()
~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Intelligent job submission that automatically detects the best execution environment and optimizes configuration accordingly.

.. code-block:: bash

   smart_spark_submit <python_file>

**Examples and Elaboration:**

The smart submission function follows this decision tree:

1. **Cluster Available**: Uses distributed mode if Spark cluster is running
2. **Can Start Cluster**: Offers to start local cluster for better performance
3. **Fallback**: Uses local mode with all CPU cores

.. code-block:: bash

   # Smart submission with cluster detection
   smart_spark_submit analysis.py
   # Output:
   # 🤖 Smart environment detection...
   # ✅ Local Spark cluster detected - using distributed mode
   # [Execution continues with distributed_spark_submit]

   # Smart submission without cluster (interactive)
   smart_spark_submit analysis.py
   # Output:
   # 🤖 Smart environment detection...
   # ℹ️  No running cluster found - would you like to start one? (y/n)
   # y
   # [Starts cluster and uses distributed mode]

   # Smart submission in container (automatic local mode)
   export ZSH_IS_DOCKER="true"
   smart_spark_submit analysis.py
   # Output:
   # 🤖 Smart environment detection...
   # ℹ️  Using local mode
   # [Uses default_spark_submit]

**Unit Tests:**

.. code-block:: bash

   # Test: Smart detection with running cluster
   test_smart_submit_with_cluster() {
       # Mock running cluster processes
       echo 'print("test")' > test.py
       
       # Set up mock environment
       export SPARK_MASTER_URL="spark://localhost:7077"
       
       # Test that it detects cluster (would need actual cluster for full test)
       smart_spark_submit test.py >/dev/null 2>&1
       local result=$?
       rm test.py
       [[ $result -eq 0 ]]
   }
   
   # Test: Container mode detection
   test_smart_submit_container_mode() {
       export ZSH_IS_DOCKER="true"
       echo 'print("test")' > test.py
       
       smart_spark_submit test.py 2>&1 | grep -q "local mode"
       local result=$?
       rm test.py
       unset ZSH_IS_DOCKER
       [[ $result -eq 0 ]]
   }

heavy_api_submit()
~~~~~~~~~~~~~~~~~

**Function Definition:**

Optimized job submission for API-intensive workloads with specialized configuration for external service calls, timeouts, and memory management.

.. code-block:: bash

   heavy_api_submit <python_file> [mode]
   # Modes: auto (default), local, distributed, yarn

**Examples and Elaboration:**

Perfect for jobs that make many HTTP requests, database calls, or external API interactions:

.. code-block:: bash

   # Auto-mode (recommended)
   heavy_api_submit api_data_pipeline.py
   # Output:
   # 🚀 Heavy API Workload Submit - Optimized for API-intensive processing...
   #    🤖 Auto-detecting best execution environment...
   #    ✅ YARN available - using YARN mode

   # Force local mode for development
   heavy_api_submit api_test.py local
   
   # Example API-heavy job
   cat > api_pipeline.py << 'EOF'
   from pyspark.sql import SparkSession
   import requests
   
   def fetch_api_data(row):
       """Fetch data from external API"""
       response = requests.get(f"https://api.example.com/data/{row.id}")
       return response.json()
   
   spark = SparkSession.builder.appName("APIDataPipeline").getOrCreate()
   
   # Read IDs to process
   ids_df = spark.read.csv("ids.csv", header=True)
   
   # Apply API calls with optimized settings
   results = ids_df.rdd.map(fetch_api_data).collect()
   
   spark.stop()
   EOF
   
   heavy_api_submit api_pipeline.py

API-specific optimizations:

- Extended network timeout: 600s
- Increased heartbeat interval: 60s  
- Arrow-based transfers enabled
- Python worker reuse enabled
- Dynamic allocation disabled for stability
- Increased driver memory: 4g
- Max result size: 2g

**Unit Tests:**

.. code-block:: bash

   # Test: Mode detection
   test_heavy_api_mode_detection() {
       echo 'print("test")' > test.py
       
       # Test auto mode
       heavy_api_submit test.py auto >/dev/null 2>&1
       local result=$?
       rm test.py
       [[ $result -eq 0 ]]
   }
   
   # Test: Configuration application
   test_heavy_api_config() {
       echo 'print("test")' > test.py
       
       # Verify API-specific configs are mentioned
       heavy_api_submit test.py local 2>&1 | grep -q "API-heavy optimizations"
       local result=$?
       rm test.py
       [[ $result -eq 0 ]]
   }

Utility Functions
----------------

spark_shell()
~~~~~~~~~~~~

**Function Definition:**

Starts an interactive Spark shell (Scala) with optimized configuration and dependency loading.

.. code-block:: bash

   spark_shell()

**Examples and Elaboration:**

.. code-block:: bash

   # Start interactive Spark shell
   spark_shell
   # Output:
   # 🐚 Starting Spark shell...
   # [Spark shell starts with optimized config]
   
   # In the shell, you can run Scala/Spark code:
   # scala> val df = spark.read.csv("data.csv")
   # scala> df.show()

**Unit Tests:**

.. code-block:: bash

   # Test: Shell startup command
   test_spark_shell_command() {
       # Mock spark-shell command availability
       command -v spark-shell >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }

pyspark_shell()
~~~~~~~~~~~~~~

**Function Definition:**

Starts an interactive PySpark shell (Python) with optimized configuration and dependency loading.

.. code-block:: bash

   pyspark_shell()

**Examples and Elaboration:**

.. code-block:: bash

   # Start interactive PySpark shell
   pyspark_shell
   # Output:
   # 🐍 Starting PySpark shell...
   # [PySpark shell starts]
   
   # In the shell:
   # >>> df = spark.read.csv("data.csv", header=True)
   # >>> df.show()

**Unit Tests:**

.. code-block:: bash

   # Test: PySpark shell startup
   test_pyspark_shell_command() {
       command -v pyspark >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }

Aliases and Shortcuts
--------------------

The module provides convenient aliases for all major functions:

.. code-block:: bash

   # Cluster management
   spark-start          # spark_start
   spark-stop           # spark_stop  
   spark-status         # spark_status
   spark-restart        # spark_stop && spark_start
   
   # Job submission
   spark-submit-local       # default_spark_submit
   spark-submit-distributed # distributed_spark_submit
   spark-submit-smart       # smart_spark_submit
   spark-submit-yarn        # spark_yarn_submit
   spark-submit-heavy       # heavy_api_submit
   
   # Interactive shells
   spark-shell-start    # spark_shell
   pyspark-start        # pyspark_shell
   
   # Utilities
   spark-history        # spark_history_server
   spark-logs           # ls -la $SPARK_HOME/logs/

Complete Usage Examples
----------------------

**Example 1: Data Science Pipeline**

.. code-block:: bash

   # Setup environment
   setup_spark_environment
   spark_start
   
   # Create and run analysis
   cat > customer_analysis.py << 'EOF'
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import *
   
   spark = SparkSession.builder.appName("CustomerAnalysis").getOrCreate()
   
   # Load customer data
   customers = spark.read.parquet("customers.parquet")
   orders = spark.read.parquet("orders.parquet")
   
   # Join and analyze
   analysis = customers.join(orders, "customer_id") \
                      .groupBy("region") \
                      .agg(sum("order_total").alias("total_revenue"),
                           count("order_id").alias("order_count")) \
                      .orderBy(desc("total_revenue"))
   
   analysis.show()
   analysis.write.mode("overwrite").parquet("output/customer_analysis")
   
   spark.stop()
   EOF
   
   # Submit with smart detection
   smart_spark_submit customer_analysis.py

**Example 2: API Data Collection**

.. code-block:: bash

   # API-intensive job with external calls
   cat > api_collector.py << 'EOF'
   from pyspark.sql import SparkSession
   import requests
   from concurrent.futures import ThreadPoolExecutor
   
   def fetch_user_data(user_id):
       try:
           response = requests.get(f"https://api.company.com/users/{user_id}", 
                                 timeout=30)
           return response.json()
       except Exception as e:
           return {"user_id": user_id, "error": str(e)}
   
   spark = SparkSession.builder.appName("APIDataCollector").getOrCreate()
   
   # Load user IDs
   user_ids = spark.read.csv("user_ids.csv", header=True).collect()
   
   # Fetch API data with optimization
   with ThreadPoolExecutor(max_workers=10) as executor:
       results = list(executor.map(fetch_user_data, 
                                 [row.user_id for row in user_ids]))
   
   # Convert back to DataFrame and save
   results_df = spark.createDataFrame(results)
   results_df.write.mode("overwrite").json("output/user_data")
   
   spark.stop()
   EOF
   
   # Use API-optimized submission
   heavy_api_submit api_collector.py

**Example 3: Production YARN Deployment**

.. code-block:: bash

   # Production job on YARN cluster
   cat > production_etl.py << 'EOF'
   from pyspark.sql import SparkSession
   from pyspark.sql.functions import *
   
   spark = SparkSession.builder \
           .appName("ProductionETL") \
           .config("spark.sql.adaptive.enabled", "true") \
           .getOrCreate()
   
   # ETL pipeline
   raw_data = spark.read.json("hdfs://data/raw/*")
   
   cleaned_data = raw_data.filter(col("status").isNotNull()) \
                          .withColumn("processed_date", current_timestamp()) \
                          .dropDuplicates(["id"])
   
   # Partition and save
   cleaned_data.write \
               .mode("overwrite") \
               .partitionBy("date_partition") \
               .parquet("hdfs://data/processed/")
   
   spark.stop()
   EOF
   
   # Submit to YARN cluster
   spark_yarn_submit production_etl.py cluster

Module Integration
-----------------

The Spark module integrates seamlessly with other system modules:

**With Python Module:**

.. code-block:: bash

   # Setup Python environment for Spark
   setup_pyenv
   pyenv activate spark_env
   pip install pyspark pandas numpy
   
   # Run Spark job with proper Python environment
   smart_spark_submit analysis.py

**With Docker Module:**

.. code-block:: bash

   # Spark jobs in containers automatically optimize for limited resources
   export ZSH_IS_DOCKER="true"
   smart_spark_submit container_job.py
   # Uses reduced memory settings automatically

**With Hadoop Module:**

.. code-block:: bash

   # Start Hadoop services first
   start_hadoop
   
   # Submit to YARN
   spark_yarn_submit distributed_job.py

This comprehensive API provides everything needed for Apache Spark development, from local testing to production deployment, with intelligent optimization and cross-platform compatibility.