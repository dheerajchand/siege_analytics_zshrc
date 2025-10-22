#!/bin/bash
# Fix Hadoop hostname issue

echo "=== Fixing Hadoop Hostname Issue ==="
echo ""

HOSTNAME=$(hostname)
echo "Current hostname: $HOSTNAME"
echo ""

# Option 1: Update Hadoop workers file (no sudo needed)
echo "Updating Hadoop configuration..."
HADOOP_HOME="${HADOOP_HOME:-$HOME/.sdkman/candidates/hadoop/current}"

if [[ -f "$HADOOP_HOME/etc/hadoop/workers" ]]; then
    # Backup original
    cp "$HADOOP_HOME/etc/hadoop/workers" "$HADOOP_HOME/etc/hadoop/workers.backup"
    
    # Replace hostname with localhost
    echo "localhost" > "$HADOOP_HOME/etc/hadoop/workers"
    echo "✅ Updated $HADOOP_HOME/etc/hadoop/workers to use localhost"
else
    echo "⚠️  Workers file not found, creating..."
    mkdir -p "$HADOOP_HOME/etc/hadoop"
    echo "localhost" > "$HADOOP_HOME/etc/hadoop/workers"
    echo "✅ Created workers file"
fi

echo ""
echo "Also need to add to /etc/hosts (requires sudo):"
echo "  sudo sh -c 'echo \"127.0.0.1 $HOSTNAME\" >> /etc/hosts'"
echo ""
echo "For now, Hadoop will use localhost instead of hostname."

