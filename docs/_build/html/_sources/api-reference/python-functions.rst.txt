Python Functions API Reference
===============================

This module provides comprehensive Python environment management, UV project handling, and data science workflow utilities integrated into the shell configuration system.

.. note::
   All functions support both PyEnv and UV workflows, with automatic detection and cross-shell compatibility (bash/zsh).

Environment Management Functions
-------------------------------

py_env_switch()
~~~~~~~~~~~~~~

**Function Definition:**

Intelligently switch between Python environments, supporting both PyEnv virtual environments and UV projects with automatic detection and activation.

.. code-block:: bash

   py_env_switch [target]
   # target: list, uv, or environment_name

**Examples and Elaboration:**

This function serves as the central hub for Python environment management:

.. code-block:: bash

   # List all available environments
   py_env_switch list
   # Output:
   # 🐍 Available Python Environments:
   # 
   # 📦 Pyenv Environments:
   #   * system
   #     3.11.7
   #     3.12.1
   #     ml_env
   #     data_science
   # 
   # ⚡ UV Projects:
   #   ✅ Current directory has UV project
   # 
   # Usage:
   #   py_env_switch <env_name>    # Switch to pyenv environment
   #   py_env_switch uv            # Activate UV project here

   # Switch to a PyEnv environment
   py_env_switch data_science
   # Output:
   # 🐍 Switching to pyenv environment: data_science
   # (data_science) $ 

   # Activate UV project in current directory
   py_env_switch uv
   # Output:
   # ⚡ Activating UV project: my_analysis
   # (.venv) $ 

   # Auto-setup UV project if .venv doesn't exist
   cd new_uv_project
   py_env_switch uv
   # Output:
   # 🔨 Setting up UV project...
   # [UV sync output...]
   # ⚡ Activating UV project: new_uv_project
   # (.venv) $ 

Environment Detection Logic:

1. **List Mode**: Shows all PyEnv environments and UV project status
2. **UV Mode**: Activates UV project in current directory, runs `uv sync` if needed
3. **Environment Name**: Switches to specified PyEnv environment with error handling

**Unit Tests:**

.. code-block:: bash

   # Test: List functionality
   test_py_env_list() {
       output=$(py_env_switch list)
       [[ "$output" == *"Available Python Environments"* ]]
   }
   
   # Test: UV project detection
   test_uv_project_detection() {
       mkdir test_project && cd test_project
       echo '[project]' > pyproject.toml
       echo 'name = "test"' >> pyproject.toml
       output=$(py_env_switch list)
       [[ "$output" == *"UV project in current directory"* ]]
       cd .. && rm -rf test_project
   }
   
   # Test: PyEnv environment switching
   test_pyenv_switch_invalid() {
       output=$(py_env_switch nonexistent_env 2>&1)
       [[ "$output" == *"not found"* ]]
   }

ds_project_init()
~~~~~~~~~~~~~~~~

**Function Definition:**

Initialize complete data science projects with UV, including directory structure, dependencies, and project type-specific packages.

.. code-block:: bash

   ds_project_init <project_name> [project_type]
   # project_types: basic (default), spark, geo

**Examples and Elaboration:**

Creates production-ready data science project structures:

.. code-block:: bash

   # Basic data science project
   ds_project_init customer_analysis
   # Output:
   # 🔬 Creating data science project: customer_analysis
   # 📦 Adding data science dependencies...
   # ✅ Data science project 'customer_analysis' created!
   # 🚀 Next steps:
   #   source .venv/bin/activate
   #   jupyter lab

   # Project with Spark dependencies
   ds_project_init big_data_analysis spark
   # Output:
   # 🔬 Creating data science project: big_data_analysis
   # 📦 Adding data science dependencies...
   # ⚡ Adding Spark dependencies...
   # ✅ Data science project 'big_data_analysis' created!

   # Geospatial analysis project
   ds_project_init geo_analysis geo
   # Output:
   # 🔬 Creating data science project: geo_analysis
   # 📦 Adding data science dependencies...
   # 🌍 Adding geospatial dependencies...
   # ✅ Data science project 'geo_analysis' created!

Project structure created:

.. code-block:: text

   project_name/
   ├── pyproject.toml          # UV project configuration
   ├── .venv/                  # Virtual environment
   ├── notebooks/              # Jupyter notebooks
   ├── data/
   │   ├── raw/               # Raw data files
   │   └── processed/         # Cleaned/processed data
   ├── src/                   # Source code modules
   └── tests/                 # Unit tests

Dependencies by project type:

- **Basic**: pandas, numpy, matplotlib, seaborn, jupyter, ipykernel
- **Spark**: + pyspark, findspark
- **Geo**: + geopandas, folium, contextily

**Unit Tests:**

.. code-block:: bash

   # Test: Basic project creation
   test_ds_project_basic() {
       ds_project_init test_project basic
       [[ -f "test_project/pyproject.toml" ]] && [[ -d "test_project/notebooks" ]]
       rm -rf test_project
   }
   
   # Test: Spark project dependencies
   test_ds_project_spark() {
       ds_project_init test_spark spark
       grep -q "pyspark" test_spark/pyproject.toml
       local result=$?
       rm -rf test_spark
       [[ $result -eq 0 ]]
   }
   
   # Test: Directory structure
   test_ds_project_structure() {
       ds_project_init test_structure
       [[ -d "test_structure/data/raw" ]] && 
       [[ -d "test_structure/data/processed" ]] &&
       [[ -d "test_structure/src" ]] &&
       [[ -d "test_structure/tests" ]]
       local result=$?
       rm -rf test_structure
       [[ $result -eq 0 ]]
   }

python_info()
~~~~~~~~~~~~

**Function Definition:**

Display comprehensive information about the current Python environment, including version, location, virtual environments, and project status.

.. code-block:: bash

   python_info()

**Examples and Elaboration:**

.. code-block:: bash

   # System Python environment
   python_info
   # Output:
   # 🐍 Python Environment Status
   # ============================
   # 
   # Current Python:
   #   Version: Python 3.11.7
   #   Location: /usr/local/bin/python
   #   Virtual Env: None
   #   Pyenv: system
   #   UV: 0.2.18
   # 
   # 📦 No UV project in current directory

   # Inside UV project
   cd my_uv_project
   python_info
   # Output:
   # 🐍 Python Environment Status
   # ============================
   # 
   # Current Python:
   #   Version: Python 3.11.7
   #   Location: /path/to/project/.venv/bin/python
   #   Virtual Env: /path/to/project/.venv
   #   Pyenv: 3.11.7
   #   UV: 0.2.18
   # 
   # 📦 Current Project:
   #   UV Project: ✅ my_uv_project
   #   Virtual Env: ✅ Ready

   # UV project needs setup
   cd unsynced_project
   python_info
   # Output:
   # [Previous sections...]
   # 📦 Current Project:
   #   UV Project: ✅ unsynced_project
   #   Virtual Env: ❌ Run 'uv sync'

Information displayed:

1. **Current Python**: Version, binary location, active virtual environment
2. **Tools**: PyEnv version, UV version (if available)
3. **Project Status**: UV project detection, virtual environment status

**Unit Tests:**

.. code-block:: bash

   # Test: Basic info display
   test_python_info_basic() {
       output=$(python_info)
       [[ "$output" == *"Python Environment Status"* ]] &&
       [[ "$output" == *"Current Python"* ]]
   }
   
   # Test: UV project detection
   test_python_info_uv_project() {
       mkdir test_project && cd test_project
       echo '[project]' > pyproject.toml
       echo 'name = "test"' >> pyproject.toml
       output=$(python_info)
       [[ "$output" == *"UV Project: ✅"* ]]
       cd .. && rm -rf test_project
   }

Core Utility Functions
---------------------

command_exists()
~~~~~~~~~~~~~~~

**Function Definition:**

Check if a command or executable is available in the system PATH, providing a reliable cross-shell method for dependency verification.

.. code-block:: bash

   command_exists <command_name>

**Examples and Elaboration:**

.. code-block:: bash

   # Check for Python tools
   if command_exists python3; then
       echo "Python 3 is available: $(python3 --version)"
   else
       echo "Python 3 not found"
   fi

   # Conditional tool usage
   if command_exists uv; then
       echo "Using UV for package management"
       uv --version
   elif command_exists pip; then
       echo "Falling back to pip"
       pip --version
   fi

   # Multiple command check
   for cmd in python3 pip uv pyenv; do
       if command_exists "$cmd"; then
           echo "✅ $cmd: Available"
       else
           echo "❌ $cmd: Not found"
       fi
   done
   # Output:
   # ✅ python3: Available
   # ✅ pip: Available
   # ✅ uv: Available
   # ❌ pyenv: Not found

**Unit Tests:**

.. code-block:: bash

   # Test: Existing command detection
   test_command_exists_positive() {
       command_exists ls  # Should exist on all systems
   }
   
   # Test: Non-existing command detection
   test_command_exists_negative() {
       ! command_exists nonexistent_command_12345
   }

is_online()
~~~~~~~~~~

**Function Definition:**

Check internet connectivity by attempting to ping a reliable external host, useful for conditional operations that require network access.

.. code-block:: bash

   is_online()

**Examples and Elaboration:**

.. code-block:: bash

   # Basic connectivity check
   if is_online; then
       echo "Internet connection available"
       pip install --upgrade pip
   else
       echo "Offline mode - using cached packages"
   fi

   # Status string helper
   echo "Network status: $(is_online_status)"
   # Output: Network status: online

   # Conditional UV operations
   if is_online; then
       echo "📡 Online - updating dependencies"
       uv sync --upgrade
   else
       echo "📴 Offline - using existing environment"
       uv sync --offline
   fi

**Unit Tests:**

.. code-block:: bash

   # Test: Online status (requires connectivity)
   test_is_online() {
       # This test may fail in isolated environments
       is_online || echo "Warning: No internet connectivity for testing"
   }
   
   # Test: Status string function
   test_is_online_status() {
       status=$(is_online_status)
       [[ "$status" == "online" ]] || [[ "$status" == "offline" ]]
   }

mkcd()
~~~~~

**Function Definition:**

Create a directory and immediately change into it, combining `mkdir -p` and `cd` into a single convenient operation.

.. code-block:: bash

   mkcd <directory_path>

**Examples and Elaboration:**

.. code-block:: bash

   # Create and enter single directory
   mkcd new_project
   pwd  # /current/path/new_project

   # Create nested directory structure
   mkcd ~/projects/data_analysis/notebooks
   pwd  # /home/user/projects/data_analysis/notebooks

   # Data science workflow
   mkcd ~/ds_projects/customer_segmentation
   ds_project_init . basic  # Initialize in current directory
   source .venv/bin/activate
   jupyter lab

**Unit Tests:**

.. code-block:: bash

   # Test: Directory creation and navigation
   test_mkcd_basic() {
       original_dir=$(pwd)
       mkcd test_mkcd_dir
       [[ "$(basename $(pwd))" == "test_mkcd_dir" ]] && [[ -d "$(pwd)" ]]
       cd "$original_dir" && rmdir test_mkcd_dir
   }
   
   # Test: Nested directory creation
   test_mkcd_nested() {
       original_dir=$(pwd)
       mkcd deep/nested/directory
       [[ -d "$(pwd)" ]]
       cd "$original_dir" && rm -rf deep
   }

Module Management Functions
--------------------------

load_module()
~~~~~~~~~~~~

**Function Definition:**

Dynamically load configuration modules from the modular shell system, with error handling and status reporting.

.. code-block:: bash

   load_module <module_name>

**Examples and Elaboration:**

.. code-block:: bash

   # Load specific modules
   load_module spark
   # Output: ✅ Loaded module: spark

   load_module database
   # Output: ✅ Loaded module: database

   # Handle missing modules gracefully
   load_module nonexistent
   # Output: ⚠️  Module not found: nonexistent (/path/to/config/nonexistent.zsh)

   # Conditional module loading
   if command_exists docker; then
       load_module docker
   fi

**Unit Tests:**

.. code-block:: bash

   # Test: Valid module loading
   test_load_module_valid() {
       # Assume core module exists
       load_module core >/dev/null 2>&1
       [[ $? -eq 0 ]]
   }
   
   # Test: Invalid module handling
   test_load_module_invalid() {
       load_module nonexistent_module >/dev/null 2>&1
       [[ $? -ne 0 ]]
   }

list_modules()
~~~~~~~~~~~~~

**Function Definition:**

Display all available configuration modules with descriptions extracted from module files.

.. code-block:: bash

   list_modules()

**Examples and Elaboration:**

.. code-block:: bash

   list_modules
   # Output:
   # 📦 Available Configuration Modules:
   # 
   #   📄 core
   #      💡 Essential shell settings, aliases, and basic functionality
   #   📄 spark
   #      💡 Cross-platform Apache Spark configuration and utilities
   #   📄 docker
   #      💡 Docker and container management utilities
   #   📄 database
   #      💡 Database connection and management tools

**Unit Tests:**

.. code-block:: bash

   # Test: Module listing
   test_list_modules() {
       output=$(list_modules)
       [[ "$output" == *"Available Configuration Modules"* ]]
   }

Aliases and Shortcuts
--------------------

The module provides convenient aliases for all major Python workflow functions:

.. code-block:: bash

   # Python environment management
   py-switch           # py_env_switch
   py-list             # py_env_switch list  
   py-info             # python_info
   py-uv               # py_env_switch uv
   
   # Data science project management
   ds-init             # ds_project_init
   ds-basic            # ds_project_init (basic type)
   ds-spark            # ds_project_init (spark type)
   ds-geo              # ds_project_init (geo type)
   
   # UV package management
   uv-init             # uv init
   uv-add              # uv add
   uv-sync             # uv sync
   uv-run              # uv run

Complete Usage Examples
----------------------

**Example 1: Setting up a new data science project**

.. code-block:: bash

   # Create and initialize project
   ds_project_init market_analysis spark
   cd market_analysis
   
   # Verify environment
   py_info
   
   # Start Jupyter Lab
   source .venv/bin/activate
   jupyter lab

**Example 2: Environment switching workflow**

.. code-block:: bash

   # List available environments
   py-list
   
   # Switch to existing PyEnv environment for ML work
   py-switch ml_production
   
   # Work on a UV project
   cd ~/projects/data_pipeline
   py-switch uv  # Activates UV project
   
   # Check current environment status
   py-info

**Example 3: Cross-platform Python setup**

.. code-block:: bash

   # Check what's available
   for tool in python3 pip uv pyenv; do
       if command_exists "$tool"; then
           echo "✅ $tool: $(which $tool)"
       else
           echo "❌ $tool: Not installed"
       fi
   done
   
   # Initialize appropriate project type
   if command_exists uv; then
       ds-init new_project
   else
       echo "Install UV for modern Python dependency management"
   fi

**Example 4: Automated environment detection**

.. code-block:: bash

   # Function to auto-activate environments
   auto_activate_python() {
       if [[ -f "pyproject.toml" ]]; then
           echo "🔍 UV project detected"
           py-switch uv
       elif [[ -f ".python-version" ]]; then
           local version=$(cat .python-version)
           echo "🔍 PyEnv version detected: $version"
           py-switch "$version"
       else
           echo "ℹ️  No Python project configuration found"
       fi
   }
   
   # Use in directory navigation
   cd ~/projects/my_analysis
   auto_activate_python

Integration with Other Modules
-----------------------------

**With Spark Module:**

.. code-block:: bash

   # Setup Spark-enabled data science environment
   ds-init spark_analysis spark
   cd spark_analysis
   py-switch uv
   
   # Load Spark module and start cluster
   load_module spark
   spark-start
   
   # Run Spark job with proper Python environment
   smart_spark_submit analysis.py

**With Docker Module:**

.. code-block:: bash

   # Python development in containers
   if [[ "$ZSH_IS_DOCKER" == "true" ]]; then
       echo "🐳 Container environment detected"
       # Use system Python in containers
       py-info
   else
       # Full environment switching on host
       py-switch production_env
   fi

**Cross-Shell Compatibility:**

.. code-block:: bash

   # Functions work in both bash and zsh
   # Bash usage:
   bash -c "source ~/.config/zsh/config/core.zsh; py_info"
   
   # ZSH usage:  
   zsh -c "source ~/.config/zsh/config/core.zsh; py_info"

This comprehensive Python environment management system provides everything needed for modern Python development workflows, from simple script execution to complex data science projects with automatic environment detection and cross-platform compatibility.