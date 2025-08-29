# 🌍 Cross-Platform Compatibility Guide

## Overview

This guide provides comprehensive instructions for running your enhanced Zsh configuration on Ubuntu Linux and RedHat Linux systems, ensuring compatibility when macOS-specific features aren't available.

## 🐧 Ubuntu Linux Compatibility

### System Requirements
- **Ubuntu 20.04 LTS** or later (recommended)
- **Zsh 5.8** or later
- **Git** for repository management
- **Python 3.8+** for development tools

### Installation Steps

#### 1. Install Zsh and Dependencies
```bash
# Update package list
sudo apt update

# Install Zsh and essential tools
sudo apt install -y zsh git curl wget build-essential

# Install Python and development tools
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Install Node.js (for NVM)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Homebrew equivalent (Linuxbrew)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Python Version Managers
```bash
# Install pyenv
curl https://pyenv.run | bash

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.pyenv/bin:$PATH"
```

#### 3. Install Big Data Tools
```bash
# Install Java (OpenJDK 11 or 17)
sudo apt install -y openjdk-11-jdk

# Install Spark
wget https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
tar -xzf spark-3.5.0-bin-hadoop3.tgz
sudo mv spark-3.5.0-bin-hadoop3 /opt/spark

# Install Hadoop
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
tar -xzf hadoop-3.3.6.tar.gz
sudo mv hadoop-3.3.6 /opt/hadoop
```

### Configuration Adaptations

#### Environment Variables
```bash
# Add to ~/.zshrc or ~/.bashrc
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export SPARK_HOME=/opt/spark
export HADOOP_HOME=/opt/hadoop
export PATH="$SPARK_HOME/bin:$HADOOP_HOME/bin:$PATH"
```

#### Path Differences
```bash
# Ubuntu-specific paths
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"  # User-installed binaries
```

## 🔴 RedHat Linux Compatibility

### System Requirements
- **RHEL 8** or later, **CentOS 8** or later, **Rocky Linux 8** or later
- **Zsh 5.8** or later
- **Git** for repository management
- **Python 3.8+** for development tools

### Installation Steps

#### 1. Install Zsh and Dependencies
```bash
# Enable EPEL repository
sudo dnf install -y epel-release

# Install Zsh and essential tools
sudo dnf install -y zsh git curl wget gcc gcc-c++ make

# Install Python and development tools
sudo dnf install -y python3 python3-pip python3-devel

# Install Node.js (for NVM)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install Homebrew equivalent (Linuxbrew)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Python Version Managers
```bash
# Install pyenv
curl https://pyenv.run | bash

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.pyenv/bin:$PATH"
```

#### 3. Install Big Data Tools
```bash
# Install Java (OpenJDK 11 or 17)
sudo dnf install -y java-11-openjdk-devel

# Install Spark
wget https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz
tar -xzf spark-3.5.0-bin-hadoop3.tgz
sudo mv spark-3.5.0-bin-hadoop3 /opt/spark

# Install Hadoop
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
tar -xzf hadoop-3.3.6.tar.gz
sudo mv hadoop-3.3.6 /opt/hadoop
```

### Configuration Adaptations

#### Environment Variables
```bash
# Add to ~/.zshrc or ~/.bashrc
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export SPARK_HOME=/opt/spark
export HADOOP_HOME=/opt/hadoop
export PATH="$SPARK_HOME/bin:$HADOOP_HOME/bin:$PATH"
```

#### Path Differences
```bash
# RedHat-specific paths
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export PATH="$HOME/.local/bin:$PATH"  # User-installed binaries
```

## 🔧 Cross-Platform Configuration

### Platform Detection
Add this to your `~/.zshrc` to automatically detect the platform:

```bash
# Platform detection
export PLATFORM=$(uname -s)
export IS_MACOS=false
export IS_LINUX=false
export IS_UBUNTU=false
export IS_REDHAT=false

case "$PLATFORM" in
    "Darwin")
        export IS_MACOS=true
        ;;
    "Linux")
        export IS_LINUX=true
        if [[ -f /etc/os-release ]]; then
            source /etc/os-release
            case "$ID" in
                "ubuntu"|"debian")
                    export IS_UBUNTU=true
                    ;;
                "rhel"|"centos"|"rocky"|"fedora")
                    export IS_REDHAT=true
                    ;;
            esac
        fi
        ;;
esac
```

### Conditional Configuration
Use platform detection to load appropriate configurations:

```bash
# Load platform-specific configurations
if [[ "$IS_MACOS" == "true" ]]; then
    # macOS-specific settings
    export PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
elif [[ "$IS_UBUNTU" == "true" ]]; then
    # Ubuntu-specific settings
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    export PATH="$HOME/.local/bin:$PATH"
elif [[ "$IS_REDHAT" == "true" ]]; then
    # RedHat-specific settings
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    export PATH="$HOME/.local/bin:$PATH"
fi
```

## 📁 Directory Structure Adaptation

### Home Directory Differences
```bash
# Platform-specific home directory handling
if [[ "$IS_MACOS" == "true" ]]; then
    export ZSHRC_CONFIG_DIR="$HOME/.config/zsh"
    export ZSHRC_BACKUPS="$HOME/.zshrc_backups"
else
    # Linux: Use standard home directory
    export ZSHRC_CONFIG_DIR="$HOME/.zsh"
    export ZSHRC_BACKUPS="$HOME/.zsh_backups"
fi
```

### Configuration File Locations
```bash
# Platform-specific config locations
if [[ "$IS_MACOS" == "true" ]]; then
    # macOS: Use ~/.config
    export XDG_CONFIG_HOME="$HOME/.config"
else
    # Linux: Use ~/.config or fallback to ~/.zsh
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
fi
```

## 🐍 Python Environment Adaptation

### pyenv Setup
```bash
# Platform-agnostic pyenv setup
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    # Initialize pyenv
    if [[ "$IS_MACOS" == "true" ]]; then
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
    else
        # Linux: Use bash-style initialization
        eval "$(pyenv init -)"
        eval "$(pyenv virtualenv-init -)"
    fi
fi
```

### uv Setup
```bash
# Platform-agnostic uv setup
if command -v uv >/dev/null 2>&1; then
    export PATH="$HOME/.local/bin:$PATH"
    
    # Linux: Ensure uv is in PATH
    if [[ "$IS_LINUX" == "true" ]]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
fi
```

## 🚀 Big Data Tools Adaptation

### Java Setup
```bash
# Platform-specific Java setup
if [[ "$IS_MACOS" == "true" ]]; then
    # macOS: Use Homebrew Java
    export JAVA_HOME="/opt/homebrew/opt/openjdk@11"
elif [[ "$IS_UBUNTU" == "true" ]]; then
    # Ubuntu: Use OpenJDK
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
elif [[ "$IS_REDHAT" == "true" ]]; then
    # RedHat: Use OpenJDK
    export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
fi

if [[ -n "$JAVA_HOME" ]]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi
```

### Spark Setup
```bash
# Platform-agnostic Spark setup
if [[ -d "/opt/spark" ]]; then
    export SPARK_HOME="/opt/spark"
    export PATH="$SPARK_HOME/bin:$PATH"
    
    # Platform-specific Spark configurations
    if [[ "$IS_MACOS" == "true" ]]; then
        export SPARK_LOCAL_IP="127.0.0.1"
    else
        export SPARK_LOCAL_IP="localhost"
    fi
fi
```

### Hadoop Setup
```bash
# Platform-agnostic Hadoop setup
if [[ -d "/opt/hadoop" ]]; then
    export HADOOP_HOME="/opt/hadoop"
    export PATH="$HADOOP_HOME/bin:$PATH"
    
    # Platform-specific Hadoop configurations
    if [[ "$IS_MACOS" == "true" ]]; then
        export HADOOP_OPTS="-Djava.security.krb5.conf=/etc/krb5.conf"
    else
        export HADOOP_OPTS="-Djava.security.krb5.conf=/etc/krb5.conf"
    fi
fi
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Zsh Not Found
```bash
# Check if Zsh is installed
which zsh

# If not found, install it
# Ubuntu/Debian:
sudo apt install -y zsh

# RedHat/CentOS:
sudo dnf install -y zsh
```

#### 2. Python Tools Not Working
```bash
# Check Python installation
python3 --version

# Check pyenv
pyenv --version

# Check uv
uv --version

# Verify PATH
echo $PATH | grep -E "(pyenv|uv)"
```

#### 3. Big Data Tools Not Found
```bash
# Check Java
java -version

# Check Spark
spark-shell --version

# Check Hadoop
hadoop version

# Verify environment variables
echo "JAVA_HOME: $JAVA_HOME"
echo "SPARK_HOME: $SPARK_HOME"
echo "HADOOP_HOME: $HADOOP_HOME"
```

### Performance Issues

#### 1. Slow Shell Startup
```bash
# Profile shell startup
time zsh -i -c exit

# Check for slow-loading modules
zsh -i -c "echo 'Shell loaded'"
```

#### 2. PATH Issues
```bash
# Check PATH length
echo "PATH length: ${#PATH}"

# Check for duplicates
echo $PATH | tr ':' '\n' | sort | uniq -d

# Use the optimize function
optimize
```

## 📋 Migration Checklist

### Before Migration
- [ ] Backup current configuration
- [ ] Document current environment variables
- [ ] List installed tools and versions
- [ ] Note any custom configurations

### During Migration
- [ ] Install required packages
- [ ] Set up Python environment managers
- [ ] Configure big data tools
- [ ] Test basic functionality

### After Migration
- [ ] Verify all tools work
- [ ] Test backup system
- [ ] Check performance
- [ ] Update documentation

## 🎯 Best Practices

### 1. Use Platform Detection
Always check the platform before running platform-specific commands or setting paths.

### 2. Maintain Compatibility
Keep configurations as generic as possible, using platform detection for specific adaptations.

### 3. Test Regularly
Test your configuration on different platforms to ensure compatibility.

### 4. Document Changes
Keep track of platform-specific modifications for future reference.

### 5. Use Environment Variables
Store platform-specific paths in environment variables for easy modification.

## 🐳 Docker Container Deployment

### Dockerfile for Enhanced Zsh Configuration

Create a `Dockerfile` that includes your enhanced Zsh configuration:

```dockerfile
# Use Ubuntu 22.04 as base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ZSHRC_CONFIG_DIR=/root/.zsh
ENV ZSHRC_BACKUPS=/root/.zsh_backups

# Install system dependencies
RUN apt-get update && apt-get install -y \
    zsh \
    git \
    curl \
    wget \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*

# Install Python version managers
RUN curl https://pyenv.run | bash
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Node.js and NVM
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install big data tools
RUN wget https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz \
    && tar -xzf spark-3.5.0-bin-hadoop3.tgz \
    && mv spark-3.5.0-bin-hadoop3 /opt/spark \
    && rm spark-3.5.0-bin-hadoop3.tgz

RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz \
    && tar -xzf hadoop-3.3.6.tar.gz \
    && mv hadoop-3.3.6 /opt/hadoop \
    && rm hadoop-3.3.6.tar.gz

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV SPARK_HOME=/opt/spark
ENV HADOOP_HOME=/opt/hadoop
ENV PYENV_ROOT=/root/.pyenv
ENV NVM_DIR=/root/.nvm

# Add to PATH
ENV PATH="$SPARK_HOME/bin:$HADOOP_HOME/bin:$PYENV_ROOT/bin:$PATH"

# Copy your Zsh configuration
COPY .zsh /root/.zsh/
COPY .zshrc /root/.zshrc

# Set Zsh as default shell
RUN chsh -s /bin/zsh root

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/zsh"]
```

### Docker Compose for Development

Create a `docker-compose.yml` for easy development setup:

```yaml
version: '3.8'

services:
  zsh-dev:
    build: .
    container_name: enhanced-zsh-dev
    volumes:
      - .:/workspace
      - ~/.gitconfig:/root/.gitconfig:ro
      - ~/.ssh:/root/.ssh:ro
    environment:
      - PLATFORM=Linux
      - IS_LINUX=true
      - IS_UBUNTU=true
    ports:
      - "8888:8888"  # For Jupyter notebooks
      - "4040:4040"  # For Spark UI
    stdin_open: true
    tty: true
    command: /bin/zsh

  zsh-spark:
    build: .
    container_name: enhanced-zsh-spark
    volumes:
      - .:/workspace
      - ~/.gitconfig:/root/.gitconfig:ro
    environment:
      - SPARK_MODE=master
      - SPARK_RPC_AUTHENTICATION_ENABLED=no
      - SPARK_RPC_ENCRYPTION_ENABLED=no
      - SPARK_LOCAL_IP=0.0.0.0
      - SPARK_MASTER_HOST=0.0.0.0
    ports:
      - "7077:7077"  # Spark master
      - "8080:8080"  # Spark master UI
    command: /opt/spark/sbin/start-master.sh -h 0.0.0.0
```

### Quick Docker Commands

```bash
# Build and run development container
docker build -t enhanced-zsh .
docker run -it --rm enhanced-zsh

# Run with volume mount for development
docker run -it --rm -v $(pwd):/workspace enhanced-zsh

# Run with specific Python version
docker run -it --rm -e PYTHON_VERSION=3.11 enhanced-zsh

# Run with Spark cluster
docker-compose up zsh-spark
```

## 🖥️ Remote Server Deployment

### Automated Deployment Script

Create a deployment script for remote servers:

```bash
#!/bin/bash
# deploy-enhanced-zsh.sh

set -e

# Configuration
REMOTE_USER="${1:-$USER}"
REMOTE_HOST="${2:-localhost}"
REMOTE_DIR="${3:-~/.enhanced-zsh}"
LOCAL_CONFIG_DIR="${4:-~/.config/zsh}"

echo "🚀 Deploying Enhanced Zsh to $REMOTE_USER@$REMOTE_HOST"

# Create remote directory structure
ssh "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR/{config,backups,docs}"

# Copy configuration files
echo "📁 Copying configuration files..."
scp -r "$LOCAL_CONFIG_DIR"/* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/config/"

# Copy documentation
echo "📚 Copying documentation..."
scp -r "$LOCAL_CONFIG_DIR/docs"/* "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/docs/"

# Create remote .zshrc
cat > remote_zshrc << EOF
# Enhanced Zsh Configuration for Remote Server
export ENHANCED_ZSH_DIR="$REMOTE_DIR"
export ZSHRC_CONFIG_DIR="$REMOTE_DIR/config"
export ZSHRC_BACKUPS="$REMOTE_DIR/backups"

# Platform detection
export PLATFORM=\$(uname -s)
export IS_LINUX=false
export IS_UBUNTU=false
export IS_REDHAT=false

if [[ "\$PLATFORM" == "Linux" ]]; then
    export IS_LINUX=true
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "\$ID" in
            "ubuntu"|"debian")
                export IS_UBUNTU=true
                ;;
            "rhel"|"centos"|"rocky"|"fedora")
                export IS_REDHAT=true
                ;;
        esac
    fi
fi

# Source configuration
if [[ -f "\$ZSHRC_CONFIG_DIR/core.zsh" ]]; then
    source "\$ZSHRC_CONFIG_DIR/core.zsh"
fi

if [[ -f "\$ZSHRC_CONFIG_DIR/environment.zsh" ]]; then
    source "\$ZSHRC_CONFIG_DIR/environment.zsh"
fi

if [[ -f "\$ZSHRC_CONFIG_DIR/backup-system.zsh" ]]; then
    source "\$ZSHRC_CONFIG_DIR/backup-system.zsh"
fi

# Set prompt
export PS1="[Enhanced Zsh] %~ %# "
EOF

# Copy remote .zshrc
scp remote_zshrc "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/.zshrc"

# Clean up
rm remote_zshrc

echo "✅ Deployment complete!"
echo "💡 To use on remote server:"
echo "   ssh $REMOTE_USER@$REMOTE_HOST"
echo "   source $REMOTE_DIR/.zshrc"
echo "   # or add to ~/.zshrc: source $REMOTE_DIR/.zshrc"
```

### Remote Server Setup Commands

```bash
# Make deployment script executable
chmod +x deploy-enhanced-zsh.sh

# Deploy to specific server
./deploy-enhanced-zsh.sh username server.example.com

# Deploy to multiple servers
for server in server1 server2 server3; do
    ./deploy-enhanced-zsh.sh username $server
done

# Deploy with custom config directory
./deploy-enhanced-zsh.sh username server.example.com ~/.enhanced-zsh ~/.config/zsh
```

### Remote Server Configuration

#### Minimal Remote .zshrc
```bash
# Minimal remote configuration
export ENHANCED_ZSH_DIR="$HOME/.enhanced-zsh"
export ZSHRC_CONFIG_DIR="$ENHANCED_ZSH_DIR/config"
export ZSHRC_BACKUPS="$ENHANCED_ZSH_DIR/backups"

# Platform detection
source "$ZSHRC_CONFIG_DIR/core.zsh"

# Load essential modules
source "$ZSHRC_CONFIG_DIR/environment.zsh"
source "$ZSHRC_CONFIG_DIR/backup-system.zsh"

# Custom prompt for remote servers
export PS1="[Remote Enhanced Zsh] %~ %# "
```

## 🔧 Container and Remote Optimizations

### Performance Optimizations

#### Docker Optimizations
```dockerfile
# Multi-stage build for smaller images
FROM ubuntu:22.04 AS base
# ... base installation

FROM base AS python-tools
# ... Python tools installation

FROM base AS big-data
# ... Big data tools installation

FROM base AS final
# Copy only necessary files
COPY --from=python-tools /root/.pyenv /root/.pyenv
COPY --from=python-tools /root/.local /root/.local
COPY --from=big-data /opt/spark /opt/spark
COPY --from=big-data /opt/hadoop /opt/hadoop
```

#### Remote Server Optimizations
```bash
# Lazy loading for remote servers
lazy_load_python() {
    if [[ ! -n "$(command -v python)" ]]; then
        source "$ZSHRC_CONFIG_DIR/python/init.zsh"
    fi
    python "$@"
}

lazy_load_spark() {
    if [[ ! -n "$(command -v spark-shell)" ]]; then
        source "$ZSHRC_CONFIG_DIR/spark.zsh"
    fi
    spark-shell "$@"
}

# Create aliases for lazy loading
alias python='lazy_load_python'
alias spark-shell='lazy_load_spark'
```

### Security Considerations

#### Docker Security
```dockerfile
# Run as non-root user
RUN useradd -m -s /bin/zsh zshuser
USER zshuser
WORKDIR /home/zshuser

# Copy config to user directory
COPY --chown=zshuser:zshuser .zsh /home/zshuser/.zsh/
```

#### Remote Server Security
```bash
# Secure file permissions
chmod 700 ~/.enhanced-zsh
chmod 600 ~/.enhanced-zsh/.zshrc

# Use SSH keys only
# In ~/.ssh/config:
Host *.example.com
    PubkeyAuthentication yes
    PasswordAuthentication no
    IdentitiesOnly yes
```

## 📋 Deployment Checklist

### Docker Deployment
- [ ] Create Dockerfile with all dependencies
- [ ] Test build process
- [ ] Verify all tools work in container
- [ ] Test volume mounts for development
- [ ] Create docker-compose.yml for complex setups

### Remote Server Deployment
- [ ] Prepare deployment script
- [ ] Test on local/development server
- [ ] Verify SSH access and permissions
- [ ] Deploy to staging server first
- [ ] Test all functionality remotely
- [ ] Deploy to production servers

### Post-Deployment Verification
- [ ] Test Zsh startup time
- [ ] Verify PATH optimization works
- [ ] Test backup system functionality
- [ ] Check help system availability
- [ ] Verify Python tools work
- [ ] Test big data tools if needed

## 🎯 Use Cases

### Development Containers
- **Local Development**: Consistent environment across team members
- **CI/CD Pipelines**: Reproducible builds with your Zsh tools
- **Testing**: Isolated testing environments

### Remote Servers
- **Production Servers**: Consistent shell experience across infrastructure
- **Development Servers**: Remote development with familiar tools
- **Data Processing**: Big data workflows on remote clusters

### Hybrid Environments
- **Local + Remote**: Same configuration locally and remotely
- **Multiple Servers**: Consistent experience across server fleet
- **Cloud Deployments**: Deploy to AWS, GCP, Azure with same tools

## 📚 Additional Resources

### Docker Resources
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-stage Builds](https://docs.docker.com/develop/dev-best-practices/multistage-build/)
- [Docker Security](https://docs.docker.com/engine/security/)

### Remote Deployment Resources
- [SSH Configuration](https://www.ssh.com/academy/ssh/config)
- [Ansible for Automation](https://docs.ansible.com/)
- [Terraform for Infrastructure](https://www.terraform.io/docs)

### Ubuntu Resources
- [Ubuntu Zsh Installation](https://wiki.ubuntu.com/Zsh)
- [Ubuntu Python Setup](https://docs.ubuntu.com/python)
- [Ubuntu Java Setup](https://help.ubuntu.com/community/Java)

### RedHat Resources
- [RHEL Zsh Setup](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_red_hat_enterprise_linux_using_the_command_line_shell/using-zsh_using-the-command-line-shell)
- [RHEL Python](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/developing_python_3/index)
- [RHEL Java](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/deploying_java_applications/index)

### Cross-Platform Tools
- [pyenv](https://github.com/pyenv/pyenv)
- [uv](https://github.com/astral-sh/uv)
- [NVM](https://github.com/nvm-sh/nvm)
- [Linuxbrew](https://docs.brew.sh/Homebrew-on-Linux)

---

*This guide ensures your enhanced Zsh configuration works seamlessly across macOS, Ubuntu Linux, and RedHat Linux systems, maintaining all functionality while adapting to platform-specific requirements.*
