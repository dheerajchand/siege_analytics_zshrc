#!/bin/zsh

# =====================================================
# SHELL PERFORMANCE DIAGNOSTIC TOOL
# =====================================================
# This script helps identify what's causing slow Finder dialogs
# and other shell performance issues

echo "🔍 Shell Performance Diagnostic Tool"
echo "=================================="
echo ""

# Check PATH for duplicates and length
echo "📁 PATH Analysis:"
echo "  Total length: ${#PATH}"
echo "  Total entries: $(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ')"
echo "  Duplicate entries: $(echo $PATH | tr ':' '\n' | sort | uniq -d | wc -l | tr -d ' ')"
echo ""

# Check for duplicate PATH entries
echo "🔄 Duplicate PATH entries:"
echo $PATH | tr ':' '\n' | sort | uniq -d | while read -r entry; do
    if [[ -n "$entry" ]]; then
        echo "  ❌ $entry"
    fi
done
echo ""

# Check for slow-loading tools
echo "🐌 Potentially Slow-Loading Tools:"
echo "  Java: ${JAVA_HOME:-'Not set'}"
echo "  Spark: ${SPARK_HOME:-'Not set'}"
echo "  Hadoop: ${HADOOP_HOME:-'Not set'}"
echo "  Pyenv: ${PYENV_ROOT:-'Not set'}"
echo "  NVM: ${NVM_DIR:-'Not set'}"
echo ""

# Check for heavy environment variables
echo "📊 Environment Variable Count:"
echo "  Total env vars: $(env | wc -l | tr -d ' ')"
echo "  Custom env vars: $(env | grep -E '^(SIEGE|UTILITIES|GEOCODE|MASAI|RESUME)' | wc -l | tr -d ' ')"
echo ""

# Check for auto-loading hooks
echo "🎣 Zsh Hooks:"
echo "  chpwd hooks: $(add-zsh-hook -L chpwd | wc -l | tr -d ' ')"
echo "  preexec hooks: $(add-zsh-hook -L preexec | wc -l | tr -d ' ')"
echo ""

# Check for slow directories in PATH
echo "📂 Slow PATH Directories (checking access time):"
echo $PATH | tr ':' '\n' | while read -r entry; do
    if [[ -n "$entry" && -d "$entry" ]]; then
        # Check if directory is slow to access
        start_time=$(date +%s%N)
        ls "$entry" >/dev/null 2>&1
        end_time=$(date +%s%N)
        duration=$(( (end_time - start_time) / 1000000 ))
        if [[ $duration -gt 100 ]]; then
            echo "  ⚠️  Slow: $entry (${duration}ms)"
        fi
    fi
done
echo ""

# Check for network mounts or slow filesystems
echo "🌐 Network/Slow Filesystems:"
echo $PATH | tr ':' '\n' | while read -r entry; do
    if [[ -n "$entry" && -d "$entry" ]]; then
        if df "$entry" 2>/dev/null | grep -q "//"; then
            echo "  🌐 Network mount: $entry"
        fi
    fi
done
echo ""

# Recommendations
echo "💡 Performance Recommendations:"
echo ""

if [[ $(echo $PATH | tr ':' '\n' | sort | uniq -d | wc -l | tr -d ' ') -gt 0 ]]; then
    echo "  ❌ Remove duplicate PATH entries"
fi

if [[ ${#PATH} -gt 1000 ]]; then
    echo "  ⚠️  PATH is very long (${#PATH} chars) - consider consolidating"
fi

if [[ -n "$SPARK_HOME" || -n "$HADOOP_HOME" ]]; then
    echo "  ⚠️  Big data tools are loaded - these can slow down shell startup"
fi

if [[ -n "$PYENV_ROOT" ]]; then
    echo "  ⚠️  Pyenv is loaded - ensure it's not auto-initializing"
fi

echo ""
echo "  ✅ Use 'source diagnose_performance.zsh' to run this diagnostic again"
echo "  ✅ Consider running 'time zsh -i -c exit' to measure shell startup time"
echo ""
