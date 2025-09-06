Welcome to Siege Analytics ZSH Configuration System
====================================================

.. image:: _static/logo.png
   :alt: Siege Analytics Logo
   :align: center
   :width: 200px

**Spatial Intelligence • Data Science • Advanced Analytics**

The Siege Analytics ZSH Configuration System is an enterprise-grade, modular shell configuration that provides comprehensive development tools, big data integration, and cross-platform compatibility. Built with SDKMAN-first architecture, it offers intelligent Python environment management, automated backup systems with toggle controls, and seamless integration with Apache Spark, Hadoop, and YARN.

**System Status: Production Ready** - 86% size reduction, 10 focused modules, cross-shell compatibility (bash + zsh), and comprehensive backup control system.

.. toctree::
   :maxdepth: 2
   :caption: Getting Started

   getting-started/installation
   getting-started/quick-start
   getting-started/configuration
   getting-started/troubleshooting

.. toctree::
   :maxdepth: 2
   :caption: Core Systems

   core-systems/python-management
   core-systems/help-system
   core-systems/performance-optimization

.. toctree::
   :maxdepth: 2
   :caption: Big Data Integration

   big-data/spark-system
   big-data/hadoop-integration
   big-data/yarn-management
   big-data/geospatial-analytics

.. toctree::
   :maxdepth: 2
   :caption: Development Tools

   development/jupyter-integration
   development/ide-integration
   development/docker-support
   development/remote-deployment

.. toctree::
   :maxdepth: 2
   :caption: Cross-Platform

   cross-platform/ubuntu-linux
   cross-platform/redhat-linux
   cross-platform/docker-containers
   cross-platform/remote-servers

.. toctree::
   :maxdepth: 2
   :caption: Advanced Topics

   advanced/repository-management
   advanced/performance-tuning
   advanced/customization
   advanced/bash-compatibility

.. toctree::
   :maxdepth: 2
   :caption: API Reference

   api-reference/functions
   api-reference/environment-variables
   api-reference/aliases
   api-reference/configuration-options

.. toctree::
   :maxdepth: 2
   :caption: Contributing

   contributing/development-setup
   contributing/documentation
   contributing/testing
   contributing/contributing-guidelines

Key Features
============

.. tabs::

   .. tab:: 🎯 SDKMAN-First Architecture

      - **Cross-Platform Consistency**: All tools managed through SDKMAN
      - **Version Management**: Easy switching between tool versions
      - **No Root Required**: User-level installations across all platforms
      - **Unified Installation**: Same process on macOS, Ubuntu, and RedHat
      - **Tool Ecosystem**: Java, Scala, Spark, Hadoop, Maven, Gradle via SDKMAN

   .. tab:: 🐍 Intelligent Python Management

      - **Dual Manager Support**: Seamless switching between pyenv and uv
      - **Automatic Detection**: Context-aware environment selection
      - **Performance Optimized**: Lazy loading and caching
      - **Spark Integration**: Automatic Python path configuration
      - **Virtual Environment Management**: Rich status and health monitoring

   .. tab:: 💾 Automated Backup System

      - **Time-Based Organization**: Year/month/week structure
      - **Dual Repository Sync**: Main config and backup repositories
      - **Automatic Git Integration**: Retry logic and conflict resolution
      - **Metadata Generation**: System information and restore scripts
      - **Health Monitoring**: Status checking and error handling

   .. tab:: 🚀 Big Data Integration

      - **Apache Spark 3.5.3**: Complete ecosystem with 74K+ lines
      - **Hadoop Integration**: HDFS and YARN support
      - **Geospatial Analytics**: Apache Sedona integration
      - **Graph Processing**: GraphFrames for network analysis
      - **Jupyter Integration**: Spark-enabled notebooks

   .. tab:: 🌍 Cross-Platform Support

      - **macOS**: Native support with SDKMAN
      - **Ubuntu Linux**: Full compatibility with apt package management
      - **RedHat Linux**: Support for RHEL, CentOS, and Rocky Linux
      - **Docker Containers**: Ready-to-use containerized environments
      - **Remote Servers**: Automated deployment scripts

Quick Start
===========

Install SDKMAN and clone the repository:

.. code-block:: bash

   # Install SDKMAN
   curl -s "https://get.sdkman.io" | bash
   source "$HOME/.sdkman/bin/sdkman-init.sh"

   # Install tools via SDKMAN
   sdk install java 17.0.9-tem
   sdk install scala 2.12.18
   sdk install spark 3.5.3
   sdk install hadoop 3.3.6

   # Clone and setup
   cd ~/.config
   git clone https://github.com/dheerajchand/siege_analytics_zshrc.git zsh
   ln -sf ~/.config/zsh/zshrc ~/.zshrc
   exec zsh

Test the installation:

.. code-block:: bash

   # Test core functions
   zsh_help all
   python_status
   load_big_data
   jupyter_spark 8889

System Architecture
===================

.. mermaid::
   :caption: System Architecture Overview

   graph TB
       A[ZSH Shell] --> B[Core Modules]
       B --> C[Python Management]
       B --> D[Backup System]
       B --> E[Help System]
       B --> F[Performance Optimization]
       
       C --> G[pyenv Manager]
       C --> H[uv Manager]
       C --> I[Virtual Environments]
       
       D --> J[Time-based Organization]
       D --> K[Git Integration]
       D --> L[Dual Repository Sync]
       
       E --> M[Interactive Help]
       E --> N[Function Documentation]
       E --> O[Search Capabilities]
       
       F --> P[PATH Deduplication]
       F --> Q[Lazy Loading]
       F --> R[Performance Monitoring]
       
       S[Big Data Stack] --> T[Apache Spark]
       S --> U[Hadoop]
       S --> V[YARN]
       S --> W[Geospatial Analytics]
       
       T --> X[Jupyter Integration]
       U --> X
       V --> X
       W --> X

Performance Metrics
===================

.. list-table:: Performance Targets
   :header-rows: 1
   :widths: 30 20 20 30

   * - Metric
     - Target
     - Current
     - Notes
   * - Startup Time
     - < 1.5s
     - 1.25s
     - Optimized with lazy loading
   * - Memory Usage
     - < 100MB
     - 85MB
     - Baseline with core modules
   * - Command Response
     - Immediate
     - < 50ms
     - No hanging or delays
   * - Module Loading
     - On-demand
     - < 100ms
     - Fast module switching

Repository Structure
====================

.. code-block:: text

   ~/.config/zsh/                    # Main configuration repository
   ├── README.md                     # Main documentation
   ├── zshrc                         # Main configuration file
   ├── backup-system.zsh             # Backup and sync system
   ├── help-module.zsh               # Interactive help system
   ├── spark.zsh                     # 74K-line Spark system
   ├── hadoop.zsh                    # Hadoop integration
   ├── notebooks.zsh                 # Jupyter integration
   ├── python/                       # Python management system
   │   ├── init.zsh                  # Main initialization
   │   ├── managers/                 # pyenv and uv managers
   │   ├── integrations/             # Spark and notebook integration
   │   └── utils/                    # Benchmarks and health checks
   ├── docs/                         # Comprehensive documentation
   │   ├── conf.py                   # Sphinx configuration
   │   ├── index.rst                 # Main documentation index
   │   ├── getting-started/          # Installation and setup guides
   │   ├── core-systems/             # Core system documentation
   │   ├── big-data/                 # Big data integration docs
   │   ├── development/              # Development tools docs
   │   ├── cross-platform/           # Cross-platform guides
   │   ├── advanced/                 # Advanced topics
   │   └── api-reference/            # Function and API reference
   └── scripts/                      # Utility scripts

Support and Community
=====================

- **GitHub Repository**: `siege_analytics_zshrc <https://github.com/dheerajchand/siege_analytics_zshrc>`_
- **Backup Repository**: `zshrc_backups <https://github.com/dheerajchand/zshrc_backups>`_
- **Company Website**: `Siege Analytics <https://www.siegeanalytics.com>`_
- **Documentation**: This comprehensive guide
- **Issues**: GitHub Issues for bug reports and feature requests

License
=======

This project is licensed under the MIT License - see the LICENSE file for details.

.. note::

   This documentation is automatically generated and kept in sync with the codebase. For the most up-to-date information, always refer to the latest version in the repository.

.. warning::

   This system is designed for advanced users and developers. Some features require understanding of shell scripting, Python environments, and big data tools.

.. tip::

   Start with the :doc:`getting-started/installation` guide for a complete setup, then explore the :doc:`core-systems/python-management` for Python environment management.
