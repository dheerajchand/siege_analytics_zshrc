# =====================================================
# AUTO-SETUP & VERSION MANAGEMENT MODULE
# =====================================================

# Note: Auto-setup control flags and target versions are now defined in main zshrc centralized section:
# - AUTO_SETUP_ON_STARTUP, AUTO_SETUP_CHECK_ONLINE, AUTO_SETUP_VERBOSE
# - TARGET_JAVA_VERSION, TARGET_SCALA_VERSION, TARGET_SPARK_VERSION, TARGET_HADOOP_VERSION, TARGET_MAVEN_VERSION

function setup_java_version {
    if [[ "$(is_online)" == "online" ]]; then
        echo "🔍 Setting up Java $TARGET_JAVA_VERSION..."
        if ! sdk list java | grep -q "$TARGET_JAVA_VERSION"; then
            echo "📦 Installing Java $TARGET_JAVA_VERSION..."
            sdk install java $TARGET_JAVA_VERSION
        fi
        sdk default java $TARGET_JAVA_VERSION
        export JAVA_HOME=$(sdk home java $TARGET_JAVA_VERSION)
        export PATH=$JAVA_HOME/bin:$PATH
        echo "✅ Java version set to $TARGET_JAVA_VERSION"
    else
        echo "⚠️  Offline - using current Java installation"
    fi
}

function auto_setup_environment {
    echo "🚀 Auto-setting up development environment..."
    
    if [[ "$(is_online)" == "offline" ]]; then
        echo "⚠️  Offline mode - skipping version updates"
        return 0
    fi
    
    setup_java_version 2>/dev/null || echo "⚠️  Java setup skipped"
    echo "✅ Environment auto-setup completed"
}

function verify_version_compatibility {
    echo "🔍 Verifying installed version compatibility..."
    echo ""
    
    local java_version=$(java -version 2>&1 | head -1 | grep -o '"[^"]*"' | tr -d '"' || echo "Not found")
    local spark_version=$(spark-submit --version 2>&1 | grep -o 'version [0-9]\+\.[0-9]\+\.[0-9]\+' | cut -d' ' -f2 || echo "Not found")
    
    echo "📊 Installed Versions:"
    echo "   Java:    $java_version"
    echo "   Spark:   $spark_version"
    echo ""
    
    local java_ok="❌"
    local spark_ok="❌"
    
    [[ "$java_version" =~ ^17\. ]] && java_ok="✅"
    [[ "$spark_version" == "$TARGET_SPARK_VERSION" ]] && spark_ok="✅"
    
    echo "🎯 Compatibility Check:"
    echo "   Java 17.x:     $java_ok"
    echo "   Spark 3.5.3:   $spark_ok"
}

function setup_environment_status {
    echo "🔍 Environment Setup Status:"
    echo ""
    echo "💾 Current Versions:"
    echo "   Java: $(java -version 2>&1 | head -1 || echo 'Not found')"
    echo "   Spark: $(spark-submit --version 2>&1 | head -1 || echo 'Not found')"
    echo ""
    echo "💡 Available Commands:"
    echo "   auto_setup_environment       - Run setup manually"
    echo "   verify_version_compatibility - Check compatibility"
    echo "   setup_java_version          - Setup Java specifically"
}

# Aliases
alias setup-status='setup_environment_status'
alias setup-auto='auto_setup_environment'
alias setup-check='verify_version_compatibility'

echo "⚙️  Auto-setup module loaded - version management ready"
