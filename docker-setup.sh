#!/bin/bash

# =====================================================
# Enhanced Zsh Docker Setup Script
# =====================================================
# This script sets up Docker containers with your enhanced Zsh configuration

set -e

echo "🐳 Enhanced Zsh Docker Setup"
echo "============================"
echo ""

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

# Configuration
IMAGE_NAME="enhanced-zsh"
CONTAINER_NAME="enhanced-zsh-dev"
WORKSPACE_DIR="${1:-$(pwd)}"

echo "📁 Workspace directory: $WORKSPACE_DIR"
echo "🐳 Image name: $IMAGE_NAME"
echo "📦 Container name: $CONTAINER_NAME"
echo ""

# Create Dockerfile
echo "📝 Creating Dockerfile..."
cat > Dockerfile << 'EOF'
# Enhanced Zsh Configuration Docker Image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ZSHRC_CONFIG_DIR=/root/.zsh
ENV ZSHRC_BACKUPS=/root/.zsh_backups
ENV PLATFORM=Linux
ENV IS_LINUX=true
ENV IS_UBUNTU=true

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
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Python version managers
RUN curl -fsSL https://pyenv.run | bash
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Install Node.js and NVM
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install big data tools
RUN wget -q https://dlcdn.apache.org/spark/spark-3.5.0/spark-3.5.0-bin-hadoop3.tgz \
    && tar -xzf spark-3.5.0-bin-hadoop3.tgz \
    && mv spark-3.5.0-bin-hadoop3 /opt/spark \
    && rm spark-3.5.0-bin-hadoop3.tgz

RUN wget -q https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz \
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
ENV PATH="$SPARK_HOME/bin:$HADOOP_HOME/bin:$PYENV_ROOT/bin:/root/.local/bin:$PATH"

# Copy Zsh configuration
COPY .zsh /root/.zsh/
COPY .zshrc /root/.zshrc

# Set Zsh as default shell
RUN chsh -s /bin/zsh root

# Set working directory
WORKDIR /workspace

# Default command
CMD ["/bin/zsh"]
EOF

# Create docker-compose.yml
echo "📝 Creating docker-compose.yml..."
cat > docker-compose.yml << EOF
version: '3.8'

services:
  zsh-dev:
    build: .
    container_name: $CONTAINER_NAME
    volumes:
      - $WORKSPACE_DIR:/workspace
      - ~/.gitconfig:/root/.gitconfig:ro
      - ~/.ssh:/root/.ssh:ro
    environment:
      - PLATFORM=Linux
      - IS_LINUX=true
      - IS_UBUNTU=true
      - WORKSPACE_DIR=/workspace
    ports:
      - "8888:8888"  # For Jupyter notebooks
      - "4040:4040"  # For Spark UI
      - "7077:7077"  # For Spark master
      - "8080:8080"  # For Spark master UI
    stdin_open: true
    tty: true
    command: /bin/zsh

  zsh-spark:
    build: .
    container_name: ${CONTAINER_NAME}-spark
    volumes:
      - $WORKSPACE_DIR:/workspace
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
EOF

# Create .dockerignore
echo "📝 Creating .dockerignore..."
cat > .dockerignore << 'EOF'
# Git
.git
.gitignore

# Docker
Dockerfile
docker-compose.yml
.dockerignore

# Documentation
docs/
*.md

# Scripts
*.sh

# Temporary files
*.tmp
*.log
EOF

# Build Docker image
echo "🔨 Building Docker image..."
docker build -t $IMAGE_NAME .

if [[ $? -eq 0 ]]; then
    echo "✅ Docker image built successfully!"
else
    echo "❌ Docker build failed!"
    exit 1
fi

# Create convenience scripts
echo "📝 Creating convenience scripts..."

# Quick start script
cat > start-enhanced-zsh.sh << EOF
#!/bin/bash
# Quick start script for Enhanced Zsh container

echo "🚀 Starting Enhanced Zsh container..."
docker run -it --rm \\
    -v $WORKSPACE_DIR:/workspace \\
    -v ~/.gitconfig:/root/.gitconfig:ro \\
    -v ~/.ssh:/root/.ssh:ro \\
    -e PLATFORM=Linux \\
    -e IS_LINUX=true \\
    -e IS_UBUNTU=true \\
    $IMAGE_NAME
EOF

# Development script
cat > dev-enhanced-zsh.sh << EOF
#!/bin/bash
# Development script for Enhanced Zsh container

echo "🔧 Starting Enhanced Zsh development environment..."
docker-compose up zsh-dev
EOF

# Spark script
cat > spark-enhanced-zsh.sh << EOF
#!/bin/bash
# Spark script for Enhanced Zsh container

echo "🚀 Starting Enhanced Zsh with Spark..."
docker-compose up zsh-spark
EOF

# Make scripts executable
chmod +x start-enhanced-zsh.sh dev-enhanced-zsh.sh spark-enhanced-zsh.sh

echo ""
echo "🎉 Setup Complete!"
echo "================"
echo ""
echo "📋 Available commands:"
echo "  ./start-enhanced-zsh.sh    # Quick start container"
echo "  ./dev-enhanced-zsh.sh      # Development environment"
echo "  ./spark-enhanced-zsh.sh    # Spark cluster"
echo "  docker-compose up zsh-dev  # Development with compose"
echo "  docker-compose up zsh-spark # Spark with compose"
echo ""
echo "🔧 Manual Docker commands:"
echo "  docker run -it --rm -v \$(pwd):/workspace $IMAGE_NAME"
echo "  docker exec -it $CONTAINER_NAME /bin/zsh"
echo ""
echo "📚 Documentation:"
echo "  See docs/CROSS_PLATFORM_GUIDE.md for detailed instructions"
echo ""
echo "💡 Tips:"
echo "  - Your workspace is mounted at /workspace in the container"
echo "  - Git config and SSH keys are available in the container"
echo "  - All your Zsh tools and functions are available"
echo "  - Use 'optimize' to clean PATH in the container"
echo ""
