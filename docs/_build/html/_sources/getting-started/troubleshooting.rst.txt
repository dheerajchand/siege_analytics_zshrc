Troubleshooting Guide
=====================

This guide helps you diagnose and resolve common issues with the Siege Analytics ZSH Configuration System.

Common Issues
-------------

Shell Not Loading
~~~~~~~~~~~~~~~~~

Symptoms
^^^^^^^^

- Shell hangs during startup
- Error messages during initialization
- Functions not available

Solutions
^^^^^^^^^

.. code-block:: bash

   # Check if zshrc exists and is a symlink
   ls -la ~/.zshrc
   file ~/.zshrc
   
   # Recreate symlink if needed
   ln -sf ~/.config/zsh/zshrc ~/.zshrc
   
   # Test configuration syntax
   zsh -n ~/.zshrc
   
   # Start with minimal configuration
   zsh -f

Functions Not Available
~~~~~~~~~~~~~~~~~~~~~~~

Symptoms
^^^^^^^^

- Commands like `zsh_help` not found
- Python functions not working
- Backup functions missing

Solutions
^^^^^^^^^

.. code-block:: bash

   # Reload configuration
   source ~/.zshrc
   
   # Check if modules are loaded
   echo $HELP_MODULE_LOADED
   echo $PYTHON_MODULE_LOADED
   
   # Manually load modules
   # backup-system.zsh is optional and disabled by default
   source ~/.config/zsh/help-module.zsh
   
   # Check module paths
   ls -la ~/.config/zsh/*.zsh

Python Issues
~~~~~~~~~~~~~

Symptoms
^^^^^^^^

- Python commands not working
- Virtual environments not activating
- Spark Python integration failing

Solutions
^^^^^^^^^

.. code-block:: bash

   # Check Python status
   python_status
   
   # Reinitialize Python system
   setup_pyenv
   setup_uv
   
   # Check Python version
   python --version
   pyenv versions
   
   # Test Python integration
   python -c "import sys; print(sys.executable)"

SDKMAN Issues
~~~~~~~~~~~~~

Symptoms
^^^^^^^^

- SDKMAN commands not found
- Tools not installing
- Environment variables not set

Solutions
^^^^^^^^^

.. code-block:: bash

   # Reload SDKMAN
   source "$HOME/.sdkman/bin/sdkman-init.sh"
   
   # Check SDKMAN installation
   ls -la ~/.sdkman
   
   # Reinstall SDKMAN if needed
   curl -s "https://get.sdkman.io" | bash
   
   # Check installed tools
   sdk current
   
   # List available candidates
   sdk list java
   sdk list spark

Spark Issues
~~~~~~~~~~~~

Symptoms
^^^^^^^^

- Spark not starting
- Jupyter not connecting to Spark
- Memory errors

Solutions
^^^^^^^^^

.. code-block:: bash

   # Check Spark installation
   ls -la $SPARK_HOME
   echo "SPARK_HOME: $SPARK_HOME"
   
   # Verify Java installation
   java -version
   echo "JAVA_HOME: $JAVA_HOME"
   
   # Test Spark
   spark-shell --version
   
   # Check Spark configuration
   show_spark_config
   
   # Adjust memory settings
   export SPARK_DRIVER_MEMORY="1g"
   export SPARK_EXECUTOR_MEMORY="512m"

Backup System Issues
~~~~~~~~~~~~~~~~~~~~

Symptoms
^^^^^^^^

- Backup commands failing
- Repository sync issues
- Git errors

Solutions
^^^^^^^^^

.. code-block:: bash

   # Check backup system status
   repostatus
   zsh_repo_status
   
   # Verify environment variables
   echo $ZSHRC_CONFIG_DIR
   echo $ZSHRC_BACKUPS
   
   # Check Git status
   cd ~/.config/zsh && git status
   cd ~/.zshrc_backups && git status
   
   # Force sync if needed
   sync_zsh_repositories "Emergency sync"

Performance Issues
------------------

Slow Startup
~~~~~~~~~~~~

Diagnosis
^^^^^^^^^

.. code-block:: bash

   # Profile startup time
   time zsh -i -c exit
   
   # Check for slow modules
   zsh -i -c "echo 'Shell loaded'"
   
   # Monitor module loading
   export PYTHON_DEBUG="1"
   source ~/.zshrc

Solutions
^^^^^^^^^

.. code-block:: bash

   # Disable auto-loading
   export PYTHON_AUTOLOAD_MODULES="0"
   
   # Enable lazy loading
   export PYTHON_LAZY_LOADING="1"
   
   # Optimize PATH
   deduplicate_path
   
   # Remove unused modules
   # Comment out unused module sources in zshrc

High Memory Usage
~~~~~~~~~~~~~~~~~

Diagnosis
^^^^^^^^^

.. code-block:: bash

   # Check memory usage
   ps aux | grep zsh
   top -p $$
   
   # Check Spark memory
   echo "SPARK_DRIVER_MEMORY: $SPARK_DRIVER_MEMORY"
   echo "SPARK_EXECUTOR_MEMORY: $SPARK_EXECUTOR_MEMORY"

Solutions
^^^^^^^^^

.. code-block:: bash

   # Reduce Spark memory
   export SPARK_DRIVER_MEMORY="512m"
   export SPARK_EXECUTOR_MEMORY="256m"
   
   # Limit worker instances
   export SPARK_WORKER_INSTANCES="1"
   
   # Disable unused features
   export PYTHON_AUTOLOAD_MODULES="0"

Command Not Found Errors
~~~~~~~~~~~~~~~~~~~~~~~~

Diagnosis
^^^^^^^^^

.. code-block:: bash

   # Check PATH
   echo $PATH
   
   # Check if command exists
   which command_name
   command -v command_name
   
   # Check module loading
   echo $HELP_MODULE_LOADED

Solutions
^^^^^^^^^

.. code-block:: bash

   # Reload configuration
   source ~/.zshrc
   
   # Check module files
   ls -la ~/.config/zsh/*.zsh
   
   # Manually load modules
   source ~/.config/zsh/help-module.zsh

Debugging Techniques
--------------------

Enable Debug Mode
~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Enable Python debug mode
   export PYTHON_DEBUG="1"
   
   # Enable shell debug mode
   set -x
   
   # Check debug output
   source ~/.zshrc

Log Analysis
~~~~~~~~~~~~

.. code-block:: bash

   # Check system logs
   tail -f /var/log/system.log
   
   # Check shell history
   history | tail -20
   
   # Check error logs
   dmesg | tail -20

Module Testing
~~~~~~~~~~~~~~

.. code-block:: bash

   # Test individual modules
   # Test core functionality instead:
   ./test-modular-quick.sh
   
   # Test Python system
   zsh -c "source ~/.config/zsh/python/init.zsh; python_status"
   
   # Test help system
   zsh -c "source ~/.config/zsh/help-module.zsh; zsh_help all"

Recovery Procedures
-------------------

Complete Reset
~~~~~~~~~~~~~~

.. code-block:: bash

   # Backup current configuration
   cp -r ~/.config/zsh ~/.config/zsh.backup.$(date +%Y%m%d_%H%M%S)
   
   # Remove current configuration
   rm -rf ~/.config/zsh
   rm -f ~/.zshrc
   
   # Reinstall from repository
   cd ~/.config
   git clone https://github.com/dheerajchand/siege_analytics_zshrc.git zsh
   ln -sf ~/.config/zsh/zshrc ~/.zshrc
   
   # Restart shell
   exec zsh

Partial Reset
~~~~~~~~~~~~~

.. code-block:: bash

   # Reset specific modules
   git checkout HEAD -- ~/.config/zsh/backup-system.zsh
   git checkout HEAD -- ~/.config/zsh/help-module.zsh
   
   # Reload modules
   source ~/.config/zsh/backup-system.zsh
   source ~/.config/zsh/help-module.zsh

Environment Reset
~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Reset environment variables
   unset PYTHON_MANAGER
   unset SPARK_DRIVER_MEMORY
   unset SPARK_EXECUTOR_MEMORY
   
   # Reload configuration
   source ~/.zshrc

Getting Help
------------

Documentation
~~~~~~~~~~~~~

- **This documentation**: Comprehensive guides and references
- **Interactive help**: Use `zsh_help` commands
- **Function documentation**: Every function has built-in help
- **GitHub repositories**: Source code and issues

Support Channels
~~~~~~~~~~~~~~~~

- **GitHub Issues**: Bug reports and feature requests
- **Documentation**: This comprehensive guide
- **Interactive Help**: Built-in help system

Emergency Contacts
~~~~~~~~~~~~~~~~~~

For critical issues:

1. **Check this troubleshooting guide** first
2. **Use the interactive help system** (`zsh_help`)
3. **Create a GitHub issue** with detailed information
4. **Include system information** and error messages

.. note::

   Most issues can be resolved by following the solutions in this guide. If problems persist, the interactive help system and GitHub issues provide additional support.
