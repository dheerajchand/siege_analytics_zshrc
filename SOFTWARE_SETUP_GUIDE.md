# Software Setup Guide

Complete guide for the `setup-software.sh` installer.

## What It Installs

### Core Components

**SDKMAN (SDK Manager)**
- Location: `~/.sdkman`
- Purpose: Manages Java, Hadoop, Spark versions
- Website: https://sdkman.io

**Java 17 (Temurin)**
- Version: 17.0.15-tem
- Location: `~/.sdkman/candidates/java/current`
- Provider: Eclipse Adoptium (formerly AdoptOpenJDK)

**Hadoop 3.3.6**
- Location: `~/.sdkman/candidates/hadoop/current`
- Data directories:
  - `~/hadoop-data/namenode` - HDFS NameNode
  - `~/hadoop-data/datanode` - HDFS DataNode
  - `~/hadoop-data/tmp` - Temporary files
- Configured for single-node cluster (localhost)

**Spark 4.1.1**
- Location: `~/.sdkman/candidates/spark/current`
- Directories:
  - `~/spark-events` - Event logs for history server
  - `~/spark-jars` - Local JAR files
- Configured for standalone mode

**pyenv (Python Version Manager)**
- Location: `~/.pyenv`
- Purpose: Manages Python versions and virtual environments
- Installed via: Homebrew (macOS) or git (Linux)

**Python 3.11.11**
- Virtual environment: `default_31111`
- Set as global default
- Includes essential packages:
  - ipython, jupyter
  - pandas, numpy
  - matplotlib, seaborn
- pyspark, pyarrow
- pytest, requests

**Zeppelin 0.12.0**
- Location: `~/opt/zeppelin/current`
- Installed from Apache tarball (no Homebrew formula)

---

## Installation Process

### One-Line Install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dheerajchand/siege_analytics_zshrc/main/setup-software.sh)
```

### Manual Install

```bash
cd ~/.config/zsh
chmod +x setup-software.sh
./setup-software.sh
```

### Installation Time

- **Total**: ~15-30 minutes
- Homebrew (if needed): ~5 minutes
- SDKMAN: ~2 minutes
- Java: ~3 minutes
- Hadoop: ~5 minutes
- Spark: ~5 minutes
- pyenv: ~2 minutes
- Python: ~5-10 minutes (depends on compilation)
- Python packages: ~2 minutes

---

## What Gets Configured

### Hadoop Configuration Files

**core-site.xml**
```xml
<property>
    <name>fs.defaultFS</name>
    <value>hdfs://localhost:9000</value>
</property>
<property>
    <name>hadoop.tmp.dir</name>
    <value>file:///Users/[your-user]/hadoop-data/tmp</value>
</property>
```

**hdfs-site.xml**
```xml
<property>
    <name>dfs.replication</name>
    <value>1</value>
</property>
<property>
    <name>dfs.namenode.name.dir</name>
    <value>file:///Users/[your-user]/hadoop-data/namenode</value>
</property>
<property>
    <name>dfs.datanode.data.dir</name>
    <value>file:///Users/[your-user]/hadoop-data/datanode</value>
</property>
```

**yarn-site.xml**
```xml
<property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
</property>
<property>
    <name>yarn.resourcemanager.hostname</name>
    <value>localhost</value>
</property>
```

### Spark Configuration

**spark-defaults.conf**
```
spark.master                     spark://localhost:7077
spark.eventLog.enabled           true
spark.eventLog.dir               file:///Users/[your-user]/spark-events
spark.history.fs.logDirectory    file:///Users/[your-user]/spark-events
spark.driver.memory              2g
spark.executor.memory            2g
```

---

## After Installation

### Verify Installation

```bash
# Check versions
java -version
hadoop version
spark-submit --version
python --version
zeppelin_start

# Check SDKMAN
sdk version

# Check pyenv
pyenv versions
```

### First Time Setup

**1. Restart your shell:**
```bash
exec zsh
```

**2. Start Hadoop (first time):**
```bash
start_hadoop
```

This will:
- Start HDFS NameNode
- Start HDFS DataNode
- Start YARN ResourceManager
- Start YARN NodeManager

**3. Start Spark:**
```bash
spark_start
```

This starts the Spark standalone cluster.

**4. Start Zeppelin (optional):**
```bash
zeppelin_start
```

**5. Verify services:**
```bash
hadoop_status
spark_status
```

---

## Web UIs

After starting services, access web interfaces:

| Service | URL | Purpose |
|---------|-----|---------|
| **Hadoop NameNode** | http://localhost:9870 | HDFS status, file browser |
| **YARN ResourceManager** | http://localhost:8088 | YARN applications, cluster metrics |
| **Spark Master** | http://localhost:8080 | Spark cluster status, workers |
| **Spark History** | http://localhost:18080 | Completed Spark applications |
| **Zeppelin** | http://localhost:8081 | Notebooks (Spark/Sedona) |

---

## Directory Structure

After installation:

```
$HOME/
├── .sdkman/
│   ├── bin/                    # SDKMAN binaries
│   └── candidates/
│       ├── java/current/       # Java installation
│       ├── hadoop/current/     # Hadoop installation
│       └── spark/current/      # Spark installation
├── .pyenv/
│   ├── versions/
│   │   ├── 3.11.11/           # Python installation
│   │   └── default_31111/     # Virtual environment
│   └── shims/                  # Python shims
├── opt/
│   └── zeppelin/
│       └── current/            # Zeppelin installation
├── hadoop-data/
│   ├── namenode/              # HDFS NameNode data
│   ├── datanode/              # HDFS DataNode data
│   └── tmp/                   # Hadoop temporary files
└── spark-events/              # Spark event logs
```

---

## Customization

### Change Python Version

Edit `setup-software.sh`:

```bash
PYTHON_VERSION="3.12.0"  # Change to desired version
DEFAULT_VENV="myenv"     # Change environment name
```

### Change Hadoop/Spark Versions

Edit `setup-software.sh`:

```bash
HADOOP_VERSION="3.3.7"   # Change Hadoop version
SPARK_VERSION="4.1.1"    # Change Spark version
```

Then run the installer again (it's idempotent - safe to re-run).

### Add More Python Packages

After installation:

```bash
# Activate environment
pyenv shell default_31111

# Install additional packages
pip install scikit-learn tensorflow dask
```

---

## Troubleshooting

### SDKMAN not found after installation

**Solution:**
```bash
source ~/.sdkman/bin/sdkman-init.sh
# Or restart shell
exec zsh
```

### Python not found after pyenv installation

**Solution:**
```bash
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
# Or restart shell
exec zsh
```

### Hadoop NameNode format fails

**Solution:**
```bash
# Remove existing data
rm -rf ~/hadoop-data/namenode/*
rm -rf ~/hadoop-data/datanode/*

# Format again
hdfs namenode -format -force
```

### Spark can't find Java

**Solution:**
```bash
# Ensure JAVA_HOME is set
source ~/.sdkman/bin/sdkman-init.sh

# Or restart shell
exec zsh

# Check
echo $JAVA_HOME
```

### Installation interrupted

The installer is **idempotent** - safe to run multiple times. Just run it again:

```bash
./setup-software.sh
```

It will skip already-installed components.

---

## Uninstalling

### Remove everything

```bash
# Remove SDKMAN and all managed software
rm -rf ~/.sdkman

# Remove pyenv
rm -rf ~/.pyenv

# Remove data directories
rm -rf ~/hadoop-data
rm -rf ~/spark-events
rm -rf ~/spark-jars

# Clean shell config (remove SDKMAN/pyenv lines from ~/.zshenv)
```

### Remove just Hadoop/Spark data

```bash
# Keep software, just clear data
rm -rf ~/hadoop-data/*
rm -rf ~/spark-events/*
```

---

## Next Steps

1. ✅ Installation complete
2. ✅ Shell configured
3. ▶️  **Start services**: `start_hadoop`, `spark_start`
4. ▶️  **Run tests**: Test HDFS, run Spark jobs
5. ▶️  **Learn**: Check zsh `help` command for all features

---

**See also:**
- `README.md` - Main documentation
- `TROUBLESHOOTING.md` - Common issues and fixes
- `install.sh` - ZSH configuration installer

