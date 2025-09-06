Core Functions API Reference
=============================

This section documents all core functions with their definitions, usage examples, and corresponding unit tests.

.. contents:: Functions in this module
   :local:
   :depth: 2

Essential Shell Utilities
--------------------------

command_exists()
~~~~~~~~~~~~~~~~

**Function Definition:**

.. code-block:: bash

   command_exists() {
       # Check if a command exists in the system
       # 
       # Args:
       #     command (str): Name of command to check
       #
       # Returns:
       #     0: Command exists
       #     1: Command not found
       command -v "$1" >/dev/null 2>&1
   }

**Examples and Elaboration:**

The ``command_exists`` function is a fundamental utility that safely checks for command availability without generating error output. This is essential for conditional loading of modules and graceful degradation.

.. code-block:: bash

   # Basic usage - check if a command exists
   if command_exists "docker"; then
       echo "Docker is available"
       load_docker_module
   else
       echo "Docker not found - skipping Docker integration"
   fi

   # Use in conditional statements
   command_exists "python" && echo "Python found" || echo "Python missing"

   # Check multiple commands
   for cmd in "git" "python" "node" "java"; do
       if command_exists "$cmd"; then
           echo "✅ $cmd: Available"
       else
           echo "❌ $cmd: Missing"
       fi
   done

   # Use in function definitions for robust error handling
   setup_development_env() {
       local required_commands=("git" "python" "node")
       for cmd in "${required_commands[@]}"; do
           if ! command_exists "$cmd"; then
               echo "Error: Required command '$cmd' not found"
               return 1
           fi
       done
       echo "All required commands available"
   }

**Unit Tests:**

.. code-block:: bash

   # Test: command_exists with existing command
   test_command_exists_with_existing_command() {
       # Should return 0 for commands that exist
       command_exists "bash"
       assert_equals $? 0 "command_exists should return 0 for existing commands"
   }

   # Test: command_exists with non-existing command  
   test_command_exists_with_missing_command() {
       # Should return 1 for commands that don't exist
       command_exists "nonexistent_command_12345"
       assert_equals $? 1 "command_exists should return 1 for missing commands"
   }

   # Test: command_exists with empty input
   test_command_exists_with_empty_input() {
       command_exists ""
       assert_equals $? 1 "command_exists should return 1 for empty input"
   }

   # Test: command_exists produces no output
   test_command_exists_silent_operation() {
       local output=$(command_exists "nonexistent_command" 2>&1)
       assert_equals "$output" "" "command_exists should produce no output"
   }

mkcd()
~~~~~~

**Function Definition:**

.. code-block:: bash

   mkcd() {
       # Create directory and change into it
       #
       # Args:
       #     directory_path (str): Path to directory to create
       #
       # Returns:
       #     0: Success
       #     1: Failed to create or enter directory
       mkdir -p "$1" && cd "$1"
   }

**Examples and Elaboration:**

The ``mkcd`` function combines the common pattern of creating a directory and immediately entering it. The ``-p`` flag ensures parent directories are created as needed, and the ``&&`` ensures we only change directories if creation succeeds.

.. code-block:: bash

   # Basic usage - create and enter directory
   mkcd "new_project"
   # Creates 'new_project' directory and changes into it

   # Create nested directories
   mkcd "projects/data_science/experiment_1"
   # Creates full path: projects/data_science/experiment_1

   # Use in project setup workflows
   setup_project() {
       local project_name="$1"
       mkcd "$project_name" || {
           echo "Failed to create project directory: $project_name"
           return 1
       }
       
       # Create project structure
       mkdir -p {src,tests,docs,data}
       echo "Project $project_name created successfully"
   }

   # Temporary directory creation
   create_temp_workspace() {
       local temp_dir="/tmp/workspace_$(date +%s)"
       mkcd "$temp_dir"
       echo "Working in temporary directory: $PWD"
   }

   # Error handling example
   mkcd "/root/restricted" || {
       echo "Cannot create directory in restricted location"
       mkcd "$HOME/alternative_location"
   }

**Unit Tests:**

.. code-block:: bash

   # Test: mkcd creates and enters directory
   test_mkcd_creates_and_enters_directory() {
       local test_dir="/tmp/test_mkcd_$$"
       
       # Ensure clean state
       rm -rf "$test_dir"
       
       # Test mkcd
       mkcd "$test_dir"
       
       # Verify directory was created and we're in it
       assert_equals "$PWD" "$test_dir" "Should be in created directory"
       assert_true "[ -d '$test_dir' ]" "Directory should exist"
       
       # Cleanup
       cd /tmp && rm -rf "$test_dir"
   }

   # Test: mkcd creates nested directories
   test_mkcd_creates_nested_directories() {
       local test_dir="/tmp/test/nested/path_$$"
       
       # Ensure clean state
       rm -rf "/tmp/test"
       
       mkcd "$test_dir"
       
       assert_equals "$PWD" "$test_dir" "Should be in nested directory"
       assert_true "[ -d '$test_dir' ]" "Nested directory should exist"
       
       # Cleanup
       cd /tmp && rm -rf "/tmp/test"
   }

   # Test: mkcd handles existing directory
   test_mkcd_handles_existing_directory() {
       local test_dir="/tmp/existing_test_$$"
       
       # Create directory first
       mkdir -p "$test_dir"
       
       # Test mkcd on existing directory
       mkcd "$test_dir"
       
       assert_equals "$PWD" "$test_dir" "Should enter existing directory"
       
       # Cleanup
       cd /tmp && rm -rf "$test_dir"
   }

   # Test: mkcd fails gracefully on permission denied
   test_mkcd_fails_gracefully() {
       # Test with restricted location (if not root)
       if [[ $EUID -ne 0 ]]; then
           mkcd "/root/restricted_test"
           assert_not_equals $? 0 "Should fail on permission denied"
           assert_not_equals "$PWD" "/root/restricted_test" "Should not change to restricted directory"
       fi
   }

is_online()
~~~~~~~~~~~

**Function Definition:**

.. code-block:: bash

   is_online() {
       # Check if internet connectivity is available
       #
       # Args:
       #     None
       #
       # Returns:
       #     0: Online (internet accessible)
       #     1: Offline (no internet connection)
       ping -c 1 google.com >/dev/null 2>&1
   }

**Examples and Elaboration:**

The ``is_online`` function provides a simple way to check internet connectivity before attempting network operations. It uses a single ping to Google's DNS servers, which is fast and reliable.

.. code-block:: bash

   # Basic connectivity check
   if is_online; then
       echo "Internet connection available"
       # Proceed with network operations
       update_packages
       download_dependencies
   else
       echo "No internet connection - working offline"
       use_cached_data
   fi

   # Use in deployment scripts
   deploy_application() {
       if ! is_online; then
           echo "Error: Internet connection required for deployment"
           return 1
       fi
       
       echo "Downloading latest dependencies..."
       npm install
       echo "Deploying to production..."
   }

   # Conditional package installation
   install_optional_packages() {
       local packages=("docker" "kubernetes-cli" "terraform")
       
       if is_online; then
           for package in "${packages[@]}"; do
               echo "Installing $package..."
               brew install "$package"
           done
       else
           echo "Offline - skipping optional package installation"
       fi
   }

   # Network-dependent configuration
   configure_development_env() {
       if is_online; then
           echo "Configuring for online development"
           export API_ENDPOINT="https://api.production.com"
           download_latest_schema
       else
           echo "Configuring for offline development"  
           export API_ENDPOINT="http://localhost:3000"
           use_local_schema
       fi
   }

**Unit Tests:**

.. code-block:: bash

   # Test: is_online basic functionality
   test_is_online_basic_functionality() {
       # This test assumes network connectivity during testing
       # In a real environment, you might mock the network call
       
       local result
       is_online
       result=$?
       
       # Should return either 0 (online) or 1 (offline)
       assert_true "(( result == 0 || result == 1 ))" "Should return valid exit code"
   }

   # Test: is_online produces no output
   test_is_online_silent_operation() {
       local output
       output=$(is_online 2>&1)
       
       assert_equals "$output" "" "is_online should produce no output"
   }

   # Mock test: is_online when network is available
   test_is_online_with_network_mock() {
       # Override ping command for testing
       ping() {
           # Mock successful ping
           return 0
       }
       
       is_online
       assert_equals $? 0 "Should return 0 when network is available"
       
       # Restore original ping
       unset -f ping
   }

   # Mock test: is_online when network is unavailable
   test_is_online_without_network_mock() {
       # Override ping command for testing
       ping() {
           # Mock failed ping
           return 1
       }
       
       is_online
       assert_equals $? 1 "Should return 1 when network is unavailable"
       
       # Restore original ping
       unset -f ping
   }

   # Performance test: is_online responds quickly
   test_is_online_performance() {
       local start_time end_time duration
       start_time=$(date +%s)
       
       is_online
       
       end_time=$(date +%s)
       duration=$((end_time - start_time))
       
       # Should complete within 5 seconds
       assert_true "(( duration <= 5 ))" "is_online should complete within 5 seconds"
   }

Python Environment Management
-----------------------------

py_env_switch()
~~~~~~~~~~~~~~~

**Function Definition:**

.. code-block:: bash

   py_env_switch() {
       # Quick switch between Python environments (cross-shell compatible)
       #
       # Usage:
       #   py_env_switch list           # List all environments
       #   py_env_switch myenv          # Switch to pyenv environment
       #   py_env_switch uv             # Use UV in current directory
       local target="${1:-list}"
       
       case "$target" in
           "list"|"-l"|"--list")
               echo "🐍 Available Python Environments:"
               echo ""
               echo "📦 Pyenv Environments:"
               if command_exists pyenv; then
                   pyenv versions | sed 's/^/  /'
               else
                   echo "  ❌ Pyenv not installed"
               fi
               echo ""
               echo "⚡ UV Projects:"
               if [[ -f "pyproject.toml" ]]; then
                   echo "  ✅ Current directory has UV project"
               else
                   echo "  ❌ No UV project in current directory"
               fi
               echo ""
               echo "Usage:"
               echo "  py_env_switch <env_name>    # Switch to pyenv environment"
               echo "  py_env_switch uv            # Activate UV project here"
               ;;
           "uv")
               if [[ -f "pyproject.toml" ]]; then
                   if [[ -d ".venv" ]]; then
                       echo "⚡ Activating UV project: $(basename $PWD)"
                       source .venv/bin/activate
                   else
                       echo "🔨 Setting up UV project..."
                       uv sync && source .venv/bin/activate
                   fi
               else
                   echo "❌ No pyproject.toml found. Run 'uv init' to create a UV project."
               fi
               ;;
           *)
               if command_exists pyenv; then
                   echo "🐍 Switching to pyenv environment: $target"
                   pyenv activate "$target" 2>/dev/null || {
                       echo "❌ Environment '$target' not found. Available:"
                       pyenv versions
                   }
               else
                   echo "❌ Pyenv not available"
               fi
               ;;
       esac
   }

**Examples and Elaboration:**

The ``py_env_switch`` function provides unified Python environment management across pyenv and UV, supporting both development workflows seamlessly.

.. code-block:: bash

   # List all available environments
   py_env_switch list
   # Shows both pyenv environments and UV projects

   # Switch to a specific pyenv environment
   py_env_switch data_science
   # Activates the 'data_science' pyenv environment

   # Activate UV project in current directory
   cd my_uv_project
   py_env_switch uv
   # Sets up and activates UV virtual environment

   # Use in project setup scripts
   setup_data_science_project() {
       local project_name="$1"
       local env_type="${2:-uv}"
       
       mkcd "$project_name"
       
       case "$env_type" in
           "uv")
               uv init --name "$project_name" --python 3.11
               uv add pandas numpy matplotlib jupyter
               py_env_switch uv
               ;;
           "pyenv")
               py_env_switch "$project_name" || {
                   echo "Creating new pyenv environment..."
                   pyenv virtualenv 3.11 "$project_name"
                   py_env_switch "$project_name"
               }
               ;;
       esac
   }

   # Environment-specific workflows
   analyze_with_spark() {
       py_env_switch spark_env
       smart_spark_submit analysis.py
   }

   analyze_with_uv() {
       py_env_switch uv
       uv run python analysis.py
   }

**Unit Tests:**

.. code-block:: bash

   # Test: py_env_switch list command
   test_py_env_switch_list() {
       local output
       output=$(py_env_switch list)
       
       assert_contains "$output" "Available Python Environments" "Should show environment list"
       assert_contains "$output" "Pyenv Environments" "Should show pyenv section"
       assert_contains "$output" "UV Projects" "Should show UV section"
   }

   # Test: py_env_switch with UV project
   test_py_env_switch_uv_project() {
       local test_dir="/tmp/test_uv_project_$$"
       mkcd "$test_dir"
       
       # Create UV project
       echo '[project]' > pyproject.toml
       echo 'name = "test-project"' >> pyproject.toml
       mkdir -p .venv/bin
       echo '#!/bin/bash' > .venv/bin/activate
       echo 'export VIRTUAL_ENV="'$test_dir'/.venv"' >> .venv/bin/activate
       chmod +x .venv/bin/activate
       
       py_env_switch uv
       
       assert_equals "$VIRTUAL_ENV" "$test_dir/.venv" "Should activate UV environment"
       
       # Cleanup
       cd /tmp && rm -rf "$test_dir"
   }

   # Test: py_env_switch without UV project
   test_py_env_switch_no_uv_project() {
       local test_dir="/tmp/test_no_uv_$$"
       mkcd "$test_dir"
       
       local output
       output=$(py_env_switch uv 2>&1)
       
       assert_contains "$output" "No pyproject.toml found" "Should detect missing UV project"
       
       # Cleanup
       cd /tmp && rm -rf "$test_dir"
   }

   # Test: py_env_switch pyenv integration
   test_py_env_switch_pyenv() {
       if ! command_exists pyenv; then
           skip_test "Pyenv not available"
           return
       fi
       
       # Test with existing environment (if any)
       local envs=$(pyenv versions --bare | head -n1)
       if [[ -n "$envs" ]]; then
           local first_env=$(echo "$envs" | head -n1)
           py_env_switch "$first_env"
           # Note: Full testing would require mock pyenv
       fi
   }

ds_project_init()
~~~~~~~~~~~~~~~~~

**Function Definition:**

.. code-block:: bash

   ds_project_init() {
       # Initialize a data science project with UV
       #
       # Usage:
       #   ds_project_init myproject        # Basic data science project
       #   ds_project_init myproject spark  # With Spark dependencies
       local project_name="$1"
       local project_type="${2:-basic}"
       
       if [[ -z "$project_name" ]]; then
           echo "Usage: ds_project_init <project_name> [basic|spark|geo]"
           return 1
       fi
       
       echo "🔬 Creating data science project: $project_name"
       mkdir -p "$project_name" && cd "$project_name"
       
       # Initialize UV project
       uv init --name "$project_name" --python 3.11
       
       # Add common data science dependencies
       echo "📦 Adding data science dependencies..."
       uv add pandas numpy matplotlib seaborn jupyter ipykernel
       
       case "$project_type" in
           "spark")
               echo "⚡ Adding Spark dependencies..."
               uv add pyspark findspark
               ;;
           "geo")
               echo "🌍 Adding geospatial dependencies..."
               uv add geopandas folium contextily
               ;;
       esac
       
       # Create project structure
       mkdir -p {notebooks,data/{raw,processed},src,tests}
       
       echo "✅ Data science project '$project_name' created!"
       echo "🚀 Next steps:"
       echo "  source .venv/bin/activate"
       echo "  jupyter lab"
   }

**Examples and Elaboration:**

The ``ds_project_init`` function creates a complete data science project structure with appropriate dependencies based on the project type.

.. code-block:: bash

   # Create basic data science project
   ds_project_init "sales_analysis"
   # Creates project with pandas, numpy, matplotlib, jupyter

   # Create Spark-enabled data science project
   ds_project_init "big_data_analysis" spark
   # Adds PySpark and Findspark for distributed computing

   # Create geospatial analysis project
   ds_project_init "location_analysis" geo
   # Adds GeoPandas, Folium, Contextily for mapping

   # Use in automated workflows
   create_monthly_analysis() {
       local month=$(date +%Y-%m)
       ds_project_init "analysis_$month" spark
       
       cd "analysis_$month"
       
       # Add custom analysis template
       cat > notebooks/monthly_report.ipynb << 'EOF'
   {
       "cells": [
           {
               "cell_type": "code",
               "source": ["import pandas as pd\nimport pyspark"]
           }
       ]
   }
   EOF
   
       echo "Monthly analysis project ready: analysis_$month"
   }

**Unit Tests:**

.. code-block:: bash

   # Test: ds_project_init basic project
   test_ds_project_init_basic_project() {
       local test_project="test_ds_basic_$$"
       local original_dir="$PWD"
       
       ds_project_init "$test_project"
       
       # Verify project structure
       assert_true "[ -d '$test_project' ]" "Project directory should exist"
       assert_true "[ -f '$test_project/pyproject.toml' ]" "Should have pyproject.toml"
       assert_true "[ -d '$test_project/notebooks' ]" "Should have notebooks directory"
       assert_true "[ -d '$test_project/data/raw' ]" "Should have data/raw directory"
       assert_true "[ -d '$test_project/src' ]" "Should have src directory"
       assert_true "[ -d '$test_project/tests' ]" "Should have tests directory"
       
       # Cleanup
       cd "$original_dir" && rm -rf "$test_project"
   }

   # Test: ds_project_init spark project
   test_ds_project_init_spark_project() {
       local test_project="test_ds_spark_$$"
       local original_dir="$PWD"
       
       ds_project_init "$test_project" spark
       
       # Verify Spark dependencies
       cd "$test_project"
       local deps=$(uv pip list 2>/dev/null | grep -E "(pyspark|findspark)" || echo "")
       assert_not_equals "$deps" "" "Should include Spark dependencies"
       
       # Cleanup
       cd "$original_dir" && rm -rf "$test_project"
   }

   # Test: ds_project_init without project name
   test_ds_project_init_missing_name() {
       local output
       output=$(ds_project_init 2>&1)
       
       assert_equals $? 1 "Should return error code"
       assert_contains "$output" "Usage:" "Should show usage message"
   }

Cross-Platform Utilities
-------------------------

path_add()
~~~~~~~~~~

**Function Definition:**

.. code-block:: bash

   path_add() {
       # Cross-platform path addition
       # Usage: path_add /path/to/add [before|after]
       local new_path="$1"
       local position="${2:-after}"
       
       # Check if path exists and is not already in PATH
       if [[ -d "$new_path" ]] && [[ ":$PATH:" != *":$new_path:"* ]]; then
           case "$position" in
               "before")
                   export PATH="$new_path:$PATH"
                   ;;
               "after"|*)
                   export PATH="$PATH:$new_path"
                   ;;
           esac
       fi
   }

**Examples and Elaboration:**

The ``path_add`` function safely adds directories to PATH, avoiding duplicates and checking for existence.

.. code-block:: bash

   # Add directory to end of PATH
   path_add "/usr/local/bin"
   
   # Add directory to beginning of PATH (higher priority)  
   path_add "/opt/homebrew/bin" before
   
   # Common development setup
   setup_development_path() {
       path_add "$HOME/.local/bin"
       path_add "/opt/homebrew/bin" before
       path_add "$HOME/go/bin"
       path_add "$HOME/.cargo/bin"
   }

**Unit Tests:**

.. code-block:: bash

   # Test: path_add adds valid directory
   test_path_add_valid_directory() {
       local original_path="$PATH"
       local test_path="/usr/local/bin"
       
       # Ensure test path exists (create if needed for test)
       mkdir -p "$test_path"
       
       path_add "$test_path"
       
       assert_contains "$PATH" "$test_path" "PATH should contain added directory"
       
       # Restore original PATH
       export PATH="$original_path"
   }

   # Test: path_add ignores non-existent directory
   test_path_add_nonexistent_directory() {
       local original_path="$PATH"
       local fake_path="/nonexistent/path/12345"
       
       path_add "$fake_path"
       
       assert_not_contains "$PATH" "$fake_path" "PATH should not contain non-existent directory"
       assert_equals "$PATH" "$original_path" "PATH should be unchanged"
   }

Notes
-----

.. note::
   
   All functions are designed to be cross-shell compatible, working in both bash and zsh environments.

.. warning::
   
   Unit tests assume certain system conditions. In production environments, consider using mocks for external dependencies like network connectivity and file system operations.

.. tip::
   
   Functions follow the principle of least surprise - they fail gracefully and provide meaningful error messages when possible.