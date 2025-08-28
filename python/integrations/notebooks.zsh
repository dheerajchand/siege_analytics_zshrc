#!/usr/bin/env zsh
# ============================================
# Jupyter & DataSpell Integration
# ============================================

# Start Jupyter with Spark configuration
jupyter_spark() {
    local port=${1:-8888}
    local dir=${2:-$(pwd)}
    
    python_log INFO "Starting Jupyter on port $port"
    
    # Ensure Jupyter is installed
    case "$PYTHON_MANAGER" in
        pyenv)
            # LAZY: pip install --quiet jupyter jupyterlab ipykernel
            ;;
        uv)
            uv # LAZY: pip install --quiet jupyter jupyterlab ipykernel
            ;;
    esac
    
    # Set Spark environment
    setup_spark_python
    
    # Create kernel if needed
    python -m ipykernel install --user --name="${PYTHON_MANAGER}_kernel" \
        --display-name="Python (${PYTHON_MANAGER})" 2>/dev/null
    
    # Start Jupyter Lab
    cd "$dir"
    
    case "$PYTHON_MANAGER" in
        pyenv)
            jupyter lab --port=$port --no-browser
            ;;
        uv)
            uv run jupyter lab --port=$port --no-browser
            ;;
    esac
}

# Setup DataSpell environment
dataspell_setup() {
    local project_dir=${1:-$(pwd)}
    
    python_log INFO "Setting up DataSpell environment"
    
    cd "$project_dir"
    
    # Ensure virtual environment exists
    if [[ ! -d ".venv" ]]; then
        create_venv
    fi
    
    source .venv/bin/activate
    
    # Install DataSpell requirements
    case "$PYTHON_MANAGER" in
        pyenv)
            # LAZY: pip install jupyter ipykernel pandas numpy matplotlib seaborn
            ;;
        uv)
            uv # LAZY: pip install jupyter ipykernel pandas numpy matplotlib seaborn
            ;;
    esac
    
    # Create DataSpell configuration
    cat > .dataspell_config.py << 'PY'
# DataSpell Configuration
import os
import sys

# Add project to path
sys.path.insert(0, os.path.dirname(__file__))

# Spark configuration (if using Spark)
try:
    from pyspark.sql import SparkSession
    spark = SparkSession.builder \
        .appName("DataSpell") \
        .config("spark.sql.execution.arrow.pyspark.enabled", "true") \
        .config("spark.sql.adaptive.enabled", "true") \
        .getOrCreate()
    print(f"✅ Spark {spark.version} initialized")
except ImportError:
    print("ℹ️ PySpark not installed")

# Import common libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Configure display
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', 100)
plt.style.use('seaborn-v0_8-darkgrid')

print("✅ DataSpell environment ready")
print(f"Python: {sys.version}")
print(f"Pandas: {pd.__version__}")
print(f"NumPy: {np.__version__}")
PY
    
    echo "✅ DataSpell setup complete"
    echo "   Config: .dataspell_config.py"
    echo "   Venv: .venv"
}

# Create notebook templates
create_notebook_templates() {
    local template_dir="$HOME/.notebook_templates"
    mkdir -p "$template_dir"
    
    # Jupyter template
    cat > "$template_dir/jupyter_template.ipynb" << 'JSON'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": ["# Project Title\n", "Description here"]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Standard imports\n",
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "\n",
    "# Display settings\n",
    "pd.set_option('display.max_columns', None)\n",
    "plt.style.use('seaborn-v0_8-darkgrid')\n",
    "%matplotlib inline"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Spark setup (if needed)\n",
    "from pyspark.sql import SparkSession\n",
    "\n",
    "spark = SparkSession.builder \\\n",
    "    .appName('Notebook') \\\n",
    "    .config('spark.sql.adaptive.enabled', 'true') \\\n",
    "    .getOrCreate()\n",
    "\n",
    "print(f'Spark version: {spark.version}')"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
JSON
    
    # DataSpell template
    cat > "$template_dir/dataspell_template.py" << 'PY'
# %% [markdown]
# # Project Title
# Description here

# %% [markdown]
# ## Setup

# %%
# Standard imports
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

# Display settings
pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', 100)
plt.style.use('seaborn-v0_8-darkgrid')

# %% [markdown]
# ## Spark Setup (if needed)

# %%
from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("DataSpell Analysis") \
    .config("spark.sql.adaptive.enabled", "true") \
    .getOrCreate()

print(f"Spark version: {spark.version}")

# %% [markdown]
# ## Data Loading

# %%
# Your code here

# %% [markdown]
# ## Analysis

# %%
# Your analysis here

# %% [markdown]
# ## Cleanup

# %%
spark.stop()
PY
    
    echo "✅ Templates created in $template_dir"
}

# Quick notebook starter
notebook_quick() {
    local type=${1:-jupyter}
    local port=${2:-8888}
    
    case "$type" in
        jupyter|jup|j)
            jupyter_spark $port
            ;;
        dataspell|ds|d)
            dataspell_setup
            ;;
        template|t)
            create_notebook_templates
            ;;
        *)
            echo "Usage: notebook_quick [jupyter|dataspell|template] [port]"
            ;;
    esac
}

# Aliases
alias pynb="jupyter_spark"
alias pyds="dataspell_setup"
alias pynb-templates="create_notebook_templates"
alias nbquick="notebook_quick"

# Export functions for use in existing configs
export -f jupyter_spark
export -f dataspell_setup
