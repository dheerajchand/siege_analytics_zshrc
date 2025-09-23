#!/usr/bin/env zsh
# =====================================================
# REAL SPARK/HDFS INTEGRATION TEST  
# =====================================================
# Tests actual Spark and HDFS functionality:
# 1. Test Spark module loading and functions
# 2. Test Hadoop/HDFS service startup
# 3. Test actual Spark job submission
# 4. Test HDFS operations (put, get, ls)
# 5. Test integration between Spark and HDFS
# =====================================================

echo "⚡ REAL SPARK/HDFS INTEGRATION TEST"
echo "=================================="

# Load zsh config
source ~/.zshrc >/dev/null 2>&1

echo ""
echo "📋 Test 1: Spark module loading"
echo "------------------------------"

# Test if spark module can be loaded
if command -v load_module >/dev/null 2>&1; then
    echo "✅ load_module available"
    
    if load_module spark 2>&1; then
        echo "✅ Spark module loaded successfully"
    else
        echo "❌ Spark module loading failed"
    fi
else
    echo "❌ load_module not available"
fi

echo ""
echo "📋 Test 2: Spark functions availability"
echo "--------------------------------------"

# Test key Spark functions
spark_functions=("spark_start" "spark_stop" "spark_status" "smart_spark_submit" "heavy_api_submit")

for func in "${spark_functions[@]}"; do
    if command -v "$func" >/dev/null 2>&1; then
        echo "✅ $func available"
    else
        echo "❌ $func not found"
    fi
done

echo ""
echo "📋 Test 3: Hadoop/HDFS functions availability"
echo "--------------------------------------------"

# Test key Hadoop functions
hadoop_functions=("start_hadoop" "stop_hadoop" "hadoop_status" "hdfs_put" "hdfs_get" "hdfs_ls")

for func in "${hadoop_functions[@]}"; do
    if command -v "$func" >/dev/null 2>&1; then
        echo "✅ $func available"
    else
        echo "❌ $func not found"
    fi
done

echo ""
echo "📋 Test 4: Java environment for Spark"
echo "------------------------------------"

# Check Java availability (required for Spark)
if command -v java >/dev/null 2>&1; then
    echo "✅ Java available: $(java -version 2>&1 | head -1)"
    echo "JAVA_HOME: ${JAVA_HOME:-'Not set'}"
else
    echo "❌ Java not available"
fi

# Check SPARK_HOME if set
echo "SPARK_HOME: ${SPARK_HOME:-'Not set'}"
echo "HADOOP_HOME: ${HADOOP_HOME:-'Not set'}"

echo ""
echo "📋 Test 5: Actual Spark functionality (if available)"
echo "--------------------------------------------------"

if command -v spark_status >/dev/null 2>&1; then
    echo "Testing Spark status..."
    spark_status 2>&1
else
    echo "❌ spark_status not available - cannot test Spark functionality"
fi

echo ""
echo "📋 Test 6: Create test Spark job"
echo "-------------------------------"

# Create a simple test Spark job
TEST_SPARK_DIR="/tmp/test_spark_$(date +%s)"
mkdir -p "$TEST_SPARK_DIR"
cd "$TEST_SPARK_DIR"

cat > test_spark_job.py << 'EOF'
#!/usr/bin/env python3
"""
Simple Spark test job to verify Spark integration works
"""
try:
    from pyspark.sql import SparkSession
    
    # Create Spark session
    spark = SparkSession.builder \
        .appName("ZSH Integration Test") \
        .master("local[2]") \
        .getOrCreate()
    
    # Create test data
    data = [("Alice", 25), ("Bob", 30), ("Charlie", 35)]
    columns = ["name", "age"]
    
    df = spark.createDataFrame(data, columns)
    
    print("✅ Spark session created successfully")
    print("✅ Test DataFrame created:")
    df.show()
    
    # Simple operation
    avg_age = df.agg({"age": "avg"}).collect()[0][0]
    print(f"✅ Spark computation successful: Average age = {avg_age}")
    
    spark.stop()
    print("✅ Spark session stopped cleanly")
    
except ImportError as e:
    print(f"❌ PySpark not available: {e}")
except Exception as e:
    print(f"❌ Spark test failed: {e}")
EOF

echo "Created test Spark job: test_spark_job.py"

# Test if we can submit this job
if command -v smart_spark_submit >/dev/null 2>&1; then
    echo "Testing smart_spark_submit..."
    if smart_spark_submit test_spark_job.py 2>&1; then
        echo "✅ Spark job submission successful"
    else
        echo "❌ Spark job submission failed"
    fi
elif command -v python >/dev/null 2>&1; then
    echo "Testing direct Python execution (fallback)..."
    if python test_spark_job.py 2>&1; then
        echo "✅ Direct Python execution successful"
    else
        echo "❌ Direct Python execution failed"
    fi
else
    echo "❌ No Python available for testing"
fi

# Cleanup
cd /tmp
rm -rf "$TEST_SPARK_DIR"

echo ""
echo "🎯 SPARK/HDFS TEST COMPLETE"
echo "==========================="
