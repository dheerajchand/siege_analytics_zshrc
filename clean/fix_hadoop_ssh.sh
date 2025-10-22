#!/bin/bash
# Proper fix for Hadoop SSH/PATH issue on macOS
# This configures SSH to properly inherit PATH when Hadoop uses it

echo "=== Fixing Hadoop SSH/PATH Issue ==="
echo ""

# Step 1: Ensure SSH is set up for passwordless localhost
echo "1. Setting up passwordless SSH..."

if [[ ! -f ~/.ssh/id_rsa ]]; then
    echo "   Generating SSH key..."
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa -q
    echo "   ✅ SSH key generated"
fi

if ! grep -q "$(cat ~/.ssh/id_rsa.pub)" ~/.ssh/authorized_keys 2>/dev/null; then
    echo "   Adding key to authorized_keys..."
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    echo "   ✅ Authorized key added"
else
    echo "   ✅ SSH key already authorized"
fi

# Step 2: Test passwordless SSH
echo ""
echo "2. Testing passwordless SSH..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 localhost 'echo "SSH works"' 2>/dev/null | grep -q "SSH works"; then
    echo "   ✅ Passwordless SSH works"
else
    echo "   ❌ Passwordless SSH failed - may need to enable Remote Login in System Preferences"
    echo "   Go to: System Preferences > Sharing > Enable 'Remote Login'"
    exit 1
fi

# Step 3: Configure SSH to pass environment variables
echo ""
echo "3. Configuring SSH environment..."

# Create ~/.ssh/environment with PATH
cat > ~/.ssh/environment << EOF
PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:\$HOME/.sdkman/candidates/hadoop/current/bin:\$HOME/.sdkman/candidates/hadoop/current/sbin
HADOOP_HOME=\$HOME/.sdkman/candidates/hadoop/current
JAVA_HOME=\$HOME/.sdkman/candidates/java/current
EOF

chmod 600 ~/.ssh/environment
echo "   ✅ Created ~/.ssh/environment"

# Step 4: Configure sshd to accept environment
echo ""
echo "4. SSH daemon configuration..."
echo "   The following requires sudo to edit /etc/ssh/sshd_config"
echo ""
echo "   You need to add this line:"
echo "   PermitUserEnvironment yes"
echo ""
echo "   Run this command:"
echo "   sudo sh -c 'echo \"PermitUserEnvironment yes\" >> /etc/ssh/sshd_config'"
echo ""
echo "   Then restart SSH:"
echo "   sudo launchctl stop com.openssh.sshd"
echo "   sudo launchctl start com.openssh.sshd"
echo ""
echo "OR use the simpler approach (recommended):"
echo ""
echo "=== SIMPLER FIX ==="
echo "Configure Hadoop to use 'hdfs --daemon' instead of SSH"
echo "This works on both macOS and Ubuntu"
echo ""
echo "Already implemented in clean/hadoop.zsh"
echo "Uses: hdfs --daemon start namenode"
echo "Instead of: start-dfs.sh (which uses SSH)"
echo ""
echo "This is the canonical way to start Hadoop on single-node systems."

