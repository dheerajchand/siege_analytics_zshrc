# 🚀 Quick Start Guide

**Get productive with the ZSH Configuration System in 5 minutes**

## ✅ System Status

Your system is **already configured and ready**! All modules load automatically when you open a new terminal.

```bash
# Verify everything is working
modules              # Show loaded modules (should show 12)
pg_connect --test    # Test database connection
py_env_switch list   # List Python environments
docker_status        # Check Docker (if available)
```

## 🎯 Essential Commands

### **System Information**
```bash
help                 # Complete command reference
modules              # Show all loaded modules
command_exists git   # Check if a command is available
is_online           # Test internet connectivity
```

### **Python Development**
```bash
# Environment management
py_env_switch list           # List all Python environments
py_env_switch myenv          # Switch to pyenv environment
py_env_switch uv             # Activate UV project

# Project creation
ds_project_init my_analysis        # Basic data science project
ds_project_init big_data spark     # With Spark dependencies
ds_project_init geo_project geo    # With geospatial tools

# Environment info
python_info          # Show current Python environment status
```

### **Database Operations**
```bash
# Setup (one-time)
setup_postgres_credentials --interactive
setup_mysql_credentials --interactive
setup_snowflake_credentials --interactive

# Daily usage
pg_connect          # Connect to PostgreSQL
pg_connect --test   # Test connection without opening psql
pg_connect mydb     # Connect to specific database

# Shortcuts
pg                  # Quick PostgreSQL connection
pgtest              # Quick connection test
db_test_all         # Test all configured databases
```

### **Container Development**
```bash
# Docker management
docker_status       # Complete Docker system status
docker_cleanup      # Clean up unused containers/images
docker_cleanup --aggressive  # Deep cleanup

# Quick checks
type docker_status  # Verify Docker module is loaded
```

### **Big Data & Analytics**
```bash
# Spark operations
spark_status            # Check Spark cluster status
start_hadoop           # Start Hadoop ecosystem
smart_spark_submit job.py  # Submit Spark job with auto-optimization

# Quick setup for big data projects
ds_project_init analysis spark
cd analysis
py_env_switch uv
start_hadoop
spark_status
```

### **Utilities**
```bash
# File operations
mkcd new_project     # Create directory and change into it
extract archive.zip  # Universal archive extraction
findtext "pattern"   # Search text in files

# System utilities
backup "commit msg"  # Backup and sync changes
path_add ~/bin       # Add directory to PATH safely
```

## 🔧 Quick Setup Workflows

### **New Python Project**
```bash
# Data science project with Spark
ds_project_init my_analysis spark
cd my_analysis
py_env_switch uv                 # Activate UV environment
start_hadoop                     # Start big data stack (if needed)
jupyter lab                      # Start Jupyter
```

### **Database Project**
```bash
# Setup database connection
setup_postgres_credentials --interactive
pg_connect --test              # Verify connection
pg_connect                     # Start working with database
```

### **Container Project**
```bash
# Docker development setup
docker_status                  # Check Docker health
mkcd my_docker_project
# Create your Dockerfile and docker-compose.yml
docker_cleanup                 # Clean up when done
```

## 🆘 Troubleshooting

### **Function Not Found**
```bash
# Check if modules are loaded
modules

# Manually load a module if needed
load_module database    # Load database functions
load_module python      # Load Python functions
load_module docker      # Load Docker functions
```

### **Database Connection Issues**
```bash
# Test individual databases
pg_connect --test       # PostgreSQL
mysql_connect --test    # MySQL (if configured)

# Re-setup credentials
setup_postgres_credentials --interactive
```

### **Python Environment Issues**
```bash
# Check current environment
python_info

# List available environments
py_env_switch list

# Switch to a working environment
py_env_switch system   # Use system Python
```

### **Performance Issues**
```bash
# Check startup time (should be <0.5s)
time zsh -c "source ~/.zshrc"

# Check PATH length (should be <500 chars)
echo $PATH | wc -c
```

## 📚 Next Steps

### **Learn More**
- Run `help` for complete command reference
- Check `docs/api-reference/` for detailed function documentation
- Review `docs/system-architecture.md` for system design

### **Advanced Features**
- **Credential Management**: Secure storage with 1Password/Keychain
- **Hostile Testing**: Security-focused testing framework
- **Context-Aware Loading**: Automatic environment detection
- **Module System**: On-demand loading for optimal performance

### **Get Help**
```bash
help                    # Built-in help system
modules                 # Show what's available
type function_name      # Check if a function exists
```

---

**🎉 You're ready to be productive! The system handles the complexity so you can focus on your work.**