Quick Start Guide
=================

Get up and running with the Siege Analytics ZSH Configuration System in minutes.

Prerequisites
-------------

Before you begin, ensure you have:

- **macOS, Ubuntu Linux, or RedHat Linux**
- **Git** installed
- **Internet connection** for downloading tools
- **Basic familiarity** with command line

Installation
------------

Step 1: Install SDKMAN
~~~~~~~~~~~~~~~~~~~~~~

SDKMAN provides consistent tool management across all platforms:

.. code-block:: bash

   # Install SDKMAN
   curl -s "https://get.sdkman.io" | bash

   # Reload your shell
   source "$HOME/.sdkman/bin/sdkman-init.sh"

   # Verify installation
   sdk version

Step 2: Install Essential Tools
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install the core development tools:

.. code-block:: bash

   # Java (required for Spark)
   sdk install java 17.0.9-tem
   sdk default java 17.0.9-tem

   # Python (via pyenv)
   sdk install pyenv
   sdk default pyenv

   # Initialize pyenv
   export PYENV_ROOT="$HOME/.sdkman/candidates/pyenv/current"
   export PATH="$PYENV_ROOT/bin:$PATH"
   eval "$(pyenv init -)"
   eval "$(pyenv virtualenv-init -)"

   # Install Python 3.11
   pyenv install 3.11.7
   pyenv global 3.11.7

Step 3: Clone the Configuration
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Clone the main configuration repository:

.. code-block:: bash

   # Navigate to config directory
   cd ~/.config

   # Backup existing zsh config (if any)
   [ -d zsh ] && mv zsh zsh.backup.$(date +%Y%m%d_%H%M%S)

   # Clone the configuration
   git clone https://github.com/dheerajchand/siege_analytics_zshrc.git zsh

   # Create symlink to main zshrc
   ln -sf ~/.config/zsh/zshrc ~/.zshrc

Step 4: Install Oh My Zsh and Theme
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Install the shell framework and theme:

.. code-block:: bash

   # Install Oh My Zsh
   sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

   # Install Powerlevel10k theme
   git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k

Step 5: Restart Your Shell
~~~~~~~~~~~~~~~~~~~~~~~~~~

Restart your shell to load the new configuration:

.. code-block:: bash

   # Restart shell
   exec zsh

   # Or open a new terminal window

First Steps
-----------

Test the Installation
~~~~~~~~~~~~~~~~~~~~~

Verify everything is working:

.. code-block:: bash

   # Test core functions
   zsh_help all

   # Check Python system
   python_status

   # Test backup system
   backup "Initial setup test"

Explore the System
~~~~~~~~~~~~~~~~~~

Get familiar with the available functions:

.. code-block:: bash

   # List all available functions
   zsh_help list

   # Get help for specific modules
   zsh_help python
   zsh_help backup
   zsh_help spark

   # Search for specific functionality
   zsh_help search "jupyter"

Create Your First Project
-------------------------

Data Science Project
~~~~~~~~~~~~~~~~~~~~

Create a data science project with Spark integration:

.. code-block:: bash

   # Create project directory
   mkdir my_data_project && cd my_data_project

   # Setup Python environment
   pyenv virtualenv 3.11.7 data_science
   pyenv local data_science

   # Install data science packages
   pip install pandas numpy matplotlib seaborn jupyter

   # Load big data stack
   load_big_data

   # Start Spark-enabled Jupyter
   jupyter_spark 8889

   # Open http://localhost:8889 in your browser

Web Development Project
~~~~~~~~~~~~~~~~~~~~~~~

Create a modern web API project:

.. code-block:: bash

   # Create project directory
   mkdir my_api && cd my_api

   # Install uv (modern Python package manager)
   curl -LsSf https://astral.sh/uv/install.sh | sh
   export PATH="$HOME/.local/bin:$PATH"

   # Initialize uv project
   uv init --python 3.12

   # Add dependencies
   uv add fastapi uvicorn

   # Run development server
   uv run uvicorn main:app --reload

   # Open http://localhost:8000 in your browser

Key Features to Try
-------------------

Backup System
~~~~~~~~~~~~~

The system includes comprehensive backup capabilities:

.. code-block:: bash

   # Create a backup
   backup "Testing backup system"

   # List all backups
   list_zsh_backups

   # Check repository status
   repostatus

Python Environment Management
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Switch between Python managers seamlessly:

.. code-block:: bash

   # Check current Python setup
   python_status

   # Switch to pyenv
   switch_python_manager pyenv

   # Switch to uv
   switch_python_manager uv

   # Auto-detect based on project
   switch_python_manager auto

Big Data Integration
~~~~~~~~~~~~~~~~~~~~

Load the complete big data stack:

.. code-block:: bash

   # Load Spark, Hadoop, and related tools
   load_big_data

   # Start Spark-enabled Jupyter
   jupyter_spark 8889

   # Check Spark configuration
   show_spark_config

Performance Optimization
~~~~~~~~~~~~~~~~~~~~~~~~

The system includes performance optimizations:

.. code-block:: bash

   # Remove duplicate PATH entries
   deduplicate_path

   # Check system performance
   python_benchmark

   # Monitor system health
   python_health_check

Common Commands
---------------

Essential Commands
~~~~~~~~~~~~~~~~~~

.. list-table:: Essential Commands
   :header-rows: 1
   :widths: 30 70

   * - Command
     - Description
   * - ``zsh_help all``
     - Show comprehensive help
   * - ``python_status``
     - Check Python environment
   * - ``backup "message"``
     - Create system backup
   * - ``load_big_data``
     - Load Spark/Hadoop stack
   * - ``jupyter_spark 8889``
     - Start Spark-enabled Jupyter
   * - ``repostatus``
     - Check repository status
   * - ``deduplicate_path``
     - Optimize PATH performance

Help System
~~~~~~~~~~~

The system includes comprehensive help:

.. code-block:: bash

   # Main help overview
   zsh_help all

   # Module-specific help
   zsh_help python
   zsh_help backup
   zsh_help spark

   # Search for functions
   zsh_help search "jupyter"
   zsh_help search "spark"

   # Function-specific help
   zsh_help function python_status
   zsh_help function backup

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

Shell Not Loading
^^^^^^^^^^^^^^^^^

If your shell doesn't load properly:

.. code-block:: bash

   # Check if zshrc exists
   ls -la ~/.zshrc

   # Check if it's a symlink
   file ~/.zshrc

   # Recreate symlink if needed
   ln -sf ~/.config/zsh/zshrc ~/.zshrc

Functions Not Available
^^^^^^^^^^^^^^^^^^^^^^^

If functions aren't available:

.. code-block:: bash

   # Reload configuration
   source ~/.zshrc

   # Check if modules are loaded
   echo $HELP_MODULE_LOADED

   # Reload specific modules
   # Backup system is optional and disabled by default

Python Issues
^^^^^^^^^^^^^

If Python isn't working:

.. code-block:: bash

   # Check Python status
   python_status

   # Reinitialize Python system
   setup_pyenv

   # Check Python version
   python --version

SDKMAN Issues
^^^^^^^^^^^^^

If SDKMAN isn't working:

.. code-block:: bash

   # Reload SDKMAN
   source "$HOME/.sdkman/bin/sdkman-init.sh"

   # Check installed tools
   sdk current

   # Reinstall if needed
   curl -s "https://get.sdkman.io" | bash

Getting Help
------------

Documentation
~~~~~~~~~~~~~

- **This documentation**: Comprehensive guides and references
- **Interactive help**: Use ``zsh_help`` commands
- **Function documentation**: Every function has built-in help
- **GitHub repositories**: Source code and issues

Support Channels
~~~~~~~~~~~~~~~~

- **GitHub Issues**: Bug reports and feature requests
- **Documentation**: This comprehensive guide
- **Interactive Help**: Built-in help system

Next Steps
----------

Explore Advanced Features
~~~~~~~~~~~~~~~~~~~~~~~~~

Once you're comfortable with the basics:

1. **Read the full documentation** for detailed guides
2. **Explore the Python management system** for advanced usage
3. **Try the big data integration** for Spark and Hadoop
4. **Set up automated backups** for your workflow
5. **Customize the configuration** for your needs

Learn More
~~~~~~~~~~

- :doc:`../core-systems/python-management` - Advanced Python management
- :doc:`../big-data/spark-system` - Big data integration
- :doc:`../development/workflows` - Development workflows

.. note::

   You're now ready to use the Siege Analytics ZSH Configuration System! Start with the basic commands and gradually explore the advanced features as you become more comfortable with the system.
