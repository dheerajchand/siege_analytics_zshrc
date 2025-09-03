# 🔬 Data Science Workflows

## 🎯 Geospatial Data Analysis

### Environment Setup
```bash
# 1. Activate geospatial environment  
setup_pyenv
pyenv activate geo31111         # Your geospatial virtualenv

# 2. Load big data stack
load_big_data                   # Loads 74K Spark system + Hadoop

# 3. Start analysis environment
jupyter_spark 8889              # Spark-enabled Jupyter

# Available tools:
# - Apache Spark with Sedona (geospatial)
# - Pandas, GeoPandas, Shapely
# - Hadoop HDFS for large datasets
# - GraphFrames for network analysis
```

### Example Project
```bash
# Create new geospatial project
mkdir geo_analysis && cd geo_analysis
echo "geo31111" > .python-version    # Auto-activate environment

# Load tools and start work
load_big_data
start_hadoop                    # Start HDFS + YARN if needed  
jupyter_spark 8889

# Access web UIs:
open http://localhost:9870      # HDFS management
open http://localhost:8088      # YARN cluster
open http://localhost:8889      # Jupyter Lab
```

## 🤖 Machine Learning Workflows

```bash
# ML environment  
setup_pyenv
pyenv activate ml_env
pip install torch tensorflow scikit-learn

# Big data ML
load_big_data
# Use Spark MLlib for distributed ML
```

## 📊 Performance Analytics

```bash
# Load performance testing
python_benchmark               # Loads utils/benchmarks.zsh
# Run performance tests on your data pipeline
```
