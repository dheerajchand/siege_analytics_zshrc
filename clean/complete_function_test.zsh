#!/usr/bin/env zsh
# Final verification - all critical functions

source ~/.config/zsh/clean/zshrc >/dev/null 2>&1

echo "═══════════════════════════════════════════════════════════"
echo "FINAL VERIFICATION - ALL CRITICAL FUNCTIONS"
echo "═══════════════════════════════════════════════════════════"
echo ""

PASS=0
FAIL=0

test_fn() {
    if eval "$1" >/dev/null 2>&1; then
        echo "✅ $2"
        ((PASS++))
    else
        echo "❌ $2"
        ((FAIL++))
    fi
}

# Utils
test_fn "command_exists ls" "command_exists"
test_fn "is_online" "is_online"

# Python
test_fn "python_status" "python_status"
test_fn "py_env_switch geo31111" "py_env_switch"

# Credentials
store_credential "test_$$" "u" "p" >/dev/null 2>&1
r=$(get_credential "test_$$" "u" 2>/dev/null)
[[ "$r" == "p" ]] && echo "✅ credentials" && ((PASS++)) || (echo "❌ credentials" && ((FAIL++)))
security delete-generic-password -s "test_$$" -a "u" 2>/dev/null

# Hadoop - all HDFS operations
echo "test" > /tmp/fv$$
test_fn "hdfs_put /tmp/fv$$ /fv$$" "hdfs_put"
test_fn "hdfs_ls /" "hdfs_ls"
test_fn "hdfs_get /fv$$ /tmp/fv_get$$" "hdfs_get"
test_fn "hdfs_rm /fv$$" "hdfs_rm"
test_fn "hadoop_status" "hadoop_status"
test_fn "yarn_cluster_info" "yarn_cluster_info"
rm /tmp/fv$$ /tmp/fv_get$$ 2>/dev/null

# Spark
test_fn "spark_status" "spark_status"

# Spark job
cat > /tmp/job$$.py << 'EOF'
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("final").getOrCreate()
print("JOB:PASS")
spark.stop()
EOF

if spark-submit --master spark://localhost:7077 /tmp/job$$.py 2>&1 | grep -q "JOB:PASS"; then
    echo "✅ spark job submission"
    ((PASS++))
else
    echo "❌ spark job submission"
    ((FAIL++))
fi
rm /tmp/job$$.py

# Spark + HDFS
cat > /tmp/hdfs$$.py << 'EOF'
from pyspark.sql import SparkSession  
spark = SparkSession.builder.getOrCreate()
df = spark.createDataFrame([(1,"a")], ["i","v"])
df.write.mode("overwrite").parquet("hdfs://localhost:9000/final_test")
df2 = spark.read.parquet("hdfs://localhost:9000/final_test")
print(f"HDFS:PASS" if df2.count() == 1 else "HDFS:FAIL")
spark.stop()
EOF

if spark-submit --master spark://localhost:7077 /tmp/hdfs$$.py 2>&1 | grep -q "HDFS:PASS"; then
    echo "✅ Spark + HDFS integration"
    ((PASS++))
else
    echo "❌ Spark + HDFS integration"
    ((FAIL++))
fi

hdfs dfs -rm -r /final_test 2>&1 >/dev/null
rm /tmp/hdfs$$.py

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "RESULTS: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]] && echo "🎉 ALL CRITICAL FUNCTIONS WORKING" || echo "⚠️  Some failures"

