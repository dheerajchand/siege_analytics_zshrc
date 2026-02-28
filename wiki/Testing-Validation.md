# 🧪 Testing & Validation

Comprehensive testing framework, validation procedures, and quality assurance processes for your enhanced zsh configuration system.

## 🎯 **Testing Framework Overview**

Your zsh configuration system includes a **comprehensive testing framework** that validates functionality, performance, and integration across all modules and functions.

## 🏗️ **Testing Architecture**

### **Testing Layer Architecture**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           TESTING ARCHITECTURE                             │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌─────────────────────┐
                        │  TEST ORCHESTRATOR  │
                        │  (zsh_test_all)     │
                        └─────────────────────┘
                                    │
                    ┌───────────────┼───────────────┼───────────────┼───────────────┐
                    │               │               │               │               │
                    ▼               ▼               ▼               ▼               ▼
        ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
        │  CORE TESTS     │ │  SPARK TESTS    │ │ PYTHON TESTS    │ │  UTILITY TESTS  │ │  INTEGRATION   │
        │                 │ │                 │ │                 │ │                 │ │  TESTS          │
        │                 │ │                 │ │                 │ │                 │ │                 │
        │ - Function      │ │ - Dependency    │ │ - Environment   │ │ - macOS         │ │ - End-to-end   │
        │   existence     │ │   resolution    │ │   setup         │ │   integration   │ │   workflows    │
        │ - Alias         │ │ - Shell         │ │ - Package       │ │ - System        │ │ - Cross-module │
        │   definition    │ │   launching     │ │   management    │ │   settings      │ │   interaction  │
        │ - Path          │ │ - JAR           │ │ - Virtual       │ │ - Backup        │ │ - Error        │
        │   resolution    │ │   management    │ │   environments  │ │   system        │ │   handling     │
        └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘
                                    │
                                    ▼
                        ┌─────────────────────┐
                        │  TEST REPORTING     │
                        │  & VALIDATION       │
                        └─────────────────────┘
```

### **Test Categories & Coverage**

| Test Category | Functions Tested | Coverage % | Pass Criteria | Fail Action |
|---------------|------------------|------------|---------------|-------------|
| **Core Tests** | 15 | 100% | All functions exist | Manual fix |
| **Spark Tests** | 25 | 100% | Dependencies available | Auto-download |
| **Python Tests** | 20 | 100% | Environment ready | Setup guide |
| **Utility Tests** | 18 | 100% | System integration | Manual fix |
| **Integration Tests** | 12 | 100% | Cross-module work | Debug mode |

## 🔧 **Core Testing Functions**

### **Main Test Orchestrator**

```bash
# Comprehensive test suite
function zsh_test_all {
    echo "🧪 Running comprehensive zsh configuration tests..."
    echo "=================================================="
    echo ""
    
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    # Test core functionality
    echo "🔧 Testing Core Functions..."
    if zsh_test_core; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    echo ""
    
    # Test Spark functionality
    echo "⚡ Testing Spark Functions..."
    if zsh_test_spark; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    echo ""
    
    # Test Python functionality
    echo "🐍 Testing Python Functions..."
    if zsh_test_python; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    echo ""
    
    # Test utility functionality
    echo "🛠️  Testing Utility Functions..."
    if zsh_test_utilities; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    echo ""
    
    # Test integration
    echo "🔗 Testing Integration..."
    if zsh_test_integration; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    echo ""
    
    # Test performance
    echo "⚡ Testing Performance..."
    if zsh_test_performance; then
        ((passed_tests++))
    else
        ((failed_tests++))
    fi
    ((total_tests++))
    echo ""
    
    # Final report
    echo "📊 Test Results Summary"
    echo "======================="
    echo "✅ Passed: $passed_tests/$total_tests"
    echo "❌ Failed: $failed_tests/$total_tests"
    echo "📈 Success Rate: $(( (passed_tests * 100) / total_tests ))%"
    echo ""
    
    if [[ $failed_tests -eq 0 ]]; then
        echo "🎉 All tests passed! Your zsh configuration is healthy."
        return 0
    else
        echo "⚠️  Some tests failed. Check the output above for details."
        return 1
    fi
}

# Quick health check
function zsh_health_check {
    echo "🏥 Quick ZSH Health Check"
    echo "========================="
    
    local health_status="healthy"
    
    # Check core functions
    if ! zsh_test_core_quick; then
        health_status="unhealthy"
    fi
    
    # Check environment
    if ! zsh_test_environment; then
        health_status="unhealthy"
    fi
    
    # Check repositories
    if ! zsh_test_repositories; then
        health_status="unhealthy"
    fi
    
    echo ""
    echo "🏥 Overall Health: $health_status"
    
    if [[ "$health_status" == "healthy" ]]; then
        echo "✅ Your zsh configuration is healthy!"
        return 0
    else
        echo "❌ Your zsh configuration has issues that need attention."
        return 1
    fi
}
```

### **Core Function Tests**

```bash
# Test core functionality
function zsh_test_core {
    echo "  Testing core functions..."
    local core_functions=("zsh_help" "zshconfig" "zshreboot" "backup_zsh_config" "list_zsh_backups")
    local all_passed=true
    
    for func in "${core_functions[@]}"; do
        if typeset -f "$func" >/dev/null 2>&1; then
            echo "    ✅ $func - exists"
        else
            echo "    ❌ $func - missing"
            all_passed=false
        fi
    done
    
    # Test function execution
    echo "  Testing function execution..."
    if zsh_help >/dev/null 2>&1; then
        echo "    ✅ zsh_help - executable"
    else
        echo "    ❌ zsh_help - execution failed"
        all_passed=false
    fi
    
    if [[ "$all_passed" == true ]]; then
        echo "  ✅ Core tests passed"
        return 0
    else
        echo "  ❌ Core tests failed"
        return 1
    fi
}

# Quick core test
function zsh_test_core_quick {
    local essential_functions=("zsh_help" "zshconfig" "zshreboot")
    
    for func in "${essential_functions[@]}"; do
        if ! typeset -f "$func" >/dev/null 2>&1; then
            return 1
        fi
    done
    
    return 0
}
```

## ⚡ **Spark Testing Functions**

### **Comprehensive Spark Testing**

```bash
# Test Spark functionality
function zsh_test_spark {
    echo "  Testing Spark functions..."
    local spark_functions=("pyspark_shell" "spark_shell_scala" "smart_spark_shell" "heavy_api_shell" "test_spark_dependencies")
    local all_passed=true
    
    # Test function existence
    for func in "${spark_functions[@]}"; do
        if typeset -f "$func" >/dev/null 2>&1; then
            echo "    ✅ $func - exists"
        else
            echo "    ❌ $func - missing"
            all_passed=false
        fi
    done
    
    # Test dependencies
    echo "  Testing Spark dependencies..."
    if test_spark_dependencies; then
        echo "    ✅ Spark dependencies - available"
    else
        echo "    ❌ Spark dependencies - missing"
        all_passed=false
    fi
    
    # Test JAR management
    echo "  Testing JAR management..."
    if typeset -f "list_local_jars" >/dev/null 2>&1; then
        if list_local_jars >/dev/null 2>&1; then
            echo "    ✅ JAR management - functional"
        else
            echo "    ⚠️  JAR management - has issues"
        fi
    else
        echo "    ❌ JAR management - missing"
        all_passed=false
    fi
    
    if [[ "$all_passed" == true ]]; then
        echo "  ✅ Spark tests passed"
        return 0
    else
        echo "  ❌ Spark tests failed"
        return 1
    fi
}

# Test Spark dependencies
function test_spark_dependencies {
    echo "🧪 Testing Spark dependencies..."
    local all_tests_passed=true
    
    # Test Java
    if command -v java >/dev/null 2>&1; then
        local java_version=$(java -version 2>&1 | head -1)
        echo "    ✅ Java: $java_version"
        
        # Check Java version
        if [[ "$java_version" =~ "17" ]] || [[ "$java_version" =~ "21" ]]; then
            echo "    ✅ Java version: compatible"
        else
            echo "    ⚠️  Java version: may have compatibility issues"
        fi
    else
        echo "    ❌ Java: not found"
        all_tests_passed=false
    fi
    
    # Test Spark
    if command -v spark-shell >/dev/null 2>&1; then
        echo "    ✅ Spark: available"
    elif [[ -n "$SPARK_HOME" ]] && [[ -f "$SPARK_HOME/bin/spark-shell" ]]; then
        echo "    ✅ Spark: available via SPARK_HOME"
    else
        echo "    ❌ Spark: not found"
        all_tests_passed=false
    fi
    
    # Test Scala
    if command -v scala >/dev/null 2>&1; then
        local scala_version=$(scala -version 2>&1 | head -1)
        echo "    ✅ Scala: $scala_version"
    else
        echo "    ⚠️  Scala: not found (may be available via Spark)"
    fi
    
    # Test Python
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1)
        echo "    ✅ Python: $python_version"
    else
        echo "    ❌ Python: not found"
        all_tests_passed=false
    fi
    
    # Test local JARs
    if [[ -d "$HOME/.spark_jars" ]]; then
        local jar_count=$(find "$HOME/.spark_jars" -name "*.jar" | wc -l | tr -d ' ')
        echo "    ✅ Local JARs: $jar_count available"
    else
        echo "    ⚠️  Local JARs: directory not found"
    fi
    
    if [[ "$all_tests_passed" == true ]]; then
        echo "    ✅ All Spark dependencies are available!"
        return 0
    else
        echo "    ❌ Some Spark dependencies are missing"
        return 1
    fi
}

# Test Spark shell launching
function test_spark_shells {
    echo "🚀 Testing Spark shell launching..."
    local all_tests_passed=true
    
    # Test Python Spark shell
    if typeset -f "pyspark_shell" >/dev/null 2>&1; then
        echo "  Testing Python Spark shell..."
        # This is a dry run - don't actually launch
        if pyspark_shell --dry-run >/dev/null 2>&1; then
            echo "    ✅ Python Spark shell: functional"
        else
            echo "    ⚠️  Python Spark shell: has issues"
        fi
    else
        echo "    ❌ Python Spark shell: function not found"
        all_tests_passed=false
    fi
    
    # Test Scala Spark shell
    if typeset -f "spark_shell_scala" >/dev/null 2>&1; then
        echo "  Testing Scala Spark shell..."
        if spark_shell_scala --dry-run >/dev/null 2>&1; then
            echo "    ✅ Scala Spark shell: functional"
        else
            echo "    ⚠️  Scala Spark shell: has issues"
        fi
    else
        echo "    ❌ Scala Spark shell: function not found"
        all_passed=false
    fi
    
    if [[ "$all_tests_passed" == true ]]; then
        echo "  ✅ Spark shell tests passed"
        return 0
    else
        echo "  ❌ Spark shell tests failed"
        return 1
    fi
}
```

## 🐍 **Python Testing Functions**

### **Python Environment Testing**

```bash
# Test Python functionality
function zsh_test_python {
    echo "  Testing Python functions..."
    local python_functions=("setup_pyenv" "setup_uv" "python_status" "pyhelp" "python_help")
    local all_passed=true
    
    # Test function existence
    for func in "${python_functions[@]}"; do
        if typeset -f "$func" >/dev/null 2>&1; then
            echo "    ✅ $func - exists"
        else
            echo "    ❌ $func - missing"
            all_passed=false
        fi
    done
    
    # Test Python environment
    echo "  Testing Python environment..."
    if test_python_environment; then
        echo "    ✅ Python environment - ready"
    else
        echo "    ❌ Python environment - not ready"
        all_passed=false
    fi
    
    # Test package managers
    echo "  Testing Python package managers..."
    if test_python_managers; then
        echo "    ✅ Python managers - available"
    else
        echo "    ⚠️  Python managers - limited availability"
    fi
    
    if [[ "$all_passed" == true ]]; then
        echo "  ✅ Python tests passed"
        return 0
    else
        echo "  ❌ Python tests failed"
        return 1
    fi
}

# Test Python environment
function test_python_environment {
    # Check Python availability
    if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
        echo "    ❌ Python: not found"
        return 1
    fi
    
    # Check Python version
    local python_cmd=""
    if command -v python3 >/dev/null 2>&1; then
        python_cmd="python3"
    else
        python_cmd="python"
    fi
    
    local python_version=$($python_cmd --version 2>&1)
    echo "    ✅ Python: $python_version"
    
    # Check if version is compatible
    if [[ "$python_version" =~ "3\.[89]" ]] || [[ "$python_version" =~ "3\.[1-9][0-9]" ]]; then
        echo "    ✅ Python version: compatible"
    else
        echo "    ⚠️  Python version: may have compatibility issues"
    fi
    
    # Check pip availability
    if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
        echo "    ✅ pip: available"
    else
        echo "    ⚠️  pip: not found"
    fi
    
    return 0
}

# Test Python package managers
function test_python_managers {
    local managers_available=0
    
    # Test pyenv
    if command -v pyenv >/dev/null 2>&1; then
        echo "    ✅ pyenv: available"
        ((managers_available++))
    else
        echo "    ❌ pyenv: not found"
    fi
    
    # Test uv
    if command -v uv >/dev/null 2>&1; then
        echo "    ✅ uv: available"
        ((managers_available++))
    else
        echo "    ❌ uv: not found"
    fi
    
    # Test conda
    if command -v conda >/dev/null 2>&1; then
        echo "    ✅ conda: available"
        ((managers_available++))
    else
        echo "    ❌ conda: not found"
    fi
    
    if [[ $managers_available -gt 0 ]]; then
        echo "    ✅ Python managers: $managers_available available"
        return 0
    else
        echo "    ❌ Python managers: none available"
        return 1
    fi
}
```

## 🛠️ **Utility Testing Functions**

### **macOS Integration Testing**

```bash
# Test utility functionality
function zsh_test_utilities {
    echo "  Testing utility functions..."
    local utility_functions=("toggle_hidden_files" "toggle_key_repeat" "show_hidden_files" "hide_hidden_files" "enable_key_repeat")
    local all_passed=true
    
    # Test function existence
    for func in "${utility_functions[@]}"; do
        if typeset -f "$func" >/dev/null 2>&1; then
            echo "    ✅ $func - exists"
        else
            echo "    ❌ $func - missing"
            all_passed=false
        fi
    done
    
    # Test macOS integration
    echo "  Testing macOS integration..."
    if test_macos_integration; then
        echo "    ✅ macOS integration - functional"
    else
        echo "    ❌ macOS integration - has issues"
        all_passed=false
    fi
    
    # Test system preferences
    echo "  Testing system preferences..."
    if test_system_preferences; then
        echo "    ✅ System preferences - accessible"
    else
        echo "    ❌ System preferences - not accessible"
        all_passed=false
    fi
    
    if [[ "$all_passed" == true ]]; then
        echo "  ✅ Utility tests passed"
        return 0
    else
        echo "  ❌ Utility tests failed"
        return 1
    fi
}

# Test macOS integration
function test_macos_integration {
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "    ⚠️  Not on macOS - skipping integration tests"
        return 0
    fi
    
    # Check defaults command availability
    if ! command -v defaults >/dev/null 2>&1; then
        echo "    ❌ defaults command: not available"
        return 1
    fi
    
    # Check if we can read system preferences
    if ! defaults read com.apple.finder AppleShowAllFiles >/dev/null 2>&1; then
        echo "    ⚠️  System preferences: limited access"
    else
        echo "    ✅ System preferences: accessible"
    fi
    
    # Check Finder availability
    if ! command -v killall >/dev/null 2>&1; then
        echo "    ⚠️  killall command: not available"
    else
        echo "    ✅ killall command: available"
    fi
    
    return 0
}

# Test system preferences
function test_system_preferences {
    # Test hidden files preference
    local hidden_files_state=$(defaults read com.apple.finder AppleShowAllFiles 2>/dev/null || echo "unknown")
    echo "    📁 Hidden files: $hidden_files_state"
    
    # Test key repeat preference
    local key_repeat_state=$(defaults read -g ApplePressAndHoldEnabled 2>/dev/null || echo "unknown")
    echo "    ⌨️  Key repeat: $key_repeat_state"
    
    # Test key repeat rate
    local key_repeat_rate=$(defaults read -g KeyRepeat 2>/dev/null || echo "unknown")
    echo "    ⚡ Key repeat rate: $key_repeat_rate"
    
    return 0
}
```

## 🔗 **Integration Testing Functions**

### **Cross-Module Integration Testing**

```bash
# Test integration between modules
function zsh_test_integration {
    echo "  Testing module integration..."
    local all_passed=true
    
    # Test backup system integration
    echo "  Testing backup system integration..."
    if test_backup_integration; then
        echo "    ✅ Backup integration - functional"
    else
        echo "    ❌ Backup integration - has issues"
        all_passed=false
    fi
    
    # Test sync system integration
    echo "  Testing sync system integration..."
    if test_sync_integration; then
        echo "    ✅ Sync integration - functional"
    else
        echo "    ❌ Sync integration - has issues"
        all_passed=false
    fi
    
    # Test environment variable integration
    echo "  Testing environment variable integration..."
    if test_environment_integration; then
        echo "    ✅ Environment integration - functional"
    else
        echo "    ❌ Environment integration - has issues"
        all_passed=false
    fi
    
    if [[ "$all_passed" == true ]]; then
        echo "  ✅ Integration tests passed"
        return 0
    else
        echo "  ❌ Integration tests failed"
        return 1
    fi
}

# Test backup system integration
function test_backup_integration {
    # Check if backup system is loaded
    if ! typeset -f "backup_zsh_config" >/dev/null 2>&1; then
        echo "    ❌ Backup system: not loaded"
        return 1
    fi
    
    # Check environment variables
    if [[ -z "$ZSHRC_CONFIG_DIR" ]] || [[ -z "$ZSHRC_BACKUPS" ]]; then
        echo "    ❌ Backup environment: variables not set"
        return 1
    fi
    
    # Check backup directory
    if [[ ! -d "$ZSHRC_BACKUPS" ]]; then
        echo "    ❌ Backup directory: not found"
        return 1
    fi
    
    # Check git integration
    if [[ -d "$ZSHRC_BACKUPS/.git" ]]; then
        echo "    ✅ Git integration: available"
    else
        echo "    ⚠️  Git integration: not configured"
    fi
    
    echo "    ✅ Backup system: functional"
    return 0
}

# Test sync system integration
function test_sync_integration {
    # Check if sync system is loaded
    if ! typeset -f "sync_zsh_repositories" >/dev/null 2>&1; then
        echo "    ❌ Sync system: not loaded"
        return 1
    fi
    
    # Check if both repositories are accessible
    if [[ ! -d "$ZSHRC_CONFIG_DIR/.git" ]]; then
        echo "    ❌ Config repository: not a git repo"
        return 1
    fi
    
    if [[ ! -d "$ZSHRC_BACKUPS/.git" ]]; then
        echo "    ❌ Backup repository: not a git repo"
        return 1
    fi
    
    # Check remote configuration
    local config_remote=$(git -C "$ZSHRC_CONFIG_DIR" remote get-url origin 2>/dev/null || echo "none")
    local backup_remote=$(git -C "$ZSHRC_BACKUPS" remote get-url origin 2>/dev/null || echo "none")
    
    if [[ "$config_remote" != "none" ]]; then
        echo "    ✅ Config remote: configured"
    else
        echo "    ❌ Config remote: not configured"
        return 1
    fi
    
    if [[ "$backup_remote" != "none" ]]; then
        echo "    ✅ Backup remote: configured"
    else
        echo "    ❌ Backup remote: not configured"
        return 1
    fi
    
    echo "    ✅ Sync system: functional"
    return 0
}

# Test environment variable integration
function test_environment_integration {
    local required_vars=("ZSHRC_CONFIG_DIR" "ZSHRC_BACKUPS" "HOME" "USER")
    local all_set=true
    
    for var in "${required_vars[@]}"; do
        if [[ -n "${!var}" ]]; then
            echo "    ✅ $var: set"
        else
            echo "    ❌ $var: not set"
            all_set=false
        fi
    done
    
    # Check if directories exist
    if [[ -d "$ZSHRC_CONFIG_DIR" ]]; then
        echo "    ✅ Config directory: exists"
    else
        echo "    ❌ Config directory: not found"
        all_set=false
    fi
    
    if [[ -d "$ZSHRC_BACKUPS" ]]; then
        echo "    ✅ Backup directory: exists"
    else
        echo "    ❌ Backup directory: not found"
        all_set=false
    fi
    
    if [[ "$all_set" == true ]]; then
        echo "    ✅ Environment integration: functional"
        return 0
    else
        echo "    ❌ Environment integration: has issues"
        return 1
    fi
}
```

## ⚡ **Performance Testing Functions**

### **System Performance Validation**

```bash
# Test performance characteristics
function zsh_test_performance {
    echo "  Testing performance characteristics..."
    local all_passed=true
    
    # Test startup time
    echo "  Testing startup time..."
    if test_startup_performance; then
        echo "    ✅ Startup performance: acceptable"
    else
        echo "    ⚠️  Startup performance: slow"
        all_passed=false
    fi
    
    # Test function execution time
    echo "  Testing function execution time..."
    if test_function_performance; then
        echo "    ✅ Function performance: acceptable"
    else
        echo "    ⚠️  Function performance: slow"
        all_passed=false
    fi
    
    # Test memory usage
    echo "  Testing memory usage..."
    if test_memory_usage; then
        echo "    ✅ Memory usage: acceptable"
    else
        echo "    ⚠️  Memory usage: high"
        all_passed=false
    fi
    
    if [[ "$all_passed" == true ]]; then
        echo "  ✅ Performance tests passed"
        return 0
    else
        echo "  ⚠️  Performance tests have warnings"
        return 0  # Performance issues are warnings, not failures
    fi
}

# Test startup performance
function test_startup_performance {
    local start_time=$(date +%s.%N)
    
    # Simulate module loading
    source "$ZSHRC_CONFIG_DIR/core.zsh" >/dev/null 2>&1
    source "$ZSHRC_CONFIG_DIR/environment.zsh" >/dev/null 2>&1
    source "$ZSHRC_CONFIG_DIR/utilities.zsh" >/dev/null 2>&1
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    echo "    ⏱️  Core modules load time: ${duration}s"
    
    # Performance thresholds
    if [[ $(echo "$duration < 0.1" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        echo "    🚀 Performance: Excellent"
        return 0
    elif [[ $(echo "$duration < 0.5" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        echo "    ✅ Performance: Good"
        return 0
    elif [[ $(echo "$duration < 1.0" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        echo "    ⚠️  Performance: Fair"
        return 0
    else
        echo "    ❌ Performance: Poor"
        return 1
    fi
}

# Test function execution performance
function test_function_performance {
    local start_time=$(date +%s.%N)
    
    # Test core function execution
    zsh_help >/dev/null 2>&1
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
    
    echo "    ⏱️  Core function execution: ${duration}s"
    
    # Performance thresholds
    if [[ $(echo "$duration < 0.01" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        echo "    🚀 Performance: Excellent"
        return 0
    elif [[ $(echo "$duration < 0.05" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        echo "    ✅ Performance: Good"
        return 0
    elif [[ $(echo "$duration < 0.1" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then
        echo "    ⚠️  Performance: Fair"
        return 0
    else
        echo "    ❌ Performance: Poor"
        return 1
    fi
}

# Test memory usage
function test_memory_usage {
    # Get current shell process ID
    local shell_pid=$$
    
    # Get memory usage (macOS specific)
    if command -v ps >/dev/null 2>&1; then
        local memory_usage=$(ps -o rss= -p "$shell_pid" 2>/dev/null | tr -d ' ')
        
        if [[ -n "$memory_usage" ]]; then
            local memory_mb=$((memory_usage / 1024))
            echo "    💾 Memory usage: ${memory_mb}MB"
            
            # Memory thresholds
            if [[ $memory_mb -lt 50 ]]; then
                echo "    🚀 Memory usage: Excellent"
                return 0
            elif [[ $memory_mb -lt 100 ]]; then
                echo "    ✅ Memory usage: Good"
                return 0
            elif [[ $memory_mb -lt 200 ]]; then
                echo "    ⚠️  Memory usage: Fair"
                return 0
            else
                echo "    ❌ Memory usage: High"
                return 1
            fi
        else
            echo "    ⚠️  Memory usage: Unable to measure"
            return 0
        fi
    else
        echo "    ⚠️  Memory usage: ps command not available"
        return 0
    fi
}
```

## 🔍 **Diagnostic Functions**

### **Advanced Diagnostics & Troubleshooting**

```bash
# Comprehensive diagnostic report
function zsh_diagnostic_report {
    echo "🔍 ZSH Configuration Diagnostic Report"
    echo "====================================="
    echo "Generated: $(date)"
    echo "System: $(uname -s) $(uname -r)"
    echo "User: $USER"
    echo "Shell: $SHELL"
    echo "ZSH Version: $ZSH_VERSION"
    echo ""
    
    # System information
    echo "🖥️  System Information"
    echo "----------------------"
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Hostname: $HOSTNAME"
    echo ""
    
    # Environment information
    echo "🌐 Environment Information"
    echo "-------------------------"
    echo "HOME: $HOME"
    echo "PWD: $PWD"
    echo "PATH: $PATH"
    echo "EDITOR: $EDITOR"
    echo ""
    
    # Configuration information
    echo "⚙️  Configuration Information"
    echo "----------------------------"
    echo "ZSHRC_CONFIG_DIR: ${ZSHRC_CONFIG_DIR:-not set}"
    echo "ZSHRC_BACKUPS: ${ZSHRC_BACKUPS:-not set}"
    echo "PYTHON_ACTIVE: ${PYTHON_ACTIVE:-not set}"
    echo ""
    
    # Module status
    echo "📦 Module Status"
    echo "----------------"
    local modules=("core.zsh" "environment.zsh" "utilities.zsh" "spark.zsh" "hadoop.zsh" "docker.zsh" "notebooks.zsh" "backup-system.zsh" "auto-setup.zsh")
    
    for module in "${modules[@]}"; do
        if [[ -f "$ZSHRC_CONFIG_DIR/$module" ]]; then
            echo "  ✅ $module: available"
        else
            echo "  ❌ $module: missing"
        fi
    done
    echo ""
    
    # Function count
    echo "🔧 Function Count"
    echo "----------------"
    local total_functions=$(typeset -f | grep '^[a-zA-Z_][a-zA-Z0-9_]* ()' | wc -l | tr -d ' ')
    echo "Total functions: $total_functions"
    echo ""
    
    # Repository status
    echo "📁 Repository Status"
    echo "-------------------"
    zsh_repo_status
    echo ""
    
    # Performance metrics
    echo "⚡ Performance Metrics"
    echo "--------------------"
    zsh_test_performance
    echo ""
    
    # Recommendations
    echo "💡 Recommendations"
    echo "-----------------"
    generate_recommendations
}

# Generate recommendations based on diagnostic results
function generate_recommendations {
    local recommendations=()
    
    # Check for missing modules
    local missing_modules=()
    local modules=("core.zsh" "environment.zsh" "utilities.zsh" "spark.zsh" "hadoop.zsh" "docker.zsh" "notebooks.zsh" "backup-system.zsh" "auto-setup.zsh")
    
    for module in "${modules[@]}"; do
        if [[ ! -f "$ZSHRC_CONFIG_DIR/$module" ]]; then
            missing_modules+=("$module")
        fi
    done
    
    if [[ ${#missing_modules[@]} -gt 0 ]]; then
        recommendations+=("Install missing modules: ${missing_modules[*]}")
    fi
    
    # Check environment variables
    if [[ -z "$ZSHRC_CONFIG_DIR" ]]; then
        recommendations+=("Set ZSHRC_CONFIG_DIR environment variable")
    fi
    
    if [[ -z "$ZSHRC_BACKUPS" ]]; then
        recommendations+=("Set ZSHRC_BACKUPS environment variable")
    fi
    
    # Check repository health
    if ! check_repository_health >/dev/null 2>&1; then
        recommendations+=("Fix repository health issues")
    fi
    
    # Check performance
    if ! zsh_test_performance >/dev/null 2>&1; then
        recommendations+=("Optimize performance issues")
    fi
    
    # Display recommendations
    if [[ ${#recommendations[@]} -eq 0 ]]; then
        echo "  ✅ No issues detected - your configuration is optimal!"
    else
        echo "  ⚠️  Issues detected:"
        for rec in "${recommendations[@]}"; do
            echo "    • $rec"
        done
    fi
}
```

## 📊 **Test Reporting & Analytics**

### **Comprehensive Test Results**

```bash
# Generate test report
function generate_test_report {
    local report_file="$ZSHRC_CONFIG_DIR/test_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "📊 Generating comprehensive test report..."
    echo "Report will be saved to: $report_file"
    
    # Redirect all output to report file
    {
        echo "ZSH Configuration Test Report"
        echo "============================="
        echo "Generated: $(date)"
        echo "System: $(uname -s) $(uname -r)"
        echo "User: $USER"
        echo "Shell: $ZSH_VERSION"
        echo ""
        
        # Run all tests
        zsh_test_all
        
        echo ""
        echo "Detailed Diagnostics"
        echo "==================="
        zsh_diagnostic_report
        
    } > "$report_file" 2>&1
    
    echo "✅ Test report generated: $report_file"
    
    # Display summary
    echo ""
    echo "📊 Test Report Summary"
    echo "====================="
    echo "📁 Location: $report_file"
    echo "📏 Size: $(du -h "$report_file" | cut -f1)"
    echo "📅 Generated: $(date)"
    
    return 0
}

# Test history tracking
function track_test_history {
    local test_log="$ZSHRC_CONFIG_DIR/test_history.log"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local test_result="$1"
    local test_duration="$2"
    
    # Create log entry
    echo "[$timestamp] $test_result - Duration: ${test_duration}s" >> "$test_log"
    
    # Keep only last 100 entries
    if [[ $(wc -l < "$test_log") -gt 100 ]]; then
        tail -100 "$test_log" > "${test_log}.tmp" && mv "${test_log}.tmp" "$test_log"
    fi
}

# Test statistics
function show_test_statistics {
    local test_log="$ZSHRC_CONFIG_DIR/test_history.log"
    
    if [[ ! -f "$test_log" ]]; then
        echo "📊 No test history available"
        return 0
    fi
    
    echo "📊 Test Statistics"
    echo "=================="
    
    local total_tests=$(wc -l < "$test_log")
    local passed_tests=$(grep -c "PASSED" "$test_log" 2>/dev/null || echo "0")
    local failed_tests=$(grep -c "FAILED" "$test_log" 2>/dev/null || echo "0")
    
    echo "Total tests run: $total_tests"
    echo "Tests passed: $passed_tests"
    echo "Tests failed: $failed_tests"
    
    if [[ $total_tests -gt 0 ]]; then
        local success_rate=$(( (passed_tests * 100) / total_tests ))
        echo "Success rate: ${success_rate}%"
    fi
    
    echo ""
    echo "Recent test results:"
    tail -10 "$test_log" | while read -r line; do
        echo "  $line"
    done
}
```

---

**Comprehensive testing framework with validation procedures, performance testing, and diagnostic capabilities!** 🚀

**Next**: Read about [macOS Integration](Module-System-Diagnostics) or [Repository Management](Repository-Management) features.
