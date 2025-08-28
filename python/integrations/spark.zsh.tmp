#!/usr/bin/env zsh
# ============================================
# Spark Integration for Python
# ============================================

# Setup Spark Python paths based on current Python manager
setup_spark_python() {
    # Only set if not already configured by notebook tools (like Jupyter)
    if [[ -z "$PYSPARK_DRIVER_PYTHON" || "$PYSPARK_DRIVER_PYTHON" == "python" ]]; then
        case "${PYTHON_MANAGER:-pyenv}" in
            pyenv)
                if command -v pyenv &>/dev/null; then
                    export PYSPARK_PYTHON=$(pyenv which python)
                    export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
                else
                    export PYSPARK_PYTHON=$(which python3)
                    export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
                fi
                ;;
            uv)
                if command -v uv &>/dev/null; then
                    export PYSPARK_PYTHON=$(uv run which python)
                    export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
                else
                    export PYSPARK_PYTHON=$(which python3)
                    export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
                fi
                ;;
            *)
                export PYSPARK_PYTHON=$(which python3)
                export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
                ;;
        esac
    fi
}

# Initialize Spark project
pyspark_init() {
    local name=$1
    local python_version=${2:-3.11}
    
    if [[ -z "$name" ]]; then
        echo "Usage: pyspark_init <project-name> [python-version]"
        return 1
    fi
    
    mkdir -p "$name"
    cd "$name"
    
    case "$PYTHON_MANAGER" in
        pyenv)
            pyenv local "$python_version"
            python -m venv .venv
            source .venv/bin/activate
            # LAZY: pip install pyspark pandas pyarrow numpy
            ;;
        uv)
            uv init --python "$python_version"
            uv venv
            source .venv/bin/activate
            uv add pyspark pandas pyarrow numpy
            ;;
    esac
    
    mkdir -p src tests data output
    
    cat > src/main.py << 'PY'
from pyspark.sql import SparkSession
import pandas as pd

def main():
    spark = SparkSession.builder \
        .appName("MyApp") \
        .config("spark.sql.adaptive.enabled", "true") \
        .getOrCreate()
    
    print(f"Spark version: {spark.version}")
    print(f"Python version: {spark.sparkContext.pythonVer}")
    
    # Your code here
    
    spark.stop()

if __name__ == "__main__":
    main()
PY
    
    echo "✅ Spark project created: $name"
    echo "   Run: python src/main.py"
}

# Wrapper for Spark submit
spark_submit_universal() {
    setup_spark_python
    
    # Call your existing smart_spark_submit if it exists
    if type smart_spark_submit > /dev/null; then
        smart_spark_submit "$@"
    else
        spark-submit "$@"
    fi
}

alias pyspark-init="pyspark_init"
alias pyspark-submit="spark_submit_universal"
