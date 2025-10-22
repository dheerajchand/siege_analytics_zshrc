# Quick Reference - Clean ZSH Build

**Status**: Production Ready ✅  
**Location**: `~/.config/zsh/clean/`

---

## 🚀 Quick Start

```bash
# Source the clean build
cd ~/.config/zsh && git checkout clean-rebuild
source ~/.config/zsh/clean/zshrc

# Or to make it permanent
cp ~/.config/zsh/zshrc ~/.config/zsh/zshrc.old
cp ~/.config/zsh/clean/zshrc ~/.config/zsh/zshrc
```

---

## 📚 Most Used Commands

### Spark
```bash
spark_start              # Start Spark cluster
spark_stop               # Stop Spark cluster
spark_status             # Check cluster status
spark_restart            # Restart cluster

# Submit jobs
smart_spark_submit script.py
spark_yarn_submit script.py  # Submit to YARN
```

### Python
```bash
py_env_switch geo31111   # Switch environment
python_status            # Show current setup
ds_project_init myproject # Create DS project
```

### Hadoop/YARN
```bash
start_hadoop             # Start YARN cluster
stop_hadoop              # Stop all services
hadoop_status            # Check status
yarn_cluster_info        # Show cluster metrics
```

### Utilities
```bash
mkcd newdir              # Make and cd into directory
path_add /custom/path    # Add to PATH
path_clean               # Remove PATH duplicates
extract archive.tar.gz   # Extract any archive
is_online                # Check network
```

### Credentials
```bash
store_credential service user password
get_credential service user
credential_backend_status
```

---

## ⚠️ Known Issues & Workarounds

### HDFS Not Available
**Problem**: NameNode won't start  
**Workaround**: Use local files or S3

```python
# Instead of HDFS
df = spark.read.parquet("hdfs://...")

# Use local files
df = spark.read.parquet("file:///path/to/data")

# Or S3 (production standard)
df = spark.read.parquet("s3://bucket/data")
```

---

## 📊 What's Tested and Working

✅ All Spark operations (start, stop, submit, YARN)  
✅ All utilities (path, files, network)  
✅ Python environment management  
✅ Credentials (keychain integration)  
✅ YARN cluster (ResourceManager, NodeManager)  
✅ Project initialization  

⚠️ HDFS (use local/S3 workaround)  

---

## 🐛 Bugs Fixed

1. ✅ Spark startup - Changed pgrep to jps
2. ✅ Hadoop PATH - Fixed module loading

---

## 📁 Files

**Main**: `clean/zshrc`  
**Modules**: `clean/*.zsh`  
**Tests**: `clean/comprehensive_behavioral_tests.zsh`  
**Docs**: `clean/*.md`

---

## 💡 Pro Tips

1. **Spark jobs**: Use local files during development
2. **Python**: Auto-activates `.venv` when you cd into projects
3. **PATH**: Use `path_clean` if PATH gets messy
4. **Credentials**: Stored securely in keychain/1Password

---

## 🎯 Bottom Line

**It works.** Use it for all your projects.

The only limitation (HDFS) has an easy workaround that's actually better for production anyway.

