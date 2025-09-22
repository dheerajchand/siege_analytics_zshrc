#!/usr/bin/env zsh
# =====================================================
# REAL DOCKER INTEGRATION TEST
# =====================================================
# Tests actual Docker functionality:
# 1. Test Docker module loading
# 2. Test Docker daemon connectivity
# 3. Test container operations
# 4. Test development environment creation
# 5. Test Docker health monitoring
# =====================================================

echo "🐳 REAL DOCKER INTEGRATION TEST"
echo "==============================="

# Load zsh config
source ~/.zshrc >/dev/null 2>&1

echo ""
echo "📋 Test 1: Docker module loading"
echo "-------------------------------"

if command -v load_module >/dev/null 2>&1; then
    echo "✅ load_module available"
    
    if load_module docker 2>&1; then
        echo "✅ Docker module loaded successfully"
    else
        echo "❌ Docker module loading failed"
    fi
else
    echo "❌ load_module not available"
fi

echo ""
echo "📋 Test 2: Docker functions availability"
echo "---------------------------------------"

# Test key Docker functions
docker_functions=("docker_status" "docker_start" "docker_stop" "docker_health_check" "docker_cleanup" "docker_dev_setup")

for func in "${docker_functions[@]}"; do
    if command -v "$func" >/dev/null 2>&1; then
        echo "✅ $func available"
    else
        echo "❌ $func not found"
    fi
done

echo ""
echo "📋 Test 3: Docker daemon connectivity"
echo "------------------------------------"

if command -v docker >/dev/null 2>&1; then
    echo "✅ Docker CLI available"
    
    # Test Docker daemon connectivity
    if docker info >/dev/null 2>&1; then
        echo "✅ Docker daemon running and accessible"
        echo "Docker version: $(docker --version)"
    else
        echo "❌ Docker daemon not running or not accessible"
        echo "Attempting to check status via zsh functions..."
        
        if command -v docker_status >/dev/null 2>&1; then
            docker_status 2>&1
        fi
    fi
else
    echo "❌ Docker CLI not available"
fi

echo ""
echo "📋 Test 4: Container operations test"
echo "-----------------------------------"

if docker info >/dev/null 2>&1; then
    echo "Testing basic container operations..."
    
    # Test running a simple container
    echo "Running hello-world container..."
    if docker run --rm hello-world 2>&1 | grep -q "Hello from Docker"; then
        echo "✅ Container execution successful"
    else
        echo "❌ Container execution failed"
    fi
    
    # Test image management
    echo "Testing image operations..."
    if docker images >/dev/null 2>&1; then
        echo "✅ Docker image listing works"
        echo "Available images: $(docker images --format 'table {{.Repository}}:{{.Tag}}' | wc -l | tr -d ' ') images"
    else
        echo "❌ Docker image operations failed"
    fi
    
else
    echo "❌ Docker daemon not available - skipping container tests"
fi

echo ""
echo "📋 Test 5: Development environment creation"
echo "------------------------------------------"

if command -v docker_dev_setup >/dev/null 2>&1; then
    echo "✅ docker_dev_setup available"
    
    # Test development environment creation (dry run)
    TEST_DEV_DIR="/tmp/test_docker_dev_$(date +%s)"
    mkdir -p "$TEST_DEV_DIR"
    cd "$TEST_DEV_DIR"
    
    echo "Testing development environment setup (dry run)..."
    # Note: This might be complex, so we'll test if the function runs without errors
    if docker_dev_setup test_env --dry-run 2>&1; then
        echo "✅ Development environment setup function works"
    else
        echo "❌ Development environment setup failed"
    fi
    
    # Cleanup
    cd /tmp
    rm -rf "$TEST_DEV_DIR"
    
else
    echo "❌ docker_dev_setup not available"
fi

echo ""
echo "📋 Test 6: Docker health monitoring"
echo "----------------------------------"

if command -v docker_health_check >/dev/null 2>&1; then
    echo "✅ docker_health_check available"
    
    echo "Testing Docker health check..."
    if docker_health_check 2>&1; then
        echo "✅ Docker health check completed"
    else
        echo "❌ Docker health check failed"
    fi
else
    echo "❌ docker_health_check not available"
fi

echo ""
echo "🎯 DOCKER INTEGRATION TEST COMPLETE"
echo "==================================="
