Backup System
=============

The backup system provides comprehensive, automated backup capabilities with time-based organization, dual repository synchronization, and intelligent conflict resolution.

System Overview
---------------

Core Features
~~~~~~~~~~~~~

- **Time-Based Organization**: Year/month/week structure
- **Dual Repository Sync**: Main config and backup repositories
- **Automatic Git Integration**: Retry logic and conflict resolution
- **Metadata Generation**: System information and restore scripts
- **Health Monitoring**: Status checking and error handling
- **Performance Optimization**: PATH deduplication and caching

Architecture
~~~~~~~~~~~~

.. mermaid::
   :caption: Backup System Architecture

   graph TB
       A[Configuration Changes] --> B[Backup Trigger]
       B --> C[Time-based Organization]
       C --> D[Metadata Generation]
       D --> E[Git Operations]
       E --> F[Dual Repository Sync]
       F --> G[Health Monitoring]
       
       H[Main Repository] --> I[Active Configuration]
       J[Backup Repository] --> K[Historical Backups]
       
       I --> L[Sync Operations]
       K --> L
       L --> M[Conflict Resolution]
       M --> N[Status Reporting]

Environment Variables
---------------------

Core Configuration
~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Core backup system configuration
   export ZSHRC_CONFIG_DIR="$HOME/.config/zsh"
   export ZSHRC_BACKUPS="$HOME/.zshrc_backups"
   
   # Automatic backup triggers
   export AUTO_BACKUP_ON_CHANGE=true
   export AUTO_BACKUP_INTERVAL=3600  # 1 hour in seconds
   
   # Performance optimization
   export PATH_DEDUPLICATION_ENABLED=true

Key Functions
-------------

``backup(message)``
~~~~~~~~~~~~~~~~~~~

Creates a comprehensive backup with metadata and Git integration.

.. code-block:: bash

   # Create backup with message
   backup "Major system update"
   
   # Features:
   # - Time-based organization
   # - Metadata generation
   # - Git commit and push
   # - Dual repository sync
   # - Health monitoring

``enhanced_backup(message)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Creates an enhanced backup with additional features.

.. code-block:: bash

   # Create enhanced backup
   enhanced_backup "Feature addition"
   
   # Additional features:
   # - Performance optimization
   # - PATH deduplication
   # - Documentation sync
   # - Health checks

``sync_zsh_repositories(message)``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Synchronizes both main and backup repositories.

.. code-block:: bash

   # Sync both repositories
   sync_zsh_repositories "Repository sync"
   
   # Operations:
   # - Git operations on both repos
   # - Conflict resolution
   # - Retry logic
   # - Status reporting

``sync_documentation_between_repos()``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Synchronizes documentation between repositories.

.. code-block:: bash

   # Sync documentation
   sync_documentation_between_repos
   
   # Syncs:
   # - README.md files
   # - docs/ directory
   # - help-module.zsh
   # - backup-system.zsh

``list_zsh_backups()``
~~~~~~~~~~~~~~~~~~~~~~~

Lists all available backups with metadata.

.. code-block:: bash

   # List all backups
   list_zsh_backups
   
   # Shows:
   # - Backup timestamps
   # - Backup messages
   # - Repository status
   # - Health information

``zsh_repo_status()``
~~~~~~~~~~~~~~~~~~~~~~

Comprehensive repository status check.

.. code-block:: bash

   # Check repository status
   zsh_repo_status
   
   # Reports:
   # - Git status
   # - Sync status
   # - Health metrics
   # - Performance data

Performance Optimization
------------------------

PATH Deduplication
~~~~~~~~~~~~~~~~~~

``deduplicate_path()``
^^^^^^^^^^^^^^^^^^^^^^

Removes duplicate PATH entries for performance optimization.

.. code-block:: bash

   # Remove duplicate PATH entries
   deduplicate_path
   
   # Benefits:
   # - Faster shell startup
   # - Improved Finder performance
   # - Reduced memory usage
   # - Better command resolution

Automatic Optimization
~~~~~~~~~~~~~~~~~~~~~~

The system automatically optimizes performance:

.. code-block:: bash

   # Automatic optimizations
   export PATH_DEDUPLICATION_ENABLED=true
   
   # Triggers:
   # - During backup creation
   # - During system startup
   # - During repository sync
   # - During health checks

Time-Based Organization
-----------------------

Directory Structure
~~~~~~~~~~~~~~~~~~~

.. code-block:: text

   ~/.zshrc_backups/                    # Backup repository root
   ├── README.md                        # Repository documentation
   ├── .last_backup                     # Last backup timestamp
   ├── 2025/                            # Year-based organization
   │   └── 01/                         # Month-based organization
   │       └── week1/                  # Week-based organization
   │           └── config_2025-01-15_14-30-45/  # Timestamped backup
   │               ├── metadata.json   # Backup metadata
   │               ├── restore.sh      # Restore script
   │               ├── zshrc.txt       # Main configuration backup
   │               └── zsh/            # Module files backup
   │                   ├── *.zsh       # All module files
   │                   ├── docs/       # Documentation
   │                   └── wiki/       # Wiki content
   └── docs/                            # Comprehensive documentation

Metadata Generation
~~~~~~~~~~~~~~~~~~~

Each backup includes comprehensive metadata:

.. code-block:: json

   {
     "timestamp": "2025-01-15T14:30:45Z",
     "message": "System update",
     "system_info": {
       "os": "macOS",
       "version": "14.6.0",
       "shell": "zsh",
       "python_manager": "pyenv",
       "spark_version": "3.5.3"
     },
     "backup_info": {
       "files_count": 45,
       "total_size": "2.3MB",
       "modules_loaded": 12,
       "functions_available": 156
     },
     "git_info": {
       "main_repo_status": "clean",
       "backup_repo_status": "clean",
       "last_commit": "abc123",
       "branch": "main"
     }
   }

Dual Repository System
----------------------

Repository Relationships
~~~~~~~~~~~~~~~~~~~~~~~~

.. mermaid::
   :caption: Dual Repository System

   graph LR
       A[Main Config Repository] --> B[Active Configuration]
       C[Backup Repository] --> D[Historical Backups]
       
       B --> E[Sync Operations]
       D --> E
       E --> F[Conflict Resolution]
       F --> G[Status Monitoring]
       
       H[Git Operations] --> I[Main Repo]
       H --> J[Backup Repo]
       I --> K[Version Control]
       J --> L[Historical Tracking]

Main Repository
~~~~~~~~~~~~~~~

- **Purpose**: Active configuration and modules
- **Content**: Current working configuration files
- **Updates**: Frequent commits and pushes
- **Remote**: `git@github.com/dheerajchand/siege_analytics_zshrc`

Backup Repository
~~~~~~~~~~~~~~~~~

- **Purpose**: Historical backups and comprehensive docs
- **Content**: Time-organized backups + full documentation
- **Updates**: Automatic backup creation and sync
- **Remote**: `git@github.com/dheerajchand/zshrc_backups`

Synchronization Process
-----------------------

Automatic Operations
~~~~~~~~~~~~~~~~~~~~

The system automatically:

- **Creates backups** when configuration changes
- **Synchronizes both repositories** to maintain consistency
- **Handles conflicts** with retry logic and rebasing
- **Monitors repository health** and reports issues

Manual Operations
~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Quick sync (daily use)
   sync                       # Sync both repositories

   # Enhanced backup with sync (major changes)
   backup                     # Create backup and sync repositories

   # Check status
   repostatus                 # Repository health and status
   zsh_repo_status           # Detailed repository status

Conflict Resolution
-------------------

Automatic Resolution
~~~~~~~~~~~~~~~~~~~~

The system handles conflicts automatically:

.. code-block:: bash

   # Automatic conflict resolution
   git pull --rebase origin main
   git push origin main
   
   # Retry logic
   for attempt in {1..3}; do
     if git push origin main; then
       break
     else
       sleep 5
     fi
   done

Manual Resolution
~~~~~~~~~~~~~~~~~

For complex conflicts:

.. code-block:: bash

   # Check repository status
   zsh_repo_status
   
   # Force sync if needed
   sync_zsh_repositories "Emergency sync"
   
   # Manual Git operations
   cd ~/.config/zsh && git status
   cd ~/.zshrc_backups && git status

Health Monitoring
-----------------

Status Checking
~~~~~~~~~~~~~~~

``repostatus()``
^^^^^^^^^^^^^^^^

Quick repository status check.

.. code-block:: bash

   # Quick status check
   repostatus
   
   # Shows:
   # - Repository status
   # - Sync status
   # - Last backup time
   # - Health indicators

``zsh_repo_status()``
^^^^^^^^^^^^^^^^^^^^^^

Comprehensive repository health check.

.. code-block:: bash

   # Comprehensive health check
   zsh_repo_status
   
   # Reports:
   # - Git status for both repos
   # - Sync status
   # - Performance metrics
   # - Error logs
   # - Recommendations

Performance Monitoring
~~~~~~~~~~~~~~~~~~~~~~

The system monitors:

- **Backup creation time**
- **Sync operation duration**
- **Git operation performance**
- **Repository health metrics**
- **Error rates and patterns**

Troubleshooting
---------------

Common Issues
~~~~~~~~~~~~~

Repository Out of Sync
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check status
   repostatus

   # Force sync
   sync_zsh_repositories "Emergency sync"

Backup Creation Issues
^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check backup system
   zsh_help backup

   # Verify environment variables
   echo $ZSHRC_CONFIG_DIR
   echo $ZSHRC_BACKUPS

Git Issues
^^^^^^^^^^

.. code-block:: bash

   # Check individual repository status
   cd ~/.config/zsh && git status
   cd ~/.zshrc_backups && git status

   # Force sync if needed
   sync_zsh_repositories "Emergency sync"

Performance Issues
^^^^^^^^^^^^^^^^^^

.. code-block:: bash

   # Check PATH duplicates
   deduplicate_path

   # Monitor performance
   zsh_repo_status

   # Optimize configuration
   export PATH_DEDUPLICATION_ENABLED=true

Advanced Usage
--------------

Custom Backup Scripts
~~~~~~~~~~~~~~~~~~~~~

Create custom backup scripts:

.. code-block:: bash

   # Custom backup script
   custom_backup() {
     local message="$1"
     local timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
     
     # Create backup
     backup "$message"
     
     # Additional operations
     sync_documentation_between_repos
     deduplicate_path
     
     # Notify completion
     echo "Backup completed: $timestamp"
   }

Automated Backups
~~~~~~~~~~~~~~~~~

Set up automated backups:

.. code-block:: bash

   # Add to crontab for daily backups
   crontab -e
   
   # Add line:
   # 0 2 * * * /Users/dheerajchand/.config/zsh/backup-system.zsh daily_backup

Integration with Other Systems
------------------------------

Python System Integration
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Backup Python environments
   backup "Python environment update"
   
   # Includes:
   # - Python manager state
   # - Virtual environment info
   # - Package lists
   # - Configuration files

Spark System Integration
~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: bash

   # Backup Spark configuration
   backup "Spark configuration update"
   
   # Includes:
   # - Spark configuration
   # - Environment variables
   # - Performance settings
   # - Integration status

Best Practices
--------------

Backup Strategy
~~~~~~~~~~~~~~~

1. **Regular backups** for configuration changes
2. **Enhanced backups** for major updates
3. **Documentation sync** for documentation changes
4. **Health monitoring** for system maintenance

Repository Management
~~~~~~~~~~~~~~~~~~~~~

1. **Keep repositories in sync** with automatic operations
2. **Monitor repository health** regularly
3. **Resolve conflicts** promptly
4. **Maintain clean history** with meaningful commit messages

Performance Optimization
~~~~~~~~~~~~~~~~~~~~~~~~

1. **Enable PATH deduplication** for better performance
2. **Monitor backup performance** and optimize as needed
3. **Use appropriate backup intervals** based on usage
4. **Clean up old backups** periodically

.. note::

   The backup system provides enterprise-grade backup capabilities with intelligent automation, comprehensive monitoring, and seamless integration with the entire ZSH configuration system.
