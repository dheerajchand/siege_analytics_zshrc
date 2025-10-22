# Comprehensive Function Testing Plan

**Goal**: Verify EVERY function in the clean build actually works, not just exists.

**Principle**: Don't just check if functions exist - actually use them and verify their behavior.

---

## Testing Status: INCOMPLETE ❌

**What I've Done So Far**:
- ✅ Verified functions exist (type command)
- ✅ Tested a few examples (path_add, python_status, spark_status)
- ⚠️  Created automated test suite (but it mostly checks existence, not deep behavior)

**What I HAVEN'T Done**:
- ❌ Actually started Spark and submitted a real job
- ❌ Actually started Hadoop/YARN and ran a YARN job
- ❌ Tested HDFS operations (put, get, ls, rm)
- ❌ Tested all Spark submit wrappers (smart_spark_submit, spark_yarn_submit)
- ❌ Tested Docker functions with real containers
- ❌ Tested database functions with real connections
- ❌ Tested credential functions with real credential storage/retrieval
- ❌ Tested backup functions with actual git operations

---

## Complete Function Inventory

### Utils Module (clean/utils.zsh)

| Function | Purpose | Test Method | Status |
|----------|---------|-------------|--------|
| `command_exists` | Check if command available | Call with known/unknown commands | ⚠️ Partial |
| `is_online` | Check network connectivity | Call and verify against actual network state | ⚠️ Partial |
| `mkcd` | Make directory and cd into it | Create dir, verify pwd changed | ⚠️ Partial |
| `extract` | Extract archives | Create test archive, extract, verify contents | ❌ Not tested |
| `path_add` | Add to PATH | Add dir, verify in PATH, test duplicate prevention | ✅ Tested |
| `path_clean` | Remove PATH duplicates | Create PATH with dupes, clean, verify | ❌ Not tested |

**Status**: 1/6 fully tested

---

### Python Module (clean/python.zsh)

| Function | Purpose | Test Method | Status |
|----------|---------|-------------|--------|
| `py_env_switch` | Switch Python versions | Switch version, verify `python --version` changed | ❌ Not tested |
| `python_status` | Show Python environment | Call and verify output matches reality | ⚠️ Partial (just ran it) |
| `ds_project_init` | Initialize data science project | Create project, verify structure created | ❌ Not tested |
| Auto-activate venv | Activate .venv on cd | Create project with .venv, cd in, verify activated | ❌ Not tested |

**Status**: 0/4 fully tested

---

### Spark Module (clean/spark.zsh)

| Function | Purpose | Test Method | Status |
|----------|---------|-------------|--------|
| `spark_start` | Start Spark cluster | Start, verify processes running, check web UI | ❌ Not tested |
| `spark_stop` | Stop Spark cluster | Stop, verify processes gone | ❌ Not tested |
| `spark_status` | Show Spark status | Call and verify matches actual process state | ⚠️ Partial (ran when stopped) |
| `smart_spark_submit` | Submit Spark job with deps | Submit actual PySpark job, verify it runs | ❌ Not tested |
| `get_spark_dependencies` | Detect dependencies | Create test script with imports, verify detection | ❌ Not tested |
| `pyspark_shell` | Interactive PySpark | Launch shell, run command, verify works | ❌ Not tested |
| `spark_yarn_submit` | Submit to YARN | Start YARN, submit job, verify runs on YARN | ❌ Not tested |
| `spark_history_server` | Start history server | Start server, verify web UI accessible | ❌ Not tested |
| `spark_restart` | Restart cluster | Restart, verify clean restart | ❌ Not tested |

**Status**: 0/9 fully tested

---

### Hadoop Module (clean/hadoop.zsh)

| Function | Purpose | Test Method | Status |
|----------|---------|-------------|--------|
| `start_hadoop` | Start HDFS + YARN | Start, verify NameNode/DataNode/RM/NM running | ❌ Not tested |
| `stop_hadoop` | Stop all Hadoop | Stop, verify all processes gone | ❌ Not tested |
| `hadoop_status` | Show Hadoop status | Call and verify matches actual state | ⚠️ Partial (ran when stopped) |
| `yarn_application_list` | List YARN apps | Submit app, list, verify it appears | ❌ Not tested |
| `hdfs_ls` | List HDFS files | Put file in HDFS, ls, verify appears | ❌ Not tested |
| `hdfs_put` | Upload to HDFS | Put file, verify in HDFS | ❌ Not tested |
| `hdfs_get` | Download from HDFS | Put file, get it, verify contents match | ❌ Not tested |
| `hdfs_rm` | Delete from HDFS | Put file, rm, verify gone | ❌ Not tested |
| `yarn_kill_all_apps` | Kill all YARN apps | Submit apps, kill all, verify gone | ❌ Not tested |
| `yarn_logs` | View app logs | Submit app, view logs, verify output | ❌ Not tested |
| `yarn_cluster_info` | Show cluster info | Call and verify against YARN web UI | ❌ Not tested |
| `test_hadoop_integration` | Full integration test | Run full test suite | ❌ Not tested |

**Status**: 0/12 fully tested

---

### Docker Module (clean/docker.zsh)

| Function | Purpose | Test Method | Status |
|----------|---------|-------------|--------|
| `docker_status` | Show Docker status | Call and verify against actual Docker state | ❌ Not tested |
| `docker_cleanup` | Prune unused resources | Check before/after disk usage | ❌ Not tested |
| `docker_shell` | Enter container shell | Start container, shell in, verify inside | ❌ Not tested |
| `docker_logs` | Follow container logs | Start container, follow logs, verify output | ❌ Not tested |

**Status**: 0/4 fully tested

---

### Database Module (clean/database.zsh)

| Function | Purpose | Test Method | Status |
|----------|---------|-------------|--------|
| `pg_connect` | Connect to PostgreSQL | Connect, run query, verify result | ❌ Not tested |
| `setup_postgres_credentials` | Store DB credentials | Store creds, verify retrievable | ❌ Not tested |
| `pg_test_connection` | Test DB connection | Test connection, verify result matches reality | ❌ Not tested |
| `database_status` | Show DB status | Call and verify against actual DB state | ❌ Not tested |

**Status**: 0/4 fully tested

---

### Credentials Module (clean/credentials.zsh)

| Function | Purpose | Test Method | Status |
|----------|---------|-------------|--------|
| `get_credential` | Retrieve credential | Store test cred, retrieve, verify value | ❌ Not tested |
| `store_credential` | Store credential | Store, retrieve, verify, delete | ❌ Not tested |
| `ga_store_service_account` | Store GA service account | Store test JSON, retrieve, verify | ❌ Not tested |
| `credential_backend_status` | Check backend availability | Call and verify against actual backend state | ❌ Not tested |

**Status**: 0/4 fully tested

---

### Backup Module (clean/backup.zsh)

| Function | Purpose | Test Method | Status |
|----------|---------|-------------|--------|
| `backup` | Commit changes to git | Make change, backup, verify commit created | ❌ Not tested |
| `pushmain` | Push to remote | Backup, push, verify on remote | ❌ Not tested |
| `sync` | Pull and push | Make remote change, sync, verify synced | ❌ Not tested |
| `repo_status` | Show git status | Make changes, check status, verify accurate | ❌ Not tested |

**Status**: 0/4 fully tested

---

## Overall Testing Status

| Module | Functions | Fully Tested | Partially Tested | Not Tested | Completion |
|--------|-----------|--------------|------------------|------------|------------|
| **Utils** | 6 | 1 | 2 | 3 | 17% |
| **Python** | 4 | 0 | 1 | 3 | 0% |
| **Spark** | 9 | 0 | 1 | 8 | 0% |
| **Hadoop** | 12 | 0 | 1 | 11 | 0% |
| **Docker** | 4 | 0 | 0 | 4 | 0% |
| **Database** | 4 | 0 | 0 | 4 | 0% |
| **Credentials** | 4 | 0 | 0 | 4 | 0% |
| **Backup** | 4 | 0 | 0 | 4 | 0% |
| **TOTAL** | **47** | **1** | **5** | **41** | **2%** |

---

## What Needs To Be Done

### Priority 1: Critical Functions (Spark/Hadoop/Python)

These are the functions you said are "very important":

1. **Spark Functions**
   - [ ] Start Spark cluster
   - [ ] Submit a real PySpark job with `smart_spark_submit`
   - [ ] Submit a job to YARN with `spark_yarn_submit`
   - [ ] Verify dependency detection with `get_spark_dependencies`
   - [ ] Test PySpark interactive shell
   - [ ] Stop and restart cluster

2. **Hadoop/YARN Functions**
   - [ ] Start Hadoop (HDFS + YARN)
   - [ ] Put files in HDFS
   - [ ] List, get, and remove HDFS files
   - [ ] Submit YARN application
   - [ ] List YARN applications
   - [ ] View YARN logs
   - [ ] Kill YARN applications
   - [ ] Stop Hadoop

3. **Python Functions**
   - [ ] Switch between Python versions
   - [ ] Verify virtual environment auto-activation
   - [ ] Initialize data science project
   - [ ] Verify Python status accuracy

### Priority 2: Supporting Functions

4. **Docker Functions**
   - [ ] Check Docker status
   - [ ] Enter container shell
   - [ ] Follow container logs
   - [ ] Cleanup unused resources

5. **Database Functions**
   - [ ] Connect to PostgreSQL
   - [ ] Test connection
   - [ ] Store and retrieve credentials

6. **Credential Functions**
   - [ ] Store credential in keychain
   - [ ] Retrieve credential
   - [ ] Verify backend status

7. **Backup Functions**
   - [ ] Create git commit
   - [ ] Push to remote
   - [ ] Sync with remote

8. **Utility Functions**
   - [ ] Extract archives
   - [ ] Clean PATH duplicates
   - [ ] Network connectivity check

---

## Proposed Testing Approach

### Phase 1: Spark Testing (Most Critical)

```bash
# Test 1: Start Spark
spark_start
# Verify: jps shows Master and Worker
# Verify: http://localhost:8080 accessible

# Test 2: Submit standalone job
cat > test_spark.py << 'EOF'
from pyspark.sql import SparkSession
spark = SparkSession.builder.appName("test").getOrCreate()
print(f"Spark version: {spark.version}")
df = spark.range(100)
print(f"Count: {df.count()}")
spark.stop()
EOF

smart_spark_submit test_spark.py
# Verify: Job runs and prints output
# Verify: Count = 100

# Test 3: Test dependency detection
cat > test_deps.py << 'EOF'
from pyspark.sql import SparkSession
import pandas as pd
import numpy as np
# Should detect these imports
EOF

get_spark_dependencies test_deps.py
# Verify: Detects pyspark, pandas, numpy

# Test 4: Interactive shell
pyspark_shell
# In shell: spark.range(10).count()
# Verify: Returns 10

# Test 5: Stop Spark
spark_stop
# Verify: No Master/Worker in jps
```

### Phase 2: Hadoop/YARN Testing

```bash
# Test 1: Start Hadoop
start_hadoop
# Verify: NameNode, DataNode, ResourceManager, NodeManager running
# Verify: http://localhost:9870 (HDFS)
# Verify: http://localhost:8088 (YARN)

# Test 2: HDFS operations
echo "test data" > test.txt
hdfs_put test.txt /test.txt
# Verify: File in HDFS

hdfs_ls /
# Verify: Shows /test.txt

hdfs_get /test.txt test_downloaded.txt
# Verify: Contents match

hdfs_rm /test.txt
# Verify: File gone

# Test 3: YARN job submission
spark_yarn_submit test_spark.py
# Verify: Job appears in YARN web UI
# Verify: Job completes successfully

yarn_application_list
# Verify: Shows completed job

# Test 4: Stop Hadoop
stop_hadoop
# Verify: All processes stopped
```

### Phase 3: Python Testing

```bash
# Test 1: Version switching
python --version  # Note current
py_env_switch 3.12.4
python --version  # Verify changed to 3.12.4
py_env_switch geo31111  # Switch back

# Test 2: Project initialization
cd /tmp
ds_project_init test_project
cd test_project
# Verify: Directory structure created
# Verify: .venv created
# Verify: Virtual environment activated

# Test 3: Auto-activation
cd /tmp
mkdir test_venv_project
cd test_venv_project
python -m venv .venv
cd ..
cd test_venv_project
# Verify: .venv auto-activated
```

### Phase 4: All Other Functions

Test each remaining function with real operations, not just existence checks.

---

## Honest Assessment

**What I claimed**: "51/53 tests passing"

**Reality**: Those tests mostly check function existence, not actual behavior.

**What I should have done**: 
1. Start Spark, submit real job
2. Start Hadoop, do HDFS operations
3. Submit YARN job, verify it runs
4. Test every function with real operations

**What I need to do**:
- Run through all 47 functions
- Actually use them for their intended purpose
- Verify they work in real workflows

---

## Questions I Need to Answer

1. **Does `smart_spark_submit` actually detect dependencies and submit jobs correctly?**
   - Need to: Create PySpark script with imports, submit, verify dependencies resolved

2. **Does `spark_yarn_submit` actually work with YARN?**
   - Need to: Start YARN, submit job to YARN, verify runs on YARN cluster

3. **Do HDFS operations work?**
   - Need to: Put/get/ls/rm files in HDFS, verify all operations

4. **Does Python version switching actually work?**
   - Need to: Switch versions, verify executables changed

5. **Do Docker functions work with real containers?**
   - Need to: Start container, shell in, view logs, cleanup

6. **Do credential functions work with actual keychain?**
   - Need to: Store/retrieve credentials, verify values

7. **Do backup functions create actual git commits?**
   - Need to: Make changes, backup, verify commits

---

## Conclusion

**Current Status**: Only 2% of functions are fully tested with real operations.

**What I Need**: Your permission/guidance to actually start services and run these tests.

**Why I Haven't**: 
- Starting Hadoop/YARN may interfere with your system
- Creating files/containers may clutter your environment  
- Some tests require specific setup (running database, etc.)

**Recommendation**: 
Either:
1. Let me run comprehensive tests (may take 30-60 minutes and create temporary resources)
2. You run the tests yourself with the test plan above
3. We test incrementally - one module at a time with your approval

**The honest truth**: I verified functions exist and have correct syntax, but I haven't proven they work in production use.

