Platform Functions API Reference
=================================

This module provides comprehensive cross-shell (bash/zsh) and cross-platform (macOS/Linux/WSL/Docker) compatibility functions, ensuring consistent behavior across different environments.

.. note::
   All functions automatically detect the current shell and platform, providing optimal implementations for each environment.

Shell Detection Functions
-------------------------

detect_shell()
~~~~~~~~~~~~~

**Function Definition:**

Detect the current shell environment and return the shell name for conditional operations.

.. code-block:: bash

   detect_shell()

**Examples and Elaboration:**

.. code-block:: bash

   # Basic shell detection
   current_shell=$(detect_shell)
   echo "Running in: $current_shell"
   # Output (in zsh): Running in: zsh
   # Output (in bash): Running in: bash

   # Conditional shell-specific operations
   case "$(detect_shell)" in
       "zsh")
           echo "ZSH-specific configuration"
           setopt autocd
           ;;
       "bash")
           echo "Bash-specific configuration"
           shopt -s autocd
           ;;
       *)
           echo "Unknown shell"
           ;;
   esac

The function detects shells by checking environment variables:

- **ZSH**: Checks for `$ZSH_VERSION`
- **Bash**: Checks for `$BASH_VERSION`  
- **Unknown**: Returns "unknown" for other shells

**Unit Tests:**

.. code-block:: bash

   # Test: Shell detection in ZSH
   test_detect_shell_zsh() {
       if [[ -n "$ZSH_VERSION" ]]; then
           [[ "$(detect_shell)" == "zsh" ]]
       else
           echo "Skipping ZSH test - not running in ZSH"
           return 0
       fi
   }
   
   # Test: Shell detection in Bash
   test_detect_shell_bash() {
       bash -c 'source shell-compat.zsh; [[ "$(detect_shell)" == "bash" ]]'
   }
   
   # Test: Current shell environment variable
   test_current_shell_export() {
       [[ -n "$CURRENT_SHELL" ]]
   }

Platform Detection Functions
----------------------------

detect_platform()
~~~~~~~~~~~~~~~~~

**Function Definition:**

Comprehensive platform detection supporting macOS, multiple Linux distributions, WSL, and Docker containers.

.. code-block:: bash

   detect_platform()

**Examples and Elaboration:**

.. code-block:: bash

   # Basic platform detection
   platform=$(detect_platform)
   echo "Running on: $platform"
   # Output examples:
   # Running on: macos
   # Running on: linux-ubuntu
   # Running on: wsl
   # Running on: docker

   # Platform-specific operations
   case "$(detect_platform)" in
       "macos")
           echo "macOS detected - using Homebrew paths"
           path_add "/opt/homebrew/bin" before
           ;;
       "linux-debian"|"linux-ubuntu")
           echo "Debian-based Linux - using apt"
           alias install="sudo apt install"
           ;;
       "linux-redhat"|"linux-centos")
           echo "Red Hat-based Linux - using yum/dnf"
           alias install="sudo dnf install"
           ;;
       "docker")
           echo "Docker container - optimizing for container"
           export SPARK_DRIVER_MEMORY="1g"
           ;;
       "wsl")
           echo "Windows Subsystem for Linux"
           # WSL-specific configurations
           ;;
   esac

Platform Detection Logic:

1. **macOS**: Checks `uname -s` for "Darwin"
2. **Linux**: Checks `uname -s` for "Linux", then reads `/etc/os-release` for distribution
3. **WSL**: Checks for `$WSL_DISTRO_NAME` or `$WSLENV` environment variables
4. **Docker**: Checks for `/.dockerenv` file or docker in `/proc/1/cgroup`

Supported platforms:

- `macos` - macOS (Darwin)
- `linux` - Generic Linux
- `linux-debian` - Debian/Ubuntu
- `linux-redhat` - CentOS/RHEL/Fedora
- `linux-alpine` - Alpine Linux
- `wsl` - Windows Subsystem for Linux
- `docker` - Docker containers

**Unit Tests:**

.. code-block:: bash

   # Test: Platform detection returns valid value
   test_platform_detection() {
       platform=$(detect_platform)
       [[ "$platform" != "unknown" ]]
   }
   
   # Test: macOS detection (when on macOS)
   test_macos_detection() {
       if [[ "$(uname -s)" == "Darwin" ]]; then
           [[ "$(detect_platform)" == "macos" ]]
       else
           echo "Skipping macOS test - not on macOS"
           return 0
       fi
   }
   
   # Test: Container detection
   test_container_detection() {
       if [[ -f "/.dockerenv" ]]; then
           [[ "$(detect_platform)" == "docker" ]]
       else
           echo "Skipping container test - not in container"
           return 0
       fi
   }

is_container()
~~~~~~~~~~~~~

**Function Definition:**

Detect if the current environment is running inside a Docker container.

.. code-block:: bash

   is_container()

**Examples and Elaboration:**

.. code-block:: bash

   # Basic container detection
   if is_container; then
       echo "Running inside a container"
       # Optimize for container environment
       export JAVA_OPTS="-Xmx1g"
       export SPARK_DRIVER_MEMORY="512m"
   else
       echo "Running on host system"
       # Use full system resources
       export JAVA_OPTS="-Xmx4g"
   fi

   # Environment variable usage
   echo "Container status: $ZSH_IS_DOCKER"
   # Output: Container status: true (in container)
   # Output: Container status: false (on host)

Container detection methods:

1. **Docker env file**: Checks for `/.dockerenv`
2. **Control groups**: Searches for "docker" in `/proc/1/cgroup`

**Unit Tests:**

.. code-block:: bash

   # Test: Container detection consistency
   test_container_detection_consistency() {
       container_function=$(is_container && echo "true" || echo "false")
       [[ "$container_function" == "$ZSH_IS_DOCKER" ]]
   }

Cross-Shell Compatibility Functions
----------------------------------

add_chdir_hook()
~~~~~~~~~~~~~~~

**Function Definition:**

Add directory change hooks that work consistently across bash and zsh shells.

.. code-block:: bash

   add_chdir_hook <function_name>

**Examples and Elaboration:**

.. code-block:: bash

   # Define a function to run on directory change
   auto_activate_virtualenv() {
       if [[ -f ".venv/bin/activate" ]]; then
           echo "🐍 Auto-activating virtual environment"
           source .venv/bin/activate
       elif [[ -f ".python-version" ]]; then
           local version=$(cat .python-version)
           echo "🐍 Auto-switching to Python $version"
           pyenv activate "$version" 2>/dev/null
       fi
   }

   # Add the hook (works in both bash and zsh)
   add_chdir_hook auto_activate_virtualenv

   # Now changing directories will trigger the function
   cd my_project  # If it has .venv/, automatically activates it

Implementation differences:

- **ZSH**: Uses `add-zsh-hook chpwd` mechanism
- **Bash**: Overrides the `cd` function to call the hook

**Unit Tests:**

.. code-block:: bash

   # Test: Hook function is callable
   test_chdir_hook_function() {
       test_hook() { echo "hook called"; }
       add_chdir_hook test_hook
       # Should not error
       [[ $? -eq 0 ]]
   }

Array Handling Functions
-----------------------

array_expand()
~~~~~~~~~~~~~

**Function Definition:**

Cross-shell array expansion that handles the differences between bash and zsh array syntax.

.. code-block:: bash

   array_expand <array_name>

**Examples and Elaboration:**

.. code-block:: bash

   # Define arrays in both shells
   # (syntax varies between bash and zsh)
   if [[ "$CURRENT_SHELL" == "zsh" ]]; then
       my_array=("item1" "item2" "item3")
   else
       my_array=("item1" "item2" "item3")
   fi

   # Cross-shell expansion
   expanded=$(array_expand my_array)
   echo "Array contents: $expanded"
   # Output: Array contents: item1 item2 item3

   # Use in loops
   for item in $(array_expand my_array); do
       echo "Processing: $item"
   done

**Unit Tests:**

.. code-block:: bash

   # Test: Array expansion works
   test_array_expand() {
       local test_array=("apple" "banana" "cherry")
       local result=$(array_expand test_array)
       [[ "$result" == *"apple"* ]] && [[ "$result" == *"banana"* ]]
   }

assoc_array_set() / assoc_array_get()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Cross-shell associative array operations that handle the syntax differences between bash and zsh.

.. code-block:: bash

   assoc_array_set <array_name> <key> <value>
   assoc_array_get <array_name> <key>

**Examples and Elaboration:**

.. code-block:: bash

   # Set up configuration mapping
   assoc_array_set config_map "database_host" "localhost"
   assoc_array_set config_map "database_port" "5432" 
   assoc_array_set config_map "redis_host" "127.0.0.1"

   # Retrieve values
   db_host=$(assoc_array_get config_map "database_host")
   db_port=$(assoc_array_get config_map "database_port")

   echo "Database: $db_host:$db_port"
   # Output: Database: localhost:5432

   # Build connection string
   build_connection_string() {
       local host=$(assoc_array_get config_map "database_host")
       local port=$(assoc_array_get config_map "database_port")
       echo "postgresql://$host:$port/mydb"
   }

Implementation:

- **ZSH**: Uses `typeset -gA` for global associative arrays
- **Bash**: Uses `declare -gA` for global associative arrays
- **Fallback**: Uses simple variables with naming convention

**Unit Tests:**

.. code-block:: bash

   # Test: Associative array set/get
   test_assoc_array_operations() {
       assoc_array_set test_map "key1" "value1"
       assoc_array_set test_map "key2" "value2"
       
       result1=$(assoc_array_get test_map "key1")
       result2=$(assoc_array_get test_map "key2")
       
       [[ "$result1" == "value1" ]] && [[ "$result2" == "value2" ]]
   }

word_split()
~~~~~~~~~~~

**Function Definition:**

Handle word splitting differences between bash and zsh for consistent argument processing.

.. code-block:: bash

   word_split <variable>

**Examples and Elaboration:**

.. code-block:: bash

   # Define arguments as string
   spark_args="--master local[*] --driver-memory 2g --executor-memory 1g"

   # Cross-shell word splitting
   for arg in $(word_split "$spark_args"); do
       echo "Argument: $arg"
   done
   # Output:
   # Argument: --master  
   # Argument: local[*]
   # Argument: --driver-memory
   # Argument: 2g
   # Argument: --executor-memory
   # Argument: 1g

   # Use in command execution
   spark_submit_with_args() {
       local args="--master yarn --deploy-mode client"
       spark-submit $(word_split "$args") my_script.py
   }

ZSH vs Bash differences:

- **ZSH**: Doesn't split words by default, requires `${=variable}` syntax
- **Bash**: Splits words automatically in unquoted contexts

**Unit Tests:**

.. code-block:: bash

   # Test: Word splitting produces multiple words
   test_word_split() {
       local test_string="word1 word2 word3"
       local count=0
       for word in $(word_split "$test_string"); do
           ((count++))
       done
       [[ $count -eq 3 ]]
   }

Cross-Platform Utilities
------------------------

platform_open()
~~~~~~~~~~~~~~~

**Function Definition:**

Open files or URLs using the appropriate system command for each platform.

.. code-block:: bash

   platform_open <file_or_url>

**Examples and Elaboration:**

.. code-block:: bash

   # Open files with default application
   platform_open "report.pdf"
   platform_open "data.csv"

   # Open URLs in default browser
   platform_open "https://github.com/user/repo"
   platform_open "http://localhost:8080"

   # Open directories
   platform_open "/path/to/project"

   # Use in automation
   generate_report() {
       python generate_report.py
       echo "Report generated: report.html"
       platform_open "report.html"
   }

Platform commands used:

- **macOS**: `open`
- **Linux**: `xdg-open`, `gnome-open` (fallback)
- **WSL**: `cmd.exe /c start`

**Unit Tests:**

.. code-block:: bash

   # Test: Open command exists for platform
   test_platform_open_command() {
       case "$ZSH_PLATFORM" in
           "macos")
               command -v open >/dev/null 2>&1
               ;;
           "linux"*)
               command -v xdg-open >/dev/null 2>&1 || command -v gnome-open >/dev/null 2>&1
               ;;
           "wsl")
               command -v cmd.exe >/dev/null 2>&1
               ;;
           *)
               echo "Unknown platform for testing: $ZSH_PLATFORM"
               return 0
               ;;
       esac
   }

platform_copy() / platform_paste()
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Cross-platform clipboard operations for copying and pasting text.

.. code-block:: bash

   platform_copy      # Copy from stdin
   platform_paste     # Paste to stdout

**Examples and Elaboration:**

.. code-block:: bash

   # Copy text to clipboard
   echo "Hello, World!" | platform_copy

   # Copy file contents
   cat important_config.yml | platform_copy

   # Paste from clipboard
   clipboard_content=$(platform_paste)
   echo "Clipboard: $clipboard_content"

   # Use in workflows
   copy_connection_string() {
       local host=$1
       local port=$2
       local database=$3
       echo "postgresql://$host:$port/$database" | platform_copy
       echo "✅ Connection string copied to clipboard"
   }

   # Copy command output
   get_system_info() {
       system_info | platform_copy
       echo "System information copied to clipboard"
   }

Platform implementations:

- **macOS**: `pbcopy` / `pbpaste`
- **Linux**: `xclip` or `xsel` (requires installation)
- **WSL**: `clip.exe` / `powershell.exe Get-Clipboard`

**Unit Tests:**

.. code-block:: bash

   # Test: Copy and paste round-trip
   test_clipboard_round_trip() {
       local test_string="test clipboard functionality"
       echo "$test_string" | platform_copy
       local pasted=$(platform_paste)
       [[ "$pasted" == *"$test_string"* ]]
   }
   
   # Test: Clipboard commands exist
   test_clipboard_commands_exist() {
       case "$ZSH_PLATFORM" in
           "macos")
               command -v pbcopy >/dev/null 2>&1 && command -v pbpaste >/dev/null 2>&1
               ;;
           "linux"*)
               command -v xclip >/dev/null 2>&1 || command -v xsel >/dev/null 2>&1
               ;;
           "wsl")
               command -v clip.exe >/dev/null 2>&1
               ;;
           *)
               return 0  # Skip for unknown platforms
               ;;
       esac
   }

Path Management Functions
------------------------

path_add()
~~~~~~~~~

**Function Definition:**

Add directories to PATH with duplicate checking and position control.

.. code-block:: bash

   path_add <directory> [before|after]

**Examples and Elaboration:**

.. code-block:: bash

   # Add to end of PATH (default)
   path_add "/usr/local/bin"
   path_add "$HOME/.local/bin"

   # Add to beginning of PATH (higher priority)
   path_add "/opt/homebrew/bin" before

   # Conditional path addition
   if [[ -d "/opt/spark/bin" ]]; then
       path_add "/opt/spark/bin"
       echo "✅ Spark added to PATH"
   fi

   # Add multiple paths
   python_paths=(
       "$HOME/.pyenv/bin"
       "$HOME/.local/bin"
       "/opt/python/bin"
   )

   for py_path in "${python_paths[@]}"; do
       path_add "$py_path"
   done

Features:

- **Duplicate prevention**: Won't add paths already in PATH
- **Existence checking**: Only adds existing directories
- **Position control**: Add at beginning or end of PATH

**Unit Tests:**

.. code-block:: bash

   # Test: Path addition (non-duplicate)
   test_path_add_new() {
       # Create temporary directory
       local temp_dir=$(mktemp -d)
       local original_path="$PATH"
       
       path_add "$temp_dir"
       [[ ":$PATH:" == *":$temp_dir:"* ]]
       
       # Cleanup
       export PATH="$original_path"
       rmdir "$temp_dir"
   }
   
   # Test: Duplicate prevention
   test_path_add_duplicate() {
       local original_path="$PATH"
       local path_count_before=$(echo "$PATH" | tr ':' '\n' | wc -l)
       
       path_add "/usr/bin"  # Already exists
       local path_count_after=$(echo "$PATH" | tr ':' '\n' | wc -l)
       
       [[ $path_count_before -eq $path_count_after ]]
   }

lib_path_add()
~~~~~~~~~~~~~

**Function Definition:**

Add directories to library path using the appropriate environment variable for each platform.

.. code-block:: bash

   lib_path_add <library_directory>

**Examples and Elaboration:**

.. code-block:: bash

   # Add custom library paths
   lib_path_add "/usr/local/lib"
   lib_path_add "$HOME/local/lib"

   # Add Java/JNI libraries
   if [[ -n "$JAVA_HOME" ]]; then
       lib_path_add "$JAVA_HOME/lib"
       lib_path_add "$JAVA_HOME/jre/lib"
   fi

   # Add Spark/Hadoop native libraries
   if [[ -n "$SPARK_HOME" ]]; then
       lib_path_add "$SPARK_HOME/lib"
   fi

   # Platform-specific library setup
   case "$ZSH_PLATFORM" in
       "macos")
           lib_path_add "/opt/homebrew/lib"
           ;;
       "linux"*)
           lib_path_add "/usr/lib64"
           lib_path_add "/usr/lib/x86_64-linux-gnu"
           ;;
   esac

Platform-specific variables:

- **macOS**: Uses `DYLD_LIBRARY_PATH` (Note: restricted by SIP in some cases)
- **Linux/WSL/Docker**: Uses `LD_LIBRARY_PATH`

**Unit Tests:**

.. code-block:: bash

   # Test: Library path setting
   test_lib_path_add() {
       # Create temporary directory
       local temp_lib=$(mktemp -d)
       
       lib_path_add "$temp_lib"
       
       case "$ZSH_PLATFORM" in
           "macos")
               [[ ":${DYLD_LIBRARY_PATH:-}:" == *":$temp_lib:"* ]]
               ;;
           "linux"*|"wsl"|"docker")
               [[ ":${LD_LIBRARY_PATH:-}:" == *":$temp_lib:"* ]]
               ;;
       esac
       
       local result=$?
       rmdir "$temp_lib"
       [[ $result -eq 0 ]]
   }

Package Manager Detection
------------------------

detect_package_managers()
~~~~~~~~~~~~~~~~~~~~~~~~~

**Function Definition:**

Detect all available package managers on the system for automated installation scripts.

.. code-block:: bash

   detect_package_managers()

**Examples and Elaboration:**

.. code-block:: bash

   # Get all available package managers
   available_managers=$(detect_package_managers)
   echo "Available package managers: $available_managers"
   # Example output: Available package managers: brew npm pip uv

   # Use in installation scripts
   install_python_deps() {
       local managers=$(detect_package_managers)
       
       if [[ "$managers" == *"uv"* ]]; then
           echo "Using UV for Python dependencies"
           uv add pandas numpy matplotlib
       elif [[ "$managers" == *"pip"* ]]; then
           echo "Using pip for Python dependencies"
           pip install pandas numpy matplotlib
       else
           echo "❌ No Python package manager found"
           return 1
       fi
   }

   # System package installation
   install_system_package() {
       local package="$1"
       local managers=$(detect_package_managers)
       
       if [[ "$managers" == *"brew"* ]]; then
           brew install "$package"
       elif [[ "$managers" == *"apt"* ]]; then
           sudo apt install "$package"
       elif [[ "$managers" == *"dnf"* ]]; then
           sudo dnf install "$package"
       elif [[ "$managers" == *"yum"* ]]; then
           sudo yum install "$package"
       else
           echo "❌ No suitable package manager found for $package"
           return 1
       fi
   }

Detected package managers:

**System Package Managers:**

- `apt` - Debian/Ubuntu
- `yum` - CentOS/RHEL (older)
- `dnf` - Fedora/CentOS/RHEL (newer)
- `pacman` - Arch Linux
- `brew` - macOS/Linux Homebrew

**Development Package Managers:**

- `npm` - Node.js packages
- `pip` - Python packages
- `uv` - Modern Python package manager

**Unit Tests:**

.. code-block:: bash

   # Test: Package manager detection returns list
   test_package_manager_detection() {
       local managers=$(detect_package_managers)
       [[ -n "$managers" ]]  # Should return something
   }
   
   # Test: Known package managers are detected
   test_known_package_managers() {
       local managers=$(detect_package_managers)
       
       # Test for commonly available tools
       if command -v pip >/dev/null 2>&1; then
           [[ "$managers" == *"pip"* ]]
       fi
   }

Environment Variables and Status
-------------------------------

The module exports several environment variables for use by other modules:

.. code-block:: bash

   # Shell information
   echo "Current shell: $CURRENT_SHELL"                    # zsh, bash, or unknown
   echo "Platform: $ZSH_PLATFORM"                         # macos, linux, wsl, docker, etc.
   echo "Container: $ZSH_IS_DOCKER"                       # true or false
   echo "Package managers: $AVAILABLE_PACKAGE_MANAGERS"   # Space-separated list

   # Module information
   echo "Module loaded: $SHELL_COMPAT_MODULE_LOADED"      # true
   echo "Module version: $SHELL_COMPAT_MODULE_VERSION"    # 1.0.0

Complete Usage Examples
----------------------

**Example 1: Cross-platform development environment setup**

.. code-block:: bash

   # Platform-aware Python environment setup
   setup_python_environment() {
       echo "🔧 Setting up Python environment for $ZSH_PLATFORM"
       
       case "$ZSH_PLATFORM" in
           "macos")
               # macOS: Use Homebrew Python
               if command -v brew >/dev/null 2>&1; then
                   brew install python
                   path_add "/opt/homebrew/bin" before
               fi
               ;;
           "linux-debian"|"linux-ubuntu")
               # Ubuntu/Debian: Use system package manager
               sudo apt update && sudo apt install python3 python3-pip python3-venv
               ;;
           "linux-redhat"|"linux-centos")
               # Red Hat: Use dnf/yum
               sudo dnf install python3 python3-pip python3-venv
               ;;
           "docker")
               echo "ℹ️  Using pre-installed Python in container"
               ;;
       esac
       
       # Add common Python paths
       path_add "$HOME/.local/bin"
       
       # Install UV if available
       if is_online && ! command -v uv >/dev/null 2>&1; then
           curl -LsSf https://astral.sh/uv/install.sh | sh
           path_add "$HOME/.cargo/bin"
       fi
   }

**Example 2: Cross-shell hook system**

.. code-block:: bash

   # Auto-activate environments on directory change
   setup_auto_activation() {
       auto_env_activate() {
           # Check for UV project
           if [[ -f "pyproject.toml" && -d ".venv" ]]; then
               if [[ "$VIRTUAL_ENV" != "$PWD/.venv" ]]; then
                   echo "⚡ Activating UV environment"
                   source .venv/bin/activate
               fi
           # Check for PyEnv version file
           elif [[ -f ".python-version" ]]; then
               local version=$(cat .python-version)
               if command -v pyenv >/dev/null 2>&1; then
                   echo "🐍 Switching to Python $version"
                   pyenv activate "$version" 2>/dev/null
               fi
           # Check for Node.js project
           elif [[ -f "package.json" && -d "node_modules" ]]; then
               echo "📦 Node.js project detected"
               # Could add nvm activation here
           fi
       }
       
       # Add hook for both shells
       add_chdir_hook auto_env_activate
   }

**Example 3: Cross-platform clipboard integration**

.. code-block:: bash

   # Enhanced clipboard utilities
   copy_file() {
       local file="$1"
       if [[ -f "$file" ]]; then
           cat "$file" | platform_copy
           echo "✅ $file copied to clipboard"
       else
           echo "❌ File not found: $file"
           return 1
       fi
   }
   
   copy_directory_tree() {
       local dir="$1"
       if [[ -d "$dir" ]]; then
           find "$dir" -type f -name "*.py" | head -10 | platform_copy
           echo "✅ Python files list copied to clipboard"
       fi
   }
   
   copy_git_info() {
       local info="Repository: $(basename $(git rev-parse --show-toplevel) 2>/dev/null || echo 'Not a git repo')"$'\n'
       info+="Branch: $(git branch --show-current 2>/dev/null || echo 'No branch')"$'\n'  
       info+="Commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'No commits')"
       
       echo "$info" | platform_copy
       echo "✅ Git information copied to clipboard"
   }

Integration with Other Modules
-----------------------------

**Module Loading Order:**

The shell-compat module should be loaded first, as other modules depend on its functions:

.. code-block:: bash

   # In main zshrc
   source "$HOME/.config/zsh/config/shell-compat.zsh"  # Load first
   source "$HOME/.config/zsh/config/core.zsh"         # Can use platform functions
   source "$HOME/.config/zsh/config/spark.zsh"        # Can use cross-shell arrays

**With Core Module:**

.. code-block:: bash

   # Core module uses platform detection
   mkcd() {
       mkdir -p "$1" && cd "$1"
       
       # Platform-specific notification
       case "$ZSH_PLATFORM" in
           "macos")
               osascript -e "display notification 'Created directory: $1' with title 'Shell'"
               ;;
           *)
               echo "📁 Created and entered: $1"
               ;;
       esac
   }

**With Spark Module:**

.. code-block:: bash

   # Spark module uses cross-shell word splitting
   get_spark_dependencies() {
       local dependencies="--packages org.apache.spark:spark-sql-kafka-0-10_2.12:3.5.0"
       
       # Cross-shell compatible argument parsing
       echo $(word_split "$dependencies")
   }

This comprehensive platform compatibility layer ensures that all shell functions work consistently across different operating systems and shell environments, providing a solid foundation for the entire modular configuration system.