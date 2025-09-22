#!/usr/bin/env zsh
# =====================================================
# REAL PYTHON ENVIRONMENT INTEGRATION TEST
# =====================================================
# Tests actual Python environment functionality:
# 1. Test pyenv environment creation and switching
# 2. Test UV project creation and activation
# 3. Test ds_project_init functionality
# 4. Test python_info reporting
# =====================================================

echo "🐍 REAL PYTHON ENVIRONMENT TEST"
echo "==============================="

# Load zsh config
source ~/.zshrc >/dev/null 2>&1

echo ""
echo "📋 Test 1: Python environment information"
echo "----------------------------------------"

if command -v python_info >/dev/null 2>&1; then
    echo "✅ python_info command available"
    python_info
else
    echo "❌ python_info command not found"
fi

echo ""
echo "📋 Test 2: Python environment switching"
echo "--------------------------------------"

if command -v py_env_switch >/dev/null 2>&1; then
    echo "✅ py_env_switch command available"
    
    # Test listing environments
    echo "Testing environment listing:"
    py_env_switch list
    
    # Test UV mode
    echo ""
    echo "Testing UV mode:"
    py_env_switch uv
    
else
    echo "❌ py_env_switch command not found"
fi

echo ""
echo "📋 Test 3: Data science project creation"
echo "---------------------------------------"

if command -v ds_project_init >/dev/null 2>&1; then
    echo "✅ ds_project_init command available"
    
    # Create test project in temp directory
    TEST_PROJECT_DIR="/tmp/test_ds_project_$(date +%s)"
    mkdir -p "$TEST_PROJECT_DIR"
    cd "$TEST_PROJECT_DIR"
    
    echo "Creating test data science project..."
    if ds_project_init test_project basic 2>&1; then
        echo "✅ Basic data science project created"
        
        # Check project structure
        if [[ -f "pyproject.toml" ]]; then
            echo "✅ pyproject.toml created"
        else
            echo "❌ pyproject.toml missing"
        fi
        
        if [[ -d "notebooks" && -d "data" && -d "src" ]]; then
            echo "✅ Project directories created"
        else
            echo "❌ Project directories missing"
        fi
        
        # Test UV project activation
        if [[ -d ".venv" ]]; then
            echo "✅ Virtual environment created"
            
            # Test activation
            if source .venv/bin/activate 2>/dev/null; then
                echo "✅ Virtual environment activation works"
                echo "Active Python: $(which python)"
                deactivate 2>/dev/null
            else
                echo "❌ Virtual environment activation failed"
            fi
        else
            echo "❌ Virtual environment not created"
        fi
        
    else
        echo "❌ Data science project creation failed"
    fi
    
    # Cleanup
    cd /tmp
    rm -rf "$TEST_PROJECT_DIR"
    
else
    echo "❌ ds_project_init command not found"
fi

echo ""
echo "📋 Test 4: Pyenv integration"
echo "---------------------------"

if command -v pyenv >/dev/null 2>&1; then
    echo "✅ Pyenv available"
    echo "Current pyenv version: $(pyenv version)"
    echo "Available versions: $(pyenv versions --bare | wc -l | tr -d ' ') installed"
else
    echo "❌ Pyenv not available"
fi

echo ""
echo "📋 Test 5: UV integration"
echo "------------------------"

if command -v uv >/dev/null 2>&1; then
    echo "✅ UV available"
    echo "UV version: $(uv --version)"
    
    # Test UV project creation in temp directory
    UV_TEST_DIR="/tmp/test_uv_project_$(date +%s)"
    mkdir -p "$UV_TEST_DIR"
    cd "$UV_TEST_DIR"
    
    echo "Testing UV project initialization..."
    if uv init test_uv_project --python 3.11 2>&1; then
        echo "✅ UV project initialization works"
        
        cd test_uv_project
        if uv add pandas 2>&1; then
            echo "✅ UV package addition works"
        else
            echo "❌ UV package addition failed"
        fi
    else
        echo "❌ UV project initialization failed"
    fi
    
    # Cleanup
    cd /tmp
    rm -rf "$UV_TEST_DIR"
    
else
    echo "❌ UV not available"
fi

echo ""
echo "🎯 PYTHON ENVIRONMENT TEST COMPLETE"
echo "==================================="
