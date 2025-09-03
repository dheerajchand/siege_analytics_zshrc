Python Management System
=========================

The Python management system is a sophisticated 8-module subsystem that provides intelligent switching between `pyenv` and `uv` package managers, rich virtual environment management, and seamless integration with the big data stack.

System Overview
---------------

Core Architecture
~~~~~~~~~~~~~~~~~

- **Modular Design**: 8 specialized modules for different aspects of Python management
- **Intelligent Switching**: Automatic detection and switching between pyenv and uv
- **Performance Optimized**: Lazy loading and caching for fast startup
- **Integration Ready**: Seamless integration with Spark, Hadoop, and development tools

Module Structure
~~~~~~~~~~~~~~~~

.. code-block:: text

   python/
   ├── init.zsh                    # Main initialization and module loader
   ├── managers/
   │   ├── pyenv.zsh              # pyenv-specific functionality
   │   └── uv.zsh                 # uv-specific functionality
   ├── integrations/
   │   ├── notebooks.zsh          # Jupyter/notebook integration
   │   └── spark.zsh              # Spark integration
   ├── utils/
   │   ├── benchmarks.zsh         # Performance testing
   │   └── health.zsh             # System health monitoring
   └── projects/                  # Project-specific configurations

Python Manager Switching System
-------------------------------

Intelligent Manager Detection
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The system automatically detects and switches between Python managers based on:

1. **Current Directory Context**: Detects `.python-version` (pyenv) or `pyproject.toml` (uv)
2. **Environment Variables**: `PYTHON_MANAGER` setting
3. **Available Tools**: Checks which managers are installed
4. **Project Requirements**: Analyzes project structure

Manager Switching Functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~

``switch_python_manager(manager)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Switch to pyenv
   switch_python_manager pyenv

   # Switch to uv
   switch_python_manager uv

   # Auto-detect based on current directory
   switch_python_manager auto

``setup_pyenv()``
^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Initialize pyenv with full configuration
   setup_pyenv

   # Features:
   # - Sets PYENV_ROOT and PATH
   # - Initializes pyenv and pyenv-virtualenv
   # - Sets default Python version
   # - Configures Spark Python paths
   # - Creates helpful aliases

``setup_uv()``
^^^^^^^^^^^^^^

.. code-block:: bash

   # Initialize uv with full configuration
   setup_uv

   # Features:
   # - Sets UV environment variables
   # - Configures Python preference to "managed"
   # - Sets up automatic Python downloads
   # - Creates uv aliases (uvpy, uvrun, uvsync, etc.)
   # - Configures Spark Python paths

Automatic Environment Detection
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The system automatically detects the appropriate Python manager:

.. code-block:: bash

   # In a pyenv project (has .python-version)
   cd my-pyenv-project
   python_status  # Automatically uses pyenv

   # In a uv project (has pyproject.toml)
   cd my-uv-project
   python_status  # Automatically uses uv

   # In a mixed environment
   cd mixed-project
   switch_python_manager auto  # Detects and switches appropriately

Virtual Environment Management
------------------------------

pyenv Virtual Environments
~~~~~~~~~~~~~~~~~~~~~~~~~~

``pyenv_install_latest(major_version)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Install latest Python 3.11
   pyenv_install_latest 3

   # Install latest Python 3.12
   pyenv_install_latest 3.12

``create_pyenv_environment(name, python_version)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Create a new virtual environment
   create_pyenv_environment data_science 3.11.7

   # Activate the environment
   pyenv activate data_science

``pyenv_status()``
^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Show comprehensive pyenv status
   pyenv_status

   # Output includes:
   # - Current Python version
   # - Active virtual environment
   # - Available versions
   # - Environment variables
   # - Spark integration status

uv Virtual Environments
~~~~~~~~~~~~~~~~~~~~~~~

``uv_init_project(python_version)``
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Initialize a new uv project
   uv_init_project 3.11

   # Creates:
   # - pyproject.toml with project configuration
   # - .venv virtual environment
   # - Development dependencies (pytest, black, ruff)

``uv_project_status()``
^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Show comprehensive uv project status
   uv_project_status

   # Output includes:
   # - Project configuration
   # - Virtual environment status
   # - Dependencies
   # - Python version
   # - Spark integration status

Environment Status and Health
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``python_status()``
^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Comprehensive Python environment status
   python_status

   # Shows:
   # - Active manager (pyenv/uv)
   # - Current Python version
   # - Virtual environment status
   # - PATH configuration
   # - Spark integration
   # - Performance metrics

``python_health_check()``
^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Complete health check of Python system
   python_health_check

   # Checks:
   # - Manager availability
   # - Python installation
   # - Virtual environment integrity
   # - Package manager functionality
   # - Spark integration
   # - Performance benchmarks

Performance Optimization
------------------------

Lazy Loading System
~~~~~~~~~~~~~~~~~~~

The Python system uses intelligent lazy loading:

.. code-block:: bash

   # Core modules loaded immediately
   # - init.zsh (always loaded)
   # - managers/pyenv.zsh (if pyenv detected)
   # - managers/uv.zsh (if uv detected)

   # Optional modules loaded on demand
   # - integrations/notebooks.zsh (when jupyter commands used)
   # - integrations/spark.zsh (when Spark functions called)
   # - utils/benchmarks.zsh (when performance testing needed)
   # - utils/health.zsh (when health checks run)

Caching System
~~~~~~~~~~~~~~

.. code-block:: bash

   # Module loading cache
   declare -A PYTHON_LOADED_MODULES

   # Manager state cache
   export PYTHON_MANAGER_STATE_FILE="$HOME/.config/python_manager_state"

   # Performance metrics cache
   export PYTHON_PERFORMANCE_CACHE="$HOME/.config/python_performance_cache"

Performance Benchmarks
~~~~~~~~~~~~~~~~~~~~~~

``python_benchmark()``
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Run comprehensive performance benchmarks
   python_benchmark

   # Tests:
   # - Module loading times
   # - Virtual environment activation speed
   # - Package installation performance
   # - Spark integration overhead
   # - Memory usage
   # - Startup time impact

Spark Integration
-----------------

Automatic Spark Python Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The system automatically configures Spark to use the correct Python:

.. code-block:: bash

   # For pyenv environments
   setup_pyenv
   # Automatically sets:
   # export PYSPARK_PYTHON=$(pyenv which python)
   # export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON

   # For uv environments
   setup_uv
   # Automatically sets:
   # export PYSPARK_PYTHON=$(uv run which python)
   # export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON

Spark-Aware Environment Switching
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Switch Python manager and update Spark configuration
   switch_python_manager pyenv
   setup_spark_python  # Updates Spark Python paths

   # Or automatically
   switch_python_manager auto  # Detects and configures everything

Jupyter Integration
-------------------

``jupyter_spark(port)``
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Start Jupyter with Spark integration
   jupyter_spark 8889

   # Features:
   # - Automatic Spark configuration
   # - Current Python environment
   # - Geospatial libraries (if available)
   # - Custom Jupyter configuration
   # - Port management

``jupyter_lab_spark(port)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Start JupyterLab with Spark integration
   jupyter_lab_spark 8888

   # Features:
   # - JupyterLab interface
   # - Spark integration
   # - Current Python environment
   # - Extension management

Development Tools Integration
-----------------------------

IDE Integration
~~~~~~~~~~~~~~~

The system provides seamless integration with:

- **Cursor IDE**: Automatic Python path detection
- **DataSpell**: JetBrains data science IDE
- **VS Code**: Python extension compatibility
- **PyCharm**: Professional Python IDE

Package Management
~~~~~~~~~~~~~~~~~~

pyenv + pip
^^^^^^^^^^^

.. code-block:: bash

   # Traditional pip workflow
   pyenv activate my_project
   pip install -r requirements.txt
   pip install -e .  # Editable installs

uv Modern Workflow
^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Modern uv workflow
   uv add fastapi uvicorn
   uv add --dev pytest black ruff
   uv sync  # Install all dependencies
   uv run python main.py  # Run with managed environment

Configuration Options
---------------------

Environment Variables
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Core configuration
   export PYTHON_MANAGER="pyenv"  # or "uv" or "auto"
   export PYTHON_DEBUG="0"        # Enable debug logging
   export PYTHON_AUTOLOAD_MODULES="0"  # Auto-load all modules

   # Performance tuning
   export PYTHON_CACHE_ENABLED="1"     # Enable caching
   export PYTHON_LAZY_LOADING="1"      # Enable lazy loading
   export PYTHON_PERFORMANCE_MONITORING="1"  # Monitor performance

   # Integration settings
   export PYTHON_SPARK_INTEGRATION="1"  # Enable Spark integration
   export PYTHON_JUPYTER_INTEGRATION="1"  # Enable Jupyter integration

Manager-Specific Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

pyenv Configuration
^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # ~/.pyenvrc (if exists)
   export PYENV_ROOT="$HOME/.pyenv"
   export PATH="$PYENV_ROOT/bin:$PATH"

   # Auto-activate virtual environments
   export PYENV_VIRTUALENV_AUTO_ACTIVATE="1"

uv Configuration
^^^^^^^^^^^^^^^^

.. code-block:: bash

   # ~/.config/uv/uv.toml
   [tool.uv]
   python-preference = "managed"
   python-downloads = "automatic"
   compile-bytecode = true
   link-mode = "copy"

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

Manager Not Found
^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check if manager is installed
   command -v pyenv
   command -v uv

   # Reinstall if needed
   curl https://pyenv.run | bash  # pyenv
   curl -LsSf https://astral.sh/uv/install.sh | sh  # uv

Virtual Environment Issues
^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check virtual environment status
   python_status

   # Recreate if corrupted
   pyenv virtualenv-delete my_env
   pyenv virtualenv 3.11.7 my_env

Spark Integration Issues
^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check Spark Python configuration
   echo "PYSPARK_PYTHON: $PYSPARK_PYTHON"
   echo "PYSPARK_DRIVER_PYTHON: $PYSPARK_DRIVER_PYTHON"

   # Reconfigure Spark integration
   setup_spark_python

Performance Issues
^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Run performance diagnostics
   python_benchmark

   # Check module loading times
   python_health_check

   # Optimize configuration
   export PYTHON_AUTOLOAD_MODULES="0"  # Disable auto-loading
   export PYTHON_LAZY_LOADING="1"      # Enable lazy loading

Debug Mode
~~~~~~~~~~

.. code-block:: bash

   # Enable debug logging
   export PYTHON_DEBUG="1"

   # Reload Python system
   source ~/.config/zsh/python/init.zsh

   # Check debug output
   python_status  # Will show detailed debug information

Advanced Usage Examples
-----------------------

Data Science Workflow
~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Create data science environment
   create_pyenv_environment data_science 3.11.7
   pyenv activate data_science

   # Install data science packages
   pip install pandas numpy matplotlib seaborn jupyter

   # Start Spark-enabled Jupyter
   load_big_data
   jupyter_spark 8889

Modern Web Development
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Create uv project
   mkdir my_api && cd my_api
   uv_init_project 3.12

   # Add dependencies
   uv add fastapi uvicorn
   uv add --dev pytest black ruff

   # Run development server
   uv run uvicorn main:app --reload

Mixed Environment Project
~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Project uses both pyenv and uv
   cd mixed_project

   # Switch to pyenv for legacy code
   switch_python_manager pyenv
   pyenv activate legacy_env

   # Switch to uv for new code
   switch_python_manager uv
   uv run python new_code.py

Spark Development
~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Setup Python environment for Spark
   setup_pyenv
   pyenv activate spark_dev

   # Configure Spark integration
   setup_spark_python

   # Start Spark-enabled Jupyter
   load_big_data
   jupyter_spark 8889

   # In Jupyter, Spark is automatically configured

Best Practices
--------------

Project Organization
~~~~~~~~~~~~~~~~~~~~

1. **Use pyenv for legacy projects** with requirements.txt
2. **Use uv for new projects** with pyproject.toml
3. **Keep environments isolated** per project
4. **Document Python version requirements**

Performance Optimization
~~~~~~~~~~~~~~~~~~~~~~~~

1. **Enable lazy loading** for faster startup
2. **Use caching** for repeated operations
3. **Monitor performance** with benchmarks
4. **Optimize module loading** order

Integration Management
~~~~~~~~~~~~~~~~~~~~~~

1. **Configure Spark integration** after Python setup
2. **Use appropriate Jupyter variants** for your needs
3. **Test integration** with health checks
4. **Monitor system resources** during heavy operations

.. note::

   This Python management system provides enterprise-grade Python environment management with intelligent switching, performance optimization, and seamless integration with the big data stack.
