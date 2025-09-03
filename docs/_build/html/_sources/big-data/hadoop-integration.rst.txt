Hadoop Integration
==================

This guide covers Hadoop integration with the Siege Analytics ZSH Configuration System.

Overview
--------

The system provides comprehensive Hadoop integration:

- **HDFS (Hadoop Distributed File System)** support
- **YARN (Yet Another Resource Negotiator)** integration
- **Hadoop ecosystem** tools and utilities
- **Cluster management** and monitoring
- **Performance optimization** for Hadoop workloads

Hadoop Installation
-------------------

SDKMAN Installation
~~~~~~~~~~~~~~~~~~~

Install Hadoop via SDKMAN:

.. code-block:: bash

   # Install Hadoop
   sdk install hadoop 3.3.6
   sdk default hadoop 3.3.6
   
   # Verify installation
   hadoop version
   
   # Check Hadoop home
   echo $HADOOP_HOME

Environment Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~

Configure Hadoop environment:

.. code-block:: bash

   # Set Hadoop environment variables
   export HADOOP_HOME="$HOME/.sdkman/candidates/hadoop/current"
   export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
   export YARN_CONF_DIR="$HADOOP_HOME/etc/hadoop"
   
   # Add to PATH
   export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"

HDFS Operations
---------------

Basic HDFS Commands
~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # List HDFS root directory
   hdfs dfs -ls /
   
   # Create HDFS directory
   hdfs dfs -mkdir /user/spark
   hdfs dfs -mkdir -p /user/spark/data
   
   # Copy files to HDFS
   hdfs dfs -put local_file.txt /user/spark/data/
   hdfs dfs -copyFromLocal local_file.txt /user/spark/data/
   
   # Copy files from HDFS
   hdfs dfs -get /user/spark/data/remote_file.txt .
   hdfs dfs -copyToLocal /user/spark/data/remote_file.txt .
   
   # View file contents
   hdfs dfs -cat /user/spark/data/file.txt
   hdfs dfs -tail /user/spark/data/file.txt
   
   # Remove files
   hdfs dfs -rm /user/spark/data/file.txt
   hdfs dfs -rm -r /user/spark/data/

HDFS Management
~~~~~~~~~~~~~~~

.. code-block:: bash

   # Check HDFS status
   hdfs dfsadmin -report
   
   # Check HDFS health
   hdfs fsck /
   
   # Get HDFS usage
   hdfs dfs -du -h /
   
   # Check HDFS permissions
   hdfs dfs -ls -la /user/spark

YARN Integration
----------------

YARN Configuration
~~~~~~~~~~~~~~~~~~

Configure YARN for resource management:

.. code-block:: bash

   # YARN configuration files
   ls -la $HADOOP_CONF_DIR/yarn-*.xml
   
   # Core YARN settings
   cat > $HADOOP_CONF_DIR/yarn-site.xml << 'EOF'
   <?xml version="1.0"?>
   <configuration>
       <property>
           <name>yarn.nodemanager.aux-services</name>
           <value>mapreduce_shuffle</value>
       </property>
       <property>
           <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
           <value>org.apache.hadoop.mapred.ShuffleHandler</value>
       </property>
       <property>
           <name>yarn.resourcemanager.hostname</name>
           <value>localhost</value>
       </property>
   </configuration>
   EOF

YARN Operations
~~~~~~~~~~~~~~~

.. code-block:: bash

   # Start YARN services
   start-yarn.sh
   
   # Check YARN status
   yarn node -list
   yarn application -list
   
   # Submit YARN application
   yarn jar $HADOOP_HOME/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.3.6.jar \
       wordcount /input /output
   
   # Monitor YARN applications
   yarn application -status application_id

Spark-Hadoop Integration
------------------------

Spark on YARN
~~~~~~~~~~~~~

Configure Spark to run on YARN:

.. code-block:: bash

   # Submit Spark job to YARN
   spark-submit --master yarn \
       --deploy-mode cluster \
       --class org.apache.spark.examples.SparkPi \
       $SPARK_HOME/examples/jars/spark-examples_2.12-3.5.3.jar 10
   
   # Client mode
   spark-submit --master yarn \
       --deploy-mode client \
       --class org.apache.spark.examples.SparkPi \
       $SPARK_HOME/examples/jars/spark-examples_2.12-3.5.3.jar 10

HDFS Integration
~~~~~~~~~~~~~~~~

Use HDFS with Spark:

.. code-block:: bash

   # Read from HDFS
   spark-shell --conf spark.hadoop.fs.defaultFS=hdfs://localhost:9000
   
   # In Spark shell:
   val data = spark.read.textFile("hdfs://localhost:9000/user/spark/data/file.txt")
   
   # Write to HDFS
   data.write.mode("overwrite").text("hdfs://localhost:9000/user/spark/output/")

Cluster Management
------------------

Hadoop Cluster Setup
~~~~~~~~~~~~~~~~~~~~

Set up a local Hadoop cluster:

.. code-block:: bash

   # Format HDFS
   hdfs namenode -format
   
   # Start HDFS
   start-dfs.sh
   
   # Start YARN
   start-yarn.sh
   
   # Check cluster status
   jps
   
   # Stop services
   stop-yarn.sh
   stop-dfs.sh

Monitoring and Management
~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # HDFS NameNode web UI
   # http://localhost:9870
   
   # YARN ResourceManager web UI
   # http://localhost:8088
   
   # Check cluster health
   hdfs dfsadmin -report
   yarn node -list
   
   # Monitor resource usage
   yarn application -list
   yarn logs -applicationId application_id

Performance Tuning
------------------

HDFS Performance
~~~~~~~~~~~~~~~~

Optimize HDFS performance:

.. code-block:: bash

   # HDFS configuration
   cat > $HADOOP_CONF_DIR/hdfs-site.xml << 'EOF'
   <?xml version="1.0"?>
   <configuration>
       <property>
           <name>dfs.replication</name>
           <value>1</value>
       </property>
       <property>
           <name>dfs.blocksize</name>
           <value>134217728</value>
       </property>
       <property>
           <name>dfs.namenode.handler.count</name>
           <value>100</value>
       </property>
   </configuration>
   EOF

YARN Performance
~~~~~~~~~~~~~~~~

Optimize YARN performance:

.. code-block:: bash

   # YARN resource configuration
   cat > $HADOOP_CONF_DIR/yarn-site.xml << 'EOF'
   <?xml version="1.0"?>
   <configuration>
       <property>
           <name>yarn.scheduler.maximum-allocation-mb</name>
           <value>8192</value>
       </property>
       <property>
           <name>yarn.nodemanager.resource.memory-mb</name>
           <value>8192</value>
       </property>
       <property>
           <name>yarn.nodemanager.resource.cpu-vcores</name>
           <value>8</value>
       </property>
   </configuration>
   EOF

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

HDFS Issues
^^^^^^^^^^^

.. code-block:: bash

   # Check HDFS status
   hdfs dfsadmin -report
   
   # Check HDFS logs
   tail -f $HADOOP_HOME/logs/hadoop-*-namenode-*.log
   
   # Restart HDFS
   stop-dfs.sh
   start-dfs.sh

YARN Issues
^^^^^^^^^^^

.. code-block:: bash

   # Check YARN status
   yarn node -list
   
   # Check YARN logs
   tail -f $HADOOP_HOME/logs/yarn-*-resourcemanager-*.log
   
   # Restart YARN
   stop-yarn.sh
   start-yarn.sh

Connection Issues
^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check network connectivity
   telnet localhost 9000  # HDFS
   telnet localhost 8088  # YARN
   
   # Check firewall settings
   sudo ufw status
   
   # Check port usage
   netstat -tlnp | grep :9000
   netstat -tlnp | grep :8088

Best Practices
--------------

Development Environment
~~~~~~~~~~~~~~~~~~~~~~~

1. **Use local mode** for development
2. **Configure appropriate memory settings**
3. **Monitor resource usage**
4. **Use HDFS for large datasets**
5. **Test with small datasets first**

Production Environment
~~~~~~~~~~~~~~~~~~~~~~

1. **Configure proper replication** for HDFS
2. **Set appropriate resource limits** for YARN
3. **Monitor cluster health** regularly
4. **Use proper security configurations**
5. **Implement backup and recovery procedures**

Integration with Spark
~~~~~~~~~~~~~~~~~~~~~~

1. **Use YARN as resource manager** for Spark
2. **Store data in HDFS** for distributed processing
3. **Configure Spark for Hadoop** environment
4. **Monitor Spark applications** through YARN
5. **Optimize for Hadoop** cluster characteristics

.. note::

   Hadoop integration provides the foundation for distributed data processing with HDFS for storage and YARN for resource management, enabling scalable big data applications.
