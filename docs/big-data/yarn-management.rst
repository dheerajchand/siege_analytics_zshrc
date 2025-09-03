YARN Management
===============

This guide covers YARN (Yet Another Resource Negotiator) management and integration with the Siege Analytics ZSH Configuration System.

Overview
--------

YARN provides:

- **Resource management** for distributed applications
- **Job scheduling** and execution
- **Cluster resource allocation**
- **Application lifecycle management**
- **Multi-tenant support** for different frameworks

YARN Architecture
-----------------

Core Components
~~~~~~~~~~~~~~~

.. mermaid::
   :caption: YARN Architecture

   graph TB
       A[Client] --> B[ResourceManager]
       B --> C[NodeManager 1]
       B --> D[NodeManager 2]
       B --> E[NodeManager N]
       
       C --> F[Container 1]
       C --> G[Container 2]
       D --> H[Container 3]
       E --> I[Container N]
       
       J[ApplicationMaster] --> B
       J --> C
       J --> D
       J --> E

ResourceManager
~~~~~~~~~~~~~~~

The ResourceManager manages cluster resources:

.. code-block:: bash

   # Start ResourceManager
   yarn-daemon.sh start resourcemanager
   
   # Stop ResourceManager
   yarn-daemon.sh stop resourcemanager
   
   # Check ResourceManager status
   jps | grep ResourceManager
   
   # ResourceManager web UI
   # http://localhost:8088

NodeManager
~~~~~~~~~~~

NodeManagers manage resources on individual nodes:

.. code-block:: bash

   # Start NodeManager
   yarn-daemon.sh start nodemanager
   
   # Stop NodeManager
   yarn-daemon.sh stop nodemanager
   
   # Check NodeManager status
   jps | grep NodeManager
   
   # List all nodes
   yarn node -list

YARN Configuration
------------------

Core Configuration
~~~~~~~~~~~~~~~~~~

Configure YARN core settings:

.. code-block:: bash

   # YARN configuration file
   cat > $HADOOP_CONF_DIR/yarn-site.xml << 'EOF'
   <?xml version="1.0"?>
   <configuration>
       <!-- ResourceManager configuration -->
       <property>
           <name>yarn.resourcemanager.hostname</name>
           <value>localhost</value>
       </property>
       <property>
           <name>yarn.resourcemanager.address</name>
           <value>localhost:8032</value>
       </property>
       <property>
           <name>yarn.resourcemanager.scheduler.address</name>
           <value>localhost:8030</value>
       </property>
       <property>
           <name>yarn.resourcemanager.resource-tracker.address</name>
           <value>localhost:8031</value>
       </property>
       
       <!-- NodeManager configuration -->
       <property>
           <name>yarn.nodemanager.aux-services</name>
           <value>mapreduce_shuffle</value>
       </property>
       <property>
           <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
           <value>org.apache.hadoop.mapred.ShuffleHandler</value>
       </property>
   </configuration>
   EOF

Resource Configuration
~~~~~~~~~~~~~~~~~~~~~~

Configure cluster resources:

.. code-block:: bash

   # Memory configuration
   cat >> $HADOOP_CONF_DIR/yarn-site.xml << 'EOF'
   <property>
       <name>yarn.scheduler.maximum-allocation-mb</name>
       <value>8192</value>
   </property>
   <property>
       <name>yarn.nodemanager.resource.memory-mb</name>
       <value>8192</value>
   </property>
   <property>
       <name>yarn.scheduler.minimum-allocation-mb</name>
       <value>128</value>
   </property>
   EOF
   
   # CPU configuration
   cat >> $HADOOP_CONF_DIR/yarn-site.xml << 'EOF'
   <property>
       <name>yarn.nodemanager.resource.cpu-vcores</name>
       <value>8</value>
   </property>
   <property>
       <name>yarn.scheduler.maximum-allocation-vcores</name>
       <value>8</value>
   </property>
   <property>
       <name>yarn.scheduler.minimum-allocation-vcores</name>
       <value>1</value>
   </property>
   EOF

YARN Operations
---------------

Starting YARN Services
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Start all YARN services
   start-yarn.sh
   
   # Start individual services
   yarn-daemon.sh start resourcemanager
   yarn-daemon.sh start nodemanager
   
   # Check service status
   jps | grep -E "(ResourceManager|NodeManager)"

Stopping YARN Services
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Stop all YARN services
   stop-yarn.sh
   
   # Stop individual services
   yarn-daemon.sh stop resourcemanager
   yarn-daemon.sh stop nodemanager
   
   # Force stop if needed
   pkill -f ResourceManager
   pkill -f NodeManager

YARN Administration
-------------------

Cluster Management
~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Check cluster status
   yarn node -list
   yarn node -list -states RUNNING
   yarn node -list -states LOST
   
   # Get cluster information
   yarn cluster -list
   yarn cluster -status
   
   # Check cluster metrics
   yarn cluster -metrics

Application Management
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # List applications
   yarn application -list
   yarn application -list -appStates RUNNING
   yarn application -list -appStates FINISHED
   
   # Get application status
   yarn application -status application_id
   
   # Kill application
   yarn application -kill application_id
   
   # Get application logs
   yarn logs -applicationId application_id
   yarn logs -applicationId application_id -containerId container_id

Resource Monitoring
~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Check resource usage
   yarn top
   
   # Get queue information
   yarn queue -status default
   
   # Check scheduler information
   yarn scheduler -getConf

Spark on YARN
-------------

Spark Configuration
~~~~~~~~~~~~~~~~~~~

Configure Spark to run on YARN:

.. code-block:: bash

   # Spark on YARN configuration
   export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
   export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop
   
   # Spark YARN settings
   export SPARK_YARN_MODE="true"
   export SPARK_MASTER="yarn"
   export SPARK_DEPLOY_MODE="cluster"

Submitting Spark Jobs
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Submit Spark job to YARN (cluster mode)
   spark-submit --master yarn \
       --deploy-mode cluster \
       --driver-memory 2g \
       --executor-memory 2g \
       --executor-cores 2 \
       --num-executors 4 \
       --class org.apache.spark.examples.SparkPi \
       $SPARK_HOME/examples/jars/spark-examples_2.12-3.5.3.jar 10
   
   # Submit Spark job to YARN (client mode)
   spark-submit --master yarn \
       --deploy-mode client \
       --driver-memory 2g \
       --executor-memory 2g \
       --executor-cores 2 \
       --num-executors 4 \
       --class org.apache.spark.examples.SparkPi \
       $SPARK_HOME/examples/jars/spark-examples_2.12-3.5.3.jar 10

Monitoring Spark on YARN
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Monitor Spark applications
   yarn application -list | grep spark
   
   # Get Spark application status
   yarn application -status spark_application_id
   
   # View Spark application logs
   yarn logs -applicationId spark_application_id
   
   # Spark History Server
   # http://localhost:18080

Performance Tuning
------------------

YARN Scheduler Tuning
~~~~~~~~~~~~~~~~~~~~~

Configure YARN schedulers:

.. code-block:: bash

   # Capacity Scheduler configuration
   cat > $HADOOP_CONF_DIR/capacity-scheduler.xml << 'EOF'
   <?xml version="1.0"?>
   <configuration>
       <property>
           <name>yarn.scheduler.capacity.maximum-applications</name>
           <value>10000</value>
       </property>
       <property>
           <name>yarn.scheduler.capacity.maximum-applications-per-user</name>
           <value>100</value>
       </property>
       <property>
           <name>yarn.scheduler.capacity.root.queues</name>
           <value>default</value>
       </property>
       <property>
           <name>yarn.scheduler.capacity.root.default.capacity</name>
           <value>100</value>
       </property>
   </configuration>
   EOF

Memory Tuning
~~~~~~~~~~~~~

Optimize memory allocation:

.. code-block:: bash

   # Adjust memory settings based on cluster
   # For 8GB RAM node:
   export YARN_NODEMANAGER_RESOURCE_MEMORY_MB=6144  # 75% of total RAM
   export YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB=6144
   
   # For 16GB RAM node:
   export YARN_NODEMANAGER_RESOURCE_MEMORY_MB=12288  # 75% of total RAM
   export YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB=12288

CPU Tuning
~~~~~~~~~~

Optimize CPU allocation:

.. code-block:: bash

   # Adjust CPU settings based on cores
   # For 8-core node:
   export YARN_NODEMANAGER_RESOURCE_CPU_VCORES=6  # Leave 2 cores for system
   export YARN_SCHEDULER_MAXIMUM_ALLOCATION_VCORES=6
   
   # For 16-core node:
   export YARN_NODEMANAGER_RESOURCE_CPU_VCORES=12  # Leave 4 cores for system
   export YARN_SCHEDULER_MAXIMUM_ALLOCATION_VCORES=12

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

ResourceManager Issues
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check ResourceManager logs
   tail -f $HADOOP_HOME/logs/yarn-*-resourcemanager-*.log
   
   # Check ResourceManager status
   jps | grep ResourceManager
   
   # Restart ResourceManager
   yarn-daemon.sh stop resourcemanager
   yarn-daemon.sh start resourcemanager

NodeManager Issues
^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check NodeManager logs
   tail -f $HADOOP_HOME/logs/yarn-*-nodemanager-*.log
   
   # Check NodeManager status
   jps | grep NodeManager
   
   # Restart NodeManager
   yarn-daemon.sh stop nodemanager
   yarn-daemon.sh start nodemanager

Application Issues
^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check application logs
   yarn logs -applicationId application_id
   
   # Check application status
   yarn application -status application_id
   
   # Kill problematic application
   yarn application -kill application_id

Resource Issues
^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check resource usage
   yarn top
   
   # Check node status
   yarn node -list
   
   # Check queue status
   yarn queue -status default

Best Practices
--------------

Resource Management
~~~~~~~~~~~~~~~~~~~

1. **Configure appropriate memory limits** for your cluster
2. **Set reasonable CPU limits** to avoid over-allocation
3. **Monitor resource usage** regularly
4. **Use queues** to manage different workloads
5. **Implement resource limits** per user/group

Application Management
~~~~~~~~~~~~~~~~~~~~~~

1. **Use appropriate deploy modes** (client vs cluster)
2. **Configure proper memory settings** for applications
3. **Monitor application performance** and resource usage
4. **Implement proper logging** for debugging
5. **Use application tags** for better organization

Cluster Monitoring
~~~~~~~~~~~~~~~~~~

1. **Set up monitoring** for ResourceManager and NodeManagers
2. **Monitor resource utilization** across the cluster
3. **Track application performance** metrics
4. **Implement alerting** for critical issues
5. **Regular health checks** of cluster components

Security Considerations
~~~~~~~~~~~~~~~~~~~~~~~

1. **Enable YARN security** features
2. **Configure proper authentication** and authorization
3. **Use secure communication** between components
4. **Implement proper access controls** for resources
5. **Regular security audits** of the cluster

.. note::

   YARN provides robust resource management for distributed applications, enabling efficient utilization of cluster resources and supporting multiple frameworks simultaneously.
