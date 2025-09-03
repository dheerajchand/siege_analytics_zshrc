Configuration Guide
====================

This guide covers advanced configuration options for the Siege Analytics ZSH Configuration System.

Environment Variables
---------------------

Core Configuration
~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Core system configuration
   export ZSHRC_CONFIG_DIR="$HOME/.config/zsh"
   export ZSHRC_BACKUPS="$HOME/.zshrc_backups"
   
   # Python management
   export PYTHON_MANAGER="auto"  # pyenv, uv, or auto
   export PYTHON_DEBUG="0"
   export PYTHON_AUTOLOAD_MODULES="0"
   
   # Performance optimization
   export PATH_DEDUPLICATION_ENABLED="true"
   export AUTO_BACKUP_ON_CHANGE="true"
   export AUTO_BACKUP_INTERVAL="3600"

SDKMAN Configuration
~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # SDKMAN environment
   export SDKMAN_DIR="$HOME/.sdkman"
   [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
   
   # SDKMAN-managed tools
   export JAVA_HOME="$HOME/.sdkman/candidates/java/current"
   export SCALA_HOME="$HOME/.sdkman/candidates/scala/current"
   export SPARK_HOME="$HOME/.sdkman/candidates/spark/current"
   export HADOOP_HOME="$HOME/.sdkman/candidates/hadoop/current"

Spark Configuration
~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Spark settings
   export SPARK_DRIVER_MEMORY="2g"
   export SPARK_EXECUTOR_MEMORY="1g"
   export SPARK_WORKER_MEMORY="2g"
   export SPARK_WORKER_INSTANCES="4"
   
   # Performance tuning
   export SPARK_SQL_ADAPTIVE_ENABLED="true"
   export SPARK_SQL_ADAPTIVE_COALESCE_PARTITIONS_ENABLED="true"

Customization Options
---------------------

Theme Configuration
~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Powerlevel10k configuration
   export ZSH_THEME="powerlevel10k/powerlevel10k"
   
   # Custom prompt elements
   export POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
   export POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time)

Alias Configuration
~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Custom aliases
   alias ll="ls -la"
   alias la="ls -A"
   alias l="ls -CF"
   alias ..="cd .."
   alias ...="cd ../.."
   
   # Git aliases
   alias gs="git status"
   alias ga="git add"
   alias gc="git commit"
   alias gp="git push"

Function Configuration
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Custom functions
   custom_function() {
       echo "This is a custom function"
   }
   
   # Add to ~/.config/zsh/custom.zsh
   # This file is automatically sourced if it exists

Performance Tuning
------------------

Startup Optimization
~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Disable slow-loading modules
   export PYTHON_AUTOLOAD_MODULES="0"
   
   # Enable lazy loading
   export PYTHON_LAZY_LOADING="1"
   
   # Optimize PATH
   deduplicate_path

Memory Optimization
~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Reduce memory usage
   export SPARK_DRIVER_MEMORY="1g"
   export SPARK_EXECUTOR_MEMORY="512m"
   
   # Limit worker instances
   export SPARK_WORKER_INSTANCES="2"

Advanced Configuration
----------------------

Custom Modules
~~~~~~~~~~~~~~

Create custom modules in `~/.config/zsh/custom/`:

.. code-block:: bash

   # Create custom module
   mkdir -p ~/.config/zsh/custom
   cat > ~/.config/zsh/custom/my-module.zsh << 'EOF'
   #!/usr/bin/env zsh
   
   # Custom module content
   my_custom_function() {
       echo "Custom function from my module"
   }
   EOF
   
   # Module will be automatically loaded

Plugin Configuration
~~~~~~~~~~~~~~~~~~~~

Configure Oh My Zsh plugins:

.. code-block:: bash

   # Edit ~/.zshrc
   plugins=(
       git
       python
       pip
       docker
       kubectl
   )

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

Slow Startup
^^^^^^^^^^^^

.. code-block:: bash

   # Profile startup time
   time zsh -i -c exit
   
   # Disable auto-loading
   export PYTHON_AUTOLOAD_MODULES="0"
   
   # Check for slow modules
   zsh -i -c "echo 'Shell loaded'"

Memory Issues
^^^^^^^^^^^^^

.. code-block:: bash

   # Check memory usage
   ps aux | grep zsh
   
   # Reduce Spark memory
   export SPARK_DRIVER_MEMORY="512m"
   
   # Limit worker instances
   export SPARK_WORKER_INSTANCES="1"

Configuration Validation
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Validate configuration
   zsh -n ~/.zshrc
   
   # Check environment variables
   env | grep -E "(SPARK|PYTHON|SDKMAN)"
   
   # Test functions
   python_status
   repostatus

.. note::

   This configuration guide provides comprehensive options for customizing the Siege Analytics ZSH Configuration System to meet your specific needs.
