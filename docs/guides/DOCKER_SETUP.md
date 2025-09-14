# 🐳 Docker Container Setup Guide

## 🚀 **Optimized Shell Configuration for Containers**

The Siege Analytics ZSH system is already **container-optimized** with automatic detection and performance tuning.

## 📊 **Container Support Overview**

### **✅ Current Container Features:**
- **Automatic Detection**: Detects Docker, Kubernetes, WSL environments
- **Light Mode**: <0.1s startup time for CI/CD and embedded systems
- **Memory Aware**: Optimizes resource usage in constrained environments
- **Cross-Platform**: Alpine, Ubuntu, RHEL, Debian container support
- **Minimal Dependencies**: Core functions work without external tools

### **🎯 Recommended Container Configurations**

## 1. **Lightweight Development Container (Recommended)**

```dockerfile
FROM alpine:latest

# Install minimal dependencies
RUN apk add --no-cache zsh git curl

# Clone the shell system
RUN git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh

# Set up lightweight configuration
ENV ZSH_MODE=light
ENV WORKING_ON_LAPTOP=False

# Use bash compatibility for maximum compatibility
COPY --from=source ~/.config/zsh/bash-compatibility.zsh /opt/shell-config.sh
RUN echo 'source ~/.config/zsh/bash-compatibility.zsh' >> ~/.bashrc

CMD ["/bin/zsh"]
```

## 2. **CI/CD Pipeline Container**

```dockerfile
FROM ubuntu:22.04

# Minimal setup for CI/CD
RUN apt-get update && apt-get install -y zsh git && rm -rf /var/lib/apt/lists/*

# Clone shell system
RUN git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh

# CI-optimized environment
ENV ZSH_MODE=light
ENV CI=true
ENV DISABLE_AUTO_BACKUP=true

# Minimal bash compatibility for scripts
RUN echo 'source ~/.config/zsh/bash-compatibility.zsh' >> ~/.bashrc

ENTRYPOINT ["/bin/bash"]
```

## 3. **Data Science Container (Full Featured)**

```dockerfile
FROM python:3.11-slim

# Install development tools
RUN apt-get update && apt-get install -y \
    zsh git curl build-essential \
    && rm -rf /var/lib/apt/lists/*

# Clone complete system
RUN git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh

# Enable container-optimized heavy mode
ENV ZSH_MODE=heavy
ENV PYTHON_MANAGER=uv
ENV SPARK_DRIVER_MEMORY=1g

# Initialize the system
RUN zsh -c "source ~/.config/zsh/zshrc && python_status"

CMD ["/bin/zsh"]
```

## 🚀 **Quick Container Setup**

### **Option 1: Minimal (Recommended for most containers)**
```bash
# In your Dockerfile or container
RUN git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh
ENV ZSH_MODE=light
RUN echo 'source ~/.config/zsh/bash-compatibility.zsh' >> ~/.bashrc
```

### **Option 2: Full System (For development containers)**
```bash
# In your Dockerfile
RUN git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh
ENV ZSH_MODE=heavy
RUN zsh -c "source ~/.config/zsh/zshrc"
```

## ⚡ **Performance in Containers**

### **Light Mode Performance:**
- **Startup**: <0.1 seconds
- **Memory**: <10MB additional
- **Functions**: Essential utilities, shell detection, PATH management
- **Perfect for**: CI/CD, Alpine containers, microservices

### **Heavy Mode Performance:**
- **Startup**: ~2 seconds (acceptable for development containers)
- **Memory**: <50MB additional
- **Functions**: Complete system with Python, Spark, database integration
- **Perfect for**: Development environments, data science containers

## 🔧 **Container-Specific Features**

### **Automatic Optimizations:**
```bash
# Container detection (automatic)
echo $IN_CONTAINER          # "true" in containers
echo $CONTAINER_TYPE        # "docker", "kubernetes", or "wsl"

# Optimized functions available:
deduplicate_path            # Clean PATH in containers
python_status              # Python environment detection
validate_environment       # Container environment validation
```

### **Platform Detection:**
```bash
# Automatic platform detection
echo $PLATFORM             # "linux" in most containers
echo $LINUX_DISTRO         # "ubuntu", "alpine", "rhel"
echo $PACKAGE_MANAGER      # "apt", "apk", "yum"
```

## 🧪 **Testing in Containers**

### **Test the Setup:**
```bash
# In your container
docker run -it your-image /bin/zsh -c "
  source ~/.config/zsh/bash-compatibility.zsh &&
  python_status &&
  validate_environment
"
```

### **Run Compatibility Tests:**
```bash
# Test cross-shell compatibility
docker run -it your-image /bin/bash ~/.config/zsh/tests/test-bash-compatibility.sh
```

## 🌟 **Best Practices for Containers**

### **1. Use Light Mode by Default**
```dockerfile
ENV ZSH_MODE=light
ENV DISABLE_AUTO_BACKUP=true  # Disable git operations in containers
```

### **2. Bash Compatibility First**
```dockerfile
# For maximum compatibility, use bash-compatibility.zsh
RUN echo 'source ~/.config/zsh/bash-compatibility.zsh' >> ~/.bashrc
```

### **3. Container-Specific Optimization**
```dockerfile
# Optimize for container environment
ENV WORKING_ON_LAPTOP=False
ENV CI=true
ENV CONTAINER_OPTIMIZED=true
```

## 📦 **Ready-to-Use Examples**

### **Minimal Python Container:**
```dockerfile
FROM python:3.11-alpine
RUN apk add --no-cache zsh git
RUN git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh
ENV ZSH_MODE=light
RUN echo 'source ~/.config/zsh/bash-compatibility.zsh' >> ~/.bashrc
CMD ["/bin/zsh"]
```

### **Development Container:**
```dockerfile
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y zsh git python3 && rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/dheerajchand/siege_analytics_zshrc.git ~/.config/zsh
ENV ZSH_MODE=heavy
WORKDIR /workspace
CMD ["/bin/zsh"]
```

## 🔧 **Troubleshooting**

### **If startup is slow:**
```bash
# Force light mode
export ZSH_MODE=light
source ~/.config/zsh/bash-compatibility.zsh
```

### **If functions are missing:**
```bash
# Test minimal compatibility
bash -c "source ~/.config/zsh/bash-compatibility.zsh && python_status"
```

### **Container-specific issues:**
```bash
# Check container detection
source ~/.config/zsh/bash-compatibility.zsh
echo "Container: $IN_CONTAINER"
echo "Type: $CONTAINER_TYPE"
validate_environment
```

---

**The system is already optimized for containers! Use light mode for best performance, or heavy mode for full development environments.** 🚀