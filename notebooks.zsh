# =====================================================
# NOTEBOOK SUPPORT MODULE (Jupyter + DataSpell)
# =====================================================

function start_jupyter_with_spark {
    local port="${1:-8889}"
    local directory="${2:-$(pwd)}"

    echo "🚀 Starting Jupyter Lab with optimized Spark integration..."
    echo "📁 Working directory: $directory"
    echo "🌐 Will be available at: http://localhost:$port"

    # Setup Spark Python paths using modular system
    if command -v setup_spark_python &>/dev/null; then
        setup_spark_python
    fi

    # Set up enhanced environment for Jupyter
    export JUPYTER_ENABLE_LAB=yes
    export PYSPARK_DRIVER_PYTHON=jupyter
    export PYSPARK_DRIVER_PYTHON_OPTS="lab --no-browser --port=$port --notebook-dir=$directory --ServerApp.token='' --ServerApp.password=''"
    
    # Ensure Spark Python paths are set up correctly for current Python manager
    if command -v setup_spark_python &>/dev/null; then
        setup_spark_python
    fi

    # Get dependencies (from Spark module if available)
    local deps=""
    if command -v get_spark_dependencies &>/dev/null; then
        deps=$(get_spark_dependencies)
    fi

    # Start with enhanced Spark configuration
    pyspark \
        --master "local[*]" \
        --driver-memory 4g \
        --executor-memory 2g \
        --conf spark.sql.adaptive.enabled=true \
        --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \
        --conf spark.ui.showConsoleProgress=false \
        --conf spark.log.level=WARN \
        $deps
}

function jupyter_spark {
    start_jupyter_with_spark "$@"
}

function setup_dataspell_spark {
    echo "🔧 Setting up optimal Spark configuration for DataSpell..."
    local dataspell_config="$HOME/.dataspell_spark_config.py"

    cat > "$dataspell_config" << DATASPELL_EOF
# DataSpell + Spark Configuration
# Copy this into your DataSpell notebook cells for optimal Spark setup

import os
import sys

# Set Spark environment variables
os.environ['SPARK_HOME'] = '${SPARK_HOME:-/opt/homebrew/opt/sdkman-cli/libexec/candidates/spark/current}'
os.environ['HADOOP_HOME'] = '${HADOOP_HOME:-/opt/homebrew/opt/sdkman-cli/libexec/candidates/hadoop/current}'
os.environ['JAVA_HOME'] = '${JAVA_HOME:-/opt/homebrew/opt/sdkman-cli/libexec/candidates/java/current}'

# Add Spark to Python path
sys.path.append(os.environ['SPARK_HOME'] + '/python')

from pyspark.sql import SparkSession
from pyspark.conf import SparkConf

def create_spark_session(app_name="DataSpell", memory_driver="4g", memory_executor="2g"):
    conf = SparkConf()
    conf.set("spark.driver.memory", memory_driver)
    conf.set("spark.executor.memory", memory_executor)
    conf.set("spark.sql.adaptive.enabled", "true")
    conf.set("spark.serializer", "org.apache.spark.serializer.KryoSerializer")
    conf.set("spark.ui.showConsoleProgress", "false")
    conf.set("spark.log.level", "WARN")

    spark = SparkSession.builder \\\\
        .appName(app_name) \\\\
        .config(conf=conf) \\\\
        .getOrCreate()

    spark.sparkContext.setLogLevel("WARN")
    
    print(f"✅ Spark session created: {spark.version}")
    print(f"✅ Master: {spark.sparkContext.master}")
    print(f"✅ UI: {spark.sparkContext.uiWebUrl}")

    return spark

# Usage: spark = create_spark_session("MyProject")
DATASPELL_EOF

    echo "✅ DataSpell configuration created at: $dataspell_config"
}

function dataspell_spark {
    setup_dataspell_spark
}

function notebook_help {
    echo "📓 Notebook Support Commands:"
    echo ""
    echo "🚀 Jupyter:"
    echo "   jupyter_spark [port] [dir]      - Start Jupyter Lab with Spark"
    echo "   start_jupyter_with_spark        - Full function name"
    echo ""
    echo "🔧 DataSpell:"
    echo "   dataspell_spark                 - Setup DataSpell configuration"
    echo "   setup_dataspell_spark           - Full function name"
    echo ""
    echo "💡 Quick start:"
    echo "   jupyter_spark 8889              - Start on port 8889"
    echo "   dataspell_spark                 - Get DataSpell setup code"
}

# Aliases
alias jlab='jupyter_spark'
alias jnotebook='start_jupyter_with_spark'

echo "📓 Notebook support module loaded - Jupyter & DataSpell ready"
